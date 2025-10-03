-- BiSWishAddon UI Module (refactored, ID-first icon resolve, no hardcoded datasets)
local addonName, ns = ...

-- Namespaces
ns.UI = ns.UI or {}

------------------------------------------------------------
-- Helpers / Constants
------------------------------------------------------------
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
------------------------------------------------------------
function ns.UI.Initialize()
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
    print("|cff39FF14BiSWishAddon|r: UI initialized!")
end

------------------------------------------------------------
-- Boss Window
------------------------------------------------------------
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

function ns.UI.ShowBossWindow(bossName)
    if not ns.UI.bossWindow then
        ns.UI.CreateBossWindow()
    end
    ns.UI.bossWindow:Show()
    local titleText = "BiS Wishlist - " .. (bossName or "Manual View")
    if ns.UI.bossWindow.TitleText then
        ns.UI.bossWindow.TitleText:SetText(titleText)
    elseif ns.UI.bossWindow.title then
        ns.UI.bossWindow.title:SetText(titleText)
    end
    ns.UI.UpdateBossWindowContent()
end

function ns.UI.UpdateBossWindowContent()
    local frame = ns.UI.bossWindow
    if not frame then return end
    local content = frame.content
    
    ClearChildren(content)
    
    local yOffset = -10
    local itemCount = 0
    
    if not BiSWishAddonDB or not BiSWishAddonDB.items then
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
            itemFrame:SetSize(520, 30)
            itemFrame:SetPoint("TOPLEFT", 10, yOffset)
            
            -- Icon (nice touch for the boss view as well)
            local iconTex = itemFrame:CreateTexture(nil, "OVERLAY")
            iconTex:SetSize(20, 20)
            iconTex:SetPoint("LEFT", 0, 0)
            iconTex:SetTexture(PLACEHOLDER_ICON)
            ns.UI.ResolveItemIcon(tonumber(itemID) or (data and data.name), function(icon)
                if icon and iconTex and iconTex.SetTexture then
                    iconTex:SetTexture(icon)
                end
            end)
            
            local itemName = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            itemName:SetPoint("LEFT", 25, 0)
            itemName:SetText((data and data.name) or "Unknown Item")
            itemName:SetTextColor(1, 1, 0)
            itemName:SetWidth(200)
            itemName:SetJustifyH("LEFT")
            
            local playersText = table.concat((data and data.players) or {}, ", ")
            local players = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            players:SetPoint("LEFT", 230, 0)
            players:SetText(playersText)
            players:SetTextColor(0.8, 0.8, 0.8)
            players:SetWidth(280)
            players:SetJustifyH("LEFT")
            
            yOffset = yOffset - 35
            itemCount = itemCount + 1
        end
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

------------------------------------------------------------
-- Data Window
------------------------------------------------------------
function ns.UI.CreateDataWindow()
    local frame = CreateFrame("Frame", "BiSWishAddon_DataWindow", UIParent, "BasicFrameTemplateWithInset")
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
    
    local itemIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemIDLabel:SetPoint("TOPLEFT", 20, -50)
    itemIDLabel:SetText("Item ID:")
    itemIDLabel:SetTextColor(1, 1, 1)
    
    local itemIDEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    itemIDEditBox:SetSize(140, 30)
    itemIDEditBox:SetPoint("LEFT", itemIDLabel, "RIGHT", 15, 0)
    itemIDEditBox:SetAutoFocus(false)
    itemIDEditBox:SetTextInsets(8, 8, 0, 0)
    itemIDEditBox:SetFontObject("GameFontHighlight")
    
    local itemNameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemNameLabel:SetPoint("TOPLEFT", 20, -90)
    itemNameLabel:SetText("Item:")
    itemNameLabel:SetTextColor(1, 1, 1)
    
    local itemNameEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    itemNameEditBox:SetSize(250, 30)
    itemNameEditBox:SetPoint("LEFT", itemNameLabel, "RIGHT", 15, 0)
    itemNameEditBox:SetAutoFocus(false)
    itemNameEditBox:SetTextInsets(8, 8, 0, 0)
    itemNameEditBox:SetFontObject("GameFontHighlight")

    local searchItemButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    searchItemButton:SetSize(90, 30)
    searchItemButton:SetPoint("LEFT", itemNameEditBox, "RIGHT", 15, 0)
    searchItemButton:SetText("Search")
    searchItemButton:SetScript("OnClick", function()
        ns.UI.ShowItemSearchDialog(itemNameEditBox)
    end)

    local playersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playersLabel:SetPoint("TOPLEFT", 20, -130)
    playersLabel:SetText("Players:")
    playersLabel:SetTextColor(1, 1, 1)
    
    local playersEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    playersEditBox:SetSize(300, 30)
    playersEditBox:SetPoint("LEFT", playersLabel, "RIGHT", 15, 0)
    playersEditBox:SetAutoFocus(false)
    playersEditBox:SetTextInsets(8, 8, 0, 0)
    playersEditBox:SetFontObject("GameFontHighlight")

    -- Description input
    local descriptionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    descriptionLabel:SetPoint("TOPLEFT", 20, -170)
    descriptionLabel:SetText("Description:")
    descriptionLabel:SetTextColor(1, 1, 1)

    local descriptionEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    descriptionEditBox:SetSize(300, 30)
    descriptionEditBox:SetPoint("LEFT", descriptionLabel, "RIGHT", 15, 0)
    descriptionEditBox:SetAutoFocus(false)
    descriptionEditBox:SetTextInsets(8, 8, 0, 0)
    descriptionEditBox:SetFontObject("GameFontHighlight")

    local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addButton:SetSize(120, 35)
    addButton:SetPoint("TOPLEFT", 20, -210)
    addButton:SetText("Add Item")
    addButton:SetScript("OnClick", function()
        local itemID = tonumber(itemIDEditBox:GetText())
        local itemName = Trim(itemNameEditBox:GetText())
        local playersText = playersEditBox:GetText()
        local description = Trim(descriptionEditBox:GetText())
        
        if not itemID or not itemName or itemName == "" then
            print("|cffFF0000BiSWishAddon|r: Please enter valid Item ID and Name")
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

        print("|cff39FF14BiSWishAddon|r: Added item " .. itemName .. " (ID: " .. itemID .. ") with " .. #players .. " players")

        itemIDEditBox:SetText("")
        itemNameEditBox:SetText("")
        playersEditBox:SetText("")
        descriptionEditBox:SetText("")
        
        ns.UI.UpdateDataWindowContent()
    end)
    
    local removeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    removeButton:SetSize(120, 35)
    removeButton:SetPoint("LEFT", addButton, "RIGHT", 15, 0)
    removeButton:SetText("Remove")
    removeButton:SetScript("OnClick", function()
        local itemID = tonumber(itemIDEditBox:GetText())
        if not itemID then
            print("|cffFF0000BiSWishAddon|r: Please enter valid Item ID")
            return
        end
        if BiSWishAddonDB.items[itemID] then
            local itemName = BiSWishAddonDB.items[itemID].name
            BiSWishAddonDB.items[itemID] = nil
            print("|cff39FF14BiSWishAddon|r: Removed item " .. (itemName or "?") .. " (ID: " .. itemID .. ")")
            itemIDEditBox:SetText("")
            itemNameEditBox:SetText("")
            playersEditBox:SetText("")
            descriptionEditBox:SetText("")
            ns.UI.UpdateDataWindowContent()
        else
            print("|cffFF0000BiSWishAddon|r: Item not found")
        end
    end)
    
    local clearDataButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearDataButton:SetSize(120, 35)
    clearDataButton:SetPoint("LEFT", removeButton, "RIGHT", 15, 0)
    clearDataButton:SetText("Clear Data")
    clearDataButton:SetScript("OnClick", function()
        BiSWishAddonDB.items = {}
        print("|cff39FF14BiSWishAddon|r: Cleared all BiS data!")
        itemIDEditBox:SetText("")
        itemNameEditBox:SetText("")
        playersEditBox:SetText("")
        descriptionEditBox:SetText("")
        ns.UI.UpdateDataWindowContent()
    end)

    local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    importButton:SetSize(120, 35)
    importButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)
    importButton:SetText("Import Data")
    importButton:SetScript("OnClick", function()
        ns.UI.ImportData()
    end)
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -300)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 100)
    
    local content = CreateFrame("Frame")
    content:SetSize(540, 1) -- inner width ~ 540 (600 - 20 - 40)
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
        itemFrame:SetSize(540, 30) -- fit inner width
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
                -- Fallback to hardcoded icon matching
                local fallbackIcon = ns.UI.GetItemIconByName(data.name)
                if fallbackIcon then
                    iconTexture = fallbackIcon
                end
            end
        end
        
        if iconTexture then
            itemIcon:SetTexture(iconTexture)
        else
            -- Fallback to hardcoded icon matching
            local fallbackIcon = ns.UI.GetItemIconByName(data.name)
            if fallbackIcon then
                itemIcon:SetTexture(fallbackIcon)
            else
                itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        end

        local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemText:SetPoint("LEFT", 40, 0)
        itemText:SetText((data and data.name) or "Unknown")
        itemText:SetTextColor(1, 1, 0)
        itemText:SetWidth(220)
        itemText:SetJustifyH("LEFT")

        local playersTextStr = table.concat((data and data.players) or {}, ", ")
        local players = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        players:SetPoint("LEFT", 270, 0)
        players:SetText(playersTextStr)
        players:SetTextColor(0.8, 0.8, 0.8)
        players:SetWidth(150)
        players:SetJustifyH("LEFT")

        -- Description (position fixed to stay inside 540px)
        local description = (data and data.description) or ""
        local descriptionText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        descriptionText:SetPoint("LEFT", 440, 0)
        descriptionText:SetText(description)
        descriptionText:SetTextColor(0.6, 0.6, 0.6)
        descriptionText:SetWidth(90)
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
    
    -- Update guild name display
    local function UpdateGuildNameDisplay()
        local guildName = (BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName) or ""
        if guildName and guildName ~= "" then
            frame.guildName:SetText("|cff39FF14Guild/Raid Team:|r " .. guildName)
            frame.guildName:Show()
        else
            frame.guildName:Hide()
        end
    end
    
    UpdateGuildNameDisplay()

    local logo = frame:CreateTexture(nil, "OVERLAY")
    -- logo:SetTexture("Assets\\logo.tga")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", 10, -10)
    
    local searchContainer = CreateFrame("Frame", nil, frame)
    searchContainer:SetSize(760, 40)
    searchContainer:SetPoint("TOPLEFT", 20, -60)

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
    headerFrame:SetPoint("TOPLEFT", 20, -100)
    
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
    scrollFrame:SetPoint("TOPLEFT", 20, -140)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 100)
    
    local content = CreateFrame("Frame")
     content:SetSize(750, 1)
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
    
    ns.UI.biSListDialog:Show()
    
    -- Update guild name display immediately
    if ns.UI.biSListDialog and ns.UI.biSListDialog.guildName then
        local guildName = (BiSWishAddonDB.options and BiSWishAddonDB.options.guildRaidTeamName) or ""
        print("|cff39FF14BiSWishAddon|r: Guild name debug - '" .. tostring(guildName) .. "'")
        if guildName and guildName ~= "" then
            ns.UI.biSListDialog.guildName:SetText("|cff39FF14Guild/Raid Team:|r " .. guildName)
            ns.UI.biSListDialog.guildName:Show()
            print("|cff39FF14BiSWishAddon|r: Showing guild name: " .. guildName)
        else
            ns.UI.biSListDialog.guildName:Hide()
            print("|cff39FF14BiSWishAddon|r: Hiding guild name (empty)")
        end
    else
        print("|cff39FF14BiSWishAddon|r: Guild name frame not found!")
    end
    
    -- Update the content
    ns.UI.UpdateBiSListContent()
end

function ns.UI.UpdateBiSListContent()
    local frame = ns.UI.biSListDialog
    if not frame then return end
    local content = frame.content
    
     content:Show()
     content:SetSize(750, 1)

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
         itemFrame:SetSize(730, 30)
        itemFrame:SetPoint("TOPLEFT", 10, yOffset)
        
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
                -- Fallback to hardcoded icon matching
                local fallbackIcon = ns.UI.GetItemIconByName(data.name)
                if fallbackIcon then
                    iconTexture = fallbackIcon
                end
            end
        end
        
        if iconTexture then
            itemIcon:SetTexture(iconTexture)
        else
            -- Fallback to hardcoded icon matching
            local fallbackIcon = ns.UI.GetItemIconByName(data.name)
            if fallbackIcon then
                itemIcon:SetTexture(fallbackIcon)
            else
                itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
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

        local playersStr = table.concat((data and data.players) or {}, ", ")
        if playersStr and #playersStr > 25 then
            playersStr = playersStr:sub(1, 22) .. "..."
        end
         local playersTextWidget = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
         playersTextWidget:SetPoint("LEFT", 270, 0)
         playersTextWidget:SetWidth(200)
         playersTextWidget:SetJustifyH("LEFT")
        playersTextWidget:SetTextColor(0.7, 0.7, 1)
         playersTextWidget:SetText(playersStr or "")

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
    content:SetSize(750, 1)
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
            itemFrame:SetSize(730, 30)
            itemFrame:SetPoint("TOPLEFT", 10, yOffset)
            
            local rowBg = itemFrame:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)

            -- Item Icon
            local itemIcon = itemFrame:CreateTexture(nil, "OVERLAY")
            itemIcon:SetSize(24, 24)
            itemIcon:SetPoint("LEFT", 10, 0)
            -- Try to get the actual item icon
            local itemName = data.name
            if itemName then
                local itemInfo = GetItemInfo(itemName)
                if itemInfo then
                    itemIcon:SetTexture(itemInfo)
                else
                    -- Fallback to hardcoded icon matching
                    local fallbackIcon = ns.UI.GetItemIconByName(itemName)
                    if fallbackIcon then
                        itemIcon:SetTexture(fallbackIcon)
                    else
                        itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    end
                end
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
            
            -- Truncate players text
            if string.len(playersText) > 25 then 
                playersText = string.sub(playersText, 1, 22) .. "..." 
            end
            
            local playersTextWidget = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            playersTextWidget:SetPoint("LEFT", 270, 0)
            playersTextWidget:SetText(playersText)
            playersTextWidget:SetTextColor(0.7, 0.7, 1)
            playersTextWidget:SetWidth(200)
            playersTextWidget:SetJustifyH("LEFT")
            
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
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 60)

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

-- Search directly in imported DB (BiSWishAddonDB.items)
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

    if not BiSWishAddonDB or not BiSWishAddonDB.items then
        local noDBText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noDBText:SetPoint("CENTER", 0, 0)
        noDBText:SetText("No database loaded")
        noDBText:SetTextColor(0.7, 0.7, 0.7)
        return
    end

    -- Build a simple array for stable iteration and optional sorting
    local matches = {}
    for itemID, data in pairs(BiSWishAddonDB.items) do
        local name = (data and data.name) or ""
        if name:lower():find(searchLower, 1, true) then
            table.insert(matches, { id = itemID, name = name })
        end
    end

    table.sort(matches, function(a, b) return tostring(a.name) < tostring(b.name) end)

    for _, item in ipairs(matches) do
        if shown >= limit then break end

        local itemFrame = CreateFrame("Frame", nil, content)
        itemFrame:SetSize(640, 35)
        itemFrame:SetPoint("TOPLEFT", 10, yOffset)

        local rowBg = itemFrame:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3)

        -- Icon
        local iconTex = itemFrame:CreateTexture(nil, "OVERLAY")
        iconTex:SetSize(24, 24)
        iconTex:SetPoint("LEFT", 10, 0)
        iconTex:SetTexture(PLACEHOLDER_ICON)
        ns.UI.ResolveItemIcon(tonumber(item.id) or item.name, function(icon)
            if icon and iconTex and iconTex.SetTexture then
                iconTex:SetTexture(icon)
            end
        end)

        -- Item ID
        local itemIDText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemIDText:SetPoint("LEFT", 45, 0)
        itemIDText:SetText(tostring(item.id))
        itemIDText:SetTextColor(0.8, 0.8, 0.8)

        -- Item Name
        local itemNameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemNameText:SetPoint("LEFT", 140, 0)
        itemNameText:SetText(item.name or "")
        itemNameText:SetTextColor(1, 1, 1)

        -- Click to select: fill both Name and ID in Data window + target editbox
        itemFrame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                local dialog = ns.UI.itemSearchDialog
                if dialog and dialog.targetEditBox then
                    dialog.targetEditBox:SetText(item.name or "")
                end
                if ns.UI.dataWindow then
                    if ns.UI.dataWindow.itemIDEditBox then
                        ns.UI.dataWindow.itemIDEditBox:SetText(tostring(item.id))
                    end
                    if ns.UI.dataWindow.itemNameEditBox then
                        ns.UI.dataWindow.itemNameEditBox:SetText(item.name or "")
                    end
                end
                if dialog then dialog:Hide() end
            end
        end)

        itemFrame:SetScript("OnEnter", function() rowBg:SetColorTexture(0.2, 0.2, 0.2, 0.5) end)
        itemFrame:SetScript("OnLeave", function() rowBg:SetColorTexture(0.05, 0.05, 0.05, 0.3) end)

        yOffset = yOffset - 40
        shown = shown + 1
    end

    if shown == 0 then
        local noResultsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noResultsText:SetPoint("CENTER", 0, 0)
        noResultsText:SetText("No items found for: " .. searchText)
        noResultsText:SetTextColor(0.7, 0.7, 0.7)
    end

    -- Keep scroll fresh
    local parentScroll = content:GetParent()
    if parentScroll and parentScroll.UpdateScrollChildRect then
        parentScroll:UpdateScrollChildRect()
        parentScroll:SetVerticalScroll(0)
    end
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
    if ns.UI.csvImportDialog then
        ns.UI.csvImportDialog:Show()
        return
    end

    local frame = CreateFrame("Frame", "BiSWishCSVImportDialog", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

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
    scrollFrame:SetSize(560, 300)
    scrollFrame:SetPoint("TOPLEFT", 20, -110)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 80)

    -- Text Edit Box with proper multi-line support
    local textEditBox = CreateFrame("EditBox", nil, scrollFrame)
    textEditBox:SetSize(540, 300)
    textEditBox:SetMultiLine(true)
    textEditBox:SetAutoFocus(false)
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

    -- Cancel Button
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 30)
    cancelButton:SetPoint("RIGHT", linkButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Clear Button
    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 30)
    clearButton:SetPoint("RIGHT", cancelButton, "LEFT", -10, 0)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        textEditBox:SetText("")
    end)
    
    -- Footer
    ns.UI.CreateFooter(frame)

    ns.UI.csvImportDialog = frame
end

-- Test item drop popup
function ns.UI.TestItemDropPopup()
    -- Simulate a dropped item
    local testItemName = "Brand of Ceaseless Ire"
    local testItemLink = "|cffa335ee|Hitem:242401::::::::80:::::::|h[Brand of Ceaseless Ire]|h|r"
    local testPlayers = {"Player1", "Player2", "Player3"}
    
    ns.UI.ShowItemDropPopup(testItemName, testItemLink, testPlayers)
end

-- Show item drop popup
function ns.UI.ShowItemDropPopup(itemName, itemLink, interestedPlayers)
    if ns.UI.itemDropPopup then
        ns.UI.itemDropPopup:Hide()
    end
    
    local frame = CreateFrame("Frame", "BiSWishAddon_ItemDropPopup", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 300)
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
        title:SetWidth(450)
        title:SetWordWrap(true)
    end
    
    -- Item info
    local itemInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemInfo:SetPoint("TOP", 0, -40)
    itemInfo:SetJustifyH("CENTER")
    itemInfo:SetWidth(450)
    itemInfo:SetWordWrap(true)
    itemInfo:SetText("|cffFFD700" .. itemName .. "|r")
    
    -- Interested players label
    local playersLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playersLabel:SetPoint("TOP", itemInfo, "BOTTOM", 0, -20)
    playersLabel:SetText("|cff39FF14Interested Players:|r")
    playersLabel:SetJustifyH("LEFT")
    playersLabel:SetWidth(450)
    
    -- Players list
    local playersText = table.concat(interestedPlayers, ", ")
    local playersList = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playersList:SetPoint("TOP", playersLabel, "BOTTOM", 0, -5)
    playersList:SetJustifyH("LEFT")
    playersList:SetWidth(450)
    playersList:SetWordWrap(true)
    playersList:SetText(playersText)
    
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
