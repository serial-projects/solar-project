-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local unpack = unpack or table.unpack

local SM_Vector   = require("Solar.Math.Vector")
local SS_Path     = require("Solar.System.Path")
local SV_Consts   = require("Solar.Values.Consts")

local SCF         = require("Solar.SCF")

local SD_Recipe   = require("Solar.Draw.Recipe")

local SSE_Script  = require("Solar.Services.Script")
local SSE_Routines= require("Solar.Services.Routines")

local SWM_Player  = require("Solar.Modes.World.Player")
local SWM_Tiles   = require("Solar.Modes.World.Tiles")
local SWM_Chunk   = require("Solar.Modes.World.Chunk")

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
            proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
            proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
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
  world.bg_size             =SM_Vector.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size        =SM_Vector.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  world.world_size          =SM_Vector.Sol_NewVector((world.bg_size.x-1)*world.bg_tile_size.x,(world.bg_size.y-1)*world.bg_tile_size.y)
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
          xpos = xpos * world.bg_tile_size.x
          ypos = ypos * world.bg_tile_size.y
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

-- Sol_LoadWorld(engine, world_mode, world, world_name: string): automatically loads the world
-- recipe file and build the world from the recipe provided.
function module.Sol_LoadWorld(engine, world_mode, world, world_name)
  local function attempt_load_world_file(world_component, inside_specific_section)
    inside_specific_section = inside_specific_section or world_component
    local component_target_file = SS_Path.Sol_MergePath({engine.root,string.format("levels/%s/%s.sl", world_name, world_component)})
    local success, result = pcall(function()
      dmsg("component file is being loaded: \"%s\"", component_target_file)
      return SCF.SCF_LoadFile(component_target_file)
    end)
    if not success then
      emsg("attempt_load_world_file() failed to load world component: \"%s\"", world_component)
      return nil
    else
      return result[inside_specific_section]
    end
  end
  world.tiles={{zindex=1,type="player"}} ; collectgarbage("collect")
  local components_load={
    {target="info"},     {target="tiles"},    {target="geometry"},  {target="level"},
    {target="layers"},   {target="player"},   {target="scripts"},   {target="messages"}
  }
  for _, component in ipairs(components_load) do
    world["recipe_" .. component.target]=attempt_load_world_file(component.target, component["specific_section"]) or world["recipe_" .. component.target]
  end
  Sol_LoadWorldGeometry(world)
  Sol_LoadWorldLevel(engine, world_mode, world)
  Sol_LoadWorldPlayer(engine, world_mode, world)
  Sol_LoadWorldScript(engine, world_mode, world)
  SWM_Chunk.Sol_MapChunksInWorld(world)
end

--
return module