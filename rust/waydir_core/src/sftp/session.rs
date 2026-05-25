use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;

use once_cell::sync::Lazy;
use russh::client::{self, Handle};
use russh::keys::{PrivateKey, PrivateKeyWithHashAlg, PublicKey};
use russh_sftp::client::SftpSession;
use tokio::sync::Mutex;

use super::auth::{discover_default_keys, load_key, AuthKind};
use super::runtime::rt;

/// Status zwracany do Darta po próbie otwarcia sesji.
#[repr(u32)]
#[derive(Clone, Copy, Debug)]
pub enum SftpOpenStatus {
    Ok = 0,
    AuthRequired = 1,
    Error = 2,
}

pub(super) struct Client {
    pub(super) _ssh: Handle<ClientHandler>,
    pub(super) sftp: SftpSession,
}

pub(super) struct ClientHandler;

impl client::Handler for ClientHandler {
    type Error = russh::Error;

    fn check_server_key(
        &mut self,
        _server_public_key: &PublicKey,
    ) -> impl std::future::Future<Output = Result<bool, Self::Error>> + Send {
        async { Ok(true) }
    }
}

#[derive(Eq, PartialEq, Hash, Clone)]
pub(super) struct SessionKey {
    pub host: String,
    pub port: u16,
    pub user: String,
}

pub(super) struct Pool {
    pub sessions: HashMap<u64, Arc<Mutex<Client>>>,
    pub by_key: HashMap<SessionKey, u64>,
}

static POOL: Lazy<Mutex<Pool>> = Lazy::new(|| {
    Mutex::new(Pool {
        sessions: HashMap::new(),
        by_key: HashMap::new(),
    })
});
static NEXT_ID: AtomicU64 = AtomicU64::new(1);

pub(super) async fn get(id: u64) -> Option<Arc<Mutex<Client>>> {
    let pool = POOL.lock().await;
    pool.sessions.get(&id).cloned()
}

pub(super) async fn open(
    host: String,
    port: u16,
    user: String,
    auth: AuthKind,
) -> Result<(SftpOpenStatus, u64, String), String> {
    let key = SessionKey {
        host: host.clone(),
        port,
        user: user.clone(),
    };
    {
        let pool = POOL.lock().await;
        if let Some(id) = pool.by_key.get(&key).copied() {
            if pool.sessions.contains_key(&id) {
                return Ok((SftpOpenStatus::Ok, id, String::new()));
            }
        }
    }

    let config = Arc::new(client::Config {
        inactivity_timeout: Some(Duration::from_secs(60 * 60)),
        ..Default::default()
    });
    let mut handle = client::connect(config, (host.as_str(), port), ClientHandler)
        .await
        .map_err(|e| format!("connect: {e}"))?;

    let auth_ok = try_authenticate(&mut handle, &user, &auth).await?;
    if !auth_ok {
        return Ok((SftpOpenStatus::AuthRequired, 0, "auth required".into()));
    }

    let channel = handle
        .channel_open_session()
        .await
        .map_err(|e| format!("channel: {e}"))?;
    channel
        .request_subsystem(true, "sftp")
        .await
        .map_err(|e| format!("subsystem: {e}"))?;
    let sftp = SftpSession::new(channel.into_stream())
        .await
        .map_err(|e| format!("sftp init: {e}"))?;

    let id = NEXT_ID.fetch_add(1, Ordering::Relaxed);
    let client = Arc::new(Mutex::new(Client { _ssh: handle, sftp }));
    let mut pool = POOL.lock().await;
    pool.sessions.insert(id, client);
    pool.by_key.insert(key, id);
    Ok((SftpOpenStatus::Ok, id, String::new()))
}

async fn try_authenticate(
    handle: &mut Handle<ClientHandler>,
    user: &str,
    auth: &AuthKind,
) -> Result<bool, String> {
    match auth {
        AuthKind::Password(password) => handle
            .authenticate_password(user, password)
            .await
            .map(|result| result.success())
            .map_err(|e| format!("auth password: {e}")),
        AuthKind::Key { path, passphrase } => {
            let key = load_key(path, passphrase.as_deref())?;
            authenticate_key(handle, user, key).await
        }
        AuthKind::Auto => {
            for key in discover_default_keys() {
                match authenticate_key(handle, user, key).await {
                    Ok(true) => return Ok(true),
                    Ok(false) => continue,
                    Err(_) => continue,
                }
            }
            Ok(false)
        }
    }
}

async fn authenticate_key(
    handle: &mut Handle<ClientHandler>,
    user: &str,
    key: PrivateKey,
) -> Result<bool, String> {
    let hash_alg = handle
        .best_supported_rsa_hash()
        .await
        .map_err(|e| format!("auth key: {e}"))?
        .flatten();
    handle
        .authenticate_publickey(user, PrivateKeyWithHashAlg::new(Arc::new(key), hash_alg))
        .await
        .map(|result| result.success())
        .map_err(|e| format!("auth key: {e}"))
}

pub(super) async fn close(id: u64) {
    let mut pool = POOL.lock().await;
    pool.by_key.retain(|_, v| *v != id);
    pool.sessions.remove(&id);
}

pub(super) fn block<F, T>(f: F) -> T
where
    F: std::future::Future<Output = T>,
{
    rt().block_on(f)
}
