-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
--
function module.Sol_NewColor4(red, green, blue, alpha)
    if type(red)=="table" then
        alpha=  red[4] or red["alpha"]  or 255
        blue=   red[3] or red["blue"]   or 0
        green=  red[2] or red["green"]  or 0
        red=    red[1] or red["red"]    or 0
    end
    return { red = red or 0,   green = green or 0,   blue = blue or 0,   alpha = alpha or 255 }
end

function module.Sol_TranslateColor(color)
    return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end
--
return module

