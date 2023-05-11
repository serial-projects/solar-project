-- smath.lua: sol's library for math stuff (more shape stuff but...)
local module = {}
function Sol_NewVector(x, y)
  return {
    x = x or 0,
    y = y or 0
  }
end ; module.Sol_NewVector=Sol_NewVector
function Sol_NewRectangle(position, size)
  return {
    position = position or Sol_NewVector(0, 0),
    size = size or Sol_NewVector(0, 0)
  }
end ; module.Sol_NewRectangle=Sol_NewRectangle
function Sol_NewColor4(red, green, blue, alpha)
  return {
    red = red or 0,
    green = green or 0,
    blue = blue or 0,
    alpha = alpha or 255
  }
end ; module.Sol_NewColor4=Sol_NewColor4

--[[ Rectangle Functions ]]--
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