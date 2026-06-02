# Writing Waydir plugins

A plugin adds entries to Waydir's right-click menu that run your own logic.
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
  "api_version": 1,
  "permissions": []
}
```

- `id` - unique, lowercase.
- `permissions` - what the plugin is allowed to do. Add `"exec"` to run external
  programs. Leave empty if you only show toasts. Users see this before they trust
  the plugin, so ask for the least you need.

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

### `when` - when the entry shows

A simple filter, all fields optional. The entry appears only when every
condition holds for the selection.

| Field | Meaning |
|-------|---------|
| `types` | `{"file"}`, `{"folder"}`, or both |
| `extensions` | only these file extensions (no dot) |
| `min` / `max` | bounds on how many items are selected |
| `in_archive` | `false` to hide inside archives |

Omit `when` entirely to show the entry for any selection.

### `run(ctx)` - what it does

`ctx` is what the user selected:

| Field | Meaning |
|-------|---------|
| `ctx.paths` | list of selected paths |
| `ctx.count` | how many |
| `ctx.dir` | the current folder |
| `ctx.plugin_dir` | your plugin's folder (to call bundled scripts) |

### `waydir` functions

| Call | Effect |
|------|--------|
| `waydir.exec(cmd, args)` | run a program (needs `"exec"` permission) |
| `waydir.toast(msg)` | show a message |
| `waydir.refresh()` | refresh the file list |
| `waydir.log(msg)` | write to Waydir's log |

## Use any language for the heavy lifting

Lua decides *when* and *where*; the real work can be any program you `exec`.
Bundle a script next to `init.lua` and run it:

```lua
run = function(ctx)
  waydir.exec("python3", { ctx.plugin_dir .. "/process.py", table.unpack(ctx.paths) })
end
```

## Examples

Ready to copy from [examples/plugins/](examples/plugins/):

- **selection-count** - shows how many items you selected. No permissions.
- **backup-copy** - makes a `.bak` copy of each selected file. Uses `exec`.

## Notes

- Each run starts fresh - don't rely on Lua globals persisting between clicks.
- A long-running `run` won't freeze Waydir, but it is capped at 5 seconds.
- The sandbox has no `os`, `io`, or `require`. Use `waydir.exec` for anything
  that touches the system.
</content>
