-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
local sfmt = string.format

--
function module.Sol_NewVector(x, y)
    local proto_vector = (type(x) == "table")   and { x = (x[1] or x["x"]) or 0, y = (x[2] or x["y"]) or 0}
                                                or { x = x or 0, y = y or 0 }
    function proto_vector:add(vector) self.x, self.y = self.x + vector.x, self.x + vector.y end
    function proto_vector:sub(vector) self.x, self.y = self.x - vector.x, self.x - vector.y end
    function proto_vector:mul(vector) self.x, self.y = self.x * vector.x, self.y * vector.y end
    function proto_vector:div(vector) self.x, self.y = self.x / vector.x, self.y / vector.y end
    function proto_vector:unpackxy() return self.x, self.y end
    setmetatable(proto_vector, {
        __add = function(base_vector, vector) base_vector:add(vector) end,
        __sub = function(base_vector, vector) base_vector:sub(vector) end,
        __mul = function(base_vector, vector) base_vector:mul(vector) end,
        __div = function(base_vector, vector) base_vector:div(vector) end,
        __tostring = function(base_vector) return sfmt("X: %d, Y: %d", base_vector.x, base_vector.y) end
    })
    return proto_vector
end
--
return module