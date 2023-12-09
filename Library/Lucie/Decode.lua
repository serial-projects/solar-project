local module = {}

local Text = require("Library.Lucie.Text")
local extra_table = require("Library.Extra.Table")

local function collapse_table(ta)
	local function collapse_table_recursive(t)
		local tree = {}
		for _, value in ipairs(t) do
			if value["type"] == "data" then tree[value["name"]] = value["content"]
			else tree[value["name"]] = collapse_table_recursive(value["content"]) end
		end
		return tree
	end
	return collapse_table_recursive(ta)
end

function module.decode_buffer(buffer)
	local tokenizer_instance = Text:new_tokenizer()
	tokenizer_instance:feed(buffer)
	local sectionized_buffer = Text.sectionize(tokenizer_instance.tokens)
	local collapsed_sections = collapse_table(sectionized_buffer)
	return sectionized_buffer, collapsed_sections
end

-- NOTE: this is a LOVE version, use love.filesystem.newFile()
function module.decode_file(file, open_function) open_function = open_function or love.filesystem.newFile
	local fp = open_function(file, "r") ; assert(fp, "failed to open file: " .. file)
	local sectionized_buffer, collapsed_sections = module.decode_buffer(fp:read("*a"))
	fp:close() ; return sectionized_buffer, collapsed_sections
end 

return module