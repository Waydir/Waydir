// waydir_core: native filesystem helpers exposed over a tiny C ABI.
//
// The first capability is a parallel recursive name search built on the
// `ignore` crate's threaded walker (the engine behind ripgrep). Results are
// serialised into the exact same binary layout Dart's `FileEntryCodec`
// understands (big-endian, magic 'WDIR'), so the Dart side can decode a
// single buffer instead of materialising entries one by one.

use std::ffi::{c_char, CStr, OsStr};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicU64, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::thread::JoinHandle;

use ignore::{WalkBuilder, WalkState};
#[cfg(target_os = "windows")]
use std::collections::HashMap;
#[cfg(target_os = "windows")]
use std::sync::OnceLock;

#[cfg(unix)]
fn os_bytes(s: &OsStr) -> Vec<u8> {
    use std::os::unix::ffi::OsStrExt;
    s.as_bytes().to_vec()
}

#[cfg(not(unix))]
fn os_bytes(s: &OsStr) -> Vec<u8> {
    s.to_string_lossy().into_owned().into_bytes()
}

const MAGIC: u32 = 0x5744_4952; // 'WDIR'

const EXCLUDED: &[&str] = &[
    ".git",
    "node_modules",
    ".cache",
    ".venv",
    "__pycache__",
    "target",
    "build",
    ".gradle",
    ".idea",
];

struct Entry {
    is_dir: bool,
    size: i64,
    mtime_ms: i64,
    name: Vec<u8>,
    path: Vec<u8>,
    disk_path: std::path::PathBuf,
}

struct ChunkSink<'a> {
    local: Vec<u8>,
    count: usize,
    chunks: &'a Mutex<Vec<(Vec<u8>, usize)>>,
}

impl Drop for ChunkSink<'_> {
    fn drop(&mut self) {
        if self.count == 0 {
            return;
        }
        let buf = std::mem::take(&mut self.local);
        self.chunks.lock().unwrap().push((buf, self.count));
    }
}

struct EntrySink<'a> {
    local: Vec<Entry>,
    buckets: &'a Mutex<Vec<Vec<Entry>>>,
}

impl Drop for EntrySink<'_> {
    fn drop(&mut self) {
        if self.local.is_empty() {
            return;
        }
        let v = std::mem::take(&mut self.local);
        self.buckets.lock().unwrap().push(v);
    }
}

#[cfg(unix)]
fn path_depth(path: &[u8]) -> usize {
    path.iter().filter(|&&b| b == b'/').count()
}

#[cfg(not(unix))]
fn path_depth(path: &[u8]) -> usize {
    path.iter().filter(|&&b| b == b'/' || b == b'\\').count()
}

fn put_u32(buf: &mut Vec<u8>, v: u32) {
    buf.extend_from_slice(&v.to_be_bytes());
}

fn put_i64(buf: &mut Vec<u8>, v: i64) {
    buf.extend_from_slice(&v.to_be_bytes());
}

#[cfg(target_os = "windows")]
fn put_u64(buf: &mut Vec<u8>, v: u64) {
    buf.extend_from_slice(&v.to_be_bytes());
}

fn put_record(buf: &mut Vec<u8>, is_dir: bool, size: i64, mtime_ms: i64, name: &[u8], path: &[u8]) {
    buf.push(if is_dir { 0 } else { 1 });
    put_i64(buf, size);
    put_i64(buf, mtime_ms);
    put_u32(buf, name.len() as u32);
    put_u32(buf, path.len() as u32);
    buf.extend_from_slice(name);
    buf.extend_from_slice(path);
}

fn serialise(entries: &[Entry]) -> Vec<u8> {
    let body: usize = entries
        .iter()
        .map(|e| 25 + e.name.len() + e.path.len())
        .sum();
    let mut buf = Vec::with_capacity(8 + body);
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, entries.len() as u32);
    for e in entries {
        put_record(&mut buf, e.is_dir, e.size, e.mtime_ms, &e.name, &e.path);
    }
    buf
}

fn assemble(count: usize, chunks: Vec<Vec<u8>>) -> Vec<u8> {
    let body: usize = chunks.iter().map(|c| c.len()).sum();
    let mut buf = Vec::with_capacity(8 + body);
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, count as u32);
    for c in chunks {
        buf.extend_from_slice(&c);
    }
    buf
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

    let mut builder = WalkBuilder::new(&root);
    builder
        .hidden(!include_hidden)
        .parents(false)
        .ignore(false)
        .git_ignore(false)
        .git_global(false)
        .git_exclude(false)
        .follow_links(false)
        .threads(num_cpus());

    builder.filter_entry(|dirent| {
        if dirent.depth() == 0 {
            return true;
        }
        let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
        if !is_dir {
            return true;
        }
        let name = dirent.file_name().to_string_lossy();
        !EXCLUDED.iter().any(|x| *x == name)
    });

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
    let mut bytes = assemble(total, ordered).into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

/// Releases a buffer returned by `waydir_search`.
///
/// # Safety
/// `ptr`/`len` must come from a previous `waydir_search` call and be used
/// exactly once.
#[no_mangle]
pub unsafe extern "C" fn waydir_free(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    drop(Vec::from_raw_parts(ptr, len, len));
}

#[no_mangle]
pub unsafe extern "C" fn waydir_trash(
    paths: *const *const c_char,
    count: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if paths.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }

    let mut out = Vec::new();
    for i in 0..count {
        let ptr = *paths.add(i);
        if ptr.is_null() {
            continue;
        }
        let c_path = CStr::from_ptr(ptr);
        let path = c_path.to_string_lossy().into_owned();
        let fs_path = PathBuf::from(&path);
        if let Err(err) = trash::delete(&fs_path) {
            let path_bytes = path.as_bytes();
            let msg = err.to_string();
            let msg_bytes = msg.as_bytes();
            put_u32(&mut out, path_bytes.len() as u32);
            put_u32(&mut out, msg_bytes.len() as u32);
            out.extend_from_slice(path_bytes);
            out.extend_from_slice(msg_bytes);
        }
    }

    if out.is_empty() {
        *out_len = 0;
        return std::ptr::null_mut();
    }

    let mut bytes = out.into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[cfg(target_os = "windows")]
static TRASH_ITEMS: OnceLock<Mutex<HashMap<String, trash::TrashItem>>> = OnceLock::new();

#[cfg(target_os = "windows")]
fn trash_items() -> &'static Mutex<HashMap<String, trash::TrashItem>> {
    TRASH_ITEMS.get_or_init(|| Mutex::new(HashMap::new()))
}

#[cfg(target_os = "windows")]
fn put_bytes(buf: &mut Vec<u8>, bytes: &[u8]) {
    put_u32(buf, bytes.len() as u32);
    buf.extend_from_slice(bytes);
}

#[cfg(target_os = "windows")]
fn trash_id(item: &trash::TrashItem) -> String {
    item.id.to_string_lossy().into_owned()
}

#[cfg(target_os = "windows")]
fn encode_trash_error(id: &str, err: impl std::fmt::Display, out: &mut Vec<u8>) {
    let id_bytes = id.as_bytes();
    let msg = err.to_string();
    let msg_bytes = msg.as_bytes();
    put_u32(out, id_bytes.len() as u32);
    put_u32(out, msg_bytes.len() as u32);
    out.extend_from_slice(id_bytes);
    out.extend_from_slice(msg_bytes);
}

#[cfg(target_os = "windows")]
fn take_trash_items(ids: *const *const c_char, count: usize, out: &mut Vec<u8>) -> Vec<trash::TrashItem> {
    let mut cache = trash_items().lock().unwrap();
    let mut items = Vec::new();
    for i in 0..count {
        let ptr = unsafe { *ids.add(i) };
        if ptr.is_null() {
            continue;
        }
        let id = unsafe { CStr::from_ptr(ptr) }.to_string_lossy().into_owned();
        match cache.remove(&id) {
            Some(item) => items.push(item),
            None => encode_trash_error(&id, "Trash item is no longer available", out),
        }
    }
    items
}

#[cfg(target_os = "windows")]
fn finish_optional_buffer(mut out: Vec<u8>, out_len: *mut usize) -> *mut u8 {
    if out.is_empty() {
        unsafe {
            *out_len = 0;
        }
        return std::ptr::null_mut();
    }
    let mut bytes = out.into_boxed_slice();
    unsafe {
        *out_len = bytes.len();
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[cfg(target_os = "windows")]
fn trash_item_size(item: &trash::TrashItem) -> (u64, bool) {
    match trash::os_limited::metadata(item) {
        Ok(meta) => match meta.size {
            trash::TrashItemSize::Bytes(size) => (size, false),
            trash::TrashItemSize::Entries(entries) => (entries as u64, true),
        },
        Err(_) => (0, false),
    }
}

#[cfg(target_os = "windows")]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_list(out_len: *mut usize) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }

    let items = match trash::os_limited::list() {
        Ok(items) => items,
        Err(_) => {
            *out_len = 0;
            return std::ptr::null_mut();
        }
    };

    let mut cache = HashMap::with_capacity(items.len());
    let mut body = Vec::new();
    for item in items {
        let id = trash_id(&item);
        let name = item.name.to_string_lossy().into_owned();
        let original_path = item.original_path().to_string_lossy().into_owned();
        let deleted_at_ms = item.time_deleted.saturating_mul(1000);
        let (size, is_dir) = trash_item_size(&item);

        put_bytes(&mut body, id.as_bytes());
        put_bytes(&mut body, name.as_bytes());
        put_bytes(&mut body, original_path.as_bytes());
        put_u64(&mut body, deleted_at_ms as u64);
        put_u64(&mut body, size);
        body.push(if is_dir { 1 } else { 0 });

        cache.insert(id, item);
    }

    let count = cache.len();
    *trash_items().lock().unwrap() = cache;

    let mut buf = Vec::with_capacity(4 + body.len());
    put_u32(&mut buf, count as u32);
    buf.extend_from_slice(&body);
    let mut bytes = buf.into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[cfg(not(target_os = "windows"))]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_list(out_len: *mut usize) -> *mut u8 {
    if !out_len.is_null() {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

#[cfg(target_os = "windows")]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_restore(
    ids: *const *const c_char,
    count: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if ids.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let mut out = Vec::new();
    let items = take_trash_items(ids, count, &mut out);
    if let Err(err) = trash::os_limited::restore_all(items) {
        encode_trash_error("", err, &mut out);
    }
    finish_optional_buffer(out, out_len)
}

#[cfg(not(target_os = "windows"))]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_restore(
    _ids: *const *const c_char,
    _count: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if !out_len.is_null() {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

#[cfg(target_os = "windows")]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_purge(
    ids: *const *const c_char,
    count: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if ids.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let mut out = Vec::new();
    let items = take_trash_items(ids, count, &mut out);
    if let Err(err) = trash::os_limited::purge_all(&items) {
        encode_trash_error("", err, &mut out);
    }
    finish_optional_buffer(out, out_len)
}

#[cfg(not(target_os = "windows"))]
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_purge(
    _ids: *const *const c_char,
    _count: usize,
    out_len: *mut usize,
) -> *mut u8 {
    if !out_len.is_null() {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

pub struct SearchSession {
    pending: Arc<Mutex<(Vec<u8>, usize)>>,
    scanned: Arc<AtomicUsize>,
    cancelled: Arc<AtomicBool>,
    finished: Arc<AtomicBool>,
    handle: Option<JoinHandle<()>>,
}

pub struct FolderScanSession {
    bytes: Arc<AtomicU64>,
    items: Arc<AtomicUsize>,
    cancelled: Arc<AtomicBool>,
    finished: Arc<AtomicBool>,
    handle: Option<JoinHandle<()>>,
}

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
        let mut builder = WalkBuilder::new(&root);
        builder
            .hidden(!include_hidden)
            .parents(false)
            .ignore(false)
            .git_ignore(false)
            .git_global(false)
            .git_exclude(false)
            .follow_links(false)
            .threads(num_cpus());

        builder.filter_entry(|dirent| {
            if dirent.depth() == 0 {
                return true;
            }
            let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
            if !is_dir {
                return true;
            }
            let name = dirent.file_name().to_string_lossy();
            !EXCLUDED.iter().any(|x| *x == name)
        });

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

    let session = Box::new(SearchSession {
        pending,
        scanned,
        cancelled,
        finished,
        handle: Some(handle),
    });
    Box::into_raw(session)
}

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
    let mut bytes = buf.into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[no_mangle]
pub unsafe extern "C" fn waydir_search_cancel(session: *mut SearchSession) {
    if session.is_null() {
        return;
    }
    (*session).cancelled.store(true, Ordering::Relaxed);
}

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
        let mut builder = WalkBuilder::new(&root);
        builder
            .hidden(false)
            .parents(false)
            .ignore(false)
            .git_ignore(false)
            .git_global(false)
            .git_exclude(false)
            .follow_links(false)
            .threads(num_cpus());

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

    let session = Box::new(FolderScanSession {
        bytes,
        items,
        cancelled,
        finished,
        handle: Some(handle),
    });
    Box::into_raw(session)
}

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

#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_cancel(session: *mut FolderScanSession) {
    if session.is_null() {
        return;
    }
    (*session).cancelled.store(true, Ordering::Relaxed);
}

#[no_mangle]
pub unsafe extern "C" fn waydir_folder_scan_free(session: *mut FolderScanSession) {
    if session.is_null() {
        return;
    }
    let mut session = Box::from_raw(session);
    session.cancelled.store(true, Ordering::Relaxed);
    // Detach the worker instead of joining: it owns its own Arc clones, so
    // dropping the handle is safe and lets it wind down on its own once the
    // cancel flag is observed. Joining here would block the caller (the UI
    // thread) until a potentially deep tree walk unwinds, freezing the app.
    drop(session.handle.take());
}

fn mtime_ms(meta: &std::fs::Metadata) -> i64 {
    match meta.modified() {
        Ok(t) => match t.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => d.as_millis() as i64,
            Err(e) => -(e.duration().as_millis() as i64),
        },
        Err(_) => 0,
    }
}

/// Lists a single directory (non-recursive). `with_stat` controls whether
/// size/mtime are resolved (a parallel stat pass) or left zero for a
/// name-only fast path. Output is sorted folders-first then case-insensitive
/// by name, matching the Dart lister. Same buffer contract as
/// `waydir_search`.
///
/// # Safety
/// `path` must be a valid NUL-terminated C string; `out_len` writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_list(
    path: *const c_char,
    with_stat: bool,
    out_len: *mut usize,
) -> *mut u8 {
    if path.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let dir = match CStr::from_ptr(path).to_str() {
        Ok(s) => s.to_owned(),
        Err(_) => return std::ptr::null_mut(),
    };

    let rd = match std::fs::read_dir(&dir) {
        Ok(r) => r,
        Err(_) => return std::ptr::null_mut(),
    };

    let mut entries: Vec<Entry> = Vec::new();
    for de in rd.flatten() {
        let ft = de.file_type();
        let is_dir = match &ft {
            Ok(t) if t.is_symlink() => std::fs::metadata(de.path())
                .map(|m| m.is_dir())
                .unwrap_or(false),
            Ok(t) => t.is_dir(),
            Err(_) => false,
        };
        let dp = de.path();
        entries.push(Entry {
            is_dir,
            size: 0,
            mtime_ms: 0,
            name: os_bytes(de.file_name().as_os_str()),
            path: os_bytes(dp.as_os_str()),
            disk_path: dp,
        });
    }

    if with_stat {
        let threads = num_cpus().min(entries.len().max(1));
        if threads > 1 {
            let chunk = entries.len().div_ceil(threads);
            std::thread::scope(|s| {
                for part in entries.chunks_mut(chunk) {
                    s.spawn(|| {
                        for e in part.iter_mut() {
                            fill_stat(e);
                        }
                    });
                }
            });
        } else {
            for e in entries.iter_mut() {
                fill_stat(e);
            }
        }
    }

    entries.sort_by(|a, b| match (a.is_dir, b.is_dir) {
        (true, false) => std::cmp::Ordering::Less,
        (false, true) => std::cmp::Ordering::Greater,
        _ => {
            let an = String::from_utf8_lossy(&a.name).to_lowercase();
            let bn = String::from_utf8_lossy(&b.name).to_lowercase();
            an.cmp(&bn)
        }
    });

    let mut bytes = serialise(&entries).into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

fn fill_stat(e: &mut Entry) {
    if let Ok(meta) = std::fs::metadata(&e.disk_path) {
        e.size = meta.len() as i64;
        e.mtime_ms = mtime_ms(&meta);
    }
}

/// Recursively enumerates everything under `root` (the root itself is not
/// included). Hidden files are always included and nothing is excluded —
/// this is meant for delete pre-scans. When `postorder` is true the result
/// is ordered deepest-path-first so a caller can unlink children before
/// their parents. Same buffer contract as the other entry points.
///
/// # Safety
/// `root` must be a valid NUL-terminated C string; `out_len` writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_enumerate(
    root: *const c_char,
    postorder: bool,
    out_len: *mut usize,
) -> *mut u8 {
    if root.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    let root = match CStr::from_ptr(root).to_str() {
        Ok(s) => s.to_owned(),
        Err(_) => return std::ptr::null_mut(),
    };

    let buckets: Mutex<Vec<Vec<Entry>>> = Mutex::new(Vec::new());

    let mut builder = WalkBuilder::new(&root);
    builder
        .hidden(false)
        .parents(false)
        .ignore(false)
        .git_ignore(false)
        .git_global(false)
        .git_exclude(false)
        .follow_links(false)
        .threads(num_cpus());

    let walker = builder.build_parallel();
    walker.run(|| {
        let mut sink = EntrySink {
            local: Vec::new(),
            buckets: &buckets,
        };
        Box::new(move |result| {
            let dirent = match result {
                Ok(d) => d,
                Err(_) => return WalkState::Continue,
            };
            if dirent.depth() == 0 {
                return WalkState::Continue;
            }
            let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
            sink.local.push(Entry {
                is_dir,
                size: 0,
                mtime_ms: 0,
                name: os_bytes(dirent.file_name()),
                path: os_bytes(dirent.path().as_os_str()),
                disk_path: std::path::PathBuf::new(),
            });
            WalkState::Continue
        })
    });

    let mut entries: Vec<Entry> = buckets
        .into_inner()
        .unwrap()
        .into_iter()
        .flatten()
        .collect();
    if postorder {
        // Deepest first by component depth, not byte length: byte length
        // can place a parent before its own child and break unlink order.
        entries.sort_by(|a, b| {
            path_depth(&b.path)
                .cmp(&path_depth(&a.path))
                .then_with(|| b.path.cmp(&a.path))
        });
    }

    let mut bytes = serialise(&entries).into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[no_mangle]
pub extern "C" fn waydir_core_abi() -> u32 {
    7
}

#[no_mangle]
pub extern "C" fn waydir_core_version() -> *const c_char {
    concat!(env!("WAYDIR_VERSION"), "\0").as_ptr() as *const c_char
}

#[no_mangle]
pub extern "C" fn waydir_core_git() -> *const c_char {
    concat!(env!("WAYDIR_GIT"), "\0").as_ptr() as *const c_char
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}
