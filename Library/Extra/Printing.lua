local module = {}

--
local sfmt = string.format

function _G.sprintf(fmt, ...)
    local s = ""
    if #{...} <= 0 then
        s = fmt
    else
        s = sfmt(fmt, ...)
    end
    return s
end
--
function _G.printf(fmt, ...)
    return sprintf(fmt, ...)
end
--
function _G.assertf(condition, fmt, ...)
    if not condition then
        error(sprintf(fmt, ...))
    end
end

-- logging.new_wrap_unit(properties: table): this generates a new unit that
-- wrap an function, ex: print, io.write, etc. The properties can be:
--  enabled:    if the unit is currently enabled.
--  wrap:       what the unit is wrapping.
function module.new_wrap_unit(properties)
    --
    local proto_wrap_unit = {
        enabled     = properties["enabled"]     or true,
        wrap        = properties["wrap"]        or false,
    }
    --
    function proto_wrap_unit:show(message)
        if type(self.wrap) == "function" and self.enabled then
            self.wrap(message)
        end
    end
    --
    return proto_wrap_unit
end

-- logging.new_file_unit(properties: table): this generates a unit that handles
-- file operations. For convenience, the file hold is only the path and not the
-- actual pointer to it. Properties are: 
--  enabled:    if the unit is currently enabled.
--  path:       the path of the file to use.
function module.new_file_unit(properties)
    --
    local proto_file_unit = {
        custom_open = properties["custom_open"] or io.open,
        enabled     = properties["enabled"]     or true,
        path        = properties["path"]        or false,
        new         = true,
    }
    --
    function proto_file_unit:show(message)
        -- NOTE: use dirty trick for single change variable :^)
        local file_pointer = self.custom_open(
            self.path,
            self.new and (function() self.new = false ; return "w" end)() or "a"
        )
        --
        assertf(file_pointer, "unit failed to open file: %s", self.path)
        --
        file_pointer:write(message .. '\n')     ---@diagnostic disable-line
        file_pointer:close()                    ---@diagnostic disable-line
    end
    --
    return proto_file_unit
end

-- logging.new(properties: table): this generates a new logger instance, it
-- contains the logger units. The properties table can take the several keys:
--  enabled:    if the logger instance is enabled.
--  en_msg:     enable logger:msg() to show messages.
--  en_debug:   enable logger:debug() to show messages.
--  en_warn:    enable logger:warn() to show messages.
--  en_error:   enable logger:error() to show messages.
--  en_colors:  on units that is not file, set colors (UNIX* only).

function module.new(properties) properties = properties or {}
    --
    local proto_logger = {
        enabled     = properties["enabled"]     or true,
        level       = properties["level"]       or false,
        en_msg      = properties["en_msg"]      or true,
        en_debug    = properties["en_debug"]    or false,
        en_warn     = properties["en_warn"]     or false,
        en_error    = properties["en_error"]    or false,
        units       = {}
    }
    --
    function proto_logger:add_unit(name, unit)
        self.units[name] = unit
    end
    --
    function proto_logger:trigger_units(message)
        for _, unit in pairs(self.units) do
            unit:show(message)
        end
    end
    --
    function proto_logger:write(mode, fmt, ...)
        local timestamp = os.date("%d/%m/%Y %H:%M:%S", os.time())
        if self["en_" .. mode] == true then
            self:trigger_units(
                sfmt("[%s]: ", timestamp) .. ( (#{...} <= 0) and fmt or sfmt(fmt, ...) )
            )
        end
    end
    --
    function proto_logger:msg(fmt, ...)
        local content = "[  MSG]: " .. fmt
        self:write("msg", content, ...)
    end
    function proto_logger:debug(fmt, ...)
        local content = "[DEBUG]: " .. fmt
        self:write("debug", content, ...)
    end
    function proto_logger:warn(fmt, ...)
        local content = "[ WARN]: " .. fmt
        self:write("warn", content, ...)
    end
    function proto_logger:error(fmt, ...)
        local content = "[ERROR]: " .. fmt
        self:write("error", content, ...)
    end
    --
    return proto_logger
end

return module