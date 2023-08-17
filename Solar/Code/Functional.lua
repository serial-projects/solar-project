local module = {}
-- 
function module.Sol_AttemptInvokeFunction(f, ...)
  if type(f) == "function" then
    return f(...)
  end
end
--
return module