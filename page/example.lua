-- /page/example

local Frame = require("frame")
local frame = Frame.New("Example")


frame:Get("/", function()
    -- load and return show the example.html
    return LoadAsset("/page/example.html")
end)


frame:Post("/", function()
    -- let a post request to the '/' path return some JSON
    SetHeader('Content-Type', 'application/json; charset=utf-8')
    return [[{"data": "This is an example"}]]
end)


return assert(frame:IsValidDefined())