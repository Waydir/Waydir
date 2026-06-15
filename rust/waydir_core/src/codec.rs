pub(crate) const MAGIC: u32 = 0x5744_4952; // 'WDIR'

pub(crate) struct Entry {
    pub is_dir: bool,
    pub size: i64,
    pub mtime_ms: i64,
    pub created_ms: i64,
    pub added_ms: i64,
    pub mode: u32,
    pub uid: u32,
    pub gid: u32,
    pub name: Vec<u8>,
    pub path: Vec<u8>,
    pub disk_path: std::path::PathBuf,
}

pub(crate) fn put_u32(buf: &mut Vec<u8>, v: u32) {
    buf.extend_from_slice(&v.to_be_bytes());
}

pub(crate) fn put_i64(buf: &mut Vec<u8>, v: i64) {
    buf.extend_from_slice(&v.to_be_bytes());
}

#[cfg(target_os = "windows")]
pub(crate) fn put_u64(buf: &mut Vec<u8>, v: u64) {
    buf.extend_from_slice(&v.to_be_bytes());
}

/// Fixed-size portion of a serialised record. Layout (big-endian):
/// u8 is_dir, i64 size, i64 mtime_ms, i64 created_ms, i64 added_ms, u32 mode,
/// u32 uid, u32 gid, u32 name_len, u32 path_len, then name + path bytes.
pub(crate) const RECORD_HEAD: usize = 1 + 8 + 8 + 8 + 8 + 4 + 4 + 4 + 4 + 4;

#[allow(clippy::too_many_arguments)]
pub(crate) fn put_record(
    buf: &mut Vec<u8>,
    is_dir: bool,
    size: i64,
    mtime_ms: i64,
    created_ms: i64,
    added_ms: i64,
    mode: u32,
    uid: u32,
    gid: u32,
    name: &[u8],
    path: &[u8],
) {
    buf.push(if is_dir { 0 } else { 1 });
    put_i64(buf, size);
    put_i64(buf, mtime_ms);
    put_i64(buf, created_ms);
    put_i64(buf, added_ms);
    put_u32(buf, mode);
    put_u32(buf, uid);
    put_u32(buf, gid);
    put_u32(buf, name.len() as u32);
    put_u32(buf, path.len() as u32);
    buf.extend_from_slice(name);
    buf.extend_from_slice(path);
}

pub(crate) fn serialise(entries: &[Entry]) -> Vec<u8> {
    let body: usize = entries
        .iter()
        .map(|e| RECORD_HEAD + e.name.len() + e.path.len())
        .sum();
    let mut buf = Vec::with_capacity(8 + body);
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, entries.len() as u32);
    for e in entries {
        put_record(
            &mut buf, e.is_dir, e.size, e.mtime_ms, e.created_ms, e.added_ms, e.mode, e.uid,
            e.gid, &e.name, &e.path,
        );
    }
    buf
}

pub(crate) fn assemble(count: usize, chunks: Vec<Vec<u8>>) -> Vec<u8> {
    let body: usize = chunks.iter().map(|c| c.len()).sum();
    let mut buf = Vec::with_capacity(8 + body);
    put_u32(&mut buf, MAGIC);
    put_u32(&mut buf, count as u32);
    for c in chunks {
        buf.extend_from_slice(&c);
    }
    buf
}

pub(crate) fn finish_buffer(bytes: Vec<u8>, out_len: *mut usize) -> *mut u8 {
    let mut bytes = bytes.into_boxed_slice();
    unsafe {
        *out_len = bytes.len();
    }
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    ptr
}
