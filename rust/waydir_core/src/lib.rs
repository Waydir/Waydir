// waydir_core: native filesystem helpers exposed over a tiny C ABI.
//
// The first capability is a parallel recursive name search built on the
// `ignore` crate's threaded walker (the engine behind ripgrep). Results are
// serialised into the exact same binary layout Dart's `FileEntryCodec`
// understands (big-endian, magic 'WDIR'), so the Dart side can decode a
// single buffer instead of materialising entries one by one.

use std::ffi::{c_char, CStr, OsStr};
use std::sync::Mutex;

use ignore::{WalkBuilder, WalkState};

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

fn put_u32(buf: &mut Vec<u8>, v: u32) {
    buf.extend_from_slice(&v.to_be_bytes());
}

fn put_i64(buf: &mut Vec<u8>, v: i64) {
    buf.extend_from_slice(&v.to_be_bytes());
}

fn serialise(entries: &[Entry]) -> Vec<u8> {
    let mut buf = Vec::with_capacity(32 + entries.len() * 48);
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, entries.len() as u32);
    for e in entries {
        buf.push(if e.is_dir { 0 } else { 1 });
        put_i64(&mut buf, e.size);
        put_i64(&mut buf, e.mtime_ms);
        put_u32(&mut buf, e.name.len() as u32);
        put_u32(&mut buf, e.path.len() as u32);
        buf.extend_from_slice(&e.name);
        buf.extend_from_slice(&e.path);
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
    let query = CStr::from_ptr(query)
        .to_string_lossy()
        .to_lowercase();

    let collected: Mutex<Vec<Entry>> = Mutex::new(Vec::new());

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
        let collected = &collected;
        let query = &query;
        Box::new(move |result| {
            let dirent = match result {
                Ok(d) => d,
                Err(_) => return WalkState::Continue,
            };
            if dirent.depth() == 0 {
                return WalkState::Continue;
            }
            let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
            let os_name = dirent.file_name();
            let name_lossy = os_name.to_string_lossy().to_lowercase();
            if name_lossy.contains(query.as_str()) {
                let entry = Entry {
                    is_dir,
                    size: 0,
                    mtime_ms: 0,
                    name: os_bytes(os_name),
                    path: os_bytes(dirent.path().as_os_str()),
                    disk_path: std::path::PathBuf::new(),
                };
                collected.lock().unwrap().push(entry);
            }
            WalkState::Continue
        })
    });

    let entries = collected.into_inner().unwrap();
    let mut bytes = serialise(&entries).into_boxed_slice();
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

    let collected: Mutex<Vec<Entry>> = Mutex::new(Vec::new());

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
        let collected = &collected;
        Box::new(move |result| {
            let dirent = match result {
                Ok(d) => d,
                Err(_) => return WalkState::Continue,
            };
            if dirent.depth() == 0 {
                return WalkState::Continue;
            }
            let is_dir = dirent.file_type().map(|t| t.is_dir()).unwrap_or(false);
            collected.lock().unwrap().push(Entry {
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

    let mut entries = collected.into_inner().unwrap();
    if postorder {
        entries.sort_by(|a, b| b.path.len().cmp(&a.path.len()));
    }

    let mut bytes = serialise(&entries).into_boxed_slice();
    *out_len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[no_mangle]
pub extern "C" fn waydir_core_abi() -> u32 {
    3
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}
