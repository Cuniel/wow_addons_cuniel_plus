local _, NS = ...
local Module = {states = setmetatable({}, {__mode = "k"})}
NS:RegisterModule("arenaSpam", Module)

local function Safe(value)
    return not issecretvalue or not issecretvalue(value)
end

local function IsJoinMessage(text)
    if not Safe(text) or type(text) ~= "string" then return false end
    local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1")
    return plain:match("^%d+名玩家加入了战斗[：:]") ~= nil
        or plain:match("^%d+ players have joined the battle[：:]") ~= nil
        or plain:match("^1 player has joined the battle[：:]") ~= nil
end

function Module:Filter(frame, _, text)
    if not NS.db.arenaSpam.enabled or not IsJoinMessage(text) then return false end
    local inInstance, instanceType = IsInInstance()
    if not Safe(inInstance) or not Safe(instanceType) or not inInstance or instanceType ~= "arena" then
        return false
    end
    local now = GetTime()
    local key = frame or self
    local state = self.states[key]
    if state and text == state.text and now - state.time < 15 then
        state.time = now
        return true
    end
    self.states[key] = {text = text, time = now}
    return false
end

function Module:Apply()
    self.states = setmetatable({}, {__mode = "k"})
end

function Module:Initialize()
    local add = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter
        or ChatFrame_AddMessageEventFilter
    if type(add) == "function" then
        add("CHAT_MSG_SYSTEM", function(...) return Module:Filter(...) end)
    end
end
