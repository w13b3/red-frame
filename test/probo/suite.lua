--[=[
    `Probo` Lua unit test framework
]=]


--[=[ Test suite assertions ]=]


local Assert = {
    attempts = 0,
    attemptsSuccess = 0,
    attemptsFailed = 0,
}
Assert.__index = Assert


function Assert.New()
    local instance = {
        -- keys here overwrites the keys in `Assert`
    }
    return setmetatable(instance, Assert)
end


---@private
---@return nil
function Assert:Attempt()
    self.attempts = self.attempts + 1
end


---@private
---@return boolean true
function Assert:AttemptSuccessful()
    self.attemptsSuccess = self.attemptsSuccess + 1
    if not self.silent then io.write(".") end
    return true
end


---@private
---@param message string custom error message
---@param level number error traceback level
---@return void
function Assert:AttemptFailed(message, level)
    self.attemptsFailed = self.attemptsFailed + 1
    if not self.silent then io.write("!") end
    return error(message, level or 2) -- 0 no line, 1 this line, 2 test case
end


--[=[ Asserts
      Returns true or false depending on the given variables
      Should not directly be used
]=]


-- Type checks
function Assert:IsNil(object)       return   type(object) == "nil"         end
function Assert:IsBoolean(object)   return   type(object) == "boolean"     end
function Assert:IsNumber(object)    return   type(object) == "number"      end
function Assert:IsString(object)    return   type(object) == "string"      end
function Assert:IsTable(object)     return   type(object) == "table"       end
function Assert:IsThread(object)    return   type(object) == "thread"      end  -- coroutine
function Assert:IsFunction(object)  return   type(object) == "function"    end
function Assert:IsUserdata(object)  return   type(object) == "userdata"    end
function Assert:IsOpenfile(ioObj)   return io.type(ioObj) == "file"        end
function Assert:IsClosedfile(ioObj) return io.type(ioObj) == "closed file" end


-- Coroutine checks
local coroStates = { ["dead"]=1, ["normal"]=1, ["running"]=1, ["suspended"]=1, ["normal"]=1 }
function Assert:IsCoroutine(coro)          return coroStates[coroutine.status(coro)] ~= nil end
function Assert:IsCoroutineDead(coro)      return coroutine.status(coro) == "dead"          end
function Assert:IsCoroutineNormal(coro)    return coroutine.status(coro) == "normal"        end
function Assert:IsCoroutineRunning(coro)   return coroutine.status(coro) == "running"       end
function Assert:IsCoroutineSuspended(coro) return coroutine.status(coro) == "suspended"     end
function Assert:IsCoroutineYieldable(coro) return coroutine.isyieldable(coro)               end


---Assert that the given conditional statement that results in boolean true
---@public
---@param expression boolean the conditional statement
---@param message string custom error message
---@return boolean
function Assert:Condition(expression, message)
    self:Attempt()
    if not expression then
        message = message or (
                "Assert:Condition failed, value: %s"
        ):format(tostring(expression))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given invokable does not create an error
---@public
---@param invokable function
---@param ... any invokable parameters
---@return boolean
function Assert:CreatesError(invokable, ...)
    self:Attempt()
    local boolean = pcall(invokable, ...)
    if boolean == true then
        local message = (
                "Assert:CreatesError failed, %s doesn't create error"
        ):format(tostring(invokable))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given invokable creates an error
---@public
---@param invokable function
---@param ... any invokable parameters
---@return boolean
function Assert:CreatesNoError(invokable, ...)
    self:Attempt()
    local boolean = pcall(invokable, ...)
    if boolean == false then
        local message = (
                "Assert:CreatesNoError failed, %s does create an error"
        ):format(tostring(invokable))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the actual value is equal to the expected value
---@public
---@param actual any
---@param expected any
---@param message string custom error message
---@return boolean
function Assert:Equal(actual, expected, message)
    self:Attempt()
    if actual ~= expected then
        message = message or (
                "Assert:Equal failed, %s is not equal to %s"
        ):format(tostring(actual), tostring(expected))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Force a failure
---@public
---@return boolean false
function Assert:Fail(message)
    self:Attempt()
    message = message or "Test Failed"
    return self:AttemptFailed(message)
end


---Asser that the given boolean is false
---@public
---@param boolean boolean
---@param message string custom error message
---@return boolean
function Assert:False(boolean, message)
    self:Attempt()
    if not self:IsBoolean(boolean) or boolean ~= false then
        message = message or (
                "Assert:False failed, received %s"
        ):format(tostring(boolean))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given object can be invoked
---@public
---@param object any
---@param message string custom error message
---@return boolean
function Assert:Invokable(object, message)
    self:Attempt()
    local meta = getmetatable(object)
    local metaTest = (meta and meta.__call and (type(meta.__call) == "function"))
    if not self:IsFunction(object) and not metaTest then
        message = message or (
                "Assert:Invokable failed, %s is invokable"
        ):format(tostring(object))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given object is a nil
---@public
---@param nilObject nil
---@param message string custom error message
---@return boolean
function Assert:Nil(nilObject, message)
    self:Attempt()
    if not self:IsNil(nilObject) then
        message = message or (
                "Assert:Nil failed, received %s"
        ):format(tostring(nilObject))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the actual value is not equal to the expected value
---@public
---@param actual any
---@param expected any
---@param message string custom error message
---@return boolean
function Assert:NotEqual(actual, expected, message)
    self:Attempt()
    if actual == expected then
        message = message or (
                "Assert:NotEqual failed, %s is equal to %s"
        ):format(tostring(actual), tostring(expected))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given object is not a nil
---@public
---@param object any
---@param message string custom error message
---@return boolean
function Assert:NotNil(object, message)
    self:Attempt()
    if self:IsNil(object) then
        message = message or (
                "Assert:NotNil failed, received %s"
        ):format(tostring(object))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Force a pass
---@public
---@return boolean true
function Assert:Pass()
    self:Attempt()
    return self:AttemptSuccessful()
end


---Assert that the given table is empty
---@public
---@param tableObject table
---@param message string custom error message
---@return boolean
function Assert:TableEmpty(tableObject, message)
    self:Attempt()
    if not self:IsTable(tableObject) then
        message = message or (
                "Assert:TableEmpty failed, expected a table, but got %s"
        ):format(type(tableObject))
        return self:AttemptFailed(message)
    elseif next(tableObject) ~= nil then
        message = message or (
                "Assert:TableEmpty failed, table has items: %s"
        ):format(tostring(tableObject))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that both given tables contains the same values
---@public
---@param tableA table
---@param tableB table
---@param message string custom error message
---@return boolean
function Assert:TableEquals(tableA, tableB, message)
    self:Attempt()
    local function CompareTables(tableA, tableB)

        if tableA == tableB then
            return true
        end

        local msg = "Assert:TableEquals failed, tables are different"
        if type(tableA) ~= "table" then
            return false, msg
        end
        if type(tableB) ~= "table" then
            return false, msg
        end

        local meta1, meta2 = getmetatable(tableA), getmetatable(tableB)
        if not CompareTables(meta1, meta2) then
            return false, msg
        end

        for key1, val1 in pairs(tableA) do
            local val2 = tableB[key1]
            if not CompareTables(val1, val2) then
                return false, msg
            end
        end

        for key2, val2 in pairs(tableB) do
            local val1 = tableA[key2]
            if not CompareTables(val1, val2) then
                return false, msg
            end
        end

        return true
    end
    local boolean, err = CompareTables(tableA, tableB)
    CompareTables = nil
    if not boolean then
        return self:AttemptFailed(message or err)
    end
    return self:AttemptSuccessful()
end


---Assert that both given tables contains the same keys
---@public
---@param tableA table
---@param tableB table
---@param message string custom error message
---@return boolean
function Assert:TableHasSameKeys(tableA, tableB, message)
    self:Attempt()
    message = message or (
            "Assert:TableHasSameKeys failed, key '%s' of table #%d is not persent in table #%d"
    )
    for key1, _ in pairs(tableA) do  -- compare table 1 keys to to table 2
        if tableB[key1] == nil then
            return self:AttemptFailed((message):format(tostring(key1), 1, 2))
        end
    end
    for key2, _ in pairs(tableB) do  -- compare table 2 keys to to table 1
        if tableA[key2] == nil then
            return self:AttemptFailed((message):format(tostring(key2), 2, 1))
        end
    end
    return self:AttemptSuccessful()
end


---Assert that the given table not is empty
---@public
---@param tableObject table
---@param message string custom error message
---@return boolean
function Assert:TableNotEmpty(tableObject, message)
    self:Attempt()
    if not self:IsTable(tableObject) then
        message = message or (
                "Assert:TableNotEmpty failed, expected a table, but got a %s"
        ):format(type(tableObject))
        return self:AttemptFailed(message)
    elseif next(tableObject) == nil then
        message = message or (
                "Assert:TableNotEmpty failed, table is empty: %s"
        ):format(tostring(tableObject))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Asser that the given boolean is true
---@public
---@param boolean boolean
---@param message string custom error message
---@return boolean
function Assert:True(boolean, message)
    self:Attempt()
    if not self:IsBoolean(boolean) or boolean ~= true then
        message = message or (
                "Assert:True failed, received %s"
        ):format(tostring(boolean))
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


---Assert that the given object is of the expected type
---@public
---@param object any
---@param expectedType string result of built-in type call
---@param message string custom error message
---@return boolean
function Assert:Type(object, expectedType, message)
    self:Attempt()
    if type(object) ~= expectedType then
        message = message or (
                "Assert:Type failed, object %s is of type %s, expected %s"
        ):format(tostring(object), type(object), expectedType)
        return self:AttemptFailed(message)
    end
    return self:AttemptSuccessful()
end


--[=[ Test suite ]=]


---Place newly created test function in a separate table
---@private
---@return nil
local function NewDefinedTests(self, key, value)
    if type(value) == "function" then
        -- assure the test function is not already defined
        if self.definedTests[key] ~= nil then
            local message = (
                    "Test '%s' in %s is previously defined"
            ):format(key, self.name or "the test suite")
            error(message, 2)
        end
        -- key is the `testName` value is the `testFunc`
        -- place it in a separate table
        self.definedTests[key] = value
    else
        -- ignore __newindex
        rawset(self, key, value)
    end
end


---Decorator for tests so testnames can have spaces
---@private
---@param self table Suite instance table
---@param testName string test name
local function SetName(self, testName)
    testName = tostring(testName)
    local function innerFunc(testFunc) -- `testFunc` is the decorated function
        self[testName] = testFunc      -- set by `NewDefinedTests`
    end
    return innerFunc
end


---The test runner
---@private
---@param self table the table of the defined test suite
---@param options table the options table
---@param runInfo table the runInfoTable
local function DoRun(self, options, runInfo)
    local testNames = {}
    for testName in pairs(runInfo.definedTests) do
        table.insert(testNames, testName)
    end

    if options.sortedByName then
        table.sort(testNames)
    end

    self.SuiteSetup(self, options, "SuiteSetup")
    for _, testName in ipairs(testNames) do
        local testFunc = runInfo.definedTests[testName]

        self.Setup(self, options, "Setup")
        -- pcall returns the message from `error` in `Assert:AttemptFailed`
        local success, message = pcall(testFunc)
        table.insert(runInfo.executedTests, testName)
        runInfo.amountExecuted = (runInfo.amountExecuted + 1)

        if success then
            runInfo.amountPassed = (runInfo.amountPassed + 1)
            runInfo.passedTests[testName] = message or ("%s passed"):format(testName)
            self.PassedHook(self, options, "PassedHook")
        else
            runInfo.amountFailed = (runInfo.amountFailed + 1)
            runInfo.failedTests[testName] = message or ("%s failed"):format(testName)
            self.FailedHook(self, options, "FailedHook")
        end

        self.Teardown(self, options, "Teardown")
        if not success and options.stopOnFail then break end
    end
    self.SuiteTeardown(self, options, "SuiteTeardown")
end


---Run the tests that are defined in the test suite
---@public
---@param options table
---@return table information about the test run
local function Run(self, options)
    options = options or self.defaultOptions or {}

    local runInfo = {}
    runInfo.options = options
    runInfo.suiteName = self.suiteName
    runInfo.definedTests = self.definedTests
    runInfo.amountExecuted = 0
    runInfo.amountPassed = 0
    runInfo.amountFailed = 0
    runInfo.executedTests = {}
    runInfo.passedTests = {}
    runInfo.failedTests = {}
    runInfo.rerunInfo = {}

    self.silent = options.silent  -- set Assert.silent

    -- start time recording
    runInfo.startTime = os.time(os.date("!*t"))
    local clockStart = os.clock()

    DoRun(self, options, runInfo)  -- mutates runInfo

    if options.rerunFailedTests then
        local rerunInfo = {}
        rerunInfo.definedTests = {}
        rerunInfo.executedTests = {}
        rerunInfo.passedTests = {}
        rerunInfo.failedTests = {}
        rerunInfo.amountExecuted = 0
        rerunInfo.amountPassed = 0
        rerunInfo.amountFailed = 0

        for testName, _ in pairs(runInfo.failedTests) do
            local testFunc = runInfo.definedTests[testName]
            if type(testFunc) == "function" then
                rerunInfo.definedTests[testName] = testFunc
            end
        end
        DoRun(self, options, rerunInfo)  -- mutates rerunInfo
        runInfo.rerunInfo = rerunInfo
    end

    -- stop time recording
    runInfo.endTime = os.time(os.date("!*t"))
    runInfo.runTime = (os.clock() - clockStart)

    runInfo.totalExecuted = runInfo.amountExecuted + (runInfo.rerunInfo.amountExecuted or 0)
    runInfo.totalPassed = runInfo.amountPassed + (runInfo.rerunInfo.amountPassed or 0)
    runInfo.totalFailed = runInfo.amountFailed + (runInfo.rerunInfo.amountFailed or 0)
    runInfo.runSuccess = (runInfo.totalFailed <= 0)


    -- after the run, write the errors to stderr
    if not options.silent and next(runInfo.failedTests) ~= nil then
        print(--[[ new line ]])
        for testName, message in pairs(runInfo.failedTests) do
            io.stderr:write(("%s\n"):format(message))
        end
        if options.rerunFailedTests and next(runInfo.rerunInfo.failedTests) ~= nil then
            for testName, message in pairs(runInfo.rerunInfo.failedTests) do
                io.stderr:write(("Rerun: %s\n"):format(message))
            end
        end
    end

    return runInfo, runInfo.runSuccess
end


local Suite = {
    -- if `<close>` is defined, __close is called at the end of the 'do-end' scope
    __close = (function() collectgarbage() end),
    __call = SetName,
    __newindex = NewDefinedTests,

}
Suite.__index = Suite
Suite = setmetatable(Suite, Assert)  -- inherit from Assert


---Create a new instance of a test suite
---@param suiteName string name of the test suite
---@return table new test suite instance
function Suite.New(suiteName)
    local SuiteHook = function() end
    local instance = {
        suiteName = tostring(suiteName) or "Probo Suite",
        definedTests = {},  -- table containing the testcases defined in the suite
        --[[ Test hooks ]]
        SuiteSetup    = SuiteHook,  -- before all the tests
        SuiteTeardown = SuiteHook,  -- after all the tests
        Setup         = SuiteHook,  -- before every tests
        Teardown      = SuiteHook,  -- after all the tests
        PassedHook    = SuiteHook,  -- after a test has passed
        FailedHook    = SuiteHook,  -- after a test has failed
        --[[ Suite runner ]]
        Run = Run,
        --[[ default Run options ]]
        defaultOptions  = {
            stopOnFail       = false,  -- stop the tests after the first failure
            silent           = false,  -- no output during tests
            rerunFailedTests = false,  -- rerun the failed tests if failures has happened
            sortedByName     = false   -- sorts the tests by name before the run of the tests
        },
    }
    return setmetatable(instance, Suite)
end


--[=[
    -- Test suite example:

    local runInfo = {}  -- define a `runInfo` table outside the do-end scope
    do
        -- create a new test suite instance
        -- with <close> defined a garbage-collection cycle is performed at the end this scope
        local test <close> = Suite.New("Probo Suite example")
        local assert = test -- more readable separation between tests and asserts

        test.run = 1                        -- test suite variable

        function test.AlwaysPasses()        -- this is a defined test
            assert:Invokable(test)          -- multiple different asserts are available
        end

        test([[Always Fails]])              -- test is a decorator
        (function()                         -- with the decorator the name of the test can have spaces
            assert:Fail()
        end)

        function test.FlakyTest()           -- failed tests in the first run can be rerun
            test.run = test.run + 1         -- if the option `rerunFailedTests` is set to true
            assert:Condition(test.run > 2)
        end

        local suiteOptions = {              -- a table with options
            stopOnFail       = false,
            silent           = false,
            rerunFailedTests = true,
            sortedByName     = false
        }

        -- run the above defined tests with the given options
        runInfo = test:Run(suiteOptions)    -- runInfo, a table with info about the run
    end
]=]


--[=[
    -- `runInfo` structure after test:Run
    runInfo = {
        suiteName = "Probo Suite example",
        runSuccess = false,
        startTime = 725893261,
        endTime = 725893265,
        runTime = 4.000175,
        amountExecuted = 3.0,
        amountFailed = 2.0,
        amountPassed = 1.0,
        totalExecuted = 5.0,
        totalFailed = 3.0,
        totalPassed = 2.0,
        definedTests = {
            ["Always Fails"] = <function 1>,
            AlwaysPasses = <function 2>,
            FlakyTest = <function 3>
        },
        executedTests = { ["Always Fails"], "FlakyTest", "AlwaysPasses" },
        failedTests = {
            ["Always Fails"] = "Test Failed",
            FlakyTest = "Assert:Condition failed, value: false"
        },
        options = {
            rerunFailedTests = true,
            silent = false,
            stopOnFail = false,
            sortedByName = false
        },
        passedTests = {
            AlwaysPasses = "AlwaysPasses passed"
        },
        rerunInfo = {
            amountExecuted = 2.0,
            amountFailed = 1.0,
            amountPassed = 1.0,
            definedTests = {
                ["Always Fails"] = <function 1>,
                FlakyTest = <function 3>
            },
            executedTests = { ["Always Fails"], "FlakyTest" },
            failedTests = {
                ["Always Fails"] = "Test Failed"
            },
            passedTests = {
                FlakyTest = "FlakyTest passed"
            }
        }
    }
]=]


--[[ make `Suite` and optionally `Assert` available when this file is imported with require ]]
return Suite, Assert