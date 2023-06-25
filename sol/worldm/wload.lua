local unpack = unpack or table.unpack

local smath=require("sol.smath")
local defaults=require("sol.defaults")
local system=require("sol.system")
local scf=require("sol.scf")
local player = require("sol.worldm.player")
local drawrec= require("sol.drawrec")
local consts = require("sol.consts")

-- ssen module:
local ssen_load=require("sol.ssen.load")
local ssen_interpreter=require("sol.ssen.interpreter")

-- world module:
local tiles=require("sol.worldm.tiles")
local chunk=require("sol.worldm.chunk")

local module={}

-- Sol_GenerateLayer(world: world, layer: layer): generate a layer by its name.
function module.Sol_GenerateLayer(world, layer)
  if world.recipe_layers[layer] then
    local current_layer = world.recipe_layers[layer]
    local layer_width = current_layer["width"]
    local layer_height= current_layer["height"]
    local layer_matrix= current_layer["matrix"]
    --> begin indexing
    for yindex = 1, layer_height do
      local line=layer_matrix[yindex]
      for xindex = 1, layer_width do
        local matrix_block=line:sub(xindex,xindex)
        if matrix_block ~= "0" then
          if world.recipe_tiles[matrix_block] == nil then
            mwarn("unable to find \"%s\" block for layer \"%s\"", matrix_block, layer)
          else
            local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[matrix_block])
            proto_tile.rectangle.position.x=(xindex-1)*world.bg_tile_size.x
            proto_tile.rectangle.position.y=(yindex-1)*world.bg_tile_size.y
            table.insert(world.tiles, proto_tile)
          end
        end
      end
    end
    --> end.
  end
end

-- Sol_WorldSpawnTile: creates a new tile.
function module.Sol_WorldSpawnTile(engine, world_mode, world, tile_name)
  if world.recipe_tiles[tile_name] then
    local proto_tile=tiles.Sol_NewTile(world.recipe_tiles[tile_name])
    table.insert(world.tiles, proto_tile)
    return true
  else
    return false
  end
end

-- Sol_LoadInterpreterSystemCalls(engine, world_mode, world, ir): load the interpreter functions.
local function Sol_LoadInterpreterSystemCalls(engine, world_mode, world, ir)
  local function __syscall_print(sysc_name, t_name, fmt, ...)
    dmsg("[syscall in thread: \"%s\" (%s)]: %s", t_name, sysc_name, fmt, ...)
  end
  ir.syscalls={
    --[[ Sol Output ]]
    ["SolOutput"]=function(ir) __syscall_print("SolOutput", ir.name, tostring(ir.registers.A)) end,
    ["SolForceGameQuit"]=function(ir)
      __syscall_print("SolForceGameQuit", ir.name, "forcing the game to QUIT.")
      love.event.quit((type(ir.registers.A)=="number" and ir.registers.A or 0))
    end,
    --[[ Set/Get Absolute Position ]]
    ["SolGetAbsolutePlayerPosition"]=function(ir)
      ir.registers.A = world_mode.player.rectangle.position.x
      ir.registers.B = world_mode.player.rectangle.position.y
    end,
    ["SolSetAbsolutePlayerPosition"]=function(ir)
      assert(type(ir.registers.A)=="number", "SolSetAbsolutePlayerPosition requires $A to be number.") ; world_mode.player.rectangle.position.x = ir.registers.A
      assert(type(ir.registers.B)=="number", "SolSetAbsolutePlayerPosition requires $B to be number.") ; world_mode.player.rectangle.position.y = ir.registers.B
    end,
    --[[ Set/Get Relative Position ]]
    ["SolGetRelativePosition"]=function(ir)
      ir.registers.A = world_mode.player.rel_position.x
      ir.registers.B = world_mode.player.rel_position.y
    end,
    ["SolSetRelativePosition"]=function(ir)
      assert(type(ir.registers.A)=="number", "SolSetRelativePlayerPosition requires $A to be number.") ; world_mode.player.rel_position.x = ir.registers.A
      assert(type(ir.registers.B)=="number", "SolSetRelativePlayerPosition requires $B to be number.") ; world_mode.player.rel_position.y = ir.registers.B
    end,
    --[[ MessageBox Generator ]]
    ["SolMessageBox"]=function(ir)
      -- read the stack to find everything about the message.
      -- TODO: make '%' reading from storage.KEYS :>
      local id_messagebox=ir.registers.A
      local msgbox_list  ={}
      for index=1, #ir.stack do
        local stkv=ir.stack[index]
        if stkv==id_messagebox then
          local subindex=index+1
          while subindex<=#ir.stack do
            local who,text = ir.stack[subindex],ir.stack[subindex+1] or '???'
            if    who == id_messagebox then break
            else                            table.insert(msgbox_list, {who=who, text=text}) end
            subindex=subindex+2
          end
          break
        end
      end
      if #msgbox_list > 0 then
        -- on the last message, add the callback.
        world_mode.msg_service.message_stack=msgbox_list
        world_mode.msg_service.message_stack[#world_mode.msg_service.message_stack]["callback"]=function() ir.status=ssen_interpreter.RUNNING end
        world_mode.msg_service.trigger=true
        ir.status=ssen_interpreter.SSEN_Status.WAITING
      end
    end,
  }
end

-- Sol_LoadWorld(engine, world_mode, world, world_name: string): automatically loads the world
-- recipe file and build the world from the recipe provided.
function module.Sol_LoadWorld(engine, world_mode, world, world_name)
  local target_file=system.Sol_MergePath({engine.root,string.format("levels/%s.slevel",world_name)})
  dmsg("Sol_LoadWorld() will attempt to load file: %s for world: %s", target_file, world_name)
  --> clean the old tiles and load everything again.
  world.tiles={{zindex=1,type="player"}}
  collectgarbage("collect")
  --> load the "recipes" and the world information from the target file.
  target_file                 =scf.SCF_LoadFile(target_file)
  world.info                  =target_file["info"]        or world.info
  world.recipe_tiles          =target_file["tiles"]       or world.recipe_tiles
  world.recipe_geometry       =target_file["geometry"]    or world.recipe_geometry
  world.recipe_level          =target_file["level"]       or world.recipe_level
  world.recipe_layers         =target_file["layers"]      or world.recipe_layers
  world.recipe_player         =target_file["player"]      or world.recipe_player
  world.recipe_scripts        =target_file["scripts"]     or world.recipe_scripts
  --> "geometry" section stuff.
  world.bg_size             =smath.Sol_NewVector(world.recipe_geometry.bg_size)
  world.bg_tile_size        =smath.Sol_NewVector(world.recipe_geometry.bg_tile_size)
  world.world_size          =smath.Sol_NewVector((world.bg_size.x-1)*world.bg_tile_size.x,(world.bg_size.y-1)*world.bg_tile_size.y)
  world.enable_world_borders=(world.recipe_geometry["enable_world_borders"] == true)
  --> "level" section stuff.
  if world.recipe_level then
    local spawn_tiles=world.recipe_level["spawn_tiles"]
    if spawn_tiles and type(spawn_tiles) == "table" then
      for _, tile in ipairs(spawn_tiles) do
        local sucess=module.Sol_WorldSpawnTile(engine, world_mode, world, tile)
        if not sucess then mwarn("couldn't generate tile: %s!", tile) end
      end
    end
    local spawn_layers=world.recipe_level["spawn_layers"]
    if spawn_layers and type(spawn_layers) == "table" then
      for _, layer in ipairs(spawn_layers) do
        module.Sol_GenerateLayer(world, layer)
      end
    end
  end
  --> "player" section 
  -- NOTE: the player section is actually loaded during the world firstrun routine.
  local function wload_AdjustPlayerOneshot_FirstRun(engine, world_mode, world, routine)
    dmsg("%s is adjust the player for the first time run on the world: \"%s\"!", routine.name, world.name)
    if world.recipe_player then
      local spawn_position = world.recipe_player["spawn"]
      if spawn_position then
        local xpos, ypos = spawn_position["xpos"] or 0, spawn_position["ypos"] or 0
        if spawn_position["use_tile_alignment"] then
          xpos = xpos * world.bg_tile_size.x
          ypos = ypos * world.bg_tile_size.y
        end
        world_mode.player.rectangle.position.x,world_mode.player.rectangle.position.y=xpos, ypos
      end
      --
      world_mode.player.draw = drawrec.Sol_NewDrawRecipe(world.recipe_player["draw"])
      world_mode.player.rectangle.size = world.recipe_player["size"] and smath.Sol_NewVector(world.recipe_player["size"]) or world_mode.player.size
      player.Sol_LoadPlayerRelativePosition(world_mode, world_mode.player)
    end
    return consts.routine_status.FINISHED
  end
  table.insert(world.routines, {name="wload.AdjustPlayerOneshot", status=consts.routine_status.FIRSTRUN, wrap={[consts.routine_status.FIRSTRUN]=wload_AdjustPlayerOneshot_FirstRun}})
  --> "script" section
  if world.recipe_scripts then
    for script_name, script in pairs(world.recipe_scripts) do
      -- TODO: due limitation in SCF, ignore all '__type' keywords.
      if script_name ~= "__type" then
        local source        = system.Sol_MergePath({engine.root, "scripts/", script.source..".ssen"})
        local proto_script  = {name=script.name, instance=ssen_load.SSEN_LoadFile(source), priority=(source["ticks_per_frame"] or 10)}
        proto_script.instance.globals=engine.vars
        Sol_LoadInterpreterSystemCalls(engine, world_mode, world, proto_script.instance)
        table.insert(world.scripts, proto_script)
      end
    end
  end
  --> build all the chunks in the map.
  chunk.Sol_MapChunksInWorld(world)
end

--
return module