-- /.init.lua is loaded at startup in redbean's main process

-- extend package.path so lua files in other directories can be loaded in
package.path = string.format("%s;?.lua", package.path)
local Frame = require("page/example")


HidePath('/usr/share/zoneinfo/')
HidePath('/usr/share/ssl/')


function OnHttpRequest()
    local path = GetPath()

    -- check if the given path is hidden
    if IsHiddenPath(path) then
        ServeError(403, "Forbidden")
    end

    -- try the path on the loaded frame module
    local respBool, respCode, respMessage = Frame:RoutePath(path)
    if respBool then
        return

    -- check if the path is in the zip or serving directory
    elseif not RoutePath(path) then
        ServeError(respCode, respMessage)
    end
end