-- engine.lua: load all the extra functions and return the REAL engine.
local xlog      =require("sol.xlog")
local xstring   =require("sol.xstring")
local xtable    =require("sol.xtable")
return require("sol._engine")