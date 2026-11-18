-- GALAXIS HUB | PROSPECTING BETA AUTO RECOVERY
-- Experimental fast farm + independent TSV mineral logger
-- Requires an executor with file APIs. Never toggles shovel activation.
-- Close button stops loops, disconnects listeners, flushes pending log entries.

local P = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
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
local CFG={dig=.025,shake=.028,shakeGap=.008,teleport=.06,panRetry=.035,rewardGap=.3,logGap=.5,timeout=3,digStall=1.25,recoveryDelay=.25,maxDig=600,maxShake=180}
-- Turbo timings are optional; regular timings remain available for comparison.
local TURBO={dig=.012,shake=.015,shakeGap=.005,teleport=.04,panRetry=.018}
local S={alive=true,running=false,token=0,cycles=0,dig=nil,water=nil,sell=false,selling=false,doubleShake=true,
    earlyTP=true,turbo=true,recentTimes={},totalCycleTime=0,
    waiting=false,completed=false,rewards=0,lastReward=0,seen={},links={},completion=nil,
    sellQueue={},lastQueuedCycle=0}
local L={running=true,pending={},unsaved={},seen=setmetatable({},{__mode="k"}),pan=0,minerals=0,lastItem=0,error=nil,writing=false}
E.CoastalSafeFarm=S
-- Exact Waypoints names: saved as human-selected dig/water position presets.
-- Only explicit LOAD PRESET changes the active farm coordinates.
-- The game has 21 FAST-TRAVEL WAYPOINTS but the toolkit has 35 MINING ZONES.
-- Zones own dig/water coordinates; many zones can map to the same waypoint.
local WAYPOINT_NAMES={
    "Crystal Caverns","Deeproot Spring","Dredge Master","Fortune River",
    "Fortune River Delta","Frostbitten Path","Frozen Peak","Lifespring Oasis",
    "Meteor Valley","Meteor Valley Entrance","Museum","Mystic Floodplains",
    "Overgrown Grotto","Rotwood Swamp","Rubble Creek","Snowy Shores",
    "Sunscorched Desert","Sunset Beach","The Magma Furnace",
    "Timelocked Sanctuary","Volcanic Sands"
}
-- Source: toolkit src/data/locs.js; keep the independent drop-location identifiers.
local ZONE_NAMES={
    "Rubble Creek Sands","Rubble Creek Deposits","Fortune River",
    "Fortune River Delta","Sunset Beach","Crystal Cavern River","Azuralite Oasis",
    "Volcanic Sands","Volcanic Springs","Windswept Beach","Magma Furnace",
    "Infernal Heart","Frostbite River","Frostbite Waterfall","Frozen Peak",
    "Overgrown Grotto","Deeproot Spring","Enchanted Ruins","Abyssal Depth",
    "Rotwood Swamp","Fungal Marsh","Timelocked Sanctuary","Meteor Falls",
    "Starfall River","Astral Caverns","Sandstone Stream","Mystic Floodplains",
    "Lifespring Oasis","Tomb Vein I","Tomb Vein II","Tomb Vein III",
    "The Void","Haunted Creek","North Pole","Seashell Beach"
}
local PRESET_FILE="GalaxisHub_ZonePresets.json" -- v2: separate zone -> waypoint map
local OLD_PRESET_FILE="GalaxisHub_FarmPresets.json" -- v1: waypoint presets, read-only
local waypointIndex,zoneIndex={},{}
for i,name in ipairs(WAYPOINT_NAMES) do waypointIndex[name]=i end
for i,name in ipairs(ZONE_NAMES) do zoneIndex[name]=i end
S.presets={}
S.legacyWaypoints={}
S.selectedWaypoint=waypointIndex["Fortune River"]
S.selectedZone=zoneIndex["Fortune River"]
S.activeZone=nil

local function packCF(cf)
    if typeof(cf)~="CFrame" then return nil end
    return {cf:GetComponents()}
end
local function unpackCF(t)
    if type(t)~="table" or #t~=12 then return nil end
    for i=1,12 do
        if type(t[i])~="number" or t[i]~=t[i] or math.abs(t[i])>1e12 then return nil end
    end
    local ok,cf=pcall(function() return CFrame.new(table.unpack(t)) end)
    return ok and cf or nil
end
local function decodePresetFile(name)
    if type(readfile)~="function" then return nil end
    if type(isfile)=="function" then
        local ok,exists=pcall(isfile,name)
        if ok and not exists then return nil end
    end
    local ok,raw=pcall(readfile,name)
    if not ok then return nil end
    local decoded,data=pcall(function() return HttpService:JSONDecode(raw) end)
    return decoded and type(data)=="table" and data or nil
end
local function savePresets()
    if type(writefile)~="function" then return false,"writefile unavailable" end
    local ok,json=pcall(function()
        return HttpService:JSONEncode({
            version=2,
            selectedZone=ZONE_NAMES[S.selectedZone],
            selectedWaypoint=WAYPOINT_NAMES[S.selectedWaypoint],
            zones=S.presets
        })
    end)
    if not ok then return false,tostring(json) end
    local written,err=pcall(writefile,PRESET_FILE,json)
    return written,written and nil or tostring(err)
end
local function validPreset(p)
    if type(p)~="table" then return nil end
    local dig,water=unpackCF(p.dig),unpackCF(p.water)
    local waypoint=type(p.waypoint)=="string" and waypointIndex[p.waypoint] and p.waypoint or nil
    if dig or water or waypoint then
        return {dig=packCF(dig),water=packCF(water),waypoint=waypoint}
    end
    return nil
end
local function loadPresets()
    local legacy=decodePresetFile(OLD_PRESET_FILE)
    if legacy and type(legacy.points)=="table" then
        for _,wp in ipairs(WAYPOINT_NAMES) do
            local old=validPreset(legacy.points[wp])
            if old then
                S.legacyWaypoints[wp]=old
                -- The only safe automatic migration: exact identical zone and waypoint names.
                if zoneIndex[wp] then
                    S.presets[wp]={dig=old.dig,water=old.water,waypoint=wp}
                end
            end
        end
    end
    local saved=decodePresetFile(PRESET_FILE)
    if saved and saved.version==2 and type(saved.zones)=="table" then
        for _,name in ipairs(ZONE_NAMES) do
            local parsed=validPreset(saved.zones[name])
            if parsed then S.presets[name]=parsed end
        end
        if zoneIndex[saved.selectedZone] then S.selectedZone=zoneIndex[saved.selectedZone] end
        if waypointIndex[saved.selectedWaypoint] then S.selectedWaypoint=waypointIndex[saved.selectedWaypoint] end
    end
    -- For a new zone, exact names may use their matching waypoint.
    for _,name in ipairs(ZONE_NAMES) do
        if waypointIndex[name] and not S.presets[name] then
            S.presets[name]={waypoint=name}
        end
    end
end
loadPresets()
local function waypointFolder()
    local map=workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Waypoints")
end
local function getWaypointCF(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then
        obj=obj:FindFirstChildWhichIsA("BasePart",true)
    end
    if not obj then return nil end
    local ok,cf=pcall(function() return obj:GetPivot() end)
    return ok and cf or nil
end
local function closestWaypoint(folder,pos)
    local best,dist=nil,math.huge
    for _,node in ipairs(folder:GetChildren()) do
        local cf=getWaypointCF(node)
        if cf then
            local d=(cf.Position-pos).Magnitude
            if d<dist then best=node;dist=d end
        end
    end
    return best
end

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
        warn("[GALAXIS HUB LOGGER] Write failure:",err)
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
G.Name="GalaxisHubBeta";G.ResetOnSpawn=false;G.DisplayOrder=9999
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
    Size=UDim2.fromOffset(340,562),
    Position=UDim2.new(.5,-170,.5,-281),
    BackgroundColor3=BG,BorderSizePixel=0,Active=true
},G))
make("UIStroke",{Color=Color3.fromRGB(69,71,79),Thickness=1},W)
local H=make("Frame",{Size=UDim2.new(1,0,0,43),BackgroundTransparency=1,Active=true},W)
make("TextLabel",{
    Position=UDim2.fromOffset(14,0),Size=UDim2.fromOffset(245,43),
    BackgroundTransparency=1,Text="GALAXIS HUB  /  BETA",
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
local status=label("Idle",14,7,312,24,12,MUTED)
local digB=button("SET DIG",14,38,149,36,Body)
local waterB=button("SET WATER",177,38,149,36,Body)
local digXYZ=label("Not saved",14,78,149,22,10,MUTED)
local waterXYZ=label("Not saved",177,78,149,22,10,MUTED)
digXYZ.TextXAlignment=Enum.TextXAlignment.Center
waterXYZ.TextXAlignment=Enum.TextXAlignment.Center
local sellB=button("AUTO SELL: OFF",14,110,312,36,Body)
local farmB=button("AUTO FARM: OFF",14,157,312,40,Body)
-- Compact footer: the only stats shown are current pan, total minerals, and average time.
local statsFooter=label("Pan: 0 | Minerals: 0 | Avg: --",14,213,312,27,12,FG)
statsFooter.Font=Enum.Font.GothamBold

-- Zone and waypoint selectors are separate: one warp may serve multiple deposits.
local zoneTitle=label("MINING ZONE",14,247,312,18,10,MUTED)
local prevZone=button("<",14,271,36,32,Body)
local zoneName=label("",56,271,228,32,12,FG)
zoneName.TextXAlignment=Enum.TextXAlignment.Center
zoneName.Font=Enum.Font.GothamMedium
local nextZone=button(">",290,271,36,32,Body)

local warpTitle=label("FAST TRAVEL WAYPOINT",14,312,312,18,10,MUTED)
local prevWaypoint=button("<",14,335,36,32,Body)
local waypointName=label("",56,335,228,32,12,FG)
waypointName.TextXAlignment=Enum.TextXAlignment.Center
waypointName.Font=Enum.Font.GothamMedium
local nextWaypoint=button(">",290,335,36,32,Body)
local loadZone=button("LOAD ZONE",14,380,149,36,Body)
local mapWaypoint=button("MAP TO WAYPOINT",177,380,149,36,Body)
local travelWaypoint=button("FAST TRAVEL",14,423,149,36,Body)
local importLegacy=button("IMPORT OLD WP",177,423,149,36,Body)
local presetStatus=label("",14,466,312,21,11,MUTED)
label("SET DIG / WATER saves to MINING ZONE",14,491,312,19,10,MUTED)
local function selectedZone() return ZONE_NAMES[S.selectedZone] end
local function selectedWaypoint() return WAYPOINT_NAMES[S.selectedWaypoint] end
local function refreshPreset()
    local name=selectedZone()
    local p=S.presets[name]
    zoneName.Text=name
    waypointName.Text=selectedWaypoint()
    local mapping=p and p.waypoint or nil
    presetStatus.Text=((p and unpackCF(p.dig)) and "Dig saved" or "Dig missing")..
        " | "..((p and unpackCF(p.water)) and "Water saved" or "Water missing")..
        (mapping and (" | WP: "..mapping) or " | WP: NOT MAPPED")
    -- Only explicit MAP TO WAYPOINT commits the selector to this zone.
end
refreshPreset()
local function show(t) if S.alive then status.Text=t end end
local function xyz(cf)
    local p=cf.Position
    return string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
end
task.spawn(function()
    while S.alive do
        local currentPan=S.cycles+(S.running and 1 or 0)
        local collected=L.minerals+#L.pending
        local avg=S.cycles>0 and string.format("%.2fs",S.totalCycleTime/S.cycles) or "--"
        statsFooter.Text=string.format("Pan: %d  |  Minerals: %d  |  Avg: %s",currentPan,collected,avg)
        task.wait(.25)
    end
end)

local function stop()
    if not S.alive then return end
    -- This invalidates all current farm cycles and pending recovery retries.
    S.running=false;S.token+=1;S.waiting=false
    S.sellQueue={}
    if S.completion then S.completion:Disconnect();S.completion=nil end
    farmB.Text="AUTO FARM: OFF"
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
        -- Refresh capacity each cycle, including equipment/buff changes.
        local newCapacity=capacity()
        if newCapacity and newCapacity>0 then target=newCapacity end
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
            -- InvokeServer already waits for a server reply. On acknowledged
            -- Fill progress, go straight to the next Collect with no extra sleep.
            -- Only back off when replication/progress has not caught up.
            local after=fill(r)
            if after and after>before+.001 then
                lastProgress=os.clock()
            elseif not pause(timing("dig"),id) then
                return
            end
            if os.clock()-lastProgress>CFG.digStall then return "Digging stalled" end
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
        S.totalCycleTime+=total
        local recent=S.recentTimes
        recent[#recent+1]=total
        if #recent>10 then table.remove(recent,1) end
        local sum=0
        for _,v in ipairs(recent) do sum+=v end
        local ppm=sum>0 and (60*#recent/sum) or 0
        -- Footer refreshes independently every 0.25s.
        autoSell(id,S.cycles)
    end
end
local function applyZone()
    local name=selectedZone()
    local p=S.presets[name]
    S.dig=p and unpackCF(p.dig) or nil
    S.water=p and unpackCF(p.water) or nil
    S.activeZone=name
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    refreshPreset()
end
local function capture(key)
    if S.running then show("Turn AUTO FARM OFF before editing");return end
    local r=root()
    if not r then show("Character root unavailable");return end
    if S.activeZone~=selectedZone() then applyZone() end
    local name=selectedZone()
    S.presets[name]=S.presets[name] or {}
    S.presets[name][key]=packCF(r.CFrame)
    if key=="dig" then S.dig=r.CFrame else S.water=r.CFrame end
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    refreshPreset()
    local ok,err=savePresets()
    show(ok and (name.." "..key.." saved") or ("Session only: "..tostring(err)))
end
bind(digB.MouseButton1Click,function() capture("dig") end)
bind(waterB.MouseButton1Click,function() capture("water") end)
local function selectZone(i)
    S.selectedZone=(i-1)%#ZONE_NAMES+1
    local p=S.presets[selectedZone()]
    if p and p.waypoint and waypointIndex[p.waypoint] then
        S.selectedWaypoint=waypointIndex[p.waypoint]
    end
    refreshPreset()
    savePresets()
end
bind(prevZone.MouseButton1Click,function() selectZone(S.selectedZone-1) end)
bind(nextZone.MouseButton1Click,function() selectZone(S.selectedZone+1) end)
bind(prevWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=(S.selectedWaypoint-2)%#WAYPOINT_NAMES+1
    refreshPreset()
    savePresets()
end)
bind(nextWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=S.selectedWaypoint%#WAYPOINT_NAMES+1
    refreshPreset()
    savePresets()
end)
bind(mapWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before editing mappings");return end
    local name,wp=selectedZone(),selectedWaypoint()
    S.presets[name]=S.presets[name] or {}
    S.presets[name].waypoint=wp
    local ok,err=savePresets()
    refreshPreset()
    show(ok and (name.." -> "..wp) or ("Mapping session only: "..tostring(err)))
end)
bind(loadZone.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before loading");return end
    local name=selectedZone()
    local p=S.presets[name]
    if not p or not unpackCF(p.dig) or not unpackCF(p.water) then
        show("Save both positions for "..name)
        return
    end
    applyZone()
    show("Loaded "..name.." zone")
end)
bind(importLegacy.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before importing");return end
    local name,wp=selectedZone(),selectedWaypoint()
    local old=S.legacyWaypoints[wp]
    if not old or not (old.dig or old.water) then
        show("No legacy positions for "..wp);return
    end
    local existing=S.presets[name]
    if existing and (unpackCF(existing.dig) or unpackCF(existing.water)) then
        show("Zone already has positions; won't overwrite");return
    end
    S.presets[name]={dig=old.dig,water=old.water,waypoint=wp}
    local ok,err=savePresets()
    refreshPreset()
    show(ok and ("Imported old "..wp.." to "..name) or ("Imported in session: "..tostring(err)))
end)
bind(travelWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before traveling");return end
    local folder=waypointFolder()
    local r=root()
    if not folder or not r then show("Waypoints or character unavailable");return end
    local to=folder:FindFirstChild(selectedWaypoint())
    if not to then show("Selected waypoint not found");return end
    local from=closestWaypoint(folder,r.Position)
    if not from then show("Current waypoint could not be resolved");return end
    if from==to then show("Already nearest to "..to.Name);return end
    local remotes=RS:FindFirstChild("Remotes")
    local misc=remotes and remotes:FindFirstChild("Misc")
    local remote=misc and misc:FindFirstChild("FastTravel")
    if not remote or not remote:IsA("RemoteEvent") then
        show("FastTravel remote unavailable");return
    end
    local ok,err=pcall(function() remote:FireServer(from,to) end)
    -- FireServer is one-way; this only confirms that the request was sent.
    show(ok and ("Travel requested: "..from.Name.." -> "..to.Name)
        or ("FastTravel failed: "..tostring(err):sub(1,65)))
end)

bind(sellB.MouseButton1Click,function()
    if not S.sell and not getSell() then show("SellAll unavailable");return end
    S.sell=not S.sell
    sellB.Text="AUTO SELL: "..(S.sell and "ON" or "OFF")
end)
-- ON is a persistent user request. A transient farm failure does not turn
-- the toggle off: we re-resolve the equipped pan and retry quickly.
bind(farmB.MouseButton1Click,function()
    if S.running then
        stop()
        return
    end
    if not S.dig or not S.water then show("Save both positions");return end
    S.running=true
    S.token+=1
    local id=S.token
    farmB.Text="AUTO FARM: ON"
    S.waiting=false
    show("Starting")

    task.spawn(function()
        while valid(id) do
            local r=panTool()
            local target=capacity()
            local reason
            if not r then
                reason="Pan not equipped"
            elseif not target or target<=0 then
                reason="Capacity unavailable"
            elseif fill(r)==nil then
                reason="Fill unavailable"
            else
                if S.completion then
                    S.completion:Disconnect()
                    S.completion=nil
                end
                if r.done and r.done:IsA("RemoteEvent") then
                    S.completion=r.done.OnClientEvent:Connect(function()
                        if valid(id) and S.waiting then S.completed=true end
                    end)
                end
                local ok,result=pcall(farming,id,r,target)
                reason=ok and (result or "Cycle ended unexpectedly")
                    or ("Runtime error: "..tostring(result))
            end

            if S.completion then
                S.completion:Disconnect()
                S.completion=nil
            end
            S.waiting=false

            if valid(id) then
                show("Recovering in 0.25s: "..tostring(reason):sub(1,58))
                warn("[GALAXIS HUB] Auto recovery:",reason)
                if not pause(CFG.recoveryDelay,id) then break end
            end
        end
    end)
end)
bind(X.MouseButton1Click,close)
local minimized=false
bind(Min.MouseButton1Click,function()
    minimized=not minimized
    Body.Visible=not minimized
    W.Size=minimized and UDim2.fromOffset(340,43) or UDim2.fromOffset(340,562)
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
bind(P.CharacterRemoving,function()
    -- Do not turn the toggle OFF on respawn; the worker will retry when
    -- an equipped pan and character are available again.
    if S.running then
        S.waiting=false
        show("Character changed - recovering")
    end
end)
print("[GALAXIS HUB BETA] Loaded. TSV:",FILE)
if L.error then warn("[GALAXIS HUB BETA] Logger:",L.error) end
