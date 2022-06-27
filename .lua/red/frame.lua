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



-- local mocks
local Write = print


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
    table.insert(self.paths[path], method)
    self.methods[method] = self.methods[method] or {}
    self.methods[method][path] = func
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
    method = method and tostring(method):upper() or GetMethod()

    local cleanPath = CleanPath(path)
    cleanPath = EscapePath(cleanPath)

    local pages = self.methods[method]
    if not pages then
        Log(kLogWarn, string.format("%s: method %s not implemented", self.frameName, method))
        return false, 501, "Not Implemented"
    end

    local func = pages[cleanPath]
    if not func then
        Log(kLogWarn, string.format("%s: page '%s' for method %s was not found", self.frameName, path, method))
        return false, 404, "Not Found"
    end

    local ok, data, respBool, respCode, respMsg = xpcall(func, function(message) Log(kLogError, message) end)
    if not ok then
        Log(kLogDebug, string.format("%s: function of %s created an error", self.frameName, path))
        Log(kLogDebug, string.format("%s: 'path' %s was requested with %s", self.frameName, path, method))
        return false, 500, "Internal Server Error"
    elseif data then
        Write(tostring(data))
    end

    Log(kLogInfo, string.format("%s: page '%s' with method %s was successful", self.frameName, path, method))
    return respBool or true, respCode or 200, respMsg or "OK"
end



-- local testing

local frame = Frame()

local function sheet()
    return nil, true, 201, "Created"
end

local function err()
    return "nil" .. nil
end

frame:Page("/", "get", sheet)   -- mix
frame:Post("/", sheet)          -- match

frame:Get("test", sheet)
frame:Post("/my%20test/path/", sheet)  -- create page with space in path

print("found: ", frame:RoutePath("/", "get"))
print("found: ", frame:RoutePath("//", "post"))
print("found: ", frame:RoutePath("/put", "put"))

print("found: ", frame:RoutePath("test", "get"))
print("found: ", frame:RoutePath("/my test/path", "post"))

print("not found: ", frame:RoutePath("test1", "get"))
print("no method like this", frame:RoutePath("test", "post"))

 frame:Page("/err", "post", err)
print("func error", frame:RoutePath("err", "post"))




return Frame
