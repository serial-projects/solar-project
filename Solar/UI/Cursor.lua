-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.
local SM_Vector     =require("Solar.Math.Vector")
local SM_Rectangle  =require("Solar.Math.Rectangle")
local SM_Color      =require("Solar.Math.Color")
local SV_Defaults   =require("Solar.Values.Defaults")
local SV_Consts     =require("Solar.Values.Consts")

local ETable        =require("Library.Extra.Table")

local module={}
local SOL_CURSOR_STATES = ETable.enum(1, {"NORMAL", "LOADING", "FAILED"}) ; module.SOL_CURSOR_STATES=SOL_CURSOR_STATES

function module.Sol_NewCursor(cursor)
    return ETable.struct({
        draw_method     = SV_Consts.draw_using.COLOR,
        textures        = {},
        current_mode    = SOL_CURSOR_STATES.NORMAL,
        texture_timing  = 0,
        texture_index   = 0,
        color           = SV_Defaults.SOL_UI_CURSOR_DEFAULT_COLOR,
        rectangle       = SM_Rectangle.Sol_NewRectangle(nil, SV_Defaults.SOL_UI_CURSOR_DEFAULT_SIZE),
        lastpos         = SM_Vector.Sol_NewVector(0, 0),
        position_offset = SM_Vector.Sol_NewVector(0, 0)
    }, cursor or {})
end

function module.Sol_TickCursor(cursor)
    cursor.rectangle.position=SM_Vector.Sol_NewVector(love.mouse.getPosition())
    cursor.rectangle.position.x=(cursor.rectangle.position.x-math.floor(cursor.rectangle.size.x/2))-cursor.position_offset.x
    cursor.rectangle.position.y=(cursor.rectangle.position.y-math.floor(cursor.rectangle.size.y/2))-cursor.position_offset.y
end

function module.Sol_DrawCursor(cursor)
    if cursor.draw_method == SV_Consts.draw_using.COLOR then
        love.graphics.setColor(SM_Color.Sol_TranslateColor(cursor.color))
        love.graphics.rectangle("fill", SM_Rectangle.Sol_UnpackRectXYWH(cursor.rectangle))
    else
        mwarn("drawing method not yet implemented for Sol_Cursor!")
        cursor.draw_method = SV_Consts.draw_using.COLOR
    end
end

--
return module