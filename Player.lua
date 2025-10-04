--[[
================================================================================
Player.lua - BiSWish Addon Player Management Module
================================================================================
This module handles player-related functionality for the BiSWish addon including:
- Player name and realm management
- Raid and group detection
- Guild membership checking
- Player data utilities

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create player namespace
ns.Player = ns.Player or {}

-- ============================================================================
-- PLAYER SYSTEM INITIALIZATION
-- ============================================================================

--[[
    Initialize player system
    Sets up player-related functionality
--]]
function ns.Player.Initialize()
    print("|cff39FF14BiSWishAddon|r: Player system initialized!")
end

-- ============================================================================
-- PLAYER INFORMATION FUNCTIONS
-- ============================================================================

--[[
    Get current player name
    @return (string) - The player's name
--]]
function ns.Player.GetCurrentPlayerName()
    return UnitName("player")
end

--[[
    Get player realm
    @return (string) - The player's realm name
--]]
function ns.Player.GetCurrentRealm()
    return GetRealmName()
end

--[[
    Get full player name with realm
    @return (string) - The player's name with realm (name-realm)
--]]
function ns.Player.GetFullPlayerName()
    local name = ns.Player.GetCurrentPlayerName()
    local realm = ns.Player.GetCurrentRealm()
    return name .. "-" .. realm
end

-- ============================================================================
-- GROUP AND RAID FUNCTIONS
-- ============================================================================

--[[
    Check if player is in raid
    @return (boolean) - True if player is in raid
--]]
function ns.Player.IsInRaid()
    return IsInRaid()
end

--[[
    Check if player is in party
    @return (boolean) - True if player is in party
--]]
function ns.Player.IsInParty()
    return IsInGroup()
end

--[[
    Get raid members
    @return (table) - Table of raid member information
--]]
function ns.Player.GetRaidMembers()
    local members = {}
    if ns.Player.IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            if name then
                table.insert(members, {
                    name = name,
                    class = class,
                    level = level,
                    online = online,
                    isDead = isDead,
                    role = role
                })
            end
        end
    end
    return members
end

-- Get party members
function ns.Player.GetPartyMembers()
    local members = {}
    if ns.Player.IsInParty() and not ns.Player.IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            if name then
                table.insert(members, {
                    name = name,
                    class = class,
                    level = level,
                    online = online,
                    isDead = isDead,
                    role = role
                })
            end
        end
    end
    return members
end

-- Get all group members (raid or party)
function ns.Player.GetAllGroupMembers()
    if ns.Player.IsInRaid() then
        return ns.Player.GetRaidMembers()
    elseif ns.Player.IsInParty() then
        return ns.Player.GetPartyMembers()
    else
        return {}
    end
end

-- Check if player is group leader
function ns.Player.IsGroupLeader()
    return IsGroupLeader()
end

-- Check if player is raid leader
function ns.Player.IsRaidLeader()
    return IsRaidLeader()
end

-- Get player class
function ns.Player.GetPlayerClass()
    local _, class = UnitClass("player")
    return class
end

-- Get player level
function ns.Player.GetPlayerLevel()
    return UnitLevel("player")
end

-- Check if player is dead
function ns.Player.IsPlayerDead()
    return UnitIsDead("player")
end

-- Get player zone
function ns.Player.GetPlayerZone()
    return GetZoneText()
end

-- Get player subzone
function ns.Player.GetPlayerSubZone()
    return GetSubZoneText()
end

-- Check if player is in instance
function ns.Player.IsInInstance()
    return IsInInstance()
end

-- Get instance type
function ns.Player.GetInstanceType()
    local inInstance, instanceType = IsInInstance()
    return instanceType
end

-- Check if player is in raid instance
function ns.Player.IsInRaidInstance()
    return ns.Player.IsInInstance() and ns.Player.GetInstanceType() == "raid"
end

-- Check if player is in dungeon instance
function ns.Player.IsInDungeonInstance()
    return ns.Player.IsInInstance() and ns.Player.GetInstanceType() == "party"
end
