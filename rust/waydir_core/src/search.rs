use std::ffi::{c_char, CStr};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::thread::JoinHandle;

use ignore::WalkState;

use crate::codec::{assemble, finish_buffer, put_record, put_u32, MAGIC};
use crate::util::os_bytes;
use crate::walker::{apply_search_filter, base_builder, ChunkSink};

pub struct SearchSession {
    pending: Arc<Mutex<(Vec<u8>, usize)>>,
    scanned: Arc<AtomicUsize>,
    cancelled: Arc<AtomicBool>,
    finished: Arc<AtomicBool>,
    handle: Option<JoinHandle<()>>,
}

/// Recursive, case-insensitive substring name search. Returns a heap buffer
/// (FileEntryCodec layout) whose length is written to `out_len`. The caller
/// must release it via `waydir_free`. Returns null on argument errors.
///
/// # Safety
/// `root` and `query` must be valid NUL-terminated C strings. `out_len`
/// must be a valid writable pointer.
#[no_mangle]
pub unsafe extern "C" fn waydir_search(
    root: *const c_char,
    query: *const c_char,
    include_hidden: bool,
    out_len: *mut usize,
) -> *mut u8 {
    if root.is_null() || query.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let root = match CStr::from_ptr(root).to_str() {
        Ok(s) => s.to_owned(),
        Err(_) => return std::ptr::null_mut(),
    };
    let query = CStr::from_ptr(query).to_string_lossy().to_lowercase();

    let chunks: Mutex<Vec<(Vec<u8>, usize)>> = Mutex::new(Vec::new());

    let mut builder = base_builder(&root);
    apply_search_filter(&mut builder, include_hidden);

    let walker = builder.build_parallel();
    walker.run(|| {
        let mut sink = ChunkSink {
            local: Vec::new(),
            count: 0,
            chunks: &chunks,
        };
        let query = &query;
        Box::new(move |result| {
            let dirent = match result {
                Ok(d) => d,
                Err(_) => return WalkState::Continue,
            };
            if dirent.depth() == 0 {
                return WalkState::Continue;
            }
            let os_name = dirent.file_name();
            let name_lossy = os_name.to_string_lossy().to_lowercase();
            if name_lossy.contains(query.as_str()) {
                let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
                put_record(
                    &mut sink.local,
                    is_dir,
                    0,
                    0,
                    &os_bytes(os_name),
                    &os_bytes(dirent.path().as_os_str()),
                );
                sink.count += 1;
            }
            WalkState::Continue
        })
    });

    let chunks = chunks.into_inner().unwrap();
    let total: usize = chunks.iter().map(|(_, n)| n).sum();
    let ordered: Vec<Vec<u8>> = chunks.into_iter().map(|(b, _)| b).collect();
    finish_buffer(assemble(total, ordered), out_len)
}

/// # Safety
/// `root` and `query` must be valid NUL-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn waydir_search_start(
    root: *const c_char,
    query: *const c_char,
    include_hidden: bool,
) -> *mut SearchSession {
    if root.is_null() || query.is_null() {
        return std::ptr::null_mut();
    }
    let root = match CStr::from_ptr(root).to_str() {
        Ok(s) => s.to_owned(),
        Err(_) => return std::ptr::null_mut(),
    };
    let query = CStr::from_ptr(query).to_string_lossy().to_lowercase();

    let pending: Arc<Mutex<(Vec<u8>, usize)>> = Arc::new(Mutex::new((Vec::new(), 0)));
    let scanned = Arc::new(AtomicUsize::new(0));
    let cancelled = Arc::new(AtomicBool::new(false));
    let finished = Arc::new(AtomicBool::new(false));

    let t_pending = Arc::clone(&pending);
    let t_scanned = Arc::clone(&scanned);
    let t_cancelled = Arc::clone(&cancelled);
    let t_finished = Arc::clone(&finished);

    let handle = std::thread::spawn(move || {
        let mut builder = base_builder(&root);
        apply_search_filter(&mut builder, include_hidden);

        let walker = builder.build_parallel();
        walker.run(|| {
            let pending = Arc::clone(&t_pending);
            let scanned = Arc::clone(&t_scanned);
            let cancelled = Arc::clone(&t_cancelled);
            let query = query.clone();
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
                scanned.fetch_add(1, Ordering::Relaxed);
                let os_name = dirent.file_name();
                let name_lossy = os_name.to_string_lossy().to_lowercase();
                if name_lossy.contains(query.as_str()) {
                    let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
                    let mut g = pending.lock().unwrap();
                    put_record(
                        &mut g.0,
                        is_dir,
                        0,
                        0,
                        &os_bytes(os_name),
                        &os_bytes(dirent.path().as_os_str()),
                    );
                    g.1 += 1;
                }
                WalkState::Continue
            })
        });
        t_finished.store(true, Ordering::Release);
    });

    Box::into_raw(Box::new(SearchSession {
        pending,
        scanned,
        cancelled,
        finished,
        handle: Some(handle),
    }))
}

/// # Safety
/// `session` must come from `waydir_search_start`; out pointers writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_search_poll(
    session: *mut SearchSession,
    out_len: *mut usize,
    out_scanned: *mut usize,
    out_done: *mut i32,
) -> *mut u8 {
    if session.is_null() || out_len.is_null() || out_scanned.is_null() || out_done.is_null() {
        return std::ptr::null_mut();
    }
    let session = &*session;

    let (body, count) = {
        let mut g = session.pending.lock().unwrap();
        let body = std::mem::take(&mut g.0);
        let count = std::mem::replace(&mut g.1, 0);
        (body, count)
    };

    *out_scanned = session.scanned.load(Ordering::Relaxed);
    *out_done = if session.finished.load(Ordering::Acquire) {
        1
    } else {
        0
    };

    if count == 0 {
        *out_len = 0;
        return std::ptr::null_mut();
    }

    let mut buf = Vec::with_capacity(8 + body.len());
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, count as u32);
    buf.extend_from_slice(&body);
    finish_buffer(buf, out_len)
}

/// # Safety
/// `session` must come from `waydir_search_start`.
#[no_mangle]
pub unsafe extern "C" fn waydir_search_cancel(session: *mut SearchSession) {
    if session.is_null() {
        return;
    }
    (*session).cancelled.store(true, Ordering::Relaxed);
}

/// # Safety
/// `session` must come from `waydir_search_start` and be used exactly once.
#[no_mangle]
pub unsafe extern "C" fn waydir_search_free(session: *mut SearchSession) {
    if session.is_null() {
        return;
    }
    let mut session = Box::from_raw(session);
    session.cancelled.store(true, Ordering::Relaxed);
    if let Some(h) = session.handle.take() {
        let _ = h.join();
    }
}
