local defaults = require "sol.defaults"
local wmode = require "sol.wmode"
local smath = require "sol.smath"
local graphics = require "sol.graphics"
local storage = require "sol.storage"
local scf = require "sol.scf"
local system = require "sol.system"

local module={}
--

--[[ Create a New Engine ]]
function Sol_NewEngine()
  return {
    engine_vars={},
    storage = storage.Sol_NewStorage(nil),
    root = nil,
    window_size = smath.Sol_NewVector(defaults.SOL_WINDOW_WIDTH, defaults.SOL_WINDOW_HEIGHT),
    window_title = defaults.SOL_WINDOW_TITLE,
    window_flags = defaults.SOL_WINDOW_FLAGS,
    viewport_size = smath.Sol_NewVector(defaults.SOL_VIEWPORT_WIDTH, defaults.SOL_VIEWPORT_HEIGHT),
    viewport_position = smath.Sol_NewVector(0, 0),
    current_mode = defaults.SOL_ENGINE_MODES.WORLD,
    menu_mode = nil,
    world_mode = wmode.Sol_NewWorldMode(),
    credits_mode = nil,
    wmode_keymap={walk_up="up", walk_down="down", walk_left="left", walk_right="right"},
  }
end ; module.Sol_NewEngine=Sol_NewEngine

--[[ Engine Functions ]]
function Sol_SetWindowFromEngine(engine)
  love.window.setMode(engine.window_size.x, engine.window_size.y, engine.window_flags)
  love.window.setTitle(engine.window_title)
end ; module.Sol_SetWindowFromEngine=Sol_SetWindowFromEngine
function Sol_AdjustViewportAtCenter(engine)
  engine.viewport_position = smath.Sol_NewVector(math.floor(engine.window_size.x / 2)-math.floor(engine.viewport_size.x / 2), math.floor(engine.window_size.y / 2)-math.floor(engine.viewport_size.y / 2))
end ; module.Sol_AdjustViewportAtCenter=Sol_AdjustViewportAtCenter

--[[ Init Related Functions ]]
function Sol_LoadSettings(engine)
  local settings_loaded=scf.SCF_LoadFile(system.Sol_MergePath({engine.root, "settings.slr"}))
  local window_section=settings_loaded["window"]
  --> section "window"
  if window_section then
    local window_width=window_section["width"] or engine.window_size.x
    local window_height=window_section["height"] or engine.window_size.y
    local window_title=window_section["title"] or engine.window_title
    engine.window_size,engine.window_title=smath.Sol_NewVector(window_width, window_height),window_title
    local flags_section=window_section["flags"]
    if flags_section then
      local _targetflags={"resizable","vsync","fullscreen","centered"}
      for _, flag in ipairs(_targetflags) do
        if flags_section[flag] then
          dmsg("using flag %s from the configuration file!", flag)
          engine.window_flags[flag]=flags_section[flag]
        end
      end
    end
  end
  --> section "world_keymap"
  local world_keymap=settings_loaded["world_keymap"]
  if world_keymap then
    for input_key, current_input in pairs(engine.wmode_keymap) do
      local wk_value=world_keymap[input_key]
      if wk_value then
        dmsg("keymap for \"%s\" event was changed from \"%s\" to \"%s\"", input_key, current_input, wk_value)
        engine.wmode_keymap[input_key]=wk_value
      end
    end
  end
  --
end ; module.Sol_LoadSettings=Sol_LoadSettings
function Sol_InitEngine(engine, path_resources)
  local begun=os.clock()
  engine.root, engine.storage.root = path_resources, path_resources ; dmsg("engine.root: "..engine.root)
  Sol_LoadSettings(engine)
  --
  Sol_SetWindowFromEngine(engine)
  Sol_AdjustViewportAtCenter(engine)
  storage.Sol_LoadLanguage(engine.storage, "en_US")
  --
  wmode.Sol_InitWorldMode(engine, engine.world_mode)
  dmsg("Sol_InitEngine() took %s seconds.", os.clock() - begun)
end ; module.Sol_InitEngine=Sol_InitEngine

--[[ Tick Related Functions ]]
function Sol_NewResizeEventEngine(engine, new_width, new_height)
  engine.window_size = smath.Sol_NewVector(new_width, new_height)
  Sol_AdjustViewportAtCenter(engine)
  Sol_SetWindowFromEngine(engine)
  wmode.Sol_ResizeEventWorldMode(engine, engine.world_mode)
end ; module.Sol_NewResizeEventEngine=Sol_NewResizeEventEngine
function Sol_KeypressEventEngine(engine, key)
  if engine.current_mode == defaults.SOL_ENGINE_MODES.MENU then
    mwarn("engine.current_mode is not yet implemented.")
  elseif engine.current_mode == defaults.SOL_ENGINE_MODES.WORLD then
    wmode.Sol_KeypressEventWorld(engine, engine.world_mode, key)
  else
    mwarn("engine.current_mode is not yet implemented.")
  end
end ; module.Sol_KeypressEventEngine=Sol_KeypressEventEngine
function Sol_TickEngine(engine)
  storage.Sol_CleanCacheInStorage(engine.storage)
  if engine.current_mode == defaults.SOL_ENGINE_MODES.MENU then
    mwarn("engine.current_mode is not yet implemented.")
  elseif engine.current_mode == defaults.SOL_ENGINE_MODES.WORLD then
    wmode.Sol_TickWorldMode(engine, engine.world_mode)
  else
    mwarn("engine.current_mode is not yet implemented.")
  end
  --
end ; module.Sol_TickEngine=Sol_TickEngine

--[[ Draw Related Functions ]]
function Sol_DrawEngine(engine)
  if engine.current_mode == defaults.SOL_ENGINE_MODES.MENU then
    mwarn("engine.current_mode is not yet implemented.")
  elseif engine.current_mode == defaults.SOL_ENGINE_MODES.WORLD then
    wmode.Sol_DrawWorldMode(engine, engine.world_mode)
    graphics.Sol_DrawCanvas(engine.world_mode.viewport, engine.viewport_position)
  else
    mwarn("engine.current_mode is not yet implemented.")
  end
end ; module.Sol_DrawEngine=Sol_DrawEngine

--
return module