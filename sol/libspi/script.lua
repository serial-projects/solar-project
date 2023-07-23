local consts = require "sol.libspi.consts"
--
-- SPI (Simple Programming Interface) by Pipes Studios.
-- The SPI project has the simple objective of being a simple language, without
-- any complications or problems, it follows the syntax of assembler.
--
_G.SPI_UseOpenFunction = love.filesystem.newFile

local module = {}
module.basicsysc=require("sol.libspi.basicsysc")
module.instance =require("sol.libspi.instance")
module.text     =require("sol.libspi.text")

function module.SPI_NewContext(recipe)
  recipe = recipe or {}
  return {
    name            = recipe["name"] or string.genstr(),
    system_calls    = module.basicsysc.SPI_GenerateBasicSystemCallsTable(),
    code            = {},
    label_addr      = {},
    spawned_threads = {},
    instance        = nil
  }
end
-- SPI_LoadContextCodeUsingFile(context: SPI_Context, file_name: string, use_open_wrapper: function | io.open):
-- the context can have multiple threads BUT, they live on the same shared code, this is
-- done to prevent extreme memory usage. If each thread had it own code, that would result
-- in more memory usage.
function module.SPI_LoadContextUsingFile(context, file_name, use_open_wrapper)
  --> open the file & tokenize it:
  use_open_wrapper = use_open_wrapper or io.open
  local file_pointer = use_open_wrapper(file_name, "r")
  local file_token_sequence = {}
  if file_pointer then
    for line in file_pointer:lines() do
      local tokenized_line = module.text.SPI_Tokenize(line)
      table.unimerge(file_token_sequence, tokenized_line)
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
function module.SPI_HasContextDied(context)
  return context.instance.status == consts.SPI_InstanceStatus.DIED, context.instance.error_msg
end
function module.SPI_TickContext(context)
  --> tick the main thread first:
  local current_main_thread_statement = module.instance.SPI_TickInstance(context, context.instance)
  if current_main_thread_statement >= 2 and current_main_thread_statement <= 4 then
    return false
  end
  --> tick all the other spawned threads:
  -- NOTE: for better freedom, threads are not recycled HERE, use "kill_zombie_threads"
  for _, thread in ipairs(context.spawned_threads) do
    module.instance.SPI_TickInstance(context, thread)
  end
  --> return true :)
  return true
end
function module.SPI_RunContext(context)
  while true do
    local current_context_state = module.SPI_TickContext(context)
    if not current_context_state then break end
  end
end
return module