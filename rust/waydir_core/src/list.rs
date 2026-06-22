use std::ffi::{c_char, CStr};

use crate::codec::{finish_buffer, serialise, Entry};
use crate::util::{mtime_ms, num_cpus, os_bytes};

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
        let is_symlink = ft.as_ref().map(|t| t.is_symlink()).unwrap_or(false);
        let is_dir = match &ft {
            Ok(t) if t.is_symlink() => std::fs::metadata(de.path())
                .map(|m| m.is_dir())
                .unwrap_or(false),
            Ok(t) => t.is_dir(),
            Err(_) => false,
        };
        let dp = de.path();
        let link_target = if is_symlink {
            std::fs::read_link(&dp)
                .map(|t| os_bytes(t.as_os_str()))
                .unwrap_or_default()
        } else {
            Vec::new()
        };
        entries.push(Entry {
            is_dir,
            size: 0,
            mtime_ms: 0,
            created_ms: 0,
            added_ms: 0,
            mode: 0,
            uid: 0,
            gid: 0,
            name: os_bytes(de.file_name().as_os_str()),
            path: os_bytes(dp.as_os_str()),
            disk_path: dp,
            is_symlink,
            link_target,
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

    finish_buffer(serialise(&entries), out_len)
}

fn fill_stat(e: &mut Entry) {
    if let Ok(meta) = std::fs::metadata(&e.disk_path) {
        e.size = meta.len() as i64;
        e.mtime_ms = mtime_ms(&meta);
        e.created_ms = created_ms(&meta);
        e.added_ms = added_ms(&e.disk_path, &meta);
        fill_owner_mode(e, &meta);
    }
}

#[cfg(unix)]
fn created_ms(meta: &std::fs::Metadata) -> i64 {
    use std::os::unix::fs::MetadataExt;
    // Real birth time (statx btime) where the filesystem records it. Some
    // filesystems (older ext4 without crtime, network mounts) have none, so we
    // fall back to ctime to keep the column populated rather than show nothing.
    created_via_btime(meta)
        .unwrap_or_else(|| meta.ctime() * 1000 + (meta.ctime_nsec() / 1_000_000))
}

fn created_via_btime(meta: &std::fs::Metadata) -> Option<i64> {
    use std::time::UNIX_EPOCH;
    meta.created()
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
}

#[cfg(not(unix))]
fn created_ms(meta: &std::fs::Metadata) -> i64 {
    created_via_btime(meta).unwrap_or(0)
}

#[cfg(target_os = "macos")]
fn added_ms(path: &std::path::Path, meta: &std::fs::Metadata) -> i64 {
    read_date_added_xattr(path).unwrap_or_else(|| created_ms(meta))
}

#[cfg(target_os = "macos")]
fn read_date_added_xattr(path: &std::path::Path) -> Option<i64> {
    use std::ffi::{c_char, c_void, CString};
    extern "C" {
        fn getxattr(
            path: *const c_char,
            name: *const c_char,
            value: *mut c_void,
            size: usize,
            position: u32,
            options: i32,
        ) -> isize;
    }
    let path_cstr = CString::new(path.as_os_str().as_encoded_bytes()).ok()?;
    const ATTR: &std::ffi::CStr =
        unsafe { std::ffi::CStr::from_bytes_with_nul_unchecked(b"com.apple.metadata:kMDItemDateAdded\0") };
    let mut buf = [0u8; 64];
    let len = unsafe {
        getxattr(
            path_cstr.as_ptr(),
            ATTR.as_ptr(),
            buf.as_mut_ptr() as *mut c_void,
            buf.len(),
            0,
            0,
        )
    };
    if len < 17 {
        return None;
    }
    if &buf[0..8] != b"bplist00" || buf[8] != 0x33 {
        return None;
    }
    let secs = f64::from_be_bytes(buf[9..17].try_into().ok()?);
    Some(((secs + 978_307_200.0) * 1000.0) as i64)
}

#[cfg(not(target_os = "macos"))]
fn added_ms(_path: &std::path::Path, meta: &std::fs::Metadata) -> i64 {
    created_ms(meta)
}

#[cfg(unix)]
fn fill_owner_mode(e: &mut Entry, meta: &std::fs::Metadata) {
    use std::os::unix::fs::MetadataExt;
    e.mode = meta.mode();
    e.uid = meta.uid();
    e.gid = meta.gid();
}

#[cfg(not(unix))]
fn fill_owner_mode(_e: &mut Entry, _meta: &std::fs::Metadata) {}
