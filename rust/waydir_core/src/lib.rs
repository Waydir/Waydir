// waydir_core: native filesystem helpers exposed over a tiny C ABI.
//
// Output buffers use a big-endian layout with magic 'WDIR' that Dart's
// `FileEntryCodec` decodes in one pass.

use std::ffi::c_char;

mod codec;
mod enumerate;
mod folder_scan;
mod list;
mod search;
mod trash;
mod util;
mod walker;

pub use enumerate::waydir_enumerate;
pub use folder_scan::{
    waydir_folder_scan_cancel, waydir_folder_scan_free, waydir_folder_scan_poll,
    waydir_folder_scan_start, FolderScanSession,
};
pub use list::waydir_list;
pub use search::{
    waydir_search, waydir_search_cancel, waydir_search_free, waydir_search_poll,
    waydir_search_start, SearchSession,
};
pub use trash::{waydir_trash, waydir_trash_list, waydir_trash_purge, waydir_trash_restore};

/// Releases a buffer returned by any `waydir_*` call.
///
/// # Safety
/// `ptr`/`len` must come from a previous `waydir_*` call and be used exactly once.
#[no_mangle]
pub unsafe extern "C" fn waydir_free(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    drop(Vec::from_raw_parts(ptr, len, len));
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
