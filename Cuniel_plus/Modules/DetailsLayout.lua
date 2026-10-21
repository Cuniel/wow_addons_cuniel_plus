local _, NS = ...
local Module = {originals = {}, hooked = setmetatable({}, {__mode = "k"})}
NS:RegisterModule("detailsLayout", Module)

-- The caller supplies a measured rectangle: action bars -> minimap icon strip,
-- bottom information line -> target frame bottom. No screen-percent placement.
local GAP = 8
local PANE_GAP = 2
local function Cells(bounds, obstacles)
    local cells = {{x = bounds.left, y = bounds.bottom,
        w = bounds.right - bounds.left, h = bounds.top - bounds.bottom}}
    for _, o in ipairs(obstacles) do
        local nextCells = {}
        for _, c in ipairs(cells) do
            local left, right = math.max(c.x, o.x - GAP), math.min(c.x + c.w, o.x + o.w + GAP)
            local bottom, top = math.max(c.y, o.y - GAP), math.min(c.y + c.h, o.y + o.h + GAP)
            if right <= left or top <= bottom then
                nextCells[#nextCells + 1] = c
            else
                -- Disjoint pieces, all strictly inside the measured bounds.
                if bottom > c.y then nextCells[#nextCells + 1] = {x = c.x, y = c.y, w = c.w, h = bottom - c.y} end
                if top < c.y + c.h then nextCells[#nextCells + 1] = {x = c.x, y = top, w = c.w, h = c.y + c.h - top} end
                if left > c.x then nextCells[#nextCells + 1] = {x = c.x, y = bottom, w = left - c.x, h = top - bottom} end
                if right < c.x + c.w then nextCells[#nextCells + 1] = {x = right, y = bottom, w = c.x + c.w - right, h = top - bottom} end
            end
        end
        cells = nextCells
        if #cells > 128 then return {} end
    end
    table.sort(cells, function(a, b)
        local areaA, areaB = a.w * a.h, b.w * b.h
        if math.abs(areaA - areaB) > 1 then return areaA > areaB end
        if a.y ~= b.y then return a.y < b.y end
        return a.x > b.x
    end)
    return cells
end

function Module.Plan(width, height, windows, obstacles, force, bounds)
    if #windows ~= 2 or not bounds then return nil, "missing-bounds" end
    if bounds.left < 0 or bounds.bottom < 0 or bounds.right > width or bounds.top > height
        or bounds.right <= bounds.left or bounds.top <= bounds.bottom then return nil, "no-space" end
    local cells = Cells(bounds, obstacles)
    -- A side-by-side pair needs the original readable width of BOTH windows.
    -- Shrinking an existing column must not make it spuriously flip into a row.
    local preferred = math.max(windows[1].preferredW or windows[1].w, windows[2].preferredW or windows[2].w)
    local minimum = math.max(windows[1].minW or 160, windows[2].minW or 160)
    for _, mode in ipairs({"row", "column"}) do
        for _, c in ipairs(cells) do
            local paneWidth = mode == "row" and preferred or math.min(preferred, c.w)
            local needWidth = mode == "row" and preferred or minimum
            local groupWidth = mode == "row" and paneWidth * 2 + PANE_GAP or paneWidth
            -- Healing is the right-hand anchor. Never stretch the two windows
            -- across empty width or slide the group left into another cell.
            if paneWidth >= needWidth and groupWidth <= c.w and math.abs(c.x + c.w - bounds.right) < 0.001 then
                local startX = bounds.right - groupWidth
                local budget = mode == "row" and c.h or c.h - PANE_GAP
                local plan, fits = {}, budget > 0
                for i, r in ipairs(windows) do
                    local overhead, row = r.overhead or 30, r.row or 20
                    local share = mode == "row" and 1 or (i == 1 and 0.6 or 0.4)
                    local count = math.floor((budget * share - overhead) / row)
                    if count < 1 then fits = false end
                    plan[i] = {x = startX + (mode == "row" and (i - 1) * (paneWidth + PANE_GAP) or 0),
                        y = c.y, w = paneWidth, h = count * row + overhead, rows = count}
                end
                if mode == "column" then plan[2].y = plan[1].y + plan[1].h + PANE_GAP end
                if fits then
                    local changed = force
                    for i, r in ipairs(windows) do
                        local q = plan[i]
                        if math.abs(q.x - r.x) > 1 or math.abs(q.y - r.y) > 1
                            or math.abs(q.w - r.w) > 1 or math.abs(q.h - r.h) > 1 then changed = true end
                    end
                    return changed and plan or nil, mode
                end
            end
        end
    end
    return nil, "no-space"
end

local function Number(value)
    return not (issecretvalue and issecretvalue(value)) and type(value) == "number"
        and value == value and value > -math.huge and value < math.huge
end

local function Rect(frame, padded, includeHidden)
    if not frame then return end
    if frame.IsForbidden and frame:IsForbidden() then return end
    if not frame.GetRect or not frame.GetEffectiveScale then return end
    if not includeHidden and (not frame.IsShown or not frame:IsShown()) then return end
    if not includeHidden and frame.IsVisible and not frame:IsVisible() then return end
    local x, y, w, h = frame:GetRect()
    if not Number(x) or not Number(y) or not Number(w) or not Number(h) or w <= 0 or h <= 0 then return end
    local scale, parentScale = frame:GetEffectiveScale(), UIParent:GetEffectiveScale()
    if not Number(scale) or not Number(parentScale) or parentScale <= 0 then return end
    local ratio = scale / parentScale
    if ratio <= 0 then return end
    local raw = padded == "raw"
    local side = raw and 0 or padded and 36 * ratio or 6
    local bottom = raw and 0 or padded and 6 * ratio or 6
    local top = raw and 0 or padded and 26 * ratio or 6
    return {x = x * ratio - side, y = y * ratio - bottom,
        w = w * ratio + side * 2, h = h * ratio + bottom + top,
        ratio = ratio, side = side, bottom = bottom, overhead = bottom + top}
end

function Module:WatchAnchor(frame)
    if not frame or not frame.HookScript or (frame.IsForbidden and frame:IsForbidden()) then return end
    self.watchedAnchors = self.watchedAnchors or setmetatable({}, {__mode = "k"})
    if self.watchedAnchors[frame] then return end
    self.watchedAnchors[frame] = true
    local function Changed() self:Schedule() end
    for _, event in ipairs({"OnShow", "OnHide", "OnSizeChanged", "OnDragStop"}) do frame:HookScript(event, Changed) end
    if hooksecurefunc and frame.SetPoint then hooksecurefunc(frame, "SetPoint", Changed) end
end

function Module:Bounds(width, height, obstacles)
    local target = Rect(_G.oUF_Target, "raw", true)
    local map = Rect(_G.MinimapAnchor, "raw", true) or Rect(_G.Minimap, "raw", true)
    if not target or not map then return end
    local targetBottom = target.y
    local function Beside(r)
        -- Portraits normally sit just OUTSIDE the health frame, not on top
        -- of it. Reserve their footprint even before a target is selected.
        return r and r.x <= target.x + target.w + GAP * 2
            and target.x <= r.x + r.w + GAP * 2
    end
    for _, key in ipairs({"Portrait", "Castbar"}) do
        local child = Rect(_G.oUF_Target[key], "raw", true)
        -- Only descendants actually beside the target, not a detached castbar.
        if Beside(child) then
            targetBottom = math.min(targetBottom, child.y)
        end
        self:WatchAnchor(_G.oUF_Target[key])
    end
    local targetTarget = Rect(_G.oUF_TargetTarget, "raw", true)
    if Beside(targetTarget) then
        targetBottom = math.min(targetBottom, targetTarget.y)
    end
    local line = Rect(_G.BottomPanel, "raw", true)
    local bottom = line and line.y + line.h + 2 or 2
    local collect = Rect(_G.ButtonCollectFrame, "raw", true)
    local iconWidth = collect and collect.w or 20.8
    local iconGap = collect and collect.ratio or 1
    local stripRight = collect and math.min(map.x, collect.x + collect.w) or map.x
    local right = math.min(width - GAP, stripRight - 2 * (iconWidth + iconGap) - GAP)
    local top = math.min(height - GAP, targetBottom - GAP)
    local left
    for _, o in ipairs(obstacles) do
        if o.action and (o.mainAction or o.x + o.w * 0.5 < (target.x + target.w * 0.5))
            and o.y < top and o.y + o.h > bottom then
            left = math.max(left or 0, o.x + o.w + GAP)
        end
    end
    -- When action bars are hidden keep a target-relative right-hand region.
    left = math.max(GAP, left or target.x)
    return {left = left, right = right, bottom = bottom, top = top,
        iconReserve = map.x - right}
end

function Module:Collect()
    local details = _G.Details
    local found, windows, obstacles = {}, {}, {}
    if type(details) ~= "table" or type(details.tabela_instancias) ~= "table" then return windows, obstacles end
    for _, instance in ipairs(details.tabela_instancias) do
        local frame = instance.baseframe
        if frame and not (frame.IsForbidden and frame:IsForbidden()) and not self.hooked[frame] then
            self.hooked[frame] = true
            for _, event in ipairs({"OnShow", "OnSizeChanged", "OnDragStop", "OnMouseUp"}) do
                frame:HookScript(event, function() if not Module.running then Module:Schedule() end end)
            end
            if hooksecurefunc then
                for _, method in ipairs({"SetPoint", "SetScale"}) do
                    if frame[method] then hooksecurefunc(frame, method, function()
                        if not Module.running then Module:Schedule(true) end
                    end) end
                end
            end
        end
        local display = instance.GetDisplay and instance:GetDisplay()
        local r = Rect(frame, true)
        if r then
            self.preferredWidths = self.preferredWidths or setmetatable({}, {__mode = "k"})
            if not self.preferredWidths[instance] then self.preferredWidths[instance] = (r.w - r.side * 2) / r.ratio end
            r.preferredW = (self.preferredWidths[instance] + 72) * r.ratio
            r.minW = (160 + 72) * r.ratio
            local info = instance.row_info
            local row = info and Number(info.height) and info.height or 14
            local space = info and info.space and info.space.between
            row = row + (Number(space) and math.max(space, 0) or 0)
            r.row = math.max(row, 1) * r.ratio
        end
        if r and (display == 1 or display == 2) and not found[display] then
            found[display] = {instance = instance, frame = frame, rect = r}
        elseif r then obstacles[#obstacles + 1] = r end
    end
    if found[1] and found[2] then windows = {found[1], found[2]} end
    for _, name in ipairs({"Minimap", "oUF_Player", "oUF_Target", "oUF_TargetTarget", "ObjectiveTrackerFrame", "ScenarioObjectiveTracker"}) do
        local owner = _G[name]
        local unit = name == "oUF_Target" or name == "oUF_Player" or name == "oUF_TargetTarget"
        local r = Rect(owner, nil, unit)
        if r then r.minimap = name == "Minimap"; obstacles[#obstacles + 1] = r end
        if name == "oUF_Target" or name == "oUF_Player" then
            for _, key in ipairs({"Portrait", "Castbar", "Buffs", "Debuffs"}) do
                local child = owner and Rect(owner[key], nil, true)
                if child then obstacles[#obstacles + 1] = child end
            end
        end
    end
    local measuredBars = 0
    for _, prefix in ipairs({"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarLeftButton", "MultiBarRightButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button", "PetActionButton", "StanceButton"}) do
        for i = 1, 12 do
            local r = Rect(_G[prefix .. i])
            if r then
                r.action = true
                r.mainAction = prefix == "ActionButton" or prefix == "MultiBarBottomLeftButton" or prefix == "MultiBarBottomRightButton"
                obstacles[#obstacles + 1] = r; measuredBars = measuredBars + 1
            end
        end
    end
    for _, name in ipairs({"Bar1Holder", "Bar2Holder", "Bar3Holder",
        "Bar4Holder", "Bar5Holder", "Bar6Holder", "Bar7Holder", "Bar8Holder"}) do
        local frame = _G[name]
        local r = Rect(frame)
        if r then r.action = true; obstacles[#obstacles + 1] = r; measuredBars = measuredBars + 1 end
        self:WatchAnchor(frame)
    end
    for _, name in ipairs({"ActionBarAnchor", "SplitBarLeft", "SplitBarRight", "RightActionBarAnchor", "PetActionBarAnchor", "StanceBarAnchor"}) do
        local frame = _G[name]
        -- Layout anchors may still have a 12-slot width in bar editor mode;
        -- use actual buttons/holders first rather than reserve phantom slots.
        local r = measuredBars == 0 and Rect(frame)
        if r then
            r.action = true; r.mainAction = name == "ActionBarAnchor" or name == "SplitBarLeft" or name == "SplitBarRight"
            obstacles[#obstacles + 1] = r
        end
        self:WatchAnchor(frame)
    end
    for _, name in ipairs({"oUF_Target", "oUF_TargetTarget", "Minimap", "MinimapAnchor", "ButtonCollectFrame", "BottomPanel"}) do self:WatchAnchor(_G[name]) end
    return windows, obstacles
end

function Module:Restore()
    self.running = true
    for instance, point in pairs(self.originals) do
        if instance.baseframe and instance.RestorePositionFromPositionTable then
            instance:RestorePositionFromPositionTable(point)
        end
    end
    self.originals = {}
    self.running = nil
end

function Module:Apply(force)
    self.pending = nil
    if not NS.db.detailsLayout.enabled then
        if InCombatLockdown() then self.pending = true; self.status = "脱战后恢复原位置和尺寸。"; return end
        self:Restore(); self.status = "自动避让已关闭。"; return
    end
    if not self.loggedIn then return end
    self.hooked = self.hooked or setmetatable({}, {__mode = "k"})
    local windows, obstacles = self:Collect()
    if #windows ~= 2 then self.status = "等待 Details 伤害与治疗两个窗口显示。"; return end
    for _, item in ipairs(windows) do
        for _, frame in ipairs({item.frame, item.instance.rowframe}) do
            if InCombatLockdown() and (not frame.IsProtected or frame:IsProtected()) then
                self.pending = true; self.status = "受保护窗口等待脱战后排列。"; return
            end
        end
        if item.frame.isMoving then self.status = "正在拖动窗口，松开鼠标后检查。"; return end
        if item.frame.IsMouseOver and item.frame:IsMouseOver() and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then return end
        if not item.instance.CreatePositionTable or not item.instance.SaveMainWindowPosition
            or not item.instance.RestorePositionFromPositionTable or not item.instance.SetSize then
            self.status = "当前 Details 缺少兼容的位置/尺寸接口，未改变窗口。"; return
        end
    end
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local bounds = self:Bounds(width, height, obstacles)
    self.bounds = bounds
    if not bounds then self.status = "等待目标框与小地图的位置，暂不猜测可用区域。"; return end
    local signature = string.format("%.1f/%.1f/%.1f/%.1f", bounds.left, bounds.right, bounds.bottom, bounds.top)
    if signature ~= self.boundsSignature then self.repairs = 0; self.boundsSignature = signature end
    local plan, mode = self.Plan(width, height, {windows[1].rect, windows[2].rect}, obstacles, force == true, bounds)
    self.mode = mode
    if not plan then
        self.status = mode == "no-space" and "目标框下方可用空间不足，请手动留空间；未越过动作条或图标预留区。"
            or (mode == "row" and "已等宽并排，位于目标框下方；右侧预留双列图标。"
                or "已等宽上下排列（伤害 60% / 治疗 40%），总高度限制在目标框下方。")
        return
    end
    if force then self.repairs = 0 end
    if (self.repairs or 0) >= 4 then self.status = "其他布局持续改写位置，已停止争抢；请关闭 Details 吸附后主动重新排列。"; return end
    self.repairs = (self.repairs or 0) + 1
    self.running = true
    for i, item in ipairs(windows) do
        local frame, instance = item.frame, item.instance
        if not self.originals[instance] then self.originals[instance] = instance:CreatePositionTable() end
        local rect, target = item.rect, plan[i]
        local ratio = rect.ratio
        -- Details' SetSize triggers its row clipping/reflow, not a font change.
        instance:SetSize((target.w - rect.side * 2) / ratio, (target.h - rect.overhead) / ratio)
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (target.x + rect.side) / ratio, (target.y + rect.bottom) / ratio)
        instance:SaveMainWindowPosition()
    end
    self.running = nil
    self.status = mode == "row" and "已等宽并排：伤害在左、治疗在右，未超过目标框下方。"
        or "已等宽上下排列：伤害下方 60% / 治疗上方 40%，总高度未超过目标框下方。"
end

function Module:Schedule(external)
    if self.running or (not NS.db.detailsLayout.enabled and not self.pending) then return end
    if external then self.externalMoves = (self.externalMoves or 0) + 1 end
    if self.scheduled then return end
    self.scheduled = true
    C_Timer.After(0.5, function() self.scheduled = nil; self:Apply() end)
end

function Module:Initialize()
    self.events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ADDON_LOADED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event, addon)
        if event == "ADDON_LOADED" and addon ~= "Details" then return end
        if event == "PLAYER_ENTERING_WORLD" then self.loggedIn = true end
        self.repairs = 0
        self:Schedule()
    end)
end
