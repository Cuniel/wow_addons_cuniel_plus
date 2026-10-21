local _, NS = ...
local Module = {originals = setmetatable({}, {__mode = "k"}), hooked = setmetatable({}, {__mode = "k"})}
NS:RegisterModule("readability", Module)

function Module:Active()
    local config = NS.db.readability
    local engine = _G.ShestakUI
    local functions = type(engine) == "table" and engine[1]
    if not config.enabled or type(functions) ~= "table" then return false end
    if config.macOnly and not (IsMacClient and IsMacClient()) then return false end
    local mult = functions.mult
    return type(mult) == "number" and mult > 0 and mult < 0.85
end

-- Only known unit labels and chat tabs. Do not change UIParent, the global
-- SetFont method, fonts in item buttons, or user-sized FPS/slot labels.
function Module:Font(fs)
    if not fs or not fs.GetFont or not fs.SetFont or (fs.IsForbidden and fs:IsForbidden()) then return end
    local tabs = NS.modules.chatTabs
    if tabs and tabs.IsManagedLabel and tabs:IsManagedLabel(fs) then self.originals[fs] = nil; return end
    if InCombatLockdown() then self.pending = true; return end
    local font, size, flags = fs:GetFont()
    if not font or type(size) ~= "number" then return end
    local record = self.originals[fs]
    if not self:Active() then
        if record and font == record.font and size == record.applied and flags == record.flags then
            self.running = true; fs:SetFont(record.font, record.size, record.flags); self.running = nil
        end
        self.originals[fs] = nil
        return
    end
    if not record or font ~= record.font or size ~= record.applied or flags ~= record.flags then
        record = {font = font, size = size, flags = flags}; self.originals[fs] = record
    end
    local minimum = math.max(10, math.min(20, tonumber(NS.db.readability.size) or 12))
    local desired = math.max(record.size, minimum)
    record.applied = desired
    if size ~= desired then
        self.running = true; fs:SetFont(font, desired, flags); self.running = nil
    end
    if not self.hooked[fs] and hooksecurefunc then
        self.hooked[fs] = true
        hooksecurefunc(fs, "SetFont", function()
            if not Module.running then Module:Font(fs) end
        end)
    end
end

function Module:Unit(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    for _, key in ipairs({"Info", "Name", "Level", "Status", "ClassMana", "Absorbs"}) do self:Font(frame[key]) end
    for _, key in ipairs({"Health", "Power", "Castbar"}) do
        local element = frame[key]
        if element then
            for _, name in ipairs({"value", "short_value", "Text", "Time", "Delay"}) do self:Font(element[name]) end
        end
    end
end

function Module:Apply()
    if InCombatLockdown() then self.pending = true; self.status = "字体调整等待脱战。"; return end
    self.pending = nil
    -- Include previously changed strings even after their frames leave oUF.objects.
    for fs in pairs(self.originals) do self:Font(fs) end
    local engine = _G.ShestakUI
    local functions = type(engine) == "table" and engine[1]
    local objects = type(functions) == "table" and functions.oUF and functions.oUF.objects
    if type(objects) == "table" then for _, frame in pairs(objects) do self:Unit(frame) end end
    for _, name in ipairs({"oUF_Player", "oUF_Target", "oUF_Focus", "oUF_Pet", "oUF_TargetTarget"}) do self:Unit(_G[name]) end
    for i = 1, 10 do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then self:Font(tab.GetFontString and tab:GetFontString() or tab.Text) end
    end
    self.status = self:Active() and "已补足高分辨率单位文字和聊天标签字号；未改变界面缩放。"
        or "当前不补偿：默认仅在 Mac 且 ShestakUI mult 小于 0.85 时生效。"
end

function Module:Schedule()
    if self.scheduled then return end
    self.scheduled = true
    C_Timer.After(0.2, function() self.scheduled = nil; self:Apply() end)
end

function Module:Initialize()
    self.events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function() self:Schedule() end)
    if hooksecurefunc and type(FCF_OpenNewWindow) == "function" then hooksecurefunc("FCF_OpenNewWindow", function() self:Schedule() end) end
end
