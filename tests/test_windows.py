from pathlib import Path
import sys
sys.path.insert(0, str(Path('work/lua-test-v036').resolve()))
from lupa.lua51 import LuaRuntime

root = Path('Cuniel_plus')
lua = LuaRuntime(unpack_returned_tuples=True)
for file in root.rglob('*.lua'):
    lua.eval('function(s,n) local f,e=loadstring(s,n);assert(f,e) end')(
        file.read_text(encoding='utf-8'), '@' + str(file))

lua.execute(r'''
NS={db={mapEscape={enabled=true}},modules={},RegisterModule=function(self,key,module) self.modules[key]=module end}
SlashCmdList={}
UISpecialFrames={'ExistingWindow'}
WorldMapFrame={scripts={OnKeyDown='original-key',OnHide='original-hide'}}
CharacterFrame={}
function WorldMapFrame:GetScript(key) return self.scripts[key] end
function CreateFrame()
 return {RegisterEvent=function() end,SetScript=function(self,key,value) self[key]=value end}
end
''')
loader=lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')
loader((root/'Modules/MapEscape.lua').read_text(encoding='utf-8'),lua.globals().NS)
lua.execute(r'''
local module=NS.modules.mapEscape
local oldKey=WorldMapFrame:GetScript('OnKeyDown')
local oldHide=WorldMapFrame:GetScript('OnHide')
module:Initialize();module:Apply();module:Apply()
assert(#UISpecialFrames==3 and UISpecialFrames[2]=='WorldMapFrame' and UISpecialFrames[3]=='CharacterFrame','windows were not registered exactly once')
assert(WorldMapFrame:GetScript('OnKeyDown')==oldKey,'keyboard handler was modified')
assert(WorldMapFrame:GetScript('OnHide')==oldHide,'map hide handler was modified')
NS.db.mapEscape.enabled=false;module:Apply()
assert(#UISpecialFrames==1 and UISpecialFrames[1]=='ExistingWindow','own registrations not removed')
UISpecialFrames[2]='WorldMapFrame';module.inserted={};NS.db.mapEscape.enabled=true;module:Apply()
assert(#UISpecialFrames==3 and UISpecialFrames[2]=='WorldMapFrame' and UISpecialFrames[3]=='CharacterFrame','pre-existing registration was removed or missing window was not restored')
-- Load-on-demand talents were the missing case. Preserve their original
-- handlers and existing registrations owned by Blizzard/other addons.
PlayerSpellsFrame={scripts={OnKeyDown='talent-key',OnHide='talent-hide'}}
ProfessionsFrame={};CollectionsJournal={};MerchantFrame={};BankFrame={};StaticPopup1={}
table.insert(UISpecialFrames,'CollectionsJournal')
module.events.OnEvent(nil,'ADDON_LOADED','Blizzard_PlayerSpells')
module.events.OnEvent(nil,'ADDON_LOADED','Blizzard_Professions')
module.events.OnEvent(nil,'PLAYER_ENTERING_WORLD')
local counts={}
for _,name in ipairs(UISpecialFrames) do counts[name]=(counts[name] or 0)+1 end
assert(counts.PlayerSpellsFrame==1 and counts.ProfessionsFrame==1 and counts.CollectionsJournal==1,'late windows missing or duplicated')
assert(not counts.MerchantFrame and not counts.BankFrame and not counts.StaticPopup1,'transaction or modal window was registered')
assert(PlayerSpellsFrame.scripts.OnKeyDown=='talent-key' and PlayerSpellsFrame.scripts.OnHide=='talent-hide','talent scripts replaced')
NS.db.mapEscape.enabled=false;module:Apply()
counts={};for _,name in ipairs(UISpecialFrames) do counts[name]=true end
assert(counts.WorldMapFrame and counts.CollectionsJournal and not counts.PlayerSpellsFrame and not counts.ProfessionsFrame,'disable removed foreign entries or retained owned entries')
module.events.OnEvent(nil,'ADDON_LOADED','AnotherAddon')
assert(#UISpecialFrames==3,'disabled module registered a late window')
-- Modern and legacy flight maps are different top-level frames. They can load
-- after login; neither should depend on the world map registration.
FlightMapFrame={IsShown=function() return true end}
TaxiFrame={IsShown=function() return false end}
NS.db.mapEscape.enabled=true
module.events.OnEvent(nil,'ADDON_LOADED','Blizzard_FlightMap')
counts={};for _,name in ipairs(UISpecialFrames) do counts[name]=(counts[name] or 0)+1 end
assert(counts.FlightMapFrame==1 and counts.TaxiFrame==1,'flight map registration missing')
for _,frame in ipairs({WorldMapFrame,CharacterFrame,PlayerSpellsFrame,ProfessionsFrame,CollectionsJournal}) do
 frame.IsShown=function() return false end
end
NS.name='Cuniel_plus';NS.Print=function() end
C_AddOns={GetAddOnMetadata=function() return 'test-version' end}
function InCombatLockdown() return false end
SlashCmdList.CUNIELPLUSWINDOWS()
local report=NS.db.windowDiagnostics
assert(report.version=='test-version' and #report.windows==1 and report.windows[1].name=='FlightMapFrame' and report.windows[1].registered,'diagnosis did not report the live flight map')
NS.db.mapEscape.enabled=false;module:Apply()
module:Diagnose()
assert(not NS.db.windowDiagnostics.windows[1].registered,'diagnosis changed registration or missed disabled state')
''')
print('PASS: ESC window registrations are unique, reversible, and do not hook keyboard or map scripts')
