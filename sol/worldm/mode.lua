local smath=require("sol.smath")
local defaults=require("sol.defaults")
local ui = require("sol.ui")
local storage = require("sol.storage")
local consts = require("sol.consts")
local testing = require("sol.testing")

local player=require("sol.worldm.player")
local world = require("sol.worldm.world")

local module={}
--
function Sol_NewWorldMode()
  return {
    viewport = nil,
    viewport_size = nil,
    worlds = {},
    current_world = nil,
    main_display = nil,
    player = player.Sol_NewPlayer(),
  }
end
module.Sol_NewWorldMode=Sol_NewWorldMode
function Sol_InitWorldModeGUI(engine, world_mode)
  local begun_initializing_gui=os.clock() ; dmsg("Sol_InitWorldModeGUI() was called!")
  local normal_font=storage.Sol_LoadFontFromStorage(engine.storage, "terminal", 14)
  world_mode.main_display=ui.Sol_NewDisplay({size=engine.viewport_size})
  --> some "macros" for the UI
  local function _GenerateDebugUIGenericLabel() return ui.Sol_NewLabel({font=normal_font, color=consts.colors.white, has_background=true, background_color=consts.colors.black}) end

  --> display_debug_ui: frame
    world_mode.display_debug_ui_frame=ui.Sol_NewFrame()
      world_mode.display_debug_ui_frame_version_label=_GenerateDebugUIGenericLabel()
        world_mode.display_debug_ui_frame_version_label.text=string.format(
          storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_DEBUG_UI_FRAME_VERSION_LABEL_TEXT"),
          defaults.SOL_VERSION,
          defaults.SOL_LOVE_MAJOR, defaults.SOL_LOVE_MINOR, defaults.SOL_LOVE_REVISION,
          _VERSION, _G["jit"]~=nil and "yes" or "no"
        )
        world_mode.display_debug_ui_frame_version_label.position=smath.Sol_NewVector(0, 0)
        world_mode.display_debug_ui_frame_version_label.force_absolute=false
        ui.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_version_label)
      world_mode.display_debug_ui_frame_memoryusage_label=_GenerateDebugUIGenericLabel()
        world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text=storage.Sol_GetText(engine.storage, "WMODE_DISPLAY_DEBUG_UI_FRAME_MEMORYUSAGE_LABEL_TEXT")
        world_mode.display_debug_ui_frame_memoryusage_label.position=smath.Sol_NewVector(100, 0)
        world_mode.display_debug_ui_frame_memoryusage_label.force_absolute=false
        ui.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_memoryusage_label)
    ui.Sol_InsertElement(world_mode.main_display, world_mode.display_debug_ui_frame)
  --> display_inv_ui: frame
  dmsg("Sol_InitWorldModeGUI() finished building GAME UI at %fs", os.clock()-begun_initializing_gui)
end
function Sol_InitWorldMode(engine, world_mode)
  --> setup the viewport: the viewport does not resize (even if the window is resizable).
  world_mode.viewport=love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
  world_mode.viewport_size=engine.viewport_size
  Sol_InitWorldModeGUI(engine, world_mode)
  player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)

  --> in-case no world is loaded, load the internal level called "niea-room"
  local proto_world=world.Sol_NewWorld()
  world.Sol_LoadWorld(engine, world_mode, proto_world, "niea-room")
  world_mode.worlds["niea-room"]=proto_world
  world_mode.current_world="niea-room"
end ; module.Sol_InitWorldMode=Sol_InitWorldMode

--[[ Tick Related Functions ]]
function Sol_TickWorldModeUI(engine, world_mode)
  --> update: world_mode.display_debug_ui_frame_memoryusage_label
  local amount_used_memory=tostring(collectgarbage("count") / 1000):sub(1, 4)
  world_mode.display_debug_ui_frame_memoryusage_label.text=string.format(world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text, amount_used_memory)
end
function Sol_TickWorldMode(engine, world_mode)
  Sol_TickWorldModeUI(engine, world_mode)
  ui.Sol_TickDisplay(world_mode.main_display)
  if world_mode.current_world then
    local current_world=world_mode.worlds[world_mode.current_world]
    world.Sol_TickWorld(engine, world_mode, current_world)
  end
end ; module.Sol_TickWorldMode=Sol_TickWorldMode
function Sol_ResizeEventWorldMode(engine, world_mode)
  ui.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end ; module.Sol_ResizeEventWorldMode=Sol_ResizeEventWorldMode
function Sol_KeypressEventWorld(engine, world_mode, key)
  if key == "f3" then
    world_mode.display_debug_ui_frame.visible = not world_mode.display_debug_ui_frame.visible
  end
end ; module.Sol_KeypressEventWorld=Sol_KeypressEventWorld

--[[ Draw Related Functions ]]
function Sol_DrawWorldMode(engine, world_mode)
  local past_canva=love.graphics.getCanvas()
  love.graphics.setCanvas(world_mode.viewport)
    love.graphics.clear(smath.Sol_TranslateColor(defaults.SOL_VIEWPORT_BACKGROUND))
    if world_mode.current_world then
      local current_world=world_mode.worlds[world_mode.current_world]
      if current_world then world.Sol_DrawWorld(engine, world_mode, current_world) end
    end
    ui.Sol_DrawDisplay(world_mode.main_display)
  love.graphics.setCanvas(past_canva)
end
module.Sol_DrawWorldMode=Sol_DrawWorldMode
--
return module