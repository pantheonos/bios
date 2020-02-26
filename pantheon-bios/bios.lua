PA_VERSION = "1.0"
local native = {
  getfenv = getfenv,
  setfenv = setfenv,
  load = load,
  loadstring = loadstring,
  bit = bit,
  string = {
    find = string.find,
    match = string.match,
    gmatch = string.gmatch,
    gsub = string.gsub
  },
  os = {
    shutdown = os.shutdown,
    reboot = os.reboot
  },
  error = error,
  type = type,
  getmetatable = getmetatable
}
term.setCursorBlink(false)
PA_BREAK = function()
  while true do
    coroutine.yield()
  end
end
PA_PRINT = function(txt)
  local count = 0
  for ch in txt:gmatch(".") do
    count = count + 1
    if count > 51 then
      count = 0
      local x, y = term.getCursorPos()
      term.setCursorPos(1, y + 1)
    end
    term.write(ch)
  end
  local x, y = term.getCursorPos()
  return term.setCursorPos(1, y + 1)
end
PA_PRINT("pantheon/bios " .. tostring(PA_VERSION))
expect = function(n, v, ts)
  for _index_0 = 1, #ts do
    local ty = ts[_index_0]
    if ty == type(v) then
      return true
    end
  end
  return error("bad argument #" .. tostring(n) .. " (expected " .. tostring(table.concat(ts, ' or ')) .. ", got " .. tostring(type(v)) .. ")", 2)
end
PA_PRINT("Running " .. tostring(_VERSION))
if _VERSION == "Lua 5.1" then
  load = function(x, name, mode, env)
    expect(1, x, {
      "string",
      "function"
    })
    expect(2, name, {
      "string",
      "nil"
    })
    expect(3, mode, {
      "string",
      "nil"
    })
    expect(4, env, {
      "table",
      "nil"
    })
    if mode and (mode ~= "t") and (debug == nil) then
      error("Binary chunk loading prohibited", 2)
    end
    local ok, p1, p2 = pcall(function()
      local loadf = ("string" == type(x)) and native.loadstring or native.load
      local result, err = loadf(x, name)
      if result then
        if env then
          env._ENV = env
          native.setfenv(result, env)
        end
        return result
      else
        return nil, err
      end
    end)
    if ok then
      return p1, p2
    else
      return error(p1, 2)
    end
  end
  table.unpack = unpack
  table.pack = function(...)
    return {
      n = (select("#", ...)),
      ...
    }
  end
  bit32 = { }
  bit32.arshift = native.bit.brshift
  bit32.band = native.bit.band
  bit32.bnot = native.bit.bnot
  bit32.bor = native.bit.bor
  bit32.btest = function(a, b)
    return (native.bit.band(a, b)) ~= 0
  end
  bit32.bxor = native.bit.bxor
  bit32.lshift = native.bit.blshift
  bit32.rshift = native.bit.blogic_rshift
  string.find = function(s, pattern, ...)
    return native.string.find(s, (native.string.gsub(pattern, "%z", "%%z")), ...)
  end
  string.match = function(s, pattern, ...)
    return native.string.match(s, (native.string.gsub(pattern, "%z", "%%z")), ...)
  end
  string.gmatch = function(s, pattern, ...)
    return native.string.gmatch(s, (native.string.gsub(pattern, "%z", "%%z")), ...)
  end
  string.gsub = function(s, pattern, ...)
    return native.string.gsub(s, (native.string.gsub(pattern, "%z", "%%z")), ...)
  end
  table.concat = function(t, sep, i, j)
    if sep == nil then
      sep = ""
    end
    if i == nil then
      i = 1
    end
    if j == nil then
      j = table.maxn(t)
    end
    local retval
    for n = i, j do
      if not (t[n] == nil) then
        retval = (retval and (retval .. sep) or "") .. t[n]
      end
    end
    return retval or ""
  end
  if _CC_DISABLE_LUA51_FEATURES then
    local setfenv = nil
    local getfenv = nil
    local loadstring = nil
    local unpack = nil
    math.log10 = nil
    table.maxn = nil
    local bit = nil
  end
end
if _VERSION == "Lua 5.3" then
  (load([[    bit32 = {}
    function bit32.arshift( n, bits )
        if type(n) ~= "number" or type(bits) ~= "number" then
            error( "Expected number, number", 2 )
        end
        return n >> bits
    end
    function bit32.band( m, n )
        if type(m) ~= "number" or type(n) ~= "number" then
            error( "Expected number, number", 2 )
        end
        return m & n
    end
    function bit32.bnot( n )
        if type(n) ~= "number" then
            error( "Expected number", 2 )
        end
        return ~n
    end
    function bit32.bor( m, n )
        if type(m) ~= "number" or type(n) ~= "number" then
            error( "Expected number, number", 2 )
        end
        return m | n
    end
    function bit32.btest( m, n )
      if type(m) ~= "number" or type(n) ~= "number" then
        error( "Expected number, number", 2 )
      end
      return (m & n) ~= 0
    end
    function bit32.bxor( m, n )
      if type(m) ~= "number" or type(n) ~= "number" then
        error( "Expected number, number", 2 )
      end
      return m ~ n
    end
    function bit32.lshift( n, bits )
      if type(n) ~= "number" or type(bits) ~= "number" then
        error( "Expected number, number", 2 )
      end
      return n << bits
    end
    function bit32.rshift( n, bits )
      if type(n) ~= "number" or type(bits) ~= "number" then
        error( "Expected number, number", 2 )
      end
      return n >> bits
    end
    ]]))()
end
PA_PRINT("Locking string metatable...")
if string.find(_HOST, "ComputerCraft") then
  local string_mt = native.getmetatable("")
  getmetatable = function(t)
    local mt = native.getmetatable(t)
    if mt == string_mt then
      native.error("Attempt to access string metatable", 2)
    end
    return mt
  end
  if (_VERSION == "Lua 5.1") and not _CC_DISABLE_LUA51_FEATURES then
    local string_env = native.getfenv(("").gsub)
    getfenv = function(env)
      if env == nil then
        env = 2
      end
      if ("number" == native.type(env)) and env > 0 then
        env = env + 1
      end
      local fenv = native.getfenv(env)
      if fenv == string_env then
        return native.getfenv(0)
      end
      return fenv
    end
  end
end
if jit then
  PA_PRINT("Running LuaJIT!")
  _G.error = function(msg, level)
    if level <= 0 then
      return native.error(msg)
    else
      return native.error(msg, level)
    end
  end
end
PA_PRINT("Load libos...")
os.pullEventRaw = coroutine.yield
os.pullEvent = function(filter)
  local data = table.pack(coroutine.yield(filter))
  if data[1] == "terminate" then
    error("Terminated", 0)
  end
  return table.unpack(data, 1, data.n)
end
os.sleep = sleep
os.shutdown = function()
  native.os.shutdown()
  while true do
    coroutine.yield()
  end
end
os.reboot = function()
  native.os.reboot()
  while true do
    coroutine.yield()
  end
end
PA_PRINT("Exporting globals...")
sleep = function(time)
  if time == nil then
    time = 0
  end
  expect(1, time, {
    "number"
  })
  local timer = os.startTimer(time)
  while true do
    local event, param = os.pullEvent("timer")
    if param == timer then
      local _ = PA_BREAK
    end
  end
end
loadfile = function(file, env)
  expect(1, file, {
    "string"
  })
  expect(2, env, {
    "table",
    "nil"
  })
  local safe
  safe = function(x)
    if x then
      return x
    else
      return {
        error = true
      }
    end
  end
  do
    local _with_0 = safe(fs.open(file, "r"))
    if _with_0.error then
      return nil, "File not found"
    end
    local name = "@/" .. fs.combine((fs.getDir(file)), (fs.getName(file)))
    local fn, err = load(_with_0.readAll(), name, "t", env)
    _with_0.close()
    return fn, err
  end
end
dofile = function(file, env)
  if env == nil then
    env = _G
  end
  expect(1, file, {
    "string"
  })
  expect(2, env, {
    "table"
  })
  local fn, err = loadfile(file, env)
  if fn then
    return fn()
  else
    return error(err, 2)
  end
end
PA_PRINT("Loading startup script...")
if _CCPC_STARTUP_SCRIPT then
  local fn, err = load(_CCPC_STARTUP_SCRIPT, "@startup.lua", "t", _ENV)
  if fn then
    local args = { }
    if _CCPC_STARTUP_ARGS then
      for n in _CCPC_STARTUP_ARGS:gmatch("[^ ]+") do
        table.insert(args, n)
      end
    end
    fn(table.unpack(args))
  else
    PA_PRINT("Could not load startup script: " .. err)
    PA_BREAK()
  end
end
local ok, err = pcall(function()
  return dofile("/entry.lua")
end)
if not ok then
  PA_PRINT("FATAL ERROR: " .. tostring(err))
  PA_BREAK()
end
term.redirect(term.native())
return os.shutdown()
