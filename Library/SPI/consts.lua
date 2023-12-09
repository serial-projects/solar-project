-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

-- SPI_InstanceStatus: keep track of the instance:
-- RUNNING:               the machine is currently executing code.
-- FINISHED:              when the PC (program counter) reached the end of the memory or HALT was called.
-- DIED:                  when the instance encountered a error (or DIE was called).
-- WAITING:               set when the instance is waiting for something.
-- SLEEPING:              the instance is sleeping until a certain time.
module.SPI_InstanceStatus = table.enum(1, {"RUNNING", "FINISHED", "DIED", "WAITING", "SLEEPING"})

return module