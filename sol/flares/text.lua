local sbyte=string.byte
local schar=string.char
local module={}

--
local function __LE_ischar_ranged(char,max,min) return sbyte(char)>=sbyte(min) and sbyte(char)<=sbyte(max) end
local function __LE_ischar_number(char) return __LE_ischar_ranged(char,'0','9') end
local function __LE_ischar_letter(char) return __LE_ischar_ranged(char,'a','z') or __LE_ischar_ranged(char,'A','Z') end
local function __LE_ischar_valid (char) return __LE_ischar_number(char) or __LE_ischar_letter(char) end
local function __LE_ischar_strchr(char) return (char == '\'' or char == '"') end

--[[ 
	FLS_Tokenize(str): tokenize the "str" into a token sequence, like:
	"section X" -> ["section", "X"]
]]--
function FLS_Tokenize(str, settings)
	local settings=settings or {comment_char=';', string_chars={["'"]=true,["\""]=true}}
	local index,length=1,#str
	local tokens,acc={},""
	local instr, sb=false,nil
	local function append_token(suffix_token,new_token)
		if suffix_token then
			acc=acc..suffix_token
		end
		if #acc > 0 then
			tokens[#tokens+1]=acc
		end
		acc=new_token or ""
	end
	while index<=length do
		local char=str:sub(index,index)
		--[[ empty characters ]]--
		if (char == ' ' or char == ',') and not instr then
			append_token()
		--[[ special chars ]]--
		elseif (char == ']' or char == '[') and not instr then
			append_token() ; tokens[#tokens+1]=char
		--[[ comment ]]--
		elseif (char == settings.comment_char) and not instr then
			append_token()
			break
		--[[ strings ]]--
		elseif (settings.string_chars[char]) and not instr then
			append_token(nil, char)
			instr, sb=true, char
		elseif (char==sb) and instr then
			append_token(char)
			instr, sb=false, nil
		--[[ string escape ]]--
		elseif (char == '\\') and instr then
			assert(index+1<=length,"unfinished escape?")
			local next_char=str:sub(index+1,index+1)
			if __LE_ischar_number(next_char) then
				local subindex,sub_acc=index+2,""
				while subindex<=subindex+3 do
					local subchar=str:sub(subindex,subindex)
					if __LE_ischar_number(subchar) then
						sub_acc=sub_acc..subchar
					else
						break
					end
					subindex=subindex+1
				end
				sub_acc=tonumber(sub_acc)
				assert(sub_acc,"escape is not number: "..sub_acc)
				if not (sub_acc>=0 and sub_acc<=255) then sub_acc = 0 end
				acc=acc..string.char(sub_acc)
				index=subindex-1
			else
				acc=acc..string.char(next_char)
				index=index+1
			end
		--[[ anything else ]]--
		else
			acc=acc..char
		end			
		index=index+1
	end
	append_token()
	return tokens
end ; module.FLS_Tokenize=FLS_Tokenize

--
return module