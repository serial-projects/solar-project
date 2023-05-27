local smath=require("sol.smath")
local defaults=require("sol.defaults")
local module={}

--
function Sol_NewTile(tile)
  local tile = tile or {}
  return {
    type = "tile",
    name = tile["name"] or "player",
    rectangle = smath.Sol_NewRectangle(smath.Sol_NewVector(tile["position"]), smath.Sol_NewVector(tile["size"])),
    zindex = (tile["zindex"] == 1 and 2 or tile["zindex"]) or 0,
    collide = tile["collide"] or false,
    should_draw = tile["should_draw"] or true,
    draw_method = tile["draw_method"] or defaults.SOL_DRAW_USING.COLOR,
    color = smath.Sol_NewColor4(tile["color"]),
    textures = tile["textures"] or {},
    texture_index = 1,
    texture_timing = 0,
    current_chunk = {}
  }
end ; module.Sol_NewTile=Sol_NewTile

--[[ Draw Related Functions ]]
function Sol_DrawTile(engine, world_mode, world, tile)
  if tile.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(tile.color))
    local rxpos, rypos = smath.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
    local width, height= smath.Sol_UnpackVectorXY(tile.rectangle.size)
    love.graphics.rectangle("fill", rxpos, rypos, width, height)
  else
    mwarn("not implemented drawing method, falling back to color.")
    tile.draw_method = defaults.SOL_DRAW_USING.COLOR
    -- NOTE: there is not actually problem to call this since we changed
    -- the color drawing method so there is no problem with eternal recursion.
    Sol_DrawTile(engine, world_mode, world, tile)
  end
end ; module.Sol_DrawTile=Sol_DrawTile

--
return module