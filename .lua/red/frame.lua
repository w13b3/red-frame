local Frame = {}
Frame.__index = Frame


-- local mocks
local Write = print


function Frame:Page(path, method, func)
    method = tostring(method):upper()

    path = tostring(path)
    path = string.match(path, "^/") and path or string.format("/%s", path)
    path = string.len(path) == 1 and path or string.gsub(path, "^(.-)%s*/$", "%1")

    self.paths[path] = self.paths[path] or {}
    table.insert(self.paths[path], method)
    self.methods[method] = self.methods[method] or {}
    self.methods[method][path] = func
end

function Frame:Get(path, func) return Frame.Page(self, path, "GET", func) end
function Frame:Head(path, func) return Frame.Page(self, path, "HEAD", func) end
function Frame:Post(path, func) return Frame.Page(self, path, "POST", func) end
function Frame:Put(path, func) return Frame.Page(self, path, "PUT", func) end
function Frame:Delete(path, func) return Frame.Page(self, path, "DELETE", func) end
function Frame:Patch(path, func) return Frame.Page(self, path, "PATCH", func) end


function Frame:RoutePath(path, method)
    method = method and tostring(method):upper() or GetMethod()

    local cleanPath = EscapePath(path)

    local pages = self.methods[method]
    if not pages then
        return false, 501, "Not Implemented"
    end

    local func = pages[cleanPath]
    if not func then
        return false, 404, "Not Found"
    end

    local ok, data, respBool, respCode, respMsg = xpcall(func, print)
    if not ok then
        return false, 500, "Internal Server Error"
    elseif data then
        Write(tostring(data))
    end

    return respBool or true, respCode or 200, respMsg or "OK"
end


function Frame.New(frameName)
    local newInstance = {
        frameName = frameName,
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


-- local testing

local frame = Frame("new frame")

local function sheet()
    return nil, true, 201, "Created"
end

local function err()
    return "nil" .. nil
end

frame:Page("/", "get", sheet)
frame:Get("test", sheet)
frame:Post("/my%20test/path/", sheet)  -- create page with space in path

print("found: ", frame:RoutePath("/", "get"))
print("found: ", frame:RoutePath("/test", "get"))
print("found: ", frame:RoutePath("/my test/path", "post"))

print("not found: ", frame:RoutePath("/test1", "get"))
print("no method like this", frame:RoutePath("/test", "post"))

 frame:Page("/err", "post", err)
print("func error", frame:RoutePath("/err", "post"))




return Frame
