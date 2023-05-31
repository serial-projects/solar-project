-- xstring.lua: extra functions for string library.
function string.getstr(size, fill_with)
  local str, fill_with, size = "", fill_with or " ", size or 0
  for _ = 1, size do
    str = str .. fill_with
  end
  return str
end
function string.tokenize(str)
  local index,length,acc,tokens=1,#str,"",{}
  local instr, string_begun_with=false,nil
  local function append_acc(include_last) 
    if include_last then acc=acc..include_last end
    if #acc > 0 then table.insert(tokens, acc) end
    acc = ""
  end
  while index<=length do
    local ch=str:sub(index, index)
    -- split --
    if (ch == ' ') and not instr then
      append_acc()
    -- string --
    -- TODO: implement string escape '\\' functionality.
    elseif (ch == '"' or ch == '\'') and not instr then
      append_acc() ; acc,string_begun_with,instr=ch,ch,true
    elseif (ch == string_begun_with) and instr then
      append_acc(ch) ; string_begun_with,instr=nil,false
    elseif (ch == '\\') and instr then
      qcrash("not implemented string escape!")
    -- everything goes --
    else
      acc = acc..ch
    end
    index=index+1
  end
  return tokens
end
function string.list2table(s)
  local t = {}
  for index = 1, #s do
    t[s:sub(index, index)]=true
  end
  return t
end
function string.findch(s, ch)
  for index = 1, #s do
    if s:sub(index, index)==ch then
      return index
    end
  end
  return nil
end