local addonName, NS = ...
NS.name = addonName
NS.modules = {}
NS.defaults = {
    version = 8,
    numbers = {mode = "east"},
    fps = {enabled = false, locked = false, size = 14, x = 0, y = 180},
    gold = {enabled = true, classes = {}},
    itemLevel = {enabled = true},
    bags = {enabled = true},
    deposit = {keepFood = true, keepIDs = {}},
    quiet = {enabled = true},
    arenaSpam = {enabled = true},
    bagPosition = {enabled = true, x = -55, y = 40},
    slotLabels = {enabled = true, size = 11},
    mapEscape = {enabled = true},
    itemCounts = {enabled = true, characters = {}, account = {},
        filters = {hearth = true, equipped = true, junk = true, quests = false, excludeIDs = {}}},
}

local function FillDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            FillDefaults(target[key], value)
        elseif type(target[key]) ~= type(value) then
            target[key] = value
        end
    end
end

function NS:RegisterModule(key, module)
    self.modules[key] = module
end

function NS:Apply()
    for _, module in pairs(self.modules) do module:Apply() end
end

function NS:Print(message)
    print("|cff66ccffCuniel_plus|r " .. message)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    CunielPlusDB = type(CunielPlusDB) == "table" and CunielPlusDB or {}
    local oldVersion = CunielPlusDB.version or 0
    if type(CunielPlusDB.deposit) ~= "table" then
        CunielPlusDB.deposit = {keepIDs = {["242744"] = true}}
    end
    FillDefaults(CunielPlusDB, NS.defaults)
    if oldVersion < 2 then
        CunielPlusDB.fps.enabled = false
        CunielPlusDB.fps.size = 14
        CunielPlusDB.version = 2
    end
    CunielPlusDB.version = 8
    NS.db = CunielPlusDB
    if not ({east = true, west = true, original = true})[NS.db.numbers.mode] then
        NS.db.numbers.mode = "east"
    end
    NS.db.fps.size = math.max(10, math.min(48, NS.db.fps.size))
    NS.db.slotLabels.size = math.max(8, math.min(24, tonumber(NS.db.slotLabels.size) or 11))
    for _, module in pairs(NS.modules) do
        if module.Initialize then module:Initialize() end
    end
    NS:Apply()
    NS:CreateOptions()
    events:UnregisterEvent("ADDON_LOADED")
end)

SLASH_CUNIELPLUS1 = "/cuniel"
SLASH_CUNIELPLUS2 = "/cplus"
SlashCmdList.CUNIELPLUS = function()
    if NS.options then
        NS.options:SetShown(not NS.options:IsShown())
    end
end
