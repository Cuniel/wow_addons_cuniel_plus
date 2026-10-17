local _, NS = ...
local Filters = {}
NS.ItemCountFilters = Filters
local DEFAULTS = {hearth = true, equipped = true, junk = true, quests = false, excludeIDs = {}}
local HEARTHSTONES = {[6948] = true, [110560] = true, [140192] = true}
local function Readable(v)
    if issecretvalue and issecretvalue(v) then return false end
    return not canaccessvalue or canaccessvalue(v)
end

function Filters:Get()
    return NS.db.itemCounts.filters or DEFAULTS
end

function Filters:Excluded(id)
    local config = self:Get()
    if config.excludeIDs and config.excludeIDs[tostring(id)] then return true end
    if config.hearth and HEARTHSTONES[id] then return true end
    if not config.junk and not config.quests then return false end
    if not C_Item or not C_Item.GetItemInfo then return false end
    local info = {pcall(C_Item.GetItemInfo, id)}
    if not info[1] then return false end
    -- GetItemInfo: quality is return #3, classID is return #12.
    local quality, class = info[4], info[13]
    if config.junk and Readable(quality) and type(quality) == "number" and quality == 0 then return true end
    if config.quests and Readable(class) and type(class) == "number" and class == 12 then return true end
    -- Do not guess a category while metadata is unavailable. On the next
    -- tooltip rebuild the loaded data will be used, without polling/Show.
    if Readable(quality) and quality == nil and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return false
end

function Filters:SaveIDs(text)
    local ids = {}
    for token in text:gsub("，", ","):gsub("；", ";"):gmatch("[^%s,;]+") do
        local value = tonumber(token)
        if not token:match("^%d+$") or not value or value < 1 or value > 2147483647 then return false end
        ids[tostring(value)] = true
    end
    self:Get().excludeIDs = ids
    return true
end

function Filters:OpenOptions()
    if self.panel then self.panel:Show(); return end
    local panel = CreateFrame("Frame", "CunielPlusItemCountOptions", UIParent, "BasicFrameTemplateWithInset")
    self.panel = panel
    panel:SetSize(490, 390)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel.TitleText:SetText("物品统计 · 过滤规则")
    table.insert(UISpecialFrames, "CunielPlusItemCountOptions")
    local checks = {}
    for i, entry in ipairs({{"hearth", "隐藏炉石、达拉然炉石、要塞炉石"},
        {"equipped", "不计入已穿在身上的装备（背包中仍统计）"},
        {"junk", "隐藏灰色垃圾物品"}, {"quests", "隐藏任务物品（默认关闭）"}}) do
        local key = entry[1]
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 20, -38 - (i - 1) * 35)
        local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", check, "RIGHT", 0, 0)
        label:SetText(entry[2])
        check:SetScript("OnClick", function(self) Filters:Get()[key] = self:GetChecked() and true or false end)
        checks[key] = check
    end
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 24, -188)
    label:SetText("另外隐藏的物品 ID，以空格或逗号分隔：")
    local edit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", 28, -220)
    edit:SetSize(425, 52)
    edit:SetMultiLine(true)
    edit:SetMaxLetters(2000)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 24, -290)
    note:SetText("绑定装备暂时保留；规则账号共用，重新悬停物品生效。\n此处仅控制 Cuniel_plus 统计，不影响战团存放或物品本身。")
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetSize(180, 28)
    save:SetPoint("BOTTOM", 0, 18)
    save:SetText("保存物品 ID 名单")
    save:SetScript("OnClick", function()
        if Filters:SaveIDs(edit:GetText()) then edit:ClearFocus(); NS:Print("物品统计排除名单已保存。")
        else NS:Print("请填写有效的正整数物品 ID，用空格或逗号分隔。") end
    end)
    panel:SetScript("OnShow", function()
        local config = Filters:Get()
        for key, check in pairs(checks) do check:SetChecked(config[key]) end
        local ids = {}
        for id, enabled in pairs(config.excludeIDs or {}) do if enabled then ids[#ids + 1] = id end end
        table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
        edit:SetText(table.concat(ids, ", "))
    end)
    panel:Hide(); panel:Show()
end
