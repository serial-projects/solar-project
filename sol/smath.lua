-- smath.lua: sol's library for math stuff (more shape stuff but...)
local module = {}

function module.Sol_NewVector(x, y)
  if type(x)=="table" then
    y = x[2] or x["y"] or 0
    x = x[1] or x["x"] or 0
  end
  return { x = x , y = y }
end

function module.Sol_NewRectangle(position, size)
  return {
    position  = position  or module.Sol_NewVector(0, 0),
    size      = size      or module.Sol_NewVector(0, 0)
  }
end

function module.Sol_NewColor4(red, green, blue, alpha)
  if type(red)=="table" then
    alpha=  red[4] or red["alpha"]  or 255
    blue=   red[3] or red["blue"]   or 0
    green=  red[2] or red["green"]  or 0
    red=    red[1] or red["red"]    or 0
  end
  return { red = red or 0,   green = green or 0,   blue = blue or 0,   alpha = alpha or 255 }
end

--[[ Vector Functions ]]--
function module.Sol_AddVector(avec, bvec)           return module.Sol_NewVector(bvec.x + avec.x, bvec.y + avec.y) end
function module.Sol_SubVector(avec, bvec)           return module.Sol_NewVector(bvec.x - avec.x, bvec.y - avec.y) end
function module.Sol_MultiplicateVector(avec, bvec)  return module.Sol_NewVector(bvec.x * avec.x, bvec.y * avec.y) end

--[[ Rectangle Functions ]]--
function module.Sol_CloneRectangle(rectangle)
  return { position = module.Sol_NewVector(rectangle.position), size = module.Sol_NewVector(rectangle.size) }
end

function module.Sol_GetTileRelativePosition(rel_position, abs_position, tile_position)
  return (-abs_position.x + rel_position.x) + tile_position.x, (-abs_position.y + rel_position.y) + tile_position.y
end

function module.Sol_UnpackVectorXY(vector)
  return vector.x, vector.y
end

function module.Sol_UnpackRectXYWH(rectangle)
  return rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y
end

function module.Sol_TestRectangleCollision(base_rectangle, target_rectangle)
  if target_rectangle.size.x < base_rectangle.size.x and target_rectangle.size.y < base_rectangle.size.y then
    local ta, tb = base_rectangle.position.x + 1, base_rectangle.position.x + (base_rectangle.size.x - 1)
    local tc, td = base_rectangle.position.y + 1, base_rectangle.position.y + (base_rectangle.size.y - 1)
    local xa, xb = target_rectangle.position.x, target_rectangle.position.x + target_rectangle.size.x
    local ya, yb = target_rectangle.position.y, target_rectangle.position.y + target_rectangle.size.y
    local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
    local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
    if cx and cy then return true end
  else
    local ta, tb = target_rectangle.position.x, target_rectangle.position.x + target_rectangle.size.x
    local tc, td = target_rectangle.position.y, target_rectangle.position.y + target_rectangle.size.y
    local xa, xb = base_rectangle.position.x + 1, base_rectangle.position.x + (base_rectangle.size.x - 1)
    local ya, yb = base_rectangle.position.y + 1, base_rectangle.position.y + (base_rectangle.size.y - 1)
    local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
    local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
    if cx and cy then return true end
  end
  return false
end

--[[ Color Functions ]]
function module.Sol_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end

--
return module