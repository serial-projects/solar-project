-- argparser.lua: simple user argument parser.
local module={}
function Sol_UserArgumentsDecode(arglist, argtable)
  local index,length,has_default=1,#arglist,argtable["default"]~=nil
  while index<=length do
    local argument=arglist[index]
    local argument_decoded=argtable[argument]
    if argument_decoded then
      while true do
        if type(argument_decoded)=="string" then
          argument_decoded=argtable[argument_decoded]
        else
          break
        end
      end
      makesure(argument_decoded, 42, "Sol_UserArgumentsDecode(): pointer to high argument is invalid = %s", argument)
      argument_decoded["wrap"](unpack(table.sub(arglist, (index+1), (index+1)+argument_decoded["nargs"])))
      index=index+argument_decoded["nargs"]
    else
      if has_default then argtable["default"](argument) end
    end
    index=index+1
  end
end ; module.Sol_UserArgumentsDecode=Sol_UserArgumentsDecode
--
return module