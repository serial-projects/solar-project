-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

function module.SPI_IsCharacterNumber(ch)
	ch = string.byte(ch)
	return (ch >= string.byte('0') and ch <= string.byte('9'))
end

local VALID_STRING_CHARS  = {["\""]=true,["'"]=true}
local IGNORE_CHARS        = {[","]=true}

function module.SPI_Tokenize(str)
	local acc, tokens = "", {}
	local index, length = 1, #str
	local instr, strb = false, nil
  	--> Local functions :)
	local function __AppendToken(begin_with, lastch)
		if lastch then
			acc = acc .. lastch
		end
		if #acc > 0 then
			table.insert(tokens, acc)
		end
		acc = begin_with or ""
	end
	local function __EmulateStringLiteral()
		local nextch = str:sub(index+1,index+1)
		if module.FOR_IsCharacterNumber(nextch) then
			local subacc = ""
			for subindex = (index + 1), (index + 4) do
				local subchar=str:sub(subindex,subindex)
				if module.FOR_IsCharacterNumber(subchar) then
					subacc = subacc .. subchar
				else
					break
				end
			end
			index  = index + #subacc
    		local converted_string = tonumber(subacc) ; converted_string = converted_string > 255 and 255 or converted_string
			acc		 = acc .. string.char(converted_string)
		else
			acc = acc .. nextch
			index = index + 1
		end
	end
	--> the parsing loop:
	while index <= length do
		local current_char = str:sub(index, index)
		if (current_char == ' ' or IGNORE_CHARS[current_char]) and not instr then
			__AppendToken()
		elseif current_char == '\n' and not instr then  __AppendToken()
		elseif current_char == '\t' and not instr then  __AppendToken()
		elseif current_char == ';'  and not instr then  break
		elseif VALID_STRING_CHARS[current_char] and not instr then
			__AppendToken(current_char, nil) ; instr, strb = true, current_char
		elseif current_char == strb and instr then
			__AppendToken(nil, current_char) ; instr = false
		elseif current_char == '\\' and instr then      __EmulateStringLiteral()
		else
			acc = acc .. current_char
		end
		index=index+1
	end
	--> flush the remaining tokens (in case there is remaining tokens!)
	__AppendToken()
	return tokens
end

return module