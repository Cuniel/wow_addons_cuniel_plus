local _, NS = ...

local Module = {inserted = {}}
NS:RegisterModule("mapEscape", Module)

local FRAME_NAMES = {
    "WorldMapFrame",
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
