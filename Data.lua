-- BiSWishAddon Data Module
local addonName, ns = ...

-- Data namespace
ns.Data = ns.Data or {}

-- Initialize data system
function ns.Data.Initialize()
    print("|cff39FF14BiSWishAddon|r: Data system initialized!")
end

-- Add item to database
function ns.Data.AddItem(itemID, itemName, players)
    if not BiSWishAddonDB.items[itemID] then
        BiSWishAddonDB.items[itemID] = {
            name = itemName,
            players = {}
        }
    end
    
    -- Add players if provided
    if players then
        for _, player in ipairs(players) do
            table.insert(BiSWishAddonDB.items[itemID].players, player)
        end
    end
end

-- Get item data
function ns.Data.GetItemData(itemID)
    return BiSWishAddonDB.items[itemID]
end

-- Remove item from database
function ns.Data.RemoveItem(itemID)
    if BiSWishAddonDB.items[itemID] then
        BiSWishAddonDB.items[itemID] = nil
        return true
    end
    return false
end

-- Get all items
function ns.Data.GetAllItems()
    return BiSWishAddonDB.items
end

-- Clear all data
function ns.Data.ClearAll()
    BiSWishAddonDB.items = {}
end

-- Get item ID from link
function ns.Data.GetItemIDFromLink(link)
    if not link then return nil end
    local itemID = link:match("item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

-- Get item count
function ns.Data.GetItemCount()
    local count = 0
    for _ in pairs(BiSWishAddonDB.items) do
        count = count + 1
    end
    return count
end

-- Check if item exists
function ns.Data.ItemExists(itemID)
    return BiSWishAddonDB.items[itemID] ~= nil
end

-- Get players for item
function ns.Data.GetPlayersForItem(itemID)
    local data = BiSWishAddonDB.items[itemID]
    return data and data.players or {}
end

-- Add player to item
function ns.Data.AddPlayerToItem(itemID, playerName)
    if not BiSWishAddonDB.items[itemID] then
        return false
    end
    
    -- Check if player already exists
    for _, player in ipairs(BiSWishAddonDB.items[itemID].players) do
        if player == playerName then
            return false -- Player already exists
        end
    end
    
    table.insert(BiSWishAddonDB.items[itemID].players, playerName)
    return true
end

-- Remove player from item
function ns.Data.RemovePlayerFromItem(itemID, playerName)
    if not BiSWishAddonDB.items[itemID] then
        return false
    end
    
    for i, player in ipairs(BiSWishAddonDB.items[itemID].players) do
        if player == playerName then
            table.remove(BiSWishAddonDB.items[itemID].players, i)
            return true
        end
    end
    
    return false
end
