-- graphics.lua: functions related to graphics.
local module={}

-- Sol_GeneratePixelatedPatternUsingAlpha(canva)
function module.Sol_GeneratePixelatedPatternUsingAlpha(canva, properties)
  local properties = properties or {}
  local PXWIDTH = 16 or properties["pixel_width"]
  local PXHEIGHT= 16 or properties["pixel_height"]
  local CW, CH  = canva:getDimensions()
  -- 
  local pastc = love.graphics.getCanvas()
  love.graphics.setCanvas(canva)
  --
  love.graphics.clear(0.2, 0.2, 0.2, 0.4)
  --
  local NBLOCKS_Y = math.floor(CH / PXHEIGHT)
  local NBLOCKS_X = math.floor(CW / PXWIDTH)
  for yindex = 0, NBLOCKS_Y do
    for xindex = 0, NBLOCKS_X do
      local amount_filled = (NBLOCKS_Y / 100) * ( (NBLOCKS_Y / (yindex/ 2) ) * 100 )
      love.graphics.setColor(200/255, 200/255, 200/255, math.random(0, 255 - amount_filled) / 255)
      love.graphics.rectangle("fill", xindex * PXWIDTH, yindex *PXHEIGHT, PXWIDTH, PXHEIGHT)
    end
  end
  --
  love.graphics.setCanvas(pastc)
end

-- Sol_DrawCanvas: draw some canva on the screen.
function module.Sol_DrawCanvas(canva, position)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canva, position.x, position.y)
end

--
return module