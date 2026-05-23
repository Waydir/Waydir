use std::ffi::{c_char, CStr};
use std::sync::atomic::{AtomicBool, AtomicU64, AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread::JoinHandle;

use ignore::WalkState;

use crate::walker::base_builder;

pub struct FolderScanSession {
    bytes: Arc<AtomicU64>,
    items: Arc<AtomicUsize>,
    cancelled: Arc<AtomicBool>,
    finished: Arc<AtomicBool>,
    handle: Option<JoinHandle<()>>,
}

/// # Safety
/// `root` must be a valid NUL-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_start(root: *const c_char) -> *mut FolderScanSession {
    if root.is_null() {
        return std::ptr::null_mut();
    }
    let root = match CStr::from_ptr(root).to_str() {
        Ok(s) => s.to_owned(),
        Err(_) => return std::ptr::null_mut(),
    };

    let bytes = Arc::new(AtomicU64::new(0));
    let items = Arc::new(AtomicUsize::new(0));
    let cancelled = Arc::new(AtomicBool::new(false));
    let finished = Arc::new(AtomicBool::new(false));

    let t_bytes = Arc::clone(&bytes);
    let t_items = Arc::clone(&items);
    let t_cancelled = Arc::clone(&cancelled);
    let t_finished = Arc::clone(&finished);

    let handle = std::thread::spawn(move || {
        let builder = base_builder(&root);
        let walker = builder.build_parallel();
        walker.run(|| {
            let bytes = Arc::clone(&t_bytes);
            let items = Arc::clone(&t_items);
            let cancelled = Arc::clone(&t_cancelled);
            Box::new(move |result| {
                if cancelled.load(Ordering::Relaxed) {
                    return WalkState::Quit;
                }
                let dirent = match result {
                    Ok(d) => d,
                    Err(_) => return WalkState::Continue,
                };
                if dirent.depth() == 0 {
                    return WalkState::Continue;
                }
                items.fetch_add(1, Ordering::Relaxed);
                if dirent.file_type().map(|t| t.is_file()).unwrap_or(false) {
                    if let Ok(meta) = dirent.metadata() {
                        bytes.fetch_add(meta.len(), Ordering::Relaxed);
                    }
                }
                WalkState::Continue
            })
        });
        t_finished.store(true, Ordering::Release);
    });

    Box::into_raw(Box::new(FolderScanSession {
        bytes,
        items,
        cancelled,
        finished,
        handle: Some(handle),
    }))
}

/// # Safety
/// `session` must come from `waydir_folder_scan_start`; out pointers writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_poll(
    session: *mut FolderScanSession,
    out_bytes: *mut u64,
    out_items: *mut usize,
    out_done: *mut i32,
) {
    if session.is_null() || out_bytes.is_null() || out_items.is_null() || out_done.is_null() {
        return;
    }
    let session = &*session;
    *out_bytes = session.bytes.load(Ordering::Relaxed);
    *out_items = session.items.load(Ordering::Relaxed);
    *out_done = if session.finished.load(Ordering::Acquire) {
        1
    } else {
        0
    };
}

/// # Safety
/// `session` must come from `waydir_folder_scan_start`.
#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_cancel(session: *mut FolderScanSession) {
    if session.is_null() {
        return;
    }
    (*session).cancelled.store(true, Ordering::Relaxed);
}

/// # Safety
/// `session` must come from `waydir_folder_scan_start` and be used exactly once.
#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_free(session: *mut FolderScanSession) {
    if session.is_null() {
        return;
    }
    let mut session = Box::from_raw(session);
    session.cancelled.store(true, Ordering::Relaxed);
    // Detach instead of joining: joining would block the caller (UI thread)
    // until a deep tree walk unwinds. The worker owns its own Arc clones, so
    // dropping the handle lets it wind down once it observes the cancel flag.
    drop(session.handle.take());
}
