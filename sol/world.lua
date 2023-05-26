local defaults=require("sol.defaults")
local smath=require("sol.smath")
local scf=require("sol.scf")
local system=require("sol.system")
local module={}

--
function Sol_NewPlayer()
  return {
    type = "player",
    name = "player",
    inventory = {},
    pets = {},
    speed = 7,
    looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.DOWN,
    --
    draw_method = defaults.SOL_DRAW_USING.COLOR,
    color = smath.Sol_NewColor4(80, 80, 80),
    textures = {},
    texture_index = 0,
    texture_timing = 0,
    --
    rel_position = smath.Sol_NewVector(0, 0),
    rectangle = smath.Sol_NewRectangle(nil, defaults.SOL_PLAYER_SIZE),
  }
end ; module.Sol_NewPlayer=Sol_NewPlayer
function Sol_LoadPlayerRelativePosition(world_mode, player)
  player.rel_position.x=math.floor(world_mode.viewport_size.x/2)-math.floor(player.rectangle.size.x/2)
  player.rel_position.y=math.floor(world_mode.viewport_size.y/2)-math.floor(player.rectangle.size.y/2)
end ; module.Sol_LoadPlayerRelativePosition=Sol_LoadPlayerRelativePosition

--[[ Draw Related Functions ]]
function Sol_DrawPlayer(engine, world_mode, player)
  if player.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(player.color))
    local posx, posy=smath.Sol_UnpackVectorXY(player.rel_position)
    local width, height=smath.Sol_UnpackVectorXY(player.rectangle.size)
    love.graphics.rectangle("fill", posx, posy, width, height)
  else
    mwarn("Sol_DrawPlayer() player draw_method is invalid, falling back to color.")
    player.draw_method=defaults.SOL_DRAW_USING.COLOR
  end
end ; module.Sol_DrawPlayer=Sol_DrawPlayer

--
function Sol_NewTile(tile)
  local tile = tile or {}
  return {
    type = "tile",
    name = tile["name"] or "player",
    rectangle = smath.Sol_NewRectangle(smath.Sol_NewVector(tile["position"]), smath.Sol_NewVector(tile["size"])),
    zindex = (tile["zindex"] == 1 and 2 or tile["zindex"]) or 0,
    collide = tile["collide"] or false,
    should_draw = tile["should_draw"] or true,
    draw_method = tile["draw_method"] or defaults.SOL_DRAW_USING.COLOR,
    color = smath.Sol_NewColor4(tile["color"]),
    textures = tile["textures"] or {},
    texture_index = 1,
    texture_timing = 0
  }
end ; module.Sol_NewTile=Sol_NewTile

--[[ Draw Related Functions ]]
function Sol_DrawTile(engine, world_mode, world, tile)
  if tile.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(tile.color))
    local rxpos, rypos = smath.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
    local width, height= smath.Sol_UnpackVectorXY(tile.rectangle.size)
    love.graphics.rectangle("fill", rxpos, rypos, width, height)
  else
    mwarn("not implemented drawing method, falling back to color.")
    tile.draw_method = defaults.SOL_DRAW_USING.COLOR
    -- NOTE: there is not actually problem to call this since we changed
    -- the color drawing method so there is no problem with eternal recursion.
    Sol_DrawTile(engine, world_mode, world, tile)
  end
end ; module.Sol_DrawTile=Sol_DrawTile

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
function Sol_SortTiles(world)
  table.sort(world.tiles, function(a, b) return a.zindex < b.zindex end)
end ; module.Sol_SortTiles=Sol_SortTiles

function Sol_GenerateWorldBackground(engine, world_mode, world)
  local valid, position=table.find({
    recipe_background=world.recipe_background,
    recipe_geometry=world.recipe_geometry,
    recipe_level=world.recipe_level,
    recipe_background_matrix=world.recipe_background["matrix"],
    recipe_geometry_bg_size=world.recipe_geometry["bg_size"],
    recipe_geometry_bg_tile_size=world.recipe_geometry["bg_tile_size"],
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
        local proto_tile=Sol_NewTile(world.recipe_tiles[matrix_block])
        proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
        proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
        table.insert(world.tiles, proto_tile)
      end
    end
  end
  -- Sol_SortTiles(world)
  --
  return true
end ; module.Sol_GenerateWorldBackground=Sol_GenerateWorldBackground
function Sol_WorldSpawnTile(engine, world_mode, world, tile_name)
  if world.recipe_tiles[tile_name] then
    local proto_tile=Sol_NewTile(world.recipe_tiles[tile_name])
    table.insert(world.tiles, proto_tile)
    return true
  else
    return false
  end
end ; module.Sol_WorldSpawnTile=Sol_WorldSpawnTile
function Sol_MapChunksInWorld(engine, world_mode, world)
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
      else
        world.chunks[chunk_reference]={}
        table.insert(world.chunks[chunk_reference], tile_index)
      end
    end
  end
  dmsg("Sol_MapChunksInWorld() took %ds", os.clock()-begun_mapping_chunks_at)
end
function Sol_LoadWorld(engine, world_mode, world, world_name)
  local target_file=system.Sol_MergePath({engine.root,string.format("levels/%s.slevel",world_name)})
  dmsg("Sol_LoadWorld() will attempt to load file: %s for world: %s", target_file, world_name)
  --> clean the old tiles and load everything again.
  world.tiles={{zindex=1,type="player"}}
  collectgarbage("collect")
  --> load the sections
  target_file=scf.SCF_LoadFile(target_file)
  world.info=target_file["info"] or world.info
  world.recipe_tiles=target_file["tiles"] or world.recipe_tiles
  world.recipe_geometry=target_file["geometry"] or world.recipe_geometry
  world.recipe_background=target_file["background"] or world.recipe_background
  world.recipe_level=target_file["level"] or world.recipe_level
  --> generate world background
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
  Sol_MapChunksInWorld(engine, world_mode, world)
end ; module.Sol_LoadWorld=Sol_LoadWorld

--[[ Tick Related Functions ]]
function Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition)
  local player_rectangle=smath.Sol_CloneRectangle(world_mode.player.rectangle)
  player_rectangle.position.x=xposition
  player_rectangle.position.y=yposition
  --
  if world.enable_world_borders then
    local inside_x=player_rectangle.position.x>=0 and player_rectangle.position.x<=world.world_size.x
    local inside_y=player_rectangle.position.y>=0 and player_rectangle.position.y<=world.world_size.y
    if not (inside_x and inside_y) then
      return false
    end
  end
  --
  for index = 1, #world.tiles do
    local tile=world.tiles[index]
    if tile.collide then
      if smath.Sol_TestRectangleCollision(player_rectangle, tile.rectangle) then
        return false
      end
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
  if      love.keyboard.isDown(engine.wmode_keymap["walk_up"])    then
    Sol_WalkInWorld(engine, world_mode, world, 0, -world_mode.player.speed)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.UP
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_down"])  then
    Sol_WalkInWorld(engine, world_mode, world, 0,  world_mode.player.speed)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.DOWN
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_left"])  then
    Sol_WalkInWorld(engine, world_mode, world, -world_mode.player.speed, 0)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.LEFT
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_right"]) then
    Sol_WalkInWorld(engine, world_mode, world, world_mode.player.speed,  0)
    world_mode.player.looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.RIGHT
  end
end ; module.Sol_TickWorld=Sol_TickWorld

--[[ Draw Related Functions ]]
function Sol_DrawWorldChunkWithZIndex(engine, world_mode, world, chunk_name, consider_player)
  local draw_queue = consider_player and {{zindex=1,target=1,type="player"}} or {}
  if world.chunks[chunk_name] then
    --> basically puts on a buffer for follow the order.
    for _, chunk_target in ipairs(world.chunks[chunk_name]) do
      table.insert(draw_queue, {target=chunk_target, zindex=world.tiles[chunk_target].zindex})
    end
    table.sort(draw_queue, function (a, b) return a.zindex < b.zindex end)
    --> draw.
    for _, draw_request in ipairs(draw_queue) do
      if draw_request["type"] then
        Sol_DrawPlayer(engine, world_mode, world_mode.player)
      else
        Sol_DrawTile(engine, world_mode, world, world.tiles[draw_request.target])
      end
    end
  end
end
function Sol_DrawWorld(engine, world_mode, world)
  -- for _, tile in ipairs(world.tiles) do
  --   if tile.zindex == 1 and tile.type=="player" then
  --     Sol_DrawPlayer(engine, world_mode, world_mode.player)
  --   else
  --     if tile.should_draw then
  --       Sol_DrawTile(engine, world_mode, world, tile)
  --     end
  --   end
  -- end
  --> determine the player current chunk.
  local player_current_chunk_x=math.floor(world_mode.player.rectangle.position.x/(world.bg_tile_size.x*defaults.SOL_WORLD_CHUNK_WIDTH))
  local player_current_chunk_y=math.floor(world_mode.player.rectangle.position.y/(world.bg_tile_size.y*defaults.SOL_WORLD_CHUNK_HEIGHT))
  --> render the player vision based on the amount to render.
  --> this will always render in a square form.
  
  -- TODO: for better performance, check if the player is near the rendering border (aka. the end of the chunk)
  -- this prevent a lower zindex tile of being drawn on the front the player cuz' the chunk is ignoring the order.
  for yindex = player_current_chunk_y - engine.vars["RENDER_CHUNK_AMOUNT"], player_current_chunk_y + engine.vars["RENDER_CHUNK_AMOUNT"] do
    for xindex = player_current_chunk_x - engine.vars["RENDER_CHUNK_AMOUNT"], player_current_chunk_x + engine.vars["RENDER_CHUNK_AMOUNT"] do
      local chunk_target=tostring(xindex)..'.'..tostring(yindex)
      if xindex == player_current_chunk_x and yindex == player_current_chunk_y then
        Sol_DrawWorldChunkWithZIndex(engine, world_mode, world, chunk_target, true)
      else
        Sol_DrawWorldChunkWithZIndex(engine, world_mode, world, chunk_target, true)
      end
    end
  end

  -- --> does the chunk exist? if yes, then render the main chunk.
  -- local player_current_chunk=tostring(player_current_chunk_x)..'.'..tostring(player_current_chunk_y)
  -- dmsg("chunk: %s", player_current_chunk)
  -- Sol_DrawWorldChunkWithZIndex(engine, world_mode, world, player_current_chunk, true)
end ; module.Sol_DrawWorld=Sol_DrawWorld

--
return module