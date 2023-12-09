-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SM_Rectangle  = require("Solar.Math.Rectangle")
local SM_Vector     = require("Solar.Math.Vector")
local SM_Tiles      = require("Solar.Math.Tile")
local SD_Recipe     = require("Solar.Draw.Recipe")

local module={}

--
function module.Sol_NewTile(tile) tile = tile or {}
    return {
        type                        = "tile",
        name                        = tile["name"] or "player",
        rectangle                   = SM_Rectangle.Sol_NewRectangle(SM_Vector.Sol_NewVector(tile["position"]), SM_Vector.Sol_NewVector(tile["size"])),
        zindex                      = (tile["zindex"] == 1 and 2 or tile["zindex"]) or 0,
        collide                     = tile["collide"] or false,
        should_draw                 = tile["should_draw"] or true,
        current_chunk               = {},
        --[[ draw ]]--
        draw                        = SD_Recipe.Sol_NewDrawRecipe(tile["draw"]),
        --[[ actions ]]--
        busy                        = false,
        when_touched                = tile["when_touched"] or 0,
        enable_interaction          = tile["enable_interaction"] or false,
        when_interacted             = tile["when_interacted"] or 0,
    }
end

--[[ Tick Related Functions ]]
function module.Sol_TickTile(engine, world_mode, world, tile)

end

--[[ Draw Related Functions ]]
function module.Sol_DrawTile(engine, world_mode, world, tile)
    local rxpos, rypos = SM_Tiles.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
    local width, height= SM_Vector.Sol_UnpackVectorXY(tile.rectangle.size)
    SD_Recipe.Sol_DrawRecipe(engine, tile.draw, rxpos, rypos, width, height)
end

--
return module