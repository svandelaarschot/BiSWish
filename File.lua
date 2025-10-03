-- BiSWishAddon File Module
local addonName, ns = ...

-- File namespace
ns.File = ns.File or {}

-- Initialize file system
function ns.File.Initialize()
    print("|cff39FF14BiSWishAddon|r: File system initialized!")
end

-- Export data to JSON file
function ns.File.ExportToJSON()
    local data = {
        version = BiSWishAddonDB.version,
        items = {}
    }
    
    -- Convert database to export format
    for itemID, itemData in pairs(BiSWishAddonDB.items) do
        data.items[tostring(itemID)] = {
            name = itemData.name,
            players = itemData.players
        }
    end
    
    -- Convert to JSON string
    local jsonString = ns.File.TableToJSON(data)
    
    -- Save to file
    local fileName = "BiSWishAddon_Export_" .. date("%Y%m%d_%H%M%S") .. ".json"
    -- Use WoW's SavedVariables system for export
    -- Store export data in a global variable that can be accessed
    _G["BiSWishAddon_Export_" .. date("%Y%m%d_%H%M%S")] = jsonString
    print("|cff39FF14BiSWishAddon|r: Data exported to global variable")
    print("|cff39FF14BiSWishAddon|r: Export data (copy this to a file):")
    print(jsonString)
    return true
end

-- Import data from JSON file
function ns.File.ImportFromJSON(fileName)
    if not fileName then
        print("|cffFF0000BiSWishAddon|r: No filename provided")
        return false
    end
    
    -- Use WoW's global variables for import
    local content = _G[fileName]
    if not content then
        print("|cffFF0000BiSWishAddon|r: Export not found: " .. fileName)
        print("|cff39FF14BiSWishAddon|r: Available exports:")
        for key, value in pairs(_G) do
            if string.find(key, "BiSWishAddon_Export_") then
                print("  • " .. key)
            end
        end
        return false
    end
    
    -- Parse JSON
    local success, data = pcall(ns.File.JSONToTable, jsonString)
    if not success then
        print("|cffFF0000BiSWishAddon|r: Invalid JSON format")
        return false
    end
    
    -- Validate data structure
    if not data.items then
        print("|cffFF0000BiSWishAddon|r: Invalid data format")
        return false
    end
    
    -- Import items
    local importedCount = 0
    for itemID, itemData in pairs(data.items) do
        local id = tonumber(itemID)
        if id and itemData.name then
            BiSWishAddonDB.items[id] = {
                name = itemData.name,
                players = itemData.players or {}
            }
            importedCount = importedCount + 1
        end
    end
    
    print("|cff39FF14BiSWishAddon|r: Imported " .. importedCount .. " items from " .. fileName)
    return true
end

-- Convert table to JSON string
function ns.File.TableToJSON(t)
    local function escape(str)
        return str:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    end
    
    local function toJSON(value, indent)
        indent = indent or 0
        local spaces = string.rep("  ", indent)
        
        if type(value) == "table" then
            local isArray = true
            local maxIndex = 0
            for k, v in pairs(value) do
                if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
                    isArray = false
                    break
                end
                maxIndex = math.max(maxIndex, k)
            end
            
            if isArray and maxIndex > 0 then
                local result = "[\n"
                for i = 1, maxIndex do
                    result = result .. spaces .. "  " .. toJSON(value[i], indent + 1)
                    if i < maxIndex then
                        result = result .. ","
                    end
                    result = result .. "\n"
                end
                result = result .. spaces .. "]"
                return result
            else
                local result = "{\n"
                local first = true
                for k, v in pairs(value) do
                    if not first then
                        result = result .. ",\n"
                    end
                    result = result .. spaces .. "  \"" .. escape(tostring(k)) .. "\": " .. toJSON(v, indent + 1)
                    first = false
                end
                result = result .. "\n" .. spaces .. "}"
                return result
            end
        elseif type(value) == "string" then
            return "\"" .. escape(value) .. "\""
        elseif type(value) == "number" then
            return tostring(value)
        elseif type(value) == "boolean" then
            return value and "true" or "false"
        elseif value == nil then
            return "null"
        else
            return "\"" .. escape(tostring(value)) .. "\""
        end
    end
    
    return toJSON(t)
end

-- Convert JSON string to table
function ns.File.JSONToTable(jsonString)
    local function parseValue(str, pos)
        pos = pos or 1
        str = str:gsub("^%s*", "") -- Remove leading whitespace
        
        if str:sub(1, 1) == "{" then
            return parseObject(str, pos)
        elseif str:sub(1, 1) == "[" then
            return parseArray(str, pos)
        elseif str:sub(1, 1) == '"' then
            return parseString(str, pos)
        elseif str:match("^%d") then
            return parseNumber(str, pos)
        elseif str:sub(1, 4) == "true" then
            return true, pos + 4
        elseif str:sub(1, 5) == "false" then
            return false, pos + 5
        elseif str:sub(1, 4) == "null" then
            return nil, pos + 4
        else
            error("Invalid JSON at position " .. pos)
        end
    end
    
    local function parseObject(str, pos)
        local result = {}
        pos = pos + 1
        str = str:sub(2)
        
        while str:sub(1, 1) ~= "}" do
            str = str:gsub("^%s*", "")
            if str:sub(1, 1) == "}" then break end
            
            local key, newPos = parseString(str, pos)
            pos = newPos
            str = str:sub(newPos - pos + 1)
            
            str = str:gsub("^%s*:%s*", "")
            pos = pos + str:match("^%s*:%s*"):len()
            str = str:sub(str:match("^%s*:%s*"):len() + 1)
            
            local value, newPos = parseValue(str, pos)
            result[key] = value
            pos = newPos
            str = str:sub(newPos - pos + 1)
            
            str = str:gsub("^%s*,?%s*", "")
            pos = pos + str:match("^%s*,?%s*"):len()
            str = str:sub(str:match("^%s*,?%s*"):len() + 1)
        end
        
        return result, pos + 1
    end
    
    local function parseArray(str, pos)
        local result = {}
        pos = pos + 1
        str = str:sub(2)
        
        while str:sub(1, 1) ~= "]" do
            str = str:gsub("^%s*", "")
            if str:sub(1, 1) == "]" then break end
            
            local value, newPos = parseValue(str, pos)
            table.insert(result, value)
            pos = newPos
            str = str:sub(newPos - pos + 1)
            
            str = str:gsub("^%s*,?%s*", "")
            pos = pos + str:match("^%s*,?%s*"):len()
            str = str:sub(str:match("^%s*,?%s*"):len() + 1)
        end
        
        return result, pos + 1
    end
    
    local function parseString(str, pos)
        local start = pos + 1
        local result = ""
        pos = pos + 1
        str = str:sub(2)
        
        while str:sub(1, 1) ~= '"' do
            if str:sub(1, 1) == "\\" then
                pos = pos + 1
                str = str:sub(2)
                if str:sub(1, 1) == "n" then
                    result = result .. "\n"
                elseif str:sub(1, 1) == "r" then
                    result = result .. "\r"
                elseif str:sub(1, 1) == "t" then
                    result = result .. "\t"
                elseif str:sub(1, 1) == "\\" then
                    result = result .. "\\"
                elseif str:sub(1, 1) == '"' then
                    result = result .. '"'
                else
                    result = result .. "\\" .. str:sub(1, 1)
                end
                pos = pos + 1
                str = str:sub(2)
            else
                result = result .. str:sub(1, 1)
                pos = pos + 1
                str = str:sub(2)
            end
        end
        
        return result, pos + 1
    end
    
    local function parseNumber(str, pos)
        local numStr = str:match("^%-?%d+%.?%d*")
        return tonumber(numStr), pos + numStr:len()
    end
    
    return parseValue(jsonString)
end

-- Get current date string
function ns.File.GetCurrentDate()
    return date("%Y-%m-%d %H:%M:%S")
end

-- List available export files
function ns.File.ListExportFiles()
    local files = {}
    -- List global variables that match our export pattern
    for key, value in pairs(_G) do
        if string.find(key, "BiSWishAddon_Export_") then
            table.insert(files, key)
        end
    end
    return files
end

-- Validate JSON file
function ns.File.ValidateJSONFile(fileName)
    -- Use WoW's global variables
    local content = _G[fileName]
    if not content then
        return false, "Export not found"
    end
    
    local success, data = pcall(ns.File.JSONToTable, jsonString)
    if not success then
        return false, "Invalid JSON format"
    end
    
    if not data.items then
        return false, "Invalid data format - missing items"
    end
    
    return true, "Valid JSON file"
end
