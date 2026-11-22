-- Galaxis module: 12_treasure.luau
-- Treasure automation. Runs only after a completed pan cycle.
for _,k in ipairs({"treasureTitle","treasureStatus","treasureToggle","treasureScanButton","treasureOutput"}) do
    if S[k] then pcall(function() S[k]:Destroy() end) end
end
S.treasureEnabled=S.treasureEnabled==true
S.treasureBusy=false
S.treasureRequested=false
S.treasureStandalone=false
S.treasureMinMaps=1
S.treasureNextTryAt=0
S.treasureCompleted=S.treasureCompleted or {}
S.treasureAttempted=S.treasureAttempted or {}
S.treasureLastError=nil

S.treasureTitle=label("AUTO TREASURE ROUTE",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("OFF | Auto-digs every map; fast travel when it saves distance.",14,39,312,38,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureToggle=button("AUTO DIG MAPS: OFF",14,82,312,36,treasurePage)
S.treasureScanButton=button("SCAN TREASURE MAPS",14,126,312,32,treasurePage)
S.treasureScanButton.BackgroundColor3=PANEL
S.treasureOutput=make("TextBox",{Position=UDim2.fromOffset(14,166),
    Size=UDim2.new(1,-28,1,-180),BackgroundColor3=PANEL,BorderSizePixel=0,
    TextColor3=FG,PlaceholderColor3=MUTED,PlaceholderText="Map inventory and route status.",
    Text="",ClearTextOnFocus=false,MultiLine=true,TextWrapped=false,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    Font=Enum.Font.Code,TextSize=9},treasurePage)

local function tContainers()
    local out={}
    local bag=P:FindFirstChild("BackpackTwo") or P:FindFirstChildOfClass("Backpack")
    if bag then out[#out+1]=bag end
    if P.Character then out[#out+1]=P.Character end
    return out
end
local function tMaps()
    local out={}
    for _,bag in ipairs(tContainers()) do
        for _,tool in ipairs(bag:GetChildren()) do
            if tool:IsA("Tool") and tool.Name=="Treasure Map" then
                local pos,region=tool:GetAttribute("Location"),tool:GetAttribute("Region")
                local guid=tool:GetAttribute("GUID")
                if typeof(pos)=="Vector3" and type(region)=="string" and region~="" then
                    out[#out+1]={tool=tool,pos=pos,region=region,guid=tostring(guid or tool)}
                end
            end
        end
    end
    return out
end
local function tEligibleMaps()
    local list={}
    for _,m in ipairs(tMaps()) do
        if not S.treasureCompleted[m.guid] and not S.treasureAttempted[m.guid] then
            list[#list+1]=m
        end
    end
    return list
end
local function tEquippedPan(id)
    local held=panTool()
    if held then return held end
    local candidate=S.panInBackpack()
    if not candidate then return nil,"No pan found in inventory" end
    if requirePanEquipped(candidate,id) then
        return panTool() or candidate
    end
    -- The game also stores pans in BackpackTwo. The normal Humanoid equip
    -- path cannot equip directly from that container.
    local remotes=RS:FindFirstChild("Remotes")
    local custom=remotes and remotes:FindFirstChild("CustomBackpack")
    local equipRemote=custom and custom:FindFirstChild("EquipRemote")
    if not equipRemote or not equipRemote:IsA("RemoteEvent") then
        return nil,"No compatible custom backpack equip remote"
    end
    local sent=pcall(function() equipRemote:FireServer(candidate.tool) end)
    if not sent then return nil,"Custom backpack equip request failed" end
    local deadline=os.clock()+3
    while valid(id) and os.clock()<deadline do
        held=panTool()
        if held then return held end
        task.wait(.1)
    end
    return nil,"Pan equip did not replicate within 3 seconds"
end

local function tChestCount()
    local n=0
    for _,bag in ipairs(tContainers()) do
        for _,obj in ipairs(bag:GetChildren()) do
            if obj:IsA("Tool") then
                local name=string.lower(obj.Name)
                if name:find("chest",1,true) and not name:find("map",1,true) then n+=1 end
            end
        end
    end
    return n
end
local function tStatus(s)
    if S.treasureStatus then S.treasureStatus.Text=s end
    if S.treasureOutput then S.treasureOutput.Text=s end
end
-- Warp decisions use actual waypoint world positions, never a guessed
-- map-region-to-warp mapping. Do not use Dredge's zone-route planner here.
local WARP_MIN_SAVING=120

local function tWaypointPairs()
    local out={}
    local folder=S.waypointFolder()
    if not folder then return out end
    for _,name in ipairs(WAYPOINT_NAMES) do
        local obj=folder:FindFirstChild(name)
        local cf=obj and S.getWaypointCF(obj)
        if obj and cf then
            out[#out+1]={name=name,obj=obj,cf=cf}
        end
    end
    return out
end

-- Estimated WALKING distance of direct travel versus walking to a real
-- stone, warping, and walking from a destination stone to the actual map.
-- Require a meaningful distance saving to avoid needless warp spam.
local function tWarpChoice(origin,destination)
    local direct=(destination-origin).Magnitude
    local stones=tWaypointPairs()
    local best=nil
    local bestDistance=direct
    for _,from in ipairs(stones) do
        local approach=(from.cf.Position-origin).Magnitude
        for _,to in ipairs(stones) do
            if from.obj~=to.obj then
                local lastLeg=(destination-to.cf.Position).Magnitude
                local combined=approach+lastLeg
                if direct-combined>=WARP_MIN_SAVING and combined<bestDistance then
                    bestDistance=combined
                    best={from=from,to=to,saved=direct-combined}
                end
            end
        end
    end
    return best,bestDistance
end

local function tEstimatedTravel(a,b)
    local _,distance=tWarpChoice(a,b)
    return distance
end

local function tPickNext(list,origin)
    local bestIndex,bestCost=nil,math.huge
    for i,m in ipairs(list) do
        local cost=tEstimatedTravel(origin,m.pos)
        if cost<bestCost then
            bestIndex,bestCost=i,cost
        end
    end
    return bestIndex
end

-- Treasure-only movement fallback. Normal Dredge and Farm paths are unchanged.
-- Use slow, per-frame, ghost-collision movement for steep terrain and
-- inaccessible walking routes. Always restore collisions on exit.
local HEIGHT_THRESHOLD=36
local FLY_SPEED=42
local FLY_CEILING_SECONDS=180

local function tFlight(target,id,description)
    local character=P.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local startRoot=root()
    if not character or not startRoot or not humanoid or humanoid.Health<=0 then
        return false,"Character unavailable for flight"
    end
    local collisions={}
    local function ghost(part)
        if part:IsA("BasePart") and collisions[part]==nil then
            collisions[part]=part.CanCollide
        end
        if part:IsA("BasePart") then part.CanCollide=false end
    end
    for _,part in ipairs(character:GetDescendants()) do ghost(part) end
    local added=character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then ghost(part) end
    end)
    local originalAutoRotate=humanoid.AutoRotate
    local originalPlatformStand=humanoid.PlatformStand
    humanoid.AutoRotate=false
    humanoid.PlatformStand=true
    local flightError=nil
    local reached=false
    local began=os.clock()
    tStatus("Slow noclip flight to "..description)
    local ok,exception=pcall(function()
        local last=os.clock()
        while valid(id) and S.treasureEnabled
            and os.clock()-began<FLY_CEILING_SECONDS do
            local r=root()
            if not r or humanoid.Health<=0 then
                flightError="Character lost during flight"
                break
            end
            local difference=target.Position-r.Position
            if difference.Magnitude<=4.5 then
                reached=true
                break
            end
            local now=os.clock()
            local dt=math.clamp(now-last,1/120,.11)
            last=now
            local step=math.min(difference.Magnitude,FLY_SPEED*dt)
            local nextPos=r.Position+difference.Unit*step
            r.AssemblyLinearVelocity=Vector3.zero
            r.AssemblyAngularVelocity=Vector3.zero
            r.CFrame=CFrame.new(nextPos)*target.Rotation
            task.wait()
        end
    end)
    added:Disconnect()
    for part,canCollide in pairs(collisions) do
        if part.Parent then pcall(function() part.CanCollide=canCollide end) end
    end
    if humanoid.Parent then
        humanoid.AutoRotate=originalAutoRotate
        humanoid.PlatformStand=originalPlatformStand
    end
    local finalRoot=root()
    if finalRoot then
        finalRoot.AssemblyLinearVelocity=Vector3.zero
        finalRoot.AssemblyAngularVelocity=Vector3.zero
    end
    if not ok then return false,"Flight runtime error: "..tostring(exception) end
    if not valid(id) or not S.treasureEnabled then return false,"Flight cancelled" end
    if not reached then return false,flightError or "Flight timed out / movement corrected" end
    -- Ensure the server did not rubber-band the avatar before we dig.
    if not stableAt(target,id,9,.35,2.5) then
        return false,"Flight destination was not stable"
    end
    return true
end

local function tMove(target,id,description,checkpoint)
    local r=root()
    if not r then return false,"Character missing before travel" end
    local rise=math.abs(r.Position.Y-target.Position.Y)
    if rise>=HEIGHT_THRESHOLD then
        return tFlight(target,id,description)
    end
    local walked,why=walkRoute(target,id,10000,checkpoint)
    if walked then return true end
    if not valid(id) or not S.treasureEnabled then
        return false,tostring(why)
    end
    tStatus("Pathfinding failed ("..tostring(why).."); switching to slow flight")
    return tFlight(target,id,description)
end

local function tTravel(target,id,description)
    local r=root()
    if not r then return false,"Character is missing" end
    local choice=tWarpChoice(r.Position,target.Position)
    if choice then
        local from,to=choice.from,choice.to
        tStatus(string.format("%s | Running to %s stone (warp saves ~%.0f studs)",
            description,from.name,choice.saved))
        local ok,why=tMove(from.cf,id,"departure stone "..from.name,true)
        if not ok then
            -- If the departure stone cannot be reached, do not jump to a
            -- different zone; try direct walking to the map instead.
            tStatus("Stone approach failed; walking directly to "..description)
        else
            r=root()
            if not r then return false,"Character lost after approaching warp" end
            if (r.Position-from.cf.Position).Magnitude<=55 then
                local rem=RS:FindFirstChild("Remotes")
                local misc=rem and rem:FindFirstChild("Misc")
                local travel=misc and misc:FindFirstChild("FastTravel")
                if travel and travel:IsA("RemoteEvent") then
                    tStatus("Fast Travel: "..from.name.." -> "..to.name)
                    local sent=pcall(function() travel:FireServer(from.obj,to.obj) end)
                    if sent then
                        -- Server must confirm the actual destination. Never
                        -- assume the fast-travel remote succeeded.
                        local arrived=stableAt(to.cf,id,85,1.1,8)
                        if not arrived and not valid(id) then
                            return false,"Treasure run interrupted after warp"
                        end
                    end
                end
            end
        end
    end

    tStatus("Running to "..description)
    local walked,why=tMove(target,id,description,false)
    if not walked then return false,"Movement failed: "..tostring(why) end
    if not stableAt(target,id,12,.45,3) then
        return false,"Destination did not settle"
    end
    return true
end

local function tRestore(cp,id)
    local home=cp.returnCF
    if not home then return false,"Original return position was not saved" end
    local ok,why=tTravel(home,id,"original dig/start position")
    if not ok then return false,"Could not return: "..tostring(why) end
    S.dig,S.water=cp.dig,cp.water
    S.activeZone,S.dredgeAt=cp.zone,cp.dredgeAt
    return true
end

local function tRun(id)
    if S.treasureBusy or not S.treasureEnabled or not valid(id) then return end
    local list=tEligibleMaps()
    if #list<S.treasureMinMaps then return end
    S.treasureBusy=true
    local rr=root()
    local cp={
        dig=S.dig,returnCF=S.dig or (rr and rr.CFrame),
        water=S.water,
        zone=S.dredge and S.dredgeAt or S.activeZone,
        dredgeAt=S.dredgeAt
    }
    local oldDredge=S.dredge==true
    S.treasureWasDredge=oldDredge
    local oldSell=S.sell
    -- Suspend the Dredge planner while the treasure route owns movement.
    -- Resume it only after one complete farm cycle at the restored checkpoint.
    S.dredge=false
    local ok,err=true,nil
    local completedThisRun,failedThisRun=0,0
    local firstFailure=nil
    S.sell=false
    local initialCount=#list
    local steps=0
    -- Re-scan after each dig: includes every new map obtained during this
    -- trip, without needing to toggle Auto Dig or start another farm cycle.
    while valid(id) and S.treasureEnabled do
        local remaining=tEligibleMaps()
        if #remaining==0 then break end
        steps+=1
        if steps>250 then
            ok,err=false,"Safety stop: 250 map destinations in a single trip"
            break
        end

        local r=root()
        if not r then ok,err=false,"Character missing during treasure route";break end
        local nextIndex=tPickNext(remaining,r.Position)
        if not nextIndex then break end
        local m=remaining[nextIndex]
        if not m.tool or not m.tool.Parent then
            -- Map was removed by the game; rescan instead of failing.
            task.wait(.1)
            continue
        end
        tStatus(string.format("Map %d | %s | target %.1f, %.1f, %.1f",
            steps,m.region,m.pos.X,m.pos.Y,m.pos.Z))
        local reached,travelWhy=tTravel(CFrame.new(m.pos),id,"map in "..m.region)
        if not reached then
            -- Skip a blocked map and continue collecting other maps.
            S.treasureAttempted[m.guid]=true
            failedThisRun+=1
            firstFailure=firstFailure or ("Unable to reach "..m.region..": "..tostring(travelWhy))
            continue
        end

        local pan,equipWhy=tEquippedPan(id)
        if not pan then
            ok,err=false,"Could not equip pan: "..tostring(equipWhy)
            break
        end
        -- Use the map itself as a second success signal. The game can
        -- consume the map before the chest tool finishes replicating.
        local before=tChestCount()
        local beforeMap=m.tool.Parent~=nil
        local sent,response,why=false,nil,nil
        local wasAccepted=false
        for attempt=1,3 do
            if not valid(id) or not S.treasureEnabled then break end
            local avatar=root()
            if not avatar or (avatar.Position-m.pos).Magnitude>10 then
                local settled,settleWhy=tMove(CFrame.new(m.pos),id,"treasure dig location",false)
                if not settled then
                    why="Cannot stay at dig location: "..tostring(settleWhy)
                    break
                end
            end
            local held,equipWhy=tEquippedPan(id)
            if not held then
                why="Pan was not equipped: "..tostring(equipWhy)
                break
            end
            tStatus(string.format("Digging %s | request %d/3",m.region,attempt))
            sent,response,why=invoke(held.dig,id,1)
            if sent and response~=false then
                wasAccepted=true
                break
            end
            -- A successful RPC with an explicit 'false' result is safe to
            -- retry after settling. An uncertain/failed RPC is NOT safe:
            -- it may have executed server-side and should not be doubled.
            if not sent then break end
            if attempt<3 then task.wait(.35) end
        end
        if not wasAccepted then
            S.treasureAttempted[m.guid]=true
            failedThisRun+=1
            firstFailure=firstFailure or
                ("Treasure dig not accepted: "..tostring(why or response))
            continue
        end
        -- Do not send another dig for an accepted or uncertain request.
        S.treasureAttempted[m.guid]=true
        local found=false
        local consumed=false
        local deadline=os.clock()+18
        while valid(id) and os.clock()<deadline do
            if tChestCount()>before then found=true;break end
            if beforeMap and m.tool.Parent==nil then consumed=true end
            task.wait(.15)
        end
        if found then
            S.treasureCompleted[m.guid]=true
            completedThisRun+=1
            tStatus(string.format("Collected %d chest(s) | %d map(s) left",
                completedThisRun,#tEligibleMaps()))
        else
            failedThisRun+=1
            firstFailure=firstFailure or
                (consumed and "Map consumed but treasure chest not confirmed"
                    or "Dig accepted, but no treasure chest detected in 18 seconds")
        end
    end

    if not valid(id) or not S.treasureEnabled then
        ok,err=false,"Stopped by user"
    end
    if failedThisRun>0 then
        ok=false
        err=string.format("%d map(s) not verified: %s",
            failedThisRun,tostring(firstFailure))
    end

    local returned,why=tRestore(cp,id)
    if not returned then ok,err=false,(err and err.."; " or "").."RETURN FAILED: "..tostring(why) end
    S.sell=oldSell
    -- Restore the controller exactly as it was before the route.
    -- Never turn Auto Farm or Auto Dredge on if they were originally off.
    S.dredge=oldDredge and S.running and returned and true or false
    if not ok then
        S.treasureNextTryAt=os.clock()+20
    else
        S.treasureNextTryAt=os.clock()+2
    end
    S.treasureBusy=false
    S.treasureWasDredge=nil
    if ok then
        S.diagEvent("TREASURE_ROUTE_COMPLETE","collected="..completedThisRun)
        tStatus("Treasure done: "..completedThisRun.." chest(s). Returned to farming location.")
    else
        S.treasureLastError=tostring(err)
        S.diagEvent("TREASURE_ROUTE_FAILED",S.treasureLastError)
        tStatus("Treasure: "..completedThisRun.." collected; "..S.treasureLastError)
    end
end

-- One entry point works for the active farm worker and independent travel.
S.treasureCycle=function(id,r)
    if not S.treasureEnabled or S.treasureBusy or not valid(id) then return end
    local n=#tEligibleMaps()
    if n<S.treasureMinMaps then
        S.treasureRequested=false
        tStatus(string.format("AUTO DIG ON | Waiting for maps (%d/%d)",n,S.treasureMinMaps))
        return
    end
    if os.clock()<(S.treasureNextTryAt or 0) then
        S.treasureRequested=false
        return
    end
    S.treasureRequested=false
    local ok,err=pcall(tRun,id)
    if not ok then
        S.treasureBusy=false
        S.treasureLastError=tostring(err)
        S.treasureNextTryAt=os.clock()+20
        S.dredge=S.treasureWasDredge and S.running or false
        S.treasureWasDredge=nil
        tStatus("Treasure error: "..S.treasureLastError)
    end
end

-- Standalone treasure runner. Auto Farm and Dredge do NOT need to be on.
-- If a farm worker is active, it owns the cycle and calls S.treasureCycle
-- between complete pan cycles. Do not move concurrently with it.
task.spawn(function()
    while S.alive do
        task.wait(1.0)
        if S.treasureEnabled and not S.treasureBusy
            and os.clock()>=(S.treasureNextTryAt or 0) then
            local count=#tEligibleMaps()
            if count>=S.treasureMinMaps then
                if S.running then
                    S.treasureRequested=true
                    -- An active farming worker will yield at a safe boundary.
                elseif not S.treasureStandalone then
                    S.treasureStandalone=true
                    S.token+=1
                    local id=S.token
                    local ok,err=pcall(S.treasureCycle,id,nil)
                    if not ok then
                        S.treasureLastError=tostring(err)
                        S.treasureNextTryAt=os.clock()+20
                        tStatus("Standalone treasure error: "..S.treasureLastError)
                    end
                    S.treasureStandalone=false
                end
            end
        end
    end
end)

local function tScan()
    local list=tMaps()
    local available=tEligibleMaps()
    local lines={"GALAXIS TREASURE MAPS","Maps: "..#list.." | eligible: "..#available,""}
    for i,m in ipairs(list) do
        lines[#lines+1]=string.format("%d. %s | %.1f, %.1f, %.1f | %s",
            i,m.region,m.pos.X,m.pos.Y,m.pos.Z,m.guid)
    end
    lines[#lines+1]=""
    lines[#lines+1]="Auto Dig: "..tostring(S.treasureEnabled)
    lines[#lines+1]="Last error: "..tostring(S.treasureLastError or "None")
    tStatus(table.concat(lines,"\n"))
end
local function tRefresh()
    S.treasureToggle.Text=S.treasureEnabled and "AUTO DIG MAPS: ON" or "AUTO DIG MAPS: OFF"
    S.treasureToggle.BackgroundColor3=S.treasureEnabled and Color3.fromRGB(49,83,62) or PANEL
end
bind(S.treasureToggle.MouseButton1Click,function()
    S.treasureEnabled=not S.treasureEnabled
    if S.treasureEnabled then
        local n=#tEligibleMaps()
        S.treasureRequested=S.running and n>=S.treasureMinMaps
        tStatus(n>=S.treasureMinMaps
            and (S.running and "AUTO DIG ON | Waiting for safe pan-cycle boundary."
                or "AUTO DIG ON | Starting treasure route independently.")
            or string.format("AUTO DIG ON | Waiting for maps (%d/%d)",n,S.treasureMinMaps))
    else
        S.treasureRequested=false
        tStatus(S.treasureBusy and "OFF | Stopping at next safe movement check." or "OFF")
    end
    tRefresh()
end)
bind(S.treasureScanButton.MouseButton1Click,tScan)
tRefresh()
tScan()
