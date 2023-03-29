local module = {} 
local consts = require("solar.consts")
function Solar_NewTerminal()
  return {
    lines     = {}, line_limit = 80,
    viewport  = nil, base_display = nil
  }
end
module.Solar_NewTerminal = Solar_NewTerminal
function Solar_InitTerminal(terminal, base_display)
end
module.Solar_InitTerminal = Solar_InitTerminal
--
return module