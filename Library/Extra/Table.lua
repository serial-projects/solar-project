local module = {}

--
function module.merge(destination, source)
    for _, value in ipairs(source) do
        destination[#destination+1] = value
    end
end

--
function module.sub(t, begins, ends)
    local new_table = {}
    for index = begins, ends do
        new_table[#new_table+1] = t[index]
    end
    return new_table
end

--
function module.enum(start, keys)
    local new_enum = {}
    for _, key in ipairs(keys) do
        new_enum[key] = start + #new_enum
    end
    return new_enum
end

--
function module.struct(default, replacement)
    local new_struct = {}
    for key, default_value in pairs(default) do
        local possible_replacement = replacement[key]
        if possible_replacement ~= nil then
            new_struct[key] = possible_replacement
        else
            new_struct[key] = default_value
        end
    end
    return new_struct
end

--
function module.reduce(t, operation)
    operation = operation or (function(acc, cur) return acc + cur end)
    assert(
        type(operation) == "function",
        "module.reduce(): operation accepts only functions."
    )
    local acc = 0
    for index = 1, #t do acc = operation(acc, t[index]) end
    return acc
end

--
function module.pop(t)
    local content ; if #t <= 0 then goto skip end
    content = t[#t] ; t[#t] = nil
    ::skip::
    return content
end

-- module.it_exist(t: table, entries: any, index_function: function(value: any)):
-- intra-table searcher.
function module.it_exist(t, entries, index_function)
    local counter = 0
    for _, value in pairs(entries) do
        if type(value) == "table" then
            if entries == index_function(value) then
                counter = counter + 1
            end
        end
    end
    return counter
end

--
function module.show(showing_table)
    local function show_table(current_table, current_depth)
        local buffer = ""
        local function buffer_push(fmt, ...)
            buffer = buffer .. (#{...} <= 0 and fmt or string.format(fmt, ...))
        end
        local padding = (function(length)
            local acc = ""
            for _ = 1, length do
                acc = acc .. " "
            end
            return acc
        end)(current_depth * 4)
        for key, value in pairs(current_table) do
            if type(value) == "table" then
                buffer_push("%skey = \"%s\"\n", padding, key)
                buffer_push("%s", show_table(value, current_depth + 1))
            else
                buffer_push("%skey = \"%s\" | value = \"%s\"\n", padding, tostring(key), tostring(value))
            end
        end
        return buffer
    end
    return show_table(showing_table, 0)
end

return module
