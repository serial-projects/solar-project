-- engine.lua: load all the extra functions and return the REAL engine.
local xstring=require("sol.xstring")
local xtable=require("sol.xtable")
local xlog=require("sol.xlog")
return require("sol._engine")