-- smath.lua: sol's library for math stuff (more shape stuff but...)
local module = {}
function Sol_NewVector(x, y)
  if type(x)=="table" then
    y = x[2] or x["y"] or 0
    x = x[1] or x["x"] or 0
  end
  return { x = x , y = y }
end ; module.Sol_NewVector=Sol_NewVector
function Sol_NewRectangle(position, size)
  return {
    position = position or Sol_NewVector(0, 0),
    size = size or Sol_NewVector(0, 0)
  }
end ; module.Sol_NewRectangle=Sol_NewRectangle
function Sol_NewColor4(red, green, blue, alpha)
  if type(red)=="table" then
    alpha=  red[4] or red["alpha"] or 255
    blue=   red[3] or red["blue"] or 0
    green=  red[2] or red["green"] or 0
    red=    red[1] or red["red"] or 0
  end
  return {
    red = red or 0,
    green = green or 0,
    blue = blue or 0,
    alpha = alpha or 255
  }
end ; module.Sol_NewColor4=Sol_NewColor4

--[[ Vector Functions ]]--
function Sol_AddVector(avec, bvec)
  return Sol_NewVector(bvec.x + avec.x, bvec.y + avec.y)
end ; module.Sol_AddVector=Sol_AddVector
function Sol_SubVector(avec, bvec)
  return Sol_NewVector(bvec.x - avec.x, bvec.y - avec.y)
end ; module.Sol_SubVector=Sol_SubVector
function Sol_MultiplicateVector(avec, bvec)
  return Sol_NewVector(bvec.x * avec.x, bvec.y * avec.y)
end ; module.Sol_MultiplicateVector=Sol_MultiplicateVector

--[[ Rectangle Functions ]]--
function Sol_CloneRectangle(rectangle)
  local _np=Sol_NewVector(rectangle.position)
  local _ns=Sol_NewVector(rectangle.size)
  return { position = _np, size = _ns }
end ; module.Sol_CloneRectangle=Sol_CloneRectangle
function Sol_GetTileRelativePosition(rel_position, abs_position, tile_position)
  return (-abs_position.x + rel_position.x) + tile_position.x, (-abs_position.y + rel_position.y) + tile_position.y
end ; module.Sol_GetTileRelativePosition=Sol_GetTileRelativePosition
function Sol_UnpackVectorXY(vector)
  return vector.x, vector.y
end ; module.Sol_UnpackVectorXY=Sol_UnpackVectorXY
function Sol_UnpackRectXYWH(rectangle)
  return rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y
end ; module.Sol_UnpackRectXYWH=Sol_UnpackRectXYWH
function Sol_TestRectangleCollision(base_rectangle, target_rectangle)
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
end ; module.Sol_TestRectangleCollision=Sol_TestRectangleCollision

--[[ Color Functions ]]
function Sol_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end ; module.Sol_TranslateColor=Sol_TranslateColor

--
return module