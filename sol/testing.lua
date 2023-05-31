local module={}
local world=require("sol.worldm.world")
local tiles=require("sol.worldm.tiles")
local smath=require("sol.smath")
--
function Sol_GenerateTestingWorld(world_mode, width, height)
  local generating_world_begun_at = os.clock()
  local proto_world=world.Sol_NewWorld({name="testing-world00",description="test the powah!!!"})
  proto_world.bg_size=smath.Sol_NewVector(100, 100)
  proto_world.bg_tile_size=smath.Sol_NewVector(width, height)
  proto_world.world_size=smath.Sol_MultiplicateVector(proto_world.bg_size, proto_world.bg_tile_size)
  proto_world.enable_world_borders = true
  --> set some titles
  proto_world.recipe_tiles["A"]={name="floorA",position={0, 0},size={width, height},zindex=0, color={150, 150, 150}, collide=false}
  proto_world.recipe_tiles["B"]={name="floorB",position={0, 0},size={width, height},zindex=0, color={100, 100, 100}, collide=false}
  for yindex = 0, proto_world.bg_size.y do
    for xindex = 0, proto_world.bg_size.x do
      local current_tile=(yindex % 2 == 0) and 1 or 0
      current_tile = current_tile + ((xindex % 2 == 0) and 1 or 0)
      local select_tile =(current_tile == 1) and "A" or "B"
      local proto_tile = tiles.Sol_NewTile(proto_world.recipe_tiles[select_tile])
      proto_tile.rectangle.position.x=xindex*proto_world.bg_tile_size.x
      proto_tile.rectangle.position.y=yindex*proto_world.bg_tile_size.y
      table.insert(proto_world.tiles, proto_tile)
    end
  end
  --> generate a maze (aka. the backrooms)
  proto_world.recipe_tiles["C"]={name="block0",position={0, 0},size={width, height},zindex=1, color={249, 197, 200}, collide=true}
  local matrix = {} 
  for yindex = 1, proto_world.bg_size.y do
    matrix[yindex]={}
    for xindex = 1, proto_world.bg_size.x do
      matrix[yindex][xindex]=0
    end
  end
  local function gen_hline(xpos, ypos, length, value)
    for yindex = ypos, ypos + length do
      if yindex >= proto_world.bg_size.y or matrix[yindex][xpos] == value then break end
      matrix[yindex][xpos]=value
    end
  end
  local function gen_vline(xpos, ypos, length, value)
    for xindex = xpos, xpos + length do
      if xindex >= proto_world.bg_size.x or matrix[ypos][xindex] == value then break end
      matrix[ypos][xindex]=value
    end
  end
  for index = 1, 256 do
    local vorh = math.random(1, 2)
    if vorh == 1 then
      gen_hline(math.random(10, proto_world.bg_size.x), math.random(10, proto_world.bg_size.y), math.random(5, 10), 'C')
    else
      gen_vline(math.random(10, proto_world.bg_size.x), math.random(10, proto_world.bg_size.y), math.random(5, 10), 'C')
    end
  end
  --> read the matrix
  for yindex = 1, proto_world.bg_size.y do
    for xindex = 1, proto_world.bg_size.x do
      local gen_tile = matrix[yindex][xindex]
      if gen_tile ~= 0 then
        local proto_tile = tiles.Sol_NewTile(proto_world.recipe_tiles[gen_tile])
        proto_tile.rectangle.position.x = xindex * proto_world.bg_tile_size.x
        proto_tile.rectangle.position.y = yindex * proto_world.bg_tile_size.y
        table.insert(proto_world.tiles, proto_tile)
      end
    end
  end
  --> fix the chunks ...
  world.Sol_MapChunksInWorld(proto_world)
  dmsg("Sol_GenerateTestingWorld() has finished in %fs!", os.clock()-generating_world_begun_at)
  --> fix the player
  world_mode.player.rectangle.size.x=width
  world_mode.player.rectangle.size.y=height
  return proto_world
end ; module.Sol_GenerateTestingWorld=Sol_GenerateTestingWorld

--
return module