local module = {}

local sbyte = string.byte
local schar = string.char

local function __generate_using_function(length, generator_function)
    local new_string = ""
    for index = 1, length do
        new_string = new_string .. generator_function(index)
    end
    return new_string
end
local function __generate_using_string(length, generator_character)
    local new_string = ""
    for _ = 1, length do
        new_string = new_string .. generator_character
    end
    return new_string
end
function module.gen(length, generator)
    local content
    if type(generator) == "function" then
        content = __generate_using_function(length, generator)
    elseif type(generator) == "string" then
        content = __generate_using_string(length, generator)
    else
        error("string.gen() generator can only accept string or function as type!")
    end
    return content
end
--

string.unique_strings = {[""]=true}
local __string_genstr_banks = {
    { begins = sbyte('a'), ends = sbyte('z') },
    { begins = sbyte('A'), ends = sbyte('Z') },
    { begins = sbyte('0'), ends = sbyte('9') }
}
function module.genustr(length)
    local acc = ""
    while string.unique_strings[acc] do
        for _ = 1, length do
            local selected_bank = __string_genstr_banks[
                math.random(1, #__string_genstr_banks)
            ]
            acc = acc .. schar(
                math.random(selected_bank.begins, selected_bank.ends)
            )
        end
    end
    string.unique_strings[acc] = true
    return acc
end

-- string.setvars(str: string, variables: table): automatically fixes the ${var}
-- pattern and return the string with the value already sub.
function module.setvars(str, variables)
    local VAR_DELIMITATIONS = "${"
    --
    local new_string = ""
    local index, length = 1, #str
    --
    local function adquire_variable_name()
        index = index + 2
        local adquired_name = ""
        while index <= length do
            local char = str:sub(index, index)
            if char == '}' then
                break
            else
                adquired_name = adquired_name .. char
            end
            index = index + 1
        end
        return adquired_name
    end
    --
    while index <= length do
        local char = str:sub(index, index)
        local nch  = index <= length and str:sub(index + 1, index + 1) or ""
        if (char .. nch) == '${' then
            local variable_name = adquire_variable_name()
            local variable_value= variables[variable_name]
            new_string = new_string .. (
                variable_value ~= nil and tostring(variable_value) or ""
            )
        else
            new_string = new_string .. char
        end
        index = index + 1
    end
    --
    return new_string
end

---@param s string
---@param char string
function module.findch(s, char, begin_indexing) begin_indexing = begin_indexing or 1
    for index = begin_indexing, #s do
        local ch = s:sub(index, index)
        if ch == char then
            return index
        end
    end
    return nil
end

return module