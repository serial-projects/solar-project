local module = {}

local utils = require("solar.utils")
local consts = require("solar.consts")
local com = require("solar.com")

--
-- Tile
--
function Solar_NewTile(name, gname, zindex, posx, posy, sizew, sizeh, collide)
  return {
    name = name, generic_name = gname,
    zindex = ( (zindex == 1) and 2 or zindex),
    position = utils.Solar_NewVectorXY(posx, posy),
    size = utils.Solar_NewVectorXY(sizew, sizeh),
    collide = ((collide == nil) and false or collide),
    --
    color = utils.Solar_NewColor(255, 255, 255),
    draw_using = consts.SOLAR_DRAW_USING_COLOR,
    textures = {},
    texture_index = 0,
    texture_timing = 0,
    --
    when_interaction = nil, run_interaction = false,
  }
end
module.Solar_NewTile = Solar_NewTile
function Solar_TickTile(engine, world_mode, world, tile)
  if tile.when_interaction and tile.run_interaction then 
    local status = com.Solar_TickCommand(engine, tile.when_interaction)
    tile.run_interaction = status ~= com.DIED and status ~= com.FINISHED
  end
end
module.Solar_TickTile = Solar_TickTile
function Solar_DrawTile(engine, world_mode, world, tile)
  -- rx, ry: relative position
  local rx, ry = utils.Solar_GetRelativePosition(world_mode.player.rel_position, world_mode.player.abs_position, tile.position)
  if rx > -tile.size.x and rx < world_mode.viewport:getWidth() and ry > -tile.size.y and ry < world_mode.viewport:getHeight() then
    if tile.draw_using == consts.SOLAR_DRAW_USING_COLOR then
      love.graphics.setColor  (utils.Solar_TranslateColor(tile.color))
      love.graphics.rectangle ("fill", rx, ry, tile.size.x, tile.size.y)
    end
  end
end
module.Solar_DrawTile = Solar_DrawTile

--
return module