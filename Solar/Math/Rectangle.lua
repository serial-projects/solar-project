-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
local SM_Vector = require("Solar.Math.Vector")

--
function module.Sol_NewRectangle(position, size)
  return {
    position  = position  or SM_Vector.Sol_NewVector(0, 0),
    size      = size      or SM_Vector.Sol_NewVector(0, 0)
  }
end

function module.Sol_CloneRectangle(rectangle)
  return { position = SM_Vector.Sol_NewVector(rectangle.position), size = SM_Vector.Sol_NewVector(rectangle.size) }
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
--
return module