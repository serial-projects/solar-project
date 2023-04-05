local module = {}
local sfmt = string.format
--
local utils = require("solar.utils")
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
	engine.handle_print(sfmt("[%s]: RuntimeCrash at (%d, aka: \"%s\"), reason: %s", command.name, command.command_index, command.commands[command.command_index], reason))
	engine.handle_print("Dumping the local/global variables...")
	for vn, vv in ipairs(command.local_vars) 		do engine.handle_print(sfmt("\t[$%s]: %s", vn, vv)) end
	for vn, vv in ipairs(engine.shared_values) 	do engine.handle_print(sfmt("\t[@%s]: %s", vn, vv)) end
	command.status = DIED
end
function Solar_GetData(engine, command, token, strip_string)
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
	elseif tonumber(token) ~= nil or prefix=='-' then
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

-- NOTE: WE ARE TAKING THE ADVANTAGE THAT EVERYTHING ON THE GLOBAL TABLE
-- TO PREVENT CIRCULAR REQUIRES! WE SHOULD LOOK THIS MORE IN DEPTH ON THE
-- FUTURE TO PREVENT BUGS AND BAD CODE.

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
	local collide = Solar_TestPlayerCollisionAt(engine.world_mode.worlds[engine.world_mode.current_world], engine.world_mode.player, xpos, ypos)
	if not collide then
		engine.world_mode.player.abs_position.x, engine.world_mode.player.abs_position.y = xpos, ypos
	end
end
Solar_CommandTable["Solar_SetPlayerPosition"]={wrap=Solar_PerformSetPlayerPosition, nargs=2}

-- Solar_GetTilePosition <generic_name> <xpos> <ypos>
function Solar_PerformGetTilePosition(engine, command, tilegn, xpos, ypos)
	local tile = Solar_GetTile(engine.world_mode.worlds[engine.world_mode.current_world], Solar_GetData(engine, command, tilegn))
	Solar_GetData(engine, command, tilegn)
	local tilex, tiley = tile.position.x, tile.position.y
	Solar_SetData(engine, command, xpos, tilex)
	Solar_SetData(engine, command, ypos, tiley)
end
Solar_CommandTable["Solar_GetTilePosition"]={wrap=Solar_PerformGetTilePosition, nargs=3}

-- Solar_SetTilePosition <generic_name> <xpos> <ypos>
function Solar_PerformSetTilePosition(engine, command, tilegn, xpos, ypos)
	local xpos, ypos = Solar_GetData(engine, command, xpos), Solar_GetData(engine, command, ypos)
	local tilegn = Solar_GetData(engine, command, tilegn)
	Solar_SetTilePosition(engine.world_mode.worlds[engine.world_mode.current_world], tilegn, xpos, ypos)
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
		engine.handle_print("[thread=\"%s\"]: %s", command.name, Solar_FillStringVariablesValues(engine, command, s))
	else
		engine.handle_print("[thread=\"%s\"]: %s", command.name, Solar_GetData(engine, command, s))
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

-- Solar_Sleep <time>
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

-- Solar_RandomNumber <min> <max> <value>
function Solar_PerformRandomNumber(engine, command, min, max, value)
	local min, max = Solar_GetData(engine, command, min), Solar_GetData(engine, command, max)
	assert(type(min)=="number","Solar_RandomNumber expects min to be number.")
	assert(type(max)=="number","Solar_RandomNumber expects max to be number.")
	local number = math.random(min, max)
	Solar_SetData(engine, command, value, number)
end
Solar_CommandTable["Solar_RandomNumber"]={wrap=Solar_PerformRandomNumber, nargs=3}

function Solar_PerformDummy(engine, command)
	engine.handle_print("[thread=\"%s\"]: Marine Time Keepers", command.name)
end
Solar_CommandTable["Solar_Dummy"]={wrap=Solar_PerformDummy, nargs=0}

--
--
--
function Solar_NewCommand()
	return {
		name = "unknown-thread",
		--
		commands = {},
		command_index = 1,
		--
		status = 0, 
		enable_warnings = true,
		--
		labels = {},
		local_vars	= {},
		global_vars = {},
		--
		steps_per_tick = 10,
		sleep_until = 0,
		--
		when_warning = nil,
		when_error = nil,
	}
end
module.Solar_NewCommand = Solar_NewCommand
function Solar_InitCommand(engine, command)
	-- initially redirect all the warning/error to the stdout
	command.when_warning = function(warning_message)
		engine.handle_print("Solar_Command (Warning): "..warning_message)
	end
	command.when_error = function(error_message)
		engine.handle_print("Solar_Command (Error): "..error_message)
	end
end
module.Solar_InitCommand = Solar_InitCommand
function Solar_TokenizeCommand(engine, command, line)
	local tokens = utils.Solar_Tokenize(line)
	for _, token in ipairs(tokens) do
		table.insert(command.commands, token)
	end
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
		return command.status
	else
		-- SLEEPING, RUNNING doesn't mean the machine needs to be halted.
		-- SLEEPING, depending of the time, it's kinda useless to tick, so break.
		for count = 1, command.steps_per_tick do
			local current_status = Solar_StepCommand(engine, command)
			if current_status == FINISHED or current_status == SLEEPING then break end
		end
	end
	return command.status
end
module.Solar_TickCommand = Solar_TickCommand
function Solar_ResetCommand(command)
	command.command_index = 1
	command.status = RUNNING
end
--
return module
