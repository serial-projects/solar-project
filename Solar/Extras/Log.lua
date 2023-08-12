-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

-- xlog.lua: load the logging functions :^)
_G["LogImported"] = true

-- :: utility for logging :: --
local REPL_DEBUG_WITH = "\27[37mDEBUG\27[0m"
local REPL_WARN_WITH  = "\27[33mWARN\27[0m"
local REPL_MSG_WITH   = "\27[34mMSG\27[0m"
local REPL_CRASH_WITH = "\27[31mCRASH\27[0m"

-- TODO: on the future, implement a better markup system.
_G.dologmarkup = function(s)
  local do_replacements = {
    {target = "DEBUG", repl = REPL_DEBUG_WITH},
    {target = "WARN", repl = REPL_WARN_WITH},
    {target = "MSG", repl = REPL_MSG_WITH},
    {target = "CRASH", repl = REPL_CRASH_WITH}
  }
  for _, replacement in ipairs(do_replacements) do
    local amount_changed = 0
    s, amount_changed = string.gsub(s, replacement.target, replacement.repl, 1)
    if amount_changed > 0 then break end
  end
  return s
end

-- :: logging :: --
_G.loggers = {{name = "print", enabled = false, wrap = print, use_markup = true}}
_G.msg_counter = 0.000001

_G.pushlogger = function(logger) _G.loggers[#_G.loggers+1]=logger end

_G.findlogger = function(logger_name)
  for _, logger in ipairs(_G.loggers) do
    if logger.name == logger_name then
      return logger
    end
  end
  return nil
end

_G.setlogger = function(logger_name, logger_property, value)
  local logger = _G.findlogger(logger_name)
  if not logger then return false
  else logger[logger_property] = value end
  return true
end

_G.genericPrint=function(fmt, ...)
  local function get_timestamp()
    return os.date("%d/%m/%Y %H:%M:%S", os.time())
  end
  fmt = string.format("(%s) [%f] ", get_timestamp(), _G.msg_counter) .. fmt
  --
  local function print_all_loggers(wraplist, text)
    for _, wrap_structure in ipairs(wraplist) do
      if wrap_structure.enabled then wrap_structure.wrap(wrap_structure.use_markup and _G.dologmarkup(text) or text) end
    end
  end
  if #{...} < 1 then print_all_loggers(_G.loggers,fmt)
  else print_all_loggers(_G.loggers,string.format(fmt, ...)) end
  _G.msg_counter=_G.msg_counter+0.000001
end

_G.logfileset = function(fname)
  -- remove all the past content from the file.
  local fp = io.open(fname, "w")
  if not fp then return end
  fp:close()
  -- build a small "class" for this element.
  local prototype_logfile = { fname = fname }
  setmetatable(prototype_logfile, {
    __call = function (t, msg)
      local fp = io.open(t.fname, "a")
      if not fp then return end
      fp:write(string.format("%s: %s\n", t.fname, msg)) ; fp:flush()
      fp:close()
    end
  })
  --
  _G.pushlogger({ name = string.format("logfile#%s", fname), enabled = true, wrap = prototype_logfile })
end

-- debugging & logging information.
_G.setdebug = function(debug_status)
  _G.setlogger("print", "enabled", debug_status)
end

_G.dmsg =function(fmt, ...) _G.genericPrint("[DEBUG]: " .. fmt, ...) end
_G.mwarn=function(fmt, ...) _G.genericPrint("[ WARN]: " .. fmt, ...) end
_G.msg  =function(fmt, ...) _G.genericPrint("[  MSG]: " .. fmt, ...) end

_G.qcrash=function(exit_code, fmt, ...)   _G.genericPrint("[CRASH]: "..fmt, ...) os.exit(exit_code) end

-- other logging features:
_G.makesure=function(condition, code, when_error, ...)
  if not condition then _G.qcrash(code, when_error, ...) end
end

-- more specifics and interactives:
_G.stopexec=function(message)
  print(string.format("\n-- _G.stopexec() was called, reason: \"%s\"", message or "??"))
  print(debug.traceback(""))
  ::top::
  io.write("[k] = keep executing, [d] = join debug.debug(), [e] = exit (not saving!): ")
  local input=string.lower(io.read())
  if      input == "d" then  debug.debug()
  elseif  input == "e" then  love.event.quit(-1) ; os.exit(-1)
  elseif  input ~= "k" then  goto top end
end
