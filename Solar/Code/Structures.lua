-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

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

-- 
return module