local modules = {}
local world = require("solar.worlds.mode")
local utils = require("solar.utils")
local consts= require("solar.consts")
local storage=require("solar.storage")
--
function Solar_NewEngine()
  return {
    storage = nil,
    window_width = 0, window_height = 0,
    world_viewport = utils.Solar_NewVectorXY(0, 0),
    world_viewport_position = utils.Solar_NewVectorXY(0, 0),
    world_mode = world.Solar_NewWorldMode(),
    current_mode = consts.SOLAR_MODE_WORLD,
    -- keymap:
    world_keymap = {
      walk_up = "up", walk_down = "down", walk_left = "left", walk_right = "right"
    },
    -- shared_values:
    -- NOTE: shared values are basically variables that are shared between
    -- commands, and other elements. They are very important to scripting and
    -- other stuff.
    shared_values = {}
  }
end
modules.Solar_NewEngine = Solar_NewEngine
function Solar_InitEngine(engine)
  --
  engine.window_width, engine.window_height = consts.SOLAR_INITIAL_WINDOW_WIDTH, consts.SOLAR_INITIAL_WINDOW_HEIGHT
  engine.world_viewport.x, engine.world_viewport.y = consts.SOLAR_INITIAL_WINDOW_WIDTH, consts.SOLAR_INITIAL_WINDOW_HEIGHT
  love.window.setMode(engine.window_width, engine.window_height, {resizable = true, vsync = true})
  love.window.setTitle(consts.SOLAR_WINDOW_TITLE)
  engine.storage = storage.Solar_NewStorage("data")
  --
  local using_language = "en_US"
  storage.Solar_StorageLoadLanguagePack(engine.storage, using_language)
  --
  world.Solar_InitWorldMode(engine, engine.world_mode)
end
modules.Solar_InitEngine = Solar_InitEngine
function Solar_RegisterKeypressEngine(engine, key)
  -- TODO: create a better control for fullscreen!
  if key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen())
  end
  if engine.current_mode == consts.SOLAR_MODE_WORLD then
    world.Solar_KeypressWorldMode(engine, engine.world_mode, key)
  end
end
modules.Solar_RegisterKeypressEngine = Solar_RegisterKeypressEngine
function Solar_ResizeEngine(engine, new_width, new_height)
  engine.window_width, engine.window_height = new_width, new_height
  engine.world_viewport_position.x = math.floor(engine.window_width / 2) - math.floor(engine.world_viewport.x / 2)
  engine.world_viewport_position.y = math.floor(engine.window_height/ 2) - math.floor(engine.world_viewport.y / 2)
  --
  local offsetx = 0+engine.world_viewport_position.x
  local offsety = 0+engine.world_viewport_position.y
  world.Solar_FixResolutionWorldMode(engine, engine.world_mode, offsetx, offsety)
  --
end
modules.Solar_ResizeEngine = Solar_ResizeEngine
function Solar_TickEngine(engine)
  if engine.current_mode == consts.SOLAR_MODE_WORLD then
    world.Solar_TickWorldMode(engine, engine.world_mode)
  end
end
modules.Solar_TickEngine = Solar_TickEngine
function Solar_DrawCanvas(canva, canva_position)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canva, canva_position.x, canva_position.y)
end
function Solar_DrawEngine(engine)
  love.graphics.clear(1, 1, 1, 1)
  if engine.current_mode == consts.SOLAR_MODE_WORLD then
    world.Solar_DrawWorldMode(engine, engine.world_mode)
    Solar_DrawCanvas(engine.world_mode.viewport, engine.world_viewport_position)
  end
end
modules.Solar_DrawEngine = Solar_DrawEngine
--
return modules
