local Frame = {}
Frame.__index = Frame

local function update(tbl, key, value)
    tbl[key] = tbl[key] or {}
    table.insert(tbl[key], value or {})
end

function Frame:Page(path, method, func)
    method = method or GetMethod()
    method = tostring(method):upper()
    --print(require("inspect")(self.paths))

    update(self.paths, path, method)
    update(self.methods, method)
    update(self.methods[method], path, func)
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




return Frame
