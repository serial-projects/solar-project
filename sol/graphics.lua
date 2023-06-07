-- graphics.lua: functions related to graphics.
local module={}

-- Sol_DrawCanvas: draw some canva on the screen.
function module.Sol_DrawCanvas(canva, position)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canva, position.x, position.y)
end

--
return module