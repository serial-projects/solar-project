-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local __TimeBegunGlobalImports = os.clock()
if not _G["LogImported"] then     local Sol_Log     =require("Solar.Extras.Log")    end
if not _G["StringImported"] then  local Sol_String  =require("Solar.Extras.String") end
if not _G["TableImported"] then   local Sol_Table   =require("Solar.Extras.Table")  end
dmsg("LoadToGlobal.lua: Global module importing has took: %f seconds.", os.clock() - __TimeBegunGlobalImports)