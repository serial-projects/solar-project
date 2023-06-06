-- TODO: yet to be implemented.

local ui=require("sol.ui")
local module={}

--[[ New mode function ]]--
function module.Sol_NewCrashMode()
  return {
    -- the main UI ::
    main_window = nil,
    -- extra contextual information ::
    current_reason = nil,
    traceback = nil,
  }
end

--[[ Init related functions ]]--
function module.Sol_InitCrashMode(engine, crash_mode)

end

--[[ Tick related functions ]]--
function module.Sol_TickCrashMode(engine, crash_mode)

end

--[[ Draw related functions ]]--
function module.Sol_DrawCrashMode(engine, crash_mode)

end

--
return module