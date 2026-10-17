local _, NS = ...
local Module = {seen = setmetatable({}, {__mode = "k"})}
NS:RegisterModule("itemCounts", Module)

local function Safe(v)
    if issecretvalue and issecretvalue(v) then return false end
    return not canaccessvalue or canaccessvalue(v)
end
local function Numeric(v) return Safe(v) and type(v) == "number" end
local function Add(counts, id, count)
    if Numeric(id) and id > 0 and Numeric(count) and count > 0 then
        counts[id] = (counts[id] or 0) + count
    end
end
local function ReadBag(bag, allowEmpty)
    local ok, size = pcall(C_Container.GetContainerNumSlots, bag)
    if not ok or not Numeric(size) or size < 0 or (size == 0 and not allowEmpty) then return end
    local counts = {}
    for slot = 1, size do
        local success, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if not success or not Safe(info) then return end
        if info then
            if not Numeric(info.itemID) or not Numeric(info.stackCount) then return end
            Add(counts, info.itemID, info.stackCount)
        end
    end
    return counts
end
local function Decode(items, equipment)
    local counts = {}
    for slot, text in pairs(items or {}) do
        if (not equipment or (type(slot) == "number" and slot >= 1 and slot <= 19))
            and type(text) == "string" then
            Add(counts, tonumber(text:match("^(%d+)")), tonumber(text:match(";(%d+)$")) or 1)
        end
    end
    return counts
end
local function Value(t, id) return t and t[id] or 0 end
local function SumTabs(tabs, id)
    local sum = 0
    for _, counts in pairs(tabs or {}) do sum = sum + Value(counts, id) end
    return sum
end

function Module:ImportBrother()
    if type(BrotherBags) ~= "table" then return end
    local db = NS.db.itemCounts
    for realm, characters in pairs(BrotherBags) do
        if realm ~= "account" and type(characters) == "table" then
            for name, data in pairs(characters) do
                if type(data) == "table" and type(data.class) == "string" then
                    local key = realm .. "\031" .. name
                    if not db.characters[key] then
                        local record = {name = name, realm = realm, class = data.class, bags = {}, bank = {}, equipment = Decode(data.equip, true)}
                        for bag, container in pairs(data) do
                            if type(bag) == "number" and type(container) == "table" and type(container.items) == "table" then
                                local target = bag >= 0 and bag <= 5 and record.bags or record.bank
                                target[bag] = Decode(container.items)
                            end
                        end
                        db.characters[key] = record
                    end
                end
            end
        end
    end
    if type(BrotherBags.account) == "table" then
        for tab, container in pairs(BrotherBags.account) do
            if type(tab) == "number" and type(container) == "table" and not db.account[tab] then
                db.account[tab] = Decode(container.items)
            end
        end
    end
end

function Module:ScanBank(record, bankType, target)
    if not C_Bank or not C_Bank.CanUseBank or not C_Bank.FetchPurchasedBankTabData then return end
    local ok, viewable = pcall(C_Bank.CanUseBank, bankType)
    if not ok or not Safe(viewable) or not viewable then return end
    local success, tabs = pcall(C_Bank.FetchPurchasedBankTabData, bankType)
    if not success or not Safe(tabs) or type(tabs) ~= "table" then return end
    for _, tab in pairs(tabs) do
        if Safe(tab) and type(tab) == "table" and Numeric(tab.ID) then
            local counts = ReadBag(tab.ID)
            -- Unavailable tabs retain their last snapshot; zero-filled readable
            -- tabs replace it, so withdrawing the final item clears the cache.
            if counts then target[tab.ID] = counts end
        end
    end
end

function Module:Scan()
    if not NS.db.itemCounts.enabled or InCombatLockdown() then return end
    local db, realm, name = NS.db.itemCounts, GetRealmName(), UnitName("player")
    if not Safe(realm) or not Safe(name) or type(realm) ~= "string" or type(name) ~= "string" then return end
    local key = realm .. "\031" .. name
    self.currentKey = key
    local record = db.characters[key] or {name = name, realm = realm, bags = {}, bank = {}}
    db.characters[key] = record
    local _, class = UnitClass("player")
    if Safe(class) and type(class) == "string" then record.class = class end
    for bag = 0, (Enum.BagIndex and Enum.BagIndex.ReagentBag or 5) do
        local counts = ReadBag(bag, true)
        if counts then record.bags[bag] = counts end
    end
    local equipment, complete = {}, true
    for slot = 1, 19 do
        local ok, id = pcall(GetInventoryItemID, "player", slot)
        if not ok or not Safe(id) then complete = false; break end
        if id then Add(equipment, id, 1) end
    end
    if complete then record.equipment = equipment end
    self:ScanBank(record, Enum.BankType.Character, record.bank)
    self:ScanBank(record, Enum.BankType.Account, db.account)
end

function Module:Schedule()
    if self.pending or not NS.db.itemCounts.enabled then return end
    self.pending = true
    C_Timer.After(0.15, function() Module.pending = nil; Module:Scan() end)
end

function Module:Rows(id)
    local rows, total = {}, 0
    for key, record in pairs(NS.db.itemCounts.characters) do
        local count = SumTabs(record.bags, id) + SumTabs(record.bank, id)
        if not NS.ItemCountFilters:Get().equipped then count = count + Value(record.equipment, id) end
        if count > 0 then
            rows[#rows + 1] = {name = record.name, realm = record.realm, class = record.class, count = count, current = key == self.currentKey}
            total = total + count
        end
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.name < b.name
    end)
    local account = SumTabs(NS.db.itemCounts.account, id)
    return rows, account, total + account
end

function Module:Tooltip(tooltip, data)
    if not NS.db.itemCounts.enabled or tooltip ~= GameTooltip or tooltip:IsForbidden() then return end
    if not Safe(data) or type(data) ~= "table" then return end
    local id = data.id
    if not Numeric(id) or id <= 0 or self.seen[tooltip] == id then return end
    if NS.ItemCountFilters:Excluded(id) then return end
    local rows, account, total = self:Rows(id)
    if total <= 0 then return end
    -- Set before adding lines to guard callbacks. Never Show/rebuild the
    -- tooltip, request inspection, or touch item button/click scripts.
    self.seen[tooltip] = id
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("战团物品统计（缓存）", tostring(total), 1, 0.82, 0, 1, 0.82, 0)
    for _, row in ipairs(rows) do
        local name = row.name
        if row.realm ~= GetRealmName() then name = name .. "-" .. row.realm end
        local color = row.class and RAID_CLASS_COLORS[row.class]
        tooltip:AddDoubleLine(name, tostring(row.count), color and color.r or 1, color and color.g or 1,
            color and color.b or 1, 1, 1, 1)
    end
    if account > 0 then tooltip:AddDoubleLine("战团银行", tostring(account), 0.4, 0.8, 1, 1, 1, 1) end
end

function Module:Apply()
    if NS.db.itemCounts.enabled then self:ImportBrother(); self:Schedule() end
end
function Module:Initialize()
    self:ImportBrother()
    local frame = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED",
        "BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED", "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", "BANK_TABS_CHANGED", "PLAYER_REGEN_ENABLED"}) do
        frame:RegisterEvent(event)
    end
    frame:SetScript("OnEvent", function() Module:Schedule() end)
    GameTooltip:HookScript("OnTooltipCleared", function(tip) Module.seen[tip] = nil end)
    if TooltipDataProcessor and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data) Module:Tooltip(tip, data) end)
    end
end
