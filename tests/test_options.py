from pathlib import Path
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
objects={};UISpecialFrames={};SlashCmdList={}
local Methods={}
function Methods:SetScript(k,v) self.scripts[k]=v end
function Methods:RegisterEvent() end
function Methods:SetSize(w,h) self.w,self.h=w,h end
function Methods:SetHeight(h) self.h=h end
function Methods:SetWidth(w) self.w=w end
function Methods:SetPoint() end
function Methods:SetText(t) self.text=t end
function Methods:SetJustifyH() end
function Methods:Hide() self.shown=false end
function Methods:Show() self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Methods:SetShown(v) self.shown=v end
function Methods:SetEnabled(v) self.enabled=v end
function Methods:SetChecked(v) self.checked=v end
function Methods:GetChecked() return self.checked end
function Methods:SetFont(f,s,flags) self.font,self.size,self.flags=f,s,flags end
function Methods:GetFont() return self.font or 'Chinese.ttf',self.size or 12,self.flags or '' end
function Methods:SetScale(s) self.scale=s end
function Methods:SetVerticalScroll(n) self.scroll=n end
function Methods:SetScrollChild(c) self.child=c end
for _,k in ipairs({'SetFrameStrata','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag','StartMoving','StopMovingOrSizing'}) do Methods[k]=function() end end
local function Object(parent) local o=setmetatable({scripts={},parent=parent},{__index=Methods});objects[#objects+1]=o;return o end
function Methods:CreateFontString() return Object(self) end
function CreateFrame(kind,name,parent,template)
 local o=Object(parent);o.name=name;o.kind=kind;o.TitleText=Object(o);if name then _G[name]=o end;return o
end
UIParent={w=1200,h=800,GetWidth=function(self) return self.w end,GetHeight=function(self) return self.h end}
tinsert=table.insert
C_AddOns={GetAddOnMetadata=function() return '0.3.18' end}
NS={};local function load(s) assert(loadstring(s))('Cuniel_plus',NS) end
Load=load
''')
lua.globals().Load(Path('Cuniel_plus/Core.lua').read_text(encoding='utf-8'))
lua.execute(r'''
NS.db=NS.defaults;NS.db.slotLabels.size=17;NS.db.slotLabels.qualities[3]=false
for _,name in ipairs({'numbers','fps','gold','itemCounts','itemLevel','bags','bagPosition','slotLabels','detailsLayout','readability','mapEscape','quiet','arenaSpam','chatTabs'}) do
 NS.modules[name]={Apply=function(self) self.applied=true end,OpenOptions=function(self) self.opened=true end,GetAutoSell=function() return false,true end,SetAutoSell=function() end,RepairShestak=function() end}
end
NS.Deposit={OpenOptions=function(self) self.opened=true end};NS.ItemCountFilters={OpenOptions=function(self) self.opened=true end}
''')
lua.globals().Load(Path('Cuniel_plus/Options.lua').read_text(encoding='utf-8'))
lua.execute(r'''
NS:CreateOptions();local p=NS.options
assert(p.w==820 and p.h==590 and p.selectedPage=='overview','old oversized UI retained')
local count=0;for _ in pairs(p.navigation) do count=count+1 end;assert(count==5,'missing navigation categories')
for _,key in ipairs({'overview','bags','tooltip','numbers','fps','slots','fonts','compat'}) do
 p:SelectPage(key);local n=0;for _,page in pairs(p.pages) do if page.frame.shown then n=n+1 end end
 assert(n==1 and p.pages[key].frame.shown,'page visibility overlaps')
end
assert(NS.db.slotLabels.size==17 and not NS.db.slotLabels.qualities[3],'UI initialization reset user settings')
local function Click(text,checked)
 for _,o in ipairs(objects) do if o.text==text and o.scripts.OnClick then o.checked=checked;o.scripts.OnClick(o);return true end end
 for _,o in ipairs(objects) do if o.text==text and o.parent and o.parent.scripts.OnClick then o.parent.checked=checked;o.parent.scripts.OnClick(o.parent);return true end end
end
assert(Click('食物保护 / 不存入的物品 ID') and NS.Deposit.opened)
assert(Click('物品统计：过滤规则 / 隐藏物品 ID') and NS.ItemCountFilters.opened)
assert(Click('中文聊天标签页') and NS.modules.chatTabs.opened)
assert(Click('自动处理伤害 / 治疗窗口重叠或越界',false) and not NS.db.detailsLayout.enabled)
assert(NS.modules.detailsLayout.applied,'checkbox did not apply settings')
assert(Click('K / M / B') and NS.db.numbers.mode=='west','number mode control missing')
assert(Click('|cff0070dd精良 · 蓝色|r',true) and NS.db.slotLabels.qualities[3],'quality configuration lost during UI move')
UIParent.w,UIParent.h=640,480;p:Show();assert(p.scale<1 and p.scale*820<=608 and p.scale*590<=448,'small screen scaling lost close/controls')
assert(#UISpecialFrames==1,'ESC registration duplicated')
''')

# Real readability module: Mac-only by default, targeted and reversible. The
# hook model also exercises ShestakUI reapplying the tab font on mouseover.
lua.execute(r'''
mac=true;combat=false
function IsMacClient() return mac end
function InCombatLockdown() return combat end
C_Timer={After=function(_,fn) fn() end}
function hooksecurefunc(target,key,callback)
 local old=target[key];target[key]=function(...) local result=old(...);callback(...);return result end
end
local function Font(size)
 local f={size=size,path='Chinese.ttf',flags='OUTLINE',changes=0}
 function f:GetFont() return self.path,self.size,self.flags end
 function f:SetFont(path,size,flags) self.path,self.size,self.flags=path,size,flags;self.changes=self.changes+1 end
 return f
end
small=Font(8);large=Font(16);tabfont=Font(9);unrelated=Font(8)
oUF_Player={Health={value=small},Info=large}
ChatFrame1Tab={GetFontString=function() return tabfont end}
ShestakUI={{mult=0.5,oUF={objects={oUF_Player}}}}
NS.db.readability={enabled=true,macOnly=true,size=12}
''')
lua.globals().Load(Path('Cuniel_plus/Modules/Readability.lua').read_text(encoding='utf-8'))
lua.execute(r'''
local m=NS.modules.readability;m:Initialize();m:Apply()
assert(small.size==12 and tabfont.size==12 and large.size==16 and unrelated.size==8,'targeted minimum or existing larger font lost')
assert(small.flags=='OUTLINE' and small.path=='Chinese.ttf','font style changed')
local count=small.changes;m:Apply();assert(small.changes==count,'font size accumulates on repeated apply')
tabfont:SetFont('Chinese.ttf',9,'OUTLINE');assert(tabfont.size==12,'mouseover font reset was not corrected')
NS.db.readability.size=14;m:Apply();assert(small.size==14 and tabfont.size==14)
combat=true;NS.db.readability.enabled=false;m:Apply();assert(m.pending and small.size==14,'font changed in combat')
combat=false;m:Apply();assert(small.size==8 and tabfont.size==9 and large.size==16,'original font did not restore')
NS.db.readability.enabled=true;mac=false;m:Apply();assert(small.size==8,'Windows default changed')
NS.db.readability.macOnly=false;m:Apply();assert(small.size==14,'explicit Windows opt-in failed')
NS.db.readability.enabled=false;m:Apply();mac=true;NS.db.readability.enabled=true
ShestakUI[1].mult=1;m:Apply();assert(small.size==8,'normal DPI modified')
ShestakUI=nil;m:Apply();assert(m.status,'missing ShestakUI not tolerated')
''')
print('PASS: classified UI navigation, page isolation, existing setting preservation, all critical dialogs, inline qualities and small-screen fitting')
print('PASS: targeted high-DPI font minimum, Mac/Windows defaults, hover reapplication, combat deferral and session restore')
