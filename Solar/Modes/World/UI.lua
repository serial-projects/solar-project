-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

local SM_Vector   = require("Solar.Math.Vector")
local SM_Color    = require("Solar.Math.Color")

local SS_Storage  = require("Solar.System.Storage")
local SD_Graphics = require("Solar.Draw.Graphics")
local SV_Defaults = require("Solar.Values.Defaults")
local SV_Consts   = require("Solar.Values.Consts")

local SUI_Display = require("Solar.UI.Display")
local SUI_Frame   = require("Solar.UI.Frame")
local SUI_Button  = require("Solar.UI.Button")
local SUI_Label   = require("Solar.UI.Label")


-- Sol_InitWorldModeGUI(engine: Sol_Engine, world_mode: Sol_WorldMode):
-- Generate the GUI for the World Mode.
function module.Sol_InitWorldModeGUI(engine, world_mode)
  local begun_initializing_gui= os.clock() ; dmsg("Sol_InitWorldModeGUI() was called!")
  local terminal_font         = SS_Storage.Sol_LoadFontFromStorage(engine.storage, "terminal", 14)
  local normal_font           = SS_Storage.Sol_LoadFontFromStorage(engine.storage, "normal", 12)
  local normal_title_font     = SS_Storage.Sol_LoadFontFromStorage(engine.storage, "normal", 24)
  world_mode.main_display     = SUI_Display.Sol_NewDisplay({size=engine.viewport_size})
  --> some "macros" for the UI
  local function _GenerateDebugUIGenericLabel() 
    return SUI_Label.Sol_NewLabel({font=terminal_font, color=SV_Consts.colors.white, has_background=true, background_color=SV_Consts.colors.black})
  end
  local function _GenerateExitFrameBackground()
    local newcanvas =love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
    SD_Graphics.Sol_GeneratePixelatedPatternUsingAlpha(newcanvas)
    return newcanvas
  end
  --> actions for the UI
  local function __display_exit_ui_yes_button_action()
    -- NOTE: make the game quit and save!
    love.event.quit(0)
  end
  local function __display_exit_ui_no_button_action()
    world_mode.display_exit_ui_frame.visible = false
    world_mode.do_world_tick = true
  end
  --> display_debug_ui: frame
  world_mode.display_debug_ui_frame=SUI_Frame.Sol_NewFrame()
    world_mode.display_debug_ui_frame_version_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_version_label.text=string.format(
        SS_Storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_DEBUG_UI_FRAME_VERSION_LABEL_TEXT"),
        SV_Defaults.SOL_VERSION,
        SV_Defaults.SOL_LOVE_MAJOR, SV_Defaults.SOL_LOVE_MINOR, SV_Defaults.SOL_LOVE_REVISION,
        _VERSION, _G["jit"]~=nil and "yes" or "no"
      )
      world_mode.display_debug_ui_frame_version_label.position        =SM_Vector.Sol_NewVector(0, 0)
      world_mode.display_debug_ui_frame_version_label.force_absolute  =false
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_version_label)
    world_mode.display_debug_ui_frame_memoryusage_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text  =SS_Storage.Sol_GetText(engine.storage, "WMODE_DISPLAY_DEBUG_UI_FRAME_MEMORYUSAGE_LABEL_TEXT")
      world_mode.display_debug_ui_frame_memoryusage_label.position            =SM_Vector.Sol_NewVector(100, 0)
      world_mode.display_debug_ui_frame_memoryusage_label.force_absolute      =false
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_memoryusage_label)
    world_mode.display_debug_ui_frame_playerpositionabs_label=_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_playerpositionabs_label.non_formatted_text  ="X: %d, Y: %d"
      world_mode.display_debug_ui_frame_playerpositionabs_label.position            =SM_Vector.Sol_NewVector(0, 100)
      world_mode.display_debug_ui_frame_playerpositionabs_label.force_absolute      =false
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_playerpositionabs_label)
    world_mode.display_debug_ui_frame_playerpositionrel_label                             =_GenerateDebugUIGenericLabel()
      world_mode.display_debug_ui_frame_playerpositionrel_label.non_formatted_text        ="RX: %d, RY: %d"
      world_mode.display_debug_ui_frame_playerpositionrel_label.position                  =SM_Vector.Sol_NewVector(50, 50)
      world_mode.display_debug_ui_frame_playerpositionrel_label.force_absolute            =false
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_debug_ui_frame, world_mode.display_debug_ui_frame_playerpositionrel_label)
  SUI_Display.Sol_InsertElement(world_mode.main_display, world_mode.display_debug_ui_frame)
  --> display_exit_ui_frame:
  world_mode.display_exit_ui_frame=SUI_Frame.Sol_NewFrame({enable_bg=true, bg_canvas=_GenerateExitFrameBackground()})
  world_mode.display_exit_ui_frame.visible=false
    world_mode.display_exit_ui_ask_label                =SUI_Label.Sol_NewLabel({font=normal_title_font, color=SV_Consts.colors.WHITE})
      world_mode.display_exit_ui_ask_label.position     =SM_Vector.Sol_NewVector(50, 30)
      world_mode.display_exit_ui_ask_label.color        =SM_Color.Sol_NewColor4(255, 255, 255)
      world_mode.display_exit_ui_ask_label.text         =SS_Storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_EXIT_UI_ASK_LABEL_TEXT")
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_ask_label)
    world_mode.display_exit_ui_yes_button=SUI_Button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_yes_button.background_color          =SM_Color.Sol_NewColor4(150, 150, 150, 100)
      world_mode.display_exit_ui_yes_button.background_hovering_color =SM_Color.Sol_NewColor4(150, 150, 150, 200)
      world_mode.display_exit_ui_yes_button.has_borders               =true
      world_mode.display_exit_ui_yes_button.border_color              =SM_Color.Sol_NewColor4(0, 0, 0)
      world_mode.display_exit_ui_yes_button.size                      =SM_Vector.Sol_NewVector(150, 30)
      world_mode.display_exit_ui_yes_button.position                  =SM_Vector.Sol_NewVector(20, 70)
      world_mode.display_exit_ui_yes_button.text                      =SS_Storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_YES_TEXT")
      world_mode.display_exit_ui_yes_button.force_absolute            =false
      world_mode.display_exit_ui_yes_button.when_left_click=__display_exit_ui_yes_button_action
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_yes_button)
    world_mode.display_exit_ui_no_button=SUI_Button.Sol_NewButton({font=normal_font})
      world_mode.display_exit_ui_no_button.background_color         =SM_Color.Sol_NewColor4(150, 150, 150, 100)
      world_mode.display_exit_ui_no_button.background_hovering_color=SM_Color.Sol_NewColor4(150, 150, 150, 200)
      world_mode.display_exit_ui_no_button.has_borders              =true
      world_mode.display_exit_ui_no_button.border_color             =SM_Color.Sol_NewColor4(0, 0, 0)
      world_mode.display_exit_ui_no_button.size                     =SM_Vector.Sol_NewVector(150, 30)
      world_mode.display_exit_ui_no_button.position                 =SM_Vector.Sol_NewVector(80, 70)
      world_mode.display_exit_ui_no_button.text                     =SS_Storage.Sol_GetText(engine.storage,"WMODE_DISPLAY_NO_TEXT")
      world_mode.display_exit_ui_no_button.force_absolute           =false
      world_mode.display_exit_ui_no_button.when_left_click=__display_exit_ui_no_button_action
    SUI_Frame.Sol_InsertElementInFrame(world_mode.display_exit_ui_frame, world_mode.display_exit_ui_no_button)
  SUI_Display.Sol_InsertElement(world_mode.main_display, world_mode.display_exit_ui_frame)
  --> display_inv_ui: frame
  dmsg("Sol_InitWorldModeGUI() finished building GAME UI at %fs", os.clock()-begun_initializing_gui)
end

--
return module