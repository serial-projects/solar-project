local module = {}
local consts = require("solar.consts")
local smath = require("solar.smath")

--
-- Player
--
function Solar_NewPlayer()
  return {
    abs_position = smath.Solar_NewVectorXY(0, 0),
    rel_position = smath.Solar_NewVectorXY(0, 0),
    size = smath.Solar_NewVectorXY(consts.SOLAR_PLAYER_WIDTH, consts.SOLAR_PLAYER_HEIGHT),
    looking_at = consts.SOLAR_PLAYER_LOOKING_DOWN,
    --
    draw_using = consts.SOLAR_DRAW_USING_COLOR,
    color = smath.Solar_NewColor(100, 100, 100),
    --
    textures = {}, texture_index = 0, texture_timing = 0,
    speed = 4
  }
end
function Solar_DrawPlayer(engine, world_mode, player)
  if player.draw_using == consts.SOLAR_DRAW_USING_COLOR then
    love.graphics.setColor(smath.Solar_TranslateColor(player.color))
    love.graphics.rectangle("fill", player.rel_position.x, player.rel_position.y, player.size.x, player.size.y)
    -- TODO: remove on the future versions, this is just for debugging LOL.
    local dot_looking_direction_position = {
      [consts.SOLAR_PLAYER_LOOKING_UP]    = {player.rel_position.x+math.floor(player.size.x/2), player.rel_position.y},
      [consts.SOLAR_PLAYER_LOOKING_DOWN]  = {player.rel_position.x+math.floor(player.size.x/2), player.rel_position.y+player.size.y},
      [consts.SOLAR_PLAYER_LOOKING_LEFT]  = {player.rel_position.x, player.rel_position.y+math.floor(player.size.y/2)},
      [consts.SOLAR_PLAYER_LOOKING_RIGHT] = {player.rel_position.x+player.size.x-1, player.rel_position.y+math.floor(player.size.y/2)}
    }
    local current_looking_position=dot_looking_direction_position[player.looking_at]
    love.graphics.setColor(smath.Solar_TranslateColor(smath.Solar_NewColor(255, 255, 255)))
    love.graphics.rectangle("fill", current_looking_position[1], current_looking_position[2], 1, 1)
    --
  end
end
module.Solar_DrawPlayer = Solar_DrawPlayer

--
return module