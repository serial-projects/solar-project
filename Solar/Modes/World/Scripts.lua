-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SPI_Script  = require("Solar.libspi.script")
local SS_Path     = require("Solar.System.Path")
local SM_Vector   = require("Solar.Math.Vector")
local SWMS_InWorld= require("Solar.Modes.World.Scripting.InWorld")

local module = {}
--
function module.Sol_NewScriptService()
  return {
    contexts = {},
    enabled = true
  }
end

-- __Sol_GenericWhenDiedWrapper(script: Sol_Script): just a generic function to print out that the script has died.
local function __Sol_GenericWhenDiedWrapper(script)
	dmsg("context \"%s\" has just died, main reason: %s", script.name, script.context.instance.error_msg)
end

-- Sol_LoadScript(engine, world_mode, world, script_service: Sol_ScriptService, recipe: {name = string, when_finish = function | nil, when_died = function | nil, ticks_per_frame = number, begin_at = string}):
-- The function will load the script to the ScriptService (it will load the file & create a new context).
function module.Sol_LoadScript(engine, world_mode, world, script_service, recipe)
  -- SOL_Script = { context = SPI_Context, when_finish = function | nil, when_die = function | nil }
  local proto_sol_script = {
    context       = SPI_Script.SPI_NewContext(recipe["name"]),
    when_finish   = recipe["when_finish"],
    when_died     = recipe["when_died"] or __Sol_GenericWhenDiedWrapper,
    performance   = recipe["ticks_per_frame"] or 10
  }
  local place_execution = recipe["place_execution"] or "inworld"
  local path_file = SS_Path.Sol_MergePath({engine.root, "scripts/" .. recipe["source"] .. ".spi"})
  dmsg("Sol_LoadScript() is loading script %s in path %s!", recipe["name"], path_file)
  --> load the script context:
  SPI_Script.SPI_LoadContextUsingFile(proto_sol_script.context, path_file, love.filesystem.newFile)
  SPI_Script.SPI_SetInstanceLocation(proto_sol_script.context, "main", recipe["begin_at"] or "main")
  --> inject the world system calls:
  if place_execution == "inworld" then SWMS_InWorld.Sol_ImplementInWorldSystemCalls(engine, world_mode, world, proto_sol_script.context) end
  --> add the context to the context list:
  table.insert(script_service.contexts, proto_sol_script)
end

-- MAX_AMOUNT_TIME_PERFORMANCE: max amount of time (in seconds) that a script can execute in a single tick.
local MAX_AMOUNT_TIME_PERFORMANCE = 10

-- UNLIMITED_PERFORMANCE_VALUE: the value the context.performance must be to have unlimited performance.
local UNLIMITED_PERFORMANCE_VALUE = -1

-- __Sol_TickScript(script_service: Sol_ScriptService, current_script_id: number, script: Sol_Script):
-- using the current_script_id (aka. the index of the context), run the context instance for a certain
-- amount (aka. amount of performance on the context).
local function __Sol_TickScript(script_service, current_script_id, script)
	local function __invoke_callback(f, ...)
		if f ~= nil and type(f) == "function" then
			f(...)
		end
	end
	--
	local tick_counter, max_performing_time = 0, os.time() + MAX_AMOUNT_TIME_PERFORMANCE
	while true do
		-- check for the performance:
		local current_performance=script.context.performance
		if tick_counter >= current_performance then
			if current_performance ~= UNLIMITED_PERFORMANCE_VALUE then
				break
			end
		else
			tick_counter = tick_counter + 1
		end
		-- check for execution time:
		if os.time() >= max_performing_time then
			script.context.instance:set_error("script took too long to perform!")
		end
		-- perform here:
		local context_status = SPI_Script.SPI_TickContext(script.context)
		if context_status ~= SPI_Script.consts.SPI_InstanceStatus.RUNNING then
			if context_status == SPI_Script.consts.SPI_InstanceStatus.FINISHED then
				__invoke_callback(script.when_finish, script)
				script_service.contexts[current_script_id]=nil
				break
			elseif context_status == SPI_Script.consts.SPI_InstanceStatus.DIED then
				__invoke_callback(script.when_died, script) 
				script_service.contexts[current_script_id]=nil
				break
			end
		end
		-- ...
	end
end

-- Sol_TickScriptService(script_service: Sol_ScriptService):
-- Tick all the contexts inside the script service.
function module.Sol_TickScriptService(script_service)
  for sol_script_index, sol_script in ipairs(script_service.contexts) do
  	__Sol_TickScript(script_service, sol_script_index, sol_script)
  end
end

--
return module