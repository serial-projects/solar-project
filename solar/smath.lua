local module={}

--
-- Vector Utils
--
function Solar_NewVectorXY(x, y)
  return {
    x = (x or 0), y = (y or 0)
  }
end
module.Solar_NewVectorXY = Solar_NewVectorXY

--
-- Rectangle
--
function Solar_NewRectangle(position, size)
  return { position = position or Solar_NewVectorXY(0, 0), size = size or Solar_NewVectorXY(0, 0) }
end ; module.Solar_NewRectangle=Solar_NewRectangle
function Solar_UnpackRectangleXYWH(rectangle)
  return rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y
end ; module.Solar_UnpackRectangleXYWH=Solar_UnpackRectangleXYWH
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

--
-- Colar Utils
--
function Solar_NewColor(r, g, b, a)
  return { red = r or 0, green = g or 0, blue = b or 0, alpha = a or 255 }
end
module.Solar_NewColor = Solar_NewColor
function Solar_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end
module.Solar_TranslateColor = Solar_TranslateColor

--
-- Math Utils
--
function Solar_GetRelativePosition(pr, pa, tp)
  -- pr: position relative
  -- pa: position absolute
  -- tp: tile position
  return (-pa.x + pr.x) + tp.x, (-pa.y + pr.y) + tp.y
end
module.Solar_GetRelativePosition = Solar_GetRelativePosition

--
return module