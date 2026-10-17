local _, NS = ...

local Module = {inserted = {}}
NS:RegisterModule("mapEscape", Module)

local FRAME_NAMES = {
    "WorldMapFrame",
    "FlightMapFrame", -- Modern flight-master map, not WorldMapFrame
    "TaxiFrame", -- Legacy flight-master route map
    -- Character, reputation and currency are tabs of this same top-level frame.
    "CharacterFrame",
    -- Explicit top-level browsing windows only. Do not include transaction
    -- windows (bank, trade, merchant), popups, or nested talent editors.
    "PlayerSpellsFrame", -- Specializations, talents and spellbook
    "ProfessionsBookFrame",
    "ProfessionsFrame",
    "CollectionsJournal",
    "EncounterJournal",
    "AchievementFrame",
    "InspectFrame",
    "PVEFrame",
    "FriendsFrame",
    "CommunitiesFrame",
    "MacroFrame",
}

local function FindFrame(frameName)
    if type(UISpecialFrames) ~= "table" then return end
    for index, name in ipairs(UISpecialFrames) do
        if name == frameName then return index end
    end
end

function Module:EnsureRegistered()
    if not NS.db or not NS.db.mapEscape or not NS.db.mapEscape.enabled then return end
    if type(UISpecialFrames) ~= "table" then return end
    for _, frameName in ipairs(FRAME_NAMES) do
        if _G[frameName] and not FindFrame(frameName) then
            table.insert(UISpecialFrames, frameName)
            self.inserted[frameName] = true
        end
    end
end

function Module:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function()
        -- Panels are created by several load-on-demand addons. Scan only the
        -- bounded list after loads instead of assuming a particular addon name.
        Module:EnsureRegistered()
    end)
    self.events = events
    SLASH_CUNIELPLUSWINDOWS1 = "/cplusesc"
    SlashCmdList.CUNIELPLUSWINDOWS = function() Module:Diagnose() end
end

function Module:Diagnose()
    local version = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata(NS.name, "Version") or "未知"
    local enabled = NS.db and NS.db.mapEscape and NS.db.mapEscape.enabled
    NS:Print("版本 " .. tostring(version) .. "；ESC 兼容：" .. (enabled and "开启" or "关闭")
        .. "；战斗：" .. (InCombatLockdown() and "是" or "否"))
    local rows = {}
    for _, frameName in ipairs(FRAME_NAMES) do
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            local registered = FindFrame(frameName) ~= nil
            rows[#rows + 1] = {name = frameName, registered = registered}
            NS:Print(frameName .. "：已显示，" .. (registered and "已登记 ESC" or "未登记 ESC"))
        end
    end
    if #rows == 0 then NS:Print("兼容名单中没有正在显示的窗口。") end
    NS.db.windowDiagnostics = {version = version, enabled = enabled, windows = rows}
end

function Module:Apply()
    if NS.db.mapEscape.enabled then
        self:EnsureRegistered()
        return
    end

    -- Remove only the entry created by this module.  Never remove a Blizzard
    -- or third-party registration that existed before Cuniel_plus loaded.
    for _, frameName in ipairs(FRAME_NAMES) do
        if self.inserted[frameName] then
            local index = FindFrame(frameName)
            if index then table.remove(UISpecialFrames, index) end
            self.inserted[frameName] = nil
        end
    end
end
