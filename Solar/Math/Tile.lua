-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
--
function module.Sol_GetTileRelativePosition(rel_position, abs_position, tile_position)
    return (-abs_position.x + rel_position.x) + tile_position.x, (-abs_position.y + rel_position.y) + tile_position.y
end
--
return module