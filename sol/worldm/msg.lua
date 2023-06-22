local sgen=require("sol.sgen")
local ui_frame    =require("sol.ui.frame")
local ui_label    =require("sol.ui.label")
local module={}
--
function module.Sol_NewMsgService(message)
  return sgen.Sol_BuildStruct({
    display             = ui_frame.Sol_NewFrame(),
    message_stack       = {},
    message_stack_index = 1,
    message_str_index   = 1,
  }, message or {})
end
function module.Sol_InitMsgService(engine, world_mode, msg_service)
  
end
function module.Sol_TickMsgService(engine, world_mode, msg_service)

end
function module.Sol_DrawMsgService(engine, world_mode, msg_service)

end
--
return module