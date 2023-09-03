-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.
local SM_Vector     =require("Solar.Math.Vector")
local SUI_Cursor    =require("Solar.UI.Cursor")
local SUI_Wrap      =require("Solar.UI.Wrap")
local SUI_Frame     =require("Solar.UI.Frame")
local module={}

--[[ Begin the "Display" object functions ]]
function module.Sol_NewDisplay(display)
  return table.structure({
    elements  = {},
    cursor    = SUI_Cursor.Sol_NewCursor(),
    name      = "display",
    type      = "display",
    size      = SM_Vector.Sol_NewVector(0, 0)
  }, display or {})
end

function module.Sol_SetMousePositionOffsetDisplay(display, offsetx, offsety)
  display.cursor.position_offset=SM_Vector.Sol_NewVector(offsetx, offsety)
end

function module.Sol_InsertElement(display, element)
  table.insert(display.elements, element)
end

function module.Sol_TickDisplay(display)
  SUI_Cursor.Sol_TickCursor(display.cursor)
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      SUI_Frame.Sol_TickFrame(display, element)
    else
      if SUI_Wrap.Sol_UIElementTypesWrap[element.type]["tick"] then
        SUI_Wrap.Sol_UIElementTypesWrap[element.type]["tick"](display, element)
      end
    end
  end
end

function module.Sol_DrawDisplay(display)
  for _, element in ipairs(display.elements) do
    if element.type == "frame" then
      SUI_Frame.Sol_DrawFrame(display, element)
    else
      if SUI_Wrap.Sol_UIElementTypesWrap[element.type]["draw"] then
        SUI_Wrap.Sol_UIElementTypesWrap[element.type]["draw"](display, element)
      end
    end
  end
  SUI_Cursor.Sol_DrawCursor(display.cursor)
end

--
return module