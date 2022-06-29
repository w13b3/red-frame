--[[ frame path test ]]

local Suite = require("test/probo/suite")
local Report = require("test/probo/htmlreport")

local Frame = require("red/frame")


local runInfo
do
    local test <close> = Suite.New('Frame path test')
    local assert <const> = test -- for readability

    -- [[ preparation ]]

    function test:Setup()
        func = function(...) return ... end
        frame = Frame("Frame path test")
    end

    function test:Teardown()
        frame = nil
    end

    -- [[ tests ]]

    test("Page path without a leading '/' gets one")
    (function()
        frame:Get("test", func)
        local pagesTable = frame.methods["GET"]
        assert:TableNotEmpty(pagesTable)
        assert:TableEquals(pagesTable, { ["/test"] = func })
    end)

    test("Page path with a trailing '/' gets stripped of the trailing '/'")
    (function()
        frame:Get("test/", func)
        local pagesTable = frame.methods["GET"]
        assert:TableNotEmpty(pagesTable)
        assert:TableEquals(pagesTable, { ["/test"] = func })
    end)

    test("Page path of only a '/' is not stripped")
    (function()
        frame:Get("/", func)
        local pagesTable = frame.methods["GET"]
        assert:TableNotEmpty(pagesTable)
        assert:TableEquals(pagesTable, { ["/"] = func })
    end)

    test("Page path with uppercase characters is not altered")
    (function()
        frame:Get("/AaBbCc", func)
        local pagesTable = frame.methods["GET"]
        assert:TableNotEmpty(pagesTable)
        assert:TableEquals(pagesTable, { ["/AaBbCc"] = func })
    end)

    test("Page path is not path-encoded before storage")
    (function()
        local characters = { [[ ]], [["]], [[%]], [[<]], [[>]], [[\]], [[^]],
                             [[`]], [[{]], [[|]], [[}]], [[£]], [[円]], [[€]] }
        for _, char in ipairs(characters) do
            local path = string.format("/test_%s_test", char)
            frame:Get(path, func)

            local pagesTable = frame.methods["GET"]
            local pageFunc = pagesTable[path]
            assert:NotNil(pageFunc)
            assert:Type(pageFunc, "function")

            local pageMethods = frame.paths[path]
            assert:TableNotEmpty(pageMethods)
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