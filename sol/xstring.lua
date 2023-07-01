-- xstring.lua: extra functions for string library.
function string.getstr(size, fill_with)
  local str, fill_with, size = "", fill_with or " ", size or 0
  for _ = 1, size do
    str = str .. fill_with
  end
  return str
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