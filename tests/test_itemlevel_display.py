from pathlib import Path
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NS={db={itemLevel={enabled=true}},modules={},RegisterModule=function(self,k,m) self.modules[k]=m end}
STAT_AVERAGE_ITEM_LEVEL='物品等级'
function issecretvalue(v) return v=='SECRET' end
function canaccessvalue(v) return v~='SECRET' end
function UnitGUID(unit) return unit=='player' and 'SELF' or 'OTHER' end
function UnitIsPlayer() return true end
function UnitIsUnit(a,b) return a==b end
function GetAverageItemLevel() return 300,300 end
function InCombatLockdown() return false end
function GetTime() return 20 end
function hooksecurefunc() end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(self,k,v) self[k]=v end} end
GameTooltip={unit='mouseover',shown=true,count=5,adds=0,shows=0,hooks={}}
function GameTooltip:IsShown() return self.shown end
function GameTooltip:GetUnit() return 'name',self.unit end
function GameTooltip:NumLines() return self.count end
function GameTooltip:HookScript(k,v) self.hooks[k]=v end
function GameTooltip:AddLine(text)
 self.count=self.count+1;self.adds=self.adds+1
 _G['GameTooltipTextLeft'..self.count]={text=text,SetText=function(self,t) self.text=t end,
 GetText=function() error('must not read tooltip text') end}
end
function GameTooltip:Show() self.shows=self.shows+1;NS.modules.itemLevel:Display('OTHER',301) end
function GameTooltip:Clear() self.count=5;self.hooks.OnTooltipCleared() end
''')
lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')(
    Path('Cuniel_plus/Modules/ItemLevel.lua').read_text(encoding='utf-8'),lua.globals().NS)
lua.execute('''
local m=NS.modules.itemLevel
m:Initialize();m.hoverGUID='OTHER'
for i=1,100 do m:Display('OTHER',301) end
assert(GameTooltip.adds==1 and GameTooltip.shows==1,'repeated rendering or recursive Show')
assert(m.line.text:find('物品等级:') and not m.line.text:find('装等  '),'style mismatch')
m:Display('OTHER',302)
assert(GameTooltip.adds==1 and m.line.text:find('302.0'),'changed value did not update original row')
GameTooltip:Clear();m:Display('OTHER',302)
assert(GameTooltip.count==6 and GameTooltip.shows==1,'natural rebuild duplicated rows or layout')
local adds=GameTooltip.adds
m:Display('OTHER','SECRET');m:Display('SELF',300)
assert(GameTooltip.adds==adds,'restricted or stale inspection rendered')
GameTooltip.hooks.OnHide();assert(not m.hoverGUID and not m.line)
GameTooltip.unit='player';GameTooltip:Clear();m:Tick();GameTooltip:Clear();m:Tick()
assert(GameTooltip.count==6 and m.line.text:find('300.0'),'own tooltip lost row after natural refresh')
''')
print('PASS: integrated tooltip row, reentrant layout guard, refresh reuse, restricted/stale data guards, and own tooltip rebuild')
