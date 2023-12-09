-- 2020 - 2023 Solar Engine by Pipes Studios. This project is under the MIT license.

local module = {}

-- Sol_MergePath: set the real path for something.
function module.Sol_MergePath(path_entries)
    local final_path,last_dir_had_endslash="",false
    for index, entry in ipairs(path_entries) do
        local current_dir_beginslash=entry:sub(1,1)=='/'
        --[[ this situation: /root/ + /sub/ = /root/sub (leave only one slash, remove from entry!) ]]
        if current_dir_beginslash and last_dir_had_endslash then
            entry=entry:sub(2,#entry)
        --[[ this situation: /root + sub/ (put a slash) ]]
        --[[ NOTE: fix for love directories, on index = 1, ignore this. ]]
        elseif index ~= 1 and not current_dir_beginslash and not last_dir_had_endslash then
            entry='/'..entry
        end
        last_dir_had_endslash=entry:sub(#entry,#entry)=='/'
        final_path=final_path..entry
    end
    return final_path
end

return module