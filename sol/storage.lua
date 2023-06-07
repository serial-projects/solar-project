-- storage.lua: keep track of the cached elements like fonts and images.
local sgen=require("sol.sgen")
local system=require("sol.system")
local scf=require("sol.scf")
local module={}

-- Storage/CacheOperations section:
function module.Sol_NewCache(cache)
  return sgen.Sol_BuildStruct({keep=true, lastuse=0, content=0}, cache)
end

-- Storage/NewStorage section:
function module.Sol_NewStorage(root)
  return {current_language = "default", texts = {}, cached_elements={}, root=root, maxlifespan=5}
end

-- Storage/Image:
function module.Sol_LoadImageFromStorage(storage, name, base_directory, keep_around)
  local base_directory = base_directory or "images/"
  local keep_around = keep_around == nil and true or keep_around
  local cache_entry,path_resource=(base_directory..name),system.Sol_MergePath({storage.root,base_directory,(name..".png")})
  if storage.cached_elements[cache_entry] then
    storage.cached_elements[cache_entry].lastuse=os.time()
    return storage.cached_elements[cache_entry].content
  else
    dmsg("Sol_LoadImageFromStorage() is loading element: "..path_resource)
    local new_image=love.graphics.newImage(path_resource)
    local proto_cache=module.Sol_NewCache({keep=keep_around, lastuse=os.time(), content=new_image})
    storage.cached_elements[cache_entry]=proto_cache
    return new_image
  end
end

-- Storage/Sprites:
--[[
  NOTE: sprites are kinda heavy on the memory or on the CPU time for some reasons:
  * It requires us to cut from the image.
  * To load the sprite instruction file (aka. slsp file).
  * To run SCF_LoadFile() on the .slsp file.
  --
  * Things that are kept on the memory are: the .slsp file of the sprite.
    SCF_LoadFile() is a heavy function: it needs to tokenize the file -> build a tree of it.
    Using this function less often is the best option to prevent lag.
  * The sprite huge image.
    Makes easy to just cut, although, on the future this may change.
  
  __Sol_AdquireSpriteNameAndFrameFromSpriteTag() -> sprite_name, sprite_frame
  __Sol_MakeSpriteFrameToLoveQuad() -> love_quad
  Sol_LoadSpriteFromStorage() -> original_image, love_quad
]]
local function __Sol_AdquireSpriteNameAndFrameFromSpriteTag(sprite_tag)
  local sep_position=string.findch(sprite_tag, ':') ; assert(sep_position ~= nil, "invalid sprite_tag: "..sprite_tag)
  return sprite_tag:sub(1,sep_position-1), sprite_tag:sub(sep_position+1, #sprite_tag)
end
local function __Sol_MakeSpriteFrameToLoveQuad(sprite_frame, original_image)
  return love.graphics.newQuad(sprite_frame["cut_x"], sprite_frame["cut_y"], sprite_frame["cut_width"], sprite_frame["cut_height"], original_image:getDimensions())
end
function module.Sol_LoadSpriteFromStorage(storage, sprite_tag, keep_around)
  -- cache.content={instructions={}}
  local keep_around = keep_around == nil and true or keep_around
  local sprite_name, sprite_frame = __Sol_AdquireSpriteNameAndFrameFromSpriteTag(sprite_tag)
  local cache_entry="sprited:"..sprite_name
  local original_image=module.Sol_LoadImageFromStorage(storage, sprite_name, "sprites/", keep_around)
  if storage.cached_elements[cache_entry] then
    local cached_content=storage.cached_elements[cache_entry].content
    storage.cached_elements[cache_entry].lastuse=os.time()
    return original_image, __Sol_MakeSpriteFrameToLoveQuad(cached_content.instructions[sprite_frame], original_image)
  else
    local sprite_instruction=system.Sol_MergePath({storage.root,"sprites/",(sprite_name..".slsp")})
    dmsg("Sol_LoadSpriteFromStorage() is loading sprite instruction file: "..sprite_instruction)
    sprite_instruction=scf.SCF_LoadFile(sprite_instruction)
    --
    local proto_cache=module.Sol_NewCache({keep=keep_around, lastuse=os.time(), content={instructions=sprite_instruction}})
    storage.cached_elements[cache_entry]=proto_cache
    return original_image, __Sol_MakeSpriteFrameToLoveQuad(sprite_instruction[sprite_frame], original_image)
  end
end

-- Storage/Font:
function module.Sol_LoadFontFromStorage(storage, name, size, keep_around)
  local keep_around = keep_around == nil and true or keep_around
  local cache_entry,path_resource=string.format("font:%s:%d",name,size),system.Sol_MergePath({storage.root,"fonts/",(name..".ttf")})
  if storage.cached_elements[cache_entry] then
    storage.cached_elements[cache_entry].lastuse=os.time()
    return storage.cached_elements[cache_entry].content
  else
    dmsg("Sol_LoadFontFromStorage() is loading element: "..path_resource)
    local new_font=love.graphics.newFont(path_resource, size)
    local proto_cache=module.Sol_NewCache({keep=keep_around, lastuse=os.time(), content=new_font})
    storage.cached_elements[cache_entry]=proto_cache
    return new_font
  end
end

-- Storage/CacheCleaningAndManagement Section:
function module.Sol_CleanCacheInStorage(storage)
  local marktoremove, timestamp={}, os.time()
  for key, cache_element in pairs(storage.cached_elements) do
    if not cache_element.keep then
      local timealive=(timestamp - cache_element.lastuse)
      if  timealive > storage.maxlifespan then
        table.insert(marktoremove, key)
      end
    end
  end
  --
  for _, key in ipairs(marktoremove) do
    dmsg("Sol_CleanCacheInStorage() cleaned element \"%s\" from cache.", key)
    storage.cached_elements[key].content:release()
    storage.cached_elements[key]=nil
  end
end

-- Storage/Language Section:
function module.Sol_ReplaceTexts(storage, texts)
  for text_key, text in pairs(texts) do
    if storage.texts[text_key] then
      dmsg("replacing text(key=%s): \"%s\" -> \"%s\"...", text_key, storage.texts[text_key], text)
    end
    storage.texts[text_key]=text
  end
end

function module.Sol_LoadLanguage(storage, language)
  local lang_file=system.Sol_MergePath({storage.root,"lang/",(language..".lang")})
  dmsg("Sol_LoadLanguage() is loading the file: "..lang_file)
  --
  lang_file=scf.SCF_LoadFile(lang_file) ; makesure(lang_file["texts"],42,"no text section found on language: "..language)
  module.Sol_ReplaceTexts(storage, lang_file["texts"])
  storage.current_language=language
end

function module.Sol_GetText(storage, key)
  return storage.texts[key] == nil and "?" or storage.texts[key]
end

--
return module