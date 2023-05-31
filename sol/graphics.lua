-- graphics.lua: functions related to graphics.
local module={}
function Sol_DrawCanvas(canva, position)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canva, position.x, position.y)
end ; module.Sol_DrawCanvas=Sol_DrawCanvas
--
return module