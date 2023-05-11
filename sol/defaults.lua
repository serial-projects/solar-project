local module={}
local smath=require("sol.smath")
--
module.SOL_VERSION = "1.0"
module.SOL_RELEASE = 10

module.SOL_ENGINE_MODES = table.enum(1, {"MENU", "WORLD", "CREDITS"})

module.SOL_WINDOW_WIDTH = 800
module.SOL_WINDOW_HEIGHT = 600
module.SOL_WINDOW_TITLE = "[Sol]"
module.SOL_WINDOW_FLAGS = { resizable = true, vsync = true, centered = true }

module.SOL_VIEWPORT_WIDTH = 800
module.SOL_VIEWPORT_HEIGHT = 600
module.SOL_VIEWPORT_BACKGROUND = smath.Sol_NewColor4(84, 72, 122)

module.SOL_DRAW_USING = table.enum(1, {"COLOR", "TEXTURE"})

module.SOL_UI_CURSOR_DEFAULT_COLOR = smath.Sol_NewColor4(255, 255, 255)
module.SOL_UI_CURSOR_DEFAULT_SIZE = smath.Sol_NewVector(16, 16)

--
return module