local _, NS = ...

local Module = {}
NS:RegisterModule("slotLabels", Module)

-- Use Blizzard's localized slot names.  This table is deliberately limited to
-- wearable equipment so consumables and crafting materials never get labels.
local SLOT_KEYS = {
    INVTYPE_HEAD = "MERCHANT_SLOT_HEAD",
    INVTYPE_NECK = "MERCHANT_SLOT_NECK",
    INVTYPE_SHOULDER = "MERCHANT_SLOT_SHOULDER",
    INVTYPE_BODY = "MERCHANT_SLOT_SHIRT",
    INVTYPE_CHEST = "MERCHANT_SLOT_CHEST",
    INVTYPE_ROBE = "MERCHANT_SLOT_CHEST",
    INVTYPE_WAIST = "MERCHANT_SLOT_WAIST",
    INVTYPE_LEGS = "MERCHANT_SLOT_LEGS",
    INVTYPE_FEET = "MERCHANT_SLOT_FEET",
    INVTYPE_WRIST = "MERCHANT_SLOT_WRIST",
    INVTYPE_HAND = "MERCHANT_SLOT_HANDS",
    INVTYPE_FINGER = "MERCHANT_SLOT_FINGER",
    INVTYPE_TRINKET = "MERCHANT_SLOT_TRINKET",
    INVTYPE_CLOAK = "MERCHANT_SLOT_BACK",
    INVTYPE_WEAPON = "MERCHANT_SLOT_ONEHAND",
    INVTYPE_SHIELD = "MERCHANT_SLOT_OFFHAND",
    INVTYPE_2HWEAPON = "MERCHANT_SLOT_TWOHAND",
    INVTYPE_WEAPONMAINHAND = "MERCHANT_SLOT_MAINHAND",
    INVTYPE_WEAPONOFFHAND = "MERCHANT_SLOT_OFFHAND",
    INVTYPE_HOLDABLE = "MERCHANT_SLOT_OFFHAND",
    INVTYPE_RANGED = "MERCHANT_SLOT_RANGED",
    INVTYPE_RANGEDRIGHT = "MERCHANT_SLOT_RANGED",
    INVTYPE_THROWN = "MERCHANT_SLOT_RANGED",
}

-- MERCHANT_SLOT_* is not exported as a global in every client build.  Keep a
-- built-in zhCN fallback so this feature does not depend on GearView's locale
-- table or on implementation details of another addon.
local SLOT_FALLBACKS = {
    INVTYPE_HEAD = "头部",
    INVTYPE_NECK = "颈部",
    INVTYPE_SHOULDER = "肩部",
    INVTYPE_BODY = "衬衣",
    INVTYPE_CHEST = "胸部",
    INVTYPE_ROBE = "胸部",
    INVTYPE_WAIST = "腰部",
    INVTYPE_LEGS = "腿部",
    INVTYPE_FEET = "脚部",
    INVTYPE_WRIST = "手腕",
    INVTYPE_HAND = "手套",
    INVTYPE_FINGER = "手指",
    INVTYPE_TRINKET = "饰品",
    INVTYPE_CLOAK = "背部",
    INVTYPE_WEAPON = "单手",
    INVTYPE_SHIELD = "副手",
    INVTYPE_2HWEAPON = "双手",
    INVTYPE_WEAPONMAINHAND = "主手",
    INVTYPE_WEAPONOFFHAND = "副手",
    INVTYPE_HOLDABLE = "副手",
    INVTYPE_RANGED = "远程",
    INVTYPE_RANGEDRIGHT = "远程",
    INVTYPE_THROWN = "远程",
}

local labels = setmetatable({}, {__mode = "k"})
local pending

local function ApplyFont(label)
    if not label or not label.SetFont or not STANDARD_TEXT_FONT then return end
    local size = NS.db and NS.db.slotLabels and tonumber(NS.db.slotLabels.size) or 11
    label:SetFont(STANDARD_TEXT_FONT, math.max(8, math.min(24, size)), "OUTLINE")
end

-- Patch 12.x can return secret values in competitive content.  A secret value
-- must be rejected before type checks, table indexing, or string formatting.
local function IsReadable(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return true
end

local function Hide(label)
    if not label then return end
    label:SetText("")
    label:Hide()
end

local function GetLabel(frame)
    local label = labels[frame]
    if label then return label end
    label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
    ApplyFont(label)
    label:SetTextColor(0.15, 0.85, 1)
    label:SetShadowOffset(1, -1)
    labels[frame] = label
    return label
end

local function ReadSlotName(bag, slot)
    if not C_Container or not C_Container.GetContainerItemLink then return end
    local ok, link = pcall(C_Container.GetContainerItemLink, bag, slot)
    if not ok or not IsReadable(link) then return end
    if link == nil then return end

    -- The global function is the primary API used by this ShestakUI/GearView
    -- generation.  C_Item is retained as a fallback for later clients.
    local getter = type(GetItemInfoInstant) == "function" and GetItemInfoInstant
        or C_Item and C_Item.GetItemInfoInstant
    if not getter then return end
    local infoOK, _, _, _, equipLoc = pcall(getter, link)
    if not infoOK or not IsReadable(equipLoc) or type(equipLoc) ~= "string" then return end

    local globalKey = SLOT_KEYS[equipLoc]
    if not globalKey then return end
    local text = _G[globalKey]
    if not IsReadable(text) or type(text) ~= "string" or text == "" then
        text = SLOT_FALLBACKS[equipLoc]
    end
    if type(text) ~= "string" or text == "" then return end
    return text
end

function Module:UpdateEntry(entry)
    local frame = type(entry) == "table" and entry.frame
    if not frame or not frame.CreateFontString then return end
    local label = GetLabel(frame)
    local enabled = NS.db and NS.db.slotLabels and NS.db.slotLabels.enabled
    local text = enabled and ReadSlotName(entry.bag, entry.slot)
    if text then
        label:SetText(text)
        label:Show()
    else
        Hide(label)
    end
end

function Module:Refresh()
    pending = nil
    local enabled = NS.db and NS.db.slotLabels and NS.db.slotLabels.enabled
    local buttons = Stuffing and Stuffing.buttons
    if type(buttons) ~= "table" then
        for _, label in pairs(labels) do Hide(label) end
        return
    end

    for _, entry in pairs(buttons) do
        self:UpdateEntry(entry)
    end
end

function Module:Schedule(delay)
    if pending then return end
    pending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0, function() Module:Refresh() end)
    else
        self:Refresh()
    end
end

function Module:Initialize()
    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED",
        "PLAYERBANKSLOTS_CHANGED", "PLAYER_REGEN_ENABLED",
    }) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(_, event)
        Module:Schedule(event == "PLAYER_LOGIN" and 0.2 or 0)
    end)
    self.events = events

    -- Refresh the exact button ShestakUI has just updated.  This also covers
    -- buttons created after login without polling or touching their scripts.
    if Stuffing and type(Stuffing.SlotUpdate) == "function" and hooksecurefunc then
        hooksecurefunc(Stuffing, "SlotUpdate", function(_, entry)
            Module:UpdateEntry(entry)
        end)
    end
end

function Module:Apply()
    for _, label in pairs(labels) do ApplyFont(label) end
    if not NS.db.slotLabels.enabled then
        for _, label in pairs(labels) do Hide(label) end
        return
    end
    self:Schedule(0)
end
