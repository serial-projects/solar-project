local module = {}
-- functional.safecall(f: function, ...): returns true or false wheather the
-- function executed good or bad, also check if 'f' is a function, case not,
-- then just ignore and return true.
function module.safecall(f, ...)
    if type(f) == "function" then
        local ok, error = pcall(
            f, ...
        )
        return ok
    end
end
-- 
return module