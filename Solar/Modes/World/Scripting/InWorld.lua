local SM_Vector = require("Solar.Math.Vector")
local module = {}

-- Sol_ImplementInWorldSystemCalls(engine, world_mode, world, context: SPI_Context):
-- This will implement the default INWORLD system calls, this system calls can only be
-- executed when the script in a WORLD level. There is a few levels in the Solar Engine
-- that a script can execute: ENGINE level, GAME level and WORLD level:
-- * ENGINE: this script can execute in all modes (world mode, credits mode, etc).
-- * GAME  : this script can execute in all worlds.
-- * WORLD : this script can only execute in isolated worlds.
function module.Sol_ImplementInWorldSystemCalls(engine, world_mode, world, context)
  --[[ Player Absolute Position ]]--
  context.system_calls["SolWorld_GetPlayerPosition"]=function(_, instance)
    local xpos, ypos = SM_Vector.Sol_UnpackVectorXY(world_mode.player.rectangle.position)
    table.insert(instance.stack, xpos)
    table.insert(instance.stack, ypos)
  end
  context.system_calls["SolWorld_SetPlayerPosition"]=function(_, instance)
    local xpos, ypos = instance.registers.X, instance.registers.Y
    if type(xpos) == "number" and type(ypos) == "number" then
      world_mode.player.rectangle.position.x, world_mode.player.rectangle.position.y = xpos, ypos
    else
      instance:set_error("SolWorld_SetPlayerPosition system call expected X & Y to be number!")
    end
  end
  --[[ Player Operations ]]--
  context.system_calls["SolWorld_GetPlayerSize"]=function(_, instance)
    table.insert(instance.stack, world_mode.player.rectangle.size.x)
    table.insert(instance.stack, world_mode.player.rectangle.size.y)
  end
  --[[ World Stuff ]]--
  context.system_calls["SolWorld_SetWorldSize"]=function(_, instance)
    local xpos, ypos = instance.registers.X, instance.registers.Y
    if type(xpos) == "number" and type(ypos) == "number" then
      world.world_size.x = xpos
      world.world_size.y = ypos
    end
  end
  context.system_calls["SolWorld_GetWorldSize"]=function(_, instance)
    table.insert(instance.stack, world.world_size.x)
    table.insert(instance.stack, world.world_size.y)
  end
end

return module