-- A fuller tour of the v2 API: the same "create from template" action is
-- surfaced four ways - a toolbar button (menu = "toolbar"), the background
-- right-click menu, the top Plugins menubar, and a shortcut - plus a second
-- menubar entry that edits this plugin's own settings via set_setting.
--
-- It reads a `select` dialog field, persists an author in settings, and writes
-- the chosen boilerplate with `fs`.

local TEMPLATES = {
  { id = "markdown", label = "Markdown document", ext = "md" },
  { id = "text", label = "Plain text", ext = "txt" },
  { id = "shell", label = "Shell script", ext = "sh" },
  { id = "python", label = "Python script", ext = "py" },
  { id = "html", label = "HTML page", ext = "html" },
  { id = "json", label = "JSON file", ext = "json" },
}

local SHELL = [[#!/usr/bin/env bash
set -euo pipefail

]]

local PYTHON = [[#!/usr/bin/env python3
"""%s."""


def main() -> None:
    pass


if __name__ == "__main__":
    main()
]]

local HTML = [[<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>%s</title>
</head>
<body>
</body>
</html>
]]

local function template_options()
  local opts = {}
  for _, tpl in ipairs(TEMPLATES) do
    opts[#opts + 1] = { value = tpl.id, label = tpl.label }
  end
  return opts
end

local function ext_for(id)
  for _, tpl in ipairs(TEMPLATES) do
    if tpl.id == id then
      return tpl.ext
    end
  end
  return "txt"
end

local function body(id, name, author)
  if id == "markdown" then
    local s = "# " .. name .. "\n"
    if author ~= "" then
      s = s .. "\n_by " .. author .. "_\n"
    end
    return s
  elseif id == "shell" then
    return SHELL
  elseif id == "python" then
    return string.format(PYTHON, name)
  elseif id == "html" then
    return string.format(HTML, name)
  elseif id == "json" then
    return "{\n}\n"
  end
  return ""
end

-- First pass opens the dialog; the submit re-runs the emitting action with
-- ctx.form populated, so every surface shares this one function.
local function create_from_template(ctx)
  local settings = ctx.settings or {}
  if not ctx.form then
    waydir.dialog({
      title = "New from template",
      fields = {
        { id = "name", type = "input", label = "File name", default = "untitled" },
        {
          id = "template",
          type = "select",
          label = "Template",
          options = template_options(),
          default = settings.default or "markdown",
        },
      },
      submit_action = "new_from_template",
    })
    return
  end

  local name = ctx.form.name
  if not name or name == "" then
    return
  end
  local id = ctx.form.template or "markdown"
  local ext = ext_for(id)
  local path = ctx.dir .. "/" .. name .. "." .. ext
  waydir.write_text(path, body(id, name, settings.author or ""))
  waydir.notify({
    title = "New from Template",
    message = "Created " .. name .. "." .. ext,
    level = "success",
  })
  waydir.refresh()
end

-- Primary entry: background menu + shortcut, and owns the settings schema.
waydir.register({
  id = "new_from_template",
  title = "New from template…",
  where = { "background" },
  icon = "note",
  shortcut = "ctrl+alt+n",
  settings = {
    { id = "author", type = "text", label = "Author (added to templates)", default = "" },
    {
      id = "default",
      type = "select",
      label = "Default template",
      options = template_options(),
      default = "markdown",
    },
  },
  run = create_from_template,
})

-- Toolbar button, next to New Folder. Uses the bundled icon.
waydir.register({
  id = "new_from_template_toolbar",
  title = "New from template…",
  menu = "toolbar",
  icon = "icon.svg",
  run = create_from_template,
})

-- Top Plugins menubar. `icon` accepts a bundled image (svg/png) just like the
-- toolbar, or a named builtin glyph (see set_author below).
waydir.register({
  id = "new_from_template_menubar",
  title = "New from template…",
  menu = "menubar",
  icon = "icon.svg",
  run = create_from_template,
})

-- A second menubar entry that edits this plugin's own setting.
waydir.register({
  id = "set_author",
  title = "Set template author…",
  menu = "menubar",
  icon = "pencil",
  run = function(ctx)
    if not ctx.form then
      waydir.dialog({
        title = "Template author",
        fields = {
          {
            id = "author",
            type = "input",
            label = "Author name",
            default = (ctx.settings or {}).author or "",
          },
        },
        submit_action = "set_author",
      })
      return
    end
    waydir.set_setting("author", ctx.form.author or "")
    waydir.notify({
      title = "New from Template",
      message = "Author saved",
      level = "success",
    })
  end,
})
