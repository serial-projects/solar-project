local module = {}

local sfmt = string.format

--- Creates a new file unit for the logger, the function can also accept
--- files that are always open (such as io.stdout).
---@param output string | table
---@param level number
---@param use_color boolean
---@param always_open boolean
function module.newFileUnit(output, level, use_color, always_open)
    use_color = use_color or false
    always_open = always_open or false
    local proto_fileunit = {
        output      = output,
        min_level   = (level or 0),
        dead        = false,
        use_color   = use_color,
        always_open = false,
    }
    --- Write a message to the desired output.
    ---@param fmt string
    ---@param ... any
    function proto_fileunit:write(fmt, ...)
        if self.dead then goto due_death_skip end
        if self.always_open then
            -- NOTE: when the output is just io.stdout
            self.output:write(sfmt(fmt, ...) .. '\n')
            self.output:flush()
        else
            -- NOTE: disable next line because what should decide what type is
            -- currently on the output is self.always_open.
            ---@diagnostic disable-next-line
            local __FP = io.open(self.output, "a")
            if not __FP then
                self.dead = true
                return
            end
            __FP:write(sfmt(fmt, ...) .. '\n')
            __FP:close()
        end
        ::due_death_skip::
    end
    return proto_fileunit
end

--- Logger holds the unit and decides what units to write a message.

module.LEVEL_MSG    = 0
module.LEVEL_DEBUG  = 1
module.LEVEL_WARN   = 2
module.LEVEL_ERROR  = 3

function module.newLogger()
    local proto_logger = {
        units   = {},
        enabled = false,
        counter = 0,
        levels  = {
            [module.LEVEL_MSG]      = { name = "Message",   color = "\27[1;32"  },
            [module.LEVEL_DEBUG]    = { name = "Debug",     color = "\27[1;36m" },
            [module.LEVEL_WARN]     = { name = "Warning",   color = "\27[1;33m" },
            [module.LEVEL_ERROR]    = { name = "Error",     color = "\27[5m\27[4m\27[1;31m" }
        }
    }
    --- Write a message to pass to all the units.
    ---@param level number
    ---@param fmt string
    ---@param ... any
    function proto_logger:write(level, fmt, ...)
        if not self.enabled then
            goto skip_everything_due_disabled
        end
        local header = sfmt("[%s] [%0.8d] ", os.date("%d/%m/%Y %H:%M:%S", os.time()), self.counter)
        for _, unit in pairs(self.units) do
            if unit.level >= level then
                unit:write(
                    header .. fmt,
                ...)
            end
        end
        self.counter = self.counter + 1
        ::skip_everything_due_disabled::
    end
    function proto_logger:addUnit(name, unit)
        self.units[name] = unit
    end
    return proto_logger
end

-- NOTE: due project large proportions, use a global logger.
_G.GlobalLogger = module.newLogger()
_G.GlobalLogger:addUnit("main", module.newFileUnit(io.stdout, 3, true, true))

function _G.msg (fmt, ...)  _G.GlobalLogger:write(module.LEVEL_MSG, fmt, ...)   end
function _G.dmsg(fmt, ...)  _G.GlobalLogger:write(module.LEVEL_DEBUG, fmt, ...) end
function _G.mwarn(fmt, ...) _G.GlobalLogger:write(module.LEVEL_WARN, fmt, ...)  end
function _G.emsg(fmt, ...)  _G.GlobalLogger:write(module.LEVEL_ERR, fmt, ...)   end

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

return module