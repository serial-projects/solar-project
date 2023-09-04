-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.
if _G["OneshotModulesImported"] then goto skip_everything end
local module_targets, module_prefix, begun = {"Log","String","Table","Tokenizer"}, "Solar.OneshotModules.%s", os.clock()
for _, module in ipairs(module_targets) do
  require(string.format(module_prefix,module))
end ; dmsg("Oneshot Modules took %f seconds to load.", os.clock() - begun)
_G["OneshotModulesImported"] = true
::skip_everything::