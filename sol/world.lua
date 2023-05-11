local smath=require("sol.smath")
local defaults=require("sol.defaults")
local storage = require("sol.storage")
local ui = require("sol.ui")
local module={}
--
function Sol_NewWorldMode()
  return {
    viewport = nil,
    viewport_size = nil,
    worlds = {},
    current_world = nil,
    main_display = nil
  }
end
module.Sol_NewWorldMode=Sol_NewWorldMode
function Sol_InitWorldMode(engine, world_mode)
  --> setup the viewport: the viewport does not resize (even if the window is resizable).
  world_mode.viewport=love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
  world_mode.viewport_size=engine.viewport_size
  world_mode.main_display=ui.Sol_NewDisplay()
end ; module.Sol_InitWorldMode=Sol_InitWorldMode

--[[ Tick Related Functions ]]
function Sol_TickWorldMode(engine, world_mode)
  ui.Sol_TickDisplay(world_mode.main_display)
end ; module.Sol_TickWorldMode=Sol_TickWorldMode
function Sol_ResizeEventWorldMode(engine, world_mode)
  ui.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end ; module.Sol_ResizeEventWorldMode=Sol_ResizeEventWorldMode
function Sol_KeypressEventWorld(engine, world_mode)
end ; module.Sol_KeypressEventWorld=Sol_KeypressEventWorld

--[[ Draw Related Functions ]]
function Sol_DrawWorldMode(engine, world_mode)
  local past_canva=love.graphics.getCanvas()
  love.graphics.setCanvas(world_mode.viewport)
    love.graphics.clear(smath.Sol_TranslateColor(defaults.SOL_VIEWPORT_BACKGROUND))
    ui.Sol_DrawDisplay(world_mode.main_display)
  love.graphics.setCanvas(past_canva)
end
module.Sol_DrawWorldMode=Sol_DrawWorldMode
--
return module