-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SV_Defaults     = require("Solar.Values.Defaults")
local SV_Consts       = require("Solar.Values.Consts")
local SM_Vector       = require("Solar.Math.Vector")
local SM_Rectangle    = require("Solar.Math.Rectangle")
local SM_Color        = require("Solar.Math.Color")
local SD_Canvas       = require("Solar.Draw.Canva")
local SS_Path         = require("Solar.System.Path")
local SS_Storage      = require("Solar.System.Storage")
local SWM_Mode        = require("Solar.Modes.World.Mode")

local LucieDecode     = require("Library.Lucie.Decode")

local module={}
--

--[[ Create a New Engine ]]
function module.Sol_NewEngine()
    return {
        vars              = {PRECISE_WALK=true, CHUNK_RENDERING=1, RENDER_CHUNK_AMOUNT = 2, CHUNK_SIZE=64},
        storage           = SS_Storage.Sol_NewStorage(nil),
        root              = nil,
        window_size       = SM_Vector.Sol_NewVector(SV_Defaults.SOL_WINDOW_WIDTH, SV_Defaults.SOL_WINDOW_HEIGHT),
        window_title      = SV_Defaults.SOL_WINDOW_TITLE,
        window_flags      = SV_Defaults.SOL_WINDOW_FLAGS,
        viewport_size     = SM_Vector.Sol_NewVector(SV_Defaults.SOL_VIEWPORT_WIDTH, SV_Defaults.SOL_VIEWPORT_HEIGHT),
        viewport_position = SM_Vector.Sol_NewVector(0, 0),
        current_mode      = SV_Consts.engine_modes.WORLD,
        menu_mode         = nil,
        world_mode        = SWM_Mode.Sol_NewWorldMode(),
        credits_mode      = nil,
        wmode_keymap      = {walk_up="up", walk_down="down", walk_left="left", walk_right="right", interact="e"},
        main_ssen_thread  = nil,
    }
end

--[[ Engine Functions ]]
function module.Sol_SetWindowFromEngine(engine)
    love.window.setMode(engine.window_size.x, engine.window_size.y, engine.window_flags)
    love.window.setTitle(engine.window_title)
end

function module.Sol_AdjustViewportAtCenter(engine)
    engine.viewport_position = SM_Vector.Sol_NewVector(math.floor(engine.window_size.x / 2)-math.floor(engine.viewport_size.x / 2), math.floor(engine.window_size.y / 2)-math.floor(engine.viewport_size.y / 2))
end

--[[ Init Related Functions ]]
function module.Sol_LoadSettings(engine)
    local _, settings_loaded=LucieDecode.decode_file(SS_Path.Sol_MergePath({engine.root, "settings.slr"}))
    --> section "window"
    local window_section=settings_loaded["window"]
    if window_section then
        local window_width  =window_section["width"]  or engine.window_size.x
        local window_height =window_section["height"] or engine.window_size.y
        local window_title  =window_section["title"]  or engine.window_title
        engine.window_size,engine.window_title=SM_Vector.Sol_NewVector(window_width, window_height),window_title
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
    --> section "viewport"
    local viewport_section=settings_loaded["viewport"]
    if viewport_section then
        engine.viewport_size=SM_Vector.Sol_NewVector(viewport_section["width"] or engine.viewport_size.x, viewport_section["height"] or engine.viewport_size.y)
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
end

function module.Sol_InitEngine(engine, path_resources)
    local begun=os.clock()
    --> assign the location of the resource path:
    engine.root, engine.storage.root = path_resources, path_resources ; dmsg("engine.root: "..engine.root)
    --> init the window & viewport:
    module.Sol_LoadSettings(engine)
    module.Sol_SetWindowFromEngine(engine)
    module.Sol_AdjustViewportAtCenter(engine)
    --> init the language:
    SS_Storage.Sol_LoadLanguage(engine.storage, "en_US")
    --> finally, initialize the modes:
    SWM_Mode.Sol_InitWorldMode(engine, engine.world_mode)
    dmsg("Sol_InitEngine() took %s seconds.", os.clock() - begun)
end

--[[ Tick Related Functions ]]
function module.Sol_NewResizeEventEngine(engine, new_width, new_height)
    engine.window_size = SM_Vector.Sol_NewVector(new_width, new_height)
    module.Sol_AdjustViewportAtCenter(engine)
    module.Sol_SetWindowFromEngine(engine)
    SWM_Mode.Sol_ResizeEventWorldMode(engine, engine.world_mode)
end

function module.Sol_KeypressEventEngine(engine, key)
    if engine.current_mode == SV_Consts.engine_modes.MENU then          mwarn("engine.current_mode is not yet implemented.")
    elseif engine.current_mode == SV_Consts.engine_modes.WORLD then     SWM_Mode.Sol_KeypressEventWorldMode(engine, engine.world_mode, key)
    else mwarn("engine.current_mode is not yet implemented.") end
end

function module.Sol_TickEngine(engine)
    SS_Storage.Sol_CleanCacheInStorage(engine.storage)
    if      engine.current_mode == SV_Consts.engine_modes.MENU   then mwarn("engine.current_mode is not yet implemented.")
    elseif  engine.current_mode == SV_Consts.engine_modes.WORLD  then SWM_Mode.Sol_TickWorldMode(engine, engine.world_mode)
    else mwarn("engine.current_mode is not yet implemented.") end
end

--[[ Draw Related Functions ]]
function module.Sol_DrawEngine(engine)
    if      engine.current_mode == SV_Consts.engine_modes.MENU   then mwarn("engine.current_mode is not yet implemented.")
    elseif  engine.current_mode == SV_Consts.engine_modes.WORLD  then
        dmsg("drawing tile...")
        SWM_Mode.Sol_DrawWorldMode(engine, engine.world_mode)
        SD_Canvas.Sol_DrawCanvas(engine.world_mode.viewport, engine.viewport_position)
    else mwarn("engine.current_mode is not yet implemented.") end
end

--
return module