local defaults=require("sol.defaults")
local module = {}

-- General Chunk Stuff
function Sol_GetPlayerCurrentChunk(world_mode, world)
  local player_current_chunk_x=math.floor(world_mode.player.rectangle.position.x/(world.bg_tile_size.x*defaults.SOL_WORLD_CHUNK_WIDTH))
  local player_current_chunk_y=math.floor(world_mode.player.rectangle.position.y/(world.bg_tile_size.y*defaults.SOL_WORLD_CHUNK_HEIGHT))
  return player_current_chunk_x, player_current_chunk_y
end ; module.Sol_GetPlayerCurrentChunk=Sol_GetPlayerCurrentChunk

function Sol_MapChunksInWorld(world)
  -- TODO: on the future make this code threaded to prevent the game lagging when creating a lot of tiles.
  local begun_mapping_chunks_at=os.clock()
  world.chunks={}
  for tile_index, tile in ipairs(world.tiles) do
    if tile.type == "tile" then
      local tile_belongs_chunk_inx=math.floor(tile.rectangle.position.x/(world.bg_tile_size.x*defaults.SOL_WORLD_CHUNK_WIDTH))
      local tile_belongs_chunk_iny=math.floor(tile.rectangle.position.y/(world.bg_tile_size.y*defaults.SOL_WORLD_CHUNK_HEIGHT))
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
end ; module.Sol_MapChunksInWorld=Sol_MapChunksInWorld

--[[ Functions used in Tick ]]
function Sol_GetChunksReferencedTiles(world, indexx, indexy, range)
  local adquired_references = {}
  for yindex = indexy - range, indexy + range do
    for xindex = indexx - range, indexx + range do
      local chunk_target=world.chunks[tostring(xindex)..'.'..tostring(yindex)]
      if chunk_target then
        for _, chunk_reference_tile in ipairs(chunk_target) do
          table.insert(adquired_references, chunk_reference_tile)
        end
      end
      --
    end
  end
  return adquired_references
end ; module.Sol_GetChunksReferencedTiles=Sol_GetChunksReferencedTiles

--[[ Functions used in Drawing ]]
function Sol_AdquireChunksConsideringZIndex(world, chunk_name, consider_player)
  local draw_queue = consider_player and {{zindex=1,target=1,type="player"}} or {}
  if world.chunks[chunk_name] then
    --> basically puts on a buffer for follow the order.
    for _, chunk_target in ipairs(world.chunks[chunk_name]) do
      table.insert(draw_queue, {target=chunk_target, zindex=world.tiles[chunk_target].zindex})
    end
    return draw_queue
  end
end ; module.Sol_AdquireChunksConsideringZIndex=Sol_AdquireChunksConsideringZIndex
function Sol_GetChunksOrdered(engine, world_mode, world)
  --> determine the player current chunk + all the sorroundings tiles.
  local player_current_chunk_x, player_current_chunk_y=Sol_GetPlayerCurrentChunk(world_mode, world)
  local draw_tile_queue = {}
  for yindex = player_current_chunk_y - engine.vars["RENDER_CHUNK_AMOUNT"], player_current_chunk_y + engine.vars["RENDER_CHUNK_AMOUNT"] do
    for xindex = player_current_chunk_x - engine.vars["RENDER_CHUNK_AMOUNT"], player_current_chunk_x + engine.vars["RENDER_CHUNK_AMOUNT"] do
      local chunk_target=tostring(xindex)..'.'..tostring(yindex)
      if xindex == player_current_chunk_x and yindex == player_current_chunk_y then
        table.unimerge(draw_tile_queue, Sol_AdquireChunksConsideringZIndex(world, chunk_target, true))
      else
        table.unimerge(draw_tile_queue, Sol_AdquireChunksConsideringZIndex(world, chunk_target, true))
      end
    end
  end
  --> begin organizing the stuff...
  table.sort(draw_tile_queue, function (a, b) return a.zindex < b.zindex end)
  return draw_tile_queue
end ; module.Sol_GetChunksOrdered=Sol_GetChunksOrdered

--
return module