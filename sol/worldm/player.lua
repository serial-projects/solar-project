local smath=require("sol.smath")
local defaults=require("sol.defaults")
local drawrec= require("sol.drawrec")
local module={}

--
function module.Sol_NewPlayer()
  return {
    type = "player",
    name = "player",
    --[[ inv. and pets :) ]]
    inventory = {},
    pets = {},
    --[[ walking ]]
    walk_speed = 4,
    walk_speed_texture_counter_add = 0.1,
    --[[ running ]]
    run_speed = 8,
    run_speed_texture_counter_add = 0.5,
    --[[ speed and looking_direction ]]
    current_speed = 0,
    looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.DOWN,
    --[[ draw ]]
    draw = nil,
    --[[ rel_position and other. ]]
    rel_position = smath.Sol_NewVector(0, 0),
    rectangle = smath.Sol_NewRectangle(nil, defaults.SOL_PLAYER_SIZE),
  }
end

function module.Sol_LoadPlayerRelativePosition(world_mode, player)
  player.rel_position.x=math.floor(world_mode.viewport_size.x/2)-math.floor(player.rectangle.size.x/2)
  player.rel_position.y=math.floor(world_mode.viewport_size.y/2)-math.floor(player.rectangle.size.y/2)
  dmsg("Sol_LoadPlayerRelativePosition() set the player.rel_position to x = %d and y = %d", player.rel_position.x, player.rel_position.y)
end

--[[ Draw Related Functions ]]
function module.Sol_DrawPlayer(engine, world_mode, player)
  local posx, posy    =smath.Sol_UnpackVectorXY(player.rel_position)
  local width, height =smath.Sol_UnpackVectorXY(player.rectangle.size)
  player.draw.using_recipe = player.looking_direction
  drawrec.Sol_DrawRecipe(engine, player.draw, posx, posy, width, height)
end

--
return module