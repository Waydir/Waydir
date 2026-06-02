waydir.register({
  id = "bak",
  menu = "context",
  title = "Create .bak copy",
  when = { types = { "file" }, min = 1, in_archive = false },
  run = function(ctx)
    for _, path in ipairs(ctx.paths) do
      waydir.exec("cp", { "-n", path, path .. ".bak" })
    end
    waydir.toast(ctx.count .. " file(s) copied to .bak")
    waydir.refresh()
  end,
})
