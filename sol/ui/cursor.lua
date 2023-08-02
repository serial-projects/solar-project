local defaults=require("sol.defaults")
local consts=require("sol.consts")
local smath=require("sol.smath")
local sgen=require("sol.sgen")
local module={}
local SOL_CURSOR_STATES = table.enum(1, {"NORMAL", "LOADING", "FAILED"}) ; module.SOL_CURSOR_STATES=SOL_CURSOR_STATES
function module.Sol_NewCursor(cursor)
  return sgen.Sol_BuildStruct({
    draw_method     = consts.draw_using.COLOR,
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

function module.Sol_TickCursor(cursor)
  cursor.rectangle.position=smath.Sol_NewVector(love.mouse.getPosition())
  cursor.rectangle.position.x=(cursor.rectangle.position.x-math.floor(cursor.rectangle.size.x/2))-cursor.position_offset.x
  cursor.rectangle.position.y=(cursor.rectangle.position.y-math.floor(cursor.rectangle.size.y/2))-cursor.position_offset.y
end

function module.Sol_DrawCursor(cursor)
  if cursor.draw_method == consts.draw_using.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(cursor.color))
    love.graphics.rectangle("fill", smath.Sol_UnpackRectXYWH(cursor.rectangle))
  else
    mwarn("drawing method not yet implemented for Sol_Cursor!")
    cursor.draw_method = consts.draw_using.COLOR
  end
end

--
return module