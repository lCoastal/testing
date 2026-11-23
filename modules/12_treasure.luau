-- Galaxis module: 12_treasure.luau
-- Treasure automation. Runs only after a completed pan cycle.
for _,k in ipairs({"treasureTitle","treasureStatus","treasureToggle","treasureMinLabel","treasureMinInput","treasureScanButton","treasureOutput"}) do
    if S[k] then pcall(function() S[k]:Destroy() end) end
end
S.treasureEnabled=S.treasureEnabled==true
S.treasureBusy=false
S.treasureRequested=false
S.treasureStandalone=false
S.treasureMinMaps=math.clamp(math.floor(tonumber(E.GalaxisTreasureMinMaps) or 3),1,100)
S.treasureNextTryAt=0
-- Clear the old permanent attempt blacklist: it caused '6 maps, 0 eligible'
-- after a failed run. Only the actual inventory determines map eligibility.
S.treasureCompleted={}
S.treasureAttempted={}
S.treasureRetryAfter={}
S.treasureTripSkipped={}
S.treasureLastError=nil

S.treasureTitle=label("AUTO TREASURE ROUTE",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("OFF | Farms until your map threshold, then collects all maps.",14,39,312,38,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureToggle=button("AUTO DIG MAPS: OFF",14,82,312,36,treasurePage)
S.treasureMinLabel=label("MAPS BEFORE TREASURE RUN",14,130,228,31,10,MUTED)
S.treasureMinInput=make("TextBox",{
    Position=UDim2.fromOffset(247,128),Size=UDim2.fromOffset(79,33),
    BackgroundColor3=PANEL,BorderSizePixel=0,TextColor3=FG,
    Font=Enum.Font.GothamBold,TextSize=13,
    Text=tostring(S.treasureMinMaps),ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Center
},treasurePage)
S.treasureScanButton=button("SCAN TREASURE MAPS",14,171,312,32,treasurePage)
S.treasureScanButton.BackgroundColor3=PANEL
S.treasureOutput=make("TextBox",{Position=UDim2.fromOffset(14,211),
    Size=UDim2.new(1,-28,1,-225),BackgroundColor3=PANEL,BorderSizePixel=0,
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
    -- A real map remains eligible while it exists in inventory. Temporary
    -- failures are filtered only when selecting a target for THIS trip.
    return tMaps()
end
local function tReadyMaps(skipped)
    local out={}
    local now=os.clock()
    for _,m in ipairs(tMaps()) do
        if (not skipped or not skipped[m.guid])
            and now>=(S.treasureRetryAfter[m.guid] or 0) then
            out[#out+1]=m
        end
    end
    return out
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
    -- Restore the mining settings even if movement failed. This ensures
    -- Dredge never inherits a treasure-map coordinate as its DIG/WATER.
    S.dig,S.water=cp.dig,cp.water
    S.activeZone,S.dredgeAt=cp.activeZone,cp.dredgeAt
    if not ok then return false,"Could not return: "..tostring(why) end
    return true
end

local function tRun(id)
    if S.treasureBusy or not S.treasureEnabled or not valid(id) then return end
    local list=tReadyMaps()
    if #list<S.treasureMinMaps then return end
    S.treasureBusy=true
    local rr=root()
    local oldDredge=S.dredge==true and S.running==true
    local cp={
        dig=S.dig,
        -- Dredge controls its OWN active dig spot and can change zones.
        -- Always return to the exact position at interruption, not a stale
        -- Auto Farm preset from an older quest.
        returnCF=oldDredge and (rr and rr.CFrame)
            or (S.dig or (rr and rr.CFrame)),
        water=S.water,
        activeZone=S.activeZone,
        dredgeAt=S.dredgeAt,
        riskZone=S.dredgeRiskZone
    }
    S.treasureWasDredge=oldDredge
    local oldSell=S.sell
    -- Temporary pause only. Keep the Dredge worker, wanted flag, quest
    -- state, Luck Cap, route and toggle untouched while Treasure travels.
    S.treasureDredgePaused=oldDredge
    if oldDredge then
        S.dredgeCurrentWork="PAUSED: collecting Treasure Maps"
        S.dredgeNextWork="Resume current Dredge quest after treasure"
    end
    S.dredge=false
    S.dredgeRiskZone=false
    local ok,err=true,nil
    local completedThisRun,failedThisRun=0,0
    local firstFailure=nil
    S.sell=false
    local initialCount=#list
    local steps=0
    local retryCounts={}
    -- The threshold is an entry condition ONLY. Once Treasure begins,
    -- it owns the worker until the real inventory reaches zero maps.
    -- Individual failures wait for their retry cooldown inside this trip;
    -- never return control to Dredge merely because fewer than X remain.
    S.treasureDraining=true
    while valid(id) and S.treasureEnabled do
        local allMaps=tMaps()
        if #allMaps==0 then break end
        local remaining=tReadyMaps()
        if #remaining==0 then
            local nearest=math.huge
            for _,m in ipairs(allMaps) do
                nearest=math.min(nearest,S.treasureRetryAfter[m.guid] or os.clock())
            end
            local delay=math.max(0,nearest-os.clock())
            tStatus(string.format(
                "Treasure ACTIVE | %d map(s) remain; waiting %.0fs to retry (Dredge paused)",
                #allMaps,delay))
            task.wait(math.clamp(delay,.3,1))
            continue
        end
        steps+=1
        if steps>250 then
            -- Treat this as a safety halt, not permission to resume Dredge
            -- with maps still held. Wait for the user to disable Auto Dig.
            tStatus("Treasure ACTIVE | route safety limit reached; Dredge remains paused")
            while valid(id) and S.treasureEnabled do task.wait(.5) end
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
            retryCounts[m.guid]=(retryCounts[m.guid] or 0)+1
            S.treasureRetryAfter[m.guid]=os.clock()+60
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
            retryCounts[m.guid]=(retryCounts[m.guid] or 0)+1
            S.treasureRetryAfter[m.guid]=os.clock()+60
            failedThisRun+=1
            firstFailure=firstFailure or
                ("Treasure dig not accepted: "..tostring(why or response))
            continue
        end
        -- An accepted request cannot be duplicated until the map has had
        -- time to replicate. Keep the same run alive if it remains held.
        S.treasureRetryAfter[m.guid]=os.clock()+90
        local found=false
        local consumed=false
        local deadline=os.clock()+18
        while valid(id) and os.clock()<deadline do
            if tChestCount()>before then found=true;break end
            if beforeMap and m.tool.Parent==nil then consumed=true end
            task.wait(.15)
        end
        if found or consumed then
            completedThisRun+=1
            tStatus(string.format("Resolved %d map(s) | %d still in inventory%s",
                completedThisRun,#tMaps(),found and "" or " (chest unverified)"))
            -- Chest replication may precede map deletion. Never consider
            -- inventory drained while the map Tool is still present.
            if m.tool.Parent==nil then S.treasureRetryAfter[m.guid]=nil end
        else
            retryCounts[m.guid]=(retryCounts[m.guid] or 0)+1
            S.treasureRetryAfter[m.guid]=os.clock()+90
            failedThisRun+=1
            firstFailure=firstFailure or
                "Dig accepted, but map still present and no chest detected in 18 seconds"
        end
    end

    local mapsLeft=#tMaps()
    if not valid(id) or not S.treasureEnabled then
        ok,err=false,"Stopped by user"
    elseif mapsLeft>0 then
        ok=false
        err="Treasure route interrupted with "..mapsLeft.." map(s) remaining"
    elseif failedThisRun>0 then
        -- Some attempts failed earlier, but the same run eventually cleared
        -- all maps. The whole run succeeded despite the temporary errors.
        S.diagEvent("TREASURE_RETRIES_RESOLVED",
            tostring(failedThisRun).." prior failures; inventory now empty")
    end
    S.treasureDraining=false

    local returned,why=tRestore(cp,id)
    if not returned then ok,err=false,(err and err.."; " or "").."RETURN FAILED: "..tostring(why) end
    S.sell=oldSell
    -- Resume the EXISTING Dredge worker, never call startWorker/stop().
    -- If the return route failed, clear stale location assumptions and let
    -- its regular planner find the correct deposit on the next iteration.
    if oldDredge and valid(id) and S.running then
        S.dredge=true
        if returned then
            S.dredgeRiskZone=cp.riskZone
            S.dredgeCurrentWork="Resuming Dredge quest after treasure"
        else
            S.dredgeAt=nil
            S.dredgeCurrent=nil
            S.dredgeGroup=nil
            S.dredgeRiskZone=false
            S.dredgeReadyAt=os.clock()+1
            S.dredgeCurrentWork="Replanning Dredge after treasure return failure"
        end
        S.dredgeNextWork="Continue current Dredge quest"
    else
        S.dredge=false
        S.dredgeRiskZone=cp.riskZone and S.running or false
    end
    S.treasureDredgePaused=false
    if not ok then
        S.treasureNextTryAt=os.clock()+20
    else
        S.treasureNextTryAt=os.clock()+2
    end
    S.treasureBusy=false
    S.treasureWasDredge=nil
    if ok then
        S.diagEvent("TREASURE_ROUTE_COMPLETE","collected="..completedThisRun)
        tStatus("Treasure complete: "..completedThisRun..
            " map(s) resolved, "..#tMaps().." remaining. Returned to farming.")
    else
        S.treasureLastError=tostring(err)
        S.diagEvent("TREASURE_ROUTE_FAILED",S.treasureLastError)
        tStatus("Treasure: "..completedThisRun.." resolved, "..
            #tMaps().." remaining; "..S.treasureLastError)
    end
end

-- One entry point works for the active farm worker and independent travel.
S.treasureCycle=function(id,r)
    if not S.treasureEnabled or S.treasureBusy or not valid(id) then return end
    -- Also protect the post-pan hook in farming(): finishing a pan is
    -- NOT the same as finishing a Dredge quest.
    if S.running and S.dredge and not S.treasureDredgeQuestReady then
        return
    end
    local n=#tReadyMaps()
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
        -- An exception must not permanently turn an active Dredge toggle
        -- into a farm worker. Force a fresh location plan if return failed.
        if S.treasureWasDredge and S.running and valid(id) then
            S.dredge=true
            S.dredgeAt=nil
            S.dredgeCurrent=nil
            S.dredgeGroup=nil
            S.dredgeRiskZone=false
            S.dredgeReadyAt=os.clock()+1
            S.dredgeCurrentWork="Replanning Dredge after Treasure error"
        end
        S.treasureDredgePaused=false
        S.treasureWasDredge=nil
        tStatus("Treasure error: "..S.treasureLastError)
    end
end

-- Independent loop: farm at the saved dig/water positions until a
-- Treasure Map is earned, collect all available maps, then farm again.
-- If Auto Farm or Dredge is already running, their EXISTING worker farms
-- and this loop only requests treasure routing at pan-cycle boundaries.
local function tFarmOneCycle(id)
    if not S.dig or not S.water then
        return false,"Set both DIG and WATER positions on the FARM tab"
    end
    local pan,why=tEquippedPan(id)
    if not pan then return false,"Cannot equip farming pan: "..tostring(why) end
    local cap=S.capacity()
    if not cap or cap<=0 then return false,"Pan capacity unavailable" end

    if S.completion then
        S.completion:Disconnect()
        S.completion=nil
    end
    if pan.done and pan.done:IsA("RemoteEvent") then
        S.completion=pan.done.OnClientEvent:Connect(function()
            if valid(id) and S.waiting then S.completed=true end
        end)
    end
    local oldSell=S.sell
    -- Prevent SellAll from disposing of a map before this loop sees it.
    S.sell=false
    local ok,whyCycle=pcall(farming,id,pan,cap)
    S.sell=oldSell
    if S.completion then
        S.completion:Disconnect()
        S.completion=nil
    end
    S.waiting=false
    if not ok then return false,tostring(whyCycle) end
    if whyCycle~="TREASURE_FARM_CYCLE_DONE" then
        return false,tostring(whyCycle or "Incomplete farm cycle")
    end
    return true
end

local function tStandaloneLoop(id)
    local errors=0
    while valid(id) and S.treasureEnabled and not S.running do
        local owned=#tMaps()
        local ready=#tReadyMaps()
        if owned>=S.treasureMinMaps then
            if ready>=S.treasureMinMaps
                and os.clock()>=(S.treasureNextTryAt or 0) then
                S.treasureCycle(id,nil)
            else
                tStatus(string.format(
                    "Treasure | %d maps held, %d ready; waiting for retry",
                    owned,ready))
                task.wait(.6)
            end
        else
            tStatus("Treasure auto-farming | digging and panning to earn maps")
            local ok,reason=tFarmOneCycle(id)
            if not ok then
                errors+=1
                tStatus("Treasure farm paused ("..errors.."/5): "..tostring(reason))
                -- Repeated missing Fill usually means an invalid dig spot or
                -- a rejected server position. Stop teleport loops and leave
                -- the actionable error visible until the user resets AUTO DIG.
                if errors>=5 then
                    S.treasureFarmBlocked=tostring(reason)
                    S.treasureEnabled=false
                    S.treasureRequested=false
                    if S.treasureToggle then
                        S.treasureToggle.Text="AUTO DIG MAPS: OFF"
                        S.treasureToggle.BackgroundColor3=PANEL
                    end
                    tStatus("Treasure stopped after 5 failures: "..S.treasureFarmBlocked)
                    break
                else
                    task.wait(1)
                end
            else
                errors=0
                -- Give earned map items a moment to replicate.
                task.wait(.4)
            end
        end
    end
end

task.spawn(function()
    while S.alive do
        task.wait(.6)
        if S.treasureEnabled then
            if S.running then
                -- Never interrupt Dredge again during the retry cooldown.
                -- A pending pan finishes before the worker handles this.
                S.treasureRequested=not S.treasureBusy
                    and os.clock()>=(S.treasureNextTryAt or 0)
                    and #tReadyMaps()>=S.treasureMinMaps
            elseif not S.treasureStandalone then
                if S.dig and S.water then
                    S.treasureStandalone=true
                    S.token+=1
                    local id=S.token
                    local ok,err=pcall(tStandaloneLoop,id)
                    if not ok and S.alive then
                        S.treasureLastError=tostring(err)
                        tStatus("Treasure farm error: "..S.treasureLastError)
                    end
                    if S.completion then
                        S.completion:Disconnect()
                        S.completion=nil
                    end
                    S.waiting=false
                    S.treasureStandalone=false
                else
                    tStatus("AUTO DIG ON | Set DIG and WATER in the FARM tab first")
                end
            end
        end
    end
end)

local function tScan()
    local list=tMaps()
    local available=tReadyMaps()
    local lines={"GALAXIS TREASURE MAPS","Maps in inventory: "..#list..
        " | ready: "..#available.." | threshold: "..S.treasureMinMaps,""}
    for i,m in ipairs(list) do
        lines[#lines+1]=string.format("%d. %s | %.1f, %.1f, %.1f | %s",
            i,m.region,m.pos.X,m.pos.Y,m.pos.Z,m.guid)
    end
    lines[#lines+1]=""
    lines[#lines+1]="Auto Dig: "..tostring(S.treasureEnabled)
    lines[#lines+1]="Run threshold: "..tostring(S.treasureMinMaps).." maps"
    lines[#lines+1]="Dig position saved: "..tostring(S.dig~=nil)
    lines[#lines+1]="Water/pan position saved: "..tostring(S.water~=nil)
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
        if not S.running and (not S.dig or not S.water) then
            tStatus("AUTO DIG ON | Set DIG and WATER on FARM tab first")
        elseif n>=S.treasureMinMaps then
            tStatus(S.running
                and (S.dredge and "AUTO DIG ON | Waiting for Dredge quest turn-in" or "AUTO DIG ON | Treasure after current pan cycle")
                or "AUTO DIG ON | Collecting existing maps")
        else
            tStatus("AUTO DIG ON | Farming maps at saved DIG and WATER positions")
        end
    else
        S.treasureRequested=false
        tStatus(S.treasureBusy and "OFF | Stopping at next safe movement check." or "OFF")
    end
    tRefresh()
end)
bind(S.treasureMinInput.FocusLost,function()
    local raw=S.treasureMinInput.Text
    local value=tonumber(raw)
    if value and value==value then
        S.treasureMinMaps=math.clamp(math.floor(value),1,100)
        E.GalaxisTreasureMinMaps=S.treasureMinMaps
    end
    S.treasureMinInput.Text=tostring(S.treasureMinMaps)
    local n=#tEligibleMaps()
    if S.treasureEnabled and not S.treasureBusy then
        S.treasureRequested=S.running and n>=S.treasureMinMaps
        tStatus(n>=S.treasureMinMaps
            and ("Threshold reached ("..n.."/"..S.treasureMinMaps..") | treasure next")
            or ("Farming until "..S.treasureMinMaps.." maps ("..n.." collected)"))
    end
end)
bind(S.treasureScanButton.MouseButton1Click,tScan)
tRefresh()
tScan()
