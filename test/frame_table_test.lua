--[[ frame table test ]]

local Suite = require("test/probo/suite")
local Report = require("test/probo/htmlreport")

local Frame = require("red/frame")


local runInfo
do
    local test <close> = Suite.New('Frame table test')
    local assert <const> = test -- for readability

    -- [[ preparation ]]

    function test:Setup()
        frame = Frame("Frame table test")
    end

    function test:Teardown()
        frame = nil
    end

    -- [[ tests ]]

    test("Frame has a default name")
    (function()
        local frame = Frame.New(nil)
        assert:Equal(frame.frameName, "Frame")
    end)

    test("Frame can have a custom name")
    (function()
        assert:Equal(frame.frameName, "Frame table test")  -- set in test:Setup
    end)

    test("Frame has a methods table")
    (function()
        assert:Type(frame.methods, "table")
        assert:TableEmpty(frame.methods)
    end)

    test("Frame has a paths table")
    (function()
        assert:Type(frame.paths, "table")
        assert:TableEmpty(frame.paths)
    end)

    test("Frame has contains the expected functions")
    (function()
        -- frame instance creation
        test:Invokable(Frame.New)

        -- page creation
        test:Invokable(Frame.Page)
        test:Invokable(Frame.Get)
        test:Invokable(Frame.Head)
        test:Invokable(Frame.Post)
        test:Invokable(Frame.Put)
        test:Invokable(Frame.Delete)
        test:Invokable(Frame.Patch)

        -- page request
        test:Invokable(Frame.RoutePath)

        -- frame utilities
        test:Invokable(Frame.GetMethodsOfPath)
        test:Invokable(Frame.GetPathsOfMethod)
        test:Invokable(Frame.IsValidDefined)
    end)

    test("Frame can have multiple instances")
    (function()
        local frame1 = Frame.New("frame1")
        local frame2 = Frame.New("frame2")
        assert:NotEqual(frame1.frameName, frame2.frameName)
        assert:NotEqual(tostring(frame1), tostring(frame2))
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