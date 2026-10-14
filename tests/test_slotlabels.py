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
NS={
 db={slotLabels={enabled=true,size=11}}, modules={},
 RegisterModule=function(self,key,module) self.modules[key]=module end,
}
STANDARD_TEXT_FONT='font'
MERCHANT_SLOT_FINGER='手指'
MERCHANT_SLOT_FEET=nil

local function NewText()
 return {
  visible=false,text=nil,
  SetPoint=function() end,SetFont=function(self,font,size,flags) self.font=font;self.size=size;self.flags=flags end,SetTextColor=function() end,SetShadowOffset=function() end,
  SetText=function(self,value) self.text=value end,
  Show=function(self) self.visible=true end,
  Hide=function(self) self.visible=false end,
 }
end
local function NewButton(name)
 local b={name=name,scripts={OnEnter=function() end,OnLeave=function() end,OnClick=function() end}}
 function b:CreateFontString() self.label=NewText();return self.label end
 function b:GetScript(key) return self.scripts[key] end
 function b:SetScript(key,value) self.scripts[key]=value end
 return b
end
finger=NewButton('finger');feet=NewButton('feet');food=NewButton('food');secret=NewButton('secret')
oldEnter=finger:GetScript('OnEnter');oldClick=finger:GetScript('OnClick')
Stuffing={SlotUpdate=function(self,entry) self.lastUpdated=entry end,buttons={
 {frame=finger,bag=0,slot=1},{frame=feet,bag=0,slot=2},
 {frame=food,bag=0,slot=3},{frame=secret,bag=0,slot=4},
}}
local links={[1]='fingerLink',[2]='feetLink',[3]='foodLink',[4]='SECRET'}
C_Container={GetContainerItemLink=function(_,slot) return links[slot] end}
C_Item={GetItemInfoInstant=function(link)
 if link=='fingerLink' then return 1,'Armor','Misc','INVTYPE_FINGER' end
 if link=='feetLink' then return 2,'Armor','Cloth','INVTYPE_FEET' end
 if link=='foodLink' then return 3,'Consumable','Food','' end
 error('a secret value must never reach item APIs')
end}
function issecretvalue(value) return value=='SECRET' end
function canaccessvalue(value) return value~='SECRET' end
C_Timer={After=function(_,callback) callback() end}
function CreateFrame()
 return {RegisterEvent=function() end,SetScript=function(self,key,value) self[key]=value end}
end
function hooksecurefunc(object,key,hook)
 local original=object[key]
 object[key]=function(...)
  local result={original(...)}
  hook(...)
  return unpack(result)
 end
end
''')
loader = lua.eval('function(s,ns) assert(loadstring(s))("Cuniel_plus",ns) end')
loader((root / 'Modules/SlotLabels.lua').read_text(encoding='utf-8'), lua.globals().NS)
lua.execute(r'''
local module=NS.modules.slotLabels
module:Initialize();module:Apply()
assert(finger.label.visible and finger.label.text=='手指','finger label missing')
assert(finger.label.size==11,'default slot label size missing')
assert(feet.label.visible and feet.label.text=='脚部','built-in zhCN fallback missing')
assert(not food.label.visible and food.label.text=='','non-equipment label shown')
assert(not secret.label.visible and secret.label.text=='','secret item was not skipped')
assert(finger:GetScript('OnEnter')==oldEnter,'hover handler was modified')
assert(finger:GetScript('OnClick')==oldClick,'right-click handler was modified')
feet.label:Hide();Stuffing:SlotUpdate(Stuffing.buttons[2]);assert(feet.label.visible and feet.label.text=='脚部','Shestak SlotUpdate hook failed')
NS.db.slotLabels.enabled=false;module:Apply()
assert(not finger.label.visible and not feet.label.visible,'disable did not hide labels')
NS.db.slotLabels.enabled=true;module:Apply()
assert(finger.label.visible and finger.label.text=='手指','re-enable failed')
NS.db.slotLabels.size=17;module:Apply()
assert(finger.label.size==17 and feet.label.size==17,'font size did not refresh existing labels')
''')
print('PASS: stable adjustable slot labels, secret-value guard, no hover/click hooks, and reversible toggle')

