use std::ffi::{c_char, CStr};
use std::path::PathBuf;

use crate::codec::put_u32;

#[cfg(target_os = "windows")]
use std::collections::HashMap;
#[cfg(target_os = "windows")]
use std::sync::{Mutex, OnceLock};

#[cfg(target_os = "windows")]
use crate::codec::put_u64;

/// # Safety
/// `paths` is an array of `count` NUL-terminated C strings; `out_len` writable.
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

    finish_optional(out, out_len)
}

fn finish_optional(out: Vec<u8>, out_len: *mut usize) -> *mut u8 {
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
fn take_trash_items(
    ids: *const *const c_char,
    count: usize,
    out: &mut Vec<u8>,
) -> Vec<trash::TrashItem> {
    let mut cache = trash_items().lock().unwrap();
    let mut items = Vec::new();
    for i in 0..count {
        let ptr = unsafe { *ids.add(i) };
        if ptr.is_null() {
            continue;
        }
        let id = unsafe { CStr::from_ptr(ptr) }
            .to_string_lossy()
            .into_owned();
        match cache.remove(&id) {
            Some(item) => items.push(item),
            None => encode_trash_error(&id, "Trash item is no longer available", out),
        }
    }
    items
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
fn finish_trash_list_error(err: impl std::fmt::Display, out_len: *mut usize) -> *mut u8 {
    let msg = err.to_string();
    let mut buf = Vec::with_capacity(8 + msg.len());
    put_u32(&mut buf, u32::MAX);
    put_bytes(&mut buf, msg.as_bytes());
    let mut bytes = buf.into_boxed_slice();
    unsafe {
        *out_len = bytes.len();
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}

#[cfg(target_os = "windows")]
/// # Safety
/// `out_len` must be writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_list(out_len: *mut usize) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }

    let items = match trash::os_limited::list() {
        Ok(items) => items,
        Err(err) => return finish_trash_list_error(err, out_len),
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
/// # Safety
/// `out_len` must be writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_trash_list(out_len: *mut usize) -> *mut u8 {
    if !out_len.is_null() {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

#[cfg(target_os = "windows")]
/// # Safety
/// `ids` is an array of `count` NUL-terminated C strings; `out_len` writable.
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
    finish_optional(out, out_len)
}

#[cfg(not(target_os = "windows"))]
/// # Safety
/// `ids` is an array of `count` NUL-terminated C strings; `out_len` writable.
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
/// # Safety
/// `ids` is an array of `count` NUL-terminated C strings; `out_len` writable.
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
    finish_optional(out, out_len)
}

#[cfg(not(target_os = "windows"))]
/// # Safety
/// `ids` is an array of `count` NUL-terminated C strings; `out_len` writable.
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
