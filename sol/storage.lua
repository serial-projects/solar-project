-- storage.lua: keep track of the cached elements like fonts and images.
local sgen=require("sol.sgen")
local system=require("sol.system")
local scf=require("sol.scf")
local module={}

-- Storage/CacheOperations section:
function Sol_NewCache(cache)
  return sgen.Sol_BuildStruct({keep=true, lastuse=0, content=0}, cache)
end ; module.Sol_NewCache=Sol_NewCache

-- Storage/NewStorage section:
function Sol_NewStorage(root)
  return {current_language = "default", texts = {}, cached_elements={}, root=root, maxlifespan=5}
end ; module.Sol_NewStorage=Sol_NewStorage

-- Storage/Image, Sprite and Font Section:
function Sol_LoadFontFromStorage(storage, name, size)
  local cache_entry,path_resource=string.format("font:%s:%d",name,size),system.Sol_MergePath({storage.root,"fonts/",(name..".ttf")})
  if storage.cached_elements[cache_entry] then
    storage.cached_elements[cache_entry].lastuse=os.time()
    return storage.cached_elements[cache_entry].content
  else
    dmsg("Sol_LoadFontFromStorage() is loading element: "..path_resource)
    local new_font=love.graphics.newFont(path_resource, size)
    local proto_cache=Sol_NewCache({lastuse=os.time(), content=new_font})
    storage.cached_elements[cache_entry]=proto_cache
    return new_font
  end
end ; module.Sol_LoadFontFromStorage=Sol_LoadFontFromStorage

-- Storage/CacheCleaningAndManagement Section:
function Sol_CleanCacheInStorage(storage)
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
end ; module.Sol_CleanCacheInStorage=Sol_CleanCacheInStorage

-- Storage/Language Section:
function Sol_ReplaceTexts(storage, texts)
  for text_key, text in pairs(texts) do
    if storage.texts[text_key] then
      dmsg("replacing text(key=%s): \"%s\" -> \"%s\"...", text_key, storage.texts[text_key], text)
    end
    storage.texts[text_key]=text
  end
end ; module.Sol_ReplaceTexts=Sol_ReplaceTexts
function Sol_LoadLanguage(storage, language)
  local lang_file=system.Sol_MergePath({storage.root,"lang/",(language..".lang")})
  dmsg("Sol_LoadLanguage() is loading the file: "..lang_file)
  --
  lang_file=scf.SCF_LoadFile(lang_file) ; makesure(lang_file["texts"],42,"no text section found on language: "..language)
  Sol_ReplaceTexts(storage, lang_file["texts"])
  storage.current_language=language
end ; module.Sol_LoadLanguage=Sol_LoadLanguage
function Sol_GetText(storage, key)
  return storage.texts[key] == nil and "?" or storage.texts[key]
end ; module.Sol_GetText=Sol_GetText
--
return module