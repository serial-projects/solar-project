local sgen=require("sol.sgen")
local smath=require("sol.smath")
local graphics=require("sol.graphics")
local ui_wrap=require("sol.ui.wrap")
local module={}

--[[ Begin the "Frame" functions ]]

-- Sol_NewFrame(frame: {type, elements, visible, enable_bg, bg_canvas, bg_position})
function module.Sol_NewFrame(frame)
  local frame = frame or {}
  return sgen.Sol_BuildStruct({
    type          = "frame",
    elements      = {},
    visible       = true,
    enable_bg     = false,
    bg_canvas     = 0,
    bg_position   = smath.Sol_NewVector(0, 0),
    bg_size       = smath.Sol_NewVector(0, 0)
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
        if ui_wrap.Sol_UIElementTypesWrap[element.type]["tick"] then
          ui_wrap.Sol_UIElementTypesWrap[element.type]["tick"](display, element)
        end
      end
    end
    --
  end
end
function module.Sol_DrawFrame(display, frame)
  if frame.visible then
    if frame.enable_bg then
      graphics.Sol_DrawCanvas(frame.bg_canvas, frame.bg_position)
    end
    for _, element in ipairs(frame.elements) do
      if element.type == "frame" then
        module.Sol_DrawFrame(display, element)
      else
        if ui_wrap.Sol_UIElementTypesWrap[element.type]["draw"] then
          ui_wrap.Sol_UIElementTypesWrap[element.type]["draw"](display, element)
        end
      end
    end
  end
end

--
return module