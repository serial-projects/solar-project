local module={}
local smath=require("sol.smath")

--[[ Version Distribution ]]
module.SOL_VERSION = "1.0 - 20230606"
module.SOL_RELEASE = 10
module.SOL_LOVE_MAJOR, module.SOL_LOVE_MINOR, module.SOL_LOVE_REVISION = love.getVersion()

--[[ Engine Modes ]]
module.SOL_ENGINE_MODES = table.enum(1, {"MENU", "WORLD", "CREDITS"})

--[[ Window Properties ]]
module.SOL_WINDOW_WIDTH = 800
module.SOL_WINDOW_HEIGHT = 600
module.SOL_WINDOW_TITLE = "[Sol]"
module.SOL_WINDOW_FLAGS = { resizable = true, vsync = true, centered = true }

--[[ Viewport Properties ]]
module.SOL_VIEWPORT_WIDTH = 800
module.SOL_VIEWPORT_HEIGHT = 600
module.SOL_VIEWPORT_BACKGROUND = smath.Sol_NewColor4(84, 72, 122)

--[[ Draw ]]
module.SOL_DRAW_USING = table.enum(1, {"COLOR", "TEXTURE", "SPRITES", "IMAGES"})

--[[ Cursor defaults ]]
module.SOL_UI_CURSOR_DEFAULT_COLOR = smath.Sol_NewColor4(255, 255, 255)
module.SOL_UI_CURSOR_DEFAULT_SIZE = smath.Sol_NewVector(16, 16)

--[[ Player size ]]
module.SOL_PLAYER_SIZE = smath.Sol_NewVector(64, 64)
module.SOL_PLAYER_LOOK_DIRECTION = table.enum(1,{"UP","DOWN","LEFT","RIGHT"})

--[[ Chunk Properties ]]
module.SOL_WORLD_CHUNK_WIDTH = 5
module.SOL_WORLD_CHUNK_HEIGHT= 5

--
return module