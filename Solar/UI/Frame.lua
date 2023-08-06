-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SG_Structures =require("Solar.Codegen.Structures")
local SM_Vector     =require("Solar.Math.Vector")
local SUI_Wrap      =require("Solar.UI.Wrap")
local SD_Canvas     =require("Solar.Draw.Canva")

local module={}

--[[ Begin the "Frame" functions ]]

-- Sol_NewFrame(frame: {type, elements, visible, enable_bg, bg_canvas, bg_position})
function module.Sol_NewFrame(frame)
  local frame = frame or {}
  return SG_Structures.Sol_BuildStruct({
    type          = "frame",
    elements      = {},
    visible       = true,
    enable_bg     = false,
    bg_canvas     = 0,
    bg_position   = SM_Vector.Sol_NewVector(0, 0),
    bg_size       = SM_Vector.Sol_NewVector(0, 0)
  }, frame)
end
function module.Sol_InsertElementInFrame(frame, element)
  table.insert(frame.elements, element)
end
function module.Sol_TickFrame(display, frame)
  if frame.visible then
    for _, element in ipairs(frame.elements) do
      if element.type == "frame" then
        module.Sol_TickFrame(display, element)
      else
        if SUI_Wrap.Sol_UIElementTypesWrap[element.type]["tick"] then
          SUI_Wrap.Sol_UIElementTypesWrap[element.type]["tick"](display, element)
        end
      end
    end
    --
  end
end

-- Sol_DrawFrame(display: Sol_Display, frame: Sol_UIFrame)
function module.Sol_DrawFrame(display, frame)
  if frame.visible then
    if frame.enable_bg then
      SD_Canvas.Sol_DrawCanvas(frame.bg_canvas, frame.bg_position)
    end
    for _, element in ipairs(frame.elements) do
      if element.type == "frame" then
        module.Sol_DrawFrame(display, element)
      else
        if SUI_Wrap.Sol_UIElementTypesWrap[element.type]["draw"] then
          SUI_Wrap.Sol_UIElementTypesWrap[element.type]["draw"](display, element)
        end
      end
    end
  end
end

--
return module