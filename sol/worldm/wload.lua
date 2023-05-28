local smath=require("sol.smath")
local defaults=require("sol.defaults")
local system=require("sol.system")
local scf=require("sol.scf")

-- world module:
local tiles=require("sol.worldm.tiles")
local chunk=require("sol.worldm.chunk")

local module={}

function Sol_GenerateLayer(world, layer)
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
            local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[matrix_block])
            proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
            proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
            table.insert(world.tiles, proto_tile)
          end
        end
      end
    end
    --> end.
  end
end ; module.Sol_GenerateLayer=Sol_GenerateLayer

function Sol_WorldSpawnTile(engine, world_mode, world, tile_name)
  if world.recipe_tiles[tile_name] then
    local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[tile_name])
    table.insert(world.tiles, proto_tile)
    return true
  else
    return false
  end
end ; module.Sol_WorldSpawnTile=Sol_WorldSpawnTile

function Sol_LoadWorld(engine, world_mode, world, world_name)
  local target_file=system.Sol_MergePath({engine.root,string.format("levels/%s.slevel",world_name)})
  dmsg("Sol_LoadWorld() will attempt to load file: %s for world: %s", target_file, world_name)
  --> clean the old tiles and load everything again.
  world.tiles={{zindex=1,type="player"}}
  collectgarbage("collect")
  --> load the "recipes" and the world information from the target file.
  target_file                 =scf.SCF_LoadFile(target_file)
  world.info                  =target_file["info"]        or world.info
  world.recipe_tiles          =target_file["tiles"]       or world.recipe_tiles
  world.recipe_geometry       =target_file["geometry"]    or world.recipe_geometry
  world.recipe_level          =target_file["level"]       or world.recipe_level
  world.recipe_layers         =target_file["layers"]      or world.recipe_layers
  --> load the level geometry
  world.bg_size             =smath.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size        =smath.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  world.world_size          =smath.Sol_NewVector((world.bg_size.x-1)*world.bg_tile_size.x,(world.bg_size.y-1)*world.bg_tile_size.y)
  world.enable_world_borders=(world.recipe_geometry["enable_world_borders"] == true)
  --> "level" section stuff.
  if world.recipe_level then
    local spawn_tiles=world.recipe_level["spawn_tiles"]
    if spawn_tiles and type(spawn_tiles) == "table" then
      for _, tile in ipairs(spawn_tiles) do
        local sucess=Sol_WorldSpawnTile(engine, world_mode, world, tile)
        if not sucess then mwarn("couldn't generate tile: %s!", tile) end
      end
    end
    local spawn_layers=world.recipe_level["spawn_layers"]
    if spawn_layers and type(spawn_layers) == "table" then
      for _, layer in ipairs(spawn_layers) do
        Sol_GenerateLayer(world, layer)
      end
    end
  end
  --> map the chunks
  chunk.Sol_MapChunksInWorld(world)
end ; module.Sol_LoadWorld=Sol_LoadWorld

--
return module