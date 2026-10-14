local _, NS = ...
local Module = {toolbars = {}}
NS:RegisterModule("bags", Module)

local function SaleConfig()
    local stats = _G.ShestakUIStats
    local realm = stats and stats[GetRealmName()]
    return realm and realm[UnitName("player")]
end
function Module:GetAutoSell()
    local conf = SaleConfig()
    return conf and conf.AutoSell, conf ~= nil
end
function Module:SetAutoSell(enabled)
    local conf = SaleConfig()
    if conf then conf.AutoSell = enabled and true or false
    else NS:Print("请启用 ShestakUI；此开关复用它的自动售卖功能。") end
end
local function Live(frame, bank, bankType)
    if not frame:IsShown() or InCombatLockdown() then return false end
    local owner = frame:GetOwner()
    if not owner or owner.offline or frame:IsCached() then return false end
    if bank then
        return C_Bank and C_Bank.CanUseBank(bankType)
            and Addon_GetBankType and Addon_GetBankType() == bankType
    end
    return true
end

function Module:MakeButton(frame, key, text, description, callback)
    local toolbar = self.toolbars[frame]
    if toolbar.buttons[key] then return toolbar.buttons[key] end
    local button = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    button:SetSize(23, 23)
    button:SetText(text)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouse)
        if not NS.db.bags.enabled then return end
        callback(mouse)
        if button:IsMouseOver() then button:GetScript("OnEnter")(button) end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Cuniel_plus · " .. description())
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    toolbar.buttons[key] = button
    return button
end

function Module:AddButtons(frame, buttons, bank)
    if not NS.db.bags.enabled then return buttons end
    if not bank then
        buttons[#buttons + 1] = self:MakeButton(frame, "sell", "售", function()
            local conf = SaleConfig()
            return "自动售卖垃圾：" .. (conf and (conf.AutoSell and "开启" or "关闭") or "ShestakUI 未就绪")
                .. "\n点击切换当前角色的 ShestakUI 开关；下次打开商人时生效。"
        end, function()
            local owner = frame:GetOwner()
            if owner and owner.offline then NS:Print("请切回当前角色的背包后操作。"); return end
            local conf = SaleConfig()
            if conf then conf.AutoSell = not conf.AutoSell else NS:Print("需要启用 ShestakUI 才能切换自动售卖。") end
        end)
    end
    buttons[#buttons + 1] = self:MakeButton(frame, "sort", "整", function()
        return "ShestakUI 原版整理规则（移植）\n使用原版排序键和从后向前摆放；左右键相同。"
            .. (bank and "\n范围为当前银行可操作的标签页。" or "\n与原版一致：整理普通背包，材料包不参与。")
            .. "\n再次点击停止。"
    end, function(mouse)
        if NS.Sorting.active then NS.Sorting:Stop("已停止整理。"); return end
        local addon = _G.Bagnon
        local bankType = bank and Addon_GetBankType and Addon_GetBankType() or nil
        if bank and bankType ~= Enum.BankType.Character and bankType ~= Enum.BankType.Account then
            NS:Print("无法识别当前银行类型。"); return
        end
        local bags = {}
        for _, bag in ipairs(bank and addon.BankBags or addon.InventoryBags) do
            local matching = not bank or (bankType == Enum.BankType.Account and bag > addon.LastBankBag)
                or (bankType == Enum.BankType.Character and bag <= addon.LastBankBag)
            if matching and not frame:IsCached(bag) and C_Container.GetContainerNumSlots(bag) > 0 then
                bags[#bags + 1] = bag
            end
        end
        NS.Sorting:Start(bags, bank, function() return NS.db.bags.enabled and Live(frame, bank, bankType) end)
    end)
    if bank then
        buttons[#buttons + 1] = self:MakeButton(frame, "deposit", "存", function()
            return "存入战团银行\n左键：过滤食物及排除名单后存放（每次最多20组）。\n右键：切换包含制作材料，当前"
                .. (GetCVarBool("bankAutoDepositReagents") and "开启" or "关闭")
        end, function(mouse)
            if mouse == "RightButton" then
                SetCVar("bankAutoDepositReagents", GetCVarBool("bankAutoDepositReagents") and "0" or "1")
                return
            end
            local owner = frame:GetOwner()
            if InCombatLockdown() or NS.Sorting.active or (owner and owner.offline) or frame:IsCached()
                or GetCursorInfo() or not C_Bank or not C_Bank.CanUseBank(Enum.BankType.Account) then
                NS:Print("请脱战、停止整理，并在可操作战团银行时存入。"); return
            end
            NS.Deposit:Run()
        end)
    end
    return buttons
end

-- Do not replace Bagnon class methods or call its Layout: keep our controls external.
function Module:RefreshToolbars()
    for frame, toolbar in pairs(self.toolbars) do
        if not NS.db.bags.enabled or InCombatLockdown() or not frame:IsShown() then toolbar:Hide() end
    end
    if not NS.db.bags.enabled or InCombatLockdown() then return end
    local addon = _G.Bagnon
    if not addon or not addon.Frames or not addon.Frames.Iterate then return end
    for _, frame in addon.Frames:Iterate() do
        if type(frame.IsShown) == "function" and frame:IsShown() and (frame.id == "inventory" or frame.id == "bank") then
            local toolbar = self.toolbars[frame]
            if not toolbar then
                toolbar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
                toolbar.buttons = {}
                toolbar:SetSize(100, 27)
                toolbar:SetClampedToScreen(true)
                toolbar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
                toolbar:SetBackdropColor(0, 0, 0, .8)
                self.toolbars[frame] = toolbar
            end
            toolbar:ClearAllPoints()
            toolbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
            toolbar:SetFrameStrata(frame:GetFrameStrata())
            toolbar:SetFrameLevel(frame:GetFrameLevel() + 10)
            local buttons = self:AddButtons(frame, {}, frame.id == "bank")
            for i, button in ipairs(buttons) do
                button:ClearAllPoints()
                button:SetPoint("LEFT", toolbar, "LEFT", 3 + (i - 1) * 26, 0)
            end
            toolbar:SetWidth(6 + #buttons * 26)
            toolbar:Show()
        end
    end
end
function Module:Apply()
    if not NS.db.bags.enabled and NS.Sorting.active then NS.Sorting:Stop() end
    self:RefreshToolbars()
end
function Module:Initialize()
    local events, elapsed = CreateFrame("Frame"), 0
    events:RegisterEvent("ADDON_ACTION_BLOCKED")
    events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    events:SetScript("OnEvent", function(_, event, addon, operation)
        if (issecretvalue and (issecretvalue(addon) or issecretvalue(operation))) then return end
        NS.db.bagDiagnostics = NS.db.bagDiagnostics or {}
        local records = NS.db.bagDiagnostics
        records[#records + 1] = {event=event, addon=addon, operation=operation, time=date("%m-%d %H:%M:%S")}
        if #records > 12 then table.remove(records, 1) end
    end)
    events:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= .5 then elapsed = 0; Module:RefreshToolbars() end
    end)
    SLASH_CUNIELPLUSDIAG1 = "/cplusdiag"
    SlashCmdList.CUNIELPLUSDIAG = function()
        local records = NS.db.bagDiagnostics or {}
        if #records == 0 then NS:Print("暂未记录到受保护操作拦截。") end
        for _, record in ipairs(records) do
            NS:Print((record.time or "") .. " " .. tostring(record.addon) .. " " .. tostring(record.operation))
        end
    end
end
