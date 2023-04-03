local module = {}

local ui      = require("solar.ui")
local storage = require("solar.storage")
local utils   = require("solar.utils")
local consts  = require("solar.consts")
local terminal= require("solar.terminal")

local wworld = require("solar.worlds.world")

-- 
-- WorldMode
--
function Solar_NewWorldMode()
  return {
    worlds      = {}, current_world = 0,
    time_taken  = {},
    player      = Solar_NewPlayer(),
    terminal    = terminal.Solar_NewTerminal(),
    -- display.
    display     = nil,
    debug_frame = nil,
    debug_version_label = nil,
    debug_fps_label = nil,
    debug_system_info = nil,
    debug_system_gpu = nil,
    debug_labels = {},
    viewport = nil,
    command_runner = nil,
  }
end
module.Solar_NewWorldMode = Solar_NewWorldMode
function Solar_BuildUIWorldMode(engine, world_mode)
  world_mode.display = ui.Solar_NewDisplay("WorldDisplay", world_mode.viewport:getWidth(), world_mode.viewport:getHeight())
  --
  world_mode.debug_frame = ui.Solar_NewFrame("DebugFrame", false, 0, 0)
  ui.Solar_InsertElementDisplay(world_mode.display, world_mode.debug_frame)
  --
  local love_version = string.format("%d.%d.%d", love.getVersion())
  world_mode.debug_version_label = ui.Solar_NewLabel(
    "DebugVersionLabel", storage.Solar_StorageLoadFont(engine.storage, "normal", 14),
    string.format("Solar Engine: %s, LOVE: %s, LUA: %s", consts.SOLAR_VERSION, love_version, _VERSION),
    0, 0, false
  )
  world_mode.debug_version_label.use_background = true
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_version_label)
  --
  world_mode.debug_fps_label = ui.Solar_NewLabel(
    "DebugFpsLabel", storage.Solar_StorageLoadFont(engine.storage, "normal", 14),
    "...", 0, 3, false
  )
  world_mode.debug_fps_label.use_background = true
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_fps_label)
  --
  local name, version, vendor, device = love.graphics.getRendererInfo()
  local graphics_info = string.format("[%s: %s]", name, version)
  world_mode.debug_system_info = ui.Solar_NewLabel(
    "DebugSystemInfo", storage.Solar_StorageLoadFont(engine.storage, "normal", 14),
    string.format(storage.Solar_StorageGetText(engine.storage, "DEBUG_SYSTEM_INFO_LABEL"), love.system.getOS(), graphics_info),
    0, 6
  )
  world_mode.debug_system_info.use_background = true
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_system_info)
  --
  local system = (string.lower(love.system.getOS()) == 'linux') and utils.Solar_GetLinuxDistributor() or love.system.getOS()
  world_mode.debug_system_gpu = ui.Solar_NewLabel(
    "DebugSystemGPU", storage.Solar_StorageLoadFont(engine.storage, "normal", 14),
    -- string.format("System: %s, GPU: %s", system, device), 0, 9
    string.format(storage.Solar_StorageGetText(engine.storage, "DEBUG_SYSTEM_GPU_LABEL"), system, device), 0, 10
  )
  world_mode.debug_system_gpu.use_background = true
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_system_gpu)
  --
  local ypos = 80
  local font = storage.Solar_StorageLoadFont(engine.storage, "normal", 12)
  for index = 1, utils.Solar_TableGetNumberKeys(world_mode.time_taken) do
    world_mode.debug_labels[index] = ui.Solar_NewLabel(
      string.format("DebugLabel%d", index), storage.Solar_StorageLoadFont(engine.storage, "normal", 12),
      "offline...", 0, ypos, true
    )
    world_mode.debug_labels[index].use_background = true
    ypos = ypos + font:getHeight()
    ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_labels[index])
  end
  --
  world_mode.debug_memory = ui.Solar_NewProgress(
    "DebugMemory", math.floor(world_mode.viewport:getWidth()/4), 5, 100, 3, false
  )
  world_mode.debug_memory.background_color = utils.Solar_NewColor(207, 240, 137)
  world_mode.debug_memory.foreground_color = utils.Solar_NewColor(240, 137, 207)
  world_mode.debug_memory.max_progress = 100000
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_memory)
  --
  world_mode.debug_memory_label = ui.Solar_NewLabel(
    "DebugMemoryLabel", storage.Solar_StorageLoadFont(engine.storage, "normal", 14),
    "...", 100, 0, false
  )
  world_mode.debug_memory_label.use_background = true
  ui.Solar_InsertElementFrame(world_mode.debug_frame, world_mode.debug_memory_label)
end
function Solar_InitWorldMode(engine, world_mode)
  world_mode.viewport = love.graphics.newCanvas(engine.world_viewport.x, engine.world_viewport.y)
  world_mode.player.rel_position.x = math.floor(engine.world_viewport.x/2)-math.floor(consts.SOLAR_TEST_WORLD_TILE_WIDTH/2)
  world_mode.player.rel_position.y = math.floor(engine.world_viewport.y/2)-math.floor(consts.SOLAR_TEST_WORLD_TILE_HEIGHT/2)
  --
  world_mode.time_taken = {
    -- Tick Functions
    Solar_TickDisplay=0,
    Solar_KeyboardEventCheckWorldMode=0,
    Solar_TickWorld=0,
    Solar_TickTerminal=0,
    -- Drawing Functions
    Solar_DrawTerminal=0,
    Solar_DrawDisplay=0,
    Solar_DrawWorld=0,
  }
  --[[ build the UI ]]--
  Solar_BuildUIWorldMode(engine, world_mode)

  --[[ initialize the terminal ]]--
  terminal.Solar_InitTerminal(engine, world_mode.terminal, world_mode.display)

  --[[ build the testing world ]]--
  wworld.Solar_BuildTestingWorld(world_mode)
  
  --[[ TODO: this is for debug only! remove from the future releases. ]]--
  local niea_room = wworld.Solar_LoadWorld(engine, world_mode, "niea-room")
end
module.Solar_InitWorldMode = Solar_InitWorldMode
-- Utilities
function Solar_FixResolutionWorldMode(engine, world_mode, offsetx, offsety)
  world_mode.display.cursor.offset = utils.Solar_NewVectorXY(offsetx, offsety)
  world_mode.display.offset = utils.Solar_NewVectorXY(offsetx, offsety)
end
module.Solar_FixResolutionWorldMode = Solar_FixResolutionWorldMode

-- Tick functions
function Solar_KeyboardEventCheckWorldMode(engine, world_mode, current_world)
  if      love.keyboard.isDown(engine.world_keymap.walk_up) then
    wworld.Solar_WalkPlayer(current_world, world_mode.player, 0, -world_mode.player.speed)
    world_mode.player.looking_at = consts.SOLAR_PLAYER_LOOKING_UP
  elseif  love.keyboard.isDown(engine.world_keymap.walk_down) then
    wworld.Solar_WalkPlayer(current_world, world_mode.player, 0,  world_mode.player.speed)
    world_mode.player.looking_at = consts.SOLAR_PLAYER_LOOKING_DOWN
  elseif  love.keyboard.isDown(engine.world_keymap.walk_left) then
    wworld.Solar_WalkPlayer(current_world, world_mode.player, -world_mode.player.speed, 0)
    world_mode.player.looking_at = consts.SOLAR_PLAYER_LOOKING_LEFT
  elseif  love.keyboard.isDown(engine.world_keymap.walk_right) then
    wworld.Solar_WalkPlayer(current_world, world_mode.player,  world_mode.player.speed, 0)
    world_mode.player.looking_at = consts.SOLAR_PLAYER_LOOKING_RIGHT
  end
end
function Solar_TickDebugScreenWorldMode(engine, world_mode, current_world)
  --
  world_mode.debug_fps_label.text = string.format(
    "FPS: %d, (X: %d, Y: %d, Xr: %d, Yr: %d)", love.timer.getFPS(),
    world_mode.player.abs_position.x, world_mode.player.abs_position.y,
    world_mode.player.rel_position.x, world_mode.player.rel_position.y
  )
  --
  local times = {} for fn, v in pairs(world_mode.time_taken) do table.insert(times, {name=fn, tt=v}) end
  table.sort(times, function(a, b) return a.tt < b.tt end)
  for tindex, tc in ipairs(times) do
    if tindex > #world_mode.debug_labels then
      break
    else
      world_mode.debug_labels[tindex].text = "["..tostring(tindex).."]: \""..tc.name.."\" took: "..tostring(tc.tt * 1000)
    end
  end
  --
  local memory_amount = collectgarbage("count")
  world_mode.debug_memory.progress = memory_amount
  world_mode.debug_memory_label.text = tostring(memory_amount / 1000):sub(1, 4) .. "MB/100MB"
  --
end
function Solar_TickWorldMode(engine, world_mode)
  --
  local current_world = world_mode.worlds[world_mode.current_world]
  Solar_TickDebugScreenWorldMode(engine, world_mode, current_world)
  world_mode.time_taken["Solar_TickDisplay"]=utils.Solar_InvokeAndMeasureTime(ui.Solar_TickDisplay, world_mode.display)
  world_mode.time_taken["Solar_KeyboardEventCheckWorldMode"]=utils.Solar_InvokeAndMeasureTime(Solar_KeyboardEventCheckWorldMode, engine, world_mode, current_world)
  world_mode.time_taken["Solar_TickWorld"]=utils.Solar_InvokeAndMeasureTime(wworld.Solar_TickWorld, engine, world_mode, current_world)
end
module.Solar_TickWorldMode = Solar_TickWorldMode

-- Keypress function
function Solar_AttemptInteraction(engine, world_mode)
  local current_world = world_mode.worlds[world_mode.current_world]
  wworld.Solar_AttemptInteraction(engine, world_mode, current_world)
end
module.Solar_AttemptInteraction = Solar_AttemptInteraction
function Solar_KeypressWorldMode(engine, world_mode, key)
  if      key == "f3" then        world_mode.debug_frame.visible = not world_mode.debug_frame.visible
  elseif  key == "f4" then        world_mode.terminal.enabled = not world_mode.terminal.enabled
  elseif  key == "e" then         Solar_AttemptInteraction(engine, world_mode)
  end
  --[[ feed the terminal information ]]--
  terminal.Solar_KeypressedEventTerminal(engine, world_mode.terminal, key)
end
module.Solar_KeypressWorldMode = Solar_KeypressWorldMode

-- Draw functions
function Solar_DrawWorldMode(engine, world_mode)
  love.graphics.setCanvas(world_mode.viewport)
  love.graphics.clear(0, 0, 0)
    local current_world = world_mode.worlds[world_mode.current_world]
    world_mode.time_taken["Solar_DrawWorld"]=utils.Solar_InvokeAndMeasureTime(wworld.Solar_DrawWorld, engine, world_mode, current_world)
    world_mode.time_taken["Solar_DrawTerminal"]=utils.Solar_InvokeAndMeasureTime(terminal.Solar_DrawTerminal, engine, world_mode.terminal)
    world_mode.time_taken["Solar_DrawDisplay"]=utils.Solar_InvokeAndMeasureTime(ui.Solar_DrawDisplay, world_mode.display)
  love.graphics.setCanvas()
end
module.Solar_DrawWorldMode = Solar_DrawWorldMode

--
return module
