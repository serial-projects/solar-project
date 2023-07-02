local module={}
local text=require("sol.ssen.text")
local interpreter=require("sol.ssen.interpreter")
--
function module.SSEN_LoadFile(path)
  dmsg("SSEN_LoadFile() is opening file: %s", path)
  --
  local tokenized_buffer={}
  local fp=love.filesystem.newFile(path,"r")
  for line in fp:lines() do
    local purified_line =text.SSEN_PurifyString(line)
    local tokenized_line=text.SSEN_Tokenize(purified_line)
    table.unimerge(tokenized_buffer, tokenized_line)
  end
  --
  local proto_ir = interpreter.SSEN_NewInterpreter({name=path.."#thread"})
  interpreter.SSEN_InitInterpreter(proto_ir, tokenized_buffer)
  return proto_ir
end
--
return module