-- BiSWishAddon Commands Module
local addonName, ns = ...

-- Commands namespace
ns.Commands = ns.Commands or {}

-- Initialize commands
function ns.Commands.Initialize()
    print("|cff39FF14BiSWishAddon|r: Starting command initialization...")
    
    -- Register slash commands
    SLASH_BISWISH1 = "/bis"
    SlashCmdList["BISWISH"] = function(msg)
        print("|cff39FF14BiSWishAddon|r: Slash command triggered!")
        ns.Commands.HandleCommand(msg)
    end
    
    print("|cff39FF14BiSWishAddon|r: Commands initialized! Use /bis for help")
    print("|cff39FF14BiSWishAddon|r: Test - /bis command should work now!")
    
    -- Test if command is registered
    if SLASH_BISWISH1 then
        print("|cff39FF14BiSWishAddon|r: SLASH_BISWISH1 = " .. SLASH_BISWISH1)
    else
        print("|cff39FF14BiSWishAddon|r: ERROR - SLASH_BISWISH1 not set!")
    end
end

-- Handle slash commands
function ns.Commands.HandleCommand(msg)
    print("|cff39FF14BiSWishAddon|r: Command received: " .. (msg or "empty"))
    
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local command = args[1] and string.lower(args[1]) or "help"
    
    if command == "help" then
        ns.Commands.ShowHelp()
    elseif command == "add" then
        ns.Commands.AddItem(args)
    elseif command == "remove" then
        ns.Commands.RemoveItem(args)
    elseif command == "list" then
        ns.Commands.ListItems()
    elseif command == "show" then
        ns.Commands.ShowWindow()
    elseif command == "data" then
        ns.Commands.ShowDataWindow()
    elseif command == "export" then
        ns.Commands.ExportData()
    elseif command == "import" then
        ns.Commands.ImportData(args)
    elseif command == "options" then
        ns.Commands.ShowOptions()
    elseif command == "list" then
        ns.Commands.ShowBiSList()
    elseif command == "clear" then
        ns.Commands.ClearData()
    elseif command == "testdrop" then
        ns.Commands.TestItemDrop()
    else
        print("|cff39FF14BiSWishAddon|r: Unknown command. Type /bis help for available commands")
    end
end

-- Show help
function ns.Commands.ShowHelp()
    print("|cff39FF14BiSWishAddon Commands:|r")
    print("|cff00FF00/bis add <itemID> <itemName> <player1,player2,player3>|r - Add item to wishlist")
    print("|cff00FF00/bis remove <itemID>|r - Remove item from wishlist")
    print("|cff00FF00/bis list|r - Show complete BiS list with search")
    print("|cff00FF00/bis show|r - Show BiS window")
    print("|cff00FF00/bis data|r - Open data management window")
    print("|cff00FF00/bis export|r - Export data to JSON file")
    print("|cff00FF00/bis import <filename>|r - Import data from JSON file")
    print("|cff00FF00/bis options|r - Open options window")
    print("|cff00FF00/bis clear|r - Clear all data")
    print("|cff00FF00/bis testdrop|r - Test item drop popup")
    print("|cff00FF00/bis help|r - Show this help")
end

-- Add item to wishlist
function ns.Commands.AddItem(args)
    if #args < 3 then
        print("|cffFF0000BiSWishAddon|r: Usage: /bis add <itemID> <itemName> <player1,player2,player3>")
        return
    end
    
    local itemID = tonumber(args[2])
    if not itemID then
        print("|cffFF0000BiSWishAddon|r: Invalid item ID")
        return
    end
    
    local itemName = args[3]
    local players = {}
    
    if args[4] then
        for player in args[4]:gmatch("[^,]+") do
            table.insert(players, player:trim())
        end
    end
    
    ns.Data.AddItem(itemID, itemName, players)
    print("|cff39FF14BiSWishAddon|r: Added item " .. itemName .. " (ID: " .. itemID .. ") with " .. #players .. " players")
end

-- Remove item from wishlist
function ns.Commands.RemoveItem(args)
    if #args < 2 then
        print("|cffFF0000BiSWishAddon|r: Usage: /bis remove <itemID>")
        return
    end
    
    local itemID = tonumber(args[2])
    if not itemID then
        print("|cffFF0000BiSWishAddon|r: Invalid item ID")
        return
    end
    
    if BiSWishAddonDB.items[itemID] then
        local itemName = BiSWishAddonDB.items[itemID].name
        BiSWishAddonDB.items[itemID] = nil
        print("|cff39FF14BiSWishAddon|r: Removed item " .. itemName .. " (ID: " .. itemID .. ")")
    else
        print("|cffFF0000BiSWishAddon|r: Item not found in wishlist")
    end
end

-- List all items (legacy function - now opens BiS list dialog)
function ns.Commands.ListItems()
    ns.Commands.ShowBiSList()
end

-- Show BiS window
function ns.Commands.ShowWindow()
    ns.UI.ShowBossWindow("Manual View")
    print("|cff39FF14BiSWishAddon|r: Showing BiS window")
end

-- Show data management window
function ns.Commands.ShowDataWindow()
    ns.UI.ShowDataWindow()
    print("|cff39FF14BiSWishAddon|r: Opening data management window")
end

-- Export data to JSON
function ns.Commands.ExportData()
    if ns.File.ExportToJSON() then
        print("|cff39FF14BiSWishAddon|r: Data exported successfully!")
    else
        print("|cffFF0000BiSWishAddon|r: Export failed!")
    end
end

-- Import data from JSON
function ns.Commands.ImportData(args)
    if #args < 2 then
        print("|cffFF0000BiSWishAddon|r: Usage: /bis import <filename>")
        print("|cff39FF14BiSWishAddon|r: Available files:")
        local files = ns.File.ListExportFiles()
        if #files > 0 then
            for _, file in ipairs(files) do
                print("  • " .. file)
            end
        else
            print("  No export files found")
        end
        return
    end
    
    local fileName = args[2]
    if ns.File.ImportFromJSON(fileName) then
        print("|cff39FF14BiSWishAddon|r: Data imported successfully!")
        -- Refresh UI if open
        if ns.UI.dataWindow and ns.UI.dataWindow:IsVisible() then
            ns.UI.UpdateDataWindowContent()
        end
    else
        print("|cffFF0000BiSWishAddon|r: Import failed!")
    end
end

-- Show BiS list dialog
function ns.Commands.ShowBiSList()
    ns.UI.ShowBiSListDialog()
    print("|cff39FF14BiSWishAddon|r: Opening BiS list dialog")
end

-- Show options window
function ns.Commands.ShowOptions()
    -- Open WoW Options menu to BiSWish category
    Settings.OpenToCategory("BiSWishAddon")
    print("|cff39FF14BiSWishAddon|r: Opening WoW Options menu to BiSWish settings")
end

-- Clear all data
function ns.Commands.ClearData()
    BiSWishAddonDB.items = {}
    print("|cff39FF14BiSWishAddon|r: All data cleared")
end

-- Test item drop popup
function ns.Commands.TestItemDrop()
    print("|cff39FF14BiSWishAddon|r: Testing item drop popup...")
    ns.UI.TestItemDropPopup()
end

-- String trim function
function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end
