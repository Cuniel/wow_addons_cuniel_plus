local _, NS = ...
function NS:CreateOptions()
    local panel = CreateFrame("Frame", "CunielPlusOptions", UIParent, "BasicFrameTemplateWithInset")
    self.options = panel
    panel:Hide(); panel:SetSize(820, 590); panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
    panel:SetMovable(true); panel:EnableMouse(true); panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving); panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata("Cuniel_plus", "Version") or "0.3.21"
    panel.TitleText:SetText("Cuniel_plus  |  " .. version)
    tinsert(UISpecialFrames, "CunielPlusOptions")
    local skin = type(ShestakUI) == "table" and ShestakUI[1]
    if skin and panel.StripTextures and panel.SetTemplate then panel:StripTextures(); panel:SetTemplate("Transparent") end
    local refreshers, pages, nav, subnav = {}, {}, {}, {}
    panel.pages, panel.navigation = pages, nav
    local function OnRefresh(fn) refreshers[#refreshers + 1] = fn end
    local function Label(parent, text, x, y, width, heading)
        local label = parent:CreateFontString(nil, "OVERLAY", heading and "GameFontNormalLarge" or "GameFontHighlight")
        label:SetPoint("TOPLEFT", x, y); label:SetWidth(width or 540); label:SetJustifyH("LEFT"); label:SetText(text)
        return label
    end
    local function Button(parent, text, x, y, width, action)
        local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT", x, y); b:SetSize(width, 28); b:SetText(text)
        b:SetScript("OnClick", function() action(); panel:Refresh() end)
        if skin and b.SkinButton then b:SkinButton() end
        return b
    end
    local scroll = CreateFrame("ScrollFrame", "CunielPlusOptionsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 202, -87); scroll:SetPoint("BOTTOMRIGHT", -32, 47)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(572, 435); scroll:SetScrollChild(content)
    local heading = Label(panel, "总览", 204, -48, 540, true)
    Label(panel, "ShestakUI 增强", 20, -519, 170)
    Label(panel, "设置自动保存 · 部分功能需重新悬停或重载", 202, -554, 565)
    local function Page(key, title, height)
        local f = CreateFrame("Frame", nil, content); f:SetPoint("TOPLEFT"); f:SetSize(572, height or 435); f:Hide()
        pages[key] = {frame = f, title = title, height = height or 435}; return f
    end
    function panel:SelectPage(key)
        if not pages[key] then return end
        self.selectedPage = key
        for name, p in pairs(pages) do p.frame:SetShown(name == key) end
        heading:SetText(pages[key].title); content:SetHeight(pages[key].height); scroll:SetVerticalScroll(0); self:Refresh()
    end
    for i, item in ipairs({{"overview", "总览"}, {"bags", "背包与银行"}, {"tooltip", "物品提示"}, {"numbers", "文字与显示"}, {"compat", "兼容与诊断"}}) do
        local key = item[1]
        nav[key] = Button(panel, item[2], 16, -57 - (i - 1) * 51, 166, function() panel:SelectPage(key) end)
    end
    local function Section(parent, text, y) Label(parent, text, 0, y, 550, true) end
    local function Check(parent, text, y, get, set)
        local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"); c:SetPoint("TOPLEFT", -4, y)
        local label = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", c, "RIGHT", 2, 0); label:SetWidth(515); label:SetJustifyH("LEFT"); label:SetText(text)
        c:SetScript("OnClick", function(button) set(button:GetChecked() and true or false); panel:Refresh() end)
        if skin and skin.SkinCheckBox then skin.SkinCheckBox(c) end
        OnRefresh(function() c:SetChecked(get()) end); return c
    end
    local function ModuleCheck(parent, text, y, key)
        return Check(parent, text, y, function() return NS.db[key].enabled end, function(v) NS.db[key].enabled = v; NS.modules[key]:Apply() end)
    end
    local function Stepper(parent, text, y, get, set, low, high)
        Label(parent, text, 0, y - 6, 190); local value = Label(parent, "", 260, y - 6, 45)
        Button(parent, "−", 208, y, 38, function() set(math.max(low, get() - 1)) end)
        Button(parent, "+", 306, y, 38, function() set(math.min(high, get() + 1)) end)
        OnRefresh(function() value:SetText(tostring(get())) end)
    end
    local function DisplayTabs(parent)
        for i, item in ipairs({{"numbers", "数字格式"}, {"fps", "帧数显示"}, {"slots", "装备部位"}, {"fonts", "字体可读性"}}) do
            local key = item[1]
            local b = Button(parent, item[2], (i - 1) * 140, 0, 132, function() panel:SelectPage(key) end)
            subnav[#subnav + 1] = {button = b, key = key}
        end
    end
    local overview = Page("overview", "总览")
    Section(overview, "常用设置，按功能分类", 0)
    Label(overview, "现有配置与角色缓存保留。左侧选择分类，无需翻找整个长窗口。", 0, -39)
    Section(overview, "当前版本", -92)
    Label(overview, "Cuniel_plus " .. version .. "\n开发客户端：国服正式服 12.1.5.70448\n\nDetails 限制在目标框下方，宽则并排、窄则堆叠。\nMac 高分辨率小字补偿可在文字与显示中调整。", 0, -127)
    Button(overview, "装备部位：字号与品质", 0, -251, 265, function() panel:SelectPage("slots") end)
    Button(overview, "Details 自动避让", 281, -251, 265, function() panel:SelectPage("compat") end)
    Button(overview, "中文聊天标签页", 0, -295, 265, function() NS.modules.chatTabs:OpenOptions() end)
    local bags = Page("bags", "背包与银行")
    Section(bags, "背包布局", 0); ModuleCheck(bags, "背包避让：向左并向上移动", -35, "bagPosition")
    Section(bags, "整理与售卖", -91); ModuleCheck(bags, "Bagnon 工具条：售卖 / 整理 / 存战团银行", -125, "bags")
    local autoSell = Check(bags, "自动出售垃圾（当前角色 · ShestakUI）", -164, function() return NS.modules.bags:GetAutoSell() end, function(v) NS.modules.bags:SetAutoSell(v) end)
    OnRefresh(function() local _, available = NS.modules.bags:GetAutoSell(); autoSell:SetEnabled(available) end)
    Label(bags, "整理沿用 ShestakUI 原有顺序，不另设炉石优先级。", 0, -210)
    Section(bags, "战团存放保护", -265)
    Button(bags, "食物保护 / 不存入的物品 ID", 0, -302, 430, function() NS.Deposit:OpenOptions() end)
    Label(bags, "存放排除名单与物品数量的隐藏名单相互独立。", 0, -347)
    local tooltip = Page("tooltip", "物品提示")
    Section(tooltip, "角色物品数量", 0); ModuleCheck(tooltip, "显示职业色角色数量 / 战团银行（缓存）", -35, "itemCounts")
    Button(tooltip, "物品统计：过滤规则 / 隐藏物品 ID", 0, -83, 430, function() NS.ItemCountFilters:OpenOptions() end)
    Label(tooltip, "离线数量来自缓存；未读取角色或银行不代表数量为零。", 0, -125)
    Section(tooltip, "装等与角色名", -188)
    ModuleCheck(tooltip, "鼠标提示装等（ShestakUI 已开启时自动让位）", -222, "itemLevel")
    ModuleCheck(tooltip, "金币统计角色名使用职业颜色", -261, "gold")
    Button(tooltip, "修复装等重复：切换 Cuniel_plus 并重载", 0, -316, 480, function() NS.modules.itemLevel:RepairShestak() end)
    local numbers = Page("numbers", "文字与显示 · 数字格式"); DisplayTabs(numbers)
    Section(numbers, "ShestakUI 数字单位", -66)
    local modes = {}
    for i, item in ipairs({{"east", "万 / 亿"}, {"west", "K / M / B"}, {"original", "跟随 ShestakUI"}}) do
        local key = item[1]
        modes[key] = Button(numbers, item[2], (i - 1) * 181, -105, 168, function() NS.db.numbers.mode = key; NS.modules.numbers:Apply() end)
    end
    local numberStatus = Label(numbers, "", 0, -157); local numberPreview = Label(numbers, "", 0, -216)
    Label(numbers, "目前覆盖公共数字函数；经验、声望等独立模块的统一及完整数值模式仍在规划中。\n\n“跟随 ShestakUI”不等于“完整数值”。", 0, -284)
    OnRefresh(function()
        for key, b in pairs(modes) do b:SetEnabled(NS.db.numbers.mode ~= key) end
        numberStatus:SetText(NS.modules.numbers.status or "等待初始化")
        local mode = NS.db.numbers.mode
        numberPreview:SetText(mode == "east" and "示例：1.23万    1234万    1.23亿" or mode == "west" and "示例：12.3K    12.3M    123M" or "保留 ShestakUI 当前的数字格式。")
    end)
    local fps = Page("fps", "文字与显示 · 帧数显示"); DisplayTabs(fps)
    ModuleCheck(fps, "显示 FPS", -70, "fps")
    Check(fps, "锁定位置（鼠标穿透）", -112, function() return NS.db.fps.locked end, function(v) NS.db.fps.locked = v; NS.modules.fps:Apply() end)
    Stepper(fps, "帧数字号", -178, function() return NS.db.fps.size end, function(v) NS.db.fps.size = v; NS.modules.fps:Apply() end, 10, 48)
    Button(fps, "重置 FPS 位置", 0, -238, 300, function() NS.db.fps.x, NS.db.fps.y = 0, 180; NS.modules.fps:Apply() end)
    Label(fps, "解锁后左键拖动 FPS，右键打开设置；位置自动保存。", 0, -292)
    local slots = Page("slots", "文字与显示 · 装备部位", 665); DisplayTabs(slots)
    ModuleCheck(slots, "在背包装备格中显示部位文字", -65, "slotLabels")
    Stepper(slots, "部位字号", -121, function() return NS.db.slotLabels.size end, function(v) NS.db.slotLabels.size = v; NS.modules.slotLabels:Apply() end, 8, 24)
    Section(slots, "显示品质", -180)
    local qualities = {{"粗糙 · 灰色", "9d9d9d"}, {"普通 · 白色", "ffffff"}, {"优秀 · 绿色", "1eff00"}, {"精良 · 蓝色", "0070dd"}, {"史诗 · 紫色", "a335ee"}, {"传说 · 橙色", "ff8000"}, {"神器 · 金色", "e6cc80"}, {"传家宝 · 浅蓝色", "00ccff"}, {"时光徽章 · 特殊品质", "00ccff"}}
    for i, item in ipairs(qualities) do
        local quality = i - 1
        Check(slots, "|cff" .. item[2] .. item[1] .. "|r", -215 - (i - 1) * 34, function() return NS.db.slotLabels.qualities[quality] end, function(v) NS.db.slotLabels.qualities[quality] = v; NS.modules.slotLabels:Apply() end)
    end
    Label(slots, "默认灰/白/绿关闭，蓝色及以上开启。仅可穿戴装备显示部位。", 0, -540)
    local slotPreview = Label(slots, "脚部     手指     胸部（文字预览）", 0, -584)
    OnRefresh(function() local font, _, flags = slotPreview:GetFont(); slotPreview:SetFont(font, NS.db.slotLabels.size, flags) end)
    local fonts = Page("fonts", "文字与显示 · 字体可读性"); DisplayTabs(fonts)
    ModuleCheck(fonts, "补偿高分辨率下偏小的单位文字与聊天标签", -65, "readability")
    Check(fonts, "仅在 Mac 自动启用（Windows 默认保持原样）", -109,
        function() return NS.db.readability.macOnly end,
        function(v) NS.db.readability.macOnly = v; NS.modules.readability:Apply() end)
    Stepper(fonts, "最低字号", -166, function() return NS.db.readability.size end,
        function(v) NS.db.readability.size = v; NS.modules.readability:Apply() end, 10, 20)
    Label(fonts, "仅在 ShestakUI mult 小于 0.85 时补足小字；保留较大字号、字体与描边。\n不改全局 UI 缩放；FPS、装备部位和 Details 字号各自设置。\n战斗中延后；关闭恢复当前会话内原字号。", 0, -224)
    local fontStatus = Label(fonts, "", 0, -320)
    OnRefresh(function() fontStatus:SetText(NS.modules.readability.status or "等待检查字体。") end)
    Stepper(fonts, "公会 / 密语 / 团队标签字号", -377, function() return NS.db.chatTabs.labelSize or 14 end,
        function(v) NS.db.chatTabs.labelSize = v; NS.modules.chatTabs:Apply() end, 10, 20)
    local compat = Page("compat", "兼容与诊断", 560)
    Section(compat, "Details 窗口避让", 0); ModuleCheck(compat, "自动处理伤害 / 治疗窗口重叠或越界", -34, "detailsLayout")
    Label(compat, "目标框下方至底部线，左避技能栏，右留双列小图标。\n治疗靠右、伤害紧邻；窄则等宽堆叠右对齐（60% / 40%），不缩字号。", 0, -77)
    Button(compat, "立即检查并重新排列", 0, -136, 300, function() NS.modules.detailsLayout:Apply(true) end)
    local layoutStatus = Label(compat, "", 0, -179)
    OnRefresh(function() layoutStatus:SetText(NS.modules.detailsLayout.status or "等待登录后检查。") end)
    Section(compat, "常用窗口与消息", -245)
    ModuleCheck(compat, "ESC 兼容：地图、角色、天赋、专业等窗口", -280, "mapEscape")
    ModuleCheck(compat, "登录静默：已识别插件的加载 / 宣传提示", -319, "quiet")
    ModuleCheck(compat, "竞技场：隐藏重复的玩家加入战斗消息", -358, "arenaSpam")
    Button(compat, "中文聊天标签页", 0, -413, 260, function() NS.modules.chatTabs:OpenOptions() end)
    Label(compat, "窗口诊断：/cplusesc    操作拦截诊断：/cplusdiag\nESC 兼容不能绕过游戏战斗保护。", 0, -464)
    function panel:Refresh()
        for _, fn in ipairs(refreshers) do fn() end
        for key, b in pairs(nav) do b:SetEnabled(not (key == self.selectedPage or key == "numbers" and (self.selectedPage == "fps" or self.selectedPage == "slots" or self.selectedPage == "fonts"))) end
        for _, item in ipairs(subnav) do item.button:SetEnabled(item.key ~= self.selectedPage) end
    end
    local function Fit() panel:SetScale(math.min(1, (UIParent:GetWidth() - 32) / 820, (UIParent:GetHeight() - 32) / 590)) end
    panel:SetScript("OnShow", function() Fit(); panel:Refresh() end)
    panel:RegisterEvent("DISPLAY_SIZE_CHANGED"); panel:RegisterEvent("UI_SCALE_CHANGED"); panel:SetScript("OnEvent", Fit)
    panel:SelectPage("overview")
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local launcher = CreateFrame("Frame"); Label(launcher, "Cuniel_plus", 20, -20, 500, true)
        Button(launcher, "打开功能设置", 20, -60, 200, function() if SettingsPanel then SettingsPanel:Hide() end; panel:Show() end)
        local category = Settings.RegisterCanvasLayoutCategory(launcher, "Cuniel_plus"); Settings.RegisterAddOnCategory(category)
    end
end
