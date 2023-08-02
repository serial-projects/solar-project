local ui_button=require("sol.ui.button")
local ui_label=require("sol.ui.label")
local module={}
--
module.Sol_UIElementTypesWrap={
  label         ={tick=ui_label.Sol_TickLabel,      draw=ui_label.Sol_DrawLabel,        keypress=nil},
  button        ={tick=ui_button.Sol_TickButton,    draw=ui_button.Sol_DrawButton,      keypress=nil}
}
--
return module