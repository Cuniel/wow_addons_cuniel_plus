from pathlib import Path
import sys
sys.path.insert(0, str(Path('work/lua-test-v036').resolve()))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
NS={db={chatTabs={enabled=true}},charDB={},modules={}}
function NS:RegisterModule(key,value) self.modules[key]=value end
function NS:Print(text) self.lastPrint=text end
local Frame={}
function Frame:GetID() return self.id end
function Frame:GetName() return 'ChatFrame'..self.id end
function Frame:GetFont() return 'Chinese.ttf',13,'OUTLINE' end
function Frame:GetPoint() return 'BOTTOMLEFT',UIParent,'BOTTOMLEFT',31,42 end
function Frame:GetSize() return 350,112 end
function Frame:RemoveAllMessageGroups() self.messageTypeList={} end
function Frame:RemoveAllChannels() self.channelList={} end
function Frame:ReceiveAllPrivateMessages() self.private=true end
function Frame:AddMessageGroup(group) table.insert(self.messageTypeList,group) end
function Frame:AddChannel(channel) table.insert(self.channelList,channel) end
function Frame:ClearAllPoints() end
function Frame:SetPoint(...) self.point={...} end
function Frame:SetSize(w,h) self.width,self.height=w,h end
UIParent={GetName=function() return 'UIParent' end}
NUM_CHAT_WINDOWS=10
opened,closed,combat=0,0,false
function hooksecurefunc(target,key,fn)
 local old=target[key];target[key]=function(...) local result=old(...);fn(...);return result end
end
local function TabFont()
 local fs={font='Chinese.ttf',size=9,flags='OUTLINE'}
 function fs:GetFont() return self.font,self.size,self.flags end
 function fs:SetFont(font,size,flags) self.font,self.size,self.flags=font,size,flags end
 return fs
end
function Reset()
 NS.charDB={}; NS.db.chatTabs.enabled=true
 for id=1,10 do
  _G['ChatFrame'..id]=setmetatable({id=id,name='',messageTypeList={},channelList={},active=false},{__index=Frame})
  local fs=TabFont();_G['ChatFrame'..id..'Tab']={GetFontString=function() return fs end}
 end
 for id=1,3 do local f=_G['ChatFrame'..id];f.name='builtin'..id;f.active=true;f.messageTypeList={'SYSTEM'} end
 for id=4,7 do local f=_G['ChatFrame'..id]; f.name='Old'..id;f.active=true;f.isDocked=id~=7;f.messageTypeList={'SAY'};f.channelList={'我的频道'} end
 ChatFrame7.isDocked=false
 opened,closed,combat=0,0,false
end
function GetChatWindowInfo(id)
 local f=_G['ChatFrame'..id]
 return f.name,15,0.1,0.2,0.3,0.4,f.active,true,f.isDocked and id or 0,false
end
function FCF_Close(frame)
 assert(frame.id>=4 and not frame.isTemporary,'closed protected or temporary frame')
 frame.active=false;frame.isDocked=false;frame.messageTypeList={};frame.channelList={};closed=closed+1
end
function FCF_SetWindowName(frame,name) frame.name=name end
function FCF_OpenNewWindow(name,noDefault)
 assert(noDefault,'default channels would leak into new tabs')
 for id=4,10 do local f=_G['ChatFrame'..id];if not f.active and not f.isTemporary then
  f.name=name;f.active=true;f.isDocked=true;opened=opened+1;return f
 end end
end
function FCF_SetLocked(frame,value) frame.locked=value end
function FCF_SetChatWindowFontSize(_,frame,size) frame.size=size end
function FCF_SetWindowColor(frame,r,g,b) frame.color={r,g,b} end
function FCF_SetWindowAlpha(frame,a) frame.alpha=a end
function FCF_UnDockFrame(frame) frame.isDocked=false end
function FCF_DockFrame(frame) frame.isDocked=true end
function FCF_SelectDockFrame(frame) selected=frame end
function FCF_SaveDock() saved=true end
function InCombatLockdown() return combat end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function(self,key,value) self[key]=value end} end
C_Timer={After=function(_,callback) callback() end}
function geterrorhandler() return function(err) NS.lastError=err end end
Reset()
''')
lua.eval('function(s) assert(loadstring(s))("Cuniel_plus",NS) end')(
    Path('Cuniel_plus/Modules/ChatTabs.lua').read_text(encoding='utf-8'))
lua.execute(r'''
local m=NS.modules.chatTabs
m:Initialize();m:Apply()
assert(opened==0,'configured before login')
m.events.OnEvent(nil,'PLAYER_ENTERING_WORLD')
assert(opened==3 and closed==4,'old permanent tabs were not cleared exactly once')
assert(ChatFrame4.name=='公会' and ChatFrame5.name=='密语' and ChatFrame6.name=='团队','Chinese tab names or reference order wrong')
assert(table.concat(ChatFrame4.messageTypeList,',')=='GUILD,OFFICER,GUILD_ACHIEVEMENT')
assert(table.concat(ChatFrame5.messageTypeList,',')=='WHISPER,BN_WHISPER','whisper replies/categories wrong')
assert(table.concat(ChatFrame6.messageTypeList,',')=='PARTY,PARTY_LEADER,RAID,RAID_LEADER,RAID_WARNING,INSTANCE_CHAT,INSTANCE_CHAT_LEADER')
assert(#ChatFrame4.channelList==0 and ChatFrame4.size==13,'changed chat body font or copied reference channels')
for id=1,3 do assert(_G['ChatFrame'..id].name=='builtin'..id and _G['ChatFrame'..id].messageTypeList[1]=='SYSTEM') end
assert(selected==ChatFrame1 and NS.charDB.chatTabs.version==1)
local backup=NS.charDB.chatTabs.backup
assert(#backup==4 and backup[1].name=='Old4' and backup[1].channels[1]=='我的频道','backup lost original settings')
assert(not backup[1].frame and not backup[1].messages,'backup saved live frames/chat history')
m:Apply();m.events.OnEvent(nil,'PLAYER_ENTERING_WORLD')
assert(opened==3 and closed==4,'reload/world entry duplicated tabs')
ChatFrame8.name='NewCustom';ChatFrame8.active=true
m:Apply();assert(ChatFrame8.active,'successful migration kept deleting user changes')
m:Configure(true)
assert(NS.charDB.chatTabs.backup==backup,'manual rebuild overwrote original backup')
assert(m:Restore(),'restore failed')
assert(NS.charDB.chatTabs.disabled and NS.charDB.chatTabs.backup==backup)
local names={};for id=4,10 do local f=_G['ChatFrame'..id];if f.active then names[f.name]=f end end
assert(names.Old4 and names.Old5 and names.Old6 and names.Old7,'restore lost original custom tabs')
assert(not names.Old7.isDocked and names.Old7.point[4]==31 and names.Old4.size==15)
local n=opened;m:Apply();assert(opened==n,'restored character was auto-overwritten')
-- New character on the same account must initialize independently.
Reset();m.failed=nil;m:Apply();assert(opened==3 and NS.charDB.chatTabs.version==1)
Reset();NS.db.chatTabs.enabled=false;m:Apply();assert(opened==0 and closed==0,'disabled setting touched tabs')
Reset();combat=true;m:Apply();assert(m.pending and not NS.charDB.chatTabs.backup and closed==0)
combat=false;m.events.OnEvent(nil,'PLAYER_REGEN_ENABLED');assert(opened==3 and not m.pending,'combat deferral failed')
Reset();m.failed=nil;local oldOpen=FCF_OpenNewWindow;FCF_OpenNewWindow=nil
m:Apply();assert(closed==0 and not NS.charDB.chatTabs.backup,'missing API destroyed settings');FCF_OpenNewWindow=oldOpen
Reset();ChatFrame4.isTemporary=true;ChatFrame4.chatTarget='private'
m:Apply();assert(ChatFrame4.active and ChatFrame4.name=='Old4' and opened==3,'temporary conversation was overwritten')
Reset();for id=4,9 do _G['ChatFrame'..id].isTemporary=true end
m:Apply();assert(closed==0 and not NS.charDB.chatTabs.backup,'no-capacity preflight changed settings')
Reset();FCF_OpenNewWindow=function() return nil end
m:Apply();assert(not NS.charDB.chatTabs.version and NS.charDB.chatTabs.backup and NS.lastError,'failure marked migration complete')
local closedAtFailure=closed;m:Apply();assert(closed==closedAtFailure,'failed migration looped automatically')
FCF_OpenNewWindow=oldOpen;assert(m:Restore(),'backup could not recover interrupted migration')
''')
# Targeted tab captions: existing initialized roles update without rebuilding,
# while body fonts and ordinary tabs stay independent of the 14-point default.
lua.execute(r"""
local m=NS.modules.chatTabs
Reset();m.failed=nil;NS.db.chatTabs.labelSize=nil;m:Apply()
local function Size(id) return select(2,_G['ChatFrame'..id..'Tab']:GetFontString():GetFont()) end
assert(Size(4)==14 and Size(5)==14 and Size(6)==14 and Size(1)==9,'three caption defaults or ordinary tabs wrong')
assert(ChatFrame4.size==13,'14-point caption changed chat body')
local count=opened
ChatFrame4Tab:GetFontString():SetFont('Chinese.ttf',8,'OUTLINE')
assert(Size(4)==14,'ShestakUI hover reset caption font')
NS.db.chatTabs.labelSize=16;m:Apply();assert(Size(4)==16 and opened==count,'changing size rebuilt windows')
combat=true;NS.db.chatTabs.labelSize=14;m:Apply();assert(m.labelPending and Size(4)==16,'changed captions in combat')
combat=false;m.events.OnEvent(nil,'PLAYER_REGEN_ENABLED');assert(Size(4)==14 and opened==count,'caption deferral missing')
ShestakUI={{mult=.5}};NS.db.readability={enabled=true,macOnly=false,size=18}
function IsMacClient() return true end
""")
lua.eval('function(s) assert(loadstring(s))("Cuniel_plus",NS) end')(
    Path('Cuniel_plus/Modules/Readability.lua').read_text(encoding='utf-8'))
lua.execute(r"""
local tabs=NS.modules.chatTabs;local readable=NS.modules.readability
readable:Apply()
assert(select(2,ChatFrame4Tab:GetFontString():GetFont())==14,'generic minimum overrode independent caption size')
ChatFrame5Tab:GetFontString():SetFont('Chinese.ttf',9,'OUTLINE')
assert(select(2,ChatFrame5Tab:GetFontString():GetFont())==14,'caption/readability hooks fight on mouseover')
NS.db.readability.enabled=false;readable:Apply()
NS.db.chatTabs.enabled=false;tabs:Apply()
assert(select(2,ChatFrame4Tab:GetFontString():GetFont())==8,'disabled captions did not restore original upstream size')
assert(ChatFrame4.size==13,'disabled caption changed body font')
""")
print('PASS: Chinese chat tabs replace old custom tabs once per character, preserve built-ins, back up/restore, defer combat and handle missing APIs/failures')
print('PASS: independent 14-point captions, hover persistence, no body/rebuild changes, configurable size, combat deferral, readability coexistence and restore')
