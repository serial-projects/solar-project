local smath=require("sol.smath")
local defaults=require("sol.defaults")
local storage = require("sol.storage")
local consts = require("sol.consts")
local graphics = require("sol.graphics")

local ui_display = require("sol.ui.display")
local ui_frame = require("sol.ui.frame")
local ui_button = require("sol.ui.button")
local ui_label = require("sol.ui.label")

local player=require("sol.worldm.player")
local world = require("sol.worldm.world")
local wload = require("sol.worldm.wload")

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
    do_world_tick = true,
    do_world_draw = true
  }
end

--[[ Quit Stuff ]]--
function module.Sol_QuitWorldMode(engine, world_mode)
  love.event.quit(0)
end

--[[ Init Stuff ]]--
function module.Sol_InitWorldModeGUI(engine, world_mode)
  local begun_initializing_gui=os.clock() ; dmsg("Sol_InitWorldModeGUI() was called!")
  local terminal_font=storage.Sol_LoadFontFromStorage(engine.storage, "terminal", 14)
  local normal_font         =storage.Sol_LoadFontFromStorage(engine.storage, "normal", 12)
  local normal_title_font   =storage.Sol_LoadFontFromStorage(engine.storage, "normal", 24)

  world_mode.main_display=ui_display.Sol_NewDisplay({size=engine.viewport_size})
  --> some "macros" for the UI
  local function _GenerateDebugUIGenericLabel() return ui_label.Sol_NewLabel({font=terminal_font, color=consts.colors.white, has_background=true, background_color=consts.colors.black}) end
  local function _GenerateExitFrameBackground()
    local newcanvas =love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
    graphics.Sol_GeneratePixelatedPatternUsingAlpha(newcanvas)
    return newcanvas
  end
  --> actions for the UI
  local function __display_exit_ui_yes_button_action()
    module.Sol_QuitWorldMode(engine, world_mode)
  end
  local function __display_exit_ui_no_button_action()
    world_mode.display_exit_ui_frame.visible=false
  end
  --> display_debug_ui: frame
  world_mode.display_debug_ui_frame=ui_frame.Sol_NewFrame()
    world_mode.display_debug_ui_frame_version_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_version_label.text=string.format(
        storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_DEBUG_UI_FRAME_VERSION_LABEL_TEXT"),
        defaults.SOL_VERSION,
        defaults.SOL_LOVE_MAJOR, defaults.SOL_LOVE_MINOR, defaults.SOL_LOVE_REVISION,
        _VERSION, _G["jit"]~=nil and "yes" or "no"
      )
      world_mode.display_debug_ui_frame_version_label.position=smath.Sol_NewVector(0, 0)
      world_mode.display_debug_ui_frame_version_label.force_absolute=false
    ui_frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_version_label)
    world_mode.display_debug_ui_frame_memoryusage_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text=storage.Sol_GetText(engine.storage, "WMODE_DISPLAY_DEBUG_UI_FRAME_MEMORYUSAGE_LABEL_TEXT")
      world_mode.display_debug_ui_frame_memoryusage_label.position=smath.Sol_NewVector(100, 0)
      world_mode.display_debug_ui_frame_memoryusage_label.force_absolute=false
    ui_frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_memoryusage_label)
  ui_display.Sol_InsertElement(world_mode.main_display, world_mode.display_debug_ui_frame)
  --> display_exit_ui_frame:
  world_mode.display_exit_ui_frame=ui_frame.Sol_NewFrame({enable_bg=true, bg_canvas=_GenerateExitFrameBackground()})
  world_mode.display_exit_ui_frame.visible=false
    world_mode.display_exit_ui_ask_label=ui_label.Sol_NewLabel({font=normal_title_font, color=consts.colors.WHITE})
      world_mode.display_exit_ui_ask_label.position=smath.Sol_NewVector(50, 30)
      world_mode.display_exit_ui_ask_label.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_EXIT_UI_ASK_LABEL_TEXT")
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_ask_label)
    world_mode.display_exit_ui_yes_button=ui_button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_yes_button.size=smath.Sol_NewVector(150, 40)
      world_mode.display_exit_ui_yes_button.position=smath.Sol_NewVector(20, 70)
      world_mode.display_exit_ui_yes_button.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_YES_TEXT")
      world_mode.display_exit_ui_yes_button.force_absolute=false
      world_mode.display_exit_ui_yes_button.when_left_click=__display_exit_ui_yes_button_action
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_yes_button)
    world_mode.display_exit_ui_no_button=ui_button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_no_button.size=smath.Sol_NewVector(150, 40)
      world_mode.display_exit_ui_no_button.position=smath.Sol_NewVector(80, 70)
      world_mode.display_exit_ui_no_button.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_NO_TEXT")
      world_mode.display_exit_ui_no_button.force_absolute=false
      world_mode.display_exit_ui_no_button.when_left_click=__display_exit_ui_no_button_action
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_no_button)
  ui_display.Sol_InsertElement(world_mode.main_display, world_mode.display_exit_ui_frame)
  --> display_inv_ui: frame
  dmsg("Sol_InitWorldModeGUI() finished building GAME UI at %fs", os.clock()-begun_initializing_gui)
end

function module.Sol_InitWorldMode(engine, world_mode)
  --> setup the viewport: the viewport does not resize (even if the window is resizable).
  world_mode.viewport=love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
  world_mode.viewport_size=engine.viewport_size
  module.Sol_InitWorldModeGUI(engine, world_mode)
  player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)

  --> incase no world is loaded, load the internal level called "niea-room"
  local proto_world=world.Sol_NewWorld()
  wload.Sol_LoadWorld(engine, world_mode, proto_world, "niea-room")
  world_mode.worlds["niea-room"]=proto_world
  world_mode.current_world="niea-room"
end

--[[ Tick Related Functions ]]
function module.Sol_TickWorldModeUI(engine, world_mode)
  --> update: world_mode.display_debug_ui_frame_memoryusage_label
  local amount_used_memory=tostring(collectgarbage("count") / 1000):sub(1, 4)
  world_mode.display_debug_ui_frame_memoryusage_label.text=string.format(world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text, amount_used_memory)
end

function module.Sol_TickWorldMode(engine, world_mode)
  module.Sol_TickWorldModeUI(engine, world_mode)
  ui_display.Sol_TickDisplay(world_mode.main_display)
  if world_mode.current_world and world_mode.do_world_tick then
    local current_world=world_mode.worlds[world_mode.current_world]
    world.Sol_TickWorld(engine, world_mode, current_world)
  end
end

function module.Sol_ResizeEventWorldMode(engine, world_mode)
  ui_display.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end

function module.Sol_KeypressEventWorld(engine, world_mode, key)
  local _keytable={
    ["f3"]  =function() 
      world_mode.display_debug_ui_frame.visible = not world_mode.display_debug_ui_frame.visible 
    end,
    ["escape"] =function()
      world_mode.display_exit_ui_frame.visible = true
      world_mode.do_world_tick = false
    end,
  }
  if _keytable[key] then _keytable[key]() end
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
  love.graphics.setCanvas(past_canva)
end

--
return module