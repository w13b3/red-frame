How-to: Create pages
---

_The examples in this document assumes red-frame is added to the Redbean zip (.lua/red/frame.lua)_


### Add the red-frame module to the Lua script
```lua
local Frame = require("frame")
```

### Start a new instance of red-frame
```lua
local frame = Frame.New("Optional Frame name")
```

### Create a page that reacts on a GET request
```lua
frame:Get("/", function()
    return "<h1>Homepage</h1>"
end)
```

### Create a page that reacts on another HTTP Method
```lua
frame:Post("/", function()
    SetHeader('Content-Type', 'application/json; charset=utf-8')
    return [[{"data": "Hello world"}]]
end)
```
Available ptions: `Get` `Head` `Post` `Put` `Delete` `Patch`

### Create a page for a custom HTTP Method
```lua
local function Link()
    Log(kLogDebug, "path '/' is requested with LINK method")
end
frame:Page("/", "LINK", Link)
```


### Check if the frame is defined without errors
```lua
local frame, assert(frame:IsValidDefined())
```


## Complete example code:

```lua
local Frame = require("frame")
local frame = Frame.New("Optional Frame name")

frame:Get("/", function()
    return "<h1>Homepage</h1>"
end)

frame:Post("/", function()
    -- received Post request to `/` path
end)

local function Link()
    Log(kLogDebug, "path '/' is requested with LINK method")
end
frame:Page("/", "LINK", Link)

assert(frame:IsValidDefined())
return frame
```






