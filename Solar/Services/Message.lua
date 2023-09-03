local module = {}
local SS_Storage  = require("Solar.System.Storage")
local SC_Functional = require("Solar.Code.Functional")
local SV_Consts   = require("Solar.Values.Consts")

local SM_Color    = require("Solar.Math.Color")
local SM_Vector   = require("Solar.Math.Vector")

local SD_Canvas = require("Solar.Draw.Canva")

local SUI_Display = require("Solar.UI.Display")
local SUI_Frame   = require("Solar.UI.Frame")
local SUI_Label   = require("Solar.UI.Label")
local SUI_Button  = require("Solar.UI.Button")
--

-- MSG_TYPE: there are several types of messages:
-- TODO: add YESNOASK and ASK.
module.MSG_TYPE = table.enum(1, {"DIALOG", "FULLSCR_MSG", "YESNOASK", "ASK"})

-- Sol_NewDialogForm(): new dialog form.
function module.Sol_NewDialogForm(recipe)
  return table.structure({
    form_type     = module.MSG_TYPE.DIALOG,
    who           = "???",
    text          = "...",
    font          = "normal",
    size          = 14,
    speed         = 0.05,
    color         = SM_Color.Sol_NewColor4(250, 250, 250),
    background    = SM_Color.Sol_NewColor4(10, 10, 10),
    xpadding      = 25,
    ypadding      = 40,
    callback      = 0
  }, recipe or {})
end
local function Sol_TickDialogForm(message_service, dialog_form)
  -- NOTE: the behaviour is the following: 
  -- * when the player clicks the space bar, there are two branches can happen:
  -- * 1° branch: when the message is not yet finished of being displayed, the
  -- * action is just to finish the message instantly.
  -- * 2° branch: when the message has finished showing, the branch will only
  -- * increment the stack and show the next message.
  if message_service.space_pressed then
    -- when: space is pressed and the message has already finished showing.
    if message_service.waiting_player_click_space then
      SC_Functional.Sol_AttemptInvokeFunction(dialog_form.callback)
      message_service.waiting_player_click_space = false
      message_service.message_index = 1
      message_service.stack_index = message_service.stack_index + 1
    -- when: space is pressed but the message has not finished showing.
    else
      message_service.message_index = #dialog_form.text
    end
    -- NOTE: remove possible bouncy effect.
    message_service.space_pressed = false
    return
  end
  -- when: the message index is larger or the same size as the dialog text.
  if message_service.message_index >= #dialog_form.text then
    message_service.waiting_player_click_space = true
  -- when: still message to be shown on the screen.
  else
    if os.clock() > message_service.message_index_timing then
      message_service.message_index = message_service.message_index + 1
      message_service.message_index_timing = os.clock() + dialog_form.speed
    end
  end
end
local function Sol_DrawDialogForm(engine, message_service, dialog_form)
  -- NOTE: load the frame to show the dialog form.
  if not message_service.dialog_frame.visible then
    message_service.dialog_frame.visible = true
  end
  -- load the who:
  message_service.dialog_frame_who_label.text = dialog_form.who
  -- load the font & begin calculating the x position and y position:
  local using_font = SS_Storage.Sol_LoadFontFromStorage(engine.storage, dialog_form.font, dialog_form.size)
  love.graphics.setFont(using_font)
  local xbegin,   ybegin    = message_service.dialog_frame_position.x + dialog_form.xpadding, message_service.dialog_frame_position.y + dialog_form.ypadding
  local xindex,   yindex    = xbegin, ybegin
  local xmargin,  ymargin   = message_service.dialog_frame_size.x - dialog_form.xpadding, math.huge
  local height              = using_font:getHeight()
  local substring           = dialog_form.text:sub(1, message_service.message_index)
  for index = 1, #substring do
    local character = substring:sub(index, index)
    if xindex >= xmargin then
      yindex = yindex + height
      xindex = xbegin
    end
    love.graphics.print(character, xindex, yindex)
    xindex = xindex + using_font:getWidth(character)
  end
end

-- Sol_NewFullScrMsgForm(recipe): new full screen message.
function module.Sol_NewFullScrMsgForm(recipe)
  return table.structure({
    form_type     = msg.MSG_TYPE.FULLSCR_MSG,
    text          = "...",
    font          = "normal",
    size          = 12,
    speed         = 0.1,
    color         = SM_Color.Sol_NewColor4(250, 250, 250),
    background    = SM_Color.Sol_NewColor4(10, 10, 10, 100),
    callback      = 0
  }, recipe or {})
end

-- Sol_YesNoForm(recipe): new yes or no message.
function module.Sol_YesNoForm(recipe)
  return table.structure({
    form_type     = module.MSG_TYPE.YESNOASK,
    who           = "???",
    text          = "...",
    font          = "normal",
    size          = 12,
    speed         = 0.1,
    color         = SM_Color.Sol_NewColor4(250, 250, 250),
    background    = SM_Color.Sol_NewColor4(10, 10, 10, 100),
    -- TODO: add forms to customize this.
    yes_text      = "1",
    no_text       = "2",
    callback_yes  = 0,
    callback_no   = 0,
  }, recipe or {})
end

-- Sol_NewMessageService()
function module.Sol_NewMessageService()
  return {
    -- stack: contains the messages & it forms.
    stack         = {},
    stack_index   = 1,
    -- message:
    message_index = 1,
    message_index_timing = 0,
    waiting_player_click_space = false,
    should_initialize = false,
    running = false,
    space_pressed = false,
    past_mode = 0,
    -- frames: contains all the UI the frame.
    dialog_frame = 0,
    dialog_frame_size = SM_Vector.Sol_NewVector(0, 0),
    dialog_frame_position = SM_Vector.Sol_NewVector(0, 0),
    dialog_frame_who_label = 0,
    fullscrmsg_frame  = 0
  }
end

-- Sol_InitMessageService(message_service: Sol_MessageService, base_display: Sol_Display):
function module.Sol_InitMessageService(engine, message_service, base_display)
  -- initialize dialog frame:
  local dialog_frame_width  = engine.viewport_size.x
  local dialog_frame_height = math.floor(engine.viewport_size.y / 4)
  message_service.dialog_frame_size = SM_Vector.Sol_NewVector(dialog_frame_width, dialog_frame_height)
  message_service.dialog_frame_position = SM_Vector.Sol_NewVector(0, engine.viewport_size.y - dialog_frame_height)
  local empty_canvas        = SD_Canvas.Sol_QuickGenerateCanva(SM_Vector.Sol_NewVector(dialog_frame_width, dialog_frame_height), SV_Consts.colors.black)
  local canva_default_pos   = SM_Vector.Sol_NewVector(0, engine.viewport_size.y - dialog_frame_height)
  message_service.dialog_frame = SUI_Frame.Sol_NewFrame({enable_bg = true, bg_canvas = empty_canvas, bg_position = canva_default_pos, visible = false })
  -- initialize the dialog frame item: dialog_frame_who_label
  local default_font        = SS_Storage.Sol_LoadFontFromStorage(engine.storage, "normal", 16)
  message_service.dialog_frame_who_label = SUI_Label.Sol_NewLabel({ text = "???", font = default_font, color = SV_Consts.colors.white })
  message_service.dialog_frame_who_label.force_absolute = true
  message_service.dialog_frame_who_label.position = SM_Vector.Sol_NewVector(25, engine.viewport_size.y - dialog_frame_height + 10)
  SUI_Frame.Sol_InsertElementInFrame(message_service.dialog_frame, message_service.dialog_frame_who_label)
  -- finalize:
  SUI_Display.Sol_InsertElement(base_display, message_service.dialog_frame)
end

--::::::::::::::::::::::::::::::::--
--[[ :: Tick Message Service :: ]]--
--::::::::::::::::::::::::::::::::--

local assign_wrapper_tick_draw_operations = {
  [module.MSG_TYPE.DIALOG] = { tick = Sol_TickDialogForm, draw = Sol_DrawDialogForm }
}
local function Sol_HideAllUI(message_service)
  dmsg("bruh")
  message_service.dialog_frame.visible = false
end
local function Sol_TickMessageService(message_service)
  -- when: no message index, set to no running and close all the UI.
  if message_service.stack_index > #message_service.stack then
    message_service.running = false
    Sol_HideAllUI(message_service)
  else
    -- when: did the form_type change? if yes, then, change the type.
    -- TODO: remove flickering by not disabling the current UI.
    local current_form = message_service.stack[message_service.stack_index]
    if message_service.past_mode ~= current_form.form_type then
      Sol_HideAllUI(message_service)
    end
    assign_wrapper_tick_draw_operations[current_form.form_type].tick(message_service, current_form)
    message_service.past_mode = current_form.form_type
  end
  message_service.space_pressed = false
end

-- Sol_TickMessageService(message_service: Sol_MessageService):
function module.Sol_TickMessageService(message_service)
  if message_service.should_initialize then
    if #message_service.stack > 0 then
      message_service.stack_index = 1
      message_service.running = true
      message_service.should_initialize = false
    end
  end
  --
  if message_service.running then
    Sol_TickMessageService(message_service)
  end
end

-- Sol_KeypressMessageService(message_service: Sol_MessageService, key: string):
function module.Sol_KeypressMessageService(message_service, key)
  if key == "space" then
    message_service.space_pressed = true
  end
end

--::::::::::::::::::::::::::::::::--
--[[ :: Draw Message Service :: ]]--
--::::::::::::::::::::::::::::::::--

-- Sol_DrawMessageService(engine: Sol_Engine, message_service, Sol_MessageService):
function module.Sol_DrawMessageService(engine, message_service)
  if message_service.running and message_service.stack_index <= #message_service.stack then
    local current_form = message_service.stack[message_service.stack_index]
    assign_wrapper_tick_draw_operations[current_form.form_type].draw(engine, message_service, current_form)
  end
end

--
return module