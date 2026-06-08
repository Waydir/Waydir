use std::collections::HashMap;
use std::ffi::{c_char, CStr};
use std::io::{Read, Write};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::thread::JoinHandle;

use once_cell::sync::Lazy;
use portable_pty::{native_pty_system, Child, CommandBuilder, MasterPty, PtySize};

struct PtySession {
    master: Box<dyn MasterPty + Send>,
    writer: Box<dyn Write + Send>,
    child: Box<dyn Child + Send + Sync>,
    buffer: Arc<Mutex<Vec<u8>>>,
    alive: Arc<AtomicBool>,
    reader: Option<JoinHandle<()>>,
}

static SESSIONS: Lazy<Mutex<HashMap<u64, PtySession>>> = Lazy::new(|| Mutex::new(HashMap::new()));
static NEXT_ID: AtomicU64 = AtomicU64::new(1);

fn cstr(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .ok()
        .map(|s| s.to_owned())
}

fn default_shell() -> String {
    if cfg!(windows) {
        std::env::var("ComSpec").unwrap_or_else(|_| "cmd.exe".into())
    } else {
        std::env::var("SHELL").unwrap_or_else(|_| "/bin/bash".into())
    }
}

/// Spawns a shell attached to a pseudo-terminal and starts a reader thread.
/// Returns a session id, or 0 on failure.
///
/// `args` is an optional newline-separated argument list passed to `shell`;
/// empty or null spawns the program with no arguments.
///
/// # Safety
/// `shell`, `cwd` and `args` must be valid NUL-terminated C strings or null.
#[no_mangle]
pub unsafe extern "C" fn waydir_pty_open(
    shell: *const c_char,
    cwd: *const c_char,
    args: *const c_char,
    cols: u16,
    rows: u16,
) -> u64 {
    let shell = cstr(shell)
        .filter(|s| !s.is_empty())
        .unwrap_or_else(default_shell);
    let cwd = cstr(cwd).filter(|s| !s.is_empty());
    let args: Vec<String> = cstr(args)
        .filter(|s| !s.is_empty())
        .map(|s| s.split('\n').map(|a| a.to_owned()).collect())
        .unwrap_or_default();

    let pty_system = native_pty_system();
    let size = PtySize {
        rows: if rows == 0 { 24 } else { rows },
        cols: if cols == 0 { 80 } else { cols },
        pixel_width: 0,
        pixel_height: 0,
    };
    let pair = match pty_system.openpty(size) {
        Ok(p) => p,
        Err(_) => return 0,
    };

    let mut cmd = CommandBuilder::new(&shell);
    for arg in &args {
        cmd.arg(arg);
    }
    if let Some(dir) = &cwd {
        cmd.cwd(dir);
    }
    cmd.env("TERM", "xterm-256color");

    let child = match pair.slave.spawn_command(cmd) {
        Ok(c) => c,
        Err(_) => return 0,
    };
    drop(pair.slave);

    let reader = match pair.master.try_clone_reader() {
        Ok(r) => r,
        Err(_) => return 0,
    };
    let writer = match pair.master.take_writer() {
        Ok(w) => w,
        Err(_) => return 0,
    };

    let buffer = Arc::new(Mutex::new(Vec::<u8>::new()));
    let alive = Arc::new(AtomicBool::new(true));

    let t_buffer = Arc::clone(&buffer);
    let t_alive = Arc::clone(&alive);
    let handle = std::thread::Builder::new()
        .name("waydir-pty".into())
        .spawn(move || {
            let mut reader = reader;
            let mut chunk = [0u8; 8192];
            loop {
                match reader.read(&mut chunk) {
                    Ok(0) | Err(_) => break,
                    Ok(n) => {
                        if let Ok(mut buf) = t_buffer.lock() {
                            buf.extend_from_slice(&chunk[..n]);
                        }
                    }
                }
            }
            t_alive.store(false, Ordering::Release);
        })
        .ok();

    let id = NEXT_ID.fetch_add(1, Ordering::Relaxed);
    if let Ok(mut map) = SESSIONS.lock() {
        map.insert(
            id,
            PtySession {
                master: pair.master,
                writer,
                child,
                buffer,
                alive,
                reader: handle,
            },
        );
        id
    } else {
        0
    }
}

/// Drains buffered output from the shell. Returns a newly allocated buffer
/// (free with `waydir_free`) and writes its length to `out_len`, or null if
/// there is nothing pending.
///
/// # Safety
/// `out_len` must be a writable pointer.
#[no_mangle]
pub unsafe extern "C" fn waydir_pty_read(id: u64, out_len: *mut usize) -> *mut u8 {
    if !out_len.is_null() {
        *out_len = 0;
    }
    let map = match SESSIONS.lock() {
        Ok(m) => m,
        Err(_) => return std::ptr::null_mut(),
    };
    let session = match map.get(&id) {
        Some(s) => s,
        None => return std::ptr::null_mut(),
    };
    let mut buf = match session.buffer.lock() {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };
    if buf.is_empty() {
        return std::ptr::null_mut();
    }
    let mut bytes = std::mem::take(&mut *buf).into_boxed_slice();
    let len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    if !out_len.is_null() {
        *out_len = len;
    }
    ptr
}

/// Writes `len` bytes of user input to the shell. Returns 0 on success.
///
/// # Safety
/// `data` must point to at least `len` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn waydir_pty_write(id: u64, data: *const u8, len: usize) -> i32 {
    if data.is_null() || len == 0 {
        return 0;
    }
    let bytes = std::slice::from_raw_parts(data, len);
    let mut map = match SESSIONS.lock() {
        Ok(m) => m,
        Err(_) => return -1,
    };
    match map.get_mut(&id) {
        Some(session) => match session
            .writer
            .write_all(bytes)
            .and_then(|_| session.writer.flush())
        {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

/// Resizes the pseudo-terminal. Returns 0 on success.
#[no_mangle]
pub extern "C" fn waydir_pty_resize(id: u64, cols: u16, rows: u16) -> i32 {
    let map = match SESSIONS.lock() {
        Ok(m) => m,
        Err(_) => return -1,
    };
    match map.get(&id) {
        Some(session) => {
            let size = PtySize {
                rows: if rows == 0 { 24 } else { rows },
                cols: if cols == 0 { 80 } else { cols },
                pixel_width: 0,
                pixel_height: 0,
            };
            match session.master.resize(size) {
                Ok(_) => 0,
                Err(_) => -1,
            }
        }
        None => -1,
    }
}

/// Returns 1 while the shell process is running, 0 once it has exited.
#[no_mangle]
pub extern "C" fn waydir_pty_alive(id: u64) -> i32 {
    let map = match SESSIONS.lock() {
        Ok(m) => m,
        Err(_) => return 0,
    };
    match map.get(&id) {
        Some(session) => {
            if session.alive.load(Ordering::Acquire) {
                1
            } else {
                0
            }
        }
        None => 0,
    }
}

/// Kills the shell and releases the session.
#[no_mangle]
pub extern "C" fn waydir_pty_close(id: u64) {
    let session = match SESSIONS.lock() {
        Ok(mut m) => m.remove(&id),
        Err(_) => return,
    };
    if let Some(mut session) = session {
        session.alive.store(false, Ordering::Release);
        let _ = session.child.kill();
        // Dropping master/writer closes the pty fds, so the reader thread sees
        // EOF and winds down. Detach rather than join to avoid blocking.
        drop(session.writer);
        drop(session.master);
        drop(session.reader.take());
    }
}
