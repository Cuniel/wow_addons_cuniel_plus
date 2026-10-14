local _, NS = ...
local Module = {}
NS:RegisterModule("gold", Module)
local function Safe(value)
    return not issecretvalue or not issecretvalue(value)
end
function Module:Apply() end
function Module:Initialize()
    local realm = GetRealmName()
    local classes = NS.db.gold.classes
    classes[realm] = classes[realm] or {}
    local _, class = UnitClass("player")
    classes[realm][UnitName("player")] = class
    -- Reuse known offline characters; never infer class from character names.
    if type(BrotherBags) == "table" then
        for server, characters in pairs(BrotherBags) do
            if type(characters) == "table" then
                classes[server] = classes[server] or {}
                for name, data in pairs(characters) do
                    if type(data) == "table" and type(data.class) == "string" then
                        classes[server][name] = data.class
                    end
                end
            end
        end
    end
    hooksecurefunc(GameTooltip, "AddDoubleLine", function(tooltip, left)
        if not NS.db.gold.enabled or not Safe(left) or type(left) ~= "string" then return end
        if not _G.LP_Gold or tooltip:GetOwner() ~= _G.LP_Gold then return end
        local classToken = classes[realm] and classes[realm][left]
        local color = classToken and RAID_CLASS_COLORS[classToken]
        local label = color and _G[tooltip:GetName() .. "TextLeft" .. tooltip:NumLines()]
        if label then label:SetTextColor(color.r, color.g, color.b) end
    end)
end
