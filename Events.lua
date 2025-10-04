--[[
================================================================================
Events.lua - BiSWish Addon Event Handling Module
================================================================================
This module handles all WoW events for the BiSWish addon including:
- Encounter end events for auto-opening BiS list
- Loot events for item drop detection
- Player and group events for raid tracking
- Addon loading and initialization events

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create events namespace
ns.Events = ns.Events or {}

-- ============================================================================
-- EVENT SYSTEM INITIALIZATION
-- ============================================================================

--[[
    Initialize events system
    Sets up all event handlers and registers them with WoW
--]]
function ns.Events.Initialize()
    ns.Events.RegisterEvents()
    print("|cff39FF14BiSWishAddon|r: Events initialized!")
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

--[[
    Register all event handlers
    Creates event frame and registers all required WoW events
--]]
function ns.Events.RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("LOOT_OPENED")
    frame:RegisterEvent("LOOT_CLOSED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        ns.Events.HandleEvent(event, ...)
    end)
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

--[[
    Main event handler
    @param event (string) - The event name
    @param ... (any) - Event arguments
--]]
function ns.Events.HandleEvent(event, ...)
    if event == "ENCOUNTER_END" then
        ns.Events.OnEncounterEnd(...)
    elseif event == "ADDON_LOADED" and ... == addonName then
        ns.Events.OnAddonLoaded()
    elseif event == "PLAYER_LOGIN" then
        ns.Events.OnPlayerLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns.Events.OnPlayerEnteringWorld()
    elseif event == "GROUP_ROSTER_UPDATE" then
        ns.Events.OnGroupRosterUpdate()
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.Events.OnPlayerRegenDisabled()
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.Events.OnPlayerRegenEnabled()
    elseif event == "LOOT_OPENED" then
        ns.Events.OnLootOpened()
    elseif event == "LOOT_CLOSED" then
        ns.Events.OnLootClosed()
    end
end

-- Event handlers
function ns.Events.OnAddonLoaded()
    print("|cff39FF14BiSWishAddon|r: Addon loaded!")
end

function ns.Events.OnPlayerLogin()
    print("|cff39FF14BiSWishAddon|r: Player logged in!")
end

function ns.Events.OnPlayerEnteringWorld()
    print("|cff39FF14BiSWishAddon|r: Player entering world!")
end

function ns.Events.OnGroupRosterUpdate()
    print("|cff39FF14BiSWishAddon|r: Group roster updated!")
end

function ns.Events.OnPlayerRegenDisabled()
    print("|cff39FF14BiSWishAddon|r: Player in combat!")
end

function ns.Events.OnPlayerRegenEnabled()
    print("|cff39FF14BiSWishAddon|r: Player out of combat!")
end

-- ============================================================================
-- SPECIFIC EVENT HANDLERS
-- ============================================================================

--[[
    Handle encounter end event
    @param encounterID (number) - The encounter ID
    @param encounterName (string) - The encounter name
    @param difficultyID (number) - The difficulty ID
    @param groupSize (number) - The group size
    @param success (boolean) - Whether the encounter was successful
--]]
function ns.Events.OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if success then
        -- Check if we should skip Mythic+ dungeons
        local skipMythicPlus = BiSWishAddonDB.options and BiSWishAddonDB.options.skipMythicPlus
        if skipMythicPlus then
            local inInstance, instanceType = IsInInstance()
            if instanceType == "party" and difficultyID == 8 then
                -- This is a Mythic+ dungeon, don't show BiS list or loot tracking
                ns.Core.DebugInfo("Mythic+ encounter detected, skipping BiS list auto-open")
                return
            end
            
            -- Check if we're in a regular dungeon (not raid)
            if instanceType == "party" and difficultyID ~= 8 then
                -- Regular dungeon, don't show BiS list but allow loot tracking
                ns.Core.DebugInfo("Regular dungeon encounter detected, skipping BiS list auto-open")
                return
            end
        end
        
        -- Only show BiS list for raids
        local inInstance, instanceType = IsInInstance()
        if instanceType == "raid" then
            print("|cff39FF14BiSWishAddon|r: Boss defeated! Showing BiS data for: " .. encounterName)
            ns.UI.ShowBossWindow(encounterName)
            
            -- Check if we should auto-open BiS Wishlist for guild raids
            ns.UI.CheckBossKillAutoOpen()
        end
    end
end

function ns.Events.OnLootOpened()
    -- Check if we should skip Mythic+ dungeons
    local skipMythicPlus = BiSWishAddonDB.options and BiSWishAddonDB.options.skipMythicPlus
    if skipMythicPlus then
        local inInstance, instanceType = IsInInstance()
        if instanceType == "party" then
            -- We're in a dungeon, check if it's Mythic+
            local difficultyID = select(3, GetInstanceInfo())
            if difficultyID == 8 then
                -- This is a Mythic+ dungeon, don't show loot tracking
                ns.Core.DebugInfo("Mythic+ loot detected, skipping loot tracking")
                return
            end
        end
    end
    
    print("|cff39FF14BiSWishAddon|r: Loot window opened!")
    -- Check for items that players want
    ns.Events.CheckLootForWantedItems()
end

function ns.Events.OnLootClosed()
    print("|cff39FF14BiSWishAddon|r: Loot window closed!")
end

-- Check loot for wanted items
function ns.Events.CheckLootForWantedItems()
    local numLootItems = GetNumLootItems()
    local wantedItems = {}
    
    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)
        if itemLink then
            local itemName = GetItemInfo(itemLink)
            if itemName then
                -- Check if any players want this item
                local interestedPlayers = {}
                for itemID, itemData in pairs(BiSWishAddonDB.items) do
                    if itemData.name == itemName then
                        for _, playerName in ipairs(itemData.players) do
                            table.insert(interestedPlayers, playerName)
                        end
                    end
                end
                
                if #interestedPlayers > 0 then
                    print("|cff39FF14BiSWishAddon|r: Found wanted item: " .. itemName)
                    table.insert(wantedItems, {
                        name = itemName,
                        link = itemLink,
                        players = interestedPlayers
                    })
                end
            end
        end
    end
    
    -- Show popup if any wanted items found
    if #wantedItems > 0 then
        print("|cff39FF14BiSWishAddon|r: Found " .. #wantedItems .. " wanted items!")
        ns.UI.ShowItemDropPopup(wantedItems)
    end
end
