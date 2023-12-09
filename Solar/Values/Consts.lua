-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local SM_Color  = require("Solar.Math.Color")
local ETable    = require("Library.Extra.Table")

--
local module = {
    colors={
        black=SM_Color.Sol_NewColor4(  0,   0,   0),
        white=SM_Color.Sol_NewColor4(255, 255, 255),
        red  =SM_Color.Sol_NewColor4(255,   0,   0),
        green=SM_Color.Sol_NewColor4(  0, 255,   0),
        blue =SM_Color.Sol_NewColor4(  0,   0, 255)
    },
    draw_using          = ETable.enum(1, {"COLOR", "TEXTURE", "SPRITES", "IMAGES"}),
    engine_modes        = ETable.enum(1, {"MENU", "WORLD", "CREDITS"}),
    player_directions   = ETable.enum(1, {"UP","DOWN","LEFT","RIGHT"}),
    ignore_chars_tiles  = {["0"]=true, [" "]=true}
}
--
return module