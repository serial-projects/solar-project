local sgen = require("sol.sgen")
local smath = require("sol.smath")
local defaults = require("sol.defaults")
local module={}
--

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
  }, display or {})
end ; module.Sol_NewDisplay=Sol_NewDisplay
function Sol_SetMousePositionOffsetDisplay(display, offsetx, offsety)
  display.cursor.position_offset=smath.Sol_NewVector(offsetx, offsety)
end ; module.Sol_SetMousePositionOffsetDisplay=Sol_SetMousePositionOffsetDisplay
function Sol_TickDisplay(display)
  Sol_TickCursor(display.cursor)
end ; module.Sol_TickDisplay=Sol_TickDisplay
function Sol_DrawDisplay(display)
  Sol_DrawCursor(display.cursor)
end ; module.Sol_DrawDisplay=Sol_DrawDisplay
--
return module