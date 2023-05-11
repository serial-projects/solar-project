-- xlog.lua: load the logging functions :^)
if not _G["genericPrint"] then
  _G.genericPrintWrappers={print}
  _G.genericPrint=function(fmt, ...)
    local function printAllWrappers(wraplist, text)
      for _, wraplist in ipairs(wraplist) do
        wraplist(text)
      end
    end
    if #{...} < 1 then
      printAllWrappers(_G.genericPrintWrappers,fmt)
    else
      printAllWrappers(_G.genericPrintWrappers,string.format(fmt, ...))
    end
  end
end
if not _G["dmsg"] then
  _G.dmsg_en=false ; _G.dmsg_counter=0.000001
  _G.dmsg=function(fmt,...)
    if _G.dmsg_en then
      _G.genericPrint((string.format("[%f]: ",_G.dmsg_counter)..fmt), ...)
      _G.dmsg_counter=_G.dmsg_counter+0.000001
    end
  end
end
if not _G["mwarn"] then
  _G.mwarn=function(fmt, ...)
    _G.genericPrint("@@ "..fmt, ...)
  end
end
if not _G["qcrash"] then
  _G.qcrash=function(exit_code, fmt, ...)
    _G.genericPrint("!! "..fmt, ...)
    os.exit(exit_code)
  end
end
if not _G["makesure"] then
  _G.makesure=function(condition, code, when_error, ...)
    if not condition then
      _G.qcrash(code, when_error, ...)
    end
  end
end