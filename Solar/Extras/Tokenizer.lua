-- string.tokenizer(s: string, specifications: table) -> table: a tokenizer will split the tokens
-- and make them more evident for internal parsing and other stuff.
_G["TokenizerImported"] = true

local DEFAULT_STRING_DELIMITERS = {["\""]=true,["'"]=true}
function string.tokenizer(s, specifications)
  local ignore_tokens = specifications["ignore_tokens"] or {}
  local single_tokens = specifications["single_tokens"] or {}
  local duple_tokens  = specifications["duple_tokens"]  or {}
  local inline_commentary_tokens  = specifications["inline_commentary_tokens"] or {}
  local string_delimiters         = specifications["string_delimiters"] or DEFAULT_STRING_DELIMITERS
  --
  local acc, tokens = "", {}
  local index, length = 1, #s
  local inside_string, string_begin_with_delimiter = false, nil
  --
  local function append_token(suffix, after_append)
    if suffix then acc = acc .. suffix end
    if #acc > 0 then
      tokens[#tokens+1] = acc
    end
    acc = after_append or ""
  end
  --
  while index <= length do
    local current_char = s:sub(index, index)
    local iterate_duple_char = current_char .. (index + 1 <= length and s:sub(index + 1, index + 1) or '')
    if current_char == ' ' and not inside_string then
      append_token()
    elseif ignore_tokens[current_char] and not inside_string then
      goto skip_everything
    elseif (single_tokens[current_char] or duple_tokens[iterate_duple_char]) and not inside_string then
      local is_duple_token = duple_tokens[iterate_duple_char] ~= nil
      append_token() ; tokens[#tokens+1] = is_duple_token and iterate_duple_char or current_char
      if is_duple_token then index = index + 1 end
    elseif inline_commentary_tokens[current_char] and not inside_string then
      append_token()
      break
    elseif string_delimiters[current_char] and not inside_string then
      append_token(nil, current_char) ; inside_string, string_begin_with_delimiter = true, current_char
    elseif current_char == string_begin_with_delimiter and inside_string then
      append_token(current_char, nil) ; inside_string = false
    else
      acc = acc .. current_char
    end
    ::skip_everything::
    index = index + 1
  end
  append_token()
  return tokens
end