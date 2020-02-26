-- pantheon/bios
-- Modified ROM that removes CraftOS parts and makes everything
-- modifiable.
-- By daelvn
export PA_VERSION = "1.0"

native = {
  :getfenv
  :setfenv
  :load
  :loadstring
  :bit
  string:
    find:   string.find
    match:  string.match
    gmatch: string.gmatch
    gsub:   string.gsub
  os:
    shutdown: os.shutdown
    reboot:   os.reboot
  :error
  :type
  :getmetatable
}

-- Set blink=off
term.setCursorBlink false

-- Primitives
export PA_BREAK = -> while true do coroutine.yield!
export PA_PRINT = (txt) ->
  count = 0
  for ch in txt\gmatch "."
    count += 1
    if count > 51
      count = 0
      x, y = term.getCursorPos!
      term.setCursorPos 1, y+1
    term.write ch
  x, y = term.getCursorPos!
  term.setCursorPos 1, y+1

-- Start here
PA_PRINT "pantheon/bios #{PA_VERSION}"

export expect = (n, v, ts) ->
  for ty in *ts
    return true if ty == type v
  error "bad argument ##{n} (expected #{table.concat ts, ' or '}, got #{type v})", 2

PA_PRINT "Running #{_VERSION}"
if _VERSION == "Lua 5.1"
  -- Redefine load
  export load = (x, name, mode, env) ->
    expect 1, x,    {"string", "function"}
    expect 2, name, {"string", "nil"}
    expect 3, mode, {"string", "nil"}
    expect 4, env,  {"table",  "nil"}
    if mode and (mode != "t") and (debug == nil)
      error "Binary chunk loading prohibited", 2
    -- load chunk/function
    ok, p1, p2 = pcall ->
      loadf       = ("string" == type x) and native.loadstring or native.load
      result, err = loadf x, name
      if result
        if env
          env._ENV = env
          native.setfenv result, env
        return result
      else
        return nil, err
    -- return
    if ok
      return p1, p2
    else
      error  p1, 2
  
  -- Table functions
  table.unpack = unpack
  table.pack   = (...) -> return {n: (select "#", ...), ...}

  -- Install bit32 API
  export bit32 = {}
  bit32.arshift = native.bit.brshift
  bit32.band    = native.bit.band
  bit32.bnot    = native.bit.bnot
  bit32.bor     = native.bit.bor
  bit32.btest   = (a, b) -> (native.bit.band a, b) != 0
  bit32.bxor    = native.bit.bxor
  bit32.lshift  = native.bit.blshift
  bit32.rshift  = native.bit.blogic_rshift

  -- Fix embedded zeroes in string library
  string.find   = (s, pattern, ...) -> native.string.find   s, (native.string.gsub pattern, "%z", "%%z"), ...
  string.match  = (s, pattern, ...) -> native.string.match  s, (native.string.gsub pattern, "%z", "%%z"), ...
  string.gmatch = (s, pattern, ...) -> native.string.gmatch s, (native.string.gsub pattern, "%z", "%%z"), ...
  string.gsub   = (s, pattern, ...) -> native.string.gsub   s, (native.string.gsub pattern, "%z", "%%z"), ...

  -- Fix table.concat() error when a table is non-contiguous
  table.concat = (t, sep="", i=1, j=table.maxn t) ->
    local retval
    for n=i,j
      retval = (retval and (retval .. sep) or "") .. t[n] unless t[n] == nil
    return retval or ""

  -- Disable Lua 5.1 features?
  if _CC_DISABLE_LUA51_FEATURES
    -- Remove the Lua 5.1 features that will be removed when we update to Lua 5.2, for compatibility testing.
    -- See "disable_lua51_functions" in ComputerCraft.cfg
    setfenv    = nil
    getfenv    = nil
    loadstring = nil
    unpack     = nil
    math.log10 = nil
    table.maxn = nil
    bit        = nil

if _VERSION == "Lua 5.3"
  -- If we're on Lua 5.3, install the bit32 api from Lua 5.2
  -- (Loaded from a string so this file will still parse on <5.3 lua)
  (load [[
    bit32 = {}
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
    ]])!

PA_PRINT "Locking string metatable..."
if string.find _HOST, "ComputerCraft"
  -- Prevent access to metatables or environments of strings
  -- These are global across all computers
  string_mt = native.getmetatable ""
  -- redefine getmetatable
  export getmetatable = (t) ->
    mt = native.getmetatable t
    if mt == string_mt
      native.error "Attempt to access string metatable", 2
    return mt
  if (_VERSION == "Lua 5.1") and not _CC_DISABLE_LUA51_FEATURES
    string_env = native.getfenv ("").gsub
    -- redefine getfenv
    export getfenv = (env=2) ->
      env += 1 if ("number" == native.type env) and env > 0
      fenv = native.getfenv env
      if fenv == string_env
        return native.getfenv 0
      return fenv

-- Patch the error function on LuaJIT because specifying a level <= 0 crashes for some reason...?
if jit
  PA_PRINT "Running LuaJIT!"
  _G.error = (msg, level) -> if level <= 0 then native.error msg else native.error msg, level

-- Install Lua parts of the OS API
-- Pantheon:
--   os.version is not defined
--   os.run is not defined
--   os.loadAPI and os.unloadAPI are not defined
PA_PRINT "Load libos..."

os.pullEventRaw = coroutine.yield
os.pullEvent    = (filter) ->
  data = table.pack coroutine.yield filter
  if data[1] == "terminate"
    error "Terminated", 0
  return table.unpack data, 1, data.n

os.sleep = sleep

os.shutdown = ->
  native.os.shutdown!
  while true do coroutine.yield!

os.reboot = ->
  native.os.reboot!
  while true do coroutine.yield!

-- Install some globals
-- Pantheon:
--   write, PA_PRINT, PA_PRINTError and read are not defined
PA_PRINT "Exporting globals..."

export sleep = (time=0) ->
  expect 1, time, {"number"}
  timer = os.startTimer time
  while true
    event, param = os.pullEvent "timer"
    PA_BREAK if param == timer

export loadfile = (file, env) ->
  expect 1, file, {"string"}
  expect 2, env,  {"table", "nil"}
  safe = (x) -> if x then return x else return error: true
  with safe fs.open file, "r"
    return nil, "File not found" if .error
    name    = "@/" .. fs.combine (fs.getDir file), (fs.getName file)
    fn, err = load .readAll!, name, "t", env
    .close!
    return fn, err

export dofile = (file, env=_G) ->
  expect 1, file, {"string"}
  expect 2, env,  {"table"}
  fn, err = loadfile file, env
  if fn then return fn! else error err, 2

--PA_BREAK!

-- fs.complete is not defined
-- HTTP is defined in lib/http
-- Libraries must be loaded manually
-- PA_PRINT "Loading settings... (#{settings})"
-- PA_BREAK!

-- -- Set default settings
-- settings.set "shell.allow_startup",        true
-- settings.set "shell.allow_disk_startup",   (commands == nil)
-- settings.set "shell.autocomplete",         true
-- settings.set "shell.report_plugin_errors", true
-- settings.set "shell.store_history",        true
-- settings.set "edit.autocomplete",          true
-- settings.set "edit.default_extension",     "lua"
-- settings.set "paint.default_extension",    "nfp"
-- settings.set "lua.autocomplete",           true
-- settings.set "list.show_hidden",           false
-- settings.set "bios.use_cash",              false
-- settings.set "motd.enable",                false
-- settings.set "motd.path",                  "/motd.txt:/rom/motd.txt"
-- settings.set "bios.use_multishell",        true if term.isColour!

-- if _CC_DEFAULT_SETTINGS
--   for pair in _CC_DEFAULT_SETTINGS\gmatch "[^,]+"
--     name, value = pair\match "([^=]*)=(.*)"
--     if name and value
--       local val
--       switch value
--         when "true"  then val = true
--         when "false" then val = false
--         when "nil"   then val = nil
--         else
--           if tonumber value
--             val = tonumber value
--           else
--             val = value
--       if val != nil
--         settings.set name, val
--       else
--         settings.unset name

-- Run CCPC script
PA_PRINT "Loading startup script..."
if _CCPC_STARTUP_SCRIPT
  fn, err = load(_CCPC_STARTUP_SCRIPT, "@startup.lua", "t", _ENV)
  if fn
    args = {}
    if _CCPC_STARTUP_ARGS then for n in _CCPC_STARTUP_ARGS\gmatch "[^ ]+" do table.insert(args, n)
    fn table.unpack args
  else
    PA_PRINT "Could not load startup script: " .. err
    PA_BREAK!

-- User settings are not loaded
-- Shell is not run from bios, but instead an entrypoint
-- /entry.lua is the entrypoint
ok, err = pcall -> dofile "/entry.lua"
if not ok
  PA_PRINT "FATAL ERROR: #{err}"
  PA_BREAK! 

-- End of BIOS
term.redirect term.native!
os.shutdown!