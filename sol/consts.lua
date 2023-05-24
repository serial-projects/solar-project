local module={}
local smath=require("sol.smath")
--
local colors={
  black=smath.Sol_NewColor4(  0,   0,   0),
  white=smath.Sol_NewColor4(255, 255, 255),
  red  =smath.Sol_NewColor4(255,   0,   0),
  green=smath.Sol_NewColor4(  0, 255,   0),
  blue =smath.Sol_NewColor4(  0,   0, 255)
} ; module.colors=colors
--
return module