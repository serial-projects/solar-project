-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
local    STRING_TOKENS = {["\""]=true, ["'"]=true}
local    VALID_BOOLEAN_TOKENS = {["true"]=true, ["yes"]=true, ["false"]=true, ["no"]=true}
local    SPECIAL_REGISTERS = {["EQ"]=true, ["GT"]=true}
function module.SPI_GetDataFromInstance(context, instance, token)
  -- prefixes:
  -- $    = local variables (usually defined by "define" keyword);
  -- @    = global variables;
  -- !    = some register.
  local possible_prefix = token:sub(1, 1)
  local without_prefix  = token:sub(2, #token)
  local function CheckReference(type_reference, where_to_look, when_error, ...)
    if where_to_look[type_reference] then
      return where_to_look[type_reference]
    else
      instance:set_error(when_error, ...)
    end
  end
  if possible_prefix == '$' then
    return CheckReference(without_prefix, instance.variables, "no local declared: \"%s\"", without_prefix)
  elseif possible_prefix == '@' then
    return CheckReference(without_prefix, context.global_scope, "no global declared: \"%s\"", without_prefix)
  elseif possible_prefix == '!' then
    return CheckReference(string.upper(without_prefix), instance.registers, "no register found: \"%s\"", without_prefix)
  elseif STRING_TOKENS[possible_prefix] and possible_prefix == token:sub(#token, #token) then
    return without_prefix:sub(1, #without_prefix - 1)
  elseif tonumber(token) then
    return tonumber(token)
  elseif VALID_BOOLEAN_TOKENS[token] then
    return (token == "yes" or token == "true") and 1 or 0
  else
    instance:set_error("invalid reference: \"%s\"", token)
  end
  return 0
end
function module.SPI_SetDataToInstance(context, instance, token, value)
  -- prefixes:
  -- $    = local variables (usually defined by "define" keyword);
  -- @    = global variables;
  -- !    = some register.
  local   possible_prefix = token:sub(1, 1)
  local   without_prefix  = token:sub(2, #token)
  local   performing_table = {
    ["$"]=function()
      instance.variables[without_prefix]=value
    end,
    ["@"]=function()
      context.global_scope[without_prefix]=value
    end,
    ["!"]=function()
      -- NOTE: all the registers are in UPPERCASE like SP, A, etc...
      without_prefix = string.upper(without_prefix)
      if instance.registers[without_prefix] or SPECIAL_REGISTERS[without_prefix] then
        instance.registers[without_prefix] = value
      else
        instance:set_error("no register %s exists.", string.upper(without_prefix))
      end
    end
  }
  local do_perform = performing_table[possible_prefix]
  if do_perform then
    do_perform()
  else
    instance:set_error("unable to set \"%s\" to temporary value: \"%s\"", value, token)
  end
end
function module.SPI_Goto(context, instance, where, save_last_location)
  local location_address = context.label_addr[where]
  if location_address then
    -- NOTE: here we assume all the instructions that move the code to a certain
    -- direction only takes ONE argument, although there is no plans for new
    -- instructions that violates this argument, it is better implement on the
    -- future a way to modify this value.
    local AMOUNT_JUMP = 1 + 1
    if save_last_location then
      local save_address = instance.registers.PC + AMOUNT_JUMP
      table.insert(instance.call_stack, save_address)
    end
    instance.registers.PC   = location_address
    instance.registers.PCI  = false
  else
    instance:set_error("no label to jump with name: \"%s\"", where)
  end
end
function module.SPI_RestoreLastLocation(instance)
  if #instance.call_stack <= 0 then
    instance:set_error("failed attempt to restore last location, #call_stack <= 0 (aka. nothing to return to.)")
  else
    -- NOTE: this makes xtable.lua required!
    instance.registers.PC = table.pop(instance.call_stack)
    instance.registers.PCI = false
  end
end
return module