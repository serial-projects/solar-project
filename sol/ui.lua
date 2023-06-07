local sgen = require("sol.sgen")
local smath = require("sol.smath")
local defaults = require("sol.defaults")
local module={}

--[[ Math stuff ]]
local function Sol_UITranslateRelativePosition(ww, wh, ew, eh, posx, posy)
  -- calculate the window divided by 100 (for every axis.)
  local xpos, ypos      = (ww / 100), (wh / 100)
  local xoff, yoff      = (ew / 100) * posx, (eh / 100) * posy
  local abposx, abposy  = (xpos * posx) - xoff, (ypos * posy) - yoff
  return math.floor(abposx), math.floor(abposy)
end

--[[ Generics ]]--
function module.Sol_GenericTickFunctionWithClickDetection(display, element)
  
end

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
  }, label)
end
local function Sol_TickLabel(display, label)

end
local function Sol_DrawLabel(display, label)
  if label.font then
    label.rectangle.size.x,label.rectangle.size.y = label.font:getWidth(label.text), label.font:getHeight()
    if    label.force_absolute then label.rectangle.position.x,label.rectangle.position.y = label.position.x, label.position.y
    else  label.rectangle.position.x, label.rectangle.position.y = Sol_UITranslateRelativePosition(display.size.x, display.size.y, label.rectangle.size.x, label.rectangle.size.y, label.position.x, label.position.y) end
    if label.has_background then
      love.graphics.setColor(smath.Sol_TranslateColor(label.background_color))
      love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(label.rectangle))
    end
    love.graphics.setFont(label.font)
    love.graphics.setColor(smath.Sol_TranslateColor(label.color))
    love.graphics.print(label.text, label.rectangle.position.x, label.rectangle.position.y)
  end
end

--[[ Begin the "Button" functions ]]
function module.Sol_NewButton(button)
  local button = button or {}
  return sgen.Sol_BuildStruct({
    text = "",
    font = 0,
  })
end
local function Sol_TickButton(display, button)

end
local function Sol_DrawButton(display, button)
end

--[[ Enumerate the types keypress and other stuff ]]
local Sol_UIElementTypesWrap={
  label={tick=Sol_TickLabel, draw=Sol_DrawLabel, keypress=nil}
}

--[[ Begin the "Frame" functions ]]
function module.Sol_NewFrame(frame)
  local frame = frame or {}
  return sgen.Sol_BuildStruct({
    type          = "frame",
    elements      = {},
    visible       = true,
    enable_bg     = false,
    bg_canvas     = sgen.SNIL,
    bg_position   = smath.Sol_NewVector(0, 0),
  }, frame)
end
function module.Sol_InsertElementInFrame(frame, element)
  table.insert(frame.elements, element)
end
local function Sol_TickFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Sol_UIElementTypesWrap[element.type]["tick"] then
        Sol_UIElementTypesWrap[element.type]["tick"](display, element)
      end
    end
  end
end
local function Sol_DrawFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Sol_UIElementTypesWrap[element.type]["draw"] then
        Sol_UIElementTypesWrap[element.type]["draw"](display, element)
      end
    end
  end
end
Sol_UIElementTypesWrap["frame"]={tick=Sol_TickFrame, draw=Sol_DrawFrame}

--[[ Begin the "Cursor" functions ]]
local SOL_CURSOR_STATES = table.enum(1, {"NORMAL", "LOADING", "FAILED"}) ; module.SOL_CURSOR_STATES=SOL_CURSOR_STATES
function module.Sol_NewCursor(cursor)
  return sgen.Sol_BuildStruct({
    draw_method     = defaults.SOL_DRAW_USING.COLOR,
    textures        = {},
    current_mode    = SOL_CURSOR_STATES.NORMAL,
    texture_timing  = 0,
    texture_index   = 0,
    color           = defaults.SOL_UI_CURSOR_DEFAULT_COLOR,
    rectangle       = smath.Sol_NewRectangle(nil, defaults.SOL_UI_CURSOR_DEFAULT_SIZE),
    lastpos         = smath.Sol_NewVector(0, 0),
    position_offset = smath.Sol_NewVector(0, 0)
  }, cursor or {})
end

local function Sol_TickCursor(cursor)
  cursor.rectangle.position=smath.Sol_NewVector(love.mouse.getPosition())
  cursor.rectangle.position.x=(cursor.rectangle.position.x-math.floor(cursor.rectangle.size.x/2))-cursor.position_offset.x
  cursor.rectangle.position.y=(cursor.rectangle.position.y-math.floor(cursor.rectangle.size.y/2))-cursor.position_offset.y
end

local function Sol_DrawCursor(cursor)
  if cursor.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(cursor.color))
    love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(cursor.rectangle))
  else
    mwarn("drawing method not yet implemented for Sol_Cursor!")
    cursor.draw_method = defaults.SOL_DRAW_USING.COLOR
  end
end

--[[ Begin the "Display" object functions ]]
function module.Sol_NewDisplay(display)
  return sgen.Sol_BuildStruct({
    elements  = {},
    cursor    = module.Sol_NewCursor(),
    name      = "display",
    type      = "display",
    size      = smath.Sol_NewVector(0, 0)
  }, display or {})
end

function module.Sol_SetMousePositionOffsetDisplay(display, offsetx, offsety)
  display.cursor.position_offset=smath.Sol_NewVector(offsetx, offsety)
end

function module.Sol_InsertElement(display, element)
  table.insert(display.elements, element)
end

function module.Sol_TickDisplay(display)
  Sol_TickCursor(display.cursor)
  for _, element in ipairs(display.elements) do
    if Sol_UIElementTypesWrap[element.type]["tick"] then
      Sol_UIElementTypesWrap[element.type]["tick"](display, element)
    end
  end
end

function module.Sol_DrawDisplay(display)
  for _, element in ipairs(display.elements) do
    if Sol_UIElementTypesWrap[element.type]["draw"] then
      Sol_UIElementTypesWrap[element.type]["draw"](display, element)
    end
  end
  Sol_DrawCursor(display.cursor)
end

--
return module