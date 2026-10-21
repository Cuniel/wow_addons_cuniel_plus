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
lua.execute(r"""
local m=NS.modules.detailsLayout
local windows={{x=700,y=24,w=280,h=400,overhead=30,row=20},
 {x=760,y=24,w=240,h=400,overhead=30,row=20}}
local wide={left=400,right=1000,bottom=20,top=330}
local narrow={left=600,right=1000,bottom=20,top=330}
local function Check(p,bounds,obstacles)
 assert(p and math.abs(p[1].w-p[2].w)<.001,'meter widths differ')
 for _,r in ipairs(p) do
  assert(r.x+.001>=bounds.left and r.y+.001>=bounds.bottom and r.x+r.w<=bounds.right+.001
   and r.y+r.h<=bounds.top+.001 and r.rows>=1,'meter crosses measured boundary')
  for _,o in ipairs(obstacles or {}) do
   assert(not (r.x<o.x+o.w and o.x<r.x+r.w and r.y<o.y+o.h and o.y<r.y+r.h),'obstacle overlap')
  end
 end
end
local plan,mode=m.Plan(1200,800,windows,{},false,wide)
assert(mode=='row','wide measured region should use a row');Check(plan,wide)
assert(plan[1].x+plan[1].w+2==plan[2].x and plan[2].x+plan[2].w==wide.right,'damage not adjacent to right-anchored healing')
assert(plan[1].w==280 and plan[1].x>wide.left,'row stretched across empty available width')
local column,columnMode=m.Plan(1200,800,windows,{},false,narrow)
assert(columnMode=='column','narrow region should stack');Check(column,narrow)
assert(column[1].y+column[1].h+2<=column[2].y,'column overlaps')
assert(column[1].x+column[1].w==narrow.right and column[2].x+column[2].w==narrow.right,'column right edges differ')
local budget=narrow.top-narrow.bottom-2
assert(column[1].rows==math.floor((budget*.6-30)/20) and column[2].rows==math.floor((budget*.4-30)/20),'6:4 budget not quantized into complete rows')
-- Remember original readable widths so layout does not oscillate after resize.
for i,r in ipairs(plan) do r.preferredW=windows[i].w;r.overhead=30;r.row=20 end
assert(not m.Plan(1200,800,plan,{},false,wide),'row drifts on repeated apply')
for i,r in ipairs(column) do r.preferredW=windows[i].w;r.overhead=30;r.row=20 end
assert(not m.Plan(1200,800,column,{},false,narrow),'column flips to row after resize')
assert(not m.Plan(1200,800,windows,{},true,{left=900,right=1000,bottom=20,top=330}),'unreadably narrow meters forced')
assert(not m.Plan(1200,800,windows,{},true,{left=600,right=1000,bottom=20,top=45}),'empty meters forced')
assert(not m.Plan(1200,800,windows,{},true),'missing anchors guessed screen percentages')
local blocked={{x=600,y=20,w=400,h=310}}
assert(not m.Plan(1200,800,windows,blocked,true,narrow),'fully blocked region forced')
local obstacle={{x=900,y=140,w=100,h=190}}
local cut=m.Plan(1200,800,windows,obstacle,true,wide);Check(cut,wide,obstacle)
-- A taller physical screen must NOT raise the ceiling above the target.
local tall=m.Plan(3600,2260,windows,{},true,wide);Check(tall,wide)
-- The supplied region can extend to the bottom line, not a hardcoded y=24.
local low={left=400,right=1000,bottom=3,top=220}
local lowPlan=m.Plan(1200,800,windows,{},true,low);Check(lowPlan,low);assert(lowPlan[1].y==3)
-- Real adapter: unequal scales, native SetSize/row clipping, external combat moves.
C_Timer={queue={}}
function C_Timer.After(_,fn) table.insert(C_Timer.queue,fn) end
local function Flush()
 local count=0
 while #C_Timer.queue>0 do count=count+1;assert(count<15,'recursive scheduling');table.remove(C_Timer.queue,1)() end
end
function hooksecurefunc(target,key,callback)
 local old=target[key];target[key]=function(...) local result=old(...);callback(...);return result end
end
local function Instance(display,x,scale)
 local f={x=x,y=24,w=280,h=400,scale=scale,protected=false,scripts={}}
 function f:IsShown() return true end
 function f:IsProtected() return self.protected end
 function f:GetRect() return self.x,self.y,self.w,self.h end
 function f:GetEffectiveScale() return self.scale end
 function f:HookScript(event,fn) self.scripts[event]=fn end
 function f:ClearAllPoints() self.cleared=true end
 function f:SetPoint(_,_,_,x,y) self.x,self.y=x,y end
 function f:SetScale(s) self.scale=s end
 local inst={baseframe=f,saves=0,row_info={height=14,space={between=7}},rows_fit_in_window=19}
 function inst:GetDisplay() return display end
 function inst:CreatePositionTable() return {pos_table=true,x=f.x,y=f.y,w=f.w,h=f.h} end
 function inst:SaveMainWindowPosition() self.saves=self.saves+1 end
 function inst:SetSize(w,h) f.w,f.h=w,h;self.rows_fit_in_window=math.floor(h/21);if f.scripts.OnSizeChanged then f.scripts.OnSizeChanged() end end
 function inst:RestorePositionFromPositionTable(p) f.x,f.y,f.w,f.h=p.x,p.y,p.w,p.h;self.restored=true end
 return inst
end
local function Anchor(x,y,w,h)
 local f={x=x,y=y,w=w,h=h,scripts={},shown=true}
 function f:IsShown() return self.shown end
 function f:GetRect() return self.x,self.y,self.w,self.h end
 function f:GetEffectiveScale() return .8 end
 function f:HookScript(event,fn) self.scripts[event]=fn end
 function f:SetPoint(_,_,_,x,y) self.x,self.y=x,y end
 return f
end
oUF_Target=Anchor(650,480,200,60);oUF_Target.Portrait=Anchor(700,450,60,100)
Minimap=Anchor(1080,40,100,120);MinimapAnchor=Minimap
ButtonCollectFrame=Anchor(1055,160,20,20)
BottomPanel=Anchor(0,18,1200,1)
ActionBarAnchor=Anchor(400,10,260,100)
local a,b=Instance(1,1500,.4),Instance(2,1520,.6)
Details={tabela_instancias={a,b}}
m:Initialize();m.loggedIn=true
combat=true;a.baseframe.protected=true;m:Apply();assert(m.pending and a.saves==0,'protected frame changed in combat')
combat=false;m.events.OnEvent(nil,'PLAYER_REGEN_ENABLED');Flush()
assert(a.saves>=1 and b.saves>=1 and m.originals[a].x==1500,'original backup/persistence missing')
assert(a.rows_fit_in_window>=1 and b.rows_fit_in_window>=1,'native row clipping not updated')
assert(m.bounds.top==442 and m.bounds.bottom==21,'target portrait or bottom information line ignored')
assert(m.bounds.left>=ActionBarAnchor.x+ActionBarAnchor.w+8,'action bars not reserved')
assert(m.bounds.right<=Minimap.x-2*(ButtonCollectFrame.w+1),'two icon columns not reserved')
local function Rect(inst)
 local f=inst.baseframe;local r=f.scale/.8
 return {x=f.x*r-36*r,y=f.y*r-6*r,w=(f.w+72)*r,h=(f.h+32)*r,rows=inst.rows_fit_in_window}
end
local function CheckActual()
 local ra,rb=Rect(a),Rect(b);Check({ra,rb},m.bounds)
 if m.mode=='column' then assert(ra.y+ra.h<rb.y,'stack overlaps')
 else assert(ra.x+ra.w<rb.x,'side-by-side overlaps') end
end
CheckActual();assert(m.mode=='column','narrow actual region did not stack')
local count=a.saves;m:Apply();assert(a.saves==count,'layout repeatedly drifted')
-- Hidden target still has a stable layout anchor; it must not raise the meters.
oUF_Target.shown=false;m:Apply();assert(m.bounds.top==442 and a.saves==count,'hidden target changed measured ceiling')
oUF_Target.shown=true
-- Real portraits are adjacent to the health frame, with an 8px gap. They
-- extend below it and inherit target visibility. Pre-reserve this footprint
-- before the first target; selection must not change mode, width or position.
oUF_Target.Portrait.x=858;oUF_Target.Portrait.y=390
oUF_Target.shown=false;oUF_Target.Portrait.shown=false
oUF_TargetTarget=Anchor(700,410,140,18);oUF_TargetTarget.shown=false
m:Apply(true);CheckActual();assert(m.bounds.top==382,'hidden adjacent portrait/ToT footprint was not reserved')
local beforeA,beforeB=Rect(a),Rect(b);count=a.saves;local beforeMode=m.mode
oUF_Target.shown=true;oUF_Target.Portrait.shown=true;oUF_TargetTarget.shown=true
m.events.OnEvent(nil,'PLAYER_TARGET_CHANGED');Flush();CheckActual()
assert(a.saves==count and m.mode==beforeMode,'target acquisition changed a precomputed layout')
local afterA,afterB=Rect(a),Rect(b)
for _,k in ipairs({'x','y','w','h'}) do assert(beforeA[k]==afterA[k] and beforeB[k]==afterB[k],'target acquisition moved/resized a meter') end
oUF_Target.shown=false;oUF_Target.Portrait.shown=false;oUF_TargetTarget.shown=false
m.events.OnEvent(nil,'PLAYER_TARGET_CHANGED');Flush();assert(a.saves==count,'target clearing changed layout')
oUF_TargetTarget=nil;oUF_Target.shown=true;oUF_Target.Portrait.shown=true
oUF_Target.Portrait.x=700;oUF_Target.Portrait.y=450;m:Apply(true)
-- Moving the action bar frees real width; screen resolution itself is unchanged.
ActionBarAnchor:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',100,10);Flush()
CheckActual();assert(m.mode=='row','freed measured width did not switch to row')
ActionBarAnchor:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',400,10);Flush()
CheckActual();assert(m.mode=='column','narrowed region did not switch back')
-- Actual anchors may have a different effective scale from UIParent.
function BottomPanel:GetEffectiveScale() return .4 end
m:Apply(true);assert(m.bounds.bottom==11.5,'bottom line effective scale ignored');CheckActual()
function BottomPanel:GetEffectiveScale() return .8 end
m:Apply(true);CheckActual()
-- Bar editor's invisible 12-slot anchor must not override measured buttons.
ActionButton1=Anchor(350,40,20,20);m:Apply(true)
assert(m.bounds.left==384 and m.mode=='row','phantom bar-anchor width reserved instead of actual buttons');CheckActual()
ActionButton1.x=760;m:Apply(true)
assert(m.bounds.left==794,'main skill button beyond target center was omitted from left boundary');CheckActual()
ActionButton1=nil;m:Apply(true);CheckActual()
-- Native Details dragging uses OnMouseUp rather than OnDragStop.
count=a.saves
a.baseframe.isMoving=true;a.baseframe:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',300,300);Flush()
assert(a.saves==count,'position was stolen while dragging')
a.baseframe.isMoving=false;a.baseframe.scripts.OnMouseUp();Flush();CheckActual()
count=a.saves
combat=true;a.baseframe.protected=false;a.baseframe:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',300,300);Flush()
assert(a.saves>count,'external combat move persisted');CheckActual()
for i=1,6 do a.baseframe:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',300,300);Flush() end
assert(m.status:find('停止争抢'),'conflicting external mover never stopped')
combat=false;m:Apply(true);CheckActual()
-- Unreadable target coordinates must not get formatted or used as table keys.
local originalGetRect=oUF_Target.GetRect;local secret={}
function issecretvalue(v) return v==secret end
function oUF_Target:GetRect() return secret,secret,secret,secret end
count=a.saves;m:Apply();assert(a.saves==count and not m.bounds,'secret target coordinates used')
oUF_Target.GetRect=originalGetRect;issecretvalue=nil
combat=true
NS.db.detailsLayout.enabled=false;m:Apply();assert(m.pending and not a.restored,'combat disable did not defer restore')
combat=false;m.events.OnEvent(nil,'PLAYER_REGEN_ENABLED');Flush()
assert(a.restored and a.baseframe.x==1500 and a.baseframe.h==400 and a.baseframe.w==280 and not next(m.originals),'position/size backup not restored')
NS.db.detailsLayout.enabled=true;a.SetSize=nil;m:Apply(true);assert(not next(m.originals),'unsupported API changed windows')
Details=nil;m:Apply();assert(m.status,'missing Details not tolerated')
""")
print('PASS: measured target/actionbar/minimap double-icon/bottom-line bounds; wide equal row and narrow equal column; full rows, mixed scales, hidden/secret target, anchor movement, combat and restore')
