-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

--
-- SPI (Simple Programming Interface) by Pipes Studios.
-- The SPI project has the simple objective of being a simple language, without
-- any complications or problems, it follows the syntax of assembler.
--
_G.SPI_AdquireTimeUsingFunction = os.clock

local unpack=table.unpack or unpack

local consts        =require("Library.SPI.Consts")
local text          =require("Library.SPI.Text")
local instructions  =require("Library.SPI.Instructions")

local ETable        =require("Library.Extra.Table")
local EString       =require("Library.Extra.String")

local module = {}

-- SPI_GenerateAPIVariables() -> table
local function  SPI_GenerateAPIVariables()
    return {
        --> SPI_THREAD_<...>: expose the states of the machine.
        ["SPI_THREAD_RUNNING"]  = consts.SPI_InstanceStatus.RUNNING,
        ["SPI_THREAD_FINISHED"] = consts.SPI_InstanceStatus.FINISHED,
        ["SPI_THREAD_DIED"]     = consts.SPI_InstanceStatus.DIED,
        ["SPI_THREAD_WAITING"]  = consts.SPI_InstanceStatus.WAITING,
        ["SPI_THREAD_SLEEPING"] = consts.SPI_InstanceStatus.SLEEPING
    }
end

-- SPI_NewInstance() -> SPI_Instance
function module.SPI_NewInstance(name)
    local proto_instance = {
        name        = name or EString.genustr(),
        variables   = SPI_GenerateAPIVariables(),
        stack       = {}, call_stack = {},
        registers   = { A = 0, B = 0, C = 0, X = 0, Y = 0, Z = 0, PC = 1, PCI = true, EQ = 0, GT = 0 },
        status      = consts.SPI_InstanceStatus.RUNNING,
        sleep_until = 0,
        error_msg   = nil
    }
    function proto_instance:set_error(reason, ...)
        self.status     = consts.SPI_InstanceStatus.DIED
        self.error_msg  = string.format("on instance: \"%s\", ", self.name) .. string.format(reason, ...)
    end
    return proto_instance
end

-- SPI_TickInstance(context: SPI_Context, instance: SPI_Instance)
function module.SPI_TickInstance(context, instance)
    --> check the status and return if nothing to do.
    if instance.status ~= consts.SPI_InstanceStatus.RUNNING then
        -- this range considers: finished: 2, died: 3, waiting: 4
        if instance.status <= 4 and instance.status >= 2 then
            return instance.status
        elseif instance.status == consts.SPI_InstanceStatus.SLEEPING then
            if instance.sleep_until <= SPI_AdquireTimeUsingFunction() then
                instance.status = consts.SPI_InstanceStatus.RUNNING
            else
                return instance.status
            end
        end
    end
    --> check if the PC >= amount of code:
    local current_pc = instance.registers.PC
    if current_pc > #context.code then
        instance.status = consts.SPI_InstanceStatus.FINISHED
        return instance.status
    end
    --> everything good? then execute the code:
    local current_opcode = context.code[current_pc]
    local current_opcode_structure = instructions.SPI_PerformTable[current_opcode]
    if current_opcode_structure then
        --> check if is possible to execute this argument:
        local current_instruction_nargs = current_opcode_structure.args
        if current_instruction_nargs > 0 then
            if ( current_pc + 1 ) + current_instruction_nargs > #context.code then
                instance:set_error("instruction: %s requires %d arguments!", current_opcode, current_instruction_nargs)
                return instance.status
            end
        end
        --> begin executing the wrapped function on the instruction wrapper:
        -- NOTE: xtable.lua is required with function table.sub()
        local arguments = ETable.sub(context.code, current_pc + 1, (current_pc + 1) + current_instruction_nargs)
        current_opcode_structure.wrap(context, instance, unpack(arguments))
        --> should we increment the PCI this time?
        if instance.registers.PCI then
            instance.registers.PC = (instance.registers.PC + 1) + current_instruction_nargs
        else
            instance.registers.PCI = true
        end
    else
        instance:set_error("invalid instruction: %s (PC: %d)", current_opcode, current_pc)
        return instance.status
    end
    --> finish or skip everything (aka. code execution):
    return instance.status
end

return module