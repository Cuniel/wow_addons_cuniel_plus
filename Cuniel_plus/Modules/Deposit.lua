local _, NS = ...
local Module = {}
NS.Deposit = Module

function Module:ShouldKeep(id)
    if NS.db.deposit.keepIDs[tostring(id)] then return true end
    if not NS.db.deposit.keepFood then return false end
    local _, _, _, _, _, _, _, _, _, _, _, class, subclass = C_Item.GetItemInfo(id)
    -- Unknown items are left alone until their metadata has loaded.
    if not class then
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        return true
    end
    return class == 0 and subclass == 5
end

function Module:Run()
    local bank = Enum.BankType.Account
    if InCombatLockdown() or NS.Sorting.active or GetCursorInfo()
        or not C_Bank.CanUseBank(bank) then return end
    local count = 0
    -- Called only by the button's hardware click; never run item use from a timer.
    for bag = 0, (Enum.BagIndex and Enum.BagIndex.ReagentBag or 5) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not info.isLocked and not self:ShouldKeep(info.itemID) then
                local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local eligible = C_Item.IsItemBindToAccount(info.itemID)
                    or C_Item.IsBoundToAccountUntilEquip(location)
                    or (GetCVarBool("bankAutoDepositReagents") and select(17, C_Item.GetItemInfo(info.itemID)))
                if eligible and C_Bank.IsItemAllowedInBankType(bank, location) then
                    C_Container.UseContainerItem(bag, slot, nil, bank)
                    count = count + 1
                    if count >= 20 then
                        NS:Print("已提交 20 组存放请求；等待背包更新后可再次点击。")
                        return
                    end
                end
            end
        end
    end
    NS:Print(count > 0 and ("已提交 " .. count .. " 组存放请求。") or "没有可存放的物品（已保留食物及排除名单物品）。")
end

function Module:SaveIDs(text)
    local ids = {}
    local normalized = text:gsub("，", ","):gsub("；", ";")
    for token in normalized:gmatch("[^%s,;]+") do
        if not token:match("^%d+$") or tonumber(token) <= 0 then return false end
        ids[tostring(tonumber(token))] = true
    end
    NS.db.deposit.keepIDs = ids
    return true
end

function Module:OpenOptions()
    if self.panel then self.panel:Show(); return end
    local panel = CreateFrame("Frame", "CunielPlusDepositOptions", UIParent, "BasicFrameTemplateWithInset")
    self.panel = panel
    panel:SetSize(480, 330)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel.TitleText:SetText("战团银行 · 保留在背包中的物品")
    tinsert(UISpecialFrames, "CunielPlusDepositOptions")
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, -40)
    local caption = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    caption:SetPoint("LEFT", check, "RIGHT", 0, 0)
    caption:SetText("自动保留食物和饮料（按游戏物品分类）")
    check:SetScript("OnClick", function(s) NS.db.deposit.keepFood = s:GetChecked() and true or false end)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 24, -85)
    label:SetText("不存入战团的物品 ID，以空格或逗号分隔：")
    local edit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", 28, -115)
    edit:SetSize(420, 95)
    edit:SetMultiLine(true)
    edit:SetMaxLetters(2000)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 24, -225)
    note:SetText("名单约束 Cuniel_plus 的“存”按钮，以及已接管的 ShestakUI 战团存放按钮。\n默认保留 242744；未接管的其他插件按钮不受影响。")
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetSize(160, 28)
    save:SetPoint("BOTTOM", 0, 18)
    save:SetText("保存排除名单")
    save:SetScript("OnClick", function()
        if Module:SaveIDs(edit:GetText()) then edit:ClearFocus(); NS:Print("存放排除名单已保存。")
        else NS:Print("请只填写正整数物品 ID，用空格或逗号分隔。") end
    end)
    panel:SetScript("OnShow", function()
        check:SetChecked(NS.db.deposit.keepFood)
        local ids = {}
        for id, enabled in pairs(NS.db.deposit.keepIDs) do if enabled then ids[#ids + 1] = id end end
        table.sort(ids)
        edit:SetText(table.concat(ids, ", "))
    end)
    panel:Hide(); panel:Show()
end
