local sgen = require("sol.sgen")
local smath = require("sol.smath")
local defaults = require("sol.defaults")
local module={}
--[[ Math stuff ]]
function Solar_UITranslateRelativePosition(ww, wh, ew, eh, posx, posy)
  -- calculate the window divided by 100 (for every axis.)
  local xpos, ypos      = (ww / 100), (wh / 100)
  local xoff, yoff      = (ew / 100) * posx, (eh / 100) * posy
  local abposx, abposy  = (xpos * posx) - xoff, (ypos * posy) - yoff
  return math.floor(abposx), math.floor(abposy)
end

--[[ Generics ]]--
function Sol_GenericTickFunctionWithClickDetection(display, element)
  
end ; module.Sol_GenericTickFunctionWithClickDetection=Sol_GenericTickFunctionWithClickDetection

--[[ Begin the "Label" functions ]]
function Sol_NewLabel(label)
  local label = label or {}
  return sgen.Sol_BuildStruct({
    type = "label",
    non_formatted_text = sgen.SNIL,
    text = "",
    font = sgen.SNIL,
    color = smath.Sol_NewColor4(0, 0, 0),
    rectangle = smath.Sol_NewRectangle(),
    position = smath.Sol_NewVector(0, 0),
    has_background = false,
    background_color = smath.Sol_NewColor4(0, 0, 0),
    force_absolute = false,
    when_left_click=0,
    when_right_click=0,
  }, label)
end ; module.Sol_NewLabel=Sol_NewLabel
function Sol_TickLabel(display, label)
  
end
function Sol_DrawLabel(display, label)
  if label.font then
    label.rectangle.size.x,label.rectangle.size.y = label.font:getWidth(label.text), label.font:getHeight()
    if    label.force_absolute then label.rectangle.position.x,label.rectangle.position.y = label.position.x, label.position.y
    else  label.rectangle.position.x, label.rectangle.position.y = Solar_UITranslateRelativePosition(display.size.x, display.size.y, label.rectangle.size.x, label.rectangle.size.y, label.position.x, label.position.y) end
    if label.has_background then
      love.graphics.setColor(smath.Sol_TranslateColor(label.background_color))
      love.graphics.rectangle("fill", Sol_UnpackRectXYWH(label.rectangle))
    end
    love.graphics.setFont(label.font)
    love.graphics.setColor(smath.Sol_TranslateColor(label.color))
    love.graphics.print(label.text, label.rectangle.position.x, label.rectangle.position.y)
  end
end

--[[ Begin the "Button" functions ]]
function Sol_NewButton(button)
  local button = button or {}
  return sgen.Sol_BuildStruct({
    text = "",
    font = 0,
  })
end
function Sol_TickButton(display, button)

end
function Sol_DrawButton(display, button)
end

--[[ Enumerate the types keypress and other stuff ]]
local Sol_UIElementTypesWrap={
  label={tick=Sol_TickLabel, draw=Sol_DrawLabel, keypress=nil}
}

--[[ Begin the "Frame" functions ]]
function Sol_NewFrame(frame)
  local frame = frame or {}
  return sgen.Sol_BuildStruct({
    type = "frame",
    elements = {},
    visible = true,
    enable_bg = false,
    bg_canvas = sgen.SNIL,
    bg_position = smath.Sol_NewVector(0, 0),
  }, frame)
end ; module.Sol_NewFrame=Sol_NewFrame
function Sol_InsertElementInFrame(frame, element)
  table.insert(frame.elements, element)
end ; module.Sol_InsertElementInFrame=Sol_InsertElementInFrame
function Sol_TickFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Sol_UIElementTypesWrap[element.type]["tick"] then
        Sol_UIElementTypesWrap[element.type]["tick"](display, element)
      end
    end
  end
end ; module.Sol_TickFrame=Sol_TickFrame
function Sol_DrawFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Sol_UIElementTypesWrap[element.type]["draw"] then
        Sol_UIElementTypesWrap[element.type]["draw"](display, element)
      end
    end
  end
end ; module.Sol_DrawFrame=Sol_DrawFrame
Sol_UIElementTypesWrap["frame"]={tick=Sol_TickFrame, draw=Sol_DrawFrame}

--[[ Begin the "Cursor" functions ]]
local SOL_CURSOR_STATES = table.enum(1, {"NORMAL", "LOADING", "FAILED"}) ; module.SOL_CURSOR_STATES=SOL_CURSOR_STATES
function Sol_NewCursor(cursor)
  return sgen.Sol_BuildStruct({
    draw_method = defaults.SOL_DRAW_USING.COLOR,
    textures = {},
    current_mode = SOL_CURSOR_STATES.NORMAL,
    texture_timing = 0,
    texture_index = 0,
    color = defaults.SOL_UI_CURSOR_DEFAULT_COLOR,
    rectangle = smath.Sol_NewRectangle(nil, defaults.SOL_UI_CURSOR_DEFAULT_SIZE),
    lastpos = smath.Sol_NewVector(0, 0),
    position_offset = smath.Sol_NewVector(0, 0)
  }, cursor or {})
end ; module.Sol_NewCursor=Sol_NewCursor
function Sol_TickCursor(cursor)
  cursor.rectangle.position=smath.Sol_NewVector(love.mouse.getPosition())
  cursor.rectangle.position.x=(cursor.rectangle.position.x-math.floor(cursor.rectangle.size.x/2))-cursor.position_offset.x
  cursor.rectangle.position.y=(cursor.rectangle.position.y-math.floor(cursor.rectangle.size.y/2))-cursor.position_offset.y
end ; module.Sol_TickCursor=Sol_TickCursor
function Sol_DrawCursor(cursor)
  if cursor.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(cursor.color))
    love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(cursor.rectangle))
  else
    mwarn("drawing method not yet implemented for Sol_Cursor!")
    cursor.draw_method = defaults.SOL_DRAW_USING.COLOR
  end
end ; module.Sol_DrawCursor=Sol_DrawCursor

--[[ Begin the "Display" object functions ]]
function Sol_NewDisplay(display)
  return sgen.Sol_BuildStruct({
    elements = {},
    cursor = Sol_NewCursor(),
    name = "display",
    type = "display",
    size = smath.Sol_NewVector(0, 0)
  }, display or {})
end ; module.Sol_NewDisplay=Sol_NewDisplay
function Sol_SetMousePositionOffsetDisplay(display, offsetx, offsety)
  display.cursor.position_offset=smath.Sol_NewVector(offsetx, offsety)
end ; module.Sol_SetMousePositionOffsetDisplay=Sol_SetMousePositionOffsetDisplay
function Sol_InsertElement(display, element)
  table.insert(display.elements, element)
end ; module.Sol_InsertElement=Sol_InsertElement
function Sol_TickDisplay(display)
  Sol_TickCursor(display.cursor)
  for _, element in ipairs(display.elements) do
    if Sol_UIElementTypesWrap[element.type]["tick"] then
      Sol_UIElementTypesWrap[element.type]["tick"](display, element)
    end
  end
end ; module.Sol_TickDisplay=Sol_TickDisplay
function Sol_DrawDisplay(display)
  for _, element in ipairs(display.elements) do
    if Sol_UIElementTypesWrap[element.type]["draw"] then
      Sol_UIElementTypesWrap[element.type]["draw"](display, element)
    end
  end
  Sol_DrawCursor(display.cursor)
end ; module.Sol_DrawDisplay=Sol_DrawDisplay
--
return module