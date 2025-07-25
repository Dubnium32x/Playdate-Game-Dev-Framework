-- csv_loader.lua
-- Simple CSV loader for Playdate Lua

local csv_loader = {}

-- Loads a CSV file and returns a 2D array (table of tables)
function csv_loader.load_csv(filepath)
    local rows = {}
    local file = playdate.file.open(filepath)
    if not file then
        print("[CSV Loader] Could not open file: " .. tostring(filepath))
        return rows
    end
    while true do
        local line = file:readline()
        if not line then break end
        local row = {}
        for value in string.gmatch(line, "[^,]+") do
            local num = tonumber(value)
            table.insert(row, num or value)
        end
        table.insert(rows, row)
    end
    file:close()
    return rows
end

return csv_loader