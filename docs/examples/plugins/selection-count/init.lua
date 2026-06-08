waydir.register({
  id = "count",
  menu = "context",
  title = "Show selection count",
  when = { min = 1 },
  run = function(ctx)
    waydir.toast("Selected: " .. ctx.count .. " (" .. ctx.dir .. ")")
  end,
})
