local Frame = {}
Frame.__index = Frame


function Frame.New(frameName)
    local newInstance = {
        frameName = frameName or "Frame",
        paths = {},
        methods = {}
    }
    return setmetatable(newInstance, Frame)
end


local MetaFrame = {
    __call = function(self, frameName)
        return Frame.New(frameName)
    end
}
setmetatable(Frame, MetaFrame)


local function CleanPath(path)
    path = tostring(path)
    path = string.match(path, "^/") and path or string.format("/%s", path)
    path = string.len(path) == 1 and path or string.gsub(path, "^(.-)%s*/$", "%1")
    return path
end


function Frame:Page(path, method, func)
    method = tostring(method):upper()
    path = CleanPath(path)

    self.paths[path] = self.paths[path] or {}
    table.insert(self.paths[path], method)   -- list can have duplicate methods
    self.methods[method] = self.methods[method] or {}
    self.methods[method][path] = func  -- keys are overwritten if already defined
    Log(kLogInfo,
        string.format("%s: created page with path '%s' for the %s method", self.frameName, path, method)
    )
end

function Frame:Get(path, func) return Frame.Page(self, path, "GET", func) end
function Frame:Head(path, func) return Frame.Page(self, path, "HEAD", func) end
function Frame:Post(path, func) return Frame.Page(self, path, "POST", func) end
function Frame:Put(path, func) return Frame.Page(self, path, "PUT", func) end
function Frame:Delete(path, func) return Frame.Page(self, path, "DELETE", func) end
function Frame:Patch(path, func) return Frame.Page(self, path, "PATCH", func) end


function Frame:RoutePath(path, method)
    method = method and tostring(method):upper() or tostring(GetMethod()):upper()
    local pages = self.methods[method]
    if not pages then
        Log(kLogWarn, string.format("%s: method %s not implemented", self.frameName, method))
        return false, 501, "Not Implemented"
    end

    local args = {}
    local cleanPath = CleanPath(path)
    local func = pages[EscapePath(cleanPath)]
    if not func then
        -- check if path matches any regex path
        for path_, func_ in pairs(pages) do
            args = { re.search(string.format([[^%s/?$]], path_), cleanPath) }
            if #args > 0 then
                func = func_
                break
            end
        end
    end
    if not func then
        if not self.paths[cleanPath] then
            Log(kLogWarn, string.format("%s: page '%s' for method %s was not found", self.frameName, cleanPath, method))
            return false, 404, "Not Found"
        else
            Log(kLogWarn, string.format("%s: page '%s' does not have method %s", self.frameName, cleanPath, method))
            return false, 405, "Method Not Allowed"
        end
    end

    local ok, data, respBool, respCode, respMsg = xpcall(
            func,
            function(message) Log(kLogError, message) end,
            select(2, table.unpack(args))
    )
    if not ok then
        Log(kLogDebug, string.format("%s: function of %s created an error", self.frameName, cleanPath))
        Log(kLogDebug, string.format("%s: 'path' %s was requested with %s", self.frameName, cleanPath, method))
        return false, 500, "Internal Server Error"
    elseif data then
        Write(tostring(data))
    end

    Log(kLogInfo, string.format("%s: page '%s' with method %s was successful", self.frameName, cleanPath, method))
    return respBool or true, respCode or 200, respMsg or "OK"
end


return Frame