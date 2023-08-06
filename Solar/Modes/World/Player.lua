-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SM_Vector   = require("Solar.Math.Vector")
local SM_Rectangle= require("Solar.Math.Rectangle")
local SWM_Chunk   = require("Solar.Modes.World.Chunk")
local SD_Recipe   = require("Solar.Draw.Recipe")
local SV_Defaults = require("Solar.Values.Defaults")
local SV_Consts   = require("Solar.Values.Consts")

local module={}

--
function module.Sol_NewPlayer()
  return {
    type                      = "player",
    name                      = "player",
    inventory                 = {},
    pets                      = {},
    walk_speed                      = 4,
    walk_speed_texture_counter_add  = 0.1,
    run_speed                       = 8,
    run_speed_texture_counter_add   = 0.5,
    current_speed             = 0,
    looking_direction         = SV_Consts.player_directions.DOWN,
    draw                      = nil,
    rel_position              = SM_Vector.Sol_NewVector(0, 0),
    rectangle                 = SM_Rectangle.Sol_NewRectangle(nil, SV_Defaults.SOL_PLAYER_SIZE),
  }
end

--[[ Tick Related Functions ]]--

-- Sol_LoadPlayerRelativePosition(world_mode: Sol_WorldMode, player: Sol_Player):
-- Calculates the relative position of the player based on the center of the screen.
function module.Sol_LoadPlayerRelativePosition(world_mode, player)
  player.rel_position.x=math.floor(world_mode.viewport_size.x/2)-math.floor(player.rectangle.size.x/2)
  player.rel_position.y=math.floor(world_mode.viewport_size.y/2)-math.floor(player.rectangle.size.y/2)
  dmsg("Sol_LoadPlayerRelativePosition() set the player.rel_position to x = %d and y = %d", player.rel_position.x, player.rel_position.y)
end

-- Sol_CheckPlayerPositionAt(engine: Sol_Engine, world_mode: Sol_WorldMode, world: Sol_World, xposition: number, yposition: number) -> good: boolean:
-- Check if the player is colliding with something at certain position. This function will not return the object colliding, only
-- if there is something the player is colliding with. ALSO, this function checks if the player is within the world borders (in
-- case the world borders are enabled, case not, this function will skip the checkup).
function module.Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition)
  --> setup the testing rectangle.
  local player_rectangle=SM_Rectangle.Sol_CloneRectangle(world_mode.player.rectangle)
  player_rectangle.position.x=xposition
  player_rectangle.position.y=yposition
  --> check if the player is inside the world borders.
  if world.enable_world_borders then
    local inside_x=player_rectangle.position.x>=0 and player_rectangle.position.x<=world.world_size.x
    local inside_y=player_rectangle.position.y>=0 and player_rectangle.position.y<=world.world_size.y
    if not (inside_x and inside_y) then return false end
  end
  --> check the player current chunk.
  local cpx, cpy      = SWM_Chunk.Sol_GetPlayerCurrentChunk(world_mode, world)
  local tiles_to_test = SWM_Chunk.Sol_GetChunksReferencedTiles(world, cpx, cpy, 1)
  for _, tiles_referenced in ipairs(tiles_to_test) do
    local tile_selected = world.tiles[tiles_referenced]
    if tile_selected.collide then
      if SM_Rectangle.Sol_TestRectangleCollision(player_rectangle, tile_selected.rectangle) then return false end
    end
  end
  return true
end

-- __Sol_DoPreciseWalk(engine: Sol_Engine, world_mode: Sol_WorldMode, world: Sol_World, xdirection: number, ydirection: number):
-- A "precise walk" is basically a walk where is tested how much the player can walk before hitting a wall, this is done when we
-- have a possible collision but want to find out how much is it far from happen. Without the precise walk, there will be gaps 
-- with the player position.
local function __Sol_DoPreciseWalk(engine, world_mode, world, xdirection, ydirection)
  --> for xdirection
  if xdirection ~= 0 then
    local x_amount=0
    while (xdirection < 0 and x_amount >= xdirection or x_amount <= xdirection) do
      if not module.Sol_CheckPlayerPositionAt(engine, world_mode, world, world_mode.player.rectangle.position.x+x_amount, world_mode.player.rectangle.position.y) then
        break
      else x_amount=x_amount+(xdirection < 0 and -1 or 1) end
    end
    -- we remove -1 amount of walking to ignore the last collision we made to check if the player is actually colliding with
    -- something, if no remove the player will be stuck in some wall. We could have put this inside the loop.
    world_mode.player.rectangle.position.x=world_mode.player.rectangle.position.x+(xdirection < 0 and x_amount + 1 or x_amount - 1)
  end
  --> for ydirection
  if ydirection ~= 0 then
    local y_amount=0
    while (ydirection < 0 and y_amount >= ydirection or y_amount <= ydirection) do
      if not module.Sol_CheckPlayerPositionAt(engine, world_mode, world, world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y+y_amount) then
        break
      else y_amount=y_amount+(ydirection < 0 and -1 or 1) end
    end
    world_mode.player.rectangle.position.y=world_mode.player.rectangle.position.y+(ydirection < 0 and y_amount + 1 or y_amount - 1)
  end
  --> (...)
end

-- Sol_WalkInWorld(engine, world_mode, world, looking_direction: number, xdirection: number, ydirection: number):
-- Walk the player to a certain direction (if possible).
function module.Sol_WalkInWorld(engine, world_mode, world, looking_direction, xdirection, ydirection)
  -- TODO: check when the player is running more efficiently by using a function argument or something else.
  world_mode.player.looking_direction =looking_direction
  world_mode.player.draw.counter      = world_mode.player.draw.counter + (world_mode.player.current_speed == world_mode.player.walk_speed and world_mode.player.walk_speed_texture_counter_add or world_mode.player.run_speed_texture_counter_add)
  -- TODO: make more precise movements.
  local xposition, yposition=world_mode.player.rectangle.position.x+xdirection, world_mode.player.rectangle.position.y+ydirection
  if module.Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition) then
    world_mode.player.rectangle.position.x=world_mode.player.rectangle.position.x+xdirection
    world_mode.player.rectangle.position.y=world_mode.player.rectangle.position.y+ydirection
  else
    -- NOTE: PRECISE_WALK is KINDA a very expansive function, use it with very caution!
    if engine.vars["PRECISE_WALK"] then
      __Sol_DoPreciseWalk(engine, world_mode, world, xdirection, ydirection)
    end
  end
end

--[[ Draw Related Functions ]]--

-- Sol_DrawPlayer(engine, world_mode, player):
-- Draw the player on the screen.
function module.Sol_DrawPlayer(engine, world_mode, player)
  local posx, posy    = SM_Vector.Sol_UnpackVectorXY(player.rel_position)
  local width, height = SM_Vector.Sol_UnpackVectorXY(player.rectangle.size)
  player.draw.using_recipe = player.looking_direction
  SD_Recipe.Sol_DrawRecipe(engine, player.draw, posx, posy, width, height)
end

--
return module