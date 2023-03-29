local module = {}

local utils = require("solar.utils")
local consts = require("solar.consts")

--
-- Player
--
function Solar_NewPlayer()
  return {
    abs_position = utils.Solar_NewVectorXY(0, 0),
    rel_position = utils.Solar_NewVectorXY(0, 0),
    size = utils.Solar_NewVectorXY(consts.SOLAR_PLAYER_WIDTH, consts.SOLAR_PLAYER_HEIGHT),
    looking_at = consts.SOLAR_PLAYER_LOOKING_DOWN,
    --
    draw_using = consts.SOLAR_DRAW_USING_COLOR,
    color = utils.Solar_NewColor(100, 100, 100),
    --
    textures = {}, texture_index = 0, texture_timing = 0,
    speed = 4
  }
end
function Solar_DrawPlayer(engine, world_mode, player)
  if player.draw_using == consts.SOLAR_DRAW_USING_COLOR then
    love.graphics.setColor(utils.Solar_TranslateColor(player.color))
    love.graphics.rectangle("fill", player.rel_position.x, player.rel_position.y, player.size.x, player.size.y)
  end
end
module.Solar_DrawPlayer = Solar_DrawPlayer

--
return module