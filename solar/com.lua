local module = {}
local sfmt = string.format
--
local utils = require("solar.utils")
local wworld= require("solar.worlds.world")

--

-- TODO: implement translation.

-- What exactly are commands? Well... in some parts, commands do play a very
-- important role on the player-world interaction, basically commands are a
-- very form of programming for elements, they can do some quick actions
-- like Solar_TeleportToWorld (which teleports the player to the world) or
-- Solar_LoadWorldAndKeepCache (which forces the world to loop and to kept
-- in cache for a unknown amount of time), the commands can perform very
-- simple math operations that do not contains brackets. For advanced stuff,
-- consider using a Basil Script for that. There are only global and local
--  variable and you can access them by using the prefix ('$' for local and
-- '@' for global). Commands also supports labels in case you need looping.

local RUNNING 	= 0
local FINISHED 	= 1
local DIED 			= 2
local SLEEPING 	= 3

-- Utilities during runtime.
function Solar_RunFunction(run_function, ...)
	if run_function then
		local args = {...}
		local sucess, error_str = pcall(function()
			return run_function(unpack(args))
		end)
		return sucess, error_str
	end
	return nil
end
function Solar_WarnCommand(command, text)
	if command.enable_warning then
		Solar_RunFunction(command.when_warning, text)
	end
end
module.Solar_WarnCommand = Solar_WarnCommand
function Solar_RuntimeCrashCommand(engine, command, reason)
	print(sfmt("[%s]: RuntimeCrash at (%d, aka: \"%s\"), reason: %s", command.name, command.command_index, command.commands[command.command_index], reason))
	print("Dumping the local/global variables...")
	for vn, vv in ipairs(command.local_vars) 		do print(sfmt("\t[$%s]: %s", vn, vv)) end
	for vn, vv in ipairs(engine.shared_values) 	do print(sfmt("\t[@%s]: %s", vn, vv)) end
	command.status = DIED
end
function Solar_GetData(engine, command, token)
	local function make_sure_exists(t, value)
		-- NOTE: allow true/false
		if value == nil then
			return Solar_RuntimeCrashCommand(engine, command, sfmt("value for %s was not defined!", t))
		end
		return value
	end
	local prefix, suffix=token:sub(1, 1), token:sub(#token, #token)
	--[[ Global '@' and '$' local ]]--
	if prefix=='$' or prefix=='@' then
		local nopfx = token:sub(2,#token)
		local value = (prefix == '$' and make_sure_exists(token, command.local_vars[nopfx]) or make_sure_exists(token, engine.shared_values[nopfx]))
		return value
	--[[ strings / numbers ]]--
	elseif (prefix=='"' or prefix=='\'') and (suffix=='"' or suffix=='\'') then
		return token:sub(2,#token-1)
	elseif tonumber(token) ~= nil then
		return tonumber(token)
	--[[ everything else is unknown ]]--
	else
		return Solar_RuntimeCrashCommand(engine, command, ("invalid token: "..token))
	end
end
module.Solar_GetData = Solar_GetData
function Solar_SetData(engine, command, token, value)
	local prefix = token:sub(1, 1)
	--[[ Global '@' and '$' local ]]--
	if prefix=='$' or prefix=='@' then
		local nopfx=token:sub(2,#token)
		if prefix=='$' then command.local_vars[nopfx]=value
		else engine.shared_values[nopfx]=value end
	else
		--[[ everything else is wrong? ]]--
		Solar_WarnCommand(command, "invalid token value set: "..token)
	end
end
function Solar_FillStringVariablesValues(engine, command, s)
	-- token we want to find: '$' or '@'
	local final_string = ""
	local index, length = 1, #s
	while index <= length do
		local char = s:sub(index, index)
		if char == '$' or char == '@' then
			local var_name, valsub = "", nil
			for vnindex = index + 1, length do
				local ch = s:sub(vnindex, vnindex)
				if utils.Solar_IsValidCharacter(ch) then var_name=var_name..ch
				else break end
			end
			--
			valsub = (char == '$') and command.local_vars[var_name] or engine.shared_values[var_name]
			final_string = final_string .. valsub
			--
			index = index + #var_name
		else
			final_string = final_string .. char
		end
		index = index + 1
	end
	return final_string
end

-- Define the command table
local Solar_CommandTable = {}

--
--[[ Not So Basic Commands ]]--
--

-- Solar_GetPlayerPosition	<dest_variable(x)> 		<dest_variable(y)>
function Solar_PerformGetPlayerPosition(engine, command, destx, desty)
	local xpos, ypos = engine.world_mode.player.abs_position.x, engine.world_mode.player.abs_position.y
	Solar_SetData(engine, command, destx, xpos)
	Solar_SetData(engine, command, desty, ypos)
end
Solar_CommandTable["Solar_GetPlayerPosition"]={wrap=Solar_PerformGetPlayerPosition, nargs=2}

-- Solar_SetPlayerPosition	<dest_variable(x)> 		<dest_variable(y)> 		<collided?>
function Solar_PerformSetPlayerPosition(engine, command, destx, desty)
	local xpos, ypos = Solar_GetData(engine, command, destx), Solar_GetData(engine, command, desty)
	local collide = wworld.Solar_TestPlayerCollisionAt(engine.world_mode.worlds[engine.world_mode.current_world], engine.world_mode.player, xpos, ypos)
	if not collide then
		engine.world_mode.player.abs_position.x, engine.world_mode.player.abs_position.y = xpos, ypos
	end
end
Solar_CommandTable["Solar_SetPlayerPosition"]={wrap=Solar_PerformSetPlayerPosition, nargs=2}

-- Solar_SetTilePosition <generic_name> <xpos> <ypos>
function Solar_PerformSetTilePosition(engine, command, tilegn, xpos, ypos)
	local xpos, ypos = Solar_GetData(engine, command, xpos), Solar_GetData(engine, command, ypos)
	wworld.Solar_SetTilePosition(engine.world_mode.worlds[engine.world_mode.current_world], tilegn, xpos, ypos)
end
Solar_CommandTable["Solar_SetTilePosition"]={wrap=Solar_PerformSetTilePosition, nargs=3}

function Solar_PerformQuit(engine, command)
	love.event.quit()
end
Solar_CommandTable["Solar_Quit"]={wrap=Solar_PerformQuit, nargs=0}

--
--[[ Basic Commands ]]--
--

-- Simple operations and other stuff.
function Solar_PerformPrint(engine, command, s)
	local prefix, suffix=s:sub(1,  1), s:sub(#s, #s)
	if (prefix=='\'' or prefix=='"') and (suffix=='\'' or suffix=='"') then
		print(Solar_FillStringVariablesValues(engine, command, s))
	else
		print(Solar_GetData(engine, command, s))
	end
end
module.Solar_PerformPrint = Solar_PerformPrint
Solar_CommandTable["Solar_Print"]={wrap=Solar_PerformPrint, nargs=1}

function Solar_PerformDefine(engine, command, name, value)
	local value = Solar_GetData(engine, command, value)
	Solar_SetData(engine, command, name, value)
end
module.Solar_PerformDefine = Solar_PerformDefine
Solar_CommandTable["Solar_Define"]={wrap=Solar_PerformDefine, nargs=2}

function Solar_PerformLabel(engine, command, name)
	command.labels[name]=command.command_index
end
Solar_CommandTable["Solar_Label"]={wrap=Solar_PerformLabel, nargs=1}

function Solar_PerformJump(engine, command, name)
	if not command.labels[name] then
		error("invalid jump: "..name)
	end
	command.command_index = command.labels[name]
end
Solar_CommandTable["Solar_Jump"]={wrap=Solar_PerformJump, nargs=1}

-- Solar_Add <x> <y>: x = x + y
function Solar_PerformAdd(engine, command, x, y)
	local xv, yv = Solar_GetData(engine, command, x), Solar_GetData(engine, command, y)
	assert(type(xv)=="number" and type(yv)=="number", "Solar_Add requires <x> and <y> to be integers!")
	Solar_SetData(engine, command, x, xv + yv)
end
Solar_CommandTable["Solar_Add"]={wrap=Solar_PerformAdd, nargs=2}

-- Solar_Sub <x> <y>: x = x - y
function Solar_PerformSub(engine, command, x, y)
	local xv, yv = Solar_GetData(engine, command, x), Solar_GetData(engine, command, y)
	assert(type(xv)=="number" and type(yv)=="number", "Solar_Sub requires <x> and <y> to be integers!")
	Solar_SetData(engine, command, x, xv - yv)
end
Solar_CommandTable["Solar_Sub"]={wrap=Solar_PerformSub, nargs=2}

-- Solar_Mul <x> <y>: x = x * y
function Solar_PerformMul(engine, command, x, y)
	local xv, yv = Solar_GetData(engine, command, x), Solar_GetData(engine, command, y)
	assert(type(xv)=="number" and type(yv)=="number", "Solar_Mul requires <x> and <y> to be integers!")
	Solar_SetData(engine, command, x, xv * yv)
end
Solar_CommandTable["Solar_Mul"]={wrap=Solar_PerformMul, nargs=2}

-- Solar_Div <x> <y>: x = x / y (this division is converted automatically to number)
function Solar_PerformDiv(engine, command, x, y)
	local xv, yv = Solar_GetData(engine, command, x), Solar_GetData(engine, command, y)
	assert(type(xv)=="number" and type(yv)=="number", "Solar_Div requires <x> and <y> to be integers!")
	Solar_SetData(engine, command, x, math.floor(xv / yv))
end
Solar_CommandTable["Solar_Div"]={wrap=Solar_PerformDiv, nargs=2}

function Solar_PerformSleep(engine, command, time)
	local tv=Solar_GetData(engine, command, time)
	if type(tv) ~= "number" then
		return Solar_RuntimeCrashCommand(engine, command, "Solar_Sleep expects <time> to be number or decimal!")
	else
		command.sleep_until=love.timer.getTime()+tv
		command.status = SLEEPING
	end
end
Solar_CommandTable["Solar_Sleep"]={wrap=Solar_PerformSleep, nargs=1}

function Solar_PerformDummy(engine, command)
	print("Marine Time Keepers")
end
Solar_CommandTable["Solar_Dummy"]={wrap=Solar_PerformDummy, nargs=0}

--
--
--
function Solar_NewCommand()
	return {
		name = "unknown-thread",
		--
		commands = {}, command_index = 1,
		status = 0, enable_warnings = true,
		labels = {}, local_vars	= {},	global_vars = {},
		steps_per_tick = 10, sleep_until = 0,
		-- when_warning(warning_message)
		-- when_error(error_message)
		when_warning = nil,
		when_error = nil,
	}
end
module.Solar_NewCommand = Solar_NewCommand
function Solar_InitCommand(engine, command)
	-- initially redirect all the warning/error to the stdout
	command.when_warning = function(warning_message)
		print("Solar_Command (Warning): "..warning_message)
	end
	command.when_error = function(error_message)
		print("Solar_Command (Error): "..error_message)
	end
end
module.Solar_InitCommand = Solar_InitCommand
function Solar_TokenizeCommand(engine, command, line)
	local tokens = utils.Solar_Tokenize(line)
	for _, token in ipairs(tokens) do table.insert(command.commands, token) end
end
module.Solar_TokenizeCommand = Solar_TokenizeCommand
function Solar_TokenizeCommands(engine, command, lines)
	for _, line in ipairs(lines) do
		Solar_TokenizeCommand(engine, command, line)
	end
end
module.Solar_TokenizeCommands = Solar_TokenizeCommands
function Solar_StepCommand(engine, command)
	if command.command_index > #command.commands then
		command.status = FINISHED
		return FINISHED
	end
	if command.status == FINISHED or command.status == DIED then
		return command.status
	elseif command.status == SLEEPING then
		if love.timer.getTime() >= command.sleep_until then
			command.status = RUNNING
		else
			return SLEEPING
		end
	end
	--
	local current_command = command.commands[command.command_index]
	if Solar_CommandTable[current_command] then
		local arguments, args, wrap = {}, Solar_CommandTable[current_command].nargs, Solar_CommandTable[current_command].wrap
		assert(command.command_index+args<=#command.commands,sfmt("%s requires %d arguments!", current_command, args))
		for index = command.command_index + 1, command.command_index + args do
			local argument = command.commands[index] table.insert(arguments, argument)
		end
		--
		pcall(function()
			wrap(engine, command, unpack(arguments))
		end)
		command.command_index = command.command_index + (1 + args)
	else
		error("invalid operation: "..current_command)
	end
end
module.Solar_StepCommand = Solar_StepCommand
function Solar_TickCommand(engine, command)
	if command.status == FINISHED or command.status == DIED then
		return
	else
		-- SLEEPING, RUNNING doesn't mean the machine needs to be halted.
		for count = 1, command.steps_per_tick do
			if Solar_StepCommand(engine, command) == FINISHED then break end
		end
	end
end
module.Solar_TickCommand = Solar_TickCommand
--
return module