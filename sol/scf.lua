-- Sectionized Configuration File: SCF for short.
local module = {}
local sfmt = string.format

local SCF_TAB_REPLACEMENT = '  '
local SCF_ENCODE_SPACING  = 2
--
local function recursive_concat(list, sep)
  local str = "["
  for index = 1, #list do
    local element = list[index]
    if type(element) == "table" then
      str = str .. recursive_concat(element)
    else
      str = str .. (type(element) == 'string' and '"' .. element .. '"' or tostring(element))
    end
    str = str .. (index == #list and '' or ', ')
  end
  str = str .. "]"
  return str
end

--
function SCF_TableRecursiveInsert(t, element)
  if type(element) == 'table' then
    for _, value in ipairs(element) do
      SCF_TableRecursiveInsert(t, value)
    end
    return
  end
  table.insert(t, element)
end
function SCF_Tokenize(str)
  local index, length, acc, tokens = 1, #str, "", {}
  local inside_str, str_begun_char, skip_string_closure = false, nil, false
  local function append_acc(acc_replacement)
    if #acc > 0 then table.insert(tokens, acc) end ; acc = (acc_replacement or "")
  end
  while index <= length do
    local char = str:sub(index, index)
    --[[ Special Characters ]]--
    if (char == ' ' or char == ',') and not inside_str then
      append_acc()
    elseif (char == '#') and not inside_str then
      append_acc() ; break
    elseif (char == '[' or char == ']') and not inside_str then
      append_acc() ; table.insert(tokens, char)
    --[[ Strings ]]--
    elseif (char == '"' or char == '\'') and not inside_str then
      append_acc(char) ; inside_str, str_begun_char = true, char
    elseif (char == str_begun_char) and inside_str then
      if skip_string_closure then
        acc, skip_string_closure = acc .. char, false
      else
        acc, inside_str, str_begun_char = acc .. char, false, nil ; append_acc()
      end
    elseif (char == '\\') and inside_str then
      skip_string_closure = true
    --[[ Anything ]]--
    else
      acc = acc .. char
    end
    index = index + 1
  end
  append_acc()
  return tokens
end
module.SCF_Tokenize = SCF_Tokenize

function SCF_Sectionize(tokenized_buffer, logger)
  --
  local function is_string_char(char) return (char == '"' or char == '\'') end
  --
  local index, length = 1, #tokenized_buffer
  local function get_current_value()
    local content=tokenized_buffer[index]
    if content == "[" then
      -- NOTE: this is a recursive function, so be very cautious when working with this.
      local array = {} ; index = index + 1
      while true do
        local list_element = tokenized_buffer[index]
        if list_element == ']' then
          break
        else
          table.insert(array, get_current_value())
          index = index + 1
        end
      end
     return array
    elseif is_string_char(content:sub(1, 1)) and is_string_char(content:sub(#content, #content)) then
      return content:sub(2, #content-1)
    elseif tonumber(content) then
      return tonumber(content)
    elseif content == "yes" or content == "true" or content == "no" or content == "false" then
      return content == "yes" or content == "true"
    else
      error("invalid type: "..content )
    end
  end
  --
  local function sectionize(initializer, depth)
    local current_tree = initializer or {}
    while index <= length do
      local token = tokenized_buffer[index]
      if token == "section" then
        assert(index + 1 <= length, "section expects: name")
        local section_name = tokenized_buffer[index + 1]
        index = index + 2
        current_tree[section_name]=sectionize({['__type']="section"}, depth + 1)
      elseif token == "end-section" then
        break
      elseif token == "define" then
        assert(index + 2 <= length, "define expects <name>, <content>")
        local name  = tokenized_buffer[index + 1]
        index       = index + 2
        assert(depth ~= 1, sfmt("%s outside section!", name))
        current_tree[name]=get_current_value()
      else
        error(sfmt("[token: %d]: invalid token: %s", index, token))
      end
      index = index + 1
    end
    return current_tree
  end
  --
  local tree = sectionize(nil, 1)
  return tree
end
module.SCF_Sectionize = SCF_Sectionize

-- TODO: implement a way to use '\t' on some files.
-- TODO: since TABLE keys are not sorted, the values get all messy.
-- TODO: this function uses two variables to store spacing_depth and last depth.
function SCF_Encode(tree)
  --
  local function generate_empty_string(length)
    local str = "" for index = 1, length do str = str .. " " end
    return str
  end
  --
  local function encode_tree(name, stree, depth)
    local spacing_depth   = generate_empty_string(SCF_ENCODE_SPACING * depth)
    local last_depth      = generate_empty_string(SCF_ENCODE_SPACING * (depth - 1))
    local str = (depth == 1 and '' or last_depth) .. "section " .. name .. "\n"
    for definition_name, definition_value in pairs(stree) do
      if definition_name ~= "__type" then
        if type(definition_value) == "table" and definition_value["__type"] then
          str = str .. encode_tree(definition_name, definition_value, SCF_ENCODE_SPACING * depth)
        else
          local value = type(definition_value) == 'table' and recursive_concat(definition_value)  or
                        type(definition_value) == 'string'and '"' .. definition_value .. '"'      or
                        tostring(definition_value)
          str = str .. (spacing_depth) .. ("define " .. definition_name .. ", " .. value) .. "\n"
        end
      end
    end
    str = str .. ( depth == 1 and '' or last_depth) .. "end-section" .. "\n"
    return str
  end
  --
  local initial = ""
  for section, content in pairs(tree) do 
    initial = initial .. encode_tree(section, content, 1)
  end
  return initial
end

function SCF_ShowTree(tree, print_function)
  local print_function = print_function or print
  --
  local function subtree(name, stree, depth)
    local spacing_depth = (function() local str = "" for index = 1, depth do str = str .. " " end return str end)()
    print_function(spacing_depth .. "** begin section [".. name .."] **")
    for definition_name, definition_value in pairs(stree) do
      if type(definition_value) == "table" and definition_value["__type"] then
        subtree(definition_name, definition_value, depth + 4)
      else
        local value = type(definition_value) == 'table' and recursive_concat(definition_value) or tostring(definition_value)
        print_function(spacing_depth .. sfmt("  %s: %s", definition_name, value ))
      end
    end
  end
  for section, content in pairs(tree) do subtree(section, content, 0) end
  --
end

function SCF_LoadBuffer(buffer, purify_buffer)
  return  purify_buffer and SCF_Sectionize(SCF_Tokenize(buffer:gsub('\n'," "):gsub('\t',SCF_TAB_REPLACEMENT)), nil) or 
          SCF_Sectionize(SCF_Tokenize(buffer), nil)
end
module.SCF_LoadBuffer = SCF_LoadBuffer

function SCF_LoadFile(file)
  assert(type(file)=="string", "invalid type for file.")
  local tokenized_file = {}
  local fp = io.open(file, "r")
  assert(fp ~= nil, "failed to open file: "..file)
  for line in fp:lines() do
    local clean_line=line:gsub("\n",""):gsub("\t",SCF_TAB_REPLACEMENT)
    SCF_TableRecursiveInsert(tokenized_file, SCF_Tokenize(clean_line))
  end
  fp:close()
  local built_tree = SCF_Sectionize(tokenized_file, nil)
  return built_tree
end
module.SCF_LoadFile = SCF_LoadFile
--
return module