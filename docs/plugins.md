# Writing Waydir plugins

A plugin adds entries to Waydir's menus and shortcuts that run your own logic.
Plugins are written in Lua. No build step - drop a folder in, reload, done.

## Quick start

A plugin is a folder with two files:

```
my-plugin/
  manifest.json
  init.lua
```

Put it in your plugins folder:

| OS | Path |
|----|------|
| Linux | `~/.config/waydir/plugins/` |
| macOS / Windows | app support dir `/plugins/` |

Then open **Preferences -> Plugins** and click **Reload plugins** (or restart
Waydir). The fastest way to find the folder is the **Open plugins folder**
button there - it opens it in a new tab.

## manifest.json

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "you",
  "description": "What it does, in one line.",
  "api_version": 2,
  "permissions": []
}
```

- `id` - unique, lowercase.
- `api_version` - must be `2` for this build.
- `permissions` - what the plugin is allowed to do. Users see this before they
  trust the plugin, so ask for the least you need:
  - `"exec"` - run external programs (`waydir.exec`, `waydir.run_task`).
  - `"fs"` - read/write/list files and queue file operations.

  Leave empty if you only show toasts, notifications, or dialogs.

## init.lua

Register one or more actions:

```lua
waydir.register({
  id    = "to_webp",
  title = "Convert to WebP",
  when  = { extensions = { "png", "jpg", "jpeg" } },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      waydir.exec("cwebp", { path, "-o", path:gsub("%.%w+$", ".webp") })
    end
    waydir.toast(ctx.count .. " converted")
    waydir.refresh()
  end,
})
```

### Where an entry shows up

| Field | Meaning |
|-------|---------|
| `menu` | `"context"` (right-click, default), `"menubar"` (top Plugins menu), or `"toolbar"` (icon button in the location bar) |
| `where` | for context menus: `{ "selection" }` (default), `{ "background" }`, or both |
| `group` | label of a context submenu; entries sharing a `group` nest under one cascading entry that opens on hover |
| `icon` | shown on context, menubar and toolbar entries. Either a `.svg`/`.png` file relative to the plugin folder, or a named builtin glyph (see below). Unset/unknown falls back to a generic glyph |
| `shortcut` | a key chord like `"ctrl+shift+x"` or `"alt+f5"` - listed under Keybindings |

`"selection"` entries appear when files/folders are selected and the `when`
filter matches. `"background"` entries appear on the empty-area right-click and
act on the current folder (`ctx.dir`, with an empty `ctx.paths`). `"toolbar"`
entries sit next to New Folder, are always visible, and also act on the current
folder (`ctx.dir`); the `title` is their tooltip.

Named builtin glyphs for `icon` (no image file needed): `archive`, `bell`,
`bookmark`, `bug`, `calendar`, `check`, `clipboard`, `clock`, `code`, `copy`,
`desktop`, `download`, `eye`, `file`, `file-audio`, `file-code`, `file-image`,
`file-pdf`, `file-text`, `file-zip`, `folder`, `folder-open`, `folder-plus`,
`gear`, `git-branch`, `hard-drive`, `image`, `info`, `keyboard`, `list`,
`magic-wand`, `music`, `note`, `palette`, `pencil`, `plus`, `ruler`, `scissors`,
`search`, `sliders`, `terminal`, `trash`, `tree`, `usb`, `video`, `warning`.

### `when` - filter the selection

A simple filter, all fields optional. The entry appears only when every
condition holds for the selection (selection surface only).

| Field | Meaning |
|-------|---------|
| `types` | `{"file"}`, `{"folder"}`, or both |
| `extensions` | only these file extensions (no dot) |
| `min` / `max` | bounds on how many items are selected |
| `in_archive` | `false` to hide inside archives |

Omit `when` entirely to show the entry for any selection.

### `settings` - user-editable config

Declare a schema; Waydir renders it under **Preferences -> Plugins ->
Configure** and persists the values. They arrive as `ctx.settings`.

```lua
settings = {
  { id = "quality", type = "text",   label = "JPEG quality", default = "85" },
  { id = "keep",    type = "checkbox", label = "Keep original", default = true },
  { id = "mode",    type = "select", label = "Mode",
    options = { "fast", "best" }, default = "fast" },
},
```

Field `type` is one of `text`, `input`, `password`, `checkbox`, `select`. A
`select` takes `options` (a list of strings, or `{value=, label=}` tables).

### `run(ctx)` - what it does

`ctx` is the invocation context:

| Field | Meaning |
|-------|---------|
| `ctx.paths` | list of selected paths (empty on the background surface) |
| `ctx.count` | how many |
| `ctx.dir` | the current folder |
| `ctx.plugin_dir` | your plugin's folder (to call bundled scripts) |
| `ctx.settings` | your stored settings (schema defaults overlaid with saved values) |
| `ctx.form` | dialog results, present only after a `waydir.dialog` round-trip |

## `waydir` functions

| Call | Permission | Effect |
|------|------------|--------|
| `waydir.toast(msg)` | - | brief message |
| `waydir.notify({title, message, level, persistent})` | - | notification; `level` = info/success/warn/error |
| `waydir.dialog({title, fields, submit_action})` | - | show a form, then re-run the action with `ctx.form` filled |
| `waydir.set_setting(key, value)` | - | persist one of your settings |
| `waydir.refresh()` | - | refresh the file list |
| `waydir.log(msg)` | - | write to Waydir's log |
| `waydir.exec(cmd, args)` | `exec` | run a program and wait, returning `stdout, stderr, exit_code` (short jobs; capped at 5s) |
| `waydir.run_task({title, cmd, args, cwd, timeout, operation, pty, progress})` | `exec` | run a long program off the UI; progress via notification or Operations. `timeout` in seconds (default 600, max 21600) |
| `waydir.read_text(path)` | `fs` | return a file's contents (capped at 4 MiB) |
| `waydir.file_size(path)` | `fs` | return a file's byte size |
| `waydir.write_text(path, text)` | `fs` | write a file |
| `waydir.mkdir(path)` | `fs` | create a directory (and parents) |
| `waydir.exists(path)` | `fs` | true if the path exists |
| `waydir.list(path)` | `fs` | list a directory: `{ {name, path, is_dir}, ... }` |
| `waydir.copy(src, destDir)` | `fs` | queue a copy into `destDir` (uses Waydir's operations) |
| `waydir.move(src, destDir)` | `fs` | queue a move into `destDir` |
| `waydir.delete(path)` | `fs` | queue a permanent delete |
| `waydir.trash(path)` | `fs` | queue a move to trash |
| `waydir.operation_start({id, title, total_bytes, total_files})` | - | create a custom Operations entry |
| `waydir.operation_update(id, {progress, message, processed_bytes, total_bytes, bytes_per_second, processed_files, total_files})` | - | update a custom Operations entry |
| `waydir.operation_finish(id, {success, cancelled, error})` | - | finish a custom Operations entry |

### Dialogs (the `ctx.form` round-trip)

`waydir.dialog` doesn't return a value - it shows a modal and, on submit,
re-invokes the same action with `ctx.form` set. Branch on `ctx.form`:

```lua
run = function(ctx)
  if not ctx.form then
    waydir.dialog({
      title = "Rename",
      fields = { { id = "name", type = "input", label = "New name" } },
      submit_action = "rename",
    })
    return
  end
  waydir.write_text(ctx.dir .. "/" .. ctx.form.name, "")
end,
```

### Long jobs vs. quick commands

`waydir.exec` runs inside the 5-second sandbox - fine for quick commands. It
returns three values: stdout, stderr and exit code:

```lua
local out, err, code = waydir.exec("tailscale", { "file", "cp", "--targets" })
if code == 0 then
  waydir.toast(out)
end
```

For anything slow, use `waydir.run_task`: it runs the process outside the
sandbox and reports completion as a notification, without freezing the action.

To show a long command in the Operations panel instead of only as a
notification, set `operation = true`. If the command only prints live progress
when connected to a terminal, set `pty = true` (currently supported on Linux via
the system `script` command). The optional `progress` table contains Dart regular
expressions; the first capture group is used.

```lua
waydir.run_task({
  title = "Upload",
  cmd = "uploader",
  args = { "--progress", "file.bin" },
  operation = true,
  pty = true,
  progress = {
    percent_regex = [[([0-9]+(?:\.[0-9]+)?)%]],
    message_regex = [[^(.+?)\s+[0-9]+]],
    bytes_regex = [[\s([0-9]+(?:\.[0-9]+)?\s*[KMGTPE]?i?B)\s]],
    speed_regex = [[\s([0-9]+(?:\.[0-9]+)?\s*[KMGTPE]?i?B/s)]],
  },
})
```

Plugins can also manage custom Operations entries directly. `id` is scoped to
the plugin, so separate plugins can reuse the same id safely.

```lua
waydir.operation_start({ id = "sync", title = "Sync", total_files = 10 })
waydir.operation_update("sync", {
  progress = 0.5,
  message = "5 of 10",
  processed_files = 5,
})
waydir.operation_finish("sync", { success = true })
```

## Use any language for the heavy lifting

Lua decides *when* and *where*; the real work can be any program you `exec`.
Bundle a script next to `init.lua` and run it:

```lua
run = function(ctx)
  waydir.run_task({
    title = "Processing",
    cmd = "python3",
    args = { ctx.plugin_dir .. "/process.py", table.unpack(ctx.paths) },
  })
end
```

## Examples

Ready to copy from [examples/plugins/](examples/plugins/):

- **selection-count** - shows how many items you selected. No permissions.
- **backup-copy** - makes a `.bak` copy of each selected file. Uses `exec`.
- **templates** - "New from template" surfaced as a toolbar button, a
  background entry, two menubar actions and a shortcut. Uses a `select` dialog,
  persists an author via `set_setting`, and writes boilerplate with `fs`. A full
  tour of the v2 API.
- **open-vscode** - toolbar button (and folder right-click entry) that opens the
  current folder in VS Code. Uses `exec` and a `command` setting.
- **sevenzip** - compress the selection or extract archives with `7z`. Uses
  `exec` + `run_task`, a `group` submenu (quick .zip / .tar.gz + "Add to
  archive…"), a `when` filter, and a dialog for custom name/format/level.

## Notes

- Each run starts fresh - don't rely on Lua globals persisting between clicks.
- A long-running `run` won't freeze Waydir, but it is capped at 5 seconds. Use
  `waydir.run_task` for slow work.
- The sandbox has no `os`, `io`, or `require`. Use `waydir.read_text` /
  `waydir.write_text` / `waydir.exec` for anything that touches the system.
