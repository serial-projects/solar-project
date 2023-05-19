local module = {}

local smath = require("solar.smath")

-- ############################################################################
-- Things you CAN change :^)
-- ############################################################################

-- Solar Version Control: define the version.
module.SOLAR_VERSION = "1.5 (Alpha Release)"
module.SOLAR_RELEASE_NUMBER = 10

-- Solar Window Configuration: before the game initializes, those are the values
-- used by the game. This prevents fails if no configuration file is provided.
module.SOLAR_INITIAL_WINDOW_WIDTH = 800
module.SOLAR_INITIAL_WINDOW_HEIGHT= 600
module.SOLAR_WINDOW_TITLE = ("Solar Engine "..module.SOLAR_VERSION)

-- Viewport size: this ALSO can be configured by the game configuration file
-- during the initialization BUT, this is the default values for it.
module.SOLAR_VIEWPORT_WIDTH = module.SOLAR_INITIAL_WINDOW_WIDTH
module.SOLAR_VIEWPORT_HEIGHT = module.SOLAR_INITIAL_WINDOW_HEIGHT

--
--  [[ World Mode Configuration ]]
--

-- Chunks: A chunk is a bit of the world, in VERY large worlds, it's better to
-- just load a small piece of it to prevent out of memory errors or LAG, which is
-- bad. Worlds bigger than 100 in any direction is loaded using chunks.
module.SOLAR_WORLD_CHUNK_WIDTH = 20
module.SOLAR_WORLD_CHUNK_HEIGHT = 20

-- Test World: simple world generated for testing the engine, if the game fails to load
-- something, this world may trigger and appear for you.
module.SOLAR_TEST_WORLD_WIDTH = 10
module.SOLAR_TEST_WORLD_HEIGHT = 10
module.SOLAR_TEST_WORLD_TILE_WIDTH = 64
module.SOLAR_TEST_WORLD_TILE_HEIGHT = 64

--
-- [[ Player Configuration ]]
--

-- * PLAYER_WIDTH and PLAYER_HEIGHT: defines the default player size.
module.SOLAR_PLAYER_WIDTH = 32
module.SOLAR_PLAYER_HEIGHT = 32

-- * PLAYER_LOOKING_(DIRECTION): what direction is the player looking at?
module.SOLAR_PLAYER_LOOKING_UP    = 0
module.SOLAR_PLAYER_LOOKING_DOWN  = 1
module.SOLAR_PLAYER_LOOKING_LEFT  = 2
module.SOLAR_PLAYER_LOOKING_RIGHT = 3

-- The cursor size (default).
module.SOLAR_CURSOR_WIDTH = 16
module.SOLAR_CURSOR_HEIGHT = 16

-- Console/Terminal configuration.
module.SOLAR_TERMINAL_BACKGROUND_COLOR = smath.Solar_NewColor(100, 100, 100)
module.SOLAR_TERMINAL_INPUT_BACKGROUND_COLOR = smath.Solar_NewColor(150, 150, 150)
module.SOLAR_TERMINAL_INPUT_FOREGROUND_COLOR = smath.Solar_NewColor(240, 240, 240)
module.SOLAR_TERMINAL_INPUTBOX_HEIGHT = 30
module.SOLAR_TERMINAL_INPUTBOX_FONTNAME = "terminal"
module.SOLAR_TERMINAL_INPUTBOX_FONTSIZE = 12
module.SOLAR_TERMINAL_TEXT_FONTNAME = "terminal"
module.SOLAR_TERMINAL_TEXT_FONTSIZE = 12
module.SOLAR_TERMINAL_HEIGHT = 400
module.SOLAR_TERMINAL_MAX_LINES = 80

-- ############################################################################
-- Things you SHOULD NOT change.
-- ############################################################################

-- Solar Modes:
-- *  init:   load some important textures and resources.
-- *  world:  used to render the world and interact.
-- *  menu:   show the save and configuration.
module.SOLAR_MODE_INIT = 1
module.SOLAR_MODE_WORLD= 2
module.SOLAR_MODE_MENU = 3

-- Solar Drawing Methods:
-- *  color:  uses basic color to draw.
-- *  textures: uses textures to draw.
module.SOLAR_DRAW_USING_COLOR   = 1
module.SOLAR_DRAW_USING_TEXTURE = 2

--
return module