--[[ frame routepath test ]]

local Suite = require("test/probo/suite")
local Mock = require("test/probo/mock")
local Report = require("test/probo/htmlreport")

local Frame = require("red/frame")


local runInfo
do
    local test <close> = Suite.New('Frame routepath test')
    local assert <const> = test -- for readability

    -- [[ preparation ]]

    function test:Setup()
        func = function(...) return ... end
        frame = Frame("Frame routepath test")
    end

    function test:Teardown()
        frame = nil
    end

    -- [[ tests ]]

    test("RoutePath the HTTP request method decides which function gets called")
    (function()
        do
            local getIsCalled = "GET"
            local postIsCalled = "POST"
            frame:Get("/", function() return getIsCalled end)
            frame:Post("/", function() return postIsCalled end)

            -- mock Write so data can be catched
            local mock <close> = Mock.New()
            local writeData = nil
            mock("Write", function(data) writeData = data end)

            do -- check if function of GET is called
                local mock_ <close> = Mock.New()
                mock_("GetMethod", function() return "GET" end)
                frame:RoutePath("/")
                assert:Equal(writeData, getIsCalled)
            end

            do -- check if function of POST is called
                local mock_ <close> = Mock.New()
                mock_("GetMethod", function() return "POST" end)
                frame:RoutePath("/")
                assert:Equal(writeData, postIsCalled)
            end

            assert:Equal(mock:Inspect("Write").timesCalled, 2)
        end
    end)

    test("RoutePath the method parameter prioritizes which function gets called")
    (function()
        do
            local getIsCalled = "GET"
            local postIsCalled = "POST"
            frame:Get("/", function() return getIsCalled end)
            frame:Post("/", function() return postIsCalled end)

            -- mock Write so data can be catched
            local mock <close> = Mock.New()
            local writeData = nil
            mock("Write", function(data) writeData = data end)

            do -- check if function of GET is called
                frame:RoutePath("/", getIsCalled)  -- parameter method
                assert:Equal(writeData, getIsCalled)
            end

            do -- check if function of POST is called
                frame:RoutePath("/", postIsCalled)  -- parameter method
                assert:Equal(writeData, postIsCalled)
            end

            assert:Equal(mock:Inspect("Write").timesCalled, 2)
        end
    end)

    test("RoutePath successful call returns 200")
    (function()
        frame:Get("/", func)
        local respBool, respCode, respMsg = frame:RoutePath("/", "GET")
        assert:True(respBool)
        assert:Equal(respCode, 200)
        assert:Equal(respMsg, "OK")
    end)

    test("RoutePath failed call for not implemented method returns 501")
    (function()
        frame:Get("/", func)
        local respBool, respCode, respMsg = frame:RoutePath("/", "POST")
        assert:False(respBool)
        assert:Equal(respCode, 501)
        assert:Equal(respMsg, "Not Implemented")
    end)

    test("RoutePath failed call for page not found returns 404")
    (function()
        frame:Get("/", func)
        local respBool, respCode, respMsg = frame:RoutePath(" not defined ", "GET")
        assert:False(respBool)
        assert:Equal(respCode, 404)
        assert:Equal(respMsg, "Not Found")
    end)

    test("RoutePath failed call for page that doesn't allow that method returns 405")
    (function()
        frame:Get("/", func)
        frame:Post("/post", func)  -- precondition, server has method defined that other pages doesn't have
        local respBool, respCode, respMsg = frame:RoutePath("/", "POST")
        assert:False(respBool)
        assert:Equal(respCode, 405)
        assert:Equal(respMsg, "Method Not Allowed")
    end)

    test("RoutePath failed call for page that has an error returns 500")
    (function()
        local func = function() return "error" .. nil end
        assert:CreatesError(func)

        frame:Get("/", func)
        local respBool, respCode, respMsg = frame:RoutePath("/", "GET")
        assert:False(respBool)
        assert:Equal(respCode, 500)
        assert:Equal(respMsg, "Internal Server Error")
    end)

    test("RoutePath returns the page defined custom HTTP code")
    (function()
        local function func() return nil, false, 418, "I'm a teapot"  end
        frame:Get("/", func)
        local respBool, respCode, respMsg = frame:RoutePath("/", "GET")
        assert:False(respBool)
        assert:Equal(respCode, 418)
        assert:Equal(respMsg, "I'm a teapot")
    end)

    test("RoutePath no path given will request '/' with requested method")
    (function()
        frame:Get("/", func)
        local respBool = frame:RoutePath(nil, "GET")
        assert:True(respBool)
    end)

    test("RoutePath escapes the given path")
    (function()
        frame:Get("/", func)
        do
            local mock <close> = Mock.New()
            mock("EscapePath", _G["EscapePath"])  -- spy on EscapePath

            local respBool, respCode =  frame:RoutePath("/some spaces", "GET")
            assert:False(respBool)
            assert:Equal(respCode, 404)

            -- assert that the EscapePath is actually called
            local spyTable = mock:Inspect("EscapePath")
            assert:Equal(spyTable.timesCalled, 1)
            assert:Equal(spyTable.parameters[1][1], "/some spaces")
            assert:Equal(spyTable.returned[1][1], "/some%20spaces")
        end

        -- pre-escape the path on page definition to ensure that the page can be found
        frame:Get(EscapePath("/some spaces"), func)
        local respBool, respCode =  frame:RoutePath("/some spaces", "GET")
        assert:True(respBool)
        assert:Equal(respCode, 200)
    end)

    test("RoutePath can match pages that has a Regex path")
    (function()
        local funcInput = {}
        local func = function(...) funcInput = { ... } end
        frame:Get([[/user(\d+)]], func)

        local randomNumber = math.random(1, 65536)
        local path = string.format("/user%d", randomNumber)

        local respBool, respCode = frame:RoutePath(path, "GET")
        assert:True(respBool)
        assert:Equal(respCode, 200)

        local inputNumber = table.unpack(funcInput)
        assert:Type(inputNumber, "string")  -- regex returns strings
        assert:TableEquals(funcInput, { inputNumber })


        -- Regex with multiple groups
        frame:Get([[/multiple(\d+)/(\w+)]], func)
        local part = "test"
        path = string.format("/multiple%d/%s", randomNumber, part)
        respBool, respCode = frame:RoutePath(path, "GET")
        assert:True(respBool)
        assert:Equal(respCode, 200)

        local pathPart
        inputNumber, pathPart = table.unpack(funcInput)
        assert:Equal(pathPart, part)
        assert:TableEquals(funcInput, { inputNumber, part })  -- assure the sequence of groups
    end)

    test("RoutePath doesn't Write if function creates an error")
    (function()
        local func  = function() return "error" .. nil  end
        assert:CreatesError(func)
        do
            local mock <close> = Mock.New()
            local writeData = nil
            mock("Write", function(data) writeData = data end)

            frame:Get("/", func)  -- should error
            local respBool, respCode = frame:RoutePath("/", "GET")
            assert:False(respBool)
            assert:Equal(respCode, 500)

            -- check mock
            assert:Nil(writeData)
            assert:Equal(mock:Inspect("Write").timesCalled, 0)
        end
    end)

    test("RoutePath doesn't Write if function returns nil")
    (function()
        do
            local mock <close> = Mock.New()
            local writeData = nil
            mock("Write", function(data) writeData = data end)

            frame:Get("/", func)  -- returns nil
            local respBool, respCode = frame:RoutePath("/", "GET")
            assert:True(respBool)
            assert:Equal(respCode, 200)

            -- check mock
            assert:Nil(writeData)
            assert:Equal(mock:Inspect("Write").timesCalled, 0)
        end
    end)

    test("RoutePath Write always gets a string as input")
    (function()
        local returnTable = { "table" }
        local func = function() return returnTable end
        do
            local mock <close> = Mock.New()
            local writeData = nil
            mock("Write", function(data) writeData = data end)

            frame:Get("/", func)  -- returns nil
            local respBool, respCode = frame:RoutePath("/", "GET")
            assert:True(respBool)
            assert:Equal(respCode, 200)

            -- check mock
            assert:NotNil(writeData)
            assert:Equal(mock:Inspect("Write").timesCalled, 1)
            assert:Type(writeData, "string")
            assert:Equal(writeData, tostring(returnTable))  -- check same instance
        end
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