local _, NS = ...
local Module = {frames = setmetatable({}, {__mode = "k"})}
NS:RegisterModule("bagPosition", Module)

function Module:HookDepositButton()
    local stuffing = _G.Stuffing
    local frame = stuffing and stuffing.warbandFrame
    local button = frame and frame.b_deposit
    if not button or button.cunielPlusDeposit then return end

    button.cunielPlusDeposit = true
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            local enabled = GetCVarBool("bankAutoDepositReagents")
            SetCVar("bankAutoDepositReagents", enabled and 0 or 1)
            local onEnter = self:GetScript("OnEnter")
            if onEnter then onEnter(self) end
            return
        end
        if InCombatLockdown() then
            NS:Print("请脱离战斗后存入战团银行。")
            return
        end
        NS.Deposit:Run()
    end)
    button:HookScript("OnEnter", function(self)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Cuniel_plus 已接管", 0.4, 0.8, 1)
        GameTooltip:AddLine("自动保留食物及排除名单中的物品。", 1, 1, 1, true)
        GameTooltip:Show()
    end)
end

function Module:PositionBag()
    if InCombatLockdown() then return end
    local stuffing = _G.Stuffing
    local frame = stuffing and stuffing.frame or _G.StuffingFrameBags
    if not frame or type(frame.GetPoint) ~= "function" then return end

    local state = self.frames[frame]
    if not state then
        local point, relative, relativePoint, x, y = frame:GetPoint(1)
        if not point then return end
        state = {point, relative or UIParent, relativePoint or point, x or 0, y or 0}
        self.frames[frame] = state
        frame:HookScript("OnShow", function()
            C_Timer.After(0, function() Module:PositionBag() end)
        end)
    end

    local x, y = state[4], state[5]
    if NS.db.bagPosition.enabled then
        x = x + (NS.db.bagPosition.x or -55)
        y = y + (NS.db.bagPosition.y or 40)
    end
    frame:ClearAllPoints()
    frame:SetPoint(state[1], state[2], state[3], x, y)
end

function Module:Refresh()
    self:HookDepositButton()
    self:PositionBag()
end

function Module:Apply()
    C_Timer.After(0, function() Module:Refresh() end)
end

function Module:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("BANKFRAME_OPENED")
    events:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function()
        C_Timer.After(0, function() Module:Refresh() end)
        C_Timer.After(0.3, function() Module:Refresh() end)
    end)
end
