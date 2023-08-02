local defaults=require("sol.defaults")
local consts=require("sol.consts")
local smath=require("sol.smath")
local wload= require("sol.worldm.wload")
local wscripts=require("sol.worldm.wscripts")
local wroutines=require("sol.worldm.wroutines")

-- world module:
local player=require("sol.worldm.player")
local tiles=require("sol.worldm.tiles")
local chunk=require("sol.worldm.chunk")

local module={}
--
function module.Sol_NewWorld(world)
  return {
    info={name="n/n", description="?"},
    --
    chunks      ={},
    routines    =wroutines.Sol_NewRoutineService(),
    scripts     =wscripts.Sol_NewScriptService(),
    --
    recipe_tiles        ={},
    recipe_geometry     ={},
    recipe_layers       ={},
    recipe_level        ={},
    recipe_player       ={},
    recipe_actions      ={},
    --
    bg_size=nil,
    bg_tile_size=nil,
    world_size=smath.Sol_NewVector(0, 0),
    enable_world_borders=true,
    tiles={{zindex=1, type="player"}},
  }
end

--[[ Init Related Functions ]]
function module.Sol_InitWorld(engine, world_mode, world, name)
  --> load the world primitives: geometry, level and player
  wload.Sol_LoadWorld(engine, world_mode, world, name)
end

--[[ Tick Related Functions ]]
function module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
  world_mode.player.current_speed = love.keyboard.isDown("lshift") and world_mode.player.run_speed or world_mode.player.walk_speed
  if      love.keyboard.isDown(engine.wmode_keymap["walk_up"])    then
    player.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.UP,   0, -world_mode.player.current_speed)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_down"])  then
    player.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.DOWN, 0,  world_mode.player.current_speed)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_left"])  then
    player.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.LEFT, -world_mode.player.current_speed, 0)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_right"]) then
    player .Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.RIGHT, world_mode.player.current_speed, 0)
  end
end

function module.Sol_TickWorld(engine, world_mode, world)
  wroutines.Sol_TickRoutineService(engine, world_mode, world, world.routines)
  module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
  wscripts.Sol_TickScriptService(world.scripts)
end

--[[ Keypress Event Related Functions ]]--

function module.Sol_DoInteractionInWorld(engine, world_mode, world, tile, interaction_recipe)
  -- NOTE: to prevent the element from triggering multiple stances of threads (aka. bouncy), we lock the file from
  -- interacting again. When the HALT instruction is called or the script finish, then unlock it.
  
  -- TODO: allow some scripts to run in a mode called "sattelite mode", on this mode, the script instance is not
  -- deleted from the script service when finished, it stays dormant until next interaction. This is very useful
  -- for tiles that need multiple interactions, for now, THE only way to do multiple interaction stuff is by using
  -- global variables (WHICH SHOULD ONLY BE USED FOR VERY IMPORTANT DATA AND NEED TO SAVE DATA!).
  interaction_recipe["when_finish"], tile.busy=(function(ir) tile.busy = false end), true
  wscripts.Sol_LoadScript(engine, world_mode, world, world.scripts, interaction_recipe)
end

function module.Sol_AttemptInteractionInWorld(engine, world_mode, world)
  -- TODO: on the future, make a RAY that hit some tile to check possible interactions.
  -- USING this method with env. PRECISE_WALK disabled MAY result in problems and less
  -- precise interactions.
  -- load all the tiles from the current chunk & load looking table:
  local current_chunk_tiles=chunk.Sol_GetChunksOrdered(engine, world_mode, world)
  local SOL_PLAYER_INTERACTION_RANGE=defaults.SOL_PLAYER_INTERACTION_RANGE
  local test_position={
    [consts.player_directions.UP]     =smath.Sol_NewVector(world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y-SOL_PLAYER_INTERACTION_RANGE),
    [consts.player_directions.DOWN]   =smath.Sol_NewVector(world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y+SOL_PLAYER_INTERACTION_RANGE),
    [consts.player_directions.LEFT]   =smath.Sol_NewVector(world_mode.player.rectangle.position.x-SOL_PLAYER_INTERACTION_RANGE, world_mode.player.rectangle.position.y),
    [consts.player_directions.RIGHT]  =smath.Sol_NewVector(world_mode.player.rectangle.position.x+SOL_PLAYER_INTERACTION_RANGE, world_mode.player.rectangle.position.y),
  }
  -- build the rectangle:
  local testing_rectangle=smath.Sol_NewRectangle(test_position[world_mode.player.looking_direction], world_mode.player.rectangle.size)
  -- begin reading the tiles in-search of possible interactions. ALSO, ignore '1' the player.
  for _, tile in ipairs(current_chunk_tiles) do
    if tile.target ~= 1 then
      local current_tile=world.tiles[tile.target]
      if current_tile.enable_interaction and not current_tile.busy then
        local has_collision=smath.Sol_TestRectangleCollision(testing_rectangle, current_tile.rectangle)
        -- dmsg("%s tile, %s enabled interaction.", current_tile.name, current_tile.enable_interaction and "yes" or "no")
        if has_collision then
          module.Sol_DoInteractionInWorld(engine, world_mode, world, current_tile, current_tile.when_interacted)
          break
        end
      end
    end
  end
end

-- Sol_KeypressEventWorld(engine, world_mode, world, key: string)
function module.Sol_KeypressEventWorld(engine, world_mode, world, key)
  if key == engine.wmode_keymap["interact"] then
    module.Sol_AttemptInteractionInWorld(engine, world_mode, world)
  end
end

--[[ Draw Related Functions ]]
function module.Sol_DrawWorld(engine, world_mode, world)
  --> determine the player current chunk + all the sorroundings tiles.
  wroutines.Sol_DrawRoutineService(engine, world_mode, world, world.routines)
  local draw_tile_queue = chunk.Sol_GetChunksOrdered(engine, world_mode, world)
  for _, tile in ipairs(draw_tile_queue) do
    if tile["type"] then
      player.Sol_DrawPlayer(engine, world_mode, world_mode.player)
    else
      tiles.Sol_DrawTile(engine, world_mode, world, world.tiles[tile.target])
    end
  end
end

--
return module