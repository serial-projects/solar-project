-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SC_Structures = require("Solar.Code.Structures")
local SM_Color      = require("Solar.Math.Color")
local SM_Vector     = require("Solar.Math.Vector")
local SM_Rectangle  = require("Solar.Math.Rectangle")

local SUI_Math      = require("Solar.UI.Math")

local module={}

--[[ Begin the "Label" functions ]]

-- Sol_NewLabel(label: { type, non_formatted_text, text, font, color, rectangle, relative_to, position, has_background, background_color, force_absolute, when_left_click, when_right_click, visible })
function module.Sol_NewLabel(label)
  local label = label or {}
  return SC_Structures.Sol_BuildStruct({
    type                = "label",
    non_formatted_text  = 0,
    text                = "",
    font                = 0,
    color               = SM_Color.Sol_NewColor4(0, 0, 0),
    rectangle           = SM_Rectangle.Sol_NewRectangle(),
    relative_to         = 0,
    position            = SM_Vector.Sol_NewVector(0, 0),
    has_background      = false,
    background_color    = SM_Color.Sol_NewColor4(0, 0, 0),
    force_absolute      = false,
    when_left_click     = 0,
    when_right_click    = 0,
    visible             = true,
  }, label)
end

-- Sol_TickLabel(display: Sol_Display, label: Sol_UILabel)
function module.Sol_TickLabel(display, label)
end

function module.Sol_DrawLabel(display, label)
  if label.visible then
    if label.font ~= 0 then
      label.rectangle.size.x,label.rectangle.size.y = label.font:getWidth(label.text), label.font:getHeight()
      if    label.force_absolute then label.rectangle.position.x,label.rectangle.position.y = label.position.x, label.position.y
      else
        if type(label.relative_to) ~= "table" then
          label.rectangle.position.x, label.rectangle.position.y = SUI_Math.Sol_UITranslateRelativePosition(display.size.x, display.size.y, label.rectangle.size.x, label.rectangle.size.y, label.position.x, label.position.y)
        else
          -- TODO: fix this probably fault calculation on the screen coords.
          label.rectangle.position.x, label.rectangle.position.y = SUI_Math.Sol_UITranslateRelativePosition(label.relative_to.bg_size.x, label.relative_to.bg_size.y, label.rectangle.size.x, label.rectangle.size.y, label.position.x, label.position.y)
          print(label.rectangle.position.y)
          label.rectangle.position.x=math.abs(label.relative_to.bg_position.x+label.rectangle.position.x)
          label.rectangle.position.y=math.abs(label.relative_to.bg_position.y+label.rectangle.position.y)
        end
      end
      if label.has_background then
        love.graphics.setColor(SM_Color.Sol_TranslateColor(label.background_color))
        love.graphics.rectangle("fill", SM_Rectangle.Sol_UnpackRectXYWH(label.rectangle))
      end
      love.graphics.setFont(label.font)
      love.graphics.setColor(SM_Color.Sol_TranslateColor(label.color))
      love.graphics.print(label.text, label.rectangle.position.x, label.rectangle.position.y)
    end
  end
end 

--
return module