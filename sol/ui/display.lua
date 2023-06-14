local sgen=require("sol.sgen")
local smath=require("sol.smath")
local ui_cursor=require("sol.ui.cursor")
local ui_wrap=require("sol.ui.wrap")
local ui_frame=require("sol.ui.frame")
local module={}

--[[ Begin the "Display" object functions ]]
function module.Sol_NewDisplay(display)
  return sgen.Sol_BuildStruct({
    elements  = {},
    cursor    = ui_cursor.Sol_NewCursor(),
    name      = "display",
    type      = "display",
    size      = smath.Sol_NewVector(0, 0)
  }, display or {})
end

function module.Sol_SetMousePositionOffsetDisplay(display, offsetx, offsety)
  display.cursor.position_offset=smath.Sol_NewVector(offsetx, offsety)
end

function module.Sol_InsertElement(display, element)
  table.insert(display.elements, element)
end

function module.Sol_TickDisplay(display)
  ui_cursor.Sol_TickCursor(display.cursor)
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      ui_frame.Sol_TickFrame(display, element)
    else
      if ui_wrap.Sol_UIElementTypesWrap[element.type]["tick"] then
        ui_wrap.Sol_UIElementTypesWrap[element.type]["tick"](display, element)
      end
    end
  end
end

function module.Sol_DrawDisplay(display)
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      ui_frame.Sol_DrawFrame(display, element)
    else
      if ui_wrap.Sol_UIElementTypesWrap[element.type]["draw"] then
        ui_wrap.Sol_UIElementTypesWrap[element.type]["draw"](display, element)
      end
    end
  end
  ui_cursor.Sol_DrawCursor(display.cursor)
end

--
return module