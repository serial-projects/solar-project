local defaults=require("sol.defaults")
local consts=require("sol.consts")
local smath=require("sol.smath")
local wload= require("sol.worldm.wload")

-- world module:
local player=require("sol.worldm.player")
local tiles=require("sol.worldm.tiles")
local chunk=require("sol.worldm.chunk")

-- ssen module:
local ssen_interpreter=require("sol.ssen.interpreter")

local module={}
--
function module.Sol_NewWorld(world)
  return {
    info={name="n/n", description="?"},
    --
    chunks      ={},
    routines    ={},
    scripts     ={},
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
function module.Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition)
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
end

function module.Sol_WalkInWorld(engine, world_mode, world, looking_direction, xdirection, ydirection)
  -- TODO: check when the player is running more efficiently by using a function argument or something else.
  world_mode.player.looking_direction=looking_direction
  world_mode.player.draw.counter = world_mode.player.draw.counter + (world_mode.player.current_speed == world_mode.player.walk_speed and world_mode.player.walk_speed_texture_counter_add or world_mode.player.run_speed_texture_counter_add)
  -- TODO: make more precise movements.
  local xposition, yposition=world_mode.player.rectangle.position.x+xdirection, world_mode.player.rectangle.position.y+ydirection
  if module.Sol_CheckPlayerPositionAt(engine, world_mode, world, xposition, yposition) then
    world_mode.player.rectangle.position.x=world_mode.player.rectangle.position.x+xdirection
    world_mode.player.rectangle.position.y=world_mode.player.rectangle.position.y+ydirection
  else
    -- NOTE: PRECISE_WALK is KINDA a very expansive function, use it with very caution!
    if engine.vars["PRECISE_WALK"] then
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
  end
end

function module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
  world_mode.player.current_speed = love.keyboard.isDown("lshift") and world_mode.player.run_speed or world_mode.player.walk_speed
  if      love.keyboard.isDown(engine.wmode_keymap["walk_up"])    then
    module.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.UP,   0, -world_mode.player.current_speed)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_down"])  then
    module.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.DOWN, 0,  world_mode.player.current_speed)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_left"])  then
    module.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.LEFT, -world_mode.player.current_speed, 0)
  elseif  love.keyboard.isDown(engine.wmode_keymap["walk_right"]) then
    module.Sol_WalkInWorld(engine, world_mode, world, consts.player_directions.RIGHT, world_mode.player.current_speed, 0)
  end
end

function module.Sol_DoWorldRoutines(engine, world_mode, world)
  if #world.routines > 0 then
    for routine_index = 1, #world.routines do
      local routine = world.routines[routine_index]
      local wrap    = routine.wrap[routine.status]
      if type(wrap) == "function" then
        routine.status = wrap(engine, world_mode, world, routine)
      end
      if routine.status == consts.routine_status.FINISHED or routine.status == consts.routine_status.DIED then
        dmsg("routine %s was deleted, last status: %d", routine.name, routine.status)
        world.routines[routine_index]=nil
      end
    end
  end
end

function module.Sol_DoScripts(engine, world_mode, world)
  local function _run(instance, n_ticks)
    local ir_code = 0
    for _ = 1, n_ticks do
      ir_code = ssen_interpreter.SSEN_TickIntepreter(instance)
      if ir_code == ssen_interpreter.SSEN_Status.FINISHED or ir_code == ssen_interpreter.SSEN_Status.DIED then
        break
      end
    end
    return ir_code
  end
  if #world.scripts > 0 then
    for ir_index = 1, #world.scripts do
      local script  = world.scripts[ir_index]
      local ir_code = _run(script.instance, script.priority)
      if ir_code == ssen_interpreter.SSEN_Status.FINISHED then
        dmsg("script %s is finished!", script.name)
        world.scripts[ir_index]=nil
      elseif ir_code == ssen_interpreter.SSEN_Status.DIED then
        stopexec(string.format("script %s DIED! (ir.fail: %s)", script.name, script.instance.fail))
        world.scripts[ir_index]=nil
      end
    end
  end
end

function module.Sol_TickWorld(engine, world_mode, world)
  module.Sol_CheckSingleDirectionWalking(engine, world_mode, world)
  module.Sol_DoWorldRoutines(engine, world_mode, world)
  module.Sol_DoScripts(engine, world_mode, world)
end

--[[ Draw Related Functions ]]
function module.Sol_DrawWorld(engine, world_mode, world)
  --> determine the player current chunk + all the sorroundings tiles.
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