local smath   =require("sol.smath")
local defaults=require("sol.defaults")
local player  =require("sol.worldm.player")
local world   = require("sol.worldm.world")
local wui     =require("sol.worldm.wui")
local msg = require("sol.worldm.msg")

local ui_display = require("sol.ui.display")

-- local wload = require("sol.worldm.wload")

local module={}
--
function module.Sol_NewWorldMode()
  return {
    viewport        = nil,
    viewport_size   = nil,
    worlds          = {},
    current_world   = nil,
    main_display    = nil,
    player          = player.Sol_NewPlayer(),
    -- tick stage:
    tick_counter    = 0,
    do_world_tick   = true,
    -- draw stage:
    draw_counter    = 0,
    do_world_draw   = true,
    -- services:
    msg_service     = msg.Sol_NewMsgService()
  }
end

--[[ Quit Stuff ]]--
function module.Sol_QuitWorldMode(engine, world_mode)
  love.event.quit(0)
end

--[[ Init Stuff ]]--
function module.Sol_InitWorldMode(engine, world_mode)
  --> init the viewport:
  world_mode.viewport=love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
  world_mode.viewport_size=engine.viewport_size
  
  --> init the UI:
  wui.Sol_InitWorldModeGUI(engine, world_mode)

  --> init the MsgService:
  msg.Sol_InitMsgService(engine, world_mode, world_mode.msg_service)

  --> init the player:
  player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)

  --> incase no world is loaded, load the internal level called "niea-room"
  local proto_world = world.Sol_NewWorld()
  world.Sol_InitWorld(engine, world_mode, proto_world, "niea-room")
  world_mode.worlds["niea-room"], world_mode.current_world=proto_world, "niea-room"
end

--[[ Tick Related Functions ]]
function module.Sol_TickWorldModeUI(engine, world_mode)
  --> update: world_mode.display_debug_ui_frame_memoryusage_label
  local amount_used_memory=tostring(collectgarbage("count") / 1000):sub(1, 4)
  world_mode.display_debug_ui_frame_memoryusage_label.text=string.format(world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text, amount_used_memory)
  world_mode.display_debug_ui_frame_playerpositionabs_label.text=string.format(world_mode.display_debug_ui_frame_playerpositionabs_label.non_formatted_text, world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y)
  world_mode.display_debug_ui_frame_playerpositionrel_label.text=string.format(world_mode.display_debug_ui_frame_playerpositionrel_label.non_formatted_text, world_mode.player.rel_position.x, world_mode.player.rel_position.y)
end

function module.Sol_TickWorldMode(engine, world_mode)
  module.Sol_TickWorldModeUI(engine, world_mode)
  msg.Sol_TickMsgService(engine, world_mode, world_mode.msg_service)
  ui_display.Sol_TickDisplay(world_mode.main_display)
  if world_mode.current_world and world_mode.do_world_tick then
    local current_world=world_mode.worlds[world_mode.current_world]
    world.Sol_TickWorld(engine, world_mode, current_world)
  end
  world_mode.tick_counter = world_mode.tick_counter + 1
end

function module.Sol_ResizeEventWorldMode(engine, world_mode)
  ui_display.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end

function module.Sol_KeypressEventWorldMode(engine, world_mode, key)
  local _keytable={
    ["f3"]      =function()
      world_mode.display_debug_ui_frame.visible = not world_mode.display_debug_ui_frame.visible 
    end,
    ["escape"]  =function()
      world_mode.display_exit_ui_frame.visible = not world_mode.display_exit_ui_frame.visible
      world_mode.do_world_tick = not world_mode.do_world_tick
    end,
  }
  if _keytable[key] then _keytable[key]() end
  msg.Sol_KeypressMsgService(engine, world_mode, world_mode.msg_service, key)
  --
  if world_mode.current_world and world_mode.do_world_tick then
    local current_world=world_mode.worlds[world_mode.current_world]
    world.Sol_KeypressEventWorld(engine, world_mode, current_world, key)
  end
end

--[[ Draw Related Functions ]]
function module.Sol_DrawWorldMode(engine, world_mode)
  local past_canva=love.graphics.getCanvas()
  love.graphics.setCanvas(world_mode.viewport)
    love.graphics.clear(smath.Sol_TranslateColor(defaults.SOL_VIEWPORT_BACKGROUND))
    if world_mode.current_world and world_mode.do_world_draw then
      local current_world=world_mode.worlds[world_mode.current_world]
      if current_world then world.Sol_DrawWorld(engine, world_mode, current_world) end
    end
    ui_display.Sol_DrawDisplay(world_mode.main_display)
    msg.Sol_DrawMsgService(engine, world_mode, world_mode.msg_service)
  love.graphics.setCanvas(past_canva)
  world_mode.draw_counter = world_mode.draw_counter + 1
end

--
return module