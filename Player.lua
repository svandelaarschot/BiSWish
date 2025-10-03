-- BiSWishAddon Player Module
local addonName, ns = ...

-- Player namespace
ns.Player = ns.Player or {}

-- Initialize player system
function ns.Player.Initialize()
    print("|cff39FF14BiSWishAddon|r: Player system initialized!")
end

-- Get current player name
function ns.Player.GetCurrentPlayerName()
    return UnitName("player")
end

-- Get player realm
function ns.Player.GetCurrentRealm()
    return GetRealmName()
end

-- Get full player name (with realm)
function ns.Player.GetFullPlayerName()
    local name = ns.Player.GetCurrentPlayerName()
    local realm = ns.Player.GetCurrentRealm()
    return name .. "-" .. realm
end

-- Check if player is in raid
function ns.Player.IsInRaid()
    return IsInRaid()
end

-- Check if player is in party
function ns.Player.IsInParty()
    return IsInGroup()
end

-- Get raid members
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
