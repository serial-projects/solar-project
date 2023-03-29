local module = {}
local utils = require("solar.utils")
local consts = require("solar.consts")

--
-- UI utils
-- 

-- Solar_UIGetAbsolutePosition(ww, wh, ew, eh, posx, posy): returns the rendering position of 
-- element, gave the position in porcent relative to the window (or canva if want).
function Solar_UIGetAbsolutePosition(ww, wh, ew, eh, posx, posy)
  -- calculate the window divided by 100 (for every axis.)
  local xpos, ypos      = (ww / 100), (wh / 100)
  local xoff, yoff      = (ew / 100) * posx, (eh / 100) * posy
  local abposx, abposy  = (xpos * posx) - xoff, (ypos * posy) - yoff
  return math.floor(abposx), math.floor(abposy)
end
function Solar_DecidePosition(display_size, element_size, element_position, force_absolute)
  local posx, posy
  if force_absolute then
    posx, posy = element_position.x, element_position.y
  else
    posx, posy = Solar_UIGetAbsolutePosition(display_size.x, display_size.y, element_size.x, element_size.y, element_position.x, element_position.y)
  end
  return posx, posy
end

--
-- Generics for all the elements.
--
function Solar_NewGenericsTable(name, type, posx, posy, force_absolute)
  return {
    name = name,
    type = type,
    -- NOTE: position can be absolute or relative, which depends of your usage, it's
    -- recommended to YOU to use the relative as it automatically adjusts to the 
    -- screen's depending of the porcentage.
    position = utils.Solar_NewVectorXY(posx, posy),
    force_absolute = (force_absolute == nil and false or force_absolute),
    draw_using = consts.SOLAR_DRAW_USING_COLOR,
    --
    at_left_click   = nil,
    at_right_click  = nil,
    at_middle_click = nil,
  }
end

--
-- Label Element
--
function Solar_NewLabel(name, font, text, posx, posy, force_absolute)
  return {
    type = "label",
    name = name,
    --
    font = font,
    text = text,
    color = utils.Solar_NewColor(255, 255, 255),
    use_background = false,
    background_color = utils.Solar_NewColor(0, 0, 0),
    --
    position = utils.Solar_NewVectorXY(posx, posy),
    zindex = 0,
    force_absolute = (force_absolute == nil) and false or force_absolute,
    --
    visible = true,
  }
end
module.Solar_NewLabel = Solar_NewLabel
function Solar_TickLabel(display, label)
  -- TODO: check when the label is pressed and other stuff.
end
function Solar_DrawLabel(display, label)
  if label.visible then
    local tw, th = label.font:getWidth(label.text), label.font:getHeight()
    local posx, posy
    if label.force_absolute then
      posx, posy = label.position.x, label.position.y
    else
      posx, posy = Solar_UIGetAbsolutePosition(
        display.size.x,   display.size.y,
        tw,               th,
        label.position.x, label.position.y
      )
    end
    --
    if label.use_background then
      love.graphics.setColor(utils.Solar_TranslateColor(label.background_color))
      love.graphics.rectangle("fill", posx, posy, tw, th)
    end
    --
    love.graphics.setFont(label.font)
    love.graphics.setColor(utils.Solar_TranslateColor(label.color))
    love.graphics.print(label.text, posx, posy)
  end
end

--
-- Progress Element
--
function Solar_NewProgress(name, width, height, posx, posy, force_absolute)
  return {
    name = name, type = "progress",
    visible = true,
    --
    position = utils.Solar_NewVectorXY(posx, posy),
    force_absolute = (force_absolute == nil) and false or force_absolute,
    size = utils.Solar_NewVectorXY(width, height),
    background_color = utils.Solar_NewColor(0,      0,    0),
    foreground_color = utils.Solar_NewColor(100,  100,  100),
    --
    progress = 0,
    max_progress = 1,
  }
end
module.Solar_NewProgress = Solar_NewProgress
function Solar_TickProgress(display, progress)
  -- DO SOMETHING?
end
module.Solar_TickProgress = Solar_TickProgress
function Solar_DrawProgress(display, progress)
  if progress.visible then
    local posx, posy = Solar_DecidePosition(display.size, progress.size, progress.position, progress.force_absolute)
    local width = (progress.size.x / progress.max_progress) * progress.progress
    love.graphics.setColor(utils.Solar_TranslateColor(progress.background_color))
    love.graphics.rectangle("fill", posx, posy, progress.size.x, progress.size.y)
    love.graphics.setColor(utils.Solar_TranslateColor(progress.foreground_color))
    love.graphics.rectangle("fill", posx, posy, width, progress.size.y)
  end
end
module.Solar_DrawProgress = Solar_DrawProgress

--
-- Frame Element
--
local Solar_ElementCallTable = {
  label = {tick = Solar_TickLabel, draw = Solar_DrawLabel},
  progress = {tick = Solar_TickProgress, draw = Solar_DrawProgress }
}

function Solar_NewFrame(name, visible, posx, posy, force_absolute)
  return {
    type = "frame",
    name = name,
    visible = visible,
    force_absolute = force_absolute == nil and false or force_absolute,
    elements = {},
    --
    background_canva = nil,
    use_background_canva = false,
    background_canva_position = utils.Solar_NewVectorXY(posx, posy),
    background_canva_postion_force_absolute = ((force_absolute == nil) and false or force_absolute),
    --
  }
end
module.Solar_NewFrame = Solar_NewFrame
function Solar_InsertElementFrame(frame, element)
  table.insert(frame.elements, element)
end
module.Solar_InsertElementFrame = Solar_InsertElementFrame
function Solar_TickFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Solar_ElementCallTable[element.type] then Solar_ElementCallTable[element.type].tick(display, element) end
    end
  end
  --
end
function Solar_DrawFrame(display, frame)
  if frame.use_background_canva then
    local posx, posy = Solar_DecidePosition(
      display.size, utils.Solar_NewVectorXY(frame.background_canva:getWidth(), frame.background_canva:getHeight()),
      frame.background_canva_position, frame.background_canva_postion_force_absolute
    )
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(frame.background_canva, posx, posy)
  end
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if Solar_ElementCallTable[element.type] then Solar_ElementCallTable[element.type].draw(display, element) end
    end
  end
  --
end
function Solar_MakeBackgroundCanvaSolidColorFrame(frame, width, height, posx, posy, color)
  --
  frame.background_canva = love.graphics.newCanvas(width, height)
  frame.background_canva_position = utils.Solar_NewVectorXY(posx, posy)
  --
  local past_canva = love.graphics.getCanvas()
  love.graphics.setCanvas(frame.background_canva)
    love.graphics.clear(utils.Solar_TranslateColor(color))
  love.graphics.setCanvas(past_canva)
  --
end
module.Solar_MakeBackgroundCanvaSolidColorFrame = Solar_MakeBackgroundCanvaSolidColorFrame

--
-- Display Element
--
function Solar_NewCursor()
  return {
    size = utils.Solar_NewVectorXY(consts.SOLAR_CURSOR_WIDTH, consts.SOLAR_CURSOR_HEIGHT),
    position = utils.Solar_NewVectorXY(0, 0),
    offset = utils.Solar_NewVectorXY(0, 0),
    visible = true,
    -- LAST position and hiding the cursor when it's not necessary, basically
    -- calculate if the mouse has moved, stores it's new position and check if
    -- the move is inside the tolerance.
    last_position         = utils.Solar_NewVectorXY(0, 0),
    last_position_change  = utils.Solar_NewVectorXY(0, 0),
    change_tolerance = 1,
    hide_timing = 0,
    hide_time = 2,
    -- draw method
    mouse_status = 0,
    mouse_textures = {},
    draw_using = consts.SOLAR_DRAW_USING_COLOR,
    color = utils.Solar_NewColor(150, 80, 100),
  }
end
module.Solar_NewCursor = Solar_NewCursor
function Solar_TickCursor(cursor)
  if os.time() > cursor.hide_timing then cursor.visible = false end
  -- calculate the cursor offset and other stuff.
  cursor.last_position.x, cursor.last_position.y = cursor.position.x, cursor.position.y
  cursor.position.x, cursor.position.y = love.mouse.getPosition()
  cursor.position.x = cursor.position.x - math.floor(cursor.size.x / 2)
  cursor.position.y = cursor.position.y - math.floor(cursor.size.y / 2)
  cursor.position.x = cursor.position.x - cursor.offset.x
  cursor.position.y = cursor.position.y - cursor.offset.y
  -- check if the cursor had moved, case not, then keep it hidden!
  cursor.last_position_change.x = math.abs(cursor.last_position.x - cursor.position.x)
  cursor.last_position_change.y = math.abs(cursor.last_position.y - cursor.position.y)
  if  (cursor.last_position_change.x >= cursor.change_tolerance) or 
      (cursor.last_position_change.y >= cursor.change_tolerance) then
    cursor.visible, cursor.hide_timing = true, os.time() + cursor.hide_time
  end
  --
end
module.Solar_TickCursor = Solar_TickCursor
function Solar_DrawCursor(cursor)
  if cursor.visible then
    if cursor.draw_using == consts.SOLAR_DRAW_USING_COLOR then
      love.graphics.setColor(utils.Solar_TranslateColor(cursor.color))
      love.graphics.rectangle("fill", cursor.position.x, cursor.position.y, cursor.size.x, cursor.size.y)
    end
  end
  --
end
function Solar_NewDisplay(name, base_width, base_height)
  return {
    elements = {}, visible = true,
    offset = utils.Solar_NewVectorXY(0, 0),
    cursor = Solar_NewCursor(),
    size = utils.Solar_NewVectorXY(base_width, base_height),
  }
end
module.Solar_NewDisplay = Solar_NewDisplay
function Solar_InsertElementDisplay(display, element)
  table.insert(display.elements, element)
end
module.Solar_InsertElementDisplay = Solar_InsertElementDisplay
function Solar_TickDisplay(display)
  if display["cursor"] then
    Solar_TickCursor(display.cursor)
  end
  --
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      Solar_TickFrame(display, element)
    else
      if Solar_ElementCallTable[element.type] then
        Solar_ElementCallTable[element.type].tick(display, element)
      end
    end
  end
  --
end
module.Solar_TickDisplay = Solar_TickDisplay
function Solar_DrawDisplay(display)
  if display["cursor"] then
    Solar_DrawCursor(display.cursor)
  end
  --
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      Solar_DrawFrame(display, element)
    else
      if Solar_ElementCallTable[element.type] then
        Solar_ElementCallTable[element.type].draw(display, element)
      end
    end
  end
  --
end
module.Solar_DrawDisplay = Solar_DrawDisplay

--
return module