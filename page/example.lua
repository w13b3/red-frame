
local Frame = require("red/frame")
local frame = Frame.New("Example")


frame:Get("/", function()
    return "<h1>Homepage</h1>"
end)


return frame