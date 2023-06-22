local sgen=require("sol.sgen")
local smath=require("sol.smath")
local ui_math=require("sol.ui.math")
local module={}

--[[ Begin the "Button" functions ]]
local BUTTON_LEFT   = 1
local BUTTON_MIDDLE = 2
local BUTTON_RIGHT  = 3

-- Sol_NewButton(button: {type, font, text, non_formatted_text, background_color, background_hovering_color, foreground_color, rectangle, position, force_absolute, has_borders, border_color, visible, hovering, when_left_click, when_right_click })
function module.Sol_NewButton(button)
  local button = button or {}
  return sgen.Sol_BuildStruct({
    type                      = "button",
    font                      = sgen.SNIL,
    text                      = "",
    non_formatted_text        = "",
    background_color          = smath.Sol_NewColor4(0, 0, 0),
    background_hovering_color = smath.Sol_NewColor4(10, 10, 10),
    foreground_color          = smath.Sol_NewColor4(255, 255, 255),
    rectangle                 = smath.Sol_NewRectangle(nil, button["size"]),
    position                  = smath.Sol_NewVector(0, 0),
    force_absolute            = sgen.SFALSE,
    has_borders               = sgen.SFALSE,
    border_color              = smath.Sol_NewColor4(0, 0, 0),
    visible                   = true,
    hovering                  = sgen.SFALSE,
    when_left_click           = sgen.SNIL,
    when_middle_click         = sgen.SNIL,
    when_right_click          = sgen.SNIL
  }, button)
end
function module.Sol_TickButton(display, button)
  local function check_click_for_button(button_id, action_perform)
    if love.mouse.isDown(button_id) and button.hovering then
      if type(action_perform)=="function" then action_perform() end
    end
  end
  button.hovering=smath.Sol_TestRectangleCollision(display.cursor.rectangle, button.rectangle)
  if button.visible then
    button.rectangle.size.x,button.rectangle.size.y=button.size.x,button.size.y
    if    button.force_absolute then button.rectangle.position.x,button.rectangle.position.y=button.position.x,button.position.y
    else  button.rectangle.position.x,button.rectangle.position.y=ui_math.Sol_UITranslateRelativePosition(display.size.x, display.size.y, button.rectangle.size.x, button.rectangle.size.y, button.position.x, button.position.y) end
    --
    check_click_for_button(BUTTON_LEFT,   button.when_left_click)
    check_click_for_button(BUTTON_MIDDLE, button.when_middle_click)
    check_click_for_button(BUTTON_RIGHT,  button.when_right_click)
  end
end
function module.Sol_DrawButton(display, button)
  -- TODO: clean this code.
  if button.visible then
    if button.font then
      --> the main rectangle
      love.graphics.setColor(smath.Sol_TranslateColor(button.hovering and button.background_hovering_color or button.background_color))
      love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(button.rectangle))
      --> the borders
      if button.has_borders then
        love.graphics.setColor(smath.Sol_TranslateColor(button.border_color))
        love.graphics.rectangle("line", smath.Sol_UnpackRectXYWH(button.rectangle))
      end
      --> the text
      local text_width, text_height=button.font:getWidth(button.text),button.font:getHeight()
      local text_position_x=math.floor( (button.rectangle.position.x+(button.rectangle.size.x/2)) - (text_width ) )
      local text_position_y=math.floor( (button.rectangle.position.y+(button.rectangle.size.y/2)) - (text_height) )
      love.graphics.setColor(smath.Sol_TranslateColor(button.foreground_color))
      love.graphics.print(button.text, text_position_x, text_position_y)
    end
  end
end

--
return module