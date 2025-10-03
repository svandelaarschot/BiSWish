-- BiSWishAddon Main File
local addonName, ns = ...

-- Global namespace
BiSWishAddon = ns

-- Initialize all modules
function ns.Initialize()
    ns.Core.Initialize()
    ns.Data.Initialize()
    ns.Player.Initialize()
    ns.Events.Initialize()
    ns.UI.Initialize()
    ns.File.Initialize()
    ns.Options.Initialize()
    ns.Commands.Initialize()
    
    print("|cff39FF14BiSWishAddon|r: All modules initialized!")
end

-- Register settings
function ns.RegisterSettings()
    if Settings then
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
        local generalPanel = ns.CreateGeneralPanel()
        local dataPanel = ns.CreateDataPanel()
        local optionsPanel = ns.CreateOptionsPanel()
        
        -- Register as addon category with subpanels
        local root = Settings.RegisterCanvasLayoutCategory(rootPanel, rootPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, generalPanel, generalPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, dataPanel, dataPanel.name)
        Settings.RegisterCanvasLayoutSubcategory(root, optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(root)
    end
end

-- Create General Panel
function ns.CreateGeneralPanel()
    local panel = CreateFrame("Frame", "BiSWishGeneralPanel")
    panel.name = "General"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - General Settings")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(500)
    desc:SetJustifyH("LEFT")
    desc:SetText("Guild raid auto-open settings for the BiSWish addon.")
    
    -- Auto-open BiS Wishlist on boss kill in guild raid
    local autoOpenGuildCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    autoOpenGuildCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    autoOpenGuildCheck.Text:SetText("Auto-open BiS Wishlist on boss kill in guild raid")
    autoOpenGuildCheck:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.autoOpenOnBossKill or true)
    autoOpenGuildCheck:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.autoOpenOnBossKill = self:GetChecked()
    end)
    
    -- Guild raid threshold
    local thresholdLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdLabel:SetPoint("TOPLEFT", autoOpenGuildCheck, "BOTTOMLEFT", 0, -20)
    thresholdLabel:SetText("Guild raid threshold (%):")
    
    local thresholdSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    thresholdSlider:SetPoint("TOPLEFT", thresholdLabel, "BOTTOMLEFT", 0, -10)
    thresholdSlider:SetSize(200, 20)
    thresholdSlider:SetMinMaxValues(0.5, 1.0)
    thresholdSlider:SetValue(BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidThreshold or 0.8)
    thresholdSlider:SetValueStep(0.1)
    thresholdSlider:SetObeyStepOnDrag(true)
    thresholdSlider.Low:SetText("50%")
    thresholdSlider.High:SetText("100%")
    
    local thresholdValue = thresholdSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdValue:SetPoint("LEFT", thresholdSlider, "RIGHT", 10, 0)
    thresholdValue:SetText(tostring(math.floor((BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidThreshold or 0.8) * 100)) .. "%")
    
    thresholdSlider:SetScript("OnValueChanged", function(self, value)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidThreshold = value
        thresholdValue:SetText(tostring(math.floor(value * 100)) .. "%")
    end)
    
    -- Guild/Raid Team Name
    local guildNameLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildNameLabel:SetPoint("TOPLEFT", thresholdSlider, "BOTTOMLEFT", 0, -30)
    guildNameLabel:SetText("Guild/Raid Team Name:")
    
    local guildNameEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    guildNameEditBox:SetPoint("TOPLEFT", guildNameLabel, "BOTTOMLEFT", 0, -10)
    guildNameEditBox:SetSize(300, 30)
    guildNameEditBox:SetText(BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or "")
    guildNameEditBox:SetAutoFocus(false)
    guildNameEditBox:SetScript("OnTextChanged", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidTeamName = self:GetText()
        print("|cff39FF14BiSWishAddon|r: Guild name saved: " .. (self:GetText() or ""))
    end)
    
    guildNameEditBox:SetScript("OnEditFocusLost", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.guildRaidTeamName = self:GetText()
        print("|cff39FF14BiSWishAddon|r: Guild name saved on focus lost: " .. (self:GetText() or ""))
    end)
    
    return panel
end

-- Create Data Management Panel
function ns.CreateDataPanel()
    local panel = CreateFrame("Frame", "BiSWishDataPanel")
    panel.name = "Data Management"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Data Management")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(600)
    desc:SetJustifyH("LEFT")
    desc:SetText("Manage your BiS data, import/export settings, and backup options.")
    
    -- Import Data Section
    local importLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -30)
    importLabel:SetText("|cff39FF14Import Data|r")
    importLabel:SetTextColor(1, 1, 1)
    
    local importDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importDesc:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -5)
    importDesc:SetWidth(600)
    importDesc:SetJustifyH("LEFT")
    importDesc:SetText("Import BiS data from CSV files. Supports the format: Player,Trinket 1,Trinket 2,Weapon 1,Weapon 2,Description")
    importDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local importButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importButton:SetPoint("TOPLEFT", importDesc, "BOTTOMLEFT", 0, -10)
    importButton:SetSize(180, 35)
    importButton:SetText("Import CSV Data")
    importButton:SetScript("OnClick", function()
        ns.UI.ImportData()
    end)
    
    -- View Data Section
    local viewLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    viewLabel:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -25)
    viewLabel:SetText("|cff39FF14View Data|r")
    viewLabel:SetTextColor(1, 1, 1)
    
    local viewDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    viewDesc:SetPoint("TOPLEFT", viewLabel, "BOTTOMLEFT", 0, -5)
    viewDesc:SetWidth(600)
    viewDesc:SetJustifyH("LEFT")
    viewDesc:SetText("View and search through your BiS wishlist. Filter by player names and see item details.")
    viewDesc:SetTextColor(0.8, 0.8, 0.8)
    
    local showListButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    showListButton:SetPoint("TOPLEFT", viewDesc, "BOTTOMLEFT", 0, -10)
    showListButton:SetSize(180, 35)
    showListButton:SetText("Show BiS List")
    showListButton:SetScript("OnClick", function()
        ns.UI.ShowBiSListDialog()
    end)
    
    -- Manage Data Section
    local manageLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    manageLabel:SetPoint("TOPLEFT", showListButton, "BOTTOMLEFT", 0, -25)
    manageLabel:SetText("|cff39FF14Manage Data|r")
    manageLabel:SetTextColor(1, 1, 1)
    
    local manageDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manageDesc:SetPoint("TOPLEFT", manageLabel, "BOTTOMLEFT", 0, -5)
    manageDesc:SetWidth(600)
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
            print("|cff39FF14BiSWishAddon|r: Error - ShowDataWindow function not found!")
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

-- Create Advanced Options Panel
function ns.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "BiSWishOptionsPanel")
    panel.name = "Advanced Options"
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff39FF14BiSWish|r - Advanced Options")
    
    -- Description
    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(500)
    desc:SetJustifyH("LEFT")
    desc:SetText("Advanced settings and options for the BiSWish addon.")
    
    -- Debug Mode
    local debugCheck = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    debugCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    debugCheck.Text:SetText("Debug Mode")
    debugCheck:SetChecked(BiSWishAddonDB.options and BiSWishAddonDB.options.debugMode or false)
    debugCheck:SetScript("OnClick", function(self)
        if not BiSWishAddonDB.options then BiSWishAddonDB.options = {} end
        BiSWishAddonDB.options.debugMode = self:GetChecked()
    end)
    
    return panel
end

-- Event handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        ns.Initialize()
        ns.RegisterSettings()
    end
end)