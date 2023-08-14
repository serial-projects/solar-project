-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

-- Sol_GeneratePixelatedRandomizedPatternUsingAlpha(canva)
function module.Sol_GeneratePixelatedRandomizedPatternUsingAlpha(canva)
  
end

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
  love.graphics.clear(10/255, 10/255, 10/255, 0.7)
  --
  local NBLOCKS_Y = math.floor(CH / PXHEIGHT)
  local NBLOCKS_X = math.floor(CW / PXWIDTH)
  for yindex = 0, NBLOCKS_Y do
    for xindex = 0, NBLOCKS_X do
      local amount_filled = (NBLOCKS_Y / 100) * ( (NBLOCKS_Y / (yindex/ 2) ) * 100 )
      amount_filled = math.floor(amount_filled / 0.5)
      love.graphics.setColor(200/255, 200/255, 200/255, math.random(0, 255 - amount_filled) / 255)
      love.graphics.rectangle("fill", xindex * PXWIDTH, yindex *PXHEIGHT, PXWIDTH, PXHEIGHT)
    end
  end
  --
  love.graphics.setCanvas(pastc)
end

return module