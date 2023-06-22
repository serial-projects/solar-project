local smath     = require("sol.smath")
local defaults  = require("sol.defaults")
local storage   = require("sol.storage")
local drawrec   = require("sol.drawrec")
local module={}

--
function module.Sol_NewTile(tile)
  local tile = tile or {}
  return {
    type                        = "tile",
    name                        = tile["name"] or "player",
    rectangle                   = smath.Sol_NewRectangle(smath.Sol_NewVector(tile["position"]), smath.Sol_NewVector(tile["size"])),
    zindex                      = (tile["zindex"] == 1 and 2 or tile["zindex"]) or 0,
    collide                     = tile["collide"] or false,
    should_draw                 = tile["should_draw"] or true,
    current_chunk               = {},
    --[[ draw ]]--
    draw = drawrec.Sol_NewDrawRecipe(tile["draw"]),
    --[[ actions ]]--
    when_touched                = tile["when_touched"] or 0,
    when_interacted             = tile["when_interacted"] or 0,
  }
end

--[[ Tick Related Functions ]]
function module.Sol_TickTile(engine, world_mode, world, tile)

end

--[[ Draw Related Functions ]]
function module.Sol_DrawTile(engine, world_mode, world, tile)
  local rxpos, rypos = smath.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
  local width, height= smath.Sol_UnpackVectorXY(tile.rectangle.size)
  drawrec.Sol_DrawRecipe(engine, tile.draw, rxpos, rypos, width, height)
end

--
return module