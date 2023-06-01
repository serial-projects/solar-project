local smath=require("sol.smath")
local defaults=require("sol.defaults")
local storage=require("sol.storage")
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
    texture_timing = tile["texture_timing"] or 1,
    texture_nextupdate=0,
    current_chunk = {},
    --
    when_touched = tile["when_touched"] or 0,
    when_interacted = tile["when_interacted"] or 0,
  }
end ; module.Sol_NewTile=Sol_NewTile

--[[ Tick Related Functions ]]
function Sol_TickTile(engine, world_mode, world, tile)

end

--[[ Draw Related Functions ]]
function Sol_DrawTile(engine, world_mode, world, tile)
  local rxpos, rypos = smath.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
  local width, height= smath.Sol_UnpackVectorXY(tile.rectangle.size)
  if tile.draw_method == defaults.SOL_DRAW_USING.COLOR then
    --[[ Draw using the color ]]--
    love.graphics.setColor(smath.Sol_TranslateColor(tile.color))
    love.graphics.rectangle("fill", rxpos, rypos, width, height)
  else
    --[[ Draw using the texture ]]--
    -- TODO: this method of rendering textures is BAD, rewrite please.
    if type(tile.textures) == "string" then
      local current_texture=storage.Sol_LoadImageFromStorage(engine.storage, tile.textures)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(current_texture, rxpos, rypos)
    elseif type(tile.textures) == "table" then
      -- TODO: when the tile is using textures as a table, it must be a sprite table.
      local o_image, quad = storage.Sol_LoadSpriteFromStorage(engine.storage, tile.textures[tile.texture_index])
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(o_image, quad, rxpos, rypos)
      if os.clock()>=tile.texture_nextupdate then
        tile.texture_index=(tile.texture_index+1> #tile.textures) and 1 or tile.texture_index+1
        tile.texture_nextupdate=os.clock()+tile.texture_timing
      end
    else
      tile.draw_method = defaults.SOL_DRAW_USING.COLOR
      return
    end
  end
end ; module.Sol_DrawTile=Sol_DrawTile

--
return module