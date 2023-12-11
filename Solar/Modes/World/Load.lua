-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local unpack = unpack or table.unpack

local SM_Vector     = require("Solar.Math.Vector")
local SS_Path       = require("Solar.System.Path")
local SV_Consts     = require("Solar.Values.Consts")
local SD_Recipe     = require("Solar.Draw.Recipe")
local SSE_Script    = require("Solar.Services.Script")
local SSE_Routines  = require("Solar.Services.Routines")
local SWM_Player    = require("Solar.Modes.World.Player")
local SWM_Tiles     = require("Solar.Modes.World.Tiles")
local SWM_Chunk     = require("Solar.Modes.World.Chunk")

local LucieDecode   = require("Library.Lucie.Decode")

local module={}

-- Sol_GenerateLayer(world: world, layer: layer): generate a layer by its name.
function module.Sol_GenerateLayer(world, layer)
    if world.recipe_layers[layer] then
        local current_layer = world.recipe_layers[layer]
        local layer_width = current_layer["width"]
        local layer_height= current_layer["height"]
        local layer_matrix= current_layer["matrix"]
        --> begin indexing
        for yindex = 1, layer_height do
            local line=layer_matrix[yindex]
            for xindex = 1, layer_width do
                local matrix_block=line:sub(xindex,xindex)
                if not SV_Consts.ignore_chars_tiles[matrix_block] then
                    if world.recipe_tiles[matrix_block] == nil then
                        mwarn("unable to find \"%s\" block for layer \"%s\"", matrix_block, layer)
                    else
                        local proto_tile=SWM_Tiles.Sol_NewTile(world.recipe_tiles[matrix_block])
                        proto_tile.rectangle.position.x=(xindex-1)*world.grid_tile_size.x
                        proto_tile.rectangle.position.y=(yindex-1)*world.grid_tile_size.y
                        table.insert(world.tiles, proto_tile)
                    end
                end
            end
        end
        --> end.
    end
end

-- Sol_WorldSpawnTile: creates a new tile.
function module.Sol_WorldSpawnTile(engine, world_mode, world, tile_name)
    if world.recipe_tiles[tile_name] then
        local proto_tile=SWM_Tiles.Sol_NewTile(world.recipe_tiles[tile_name])
        table.insert(world.tiles, proto_tile)
        return true
    else
        return false
    end
end

--> LoadWorld<Section>: this functions are going to load a specific world section.
local function Sol_LoadWorldGeometry(world)
    world.info                  = world.recipe_info
    world.grid_size             = SM_Vector.Sol_NewVector(world.recipe_geometry.world_size)
    world.grid_tile_size        = SM_Vector.Sol_NewVector(world.recipe_geometry.world_grid_tile_size)
    world.size                  = SM_Vector.Sol_NewVector((world.grid_size.x-1)*world.grid_tile_size.x,(world.grid_size.y-1)*world.grid_tile_size.y)
    world.enable_world_borders=(world.recipe_geometry["enable_world_borders"] == true)
end

local function Sol_LoadWorldLevel(engine, world_mode, world)
    if world.recipe_level then
        local spawn_tiles=world.recipe_level["spawn_tiles"]
        if spawn_tiles and type(spawn_tiles) == "table" then
            for _, tile in ipairs(spawn_tiles) do
                local sucess=module.Sol_WorldSpawnTile(engine, world_mode, world, tile)
                if not sucess then mwarn("couldn't generate tile: %s!", tile) end
            end
        end
        local spawn_layers=world.recipe_level["spawn_layers"]
        if spawn_layers and type(spawn_layers) == "table" then
            for _, layer in ipairs(spawn_layers) do
                module.Sol_GenerateLayer(world, layer)
            end
        end
    end
end

local function Sol_LoadWorldPlayer(engine, world_mode, world)
    local function wload_AdjustPlayerOneshot_FirstRun(routine, _, world_mode, world)
        dmsg("%s is adjust the player for the first time run on the world: \"%s\"!", routine.name, world.name)
        if world.recipe_player then
        local spawn_position = world.recipe_player["spawn"]
        if spawn_position then
                local xpos, ypos = spawn_position["xpos"] or 0, spawn_position["ypos"] or 0
                if spawn_position["use_tile_alignment"] then
                    xpos = xpos * world.grid_tile_size.x
                    ypos = ypos * world.grid_tile_size.y
                end
                world_mode.player.rectangle.position.x,world_mode.player.rectangle.position.y=xpos, ypos
            end
            --
            world_mode.player.draw = SD_Recipe.Sol_NewDrawRecipe(world.recipe_player["draw"])
            world_mode.player.rectangle.size = world.recipe_player["size"] and SM_Vector.Sol_NewVector(world.recipe_player["size"]) or world_mode.player.size
            SWM_Player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)
        end
        return SSE_Routines.ROUTINE_STATUS_FINISHED
    end
    SSE_Routines.Sol_PushRoutine(world.routines, SSE_Routines.Sol_NewRoutine(
        "wload.AdjustPlayerOneshot", SSE_Routines.EXEC_ON_TICK,
        {[SSE_Routines.ROUTINE_STATUS_FIRSTRUN]=wload_AdjustPlayerOneshot_FirstRun},
        {}
    ))
end

local function Sol_LoadWorldScript(engine, world_mode, world)
    if world.recipe_scripts then
        for script_name, script_recipe in pairs(world.recipe_scripts) do
            if script_name ~= "__type" then
                dmsg("loading script: %s ...", script_name)
                SSE_Script.Sol_LoadScriptInWorld(engine, world_mode, world, world.scripts, script_recipe)
            end
        end
    end
end

local function Sol_LoadWorldSkybox(world)
  -- NOTE: provide a fallback skybox.
    if world.recipe_skybox then
        if not world.recipe_skybox["main"] then
            mwarn("for world: \"%s\" there was no main skybox fallback, creating one!", world.info.name)
            world.recipe_skybox["main"] = {method="color", color={0, 0, 0}}
        end
        world.current_skybox = world.recipe_skybox["default"] or "main"
    end
end

-- Sol_LoadWorld(engine, world_mode, world, world_name: string): automatically loads the world
-- recipe file and build the world from the recipe provided.
function module.Sol_LoadWorld(engine, world_mode, world, world_name)
    dmsg("Sol_LoadWorld() is loading \"%s\" world.", world_name)
    local function attempt_load_world_file(world_component, inside_specific_section)
        inside_specific_section = inside_specific_section or world_component
        local component_target_file = SS_Path.Sol_MergePath({engine.root,string.format("levels/%s/%s.sl", world_name, world_component)})
        dmsg("opening world component = %s", component_target_file)
        local success, result = pcall(function()
            local _, content = LucieDecode.decode_file(component_target_file)
            return content
        end)
        if not success then
            error(string.format("attempt_load_world_file() failed to load world component: \"%s\", due: %s", world_component, result))
            return nil
        else
            dmsg("component \"%s\" file is was loaded: \"%s\"", inside_specific_section, component_target_file)
            return result[inside_specific_section]
        end
    end
    world.tiles={{zindex=1,type="player"}} ; collectgarbage("collect")
    local components_load={
        {target="info"}     ,
        {target="tiles"}    ,
        {target="info",     specific_section="geometry"},
        {target="info",     specific_section="level"}   ,
        {target="info",     specific_section="skybox"}  ,
        {target="layers"}   ,
        {target="player"}   ,
        {target="scripts"}  ,
        {target="messages"}
    }
    for _, component in ipairs(components_load) do
        local target, specific_section = component.target, component.specific_section
        world["recipe_" .. (specific_section ~= nil and specific_section or target)]=attempt_load_world_file(target, specific_section) or world["recipe_" .. target]
    end
    Sol_LoadWorldGeometry(world)
    Sol_LoadWorldLevel(engine, world_mode, world)
    Sol_LoadWorldPlayer(engine, world_mode, world)
    Sol_LoadWorldScript(engine, world_mode, world)
    Sol_LoadWorldSkybox(world)
    --
    dmsg("Loaded map: %dx%d with %d tiles.", world.size[1], world.size[2], #world.tiles)
    SWM_Chunk.Sol_MapChunksInWorld(world)
end

--
return module