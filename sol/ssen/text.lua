local module={}
--
local function SSEN_IsCharNumber(ch)
  local ch = string.byte(ch) ; return ch >= string.byte('0') and ch <= string.byte('9')
end
function module.SSEN_PurifyString(str)
  -- TODO: this thing of purifying the string CAN remove some properties from the original
  -- file and must be rewritten on a distant future for a more smarter version of this.
  local _TAB_REPLACEMENT="  "
  return str:gsub("\n"," "):gsub("\t",_TAB_REPLACEMENT)
end
function module.SSEN_Tokenize(str)
  local index, length   = 1, #str
  local tokens, acc     = {}, ""
  local instr, strb     = false, nil
  local function append_token(prefix, suffix)
    if suffix then acc = acc .. suffix end
    if #acc > 0 then
      tokens[#tokens+1]=acc
    end
    acc=prefix ~= nil and prefix or ""
  end
  local STRING_CHARS={["'"]=true,['"']=true}
  while index<=length do
    local cch = str:sub(index, index)
    -- for empty spaces:
    if (cch == ' ') and not instr then
      append_token()
    -- for comments:
    elseif (cch == ';') and not instr then
      append_token() ; break
    -- for strings:
    elseif (STRING_CHARS[cch]) and not instr then
      append_token(cch, nil) ; instr, strb = true, cch
    elseif (cch == strb) and instr then
      append_token(nil, cch) ; instr, strb = false, nil
    -- escape emulation:
    elseif (cch == '\\') and instr then
      mwarn("escape not yet supported: \"%s\" (condition found in string).", str)
    -- for any other character:
    else
      acc = acc .. cch
    end
    index=index+1
  end
  append_token()
  return tokens
end
--
return module