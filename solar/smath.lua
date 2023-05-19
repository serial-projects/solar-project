local module={}

--
-- Vector Utils
--
function Solar_NewVectorXY(x, y)
  return {
    x = (x or 0), y = (y or 0)
  }
end
module.Solar_NewVectorXY = Solar_NewVectorXY

--
-- Colar Utils
--
function Solar_NewColor(r, g, b, a)
  return { red = r or 0, green = g or 0, blue = b or 0, alpha = a or 255 }
end
module.Solar_NewColor = Solar_NewColor
function Solar_TranslateColor(color)
  return color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255
end
module.Solar_TranslateColor = Solar_TranslateColor

--
-- Math Utils
--
function Solar_GetRelativePosition(pr, pa, tp)
  -- pr: position relative
  -- pa: position absolute
  -- tp: tile position
  return (-pa.x + pr.x) + tp.x, (-pa.y + pr.y) + tp.y
end
module.Solar_GetRelativePosition = Solar_GetRelativePosition

--
return module