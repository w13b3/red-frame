--[=[
    `Probo` Lua unit test framework

    HTML based of gist.github.com/cemremengu/5365729
]=]

local report = {}


local htmlStart = ([[<!DOCTYPE html><html lang="en">]])
local head = ([[
<head><title>Test Report</title>
<style>
table { border-collapse: collapse; border: 1px solid black; width: 800px; }
/*.table header cells */
table thead td { background-color: silver; padding-left: 3px }
/*.table header cells */
table tbody td { padding-left: 3px; }
/* Result colors */
.test-passed { background-color: green; }
.test-skipped { background-color: white; }
.test-failed { background-color: red; }
.describe-cell { background-color: tan; font-style: italic; }
.rerun-cell { background-color: lightgoldenrodyellow; font-style: italic; }
</style></head>
]])
local bodyStart = [[<body>]]
local tableStart = ([[
<table class="test-report"><thead>
<tr class="header-row">
<td>Test Suite</td><td>Test Case</td><td>Result</td>
</tr></thead><tbody>
]])
local tableEnd = ([[</tbody></table>]])
local bodyEnd = ([[</body>]])
local htmlEnd = ([[</html>]])


---@private
---@param suiteName string the suite name
---@param testName string the test name
---@return string table row representing the info and result of the tests
local function CreatePassedResult(suiteName, testName)
    local stepRow = ([[
    <tr class="step-row">
        <td class="step-cell test-suite-name">%s</td>
        <td class="step-cell test-case-name">%s</td>
        <td class="test-passed test-case-result">OK</td>
    </tr>
    ]]):format(suiteName, testName)
    return stepRow
end


---@private
---@param suiteName string the suite name
---@param testName string the test name
---@param message string the error message
---@return string table row representing the info and result of the tests
local function CreateFailedResult(suiteName, testName, message)
    local stepRow = ([[
    <tr class="step-row">
        <td class="step-cell test-suite-name">%s</td>
        <td class="step-cell test-case-name">%s</td>
        <td class="test-failed test-case-result">FAILED</td>
    </tr>
        <!-- Test failed error comment -->
    <tr class="step-row comment-row">
        <td class="describe-cell" colspan="3">%s</td>
    </tr>
    ]]):format(suiteName, testName, message)
    return stepRow
end


---@private
---@param runInfo table the runInfo table received from a Probo test run
---@return string table rows representing a summary of the test
local function CreateSummary(runInfo)
    local result = ""
    result = result .. [[<div class="test-run-info">]]
    result = result .. ([[<div class="total-tests">Total tests %s</div>]]):format(runInfo.totalExecuted)
    result = result .. ([[<div class="total-passed">Total passed %s</div>]]):format(runInfo.totalPassed)
    result = result .. ([[<div class="total-failed">Total failed %s</div>]]):format(runInfo.totalFailed)
    result = result .. [[</div>]]
    return result
end


---@private
---@param runInfo table the runInfo table received from a Probo test run
---@return string table rows representing the info and result of the tests
local function CreateTestStepResults(runInfo)
    local result = ""
    local suiteName = runInfo.suiteName or "Test suite"
    local executedTests = runInfo.executedTests
    table.sort(executedTests)

    if next(runInfo.failedTests) ~= nil then
        for _, testName in ipairs(executedTests) do
            local message = runInfo.failedTests[testName]
            if message then
                -- FAIL
                result = result .. CreateFailedResult(suiteName, testName, message)
            end
        end
    end

    if next(runInfo.passedTests) ~= nil then
        for _, testName in ipairs(executedTests) do
            local message = runInfo.passedTests[testName]
            if message then
                -- PASSED
                result = result .. CreatePassedResult(suiteName, testName, message)
            end
        end
    end

    if runInfo.options and runInfo.options.rerunFailedTests then
        if next(runInfo.rerunInfo.failedTests) ~= nil or next(runInfo.rerunInfo.passedTests) ~= nil then
            local rerunRow = ([[
                <tr class="step-row rerun-row"> <!-- Rerun row -->
                <td class="rerun-cell" colspan="3">Reruns</td>
                </tr>]])
            result = result .. rerunRow
            runInfo.rerunInfo.suiteName = suiteName  -- set the suiteName for the recursive call
            result = result .. CreateTestStepResults(runInfo.rerunInfo)
        end
    end
    return result
end


---Create a test report
---@public
---@param runInfoTable table the runInfo table received from a Probo test run
---@return string HTML test report
function report.Create(runInfoTable)
    local result = ""
    result = result .. htmlStart
    result = result .. head
    result = result .. bodyStart
    result = result .. tableStart
    result = result .. CreateTestStepResults(runInfoTable)
    result = result .. tableEnd
    result = result .. CreateSummary(runInfoTable)
    result = result .. bodyEnd
    result = result .. htmlEnd
    return result
end


---Combine two runInfo tables into one
---@public
---@param runInfo1 table the runInfo table received from a Probo test run
---@param runInfo2 table the runInfo table received from a Probo test run
---@param newName string the new name for the returned table
---@return table the combined runInfo
function report.CombineRunInfo(runInfo1, runInfo2, newName)
    newName = newName or "Combined info"
    runInfo1 = runInfo1 or {}
    runInfo2 = runInfo2 or {}

    runInfo1.rerunInfo = runInfo1.rerunInfo or {}
    runInfo2.rerunInfo = runInfo2.rerunInfo or {}

    -- initial run
    local executedTests = {}
    for _, testName in ipairs(runInfo1.executedTests or {}) do
        table.insert(executedTests, testName)
    end
    for _, testName in ipairs(runInfo2.executedTests or {}) do
        table.insert(executedTests, testName)
    end

    local definedTests = {}
    for testName, testFunc in pairs(runInfo1.definedTests or {}) do
        definedTests[testName] = testFunc
    end
    for testName, testFunc in pairs(runInfo2.definedTests or {}) do
        definedTests[testName] = testFunc
    end

    local failedTests = {}
    for testName, message in pairs(runInfo1.failedTests or {}) do
        failedTests[testName] = message
    end
    for testName, message in pairs(runInfo2.failedTests or {}) do
        failedTests[testName] = message
    end

    local passedTests = {}
    for testName, message in pairs(runInfo1.passedTests or {}) do
        passedTests[testName] = message
    end
    for testName, message in pairs(runInfo2.passedTests or {}) do
        passedTests[testName] = message
    end

    -- rerun
    local rerunExecutedTests = {}
    for _, testName in ipairs(runInfo1.rerunInfo.executedTests or {}) do
        table.insert(rerunExecutedTests, testName)
    end
    for _, testName in ipairs(runInfo2.rerunInfo.executedTests or {}) do
        table.insert(rerunExecutedTests, testName)
    end

    local rerunDefinedTests = {}
    for testName, testFunc in pairs(runInfo1.rerunInfo.definedTests or {}) do
        rerunDefinedTests[testName] = testFunc
    end
    for testName, testFunc in pairs(runInfo2.rerunInfo.definedTests or {}) do
        rerunDefinedTests[testName] = testFunc
    end

    local rerunFailedTests = {}
    for testName, message in pairs(runInfo1.rerunInfo.failedTests or {}) do
        rerunFailedTests[testName] = message
    end
    for testName, message in pairs(runInfo2.rerunInfo.failedTests or {}) do
        rerunFailedTests[testName] = message
    end

    local rerunPassedTests = {}
    for testName, message in pairs(runInfo1.rerunInfo.passedTests or {}) do
        rerunPassedTests[testName] = message
    end
    for testName, message in pairs(runInfo2.rerunInfo.passedTests or {}) do
        rerunPassedTests[testName] = message
    end


    -- get the smallest startTime and the largest endTime
    runInfo1.startTime = runInfo1.startTime or os.time(os.date("!*t"))
    runInfo1.endTime = runInfo1.endTime or os.time(os.date("!*t"))
    runInfo2.startTime = runInfo2.startTime or os.time(os.date("!*t"))
    runInfo2.endTime = runInfo2.endTime or os.time(os.date("!*t"))

    local startTime = math.min(runInfo1.startTime, runInfo2.startTime)
    local endTime = math.max(runInfo1.endTime, runInfo2.endTime)

    local runInfo = {
        -- new name
        suiteName = newName,

        -- add new times
        startTime = startTime,
        endTime = endTime,
        runTime = math.abs(endTime - startTime),

        -- execution results
        amountExecuted = (runInfo1.amountExecuted or 0) + (runInfo2.amountExecuted or 0),
        amountFailed = (runInfo1.amountFailed or 0) + (runInfo2.amountFailed or 0),
        amountPassed = (runInfo1.amountPassed or 0) + (runInfo2.amountPassed or 0),
        totalExecuted = (runInfo1.totalExecuted or 0) + (runInfo2.totalExecuted or 0),
        totalFailed = (runInfo1.totalFailed or 0) + (runInfo2.totalFailed or 0),
        totalPassed = (runInfo1.totalPassed or 0) + (runInfo2.totalPassed or 0),

        -- test tables
        executedTests = executedTests,
        definedTests = definedTests,
        failedTests = failedTests,
        passedTests = passedTests,
    }

    local rerunInfo = {
        -- rerun execution results
        amountExecuted = (runInfo1.rerunInfo.amountExecuted or 0) + (runInfo2.rerunInfo.amountExecuted or 0),
        amountFailed = (runInfo1.rerunInfo.amountFailed or 0) + (runInfo2.rerunInfo.amountFailed or 0),
        amountPassed = (runInfo1.rerunInfo.amountPassed or 0) + (runInfo2.rerunInfo.amountPassed or 0),

        -- rerun test tables
        executedTests = rerunExecutedTests,
        definedTests = rerunDefinedTests,
        failedTests = rerunFailedTests,
        passedTests = rerunPassedTests
    }

    runInfo.rerunInfo = rerunInfo

    runInfo1.options = runInfo1.options or {}
    runInfo2.options = runInfo2.options or {}
    runInfo.options = {
        stopOnFail       = runInfo1.options.stopOnFail or runInfo2.options.stopOnFail,
        silent           = runInfo1.options.silent or runInfo2.options.silent,
        rerunFailedTests = runInfo1.options.rerunFailedTests or runInfo2.options.rerunFailedTests,
        sortedByName     = runInfo1.options.sortedByName or runInfo2.options.sortedByName
    }

    return runInfo
end


return report