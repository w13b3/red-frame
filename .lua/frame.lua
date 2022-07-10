local Frame = {
    _VERSION = "frame.lua 0.0.2",
    _URL = "https://github.com/w13b3/red-frame",
    _DESCRIPTION = "website framework for redbean",
    _LICENSE = [[
        Copyright 2022 w13b3

        Permission to use, copy, modify, and/or distribute this software for
        any purpose with or without fee is hereby granted, provided that the
        above copyright notice and this permission notice appear in all copies.

        THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
        WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
        AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
        DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
        PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
        TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
        PERFORMANCE OF THIS SOFTWARE.
    ]]
}
Frame.__index = Frame


---Initialize a new instance of Frame
---@public
---@param frameName string optional name for logging purpose
---@return table the new instance
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


---Clean and form the path to an expected format
---@private
---@param path string a path to clean
---@return string a path that has an expected format
local function CleanPath(path)
    path = tostring(path)
    -- if path doesn't start with '/', add a '/'.
    path = string.match(path, "^/") and path or string.format("/%s", path)
    -- if path only has a '/', do nothing, else remove trailing '/'
    path = string.len(path) == 1 and path or string.gsub(path, "^(.-)%s*/$", "%1")
    return path
end


---Create a page that calls the given function based on which method it is requested with
---@public
---@param path string the path to the page
---@param method string the HTTP-method to use for this page
---@param func function the function to call when the page is requested using the given method
---@return nil
function Frame:Page(path, method, func)
    method = tostring(method):upper()
    path = CleanPath(path)

    self.paths[path] = self.paths[path] or {}  -- add table to paths for the path, if it doesn't already exists
    table.insert(self.paths[path], method)   -- list can have duplicate methods

    -- assure that given func ends up in the methods as a function
    if type(func) == "function" then
        self.methods[method] = self.methods[method] or {}  -- add table for method
        self.methods[method][path] = func  -- keys are overwritten if already defined
        Log(kLogInfo, string.format(
            "%s: created page with path '%s' for the %s method", self.frameName, path, method
        ))
    else
        Log(kLogError, string.format(
            "%s: the object given to '%s' is of type %s, expected 'function'", self.frameName, path, type(func)
        ))
    end

end


---Create a page that calls the given function if it is requested with the GET method
---@public
---@param path string path of the page
---@param func function a function to call when a GET request is made to given `pagePath`
---@return nil
function Frame:Get(path, func) return Frame.Page(self, path, "GET", func) end


---Create a page that calls the given function if it is requested with the HEAD method
---@public
---@param path string path of the page
---@param func function a function to call when a HEAD request is made to given path
---@return nil
function Frame:Head(path, func) return Frame.Page(self, path, "HEAD", func) end


---Create a page that calls the given function if it is requested with the POST method
---@public
---@param path string path of the page
---@param func function a function to call when a POST request is made to given path
---@return nil
function Frame:Post(path, func) return Frame.Page(self, path, "POST", func) end


---Create a page that calls the given function if it is requested with the PUT method
---@public
---@param path string path of the page
---@param func function a function to call when a PUT request is made to given path
---@return nil
function Frame:Put(path, func) return Frame.Page(self, path, "PUT", func) end


---Create a page that calls the given function if it is requested with the DELETE method
---@public
---@param path string path of the page
---@param func function a function to call when a DELETE request is made to given path
---@return nil
function Frame:Delete(path, func) return Frame.Page(self, path, "DELETE", func) end


---Create a page that calls the given function if it is requested with the PATCH method
---@public
---@param path string path of the page
---@param func function a function to call when a PATCH request is made to given path
---@return nil
function Frame:Patch(path, func) return Frame.Page(self, path, "PATCH", func) end


---Uses given path to find a defined page, if found the content of the page is shown.
---@public
---@param path string the requested path
---@param method string (optional) the HTTP-method to use for given path
---@return boolean, number, string true if successful false otherwise, HTTP status code, HTTP status message
function Frame:RoutePath(path, method)
    method = method and tostring(method):upper() or tostring(GetMethod()):upper()
    -- `pages` is the paths defined for the requested method
    local pages = self.methods[method]
    -- if pages is nil then the method is not implemented
    if not pages then
        Log(kLogWarn, string.format("%s: method %s not implemented", self.frameName, method))
        return false, 501, "Not Implemented"
    end

    local args = {}
    local cleanPath = CleanPath(path or "/")
    -- get the function of the defined path, if not check if the path matches with defined Regex
    local func = pages[EscapePath(cleanPath)]
    if not func then
        -- check if path matches any regex path
        for path_, func_ in pairs(pages) do
            args = { re.search(string.format([[^%s/?$]], path_), cleanPath) }
            if args[1] ~= nil then
                func = func_
                break
            end
        end
    end
    -- if func is still nil, return an error code
    if not func then
        if not self.paths[cleanPath] then
            Log(kLogWarn, string.format("%s: page '%s' for method %s was not found", self.frameName, cleanPath, method))
            return false, 404, "Not Found"
        else
            Log(kLogWarn, string.format("%s: page '%s' does not have method %s", self.frameName, cleanPath, method))
            return false, 405, "Method Not Allowed"
        end
    end

    -- call the function given to the page and return the data
    local ok, data, respBool, respCode, respMsg = xpcall(
            func,
            -- callback function for logging if an error occurs in func
            (function(message) Log(kLogError, message) end),
            -- unpack re.search, the first result is the match, the others are the matched groups
            -- give the matched strings as arguments to the func
            select(2, table.unpack(args))
    )
    if not ok then
        Log(kLogDebug, string.format("%s: function of %s created an error", self.frameName, cleanPath))
        Log(kLogDebug, string.format("%s: 'path' %s was requested with %s", self.frameName, cleanPath, method))
        return false, 500, "Internal Server Error"
    elseif data ~= nil then
        -- show the data what is returned from the page call
        Write(tostring(data))
    end

    Log(kLogInfo, string.format("%s: page '%s' with method %s was successful", self.frameName, cleanPath, method))
    if respBool == nil then respBool = true end -- keep respBool false if false is given
    return respBool, respCode or 200, respMsg or "OK"
end


---Get the HTTP-methods that a path can use
---@public
---@param path string a path to a page
---@return table sorted array of strings
function Frame:GetMethodsOfPath(path)
    path = CleanPath(path)
    local result = {}
    for method, methodTable in pairs(self.methods) do
        if methodTable[path] then
            table.insert(result, method)
        end
    end
    table.sort(result)
    return result
end


---Get the paths that a HTTP-method contains
---@public
---@param method string HTTP-method like: GET, POST ,etc.
---@return table sorted array of strings
function Frame:GetPathsOfMethod(method)
    method = method and tostring(method):upper() or ""
    local result = {}
    for path, _ in pairs(self.methods[method] or {}) do
        table.insert(result, path)
    end
    table.sort(result)
    return result
end


---This checks if all the pages are defined correctly
---@public
---@return boolean, string true, "OK" returned if no errors are found
---@return boolean, string false, error message returned if errors are found
function Frame:IsValidDefined()
    for method, _ in pairs(self.methods) do
        local allPaths = self:GetPathsOfMethod(method)
        for _, path in ipairs(allPaths) do
            local message = string.format(
                "%s: method %s of path '%s' is faulty", self.frameName, method, path
            )
            local extractedMethods = self:GetMethodsOfPath(path)
            local definedMethods = self.paths[path] or {}
            if #extractedMethods ~= #definedMethods then
                return false, message
            end
            local tbl1, tbl2 = {}, {}
            for key, _ in pairs(extractedMethods) do
                tbl1[key] = (tbl1[key] or 0) + 1
            end
            for key, _ in pairs(definedMethods) do
                tbl2[key] = (tbl2[key] or 0) + 1
            end
            for key, value in pairs(tbl1) do
                if value ~= tbl2[key] then
                    return false, message
                end
            end
        end
    end
    return self, "OK"
end


return Frame