// waydir_core: native filesystem helpers exposed over a tiny C ABI.
//
// Output buffers use a big-endian layout with magic 'WDIR' that Dart's
// `FileEntryCodec` decodes in one pass.

use std::ffi::c_char;

mod codec;
mod enumerate;
mod folder_scan;
mod list;
mod pdf;
mod plugin;
mod pty;
mod search;
mod sftp;
mod trash;
mod util;
mod walker;

pub use enumerate::waydir_enumerate;
pub use folder_scan::{
    waydir_folder_scan_cancel, waydir_folder_scan_free, waydir_folder_scan_poll,
    waydir_folder_scan_start, FolderScanSession,
};
pub use list::waydir_list;
pub use pdf::{waydir_pdf_page_sizes, waydir_pdf_render};
pub use plugin::{waydir_plugin_invoke, waydir_plugin_load, waydir_plugin_str_free};
pub use pty::{
    waydir_pty_alive, waydir_pty_close, waydir_pty_open, waydir_pty_read, waydir_pty_resize,
    waydir_pty_write,
};
pub use search::{
    waydir_search, waydir_search_cancel, waydir_search_free, waydir_search_poll,
    waydir_search_start, SearchSession,
};
pub use sftp::{
    waydir_sftp_free_cstr, waydir_sftp_list, waydir_sftp_mkdir, waydir_sftp_read,
    waydir_sftp_realpath, waydir_sftp_remove, waydir_sftp_rename, waydir_sftp_session_close,
    waydir_sftp_session_open, waydir_sftp_stat, waydir_sftp_write, waydir_sftp_write_chunk,
    SftpStat,
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
    17
}

#[no_mangle]
pub extern "C" fn waydir_core_version() -> *const c_char {
    concat!(env!("WAYDIR_VERSION"), "\0").as_ptr() as *const c_char
}

#[no_mangle]
pub extern "C" fn waydir_core_git() -> *const c_char {
    concat!(env!("WAYDIR_GIT"), "\0").as_ptr() as *const c_char
}
