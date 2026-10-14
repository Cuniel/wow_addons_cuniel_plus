local _, NS = ...

function NS:CreateOptions()
    local panel = CreateFrame("Frame", "CunielPlusOptions", UIParent, "BasicFrameTemplateWithInset")
    self.options = panel
    panel:Hide()
    panel:SetSize(590, 815)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel.TitleText:SetText("Cuniel_plus  |  0.3.9")
    tinsert(UISpecialFrames, "CunielPlusOptions")

    local function Label(text, x, y, template)
        local label = panel:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
        label:SetPoint("TOPLEFT", x, y)
        label:SetText(text)
        label:SetJustifyH("LEFT")
        return label
    end
    local function Button(text, x, y, width, callback)
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", x, y)
        button:SetSize(width, 28)
        button:SetText(text)
        button:SetScript("OnClick", callback)
        return button
    end
    Label("数字显示 · ShestakUI", 24, -48, "GameFontNormalLarge")
    Label("切换四位进位（万 / 亿）或三位进位（K / M / B）。", 24, -77)
    local modeButtons = {}
    for i, item in ipairs({{"east", "万 / 亿"}, {"west", "K / M / B"}, {"original", "跟随 ShestakUI"}}) do
        local mode = item[1]
        modeButtons[mode] = Button(item[2], 24 + (i - 1) * 180, -101, 168, function()
            NS.db.numbers.mode = mode
            NS.modules.numbers:Apply()
            panel:Refresh()
        end)
    end
    local status = Label("", 24, -143)
    status:SetWidth(538)
    status:SetHeight(40)
    local preview = Label("", 24, -184)
    Label("帧数显示", 24, -222, "GameFontNormalLarge")
    local function Check(text, x, y, key)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", x, y)
        local caption = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        caption:SetPoint("LEFT", check, "RIGHT", 2, 0)
        caption:SetText(text)
        check:SetScript("OnClick", function(self)
            NS.db.fps[key] = self:GetChecked() and true or false
            NS.modules.fps:Apply()
        end)
        return check
    end
    local enabled = Check("显示 FPS", 20, -250, "enabled")
    local locked = Check("锁定位置（鼠标穿透）", 230, -250, "locked")
    Label("字号", 24, -303)
    local sizeLabel = Label("", 146, -303)
    local function ChangeSize(delta)
        NS.db.fps.size = math.max(10, math.min(48, NS.db.fps.size + delta))
        NS.modules.fps:Apply()
        panel:Refresh()
    end
    Button("−", 91, -295, 36, function() ChangeSize(-1) end)
    Button("+", 180, -295, 36, function() ChangeSize(1) end)
    Button("重置 FPS 位置", 300, -295, 240, function()
        NS.db.fps.x, NS.db.fps.y = 0, 180
        NS.modules.fps:Apply()
    end)
    Label("解锁后：左键拖动 FPS，右键打开设置。位置自动保存。", 24, -341)
    Label("所有角色共用设置。输入 /cuniel 或 /cplus 打开此窗口。", 24, -367)
    Label("ShestakUI 提示增强", 24, -405, "GameFontNormalLarge")
    local function ModuleCheck(text, y, key)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 20, y)
        local caption = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        caption:SetPoint("LEFT", check, "RIGHT", 2, 0)
        caption:SetText(text)
        check:SetScript("OnClick", function(self)
            NS.db[key].enabled = self:GetChecked() and true or false
            NS.modules[key]:Apply()
        end)
        return check
    end
    local gold = ModuleCheck("金币统计角色名使用职业颜色", -435, "gold")
    local itemLevel = ModuleCheck("鼠标提示装等（ShestakUI 已开启时自动让位）", -470, "itemLevel")
    local bags = ModuleCheck("Bagnon 独立工具条：售卖 / 整理 / 存战团银行", -505, "bags")
    local autoSell = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    autoSell:SetPoint("TOPLEFT", 20, -540)
    local saleCaption = autoSell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    saleCaption:SetPoint("LEFT", autoSell, "RIGHT", 2, 0)
    saleCaption:SetText("自动出售垃圾（当前角色 · ShestakUI）")
    autoSell:SetScript("OnClick", function(self)
        NS.modules.bags:SetAutoSell(self:GetChecked())
        panel:Refresh()
    end)
    local quiet = ModuleCheck("登录静默：屏蔽已识别插件的加载 / 宣传提示", -575, "quiet")
    local arenaSpam = ModuleCheck("竞技场：隐藏重复的“玩家加入战斗”系统消息", -610, "arenaSpam")
    local bagPosition = ModuleCheck("ShestakUI 背包避让：向左并向上移动", -645, "bagPosition")
    local slotLabels = ModuleCheck("ShestakUI 背包：显示装备部位文字", -680, "slotLabels")
    Label("部位字号", 345, -689)
    local slotSizeLabel = Label("", 473, -689)
    local function ChangeSlotSize(delta)
        NS.db.slotLabels.size = math.max(8, math.min(24, NS.db.slotLabels.size + delta))
        NS.modules.slotLabels:Apply()
        panel:Refresh()
    end
    Button("−", 420, -681, 36, function() ChangeSlotSize(-1) end)
    Button("+", 505, -681, 36, function() ChangeSlotSize(1) end)
    local mapEscape = ModuleCheck("窗口兼容：允许 ESC 关闭地图、角色、声望和货币", -715, "mapEscape")
    Button("战团存放：食物保护 / 排除物品 ID", 24, -755, 360, function() NS.Deposit:OpenOptions() end)
    function panel:Refresh()
        for mode, button in pairs(modeButtons) do
            button:SetEnabled(mode ~= NS.db.numbers.mode)
        end
        status:SetText(NS.modules.numbers.status or "等待初始化")
        local mode = NS.db.numbers.mode
        preview:SetText(mode == "east" and "示例：1.23万    1234万    1.23亿"
            or mode == "west" and "示例：12.3K    12.3M    123M"
            or "跟随模式不会撤销 ShestakUI 文件中已存在的补丁。")
        enabled:SetChecked(NS.db.fps.enabled)
        locked:SetChecked(NS.db.fps.locked)
        sizeLabel:SetText(tostring(NS.db.fps.size))
        gold:SetChecked(NS.db.gold.enabled)
        itemLevel:SetChecked(NS.db.itemLevel.enabled)
        bags:SetChecked(NS.db.bags.enabled)
        local selling, available = NS.modules.bags:GetAutoSell()
        autoSell:SetChecked(selling)
        autoSell:SetEnabled(available)
        quiet:SetChecked(NS.db.quiet.enabled)
        arenaSpam:SetChecked(NS.db.arenaSpam.enabled)
        bagPosition:SetChecked(NS.db.bagPosition.enabled)
        slotLabels:SetChecked(NS.db.slotLabels.enabled)
        slotSizeLabel:SetText(tostring(NS.db.slotLabels.size))
        mapEscape:SetChecked(NS.db.mapEscape.enabled)
    end
    panel:SetScript("OnShow", panel.Refresh)

    -- Also provide an entry in Blizzard's Settings > AddOns, when available.
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local launcher = CreateFrame("Frame")
        local title = launcher:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 20, -20)
        title:SetText("Cuniel_plus")
        local open = CreateFrame("Button", nil, launcher, "UIPanelButtonTemplate")
        open:SetPoint("TOPLEFT", 20, -60)
        open:SetSize(200, 30)
        open:SetText("打开功能设置")
        open:SetScript("OnClick", function()
            if SettingsPanel then SettingsPanel:Hide() end
            panel:Show()
        end)
        local category = Settings.RegisterCanvasLayoutCategory(launcher, "Cuniel_plus")
        Settings.RegisterAddOnCategory(category)
    end
end
