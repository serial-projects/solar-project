-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
local SM_Vector = require("Solar.Math.Vector")

function module.Sol_NewRectangle(position, size)
    local proto_rectangle = {
        position    = position or SM_Vector.Sol_NewVector(0, 0),
        size        = size or SM_Vector.Sol_NewVector(0, 0)
    }
    function proto_rectangle:clone()
        return module.Sol_NewRectangle(
            SM_Vector.Sol_NewVector(self.position.x, self.position.y),
            SM_Vector.Sol_NewVector(self.size.x, self.size.y)
        )
    end
    function proto_rectangle:unpackxywh()
        return self.position.x, self.position.y, self.size.x, self.size.y
    end
    function proto_rectangle:collide(target_rectangle)
        if target_rectangle.size.x < self.size.x and target_rectangle.size.y < self.size.y then
            local ta, tb = self.position.x + 1, self.position.x + (self.size.x - 1)
            local tc, td = self.position.y + 1, self.position.y + (self.size.y - 1)
            local xa, xb = target_rectangle.position.x, target_rectangle.position.x + target_rectangle.size.x
            local ya, yb = target_rectangle.position.y, target_rectangle.position.y + target_rectangle.size.y
            local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
            local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
            if cx and cy then return true end
        else
            local ta, tb = target_rectangle.position.x, target_rectangle.position.x + target_rectangle.size.x
            local tc, td = target_rectangle.position.y, target_rectangle.position.y + target_rectangle.size.y
            local xa, xb = self.position.x + 1, self.position.x + (self.size.x - 1)
            local ya, yb = self.position.y + 1, self.position.y + (self.size.y - 1)
            local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
            local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
            if cx and cy then return true end
        end
    end
    return proto_rectangle
end

--
-- function module.Sol_NewRectangle(position, size)
--     return {
--         position  = position  or SM_Vector.Sol_NewVector(0, 0),
--         size      = size      or SM_Vector.Sol_NewVector(0, 0)
--     }
-- end

--

return module