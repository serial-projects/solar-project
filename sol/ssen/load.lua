local module={}
local text=require("sol.ssen.text")
--
function module.SSEN_LoadBuffer(buffer)
  local tokenized_buffer=text.SSEN_Tokenize(text.SSEN_PurifyString(buffer))
  dmsg(table.show(tokenized_buffer))
end
function module.SSEN_LoadFile(path)
  local fp = love.filesystem.newFile(path, "r")
    local loaded_buffer=fp:read()
  fp:close()
  loaded_buffer=module.SSEN_LoadBuffer(loaded_buffer)
end
--
return module