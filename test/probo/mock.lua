--[=[
    `Probo` Lua unit test framework
]=]

--[=[ Mock ]=]

---@private
local function SplitName(mockFuncName)
    local nameParts = {}
    for namePart in string.gmatch(mockFuncName, "[^.]+") do  -- split on dot (.)
        table.insert(nameParts, namePart)
    end
    return nameParts
end


---@private
local function TableTrace(tbl, newValue, ...)
    local traceTable = {}
    local value
    for i = 1, select("#", ...) do
        local namePart = select(i, ...)
        value = tbl[namePart]
        if value and type(value) == "table" then
            traceTable[namePart] = TableTrace(--[[tbl]] value, select(i, newValue, ...))
        else
            traceTable[namePart] = newValue or value -- tail of trace
        end
    end
    return traceTable
end


---@private
local function Merge(tbl1, tbl2)
    tbl2 = tbl2 or {}
    if type(tbl1) == 'table' and type(tbl2) == 'table' then
        for key, value in pairs(tbl2) do
            if type(value) == 'table' and type(tbl1[key]) == 'table' then
                Merge(tbl1[key], value)
            else
                tbl1[key] = value
            end
        end
    end
    return tbl1
end


---@private
local function Spy(self, mockFuncName, replacementFunc)
    local function InnerFunc(...)
        -- save the parameters given to the mocked function
        table.insert(self.mockInfo[mockFuncName].parameters, { ... })

        -- update the amount of calls to the mocked function
        local current = self.mockInfo[mockFuncName].timesCalled
        self.mockInfo[mockFuncName].timesCalled = current + 1

        -- run the mocked function and record the result
        local funcResult = { replacementFunc(...) }
        table.insert(self.mockInfo[mockFuncName].returned, funcResult)

        -- unpack the recorded result and return it
        return table.unpack(funcResult)
    end
    return InnerFunc
end


---@private
local function Inspect(self, mockFuncName)
    return self.mockInfo[mockFuncName]
end


---@private
local function Create(self, mockFuncName, replacementFunc)
    assert(type(mockFuncName) == "string" and type(replacementFunc) == "function")
    -- split the name into a table
    local nameParts = SplitName(mockFuncName)

    -- get the path to the Global function
    local _GfuncPath = TableTrace(_G, nil, table.unpack(nameParts))

    -- add the original path to the reset table
    self.originalFuncTable[mockFuncName] = {}
    Merge(self.originalFuncTable[mockFuncName], _GfuncPath)

    -- add the info to the `mockInfo` table
    self.mockInfo[mockFuncName] = {
        replacementFunc = replacementFunc,
        timesCalled = 0,  -- amount of times the mock is called
        parameters = {},  -- the parameters the mock has received
        returned = {},    -- the parameters the mock has returned (not the original function)
    }
    -- create a wrapper of the `replacementFunc` that is a spy-function
    local wrapFunc = Spy(self, mockFuncName, replacementFunc)

    -- create a replacement path for merging.
    local replaced_GfuncPath = TableTrace(_GfuncPath, wrapFunc, table.unpack(nameParts))

    -- overwrite/replace the Global function with the mocked function
    Merge(_G, replaced_GfuncPath)
end


---@private
local function Reset(self, mockFuncName)
    -- get the path to the Global function
    local original_GfuncPath = self.originalFuncTable[mockFuncName]

    if original_GfuncPath ~= nil then
        Merge(_G, original_GfuncPath)                -- reset the Global function
        self.originalFuncTable[mockFuncName] = nil   -- remove items from the tables
        self.mockInfo[mockFuncName] = nil
    end
end


---@private
local function Close(self)
    for mockFuncName, _ in pairs(self.mockInfo) do
        self:Reset(mockFuncName)
    end
end


local Mock = {}
local MetaMock = {
    __index = Mock,
    __call = Create,  -- create by mock()
    __close = Close   -- release mocks with <close> at end of do-end
}


---@public
function Mock.New()
    local object = {
        -- each instance an own object-table
        originalFuncTable = {},
        --[[
            -- example structure if `string.rep` is mocked
            originalFuncTable = {
                ["string.rep"] = {
                    string = {
                        rep = <original function>
                    }
                }
            }
        ]]
        mockInfo = {},
        --[[
            -- example structure if `string.rep` is mocked
            ["string.rep"] = {
                replacementFunc = <function that is given to replace string.rep>,
                parameters = {},
                returned = {},
                timesCalled = 0.0
            }
        ]]
        Create = Create,
        Inspect = Inspect,
        Reset = Reset
    }
    return setmetatable(object, MetaMock)
end


--[=[
    -- Mock example
    do
        local mock <close> = Mock.New()
        mock("string.reverse", function(input) return input end)
        mock("print", function(...) return { ... } end)

        -- test 1
        local given = "abc"
        local actual = string.reverse(given)
        assert(actual == given, "'string.reverse' is not mocked")

        -- reset the mock
        mock:Reset("string.reverse")

        -- test 2
        local expected = "cba"
        actual = string.reverse(given)
        assert(actual == expected, "'string.reverse' has not been reset")

        print("No output")  -- check the console for this output
    end

    -- after do-end <close> resets all the mocked functions
    print("print un-mocked")
]=]


--[[ make `Mock` available when this file is imported with require ]]
return Mock