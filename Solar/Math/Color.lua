-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
local floor = math.floor

--
function module.Sol_NewColor4(red, green, blue, alpha)
    local proto_color4 = ( type(red) == "table" )   and {red = (red[1] or red["red"]) or 0, blue = (red[2] or red["blue"]) or 0, green = (red[3] or red["green"]) or 0, alpha = (red[4] or red["alpha"]) or 255 }
                                                    or  {red = red or 0, green = green or 0, blue = blue or 0, alpha = alpha or 255}
    function proto_color4:unpackrgb()   return self.red, self.green, self.blue end
    function proto_color4:unpackrgba()  return self.red, self.green, self.blue, self.alpha end
    function proto_color4:translate()   return self.red / 255, self.green / 255, self.blue / 255, self.alpha / 255 end
    function proto_color4:lerp(target, t)
        return module.New_Color4(
            floor(self.red    + (target.red    - self.red)     * t),
            floor(self.green  + (target.green  - self.green)   * t),
            floor(self.blue   + (target.blue   - self.blue)    * t),
            floor(self.alpha  + (target.alpha  - self.alpha)   * t)
        )
    end
    return proto_color4
end
--
return module

