-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local consts = require ("Library.SPI.Consts")
--
-- SPI (Simple Programming Interface) by Pipes Studios.
-- The SPI project has the simple objective of being a simple language, without
-- any complications or problems, it follows the syntax of assembler.
--
_G.SPI_UseOpenFunction = love.filesystem.newFile

local module = {}

module.basicsysc    = require("Library.SPI.BasicSystemCalls")
module.instance     = require("Library.SPI.Instance")
module.text         = require("Library.SPI.Text")
module.consts       = require("Library.SPI.Consts")

local EString       = require("Library.Extra.String")
local ETable        = require("Library.Extra.Table")

-- SPI_NewContext(recipe: {name = string | nil:string.genstr() })
function module.SPI_NewContext(recipe)
    recipe = recipe or {}
    return {
        name            = recipe["name"] or EString.genustr(),
        system_calls    = module.basicsysc.SPI_GenerateBasicSystemCallsTable(),
        code            = {},
        label_addr      = {},
        spawned_threads = {},
        instance        = nil,
        performance	    = 20,
        global_scope    = {},
    }
end

-- SPI_LoadContextCodeUsingFile(context: SPI_Context, file_name: string, use_open_wrapper: function | io.open):
function module.SPI_LoadContextUsingFile(context, file_name, use_open_wrapper)
    --> open the file & tokenize it:
    use_open_wrapper = use_open_wrapper or io.open
    local file_pointer = use_open_wrapper(file_name, "r")
    local file_token_sequence = {}
    if file_pointer then
        for line in file_pointer:lines() do
            local tokenized_line = module.text.SPI_Tokenize(line)
            ETable.merge(file_token_sequence, tokenized_line)
        end
    else
        error("could not open file: "..file_name)
    end
    file_pointer:close()
    --> initialize the main instance & map the labels.
    context.instance = module.instance.SPI_NewInstance(file_name .. "#main")
    local index, length = 1, #file_token_sequence
    while index <= length do
        local current_token = file_token_sequence[index]
        if current_token:sub(#current_token, #current_token) == ':' then
            local label_name = current_token:sub(1, #current_token - 1)
            local label_already_exists = context.label_addr[label_name]
            if label_already_exists then
                error(string.format("duplicated label found: %s, previous address: %d", label_name, label_already_exists))
            end
            local label_addr = #context.code + 1
            context.label_addr[label_name] = label_addr
        else
            table.insert(context.code, current_token)
        end
        index = index + 1
    end
    -- if main label is defined, then start by the main label:
    if context.label_addr["main"] then
        context.instance.registers.PC = context.label_addr["main"]
    end
end

-- SPI_HasContextDied(context: SPI_Context) -> has_died: boolean, error_msg: string | nil
function module.SPI_HasContextDied(context)
    return context.instance.status == consts.SPI_InstanceStatus.DIED, context.instance.error_msg
end

-- SPI_ClearAllThreadsFromContext(context: SPI_Context) -> nil
function module.SPI_ClearAllThreadsFromContext(context)
    for tindex, _ in ipairs(context.spawned_threads) do
        context.spawned_threads[tindex] = nil
    end
end

-- SPI_ClearContext(context: SPI_Context) -> nil
function module.SPI_ClearContext(context)
    module.SPI_ClearAllThreadsFromContext(context)
    context.instance = nil
    collectgarbage("collect")
end

-- SPI_SetInstanceLocation(context: SPI_Context, instance_name: string, location_name: string) (crashable: yes) -> nil
function module.SPI_SetInstanceLocation(context, instance_name, location_name)
    local location_addr = context.label_addr[location_name]
    assert(location_addr, "invalid location: " .. location_name)
    if instance_name == "main" then
        context.instance.registers.PC = location_addr
    else
        for _, thread in ipairs(context.spawned_threads) do
            thread.registers.PC = location_addr
        end
    end
end

-- SPI_TickContext(context: SPI_Context) -> main_thread_status: number
function module.SPI_TickContext(context)
    -- NOTE: if the main thread dies or finishes it task, clear all the running/waiting, etc. threads that
    -- spawned later on to prevent over memory usage.
    local current_main_thread_statement = module.instance.SPI_TickInstance(context, context.instance)
    if current_main_thread_statement >= consts.SPI_InstanceStatus.FINISHED and current_main_thread_statement <= consts.SPI_InstanceStatus.DIED then
        module.SPI_ClearAllThreadsFromContext(context)
    end
    --> tick all the threads:
    for _, thread in ipairs(context.spawned_threads) do
        module.instance.SPI_TickInstance(context, thread)
    end
    --> return the current thread statement:
    return current_main_thread_statement
end

return module