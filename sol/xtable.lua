-- xtable.lua: keep track of functions related with the table.
function table.sub(t, begin, ends)
  local subtable={}
  for index=begin, ends do
    table.insert(subtable, t[index])
  end
  return subtable
end
function table.unimerge(target, source)
  if source then
    for _, value in ipairs(source) do
      table.insert(target, value)
    end
  end
end
function table.getnkeys(t, only_keys)
  local count, only_keys = 0, only_keys or false
  for key, _ in pairs(t) do
    if only_keys then
      if tonumber(key) ~= "number" then
        count = count + 1
      end
    else
      count = count + 1
    end
  end
  return count
end
function table.enum(begin, keys)
  local new_table = {}
  for _, element in ipairs(keys) do
    new_table[element]=begin+table.getnkeys(new_table)
  end
  return new_table
end
function table.show(t)
  local function _show(ts, depth)
    local prefix=string.getstr(depth, " ")
    local text=""
    for key, value in pairs(ts) do
      if type(value)~="table" then
        text=text..(prefix..string.format("[key=\"%s\" (type: %s)]: %s", key, type(key), tostring(value)).."\n")
      else
        text=text..(prefix..string.format("[key=\"%s\" (type: %s)] >>", key, type(key))..'\n')
        text=text..(_show(value, depth+2))
      end
    end
    return text
  end
  return _show(t, 0)
end
function table.find(t, value)
  for key, tvalue in pairs(t) do
    if tvalue == value then
      return true, key
    end
  end
  return false, nil
end