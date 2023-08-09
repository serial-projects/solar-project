local module = {}
local SC_Structures = require("Solar.Code.Structures")
local SM_Color = require("Solar.Math.Color")
--

-- MSG_TYPE: there are several types of messages:
-- TODO: add YESNOASK and ASK.
module.MSG_TYPE = table.enum(1, {"DIALOG", "FULLSCR_MSG", "YESNOASK", "ASK"})

-- Sol_NewDialogForm(): new dialog form.
function module.Sol_NewDialogForm(recipe)
  return SC_Structures.Sol_BuildStruct({
    who           = "???",
    text          = "...",
    font          = "normal",
    size          = 12,
    speed         = 0.1,
    color         = SM_Color.Sol_NewColor4(250, 250, 250),
    background    = SM_Color.Sol_NewColor4(10, 10, 10),
    callback      = 0
  }, recipe or {})
end

-- Sol_NewFullScrMsgForm(recipe): new full screen message.
function module.Sol_NewFullScrMsgForm(recipe)
  return SC_Structures.Sol_BuildStruct({
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
  return SC_Structures.Sol_BuildStruct({
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
    stack   = {},
    stack_index = 1,
    -- message:
    text_index = 0,
    text_index_timing = 0,
    waiting_player_click_space = false,
    -- frames: contains all the UI the frame.
    dialog_frame = 0,
    fullscrmsg_frame = 0
  }
end

--
return module