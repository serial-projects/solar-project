local sgen=require("sol.sgen")
local smath=require("sol.smath")
local ui_math=require("sol.ui.math")
local module={}

--[[ Begin the "Label" functions ]]
function module.Sol_NewLabel(label)
  local label = label or {}
  return sgen.Sol_BuildStruct({
    type                = "label",
    non_formatted_text  = sgen.SNIL,
    text                = "",
    font                = sgen.SNIL,
    color               = smath.Sol_NewColor4(0, 0, 0),
    rectangle           = smath.Sol_NewRectangle(),
    position            = smath.Sol_NewVector(0, 0),
    has_background      = false,
    background_color    = smath.Sol_NewColor4(0, 0, 0),
    force_absolute      = false,
    when_left_click     = 0,
    when_right_click    = 0,
    visible             = true,
  }, label)
end
function module.Sol_TickLabel(display, label)

end
function module.Sol_DrawLabel(display, label)
  if label.visible then
    if label.font then
      label.rectangle.size.x,label.rectangle.size.y = label.font:getWidth(label.text), label.font:getHeight()
      if    label.force_absolute then label.rectangle.position.x,label.rectangle.position.y = label.position.x, label.position.y
      else  label.rectangle.position.x, label.rectangle.position.y = ui_math.Sol_UITranslateRelativePosition(display.size.x, display.size.y, label.rectangle.size.x, label.rectangle.size.y, label.position.x, label.position.y) end
      if label.has_background then
        love.graphics.setColor(smath.Sol_TranslateColor(label.background_color))
        love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(label.rectangle))
      end
      love.graphics.setFont(label.font)
      love.graphics.setColor(smath.Sol_TranslateColor(label.color))
      love.graphics.print(label.text, label.rectangle.position.x, label.rectangle.position.y)
    end
  end
end

--
return module