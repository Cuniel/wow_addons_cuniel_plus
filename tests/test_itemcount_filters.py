from pathlib import Path
from lupa.lua51 import LuaRuntime

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NS={db={itemCounts={}}}
function issecretvalue(v) return v=='SECRET' end
function canaccessvalue(v) return v~='SECRET' end
quality=2;classID=7
C_Item={GetItemInfo=function() return 'item',nil,quality,1,1,nil,nil,1,'',0,0,classID end,
RequestLoadItemDataByID=function(id) requested=id end}
''')
lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')(
    Path('Cuniel_plus/Modules/ItemCountFilters.lua').read_text(encoding='utf-8'),lua.globals().NS)
lua.execute('''
local f=NS.ItemCountFilters
assert(f:Get().hearth and f:Get().equipped and f:Get().junk and not f:Get().quests,'defaults changed')
assert(f:Excluded(6948) and f:Excluded(110560) and f:Excluded(140192),'hearthstone variants not excluded')
assert(not f:Excluded(123),'normal crafting item hidden')
quality=0;assert(f:Excluded(123),'junk not excluded')
f:Get().junk=false;assert(not f:Excluded(123),'junk opt-out ignored')
quality=2;classID=12;assert(not f:Excluded(123),'quests should be retained by default')
f:Get().quests=true;assert(f:Excluded(123),'quest filter ignored')
quality='SECRET';classID='SECRET';assert(not f:Excluded(123),'restricted metadata was treated as a category')
quality=nil;classID=nil;assert(not f:Excluded(123) and requested==123,'uncached metadata was guessed or not requested')
assert(f:SaveIDs('000123，456; 789'))
assert(f:Excluded(123) and f:Excluded(456) and f:Excluded(789),'ID normalization failed')
assert(not f:SaveIDs('123,abc') and f:Excluded(456),'invalid input destroyed saved list')
assert(not f:SaveIDs('0') and not f:SaveIDs('-2') and not f:SaveIDs('99999999999999999999999999'))
assert(f:SaveIDs('') and not f:Excluded(456),'empty list failed to restore item')
''')
print('PASS: default and optional category filters, independent equipment exclusion, unknown/restricted metadata, ID normalization and atomic validation')
