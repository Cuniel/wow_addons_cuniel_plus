from pathlib import Path
from lupa.lua51 import LuaRuntime

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
NS={db={itemCounts={enabled=true,characters={},account={}}},modules={},RegisterModule=function(self,k,m) self.modules[k]=m end}
Enum={BagIndex={ReagentBag=5},BankType={Character=0,Account=2},TooltipDataType={Item=0}}
function GetRealmName() return 'Realm' end
function UnitName() return 'Current' end
function UnitClass() return 'class','PALADIN' end
combat=false
function InCombatLockdown() return combat end
function issecretvalue(v) return v=='SECRET' end
function canaccessvalue(v) return v~='SECRET' end
function GetInventoryItemID(_,slot) if slot==1 then return 100 end end
bags={[0]={{itemID=100,stackCount=2}},[5]={{itemID=100,stackCount=3}},[6]={{itemID=100,stackCount=4}},[12]={{itemID=100,stackCount=7}}}
C_Container={GetContainerNumSlots=function(bag) return bags[bag] and 1 or 0 end,
GetContainerItemInfo=function(bag,slot) return bags[bag] and bags[bag][slot] end}
bankOpen=false
C_Bank={CanUseBank=function() return bankOpen end,FetchPurchasedBankTabData=function(kind) return {{ID=kind==0 and 6 or 12}} end}
BrotherBags={Realm={Offline={class='MAGE',[0]={items={'100;9'}},[6]={items={'100;10'}},equip={[1]='100',[20]='100'},mail={'100;200'}},
 Guild={ [0]={items={'100;900'}}}},account={[12]={items={'100;7'}}}}
RAID_CLASS_COLORS={MAGE={r=0.2,g=0.5,b=1},PALADIN={r=1,g=0.4,b=0.7}}
GameTooltip={lines={},hooks={}}
function GameTooltip:IsForbidden() return self.forbidden end
function GameTooltip:HookScript(k,v) self.hooks[k]=v end
function GameTooltip:AddLine(t) self.lines[#self.lines+1]={t} end
function GameTooltip:AddDoubleLine(a,b,r,g,bl) self.lines[#self.lines+1]={a,b,r,g,bl} end
function GameTooltip:Show() error('must not rebuild or Show tooltip') end
TooltipDataProcessor={AddTooltipPostCall=function(_,f) callback=f end}
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(self,k,f) self[k]=f end} end
C_Timer={After=function(_,f) f() end}
''')
lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')(
 Path('Cuniel_plus/Modules/ItemCounts.lua').read_text(encoding='utf-8'),lua.globals().NS)
lua.execute('''
local m=NS.modules.itemCounts;m:Initialize();m:Apply()
local rows,account,total=m:Rows(100)
assert(#rows==2 and rows[1].name=='Offline' and rows[1].count==20,'import count: bags+bank+equipment only')
assert(rows[2].count==6 and account==7 and total==33,'current bags/reagent/equipment or account counted twice')
bankOpen=true;m:Scan();rows,account,total=m:Rows(100)
assert(total==37,'live personal bank scan not counted')
m:Tooltip(GameTooltip,{id=100});local count=#GameTooltip.lines
assert(GameTooltip.lines[3][1]=='Offline' and GameTooltip.lines[3][3]==0.2,'class-colored character row missing')
assert(GameTooltip.lines[count][1]=='战团银行' and GameTooltip.lines[count][2]=='7','account bank row missing')
for i=1,100 do m:Tooltip(GameTooltip,{id=100}) end
assert(#GameTooltip.lines==count,'duplicate tooltip lines')
GameTooltip.hooks.OnTooltipCleared(GameTooltip);m:Tooltip(GameTooltip,{id='SECRET'})
assert(#GameTooltip.lines==count,'secret item rendered')
GameTooltip.forbidden=true;m:Tooltip(GameTooltip,{id=100});assert(#GameTooltip.lines==count)
GameTooltip.forbidden=false
-- A temporarily unreadable bank preserves its snapshot; a readable empty one clears it.
bags[12][1]={itemID='SECRET',stackCount=1};m:Scan();local _,ac=m:Rows(100);assert(ac==7)
bankOpen=false;bags[12][1]=nil;m:Scan();local _,ac=m:Rows(100);assert(ac==7)
bankOpen=true;m:Scan();local _,ac=m:Rows(100);assert(ac==0,'empty bank left stale item')
bags[0]=nil;bags[5]=nil;m:Scan();rows,_,total=m:Rows(100);assert(total==25,'removed bags left stale count')
combat=true;bags[6][1]=nil;m:Scan();rows,_,total=m:Rows(100);assert(total==25,'combat overwrote cache')
combat=false;m:Scan();rows,_,total=m:Rows(100);assert(total==21)
m:ImportBrother();rows,_,total=m:Rows(100)
assert(total==21,'old import overwrote newer snapshot')
NS.db.itemCounts.enabled=false;GameTooltip.hooks.OnTooltipCleared(GameTooltip);m:Tooltip(GameTooltip,{id=100})
assert(#GameTooltip.lines==count,'disabled module rendered')
''')
print('PASS: offline import, live bags/equipment/banks, shared-bank deduplication, class colors, tooltip reuse, restricted data and stale-cache guards')
