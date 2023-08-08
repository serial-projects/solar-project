-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local spi_instance 	= require("Solar.libspi.instance")
local spi_consts 		= require("Solar.libspi.consts")
local module = {}

-- debug()
local function sysc_debug(_, instance)
	dmsg("TOP Registers: A = %d, B = %d, C = %d", instance.registers.A, instance.registers.B, instance.registers.C)
	dmsg("POS Registers: X = %d, Y = %d, Z = %d", instance.registers.X, instance.registers.Y, instance.registers.Z)
end

-- puts(message[A]: string) 
local function sysc_puts(_, instance) 	dmsg(tostring(instance.registers.A)) end

-- write(message[A]: string)
local function sysc_write(_, instance)	
	dmsg("thread: \"%s\", says: \"%s\"", instance.name, tostring(instance.registers.A))
end

-- exit(exit_code[A]: number)
local function sysc_exit(_, instance)
	os.exit(type(instance.registers.A) == "number" and instance.registers.A or 0)
end

-- new_thread(begin_at[A]: string | "main", thread_name[B]: string | random name ...)
local function sysc_new_thread(context, instance)
	local begin_at=type(instance.registers.A)=="string" and instance.registers.A or "main"
	local thread_name=type(instance.registers.B)=="string" and instance.registers.B or (instance.name .. "$" .. string.genstr())
	if context.label_addr[begin_at] then
		local proto_thread=spi_instance.SPI_NewInstance(thread_name)
		proto_thread.registers.PC=context.label_addr[begin_at]
		table.insert(context.spawned_threads, proto_thread)
	else
		instance:set_error("new thread request failed, no label: %s", begin_at)
	end
end

-- get_thread_status(thread_name[A]: string) -> status[A]: number
local function sysc_get_thread_status(context, instance)
	local thread_name=instance.registers.A
	if type(thread_name) ~= "string" then
		instance:set_error("invalid thread name (at get_thread_status system call): %s", tostring(thread_name))
	else
		for _, thread in ipairs(context.spawned_threads) do
			if thread.name == thread_name then
				instance.registers.A = thread.status
				return
			end
		end
		instance.registers.A = -1
	end
end

-- clear_threads(put_on_stack_cleaned_threads_names[A]: number) -> amount_threads_cleaned[A]: number
local function sysc_clear_threads(context, instance)
	local put_on_stack_cleaned_threads_names = (instance.registers.A == 0)
	local cleaned_thread_name_list = {}
	for thread_index, thread in ipairs(context.spawned_threads) do
		if thread.status == spi_consts.SPI_InstanceStatus.DIED or spi_consts.SPI_InstanceStatus.FINISHED then
			table.insert(cleaned_thread_name_list, thread.name)
			context.spawned_threads[thread_index]=nil
		end
	end
	instance.registers.A=#cleaned_thread_name_list
	table.unimerge(instance.stack, cleaned_thread_name_list)
end

-- adjust_performance(desired_performance[A]: number | string["unlimited", "max, "min"])
local function sysc_adjust_performance(context, instance)
	local PERFORMANCE_DEFAULT_VALUES = {
		max 			= 25,
		min 			= 10,
		unlimited = -1,
	}
	local desired_performance=instance.registers.A
	if type(desired_performance) ~= "number" then
		if PERFORMANCE_DEFAULT_VALUES[desired_performance] then
			context.performance=PERFORMANCE_DEFAULT_VALUES[desired_performance]
			dmsg("performance was changed, new performance: %d", context.performance)
		end
	else
		context.performance=desired_performance
	end
end

-- sleep(amount_time_seconds[A]: number)
local function sysc_sleep(_, instance)
	local amount_time_seconds = instance.registers.A
	if type(amount_time_seconds) == "number" then
		dmsg("thread set to sleep for %d secs.", amount_time_seconds)
		instance.sleep_until = SPI_AdquireTimeUsingFunction() + amount_time_seconds
		instance.status = spi_consts.SPI_InstanceStatus.SLEEPING
	end
end

-- module.SPI_GenerateBasicSystemCallsTable():
function module.SPI_GenerateBasicSystemCallsTable()
	return {
		-- output functions:
		["debug"] = sysc_debug,
		puts 	= sysc_puts,
		write	= sysc_write,
		-- exit function:
		exit  = sysc_exit,
		-- thread functions:
		new_thread 				= sysc_new_thread,
		get_thread_status = sysc_get_thread_status,
		clear_threads			= sysc_clear_threads,
		-- system operations:
		adjust_performance= sysc_adjust_performance,
		sleep 						= sysc_sleep
	}
end
return module