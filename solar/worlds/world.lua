local module  = {}

local utils   = require("solar.utils")
local consts  = require("solar.consts")
local scf     = require("solar.scf")
local storage = require("solar.storage")

local wtile   = require("solar.worlds.tiles")
local wplayer = require("solar.worlds.player")

--
--
--

--
-- World
--
function Solar_NewWorld(ww, wh, wtw, wth)
  return {
    tiles = {{name="player", generic_name="player00", is_player=true, zindex=1}}, chunks = {},
    size = utils.Solar_NewVectorXY(ww * wtw, wh * wth),
    tile_size = utils.Solar_NewVectorXY(wtw, wth),
    -- use_chunks: the chunks are a important optimization made to prevent lag on really large
    -- maps, obviously this rendering requires a longer initialization time.
    use_chunks = (ww > 50 or wh > 50),
  }
end
module.Solar_NewWorld = Solar_NewWorld
function Solar_SortTilesWorld(world)
  table.sort(world.tiles, function(a, b) return a.zindex < b.zindex end)
end
function Solar_InsertTileWorld(world, tile, ignore_sorting)
  local ignore_sorting = ignore_sorting or false
  table.insert(world.tiles, tile)
  if not ignore_sorting then Solar_SortTilesWorld(world) end
end
module.Solar_InsertTileWorld = Solar_InsertTileWorld
function Solar_BuildTestingWorld(world_mode)
  --
  local proto_world = Solar_NewWorld(
    consts.SOLAR_TEST_WORLD_WIDTH,      consts.SOLAR_TEST_WORLD_HEIGHT,
    consts.SOLAR_TEST_WORLD_TILE_WIDTH, consts.SOLAR_TEST_WORLD_TILE_HEIGHT
  )
  --
  for yindex = 0, consts.SOLAR_TEST_WORLD_HEIGHT - 1 do
    for xindex = 0, consts.SOLAR_TEST_WORLD_HEIGHT - 1 do
      local proto_tile = Solar_NewTile(
        "floor", string.format("floor$%d$%d", xindex, yindex), 0,
        xindex * consts.SOLAR_TEST_WORLD_TILE_WIDTH,
        yindex * consts.SOLAR_TEST_WORLD_TILE_HEIGHT,
        consts.SOLAR_TEST_WORLD_TILE_WIDTH, consts.SOLAR_TEST_WORLD_TILE_HEIGHT,
        false
      )
      Solar_InsertTileWorld(proto_world, proto_tile, true)
    end
  end
  -- Build a simple pattern in the world to thest the capacity of collision.
  for yindex = 1, consts.SOLAR_TEST_WORLD_HEIGHT - 1 do
    for xindex = 1, consts.SOLAR_TEST_WORLD_WIDTH - 1 do
      if xindex % 2 == 0 and yindex % 2 == 0 then
        local proto_tile = Solar_NewTile(
          "wall", string.format("wall$%d$%d", xindex, yindex), 1,
          xindex * consts.SOLAR_TEST_WORLD_TILE_WIDTH,
          yindex * consts.SOLAR_TEST_WORLD_TILE_HEIGHT,
          consts.SOLAR_TEST_WORLD_TILE_WIDTH, consts.SOLAR_TEST_WORLD_TILE_HEIGHT
        )
        proto_tile.color = utils.Solar_NewColor(math.random(1, 255),math.random(1, 255),math.random(1, 255))
        proto_tile.collide = true
        Solar_InsertTileWorld(proto_world, proto_tile, true)
      end
    end
    Solar_SortTilesWorld(proto_world)
  end
  --
  local proto_tile = Solar_NewTile("MovinTile", "movingtile00", 1, 100, 100, 64, 64, true)
  proto_tile.color = utils.Solar_NewColor(100, 80, 123)
  Solar_InsertTileWorld(proto_world, proto_tile)
  table.insert(world_mode.worlds, proto_world)
  world_mode.current_world = 1
end
module.Solar_BuildTestingWorld = Solar_BuildTestingWorld
function Solar_TestPlayerCollisionAt(world, player, posx, posy, return_object)
  -- Check if the player at the position still on the world boundaries.
  do
    local xa, xb = posx, posx + (player.size.x)
    local ya, yb = posy, posy + (player.size.y)
    local ww, wh = world.size.x, world.size.y
    local inx = (xa >= 0 and xa <= ww) and (xb >= 0 and xb <= ww)
    local iny = (ya >= 0 and ya <= wh) and (yb >= 0 and yb <= wh)
    if not (inx and iny) then return true end
  end
  -- TODO: on the future do a better collision algorithm, this WORKS but it's a bit too big.
  for _, tile in ipairs(world.tiles) do
    if tile.collide then
      -- NOTE: checking if the player collided with something using this, works fine for objects
      -- bigger than the player, but objects smaller, this algorithm fails.
      if tile.size.x < player.size.x and tile.size.y < player.size.y then
        -- For smaller objects, check if the object actually collides with the player.
        -- On large objects, it's better to just check if the player is colliding with the object.
        -- [[ NOTE: this is basically the opposite of the operation made below!! ]] --
        -- calculate the tile lines tatb and tctd for X and Y axis.
        local ta, tb = posx + 1, posx + (player.size.x - 1)
        local tc, td = posy + 1, posy + (player.size.y - 1)
        -- calculate the corners of the player.
        local xa, xb = tile.position.x, tile.position.x + tile.size.x
        local ya, yb = tile.position.y, tile.position.y + tile.size.y
        local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
        local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
        if cx and cy then return (return_object and tile or true) end
      else
        -- calculate the tile lines tatb and tctd for X and Y axis.
        local ta, tb = tile.position.x, tile.position.x + tile.size.x
        local tc, td = tile.position.y, tile.position.y + tile.size.y
        -- calculate the corners of the player.
        local xa, xb = posx + 1, posx + (player.size.x - 1)
        local ya, yb = posy + 1, posy + (player.size.y - 1)
        local cx = (xa >= ta and xa <= tb) or (xb >= ta and xb <= tb)
        local cy = (ya >= tc and ya <= td) or (yb >= tc and yb <= td)
        --local colliding = cx and cy
        --if colliding then return true end
        if cx and cy then return (return_object and tile or true) end
      end
    end
  end
  -- no the player is not colliding with anything.
  return false
end
module.Solar_TestPlayerCollisionAt = Solar_TestPlayerCollisionAt
function Solar_WalkPlayer(world, player, xdir, ydir)
  -- check for initial collision.
  local has_collision = Solar_TestPlayerCollisionAt(world, player, (player.abs_position.x + xdir), (player.abs_position.y + ydir))
  if has_collision then
    -- To prevent gaps and bad positioning of a walking, basically test for possible collisions and
    -- how much can we walk. This is obviously a not cheap process, specially if you have a speed of
    -- 200 pixels for frame, for example.
    if xdir ~= 0 then
      local can_walk = 0
      while true do
        if can_walk == xdir then break end
        local collided = Solar_TestPlayerCollisionAt(world, player, (player.abs_position.x + can_walk), player.abs_position.y)
        if collided then break end
        can_walk = can_walk + (xdir < 0 and - 1 or 1)
      end
      player.abs_position.x = player.abs_position.x + (can_walk == 0 and can_walk or ((can_walk < 0) and can_walk + 1 or can_walk - 1))
    end
    if ydir ~= 0 then
      local can_walk = 0
      while true do
        if can_walk == ydir then break end
        local collided = Solar_TestPlayerCollisionAt(world, player, player.abs_position.x, (player.abs_position.y + can_walk))
        if collided then break end
        can_walk = can_walk + (ydir < 0 and - 1 or 1)
      end
      -- NOTE: +1 or -1 of tolerance, because +1 is actually touching on the wall, locking the 
      -- player capacity of walking on the the opposite direction.
      player.abs_position.y = player.abs_position.y + (can_walk == 0 and can_walk or ((can_walk < 0) and can_walk + 1 or can_walk - 1))
    end
  else
    player.abs_position.x, player.abs_position.y = player.abs_position.x + xdir, player.abs_position.y + ydir
  end
end
module.Solar_WalkPlayer = Solar_WalkPlayer
function Solar_GetTile(world, tilegn)
  for _, tile in ipairs(world.tiles) do
    if tile.generic_name == tilegn then
      return tile
    end
  end
  --
  return nil
end
module.Solar_GetTile = Solar_GetTile
function Solar_SetTilePosition(world, tilegn, xpos, ypos)
  local tt = Solar_GetTile(world, tilegn)
  assert(tt, "no tile found: "..tilegn)
  tt.position.x = xpos
  tt.position.y = ypos
end
module.Solar_SetTilePosition = Solar_SetTilePosition

--[[ LOAD WORLD FILE ]]--
local function Solar_UnpackWorldInformation(tr)
  return  tr.name     or 'na',
          tr.refname  or 'na',
          tr.zindex   or 0,
          tr.xpos     or 0,
          tr.ypos     or 0,
          tr.width    or 0,
          tr.height   or 0,
          ((tr.collide == nil) and false or tr.collide)
end
function Solar_GenerateFloorWorld(engine, world, floor)
  --
  for line_count = 1, #floor.background do
    local line = floor.background[line_count]
    for line_index = 1, #line do
      local char = line:sub(line_index, line_index)
      -- ctr: current tile recipe. Each tile has a recipe in it.
      local ctr = floor[char]
      local tw, th = ctr.width, ctr.height
      local proto_tile = wtile.Solar_NewTile(Solar_UnpackWorldInformation(ctr))
      proto_tile.draw_using = (ctr.draw_using=='color' and consts.SOLAR_DRAW_USING_COLOR or consts.SOLAR_DRAW_USING_TEXTURE)
      proto_tile.color = utils.Solar_NewColor(unpack(ctr.color))
      proto_tile.position = utils.Solar_NewVectorXY(tw * (line_index - 1), th * (line_count - 1))
      -- TODO: implement texturing!
      Solar_InsertTileWorld(world, proto_tile, false)
    end
  end
  --
end
function Solar_SpawnTilesWorld(engine, world, tile)
  for _, tile_name in ipairs(tile.spawn) do
    if tile[tile_name] then
      local tile_data = tile[tile_name]
      local proto_tile = Solar_NewTile(Solar_UnpackWorldInformation(tile_data))
      proto_tile.draw_using = (tile_data.draw_using=='color' and consts.SOLAR_DRAW_USING_COLOR or consts.SOLAR_DRAW_USING_TEXTURE)
      proto_tile.color = utils.Solar_NewColor(unpack(tile_data.color))
      if tile_data["use_tile_alignment"] then
        proto_tile.position = utils.Solar_NewVectorXY(tile_data.xpos * world.tile_size.x, tile_data.ypos * world.tile_size.y)
      else proto_tile.position = utils.Solar_NewVectorXY(tile_data.xpos, tile_data.ypos) end
      --
      if tile_data["when_interaction"] then
        proto_tile.has_action = true
        proto_tile.when_interaction = Solar_NewCommand()
        Solar_TokenizeCommands(engine, proto_tile.when_interaction, tile_data.when_interaction)
      end
      Solar_InsertTileWorld(world, proto_tile)
      print("generated?")
    else
      -- TODO: crash INGAME.
      error("couldn't find tile: "..tile_name)
    end
  end
  --[[ SPAWN ]]--
end
function Solar_LoadWorld(engine, world_mode, file)
  local map_data = scf.SCF_LoadBuffer(storage.Solar_StorageLoadFile(engine.storage, "maps/"..file..".bc"), true)
  local ww, wh = map_data.geometry.width, map_data.geometry.height
  local tfw, tfh = map_data.geometry.floor_tile_width, map_data.geometry.floor_tile_height
  local proto_world = Solar_NewWorld(ww, wh, tfw, tfh)
  --
  Solar_GenerateFloorWorld(engine, proto_world, map_data.floor)
  Solar_SpawnTilesWorld(engine, proto_world, map_data.tiles)
  --
  Solar_SortTilesWorld(proto_world)
  --
  world_mode.current_world = 2
  table.insert(world_mode.worlds, proto_world)
end
module.Solar_LoadWorld = Solar_LoadWorld

--[[ INTERACTION ]]--
function Solar_AttemptInteraction(engine, world_mode, world)
  -- this is basically the same as WALK in a certain direction and check if we are colliding with
  -- something based on the player direction it is looking.
  local player = world_mode.player
  local test_directions = {
    [consts.SOLAR_PLAYER_LOOKING_UP]    ={0, -1},
    [consts.SOLAR_PLAYER_LOOKING_DOWN]  ={0,  1},
    [consts.SOLAR_PLAYER_LOOKING_LEFT]  ={-1, 0},
    [consts.SOLAR_PLAYER_LOOKING_RIGHT] ={ 1, 0}
  }
  local current_direction=test_directions[world_mode.player.looking_at]
  local has_collision = Solar_TestPlayerCollisionAt(world, player, (player.abs_position.x + current_direction[1]), (player.abs_position.y + current_direction[2]), true)
  if has_collision ~= false then
    Solar_ResetCommand(has_collision.when_interaction)
    has_collision.run_interaction = true
  end
end
module.Solar_AttemptInteraction = Solar_AttemptInteraction

--[[ TICK WORLD ]]--
function Solar_TickWorld(engine, world_mode, world)
  for _, tile in ipairs(world.tiles) do
    if tile.has_action then
      wtile.Solar_TickTile(engine, world_mode, world, tile)
    end
  end
end
module.Solar_TickWorld = Solar_TickWorld

--[[ DRAW WORLD ]]--
function Solar_DrawWorld(engine, world_mode, world)
  for _, tile in ipairs(world.tiles) do
    if tile.zindex == 1 and tile['is_player'] then
      wplayer.Solar_DrawPlayer(engine, world_mode, world_mode.player)
    else
      wtile.Solar_DrawTile(engine, world_mode, world, tile)
    end
  end
end
module.Solar_DrawWorld = Solar_DrawWorld
--
return module