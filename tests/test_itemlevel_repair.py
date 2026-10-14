from pathlib import Path
import sys
sys.path.insert(0, str(Path('../work/lua-test-v036').resolve()))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NS={db={itemLevel={enabled=false}},modules={},Print=function(self,msg) self.message=msg end,
RegisterModule=function(self,key,module) self.modules[key]=module end}
combat=false
function InCombatLockdown() return combat end
reloads=0
function ReloadUI() reloads=reloads+1 end
profile={tooltip={average_lvl=true,enable=true,other=true}}
ShestakUIOptions={['1']=profile}
ShestakUI={ {}, {options=profile,tooltip={enable=true,average_lvl=true}} }
''')
source=Path('Cuniel_plus/Modules/ItemLevel.lua').read_text(encoding='utf-8')
lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')(source,lua.globals().NS)
lua.execute('''
local module=NS.modules.itemLevel
combat=true
assert(not module:RepairShestak() and reloads==0 and profile.tooltip.average_lvl)
combat=false
assert(module:RepairShestak())
assert(profile.tooltip.average_lvl==false and profile.tooltip.other and profile.tooltip.enable)
assert(NS.db.itemLevel.enabled and reloads==1)
assert(module:UsesShestak(),'running module must remain detected until reload')
ShestakUI[2].tooltip.average_lvl=false
assert(not module:UsesShestak(),'replacement did not become active after reload')
ShestakUI[2].options={}
assert(not module:RepairShestak() and reloads==1,'non-persistent profile should not be modified')
local charProfile={}
ShestakUIOptionsPerChar={['2']=charProfile}
ShestakUI[2].options=charProfile
assert(module:RepairShestak() and charProfile.tooltip.average_lvl==false and reloads==2)
''')
print('PASS: combat guard, persisted account/character profiles, preservation of other settings, and reload handover')
