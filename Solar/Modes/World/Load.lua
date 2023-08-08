-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local unpack = unpack or table.unpack

local SM_Vector   = require("Solar.Math.Vector")
local SS_Path     = require("Solar.System.Path")
local SCF         = require("Solar.SCF")
local SD_Recipe   = require("Solar.Draw.Recipe")
local SWM_Player  = require("Solar.Modes.World.Player")
local SWM_Routines= require("Solar.Modes.World.Routine")
local SWM_Scripts = require("Solar.Modes.World.Scripts")
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
        if matrix_block ~= "0" then
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

-- Sol_LoadWorld(engine, world_mode, world, world_name: string): automatically loads the world
-- recipe file and build the world from the recipe provided.
function module.Sol_LoadWorld(engine, world_mode, world, world_name)
  local target_file=SS_Path.Sol_MergePath({engine.root,string.format("levels/%s.slevel",world_name)})
  dmsg("Sol_LoadWorld() will attempt to load file: %s for world: %s", target_file, world_name)
  --> clean the old tiles and load everything again.
  world.tiles={{zindex=1,type="player"}}
  collectgarbage("collect")
  --> load the "recipes" and the world information from the target file.
  target_file                 =SCF.SCF_LoadFile(target_file)
  world.info                  =target_file["info"]        or world.info
  world.recipe_tiles          =target_file["tiles"]       or world.recipe_tiles
  world.recipe_geometry       =target_file["geometry"]    or world.recipe_geometry
  world.recipe_level          =target_file["level"]       or world.recipe_level
  world.recipe_layers         =target_file["layers"]      or world.recipe_layers
  world.recipe_player         =target_file["player"]      or world.recipe_player
  world.recipe_scripts        =target_file["scripts"]     or world.recipe_scripts
  --> "geometry" section stuff.
  world.bg_size             =SM_Vector.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size        =SM_Vector.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  world.world_size          =SM_Vector.Sol_NewVector((world.bg_size.x-1)*world.bg_tile_size.x,(world.bg_size.y-1)*world.bg_tile_size.y)
  world.enable_world_borders=(world.recipe_geometry["enable_world_borders"] == true)
  --> "level" section stuff.
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
  --> "player" section 
  -- NOTE: the player section is actually loaded during the world firstrun routine.
  local function wload_AdjustPlayerOneshot_FirstRun(engine, world_mode, world, routine)
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
    return SWM_Routines.ROUTINE_STATUS_FINISHED
  end
  SWM_Routines.Sol_PushRoutine(world.routines, SWM_Routines.Sol_NewRoutine(
    "wload.AdjustPlayerOneshot", SWM_Routines.EXEC_ON_TICK,
    {[SWM_Routines.ROUTINE_STATUS_FIRSTRUN]=wload_AdjustPlayerOneshot_FirstRun},
    {}
  ))
  --> "script" section
  if world.recipe_scripts then
    for script_name, script_recipe in pairs(world.recipe_scripts) do
      if script_name ~= "__type" then
        dmsg("loading script: %s ...", script_name)
        SWM_Scripts.Sol_LoadScript(engine, world_mode, world, world.scripts, script_recipe)
      end
    end
  end
  --> build all the chunks in the map.
  SWM_Chunk.Sol_MapChunksInWorld(world)
end

--
return module