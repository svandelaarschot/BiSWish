--[[
================================================================================
UI.lua - BiSWish Addon User Interface Module
================================================================================
This module handles all user interface components for the BiSWish addon including:
- Boss window and BiS list display
- Item drop popups and notifications
- Data management dialogs
- Icon resolution and item display
- Window management and styling

Author: BiSWish Development Team
Version: 1.0
================================================================================
--]]

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

-- Get addon namespace
local addonName, ns = ...

-- Create UI namespace
ns.UI = ns.UI or {}

-- ============================================================================
-- UI UTILITY FUNCTIONS
-- ============================================================================

--[[
    Create a footer for dialogs
    @param frame (Frame) - The frame to add the footer to
--]]
function ns.UI.CreateFooter(frame)
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 16, 16)
    footer:SetWidth(580)
    footer:SetJustifyH("LEFT")
    
    -- Get dynamic version from .toc file with fallback
    local version = "1.1"
    local author = "Alvarín-Silvermoon"
    
    -- Try to get metadata, but use fallbacks if it fails
    if GetAddOnMetadata then
        local addonName = "BiSWish"
        local metadataVersion = GetAddOnMetadata(addonName, "Version")
        local metadataAuthor = GetAddOnMetadata(addonName, "Author")
        
        if metadataVersion then
            version = metadataVersion
        end
        if metadataAuthor then
            author = metadataAuthor
        end
    end
    
    footer:SetText("|cff39FF14BiSWish|r - Best in Slot Wishlist Addon | Version " .. version .. " | by " .. author .. " | Use /bis help for commands")
    footer:SetTextColor(0.7, 0.7, 0.7)
end

-- ============================================================================
-- CONSTANTS AND HELPERS
-- ============================================================================
local PLACEHOLDER_ICON = "Interface\\Icons\\INV_Misc_Orb_01"

local function Trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function ClearChildren(frame)
    local kids = { frame:GetChildren() }
    for _, child in ipairs(kids) do
        child:Hide()
        child:SetParent(nil)
    end
end

------------------------------------------------------------
-- Icon resolving (ID-first, instant + async) + name fallback
------------------------------------------------------------
local function TryGetIconByIDInstant(itemID)
    if type(itemID) ~= "number" then return nil end
    -- Fast path: GetItemInfoInstant
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfoInstant(itemID)
    if icon and icon ~= 0 then return icon end
    -- API helper
    if C_Item and C_Item.GetItemIconByID then
        local icon2 = C_Item.GetItemIconByID(itemID)
        if icon2 and icon2 ~= 0 then return icon2 end
    end
    return nil
end

-- Resolve by ID with proper async; callback(icon|nil)
local function ResolveItemIconByID(itemID, callback)
    local icon = TryGetIconByIDInstant(itemID)
    if icon then
        callback(icon)
        return
    end

    -- Hint client to load
    if C_Item and C_Item.RequestLoadItemData then
        pcall(C_Item.RequestLoadItemData, itemID)
    end

    local ok, itemObj = pcall(Item.CreateFromItemID, Item, itemID)
    if ok and itemObj and itemObj.ContinueOnItemLoad then
        itemObj:ContinueOnItemLoad(function()
            callback(TryGetIconByIDInstant(itemID))
        end)
    else
        -- Very light fallback: single delayed retry
        C_Timer.After(0.25, function()
            callback(TryGetIconByIDInstant(itemID))
        end)
    end
end

-- Name-only fallback (when no reliable ID is available)
local function ResolveIconByName(name, callback)
    if not name or name == "" then callback(nil) return end
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(name)
    if icon and icon ~= 0 then
        callback(icon)
        return
    end
    -- Trigger server lookup + short retry chain
    GetItemInfo(name)
    C_Timer.After(0.25, function()
        local _, _, _, _, _, _, _, _, _, icon2 = GetItemInfo(name)
        callback(icon2)
    end)
end

-- Public: Synchronous best-effort (kept for compatibility)
-- item can be: itemID (number), itemLink (string), or itemName (string, cached)
-- Hardcoded icon matching based on item name patterns
function ns.UI.GetItemIconByName(itemName)
    if not itemName then return nil end
    
    local name = string.lower(itemName)
    
    -- Weapon patterns - Better, more specific icons
    if string.find(name, "sword") or string.find(name, "blade") or string.find(name, "sovereign") then
        return "Interface\\Icons\\INV_Sword_04"
    elseif string.find(name, "axe") then
        return "Interface\\Icons\\INV_Axe_02"
    elseif string.find(name, "mace") or string.find(name, "hammer") then
        return "Interface\\Icons\\INV_Mace_02"
    elseif string.find(name, "dagger") or string.find(name, "kris") then
        return "Interface\\Icons\\INV_Weapon_ShortBlade_02"
    elseif string.find(name, "staff") or string.find(name, "spire") then
        return "Interface\\Icons\\INV_Staff_02"
    elseif string.find(name, "bow") or string.find(name, "strandbow") then
        return "Interface\\Icons\\INV_Weapon_Bow_02"
    elseif string.find(name, "gun") or string.find(name, "rifle") then
        return "Interface\\Icons\\INV_Weapon_Rifle_02"
    elseif string.find(name, "wand") then
        return "Interface\\Icons\\INV_Wand_02"
    elseif string.find(name, "shield") then
        return "Interface\\Icons\\INV_Shield_02"
    
    -- Trinket patterns - Better trinket icons
    elseif string.find(name, "trinket") or string.find(name, "antenna") or string.find(name, "core") or string.find(name, "forge") or string.find(name, "silk") or string.find(name, "command") or string.find(name, "sky") or string.find(name, "netherprism") or string.find(name, "hunt") or string.find(name, "splicer") or string.find(name, "arcanocore") or string.find(name, "brand") or string.find(name, "ritual") or string.find(name, "oath") or string.find(name, "ward") or string.find(name, "screams") or string.find(name, "photon") or string.find(name, "voidglass") or string.find(name, "diamantine") or string.find(name, "unwavering") or string.find(name, "sigil") or string.find(name, "prodigious") or string.find(name, "lacerated") or string.find(name, "maw") or string.find(name, "vengeful") or string.find(name, "collapsing") or string.find(name, "eradicating") then
        return "Interface\\Icons\\INV_Misc_Orb_02"
    
    -- Armor patterns - Better armor icons
    elseif string.find(name, "helmet") or string.find(name, "helm") or string.find(name, "crown") then
        return "Interface\\Icons\\INV_Helmet_02"
    elseif string.find(name, "chest") or string.find(name, "robe") or string.find(name, "vest") then
        return "Interface\\Icons\\INV_Chest_Cloth_02"
    elseif string.find(name, "pants") or string.find(name, "leggings") or string.find(name, "breeches") then
        return "Interface\\Icons\\INV_Pants_Cloth_02"
    elseif string.find(name, "boots") or string.find(name, "shoes") or string.find(name, "slippers") then
        return "Interface\\Icons\\INV_Boots_Cloth_02"
    elseif string.find(name, "gloves") or string.find(name, "gauntlets") or string.find(name, "mitts") then
        return "Interface\\Icons\\INV_Gauntlets_02"
    elseif string.find(name, "bracers") or string.find(name, "bracelets") or string.find(name, "wrist") then
        return "Interface\\Icons\\INV_Bracer_02"
    elseif string.find(name, "belt") or string.find(name, "girdle") or string.find(name, "sash") then
        return "Interface\\Icons\\INV_Belt_02"
    elseif string.find(name, "cloak") or string.find(name, "cape") or string.find(name, "mantle") then
        return "Interface\\Icons\\INV_Misc_Cape_02"
    
    -- Ring patterns - Better ring icons
    elseif string.find(name, "ring") then
        return "Interface\\Icons\\INV_Jewelry_Ring_02"
    
    -- Neck patterns - Better necklace icons
    elseif string.find(name, "necklace") or string.find(name, "amulet") or string.find(name, "pendant") or string.find(name, "choker") then
        return "Interface\\Icons\\INV_Jewelry_Necklace_02"
    
    -- Off-hand patterns - Better off-hand icons
    elseif string.find(name, "off") or string.find(name, "tome") or string.find(name, "book") or string.find(name, "tome") then
        return "Interface\\Icons\\INV_Misc_Book_02"
    
    -- Generic fallbacks - Better generic icons
    elseif string.find(name, "weapon") then
        return "Interface\\Icons\\INV_Sword_02"
    elseif string.find(name, "armor") or string.find(name, "gear") then
        return "Interface\\Icons\\INV_Chest_Cloth_02"
    else
        return "Interface\\Icons\\INV_Misc_Gem_01"
    end
end

function ns.UI.TryGetItemIconSync(item)
    if type(item) == "number" then
        local icon = TryGetIconByIDInstant(item)
        if icon then return icon end
        local _, _, _, _, _, _, _, _, _, icon2 = GetItemInfo(item)
        if icon2 then return icon2 end
        return nil
    elseif type(item) == "string" then
        -- Link or name
        local _, _, _, _, _, _, _, _, _, icon = GetItemInfoInstant(item)
        if icon and icon ~= 0 then return icon end
        local _, _, _, _, _, _, _, _, _, icon2 = GetItemInfo(item)
        if icon2 and icon2 ~= 0 then return icon2 end
    end
    return nil
end

-- Public: Resolve icon smartly. Prefers ID; falls back to name.
-- input can be number (itemID) or string (name/link)
function ns.UI.ResolveItemIcon(input, callback)
    if type(input) == "number" then
        ResolveItemIconByID(input, function(icon)
            if icon then callback(icon) else callback(nil) end
        end)
    elseif type(input) == "string" then
        -- Try parse itemID from link like "item:19019"
        local id = tonumber(input:match("item:(%d+)") or "")
        if id then
            ResolveItemIconByID(id, function(icon)
                if icon then callback(icon) else ResolveIconByName(input, callback) end
            end)
        else
            ResolveIconByName(input, callback)
        end
    else
        callback(nil)
    end
end

------------------------------------------------------------
-- Footer
------------------------------------------------------------
function ns.UI.CreateFooter(parent)
    local footer = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOM", 0, 10)
    footer:SetText("Alvarín-Silvermoon - v2025")
    footer:SetTextColor(0.7, 0.7, 0.7)
    return footer
end

------------------------------------------------------------
-- Initialize UI
-- ============================================================================
-- UI SYSTEM INITIALIZATION
-- ============================================================================

--[[
    Initialize UI system
    Sets up all UI components and windows
--]]
function ns.UI.Initialize()
    ns.Core.DebugInfo("Initializing UI components...")
    ns.UI.CreateBossWindow()
    ns.UI.CreateDataWindow()
    ns.UI.CreateBiSListDialog()
    ns.UI.CreateTooltipHooks()
    -- Event frame ready for future boss-kill triggers
    if not ns.UI._eventFrame then
        ns.UI._eventFrame = CreateFrame("Frame")
        -- Example:
        -- ns.UI._eventFrame:RegisterEvent("ENCOUNTER_END")
        -- ns.UI._eventFrame:SetScript("OnEvent", function(_, event) if event=="ENCOUNTER_END" then ns.UI.CheckBossKillAutoOpen() end end)
    end
    ns.Core.DebugInfo("UI initialized!")
end

------------------------------------------------------------
-- Boss Window
------------------------------------------------------------
-- ============================================================================
-- WINDOW CREATION FUNCTIONS
-- ============================================================================

--[[
    Create the main boss window
    This is the primary window for displaying BiS data
--]]
function ns.UI.CreateBossWindow()
    local frame = CreateFrame("Frame", "BiSWishAddon_BossWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:Hide()
    
    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14BiS Wishlist|r")
    else
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("|cff39FF14BiS Wishlist|r")
        frame.title:SetJustifyH("CENTER")
        frame.title:SetWidth(550)
        frame.title:SetWordWrap(true)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 30)
    
    local content = CreateFrame("Frame")
    content:SetSize(520, 1)
    scrollFrame:SetScrollChild(content)
    
    frame.scrollFrame = scrollFrame
    frame.content = content
    
    ns.UI.CreateFooter(frame)
    ns.UI.bossWindow = frame
end

-- ============================================================================
-- WINDOW DISPLAY FUNCTIONS
-- ============================================================================

--[[
    Show the boss window
    @param bossName (string) - Name of the boss for display
--]]
function ns.UI.ShowBossWindow(bossName)
    ns.Core.DebugDebug("Showing boss window for: %s", bossName or "Manual View")
    if not ns.UI.bossWindow then
        ns.Core.DebugInfo("Creating boss window...")
        ns.UI.CreateBossWindow()
    end
    ns.UI.bossWindow:Show()
    
    -- Get guild name from options
    local guildName = ""
    if BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName and BiSWishAddonDB.options.guildRaidTeamName ~= "" then
        guildName = " [" .. BiSWishAddonDB.options.guildRaidTeamName .. "]"
    end
    
    ns.Core.DebugInfo("Boss Window - Guild name: '%s'", BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or "nil")
    
    local titleText = "BiS Wishlist - " .. (bossName or "Manual View") .. guildName
    if ns.UI.bossWindow.TitleText then
        ns.UI.bossWindow.TitleText:SetText(titleText)
    elseif ns.UI.bossWindow.title then
        ns.UI.bossWindow.title:SetText(titleText)
    end
    ns.UI.UpdateBossWindowContent()
end

function ns.UI.UpdateBossWindowContent()
    ns.Core.DebugDebug("Updating boss window content...")
    local frame = ns.UI.bossWindow
    if not frame then 
        ns.Core.DebugWarning("Boss window frame not found!")
        return 
    end
    local content = frame.content
    
    ClearChildren(content)
    
    local yOffset = -10
    local itemCount = 0
    
    if not BiSWishAddonDB or not BiSWishAddonDB.items then
        ns.Core.DebugInfo("No BiS data available")
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        return
    end

    -- Show up to 20 items to prevent overflow
    for itemID, data in pairs(BiSWishAddonDB.items) do
        if itemCount < 20 then
            local itemFrame = CreateFrame("Frame", nil, content)
            itemFrame:SetSize(520, 35)
            itemFrame:SetPoint("TOPLEFT", 10, yOffset)
            
            -- Add subtle background for better visual separation
            local rowBg = itemFrame:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)
            
            -- Icon with tooltip
            local iconTex = itemFrame:CreateTexture(nil, "OVERLAY")
            iconTex:SetSize(24, 24)
            iconTex:SetPoint("LEFT", 5, 0)
            iconTex:SetTexture(PLACEHOLDER_ICON)
            ns.UI.ResolveItemIcon(tonumber(itemID) or (data and data.name), function(icon)
                if icon and iconTex and iconTex.SetTexture then
                    iconTex:SetTexture(icon)
                end
            end)
            
            -- Add tooltip to icon
            iconTex:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("|cff39FF14" .. ((data and data.name) or "Unknown") .. "|r", 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffFFFF00Players wanting this item:|r", 1, 1, 0)
                for _, player in ipairs((data and data.players) or {}) do
                    GameTooltip:AddLine("• " .. player, 0.8, 0.8, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00FF00Total players: " .. tostring(#((data and data.players) or {})) .. "|r", 0, 1, 0)
                GameTooltip:Show()
            end)
            iconTex:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            -- Item name with enhanced styling
            local itemName = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            itemName:SetPoint("LEFT", 35, 0)
            itemName:SetText((data and data.name) or "Unknown Item")
            itemName:SetTextColor(1, 1, 0)
            itemName:SetWidth(200)
            itemName:SetJustifyH("LEFT")
            
            -- Add tooltip to item name
            itemName:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("|cff39FF14" .. ((data and data.name) or "Unknown") .. "|r", 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffFFFF00Players wanting this item:|r", 1, 1, 0)
                for _, player in ipairs((data and data.players) or {}) do
                    GameTooltip:AddLine("• " .. player, 0.8, 0.8, 1)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff00FF00Total players: " .. tostring(#((data and data.players) or {})) .. "|r", 0, 1, 0)
                GameTooltip:Show()
            end)
            itemName:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            -- Truncated player list with tooltip
            local playersList = (data and data.players) or {}
            local playerCount = #playersList
            local shortPlayersText = ""
            
            if playerCount > 0 then
                if playerCount <= 3 then
                    shortPlayersText = table.concat(playersList, ", ")
                else
                    shortPlayersText = table.concat(playersList, ", ", 1, 2) .. " +" .. (playerCount - 2) .. " more"
                end
            end
            
            local players = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            players:SetPoint("LEFT", 240, 0)
            players:SetText(shortPlayersText)
            players:SetTextColor(0.7, 0.7, 1)
            players:SetWidth(250)
            players:SetJustifyH("LEFT")
            
            -- Add tooltip to players text
            players:SetScript("OnEnter", function(self)
                if #playersList > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("|cff00FF00Players wanting this item (" .. playerCount .. "):|r", 1, 1, 1)
                    for i, playerName in ipairs(playersList) do
                        GameTooltip:AddLine("• " .. playerName, 1, 1, 1)
                    end
                    GameTooltip:Show()
                end
            end)
            
            players:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            -- Add hover effects to the row
            itemFrame:SetScript("OnEnter", function()
                rowBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
            end)
            itemFrame:SetScript("OnLeave", function()
                rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)
            end)
            
            yOffset = yOffset - 40
            itemCount = itemCount + 1
        end
    end
    
    if itemCount == 0 then
        ns.Core.DebugInfo("No items to display")
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
    else
        ns.Core.DebugDebug("Displayed %d items in boss window", itemCount)
    end

    if frame.scrollFrame then
        frame.scrollFrame:UpdateScrollChildRect()
        frame.scrollFrame:SetVerticalScroll(0)
    end
end

------------------------------------------------------------
-- Data Window
------------------------------------------------------------
--[[
    Create the data management window
    This window allows users to manage BiS data
--]]
function ns.UI.CreateDataWindow()
    local frame = CreateFrame("Frame", "BiSWishAddon_DataWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(650, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:Hide()
    
    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14BiS Data Management|r")
    else
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("|cff39FF14BiS Data Management|r")
        frame.title:SetJustifyH("CENTER")
        frame.title:SetWidth(550)
        frame.title:SetWordWrap(true)
    end

    local logo = frame:CreateTexture(nil, "OVERLAY")
    logo:SetTexture("Assets\\logo.ico")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", 10, -10)
    
    -- Create input container for better organization
    local inputContainer = CreateFrame("Frame", nil, frame)
    inputContainer:SetSize(610, 200)
    inputContainer:SetPoint("TOPLEFT", 20, -60)
    
    -- Item ID Row
    local itemIDLabel = inputContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemIDLabel:SetPoint("TOPLEFT", 0, 0)
    itemIDLabel:SetText("Item ID:")
    itemIDLabel:SetTextColor(1, 1, 1)
    itemIDLabel:SetWidth(100)
    itemIDLabel:SetJustifyH("LEFT")
    
    local itemIDEditBox = CreateFrame("EditBox", nil, inputContainer, "InputBoxTemplate")
    itemIDEditBox:SetSize(140, 30)
    itemIDEditBox:SetPoint("LEFT", itemIDLabel, "RIGHT", 10, 0)
    itemIDEditBox:SetAutoFocus(false)
    itemIDEditBox:SetTextInsets(8, 8, 0, 0)
    itemIDEditBox:SetFontObject("GameFontHighlight")
    
    -- Item Name Row
    local itemNameLabel = inputContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemNameLabel:SetPoint("TOPLEFT", 0, -40)
    itemNameLabel:SetText("Item Name:")
    itemNameLabel:SetTextColor(1, 1, 1)
    itemNameLabel:SetWidth(100)
    itemNameLabel:SetJustifyH("LEFT")
    
    local itemNameEditBox = CreateFrame("EditBox", nil, inputContainer, "InputBoxTemplate")
    itemNameEditBox:SetSize(250, 30)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 10, 0)
    itemNameEditBox:SetAutoFocus(false)
    itemNameEditBox:SetTextInsets(8, 8, 0, 0)
    itemNameEditBox:SetFontObject("GameFontHighlight")

    local searchItemButton = CreateFrame("Button", nil, inputContainer, "UIPanelButtonTemplate")
    searchItemButton:SetSize(90, 30)
    searchItemButton:SetPoint("LEFT", itemNameEditBox, "RIGHT", 10, 0)
    searchItemButton:SetText("Search")
    searchItemButton:SetScript("OnClick", function()
        ns.UI.ShowItemSearchDialog(itemNameEditBox)
    end)

    -- Players Row
    local playersLabel = inputContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playersLabel:SetPoint("TOPLEFT", 0, -80)
    playersLabel:SetText("Players:")
    playersLabel:SetTextColor(1, 1, 1)
    playersLabel:SetWidth(100)
    playersLabel:SetJustifyH("LEFT")
    
    local playersEditBox = CreateFrame("EditBox", nil, inputContainer, "InputBoxTemplate")
    playersEditBox:SetSize(350, 30)
    playersEditBox:SetPoint("LEFT", playersLabel, "RIGHT", 10, 0)
    playersEditBox:SetAutoFocus(false)
    playersEditBox:SetTextInsets(8, 8, 0, 0)
    playersEditBox:SetFontObject("GameFontHighlight")

    -- Description Row
    local descriptionLabel = inputContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    descriptionLabel:SetPoint("TOPLEFT", 0, -120)
    descriptionLabel:SetText("Description:")
    descriptionLabel:SetTextColor(1, 1, 1)
    descriptionLabel:SetWidth(100)
    descriptionLabel:SetJustifyH("LEFT")

    local descriptionEditBox = CreateFrame("EditBox", nil, inputContainer, "InputBoxTemplate")
    descriptionEditBox:SetSize(350, 30)
    descriptionEditBox:SetPoint("LEFT", descriptionLabel, "RIGHT", 10, 0)
    descriptionEditBox:SetAutoFocus(false)
    descriptionEditBox:SetTextInsets(8, 8, 0, 0)
    descriptionEditBox:SetFontObject("GameFontHighlight")

    -- Create button container for better organization
    local buttonContainer = CreateFrame("Frame", nil, frame)
    buttonContainer:SetSize(610, 100)
    buttonContainer:SetPoint("TOPLEFT", 20, -200)
    
    -- First row of buttons
    local addButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    addButton:SetSize(130, 35)
    addButton:SetPoint("TOPLEFT", 0, 0)
    addButton:SetText("Add Item")
    addButton:SetScript("OnClick", function()
        local itemID = tonumber(itemIDEditBox:GetText())
        local itemName = Trim(itemNameEditBox:GetText())
        local playersText = playersEditBox:GetText()
        local description = Trim(descriptionEditBox:GetText())
        
        if not itemID or not itemName or itemName == "" then
            ns.Core.DebugError("Please enter valid Item ID and Name")
            return
        end
        
        local players = {}
        if playersText and playersText ~= "" then
            for player in playersText:gmatch("[^,]+") do
                table.insert(players, Trim(player))
            end
        end
        
        if ns.Data and ns.Data.AddItem then
            ns.Data.AddItem(itemID, itemName, players, description)
        else
            BiSWishAddonDB.items[itemID] = { 
                name = itemName, 
                players = players,
                description = description or ""
            }
        end

        ns.Core.DebugInfo("Added item %s (ID: %d) with %d players", itemName, itemID, #players)

        itemIDEditBox:SetText("")
        itemNameEditBox:SetText("")
        playersEditBox:SetText("")
        descriptionEditBox:SetText("")
        
        ns.UI.UpdateDataWindowContent()
    end)
    
    local removeButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    removeButton:SetSize(130, 35)
    removeButton:SetPoint("LEFT", addButton, "RIGHT", 15, 0)
    removeButton:SetText("Remove")
    removeButton:SetScript("OnClick", function()
        local itemID = tonumber(itemIDEditBox:GetText())
        if not itemID then
            ns.Core.DebugError("Please enter valid Item ID")
            return
        end
        if BiSWishAddonDB.items[itemID] then
            local itemName = BiSWishAddonDB.items[itemID].name
            BiSWishAddonDB.items[itemID] = nil
            ns.Core.DebugInfo("Removed item %s (ID: %d)", itemName or "?", itemID)
            itemIDEditBox:SetText("")
            itemNameEditBox:SetText("")
            playersEditBox:SetText("")
            descriptionEditBox:SetText("")
            ns.UI.UpdateDataWindowContent()
        else
            ns.Core.DebugError("Item not found")
        end
    end)
    
    local clearDataButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    clearDataButton:SetSize(130, 35)
    clearDataButton:SetPoint("LEFT", removeButton, "RIGHT", 15, 0)
    clearDataButton:SetText("Clear Data")
    clearDataButton:SetScript("OnClick", function()
        BiSWishAddonDB.items = {}
        ns.Core.DebugInfo("Cleared all BiS data!")
        itemIDEditBox:SetText("")
        itemNameEditBox:SetText("")
        playersEditBox:SetText("")
        descriptionEditBox:SetText("")
        ns.UI.UpdateDataWindowContent()
    end)

    -- Second row of buttons
    local importButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    importButton:SetSize(130, 35)
    importButton:SetPoint("TOPLEFT", 0, -45)
    importButton:SetText("Import Data")
    importButton:SetScript("OnClick", function()
        ns.UI.ImportData()
    end)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -330)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 100)
    
    local content = CreateFrame("Frame")
    content:SetSize(590, 1) -- inner width ~ 590 (650 - 20 - 40)
    scrollFrame:SetScrollChild(content)
    
    frame.scrollFrame       = scrollFrame
    frame.content           = content
    frame.itemIDEditBox     = itemIDEditBox
    frame.itemNameEditBox   = itemNameEditBox
    frame.playersEditBox    = playersEditBox
    frame.descriptionEditBox= descriptionEditBox
    
    ns.UI.CreateFooter(frame)
    ns.UI.dataWindow = frame
end

function ns.UI.ShowDataWindow()
    if not ns.UI.dataWindow then
        ns.UI.CreateDataWindow()
    end
    
    -- Update title with guild name
    local guildName = ""
    if BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName and BiSWishAddonDB.options.guildRaidTeamName ~= "" then
        guildName = " [" .. BiSWishAddonDB.options.guildRaidTeamName .. "]"
    end
    
    ns.Core.DebugInfo("Data Window - Guild name: '%s'", BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName or "nil")
    
    local titleText = "|cff39FF14BiS Data Management|r" .. guildName
    if ns.UI.dataWindow.TitleText then
        ns.UI.dataWindow.TitleText:SetText(titleText)
    elseif ns.UI.dataWindow.title then
        ns.UI.dataWindow.title:SetText(titleText)
    end
    
    ns.UI.dataWindow:Show()
    ns.UI.UpdateDataWindowContent()
end

function ns.UI.UpdateDataWindowContent()
    local frame = ns.UI.dataWindow
    if not frame then return end
    local content = frame.content
    
    ClearChildren(content)

    if not BiSWishAddonDB or not BiSWishAddonDB.items then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        return
    end
    
    local yOffset = -10
    
    for itemID, data in pairs(BiSWishAddonDB.items) do
        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(590, 30) -- fit inner width
        itemFrame:SetPoint("TOPLEFT", 0, yOffset)
        
        local itemIcon = itemFrame:CreateTexture(nil, "OVERLAY")
        itemIcon:SetSize(24, 24)
        itemIcon:SetPoint("LEFT", 10, 0)
        itemIcon:SetTexture(PLACEHOLDER_ICON)

        -- Try to get icon by itemID first, then by name
        local iconTexture = nil
        if type(itemID) == "number" then
            local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if icon then iconTexture = icon end
        end
        
        if not iconTexture and data and data.name then
            local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.name)
            if icon then 
                iconTexture = icon 
            else
            end
        end
        
        if iconTexture then
            itemIcon:SetTexture(iconTexture)
        else
            itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", 40, 0)
        itemText:SetText((data and data.name) or "Unknown")
        itemText:SetTextColor(1, 1, 0)
        itemText:SetWidth(220)
        itemText:SetJustifyH("LEFT")

        local playersTextStr = table.concat((data and data.players) or {}, ", ")
        -- Truncate players text if too long
        if string.len(playersTextStr) > 25 then
            playersTextStr = string.sub(playersTextStr, 1, 22) .. "..."
        end
        local players = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        players:SetPoint("LEFT", 270, 0)
        players:SetText(playersTextStr)
        players:SetTextColor(0.8, 0.8, 0.8)
        players:SetWidth(200)
        players:SetJustifyH("LEFT")

        -- Description (position fixed to stay inside 590px)
        local description = (data and data.description) or ""
        local descriptionText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        descriptionText:SetPoint("LEFT", 480, 0)
        descriptionText:SetText(description)
        descriptionText:SetTextColor(0.6, 0.6, 0.6)
        descriptionText:SetWidth(100)
        descriptionText:SetJustifyH("LEFT")

        itemFrame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                if frame.itemIDEditBox then frame.itemIDEditBox:SetText(tostring(itemID)) end
                if frame.itemNameEditBox then frame.itemNameEditBox:SetText((data and data.name) or "") end
                if frame.playersEditBox then frame.playersEditBox:SetText(playersTextStr or "") end
                if frame.descriptionEditBox then frame.descriptionEditBox:SetText(description or "") end
            end
        end)
        
        yOffset = yOffset - 30
    end

    if frame.scrollFrame then
        frame.scrollFrame:UpdateScrollChildRect()
        frame.scrollFrame:SetVerticalScroll(0)
    end
end

------------------------------------------------------------
-- BiS List Dialog (main list with headers/search)
------------------------------------------------------------
--[[
    Create the BiS list dialog
    This dialog shows the complete BiS list with search functionality
--]]
function ns.UI.CreateBiSListDialog()
    local frame = CreateFrame("Frame", "BiSWishAddon_BiSListDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:Hide()
    
    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14BiS Wishlist|r")
    else
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("|cff39FF14BiS Wishlist|r")
        frame.title:SetJustifyH("CENTER")
        frame.title:SetWidth(750)
        frame.title:SetWordWrap(true)
    end
    
    -- Guild/Raid Team Name
    frame.guildName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.guildName:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.guildName:SetJustifyH("CENTER")
    frame.guildName:SetWidth(750)
    frame.guildName:SetWordWrap(true)
    frame.guildName:SetTextColor(0.8, 0.8, 0.8)
    
    -- Update guild name display function (global)
    function ns.UI.UpdateGuildNameDisplay()
        ns.Core.DebugDebug("UpdateGuildNameDisplay called")
        ns.Core.DebugDebug("biSListDialog exists: %s", tostring(ns.UI.biSListDialog ~= nil))
        
        if not ns.UI.biSListDialog then
            ns.Core.DebugError("UpdateGuildNameDisplay - biSListDialog not found")
            return
        end
        
        if not ns.UI.biSListDialog.guildName then
            ns.Core.DebugError("UpdateGuildNameDisplay - guildName frame not found")
            return
        end
        
        local guildName = (BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName) or ""
        ns.Core.DebugInfo("UpdateGuildNameDisplay - guildName: '%s'", tostring(guildName))
        if guildName and guildName ~= "" then
            ns.UI.biSListDialog.guildName:SetText("|cff39FF14Guild/Raid Team:|r " .. guildName)
            ns.UI.biSListDialog.guildName:Show()
            ns.Core.DebugInfo("Guild name displayed: %s", guildName)
        else
            ns.UI.biSListDialog.guildName:Hide()
            ns.Core.DebugInfo("Guild name hidden (empty)")
        end
    end
    
    -- Call immediately
    ns.UI.UpdateGuildNameDisplay()
    
    local searchContainer = CreateFrame("Frame", nil, frame)
    searchContainer:SetSize(760, 40)
    searchContainer:SetPoint("TOPLEFT", 20, -20)

    local searchLabel = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    searchLabel:SetPoint("LEFT", 0, 0)
    searchLabel:SetText("Search Player:")
    searchLabel:SetTextColor(1, 1, 1)

    local searchEditBox = CreateFrame("EditBox", nil, searchContainer, "InputBoxTemplate")
    searchEditBox:SetSize(250, 25)
    searchEditBox:SetPoint("LEFT", searchLabel, "RIGHT", 15, 0)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetTextInsets(8, 8, 0, 0)
    searchEditBox:SetFontObject("GameFontHighlight")
    searchEditBox:SetScript("OnTextChanged", function(self)
        ns.UI.FilterBiSList(self:GetText())
    end)
    
    local clearSearchButton = CreateFrame("Button", nil, searchContainer, "UIPanelButtonTemplate")
    clearSearchButton:SetSize(80, 25)
    clearSearchButton:SetPoint("LEFT", searchEditBox, "RIGHT", 10, 0)
    clearSearchButton:SetText("Clear")
    clearSearchButton:SetScript("OnClick", function()
        searchEditBox:SetText("")
        ns.UI.FilterBiSList("")
    end)
    
    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetSize(760, 35)
    headerFrame:SetPoint("TOPLEFT", 20, -60)
    
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local iconHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconHeader:SetPoint("LEFT", 10, 0)
    iconHeader:SetText(" ")
    iconHeader:SetTextColor(1, 1, 0)
    iconHeader:SetWidth(30)
    iconHeader:SetJustifyH("LEFT")

    local itemNameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemNameHeader:SetPoint("LEFT", 40, 0)
    itemNameHeader:SetText("Item Name")
    itemNameHeader:SetTextColor(1, 1, 0)
    itemNameHeader:SetWidth(220)
    itemNameHeader:SetJustifyH("LEFT")
    
     local playersHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
     playersHeader:SetPoint("LEFT", 270, 0)
    playersHeader:SetText("Players")
    playersHeader:SetTextColor(1, 1, 0)
     playersHeader:SetWidth(200)
     playersHeader:SetJustifyH("LEFT")

     local descriptionHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
     descriptionHeader:SetPoint("LEFT", 480, 0)
     descriptionHeader:SetText("Description")
     descriptionHeader:SetTextColor(1, 1, 0)
     descriptionHeader:SetWidth(180)
     descriptionHeader:SetJustifyH("LEFT")

    local countHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countHeader:SetPoint("LEFT", 670, 0)
    countHeader:SetText("Count")
    countHeader:SetTextColor(1, 1, 0)
    countHeader:SetWidth(50)
    countHeader:SetJustifyH("CENTER")
    countHeader:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -100)
    scrollFrame:SetPoint("BOTTOMRIGHT", -60, 65)
    
    local content = CreateFrame("Frame")
     content:SetSize(720, 1)
    scrollFrame:SetScrollChild(content)
    
    frame.scrollFrame = scrollFrame
    frame.content     = content
    frame.searchEditBox = searchEditBox
    
    ns.UI.CreateFooter(frame)
    ns.UI.biSListDialog = frame
end

function ns.UI.ShowBiSListDialog()
    if not ns.UI.biSListDialog then
        ns.UI.CreateBiSListDialog()
    end
    
    -- Update title with guild name
    local guildName = ""
    if BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName and BiSWishAddonDB.options.guildRaidTeamName ~= "" then
        guildName = " [" .. BiSWishAddonDB.options.guildRaidTeamName .. "]"
    end
    
    local titleText = "|cff39FF14BiS Wishlist|r" .. guildName
    if ns.UI.biSListDialog.TitleText then
        ns.UI.biSListDialog.TitleText:SetText(titleText)
    elseif ns.UI.biSListDialog.title then
        ns.UI.biSListDialog.title:SetText(titleText)
    end
    
    ns.UI.biSListDialog:Show()
    
    -- Update guild name display immediately
    if ns.UI.biSListDialog and ns.UI.biSListDialog.guildName then
        local guildName = (BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName) or ""
        ns.Core.DebugInfo("Guild name debug - '%s'", tostring(guildName))
        if guildName and guildName ~= "" then
            ns.UI.biSListDialog.guildName:SetText("|cff39FF14Guild/Raid Team:|r " .. guildName)
            ns.UI.biSListDialog.guildName:Show()
            ns.Core.DebugInfo("Showing guild name: %s", guildName)
        else
            ns.UI.biSListDialog.guildName:Hide()
            ns.Core.DebugInfo("Hiding guild name (empty)")
        end
    else
        ns.Core.DebugError("Guild name frame not found!")
    end
    
    -- Also call the UpdateGuildNameDisplay function
    ns.UI.UpdateGuildNameDisplay()
    
    -- Force update guild name display after a short delay to ensure options are loaded
    C_Timer.After(0.1, function()
        if ns.UI.biSListDialog and ns.UI.biSListDialog.guildName then
            local guildName = (BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName) or ""
            ns.Core.DebugInfo("BiS List Dialog - Guild name after delay: '%s'", guildName)
            if guildName and guildName ~= "" then
                ns.UI.biSListDialog.guildName:SetText("|cff39FF14Guild/Raid Team:|r " .. guildName)
                ns.UI.biSListDialog.guildName:Show()
                ns.Core.DebugInfo("BiS List Dialog - Guild name displayed: %s", guildName)
            else
                ns.UI.biSListDialog.guildName:Hide()
                ns.Core.DebugInfo("BiS List Dialog - Guild name hidden (empty)")
            end
        end
    end)
    
    -- Update the content
    ns.UI.UpdateBiSListContent()
end

function ns.UI.UpdateBiSListContent()
    local frame = ns.UI.biSListDialog
    if not frame then return end
    local content = frame.content
    
     content:Show()
     content:SetSize(720, 1)

    ClearChildren(content)
    
    local yOffset = -10
    local itemCount = 0
    
    if not BiSWishAddonDB or not BiSWishAddonDB.items then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        if frame.scrollFrame then
            frame.scrollFrame:UpdateScrollChildRect()
            frame.scrollFrame:SetVerticalScroll(0)
        end
        return
    end

    for itemID, data in pairs(BiSWishAddonDB.items) do
        local itemFrame = CreateFrame("Frame", nil, content)
         itemFrame:SetSize(700, 30)
        itemFrame:SetPoint("TOPLEFT", 10, yOffset)
        
        local itemIcon = itemFrame:CreateTexture(nil, "OVERLAY")
        itemIcon:SetSize(24, 24)
        itemIcon:SetPoint("LEFT", 10, 0)
        itemIcon:SetTexture(PLACEHOLDER_ICON)

        -- Try to get icon by itemID first, then by name
        local iconTexture = nil
        if type(itemID) == "number" then
            iconTexture = TryGetIconByIDInstant(itemID)
        end
        
        if not iconTexture and data and data.name then
            local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.name)
            if icon then 
                iconTexture = icon 
            end
        end
        
        if iconTexture then
            itemIcon:SetTexture(iconTexture)
        else
            itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        itemIcon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cff39FF14" .. ((data and data.name) or "Unknown") .. "|r", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFF00Players wanting this item:|r", 1, 1, 0)
            for _, player in ipairs((data and data.players) or {}) do
                GameTooltip:AddLine("• " .. player, 0.8, 0.8, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00FF00Total players: " .. tostring(#((data and data.players) or {})) .. "|r", 0, 1, 0)
            GameTooltip:Show()
        end)
        itemIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local itemNameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemNameText:SetPoint("LEFT", 40, 0)
        itemNameText:SetText((data and data.name) or "Unknown")
        itemNameText:SetTextColor(1, 1, 1)
        itemNameText:SetWidth(220)
        itemNameText:SetJustifyH("LEFT")

        itemNameText:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cff39FF14" .. ((data and data.name) or "Unknown") .. "|r", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFF00Players wanting this item:|r", 1, 1, 0)
            for _, player in ipairs((data and data.players) or {}) do
                GameTooltip:AddLine("• " .. player, 0.8, 0.8, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00FF00Total players: " .. tostring(#((data and data.players) or {})) .. "|r", 0, 1, 0)
            GameTooltip:Show()
        end)
        itemNameText:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Create a shorter player display with count
        local playersList = (data and data.players) or {}
        local playerCount = #playersList
        local shortPlayersText = ""
        
        if playerCount > 0 then
            if playerCount <= 3 then
                shortPlayersText = table.concat(playersList, ", ")
            else
                shortPlayersText = table.concat(playersList, ", ", 1, 2) .. " +" .. (playerCount - 2) .. " more"
            end
        end
        
        local playersTextWidget = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        playersTextWidget:SetPoint("LEFT", 270, 0)
        playersTextWidget:SetWidth(200)
        playersTextWidget:SetJustifyH("LEFT")
        playersTextWidget:SetTextColor(0.7, 0.7, 1)
        playersTextWidget:SetText(shortPlayersText)
        
        -- Add tooltip to players text
        playersTextWidget:SetScript("OnEnter", function(self)
            if #playersList > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("|cff00FF00Players wanting this item (" .. playerCount .. "):|r", 1, 1, 1)
                for i, playerName in ipairs(playersList) do
                    GameTooltip:AddLine("• " .. playerName, 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end)
        
        playersTextWidget:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

         -- Description
         local description = (data and data.description) or ""
         if description and #description > 50 then
             description = description:sub(1, 47) .. "..."
         end
         local descriptionText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
         descriptionText:SetPoint("LEFT", 480, 0)
         descriptionText:SetWidth(180)
         descriptionText:SetJustifyH("LEFT")
         descriptionText:SetTextColor(0.6, 0.6, 0.6)
         descriptionText:SetText(description)
         
         -- Tooltip for full description text
         descriptionText:SetScript("OnEnter", function(self)
             local fullDescription = (data and data.description) or ""
             if fullDescription and fullDescription ~= "" then
                 GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                 GameTooltip:ClearLines()
                 GameTooltip:SetText("|cff39FF14Description:|r", 1, 1, 1)
                 GameTooltip:AddLine(fullDescription, 0.8, 0.8, 0.8, true)
                 GameTooltip:Show()
             end
         end)
         descriptionText:SetScript("OnLeave", function()
             GameTooltip:Hide()
         end)

         local countText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
         countText:SetPoint("LEFT", 670, 0)
         countText:SetText(tostring(#((data and data.players) or {})))
         countText:SetTextColor(1, 1, 0)
         countText:SetWidth(50)
         countText:SetJustifyH("CENTER")
         countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        
        yOffset = yOffset - 30
        itemCount = itemCount + 1
    end
    
    if itemCount == 0 then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
    end

    if frame.scrollFrame then
        frame.scrollFrame:UpdateScrollChildRect()
        frame.scrollFrame:SetVerticalScroll(0)
    end
end

function ns.UI.FilterBiSList(searchText)
    local frame = ns.UI.biSListDialog
    if not frame then return end
    local content = frame.content
    
    content:Show()
    content:SetSize(720, 1)
    ClearChildren(content)
    
    local yOffset = -10
    local itemCount = 0
    local searchLower = (searchText or ""):lower()

    if not BiSWishAddonDB or not BiSWishAddonDB.items then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No BiS data available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        return
    end

    for itemID, data in pairs(BiSWishAddonDB.items) do
        local showItem = false
        if searchLower == "" then
            showItem = true
        else
            for _, player in ipairs((data and data.players) or {}) do
                if player:lower():find(searchLower) then
                    showItem = true
                    break
                end
            end
        end
        
        if showItem then
            local itemFrame = CreateFrame("Frame", nil, content)
            itemFrame:SetSize(700, 30)
            itemFrame:SetPoint("TOPLEFT", 10, yOffset)
            
            local rowBg = itemFrame:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)

            -- Item Icon
            local itemIcon = itemFrame:CreateTexture(nil, "OVERLAY")
            itemIcon:SetSize(24, 24)
            itemIcon:SetPoint("LEFT", 10, 0)
            
            -- Try to get icon by itemID first, then by name
            local iconTexture = nil
            if type(itemID) == "number" then
                iconTexture = TryGetIconByIDInstant(itemID)
            end
            
            if not iconTexture and data and data.name then
                local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.name)
                if icon then 
                    iconTexture = icon 
                end
            end
            
            if iconTexture then
                itemIcon:SetTexture(iconTexture)
            else
                itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Item Name
            local itemNameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            itemNameText:SetPoint("LEFT", 40, 0)
            itemNameText:SetText((data and data.name) or "Unknown")
            itemNameText:SetTextColor(1, 1, 1)
            itemNameText:SetWidth(220)
            itemNameText:SetJustifyH("LEFT")
            
            -- Players
            local playersText = ""
            for i, player in ipairs((data and data.players) or {}) do
                if i > 1 then playersText = playersText .. ", " end
                if player:lower():find(searchLower) and searchLower ~= "" then
                    playersText = playersText .. "|cffFFFF00" .. player .. "|r"
                else
                    playersText = playersText .. player
                end
            end
            
            -- Create a shorter player display with count
            local playersList = (data and data.players) or {}
            local playerCount = #playersList
            local shortPlayersText = ""
            
            if playerCount > 0 then
                if playerCount <= 3 then
                    shortPlayersText = table.concat(playersList, ", ")
                else
                    shortPlayersText = table.concat(playersList, ", ", 1, 2) .. " +" .. (playerCount - 2) .. " more"
                end
            end
            
            local playersTextWidget = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            playersTextWidget:SetPoint("LEFT", 270, 0)
            playersTextWidget:SetText(shortPlayersText)
            playersTextWidget:SetTextColor(0.7, 0.7, 1)
            playersTextWidget:SetWidth(200)
            playersTextWidget:SetJustifyH("LEFT")
            
            -- Add tooltip to players text
            playersTextWidget:SetScript("OnEnter", function(self)
                if #playersList > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("|cff00FF00Players wanting this item (" .. playerCount .. "):|r", 1, 1, 1)
                    for i, playerName in ipairs(playersList) do
                        GameTooltip:AddLine("• " .. playerName, 1, 1, 1)
                    end
                    GameTooltip:Show()
                end
            end)
            
            playersTextWidget:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            -- Description
            local description = (data and data.description) or ""
            if description and #description > 50 then 
                description = description:sub(1, 47) .. "..." 
            end
            
            local descriptionText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            descriptionText:SetPoint("LEFT", 480, 0)
            descriptionText:SetText(description)
            descriptionText:SetTextColor(0.8, 0.8, 0.8)
            descriptionText:SetWidth(180)
            descriptionText:SetJustifyH("LEFT")
            
            -- Description tooltip
            local fullDescription = (data and data.description) or ""
            if fullDescription and fullDescription ~= "" then
                descriptionText:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:ClearLines()
                    GameTooltip:SetText("|cff39FF14Description:|r", 1, 1, 1)
                    GameTooltip:AddLine(fullDescription, 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end)
                descriptionText:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
            
            -- Count
            local countText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            countText:SetPoint("LEFT", 670, 0)
            countText:SetText(tostring(#((data and data.players) or {})))
            countText:SetTextColor(1, 1, 0)
            countText:SetWidth(50)
            countText:SetJustifyH("CENTER")
            countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            
            itemFrame:SetScript("OnEnter", function()
                rowBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
            end)
            itemFrame:SetScript("OnLeave", function()
                rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)
            end)
            
            yOffset = yOffset - 30
            itemCount = itemCount + 1
        end
    end
    
    if itemCount == 0 then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDataText:SetPoint("CENTER", 0, 0)
        noDataText:SetText("No items found for: " .. (searchText or ""))
        noDataText:SetTextColor(0.7, 0.7, 0.7)
    end

    if frame.scrollFrame then
        frame.scrollFrame:UpdateScrollChildRect()
        frame.scrollFrame:SetVerticalScroll(0)
    end
end

------------------------------------------------------------
-- Tooltip Hooks (safe)
------------------------------------------------------------
--[[
    Create tooltip hooks
    Sets up tooltip functionality for UI elements
--]]
function ns.UI.CreateTooltipHooks()
    if ns.UI._tooltipHooked then return end
    ns.UI._tooltipHooked = true
        
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
        if not ns.Data or not ns.Data.GetItemIDFromLink or not ns.Data.GetItemData then return end
        local itemID = ns.Data.GetItemIDFromLink(link)
        if not itemID then return end
            local data = ns.Data.GetItemData(itemID)
        if data and (data.players and #data.players > 0) then
                self:AddLine(" ")
                self:AddLine("|cff39FF14BiS Wishlist:|r", 1, 1, 1)
                for _, player in ipairs(data.players) do
                    self:AddLine("• " .. player, 0.8, 0.8, 0.8)
                end
            self:Show()
        end
    end)
end

------------------------------------------------------------
-- Boss Kill Auto-Open (guild raid threshold)
------------------------------------------------------------
function ns.UI.CheckBossKillAutoOpen()
    if not (BiSWishAddonDB and BiSWishAddonDB.options and BiSWishAddonDB.options.autoOpenOnBossKill) then
        return
    end
    
    -- Check if we should disable all functionality in dungeons
    local disableInDungeons = BiSWishAddonDB.options and BiSWishAddonDB.options.disableInDungeons
    if disableInDungeons then
        local inInstance, instanceType = IsInInstance()
        if instanceType == "party" then
            -- We're in a dungeon, don't auto-open
            ns.Core.DebugInfo("Dungeon detected, skipping guild raid auto-open")
            return
        end
    end
    
    if not IsInRaid() then return end

    local myGuild = GetGuildInfo("player")
    if not myGuild then return end

    local total = GetNumGroupMembers()
    if total == 0 then return end

    local guildCount = 0
    for i = 1, total do
        local unit = "raid"..i
        if UnitExists(unit) then
            local g = GetGuildInfo(unit)
            if g == myGuild then
                guildCount = guildCount + 1
            end
        end
    end

    local threshold = BiSWishAddonDB.options.guildRaidThreshold or 0.8
    if (guildCount / total) >= threshold then
        ns.UI.ShowBiSListDialog()
        print("|cff39FF14BiSWish|r: Guild raid detected! Opening BiS Wishlist...")
    end
end

------------------------------------------------------------
-- Item Search Dialog (reads from BiSWishAddonDB.items)
------------------------------------------------------------
function ns.UI.ShowItemSearchDialog(targetEditBox)
    if ns.UI.itemSearchDialog then
        ns.UI.itemSearchDialog:Show()
        return
    end

    local frame = CreateFrame("Frame", "BiSWishAddon_ItemSearchDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)

    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14Item Search|r")
    else
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("|cff39FF14Item Search|r")
        title:SetJustifyH("CENTER")
        title:SetWidth(650)
        title:SetWordWrap(true)
    end

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("TOPLEFT", 20, -40)
    searchLabel:SetText("Search for item:")
    searchLabel:SetTextColor(1, 1, 1)

    local searchEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchEditBox:SetSize(350, 30)
    searchEditBox:SetPoint("LEFT", searchLabel, "RIGHT", 15, 0)
    searchEditBox:SetAutoFocus(false)
    searchEditBox:SetTextInsets(8, 8, 0, 0)
    searchEditBox:SetFontObject("GameFontHighlight")
    searchEditBox:SetScript("OnEnterPressed", function()
        ns.UI.SearchItems(searchEditBox:GetText(), frame.content)
    end)

    local searchButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    searchButton:SetSize(90, 30)
    searchButton:SetPoint("LEFT", searchEditBox, "RIGHT", 15, 0)
    searchButton:SetText("Search")
    searchButton:SetScript("OnClick", function()
        ns.UI.SearchItems(searchEditBox:GetText(), frame.content)
    end)

    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 30)
    clearButton:SetPoint("LEFT", searchButton, "RIGHT", 10, 0)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        searchEditBox:SetText("")
        ns.UI.ClearItemSearch(frame.content)
    end)

    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instructions:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -10)
    instructions:SetWidth(650)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Type part of an item name to search. Click on an item to select it.")
    instructions:SetTextColor(0.8, 0.8, 0.8)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -120)
    
    -- Use configurable height for the dropdown
    local dropdownHeight = BiSWishAddonDB.options and BiSWishAddonDB.options.itemDropdownHeight or 200
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 60)
    scrollFrame:SetHeight(dropdownHeight)

    local content = CreateFrame("Frame")
    content:SetSize(640, 1)
    scrollFrame:SetScrollChild(content)

    frame.scrollFrame   = scrollFrame
    frame.content       = content
    frame.searchEditBox = searchEditBox
    frame.targetEditBox = targetEditBox

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)

    ns.UI.CreateFooter(frame)
    ns.UI.itemSearchDialog = frame
end

-- Search through Blizzard's item database
function ns.UI.SearchItems(searchText, content)
    if not searchText or searchText == "" then
        ns.UI.ClearItemSearch(content)
        return
    end

    ClearChildren(content)

    local yOffset = -10
    local shown = 0
    local limit = 200  -- hard cap to keep UI responsive
    local searchLower = searchText:lower()
    
    -- Show loading message
    local loadingText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    loadingText:SetPoint("CENTER", 0, 0)
    loadingText:SetText("Searching Blizzard item database...")
    loadingText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Use a more efficient approach - search through a curated list of common items
    C_Timer.After(0.1, function()
        ClearChildren(content)
        
        local yOffset = -10
        local shown = 0
        local limit = 50
        
        -- Use a curated list of common item IDs that are likely to be searched for
        -- This is much more efficient than searching through thousands of IDs
        local commonItemIDs = {
            -- Common consumables
            118, 858, 929, 1710, 3827, 6149, 13446, 13444, 20079, 20080, 20081, 20082, 20083, 20084, 20085,
            -- Common equipment (various levels)
            6948, 6949, 6950, 6951, 6952, 6953, 6954, 6955, 6956, 6957, 6958, 6959, 6960, 6961, 6962,
            -- More common items
            10018, 10019, 10020, 10021, 10022, 10023, 10024, 10025, 10026, 10027, 10028, 10029, 10030,
            -- Add more common item IDs here as needed
        }
        
        -- Search through the curated list
        for _, itemID in ipairs(commonItemIDs) do
            if shown >= limit then break end
            
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID = GetItemInfo(itemID)
            
            if itemName and itemName:lower():find(searchLower, 1, true) then
                local itemFrame = CreateFrame("Frame", nil, content)
                itemFrame:SetSize(600, 30)
                itemFrame:SetPoint("TOPLEFT", 0, yOffset)
                
                -- Item icon
                local itemIcon = itemFrame:CreateTexture(nil, "OVERLAY")
                itemIcon:SetSize(24, 24)
                itemIcon:SetPoint("LEFT", 10, 0)
                itemIcon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
                
                -- Item name with rarity color
                local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                itemText:SetPoint("LEFT", 40, 0)
                itemText:SetText(itemName)
                itemText:SetWidth(400)
                itemText:SetJustifyH("LEFT")
                
                -- Set rarity color
                local rarityColor = ITEM_QUALITY_COLORS[itemRarity or 0]
                if rarityColor then
                    itemText:SetTextColor(rarityColor.r, rarityColor.g, rarityColor.b)
                else
                    itemText:SetTextColor(1, 1, 1)
                end
                
                -- Item level and type
                local itemInfo = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                itemInfo:SetPoint("LEFT", 450, 0)
                itemInfo:SetText("Lvl " .. (itemLevel or "?") .. " " .. (itemType or ""))
                itemInfo:SetTextColor(0.7, 0.7, 0.7)
                itemInfo:SetWidth(150)
                itemInfo:SetJustifyH("LEFT")
                
                -- Click to select
                itemFrame:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" and ns.UI.itemSearchDialog and ns.UI.itemSearchDialog.targetEditBox then
                        ns.UI.itemSearchDialog.targetEditBox:SetText(itemName)
                        ns.UI.itemSearchDialog:Hide()
                    end
                end)
                
                -- Hover effect
                itemFrame:SetScript("OnEnter", function()
                    itemFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
                end)
                itemFrame:SetScript("OnLeave", function()
                    itemFrame:SetBackdropColor(0, 0, 0, 0)
                end)
                
                yOffset = yOffset - 35
                shown = shown + 1
            end
        end
        
        if shown == 0 then
            local noResultsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noResultsText:SetPoint("CENTER", 0, 0)
            noResultsText:SetText("No items found matching: " .. searchText .. "\n\nNote: This searches through a curated list of common items.\nFor a complete search, use the in-game item database.")
            noResultsText:SetTextColor(0.7, 0.7, 0.7)
        end
    end)
end

function ns.UI.ClearItemSearch(content)
    ClearChildren(content)
    local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noDataText:SetPoint("CENTER", 0, 0)
    noDataText:SetText("Enter search term to find items")
    noDataText:SetTextColor(0.7, 0.7, 0.7)

    local parentScroll = content:GetParent()
    if parentScroll and parentScroll.UpdateScrollChildRect then
        parentScroll:UpdateScrollChildRect()
        parentScroll:SetVerticalScroll(0)
    end
end

-- Import data from CSV
function ns.UI.ImportData()
    ns.UI.ShowCSVImportDialog()
end

-- Show CSV import dialog
function ns.UI.ShowCSVImportDialog()
    -- Create dialog if it doesn't exist
    if not ns.UI.csvImportDialog then
        local frame = CreateFrame("Frame", "BiSWishCSVImportDialog", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(700, 500)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetFrameStrata("DIALOG")
        frame:Hide()
        
        -- Store reference
        ns.UI.csvImportDialog = frame
        
        -- Create all UI elements here (moved from below)
        -- Title
        if frame.TitleText then
            frame.TitleText:SetText("|cff39FF14CSV Import|r")
        end

        -- Instructions
        local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        instructions:SetPoint("TOPLEFT", 20, -50)
        instructions:SetWidth(560)
        instructions:SetJustifyH("LEFT")
        instructions:SetText("Paste your CSV data below. Format: Player,Trinket 1,Trinket 2,Weapon 1,Weapon 2,Description")

        -- Text Label
        local textLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textLabel:SetPoint("TOPLEFT", 20, -80)
        textLabel:SetText("CSV Data:")

        -- Scroll Frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 20, -110)
        scrollFrame:SetPoint("BOTTOMRIGHT", -40, 80) -- More space for scrollbar

        -- Text Edit Box with proper multi-line support
        local textEditBox = CreateFrame("EditBox", nil, scrollFrame)
        textEditBox:SetSize(600, 300) -- Smaller to fit within frame
        textEditBox:SetMultiLine(true)
        textEditBox:SetAutoFocus(true)
        textEditBox:SetTextInsets(10, 10, 10, 10)
        textEditBox:SetFontObject("GameFontHighlight")
        textEditBox:SetJustifyH("LEFT")
        textEditBox:SetJustifyV("TOP")
        textEditBox:SetMaxLetters(0) -- No limit
        textEditBox:SetScript("OnTextChanged", function(self)
            self:GetParent():UpdateScrollChildRect()
        end)
        textEditBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText(0, 0)
        end)
        textEditBox:SetScript("OnEditFocusLost", function(self)
            self:HighlightText(0, 0)
        end)
        scrollFrame:SetScrollChild(textEditBox)

        -- Import Players Button
        local importPlayersButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        importPlayersButton:SetSize(120, 30)
        importPlayersButton:SetPoint("BOTTOMRIGHT", -20, 20)
        importPlayersButton:SetText("Import Players")
        importPlayersButton:SetScript("OnClick", function()
            local data = textEditBox:GetText()
            if data and data ~= "" then
                ns.UI.ProcessCSVImport(data)
                frame:Hide()
            else
                print("|cffFF0000BiSWishAddon|r: No data to import!")
            end
        end)
        
        -- Import Loot Items Button
        local importLootButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        importLootButton:SetSize(120, 30)
        importLootButton:SetPoint("RIGHT", importPlayersButton, "LEFT", -10, 0)
        importLootButton:SetText("Import Loot")
        importLootButton:SetScript("OnClick", function()
            local data = textEditBox:GetText()
            if data and data ~= "" then
                ns.UI.ProcessLootImport(data)
                frame:Hide()
            else
                print("|cffFF0000BiSWishAddon|r: No data to import!")
            end
        end)
        
        -- Link Players to Loot Button
        local linkButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        linkButton:SetSize(120, 30)
        linkButton:SetPoint("RIGHT", importLootButton, "LEFT", -10, 0)
        linkButton:SetText("Link Players")
        linkButton:SetScript("OnClick", function()
            local data = textEditBox:GetText()
            if data and data ~= "" then
                ns.UI.ProcessPlayerLootLink(data)
                frame:Hide()
            else
                print("|cffFF0000BiSWishAddon|r: No data to link!")
            end
        end)

        
        -- Clear Button
        local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        clearButton:SetSize(80, 30)
        clearButton:SetPoint("RIGHT", linkButton, "LEFT", -10, 0)
        clearButton:SetText("Clear")
        clearButton:SetScript("OnClick", function()
            textEditBox:SetText("")
        end)
        
        -- Footer
        ns.UI.CreateFooter(frame)
    end
    
    -- Just show the existing dialog
    ns.UI.csvImportDialog:Show()
end

-- Test item drop popup
function ns.UI.TestItemDropPopup()
    -- Simulate multiple dropped items
    local testItems = {
        {
            name = "Brand of Ceaseless Ire",
            link = "|cffa335ee|Hitem:242401::::::::80:::::::|h[Brand of Ceaseless Ire]|h|r",
            players = {"Player1", "Player2", "Player3"}
        },
        {
            name = "Astral Antenna",
            link = "|cffa335ee|Hitem:242395::::::::80:::::::|h[Astral Antenna]|h|r",
            players = {"Player4", "Player5"}
        },
        {
            name = "Voidglass Spire",
            link = "|cffa335ee|Hitem:237730::::::::80:::::::|h[Voidglass Spire]|h|r",
            players = {"Player6", "Player7", "Player8", "Player9"}
        }
    }
    
    print("|cff39FF14BiSWishAddon|r: Testing item drop popup for " .. #testItems .. " items")
    ns.UI.ShowItemDropPopup(testItems)
end

-- Show item drop popup for multiple items
function ns.UI.ShowItemDropPopup(items)
    if ns.UI.itemDropPopup then
        ns.UI.itemDropPopup:Hide()
    end
    
    local frame = CreateFrame("Frame", "BiSWishAddon_ItemDropPopup", UIParent, "BasicFrameTemplateWithInset")
    
    -- Use configurable height for the popup
    local dropdownHeight = BiSWishAddonDB.options and BiSWishAddonDB.options.itemDropdownHeight or 200
    local popupHeight = math.max(180, dropdownHeight + 80) -- Add extra space for title and buttons
    frame:SetSize(350, popupHeight)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    
    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14Items Dropped!|r")
    else
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("|cff39FF14Items Dropped!|r")
        title:SetJustifyH("CENTER")
        title:SetWidth(320)
        title:SetWordWrap(true)
    end
    
    -- Scroll frame for items list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(280, dropdownHeight)
    scrollFrame:SetPoint("TOPLEFT", 15, -40)
    
    -- Items content frame
    local itemsContent = CreateFrame("Frame", nil, scrollFrame)
    itemsContent:SetSize(260, 1)
    scrollFrame:SetScrollChild(itemsContent)
    
    local yOffset = -10
    local itemCount = 0
    
    for _, itemData in ipairs(items) do
        local itemName = itemData.name
        local itemLink = itemData.link
        local interestedPlayers = itemData.players
        
        if itemName and #interestedPlayers > 0 then
            itemCount = itemCount + 1
            
            -- Item container
            local itemContainer = CreateFrame("Frame", nil, itemsContent)
            itemContainer:SetSize(260, 35)
            itemContainer:SetPoint("TOPLEFT", 5, yOffset)
            
            -- Item icon
            local itemIcon = itemContainer:CreateTexture(nil, "OVERLAY")
            itemIcon:SetSize(28, 28)
            itemIcon:SetPoint("LEFT", 10, 0)
            
            -- Try to get item icon
            local itemID = nil
            local icon = nil
            
            -- First try to get itemID from itemLink if available
            if itemLink then
                itemID = tonumber(string.match(itemLink, "item:(%d+)"))
            end
            
            -- Try to get icon by itemID first
            if itemID then
                local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                if itemIcon then
                    icon = itemIcon
                end
            end
            
            -- Fallback to item name
            if not icon then
                local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemName)
                if itemIcon then
                    icon = itemIcon
                end
            end
            
            -- Set the icon
            if icon then
                itemIcon:SetTexture(icon)
            else
                itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Item info
            local itemInfo = itemContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            itemInfo:SetPoint("LEFT", itemIcon, "RIGHT", 12, 0)
            itemInfo:SetJustifyH("LEFT")
            itemInfo:SetWidth(175)
            itemInfo:SetWordWrap(true)
            itemInfo:SetText("|cffFFD700" .. itemName .. "|r")
            
            -- Players count
            local playersCount = itemContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            playersCount:SetPoint("RIGHT", -25, 0)
            playersCount:SetJustifyH("RIGHT")
            playersCount:SetWidth(50)
            playersCount:SetText("|cff39FF14" .. #interestedPlayers .. "|r")
            
            -- Add tooltip to player count
            playersCount:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Interested Players:", 1, 1, 1)
                for i, playerName in ipairs(interestedPlayers) do
                    GameTooltip:AddLine("• " .. playerName, 1, 1, 1)
                end
                GameTooltip:Show()
            end)
            
            playersCount:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            -- Add tooltip to icon
            itemIcon:SetScript("OnEnter", function(self)
                if itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(itemLink)
                    GameTooltip:Show()
                end
            end)
            
            itemIcon:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            yOffset = yOffset - 40
        end
    end
    
    -- Update scroll frame
    itemsContent:SetSize(300, math.max(100, itemCount * 40 + 20))
    scrollFrame:UpdateScrollChildRect()
    
    -- No close button - auto-close only
    
    -- Auto-close after 30 seconds (configurable)
    local autoCloseTime = BiSWishAddonDB.options.autoCloseTime or 30
    C_Timer.After(autoCloseTime, function()
        if frame and frame:IsVisible() then
            frame:Hide()
        end
    end)
    
    -- Footer
    ns.UI.CreateFooter(frame)
    
    frame:Show()
    ns.UI.itemDropPopup = frame
end

-- Legacy function for single item (backward compatibility)
function ns.UI.ShowItemDropPopupLegacy(itemName, itemLink, interestedPlayers)
    if ns.UI.itemDropPopup then
        ns.UI.itemDropPopup:Hide()
    end
    
    local frame = CreateFrame("Frame", "BiSWishAddon_ItemDropPopup", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(350, 180)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    
    if frame.TitleText then
        frame.TitleText:SetText("|cff39FF14Item Dropped!|r")
    else
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("|cff39FF14Item Dropped!|r")
        title:SetJustifyH("CENTER")
        title:SetWidth(320)
        title:SetWordWrap(true)
    end
    
    -- Item container for centering
    local itemContainer = CreateFrame("Frame", nil, frame)
    itemContainer:SetSize(320, 35)
    itemContainer:SetPoint("TOP", 0, -40)
    
    -- Item icon
    local itemIcon = itemContainer:CreateTexture(nil, "OVERLAY")
    itemIcon:SetSize(28, 28)
    itemIcon:SetPoint("LEFT", 10, 0)
    
    -- Try to get item icon
    local itemID = nil
    local icon = nil
    
    -- First try to get itemID from itemLink if available
    if itemLink then
        itemID = tonumber(string.match(itemLink, "item:(%d+)"))
    end
    
    -- Try to get icon by itemID first
    if itemID then
        local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        if itemIcon then
            icon = itemIcon
        end
    end
    
    -- Fallback to item name
    if not icon then
        local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemName)
        if itemIcon then
            icon = itemIcon
        end
    end
    
    -- Set the icon
    if icon then
        itemIcon:SetTexture(icon)
        print("|cff39FF14BiSWishAddon|r: Item icon loaded: " .. icon)
    else
        itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        print("|cff39FF14BiSWishAddon|r: Using fallback icon for: " .. itemName)
    end
    
    -- Item info
    local itemInfo = itemContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemInfo:SetPoint("LEFT", itemIcon, "RIGHT", 12, 0)
    itemInfo:SetJustifyH("LEFT")
    itemInfo:SetWidth(260)
    itemInfo:SetWordWrap(true)
    itemInfo:SetText("|cffFFD700" .. itemName .. "|r")
    
    -- Add tooltip to icon
    itemIcon:SetScript("OnEnter", function(self)
        if itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end
    end)
    
    itemIcon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Interested players label
    local playersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playersLabel:SetPoint("TOP", itemContainer, "BOTTOM", 0, -8)
    playersLabel:SetText("|cff39FF14Interested Players:|r")
    playersLabel:SetJustifyH("CENTER")
    playersLabel:SetWidth(320)
    
    -- Scroll frame for players list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 60)
    scrollFrame:SetPoint("TOP", playersLabel, "BOTTOM", 0, -3)
    
    -- Players content frame
    local playersContent = CreateFrame("Frame", nil, scrollFrame)
    playersContent:SetSize(280, 1)
    scrollFrame:SetScrollChild(playersContent)
    
    -- Players list
    local playersText = table.concat(interestedPlayers, ", ")
    local playersList = playersContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playersList:SetPoint("TOPLEFT", 10, 0)
    playersList:SetJustifyH("LEFT")
    playersList:SetWidth(260)
    playersList:SetWordWrap(true)
    playersList:SetText(playersText)
    
    -- Update scroll frame
    playersContent:SetSize(280, playersList:GetStringHeight() + 5)
    scrollFrame:UpdateScrollChildRect()
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 30)
    closeButton:SetPoint("BOTTOM", 0, 20)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Auto-close after 10 seconds
    C_Timer.After(10, function()
        if frame and frame:IsVisible() then
            frame:Hide()
        end
    end)
    
    -- Footer
    ns.UI.CreateFooter(frame)
    
    frame:Show()
    ns.UI.itemDropPopup = frame
end

-- Process Player-Loot Link (Player, Item Name, Item Name, ... format)
function ns.UI.ProcessPlayerLootLink(data)
    local lines = {}
    for line in data:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local linkedCount = 0

    -- Skip header line
    for i = 2, #lines do
        local line = lines[i]
        if line and line ~= "" then
            local parts = {}
            for part in line:gmatch("[^,]+") do
                table.insert(parts, Trim(part))
            end

            if #parts >= 2 then
                local playerName = parts[1]
                local items = {}
                
                -- Get all items for this player (skip first column which is player name)
                for j = 2, #parts do
                    local itemName = Trim(parts[j])
                    if itemName and itemName ~= "" and itemName ~= "Leeg" then
                        table.insert(items, itemName)
                    end
                end
                
                -- Link each item to this player
                for _, itemName in ipairs(items) do
                    -- Find existing item by name
                    for itemID, itemData in pairs(BiSWishAddonDB.items) do
                        if itemData.name == itemName then
                            -- Add player to item if not already present
                            local playerExists = false
                            for _, existingPlayer in ipairs(itemData.players) do
                                if existingPlayer == playerName then
                                    playerExists = true
                                    break
                                end
                            end
                            
                            if not playerExists then
                                table.insert(itemData.players, playerName)
                                linkedCount = linkedCount + 1
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    print("|cff39FF14BiSWishAddon|r: Linked " .. linkedCount .. " player-item connections!")

    -- Refresh the data window
    if ns.UI.dataWindow then
        ns.UI.UpdateDataWindowContent()
    end
end

-- Process Loot Import (Item ID, Item Name, Players format)
function ns.UI.ProcessLootImport(data)
    local lines = {}
    for line in data:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local importedCount = 0
    local itemMap = {}

    -- Skip header line
    for i = 2, #lines do
        local line = lines[i]
        if line and line ~= "" then
            local parts = {}
            for part in line:gmatch("[^,]+") do
                table.insert(parts, Trim(part))
            end

            if #parts >= 2 then
                local itemID = tonumber(parts[1])
                local itemName = parts[2]
                local players = parts[3] or ""
                
                if itemID and itemName and itemName ~= "" then
                    -- Parse players (comma-separated)
                    local playerList = {}
                    if players and players ~= "" then
                        for player in players:gmatch("[^,]+") do
                            table.insert(playerList, Trim(player))
                        end
                    end
                    
                    -- Store item with real Blizzard item ID
                    BiSWishAddonDB.items[itemID] = {
                        name = itemName,
                        players = playerList,
                        description = ""
                    }
                    importedCount = importedCount + 1
                end
            end
        end
    end

    print("|cff39FF14BiSWishAddon|r: Imported " .. importedCount .. " loot items with real Blizzard IDs!")

    -- Refresh the data window
    if ns.UI.dataWindow then
        ns.UI.UpdateDataWindowContent()
    end
end

-- Process CSV import
function ns.UI.ProcessCSVImport(data)
    local lines = {}
    for line in data:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local importedCount = 0
    local itemMap = {}

    -- Skip header line
    for i = 2, #lines do
        local line = lines[i]
        if line and line ~= "" then
            local parts = {}
            for part in line:gmatch("[^,]+") do
                table.insert(parts, Trim(part))
            end

            if #parts >= 2 then
                local playerName = parts[1]
                local description = parts[6] or "" -- Description column
                local items = {}

                -- Get all items (Trinket 1, Trinket 2, Weapon 1, Weapon 2)
                for j = 2, 5 do
                    if parts[j] and parts[j] ~= "" and parts[j] ~= "Leeg" and parts[j] ~= "Vul in" then
                        table.insert(items, parts[j])
                    end
                end

                -- Add player to each item
                for _, itemName in ipairs(items) do
                    if not itemMap[itemName] then
                        itemMap[itemName] = { players = {}, description = description }
                    end
                    table.insert(itemMap[itemName].players, playerName)
                end
            end
        end
    end

    -- Create items from the map
    for itemName, data in pairs(itemMap) do
        local itemID = 400000 + importedCount + 1
        BiSWishAddonDB.items[itemID] = {
            name = itemName,
            players = data.players,
            description = data.description or ""
        }
        importedCount = importedCount + 1
    end

    print("|cff39FF14BiSWishAddon|r: Imported " .. importedCount .. " items from CSV data!")

    -- Refresh the data window
    if ns.UI.dataWindow then
        ns.UI.UpdateDataWindowContent()
    end
end
