local module = {}
--

-- DIE_SEVERITY_(LOW, MEDIUM, HIGH): from (1 to 3), determine the severity of the death.
module.DIE_SEVERITY_LOW   = 1 -- POSSIBLE recoverable error; won't report in GAME, only in logs.
module.DIE_SEVERITY_MEDIUM= 2 -- non-lethal error BUT report in GAME (does not kill the game though).
module.DIE_SEVERITY_HIGH  = 3 -- lethal error and the GAME is forced to halt.


-- EXEC_ON_(TICK, DRAW): from (1 to 3), determine where the routine is gonna run.
module.EXEC_ON_TICK       = 1
module.EXEC_ON_DRAW       = 2
module.EXEC_ON_TICKDRAW   = 3

-- ROUTINE_STATUS_(FIRSTRUN, RUNNING, FINISHED, DIED): from (1 to 4), determine 
-- the status of a certain routine, FIRSTRUN will change automatically to RUNNING
-- on the next tick. But, be sure to return RUNNING status to prevent warnings!
module.ROUTINE_STATUS_FIRSTRUN  = 1
module.ROUTINE_STATUS_RUNNING   = 2
module.ROUTINE_STATUS_FINISHED  = 3
module.ROUTINE_STATUS_DIED      = 4

-- Sol_NewRoutine(name: string, status: number, exec_on: number, on_tick_wrap: table, on_draw_wrap: table)
function module.Sol_NewRoutine(name, exec_on, on_tick_wrap, on_draw_wrap)
  return { 
    name          = name,
    status        = module.ROUTINE_STATUS_FIRSTRUN,
    die_severity  = module.DIE_SEVERITY_LOW,
    dump          = nil,
    exec_on       = exec_on or module.EXEC_ON_TICKDRAW,
    on_tick_wrap  = on_tick_wrap or {},
    on_draw_wrap  = on_draw_wrap or {}
  }
end

-- Sol_NewRoutineService()
function module.Sol_NewRoutineService()
  return { routines = {} }
end

function Sol_RoutineServiceDie(engine, world_mode, world, routine)
  local perform_table = {
    [module.DIE_SEVERITY_LOW]=function()
      mwarn("routine: \"%s\" has DIED, dump: %s", routine.name, routine.dump)
    end,
    [module.DIE_SEVERITY_MEDIUM]=function()
      -- TODO: trigger world mode's warning message box.
      mwarn("routine: \"%s\" has DIED a medium death, dump: %s", routine.name, routine.dump)
    end,
    [module.DIE_SEVERITY_HIGH]=function()
      -- TODO: change from world mode to crash mode.
      qcrash(1, "routine: \"%s\" has DIED and took the entire game out, dump: %s", routine.name, routine.dump)
    end
  }
  perform_table[(routine.die_severity > 3) and module.DIE_SEVERITY_HIGH or routine.die_severity]()
end

function Sol_RoutineServiceExecutionTemplate(engine, world_mode, world, routine_service, current_mode)
  local wrap_bank        ={"on_tick_wrap","on_draw_wrap"}
  local current_wrap_bank=wrap_bank[current_mode]
  for routine_index, routine in ipairs(routine_service.routines) do
    if routine.exec_on == current_mode or routine.exec_on <= 3 then
      local routine_name  = routine.name
      local routine_status= routine.status
      assert(routine[current_wrap_bank], string.format("expected wrap for routine (on current mode: %s): \"%s\", got nothing!", current_mode, routine_name))
      local routine_wrap  = routine[current_wrap_bank][routine_status]
      if routine_wrap then
        routine.status = routine[current_wrap_bank][routine_status](engine, world_mode, world, routine)
      else
        routine.status = (routine.status == module.ROUTINE_STATUS_FIRSTRUN) and module.ROUTINE_STATUS_RUNNING or module.ROUTINE_STATUS_FINISHED
      end
      --[[ FIRSTRUN MODE ]]
      if routine.status == module.ROUTINE_STATUS_FIRSTRUN then
        routine.status = module.ROUTINE_STATUS_RUNNING
        mwarn("routine \"%s\" was updated from FIRSTRUN to RUNNING by the RoutineService!", routine_name)
      --[[ FINISHED MODE ]]
      elseif routine.status == module.ROUTINE_STATUS_FINISHED then
        routine_service.routines[routine_index]=nil
        mwarn("routine \"%s\" finished and was removed!")
      --[[ DIED MODE ]]
      elseif routine.status == module.ROUTINE_STATUS_DIED then
        Sol_RoutineServiceDie(engine, world_mode, world, routine)
        routine_service.routines[routine_index]=nil
      end
    end
  end
end
function module.Sol_PushRoutine(routine_service, routine)
  table.insert(routine_service.routines, routine)
end
function module.Sol_TickRoutineService(engine, world_mode, world, routine_service)
  Sol_RoutineServiceExecutionTemplate(engine, world_mode, world, routine_service, module.EXEC_ON_TICK)
end
function module.Sol_DrawRoutineService(engine, world_mode, world, routine_service)
  Sol_RoutineServiceExecutionTemplate(engine, world_mode, world, routine_service, module.EXEC_ON_DRAW)
end

--
return module