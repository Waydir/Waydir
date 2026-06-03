-- Shows off the v2 API: a background-menu entry, a settings field, a
-- shortcut, a dialog round-trip, and a filesystem write.

waydir.register({
  id = "new_note",
  title = "New note…",
  -- Appears on the empty-area (background) menu and the menubar.
  where = { "background" },
  shortcut = "ctrl+alt+n",
  -- User-editable defaults, shown under Preferences -> Plugins -> Configure.
  settings = {
    { id = "ext", type = "text", label = "File extension", default = "md" },
  },
  run = function(ctx)
    -- First click: no form yet, so ask for a name.
    if not ctx.form then
      waydir.dialog({
        title = "New note",
        fields = {
          { id = "name", type = "input", label = "Note name" },
        },
        submit_action = "new_note",
      })
      return
    end

    -- Second pass: the dialog came back with values in ctx.form.
    local name = ctx.form.name
    if not name or name == "" then
      return
    end
    local ext = ctx.settings.ext or "md"
    local path = ctx.dir .. "/" .. name .. "." .. ext
    waydir.write_text(path, "# " .. name .. "\n")
    waydir.notify({ title = "New Note", message = "Created " .. name .. "." .. ext, level = "success" })
    waydir.refresh()
  end,
})
