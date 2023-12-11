-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.
local SV_Consts     = require("Solar.Values.Consts")

local SM_Vector     = require("Solar.Math.Vector")
local SM_Color      = require("Solar.Math.Color")

local SSE_Script    = require("Solar.Services.Script")
local SSE_Routines  = require("Solar.Services.Routines")

local SWM_Load      = require("Solar.Modes.World.Load")
local SWM_Player    = require("Solar.Modes.World.Player")
local SWM_Tiles     = require("Solar.Modes.World.Tiles")
local SWM_Chunk     = require("Solar.Modes.World.Chunk")
local SWM_Interact  = require("Solar.Modes.World.Interact")

local module={}
--
function module.Sol_NewWorld(world)
    return {
        info={name="n/n", description="?"},
        --
        chunks      ={},
        routines    =SSE_Routines.Sol_NewRoutineService(),
        scripts     =SSE_Script.Sol_NewScriptService(),
        --
        recipe_tiles        ={},
        recipe_geometry     ={},
        recipe_layers       ={},
        recipe_level        ={},
        recipe_player       ={},
        recipe_actions      ={},
        recipe_messages     ={},
        recipe_skybox       ={},
        --
        grid_tile_size          = SM_Vector.Sol_NewVector(0, 0),
        grid_size               = SM_Vector.Sol_NewVector(0, 0),
        size                    = SM_Vector.Sol_NewVector(0, 0),
        enable_world_borders    = true,
        tiles                   = {{zindex=1, type="player"}},
        current_skybox          = nil,
    }
end

--[[ Init Related Functions ]]
function module.Sol_InitWorld(engine, world_mode, world, name)
    --> load the world primitives: geometry, level and player
    SWM_Load.Sol_LoadWorld(engine, world_mode, world, name)
end

--[[ Tick Related Functions ]]
function module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
    world_mode.player.current_speed = love.keyboard.isDown("lshift") and world_mode.player.run_speed or world_mode.player.walk_speed
    if      love.keyboard.isDown(engine.wmode_keymap["walk_up"])    then
        SWM_Player.Sol_WalkInWorld(engine, world_mode, world, SV_Consts.player_directions.UP,   0, -world_mode.player.current_speed)
    elseif  love.keyboard.isDown(engine.wmode_keymap["walk_down"])  then
        SWM_Player.Sol_WalkInWorld(engine, world_mode, world, SV_Consts.player_directions.DOWN, 0,  world_mode.player.current_speed)
    elseif  love.keyboard.isDown(engine.wmode_keymap["walk_left"])  then
        SWM_Player.Sol_WalkInWorld(engine, world_mode, world, SV_Consts.player_directions.LEFT, -world_mode.player.current_speed, 0)
    elseif  love.keyboard.isDown(engine.wmode_keymap["walk_right"]) then
        SWM_Player.Sol_WalkInWorld(engine, world_mode, world, SV_Consts.player_directions.RIGHT, world_mode.player.current_speed, 0)
    end
end

function module.Sol_TickWorld(engine, world_mode, world)
    SSE_Routines.Sol_TickRoutineService(world.routines, engine, world_mode, world)
    module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
    SSE_Script.Sol_TickScriptService(world.scripts)
end

--[[ Keypress Event Related Functions ]]--

-- Sol_KeypressEventWorld(engine, world_mode, world, key: string)
function module.Sol_KeypressEventWorld(engine, world_mode, world, key)
    if key == engine.wmode_keymap["interact"] then
        SWM_Interact.Sol_AttemptInteractionInWorld(engine, world_mode, world)
    end
end

--[[ Draw Related Functions ]]
local function Sol_DrawWorldSkyboxSimpleColor(_, recipe)
    local __color_object=SM_Color.Sol_NewColor4(recipe.color)
    love.graphics.clear(__color_object:translate())
end

local function Sol_DrawWorldSkyboxTexture(engine, recipe)
    -- TODO: make the skybox.
end

local function Sol_DrawWorldSkyboxRecipe(engine, recipe)
    local method_invokation_table={color=Sol_DrawWorldSkyboxSimpleColor, texture=Sol_DrawWorldSkyboxTexture}
    local invoke_method = method_invokation_table[recipe.method]
    if invoke_method then invoke_method(engine, recipe)
    else --[[ qcrash("unknown method for skybox drawing: \"%s\"", recipe.method) ]] end
end

local function Sol_DrawWorldSkybox(engine, world)
    if world.current_skybox then
        local current_skybox_recipe = world.recipe_skybox[world.current_skybox]
        Sol_DrawWorldSkyboxRecipe(engine, current_skybox_recipe)
    end
end

function module.Sol_DrawWorld(engine, world_mode, world)
    Sol_DrawWorldSkybox(engine, world)
    SSE_Routines.Sol_DrawRoutineService(world.routines, engine, world_mode, world)
    local draw_tile_queue = SWM_Chunk.Sol_GetChunksOrdered(engine, world_mode, world, true)
    for _, tile in ipairs(draw_tile_queue) do
        if tile["type"] and tile["type"] == "player" then
            SWM_Player.Sol_DrawPlayer(engine, world_mode, world_mode.player)
        else
            SWM_Tiles.Sol_DrawTile(engine, world_mode, world, world.tiles[tile.target])
        end
    end
end

--
return module