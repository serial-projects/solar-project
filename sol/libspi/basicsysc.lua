local spi_instance = require("sol.libspi.instance")
local module = {}
function module.SPI_GenerateBasicSystemCallsTable()
  return {
    -- puts(message[r0]: string) -> nothing
    ["puts"] = function(_, instance)
      dmsg(tostring(instance.registers.R0))
    end,
    -- write(message[r0]: string) -> nothing
    ["write"]= function(_, instance)
      dmsg("thread name: %s, R0 says: \"%s\"", instance.name, instance.registers.R0)
    end,
    -- exit(exit_code[r0]: number) -> nothing
    ["exit"] = function(_, instance)
      os.exit(type(instance.registers.R0)=="number" or instance.registers.R0 or 0)
    end,
    -- new_thread(begin_at[r0]: string | "main", thread_name[r1]: string | random name ... ) -> new_thread
    ["new_thread"] = function(context, instance)
      local begin_at    = type(instance.registers.R0) == "string" and instance.registers.R0 or "main"
      local thread_name = type(instance.registers.R1) == "string" and instance.registers.R1 or ( instance.name .. "$" .. string.genstr() )
      if not context.label_addr[begin_at] then
        instance:set_error("new_thread request failed, no label: %s", begin_at)
      else
        local proto_thread = spi_instance.SPI_NewInstance(thread_name)
        proto_thread.registers.PC = context.label_addr[begin_at]
        table.insert(context.spawned_threads, proto_thread)
      end
    end,
    -- get_state_thread(thread_name[r0]: string) -> number[r0] | at_error: -1 (no thread found), -2 (no target set) [r0]
    ["get_state_thread"] = function(context, instance)
      local target_name = type(instance.registers.R0) == "string" and instance.registers.R0 or nil
      if target_name then
        for _, thread in ipairs(context.spawned_threads) do
          if thread.name == target_name then
            instance.registers.R0 = thread.status
            return
          end
        end
      else
        instance.registers.R0 = -2
      end
      instance.registers.R0 = -1
    end,
  }
end
return module