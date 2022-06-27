local Frame = {}
Frame.__index = Frame

function Frame:Page(path, method, func)
    method = tostring(method):upper()
    self.paths[path] = method
    self.methods[method] = self.methods[method] or {}
    self.methods[method][path] = func
end

function Frame:RoutePath(path, method)
    method = method and tostring(method):upper() or GetMethod()

    local pages = self.methods[method]
    local func = pages[path]
    return func()
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

local frame = Frame("new frame")

local function sheet()
    return "sheet"
end

frame:Page("test", "get", sheet)

local result = frame:RoutePath("test", "get")
print(result)

return Frame
