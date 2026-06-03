-- 7-Zip integration. Needs the `7z` binary on PATH (p7zip / 7-Zip).
-- Shows: a selection-filtered context entry, a settings schema, a dialog
-- round-trip for the archive name, and a long job via run_task.

local function basename(path)
  return (path:gsub("(.*/)(.*)", "%2"))
end

local function strip_ext(name)
  return (name:gsub("%.[^.]+$", ""))
end

-- Compress the current selection into one archive.
waydir.register({
  id = "compress",
  title = "Compress with 7-Zip…",
  when = { min = 1, in_archive = false },
  settings = {
    { id = "format", type = "select", label = "Format",
      options = { "7z", "zip", "tar" }, default = "7z" },
    { id = "level", type = "select", label = "Compression",
      options = {
        { value = "1", label = "Fastest" },
        { value = "5", label = "Normal" },
        { value = "9", label = "Ultra" },
      }, default = "5" },
  },
  run = function(ctx)
    if ctx.count == 0 then return end

    -- First pass: ask for a name (default from the first selected item).
    if not ctx.form then
      local default = strip_ext(basename(ctx.paths[1]))
      waydir.dialog({
        title = "Compress with 7-Zip",
        fields = {
          { id = "name", type = "input", label = "Archive name", default = default },
        },
        submit_action = "compress",
      })
      return
    end

    local name = ctx.form.name
    if not name or name == "" then return end

    local fmt = ctx.settings.format or "7z"
    local level = ctx.settings.level or "5"
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
  end,
})

-- Extract a selected archive into a folder next to it.
waydir.register({
  id = "extract",
  title = "Extract here with 7-Zip",
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
