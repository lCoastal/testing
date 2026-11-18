-- COASTAL PROSPECTING | BETA EARLY TELEPORT + TURBO
-- Experimental fast farm + independent TSV mineral logger
-- Requires an executor with file APIs. Never toggles shovel activation.
-- Close button stops loops, disconnects listeners, flushes pending log entries.

local P = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local E = getgenv()
if E.CoastalSafeFarm and E.CoastalSafeFarm.Close then
    pcall(function() E.CoastalSafeFarm:Close() end)
end
if E.StopUniversalLogger then pcall(E.StopUniversalLogger) end

-- New timestamped .txt file on EVERY launch; never overwrite previous runs.
local BASE=os.date("%H-%M-%S")
local FILE=BASE..".txt"
local function fileExists(path)
    if type(isfile)=="function" then
        local ok,exists=pcall(isfile,path)
        if ok then return exists end
    end
    if type(readfile)=="function" then
        return pcall(readfile,path)
    end
    return false
end
local suffix=1
while fileExists(FILE) do
    suffix+=1
    FILE=BASE.."_"..suffix..".txt"
end
local HEADER="Time\tPan\tMineral\tMutation\tWeight (kg)\tItemID\tLuck\tSize Boost\tModifier Boost\tCapacity\tZone\n"
local CFG={dig=.025,shake=.028,shakeGap=.008,teleport=.06,panRetry=.035,rewardGap=.3,logGap=.5,timeout=3,maxDig=600,maxShake=180}
-- Turbo timings are optional; regular timings remain available for comparison.
local TURBO={dig=.012,shake=.015,shakeGap=.005,teleport=.04,panRetry=.018}
local S={alive=true,running=false,testing=false,token=0,cycles=0,dig=nil,water=nil,sell=false,selling=false,doubleShake=true,
    earlyTP=true,turbo=false,recentTimes={},
    waiting=false,completed=false,rewards=0,lastReward=0,seen={},links={},completion=nil,
    sellQueue={},lastQueuedCycle=0}
local L={running=true,pending={},unsaved={},seen=setmetatable({},{__mode="k"}),pan=0,minerals=0,lastItem=0,error=nil,writing=false}
E.CoastalSafeFarm=S
local function timing(key)
    return (S.turbo and TURBO[key]) or CFG[key]
end

local function valid(id) return S.alive and S.running and S.token==id end
local function bind(sig,fn) local c=sig:Connect(fn);S.links[#S.links+1]=c;return c end
local function root() local c=P.Character;return c and c:FindFirstChild("HumanoidRootPart") end
local function panTool()
    local c=P.Character
    if not c then return end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local x=t:FindFirstChild("Scripts")
            local d=x and x:FindFirstChild("Collect")
            local p=x and x:FindFirstChild("Pan")
            local s=x and x:FindFirstChild("Shake")
            if d and p and s and d:IsA("RemoteFunction") and p:IsA("RemoteFunction") and s:IsA("RemoteEvent") then
                return {tool=t,dig=d,pan=p,shake=s,done=x:FindFirstChild("PanningComplete")}
            end
        end
    end
end
local function fill(r) return tonumber(r.tool:GetAttribute("Fill")) end
local function capacity()
    local a=P:FindFirstChild("Stats")
    return a and tonumber(a:GetAttribute("Capacity"))
end
local function pause(sec,id,ready)
    local deadline=os.clock()+sec
    while os.clock()<deadline do
        if not valid(id) then return false end
        if ready and ready() then return true end
        task.wait(.01)
    end
    return valid(id)
end
local function invoke(r,id,...)
    if not valid(id) then return false end
    local args=table.pack(...)
    local done,ok,res=false,false,nil
    task.spawn(function()
        if valid(id) then
            ok,res=pcall(function() return r:InvokeServer(table.unpack(args,1,args.n)) end)
        end
        done=true
    end)
    local deadline=os.clock()+CFG.timeout
    while not done and valid(id) and os.clock()<deadline do task.wait(.01) end
    return done and ok and valid(id),res
end
local function move(cf,id)
    for _=1,2 do
        if not valid(id) then return false end
        local r=root()
        if not r then return false end
        if (r.Position-cf.Position).Magnitude<7 then return true end
        local ok=pcall(function() r.CFrame=cf end)
        if not ok or not pause(timing("teleport"),id) then return false end
        r=root()
        if r and (r.Position-cf.Position).Magnitude<10 then return true end
    end
    return false
end

-- Persistent tab-separated logger
local function cell(v)
    local s=tostring(v==nil and "" or v)
    return (s:gsub("[\t\r\n]"," "))
end
local function search(root,names)
    if not root then return nil end
    local function check(obj)
        for _,name in ipairs(names) do
            local a=obj:GetAttribute(name)
            if a~=nil then return a end
            if obj.Name==name and obj:IsA("ValueBase") then return obj.Value end
        end
    end
    local value=check(root)
    if value~=nil then return value end
    for _,child in ipairs(root:GetDescendants()) do
        value=check(child)
        if value~=nil then return value end
    end
end
local function stat(names)
    local stats=P:FindFirstChild("Stats")
    if stats then
        for _,name in ipairs(names) do
            local v=stats:GetAttribute(name)
            if v~=nil then return v end
            local child=stats:FindFirstChild(name)
            if child and child:IsA("ValueBase") then return child.Value end
        end
        local v=search(stats,names)
        if v~=nil then return v end
    end
    for _,name in ipairs(names) do
        local v=P:GetAttribute(name)
        if v~=nil then return v end
    end
    return "UNKNOWN"
end
local function zone()
    local v=P:GetAttribute("LastDeposit")
    if v==nil then
        local st=P:FindFirstChild("Stats")
        v=st and st:GetAttribute("LastDeposit")
    end
    if v==nil then v=search(P:FindFirstChild("Data"),{"LastDeposit"}) end
    if v==nil then v=P:GetAttribute("CurrentDeposit") end
    if v==nil then v=P:GetAttribute("CurrentArea") end
    if typeof(v)=="Instance" then return v.Name end
    return v==nil and "UNKNOWN" or tostring(v)
end
local function itemData(item)
    local d=item:FindFirstChild("ItemData")
    if not d then return nil,nil,false end
    local weight=d:GetAttribute("Weight")
    local mutation=d:GetAttribute("Modifier")
    if weight==nil then weight=search(d,{"Weight"}) end
    if mutation==nil then mutation=search(d,{"Modifier","Mutation"}) end
    return weight,mutation,true
end
local function flush()
    if L.writing or #L.unsaved==0 then return end
    L.writing=true
    -- Move queued rows aside BEFORE a potentially yielding file operation.
    -- New batches appended during a write must not be erased afterward.
    local batch=L.unsaved
    L.unsaved={}
    local chunk=table.concat(batch)
    local ok,err=pcall(function()
        if type(appendfile)=="function" then
            appendfile(FILE,chunk)
        elseif type(readfile)=="function" and type(writefile)=="function" then
            writefile(FILE,readfile(FILE)..chunk)
        else
            error("Executor lacks appendfile/readfile")
        end
    end)
    if ok then
        L.error=nil
    else
        local retry={}
        for _,line in ipairs(batch) do retry[#retry+1]=line end
        for _,line in ipairs(L.unsaved) do retry[#retry+1]=line end
        L.unsaved=retry
        L.error=tostring(err)
        warn("[COASTAL LOGGER] Write failure:",err)
    end
    L.writing=false
end
local function finishBatch()
    if #L.pending>0 then
        L.pan+=1
        local lines={}
        for _,d in ipairs(L.pending) do
            local w,m,has=itemData(d.item)
            w=w or d.weight or "UNKNOWN"
            m=m or d.mutation or (has and "None" or "UNKNOWN")
            lines[#lines+1]=table.concat({
                cell(d.time),cell(L.pan),cell(d.name),cell(m),cell(w),
                cell(d.id),cell(d.luck),cell(d.size),cell(d.mod),cell(d.cap),cell(d.zone)
            },"\t")
        end
        L.minerals+=#L.pending
        L.pending={}
        L.unsaved[#L.unsaved+1]=table.concat(lines,"\n").."\n"
    end
    flush()
end
local function logItem(item)
    if not L.running or L.seen[item] or not item:IsA("Tool") then return end
    if item:GetAttribute("ItemType")~="Valuable" then return end
    L.seen[item]=true
    local w,m=itemData(item)
    L.pending[#L.pending+1]={
        item=item,time=os.date("%Y-%m-%d %H:%M:%S"),name=item.Name,weight=w,mutation=m,
        id=item:GetAttribute("ItemID") or "UNKNOWN",
        luck=stat({"TotalLuck","ActiveLuck","MiningLuck","Luck"}),
        size=stat({"SizeBoost","SizeMultiplier"}),
        mod=stat({"ModifierBoost","ModBoost","MutationBoost"}),
        cap=stat({"Capacity","PanCapacity"}),zone=zone()
    }
    L.lastItem=os.clock()
end
-- Start a new session file now, including the TSV column names.
if type(writefile)=="function" then
    local ok,err=pcall(writefile,FILE,HEADER)
    if not ok then L.error=tostring(err) end
else
    L.error="Executor lacks writefile"
end
local backpack=P:WaitForChild("BackpackTwo")
for _,item in ipairs(backpack:GetChildren()) do L.seen[item]=true end
local function stopLogger()
    if not L.running then return end
    L.running=false
    finishBatch()
end
E.StopUniversalLogger=stopLogger
bind(backpack.ChildAdded,function(item)
    if L.running then
        logItem(item)
        if item:GetAttribute("ItemType")==nil then
            task.delay(.1,function() if L.running then logItem(item) end end)
        end
    end
    if not S.running or not S.waiting then return end
    local id=S.token
    task.delay(.02,function()
        if not valid(id) or not S.waiting or not item:IsA("Tool") then return end
        if item:GetAttribute("ItemType")=="Valuable" and not S.seen[item] then
            S.seen[item]=true
            S.rewards+=1
            S.lastReward=os.clock()
        end
    end)
end)
task.spawn(function()
    while L.running do
        task.wait(.05)
        if #L.pending>0 and os.clock()-L.lastItem>=CFG.logGap then
            finishBatch()
        elseif #L.unsaved>0 then
            flush()
        end
    end
end)

-- Minimal monochrome UI
local G=Instance.new("ScreenGui")
G.Name="CoastalProspectingBeta";G.ResetOnSpawn=false;G.DisplayOrder=9999
local parent=P:WaitForChild("PlayerGui")
if type(gethui)=="function" then
    local ok,v=pcall(gethui)
    if ok and v then parent=v end
end
G.Parent=parent
local BG=Color3.fromRGB(22,23,27)
local PANEL=Color3.fromRGB(39,41,47)
local FG=Color3.fromRGB(237,237,241)
local MUTED=Color3.fromRGB(145,148,158)
local function make(class,props,par)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=par
    return o
end
local function rounded(o)
    make("UICorner",{CornerRadius=UDim.new(0,7)},o)
    return o
end
local W=rounded(make("Frame",{
    Size=UDim2.fromOffset(340,535),
    Position=UDim2.new(.5,-170,.5,-267),
    BackgroundColor3=BG,BorderSizePixel=0,Active=true
},G))
make("UIStroke",{Color=Color3.fromRGB(69,71,79),Thickness=1},W)
local H=make("Frame",{Size=UDim2.new(1,0,0,43),BackgroundTransparency=1,Active=true},W)
make("TextLabel",{
    Position=UDim2.fromOffset(14,0),Size=UDim2.fromOffset(245,43),
    BackgroundTransparency=1,Text="COASTAL  /  PROSPECTING BETA",
    TextColor3=FG,Font=Enum.Font.GothamBold,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
},H)
local function button(txt,x,y,w,h,par)
    return rounded(make("TextButton",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundColor3=PANEL,BorderSizePixel=0,Text=txt,
        TextColor3=FG,Font=Enum.Font.GothamMedium,TextSize=12,AutoButtonColor=true
    },par or W))
end
local X=button("×",302,7,29,29,H)
local Min=button("−",269,7,29,29,H)
local Body=make("Frame",{Position=UDim2.fromOffset(0,43),Size=UDim2.new(1,0,1,-43),BackgroundTransparency=1},W)
local function label(txt,x,y,w,h,size,color)
    return make("TextLabel",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundTransparency=1,Text=txt,TextColor3=color or FG,
        Font=Enum.Font.Gotham,TextSize=size or 11,TextXAlignment=Enum.TextXAlignment.Left
    },Body)
end
local status=label("Idle",14,7,312,23,12,MUTED)
local count=label("0 completed pans",14,31,312,27,16)
count.Font=Enum.Font.GothamBold
local digB=button("SET DIG",14,69,149,36,Body)
local waterB=button("SET WATER",177,69,149,36,Body)
local digXYZ=label("Not saved",14,109,149,22,10,MUTED)
local waterXYZ=label("Not saved",177,109,149,22,10,MUTED)
digXYZ.TextXAlignment=Enum.TextXAlignment.Center
waterXYZ.TextXAlignment=Enum.TextXAlignment.Center
local testB=button("TEST DIG",14,141,149,36,Body)
local sellB=button("AUTO SELL: OFF",177,141,149,36,Body)
local shakeB=button("DOUBLE SHAKE: ON",14,188,312,35,Body)
local startB=button("START",14,235,149,40,Body)
local stopB=button("STOP",177,235,149,40,Body)
label("Capacity",14,286,130,27,12,MUTED)
local cap=rounded(make("TextBox",{
    Position=UDim2.fromOffset(177,284),Size=UDim2.fromOffset(149,29),
    BackgroundColor3=PANEL,BorderSizePixel=0,
    Text=tostring(capacity() or ""),PlaceholderText="Capacity",
    TextColor3=FG,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false
},Body))
local logStatus=label("Logger: starting...",14,320,312,20,11,MUTED)
local zoneStatus=label("Zone: "..zone(),14,342,312,20,11,MUTED)
local earlyB=button("EARLY TP: ON (EXPERIMENT)",14,367,312,34,Body)
local perfStatus=label("Last cycle: --",14,408,312,37,11,MUTED)
perfStatus.TextWrapped=true
local turboB=button("TURBO: OFF (TEST)",14,455,312,34,Body)
local function show(t) if S.alive then status.Text=t end end
local function xyz(cf)
    local p=cf.Position
    return string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
end
task.spawn(function()
    while S.alive do
        logStatus.Text=L.error and ("Logger error: "..tostring(L.error):sub(1,27))
            or string.format("Logger: %d batches / %d minerals",L.pan,L.minerals)
        zoneStatus.Text="Zone: "..zone()
        task.wait(.5)
    end
end)

local function stop()
    if not S.alive then return end
    S.running=false;S.token+=1;S.waiting=false
    S.sellQueue={}
    if S.completion then S.completion:Disconnect();S.completion=nil end
    finishBatch()
    show("Stopped")
end
local function close()
    if not S.alive then return end
    stop()
    stopLogger()
    S.alive=false
    for _,c in ipairs(S.links) do pcall(function() c:Disconnect() end) end
    G:Destroy()
    if E.CoastalSafeFarm==S then E.CoastalSafeFarm=nil end
    if E.StopUniversalLogger==stopLogger then E.StopUniversalLogger=nil end
end
S.Stop=stop;S.Close=close

local function getSell()
    local rem=RS:FindFirstChild("Remotes")
    local shop=rem and rem:FindFirstChild("Shop")
    local r=shop and shop:FindFirstChild("SellAll")
    return r and r:IsA("RemoteFunction") and r or nil
end
-- Exactly one SellAll request for each successfully completed pan
-- while Auto Sell is enabled. Sequential queue prevents dropped pans.
-- Sales run separately, so digging is never blocked by selling.
local function autoSell(id,cycle)
    if not S.sell or not valid(id) or S.lastQueuedCycle==cycle then return end
    S.lastQueuedCycle=cycle
    S.sellQueue[#S.sellQueue+1]={id=id,cycle=cycle,queuedAt=os.clock()}
    if S.selling then return end
    S.selling=true
    task.spawn(function()
        while S.alive and #S.sellQueue>0 do
            local job=table.remove(S.sellQueue,1)
            if valid(job.id) and S.sell then
                -- Let rewards replicate and the logger flush before selling.
                -- Do not wait for newer pans indefinitely.
                local deadline=os.clock()+2.5
                while valid(job.id) and S.sell and os.clock()<deadline do
                    if os.clock()-job.queuedAt>=CFG.logGap
                        and #L.pending==0 and #L.unsaved==0 and not L.writing then
                        break
                    end
                    task.wait(.025)
                end
                if valid(job.id) and S.sell then
                    local r=getSell()
                    if r then
                        local ok=pcall(function() r:InvokeServer() end)
                        if not ok then show("Auto Sell failed on pan "..job.cycle) end
                    else
                        S.sell=false
                        sellB.Text="AUTO SELL: OFF"
                        show("SellAll unavailable")
                    end
                end
            end
        end
        S.selling=false
    end)
end
local function farming(id,r,target)
    while valid(id) do
        local cycleStart=os.clock()
        show("Digging")
        if not move(S.dig,id) then return "Dig teleport failed" end
        local lastProgress=os.clock()
        for _=1,CFG.maxDig do
            if not valid(id) then return end
            local before=fill(r)
            if before==nil then return "Fill unavailable" end
            if before>=target-.01 then break end
            local ok=invoke(r.dig,id,1)
            if not ok then return "Collect failed" end
            if not pause(timing("dig"),id) then return end
            local after=fill(r)
            if after and after>before+.001 then lastProgress=os.clock() end
            if os.clock()-lastProgress>3 then return "Digging stalled" end
        end
        if not valid(id) then return end
        if (fill(r) or 0)<target-.01 then return "Pan not full" end
        local digTime=os.clock()-cycleStart

        show("Panning")
        local waterStart=os.clock()
        if not move(S.water,id) then return "Water teleport failed" end
        local waterTime=os.clock()-waterStart
        S.rewards=0;S.lastReward=0;S.completed=false;S.waiting=true;S.seen={}
        local panStart=os.clock()
        local accepted=false
        for _=1,15 do
            if not valid(id) then return end
            local ok,result=invoke(r.pan,id)
            if not ok then return "Pan call failed" end
            if result==true then accepted=true;break end
            if not pause(timing("panRetry"),id) then return end
        end
        if not accepted then return "Pan rejected" end
        local panTime=os.clock()-panStart

        show("Shaking")
        local shakeStart=os.clock()
        local earlyMoved=false
        local earlyTime=0
        local function finished()
            return S.completed or (S.rewards>0 and os.clock()-S.lastReward>=CFG.rewardGap)
        end
        -- Experimental early travel after first two rewards and a very short lull.
        -- Starts at ~30ms of quiet instead of ~165ms. If leaving water
        -- interrupts remaining rewards, switch Early TP OFF for that zone.
        -- No further shake packets are sent after teleporting.
        local function tryEarlyMove()
            if not S.earlyTP or earlyMoved or S.completed or S.rewards<2 then return false end
            if os.clock()-S.lastReward < math.max(.03,CFG.rewardGap*.10) then return false end
            show("Early teleport (test)")
            local t=os.clock()
            if not move(S.dig,id) then return nil,"Early teleport failed" end
            earlyTime=os.clock()-t
            earlyMoved=true
            return true
        end

        local done=false
        for _=1,CFG.maxShake do
            if not valid(id) then return end
            if finished() then done=true;break end
            local jumped,err=tryEarlyMove()
            if err then return err end
            if jumped then break end

            local ok=pcall(function() r.shake:FireServer() end)
            if not ok then return "Shake failed" end
            if S.doubleShake then
                if not pause(timing("shakeGap"),id,finished) then return end
                if finished() then done=true;break end
                jumped,err=tryEarlyMove()
                if err then return err end
                if jumped then break end
                ok=pcall(function() r.shake:FireServer() end)
                if not ok then return "Shake failed" end
            end
            if not pause(timing("shake"),id,finished) then return end
        end

        if not done then
            local deadline=os.clock()+(earlyMoved and 3 or 1.5)
            while valid(id) and os.clock()<deadline do
                if finished() then done=true;break end
                task.wait(.02)
            end
        end
        if not done then return "No completion detected" end
        if not valid(id) then return end
        local shakeTime=os.clock()-shakeStart

        S.waiting=false
        S.cycles+=1
        local total=os.clock()-cycleStart
        local recent=S.recentTimes
        recent[#recent+1]=total
        if #recent>10 then table.remove(recent,1) end
        local sum=0
        for _,v in ipairs(recent) do sum+=v end
        local ppm=sum>0 and (60*#recent/sum) or 0
        count.Text=string.format("%d completed pans | %.1f/min",S.cycles,ppm)
        perfStatus.Text=string.format(
            "Last %.2fs | Dig %.2fs | Water %.2fs | Pan %.2fs\nShake+wait %.2fs | Early TP %s (%.2fs) | Avg %d",
            total,digTime,waterTime,panTime,shakeTime,
            earlyMoved and "YES" or "NO",earlyTime,#recent
        )
        autoSell(id,S.cycles)
    end
end
bind(digB.MouseButton1Click,function()
    if S.running then return end
    local r=root()
    if r then S.dig=r.CFrame;digB.Text="DIG SAVED";digXYZ.Text=xyz(S.dig) end
end)
bind(waterB.MouseButton1Click,function()
    if S.running then return end
    local r=root()
    if r then S.water=r.CFrame;waterB.Text="WATER SAVED";waterXYZ.Text=xyz(S.water) end
end)
bind(testB.MouseButton1Click,function()
    if S.running or S.testing then return end
    local r=panTool()
    if not r then show("Equip your pan");return end
    S.testing=true;show("Testing dig")
    task.spawn(function()
        local before=fill(r)
        local ok=pcall(function() r.dig:InvokeServer(1) end)
        task.wait(.2)
        if not S.alive then return end
        local after=fill(r)
        S.testing=false
        show(ok and before and after and after>before and "Dig test successful" or "Dig test failed")
    end)
end)
bind(sellB.MouseButton1Click,function()
    if not S.sell and not getSell() then show("SellAll unavailable");return end
    S.sell=not S.sell
    sellB.Text="AUTO SELL: "..(S.sell and "ON" or "OFF")
end)
bind(shakeB.MouseButton1Click,function()
    S.doubleShake=not S.doubleShake
    shakeB.Text="DOUBLE SHAKE: "..(S.doubleShake and "ON" or "OFF")
end)
bind(earlyB.MouseButton1Click,function()
    S.earlyTP=not S.earlyTP
    S.recentTimes={}
    earlyB.Text="EARLY TP: "..(S.earlyTP and "ON (EXPERIMENT)" or "OFF (EXPERIMENT)")
    perfStatus.Text="Speed sample reset: measure 10 pans for comparison"
end)
bind(turboB.MouseButton1Click,function()
    S.turbo=not S.turbo
    S.recentTimes={}
    turboB.Text="TURBO: "..(S.turbo and "ON (TEST)" or "OFF (TEST)")
    perfStatus.Text="Speed sample reset: measure 10 pans for comparison"
end)
bind(startB.MouseButton1Click,function()
    if S.running or S.testing then return end
    if not S.dig or not S.water then show("Save both positions");return end
    local r=panTool()
    if not r then show("Equip your pan");return end
    local target=tonumber(cap.Text)
    if not target or target<=0 then show("Invalid capacity");return end
    if fill(r)==nil then show("Fill unavailable");return end
    S.running=true;S.token+=1
    local id=S.token
    if r.done and r.done:IsA("RemoteEvent") then
        S.completion=r.done.OnClientEvent:Connect(function()
            if valid(id) and S.waiting then S.completed=true end
        end)
    end
    show("Running")
    task.spawn(function()
        local ok,reason=pcall(farming,id,r,target)
        if valid(id) then
            stop()
            show(ok and (reason or "Stopped") or "Automation error")
        end
    end)
end)
bind(stopB.MouseButton1Click,stop)
bind(X.MouseButton1Click,close)
local minimized=false
bind(Min.MouseButton1Click,function()
    minimized=not minimized
    Body.Visible=not minimized
    W.Size=minimized and UDim2.fromOffset(340,43) or UDim2.fromOffset(340,535)
    Min.Text=minimized and "+" or "−"
end)
local dragging=false
local dragStart,windowStart
bind(H.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true;dragStart=i.Position;windowStart=W.Position
    end
end)
bind(UIS.InputChanged,function(i)
    if dragging and S.alive and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        W.Position=UDim2.new(windowStart.X.Scale,windowStart.X.Offset+d.X,
            windowStart.Y.Scale,windowStart.Y.Offset+d.Y)
    end
end)
bind(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
bind(P.CharacterRemoving,function() if S.running then stop() end end)
print("[COASTAL BETA] Loaded. TSV:",FILE)
if L.error then warn("[COASTAL BETA] Logger:",L.error) end
