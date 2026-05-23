use std::sync::Mutex;

use ignore::WalkBuilder;

use crate::codec::Entry;
use crate::util::{num_cpus, EXCLUDED};

pub(crate) struct ChunkSink<'a> {
    pub local: Vec<u8>,
    pub count: usize,
    pub chunks: &'a Mutex<Vec<(Vec<u8>, usize)>>,
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

pub(crate) struct EntrySink<'a> {
    pub local: Vec<Entry>,
    pub buckets: &'a Mutex<Vec<Vec<Entry>>>,
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

pub(crate) fn base_builder(root: &str) -> WalkBuilder {
    let mut builder = WalkBuilder::new(root);
    builder
        .hidden(false)
        .parents(false)
        .ignore(false)
        .git_ignore(false)
        .git_global(false)
        .git_exclude(false)
        .follow_links(false)
        .threads(num_cpus());
    builder
}

pub(crate) fn apply_search_filter(builder: &mut WalkBuilder, include_hidden: bool) {
    builder.hidden(!include_hidden);
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
}
