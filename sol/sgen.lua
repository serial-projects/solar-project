-- sgen.lua: code generators and object generating functions.
local module={}

--[[ 
  Sol_BuildStruct(default, new_values): generates a table containing all the default values, if there is a
  new_value for the default, use it then. DO not set a default value to NIL (use sgen.SNIL or sgen.SFALSE for false)!
]]
function module.Sol_BuildStruct(default, substitute_values)
  local substitute_values, new_struct = substitute_values or {}, {}
  for key, value in pairs(default) do
    if substitute_values[key] ~= nil then
      new_struct[key]=substitute_values[key]
    else
      new_struct[key]=value
    end
  end
  return new_struct
end

--[[ 
  Sol_PerformFunctionsAndMeasureTime(function_table): perform a table of functions and measure their time.
]]
function module.Sol_PerformFunctionsAndMeasureTime(function_table)
  local function _capsule(f, ...)
    local args ={...}
    local begun=os.clock()
    f(unpack(args))
    return os.clock()-begun
  end
  for function_index, function_interface in ipairs(function_table) do
    makesure(function_interface["wrap"], 42, "Sol_PerformFunctionsAndMeasureTime(): expected \"wrap\" at function: %d", function_index)
    -- NOTE: make sure the IF is not gonna mess the value of the time.
    function_interface["finished"]=_capsule(function_interface["wrap"],unpack(function_interface["args"]))
  end
end

--
return module