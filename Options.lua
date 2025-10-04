--[[
================================================================================
Options.lua - BiSWish Addon Settings Management
================================================================================
This module handles all addon settings and configuration options including:
- Settings initialization and defaults
- Options panel creation with submenus
- Settings persistence and retrieval
- UI for all configuration options

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create options namespace
ns.Options = ns.Options or {}

-- ============================================================================
-- DEFAULT CONFIGURATION
-- ============================================================================

--[[
    Default options configuration
    These values are used when the addon is first loaded or when options are missing
--]]
local defaultOptions = {
    -- Guild Raid Settings
    autoOpenOnBossKill = true,        -- Auto-open BiS list on boss kill in guild raid
    guildRaidThreshold = 0.8,        -- Percentage of guild members required (80%)
    guildRaidTeamName = "",          -- Guild or raid team name
    
    -- Display Settings
    autoCloseTime = 30,              -- Auto-close time for item drop popup (seconds)
    skipMythicPlus = true,           -- Skip auto-open and loot tracking in Mythic+ dungeons
    disableInDungeons = true,        -- Disable BiS dialog in dungeons (default: off)
    
    -- Debug Settings
    debugMode = false,               -- Enable debug output
    debugLevel = 3,                 -- Debug level (1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG, 5=VERBOSE)
}

-- ============================================================================
-- CORE OPTIONS FUNCTIONS
-- ============================================================================

--[[
    Initialize options with default values if they don't exist
    This ensures all options are properly set when the addon loads
--]]
function ns.Options.InitializeOptions()
    if not BiSWishAddonDB.options then
        BiSWishAddonDB.options = {}
    end
    
    -- Set default values for any missing options
    for key, defaultValue in pairs(defaultOptions) do
        if BiSWishAddonDB.options[key] == nil then
            BiSWishAddonDB.options[key] = defaultValue
        end
    end
end

--[[
    Initialize options system
    Sets up default options if they don't exist in the saved variables
--]]
function ns.Options.Initialize()
    -- Create options table if it doesn't exist
    if not BiSWishAddonDB.options then
        BiSWishAddonDB.options = {}
    end
    
    -- Set default values for any missing options
    for key, value in pairs(defaultOptions) do
        if BiSWishAddonDB.options[key] == nil then
            BiSWishAddonDB.options[key] = value
        end
    end
    
    -- Debug: Log current guild name
    local guildName = BiSWishAddonDB.options.guildRaidTeamName or ""
    ns.Core.DebugInfo("Options initialized - Guild name: '%s'", guildName)
    
    -- Force update any open dialogs after a delay
    C_Timer.After(0.5, function()
        ns.Options.UpdateAllGuildNames()
    end)
    
    print("|cff39FF14BiSWishAddon|r: Options initialized!")
end

--[[
    Set an option value
    @param key (string) - The option key to set
    @param value (any) - The value to set
--]]
function ns.Options.SetOption(key, value)
    -- Ensure options table exists
    if BiSWishAddonDB.options then
        BiSWishAddonDB.options[key] = value
    end
end

--[[
    Get an option value
    @param key (string) - The option key to retrieve
    @return (any) - The option value or default if not set
--]]
function ns.Options.GetOption(key)
    -- Return saved value if it exists
    if BiSWishAddonDB.options then
        return BiSWishAddonDB.options[key]
    end
    -- Return default value
    return defaultOptions[key]
end

-- ============================================================================
-- SETTINGS REGISTRATION
-- ============================================================================

--[[
    Register settings with WoW interface
    Creates the main settings panel and registers it with WoW's settings system
--]]
function ns.Options.RegisterSettings()
    if Settings then
        -- Initialize options with default values
        ns.Options.InitializeOptions()
        
        -- Create root panel
        local rootPanel = CreateFrame("Frame", "BiSWishRootPanel")
        rootPanel.name = "BiSWish"
        
        -- Title
        local titleRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleRoot:SetPoint("TOPLEFT", 16, -16)
        titleRoot:SetText("|cff39FF14BiSWish|r - Settings")
        
        -- Description
        local descRoot = rootPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        descRoot:SetPoint("TOPLEFT", titleRoot, "BOTTOMLEFT", 0, -8)
        descRoot:SetWidth(500)
        descRoot:SetJustifyH("LEFT")
        descRoot:SetText("BiS Wishlist addon for raid loot tracking. Use /bis for commands.")
        
        -- Create subpanels
        local guildPanel = ns.Options.CreateGuildPanel()
        local displayPanel = ns.Options.CreateDisplayPanel()
        local debugPanel = ns.Options.CreateDebugPanel()
        local dataPanel = ns.Options.CreateDataPanel()
        
        -- Register as addon category with subpanels
        local root = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, guildPanel, guildPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, displayPanel, displayPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, debugPanel, debugPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, dataPanel, dataPanel.name)
        Settings.RegisterAddOnCategory(root)
        
    -- Store category reference for commands
    _G.BiSWishSettingsCategory = root
    
    -- Add function to update guild name display when settings are opened
    function ns.Options.UpdateGuildNameInSettings()
        -- First, try to auto-detect guild name if not already set
        local currentGuildName = BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or ""
        
        -- If guild name is not set, try to get it from the player's guild
        if not currentGuildName or currentGuildName == "" then
            local playerGuildName = GetGuildInfo("player")
            if playerGuildName then
                ns.Core.DebugInfo("Settings - Auto-detected guild name: '%s'", playerGuildName)
                if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
                BiSWishAddonDB.options.guildRaidTeamName = playerGuildName
                currentGuildName = playerGuildName
            else
                ns.Core.DebugInfo("Settings - No guild detected for player")
            end
        end
        
        if currentGuildName and currentGuildName ~= "" then
            ns.Core.DebugInfo("Settings - Updating guild name display: '%s'", currentGuildName)
            
            -- Find and update the guild name edit box in the settings panel
            if _G.BiSWishSettingsCategory and _G.BiSWishSettingsCategory.guildNameEditBox then
                _G.BiSWishSettingsCategory.guildNameEditBox:SetText(currentGuildName)
                ns.Core.DebugInfo("Settings - Updated guild name edit box: '%s'", currentGuildName)
            end
        end
    end
    
    -- Function to update all guild names in open dialogs
    function ns.Options.UpdateAllGuildNames()
        local guildName = BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or ""
        ns.Core.DebugInfo("UpdateAllGuildNames - Guild name: '%s'", guildName)
        
        -- Update BiS List Dialog if open
        if ns.UI and ns.UI.biSListDialog and ns.UI.biSListDialog:IsShown() then
            -- Update title with guild name
            local titleText = "|cff39FF14BiS Wishlist|r"
            if guildName and guildName ~= "" then
                titleText = titleText .. " [" .. guildName .. "]"
            end
            if ns.UI.biSListDialog.TitleText then
                ns.UI.biSListDialog.TitleText:SetText(titleText)
            elseif ns.UI.biSListDialog.title then
                ns.UI.biSListDialog.title:SetText(titleText)
            end
            
            ns.UI.UpdateGuildNameDisplay()
        end
        
        -- Update Boss Window if open
        if ns.UI and ns.UI.bossWindow and ns.UI.bossWindow:IsShown() then
            local bossName = "Manual View"
            local titleText = "BiS Wishlist - " .. bossName
            if guildName and guildName ~= "" then
                titleText = titleText .. " [" .. guildName .. "]"
            end
            if ns.UI.bossWindow.TitleText then
                ns.UI.bossWindow.TitleText:SetText(titleText)
            elseif ns.UI.bossWindow.title then
                ns.UI.bossWindow.title:SetText(titleText)
            end
        end
        
        -- Update Data Window if open
        if ns.UI and ns.UI.dataWindow and ns.UI.dataWindow:IsShown() then
            local titleText = "|cff39FF14BiS Data Management|r"
            if guildName and guildName ~= "" then
                titleText = titleText .. " [" .. guildName .. "]"
            end
            if ns.UI.dataWindow.TitleText then
                ns.UI.dataWindow.TitleText:SetText(titleText)
            elseif ns.UI.dataWindow.title then
                ns.UI.dataWindow.title:SetText(titleText)
            end
        end
    end
    end
end

-- ============================================================================
-- UI PANEL CREATION
-- ============================================================================

--[[
    Create the main options panel
    This creates a standalone options panel (not used in current implementation)
--]]
function ns.Options.CreateOptionsPanel()
    local frame = CreateFrame("Frame", "BiSWishOptionsFrame", UIParent)
    frame.name = "General"
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:Hide()
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cff39FF14BiSWish|r - General Settings")
    
    -- Description
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("All BiSWish addon settings and data management options.")
    
    -- Create subpanels
    local guildPanel = ns.Options.CreateGuildPanel()
    local displayPanel = ns.Options.CreateDisplayPanel()
    local debugPanel = ns.Options.CreateDebugPanel()
    local dataPanel = ns.Options.CreateDataPanel()
    
    -- Register as addon category with subpanels
    local root = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
    Settings.RegisterCanvasLayoutSubcategory(root, guildPanel, guildPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, displayPanel, displayPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, debugPanel, debugPanel.name)
    Settings.RegisterCanvasLayoutSubcategory(root, dataPanel, dataPanel.name)
    Settings.RegisterAddOnCategory(root)
    
    return frame
end

-- ============================================================================
-- INDIVIDUAL PANEL CREATION FUNCTIONS
-- ============================================================================

--[[
    Create Guild Raid Settings Panel
    Contains settings for guild raid auto-open functionality and guild name
--]]
function ns.Options.CreateGuildPanel()
    local panel = CreateFrame("Frame", "BiSWishGuildPanel")
    panel.name = "Guild Raid"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Guild Raid Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure guild raid auto-open settings and guild name. These settings control when the BiS wishlist automatically opens during guild raids.")
    
    local yOffset = -80
    
    -- Auto-open BiS Wishlist on boss kill in guild raid
    local autoOpenGuildCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoOpenGuildCheck:SetPoint("TOPLEFT", 20, yOffset)
    autoOpenGuildCheck.Text:SetText("Auto-open BiS Wishlist on boss kill in guild raid")
    autoOpenGuildCheck:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.autoOpenOnBossKill or true)
    autoOpenGuildCheck:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.autoOpenOnBossKill = self:GetChecked()
    end)
    
    -- Auto-open description
    local autoOpenDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoOpenDesc:SetPoint("TOPLEFT", autoOpenGuildCheck, "BOTTOMLEFT", 20, -5)
    autoOpenDesc:SetWidth(540)
    autoOpenDesc:SetJustifyH("LEFT")
    autoOpenDesc:SetText("Automatically opens the BiS wishlist when a boss is killed in a guild raid (based on guild raid threshold).")
    autoOpenDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 80
    
    -- Guild raid threshold
    local thresholdLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdLabel:SetPoint("TOPLEFT", 20, yOffset)
    thresholdLabel:SetText("Guild raid threshold (%):")
    
    local thresholdSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    thresholdSlider:SetPoint("TOPLEFT", thresholdLabel, "BOTTOMLEFT", 0, -10)
    thresholdSlider:SetSize(300, 20)
    thresholdSlider:SetMinMaxValues(0.5, 1.0)
    thresholdSlider:SetValue(BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidThreshold or 0.8)
    thresholdSlider:SetValueStep(0.1)
    thresholdSlider:SetObeyStepOnDrag(true)
    thresholdSlider.Low:SetText("50%")
    thresholdSlider.High:SetText("100%")
    
    local thresholdValue = thresholdSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdValue:SetPoint("LEFT", thresholdSlider, "RIGHT", 15, 0)
    thresholdValue:SetText(tostring(math.floor((BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidThreshold or 0.8) * 100)) .. "%")
    
    thresholdSlider:SetScript("OnValueChanged", function(self, value)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidThreshold = value
        thresholdValue:SetText(tostring(math.floor(value * 100)) .. "%")
    end)
    
    -- Threshold description
    local thresholdDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresholdDesc:SetPoint("TOPLEFT", thresholdSlider, "BOTTOMLEFT", 0, -5)
    thresholdDesc:SetWidth(540)
    thresholdDesc:SetJustifyH("LEFT")
    thresholdDesc:SetText("Percentage of raid members that must be from your guild to trigger auto-open. Higher values mean more guild members required.")
    thresholdDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 100
    
    -- Guild/Raid Team Name
    local guildNameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildNameLabel:SetPoint("TOPLEFT", 20, yOffset)
    guildNameLabel:SetText("Guild/Raid Team Name:")
    
    local guildNameEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    guildNameEditBox:SetPoint("TOPLEFT", guildNameLabel, "BOTTOMLEFT", 0, -10)
    guildNameEditBox:SetSize(250, 30)
    guildNameEditBox:SetAutoFocus(false)
    
    -- Add refresh button for guild name detection
    local guildNameRefreshButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    guildNameRefreshButton:SetPoint("LEFT", guildNameEditBox, "RIGHT", 10, 0)
    guildNameRefreshButton:SetSize(80, 30)
    guildNameRefreshButton:SetText("Auto-fill")
    guildNameRefreshButton:SetScript("OnClick", function()
        local playerGuildName = GetGuildInfo("player")
        if playerGuildName then
            guildNameEditBox:SetText(playerGuildName)
            if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
            BiSWishAddonDB.options.guildRaidTeamName = playerGuildName
            ns.Core.DebugInfo("Settings - Manually refreshed guild name: '%s'", playerGuildName)
        else
            ns.Core.DebugInfo("Settings - No guild detected when refreshing")
        end
    end)
    
    -- Store reference to the edit box for later updates
    if _G.BiSWishSettingsCategory then
        _G.BiSWishSettingsCategory.guildNameEditBox = guildNameEditBox
    end
    
    -- Set initial guild name with auto-detection if not already set
    local initialGuildName = BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or ""
    
    -- If guild name is not set, try to get it from the player's guild
    if not initialGuildName or initialGuildName == "" then
        local playerGuildName = GetGuildInfo("player")
        if playerGuildName then
            ns.Core.DebugInfo("Settings - Auto-detected guild name during initialization: '%s'", playerGuildName)
            if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
            BiSWishAddonDB.options.guildRaidTeamName = playerGuildName
            initialGuildName = playerGuildName
        else
            ns.Core.DebugInfo("Settings - No guild detected for player during initialization")
        end
    end
    
    ns.Core.DebugInfo("Settings - Setting initial guild name: '%s'", initialGuildName)
    guildNameEditBox:SetText(initialGuildName)
    
    guildNameEditBox:SetScript("OnTextChanged", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidTeamName = self:GetText()
    end)
    
    guildNameEditBox:SetScript("OnEditFocusLost", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidTeamName = self:GetText()
        -- Update guild name display if BiS list is open
        if ns.UI and ns.UI.UpdateGuildNameDisplay then
            ns.UI.UpdateGuildNameDisplay()
        end
        -- Also update boss window title if it's open
        if ns.UI and ns.UI.bossWindow and ns.UI.bossWindow:IsShown() then
            local guildName = ""
            if BiSWishAddonDB.options.guildRaidTeamName and BiSWishAddonDB.options.guildRaidTeamName ~= "" then
                guildName = " [" .. BiSWishAddonDB.options.guildRaidTeamName .. "]"
            end
            local bossName = "Manual View" -- Default, could be improved to get actual boss name
            local titleText = "BiS Wishlist - " .. bossName .. guildName
            if ns.UI.bossWindow.TitleText then
                ns.UI.bossWindow.TitleText:SetText(titleText)
            elseif ns.UI.bossWindow.title then
                ns.UI.bossWindow.title:SetText(titleText)
            end
        end
        
        -- Also update data management window title if it's open
        if ns.UI and ns.UI.dataWindow and ns.UI.dataWindow:IsShown() then
            local guildName = ""
            if BiSWishAddonDB.options.guildRaidTeamName and BiSWishAddonDB.options.guildRaidTeamName ~= "" then
                guildName = " [" .. BiSWishAddonDB.options.guildRaidTeamName .. "]"
            end
            local titleText = "|cff39FF14BiS Data Management|r" .. guildName
            if ns.UI.dataWindow.TitleText then
                ns.UI.dataWindow.TitleText:SetText(titleText)
            elseif ns.UI.dataWindow.title then
                ns.UI.dataWindow.title:SetText(titleText)
            end
        end
    end)
    
    -- Guild name description
    local guildNameDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guildNameDesc:SetPoint("TOPLEFT", guildNameEditBox, "BOTTOMLEFT", 0, -5)
    guildNameDesc:SetWidth(540)
    guildNameDesc:SetJustifyH("LEFT")
    guildNameDesc:SetText("Enter your guild or raid team name. This will be displayed in the BiS wishlist interface.")
    guildNameDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 80
    
    -- Skip Mythic+ checkbox
    local skipMythicPlusCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    skipMythicPlusCheckbox:SetPoint("TOPLEFT", 20, yOffset)
    skipMythicPlusCheckbox:SetSize(20, 20)
    skipMythicPlusCheckbox:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.skipMythicPlus or true)
    
    skipMythicPlusCheckbox:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.skipMythicPlus = self:GetChecked()
        ns.Core.DebugInfo("Skip Mythic+ setting changed to: %s", tostring(self:GetChecked()))
    end)
    
    local skipMythicPlusLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skipMythicPlusLabel:SetPoint("LEFT", skipMythicPlusCheckbox, "RIGHT", 5, 0)
    skipMythicPlusLabel:SetText("Skip auto-open and loot tracking in Mythic+ dungeons")
    skipMythicPlusLabel:SetTextColor(1, 1, 1)
    
    -- Skip Mythic+ description
    local skipMythicPlusDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    skipMythicPlusDesc:SetPoint("TOPLEFT", skipMythicPlusCheckbox, "BOTTOMLEFT", 0, -5)
    skipMythicPlusDesc:SetWidth(540)
    skipMythicPlusDesc:SetJustifyH("LEFT")
    skipMythicPlusDesc:SetText("Prevents the BiS list and loot tracking from appearing during Mythic+ dungeon runs.")
    skipMythicPlusDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 60
    
    -- Disable in dungeons checkbox
    local disableInDungeonsCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    disableInDungeonsCheckbox:SetPoint("TOPLEFT", 20, yOffset)
    disableInDungeonsCheckbox:SetSize(20, 20)
    disableInDungeonsCheckbox:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.disableInDungeons or true)
    
    disableInDungeonsCheckbox:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.disableInDungeons = self:GetChecked()
        ns.Core.DebugInfo("Disable in dungeons setting changed to: %s", tostring(self:GetChecked()))
    end)
    
    local disableInDungeonsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    disableInDungeonsLabel:SetPoint("LEFT", disableInDungeonsCheckbox, "RIGHT", 5, 0)
    disableInDungeonsLabel:SetText("Disable BiS dialog in dungeons (including Mythic+)")
    disableInDungeonsLabel:SetTextColor(1, 1, 1)
    
    -- Disable in dungeons description
    local disableInDungeonsDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    disableInDungeonsDesc:SetPoint("TOPLEFT", disableInDungeonsCheckbox, "BOTTOMLEFT", 0, -5)
    disableInDungeonsDesc:SetWidth(540)
    disableInDungeonsDesc:SetJustifyH("LEFT")
    disableInDungeonsDesc:SetText("Prevents the BiS dialog from opening when using /bis show in dungeons. Recommended for M+ runs.")
    disableInDungeonsDesc:SetTextColor(0.7, 0.7, 0.7)
    
    return panel
end

--[[
    Create Display Settings Panel
    Contains settings for display and popup behavior
--]]
function ns.Options.CreateDisplayPanel()
    local panel = CreateFrame("Frame", "BiSWishDisplayPanel")
    panel.name = "Display"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Display Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure display and popup settings for the BiS wishlist interface.")
    
    local yOffset = -60
    
    -- Auto-close time for item drop popup
    local autoCloseLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoCloseLabel:SetPoint("TOPLEFT", 20, yOffset)
    autoCloseLabel:SetText("Auto-close time for item drop popup (seconds):")
    
    local autoCloseSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    autoCloseSlider:SetPoint("TOPLEFT", autoCloseLabel, "BOTTOMLEFT", 0, -10)
    autoCloseSlider:SetSize(300, 20)
    autoCloseSlider:SetMinMaxValues(5, 60)
    autoCloseSlider:SetValue(BiSWishAddonDB.options and BiSWishAddonDB.options.autoCloseTime or 30)
    autoCloseSlider:SetValueStep(5)
    autoCloseSlider:SetObeyStepOnDrag(true)
    autoCloseSlider.Low:SetText("5s")
    autoCloseSlider.High:SetText("60s")
    
    local autoCloseValue = autoCloseSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoCloseValue:SetPoint("LEFT", autoCloseSlider, "RIGHT", 15, 0)
    autoCloseValue:SetText(tostring(BiSWishAddonDB.options and BiSWishAddonDB.options.autoCloseTime or 30) .. "s")
    
    autoCloseSlider:SetScript("OnValueChanged", function(self, value)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.autoCloseTime = value
        autoCloseValue:SetText(tostring(value) .. "s")
    end)
    
    -- Auto-close description
    local autoCloseDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoCloseDesc:SetPoint("TOPLEFT", autoCloseSlider, "BOTTOMLEFT", 0, -5)
    autoCloseDesc:SetWidth(540)
    autoCloseDesc:SetJustifyH("LEFT")
    autoCloseDesc:SetText("How long the item drop popup stays open before automatically closing. Set to 0 to disable auto-close.")
    autoCloseDesc:SetTextColor(0.7, 0.7, 0.7)
    
    return panel
end

--[[
    Create Debug Settings Panel
    Contains settings for debug mode and logging levels
--]]
function ns.Options.CreateDebugPanel()
    local panel = CreateFrame("Frame", "BiSWishDebugPanel")
    panel.name = "Debug"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Debug Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure debug mode and logging levels for troubleshooting addon issues.")
    
    local yOffset = -60
    
    -- Debug mode
    local debugModeCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    debugModeCheck:SetPoint("TOPLEFT", 20, yOffset)
    debugModeCheck.Text:SetText("Enable debug mode")
    debugModeCheck:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.debugMode or false)
    debugModeCheck:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.debugMode = self:GetChecked()
    end)
    
    -- Debug mode description
    local debugModeDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    debugModeDesc:SetPoint("TOPLEFT", debugModeCheck, "BOTTOMLEFT", 20, -5)
    debugModeDesc:SetWidth(540)
    debugModeDesc:SetJustifyH("LEFT")
    debugModeDesc:SetText("Enable debug output to chat. Useful for troubleshooting addon issues.")
    debugModeDesc:SetTextColor(0.7, 0.7, 0.7)
    
    yOffset = yOffset - 60
    
    -- Debug level
    local debugLevelLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugLevelLabel:SetPoint("TOPLEFT", 20, yOffset)
    debugLevelLabel:SetText("Debug level:")
    
    local debugLevelSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    debugLevelSlider:SetPoint("TOPLEFT", debugLevelLabel, "BOTTOMLEFT", 0, -10)
    debugLevelSlider:SetSize(300, 20)
    debugLevelSlider:SetMinMaxValues(1, 5)
    debugLevelSlider:SetValue(BiSWishAddonDB.options and BiSWishAddonDB.options.debugLevel or 3)
    debugLevelSlider:SetValueStep(1)
    debugLevelSlider:SetObeyStepOnDrag(true)
    debugLevelSlider.Low:SetText("1")
    debugLevelSlider.High:SetText("5")
    
    local debugLevelValue = debugLevelSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    debugLevelValue:SetPoint("LEFT", debugLevelSlider, "RIGHT", 15, 0)
    local levelNames = {"ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE"}
    local currentLevel = BiSWishAddonDB.options and BiSWishAddonDB.options.debugLevel or 3
    debugLevelValue:SetText(levelNames[currentLevel])
    
    debugLevelSlider:SetScript("OnValueChanged", function(self, value)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.debugLevel = value
        debugLevelValue:SetText(levelNames[value])
    end)
    
    -- Debug level description
    local debugLevelDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    debugLevelDesc:SetPoint("TOPLEFT", debugLevelSlider, "BOTTOMLEFT", 0, -5)
    debugLevelDesc:SetWidth(540)
    debugLevelDesc:SetJustifyH("LEFT")
    debugLevelDesc:SetText("1=ERROR, 2=WARNING, 3=INFO, 4=DEBUG, 5=VERBOSE. Higher levels show more detailed information.")
    debugLevelDesc:SetTextColor(0.7, 0.7, 0.7)
    
    return panel
end

--[[
    Create Data Management Panel
    Contains buttons and options for managing BiS data (import, view, manage)
--]]
function ns.Options.CreateDataPanel()
    local panel = CreateFrame("Frame", "BiSWishDataPanel")
    panel.name = "Data Management"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Data Management")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(580)
    desc:SetJustifyH("LEFT")
    desc:SetText("Manage your BiS data, import/export settings, and backup options.")
    
    local yOffset = -60
    
    -- Import Data Section
    local importLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", 20, yOffset)
    importLabel:SetText("Import Data:")
    importLabel:SetTextColor(1, 1, 1)
    
    local importDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importDesc:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -5)
    importDesc:SetWidth(560)
    importDesc:SetJustifyH("LEFT")
    importDesc:SetText("Import BiS data from CSV files. Supports the format: Player,Trinket 1,Trinket 2,Weapon 1,Weapon 2,Description")
    importDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local importButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importButton:SetPoint("TOPLEFT", importDesc, "BOTTOMLEFT", 0, -10)
    importButton:SetSize(180, 35)
    importButton:SetText("Import CSV Data")
    importButton:SetScript("OnClick", function()
        if ns.UI and ns.UI.ImportData then
            ns.UI.ImportData()
        else
            print("|cffFF0000BiSWishAddon|r: Import function not available")
        end
    end)
    
    yOffset = yOffset - 100
    
    -- View Data Section
    local viewLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    viewLabel:SetPoint("TOPLEFT", 20, yOffset)
    viewLabel:SetText("View Data:")
    viewLabel:SetTextColor(1, 1, 1)
    
    local viewDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    viewDesc:SetPoint("TOPLEFT", viewLabel, "BOTTOMLEFT", 0, -5)
    viewDesc:SetWidth(560)
    viewDesc:SetJustifyH("LEFT")
    viewDesc:SetText("View and search through your BiS wishlist. Filter by player names and see item details.")
    viewDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local showListButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    showListButton:SetPoint("TOPLEFT", viewDesc, "BOTTOMLEFT", 0, -10)
    showListButton:SetSize(180, 35)
    showListButton:SetText("Show BiS List")
    showListButton:SetScript("OnClick", function()
        if ns.UI and ns.UI.ShowBiSListDialog then
            ns.UI.ShowBiSListDialog()
        else
            print("|cffFF0000BiSWishAddon|r: ShowBiSListDialog function not available")
        end
    end)
    
    yOffset = yOffset - 100
    
    -- Manage Data Section
    local manageLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    manageLabel:SetPoint("TOPLEFT", 20, yOffset)
    manageLabel:SetText("Manage Data:")
    manageLabel:SetTextColor(1, 1, 1)
    
    local manageDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manageDesc:SetPoint("TOPLEFT", manageLabel, "BOTTOMLEFT", 0, -5)
    manageDesc:SetWidth(560)
    manageDesc:SetJustifyH("LEFT")
    manageDesc:SetText("Add new items manually or clear all existing data. Use with caution!")
    manageDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local addItemButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addItemButton:SetPoint("TOPLEFT", manageDesc, "BOTTOMLEFT", 0, -10)
    addItemButton:SetSize(180, 35)
    addItemButton:SetText("Add Item Manually")
    addItemButton:SetScript("OnClick", function()
        if ns.UI and ns.UI.ShowDataWindow then
            ns.UI.ShowDataWindow()
        else
            print("|cffFF0000BiSWishAddon|r: ShowDataWindow function not available")
        end
    end)
    
    local clearDataButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearDataButton:SetPoint("TOPLEFT", addItemButton, "BOTTOMLEFT", 0, -10)
    clearDataButton:SetSize(180, 35)
    clearDataButton:SetText("Clear All Data")
    clearDataButton:SetScript("OnClick", function()
        BiSWishAddonDB.items = {}
        print("|cff39FF14BiSWishAddon|r: Cleared all BiS data!")
    end)
    
    return panel
end