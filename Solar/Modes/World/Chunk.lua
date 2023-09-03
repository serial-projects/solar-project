-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SV_Defaults = require("Solar.Values.Defaults")
local module = {}

-- Sol_GetPlayerCurrentChunk(world_mode: Sol_WorldMode, world: Sol_World) -> player_current_chunk_x: number, player_current_chunk_y: number
-- Returns the player current chunk (in x and y) based on it's absolute position.
function module.Sol_GetPlayerCurrentChunk(world_mode, world)
  local player_current_chunk_x=math.floor(world_mode.player.rectangle.position.x/(world.bg_tile_size.x*SV_Defaults.SOL_WORLD_CHUNK_WIDTH))
  local player_current_chunk_y=math.floor(world_mode.player.rectangle.position.y/(world.bg_tile_size.y*SV_Defaults.SOL_WORLD_CHUNK_HEIGHT))
  return player_current_chunk_x, player_current_chunk_y
end

-- Sol_MapChunksInWorld(world: Sol_World)
-- This will map all the chunk elements locations.
function module.Sol_MapChunksInWorld(world)
  -- TODO: on the future make this code threaded to prevent the game lagging when creating a lot of tiles.
  local begun_mapping_chunks_at=os.clock()
  world.chunks={}
  for tile_index, tile in ipairs(world.tiles) do
    if tile.type == "tile" then
      local tile_belongs_chunk_inx=math.floor(tile.rectangle.position.x/(world.bg_tile_size.x*SV_Defaults.SOL_WORLD_CHUNK_WIDTH))
      local tile_belongs_chunk_iny=math.floor(tile.rectangle.position.y/(world.bg_tile_size.y*SV_Defaults.SOL_WORLD_CHUNK_HEIGHT))
      local chunk_reference=tostring(tile_belongs_chunk_inx)..'.'..tostring(tile_belongs_chunk_iny)
      if world.chunks[chunk_reference] then
        table.insert(world.chunks[chunk_reference], tile_index)
        table.insert(tile.current_chunk, chunk_reference)
      else
        world.chunks[chunk_reference]={}
        table.insert(world.chunks[chunk_reference], tile_index)
        table.insert(tile.current_chunk, chunk_reference)
      end
    end
  end
  dmsg("Sol_MapChunksInWorld() took %fs", os.clock()-begun_mapping_chunks_at)
end

-- Sol_GetChunksReferencedTiles(world: Sol_World, indexx: number, indexy: number, range: number):
---@return table {[n]: {target: string, zindex: number}}
module.Sol_GetChunksReferencedTiles=function(world, indexx, indexy, range)
  local adquired_references = {}
  for yindex = indexy - range, indexy + range do
    for xindex = indexx - range, indexx + range do
      local chunk_target=world.chunks[string.format("%d.%d", xindex, yindex)]
      if chunk_target then
        for _, chunk_reference_tile in ipairs(chunk_target) do
          table.insert(adquired_references, {target=chunk_reference_tile, zindex=world.tiles[chunk_reference_tile].zindex})
        end
      end
    end
  end
  return adquired_references
end

-- Sol_GetChunksOrdered(engine: Sol_Engine, world_mode: Sol_WorldMode, world: Sol_World) -> draw_tile_queue: table
function module.Sol_GetChunksOrdered(engine, world_mode, world, should_consider_player)
  --> determine the player current chunk + all the sorroundings tiles.
  local player_current_chunk_x, player_current_chunk_y=module.Sol_GetPlayerCurrentChunk(world_mode, world)
  local RENDER_CHUNK_AMOUNT = engine.vars["RENDER_CHUNK_AMOUNT"]
  local draw_tile_queue = module.Sol_GetChunksReferencedTiles(world, player_current_chunk_x, player_current_chunk_y, RENDER_CHUNK_AMOUNT)
  if should_consider_player then
    table.insert(draw_tile_queue, {zindex=1, target=1, type="player"})
  end
  table.sort(draw_tile_queue, function (a, b) return a.zindex < b.zindex end)
  return draw_tile_queue
end

--
return module