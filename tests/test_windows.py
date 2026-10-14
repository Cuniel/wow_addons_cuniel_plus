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
''')
print('PASS: ESC window registrations are unique, reversible, and do not hook keyboard or map scripts')
