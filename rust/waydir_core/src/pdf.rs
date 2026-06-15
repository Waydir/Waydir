use std::ffi::{c_char, CStr};
use std::sync::Mutex;

use once_cell::sync::OnceCell;
use pdfium_render::prelude::*;

use crate::codec::finish_buffer;

/// Process-wide Pdfium instance. Pdfium's `FPDF_InitLibrary` /
/// `FPDF_DestroyLibrary` must run exactly once per process: binding a fresh
/// instance per call and dropping it tears the library down globally and
/// breaks every subsequent render. We initialise it once, on the first call,
/// and never drop it for the life of the process.
static PDFIUM: OnceCell<Pdfium> = OnceCell::new();

/// Pdfium is not thread-safe. These FFI entry points are invoked from many
/// Dart isolates at once (one per page render plus the page-size scan), each
/// on its own OS thread, all hitting the single shared `PDFIUM` above.
/// Concurrent calls corrupt Pdfium's internal state and crash the process, so
/// every call serialises through this lock.
static PDFIUM_LOCK: Mutex<()> = Mutex::new(());

/// Returns the shared Pdfium instance, binding to the library on first use.
/// An empty `lib_path` falls back to the system-installed library; otherwise
/// it is the full path to the vendored `libpdfium.{so,dylib,dll}` shipped next
/// to `waydir_core`.
fn pdfium(lib_path: &str) -> Result<&'static Pdfium, PdfiumError> {
    PDFIUM.get_or_try_init(|| {
        let bindings = if lib_path.is_empty() {
            Pdfium::bind_to_system_library()?
        } else {
            Pdfium::bind_to_library(lib_path)?
        };
        Ok(Pdfium::new(bindings))
    })
}

unsafe fn read_str(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    CStr::from_ptr(ptr).to_str().ok().map(|s| s.to_owned())
}

/// Returns the size of every page as a big-endian buffer: a u32 page count
/// followed by `count` pairs of f32 (width, height) in PDF points. Lets the
/// UI reserve the correct height per page up front, so lazily rendered pages
/// do not resize and jolt the scrollbar. Returns null on failure; free with
/// `waydir_free`.
///
/// # Safety
/// String pointers must be valid NUL-terminated C strings; `out_len` writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_pdf_page_sizes(
    lib_path: *const c_char,
    pdf_path: *const c_char,
    out_len: *mut usize,
) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    let _guard = match PDFIUM_LOCK.lock() {
        Ok(g) => g,
        Err(_) => return std::ptr::null_mut(),
    };
    let (lib, path) = match (read_str(lib_path), read_str(pdf_path)) {
        (Some(l), Some(p)) => (l, p),
        _ => return std::ptr::null_mut(),
    };
    let pdfium = match pdfium(&lib) {
        Ok(p) => p,
        Err(_) => return std::ptr::null_mut(),
    };
    let document = match pdfium.load_pdf_from_file(&path, None) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };
    let pages = document.pages();
    let mut buf = Vec::with_capacity(4 + pages.len() as usize * 8);
    buf.extend_from_slice(&(pages.len() as u32).to_be_bytes());
    for page in pages.iter() {
        buf.extend_from_slice(&page.width().value.to_be_bytes());
        buf.extend_from_slice(&page.height().value.to_be_bytes());
    }
    finish_buffer(buf, out_len)
}

/// Renders a single PDF page to an RGBA8888 byte buffer scaled to
/// `target_width` (height follows the page aspect ratio). Writes the actual
/// pixel dimensions to `out_width`/`out_height` and the byte length to
/// `out_len`. Returns null on any failure. Free the buffer with `waydir_free`.
///
/// # Safety
/// String pointers must be valid NUL-terminated C strings; the out pointers
/// must be writable.
#[no_mangle]
pub unsafe extern "C" fn waydir_pdf_render(
    lib_path: *const c_char,
    pdf_path: *const c_char,
    page_index: i32,
    target_width: i32,
    out_width: *mut i32,
    out_height: *mut i32,
    out_len: *mut usize,
) -> *mut u8 {
    if out_width.is_null() || out_height.is_null() || out_len.is_null() {
        return std::ptr::null_mut();
    }
    if page_index < 0 || target_width <= 0 {
        return std::ptr::null_mut();
    }
    let _guard = match PDFIUM_LOCK.lock() {
        Ok(g) => g,
        Err(_) => return std::ptr::null_mut(),
    };
    let (lib, path) = match (read_str(lib_path), read_str(pdf_path)) {
        (Some(l), Some(p)) => (l, p),
        _ => return std::ptr::null_mut(),
    };
    let pdfium = match pdfium(&lib) {
        Ok(p) => p,
        Err(_) => return std::ptr::null_mut(),
    };
    let document = match pdfium.load_pdf_from_file(&path, None) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };
    let pages = document.pages();
    if page_index >= pages.len() as i32 {
        return std::ptr::null_mut();
    }
    let page = match pages.get(page_index) {
        Ok(p) => p,
        Err(_) => return std::ptr::null_mut(),
    };
    let config = PdfRenderConfig::new().set_target_width(target_width);
    let bitmap = match page.render_with_config(&config) {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };
    let width = bitmap.width() as i32;
    let height = bitmap.height() as i32;
    let bytes = bitmap.as_rgba_bytes();
    *out_width = width;
    *out_height = height;
    finish_buffer(bytes, out_len)
}
