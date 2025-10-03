-- BiSWishAddon Events Module
local addonName, ns = ...

-- Events namespace
ns.Events = ns.Events or {}

-- Initialize events
function ns.Events.Initialize()
    ns.Events.RegisterEvents()
    print("|cff39FF14BiSWishAddon|r: Events initialized!")
end

-- Register event handlers
function ns.Events.RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        ns.Events.HandleEvent(event, ...)
    end)
end

-- Handle events
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

function ns.Events.OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    if success then
        print("|cff39FF14BiSWishAddon|r: Boss defeated! Showing BiS data for: " .. encounterName)
        ns.UI.ShowBossWindow(encounterName)
        
        -- Check if we should auto-open BiS Wishlist for guild raids
        ns.UI.CheckBossKillAutoOpen()
    end
end
