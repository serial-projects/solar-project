local module = {}

local sfmt = string.format
local sbyte = string.byte
local schar = string.char

local LUCIE_TOKEN_DELIMITATIONS 		= {[" "]=true,["\t"]=true}
local LUCIE_HIGHLIGHT_TOKENS 			= {["["]=true, ["]"]=true, ['\n']=true}
local LUCIE_IGNORE_TOKENS 				= {[","]=true}
local LUCIE_STRING_DELIMITATIONS 		= {["\""]=true,["'"]=true}
local LUCIE_INLINE_COMMENT 				= "#"

function module.new_tokenizer()
	local proto_tokenizer = {
		tokens = {}, 	acc = "",
		instr = false,  strb = 0, inliteral = false, litbuffer = "",
		incom = false,	comtype = 0, waitnl = false
	}
	--[[ push/ enter & quit state functions ]]--
	function proto_tokenizer:push_token(pre_push, post_push)
		if pre_push then self.acc = self.acc .. pre_push end
		if #self.acc > 0 then self.tokens[#self.tokens+1] = self.acc end
		self.acc = post_push or ""
	end
	function proto_tokenizer:enter_string(entered_with_ch)
		self.strb = entered_with_ch ; self.instr = true
		self:push_token(nil, entered_with_ch)
	end
	function proto_tokenizer:quit_string()
		self:push_token(self.strb, nil)
		self.instr = false
	end
	function proto_tokenizer:enter_comment()
		self:push_token()
		self.incom = true
	end
	--[[ inside/outside string text processing ]]--
	function proto_tokenizer:enter_literal()
		self.inliteral = true
	end
	function proto_tokenizer:instr_eat(char)
		if self.inliteral then
			local literal_counter = #self.litbuffer
			if tonumber(char) and literal_counter == 0 then
				-- BEGIN:
			elseif tonumber(char) then
				-- KEEP:
				self.acc = self.acc .. char
			else
				-- everything on chars:
				-- 1° situation: when running on the literal 0, the literal will just add the next character.
				-- 2° situation: tonumber failed (non number), then convert.
				if literal_counter == 0 then
					self.acc 		= self.acc .. char
					self.inliteral 	= false
				else
					local converted_number = tonumber(self.litbuffer)
					---@diagnostic disable-next-line
					self.acc = self.acc .. string.char(converted_number)
					self.inliteral = false
				end
			end
		else
			if self.strb == char then 	self:quit_string()
			elseif char == '\\' then 	self:enter_literal()
			else self.acc = self.acc .. char end
		end
	end
	-- NOTE: try to decide what type of commentary it is, a single line will wait for the '\n' character
	-- but multiline commentary, we just enter different states of comments, here how the logic works:
	-- [<initial decision>: 0, <inline_com>: 1, <multiline_com>: 2, <end_multiline>: 3]
	-- 																| (if not '#' on the last, then return to mode '2')

	-- NOTE: also, capture all the '\n' tokens, on the next step, they will be important to keep track
	-- of where the objects are being defined (aka. line which it was defined). On the future, though,
	-- do a better method where a single line can do that.
	function proto_tokenizer:incom_eat(char)
		if char ~= '*' then self.comtype = 1
		else 				self.comtype = 2 end
	end
	function proto_tokenizer:inlinecom_eat(char)
		if char == '\n' then
			self.incom, self.comtype = false, 0
			self.tokens[#self.tokens+1] = '\n'
		end
	end
	function proto_tokenizer:inmultilinecom_eat(char)
		if char == '*' then
			-- NOTE: because '*' is a very used character, we need to check more deeply 
			-- if '#' is the next character, if yes, then break from the commentary state.
			self.comtype = 3
		elseif char == '\n' then
			self.tokens[#self.tokens+1] = '\n'
		end
	end
	function proto_tokenizer:inmultilinecom_try_quit(char)
		if char == '#' then
			self.incom, self.comtype = false, 0
		else
			-- anything else, return to the past state & do not leave the current state.
			if char == '\n' then self.tokens[#self.tokens+1] = '\n' end
			self.comtype = 2
		end
	end
	function proto_tokenizer:default_eat(char)
		if LUCIE_TOKEN_DELIMITATIONS[char] or LUCIE_IGNORE_TOKENS[char] then
			self:push_token()
		elseif LUCIE_HIGHLIGHT_TOKENS[char] then
			self:push_token()
			self.tokens[#self.tokens+1] = char
		elseif LUCIE_STRING_DELIMITATIONS[char] then
			self:enter_string(char)
		elseif LUCIE_INLINE_COMMENT == char then
			self:enter_comment()
		else 
			self.acc = self.acc .. char
		end
	end
	function proto_tokenizer:feedch(char)
		local comswitch = {
			[0] = function(ch) self:incom_eat(ch) end,
			[1] = function(ch) self:inlinecom_eat(ch) end,
			[2] = function(ch) self:inmultilinecom_eat(ch) end,
			[3] = function(ch) self:inmultilinecom_try_quit(ch) end
		}
		if self.instr then self:instr_eat(char)
		elseif self.incom then comswitch[self.comtype](char)
		else self:default_eat(char) end
	end
	function proto_tokenizer:feed(buffer)
		for index = 1, #buffer do
			self:feedch( buffer:sub(index, index) )
		end
		self:push_token()
	end
	--[[ return the proto token ]]--
	return proto_tokenizer
end

local function validate_name(token)
	local function ischar(char, allow_numbers) allow_numbers = (allow_numbers == nil) and false or allow_numbers
		char = sbyte(char)
		return 	( char >= sbyte('a') and char <= sbyte('z' )) 						or
				( char >= sbyte('A') and char <= sbyte('Z') ) 						or
				( allow_numbers and (char >= sbyte('0') and char <= sbyte('9')) ) 	or
				( char == sbyte('_') )
	end
	for index = 1, #token do
		local ch = token:sub(index, index)
		if not ischar(ch, true) then
			return false, index
		end
	end
	return true, 0
end

local LUCIE_DEFINE_DATA_KEYWORDS = {["set"]=true,["define"]=true}
local LUCIE_BOOLEANS = {["yes"]=true,["true"]=true,["no"]=true,["false"]=true}

function module.sectionize(tokens)

	local index, length = 1, #tokens
	local line_counter = 0

	local function get_data()
		local data
		local token = tokens[index]
		if LUCIE_STRING_DELIMITATIONS[token:sub(1, 1)] and LUCIE_STRING_DELIMITATIONS[token:sub(#token, #token )] then
			data = token:sub(2, #token - 1)
		elseif tonumber(token) then
			data = tonumber(token)
		elseif LUCIE_BOOLEANS[token] then
			data = (token == "yes" or token == "true")
		elseif token == "[" then
			index = index + 1
			data = {}
			while index <= length do
				token = tokens[index]
				if token == "]" then
					break
				elseif token == '\n' then
					line_counter = line_counter + 1
				else
					data[#data+1] = get_data()
				end
				index = index + 1
			end
			-- NOTE: do not increment from ']', the loop already to this do us!
		else
			error(sfmt("at line: %d, invalid data value: \"%s\"", line_counter, token))
		end
		return data
	end

	local function get_section()
		local tree = {}
		while index <= length do
			local token = tokens[index]
			if token == "section" then
				assert(index + 1 <= length, sfmt("at line: %d, section requires <name>, tokens finished too early!", line_counter))
				local secname = tokens[index + 1]
				local secname_validated, secname_badtoken_index = validate_name(secname)
				assert(secname_validated, sfmt("at line: %d, invalid name: \"%s\", bad token at: %d", line_counter, secname, secname_badtoken_index))
				-- up with the index & begin recursion:
				index = index + 2
				tree[#tree+1] = { ["type"] = "section", name = secname, content = get_section() }
			elseif token == "end" then
				index = index + 1
				break
			elseif LUCIE_DEFINE_DATA_KEYWORDS[token] then
				assert(index + 1 <= length, sfmt("at line: %d, %s requires <name>, <content...>, keyword finished too early!", line_counter, token))
				local data_name = tokens[index + 1]
				local dname_validated, dname_badtoken_index = validate_name(data_name)
				assert(dname_validated, sfmt("at line: %d, invalid name: \"%s\", bad token at: %d", line_counter, data_name, dname_badtoken_index))
				-- also, up with the index & begin recursion:
				index = index + 2
				tree[#tree+1] = { ["type"] = "data", name = data_name, content = get_data() }
				index = index + 1
			elseif token == '\n' then
				line_counter = line_counter + 1
				index = index + 1
			else
				error(sfmt("at line: %d, invalid keyword: \"%s\"", line_counter, token))
			end
		end
		return tree
	end

	return get_section()
end

return module