local module = {} 
local consts = require("solar.consts")
local utils = require("solar.utils")
local storage = require("solar.storage")

function Solar_NewTerminal()
  return {
    -- terminal buffer: how much things can the terminal have?
    lines = {},
    line_limit = 80,
    size = utils.Solar_NewVectorXY(0, 0),
    inputbox_font = nil,
    text_font = nil,
    --[[ canvas & viewport ]]--
    textbox_canva = nil,            textbox_need_redraw = true,
    inputbox_canva = nil,           inputbox_need_redraw = true,
    viewport  = nil,                viewport_position = utils.Solar_NewVectorXY(0, 0),
    enabled   = false,
    current_input = ""
  }
end
module.Solar_NewTerminal = Solar_NewTerminal

--[[ terminal functions ]]--
function Solar_TerminalDrawCurrentInput(engine, terminal)
  love.graphics.setCanvas(terminal.inputbox_canva)
    love.graphics.clear(utils.Solar_TranslateColor(consts.SOLAR_TERMINAL_INPUT_BACKGROUND_COLOR))
    love.graphics.setFont(terminal.inputbox_font)
    local th = terminal.inputbox_font:getHeight()
    love.graphics.setColor(utils.Solar_TranslateColor(consts.SOLAR_TERMINAL_INPUT_FOREGROUND_COLOR))
    love.graphics.print(terminal.current_input, 0, math.floor(terminal.inputbox_canva:getHeight()/2)-math.floor(th/2))
  love.graphics.setCanvas(terminal.viewport)
end
function Solar_TerminalDrawTextBox(engine, terminal)
  love.graphics.setCanvas(terminal.textbox_canva)
    love.graphics.clear(utils.Solar_TranslateColor(consts.SOLAR_TERMINAL_BACKGROUND_COLOR))
  love.graphics.setCanvas(terminal.viewport)
end

--[[ init terminal ]]--
function Solar_InitTerminal(engine, terminal, base_display)
  print(base_display)
  terminal.viewport = love.graphics.newCanvas(base_display.size.x, math.floor(base_display.size.y/2))
  terminal.size = utils.Solar_NewVectorXY(terminal.viewport:getWidth(), terminal.viewport:getHeight())
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

--[[ keypressed events ]]--
function Solar_KeypressedEventTerminal(engine, terminal, key)
  if terminal.enabled then
    terminal.current_input = terminal.current_input .. key
    terminal.inputbox_need_redraw = true
  end
end
module.Solar_KeypressedEventTerminal = Solar_KeypressedEventTerminal

--[[ draw the terminal ]]--
function Solar_DrawTerminal(engine, terminal)
  if terminal.enabled then
    if terminal.textbox_need_redraw or terminal.inputbox_need_redraw then
      local past_canva = love.graphics.getCanvas()
      love.graphics.setCanvas(terminal.viewport)
      love.graphics.clear(0, 0, 0, 1)
      if terminal.textbox_need_redraw then
        Solar_TerminalDrawTextBox(engine, terminal)
        terminal.textbox_need_redraw = false
      end
      if terminal.inputbox_need_redraw then
        Solar_TerminalDrawCurrentInput(engine, terminal)
        terminal.inputbox_need_redraw = false
      end
      --[[ draw the elements ]]--
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(terminal.textbox_canva, 0, 0)
      love.graphics.draw(terminal.inputbox_canva, 0, terminal.textbox_canva:getHeight())
      love.graphics.setCanvas(past_canva)
    end
    love.graphics.draw(terminal.viewport, 0, 0)
  end
end
module.Solar_DrawTerminal = Solar_DrawTerminal

--
return module