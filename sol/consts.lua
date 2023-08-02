local smath=require("sol.smath")
--
local module = {
  colors={
    black=smath.Sol_NewColor4(  0,   0,   0),
    white=smath.Sol_NewColor4(255, 255, 255),
    red  =smath.Sol_NewColor4(255,   0,   0),
    green=smath.Sol_NewColor4(  0, 255,   0),
    blue =smath.Sol_NewColor4(  0,   0, 255)
  },
  draw_using          = table.enum(1, {"COLOR", "TEXTURE", "SPRITES", "IMAGES"}),
  engine_modes        = table.enum(1, {"MENU", "WORLD", "CREDITS"}),
  player_directions   = table.enum(1, {"UP","DOWN","LEFT","RIGHT"}),
}
--
return module