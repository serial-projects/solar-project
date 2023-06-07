-- argparser.lua: simple user argument parser.
local module={}

function module.Sol_UserArgumentsDecode(arglist, argtable)
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
      local nargs=argument_decoded["nargs"]
      makesure(argument_decoded, 42, "Sol_UserArgumentsDecode(): pointer to high argument is invalid = %s", argument)
      makesure(index+nargs<=length, 42, "%s requires %d arguments!", argument, nargs)
      argument_decoded["wrap"](unpack(table.sub(arglist, (index+1), (index+1)+nargs)))
      index=index+nargs
    else
      if has_default then argtable["default"](argument) end
    end
    index=index+1
  end
end

--
return module