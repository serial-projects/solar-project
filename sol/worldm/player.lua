local smath=require("sol.smath")
local defaults=require("sol.defaults")
local storage=require("sol.storage")
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
    texture_index = 1,
    texture_nextupdate = 0,
    texture_timing = 0.1,
    --
    rel_position = smath.Sol_NewVector(0, 0),
    rectangle = smath.Sol_NewRectangle(nil, defaults.SOL_PLAYER_SIZE),
  }
end ; module.Sol_NewPlayer=Sol_NewPlayer
function Sol_LoadPlayerRelativePosition(world_mode, player)
  player.rel_position.x=math.floor(world_mode.viewport_size.x/2)-math.floor(player.rectangle.size.x/2)
  player.rel_position.y=math.floor(world_mode.viewport_size.y/2)-math.floor(player.rectangle.size.y/2)
  dmsg("Sol_LoadPlayerRelativePosition() set the player.rel_position to x = %d and y = %d", player.rel_position.x, player.rel_position.y)
end ; module.Sol_LoadPlayerRelativePosition=Sol_LoadPlayerRelativePosition

--[[ Draw Related Functions ]]
function Sol_DrawPlayer(engine, world_mode, player)
  local posx, posy=smath.Sol_UnpackVectorXY(player.rel_position)
  local width, height=smath.Sol_UnpackVectorXY(player.rectangle.size)
  local function _draw_rectangle()
    love.graphics.setColor(smath.Sol_TranslateColor(player.color))
    love.graphics.rectangle("fill", posx, posy, width, height)
  end
  local function _draw_texture()
    -- TODO: optimize code.
    local texturelist=player.textures[player.looking_direction]
    if type(texturelist)=="string" then
      local current_texture = storage.Sol_LoadImageFromStorage(engine.storage, texturelist)
      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(current_texture, posx, posy)
    elseif type(texturelist)=="table" then
      local current_texture=texturelist.textures[player.texture_index]
      local o_image, quad = storage.Sol_LoadSpriteFromStorage(engine.storage, current_texture)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(o_image, quad, posx, posy)
      if os.clock()>=player.texture_nextupdate then
        player.texture_index=(player.texture_index+1> #texturelist.textures) and 1 or player.texture_index+1
        player.texture_nextupdate=os.clock()+player.texture_timing
      end
    end
  end
  if player.draw_method == defaults.SOL_DRAW_USING.COLOR then
    _draw_rectangle()
  else
    if player.textures[player.looking_direction] then _draw_texture()
    else _draw_rectangle() end
  end
end ; module.Sol_DrawPlayer=Sol_DrawPlayer

--
return module