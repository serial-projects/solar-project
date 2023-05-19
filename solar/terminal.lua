local module = {} 
local smath = require("solar.smath")
local storage = require("solar.storage")
local consts = require("solar.consts")
--

local unpack = unpack or table.unpack

function Solar_NewTerminal()
  return {
    -- terminal buffer: how much things can the terminal have?
    lines = {},
    line_limit = 80,
    size = smath.Solar_NewVectorXY(0, 0),
    inputbox_font = nil,
    text_font = nil,
    --[[ canvas & viewport ]]--
    textbox_canva = nil,            textbox_need_redraw = true,
    inputbox_canva = nil,           inputbox_need_redraw = true,
    viewport  = nil,                viewport_position = smath.Solar_NewVectorXY(0, 0),
    enabled   = false,
    current_input = ""
  }
end
module.Solar_NewTerminal = Solar_NewTerminal

--[[ terminal functions ]]--
function Solar_TerminalDrawCurrentInput(engine, terminal)
  love.graphics.setCanvas(terminal.inputbox_canva)
    love.graphics.clear(smath.Solar_TranslateColor(consts.SOLAR_TERMINAL_INPUT_BACKGROUND_COLOR))
    love.graphics.setFont(terminal.inputbox_font)
    local th = terminal.inputbox_font:getHeight()
    love.graphics.setColor(smath.Solar_TranslateColor(consts.SOLAR_TERMINAL_INPUT_FOREGROUND_COLOR))
    love.graphics.print(terminal.current_input, 0, math.floor(terminal.inputbox_canva:getHeight()/2)-math.floor(th/2))
  love.graphics.setCanvas(terminal.viewport)
end

function Solar_TerminalDrawTextBox(engine, terminal)
  love.graphics.setCanvas(terminal.textbox_canva)
    love.graphics.clear(smath.Solar_TranslateColor(consts.SOLAR_TERMINAL_BACKGROUND_COLOR))
    love.graphics.setFont(terminal.text_font)
    love.graphics.setColor(1, 1, 1, 1)
    --
    if #terminal.lines > consts.SOLAR_TERMINAL_MAX_LINES then
      local new_list = {}
      for index = math.floor(consts.SOLAR_TERMINAL_MAX_LINES/2), #terminal.lines do
        table.insert(new_list, terminal.lines[index])
      end
      terminal.lines = new_list
    end
    local index = #terminal.lines
    if index > 0 then
      local th = terminal.text_font:getHeight()
      local tbh = terminal.textbox_canva:getHeight()
      while index > 0 do
        --
        local text = terminal.lines[index]
        local line = (#terminal.lines - index) + 1
        local ypos = tbh - (th * line)
        --
        if ypos <= 0 then
          break
        end
        love.graphics.print(text, 0, ypos)
        index = index - 1
      end
    end
    --
  love.graphics.setCanvas(terminal.viewport)
end
function Solar_TerminalPrint(terminal, format, ...)
  local args = {...}
  local text
  if #args > 0 then
    text = string.format(format, unpack(args))
  else
    text = format
  end
  terminal.textbox_need_redraw = true
  table.insert(terminal.lines, text)
end
module.Solar_TerminalPrint = Solar_TerminalPrint

--[[ init terminal ]]--
function Solar_InitTerminal(engine, terminal, base_display)
  print(base_display)
  terminal.viewport = love.graphics.newCanvas(base_display.size.x, math.floor(base_display.size.y/2))
  terminal.size = smath.Solar_NewVectorXY(terminal.viewport:getWidth(), terminal.viewport:getHeight())
  terminal.inputbox_font = storage.Solar_StorageLoadFont(engine.storage, consts.SOLAR_TERMINAL_INPUTBOX_FONTNAME, consts.SOLAR_TERMINAL_INPUTBOX_FONTSIZE)
  terminal.text_font = storage.Solar_StorageLoadFont(engine.storage, consts.SOLAR_TERMINAL_TEXT_FONTNAME, consts.SOLAR_TERMINAL_TEXT_FONTSIZE)
  --[[ begin terminal viewport initialization ]]--
  terminal.textbox_canva = love.graphics.newCanvas(base_display.size.x, terminal.viewport:getHeight() - consts.SOLAR_TERMINAL_INPUTBOX_HEIGHT)
  terminal.inputbox_canva = love.graphics.newCanvas(base_display.size.x, consts.SOLAR_TERMINAL_INPUTBOX_HEIGHT)
end
module.Solar_InitTerminal = Solar_InitTerminal

--[[ tick the terminal ]]--
function Solar_TickTerminal(engine, terminal)
end
module.Solar_TickTerminal = Solar_TickTerminal

--[[ process the text inputs ]]--
function Solar_ProcessCommandTerminal(terminal, command)
  Solar_TerminalPrint(terminal, '>> '..command)
  local command_table = {
    ["/help"]=function(args)
      Solar_TerminalPrint(terminal, "-- Solar Commands --")
      Solar_TerminalPrint(terminal, "/help: show this message.")
      Solar_TerminalPrint(terminal, "/exec <command>: execute the command inside the STRING.")
      Solar_TerminalPrint(terminal, "/quit: close the game (no saves).")
      Solar_TerminalPrint(terminal, "/info: shows the game version.") 
    end,
    ["/exec"]=function(args)
    end,
    ["/quit"]=function(args)
      love.event.quit()
    end,
  }
  --
  local command_parsed=string.tokenize(command)
  if #command_parsed <= 0 then
    return
  end
  local program = command_parsed[1]
  if command_table[program] then
    command_table[program](command_parsed)
  else
    Solar_TerminalPrint(terminal, "!! no command: "..program)
  end
end

--[[ keypressed events ]]--
local SOLAR_TERMINAL_EXTRA_ALLOWED_CHARACTERS = string.charseq2list("{}()[]\"'*!$%:;?~-/=")
local SOLAR_TERMINAL_SHIFT_REPLACEMENT = {
  ['-']='_',  ['9']='(', ['0']=')', ['[']='{', [']']='}',
  ['\'']='"', ['1']='!', ['2']='@', ['3']='#', ['4']='$',
  ['=']='+'
}
function Solar_KeypressedEventTerminal(engine, terminal, key)
  if terminal.enabled then
    --
    local input_key_events = {
      -- backspace key: delete everything.
      backspace = function(terminal)
        terminal.current_input = #terminal.current_input > 0 and terminal.current_input:sub(1, #terminal.current_input-1) or terminal.current_input
      end,
      -- enter/return key
      ['return'] = function(terminal)
        Solar_ProcessCommandTerminal(terminal, terminal.current_input)
        terminal.current_input = ""
      end,
      -- space: input the text.
      space = function(terminal)
        terminal.current_input = terminal.current_input .. ' '
      end,
    }
    if input_key_events[key] then
      input_key_events[key](terminal)
    else
      if #key <= 1 and string.isvalidchar(key, SOLAR_TERMINAL_EXTRA_ALLOWED_CHARACTERS) then
        local should_shift = love.keyboard.isDown("lshift")
        terminal.current_input = terminal.current_input .. (should_shift and (SOLAR_TERMINAL_SHIFT_REPLACEMENT[key] and SOLAR_TERMINAL_SHIFT_REPLACEMENT[key] or string.upper(key)) or key)
      end
    end
    terminal.inputbox_need_redraw = true
  end
end
module.Solar_KeypressedEventTerminal = Solar_KeypressedEventTerminal

--[[ draw the terminal ]]--
function Solar_DrawTerminal(engine, terminal)
  if terminal.enabled then
    --
    local past_canva = love.graphics.getCanvas()
    love.graphics.setCanvas(terminal.viewport)
    --
      love.graphics.clear(0, 0, 0, 1)
      if terminal.textbox_need_redraw then
        Solar_TerminalDrawTextBox(engine, terminal)
        terminal.textbox_need_redraw = false
      end
      if terminal.inputbox_need_redraw then
        Solar_TerminalDrawCurrentInput(engine, terminal)
        terminal.inputbox_need_redraw = false
      end
    --
    love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(terminal.textbox_canva, 0, 0)
      love.graphics.draw(terminal.inputbox_canva, 0, terminal.textbox_canva:getHeight())
    love.graphics.setCanvas(past_canva)
    love.graphics.draw(terminal.viewport, 0, 0)
  end
end
module.Solar_DrawTerminal = Solar_DrawTerminal

--
return module