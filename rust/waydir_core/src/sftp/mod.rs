//! SFTP via russh. C ABI for Dart FFI.
//!
//! Wszystkie wywołania FFI są synchroniczne z punktu widzenia callera,
//! a wewnętrznie wykonywane przez współdzielony tokio runtime (patrz
//! [`runtime`]). Sesje SSH są pulowane po `host:port@user` i identyfikowane
//! przez u64 zwracane do Darta.

mod auth;
mod ops;
mod runtime;
mod session;

pub use ops::*;
