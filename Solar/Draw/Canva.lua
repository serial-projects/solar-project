-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SM_Vector = require("Solar.Math.Vector")
local SM_Color  = require("Solar.Math.Color")

local module = {}

-- Sol_SaveLastCanvaAndPerformFunction(canva: love.canva, todo: function)
function module.Sol_SaveLastCanvaAndPerformFunction(canva, todo)
    local pastc=love.graphics.getCanvas()
    love.graphics.setCanvas(canva)
        local to_return = todo()
    love.graphics.setCanvas(pastc)
    return to_return
end

-- Sol_QuickGenerateCanva(size: Sol_Vector, color: Sol_Color)
function module.Sol_QuickGenerateCanva(size, color)
    local new_canva=love.graphics.newCanvas(size:unpackxy())
    module.Sol_SaveLastCanvaAndPerformFunction(new_canva, function()
        love.graphics.clear(color:translate())
    end)
    return new_canva
end

-- Sol_DrawCanvas: draw some canva on the screen.
function module.Sol_DrawCanvas(canva, position)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canva, position.x, position.y)
end

return module