local module={}
function Solar_InvokeAndMeasureTime(invoke_function, ...)
  local begun     = os.clock()
  local returned  = invoke_function(...)
  return os.clock() - begun, returned
end
module.Solar_InvokeAndMeasureTime = Solar_InvokeAndMeasureTime

--
return module