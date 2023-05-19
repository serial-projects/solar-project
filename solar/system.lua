local module={}
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
    table.merge(tokenized_file, Solar_Tokenize(line:gsub("\n",' '):gsub("\t",'  ')))
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
return module