local _, NS = ...
local Module = {deadline = GetTime() + 90, count = 0}
NS:RegisterModule("quiet", Module)
local function Safe(v) return not issecretvalue or not issecretvalue(v) end
function Module:Matches(message)
    if not Safe(message) or type(message) ~= "string" then return false end
    local text = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|H.-|h(.-)|h", "%1")
        :gsub("^%s+", "")
    local gear = text:find("GearInsight", 1, true)
    if text:match("^%[RTK%]%s*已加载 v") and text:find("输入 /rtk 打开", 1, true) then
        return true
    end
    if text:find("欢迎使用ShestakUI ", 1, true) == 1 then return true end
    if text:find("键入 /cfg 进行插件设置", 1, true) == 1
        and text:find("github.com/Wetxius/ShestakUI_Help/", 1, true) then return true end
    if gear and gear <= 2 then
        return text:find("已加载", 1, true) ~= nil or text:find("交流群", 1, true) ~= nil
            or text:find("Telegram group", 1, true) ~= nil
    end
    if text:find("RaiderIO", 1, true) == 1 then
        return text:find("过期", 1, true) ~= nil or text:find("out of date", 1, true) ~= nil
    end
    if text:find("[信息]", 1, true) == 1 then
        return (text:find("地下堡助手", 1, true) ~= nil and text:find("已加载", 1, true) ~= nil)
            or (text:find("自动进入", 1, true) ~= nil and text:find("速刷模式", 1, true) ~= nil)
    end
    if text:find("感谢使用", 1, true) == 1 and text:find("地瓜", 1, true) then return true end
    if text:find("[牧羊少年]", 1, true) == 1 and text:find("上线了", 1, true) then return true end
    return false
end
function Module:Clean()
    if not NS.db.quiet.enabled then return end
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if frame and type(frame.RemoveMessagesByPredicate) == "function" then
            frame:RemoveMessagesByPredicate(function(text, r, g, b, chatTypeID)
                if not Safe(chatTypeID) or (chatTypeID ~= nil and chatTypeID ~= 0) then return false end
                if Module:Matches(text) then Module.count = Module.count + 1; return true end
                return false
            end)
        end
    end
end
function Module:Apply()
    if NS.db.quiet.enabled then
        self.deadline = GetTime() + 30
        self:Clean()
        if self.worker then self.worker:Show() end
    elseif self.worker then self.worker:Hide() end
end
function Module:Initialize()
    local worker, elapsed = CreateFrame("Frame"), 0
    self.worker = worker
    worker:RegisterEvent("PLAYER_LOGIN")
    worker:SetScript("OnEvent", function() Module:Apply() end)
    worker:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.5 then
            elapsed = 0
            if not NS.db.quiet.enabled or GetTime() > Module.deadline then worker:Hide(); return end
            Module:Clean()
        end
    end)
end
