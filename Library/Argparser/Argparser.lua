--
local module = {}
local unpack = unpack or table.unpack
--
local function __assertf(condition, fmt, ...)
    if not condition then
        error(#{...} <= 0 and fmt or string.format(fmt, ...))
    end
end
local function __table_sub(t, begin, ends)
    local new_table = {}
    for index = begin, ends do
        new_table[#new_table+1] = t[index]
    end
    return new_table
end
--
function module.Argparse(args, argtable)
    local index, length = 1, #args
    local has_default = argtable["*"]
    -- 
    while index <= length do
        local argument = args[index]
        local possible_argument = argtable[argument]
        if possible_argument then
            if argument == "*" then
                error("Argparser.Argparse() wildcard not yet implemented.")
            end
            -- 
            local argument_struct = possible_argument
            if type(argument_struct) ~= "table" then
                repeat
                    argument_struct = argtable[argument_struct]
                until type(argument_struct) == "table"
            end
            --
            local wrap = argument_struct["wrap"]
            local nargs= argument_struct["nargs"] or 0
            if nargs <= 0 then
                wrap()
            else
                wrap(
                    unpack(__table_sub(args, (index + 1), (index + 1) + nargs))
                )
                index = index + nargs
            end
            --
        else
            if has_default then
                argtable["*"](argument)
            end
        end
        index = index + 1
    end
    --
end
--
return module