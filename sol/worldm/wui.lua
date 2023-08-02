local module = {}

local storage   = require("sol.storage")
local defaults  = require("sol.defaults")
local consts    = require("sol.consts")
local graphics  = require("sol.graphics")
local smath     = require("sol.smath")

local ui_label  = require("sol.ui.label")
local ui_button = require("sol.ui.button")
local ui_frame  = require("sol.ui.frame")
local ui_display= require("sol.ui.display")

-- Sol_InitWorldModeGUI(engine: Sol_Engine, world_mode: Sol_WorldMode):
-- Generate the GUI for the World Mode.
function module.Sol_InitWorldModeGUI(engine, world_mode)
  local begun_initializing_gui= os.clock() ; dmsg("Sol_InitWorldModeGUI() was called!")
  local terminal_font         = storage.Sol_LoadFontFromStorage(engine.storage, "terminal", 14)
  local normal_font           = storage.Sol_LoadFontFromStorage(engine.storage, "normal", 12)
  local normal_title_font     = storage.Sol_LoadFontFromStorage(engine.storage, "normal", 24)
  world_mode.main_display     = ui_display.Sol_NewDisplay({size=engine.viewport_size})
  --> some "macros" for the UI
  local function _GenerateDebugUIGenericLabel() 
    return ui_label.Sol_NewLabel({font=terminal_font, color=consts.colors.white, has_background=true, background_color=consts.colors.black})
  end
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
    world_mode.display_exit_ui_frame.visible = false
    world_mode.do_world_tick = true
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
    world_mode.display_debug_ui_frame_playerpositionabs_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_playerpositionabs_label.non_formatted_text="X: %d, Y: %d"
      world_mode.display_debug_ui_frame_playerpositionabs_label.position=smath.Sol_NewVector(0, 100)
      world_mode.display_debug_ui_frame_playerpositionabs_label.force_absolute=false
    ui_frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_playerpositionabs_label)
    world_mode.display_debug_ui_frame_playerpositionrel_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_playerpositionrel_label.non_formatted_text="RX: %d, RY: %d"
      world_mode.display_debug_ui_frame_playerpositionrel_label.position=smath.Sol_NewVector(50, 50)
      world_mode.display_debug_ui_frame_playerpositionrel_label.force_absolute=false
    ui_frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_playerpositionrel_label)
  ui_display.Sol_InsertElement(world_mode.main_display, world_mode.display_debug_ui_frame)
  --> display_exit_ui_frame:
  world_mode.display_exit_ui_frame=ui_frame.Sol_NewFrame({enable_bg=true, bg_canvas=_GenerateExitFrameBackground()})
  world_mode.display_exit_ui_frame.visible=false
    world_mode.display_exit_ui_ask_label=ui_label.Sol_NewLabel({font=normal_title_font, color=consts.colors.WHITE})
      world_mode.display_exit_ui_ask_label.position=smath.Sol_NewVector(50, 30)
      world_mode.display_exit_ui_ask_label.color=smath.Sol_NewColor4(255, 255, 255)
      world_mode.display_exit_ui_ask_label.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_EXIT_UI_ASK_LABEL_TEXT")
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_ask_label)
    world_mode.display_exit_ui_yes_button=ui_button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_yes_button.background_color=smath.Sol_NewColor4(150, 150, 150, 100)
      world_mode.display_exit_ui_yes_button.background_hovering_color=smath.Sol_NewColor4(150, 150, 150, 200)
      world_mode.display_exit_ui_yes_button.has_borders=true
      world_mode.display_exit_ui_yes_button.border_color=smath.Sol_NewColor4(0, 0, 0)
      world_mode.display_exit_ui_yes_button.size=smath.Sol_NewVector(150, 30)
      world_mode.display_exit_ui_yes_button.position=smath.Sol_NewVector(20, 70)
      world_mode.display_exit_ui_yes_button.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_YES_TEXT")
      world_mode.display_exit_ui_yes_button.force_absolute=false
      world_mode.display_exit_ui_yes_button.when_left_click=__display_exit_ui_yes_button_action
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_yes_button)
    world_mode.display_exit_ui_no_button=ui_button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_no_button.background_color=smath.Sol_NewColor4(150, 150, 150, 100)
      world_mode.display_exit_ui_no_button.background_hovering_color=smath.Sol_NewColor4(150, 150, 150, 200)
      world_mode.display_exit_ui_no_button.has_borders=true
      world_mode.display_exit_ui_no_button.border_color=smath.Sol_NewColor4(0, 0, 0)
      world_mode.display_exit_ui_no_button.size=smath.Sol_NewVector(150, 30)
      world_mode.display_exit_ui_no_button.position=smath.Sol_NewVector(80, 70)
      world_mode.display_exit_ui_no_button.text=storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_NO_TEXT")
      world_mode.display_exit_ui_no_button.force_absolute=false
      world_mode.display_exit_ui_no_button.when_left_click=__display_exit_ui_no_button_action
    ui_frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_no_button)
  ui_display.Sol_InsertElement(world_mode.main_display, world_mode.display_exit_ui_frame)
  --> display_inv_ui: frame
  dmsg("Sol_InitWorldModeGUI() finished building GAME UI at %fs", os.clock()-begun_initializing_gui)
end

--
return module