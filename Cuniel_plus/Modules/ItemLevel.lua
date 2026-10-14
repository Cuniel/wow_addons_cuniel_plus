local _, NS = ...
local Module = {cache = {}, attempted = {}, lastRequest = -10}
NS:RegisterModule("itemLevel", Module)
local function Safe(v) return not issecretvalue or not issecretvalue(v) end
function Module:UsesShestak()
    local config = ShestakUI and ShestakUI[2]
    local tooltip = config and config.tooltip
    return tooltip and tooltip.enable == true and tooltip.average_lvl == true
end
local function Guid(unit)
    local v = UnitGUID(unit)
    if Safe(v) then return v end
end
local function Number(v) return Safe(v) and type(v) == "number" and v > 0 end
local function CurrentUnit()
    if not GameTooltip:IsShown() then return end
    local _, unit = GameTooltip:GetUnit()
    if not Safe(unit) or type(unit) ~= "string" then return end
    local player = UnitIsPlayer(unit)
    if Safe(player) and player then return unit end
end
function Module:ResetHover()
    self.hoverGUID, self.requested = nil, false
    if self.footer then self.footer:Hide() end
end
function Module:Apply() self:ResetHover() end

function Module:RepairShestak()
    if InCombatLockdown() then
        NS:Print("请脱离战斗后再修复装等提示。")
        return false
    end
    local config = ShestakUI and ShestakUI[2]
    local profile = config and config.options
    -- C.options must be the actual SavedVariables profile, not the temporary
    -- empty table Shestak creates when its configuration addon is unavailable.
    local persisted = false
    for _, profiles in ipairs({ShestakUIOptions or {}, ShestakUIOptionsPerChar or {}}) do
        for _, candidate in pairs(profiles) do
            if candidate == profile then persisted = true end
        end
    end
    if type(profile) ~= "table" or not persisted then
        NS:Print("请启用 ShestakUI_Config 并重载，再点击修复装等提示。")
        return false
    end
    if type(profile.tooltip) ~= "table" then profile.tooltip = {} end
    profile.tooltip.average_lvl = false
    NS.db.itemLevel.enabled = true
    -- Keep the running Shestak configuration intact until reload. Its private
    -- OnUpdate was installed at file load and cannot be safely removed here.
    ReloadUI()
    return true
end
function Module:Display(guid, value)
    if not NS.db.itemLevel.enabled or self:UsesShestak() or not Number(value) or self.hoverGUID ~= guid then return end
    local unit = CurrentUnit()
    if not unit or Guid(unit) ~= guid then return end
    -- A separate footer never rebuilds GameTooltip or triggers its OnShow hooks.
    local text = string.format("装等  %.1f", value)
    if self.lastText ~= text then self.label:SetText(text); self.lastText = text end
    if not self.footer:IsShown() then self.footer:Show() end
end
function Module:Tick()
    if not NS.db.itemLevel.enabled or self:UsesShestak() or InCombatLockdown() then self:ResetHover(); return end
    local unit = CurrentUnit()
    local guid = unit and Guid(unit)
    if not guid then self:ResetHover(); return end
    local now = GetTime()
    if guid ~= self.hoverGUID then
        self:ResetHover()
        self.hoverGUID, self.hoverSince = guid, now
    end
    local isSelf = UnitIsUnit(unit, "player")
    if not Safe(isSelf) then return end
    if isSelf then
        if not self.requested then
            self.requested = true
            local _, equipped = GetAverageItemLevel()
            self:Display(guid, equipped)
        end
        return
    end
    local cached = self.cache[guid]
    if cached and now - cached.time < 120 then self:Display(guid, cached.value); return end
    if self.requested or now - self.hoverSince < 0.6 or now - self.lastRequest < 3 then return end
    if self.attempted[guid] and now - self.attempted[guid] < 15 then return end
    if InspectFrame and InspectFrame:IsShown() then return end
    local canInspect = CanInspect(unit)
    if not Safe(canInspect) or not canInspect then return end
    self.requested, self.lastRequest, self.attempted[guid] = true, now, now
    NotifyInspect(unit)
end
function Module:Initialize()
    local footer = CreateFrame("Frame", "CunielPlusItemLevel", GameTooltip, "BackdropTemplate")
    self.footer = footer
    footer:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -1)
    footer:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", 0, -1)
    footer:SetHeight(23)
    footer:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    footer:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
    footer:EnableMouse(false)
    self.label = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.label:SetPoint("LEFT", 9, 0)
    self.label:SetTextColor(1, 0.82, 0)
    footer:Hide()
    GameTooltip:HookScript("OnHide", function() Module:ResetHover() end)
    local frame, elapsed = CreateFrame("Frame"), 0
    frame:RegisterEvent("INSPECT_READY")
    frame:SetScript("OnEvent", function(_, _, guid)
        if not NS.db.itemLevel.enabled or Module:UsesShestak() or InCombatLockdown() or not Safe(guid) or not guid then return end
        local unit = CurrentUnit()
        if not unit or Guid(unit) ~= guid or Module.hoverGUID ~= guid then return end
        if not C_PaperDollInfo or not C_PaperDollInfo.GetInspectItemLevel then return end
        local value = C_PaperDollInfo.GetInspectItemLevel(unit)
        if Number(value) then
            Module.cache[guid] = {value = value, time = GetTime()}
            Module:Display(guid, value)
        end
    end)
    hooksecurefunc("NotifyInspect", function() Module.lastRequest = GetTime() end)
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.25 then elapsed = 0; Module:Tick() end
    end)
    self.events = frame
end
