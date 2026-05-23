use std::ffi::OsStr;

pub(crate) const EXCLUDED: &[&str] = &[
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

#[cfg(unix)]
pub(crate) fn os_bytes(s: &OsStr) -> Vec<u8> {
    use std::os::unix::ffi::OsStrExt;
    s.as_bytes().to_vec()
}

#[cfg(not(unix))]
pub(crate) fn os_bytes(s: &OsStr) -> Vec<u8> {
    s.to_string_lossy().into_owned().into_bytes()
}

#[cfg(unix)]
pub(crate) fn path_depth(path: &[u8]) -> usize {
    path.iter().filter(|&&b| b == b'/').count()
}

#[cfg(not(unix))]
pub(crate) fn path_depth(path: &[u8]) -> usize {
    path.iter().filter(|&&b| b == b'/' || b == b'\\').count()
}

pub(crate) fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}

pub(crate) fn mtime_ms(meta: &std::fs::Metadata) -> i64 {
    match meta.modified() {
        Ok(t) => match t.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => d.as_millis() as i64,
            Err(e) => -(e.duration().as_millis() as i64),
        },
        Err(_) => 0,
    }
}
