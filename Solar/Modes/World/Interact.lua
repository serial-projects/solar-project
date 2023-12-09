local module = {}

local SWM_Chunk   = require("Solar.Modes.World.Chunk")
local SSE_Script  = require("Solar.Services.Script")
local SV_Defaults = require("Solar.Values.Defaults")
local SV_Consts   = require("Solar.Values.Consts")
local SM_Vector   = require("Solar.Math.Vector")
local SM_Rectangle= require("Solar.Math.Rectangle")

function module.Sol_DoInteractionInWorld(engine, world_mode, world, tile, interaction_recipe)
    interaction_recipe["when_finish"] = function(ir)
        tile.busy = false
    end
    tile.busy = true
    SSE_Script.Sol_LoadScriptInWorld(engine, world_mode, world, world.scripts, interaction_recipe)
end

function module.Sol_AttemptInteractionInWorld(engine, world_mode, world)
    -- TODO: on the future, make a RAY that hit some tile to check possible interactions.
    -- USING this method with env. PRECISE_WALK disabled MAY result in problems and less
    -- precise interactions. Load all the tiles from the current chunk & load looking table:
    local current_chunk_tiles=SWM_Chunk.Sol_GetChunksOrdered(engine, world_mode, world, false)
    local SOL_PLAYER_INTERACTION_RANGE=SV_Defaults.SOL_PLAYER_INTERACTION_RANGE
    local test_position={
        [SV_Consts.player_directions.UP]     =SM_Vector.Sol_NewVector(world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y-SOL_PLAYER_INTERACTION_RANGE),
        [SV_Consts.player_directions.DOWN]   =SM_Vector.Sol_NewVector(world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y+SOL_PLAYER_INTERACTION_RANGE),
        [SV_Consts.player_directions.LEFT]   =SM_Vector.Sol_NewVector(world_mode.player.rectangle.position.x-SOL_PLAYER_INTERACTION_RANGE, world_mode.player.rectangle.position.y),
        [SV_Consts.player_directions.RIGHT]  =SM_Vector.Sol_NewVector(world_mode.player.rectangle.position.x+SOL_PLAYER_INTERACTION_RANGE, world_mode.player.rectangle.position.y),
    }
    
    -- build the rectangle:
    local testing_rectangle=SM_Rectangle.Sol_NewRectangle(test_position[world_mode.player.looking_direction], world_mode.player.rectangle.size)
    
    -- begin reading the tiles in-search of possible interactions. ALSO, ignore '1' the player.
    for _, tile in ipairs(current_chunk_tiles) do
        local current_tile=world.tiles[tile.target]
        if current_tile.enable_interaction and not current_tile.busy then
            local has_collision=SM_Rectangle.Sol_TestRectangleCollision(testing_rectangle, current_tile.rectangle)
            if has_collision then
                module.Sol_DoInteractionInWorld(engine, world_mode, world, current_tile, current_tile.when_interacted)
                break
            end
        end
    end
end

return module