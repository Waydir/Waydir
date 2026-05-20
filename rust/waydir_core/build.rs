use std::process::Command;

fn main() {
    let version = std::env::var("WAYDIR_VERSION").unwrap_or_else(|_| "dev".into());

    let hash = Command::new("git")
        .args(["rev-parse", "--short", "HEAD"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "unknown".into());

    let dirty = Command::new("git")
        .args(["status", "--porcelain"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| !o.stdout.is_empty())
        .unwrap_or(false);

    let git = if dirty { format!("{hash}-dirty") } else { hash };

    println!("cargo:rustc-env=WAYDIR_VERSION={version}");
    println!("cargo:rustc-env=WAYDIR_GIT={git}");
    println!("cargo:rerun-if-env-changed=WAYDIR_VERSION");
    println!("cargo:rerun-if-changed=../../.git/HEAD");
    println!("cargo:rerun-if-changed=../../.git/index");
}
