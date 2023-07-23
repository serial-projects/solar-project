local consts      =require("sol.libspi.consts")
local operations  =require("sol.libspi.operation")
local module = {}
function module.SPI_define(instance, source, destination)
  local destination_value = operations.SPI_GetDataFromInstance(instance, destination)
  instance.variables[source] = destination_value
end
function module.SPI_move(instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  operations.SPI_SetDataToInstance(instance, destination, source_value)
end
function module.SPI_sysc(context, instance, source)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  local possible_sysc_wrapper = context.system_calls[source_value]
  if possible_sysc_wrapper then
    possible_sysc_wrapper(context, instance)
  else
    instance:set_error("no system call: %s (from value: %s)", source_value, source)
  end
end
function module.SPI_swap(instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  local target_value = operations.SPI_GetDataFromInstance(instance, destination)
  operations.SPI_SetDataToInstance(instance, source, target_value)
  operations.SPI_SetDataToInstance(instance, destination, source_value)
end
function __SPI_IncrDecrTemplateOperation(instance, source, template_function, operation_name)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  if type(source_value) == "number" then
    operations.SPI_SetDataToInstance(instance, source, template_function(source_value))
  else
    instance:set_error("%s requires a number, got: \"%s\"!", operation_name, source)
  end
end
function module.SPI_incr(instance, source)
  __SPI_IncrDecrTemplateOperation(instance, source, function(a) return a + 1 end, "incr")
end
function module.SPI_decr(instance, source)
  __SPI_IncrDecrTemplateOperation(instance, source, function(a) return a - 1 end, "decr")
end
function module.SPI_push(instance, source)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  table.insert(instance.stack, source_value)
end
function module.SPI_pop(instance, source)
  if #instance.stack <= 0 then
    instance:set_error("attempt to POP the stack but stack size is 0 (aka. there is nothing to pop anymore)")
  else
    local pop_value = table.pop(instance.stack)
    operations.SPI_SetDataToInstance(instance, source, pop_value)
  end
end
function __SPI_MathOperationTemplateOperation(instance, source, destination, result, template_function, operation_name)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  if type(source_value) ~= "number" then return instance:set_error("%s requires first argument to be %s, got: %s", operation_name, custom_type, source) end
  local target_value = operations.SPI_GetDataFromInstance(instance, destination)
  if type(target_value) ~= "number" then return instance:set_error("%s requires second argument to be %s, got: %s", operation_name, custom_type, destination) end
  --
  operations.SPI_SetDataToInstance(instance, result, template_function(source_value, target_value))
end
function module.SPI_add(instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a + b end, "add")
end
function module.SPI_sub(instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a - b end, "sub")
end
function module.SPI_mul(instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a * b end, "mul")
end
function module.SPI_div(instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a / b end, "div")
end
function module.SPI_pow(instance, source, destination, result)
  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return math.pow(a, b) end, "pow")
end
function module.SPI_halt(instance)
  instance.status = consts.SPI_InstanceStatus.FINISHED
end
function module.SPI_die (instance, source)
  instance.error_msg = operations.SPI_GetDataFromInstance(instance, source)
  instance.status = consts.SPI_InstanceStatus.DIED
end
function module.SPI_cmpr(instance, source, destination)
  local source_value = operations.SPI_GetDataFromInstance(instance, source)
  local destination_value = operations.SPI_GetDataFromInstance(instance, destination)
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
function module.SPI_retn(instance)
  operations.SPI_RestoreLastLocation(instance)
end
function module.SPI_clr(instance)
  instance.registers.EQ = 0
  instance.registers.GT = 0
end
function module.SPI_je(context,   instance, source) if instance.registers.EQ      == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jne(context,  instance, source) if not instance.registers.EQ  == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jle(context,  instance, source) if not instance.registers.GT  == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_jge(context,  instance, source) if instance.registers.GT      == 1 then operations.SPI_Goto(context, instance, source, false) end end
function module.SPI_ce(context,   instance, source) if instance.registers.EQ      == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cne(context,  instance, source) if not instance.registers.EQ  == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cle(context,  instance, source) if not instance.registers.GT  == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_cge(context,  instance, source) if instance.registers.GT      == 1 then operations.SPI_Goto(context, instance, source, true) end end
function module.SPI_and(instance, source, destination, result)
  -- TODO: on the future, implement pre-execution MACRO to remove this redundancy.
  if    _G["jit"] then __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return bit.band(a, b) end, "and")
  else  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a & b end, "and") end
end
function module.SPI_or (instance, source, destination, result) 
  if    _G["jit"] then __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return bit.bor(a, b) end, "or")
  else  __SPI_MathOperationTemplateOperation(instance, source, destination, result, function(a, b) return a | b end, "or") end
end
module.SPI_PerformTable = {
  define    = {args = 2, wrap = module.SPI_define },
  move      = {args = 2, wrap = module.SPI_move},
  sysc      = {args = 1, wrap = module.SPI_sysc, pass_context = true },
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
  jump      = {args = 1, wrap = module.SPI_jump, pass_context = true },
  call      = {args = 1, wrap = module.SPI_call, pass_context = true },
  retn      = {args = 0, wrap = module.SPI_retn},
  clr       = {args = 0, wrap = module.SPI_clr },
  je        = {args = 1, wrap = module.SPI_je  , pass_context = true },
  jne       = {args = 1, wrap = module.SPI_jne , pass_context = true },
  jle       = {args = 1, wrap = module.SPI_jle , pass_context = true },
  jge       = {args = 1, wrap = module.SPI_jge , pass_context = true },
  ce        = {args = 1, wrap = module.SPI_ce  , pass_context = true },
  cne       = {args = 1, wrap = module.SPI_cne , pass_context = true },
  cle       = {args = 1, wrap = module.SPI_cle , pass_context = true },
  cge       = {args = 1, wrap = module.SPI_cge , pass_context = true },
  ["and"]   = {args = 3, wrap = module.SPI_and },
  ["or"]    = {args = 3, wrap = module.SPI_or  },
  -- ["not"]   = {args = 2, wrap = module.SPI_not }
}
--
return module