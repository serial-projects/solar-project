-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SUI_Display   = require("Solar.UI.Display")
local SV_Defaults   = require("Solar.Values.Defaults")
local SM_Color      = require("Solar.Math.Color")
local SWM_Player    = require("Solar.Modes.World.Player")
local SWM_World     = require("Solar.Modes.World.World")
local SWM_UI        = require("Solar.Modes.World.UI")

local SSE_Message   = require("Solar.Services.Message")

-- local wload = require("sol.worldm.wload")

local module={}
--
function module.Sol_NewWorldMode()
    return {
        viewport        = nil,  viewport_size   = nil,
        worlds          = {},   current_world   = nil,  load_world_request = nil,
        player          = SWM_Player.Sol_NewPlayer(),
        main_display    = nil,
        -- tick stage:
        tick_counter    = 0,
        do_world_tick   = true,
        -- draw stage:
        draw_counter    = 0,
        do_world_draw   = true,
        -- services:
        message_service = SSE_Message.Sol_NewMessageService()
    }
end

--[[ Quit Stuff ]]--
function module.Sol_QuitWorldMode(engine, world_mode)
    love.event.quit(0)
end

--[[ Init Stuff ]]--
function module.Sol_InitWorldMode(engine, world_mode)
    --> init the viewport:
    world_mode.viewport     = love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
    world_mode.viewport_size= engine.viewport_size
    world_mode.main_display = SUI_Display.Sol_NewDisplay({size=engine.viewport_size})
    
    --> init the MsgService:
    SSE_Message.Sol_InitMessageService(engine, world_mode.message_service, world_mode.main_display)
    world_mode.message_service.stack = {
        SSE_Message.Sol_NewDialogForm({ text = "Hello World!", who = "Solar Engine" }),
        SSE_Message.Sol_NewDialogForm({ text = "Your game is currently updated!", who = "Solar Engine" })
    }

    --> init the UI:
    SWM_UI.Sol_InitWorldModeGUI(engine, world_mode)

    --> init the player:
    SWM_Player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)

    --> incase no world is loaded, load the internal level called "niea-room"
    local proto_world = SWM_World.Sol_NewWorld()
    SWM_World.Sol_InitWorld(engine, world_mode, proto_world, "niea-room")
    world_mode.worlds["niea-room"], world_mode.current_world=proto_world, "niea-room"
end

--[[ Tick Related Functions ]]
function module.Sol_TickWorldModeUI(engine, world_mode)
    --> update: world_mode.display_debug_ui_frame_memoryusage_label
    local amount_used_memory=tostring(collectgarbage("count") / 1000):sub(1, 4)
    world_mode.display_debug_ui_frame_memoryusage_label.text=string.format(world_mode.display_debug_ui_frame_memoryusage_label.non_formatted_text, amount_used_memory)
    world_mode.display_debug_ui_frame_playerpositionabs_label.text=string.format(world_mode.display_debug_ui_frame_playerpositionabs_label.non_formatted_text, world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y)
    world_mode.display_debug_ui_frame_playerpositionrel_label.text=string.format(world_mode.display_debug_ui_frame_playerpositionrel_label.non_formatted_text, world_mode.player.rel_position.x, world_mode.player.rel_position.y)
end

local function Sol_TickCheckIfWorldChangeHasBeenRequested(engine, world_mode)
    if world_mode.load_world_request then
        local lwr_name        = world_mode.load_world_request["name"]
        local lwr_do_change   = world_mode.load_world_request["change"]
        dmsg("Sol_TickCheckIfWorldChangeHasBeenRequested() has detected a world request (from \"%s\" -> \"%s\")", world_mode.current_world, lwr_name)
        local proto_world = SWM_World.Sol_NewWorld()
        SWM_World.Sol_InitWorld(engine, world_mode, proto_world, lwr_name)
        world_mode.worlds[lwr_name]=proto_world
        if lwr_do_change then world_mode.current_world = lwr_name end
        world_mode.load_world_request = nil
    end
end

function module.Sol_TickWorldMode(engine, world_mode)
    Sol_TickCheckIfWorldChangeHasBeenRequested(engine, world_mode)
    module.Sol_TickWorldModeUI(engine, world_mode)
    SSE_Message.Sol_TickMessageService(world_mode.message_service)
    SUI_Display.Sol_TickDisplay(world_mode.main_display)
    -- NOTE: 
    if world_mode.current_world and world_mode.do_world_tick then
        local current_world=world_mode.worlds[world_mode.current_world]
        SWM_World.Sol_TickWorld(engine, world_mode, current_world)
    end
    world_mode.tick_counter = world_mode.tick_counter + 1
end

function module.Sol_ResizeEventWorldMode(engine, world_mode)
    SUI_Display.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end

function module.Sol_KeypressEventWorldMode(engine, world_mode, key)
    local _keytable={
        ["f3"]      =function()
            world_mode.display_debug_ui_frame.visible = not world_mode.display_debug_ui_frame.visible
        end,
        ["escape"]  =function()
            world_mode.display_exit_ui_frame.visible = not world_mode.display_exit_ui_frame.visible
            world_mode.do_world_tick = not world_mode.do_world_tick
        end,
        ["f5"]      =function()
            if not world_mode.message_service.running then
                world_mode.message_service.should_initialize = true
            end
        end
    }
    if _keytable[key] then _keytable[key]() end
    SSE_Message.Sol_KeypressMessageService(world_mode.message_service, key)
    --
    if world_mode.current_world and world_mode.do_world_tick then
        local current_world=world_mode.worlds[world_mode.current_world]
        SWM_World.Sol_KeypressEventWorld(engine, world_mode, current_world, key)
    end
end

--[[ Draw Related Functions ]]
function module.Sol_DrawWorldMode(engine, world_mode)
    love.graphics.setCanvas(world_mode.viewport)
        love.graphics.clear(SM_Color.Sol_TranslateColor(SV_Defaults.SOL_VIEWPORT_BACKGROUND))
        if world_mode.current_world and world_mode.do_world_draw then
            local current_world=world_mode.worlds[world_mode.current_world]
            if current_world then SWM_World.Sol_DrawWorld(engine, world_mode, current_world) end
        end
        SUI_Display.Sol_DrawDisplay(world_mode.main_display)
        SSE_Message.Sol_DrawMessageService(engine, world_mode.message_service)
    love.graphics.setCanvas()
    world_mode.draw_counter = world_mode.draw_counter + 1
end

--
return module