local _, NS = ...
local Numbers = {}
NS:RegisterModule("numbers", Numbers)

-- Pass values directly to Blizzard's formatter. Do not inspect or perform
-- arithmetic on health/power values: they can be secret during combat.
local east = {breakpointData = {}}
for _, unit in ipairs({{12, "万亿"}, {8, "亿"}, {4, "万"}}) do
    local exponent, suffix = unit[1], unit[2]
    for offset = 3, 0, -1 do
        local precision = offset >= 2 and 0 or (offset == 1 and 1 or 2)
        east.breakpointData[#east.breakpointData + 1] = {
            breakpoint = 10 ^ (exponent + offset),
            abbreviation = suffix,
            significandDivisor = 10 ^ (exponent - precision),
            fractionDivisor = 10 ^ precision,
            abbreviationIsGlobal = false,
        }
    end
end
local west = {breakpointData = {}}
for _, unit in ipairs({{12, "T"}, {9, "B"}, {6, "M"}, {3, "K"}}) do
    local exponent, suffix = unit[1], unit[2]
    for offset = 2, 0, -1 do
        local precision = 2 - offset
        west.breakpointData[#west.breakpointData + 1] = {
            breakpoint = 10 ^ (exponent + offset), abbreviation = suffix,
            significandDivisor = 10 ^ (exponent - precision),
            fractionDivisor = 10 ^ precision, abbreviationIsGlobal = false,
        }
    end
end

function Numbers:Apply()
    local engine = _G.ShestakUI
    local functions = type(engine) == "table" and engine[1]
    if type(functions) ~= "table" or type(functions.ShortValue) ~= "function"
        or type(AbbreviateNumbers) ~= "function" then
        self.status = "未检测到兼容的 ShestakUI；数字覆盖未启用。"
        return
    end
    if not self.original then
        self.original = functions.ShortValue
        self.wrapper = function(value)
            return AbbreviateNumbers(value, NS.db.numbers.mode == "west" and west or east)
        end
    end
    if functions.ShortValue ~= self.original and functions.ShortValue ~= self.wrapper then
        self.status = "数字函数被其他插件更改，已停止覆盖；请重载后检查。"
        return
    end
    if NS.db.numbers.mode == "original" then
        functions.ShortValue = self.original
        self.status = "跟随 ShestakUI：保留它当前自带的格式（包括旧补丁）。"
    else
        functions.ShortValue = self.wrapper
        self.status = "已覆盖 ShestakUI 数字格式；数值下次刷新时生效。"
    end
end
