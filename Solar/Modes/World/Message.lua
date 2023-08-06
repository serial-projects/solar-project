-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SS_Storage    =require("Solar.System.Storage")
local SUI_Display   =require("Solar.UI.Display")
local SUI_Frame     =require("Solar.UI.Frame")
local SUI_Label     =require("Solar.UI.Label")
local SG_Structures =require("Solar.Codegen.Structures")
local SD_Canva      =require("Solar.Draw.Canva")
local SM_Vector     =require("Solar.Math.Vector")
local SM_Rectangle  =require("Solar.Math.Rectangle")
local SM_Color      =require("Solar.Math.Color")


local module={}
--
function module.Sol_NewMsgUnit(who, text, theming)
  return {who=who, text=text, theming=theming}
end
function module.Sol_NewMsgService(message)
  return SG_Structures.Sol_BuildStruct({
    base_frame          = SUI_Frame.Sol_NewFrame(),
    -- controls:
    trigger             = false,
    should_skip         = false,
    finished            = false,
    hold_key            = 1,
    -- message control:
    message_stack       = {},
    message_stack_index = 1,
    message_str_index   = 1,
    timing              = 0,
    current_speed       = 0.05,
    -- font configuration:
    who_font            = "normal",
    text_font           = "normal"
  }, message or {})
end
function module.Sol_InitMsgService(engine, world_mode, msg_service)
  --[[ :: build the UI :: ]]--
  local who_font        = SS_Storage.Sol_LoadFontFromStorage(engine.storage, "normal", 16)
  local MSGBOX_HEIGHT   = 200
  local using_canva     = SD_Canva.Sol_QuickGenerateCanva(
    SM_Vector.Sol_NewVector (world_mode.viewport:getWidth(), MSGBOX_HEIGHT),
    SM_Color.Sol_NewColor4  (10, 10, 10)
  )
  msg_service.base_frame= SUI_Frame.Sol_NewFrame({
    enable_bg   =true,
    bg_canvas   =using_canva,
    bg_position =SM_Vector.Sol_NewVector(0, world_mode.viewport_size.y - MSGBOX_HEIGHT),
    bg_size     =SM_Vector.Sol_NewVector(world_mode.viewport_size.x, MSGBOX_HEIGHT),
  })
  msg_service.base_frame.visible=false
    msg_service.base_frame_who_label=SUI_Label.Sol_NewLabel({font=who_font, text="N/A", color=SM_Color.Sol_NewColor4(200, 200, 200)})
      msg_service.base_frame_who_label.position=SM_Vector.Sol_NewVector(10, 8)
      msg_service.base_frame_who_label.relative_to=msg_service.base_frame
    SUI_Frame.Sol_InsertElementInFrame(msg_service.base_frame, msg_service.base_frame_who_label)
  SUI_Display.Sol_InsertElement(world_mode.main_display, msg_service.base_frame)
  --
end
function module.Sol_PrepareMsgService(msg_service)
  msg_service.message_stack_index,msg_service.message_str_index=1, 1
  msg_service.base_frame.visible=true
end
function module.Sol_KeypressMsgService(engine, world_mode, msg_service, key)
  msg_service.should_skip=(key == "space")
end
function module.Sol_TickMsgService(engine, world_mode, msg_service)
  --[[ :: set the visible :: ]]--
  if msg_service.finished and msg_service.should_skip then
    msg_service.base_frame.visible  =false
    msg_service.should_skip         =false
    msg_service.finished            =false
  end
  --
  if msg_service.base_frame.visible and not msg_service.finished then
    -- TODO: checking this MAY create a little bit of wasted potential, review this on the future.
    local _msglength=#msg_service.message_stack[msg_service.message_stack_index]["text"]
    if msg_service.timing <= os.clock() then
      msg_service.message_str_index=msg_service.message_str_index<_msglength and msg_service.message_str_index+1 or _msglength
      msg_service.timing=os.clock()+msg_service.current_speed
    end
    if msg_service.should_skip then
      -- keep going ... :
      if msg_service.message_str_index<_msglength then
        msg_service.message_str_index=_msglength
        msg_service.should_skip=false
      else
        if msg_service.message_stack_index+1<=#msg_service.message_stack then
          local msg_callback        =msg_service.message_stack[msg_service.message_stack_index]["callback"]
          if msg_callback then      msg_callback() end
          msg_service.message_stack_index, msg_service.message_str_index=msg_service.message_stack_index+1, 1
          msg_service.should_skip   =false
        else
          local msg_callback        =msg_service.message_stack[msg_service.message_stack_index]["callback"]
          if msg_callback then      msg_callback() end
          msg_service.finished=true
        end
      end
    end
  end
  --[[ :: unset the visible :: ]]--
  -- NOTE: if two scripts insert text in the same time, this may create a crash
  -- when the msg system is gonna read the invalid msg_stack (example, str_index > text length).
  if msg_service.trigger and not msg_service.base_frame.visible then
    module.Sol_PrepareMsgService(msg_service) ; msg_service.trigger=false
    dmsg("Sol_TickMsgService() is preparing for message exhibition!")
  elseif msg_service.trigger and msg_service.base_frame.visible then
    mwarn("MsgService is BUSY! this may crash the game... prepare yourself!")
  end
end
function module.Sol_DrawMsgService(engine, world_mode, msg_service)
  if msg_service.base_frame.visible then
    local current_msg=msg_service.message_stack[msg_service.message_stack_index]
    local msg_text    =current_msg["text"]
    local msg_who     =current_msg["who"]
    --
    msg_service.base_frame_who_label.text=msg_who
    --
    local text_font   =SS_Storage.Sol_LoadFontFromStorage(engine.storage, "normal", 16)
    local xmarginb    =msg_service.base_frame_who_label.rectangle.position.x
    local xmargine    =world_mode.viewport_size.x-xmarginb
    local yindex      =msg_service.base_frame_who_label.rectangle.position.y+40
    local xindex      =xmarginb
    local htext       =text_font:getHeight()
    --
    love.graphics.setFont   (text_font)
    love.graphics.setColor  (SM_Color.Sol_TranslateColor(SM_Color.Sol_NewColor4(255, 255, 255)))
    for index = 1, msg_service.message_str_index do
      local ch  =msg_text:sub(index,index)
      local chw =text_font:getWidth(ch)
      if xindex>xmargine then
        xindex=xmarginb
        yindex=(yindex+htext) + 2
      end
      --
      love.graphics.print(ch, xindex, yindex)
      xindex    =xindex+chw
    end
  end
end
--
return module