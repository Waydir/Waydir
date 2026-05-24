use once_cell::sync::Lazy;
use tokio::runtime::{Builder, Runtime};

static RUNTIME: Lazy<Runtime> = Lazy::new(|| {
    Builder::new_multi_thread()
        .worker_threads(2)
        .thread_name("waydir-sftp")
        .enable_all()
        .build()
        .expect("failed to build tokio runtime for sftp")
});

pub(super) fn rt() -> &'static Runtime {
    &RUNTIME
}
