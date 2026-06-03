-- A toolbar button that opens the current folder in VS Code. Needs the `exec`
-- permission and the `code` CLI on PATH (set a different command - e.g.
-- `code-insiders`, `codium`, or a flatpak wrapper - under Configure).

local function editor_command(ctx)
  local cmd = (ctx.settings or {}).command
  if not cmd or cmd == "" then
    return "code"
  end
  return cmd
end

waydir.register({
  id = "open_vscode",
  title = "Open in VS Code",
  menu = "toolbar",
  icon = "icon.svg",
  settings = {
    { id = "command", type = "text", label = "Editor command", default = "code" },
  },
  run = function(ctx)
    if not ctx.dir or ctx.dir == "" then
      return
    end
    waydir.exec(editor_command(ctx), { ctx.dir })
    waydir.notify({
      title = "VS Code",
      message = "Opening " .. ctx.dir,
      level = "info",
    })
  end,
})

-- Bonus: also open a selected folder straight from its right-click menu. The
-- same bundled svg icon works in the context menu, just like the toolbar.
waydir.register({
  id = "open_vscode_selection",
  title = "Open in VS Code",
  icon = "icon.svg",
  when = { types = { "folder" }, min = 1, max = 1 },
  run = function(ctx)
    local target = ctx.paths[1]
    if not target or target == "" then
      return
    end
    waydir.exec(editor_command(ctx), { target })
  end,
})
