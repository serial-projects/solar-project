local module = {}
--
function module.Sol_ImplementEngineSystemCalls(engine, context)
  context.system_calls["SolEngine_DoSave"] = function(_, instance)
    dmsg("we saving the game...")
  end
end
-- 
return module