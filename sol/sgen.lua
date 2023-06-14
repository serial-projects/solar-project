-- sgen.lua: code generators and object generating functions.
local module={}
module.SNIL     =string.byte(1)
module.SFALSE   =string.byte(2)

--[[ 
  Sol_BuildStruct(default, new_values): generates a table containing all the default values, if there is a
  new_value for the default, use it then. DO not set a default value to NIL (use sgen.SNIL or sgen.SFALSE for false)!
]]
function module.Sol_BuildStruct(default, new_values)
  local new_structure = {}
  for key, value in pairs(default) do
    if new_values[key] then
      new_structure[key] = (new_values[key] == module.SNIL) and nil or ( (new_values[key]==module.SFALSE) and false or new_values[key] )
    else
      new_structure[key] = (value == module.SNIL) and nil or value
    end
  end
  return new_structure
end

--[[ 
  Sol_PerformFunctionsAndMeasureTime(function_table): perform a table of functions and measure their time.
]]
function module.Sol_PerformFunctionsAndMeasureTime(function_table)
  for function_index, function_interface in ipairs(function_table) do
    makesure(function_interface["wrap"], 42, "Sol_PerformFunctionsAndMeasureTime(): expected \"wrap\" at function: %d", function_index)
    -- NOTE: make sure the IF is not gonna mess the value of the time.
    local begun_executing
    if function_interface["args"] then
      begun_executing = os.clock()
      function_interface["wrap"](unpack(function_interface["args"]))
      function_interface["finished"]=os.clock()-begun_executing
    else
      begun_executing = os.clock()
      function_interface["wrap"]()
      function_interface["finished"]=os.clock()-begun_executing
    end
  end
end

--
return module