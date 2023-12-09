-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local consts      =require("Solar.libspi.consts")
local operations  =require("Solar.libspi.operation")
local module = {}
function module.SPI_define(context, instance, source, destination)
  local destination_value = operations.SPI_GetDataFromInstance(context, instance, destination)
  instance.variables[source] = destination_value
end
function module.SPI_move(context, instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  operations.SPI_SetDataToInstance(context, instance, destination, source_value)
end
function module.SPI_sysc(context, instance, source)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  local possible_sysc_wrapper = context.system_calls[source_value]
  if possible_sysc_wrapper then
    possible_sysc_wrapper(context, instance)
  else
    instance:set_error("no system call: %s (from value: %s)", source_value, source)
  end
end
function module.SPI_swap(context, instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  local target_value = operations.SPI_GetDataFromInstance(context, instance, destination)
  operations.SPI_SetDataToInstance(context, instance, source, target_value)
  operations.SPI_SetDataToInstance(context, instance, destination, source_value)
end
function __SPI_IncrDecrTemplateOperation(context, instance, source, template_function, operation_name)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  if type(source_value) == "number" then
    operations.SPI_SetDataToInstance(context, instance, source, template_function(source_value))
  else
    instance:set_error("%s requires a number, got: \"%s\"!", operation_name, source)
  end
end
function module.SPI_incr(context, instance, source)
  __SPI_IncrDecrTemplateOperation(context, instance, source, function(a) return a + 1 end, "incr")
end
function module.SPI_decr(context, instance, source)
  __SPI_IncrDecrTemplateOperation(context, instance, source, function(a) return a - 1 end, "decr")
end
function module.SPI_push(context, instance, source)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  table.insert(instance.stack, source_value)
end
function module.SPI_pop(context, instance, source)
  if #instance.stack <= 0 then
    instance:set_error("attempt to POP the stack but stack size is 0 (aka. there is nothing to pop anymore)")
  else
    local pop_value = table.pop(instance.stack)
    operations.SPI_SetDataToInstance(context, instance, source, pop_value)
  end
end
function __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, template_function, operation_name, custom_type)
  custom_type = custom_type or "number"
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  if type(source_value) ~= custom_type then return instance:set_error("%s requires first argument to be %s, got: %s", operation_name, custom_type, source) end
  local target_value = operations.SPI_GetDataFromInstance(context, instance, destination)
  if type(target_value) ~= custom_type then return instance:set_error("%s requires second argument to be %s, got: %s", operation_name, custom_type, destination) end
  operations.SPI_SetDataToInstance(context, instance, result, template_function(source_value, target_value))
end
function module.SPI_add(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return a + b end, "add")
end
function module.SPI_sub(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return a - b end, "sub")
end
function module.SPI_mul(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return a * b end, "mul")
end
function module.SPI_div(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return a / b end, "div")
end
function module.SPI_pow(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return math.pow(a, b) end, "pow")
end
function module.SPI_halt(_, instance)
  instance.status = consts.SPI_InstanceStatus.FINISHED
end
function module.SPI_die (context, instance, source)
  instance.error_msg = operations.SPI_GetDataFromInstance(context, instance, source)
  instance.status = consts.SPI_InstanceStatus.DIED
end
function module.SPI_cmpr(context, instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(context, instance, source)
  local destination_value = operations.SPI_GetDataFromInstance(context, instance, destination)
  if type(source_value) == type(destination_value) then
    if type(source_value) == "number" then
      instance.registers.GT = (source_value > destination_value) and 1 or 0
    end
    instance.registers.EQ = (source_value == destination_value) and 1 or 0
  else
    instance.registers.EQ = 0
    instance.registers.GT = 0
  end
end
function module.SPI_jump(context, instance, source)
  operations.SPI_Goto(context, instance, source, false)
end
function module.SPI_call(context, instance, source)
  operations.SPI_Goto(context, instance, source, true)
end
function module.SPI_retn(_, instance)
  operations.SPI_RestoreLastLocation(instance)
end
function module.SPI_clr(_, instance)
  instance.registers.EQ = 0
  instance.registers.GT = 0
end
function module.SPI_je  (context, instance, source) if instance.registers.EQ      == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jne (context, instance, source) if not instance.registers.EQ  == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jle (context, instance, source) if not instance.registers.GT  == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jge (context, instance, source) if instance.registers.GT      == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_ce  (context, instance, source) if instance.registers.EQ      == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cne (context, instance, source) if not instance.registers.EQ  == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cle (context, instance, source) if not instance.registers.GT  == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cge (context, instance, source) if instance.registers.GT      == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_and (context, instance, source, destination, result)
  -- TODO: when luajit supports '<<' and '&', remove from the bit library.
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, (function(a, b) return bit.band(a, b) end), "and")
end
function module.SPI_or (context, instance, source, destination, result) 
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, (function(a, b) return bit.bor(a, b) end), "or")
end
function module.SPI_iran(context, instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(context, instance, source, destination, result, function(a, b) return math.random(a, b) end, "iran")
end
module.SPI_PerformTable = {
  define    = {args = 2, wrap = module.SPI_define },
  move      = {args = 2, wrap = module.SPI_move},
  sysc      = {args = 1, wrap = module.SPI_sysc},
  swap      = {args = 2, wrap = module.SPI_swap},
  incr      = {args = 1, wrap = module.SPI_incr},
  decr      = {args = 1, wrap = module.SPI_decr},
  push      = {args = 1, wrap = module.SPI_push},
  pop       = {args = 1, wrap = module.SPI_pop },
  add       = {args = 3, wrap = module.SPI_add },
  sub       = {args = 3, wrap = module.SPI_sub },
  mul       = {args = 3, wrap = module.SPI_mul },
  div       = {args = 3, wrap = module.SPI_div },
  pow       = {args = 3, wrap = module.SPI_pow },
  halt      = {args = 0, wrap = module.SPI_halt},
  die       = {args = 1, wrap = module.SPI_die },
  -- sqrt   = {args = 2, wrap = module.SPI_sqrt},
  -- sin    = {args = 2, wrap = module.SPI_sin },
  -- cos    = {args = 2, wrap = module.SPI_cos },
  -- tan    = {args = 2, wrap = module.SPI_tan },
  cmpr      = {args = 2, wrap = module.SPI_cmpr},
  jump      = {args = 1, wrap = module.SPI_jump},
  call      = {args = 1, wrap = module.SPI_call},
  retn      = {args = 0, wrap = module.SPI_retn},
  clr       = {args = 0, wrap = module.SPI_clr },
  je        = {args = 1, wrap = module.SPI_je  },
  jne       = {args = 1, wrap = module.SPI_jne },
  jle       = {args = 1, wrap = module.SPI_jle },
  jge       = {args = 1, wrap = module.SPI_jge },
  ce        = {args = 1, wrap = module.SPI_ce  },
  cne       = {args = 1, wrap = module.SPI_cne },
  cle       = {args = 1, wrap = module.SPI_cle },
  cge       = {args = 1, wrap = module.SPI_cge },
  ["and"]   = {args = 3, wrap = module.SPI_and },
  ["or"]    = {args = 3, wrap = module.SPI_or  },
  -- ["not"]   = {args = 2, wrap = module.SPI_not }
  iran      = {args = 3, wrap = module.SPI_iran},
}
--
return module