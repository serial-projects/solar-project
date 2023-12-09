-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module={}

-- Sol_UITranslateRelativePosition(ww, wh, ew, eh, posx, posy: number) -> abposx: number, abposy: number
function module.Sol_UITranslateRelativePosition(ww, wh, ew, eh, posx, posy)
    -- calculate the window divided by 100 (for every axis.)
    local xpos, ypos      = (ww / 100), (wh / 100)
    local xoff, yoff      = (ew / 100) * posx, (eh / 100) * posy
    local abposx, abposy  = (xpos * posx) - xoff, (ypos * posy) - yoff
    return math.floor(abposx), math.floor(abposy)
end

--
return module