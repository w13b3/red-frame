How-to: Route to pages
---

_The examples in this document assumes red-frame is added to the Redbean zip (.lua/red/frame.lua)_

### The setup
This document assumes the following code in the zip path: `/page/myframe.lua`

```lua
-- filename: /page/myframe.lua

local Frame = require("frame")
local frame = Frame.New("My Frame")

-- root page
frame:Get("/", function() 
    return [[<h1>homepage</h1>]]
end)

-- return the frame instance
return frame
```

### The .init.lua file

To pass on requests to the frame instance the `page/myframe.lua` module needs to be included into `.init.lua`  
```lua
-- filename: /.init.lua

-- extend the path where Lua's require looks for modules
package.path = string.format("%s;/zip/?.lua", package.path)

-- require runs the file, `myFrame` is the returned frame instance
local myFrame = require("page/myframe")
```

`.init.lua` is where the redbean provided [OnHttpRequest](https://redbean.dev/#OnHttpRequest) hook is available.  
This function is used to pass the requested path to the `RoutePath` function of the `myFrame` frame instance.  
```lua
function OnHttpRequest()
    local path = GetPath()
    myFrame:RoutePath(path)
end
```

Everytime a request is send to Redbean the `OnHttpRequest` hook is called.  
`RoutePath` requires the path that is requested, `RoutePath` figures out the method itself by calling [`GetMethod`](https://redbean.dev/#GetMethod)


### Note
A more advanced form of OnHttpRequest hook is available here: [:link: .init.lua](../.init.lua)  