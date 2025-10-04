--[[
================================================================================
Commands.lua - BiSWish Addon Slash Commands Module
================================================================================
This module handles all slash commands for the BiSWish addon including:
- Command registration and parsing
- Help system and command documentation
- Debug commands and settings management
- User interaction through chat commands

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create commands namespace
ns.Commands = ns.Commands or {}

-- ============================================================================
-- COMMAND REGISTRATION
-- ============================================================================

--[[
    Initialize slash commands system
    Registers all slash commands with WoW's command system
--]]
function ns.Commands.Initialize()
    ns.Core.DebugInfo("Starting command initialization...")
    
    -- Register slash commands
    SLASH_BISWISH1 = "/bis"
    SlashCmdList["BISWISH"] = function(msg)
        ns.Core.DebugDebug("Slash command triggered!")
        ns.Commands.HandleCommand(msg)
    end
    
    ns.Core.DebugInfo("Commands initialized! Use /bis for help")
    ns.Core.DebugDebug("Test - /bis command should work now!")
    
    -- Test if command is registered
    if SLASH_BISWISH1 then
        ns.Core.DebugDebug("SLASH_BISWISH1 = %s", SLASH_BISWISH1)
    else
        ns.Core.DebugError("SLASH_BISWISH1 not set!")
    end
end

-- ============================================================================
-- COMMAND HANDLING
-- ============================================================================

--[[
    Handle slash commands
    @param msg (string) - The command message from the user
--]]
function ns.Commands.HandleCommand(msg)
    ns.Core.DebugDebug("Command received: %s", msg or "empty")
    
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
    elseif command == "options" or command == "config" or command == "settings" then
        ns.Commands.ShowOptions()
    elseif command == "list" then
        ns.Commands.ShowBiSList()
    elseif command == "clear" then
        ns.Commands.ClearData()
    elseif command == "testdrop" then
        ns.Commands.TestItemDrop()
    elseif command == "debug" then
        ns.Commands.ToggleDebugMode()
    elseif command == "debuglevel" then
        ns.Commands.SetDebugLevel(args)
    else
        ns.Core.DebugInfo("Unknown command. Type /bis help for available commands")
    end
end

-- ============================================================================
-- HELP SYSTEM
-- ============================================================================

--[[
    Show help information
    Displays all available commands and their usage
--]]
function ns.Commands.ShowHelp()
    ns.Core.DebugInfo("BiSWishAddon Commands:")
    ns.Core.DebugInfo("/bis add <itemID> <itemName> <player1,player2,player3> - Add item to wishlist")
    ns.Core.DebugInfo("/bis remove <itemID> - Remove item from wishlist")
    ns.Core.DebugInfo("/bis list - Show complete BiS list with search")
    ns.Core.DebugInfo("/bis show - Show BiS window")
    ns.Core.DebugInfo("/bis data - Open data management window")
    ns.Core.DebugInfo("/bis export - Export data to JSON file")
    ns.Core.DebugInfo("/bis import <filename> - Import data from JSON file")
    ns.Core.DebugInfo("/bis options - Open options window")
    ns.Core.DebugInfo("/bis config - Open settings window")
    ns.Core.DebugInfo("/bis settings - Open settings window")
    ns.Core.DebugInfo("/bis clear - Clear all data")
    ns.Core.DebugInfo("/bis testdrop - Test item drop popup")
    ns.Core.DebugInfo("/bis debug - Toggle debug mode")
    ns.Core.DebugInfo("/bis debuglevel <1-5> - Set debug level (1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG, 5=VERBOSE)")
    ns.Core.DebugInfo("/bis help - Show this help")
end

-- ============================================================================
-- ITEM MANAGEMENT COMMANDS
-- ============================================================================

--[[
    Add item to wishlist
    @param args (table) - Command arguments [itemID, itemName, players]
--]]
function ns.Commands.AddItem(args)
    if #args < 3 then
        ns.Core.DebugError("Usage: /bis add <itemID> <itemName> <player1,player2,player3>")
        return
    end
    
    local itemID = tonumber(args[2])
    if not itemID then
        ns.Core.DebugError("Invalid item ID")
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
    ns.Core.DebugInfo("Added item %s (ID: %s) with %d players", itemName, itemID, #players)
end

--[[
    Remove item from wishlist
    @param args (table) - Command arguments [itemID]
--]]
function ns.Commands.RemoveItem(args)
    if #args < 2 then
        ns.Core.DebugError("Usage: /bis remove <itemID>")
        return
    end
    
    local itemID = tonumber(args[2])
    if not itemID then
        ns.Core.DebugError("Invalid item ID")
        return
    end
    
    if BiSWishAddonDB.items[itemID] then
        local itemName = BiSWishAddonDB.items[itemID].name
        BiSWishAddonDB.items[itemID] = nil
        ns.Core.DebugInfo("Removed item %s (ID: %s)", itemName, itemID)
    else
        ns.Core.DebugError("Item not found in wishlist")
    end
end

-- List all items (legacy function - now opens BiS list dialog)
-- ============================================================================
-- DISPLAY COMMANDS
-- ============================================================================

--[[
    List all items in the wishlist
--]]
function ns.Commands.ListItems()
    ns.Commands.ShowBiSList()
end

--[[
    Show BiS window
--]]
function ns.Commands.ShowWindow()
    ns.UI.ShowBossWindow("Manual View")
    ns.Core.DebugInfo("Showing BiS window")
end

-- Show data management window
function ns.Commands.ShowDataWindow()
    ns.UI.ShowDataWindow()
    ns.Core.DebugInfo("Opening data management window")
end

-- Export data to JSON
function ns.Commands.ExportData()
    if ns.File.ExportToJSON() then
        ns.Core.DebugInfo("Data exported successfully!")
    else
        ns.Core.DebugError("Export failed!")
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
    -- Update guild name in settings before opening
    if ns.Options and ns.Options.UpdateGuildNameInSettings then
        ns.Options.UpdateGuildNameInSettings()
    end
    
    -- Open the correct settings and go directly to BiSWish tab
    if Settings and Settings.OpenToCategory then
        -- Retail (Dragonflight+) - use the saved category reference
        if _G.BiSWishSettingsCategory then
            Settings.OpenToCategory(_G.BiSWishSettingsCategory:GetID())
            ns.Core.DebugInfo("Opening BiSWish settings...")
        else
            -- Fallback: try to get the category
            local category = Settings.GetCategory("BiSWish")
            if category then
                Settings.OpenToCategory(category:GetID())
                ns.Core.DebugInfo("Opening BiSWish settings (found category)...")
            else
                -- Last fallback: try the old method
                Settings.OpenToCategory("BiSWish")
                ns.Core.DebugInfo("Opening settings (fallback)...")
            end
        end
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- Classic/older versions - double call fixes Blizzard bug
        InterfaceOptionsFrame_OpenToCategory("BiSWish")
        C_Timer.After(0.1, function()
            InterfaceOptionsFrame_OpenToCategory("BiSWish")
        end)
        ns.Core.DebugInfo("Opening settings...")
    else
        -- Fallback: open interface options
        if SettingsPanel then
            SettingsPanel:Show()
            ns.Core.DebugInfo("Please navigate to the BiSWish section in Settings.")
        elseif InterfaceOptionsFrame then
            InterfaceOptionsFrame:Show()
            ns.Core.DebugInfo("Please navigate to the BiSWish section in Interface Options.")
        else
            ns.Core.DebugInfo("Could not open settings. Please use the Game Menu > Options > AddOns.")
        end
    end
end

-- Clear all data
function ns.Commands.ClearData()
    BiSWishAddonDB.items = {}
    ns.Core.DebugInfo("All data cleared")
end

-- Test item drop popup
function ns.Commands.TestItemDrop()
    ns.Core.DebugInfo("Testing item drop popup...")
    ns.UI.TestItemDropPopup()
end

-- ============================================================================
-- DEBUG COMMANDS
-- ============================================================================

--[[
    Toggle debug mode on/off
--]]
function ns.Commands.ToggleDebugMode()
    if ns.Core and ns.Core.ToggleDebugMode then
        ns.Core.ToggleDebugMode()
    else
        print("|cffFF0000BiSWishAddon|r: Debug system not available")
    end
end

-- Set debug level
function ns.Commands.SetDebugLevel(args)
    if #args < 2 then
        print("|cffFF0000BiSWishAddon|r: Usage: /bis debuglevel <1-5>")
        print("|cff39FF14BiSWishAddon|r: 1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG, 5=VERBOSE")
        return
    end
    
    local level = tonumber(args[2])
    if not level or level < 1 or level > 5 then
        print("|cffFF0000BiSWishAddon|r: Invalid debug level. Use 1-5")
        return
    end
    
    if ns.Core and ns.Core.SetDebugLevel then
        ns.Core.SetDebugLevel(level)
    else
        print("|cffFF0000BiSWishAddon|r: Debug system not available")
    end
end

-- String trim function
function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end
