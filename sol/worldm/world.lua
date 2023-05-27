local defaults=require("sol.defaults")
local smath=require("sol.smath")
local scf=require("sol.scf")
local system=require("sol.system")
local player=require("sol.worldm.player")
local tiles=require("sol.worldm.tiles")
local chunk=require("sol.worldm.chunk")
local module={}

--
function Sol_NewWorld(world)
  return {
    info={name="n/n", description="?"},
    --
    chunks={},
    --
    recipe_tiles={},
    recipe_geometry={},
    recipe_background={},
    recipe_level={},
    --
    bg_size=nil,
    bg_tile_size=nil,
    world_size=smath.Sol_NewVector(0, 0),
    enable_world_borders=true,
    tiles={{zindex=1, type="player"}},
  }
end ; module.Sol_NewWorld=Sol_NewWorld

--[[ Init Related Functions ]]
function Sol_GenerateWorldBackground(engine, world_mode, world)
  local valid, position=table.find({
    recipe_background               =world.recipe_background,
    recipe_geometry                 =world.recipe_geometry,
    recipe_level                    =world.recipe_level,
    recipe_background_matrix        =world.recipe_background["matrix"],
    recipe_geometry_bg_size         =world.recipe_geometry["bg_size"],
    recipe_geometry_bg_tile_size    =world.recipe_geometry["bg_tile_size"],
  }, nil)
  if valid then
    mwarn("Sol_GenerateWorldBackground() failed to generate world due lack of: %s section/define!", position)
    return false
  end
  world.bg_size=smath.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size=smath.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  world.world_size=smath.Sol_NewVector((world.bg_size.x-1)*world.bg_tile_size.x,(world.bg_size.y-1)*world.bg_tile_size.y)
  world.enable_world_borders=(world.recipe_geometry["enable_world_borders"] == true)
  -- A - Z, a - z, 0 - 9 amount of blocks for you to play on the background.
  for yindex = 1, world.bg_size.y do
    local line=world.recipe_background.matrix[yindex]
    for xindex = 1, world.bg_size.x do
      local matrix_block=line:sub(xindex,xindex)
      if world.recipe_tiles[matrix_block] == nil then
        mwarn("unable to find %s block.", matrix_block)
      else
        local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[matrix_block])
        proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
        proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
        table.insert(world.tiles, proto_tile)
      end
    end
  end
  return true
end ; module.Sol_GenerateWorldBackground=Sol_GenerateWorldBackground
function Sol_WorldSpawnTile(engine, world_mode, world, tile_name)
  if world.recipe_tiles[tile_name] then
    local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[tile_name])
    table.insert(world.tiles, proto_tile)
    return true
  else
    return false
  end
end ; module.Sol_WorldSpawnTile=Sol_WorldSpawnTile
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
  world.recipe_background     =target_file["background"]  or world.recipe_background
  world.recipe_level          =target_file["level"]       or world.recipe_level
  --> for the section "background"
  local _worked=Sol_GenerateWorldBackground(engine, world_mode, world)
  if not _worked then mwarn("WORLD did not generate BACKGROUND!") end
  --> "level" section stuff.
  if world.recipe_level then
    local spawn_tiles=world.recipe_level["spawn_tiles"]
    if spawn_tiles and type(spawn_tiles) == "table" then
      for _, tile in ipairs(spawn_tiles) do
        local sucess=Sol_WorldSpawnTile(engine, world_mode, world, tile)
        if not sucess then mwarn("couldn't generate tile: %s!", tile) end
      end
    end
  end
  --> map the chunks
  Sol_MapChunksInWorld(world)
end ; module.Sol_LoadWorld=Sol_LoadWorld

--[[ Tick Related Functions ]]
function Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition)
  --> setup the testing rectangle.
  local player_rectangle=smath.Sol_CloneRectangle(world_mode.player.rectangle)
  player_rectangle.position.x=xposition
  player_rectangle.position.y=yposition
  --> check if the player is inside the world borders.
  if world.enable_world_borders then
    local inside_x=player_rectangle.position.x>=0 and player_rectangle.position.x<=world.world_size.x
    local inside_y=player_rectangle.position.y>=0 and player_rectangle.position.y<=world.world_size.y
    if not (inside_x and inside_y) then return false end
  end
  --> check the player current chunk.
  local cpx, cpy=chunk.Sol_GetPlayerCurrentChunk(world_mode, world)
  local tiles_to_test=chunk.Sol_GetChunksReferencedTiles(world, cpx, cpy, 1)
  for _, tiles_referenced in ipairs(tiles_to_test) do
    local tile_selected = world.tiles[tiles_referenced]
    if tile_selected.collide then
      if smath.Sol_TestRectangleCollision(player_rectangle, tile_selected.rectangle) then return false end
    end
  end
  return true
end ; module.Sol_CheckPlayerPositionAt=Sol_CheckPlayerPositionAt
function Sol_WalkInWorld(engine, world_mode, world, xdirection, ydirection)
  -- TODO: make more precise movements.
  local xposition, yposition=world_mode.player.rectangle.position.x+xdirection, world_mode.player.rectangle.position.y+ydirection
  if Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition) then
    world_mode.player.rectangle.position.x=world_mode.player.rectangle.position.x+xdirection
    world_mode.player.rectangle.position.y=world_mode.player.rectangle.position.y+ydirection
  else
    -- NOTE: PRECISE_WALK is KINDA a very expansive function, use it with very caution!
    if engine.vars["PRECISE_WALK"] then
      --> for xdirection
      if xdirection ~= 0 then
        local x_amount=0
        while (xdirection < 0 and x_amount >= xdirection or x_amount <= xdirection) do
          if not Sol_CheckPlayerPositionAt(engine, world_mode, world, world_mode.player.rectangle.position.x+x_amount, world_mode.player.rectangle.position.y) then
            break
          else
            x_amount=x_amount+(xdirection < 0 and -1 or 1)
          end
        end
        -- we remove -1 amount of walking to ignore the last collision we made to check if the player is actually colliding with
        -- something, if no remove the player will be stuck in some wall. We could have put this inside the loop.
        world_mode.player.rectangle.position.x=world_mode.player.rectangle.position.x+(xdirection < 0 and x_amount + 1 or x_amount - 1)
      end
      --> for ydirection
      if ydirection ~= 0 then
        local y_amount=0
        while (ydirection < 0 and y_amount >= ydirection or y_amount <= ydirection) do
          if not Sol_CheckPlayerPositionAt(engine, world_mode, world, world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y+y_amount) then
            break
          else
            y_amount=y_amount+(ydirection < 0 and -1 or 1)
          end
        end
        world_mode.player.rectangle.position.y=world_mode.player.rectangle.position.y+(ydirection < 0 and y_amount + 1 or y_amount - 1)
      end
      --> (...)
    end
  end
end ; module.Sol_WalkInWorld=Sol_WalkInWorld
function Sol_TickWorld(engine, world_mode, world)
  world_mode.player.current_speed = love.keyboard.isDown("lshift") and world_mode.player.run_speed or world_mode.player.walk_speed
  if      love.keyboard.isDown(engine.wmode_keymap["walk_up"])    then
    Sol_WalkInWorld(engine, world_mode, world, 0, -world_mode.player.current_speed)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.UP
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_down"])  then
    Sol_WalkInWorld(engine, world_mode, world, 0,  world_mode.player.current_speed)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.DOWN
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_left"])  then
    Sol_WalkInWorld(engine, world_mode, world, -world_mode.player.current_speed, 0)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.LEFT
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_right"]) then
    Sol_WalkInWorld(engine, world_mode, world, world_mode.player.current_speed,  0)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.RIGHT
  end
end ; module.Sol_TickWorld=Sol_TickWorld

--[[ Draw Related Functions ]]
function Sol_DrawWorld(engine, world_mode, world)
  --> determine the player current chunk + all the sorroundings tiles.
  local draw_tile_queue = chunk.Sol_GetChunksOrdered(engine, world_mode, world)
  for _, tile in ipairs(draw_tile_queue) do
    if tile["type"] then
      player.Sol_DrawPlayer(engine, world_mode, world_mode.player)
    else
      tiles.Sol_DrawTile(engine, world_mode, world, world.tiles[tile.target])
    end
  end
end ; module.Sol_DrawWorld=Sol_DrawWorld

--
return module