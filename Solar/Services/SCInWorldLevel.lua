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
    local begun_registering_functions=os.clock()
    --[[ Player Absolute Position ]]--
    context.system_calls["SolWorld_GetPlayerPosition"]=function(_, instance)
        local xpos, ypos = world_mode.player.rectangle.position:unpackxy()
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
    --> :: functions to change the world
    context.system_calls["SolWorld_RequestWorldLoad"]=function(_, instance)
        local world_name = instance.registers.X
        world_mode.load_world_request = {name = world_name, change = false}
    end
    context.system_calls["SolWorld_SetCurrentWorld"]=function(_, instance)
        local world_name = instance.registers.X
        if world_mode.worlds[world_name] then
            world_mode.current_world = world_name
        else
            instance.registers.X = 0
        end
    end
    context.system_calls["SolWorld_SetWorld"]=function(_, instance)
        local world_name = instance.registers.X
        world_mode.load_world_request = {name = world_name, change = true}
    end
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
    context.system_calls["SolWorld_SetTileProperty"]=function(_, instance)
        local tile_name = instance.registers.X
        local tile_property_key = instance.registers.Y
        local tile_property_new_value = instance.registers.Z
        for _, tile in ipairs(world.tiles) do
            if tile.name == tile_name then
                tile[tile_property_key] = tile_property_new_value
            end
        end
    end
    dmsg("finished registering world system calls in %f seconds.", os.clock() - begun_registering_functions)
end

return module