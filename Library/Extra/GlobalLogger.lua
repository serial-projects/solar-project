local Printing = require("Library.Extra.Printing")

-- NOTE: due project large proportions, use a global logger.
_G.GlobalLogger = Printing.new()
_G.GlobalLogger:add_unit("main", Printing.new_wrap_unit({ wrap = function(s) io.stdout:write(s..'\n') end}))

function _G.msg (fmt, ...)  _G.GlobalLogger:write("msg"     , fmt, ...)     end
function _G.dmsg(fmt, ...)  _G.GlobalLogger:write("debug"   , fmt, ...)     end
function _G.mwarn(fmt, ...) _G.GlobalLogger:write("warn"    , fmt, ...)     end
function _G.emsg(fmt, ...)  _G.GlobalLogger:write("error"   , fmt, ...)     end

function _G.stopexec(message)
    print(string.format("\n-- _G.stopexec() was called, reason: \"%s\"", message or "??"))
    print(debug.traceback(""))
    ::top::
    io.write("[k] = keep executing, [d] = join debug.debug(), [e] = exit (not saving!): ")
    local input=string.lower(io.read())
    if      input == "d" then  debug.debug()
    elseif  input == "e" then  love.event.quit(-1) ; os.exit(-1)
    elseif  input ~= "k" then  goto top end
end