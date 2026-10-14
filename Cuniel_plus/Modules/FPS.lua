local _, NS = ...
local FPS = {}
NS:RegisterModule("fps", FPS)

function FPS:Place()
    local db = NS.db.fps
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local marginX = self.frame:GetWidth() / 2
    local marginY = self.frame:GetHeight() / 2
    db.x = math.max(-width / 2 + marginX, math.min(width / 2 - marginX, db.x))
    db.y = math.max(-height / 2 + marginY, math.min(height / 2 - marginY, db.y))
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
end

function FPS:Initialize()
    local frame = CreateFrame("Frame", "CunielPlusFPS", UIParent, "BackdropTemplate")
    self.frame = frame
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetTextColor(0.4, 1, 0.65)
    self.text = text
    local function SavePosition()
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        local cx, cy = UIParent:GetCenter()
        if x and y and cx and cy then
            NS.db.fps.x, NS.db.fps.y = x - cx, y - cy
        end
        FPS:Place()
    end
    frame:SetScript("OnDragStart", function()
        if not NS.db.fps.locked then frame:StartMoving() end
    end)
    frame:SetScript("OnDragStop", SavePosition)
    frame:SetScript("OnHide", SavePosition)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then NS.options:Show() end
    end)
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_TOP")
        GameTooltip:SetText("Cuniel_plus 帧数")
        GameTooltip:AddLine("左键拖动 · 右键设置 · /cuniel 打开设置", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.5 then
            elapsed = 0
            text:SetFormattedText("%d FPS", math.floor(GetFramerate() + 0.5))
        end
    end)
    frame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    frame:RegisterEvent("UI_SCALE_CHANGED")
    frame:SetScript("OnEvent", function() FPS:Place() end)
end

function FPS:Apply()
    local db = NS.db.fps
    self.text:SetFont(STANDARD_TEXT_FONT, db.size, "OUTLINE")
    self.text:SetFormattedText("%d FPS", math.floor(GetFramerate() + 0.5))
    self.frame:SetSize(db.size * 4.8 + 4, db.size + 2)
    self.frame:SetBackdropColor(0.02, 0.03, 0.05, db.locked and 0 or 0.2)
    self.frame:EnableMouse(not db.locked)
    self:Place()
    self.frame:SetShown(db.enabled)
end
