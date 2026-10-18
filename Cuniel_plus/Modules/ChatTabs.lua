local _, NS = ...
local Module = {}
NS:RegisterModule("chatTabs", Module)

-- Ciaoasher's categories, with Chinese tab names. Do not clone server channels,
-- account identifiers, window coordinates, or chat message history.
local templates = {
    {name = "公会", groups = {"GUILD", "OFFICER", "GUILD_ACHIEVEMENT"}},
    {name = "密语", groups = {"WHISPER", "BN_WHISPER"}},
    {name = "团队", groups = {"PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER",
        "RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER"}},
}

local function CopyList(list)
    local copy = {}
    for _, value in ipairs(list or {}) do
        if type(value) == "string" then copy[#copy + 1] = value end
    end
    return copy
end

local function State()
    NS.charDB.chatTabs = NS.charDB.chatTabs or {}
    return NS.charDB.chatTabs
end

local function CustomFrames()
    local list = {}
    -- 1=General, 2=Combat Log, 3=Blizzard voice transcription. Never replace them.
    for id = 4, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. id]
        if frame and not frame.isTemporary then
            local name, size, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(id)
            if shown == true or shown == 1 or frame.isDocked or frame.minimized
                or (type(docked) == "number" and docked > 0) then
                list[#list + 1] = {frame = frame, name = name, size = size,
                    r = r, g = g, b = b, alpha = alpha, locked = locked,
                    docked = docked, uninteractable = uninteractable}
            end
        end
    end
    return list
end

local function Ready()
    for _, name in ipairs({"GetChatWindowInfo", "FCF_OpenNewWindow", "FCF_Close",
        "FCF_SetWindowName", "FCF_SetLocked", "FCF_SetChatWindowFontSize",
        "FCF_SetWindowColor", "FCF_SetWindowAlpha", "FCF_UnDockFrame", "FCF_DockFrame"}) do
        if type(_G[name]) ~= "function" then return false end
    end
    return ChatFrame1 and type(ChatFrame1.RemoveAllMessageGroups) == "function"
end

function Module:Snapshot()
    local windows = {}
    for _, item in ipairs(CustomFrames()) do
        local frame = item.frame
        item.frame = nil
        item.groups = CopyList(frame.messageTypeList)
        item.channels = CopyList(frame.channelList)
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
        item.point, item.relativePoint, item.x, item.y = point, relativePoint, x, y
        item.relativeTo = relativeTo and relativeTo.GetName and relativeTo:GetName() or "UIParent"
        item.width, item.height = frame:GetSize()
        windows[#windows + 1] = item
    end
    return windows
end

local function ClearCustom()
    for _, item in ipairs(CustomFrames()) do
        FCF_Close(item.frame)
        FCF_SetWindowName(item.frame, "")
    end
end

local function Open(item, restore)
    local frame = FCF_OpenNewWindow(item.name, true)
    assert(frame, "没有可用的聊天窗口")
    frame:RemoveAllMessageGroups()
    frame:RemoveAllChannels()
    frame:ReceiveAllPrivateMessages()
    for _, group in ipairs(item.groups) do frame:AddMessageGroup(group) end
    for _, channel in ipairs(item.channels or {}) do frame:AddChannel(channel) end
    -- Retain each character's current chat font rather than copying a fixed
    -- pixel font. New tabs receive ShestakUI's normal chat styling/hooks.
    local size = item.size or select(2, ChatFrame1:GetFont()) or 14
    FCF_SetChatWindowFontSize(nil, frame, size)
    if restore then
        FCF_SetWindowColor(frame, item.r or 0, item.g or 0, item.b or 0)
        FCF_SetWindowAlpha(frame, item.alpha or 0)
        FCF_SetLocked(frame, item.locked == true or item.locked == 1)
        if not item.docked or item.docked == 0 then
            FCF_UnDockFrame(frame)
            if item.point and item.relativePoint then
                frame:ClearAllPoints()
                frame:SetPoint(item.point, _G[item.relativeTo or "UIParent"] or UIParent,
                    item.relativePoint, item.x or 0, item.y or 0)
            end
            if item.width and item.height then frame:SetSize(item.width, item.height) end
        end
        if SetChatWindowUninteractable then
            SetChatWindowUninteractable(frame:GetID(), item.uninteractable == true or item.uninteractable == 1)
        end
    else
        FCF_SetLocked(frame, true)
    end
    return frame
end

function Module:Run(action, needed)
    if self.running then return false end
    if InCombatLockdown() then
        self.status = "战斗中暂不调整聊天标签；脱战后再试。"
        return false
    end
    if not Ready() then
        self.status = "聊天接口尚未就绪，未修改标签。"
        return false
    end
    local capacity = 0
    for id = 4, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. id]
        if frame and not frame.isTemporary then capacity = capacity + 1 end
    end
    if capacity < (needed or 3) then
        self.status = "临时会话占用了聊天窗口，请先关闭临时会话后再试；现有标签未修改。"
        return false
    end
    self.running = true
    local ok, err = pcall(action)
    self.running = nil
    if not ok then
        self.failed = true
        self.status = "聊天标签配置未完成，可使用原配置备份恢复。"
        -- Keep failures observable without printing private chat contents.
        if geterrorhandler then geterrorhandler()(err) end
    end
    return ok
end

function Module:Configure(force)
    local state = State()
    if not force and (not NS.db.chatTabs.enabled or state.disabled or state.version == 1 or self.failed) then return end
    if InCombatLockdown() then self.pending = true; return end
    local ok = self:Run(function()
        if not state.backup then state.backup = self:Snapshot() end
        state.version = nil
        ClearCustom()
        for _, item in ipairs(templates) do Open(item) end
        if FCF_SelectDockFrame then FCF_SelectDockFrame(ChatFrame1) end
        if FCF_SaveDock then FCF_SaveDock() end
        state.version, state.disabled = 1, false
        self.pending, self.failed = nil, nil
        self.status = "已配置公会、密语、团队；本角色后续登录不重复创建。"
    end)
    if ok and force then NS:Print(self.status) end
    return ok
end

function Module:Restore()
    local state = State()
    if not state.backup then self.status = "当前角色没有原标签备份。"; return false end
    local ok = self:Run(function()
        ClearCustom()
        local rows = {}
        for _, item in ipairs(state.backup) do rows[#rows + 1] = item end
        table.sort(rows, function(a, b) return (tonumber(a.docked) or 100) < (tonumber(b.docked) or 100) end)
        for _, item in ipairs(rows) do Open(item, true) end
        if FCF_SelectDockFrame then FCF_SelectDockFrame(ChatFrame1) end
        if FCF_SaveDock then FCF_SaveDock() end
        state.disabled = true
        self.pending, self.failed = nil, nil
        self.status = "已恢复原标签，并停用当前角色的自动配置。备份不含聊天记录。"
    end, #state.backup)
    if ok then NS:Print(self.status) end
    return ok
end

function Module:Apply()
    if not NS.db.chatTabs.enabled then self.pending = nil; return end
    if self.loggedIn then self:Configure() end
end

function Module:Initialize()
    self.events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            self.loggedIn = true
            if not self.scheduled then
                self.scheduled = true
                C_Timer.After(1, function() self.scheduled = nil; self:Apply() end)
            end
        elseif self.pending then self.pending = nil; self:Apply() end
    end)
end

function Module:OpenOptions()
    if not self.panel then
        local panel = CreateFrame("Frame", "CunielPlusChatTabsOptions", UIParent, "BasicFrameTemplateWithInset")
        self.panel = panel
        panel:SetSize(560, 330)
        panel:SetPoint("CENTER")
        panel:SetClampedToScreen(true)
        panel:SetFrameStrata("DIALOG")
        panel.TitleText:SetText("中文聊天标签页")
        local skin = type(ShestakUI) == "table" and ShestakUI[1]
        if skin and panel.StripTextures and panel.SetTemplate then
            panel:StripTextures()
            panel:SetTemplate("Transparent")
        end
        tinsert(UISpecialFrames, "CunielPlusChatTabsOptions")
        local function Label(text, y)
            local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("TOPLEFT", 22, y)
            label:SetWidth(512)
            label:SetJustifyH("LEFT")
            label:SetText(text)
            return label
        end
        Label("参考 Ciaoasher：公会 / 密语 / 团队（含小队、团队、副本）。", -48)
        Label("首次应用会先备份并清理已有自定义标签，保留综合、战斗记录和内置语音。成功后每个角色只初始化一次。", -80)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 18, -127)
        local caption = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        caption:SetPoint("LEFT", check, "RIGHT", 2, 0)
        caption:SetText("登录自动配置（账号共用开关，默认开启）")
        if skin and skin.SkinCheckBox then skin.SkinCheckBox(check) end
        check:SetScript("OnClick", function(button)
            NS.db.chatTabs.enabled = button:GetChecked() and true or false
            Module:Apply(); panel:Refresh()
        end)
        local status = Label("", -173)
        local function Button(text, x, width, action)
            local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
            button:SetPoint("BOTTOMLEFT", x, 44)
            button:SetSize(width, 28)
            button:SetText(text)
            button:SetScript("OnClick", function() action(); panel:Refresh() end)
            if skin and button.SkinButton then button:SkinButton() end
            return button
        end
        Button("重建中文标签（清理现有自定义页）", 22, 263, function() Module:Configure(true) end)
        self.restoreButton = Button("恢复原标签并停用当前角色", 293, 245, function() Module:Restore() end)
        Label("备份按角色保存，不保存聊天内容。关闭开关不会删除已创建的标签。", -295)
        function panel:Refresh()
            check:SetChecked(NS.db.chatTabs.enabled)
            local state = State()
            status:SetText(Module.status or (state.disabled and "当前角色已选择保留原配置。"
                or state.version == 1 and "当前角色已初始化；再次登录不会重复创建。" or "等待登录后初始化。"))
            Module.restoreButton:SetEnabled(state.backup ~= nil)
        end
        panel:SetScript("OnShow", panel.Refresh)
    end
    self.panel:Show()
    self.panel:Refresh()
end
