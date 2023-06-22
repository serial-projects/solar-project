local sgen        =require("sol.sgen")
local graphics    =require("sol.graphics")
local smath       =require("sol.smath")
local storage     =require("sol.storage")

local ui_frame    =require("sol.ui.frame")
local ui_label    =require("sol.ui.label")
local ui_display  =require("sol.ui.display")

local module={}
--
function module.Sol_NewMsgService(message)
  return sgen.Sol_BuildStruct({
    base_frame          = ui_frame.Sol_NewFrame(),
    message_stack       = {},
    message_stack_index = 1,
    message_str_index   = 1,
    who_font            = "normal",
    text_font           = "normal"
  }, message or {})
end
function module.Sol_InitMsgService(engine, world_mode, msg_service)
  --
  local who_font        = storage.Sol_LoadFontFromStorage(engine.storage, "normal", 16)
  local text_font       = storage.Sol_LoadFontFromStorage(engine.storage, "normal", 14)
  --
  local MSGBOX_HEIGHT   =200
  local using_canva     =graphics.Sol_QuickGenerateCanva(smath.Sol_NewVector(world_mode.viewport:getWidth(), MSGBOX_HEIGHT), smath.Sol_NewColor4(100, 100, 100))
  msg_service.base_frame=ui_frame.Sol_NewFrame({
    enable_bg           =true,
    bg_canvas           =using_canva,
    bg_position         =smath.Sol_NewVector(0, world_mode.viewport_size.y - MSGBOX_HEIGHT),
    bg_size             =smath.Sol_NewVector(world_mode.viewport_size.x, MSGBOX_HEIGHT)
  })
    msg_service.base_frame_who_label=ui_label.Sol_NewLabel({font=who_font, text="N/A", color=smath.Sol_NewColor4(200, 200, 200)})
      msg_service.base_frame_who_label.position=smath.Sol_NewVector(10, 8)
      msg_service.base_frame_who_label.relative_to=msg_service.base_frame
    ui_frame.Sol_InsertElementInFrame(msg_service.base_frame, msg_service.base_frame_who_label)
  ui_display.Sol_InsertElement(world_mode.main_display, msg_service.base_frame)
  --
end
function module.Sol_TickMsgService(engine, world_mode, msg_service)

end
function module.Sol_DrawMsgService(engine, world_mode, msg_service)

end
--
return module