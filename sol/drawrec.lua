-- TODO: optimize the function arguments (specially rxpos, rypos)

local defaults=require("sol.defaults")
local consts=require("sol.consts")
local smath=require("sol.smath")
local storage=require("sol.storage")
local sgen=require("sol.sgen")
local module={}
--
function module.Sol_NewDrawRecipe(draw)
  -- _NewRecipe() build a recipe with the default values.
  local function _NewRecipe(recipe)
    return sgen.Sol_BuildStruct({
      draw_method             = 0,
      textures                = {},
      texture_index           = 1,
      texture_timing          = 0.1,
      texture_nextupdate      = 0,
      texture_autoupdate      = false,
      texture_counter         = 0,
    }, recipe)
  end
  -- _InitializeRecipes(): initializes all the recipes to prevent 'nil' accesses.
  local function _InitializeRecipes(recipes)
    local built_recipes = {}
    for recipe_name, recipe in pairs(recipes) do
      built_recipes[recipe_name]=_NewRecipe(recipe)
    end
    return built_recipes
  end
  return {
    recipes=_InitializeRecipes(draw["recipes"]),
    using_recipe=draw["using_recipe"] or 0,
    counter = draw["counter"] or 0,
    max_counter = draw["max_counter"] or 5,
  }
end

-- _DrawImage(): draw some image on the screen.
local function _DrawSimpleRectangle(draw, rxpos, rypos, width, height)
  love.graphics.setColor(smath.Sol_TranslateColor(draw.color))
  love.graphics.rectangle("fill", rxpos, rypos, width, height)
end

-- _DrawSequence(): draw a sequence of images or sprites. Use handle_texture for drawing.
local function _DrawSequence(draw, recipe, handle_texture)
  local function _DoTextureNextUpdateUsingTime()
    if recipe.texture_nextupdate<=os.clock() then
      recipe.texture_index=(recipe.texture_index>=#recipe.textures and 1 or recipe.texture_index+1)
      recipe.texture_nextupdate=os.clock()+recipe.texture_timing
    end
  end
  local function _DoTextureNextUpdateUsingCounter()
    if draw.counter >= draw.max_counter then
      recipe.texture_index=(recipe.texture_index>=#recipe.textures and 1 or recipe.texture_index+1)
      draw.counter = 0
    end
  end
  if type(recipe.textures)=="string" or #recipe.textures == 1 then
    handle_texture(recipe.textures[1])
  else
    handle_texture(recipe.textures[recipe.texture_index])
    -- if the autoupdate is not enabled, then check for the draw.counter and draw.max_counter
    -- there the user can add draw.counter until it becomes <= draw.max_counter.
    if recipe.texture_autoupdate then _DoTextureNextUpdateUsingTime()
    else _DoTextureNextUpdateUsingCounter() end
  end
end

-- _DrawSprites(): draw the sprite on the screen.
local function _DrawSprites(engine, draw, recipe, rxpos, rypos)
  local function _DrawSprite(name)
    local o_image, s_quad=storage.Sol_LoadSpriteFromStorage(engine.storage, name)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(o_image, s_quad, rxpos, rypos)
  end
  -- when draw.textures is string, it's just a single sprite.
  _DrawSequence(draw, recipe, _DrawSprite)
end

-- _DrawImages(): draw a sequence of images or a single image.
local function _DrawImages(engine, draw, recipe, rxpos, rypos)
  local function _DrawImage(name)
    local image = storage.Sol_LoadImageFromStorage(engine.storage, name)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, rxpos, rypos)
  end
  --
  _DrawSequence(draw, recipe, _DrawImage)
end

-- Sol_DrawUsingRecipe(): 
function module.Sol_DrawUsingRecipe(engine, draw, recipe, rxpos, rypos, width, height)
  if      recipe.draw_method == consts.draw_using.COLOR   then
    _DrawSimpleRectangle(recipe, rxpos, rypos, width, height)
  elseif  recipe.draw_method == consts.draw_using.SPRITES then
    _DrawSprites(engine, draw, recipe, rxpos, rypos)
  elseif  recipe.draw_method == consts.draw_using.IMAGES  then
    _DrawImages(engine, draw, recipe, rxpos, rypos)
  end
end

-- Sol_DrawRecipe():
function module.Sol_DrawRecipe(engine, draw, rxpos, rypos, width, height)
  if draw.using_recipe ~= 0 or draw.using_recipe ~= "0" then
    module.Sol_DrawUsingRecipe(engine, draw, draw.recipes[tostring(draw.using_recipe)], rxpos, rypos, width, height)
  end
end

--
return module