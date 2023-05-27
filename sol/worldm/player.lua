local smath=require("sol.smath")
local defaults=require("sol.defaults")
local module={}

--
function Sol_NewPlayer()
  return {
    type = "player",
    name = "player",
    inventory = {},
    pets = {},
    walk_speed = 4,
    run_speed = 8,
    current_speed = 0,
    looking_direction=defaults.SOL_PLAYER_LOOK_DIRECTION.DOWN,
    --
    draw_method = defaults.SOL_DRAW_USING.COLOR,
    color = smath.Sol_NewColor4(80, 80, 80),
    textures = {},
    texture_index = 0,
    texture_timing = 0,
    --
    rel_position = smath.Sol_NewVector(0, 0),
    rectangle = smath.Sol_NewRectangle(nil, defaults.SOL_PLAYER_SIZE),
  }
end ; module.Sol_NewPlayer=Sol_NewPlayer
function Sol_LoadPlayerRelativePosition(world_mode, player)
  player.rel_position.x=math.floor(world_mode.viewport_size.x/2)-math.floor(player.rectangle.size.x/2)
  player.rel_position.y=math.floor(world_mode.viewport_size.y/2)-math.floor(player.rectangle.size.y/2)
end ; module.Sol_LoadPlayerRelativePosition=Sol_LoadPlayerRelativePosition

--[[ Draw Related Functions ]]
function Sol_DrawPlayer(engine, world_mode, player)
  if player.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(player.color))
    local posx, posy=smath.Sol_UnpackVectorXY(player.rel_position)
    local width, height=smath.Sol_UnpackVectorXY(player.rectangle.size)
    love.graphics.rectangle("fill", posx, posy, width, height)
  else
    mwarn("Sol_DrawPlayer() player draw_method is invalid, falling back to color.")
    player.draw_method=defaults.SOL_DRAW_USING.COLOR
  end
end ; module.Sol_DrawPlayer=Sol_DrawPlayer

--
return module