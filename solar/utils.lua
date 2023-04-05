local module = {}
local unpack = unpack or table.unpack
local sfmt = string.format
local sbyte = string.byte
local schar = string.char

--
-- String Utils
--
function Solar_GenerateExtraCharacterListFromString(s)
  local t = {} for index = 1, #s do t[s:sub(index, index)]=true end
  return t
end
module.Solar_GenerateExtraCharacterListFromString = Solar_GenerateExtraCharacterListFromString

function Solar_IsValidCharacter(char, extras)
  extras = extras or {}
  return  (sbyte(char) >= sbyte('a') and sbyte(char) <= sbyte('z')) or
          (sbyte(char) >= sbyte('A') and sbyte(char) <= sbyte('Z')) or
          (sbyte(char) >= sbyte('0') and sbyte(char) <= sbyte('9')) or
          (extras[char] ~= nil) or
          (char == '_')
end
module.Solar_IsValidCharacter = Solar_IsValidCharacter

--
-- Table Utils
--
function Solar_TableSingleDimensionMerge(first, second)
  -- merge the first table with the second: first = first + second
  for _, element in ipairs(second) do
    table.insert(first, element)
  end
  for key, element in pairs(second) do
    first[key]=element
  end
end
module.Solar_TableSingleDimensionMerge = Solar_TableSingleDimensionMerge
function Solar_TableRecursiveInsert(t, element)
  if type(element) == 'table' then
    for _, value in ipairs(element) do
      Solar_TableRecursiveInsert(t, value)
    end
    return
  end
  table.insert(t, element)
end
module.Solar_TableRecursiveInsert = Solar_TableRecursiveInsert
function Solar_TableGetNumberKeys(table)
  local counter = 0 ; for _, _ in pairs(table) do counter = counter + 1 end
  return counter
end
module.Solar_TableGetNumberKeys = Solar_TableGetNumberKeys

--
-- Generic Configuration File Reader
--
function Solar_Tokenize(s)
  local acc, tokens = "", {}
  local index, length = 1, #s
  local inside_string, string_begun_with, skip_string_closure = false, nil, false
  local function append(list, str)
    if #str > 0 then table.insert(list, str) end
  end
  while index <= length do
    local char = s:sub(index, index)
    if char == ' ' and not inside_string then
      append(tokens, acc) ; acc = ""
    elseif (char == '"' or char == '\'') and not inside_string then
      append(tokens, acc) ; acc = char
      inside_string, string_begun_with = true, char
    elseif (char == '"' or char == '\'') and inside_string and char == string_begun_with then
      append(tokens, acc .. char) ; acc = ""
      inside_string = false
    elseif (char == '#') and not inside_string then
      append(tokens, acc) ; acc = ""
      break
    elseif (char == '=') and not inside_string then
      append(tokens, acc) ; acc = ""
      table.insert(tokens, char)
    else
      acc = acc .. char
    end
    index = index + 1
  end
	append(tokens, acc)
  return tokens
end
module.Solar_Tokenize = Solar_Tokenize
function Solar_LoadGenericConfigurationFile(file_name)
  --
  local tokenized_file = {}
  local file = io.open(file_name, "r")
  assert(file ~= nil, "failed to open: "..file_name)
  for line in file:lines() do
    Solar_TableRecursiveInsert(tokenized_file, Solar_Tokenize(line:gsub("\n",' '):gsub("\t",'  ')))
  end
  file:close()
  -- TODO: create a more smart parsing, this is very limited.
  -- Since everything should be built like this:
  -- MY_VARIABLE="something?"
  local data_adquired = {}
  local index, length = 1, #tokenized_file
  while index <= length do
    local name = tokenized_file[index]
		local middle=tokenized_file[index+1] assert(middle=="=","invalid definition at name: "..name)
    local value= tokenized_file[index+2]
    data_adquired[name]=value
    index = index + 3
  end
  --
  return data_adquired
end
module.Solar_LoadGenericConfigurationFile = Solar_LoadGenericConfigurationFile
function Solar_GetLinuxDistributor()
  -- NOTE: no, Solar will not send your data to anywhere, instead, this is just to
  -- help determine (in case of errors), possible problems with your Mesa version
  -- for example, knowing what distro you are is very important to solve some problems.

  -- First attempt: the /etc/os-release.
  local os_release = Solar_LoadGenericConfigurationFile("/etc/os-release")
  if os_release['name'] ~= nil or os_release['NAME'] ~= nil then
    return os_release['name'] or os_release['NAME']
  end
end
module.Solar_GetLinuxDistributor = Solar_GetLinuxDistributor

--
-- Vector Utils
--
function Solar_NewVectorXY(x, y)
  return {
    x = (x or 0), y = (y or 0)
  }
end
module.Solar_NewVectorXY = Solar_NewVectorXY

--
-- Colar Utils
--
function Solar_NewColor(r, g, b, a)
  return {
    red = r or 0, green = g or 0, blue = b or 0, alpha = a or 255
  }
end
module.Solar_NewColor = Solar_NewColor
function Solar_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end
module.Solar_TranslateColor = Solar_TranslateColor

--
-- Math Utils
--
function Solar_GetRelativePosition(pr, pa, tp)
  -- pr: position relative
  -- pa: position absolute
  -- tp: tile position
  return (-pa.x + pr.x) + tp.x, (-pa.y + pr.y) + tp.y
end
module.Solar_GetRelativePosition = Solar_GetRelativePosition

--
-- Misc. Utils
--
function Solar_InvokeAndMeasureTime(invoke_function, ...)
  local begun     = os.clock()
  local returned  = invoke_function(...)
  return os.clock() - begun, returned
end
module.Solar_InvokeAndMeasureTime = Solar_InvokeAndMeasureTime
function Solar_Printf(format, ...)
  local wrap_within = print
  wrap_within(string.format(format, unpack(...)))
end
module.Solar_Printf = Solar_Printf
function Solar_CheckFile(file)
  local fp = io.open(file, "r")
  if fp == nil then
    return false
  else
    fp:close()
    return true
  end
end
module.Solar_CheckFile = Solar_CheckFile

--
-- Routine Utility
--
function Solar_PerformRoutineTable(routine_table)
  for _, routine in ipairs(routine_table) do
    local time_taken, _   = Solar_InvokeAndMeasureTime(routine.wrap, unpack(routine.args))
    routine["time_taken"] =time_taken
  end
end
module.Solar_PerformRoutineTable = Solar_PerformRoutineTable

--
return module