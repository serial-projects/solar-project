-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local spi_instance 	= require("Solar.libspi.instance")
local spi_consts 		= require("Solar.libspi.consts")
local module = {}

-- puts(message[r0]: string) 
local function sysc_puts(_, instance) 	dmsg(tostring(instance.registers.R0)) end

-- write(message[r0]: string)
local function sysc_write(_, instance)	
	dmsg("thread: \"%s\", says: \"%s\"", instance.name, tostring(instance.registers.R0)) 
end

-- exit(exit_code[r0]: number)
local function sysc_exit(_, instance)
	os.exit(type(instance.registers.R0) == "number" and instance.registers.R0 or 0)
end

-- new_thread(begin_at[r0]: string | "main", thread_name[r1]: string | random name ...)
local function sysc_new_thread(context, instance)
	local begin_at=type(instance.registers.R0)=="string" and instance.registers.R0 or "main"
	local thread_name=type(instance.registers.R1)=="string" and instance.registers.R1 or (instance.name .. "$" .. string.genstr())
	if context.label_addr[begin_at] then
		local proto_thread=spi_instance.SPI_NewInstance(thread_name)
		proto_thread.registers.PC=context.label_addr[begin_at]
		table.insert(context.spawned_threads, proto_thread)
	else
		instance:set_error("new thread request failed, no label: %s", begin_at)
	end
end

-- get_thread_status(thread_name[r0]: string) -> status[r0]: number
local function sysc_get_thread_status(context, instance)
	local thread_name=instance.registers.R0
	if type(thread_name) ~= "string" then
		instance:set_error("invalid thread name (at get_thread_status system call): %s", tostring(thread_name))
	else
		for _, thread in ipairs(context.spawned_threads) do
			if thread.name == thread_name then
				instance.registers.R0 = thread.status
				return
			end
		end
		instance.registers.R0 = -1
	end
end

-- clear_threads(put_on_stack_cleaned_threads_names[r0]: number) -> amount_threads_cleaned[r0]: number
local function sysc_clear_threads(context, instance)
	local put_on_stack_cleaned_threads_names = (instance.registers.R0 == 0)
	local cleaned_thread_name_list = {}
	for thread_index, thread in ipairs(context.spawned_threads) do
		if thread.status == spi_consts.SPI_InstanceStatus.DIED or spi_consts.SPI_InstanceStatus.FINISHED then
			table.insert(cleaned_thread_name_list, thread.name)
			context.spawned_threads[thread_index]=nil
		end
	end
	instance.registers.R0=#cleaned_thread_name_list
	table.unimerge(instance.stack, cleaned_thread_name_list)
end

-- adjust_performance(desired_performance[r0]: number | string["unlimited", "max, "min"])
local function sysc_adjust_performance(context, instance)
	local PERFORMANCE_DEFAULT_VALUES = {
		max 			= 25,
		min 			= 10,
		unlimited = -1,
	}
	local desired_performance=instance.registers.R0
	if type(desired_performance) ~= "number" then
		if PERFORMANCE_DEFAULT_VALUES[desired_performance] then
			context.performance=PERFORMANCE_DEFAULT_VALUES[desired_performance]
			dmsg("performance was changed, new performance: %d", context.performance)
		end
	else
		context.performance=desired_performance
	end
end

-- module.SPI_GenerateBasicSystemCallsTable():
function module.SPI_GenerateBasicSystemCallsTable()
	return {
		-- output functions:
		puts 	= sysc_puts,
		write	= sysc_write,
		-- exit function:
		exit  = sysc_exit,
		-- thread functions:
		new_thread 				= sysc_new_thread,
		get_thread_status = sysc_get_thread_status,
		clear_threads			= sysc_clear_threads,
		-- system operations:
		adjust_performance= sysc_adjust_performance
	}
end
return module