-- [[ index ]]

-- tests in /zip/test/
local tests = {
    "frame_page_test",
    "frame_path_test",
    "frame_routepath_test",
    "frame_table_test",
}

local original = package.path
package.path = string.format("%s;/zip/test/?.lua", package.path)  -- redbean version 1.5+

for _, test in ipairs(tests) do
    local html = require(test)
    Write(string.format([[<a href="/test/%s.lua">%s</a>]], test, test))
    Write(tostring(html))
    Write("<hr>")
end

package.path = original