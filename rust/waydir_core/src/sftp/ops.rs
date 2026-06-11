use std::collections::HashMap;
use std::ffi::{c_char, CStr};
use std::ptr;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

use once_cell::sync::Lazy;
use russh_sftp::client::fs::File as SftpFile;
use russh_sftp::protocol::{FileType, OpenFlags};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::Mutex as TokioMutex;

use super::auth::AuthKind;
use super::session::{self, SftpOpenStatus};
use crate::codec::{finish_buffer, put_record, put_u32};

static WRITERS: Lazy<TokioMutex<HashMap<u64, Arc<TokioMutex<SftpFile>>>>> =
    Lazy::new(|| TokioMutex::new(HashMap::new()));
static READERS: Lazy<TokioMutex<HashMap<u64, Arc<TokioMutex<SftpFile>>>>> =
    Lazy::new(|| TokioMutex::new(HashMap::new()));
static NEXT_WRITER: AtomicU64 = AtomicU64::new(1);
static NEXT_READER: AtomicU64 = AtomicU64::new(1);

fn c_str(p: *const c_char) -> Option<String> {
    if p.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(p).to_str().ok().map(|s| s.to_owned()) }
}

fn err_string(s: String) -> *mut c_char {
    let cs = std::ffi::CString::new(s).unwrap_or_else(|_| std::ffi::CString::new("error").unwrap());
    cs.into_raw()
}

/// Zwalnia string zwrócony przez `waydir_sftp_*`.
/// # Safety
/// `ptr` musi pochodzić z funkcji SFTP tego modułu i być zwolniony dokładnie raz.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_free_cstr(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    drop(std::ffi::CString::from_raw(ptr));
}

/// Otwiera sesję SFTP.
/// `auth_kind`: 0=auto (klucze z ~/.ssh), 1=password, 2=key
/// Zwraca: null gdy ok lub auth_required (status w `out_status`),
///         w przeciwnym razie wskaźnik do komunikatu błędu (zwolnić przez `waydir_sftp_free_cstr`).
/// `out_session_id` zostaje ustawione tylko gdy status == Ok.
///
/// # Safety
/// Wszystkie wskaźniki C-stringów muszą być NUL-terminated lub null;
/// `out_status`/`out_session_id` muszą być writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_session_open(
    host: *const c_char,
    port: u16,
    user: *const c_char,
    auth_kind: u32,
    password: *const c_char,
    key_path: *const c_char,
    passphrase: *const c_char,
    out_status: *mut u32,
    out_session_id: *mut u64,
) -> *mut c_char {
    if out_status.is_null() || out_session_id.is_null() {
        return err_string("null out param".into());
    }
    let host = match c_str(host) {
        Some(s) if !s.is_empty() => s,
        _ => {
            *out_status = SftpOpenStatus::Error as u32;
            return err_string("missing host".into());
        }
    };
    let user = c_str(user).unwrap_or_default();
    let auth = AuthKind::from_ffi(
        auth_kind,
        c_str(password),
        c_str(key_path),
        c_str(passphrase),
    );

    let result = session::block(async { session::open(host, port, user, auth).await });
    match result {
        Ok((status, id, msg)) => {
            *out_status = status as u32;
            *out_session_id = id;
            if matches!(status, SftpOpenStatus::Error) && !msg.is_empty() {
                return err_string(msg);
            }
            ptr::null_mut()
        }
        Err(e) => {
            *out_status = SftpOpenStatus::Error as u32;
            err_string(e)
        }
    }
}

/// # Safety: zamyka sesję; `id` musi pochodzić z `waydir_sftp_session_open`.
#[no_mangle]
pub extern "C" fn waydir_sftp_session_close(id: u64) {
    session::block(async {
        session::close(id).await;
    });
}

#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_realpath(session_id: u64, path: *const c_char) -> *mut c_char {
    let path = match c_str(path) {
        Some(p) => p,
        None => return std::ptr::null_mut(),
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        client
            .sftp
            .canonicalize(&path)
            .await
            .map_err(|e| format!("realpath: {e}"))
    });
    match result {
        Ok(path) => err_string(path),
        Err(_) => std::ptr::null_mut(),
    }
}

fn mtime_ms_from(attr: &russh_sftp::protocol::FileAttributes) -> i64 {
    attr.mtime.map(|s| (s as i64) * 1000).unwrap_or(0)
}

fn is_dir_from(attr: &russh_sftp::protocol::FileAttributes) -> bool {
    matches!(attr.file_type(), FileType::Dir)
}

/// Listing pojedynczego katalogu. Zwraca codec buffer (jak `waydir_list`)
/// lub null gdy błąd.
///
/// # Safety
/// `path` musi być NUL-terminated, `out_len` writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_list(
    session_id: u64,
    path: *const c_char,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let path_str = match c_str(path) {
        Some(p) => p,
        None => return std::ptr::null_mut(),
    };
    let path_owned = path_str.clone();
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let entries = client
            .sftp
            .read_dir(&path_owned)
            .await
            .map_err(|e| format!("read_dir: {e}"))?;
        Ok::<Vec<(String, russh_sftp::protocol::FileAttributes)>, String>(
            entries
                .into_iter()
                .map(|de| (de.file_name(), de.metadata()))
                .collect(),
        )
    });

    let entries = match result {
        Ok(e) => e,
        Err(_) => return std::ptr::null_mut(),
    };

    let normalized = path_with_trailing_slash(if path_str.is_empty() {
        "/"
    } else {
        path_str.as_str()
    });
    // count + records
    let count = entries.len();
    let mut chunks: Vec<Vec<u8>> = Vec::with_capacity(count);
    let mut sorted = entries;
    sorted.sort_by(|a, b| match (is_dir_from(&a.1), is_dir_from(&b.1)) {
        (true, false) => std::cmp::Ordering::Less,
        (false, true) => std::cmp::Ordering::Greater,
        _ => a.0.to_lowercase().cmp(&b.0.to_lowercase()),
    });
    for (name, attr) in &sorted {
        if name == "." || name == ".." {
            continue;
        }
        let mut buf = Vec::with_capacity(64);
        let is_dir = is_dir_from(attr);
        let size = attr.size.unwrap_or(0) as i64;
        let mtime = mtime_ms_from(attr);
        let full_path = format!("{}{}", normalized, name);
        put_record(
            &mut buf,
            is_dir,
            size,
            mtime,
            0,
            attr.permissions.unwrap_or(0),
            attr.uid.unwrap_or(0),
            attr.gid.unwrap_or(0),
            name.as_bytes(),
            full_path.as_bytes(),
        );
        chunks.push(buf);
    }

    // assemble header + entries (skipping skipped "." and ".." in count)
    let real_count = chunks.len();
    let body: usize = chunks.iter().map(|c| c.len()).sum();
    let mut out = Vec::with_capacity(8 + body);
    put_u32(&mut out, crate::codec::MAGIC);
    put_u32(&mut out, real_count as u32);
    for c in chunks {
        out.extend_from_slice(&c);
    }
    finish_buffer(out, out_len)
}

fn path_with_trailing_slash(p: &str) -> String {
    if p.is_empty() {
        return "/".into();
    }
    if p.ends_with('/') {
        p.to_string()
    } else {
        format!("{}/", p)
    }
}

#[repr(C)]
pub struct SftpStat {
    pub exists: i32,
    pub is_dir: i32,
    pub size: i64,
    pub mtime_ms: i64,
}

/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_stat(
    session_id: u64,
    path: *const c_char,
    out: *mut SftpStat,
) -> i32 {
    if out.is_null() {
        return -1;
    }
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        match client.sftp.metadata(&path).await {
            Ok(meta) => Ok(Some((
                is_dir_from(&meta),
                meta.size.unwrap_or(0),
                mtime_ms_from(&meta),
            ))),
            Err(_) => Ok(None),
        }
    });
    match result {
        Ok(Some((is_dir, size, mtime_ms))) => {
            *out = SftpStat {
                exists: 1,
                is_dir: if is_dir { 1 } else { 0 },
                size: size as i64,
                mtime_ms,
            };
            0
        }
        Ok(None) => {
            *out = SftpStat {
                exists: 0,
                is_dir: 0,
                size: 0,
                mtime_ms: 0,
            };
            0
        }
        Err(_) => -1,
    }
}

/// Czyta plik (cały bądź zakres) i zwraca bufor bajtów.
/// `start < 0` lub `len < 0` → cały plik.
///
/// # Safety: standardowe wymagania FFI.
fn sftp_read_bytes(session_id: u64, path: String, start: i64, len: i64) -> Result<Vec<u8>, String> {
    session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let bytes = client
            .sftp
            .read(&path)
            .await
            .map_err(|e| format!("read: {e}"))?;
        let s = if start > 0 { start as usize } else { 0 };
        let end = if len > 0 {
            (s + len as usize).min(bytes.len())
        } else {
            bytes.len()
        };
        if s >= bytes.len() {
            return Ok::<Vec<u8>, String>(Vec::new());
        }
        Ok(bytes[s..end].to_vec())
    })
}

#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_read(
    session_id: u64,
    path: *const c_char,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let path = match c_str(path) {
        Some(p) => p,
        None => return std::ptr::null_mut(),
    };
    let bytes = match sftp_read_bytes(session_id, path, -1, -1) {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };
    finish_buffer(bytes, out_len)
}

#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_read_range(
    session_id: u64,
    path: *const c_char,
    start: i64,
    len: i64,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let path = match c_str(path) {
        Some(p) => p,
        None => return std::ptr::null_mut(),
    };
    let bytes = match sftp_read_bytes(session_id, path, start, len) {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };
    finish_buffer(bytes, out_len)
}

/// Zapisuje bajty do pliku (overwrite). Tworzy plik gdy nie istnieje.
///
/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_write(
    session_id: u64,
    path: *const c_char,
    data: *const u8,
    len: usize,
) -> i32 {
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    if data.is_null() && len > 0 {
        return -1;
    }
    let slice = if len == 0 {
        &[][..]
    } else {
        std::slice::from_raw_parts(data, len)
    };
    let owned = slice.to_vec();
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let mut file = client
            .sftp
            .create(&path)
            .await
            .map_err(|e| format!("create: {e}"))?;
        file.write_all(&owned)
            .await
            .map_err(|e| format!("write: {e}"))?;
        file.shutdown().await.map_err(|e| format!("close: {e}"))
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_write_chunk(
    session_id: u64,
    path: *const c_char,
    data: *const u8,
    len: usize,
    append: i32,
) -> i32 {
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    if data.is_null() && len > 0 {
        return -1;
    }
    let slice = if len == 0 {
        &[][..]
    } else {
        std::slice::from_raw_parts(data, len)
    };
    let owned = slice.to_vec();
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let flags = if append != 0 {
            OpenFlags::CREATE | OpenFlags::APPEND | OpenFlags::WRITE
        } else {
            OpenFlags::CREATE | OpenFlags::TRUNCATE | OpenFlags::WRITE
        };
        let mut file = client
            .sftp
            .open_with_flags(&path, flags)
            .await
            .map_err(|e| format!("open: {e}"))?;
        file.write_all(&owned)
            .await
            .map_err(|e| format!("write: {e}"))?;
        file.shutdown().await.map_err(|e| format!("close: {e}"))
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

// ---------------------------------------------------------------------------
// Persistent file handles for streaming uploads/downloads
// ---------------------------------------------------------------------------

/// Otwiera plik do strumieniowego zapisu i zwraca `writer_id`.
/// `append != 0` → CREATE | APPEND | WRITE, w przeciwnym razie
/// CREATE | TRUNCATE | WRITE. Plik pozostaje otwarty do czasu
/// `waydir_sftp_writer_close`.
///
/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_open_writer(
    session_id: u64,
    path: *const c_char,
    append: i32,
    out_writer_id: *mut u64,
) -> i32 {
    if out_writer_id.is_null() {
        return -1;
    }
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    let flags = if append != 0 {
        OpenFlags::CREATE | OpenFlags::APPEND | OpenFlags::WRITE
    } else {
        OpenFlags::CREATE | OpenFlags::TRUNCATE | OpenFlags::WRITE
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let file = client
            .sftp
            .open_with_flags(&path, flags)
            .await
            .map_err(|e| format!("open: {e}"))?;
        let id = NEXT_WRITER.fetch_add(1, Ordering::Relaxed);
        WRITERS
            .lock()
            .await
            .insert(id, Arc::new(TokioMutex::new(file)));
        Ok::<u64, String>(id)
    });
    match result {
        Ok(id) => {
            *out_writer_id = id;
            0
        }
        Err(_) => -1,
    }
}

/// Zapisuje kolejną porcję bajtów do otwartego writera.
///
/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_writer_write(
    writer_id: u64,
    data: *const u8,
    len: usize,
) -> i32 {
    if data.is_null() && len > 0 {
        return -1;
    }
    let slice = if len == 0 {
        &[][..]
    } else {
        std::slice::from_raw_parts(data, len)
    };
    let owned = slice.to_vec();
    let result = session::block(async move {
        let writer = {
            let map = WRITERS.lock().await;
            map.get(&writer_id).cloned()
        };
        let writer = match writer {
            Some(w) => w,
            None => return Err("no writer".to_string()),
        };
        let mut file = writer.lock().await;
        file.write_all(&owned)
            .await
            .map_err(|e| format!("write: {e}"))
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

/// Domyka writer (flush + zamknięcie kanału pliku) i zwalnia uchwyt.
#[no_mangle]
pub extern "C" fn waydir_sftp_writer_close(writer_id: u64) -> i32 {
    let result = session::block(async move {
        let writer = {
            let mut map = WRITERS.lock().await;
            map.remove(&writer_id)
        };
        if let Some(w) = writer {
            let mut file = w.lock().await;
            file.shutdown()
                .await
                .map_err(|e| format!("shutdown: {e}"))?;
        }
        Ok::<(), String>(())
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

/// Otwiera plik do strumieniowego odczytu sekwencyjnego.
/// Zwraca 0 i wypełnia `out_reader_id` + `out_size`; -1 gdy błąd.
///
/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_open_reader(
    session_id: u64,
    path: *const c_char,
    out_reader_id: *mut u64,
    out_size: *mut i64,
) -> i32 {
    if out_reader_id.is_null() || out_size.is_null() {
        return -1;
    }
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        let meta = client
            .sftp
            .metadata(&path)
            .await
            .map_err(|e| format!("metadata: {e}"))?;
        let size = meta.size.unwrap_or(0) as i64;
        let file = client
            .sftp
            .open_with_flags(&path, OpenFlags::READ)
            .await
            .map_err(|e| format!("open: {e}"))?;
        let id = NEXT_READER.fetch_add(1, Ordering::Relaxed);
        READERS
            .lock()
            .await
            .insert(id, Arc::new(TokioMutex::new(file)));
        Ok::<(u64, i64), String>((id, size))
    });
    match result {
        Ok((id, size)) => {
            *out_reader_id = id;
            *out_size = size;
            0
        }
        Err(_) => -1,
    }
}

/// Czyta sekwencyjnie do `max_len` bajtów z otwartego readera.
/// Zwraca bufor (zwolnić przez `waydir_free`), `out_len` = liczba odczytanych.
/// `out_len == 0` przy zwróconym non-null oznacza EOF.
///
/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_reader_read(
    reader_id: u64,
    max_len: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let result = session::block(async move {
        let reader = {
            let map = READERS.lock().await;
            map.get(&reader_id).cloned()
        };
        let reader = match reader {
            Some(r) => r,
            None => return Err("no reader".to_string()),
        };
        let mut file = reader.lock().await;
        let mut buf = vec![0u8; max_len];
        let mut total = 0usize;
        while total < max_len {
            let n = file
                .read(&mut buf[total..])
                .await
                .map_err(|e| format!("read: {e}"))?;
            if n == 0 {
                break;
            }
            total += n;
        }
        buf.truncate(total);
        Ok::<Vec<u8>, String>(buf)
    });
    match result {
        Ok(bytes) => finish_buffer(bytes, out_len),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Zamyka reader.
#[no_mangle]
pub extern "C" fn waydir_sftp_reader_close(reader_id: u64) -> i32 {
    session::block(async move {
        let _ = READERS.lock().await.remove(&reader_id);
    });
    0
}

/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_mkdir(
    session_id: u64,
    path: *const c_char,
    recursive: i32,
) -> i32 {
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        if recursive != 0 {
            let mut current = String::new();
            for part in path.split('/').filter(|s| !s.is_empty()) {
                current.push('/');
                current.push_str(part);
                let _ = client.sftp.create_dir(&current).await;
            }
            Ok(())
        } else {
            client
                .sftp
                .create_dir(&path)
                .await
                .map_err(|e| format!("mkdir: {e}"))
        }
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_remove(
    session_id: u64,
    path: *const c_char,
    recursive: i32,
) -> i32 {
    let path = match c_str(path) {
        Some(p) => p,
        None => return -1,
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        remove_entry(&client.sftp, &path, recursive != 0).await
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}

async fn remove_entry(
    sftp: &russh_sftp::client::SftpSession,
    path: &str,
    recursive: bool,
) -> Result<(), String> {
    match sftp.metadata(path).await {
        Ok(meta) if is_dir_from(&meta) => {
            if !recursive {
                return sftp
                    .remove_dir(path)
                    .await
                    .map_err(|e| format!("rmdir: {e}"));
            }
            let entries = sftp
                .read_dir(path)
                .await
                .map_err(|e| format!("read_dir: {e}"))?;
            for de in entries {
                let name = de.file_name();
                if name == "." || name == ".." {
                    continue;
                }
                let child = format!("{}/{}", path.trim_end_matches('/'), name);
                Box::pin(remove_entry(sftp, &child, true)).await?;
            }
            sftp.remove_dir(path)
                .await
                .map_err(|e| format!("rmdir: {e}"))
        }
        Ok(_) => sftp.remove_file(path).await.map_err(|e| format!("rm: {e}")),
        Err(e) => Err(format!("stat: {e}")),
    }
}

/// # Safety: standardowe wymagania FFI.
#[no_mangle]
pub unsafe extern "C" fn waydir_sftp_rename(
    session_id: u64,
    from: *const c_char,
    to: *const c_char,
) -> i32 {
    let from = match c_str(from) {
        Some(p) => p,
        None => return -1,
    };
    let to = match c_str(to) {
        Some(p) => p,
        None => return -1,
    };
    let result = session::block(async move {
        let client = match session::get(session_id).await {
            Some(c) => c,
            None => return Err("no session".to_string()),
        };
        let client = client.lock().await;
        client
            .sftp
            .rename(&from, &to)
            .await
            .map_err(|e| format!("rename: {e}"))
    });
    if result.is_ok() {
        0
    } else {
        -1
    }
}
