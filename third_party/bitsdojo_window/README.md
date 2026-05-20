# bitsdojo_window attribution

Source: https://github.com/bitsdojo/bitsdojo_window (MIT License)

The native window chrome code in `windows/runner/window/` and
`linux/runner/window/` is a subset port of bitsdojo_window 0.1.6
(`bitsdojo_window_windows-0.1.6`, `bitsdojo_window_linux-0.1.4`).

We vendor it because the upstream package is unmaintained and pins
`win32 ^5`, blocking dependency upgrades. The Dart shim in
`lib/ui/window/` is a rewrite using `dart:ffi` against the runner-embedded
native library; it is not derived from upstream Dart code.

See LICENSE for the original copyright.
