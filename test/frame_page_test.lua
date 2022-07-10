--[[ frame page test ]]

package.path = string.format("%s;/zip/?.lua", package.path)

local Suite = require("test/probo/suite")
local Report = require("test/probo/htmlreport")

local Frame = require("frame")


local runInfo
do
    local test <close> = Suite.New('Frame page test')
    local assert <const> = test -- for readability

    -- [[ preparation ]]

    function test:Setup()
        func = function(...) return ... end
        frame = Frame("Frame page test")
    end

    function test:Teardown()
        frame = nil
    end

    -- [[ tests ]]

    test("Frame Get function creates a new page for the GET method")
    (function()
        -- prepare
        local expectedMethod = "GET"
        frame:Get("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Head function creates a new page for the HEAD method")
    (function()
        -- prepare
        local expectedMethod = "HEAD"
        frame:Head("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Post function creates a new page for the POST method")
    (function()
        -- prepare
        local expectedMethod = "POST"
        frame:Post("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Put function creates a new page for the PUT method")
    (function()
        -- prepare
        local expectedMethod = "PUT"
        frame:Put("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Delete function creates a new page for the DELETE method")
    (function()
        -- prepare
        local expectedMethod = "DELETE"
        frame:Delete("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Patch function creates a new page for the PATCH method")
    (function()
        -- prepare
        local expectedMethod = "PATCH"
        frame:Patch("/", func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame Page can create a new page for a custom method")
    (function()
        -- prepare
        local expectedMethod = "CUSTOM"
        frame:Page("/", (expectedMethod):lower(), func)

        -- test methods table is filled as expected
        local methodTable = frame.methods[expectedMethod]
        assert:TableNotEmpty(methodTable)
        assert:Type(methodTable["/"], "function")
        assert:Equal(tostring(methodTable["/"]), tostring(func))

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, { expectedMethod })
    end)

    test("Frame pages can be set to multiple methods")
    (function()
        -- prepare
        local methods = { "GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "CUSTOM" }

        for _, method in ipairs(methods) do
            -- create page
            frame:Page("/", method, func)

            -- test methods table is filled as expected
            local methodTable = frame.methods[method]
            assert:TableNotEmpty(methodTable)
            assert:Type(methodTable["/"], "function")
            assert:Equal(tostring(methodTable["/"]), tostring(func))
        end

        -- test paths table is filled as expected
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, methods)
    end)

    test("Frame page won't be created if it doesn't point to a function")
    (function()
        -- prepare
        local methods = { "GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "CUSTOM" }

        for _, method in ipairs(methods) do
            -- create page
            frame:Page("/", method, nil)

            -- test methods table is NOT filled as expected
            local methodTable = frame.methods[method]
            assert:Nil(methodTable)
            assert:TableEmpty(frame.methods)
        end

        -- test paths table IS filled as expected
        -- this allows `Frame:IsValidDefined` to make the check
        local pathTable = frame.paths["/"]
        assert:TableEquals(pathTable, methods)
    end)


    -- [[ run this suite ]]

    runInfo = test:Run({
        silent = true,
        rerunFailedTests = true
    })
end

local html = Report.Create(runInfo)
local path = GetPath()
if path == "/test/" or path == "/test/index.lua" then
    return html
else
    pcall(Write, html)
end