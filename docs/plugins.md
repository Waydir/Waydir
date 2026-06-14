# Waydir Plugin Guide

Waydir plugins are small Lua folders that add workflow actions to the file manager. They can add context menu items, top menu items, toolbar buttons, shortcuts, status bars, dialogs, background commands and queued file operations.

No build step is required. Drop a folder into the plugins directory, reload plugins and the action is live.

## What You Can Build

Good plugin ideas are small actions around the current folder or selection:

| Idea | How it fits |
|------|-------------|
| Open current folder in an editor | Toolbar button or background context action using `waydir.exec` |
| Compress selected files | Selection context action using `waydir.run_task` |
| Create files from templates | Toolbar, menubar and shortcut action using `waydir.dialog` and `waydir.write_text` |
| Show project metadata | Per-pane status bar using `waydir.register_bar` |
| Run a backup command | Long task in Operations using `waydir.run_task({ operation = true })` |
| Add custom copy or trash actions | Queued operations using `waydir.copy`, `waydir.move`, `waydir.trash` |

Plugins are not meant to replace full applications. Lua decides where an action appears and when it runs. Heavy work should be delegated to external commands or Waydir's queued file operations.

## Quick Start

Create this folder:

```text
hello-waydir/
  manifest.json
  init.lua
```

`manifest.json`:

```json
{
  "id": "hello-waydir",
  "name": "Hello Waydir",
  "version": "1.0.0",
  "author": "you",
  "description": "Shows a toast from the selection menu.",
  "api_version": 2,
  "permissions": []
}
```

`init.lua`:

```lua
waydir.register({
  id = "hello",
  title = "Say hello",
  icon = "bell",
  run = function(ctx)
    waydir.toast("Selected " .. ctx.count .. " item(s)")
  end,
})
```

Install it, reload plugins and right-click a selected file. You should see **Say hello** in the context menu.

## Install A Plugin

Copy the whole plugin folder into Waydir's plugins directory. The folder itself must contain `manifest.json` and `init.lua` at the top level.

| OS | Plugins directory |
|----|-------------------|
| Linux | `~/.config/waydir/plugins/` or `$XDG_CONFIG_HOME/waydir/plugins/` |
| Windows | Application support directory, then `plugins/` |
| macOS | Application support directory, then `plugins/` |

The easiest way to find the exact path is **Preferences -> Plugins -> Open plugins folder**.

After copying a plugin:

1. Open **Preferences -> Plugins**.
2. Click **Reload plugins**.
3. Review the permissions shown for the plugin.
4. Enable or configure it if needed.

If a plugin does not appear, check these first:

- The folder is not nested one level too deep after extracting an archive.
- `manifest.json` is valid JSON.
- `init.lua` exists next to `manifest.json`.
- `api_version` is `2`.
- The plugin is enabled.
- The action's `when` filter matches the current selection.
- The action shortcut does not conflict with a built-in shortcut or another plugin.

## Plugin Anatomy

A plugin has one manifest and one Lua entry file:

```text
my-plugin/
  manifest.json
  init.lua
  icon.svg
  helper-script.py
```

`manifest.json` describes the plugin. `init.lua` registers actions and bars. Extra files can be icons, scripts, templates or data files accessed through `ctx.plugin_dir`.

Only registration should happen at the top level of `init.lua`. Actions run later through their `run(ctx)` function. Bars run later through `update(ctx)` and optional `click(ctx)` functions.

## Runtime Model

On reload, Waydir scans the plugins directory, reads each `manifest.json`, rejects unsupported API versions and runs `init.lua` once in a sandbox to collect contributions from `waydir.register` and `waydir.register_bar`.

When a user invokes an action, Waydir starts a fresh Lua VM, runs the same `init.lua`, finds the matching action id, calls `run(ctx)` and applies the effects emitted through the `waydir.*` API.

Status bars follow the same fresh-VM rule. Waydir calls `update(ctx)` on load, when the bar context changes and on the configured interval. Button clicks call `click(ctx)` when the bar defines one.

| Area | Behavior |
|------|----------|
| API version | This build supports manifest `api_version` value `2`. |
| Sandbox | Lua gets `table`, `string`, `math` and `waydir`. No `os`, `io` or `require`. |
| Timeout | Lua load, action runs and bar updates are capped at 5 seconds. |
| State | Lua globals do not persist between clicks. Use settings for durable state. |
| Permissions | External commands need `exec`; file reads, writes and queued file operations need `fs`. |

## manifest.json

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "author": "you",
  "description": "One sentence explaining what it adds.",
  "api_version": 2,
  "permissions": []
}
```

| Field | Required | Meaning |
|-------|----------|---------|
| `id` | No | Stable plugin id. If missing, Waydir uses the folder name. Use lowercase words separated by `-`. |
| `name` | No | Human-readable name in Preferences. Defaults to the plugin id. |
| `version` | No | Plugin version shown to users. Defaults to `0.0.0`. |
| `author` | No | Author name. |
| `description` | No | Short explanation shown in Preferences. |
| `api_version` | Yes | Must be `2` for this Waydir build. |
| `permissions` | No | List of permissions requested by the plugin. Defaults to no permissions. |

Permissions:

| Permission | Allows |
|------------|--------|
| `exec` | `waydir.exec` and `waydir.run_task` |
| `fs` | `waydir.read_text`, `write_text`, `mkdir`, `exists`, `list`, `file_size`, `copy`, `move`, `delete`, `trash` |

Ask for the least permission you need. Users see permissions before trusting a plugin.

## Register An Action

Actions are registered with `waydir.register`:

```lua
waydir.register({
  id = "open_here",
  title = "Open here in Code",
  menu = "toolbar",
  icon = "code",
  run = function(ctx)
    waydir.exec("code", { ctx.dir })
  end,
})
```

Action fields:

| Field | Type | Meaning |
|-------|------|---------|
| `id` | string | Unique action id inside this plugin. |
| `title` | string | Label shown in menus, tooltips and keybindings. |
| `run` | function | Function called when the action runs. Receives `ctx`. |
| `menu` | string | `context`, `menubar` or `toolbar`. Defaults to `context`. |
| `where` | list | Context menu surface. Use `{ "selection" }`, `{ "background" }` or both. Defaults to `{ "selection" }`. |
| `group` | string | Context submenu label. Actions with the same group are nested together. |
| `icon` | string | Built-in icon name or bundled `.svg` or `.png` path. |
| `shortcut` | string | Chord such as `ctrl+shift+x` or `alt+f5`. |
| `when` | table | Selection filter. Applies to selection context actions. |
| `settings` | list | User-editable plugin settings schema. |

Menu behavior:

| `menu` | Where it appears | Context |
|--------|------------------|---------|
| `context` | Right-click menu | Uses `where` to decide selection or background. |
| `menubar` | Top **Plugins** menu | Runs against the active folder and selection. |
| `toolbar` | Location toolbar | Runs against the active folder. The `title` is the tooltip. |

Shortcut behavior:

- Shortcuts are listed under the Plugins section in keybindings help.
- Shortcuts that conflict with built-in shortcuts are ignored.
- Shortcuts that conflict with another plugin shortcut are ignored.
- Use lowercase chord names like `ctrl+alt+n`, `ctrl+shift+x`, `alt+f5`.

Supported modifier names:

- `ctrl`, `control`, `cmd`, `command`, `meta`, `super`
- `shift`
- `alt`, `option`

Supported keys include letters, digits, `f1` through `f12`, arrows, `space`, `enter`, `tab`, `escape`, `backspace`, `delete`, `home`, `end`, `pageup`, `pagedown`, `comma`, `period` and `slash`.

## Invocation Context

The `ctx` table tells your action where it is running:

| Field | Meaning |
|-------|---------|
| `ctx.paths` | Selected paths as a Lua array. Empty for background actions with no selection. |
| `ctx.count` | Number of selected paths. |
| `ctx.dir` | Current folder. |
| `ctx.plugin_dir` | Absolute path to your plugin folder. |
| `ctx.settings` | Settings values, with defaults merged with saved user values. |
| `ctx.form` | Dialog result after a `waydir.dialog` submit. |

Example:

```lua
waydir.register({
  id = "copy_paths",
  title = "Show selected paths",
  when = { min = 1 },
  run = function(ctx)
    waydir.notify({
      title = "Selected paths",
      message = table.concat(ctx.paths, "\n"),
      level = "info",
    })
  end,
})
```

## Selection Filters

Use `when` to control when a selection action appears. All conditions must match.

```lua
when = {
  types = { "file" },
  extensions = { "png", "jpg", "jpeg" },
  min = 1,
  max = 20,
  in_archive = false,
}
```

| Field | Meaning |
|-------|---------|
| `types` | Allowed item types: `file`, `folder` or both. |
| `extensions` | Allowed file extensions without dots. Matching is lowercase. |
| `min` | Minimum selected items. Defaults to `1`. |
| `max` | Maximum selected items. |
| `in_archive` | `false` hides the action inside archives. `true` shows it only inside archives. |

Omit `when` to show the action for any non-empty selection. For background actions, use `where = { "background" }`.

## Dialogs

`waydir.dialog` opens a modal form. It does not return a value immediately. When the user submits the form, Waydir runs the same action again with `ctx.form` filled.

`submit_action` is kept in examples to make the intent obvious. Current Waydir builds always re-run the same action that opened the dialog.

```lua
waydir.register({
  id = "new_file",
  title = "New file...",
  where = { "background" },
  icon = "file-text",
  run = function(ctx)
    if not ctx.form then
      waydir.dialog({
        title = "New file",
        fields = {
          { id = "name", type = "input", label = "File name", default = "untitled.txt" },
        },
        submit_action = "new_file",
      })
      return
    end

    if not ctx.form.name or ctx.form.name == "" then
      return
    end

    waydir.write_text(ctx.dir .. "/" .. ctx.form.name, "")
    waydir.refresh()
  end,
})
```

Field types:

| Type | UI |
|------|----|
| `text` | Text input. |
| `input` | Text input. |
| `password` | Obscured text input. |
| `checkbox` | Boolean checkbox. |
| `toggle` | Boolean checkbox. |
| `bool` | Boolean checkbox. |
| `select` | Dropdown. |
| `dropdown` | Dropdown. |
| `info` | Read-only text. |
| `label` | Read-only text. |

Field schema:

| Field | Meaning |
|-------|---------|
| `id` | Key used in `ctx.form` and `ctx.settings`. |
| `type` | Field type. Defaults to `text`. |
| `label` | Label shown to the user. |
| `hint` | Placeholder for text inputs. |
| `default` | Default value. |
| `options` | Dropdown options for `select` and `dropdown`. |

Dropdown options can be strings or objects:

```lua
options = {
  "fast",
  "best",
  { value = "ultra", label = "Ultra compression" },
}
```

## Settings

Declare `settings` on any action or bar. Waydir merges all fields from the plugin, renders them in **Preferences -> Plugins -> Configure** and injects saved values into `ctx.settings`.

```lua
waydir.register({
  id = "convert",
  title = "Convert image",
  settings = {
    { id = "quality", type = "input", label = "JPEG quality", default = "85" },
    { id = "keep", type = "checkbox", label = "Keep original", default = true },
    {
      id = "mode",
      type = "select",
      label = "Mode",
      options = { "fast", "best" },
      default = "fast",
    },
  },
  run = function(ctx)
    local quality = (ctx.settings or {}).quality or "85"
    waydir.toast("Quality: " .. quality)
  end,
})
```

Update one setting from Lua with `waydir.set_setting`:

```lua
waydir.set_setting("quality", "90")
```

Settings are stored per plugin id.

## Status Bars

Use `waydir.register_bar` for compact always-visible information.

Waydir refreshes a bar when it is first shown, when its context changes and on its `interval`. Current builds always refresh on context changes.

```lua
waydir.register_bar({
  id = "project",
  scope = "pane",
  title = "Project",
  icon = "code",
  interval = 10,
  update = function(ctx)
    if not ctx.dir:match("src") then
      return { visible = false }
    end

    return {
      visible = true,
      items = {
        { type = "badge", text = "src", level = "info" },
        { type = "text", text = ctx.dir },
        { type = "button", id = "refresh", icon = "refresh", tooltip = "Refresh", action = "refresh" },
      },
    }
  end,
})
```

Bar fields:

| Field | Type | Meaning |
|-------|------|---------|
| `id` | string | Unique bar id inside this plugin. |
| `scope` | string | `global` or `pane`. Defaults to `global`. |
| `title` | string | Label shown at the start of the bar. Defaults to `id`. |
| `icon` | string | Built-in icon name or bundled image path. |
| `interval` | number | Refresh interval in seconds. `0` disables periodic refresh. Values above `0` are clamped between 2 and 3600. |
| `settings` | list | Optional settings schema. |
| `update(ctx)` | function | Returns the current bar state. |
| `click(ctx)` | function | Optional handler for button clicks. Receives `ctx.item_id`. |

Bar context includes the normal `ctx.dir`, `ctx.paths`, `ctx.count`, `ctx.plugin_dir` and `ctx.settings` fields. It also includes:

| Field | Meaning |
|-------|---------|
| `ctx.scope` | `global` or `pane`. |
| `ctx.pane` | Pane id for pane bars. Can be absent for global bars. |
| `ctx.is_active` | `true` when the pane is active. |
| `ctx.item_id` | Button id during `click(ctx)`. |

Bar state:

| Field | Meaning |
|-------|---------|
| `visible` | Set to `false` to hide the bar for the current context. |
| `items` | List of compact UI items. |

Item types:

| Type | Fields |
|------|--------|
| `text` | `text`, optional `level` |
| `badge` | `text`, optional `level` |
| `icon` | `icon`, optional `level` |
| `button` | `id`, optional `text`, `icon`, `tooltip`, `action` |
| `separator` | No fields |

Levels: `info`, `success`, `warn`, `error`.

Button behavior:

- A button with `action = "refresh"` refreshes the bar and does not call `click(ctx)`.
- Other buttons call `click(ctx)` with `ctx.item_id` set to the button `id`.
- If `click(ctx)` returns a bar state, Waydir applies it and then refreshes the bar.

## `waydir` API

### UI And State

| Function | Permission | Effect |
|----------|------------|--------|
| `waydir.toast(message)` | None | Shows a short toast. |
| `waydir.notify({ title, message, level, persistent })` | None | Shows a notification. `level` can be `info`, `success`, `warn` or `error`. |
| `waydir.dialog({ title, fields, submit_action })` | None | Opens a form and re-runs the same action with `ctx.form`. |
| `waydir.set_setting(key, value)` | None | Persists one setting for this plugin. |
| `waydir.refresh()` | None | Refreshes the active file list. |
| `waydir.log(message)` | None | Writes to Waydir's plugin log channel. |

### External Commands

| Function | Permission | Effect |
|----------|------------|--------|
| `waydir.exec(cmd, args)` | `exec` | Runs a short command and waits for it. Returns `stdout`, `stderr`, `exit_code`. |
| `waydir.run_task(spec)` | `exec` | Starts a long-running process outside the Lua action. |

Use `waydir.exec` only for quick commands. Lua actions have a 5 second sandbox budget.

```lua
local out, err, code = waydir.exec("git", { "branch", "--show-current" })
if code == 0 then
  waydir.toast("Branch: " .. out)
else
  waydir.notify({ title = "Git failed", message = err, level = "error" })
end
```

Use `waydir.run_task` for slow commands:

```lua
waydir.run_task({
  title = "Backup",
  cmd = "rsync",
  args = { "-a", ctx.dir .. "/", "/backup/project/" },
  cwd = ctx.dir,
  timeout = 3600,
})
```

`run_task` fields:

| Field | Meaning |
|-------|---------|
| `title` | Title shown in notification or Operations. |
| `cmd` | Executable name or path. |
| `args` | List of string arguments. |
| `cwd` | Optional working directory. |
| `timeout` | Timeout in seconds. Defaults to 600. Maximum is 21600. |
| `operation` | `true` shows the process in the Operations panel. |
| `pty` | `true` asks Waydir to run through a PTY wrapper on Linux. Useful for commands that only print progress in a terminal. |
| `progress` | Regex config for Operations progress parsing. |

Progress parsing uses Dart regular expressions. The first capture group is used when present.

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

### File System

| Function | Permission | Effect |
|----------|------------|--------|
| `waydir.read_text(path)` | `fs` | Reads UTF-8 text. Capped at 4 MiB. |
| `waydir.write_text(path, text)` | `fs` | Writes UTF-8 text. |
| `waydir.mkdir(path)` | `fs` | Creates a directory and parents. |
| `waydir.exists(path)` | `fs` | Returns `true` if the path exists. |
| `waydir.list(path)` | `fs` | Returns `{ { name, path, is_dir }, ... }`. |
| `waydir.file_size(path)` | `fs` | Returns file size in bytes. |
| `waydir.copy(src, dest_dir)` | `fs` | Queues a Waydir copy operation. |
| `waydir.move(src, dest_dir)` | `fs` | Queues a Waydir move operation. |
| `waydir.delete(path)` | `fs` | Queues a permanent delete after confirmation. |
| `waydir.trash(path)` | `fs` | Queues move to trash, respecting delete confirmation settings. |

Queued file operations appear in Waydir's Operations panel and use the same copy, move, delete and trash machinery as the UI.

### Custom Operations

Use custom Operations entries when your plugin does work itself and wants to report progress.

```lua
waydir.operation_start({ id = "sync", title = "Sync", total_files = 10 })
waydir.operation_update("sync", {
  progress = 0.5,
  message = "5 of 10",
  processed_files = 5,
})
waydir.operation_finish("sync", { success = true })
```

| Function | Permission | Effect |
|----------|------------|--------|
| `waydir.operation_start({ id, title, total_bytes, total_files })` | None | Creates a custom Operations entry. |
| `waydir.operation_update(id, spec)` | None | Updates progress, message, bytes and files. |
| `waydir.operation_finish(id, spec)` | None | Marks the operation as successful, cancelled or failed. |

`operation_update` fields:

| Field | Meaning |
|-------|---------|
| `progress` | Number between `0` and `1`. |
| `message` | Current file or status text. |
| `processed_bytes` | Bytes processed. |
| `total_bytes` | Total bytes. |
| `bytes_per_second` | Current speed. |
| `processed_files` | Files processed. |
| `total_files` | Total files. |

`operation_finish` fields:

| Field | Meaning |
|-------|---------|
| `success` | Defaults to `true`. |
| `cancelled` | Defaults to `false`. |
| `error` | Error message for failed operations. |

Operation ids are scoped to the plugin, so different plugins can reuse the same id safely.

## Icons

`icon` can be a built-in glyph name or a bundled image path.

Bundled images:

```lua
icon = "icon.svg"
icon = "assets/action.png"
```

Built-in glyphs:

```text
archive, arrow-clockwise, bell, bookmark, bug, calendar, check, clipboard,
clock, code, copy, desktop, download, eye, file, file-audio, file-code,
file-image, file-pdf, file-text, file-zip, folder, folder-open,
folder-plus, gear, git-branch, hard-drive, image, info, keyboard, list,
magic-wand, music, note, palette, pencil, plus, refresh, ruler, scissors,
search, sliders, terminal, trash, tree, usb, video, warning
```

Unknown icon names fall back to the default plugin glyph.

## Sandbox And Runtime Rules

Waydir runs plugins in a restricted Lua sandbox:

- Available standard libraries: `table`, `string`, `math`.
- Not available: `os`, `io`, `require`.
- Each load, action run and bar update gets a fresh Lua VM.
- Do not rely on Lua globals persisting between clicks.
- Top-level code should only register actions and bars.
- Action and bar Lua execution has a 5 second budget.
- Use `waydir.run_task` for slow external work.
- Use `ctx.plugin_dir` to call bundled helper scripts or read bundled files.
- `exec` and `fs` APIs fail unless the manifest requests the matching permission.

## Patterns

### Background Action

```lua
waydir.register({
  id = "open_terminal_here",
  title = "Open external terminal here",
  where = { "background" },
  icon = "terminal",
  run = function(ctx)
    waydir.exec("x-terminal-emulator", { "--working-directory", ctx.dir })
  end,
})
```

### Toolbar Button

```lua
waydir.register({
  id = "open_code",
  title = "Open in VS Code",
  menu = "toolbar",
  icon = "code",
  run = function(ctx)
    waydir.exec("code", { ctx.dir })
  end,
})
```

### Context Submenu

```lua
local group = "Image tools"

waydir.register({
  id = "webp",
  title = "Convert to WebP",
  group = group,
  icon = "image",
  when = { types = { "file" }, extensions = { "png", "jpg", "jpeg" } },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      waydir.run_task({
        title = "Convert " .. path,
        cmd = "cwebp",
        args = { path, "-o", path .. ".webp" },
      })
    end
  end,
})
```

### Helper Script

```lua
waydir.register({
  id = "process",
  title = "Process with helper",
  when = { min = 1 },
  run = function(ctx)
    local args = { ctx.plugin_dir .. "/process.py" }
    for _, path in ipairs(ctx.paths) do
      args[#args + 1] = path
    end
    waydir.run_task({
      title = "Processing",
      cmd = "python3",
      args = args,
      cwd = ctx.dir,
      operation = true,
    })
  end,
})
```

## Examples In This Repository

Ready-to-copy examples live in [examples/plugins/](examples/plugins/):

| Example | Shows |
|---------|-------|
| `selection-count` | Tiny no-permission action using `ctx.count` and `waydir.toast`. |
| `backup-copy` | External command action using `exec`. |
| `open-vscode` | Toolbar and folder action with a configurable command. |
| `templates` | Toolbar, background menu, top menu, shortcut, settings, dialog and `fs`. |
| `sevenzip` | Context submenu, filters, dialogs, `run_task`, compression and extraction. |

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Plugin is not listed | Folder must contain `manifest.json` and `init.lua` directly. |
| Load error says unsupported API | Set `api_version` to `2`. |
| Action is missing from context menu | Check `where`, `menu`, `when`, current selection and archive state. |
| Shortcut does nothing | Check for conflicts with built-in shortcuts or another plugin. |
| `exec permission not granted` | Add `"exec"` to `permissions`. |
| `fs permission not granted` | Add `"fs"` to `permissions`. |
| Command works in terminal but not plugin | Use an absolute command path, configure `cwd`, or check PATH differences. |
| Long command times out | Use `waydir.run_task` and set a suitable `timeout`. |
| Progress does not update | Use `operation = true`, check regex capture groups and try `pty = true` on Linux. |
| Dialog submits but nothing happens | Branch on `ctx.form` after the form is submitted. |

Use `waydir.log("message")` while developing. Plugin failures are also surfaced in **Preferences -> Plugins** or as notifications.
