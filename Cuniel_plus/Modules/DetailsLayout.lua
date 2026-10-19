local _, NS = ...
local Module = {originals = {}}
NS:RegisterModule("detailsLayout", Module)

local function Overlap(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
local function Inside(r, width, height)
    return r.x >= 8 and r.y >= 8 and r.x + r.w <= width - 8 and r.y + r.h <= height - 8
end

-- All geometry is in UIParent units, never in raw screen pixels. The planner
-- includes title/skin margins, so text and borders count as occupied space.
function Module.Plan(width, height, windows, obstacles, force)
    if #windows ~= 2 then return end
    local invalid = force or Overlap(windows[1], windows[2])
    for _, r in ipairs(windows) do
        if not Inside(r, width, height) then invalid = true end
        for _, o in ipairs(obstacles) do if Overlap(r, o) then invalid = true end end
    end
    if not invalid then return end
    local rights, bottoms = {width - 12}, {24}
    for _, o in ipairs(obstacles) do
        if o.x > width * 0.5 then table.insert(rights, 1, o.x - 12) end
        if o.y + o.h < height * 0.6 then bottoms[#bottoms + 1] = o.y + o.h + 12 end
    end
    local a, b, gap = windows[1], windows[2], 12
    for _, bottom in ipairs(bottoms) do
        for _, right in ipairs(rights) do
            for _, mode in ipairs({"row", "column"}) do
                local plan
                if mode == "row" then
                    plan = {{x = right - a.w - gap - b.w, y = bottom, w = a.w, h = a.h},
                        {x = right - b.w, y = bottom, w = b.w, h = b.h}}
                else
                    plan = {{x = right - a.w, y = bottom, w = a.w, h = a.h},
                        {x = right - b.w, y = bottom + a.h + gap, w = b.w, h = b.h}}
                end
                local fits = true
                for _, r in ipairs(plan) do
                    if not Inside(r, width, height) or r.x < width * 0.38 or r.y + r.h > height * 0.68 then fits = false end
                    for _, o in ipairs(obstacles) do if Overlap(r, o) then fits = false end end
                end
                if fits then return plan, mode end
            end
        end
    end
    return nil, "no-space"
end

local function Rect(frame, padded)
    if not frame or not frame.IsShown or not frame:IsShown() or not frame.GetRect then return end
    if frame.IsVisible and not frame:IsVisible() then return end
    local x, y, w, h = frame:GetRect()
    if not x or not y or not w or not h or w <= 0 or h <= 0 then return end
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    if ratio <= 0 then return end
    local side, bottom, top = padded and 28 or 6, padded and 6 or 6, padded and 24 or 6
    return {x = x * ratio - side, y = y * ratio - bottom,
        w = w * ratio + side * 2, h = h * ratio + bottom + top}
end

function Module:Collect()
    local details = _G.Details
    local found, windows, obstacles = {}, {}, {}
    if type(details) ~= "table" or type(details.tabela_instancias) ~= "table" then return windows, obstacles end
    for _, instance in ipairs(details.tabela_instancias) do
        local frame = instance.baseframe
        if frame and not self.hooked[frame] then
            self.hooked[frame] = true
            for _, event in ipairs({"OnShow", "OnSizeChanged", "OnDragStop"}) do
                frame:HookScript(event, function() if not Module.running then Module:Schedule() end end)
            end
        end
        local display = instance.GetDisplay and instance:GetDisplay()
        local r = Rect(frame, true)
        if r and (display == 1 or display == 2) and not found[display] then
            found[display] = {instance = instance, frame = frame, rect = r}
        elseif r then obstacles[#obstacles + 1] = r end
    end
    if found[1] and found[2] then windows = {found[1], found[2]} end
    for _, name in ipairs({"Minimap", "oUF_Player", "oUF_Target"}) do
        local r = Rect(_G[name]); if r then obstacles[#obstacles + 1] = r end
    end
    for _, prefix in ipairs({"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarLeftButton", "MultiBarRightButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}) do
        for i = 1, 12 do
            local r = Rect(_G[prefix .. i]); if r then obstacles[#obstacles + 1] = r end
        end
    end
    return windows, obstacles
end

function Module:Restore()
    for instance, point in pairs(self.originals) do
        if instance.baseframe and instance.RestorePositionFromPositionTable then
            instance:RestorePositionFromPositionTable(point)
        end
    end
    self.originals = {}
end

function Module:Apply(force)
    if InCombatLockdown() then self.pending = true; self.status = "战斗中暂不移动窗口，脱战后检查。"; return end
    self.pending = nil
    if not NS.db.detailsLayout.enabled then self:Restore(); self.status = "自动避让已关闭。"; return end
    if not self.loggedIn then return end
    self.hooked = self.hooked or setmetatable({}, {__mode = "k"})
    local windows, obstacles = self:Collect()
    if #windows ~= 2 then self.status = "等待 Details 伤害与治疗两个窗口显示。"; return end
    for _, item in ipairs(windows) do
        if item.frame.IsMouseOver and item.frame:IsMouseOver() and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then return end
        if not item.instance.CreatePositionTable or not item.instance.SaveMainWindowPosition
            or not item.instance.RestorePositionFromPositionTable then
            self.status = "当前 Details 版本缺少兼容的位置接口，未移动窗口。"; return
        end
    end
    local plan, mode = self.Plan(UIParent:GetWidth(), UIParent:GetHeight(),
        {windows[1].rect, windows[2].rect}, obstacles, force == true)
    if not plan then
        self.status = mode == "no-space" and "可用空间不足，未缩小字体或覆盖现有布局；请手动留出空间。"
            or "两个窗口没有重叠或越界，保留当前位置。"
        return
    end
    self.running = true
    for i, item in ipairs(windows) do
        local frame, instance = item.frame, item.instance
        if not self.originals[instance] then self.originals[instance] = instance:CreatePositionTable() end
        local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (plan[i].x + 28) / ratio, (plan[i].y + 6) / ratio)
        instance:SaveMainWindowPosition()
    end
    self.running = nil
    self.status = mode == "row" and "已将伤害与治疗窗口并排避让。" or "横向空间不足，已将伤害与治疗窗口上下排列。"
end

function Module:Schedule()
    if self.scheduled then return end
    self.scheduled = true
    C_Timer.After(0.5, function() self.scheduled = nil; self:Apply() end)
end

function Module:Initialize()
    self.events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "PLAYER_REGEN_ENABLED", "ADDON_LOADED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event, addon)
        if event == "ADDON_LOADED" and addon ~= "Details" then return end
        if event == "PLAYER_ENTERING_WORLD" then self.loggedIn = true end
        self:Schedule()
    end)
end
