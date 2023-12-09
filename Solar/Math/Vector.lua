-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}
--
function module.Sol_NewVector(x, y)
    if type(x) == "table" then
        y = x[2] or x["y"] or 0
        x = x[1] or x["x"] or 0
    end
    return { x = x, y = y }
end
function module.Sol_AddVector(avec, bvec)           return module.Sol_NewVector(bvec.x + avec.x, bvec.y + avec.y) end
function module.Sol_SubVector(avec, bvec)           return module.Sol_NewVector(bvec.x - avec.x, bvec.y - avec.y) end
function module.Sol_MultiplicateVector(avec, bvec)  return module.Sol_NewVector(bvec.x * avec.x, bvec.y * avec.y) end
function module.Sol_UnpackVectorXY(vector)          return vector.x, vector.y end
--
return module