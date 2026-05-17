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
    name: Vec<u8>,
    path: Vec<u8>,
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
        put_i64(&mut buf, 0); // size: parity with the Dart walker
        put_i64(&mut buf, 0); // modifiedMs: parity with the Dart walker
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
                    name: os_bytes(os_name),
                    path: os_bytes(dirent.path().as_os_str()),
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

#[no_mangle]
pub extern "C" fn waydir_core_abi() -> u32 {
    1
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}
