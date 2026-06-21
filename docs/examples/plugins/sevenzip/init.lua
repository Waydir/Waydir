-- 7-Zip integration. Needs the `7z` binary on PATH (p7zip / 7-Zip); the
-- tar.gz entries also need `tar`. All compress entries share a "Compress with
-- 7-Zip" submenu: quick .zip / .tar.gz plus "Add to archive…", which opens a
-- modal for the name, format and compression level.

local GROUP = "Compress with 7-Zip"
local SELECTION = { min = 1, in_archive = false }

local function basename(path)
  return (path:gsub("(.*/)(.*)", "%2"))
end

local function strip_ext(name)
  return (name:gsub("%.[^.]+$", ""))
end

local function default_name(ctx)
  return strip_ext(basename(ctx.paths[1]))
end

local function run_7z(ctx, name, fmt, level)
  local archive = ctx.dir .. "/" .. name .. "." .. fmt
  local args = { "a", "-t" .. fmt, "-mx" .. level, archive }
  for _, path in ipairs(ctx.paths) do
    args[#args + 1] = path
  end
  waydir.run_task({
    title = "7-Zip: " .. name .. "." .. fmt,
    cmd = "7z",
    args = args,
    cwd = ctx.dir,
    timeout = 3600,
  })
end

local function run_targz(ctx, name)
  local args = { "-czf", name .. ".tar.gz" }
  for _, path in ipairs(ctx.paths) do
    args[#args + 1] = basename(path)
  end
  waydir.run_task({
    title = "tar: " .. name .. ".tar.gz",
    cmd = "tar",
    args = args,
    cwd = ctx.dir,
    timeout = 3600,
  })
end

waydir.register({
  id = "zip",
  group = GROUP,
  title = "Compress to .zip",
  icon = "file-zip",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end
    run_7z(ctx, default_name(ctx), "zip", "5")
  end,
})

waydir.register({
  id = "targz",
  group = GROUP,
  title = "Compress to .tar.gz",
  icon = "archive",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end
    run_targz(ctx, default_name(ctx))
  end,
})

-- Custom pass: first invoke opens the modal, the submit re-runs this action
-- with `ctx.form` populated.
waydir.register({
  id = "custom",
  group = GROUP,
  title = "Add to archive…",
  icon = "sliders",
  when = SELECTION,
  run = function(ctx)
    if ctx.count == 0 then return end

    if not ctx.form then
      waydir.dialog({
        title = "Add to archive",
        fields = {
          { id = "name", type = "input", label = "Archive name",
            default = default_name(ctx) },
          { id = "format", type = "select", label = "Format",
            options = { "7z", "zip", "tar", "tar.gz" }, default = "7z" },
          { id = "level", type = "select", label = "Compression",
            options = {
              { value = "1", label = "Fastest" },
              { value = "5", label = "Normal" },
              { value = "9", label = "Ultra" },
            }, default = "5" },
        },
      })
      return
    end

    local name = ctx.form.name
    if not name or name == "" then return end

    local fmt = ctx.form.format or "7z"
    if fmt == "tar.gz" then
      run_targz(ctx, name)
    else
      run_7z(ctx, name, fmt, ctx.form.level or "5")
    end
  end,
})

-- Extract a selected archive into a folder next to it.
waydir.register({
  id = "extract",
  title = "Extract here with 7-Zip",
  icon = "archive",
  when = { extensions = { "7z", "zip", "rar", "tar", "gz", "bz2", "xz" }, min = 1 },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      local dest = ctx.dir .. "/" .. strip_ext(basename(path))
      waydir.run_task({
        title = "Extract " .. basename(path),
        cmd = "7z",
        args = { "x", path, "-o" .. dest, "-y" },
        cwd = ctx.dir,
        timeout = 3600,
      })
    end
  end,
})
