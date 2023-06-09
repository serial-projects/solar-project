local module = {}
--[[ New Interpreter ]]
function module.SSEN_NewInterpreter(in_properties)
  return {
    name      = in_properties["name"] or "main",
    code      = {},
    registers = {EQ = false, GT = false, PC = 0, X = 0, Y = 0, Z = 0, A = 0, B = 0, C = 0},
    stack     = {},
    call_stack= {},
    label_addr= {},
    vars      = {},
  }
end
--[[ Init Interpreter ]]
function module.SSEN_InitInterpreter(ir, token_sequence)
  -- initializes the labels and its locations. Since this is Sol Scripting Engine Bytecode,
  -- according to the reference, there is no variables to load. Also, initializes the address
  -- of the defines.
  local index, length = 1, #token_sequence
  while index<=length do
    local current_token=token_sequence[index]
    if current_token:sub(#current_token,#current_token)==':' then
      local lname=current_token:sub(1,#current_token-1)
      assert(not ir.label_addr[lname], "duplicated label: "..lname)
      ir.label_addr[lname]=index
      dmsg("(SSEN_InitInterpreter, ir.name = %s): loaded label: %s, addr = %d", ir.name, lname, index)
    elseif current_token=="define" then
      assert(index+2<=length, "define expects <name> and <value>")
      local dname, dvalue = token_sequence[index+1], token_sequence[index+2]
      ir.vars[dname]=dvalue
      index=index+2
    else
      ir.code[#ir.code+1]=current_token
    end
    index=index+1
  end
end
--[[ Get and Set Data Utility ]]
--[[ Quick prefixes: @ = variable, $ = register, % = globals ]]
local STRING_TOKENS={['\'']=true,['"']=true}
function module.SSEN_IrGetData(ir, token)
  -- TODO: implement the globals :)
  local function _CheckTableAndReturnIfAvailable(t, k, e)
    if t[k] then 
      return t[k]
    else
      error(e)
    end
  end
  local prefix, noprefix=token:sub(1, 1), token:sub(2, #token)
  if            prefix == '@' then
    return _CheckTableAndReturnIfAvailable(ir.vars, noprefix, "no variable with name: "..noprefix)
  elseif        prefix == '$' then
    return _CheckTableAndReturnIfAvailable(ir.registers, noprefix, "no register with name: "..noprefix)
  elseif        (STRING_TOKENS[prefix] and STRING_TOKENS[token:sub(#token,#token)]) then
    return token:sub(2, #token-1)
  elseif        (tonumber(token)) then
    return tonumber(token)
  else
    error("unknown token: "..token)
  end
end
function module.SSEN_IrSetData(ir, token, value)
  local prefix, noprefix=token:sub(1, 1), token:sub(2, #token)
  if            prefix == '@' then
    ir.vars[noprefix]=value
  elseif        prefix == '$' then
    ir.registers[noprefix]=value
  else
    return
  end
end
--[[ Tick Interpreter ]]
function module.SSEN_TickIntepreter(ir)

end
--[[ Run Interpreter ]]
function module.SSEN_RunInterpreter(ir)

end

--
return module