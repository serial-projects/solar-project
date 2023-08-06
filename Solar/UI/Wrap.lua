-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SUI_Button    = require("Solar.UI.Button")
local SUI_Label     = require("Solar.UI.Label")

local module={}

module.Sol_UIElementTypesWrap={
  label         ={tick=SUI_Label.Sol_TickLabel,      draw=SUI_Label.Sol_DrawLabel,        keypress=nil},
  button        ={tick=SUI_Button.Sol_TickButton,    draw=SUI_Button.Sol_DrawButton,      keypress=nil}
}

return module