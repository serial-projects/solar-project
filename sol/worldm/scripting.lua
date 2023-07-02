local module = {}
local system=require("sol.system")
local ssen_interpreter=require("sol.ssen.interpreter")
local ssen_load=require("sol.ssen.load")

-- Sol_LoadInterpreterSystemCalls(engine, world_mode, world, ir): load the interpreter functions.
function module.Sol_LoadInterpreterSystemCalls(engine, world_mode, world, ir)
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
            else table.insert(msgbox_list, {who=who, text=text}) end
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

--[[ Script Containers ]]--
function module.Sol_NewScriptContainer(engine, world_mode, world, recipe)
  local recipe    = recipe or {}
  local proto_script_container={
    name          = recipe["name"] or string.genstr(),
    instance      = 0,
    time_taken    = 0,
    when_finish   = recipe["when_finish"] or 0
  }
  proto_script_container.instance             = ssen_load.SSEN_LoadFile(system.Sol_MergePath({engine.root, ("scripts/"..recipe["source"]..".ssen")}))
  proto_script_container.instance.name        = proto_script_container.name
  proto_script_container.instance.globals     = engine.vars
  proto_script_container.instance.nticks      = recipe["ticks_per_frame"] or 10
  -- NOTE: for tile scripts, you can define some presets for them, more simple saying, a start
  -- label. You can project code like "MyTile_InteractedEvent: ..."
  if recipe["begin_at"] then ssen_interpreter.SSEN_IrSetPC(proto_script_container.instance, recipe["begin_at"]) end
  --
  module.Sol_LoadInterpreterSystemCalls(engine, world_mode, world, proto_script_container.instance)
  return proto_script_container
end

function module.Sol_TickScriptContainer(script_container)
  local FINAL_STATUS={
    [ssen_interpreter.SSEN_Status.FINISHED]   =true,
    [ssen_interpreter.SSEN_Status.DIED]       =true,
    [ssen_interpreter.SSEN_Status.WAITING]    =true
  }
  local current_status
  local index = 1
  local begun_executing=os.time()
  while true do
    current_status=ssen_interpreter.SSEN_TickIntepreter(script_container.instance)
    if FINAL_STATUS[current_status] or index >= script_container.instance.nticks then break
    else index = index + 1 end
  end
  script_container.time_taken = os.time() - begun_executing
  return current_status
end

--[[ Script Service ]]--
function module.Sol_NewScriptService()
  return { scripts = {}, enabled = true }
end
function module.Sol_TickScriptService(script_service)
  if script_service.enabled then
    for index, script_container in ipairs(script_service.scripts) do
      local final_return=module.Sol_TickScriptContainer(script_container)
      if final_return == ssen_interpreter.SSEN_Status.FINISHED then
        dmsg("script \"%s\" has just finished execution!", script_container.instance.name)
        if script_container.when_finish and type(script_container.when_finish) == "function" then
          script_container.when_finish(script_container.instance)
        end
        script_service.scripts[index]=nil
      elseif final_return == ssen_interpreter.SSEN_Status.DIED then
        stopexec(string.format("script \"%s\" has just died, reason: \"%s\"", script_container.instance.name, script_container.instance.fail))
        script_service.scripts[index]=nil
        dmsg("script \"%s\" has just NOT finished execution properly!", script_container.instance.name)
      end
    end
  end
end
function module.Sol_LoadScript(engine, world_mode, world, recipe, script_service)
  local script_container=module.Sol_NewScriptContainer(engine, world_mode, world, recipe)
  table.insert(script_service.scripts, script_container)
end

--
return module