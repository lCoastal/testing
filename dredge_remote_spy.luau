-- GALAXIS HUB | DREDGE REMOTE SPY
-- Observes client->server remote calls; DOES NOT fire, invoke, modify, or block them.
-- Default: Quests/NPCs/Settings remotes only. Toggle ALL to inspect every remote.
-- Writes timestamped logs if executor file APIs exist; clipboard only on button press.
-- An executor supporting hookmetamethod and getnamecallmethod is required.

local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local E=getgenv()

if E.GalaxisDredgeRemoteSpy and E.GalaxisDredgeRemoteSpy.Close then
    pcall(function() E.GalaxisDredgeRemoteSpy:Close() end)
end

local spy={
    active=true,alive=true,all=false,count=0,dropped=0,
    lines={},file=nil,links={},last="Waiting for quest interactions..."
}
E.GalaxisDredgeRemoteSpy=spy

local function exists(path)
    if type(isfile)=="function" then
        local ok,result=pcall(isfile,path)
        if ok then return result end
    end
    if type(readfile)=="function" then return pcall(readfile,path) end
    return false
end

local base="DredgeSpy_"..os.date("%H-%M-%S")
local file=base..".txt"
local suffix=1
while exists(file) do
    suffix+=1
    file=base.."_"..suffix..".txt"
end
spy.file=file

local function line(s)
    local msg=tostring(s)
    if #spy.lines>=450 then
        table.remove(spy.lines,2) -- Keep the header and newest events.
        spy.dropped+=1
    end
    spy.lines[#spy.lines+1]=msg
    print("[GALAXIS SPY] "..msg)
    if spy.file and type(appendfile)=="function" then
        local ok,err=pcall(appendfile,spy.file,msg.."\n")
        if not ok then warn("[GALAXIS SPY] File append failed:",err) end
    end
end

local header="GALAXIS HUB DREDGE REMOTE SPY | "..os.date("%Y-%m-%d %H:%M:%S")
if type(writefile)=="function" then
    local ok,err=pcall(writefile,file,header.."\n")
    if not ok then warn("[GALAXIS SPY] File creation failed:",err);spy.file=nil end
else
    spy.file=nil
end
spy.lines[1]=header

local function pretty(v,depth,seen)
    local kind=typeof(v)
    if kind=="string" then
        return string.format("%q",v:sub(1,400))..(#v>400 and "...[truncated]" or "")
    end
    if kind=="Instance" then
        return "Instance<"..v:GetFullName()..">"
    end
    if kind~="table" then
        return kind=="nil" and "nil" or tostring(v)
    end
    if seen[v] then return "<cycle>" end
    if depth>=4 then return "{...}" end
    seen[v]=true
    local keys={}
    for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local parts={}
    for i,k in ipairs(keys) do
        if i>30 then parts[#parts+1]="... +"..(#keys-30).." fields";break end
        parts[#parts+1]="["..pretty(k,depth+1,seen).."]="..pretty(v[k],depth+1,seen)
    end
    seen[v]=nil
    return "{"..table.concat(parts,", ").."}"
end

local function bind(signal,fn)
    local c=signal:Connect(fn)
    spy.links[#spy.links+1]=c
    return c
end

local ui=Instance.new("ScreenGui")
ui.Name="GalaxisDredgeRemoteSpy"
ui.ResetOnSpawn=false
ui.DisplayOrder=10020
local parent=player:WaitForChild("PlayerGui")
if type(gethui)=="function" then
    local ok,h=pcall(gethui)
    if ok and h then parent=h end
end
ui.Parent=parent

local function make(class,props,par)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=par
    return o
end
local BG=Color3.fromRGB(22,23,28)
local PANEL=Color3.fromRGB(41,43,50)
local FG=Color3.fromRGB(240,241,244)
local MUTE=Color3.fromRGB(166,171,183)
local win=make("Frame",{
    Name="SpyWindow",
    Size=UDim2.fromOffset(390,210),
    Position=UDim2.new(.5,-195,.5,-105),
    BackgroundColor3=BG,BorderSizePixel=0,Active=true
},ui)
make("UICorner",{CornerRadius=UDim.new(0,9)},win)
make("UIStroke",{Color=Color3.fromRGB(83,87,100),Thickness=1},win)

local function label(t,y,h,size)
    return make("TextLabel",{
        Position=UDim2.fromOffset(13,y),Size=UDim2.fromOffset(364,h),
        BackgroundTransparency=1,Text=t,
        TextColor3=FG,Font=Enum.Font.GothamMedium,
        TextSize=size or 12,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd
    },win)
end
local title=label("GALAXIS HUB  /  DREDGE SPY",8,31,14)
title.Font=Enum.Font.GothamBold
local status=label("Listening for Quests / NPCs / Settings",45,22,12)
local latest=label("Last: waiting...",70,24,11)
latest.TextColor3=MUTE
local fileLabel=label(spy.file and ("Log: "..spy.file) or "Log: file API unavailable",96,23,11)
fileLabel.TextColor3=MUTE

local function button(t,x,w)
    local b=make("TextButton",{
        Position=UDim2.fromOffset(x,130),
        Size=UDim2.fromOffset(w,34),
        BackgroundColor3=PANEL,
        BorderSizePixel=0,Text=t,TextColor3=FG,
        Font=Enum.Font.GothamMedium,TextSize=12
    },win)
    make("UICorner",{CornerRadius=UDim.new(0,6)},b)
    return b
end
local stopB=button("PAUSE",13,85)
local modeB=button("ALL: OFF",108,85)
local copyB=button("COPY LOG",203,90)
local closeB=button("CLOSE",303,74)
local hint=label("Start spy → finish quest → accept next quest → COPY LOG",174,21,10)
hint.TextColor3=MUTE

local function refresh()
    if not spy.alive then return end
    status.Text=(spy.active and "CAPTURING" or "PAUSED")..
        " | "..spy.count.." calls | "..(spy.all and "ALL REMOTES" or "QUEST FILTER")
    latest.Text="Last: "..spy.last
end
local function copy()
    if type(setclipboard)~="function" then
        status.Text="Clipboard API unavailable; check file / console"
        return
    end
    local contents=table.concat(spy.lines,"\n")
    if spy.dropped>0 then contents=contents.."\n[Earlier "..spy.dropped.." entries not in clipboard; see file.]" end
    local ok,err=pcall(setclipboard,contents)
    if ok then status.Text="Copied "..spy.count.." calls to clipboard" else warn("[GALAXIS SPY] Copy failed:",err) end
end
function spy:Pause()
    self.active=false
    refresh()
    stopB.Text="RESUME"
end
function spy:Resume()
    self.active=true
    refresh()
    stopB.Text="PAUSE"
end
function spy:Copy() copy() end
function spy:Close()
    if not self.alive then return end
    self.active=false
    self.alive=false
    if E.GalaxisDredgeSpyRecord==self.record then E.GalaxisDredgeSpyRecord=nil end
    for _,c in ipairs(self.links) do pcall(function() c:Disconnect() end) end
    ui:Destroy()
    if E.GalaxisDredgeRemoteSpy==self then E.GalaxisDredgeRemoteSpy=nil end
end

bind(stopB.MouseButton1Click,function()
    if spy.active then spy:Pause() else spy:Resume() end
end)
bind(modeB.MouseButton1Click,function()
    spy.all=not spy.all
    modeB.Text="ALL: "..(spy.all and "ON" or "OFF")
    refresh()
end)
bind(copyB.MouseButton1Click,copy)
bind(closeB.MouseButton1Click,function() spy:Close() end)

local dragging=false
local origin,winStart
bind(win.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true;origin=i.Position;winStart=win.Position
    end
end)
bind(UIS.InputChanged,function(i)
    if dragging and spy.alive and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-origin
        win.Position=UDim2.new(winStart.X.Scale,winStart.X.Offset+d.X,
            winStart.Y.Scale,winStart.Y.Offset+d.Y)
    end
end)
bind(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

local recentSecond=0
local burst=0
local function isRelevant(remote,method)
    if not spy.alive or not spy.active then return false end
    if typeof(remote)~="Instance" then return false end
    if method=="FireServer" and not remote:IsA("RemoteEvent") then return false end
    if method=="InvokeServer" and not remote:IsA("RemoteFunction") then return false end

    local path=remote:GetFullName()
    if spy.all then return true end
    return path:find(".Remotes.Quests.",1,true)~=nil
        or path:find(".Remotes.Settings.",1,true)~=nil
        or path:find(".Remotes.NPCs.",1,true)~=nil
        or path:lower():find("dredge",1,true)~=nil
end

local function record(remote,method,args)
    if not isRelevant(remote,method) then return end
    local now=os.clock()
    if now-recentSecond>=1 then recentSecond=now;burst=0 end
    burst+=1
    if burst>30 then
        spy.dropped+=1
        return
    end
    local path=remote:GetFullName()
    -- Defer formatting and I/O so the original server call is not held up.
    task.defer(function()
        if not spy.alive then return end
        local ok,msg=pcall(function()
            local parts={}
            for i=1,math.min(args.n,30) do
                parts[#parts+1]=pretty(args[i],0,{})
            end
            if args.n>30 then parts[#parts+1]="... additional arguments" end
            return string.format("[%s] %s:%s(%s)",
                os.date("%H:%M:%S"),path,method,table.concat(parts,", "))
        end)
        if ok then
            spy.count+=1
            spy.last=remote.Name.." : "..method
            line(msg)
            refresh()
        else
            warn("[GALAXIS SPY] Formatting failed:",msg)
        end
    end)
end
spy.record=record

-- The __namecall hook is installed only once per executor session.
-- Later runs update one global receiver rather than stacking hooks.
E.GalaxisDredgeSpyRecord=record

if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then
    spy:Pause()
    status.Text="This executor does not support remote spying hooks"
    warn("[GALAXIS SPY] hookmetamethod and getnamecallmethod are required.")
elseif not E.GalaxisDredgeSpyHookInstalled then
    local wrap=type(newcclosure)=="function" and newcclosure or function(f)return f end
    local previous
    local intercept=wrap(function(self,...)
        local method=getnamecallmethod()
        if method=="FireServer" or method=="InvokeServer" then
            local listener=E.GalaxisDredgeSpyRecord
            if type(listener)=="function" then
                local caller=false
                if type(checkcaller)=="function" then
                    local ok,v=pcall(checkcaller)
                    caller=ok and v
                end
                if not caller then
                    local args=table.pack(...)
                    pcall(listener,self,method,args)
                end
            end
        end
        return previous(self,...)
    end)
    local ok,original=pcall(function() return hookmetamethod(game,"__namecall",intercept) end)
    if ok and type(original)=="function" then
        previous=original
        E.GalaxisDredgeSpyHookInstalled=true
        print("[GALAXIS SPY] Installed read-only __namecall observer.")
    else
        E.GalaxisDredgeSpyRecord=nil
        spy:Pause()
        status.Text="Hook failed: "..tostring(original):sub(1,60)
        warn("[GALAXIS SPY] Could not hook __namecall:",original)
    end
end

refresh()
print("[GALAXIS SPY] Capturing quest-related remotes. File:",spy.file or "not supported")
print("[GALAXIS SPY] Turn in Dredge quest and accept next, then press COPY LOG.")
