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

--[[ Rectangle Functions ]]--
function Sol_UnpackVectorXY(vector)
  return vector.x, vector.y
end ; module.Sol_UnpackVectorXY=Sol_UnpackVectorXY
function Sol_UnpackRectXYWH(rectangle)
  return rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y
end ; module.Sol_UnpackRectXYWH=Sol_UnpackRectXYWH
function Sol_TestRectangleCollision(main_rectangle, testing_rectangle)
  mwarn("not implemented.") return false
end ; module.Sol_TestRectangleCollision=Sol_TestRectangleCollision

--[[ Color Functions ]]
function Sol_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end ; module.Sol_TranslateColor=Sol_TranslateColor

--
return module