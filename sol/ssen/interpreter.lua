local unpack = unpack or table.unpack
local module = {}
--[[ Status ]]
module.SSEN_Status = table.enum(1, {"RUNNING", "FINISHED", "DIED", "SLEEPING", "WAITING"})

--[[ New Interpreter ]]
function module.SSEN_NewInterpreter(in_properties)
  return {
    name      = in_properties["name"] or "main",
    code      = {},
    --
    sleeptime = 0,
    status    = module.SSEN_Status.RUNNING,
    fail      = nil,
    nticks    = 10,
    --
    label_addr= {},
    --
    call_stack= {},
    --
    registers = {PCI = true, EQ = false, GT = false, PC = 1, X = 0, Y = 0, Z = 0, A = 0, B = 0, C = 0},
    stack     = {},
    vars      = {},
    globals   = nil,
    --
    syscalls  = {},
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
      local laddr=(#ir.code + 1)
      assert(not ir.label_addr[lname], "duplicated label: "..lname)
      ir.label_addr[lname]=laddr
      dmsg("(SSEN_InitInterpreter, ir.name = %s): loaded label: %s, addr = %d", ir.name, lname, laddr)
    else
      ir.code[#ir.code+1]=current_token
    end
    index=index+1
  end
end
--[[ Machine operations ]]
function module.SSEN_ErrorInterpreter(ir, reason)
  dmsg("(SSEN_Engine): thread \"%s\" just failed due: \"%s\"...", ir.name, reason)
  ir.status, ir.fail=module.SSEN_Status.DIED, reason
  return ir.status
end

--[[ Get and Set Data Utility ]]
--[[ Quick prefixes: @ = variable, $ = register, % = globals ]]
local STRING_TOKENS={['\'']=true,['"']=true}
function module.SSEN_IrGetData(ir, token)
  -- TODO: implement the globals :)
  local function _CheckTableAndReturnIfAvailable(t, k, e)
    if type(t)=="table" then
      if t[k] then
        return t[k]
      else
        error(e)
      end
    else
      -- TODO: when the globals are not loaded!
      error("[POSSIBLE BUG]: not loaded globals!")
    end
  end
  local prefix, noprefix=token:sub(1, 1), token:sub(2, #token)
  if            prefix == '@' then
    return _CheckTableAndReturnIfAvailable(ir.vars, noprefix, "no variable with name: "..noprefix)
  elseif        prefix == '$' then
    return _CheckTableAndReturnIfAvailable(ir.registers, string.upper(noprefix), "no register with name: "..noprefix)
  elseif        (STRING_TOKENS[prefix] and STRING_TOKENS[token:sub(#token,#token)]) then
    return token:sub(2, #token-1)
  elseif        prefix == '%' then
    return _CheckTableAndReturnIfAvailable(ir["globals"], noprefix, "no global with name: "..noprefix)
  elseif        (token=="true" or token=="false") then
    return token == "true"
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
  elseif        prefix == '%' then
    assert(ir["globals"], "[POSSIBLE BUG]: not loaded globals!") ; ir.globals[noprefix]=value
  end
end
function module.SSEN_IrGoto(ir, location, save_pc)
  assert(ir.label_addr[location]~=nil, string.format("SSEN_IrGoto(location: %s, save_pc: %s)", location, save_pc and "yes" or "no"))
  -- NOTE: we add +2 to the PC because every instruction that saves PC to call_stack
  -- is composed of two opcodes, example: call some_label, ceq some_label (...)
  local label_addr=ir.label_addr[location]
  if save_pc then table.insert(ir.call_stack, ir.registers.PC+2) end
  ir.registers.PC=label_addr
  ir.registers.PCI=false
end
function module.SSEN_IrSetPC(ir, label_name)
  local label_addr=ir.label_addr[label_name]
  assert(label_addr, "no label found with name: "..label_name)
  ir.registers.PC=label_addr
end

--[[ Instructions ]]

-- moving data & data manipulation:
function module.SSEN_PerformMove(ir, src, dest) module.SSEN_IrSetData(ir, dest, module.SSEN_IrGetData(ir, src)) end
function module.SSEN_PerformDefine(ir, src, dest) ir.vars[src]=module.SSEN_IrGetData(ir, dest)    end
function module.SSEN_PerformGlobal(ir, src, dest) ir.globals[src]=module.SSEN_IrGetData(ir, dest) end
function module.SSEN_PerformDefined(ir, src)
  local __prefix, checking=src:sub(1, 1),{
    ["@"]=function(name) return ir.vars[name] ~= nil end,
    ["%"]=function(name) return (ir.globals ~= nil and ir.globals[name] ~= nil or false) end
  }
  if checking[__prefix] then
    ir.registers.EQ=checking[__prefix](src:sub(2,#src))
  else
    module.SSEN_ErrorInterpreter(ir, "expected global/local, got: "..src)
  end
end

-- system operations:
function module.SSEN_PerformSysc(ir, src)
  local src=module.SSEN_IrGetData(ir, src) ; assert(ir.syscalls[src] and type(ir.syscalls[src])=="function", "no system call with name: "..src)
  ir.syscalls[src](ir)
end
function module.SSEN_PerformHalt(ir) ir.status=module.SSEN_Status.FINISHED end
function module.SSEN_PerformStkt(ir, src) module.SSEN_IrSetData(ir, src, #ir.stack)               end
function module.SSEN_PerformPush(ir, src) table.insert(ir.stack, module.SSEN_IrGetData(ir, src))  end
function module.SSEN_PerformPop (ir, src) module.SSEN_IrSetData(ir, src, table.pop(ir.stack))     end

-- math operations:
local function __SSEN_PerformOperationsTemplate(ir, a, b, result, opcode, wrap)
  local a=module.SSEN_IrGetData(ir, a) ; assert(type(a)=="number", string.format("on opcode \"%s\", source (1° argument) is expected to be a number, got: \"%s\"", opcode, tostring(a)))
  local b=module.SSEN_IrGetData(ir, b) ; assert(type(b)=="number", string.format("on opcode \"%s\", dest (2° argument) is expected to be a number, got: \"%s\"", opcode, tostring(b)))
  local r=wrap(a, b) ; module.SSEN_IrSetData(ir, result, r)
end
function module.SSEN_PerformAdd (ir, src, dest, result) __SSEN_PerformOperationsTemplate(ir, src, dest, result, "add", function(a, b) return a + b end) end
function module.SSEN_PerformSub (ir, src, dest, result) __SSEN_PerformOperationsTemplate(ir, src, dest, result, "sub", function(a, b) return a - b end) end
function module.SSEN_PerformMul (ir, src, dest, result) __SSEN_PerformOperationsTemplate(ir, src, dest, result, "div", function(a, b) return a * b end) end
function module.SSEN_PerformDiv (ir, src, dest, result) __SSEN_PerformOperationsTemplate(ir, src, dest, result, "div", function(a, b) return a / b end) end

function module.SSEN_PerformCmpr(ir, src, dest)
  local src   =module.SSEN_IrGetData(ir, src)
  local dest  =module.SSEN_IrGetData(ir, dest)
  if type(src) == type(dest) then ir.registers.EQ = src == dest
  else ir.registers.EQ = false end
  -- NOTE: GT is only available for number comparasions.
  if type(src) == "number" and type(dest) == "number" then  ir.registers.GT = src > dest
  else ir.registers.GT = false end
end

-- single jump and call:
function module.SSEN_PerformJump(ir, src) module.SSEN_IrGoto(ir, src, false)  end
function module.SSEN_PerformCall(ir, src) module.SSEN_IrGoto(ir, src, true )  end
function module.SSEN_PerformRetn(ir) assert(ir.registers.PC>0,"invalid retn, no place to go.") ir.registers.PC=ir.call_stack[#ir.call_stack] ; table.remove(ir.call_stack, #ir.call_stack) ; ir.registers.PCI = false end

-- conditional jumps:
function module.SSEN_PerformJE  (ir, src) if      ir.registers.EQ then module.SSEN_IrGoto(ir, src, false) end end
function module.SSEN_PerformJNE (ir, src) if not  ir.registers.EQ then module.SSEN_IrGoto(ir, src, false) end end
function module.SSEN_PerformJGE (ir, src) if      ir.registers.GT then module.SSEN_IrGoto(ir, src, false) end end
function module.SSEN_PerformJLE (ir, src) if not  ir.registers.GT then module.SSEN_IrGoto(ir, src, false) end end

-- conditional calls:
function module.SSEN_PerformCE  (ir, src) if      ir.registers.EQ then module.SSEN_IrGoto(ir, src, true) end end
function module.SSEN_PerformCNE (ir, src) if not  ir.registers.EQ then module.SSEN_IrGoto(ir, src, true) end end
function module.SSEN_PerformCGE (ir, src) if      ir.registers.GT then module.SSEN_IrGoto(ir, src, true) end end
function module.SSEN_PerformCLE (ir, src) if not  ir.registers.GT then module.SSEN_IrGoto(ir, src, true) end end

-- register all the instructions on a table:
module.SSEN_IrInstructionTable={
  -- move data around:
  move          ={nargs=2, wrap=module.SSEN_PerformMove   },
  stkt          ={nargs=1, wrap=module.SSEN_PerformStkt   },
  push          ={nargs=1, wrap=module.SSEN_PerformPush   },
  pop           ={nargs=1, wrap=module.SSEN_PerformPop    },
  -- math operations:
  add           ={nargs=3, wrap=module.SSEN_PerformAdd    },
  sub           ={nargs=3, wrap=module.SSEN_PerformSub    },
  mul           ={nargs=3, wrap=module.SSEN_PerformMul    },
  div           ={nargs=3, wrap=module.SSEN_PerformDiv    },
  -- compare instruction:
  cmpr          ={nargs=2, wrap=module.SSEN_PerformCmpr   },
  -- jump, call and return:
  jump          ={nargs=1, wrap=module.SSEN_PerformJump   },
  call          ={nargs=1, wrap=module.SSEN_PerformCall   },
  retn          ={nargs=0, wrap=module.SSEN_PerformRetn   },
  -- conditional jumps and calls:
  je            ={nargs=1, wrap=module.SSEN_PerformJE     },
  jne           ={nargs=1, wrap=module.SSEN_PerformJNE    },
  jge           ={nargs=1, wrap=module.SSEN_PerformJGE    },
  jle           ={nargs=1, wrap=module.SSEN_PerformJLE    },
  ce            ={nargs=1, wrap=module.SSEN_PerformCE     },
  cne           ={nargs=1, wrap=module.SSEN_PerformCNE    },
  cge           ={nargs=1, wrap=module.SSEN_PerformCGE    },
  cle           ={nargs=1, wrap=module.SSEN_PerformCLE    },
  -- system instructions:
  sysc          ={nargs=1, wrap=module.SSEN_PerformSysc   },
  halt          ={nargs=0, wrap=module.SSEN_PerformHalt   },
  -- define some variables:
  define        ={nargs=2, wrap=module.SSEN_PerformDefine },
  defined       ={nargs=1, wrap=module.SSEN_PerformDefined}
}

--[[ Tick Interpreter ]]
local ignore_status={[module.SSEN_Status.DIED]=true,[module.SSEN_Status.FINISHED]=true,[module.SSEN_Status.WAITING]=true}
function module.SSEN_TickIntepreter(ir)
  -- TODO: re-write this on the future for more coolness.
  if ir.status ~= module.SSEN_Status.RUNNING then
    if      ignore_status[ir.status] ~= nil then
      -- in case of died, finished or WAITING (in special, waiting), just return the current status.
      return ir.status
    elseif  ir.status == module.SSEN_Status.SLEEPING then
      -- in case of sleeping, then (...)
      -- TODO: implement sleep on interpreter.
      if ir.sleeptime < os.time() then
        ir.status = module.SSEN_Status.RUNNING
      else
        return ir.status
      end
    end
  end
  if ir.registers.PC>#ir.code then
    ir.status=module.SSEN_Status.FINISHED
    return ir.status
  end
  -- begin loading the opcode and do the logic.
  local current_instr=ir.code[ir.registers.PC]
  if module.SSEN_IrInstructionTable[current_instr] then
    local instr_table=module.SSEN_IrInstructionTable[current_instr]
    if ir.registers.PC+instr_table.nargs>#ir.code then
      return module.SSEN_ErrorInterpreter(ir, string.format("%s requires %d arguments.", current_instr, instr_table.nargs))
    end
    local args=table.sub(ir.code, ir.registers.PC+1, (ir.registers.PC+1)+instr_table.nargs)
    instr_table.wrap(ir, unpack(args))
    -- NOTE: PCI register stands for (PC should Increment?)
    if    ir.registers.PCI then ir.registers.PC=ir.registers.PC+instr_table.nargs+1
    else  ir.registers.PCI = true end
  else
    dmsg("PC: %d, IR.CODE: %s", ir.registers.PC, table.show(ir.code))
    return module.SSEN_ErrorInterpreter(ir, "invalid instruction: "..current_instr)
  end
end

--[[ Run Interpreter ]]
function module.SSEN_RunInterpreter(ir)

end

--
return module