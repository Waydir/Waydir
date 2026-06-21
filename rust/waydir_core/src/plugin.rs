use std::cell::RefCell;
use std::ffi::{c_char, CStr, CString};
use std::io::Read;
use std::process::Stdio;
use std::rc::Rc;
use std::time::{Duration, Instant};

use mlua::{HookTriggers, Lua, LuaOptions, LuaSerdeExt, StdLib, Table, Value, VmState};
use serde_json::{json, Value as Json};
use wait_timeout::ChildExt;

const PLUGIN_TIMEOUT: Duration = Duration::from_secs(5);

/// Hard cap on how long a synchronous `waydir.exec` may run. A blocked child
/// does not execute Lua instructions, so the instruction-count hook cannot
/// interrupt it; this bound is what actually stops a hung command from
/// wedging the plugin isolate. Slow work belongs in `waydir.run_task`.
const EXEC_TIMEOUT: Duration = Duration::from_secs(5);

/// Cap on the size of a file `waydir.read_text` will load, in bytes.
const READ_TEXT_CAP: u64 = 4 * 1024 * 1024;

type Effects = Rc<RefCell<Vec<Json>>>;

fn new_sandbox() -> mlua::Result<Lua> {
    let libs = StdLib::TABLE | StdLib::STRING | StdLib::MATH;
    let lua = Lua::new_with(libs, LuaOptions::default())?;
    let deadline = Instant::now() + PLUGIN_TIMEOUT;
    let _ = lua.set_hook(
        HookTriggers::new().every_nth_instruction(50_000),
        move |_lua, _debug| {
            if Instant::now() >= deadline {
                Err(mlua::Error::RuntimeError("plugin timed out".into()))
            } else {
                Ok(VmState::Continue)
            }
        },
    );
    Ok(lua)
}

fn opt_string_array(t: &Table, key: &str) -> mlua::Result<Option<Vec<String>>> {
    match t.get::<Option<Table>>(key)? {
        Some(arr) => {
            let mut out = Vec::new();
            for v in arr.sequence_values::<String>() {
                out.push(v?);
            }
            Ok(Some(out))
        }
        None => Ok(None),
    }
}

fn when_to_json(t: &Table) -> mlua::Result<Json> {
    let mut obj = serde_json::Map::new();
    if let Some(v) = opt_string_array(t, "types")? {
        obj.insert("types".into(), json!(v));
    }
    if let Some(v) = opt_string_array(t, "extensions")? {
        obj.insert("extensions".into(), json!(v));
    }
    if let Some(v) = t.get::<Option<i64>>("min")? {
        obj.insert("min".into(), json!(v));
    }
    if let Some(v) = t.get::<Option<i64>>("max")? {
        obj.insert("max".into(), json!(v));
    }
    if let Some(v) = t.get::<Option<bool>>("in_archive")? {
        obj.insert("in_archive".into(), json!(v));
    }
    Ok(Json::Object(obj))
}

fn settings_to_json(lua: &Lua, spec: &Table) -> mlua::Result<Json> {
    match spec.get::<Option<Table>>("settings")? {
        Some(s) => table_to_json(lua, s),
        None => Ok(Json::Null),
    }
}

fn table_to_json(lua: &Lua, t: Table) -> mlua::Result<Json> {
    lua.from_value(Value::Table(t))
}

fn err(msg: impl Into<String>) -> mlua::Error {
    mlua::Error::RuntimeError(msg.into())
}

fn install_api(lua: &Lua, effects: &Effects) -> mlua::Result<Table> {
    let waydir = lua.create_table()?;

    let e = effects.clone();
    waydir.set(
        "toast",
        lua.create_function(move |_, msg: String| {
            e.borrow_mut()
                .push(json!({ "type": "toast", "message": msg }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "notify",
        lua.create_function(move |lua, spec: Table| {
            let title: Option<String> = spec.get("title")?;
            let message: String = spec.get("message")?;
            let level: Option<String> = spec.get("level")?;
            let persistent: Option<bool> = spec.get("persistent")?;
            let _ = lua;
            e.borrow_mut().push(json!({
                "type": "notify",
                "title": title,
                "message": message,
                "level": level.unwrap_or_else(|| "info".into()),
                "persistent": persistent.unwrap_or(false),
            }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "refresh",
        lua.create_function(move |_, ()| {
            e.borrow_mut().push(json!({ "type": "refresh" }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "log",
        lua.create_function(move |_, msg: String| {
            e.borrow_mut()
                .push(json!({ "type": "log", "message": msg }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "set_setting",
        lua.create_function(move |lua, (key, value): (String, Value)| {
            let v: Json = lua.from_value(value)?;
            e.borrow_mut().push(json!({
                "type": "set_setting",
                "key": key,
                "value": v,
            }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "dialog",
        lua.create_function(move |lua, spec: Table| {
            let json = table_to_json(lua, spec)?;
            e.borrow_mut()
                .push(json!({ "type": "dialog", "dialog": json }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "exec",
        lua.create_function(move |_, (cmd, args): (String, Option<Vec<String>>)| {
            let args = args.unwrap_or_default();
            let mut child = std::process::Command::new(&cmd)
                .args(&args)
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()
                .map_err(|error| err(format!("exec {cmd}: {error}")))?;

            let status = match child
                .wait_timeout(EXEC_TIMEOUT)
                .map_err(|error| err(format!("exec {cmd}: {error}")))?
            {
                Some(status) => status,
                None => {
                    let _ = child.kill();
                    let _ = child.wait();
                    e.borrow_mut().push(json!({
                        "type": "log",
                        "message": format!(
                            "exec {} timed out after {}s",
                            cmd,
                            EXEC_TIMEOUT.as_secs()
                        )
                    }));
                    return Ok((
                        String::new(),
                        format!("exec {cmd} timed out"),
                        -1_i32,
                    ));
                }
            };

            let mut stdout = String::new();
            if let Some(mut out) = child.stdout.take() {
                let _ = out.read_to_string(&mut stdout);
            }
            let mut stderr = String::new();
            if let Some(mut out) = child.stderr.take() {
                let _ = out.read_to_string(&mut stderr);
            }
            let code = status.code().unwrap_or(-1);
            if !status.success() {
                e.borrow_mut().push(json!({
                    "type": "log",
                    "message": format!("exec {} failed: code {}", cmd, code)
                }));
            }
            Ok((stdout, stderr, code))
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "run_task",
        lua.create_function(move |lua, spec: Table| {
            let title: String = spec.get("title")?;
            let cmd: String = spec.get("cmd")?;
            let args: Vec<String> = opt_string_array(&spec, "args")?.unwrap_or_default();
            let cwd: Option<String> = spec.get("cwd")?;
            let timeout: Option<i64> = spec.get("timeout")?;
            let operation: Option<bool> = spec.get("operation")?;
            let pty: Option<bool> = spec.get("pty")?;
            let progress = match spec.get::<Option<Table>>("progress")? {
                Some(p) => table_to_json(lua, p)?,
                None => Json::Null,
            };
            e.borrow_mut().push(json!({
                "type": "task",
                "title": title,
                "cmd": cmd,
                "args": args,
                "cwd": cwd,
                "timeout": timeout,
                "operation": operation.unwrap_or(false),
                "pty": pty.unwrap_or(false),
                "progress": progress,
            }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "operation_start",
        lua.create_function(move |lua, spec: Table| {
            let json = table_to_json(lua, spec)?;
            e.borrow_mut().push(json!({
                "type": "custom_operation_start",
                "id": json.get("id").cloned().unwrap_or(Json::Null),
                "title": json.get("title").cloned().unwrap_or(Json::Null),
                "total_bytes": json.get("total_bytes").cloned().unwrap_or(Json::Null),
                "total_files": json.get("total_files").cloned().unwrap_or(Json::Null),
            }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "operation_update",
        lua.create_function(move |lua, (id, spec): (String, Table)| {
            let json = table_to_json(lua, spec)?;
            e.borrow_mut().push(json!({
                "type": "custom_operation_update",
                "id": id,
                "progress": json.get("progress").cloned().unwrap_or(Json::Null),
                "message": json.get("message").cloned().unwrap_or(Json::Null),
                "processed_bytes": json.get("processed_bytes").cloned().unwrap_or(Json::Null),
                "total_bytes": json.get("total_bytes").cloned().unwrap_or(Json::Null),
                "bytes_per_second": json.get("bytes_per_second").cloned().unwrap_or(Json::Null),
                "processed_files": json.get("processed_files").cloned().unwrap_or(Json::Null),
                "total_files": json.get("total_files").cloned().unwrap_or(Json::Null),
            }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "operation_finish",
        lua.create_function(move |lua, (id, spec): (String, Option<Table>)| {
            let json = match spec {
                Some(s) => table_to_json(lua, s)?,
                None => Json::Null,
            };
            e.borrow_mut().push(json!({
                "type": "custom_operation_finish",
                "id": id,
                "success": json.get("success").cloned().unwrap_or(Json::Bool(true)),
                "cancelled": json.get("cancelled").cloned().unwrap_or(Json::Bool(false)),
                "error": json.get("error").cloned().unwrap_or(Json::Null),
            }));
            Ok(())
        })?,
    )?;

    waydir.set(
        "read_text",
        lua.create_function(move |_, path: String| {
            let meta =
                std::fs::metadata(&path).map_err(|er| err(format!("read_text {path}: {er}")))?;
            if meta.len() > READ_TEXT_CAP {
                return Err(err(format!(
                    "read_text {path}: file exceeds {READ_TEXT_CAP} byte cap"
                )));
            }
            std::fs::read_to_string(&path).map_err(|er| err(format!("read_text {path}: {er}")))
        })?,
    )?;

    waydir.set(
        "file_size",
        lua.create_function(move |_, path: String| {
            let meta =
                std::fs::metadata(&path).map_err(|er| err(format!("file_size {path}: {er}")))?;
            Ok(meta.len())
        })?,
    )?;

    waydir.set(
        "write_text",
        lua.create_function(move |_, (path, content): (String, String)| {
            std::fs::write(&path, content).map_err(|er| err(format!("write_text {path}: {er}")))
        })?,
    )?;

    waydir.set(
        "mkdir",
        lua.create_function(move |_, path: String| {
            std::fs::create_dir_all(&path).map_err(|er| err(format!("mkdir {path}: {er}")))
        })?,
    )?;

    waydir.set(
        "exists",
        lua.create_function(move |_, path: String| {
            Ok(std::path::Path::new(&path).exists())
        })?,
    )?;

    waydir.set(
        "list",
        lua.create_function(move |lua, path: String| {
            let out = lua.create_table()?;
            let rd = std::fs::read_dir(&path).map_err(|er| err(format!("list {path}: {er}")))?;
            let mut i = 1;
            for entry in rd.flatten() {
                let p = entry.path();
                let item = lua.create_table()?;
                item.set("name", entry.file_name().to_string_lossy().to_string())?;
                item.set("path", p.to_string_lossy().to_string())?;
                item.set("is_dir", p.is_dir())?;
                out.set(i, item)?;
                i += 1;
            }
            Ok(out)
        })?,
    )?;

    for (name, op) in [("copy", "copy"), ("move", "move")] {
        let e = effects.clone();
        let op = op.to_string();
        waydir.set(
            name,
            lua.create_function(move |_, (src, dst): (String, String)| {
                e.borrow_mut().push(json!({
                    "type": "operation",
                    "op": op,
                    "src": src,
                    "dst": dst,
                }));
                Ok(())
            })?,
        )?;
    }

    for (name, op) in [("delete", "delete"), ("trash", "trash")] {
        let e = effects.clone();
        let op = op.to_string();
        waydir.set(
            name,
            lua.create_function(move |_, path: String| {
                e.borrow_mut().push(json!({
                    "type": "operation",
                    "op": op,
                    "src": path,
                }));
                Ok(())
            })?,
        )?;
    }

    // Default no-op so top-level `register_column` calls are safe in every
    // entry point; load and column-compute override it below.
    waydir.set(
        "register_column",
        lua.create_function(|_, _: Table| Ok(()))?,
    )?;

    Ok(waydir)
}

fn ctx_to_lua_table(lua: &Lua, ctx: &Json) -> mlua::Result<Table> {
    let tbl = lua.create_table()?;
    let nil_opts = mlua::SerializeOptions::new()
        .serialize_none_to_null(false)
        .serialize_unit_to_null(false);
    if let Some(obj) = ctx.as_object() {
        for (key, value) in obj {
            if key == "paths" {
                continue;
            }
            tbl.set(key.as_str(), lua.to_value_with(value, nil_opts)?)?;
        }
    }
    let paths_tbl = lua.create_table()?;
    let paths = ctx.get("paths").and_then(|v| v.as_array());
    let mut count = 0;
    if let Some(arr) = paths {
        for (i, v) in arr.iter().enumerate() {
            if let Some(s) = v.as_str() {
                paths_tbl.set(i + 1, s)?;
                count += 1;
            }
        }
    }
    tbl.set("paths", paths_tbl)?;
    tbl.set("count", count)?;
    Ok(tbl)
}

fn load_impl(path: &str) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path).map_err(|e| err(format!("read {path}: {e}")))?;
    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects)?;

    let contribs: Rc<RefCell<Vec<Json>>> = Rc::new(RefCell::new(Vec::new()));
    let bars: Rc<RefCell<Vec<Json>>> = Rc::new(RefCell::new(Vec::new()));
    let sink = contribs.clone();
    waydir.set(
        "register",
        lua.create_function(move |lua, spec: Table| {
            let id: String = spec.get("id")?;
            let menu: String = spec
                .get::<Option<String>>("menu")?
                .unwrap_or_else(|| "context".into());
            let title: String = spec.get("title")?;
            let group: Option<String> = spec.get("group")?;
            let icon: Option<String> = spec.get("icon")?;
            let when = match spec.get::<Option<Table>>("when")? {
                Some(w) => when_to_json(&w)?,
                None => Json::Null,
            };
            let where_ = opt_string_array(&spec, "where")?;
            let shortcut: Option<String> = spec.get("shortcut")?;
            let event: Option<String> = spec.get("event")?;
            let settings = settings_to_json(lua, &spec)?;
            sink.borrow_mut().push(json!({
                "id": id,
                "menu": menu,
                "title": title,
                "group": group,
                "icon": icon,
                "when": when,
                "where": where_,
                "shortcut": shortcut,
                "event": event,
                "settings": settings,
            }));
            Ok(())
        })?,
    )?;
    let bar_sink = bars.clone();
    waydir.set(
        "register_bar",
        lua.create_function(move |lua, spec: Table| {
            let id: String = spec.get("id")?;
            let scope: String = spec
                .get::<Option<String>>("scope")?
                .unwrap_or_else(|| "global".into());
            let title: String = spec
                .get::<Option<String>>("title")?
                .unwrap_or_else(|| id.clone());
            let icon: Option<String> = spec.get("icon")?;
            let interval: Option<i64> = spec.get("interval")?;
            let settings = settings_to_json(lua, &spec)?;
            bar_sink.borrow_mut().push(json!({
                "id": id,
                "scope": scope,
                "title": title,
                "icon": icon,
                "interval": interval,
                "settings": settings,
            }));
            Ok(())
        })?,
    )?;
    let columns: Rc<RefCell<Vec<Json>>> = Rc::new(RefCell::new(Vec::new()));
    let col_sink = columns.clone();
    waydir.set(
        "register_column",
        lua.create_function(move |lua, spec: Table| {
            let id: String = spec.get("id")?;
            let title: String = spec
                .get::<Option<String>>("title")?
                .unwrap_or_else(|| id.clone());
            let width: Option<i64> = spec.get("width")?;
            let settings = settings_to_json(lua, &spec)?;
            col_sink.borrow_mut().push(json!({
                "id": id,
                "title": title,
                "width": width,
                "settings": settings,
            }));
            Ok(())
        })?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let list = contribs.borrow().clone();
    let bar_list = bars.borrow().clone();
    let col_list = columns.borrow().clone();
    Ok(json!({
        "ok": true,
        "contributions": list,
        "bars": bar_list,
        "columns": col_list,
    }))
}

fn invoke_impl(path: &str, action_id: &str, ctx_json: &str) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path).map_err(|e| err(format!("read {path}: {e}")))?;
    let ctx: Json = serde_json::from_str(ctx_json).map_err(|e| err(format!("ctx json: {e}")))?;

    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects)?;

    let target = action_id.to_string();
    let found: Rc<RefCell<Option<mlua::Function>>> = Rc::new(RefCell::new(None));
    let slot = found.clone();
    waydir.set(
        "register",
        lua.create_function(move |_, spec: Table| {
            let id: String = spec.get("id")?;
            if id == target {
                if let Some(run) = spec.get::<Option<mlua::Function>>("run")? {
                    *slot.borrow_mut() = Some(run);
                }
            }
            Ok(())
        })?,
    )?;
    waydir.set(
        "register_bar",
        lua.create_function(move |_, _: Table| Ok(()))?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let run = found.borrow_mut().take();
    let run = run.ok_or_else(|| err(format!("action {action_id} not found")))?;

    let ctx_tbl = ctx_to_lua_table(&lua, &ctx)?;

    run.call::<Value>(ctx_tbl)?;

    let list = effects.borrow().clone();
    Ok(json!({ "ok": true, "effects": list }))
}

fn bar_update_impl(path: &str, bar_id: &str, ctx_json: &str) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path).map_err(|e| err(format!("read {path}: {e}")))?;
    let ctx: Json = serde_json::from_str(ctx_json).map_err(|e| err(format!("ctx json: {e}")))?;

    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects)?;
    waydir.set("register", lua.create_function(move |_, _: Table| Ok(()))?)?;

    let target = bar_id.to_string();
    let found: Rc<RefCell<Option<mlua::Function>>> = Rc::new(RefCell::new(None));
    let slot = found.clone();
    waydir.set(
        "register_bar",
        lua.create_function(move |_, spec: Table| {
            let id: String = spec.get("id")?;
            if id == target {
                if let Some(update) = spec.get::<Option<mlua::Function>>("update")? {
                    *slot.borrow_mut() = Some(update);
                }
            }
            Ok(())
        })?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let update = found.borrow_mut().take();
    let update = update.ok_or_else(|| err(format!("bar {bar_id} update not found")))?;
    let state_value = update.call::<Value>(ctx_to_lua_table(&lua, &ctx)?)?;
    let state = match state_value {
        Value::Nil => Json::Null,
        value => lua.from_value(value)?,
    };
    let list = effects.borrow().clone();
    Ok(json!({ "ok": true, "state": state, "effects": list }))
}

fn bar_click_impl(
    path: &str,
    bar_id: &str,
    item_id: &str,
    ctx_json: &str,
) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path).map_err(|e| err(format!("read {path}: {e}")))?;
    let mut ctx: Json =
        serde_json::from_str(ctx_json).map_err(|e| err(format!("ctx json: {e}")))?;
    if let Some(obj) = ctx.as_object_mut() {
        obj.insert("item_id".into(), Json::String(item_id.to_string()));
    }

    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects)?;
    waydir.set("register", lua.create_function(move |_, _: Table| Ok(()))?)?;

    let target = bar_id.to_string();
    let found: Rc<RefCell<Option<mlua::Function>>> = Rc::new(RefCell::new(None));
    let slot = found.clone();
    waydir.set(
        "register_bar",
        lua.create_function(move |_, spec: Table| {
            let id: String = spec.get("id")?;
            if id == target {
                if let Some(click) = spec.get::<Option<mlua::Function>>("click")? {
                    *slot.borrow_mut() = Some(click);
                }
            }
            Ok(())
        })?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let state = match found.borrow_mut().take() {
        Some(click) => {
            let value = click.call::<Value>(ctx_to_lua_table(&lua, &ctx)?)?;
            match value {
                Value::Nil => Json::Null,
                value => lua.from_value(value)?,
            }
        }
        None => Json::Null,
    };
    let list = effects.borrow().clone();
    Ok(json!({ "ok": true, "state": state, "effects": list }))
}

fn column_compute_impl(path: &str, column_id: &str, ctx_json: &str) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path).map_err(|e| err(format!("read {path}: {e}")))?;
    let ctx: Json = serde_json::from_str(ctx_json).map_err(|e| err(format!("ctx json: {e}")))?;

    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects)?;
    waydir.set("register", lua.create_function(move |_, _: Table| Ok(()))?)?;
    waydir.set(
        "register_bar",
        lua.create_function(move |_, _: Table| Ok(()))?,
    )?;

    let target = column_id.to_string();
    let found: Rc<RefCell<Option<mlua::Function>>> = Rc::new(RefCell::new(None));
    let slot = found.clone();
    waydir.set(
        "register_column",
        lua.create_function(move |_, spec: Table| {
            let id: String = spec.get("id")?;
            if id == target {
                if let Some(compute) = spec.get::<Option<mlua::Function>>("compute")? {
                    *slot.borrow_mut() = Some(compute);
                }
            }
            Ok(())
        })?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let compute = found.borrow_mut().take();
    let compute =
        compute.ok_or_else(|| err(format!("column {column_id} compute not found")))?;
    let value = compute.call::<Value>(ctx_to_lua_table(&lua, &ctx)?)?;
    let values = match value {
        Value::Nil => Json::Null,
        value => lua.from_value(value)?,
    };
    let list = effects.borrow().clone();
    Ok(json!({ "ok": true, "values": values, "effects": list }))
}

fn to_cstring(value: Json) -> *mut c_char {
    let s = value.to_string();
    match CString::new(s) {
        Ok(c) => c.into_raw(),
        Err(_) => CString::new("{\"ok\":false,\"error\":\"nul byte\"}")
            .unwrap()
            .into_raw(),
    }
}

fn err_json(e: impl std::fmt::Display) -> Json {
    json!({ "ok": false, "error": e.to_string() })
}

/// Loads a plugin's Lua entry file and returns its registered contributions
/// as JSON. The VM is discarded; nothing persists between calls.
///
/// # Safety
/// `path` must be a valid NUL-terminated UTF-8 C string.
#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_load(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return to_cstring(err_json("null path"));
    }
    let path = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    match load_impl(path) {
        Ok(v) => to_cstring(v),
        Err(e) => to_cstring(err_json(e)),
    }
}

/// Runs one registered action's `run` function in a fresh sandbox and returns
/// the collected host effects as JSON.
///
/// # Safety
/// All pointer args must be valid NUL-terminated UTF-8 C strings.
#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_invoke(
    path: *const c_char,
    action_id: *const c_char,
    ctx_json: *const c_char,
) -> *mut c_char {
    if path.is_null() || action_id.is_null() || ctx_json.is_null() {
        return to_cstring(err_json("null argument"));
    }
    let path = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let action_id = match CStr::from_ptr(action_id).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let ctx_json = match CStr::from_ptr(ctx_json).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    match invoke_impl(path, action_id, ctx_json) {
        Ok(v) => to_cstring(v),
        Err(e) => to_cstring(err_json(e)),
    }
}

#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_bar_update(
    path: *const c_char,
    bar_id: *const c_char,
    ctx_json: *const c_char,
) -> *mut c_char {
    if path.is_null() || bar_id.is_null() || ctx_json.is_null() {
        return to_cstring(err_json("null argument"));
    }
    let path = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let bar_id = match CStr::from_ptr(bar_id).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let ctx_json = match CStr::from_ptr(ctx_json).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    match bar_update_impl(path, bar_id, ctx_json) {
        Ok(v) => to_cstring(v),
        Err(e) => to_cstring(err_json(e)),
    }
}

#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_bar_click(
    path: *const c_char,
    bar_id: *const c_char,
    item_id: *const c_char,
    ctx_json: *const c_char,
) -> *mut c_char {
    if path.is_null() || bar_id.is_null() || item_id.is_null() || ctx_json.is_null() {
        return to_cstring(err_json("null argument"));
    }
    let path = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let bar_id = match CStr::from_ptr(bar_id).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let item_id = match CStr::from_ptr(item_id).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let ctx_json = match CStr::from_ptr(ctx_json).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    match bar_click_impl(path, bar_id, item_id, ctx_json) {
        Ok(v) => to_cstring(v),
        Err(e) => to_cstring(err_json(e)),
    }
}

/// Computes a registered column's values for a batch of files. `ctx_json`'s
/// `paths` lists the files; the column's `compute(ctx)` returns a table mapping
/// path to display string. Result JSON carries `values` and `effects`.
///
/// # Safety
/// All pointer args must be valid NUL-terminated UTF-8 C strings.
#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_column_compute(
    path: *const c_char,
    column_id: *const c_char,
    ctx_json: *const c_char,
) -> *mut c_char {
    if path.is_null() || column_id.is_null() || ctx_json.is_null() {
        return to_cstring(err_json("null argument"));
    }
    let path = match CStr::from_ptr(path).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let column_id = match CStr::from_ptr(column_id).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    let ctx_json = match CStr::from_ptr(ctx_json).to_str() {
        Ok(s) => s,
        Err(e) => return to_cstring(err_json(e)),
    };
    match column_compute_impl(path, column_id, ctx_json) {
        Ok(v) => to_cstring(v),
        Err(e) => to_cstring(err_json(e)),
    }
}

/// Frees a string returned by `waydir_plugin_load` / `waydir_plugin_invoke`.
///
/// # Safety
/// `ptr` must come from one of those calls and be freed exactly once.
#[no_mangle]
pub unsafe extern "C" fn waydir_plugin_str_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}
