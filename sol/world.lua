local smath=require("sol.smath")
local defaults=require("sol.defaults")
local storage = require("sol.storage")
local scf = require("sol.scf")
local ui = require("sol.ui")
local sgen = require("sol.sgen")
local system = require("sol.system")

local module={}
--
function Sol_NewPlayer()
  return {
    type = "player",
    name = "player",
    inventory = {},
    pets = {},
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
    texture_timing = 0
  }
end ; module.Sol_NewTile=Sol_NewTile
function Sol_DrawTile(engine, world_mode, world, tile)
  if tile.draw_method == defaults.SOL_DRAW_USING.COLOR then
    love.graphics.setColor(smath.Sol_TranslateColor(tile.color))
    local rxpos, rypos = smath.Sol_GetTileRelativePosition(world_mode.player.rel_position, world_mode.player.rectangle.position, tile.rectangle.position)
    local width, height= smath.Sol_UnpackVectorXY(world_mode.player.rectangle.size)
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
function Sol_NewWorld(world)
  return {
    info={name="n/n", description="?"},
    --
    recipe_tiles={},
    recipe_geometry={},
    recipe_background={},
    --
    bg_size=nil,
    bg_tile_size=nil,
    tiles={{zindex=1, type="player"}},
  }
end ; module.Sol_NewWorld=Sol_NewWorld
function Sol_SortTiles(world)
  table.sort(world.tiles, function(a, b) return a.zindex < b.zindex end)
end ; module.Sol_SortTiles=Sol_SortTiles
function Sol_GenerateWorldBackground(engine, world_mode, world)
  local valid, position=table.find({
    recipe_background=world.recipe_background,
    recipe_geometry=world.recipe_geometry,
    recipe_background_matrix=world.recipe_background["matrix"],
    recipe_geometry_bg_size=world.recipe_geometry["bg_size"],
    recipe_geometry_bg_tile_size=world.recipe_geometry["bg_tile_size"],
  }, nil) if valid then
    mwarn("Sol_GenerateWorldBackground() failed to generate world due lack of: %s section/define!", position)
    return false
  end
  world.bg_size=smath.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size=smath.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  -- A - Z, a - z, 0 - 9 amount of blocks for you to play on the background.
  for yindex = 1, world.bg_size.y do
    local line=world.recipe_background.matrix[yindex]
    for xindex = 1, world.bg_size.x do
      local matrix_block=line:sub(xindex,xindex)
      if world.recipe_tiles[matrix_block] == nil then
        mwarn("unable to find %s block.", matrix_block)
      else
        local proto_tile=Sol_NewTile(world.recipe_tiles[matrix_block])
        proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
        proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
        table.insert(world.tiles, proto_tile)
      end
    end
  end
  Sol_SortTiles(world)
  --
  return true
end ; module.Sol_GenerateWorldBackground=Sol_GenerateWorldBackground
function Sol_LoadWorld(engine, world_mode, world, world_name)
  local target_file=system.Sol_MergePath({engine.root,string.format("levels/%s.slevel",world_name)})
  dmsg("Sol_LoadWorld() will attempt to load file: %s for world: %s", target_file, world_name)
  --
  target_file=scf.SCF_LoadFile(target_file)
  world.info=target_file["info"] or world.info
  world.recipe_tiles=target_file["tiles"] or world.recipe_tiles
  world.recipe_geometry=target_file["geometry"] or world.recipe_geometry
  world.recipe_background=target_file["background"] or world.recipe_background
  --
  local _worked=Sol_GenerateWorldBackground(engine, world_mode, world)
  if not _worked then
    mwarn("WORLD did not generate BACKGROUND!")
  end
end ; module.Sol_LoadWorld=Sol_LoadWorld
function Sol_TickWorld(engine, world_mode, world)
end ; module.Sol_TickWorld=Sol_TickWorld
function Sol_DrawWorld(engine, world_mode, world)
  for _, tile in ipairs(world.tiles) do
    if tile.zindex == 1 and tile.type=="player" then
      Sol_DrawPlayer(engine, world_mode, world_mode.player)
    else
      if tile.should_draw then
        Sol_DrawTile(engine, world_mode, world, tile)
      end
    end
  end
end ; module.Sol_DrawWorld=Sol_DrawWorld

--
function Sol_NewWorldMode()
  return {
    viewport = nil,
    viewport_size = nil,
    worlds = {},
    current_world = nil,
    main_display = nil,
    player = Sol_NewPlayer(),
  }
end
module.Sol_NewWorldMode=Sol_NewWorldMode
function Sol_InitWorldMode(engine, world_mode)
  --> setup the viewport: the viewport does not resize (even if the window is resizable).
  world_mode.viewport=love.graphics.newCanvas(engine.viewport_size.x, engine.viewport_size.y)
  world_mode.viewport_size=engine.viewport_size
  world_mode.main_display=ui.Sol_NewDisplay()
  Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)

  --> in-case no world is loaded, load the internal level called "niea-room"
  local proto_world=Sol_NewWorld()
  Sol_LoadWorld(engine, world_mode, proto_world, "niea-room")
  world_mode.worlds["niea-room"]=proto_world
  world_mode.current_world="niea-room"
end ; module.Sol_InitWorldMode=Sol_InitWorldMode

--[[ Tick Related Functions ]]
function Sol_TickWorldMode(engine, world_mode)
  ui.Sol_TickDisplay(world_mode.main_display)
  if world_mode.current_world then
    local current_world=world_mode.worlds[world_mode.current_world]
  end
end ; module.Sol_TickWorldMode=Sol_TickWorldMode
function Sol_ResizeEventWorldMode(engine, world_mode)
  ui.Sol_SetMousePositionOffsetDisplay(world_mode.main_display, engine.viewport_position.x, engine.viewport_position.y)
end ; module.Sol_ResizeEventWorldMode=Sol_ResizeEventWorldMode
function Sol_KeypressEventWorld(engine, world_mode)
end ; module.Sol_KeypressEventWorld=Sol_KeypressEventWorld

--[[ Draw Related Functions ]]
function Sol_DrawWorldMode(engine, world_mode)
  local past_canva=love.graphics.getCanvas()
  love.graphics.setCanvas(world_mode.viewport)
    love.graphics.clear(smath.Sol_TranslateColor(defaults.SOL_VIEWPORT_BACKGROUND))
    if world_mode.current_world then
      local current_world=world_mode.worlds[world_mode.current_world]
      if current_world then
        Sol_DrawWorld(engine, world_mode, current_world)
      end
    end
    ui.Sol_DrawDisplay(world_mode.main_display)
  love.graphics.setCanvas(past_canva)
end
module.Sol_DrawWorldMode=Sol_DrawWorldMode
--
return module