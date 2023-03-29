-- load the Solar Engine.
local Solar_Engine = require("solar.engine")

-- Global variables
local UsingEngine = Solar_Engine.Solar_NewEngine()

-- Usual LOVE functions.
function love.load(arguments)
  Solar_Engine.Solar_InitEngine(UsingEngine)
end
function love.update(dt)
  Solar_Engine.Solar_TickEngine(UsingEngine)
end
function love.draw()
  Solar_Engine.Solar_DrawEngine(UsingEngine)
end
-- Not so usual love functions.
function love.keypressed(key)
  Solar_Engine.Solar_RegisterKeypressEngine(UsingEngine, key)
end
function love.resize(width, height)
  Solar_Engine.Solar_ResizeEngine(UsingEngine, width, height)
end