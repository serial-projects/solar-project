local module = {}

function module.encode_syntax_tree(syntax_tree, settings) settings = settings or {}
    local LEFT_PADDING  = settings["left_padding"] or 4
    local INCLUDE_HEADER= settings["include_header"] or false
    --
    local build_types = {
        ["string"] = function(working_string)
            return "\"" .. working_string .. "\""
        end,
        ["number"] = function(working_number)
            return tostring(working_number)
        end,
        ["boolean"] = function(working_boolean)
            return (working_boolean == "yes" or working_boolean == "true") and "yes" or "no"
        end
    }
    build_types["table"] = function(working_table)
        local acc = "["
        for index, content in ipairs(working_table) do
            acc = acc .. build_types[type(content)](content) .. ( (index < #working_table) and ", " or "" )
        end
        acc = acc .. "]"
        return acc
    end
    local function __generate_header()
        return string.format(
            "# Lucie Generated Code (Lua: %s, jit? %s), Lucie Version: %s\n",
            _VERSION,
            _G["jit"] and "yes" or "no",
            require("Library.Lucie.Consts").LUCIE_VERSION
        )
    end
    --
    local function encode_section(section_table, depth)
        local buffer = (depth == 0 and INCLUDE_HEADER) and __generate_header() or ""
        local padding = (function(length)
            local acc = ""
            for _ = 1, length do
                acc = acc .. " "
            end
            return acc
        end)(depth * LEFT_PADDING)
        local function bpush(use_padding, fmt, ...)
            buffer = buffer .. ( (use_padding and padding or "" ) .. (#{...} <= 0 and fmt or string.format(fmt, ...)) )
        end
        for _, value in ipairs(section_table) do
            if value["type"] == "data" then
                local built_value = build_types[type(value["content"])](value["content"])
                bpush(true, "set %s, %s\n", value["name"], built_value)
            else
                bpush(true, "section %s\n", value["name"])
                bpush(false, "%s", encode_section(value["content"], depth + 1))
                bpush(true, "end\n")
            end
        end
        return buffer
    end
    return encode_section(syntax_tree, 0)
end

return module
