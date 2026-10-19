from pathlib import Path
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
NS={db={detailsLayout={enabled=true}},modules={},RegisterModule=function(self,k,m) self.modules[k]=m end}
combat=false;function InCombatLockdown() return combat end
UIParent={GetWidth=function() return 1200 end,GetHeight=function() return 800 end,GetEffectiveScale=function() return 0.8 end}
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(self,k,v) self[k]=v end} end
C_Timer={After=function(_,fn) fn() end}
''')
lua.eval('function(s) assert(loadstring(s))("Cuniel_plus",NS) end')(
    Path('Cuniel_plus/Modules/DetailsLayout.lua').read_text(encoding='utf-8'))
lua.execute(r'''
local m=NS.modules.detailsLayout
local windows={{x=700,y=24,w=280,h=120},{x=760,y=24,w=280,h=120}}
local obstacles={{x=1020,y=10,w=170,h=180}}
local plan,mode=m.Plan(1200,800,windows,obstacles)
assert(plan and mode=='column','narrow minimap-adjacent area must stack windows')
assert(plan[1].y+plan[1].h<=plan[2].y and plan[1].x+plan[1].w<=1020,'stack overlaps or covers minimap')
local wide,wideMode=m.Plan(1920,1080,windows,{{x=1730,y=8,w=180,h=180}})
assert(wide and wideMode=='row','wide screen should fit side by side')
assert(wide[1].x+wide[1].w<wide[2].x)
assert(not m.Plan(1920,1080,wide,{},false),'valid custom layout was moved')
local off={{x=-5,y=8,w=280,h=120},{x=2000,y=8,w=280,h=120}}
assert(m.Plan(1920,1080,off,{},false),'offscreen windows not repaired')
assert(not m.Plan(400,250,windows,{},true),'impossible layout should not shrink/hide windows')
-- Real adapter: UI scale differs from each Details window's scale.
local function Instance(display,x)
 local f={x=x,y=24,w=280,h=120,scale=0.4}
 function f:IsShown() return true end
 function f:GetRect() return self.x,self.y,self.w,self.h end
 function f:GetEffectiveScale() return self.scale end
 function f:HookScript() end
 function f:ClearAllPoints() self.cleared=true end
 function f:SetPoint(_,_,_,x,y) self.x,self.y=x,y end
 local inst={baseframe=f,saves=0}
 function inst:GetDisplay() return display end
 function inst:CreatePositionTable() return {pos_table=true,x=f.x,y=f.y} end
 function inst:SaveMainWindowPosition() self.saves=self.saves+1 end
 function inst:RestorePositionFromPositionTable(p) f.x,f.y=p.x,p.y;self.restored=true end
 return inst
end
local a,b=Instance(1,1500),Instance(2,1520)
Details={tabela_instancias={a,b}}
m:Initialize();m.loggedIn=true
combat=true;m:Apply();assert(m.pending and a.saves==0,'moved in combat')
combat=false;m.events.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(a.saves==1 and b.saves==1 and m.originals[a].x==1500,'adapter failed to save original or persist new position')
local function parentX(inst) return inst.baseframe.x*0.5-28 end
assert(parentX(a)>=8 and parentX(b)>=8,'coordinate conversion ignored effective scale')
local count=a.saves;m:Apply();assert(a.saves==count,'layout repeatedly drifted')
NS.db.detailsLayout.enabled=false;m:Apply();assert(a.restored and a.baseframe.x==1500 and not next(m.originals),'disable did not restore this-session original')
NS.db.detailsLayout.enabled=true
a.SaveMainWindowPosition=nil;m:Apply(true);assert(not next(m.originals),'unsupported API changed windows')
Details=nil;m:Apply();assert(m.status,'missing Details not tolerated')
''')
print('PASS: Details geometry, side-by-side/stacked layouts, obstacle avoidance, UI scale conversion, combat deferral, restore and unsupported versions')
