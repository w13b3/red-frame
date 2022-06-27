local Frame = {}
Frame.__index = Frame


function Frame:Page(path, method, func)
    method = tostring(method):upper()
    self.paths[path] = self.paths[path] or {}
    table.insert(self.paths[path], method)
    self.methods[method] = self.methods[method] or {}
    self.methods[method][path] = func
end


function Frame:RoutePath(path, method)
    method = method and tostring(method):upper() or GetMethod()

    local pages = self.methods[method]
    if not pages then
        return false, 405
    end

    local func = pages[path]
    if not func then
        return false, 404
    end

    local ok, data = xpcall(func, print)
    if not ok then
        return false, 500
    elseif data then
        print(data)
    end

    return true, 200
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
    return "sheet"
end

local function err()
    return "nil" .. nil
end

frame:Page("test", "get", sheet)
frame:Page("err", "post", err)

print("found: ", frame:RoutePath("test", "get"))
print("not found: ", frame:RoutePath("test1", "get"))
print("no method like this", frame:RoutePath("test", "post"))
print("func error", frame:RoutePath("err", "post"))




return Frame
