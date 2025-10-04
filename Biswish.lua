--[[
================================================================================
BiSWishAddon Main File
================================================================================
This is the main entry point for the BiSWish addon. It handles:
- Addon initialization and module loading
- Settings registration with WoW interface
- Event handling for addon loading

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- INITIALIZATION & NAMESPACE SETUP
-- ============================================================================

-- Get addon name and namespace from WoW
local addonName, ns = ...

-- Create global namespace for external access
BiSWishAddon = ns

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

--[[
    Initialize all addon modules in the correct order
    This function loads all required modules and sets up the addon
--]]
function ns.Initialize()
    -- Initialize core functionality first
    ns.Core.Initialize()
    
    -- Initialize data management
    ns.Data.Initialize()
    
    -- Initialize player tracking
    ns.Player.Initialize()
    
    -- Initialize event handling
    ns.Events.Initialize()
    
    -- Initialize user interface
    ns.UI.Initialize()
    
    -- Initialize file operations
    ns.File.Initialize()
    
    -- Initialize options/settings FIRST to ensure options are available
    ns.Options.Initialize()
    
    -- Initialize slash commands
    ns.Commands.Initialize()
    
    -- Try to auto-detect guild name after a short delay
    C_Timer.After(2.0, function()
        if ns.Options and ns.Options.UpdateGuildNameIfNeeded then
            ns.Options.UpdateGuildNameIfNeeded()
        end
    end)
    
    -- Notify user of successful initialization
    print("|cff39FF14BiSWishAddon|r: All modules initialized!")
end

--[[
    Register addon settings with WoW interface
    This function delegates to the Options module for settings registration
--]]
function ns.RegisterSettings()
    if Settings then
        -- Delegate settings registration to Options module
        if ns.Options and ns.Options.RegisterSettings then
            ns.Options.RegisterSettings()
        end
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

--[[
    Main event handler for addon loading
    This frame listens for the ADDON_LOADED event and initializes the addon
--]]
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    -- Check if this is our addon being loaded
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize all modules
        ns.Initialize()
        
        -- Register settings with WoW interface
        ns.RegisterSettings()
    end
end)