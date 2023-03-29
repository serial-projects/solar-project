local module = {}
local utils = require("solar.utils")
local scf = require("solar.scf")
--
function Solar_NewStorage(path)
  return {
    images    = {},
    fonts     = {},
    texts     = {},
    resource_path = path
  }
end
module.Solar_NewStorage = Solar_NewStorage

function Solar_StorageLoadLanguagePack(storage, language)
  local loaded_file = scf.SCF_LoadFile(storage.resource_path.."/lang/"..language..".lang")
  assert(loaded_file['language'], "language pack has no language section.")
  for key, content in pairs(loaded_file['language']) do
    storage.texts[key]=content
  end
end
module.Solar_StorageLoadLanguagePack = Solar_StorageLoadLanguagePack

function Solar_StorageGetText(storage, key)
  return storage.texts[key]
end
module.Solar_StorageGetText = Solar_StorageGetText

function Solar_StorageLoadImage(storage, image_key)
  local from_cache = storage.images[image_key]
  if from_cache then
    return from_cache
  else
    local path = storage.resource_path .. '/images/' .. image_key .. '.png'
    if utils.Solar_CheckFile(path) then
      local image = love.graphics.newImage(path)
      storage.images[image_key] = image
      return image
    end
  end
end
module.Solar_StorageLoadImage = Solar_StorageLoadImage

function Solar_StorageLoadFont(storage, font_key, size)
  -- TODO: enable a option to fully disable caching.
  local from_cache = storage.fonts[font_key.."_"..tostring(size)]
  if from_cache then
    -- TODO: more the element is used, keep it longer as cache.
    return from_cache.font
  else
    local path = storage.resource_path .. '/fonts/' .. font_key .. '.ttf'
    if utils.Solar_CheckFile(path) then
      local font = love.graphics.newFont(path, size)
      storage.fonts[font_key..'_'..tostring(size)]={lifespan=0, font=font}
      return font
    end
  end
end
module.Solar_StorageLoadFont = Solar_StorageLoadFont

function Solar_StorageLoadFile(storage, file)
  -- TODO: KEEP in cache some important file.
  local fp = io.open(storage.resource_path .. "/" .. file, "r")
  assert(fp~=nil,"failed to open file: "..file)
  local content = fp:read("*a") fp:close()
  return content
end
module.Solar_StorageLoadFile = Solar_StorageLoadFile

function Solar_StorageRemoveOldCache(storage)
  --
  function Solar_CheckStorageList(list, remove_keyword)
    local elements_deleted = 0
    for key, element in pairs(list) do
      if element.lifespan <= os.clock() then
        local sucess, _ = pcall(function()
          element[remove_keyword]:release()
        end)
        if sucess then
          elements_deleted = elements_deleted + 1
        end
        list[key]=nil
      end
    end
    return elements_deleted
    --
  end
  local deleted_images = Solar_CheckStorageList(storage.fonts,'font')
  local deleted_fonts  = Solar_CheckStorageList(storage.images,'image')
end
module.Solar_RemoveOldCache = Solar_RemoveOldCache

--
return module