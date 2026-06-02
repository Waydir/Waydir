use std::cell::RefCell;
use std::ffi::{c_char, CStr, CString};
use std::rc::Rc;
use std::time::{Duration, Instant};

use mlua::{HookTriggers, Lua, LuaOptions, StdLib, Table, Value, VmState};
use serde_json::{json, Value as Json};

const PLUGIN_TIMEOUT: Duration = Duration::from_secs(5);

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

fn install_api(lua: &Lua, effects: &Effects, allow_exec: bool) -> mlua::Result<Table> {
    let waydir = lua.create_table()?;

    let e = effects.clone();
    waydir.set(
        "toast",
        lua.create_function(move |_, msg: String| {
            e.borrow_mut().push(json!({ "type": "toast", "message": msg }));
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
            e.borrow_mut().push(json!({ "type": "log", "message": msg }));
            Ok(())
        })?,
    )?;

    let e = effects.clone();
    waydir.set(
        "exec",
        lua.create_function(move |_, (cmd, args): (String, Option<Vec<String>>)| {
            if !allow_exec {
                return Err(mlua::Error::RuntimeError(
                    "exec permission not granted".into(),
                ));
            }
            let args = args.unwrap_or_default();
            match std::process::Command::new(&cmd).args(&args).output() {
                Ok(out) if !out.status.success() => {
                    e.borrow_mut().push(json!({
                        "type": "log",
                        "message": format!(
                            "exec {} failed: code {}",
                            cmd,
                            out.status.code().unwrap_or(-1)
                        )
                    }));
                    Ok(())
                }
                Ok(_) => Ok(()),
                Err(err) => Err(mlua::Error::RuntimeError(format!("exec {cmd}: {err}"))),
            }
        })?,
    )?;

    Ok(waydir)
}

fn load_impl(path: &str) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path)
        .map_err(|e| mlua::Error::RuntimeError(format!("read {path}: {e}")))?;
    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects, false)?;

    let contribs: Rc<RefCell<Vec<Json>>> = Rc::new(RefCell::new(Vec::new()));
    let sink = contribs.clone();
    waydir.set(
        "register",
        lua.create_function(move |_, spec: Table| {
            let id: String = spec.get("id")?;
            let menu: String = spec
                .get::<Option<String>>("menu")?
                .unwrap_or_else(|| "context".into());
            let title: String = spec.get("title")?;
            let icon: Option<String> = spec.get("icon")?;
            let when = match spec.get::<Option<Table>>("when")? {
                Some(w) => when_to_json(&w)?,
                None => Json::Null,
            };
            sink.borrow_mut().push(json!({
                "id": id,
                "menu": menu,
                "title": title,
                "icon": icon,
                "when": when,
            }));
            Ok(())
        })?,
    )?;
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let list = contribs.borrow().clone();
    Ok(json!({ "ok": true, "contributions": list }))
}

fn invoke_impl(
    path: &str,
    action_id: &str,
    ctx_json: &str,
    allow_exec: bool,
) -> mlua::Result<Json> {
    let code = std::fs::read_to_string(path)
        .map_err(|e| mlua::Error::RuntimeError(format!("read {path}: {e}")))?;
    let ctx: Json = serde_json::from_str(ctx_json)
        .map_err(|e| mlua::Error::RuntimeError(format!("ctx json: {e}")))?;

    let lua = new_sandbox()?;
    let effects: Effects = Rc::new(RefCell::new(Vec::new()));
    let waydir = install_api(&lua, &effects, allow_exec)?;

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
    lua.globals().set("waydir", waydir)?;

    lua.load(&code).set_name(path).exec()?;

    let run = found.borrow_mut().take();
    let run = run.ok_or_else(|| {
        mlua::Error::RuntimeError(format!("action {action_id} not found"))
    })?;

    let ctx_tbl = lua.create_table()?;
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
    ctx_tbl.set("paths", paths_tbl)?;
    ctx_tbl.set("count", count)?;
    ctx_tbl.set("dir", ctx.get("dir").and_then(|v| v.as_str()).unwrap_or(""))?;
    ctx_tbl.set(
        "plugin_dir",
        ctx.get("plugin_dir").and_then(|v| v.as_str()).unwrap_or(""),
    )?;

    run.call::<Value>(ctx_tbl)?;

    let list = effects.borrow().clone();
    Ok(json!({ "ok": true, "effects": list }))
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
    allow_exec: i32,
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
    match invoke_impl(path, action_id, ctx_json, allow_exec != 0) {
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
