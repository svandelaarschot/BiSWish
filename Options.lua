-- BiSWishAddon Options Module
local addonName, ns = ...

-- Options namespace
ns.Options = ns.Options or {}

-- Default options
local defaultOptions = {
    -- Guild Raid Auto-Open
    autoOpenOnBossKill = true,
    guildRaidThreshold = 0.8,
    -- Guild/Raid Team Name
    guildRaidTeamName = "",
}

-- Initialize options
function ns.Options.Initialize()
    -- Initialize options database
    if not BiSWishAddonDB.options then
        BiSWishAddonDB.options = {}
    end
    
    -- Set default values for missing options
    for key, value in pairs(defaultOptions) do
        if BiSWishAddonDB.options[key] == nil then
            BiSWishAddonDB.options[key] = value
        end
    end
    
    print("|cff39FF14BiSWishAddon|r: Options initialized!")
end

-- Set option value
function ns.Options.SetOption(key, value)
    if BiSWishAddonDB.options then
        BiSWishAddonDB.options[key] = value
    end
end

-- Get option value
function ns.Options.GetOption(key)
    if BiSWishAddonDB.options then
        return BiSWishAddonDB.options[key]
    end
    return defaultOptions[key]
end

-- Create options panel
function ns.Options.CreateOptionsPanel()
    local frame = CreateFrame("Frame", "BiSWishOptionsFrame", UIParent)
    frame.name = "BiSWish"
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:Hide()
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("|cff39FF14BiSWishAddon|r Settings")
    
    -- Create tabs
    local tabFrame = CreateFrame("Frame", nil, frame)
    tabFrame:SetSize(580, 350)
    tabFrame:SetPoint("TOPLEFT", 10, -50)
    
    -- General tab
    local generalTab = CreateFrame("Frame", nil, tabFrame)
    generalTab:SetAllPoints()
    generalTab:Hide()
    
    ns.Options.CreateGeneralTab(generalTab)
    
    -- Show general tab by default
    generalTab:Show()
    
    frame.generalTab = generalTab
    
    return frame
end

-- Create general tab
function ns.Options.CreateGeneralTab(parent)
    local yOffset = -20
    
    -- Auto-open BiS Wishlist on boss kill in guild raid
    local autoOpenGuildCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    autoOpenGuildCheck:SetPoint("TOPLEFT", 20, yOffset)
    autoOpenGuildCheck:SetChecked(BiSWishAddonDB.options.autoOpenOnBossKill)
    autoOpenGuildCheck:SetScript("OnClick", function(self)
        ns.Options.SetOption("autoOpenOnBossKill", self:GetChecked())
    end)
    
    local autoOpenGuildLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoOpenGuildLabel:SetPoint("LEFT", autoOpenGuildCheck, "RIGHT", 5, 0)
    autoOpenGuildLabel:SetText("Auto-open BiS Wishlist on boss kill in guild raid")
    
    yOffset = yOffset - 30
    
    -- Guild raid threshold
    local thresholdLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    thresholdLabel:SetPoint("TOPLEFT", 20, yOffset)
    thresholdLabel:SetText("Guild raid threshold (%):")
    
    local thresholdSlider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    thresholdSlider:SetPoint("LEFT", thresholdLabel, "RIGHT", 10, 0)
    thresholdSlider:SetMinMaxValues(0.5, 1.0)
    thresholdSlider:SetValue(BiSWishAddonDB.options.guildRaidThreshold)
    thresholdSlider:SetValueStep(0.1)
    thresholdSlider:SetScript("OnValueChanged", function(self, value)
        ns.Options.SetOption("guildRaidThreshold", value)
    end)
end