-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

-- xstring.lua: extra functions for string library.
_G["StringImported"] = true
local __TokenizerModuleOneshotRequire = require("Solar.Extras.Tokenizer")

function string.getstr(size, fill_with)
  local str, fill_with, size = "", fill_with or " ", size or 0
  for _ = 1, size do
    str = str .. fill_with
  end
  return str
end

-- string.genstr(length: number) -> random UNIQUE generated string.
_G.__generatedStrings={}
function string.genstr(length)
  local length = length or 32
  local ranges = {
    {b=string.byte('a'), e=string.byte('z')},
    {b=string.byte('A'), e=string.byte('Z')},
    {b=string.byte('0'), e=string.byte('9')}
  }
  local acc = ""
  while _G.__generatedStrings[acc] ~= nil do
    acc = ""
    for _=1, length do
      local selected_range=ranges[math.random(1, #ranges)]
      acc = acc .. string.char(math.random(selected_range.b, selected_range.e))
    end
  end ; _G.__generatedStrings[acc]=true
  return acc
end

-- string.getchseq(s: "... your char sequence ...") -> {'.', 'y', ...}:
-- converts a string to a table containing all the characters in a single entry.
function string.getchseq(s)
  local   t = {}
  for index = 1, #s do t[s:sub(index, index)]=true end
  return  t
end

function string.findch(s, ch)
  for index = 1, #s do
    if s:sub(index, index)==ch then
      return index
    end
  end
  return nil
end