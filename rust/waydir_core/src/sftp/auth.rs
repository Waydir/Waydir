use std::path::Path;

use russh::keys::{decode_secret_key, load_secret_key, PrivateKey};

pub(super) enum AuthKind {
    Auto,
    Password(String),
    Key {
        path: String,
        passphrase: Option<String>,
    },
}

impl AuthKind {
    pub fn from_ffi(
        kind: u32,
        password: Option<String>,
        key_path: Option<String>,
        passphrase: Option<String>,
    ) -> Self {
        match kind {
            1 => AuthKind::Password(password.unwrap_or_default()),
            2 => AuthKind::Key {
                path: key_path.unwrap_or_default(),
                passphrase,
            },
            _ => AuthKind::Auto,
        }
    }
}

pub(super) fn discover_default_keys() -> Vec<PrivateKey> {
    let home = match std::env::var("HOME") {
        Ok(h) => h,
        Err(_) => return Vec::new(),
    };
    let candidates = ["id_ed25519", "id_ecdsa", "id_rsa"];
    let mut keys = Vec::new();
    for name in candidates.iter() {
        let p = Path::new(&home).join(".ssh").join(name);
        if !p.exists() {
            continue;
        }
        if let Ok(k) = load_secret_key(&p, None) {
            keys.push(k);
        }
    }
    keys
}

pub(super) fn load_key(path: &str, passphrase: Option<&str>) -> Result<PrivateKey, String> {
    let content = std::fs::read_to_string(path).map_err(|e| format!("read key: {e}"))?;
    decode_secret_key(&content, passphrase).map_err(|e| format!("decode key: {e}"))
}
