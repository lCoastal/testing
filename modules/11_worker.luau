-- Galaxis module: 11_worker.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function startWorker(asDredge)
    if S.treasureBusy or S.treasureStandalone then
        show("Treasure route is active; finish or stop it first")
        return
    end
    if S.running then return end
    -- AUTO FARM FAST START: saved locations are already loaded when
    -- selected/captured. Do not reload presets or run any zone setup.
    if not asDredge and (not S.dig or not S.water) then
        show("Set dig and water positions first")
        return
    end
    if asDredge then
        if type(getsenv)~="function" then dredgeText("Executor requires getsenv");return end
        S.dredgeRestore={dig=S.dig,water=S.water,zone=S.activeZone}
        S.dredge=true;S.dredgeCurrent=nil;S.dredgeGroup=nil
        S.treasureAwaitingQuestBoundary=false
        S.treasureDredgeQuestReady=false
        S.treasureTaskReason=nil
        S.dredgeTaskSeen={}
        S.treasurePanCycleActive=false
        S.enchantedRecording=nil
        -- Preserve the recorded Enchanted entry path across OFF -> ON.
        -- Restarting without that path previously broke the return route.
        S.dredgeAt=S.dredgeResumeZone
        S.dredgeAppliedCap="UNSET"
        if S.dredgeAt then
            S.diagEvent("DREDGE_RESUME_ZONE",S.dredgeAt)
        end
        S.dredgeCapLockedZone=nil;S.dredgeCapLockedKey=nil
        S.dredgeTurnAttempts=0;S.dredgeTurnRetryAt=nil
        S.dredgeCapLastAt=-math.huge
        S.dredgeLastStepQuery=-math.huge
        S.dredgeUncappedLuck=nil
        S.dredgeWarped={};S.dredgeTravelFailed={};S.dredgeTravelRetryAt=nil
        S.dredgeReadyAt=0;S.dredgeZoneCycle=S.cycles
        S.dredgeFailureCount=0;S.dredgeFailureZone=nil
        S.dredgePlanLuck=nil;S.dredgePlanCapacity=nil
        S.dredgePlannedRemaining=nil
        S.dredgeTalkAt=nil;S.dredgeNextAt=nil;S.dredgeStartAt=nil
        S.dredgeServerStatus=nil;S.dredgeServerProgress=nil
        S.dredgeCurrentWork="Reading quest"
        S.dredgeNextWork="Choose a zone and Luck Cap"
        S.dredgeNextStop=nil
        S.dredgeNextServerPoll=0;S.dredgeQuestPollError=nil
        S.dredgePollAttempts=0;S.dredgePollStartedAt=nil
        S.dredgePollCompletedAt=nil;S.dredgeInitAt=os.clock()
        S.dredgePollBusy=false;S.dredgeTransitionMode=nil
        S.dredgeTransitionAttempts=0;S.dredgeTransitionAt=0
        -- Remove preexisting Luck Caps before the first planning snapshot.
        local rem=RS:FindFirstChild("Remotes")
        local setting=rem and rem:FindFirstChild("Settings")
        local change=setting and setting:FindFirstChild("ChangeSetting")
        if not change or not change:IsA("RemoteEvent") then
            S.dredge=false;dredgeText("Luck Cap remote missing");return
        end
        if not pcall(function() change:FireServer("MaximumLuck","None") end) then
            S.dredge=false;dredgeText("Failed to clear previous cap");return
        end
        S.dredgeAppliedCap="NONE"
        S.dredgeLuckReadyAt=os.clock()+2.0
        dredgeButton.Text="AUTO DREDGE: ON"
        dredgeText("Starting / reading Dredge quest")
    else
        S.dredge=false
    end
    S.running=true
    S.simpleFailures=0
    S.diagEvent("START",asDredge and "AUTO DREDGE" or "AUTO FARM")
    S.token+=1
    local id=S.token
    farmB.Text="AUTO FARM: ON"
    S.waiting=false
    show(asDredge and "Planning Dredge" or "Digging")

    task.spawn(function()
        while valid(id) do
            -- A dedicated Treasure dispatcher may take over while this worker
            -- was suspended in a quest or movement function. Never issue
            -- concurrent pan/dig/movement requests during that handoff.
            if S.treasureBusy or S.treasureDispatchBusy then
                task.wait(.15)
                continue
            end
            -- During Dredge, wait for a CONFIRMED quest turn-in before
            -- switching to Treasure. Do not interrupt objective collection,
            -- travel, or the turn-in itself. Auto Farm still uses its normal
            -- between-pan handoff.
            local questBoundaryTreasure=S.dredge
                and S.treasureDredgeQuestReady
                and S.treasureCanStart and S.treasureCanStart()
            if S.treasureCycle
                and (S.treasureRequested or questBoundaryTreasure)
                and (not S.dredge or questBoundaryTreasure) then
                local trOk,trResult=pcall(S.treasureCycle,id,panTool() or S.panInBackpack())
                if not trOk then
                    local trErr=trResult
                    S.treasureLastError=tostring(trErr)
                    if S.treasureStatus then
                        S.treasureStatus.Text="Treasure error: "..S.treasureLastError
                    end
                    S.treasureRequested=false
                end
                if questBoundaryTreasure and trOk and trResult==true then
                    -- Clear only after Treasure actually attempted a route.
                    -- A cooldown/early return must not lose the handoff.
                    S.treasureDredgeQuestReady=false
                    S.treasureAwaitingQuestBoundary=false
                end
                if S.treasureBusy then
                    repeat task.wait(.1) until not S.treasureBusy or not valid(id)
                end
                if not pause(.05,id) then break end
                continue
            end
            -- Quest turn-in/start requires no equipped pan. Previously a
            -- missing pan blocked the whole worker before it could walk
            -- back to the Dredge Master after re-enabling.
            local questAction=S.dredge and S.dredgeServerStatus
                and (questMode(S.dredgeServerStatus)=="turnin"
                    or questMode(S.dredgeServerStatus)=="available")
            if questAction then
                local ok,err=pcall(dredgeCycle,id)
                if not ok then
                    S.diagEvent("DREDGE_TRANSITION_ERROR",tostring(err))
                end
                if not pause(.3,id) then break end
                continue
            end
            local r=panTool() or S.panInBackpack()
            -- Dredge's planner and travel logic must keep running even if
            -- the pan is temporarily unequipped (e.g. during a warp or NPC
            -- interaction). A pan-less planning interval is not a farm error.
            if S.dredge and not r then
                S.diagEvent("DREDGE_PAN_UNAVAILABLE",
                    "No compatible equipped/backpack pan; continuing quest planning")
                local ok,err=pcall(dredgeCycle,id)
                if not ok then S.diagEvent("DREDGE_PLAN_ERROR",tostring(err)) end
                if not pause(1,id) then break end
                continue
            end
            if r then requirePanEquipped(r,id) end
            local target=S.capacity()
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
                S.treasurePanCycleActive=false
                reason=ok and (result or "Cycle ended unexpectedly")
                    or ("Runtime error: "..tostring(result))
            end

            if S.completion then
                S.completion:Disconnect()
                S.completion=nil
            end
            S.waiting=false

            if valid(id) and reason=="TREASURE_REQUESTED" then
                if S.treasureCycle then
                    local trOk,trErr=pcall(S.treasureCycle,id,r)
                    if not trOk then
                        S.treasureLastError=tostring(trErr)
                        if S.treasureStatus then
                            S.treasureStatus.Text="Treasure error: "..S.treasureLastError
                        end
                        S.treasureRequested=false
                    end
                end
                if S.treasureBusy then
                    repeat task.wait(.1) until not S.treasureBusy or not valid(id)
                end
                if not pause(.05,id) then break end
                continue
            end

            if valid(id) then
                S.traceCurrentAction=nil
                S.traceActionStartedAt=nil
                S.traceNextStallAt=nil
                S.diagLastFailure=tostring(reason)
                S.diagEvent("RECOVERY",tostring(reason).." | "..S.diagSnapshot())
                -- Keep one in-flight RPC protection: a timed-out request
                -- cannot be cancelled, so never pile another onto it.
                local why=tostring(reason)
                if why:find("still in flight",1,true) or
                    why:find("still pending",1,true) then
                    S.diagEvent("RPC_PENDING_STOP",why)
                    stop()
                    show("Stopped: remote still pending")
                    break
                end
                S.simpleFailures=(S.simpleFailures or 0)+1
                if S.simpleFailures>=5 and S.dredge then
                    S.diagEvent("DREDGE_FAILURE_COOLDOWN",why)
                    show("Dredge recovering after "..S.simpleFailures.." failures: "..why:sub(1,55))
                    S.simpleFailures=0
                    if not pause(8,id) then break end
                elseif S.simpleFailures>=5 then
                    stop()
                    show("Stopped after 5 consecutive failures: "..why:sub(1,50))
                    break
                else
                    show("Retrying: "..why:sub(1,70))
                    if not pause(.45,id) then break end
                end
            end
        end
    end)
end
-- Dredge intent is separate from a worker's lifetime. A death invalidates
-- the old character, pan, and RPC session, then starts a fresh session after
-- the new character and inventory are replicated. Manual OFF cancels this.
S.dredgeWanted=false
S.dredgeRespawnSerial=0
      function cancelDredgeRespawn()
    S.dredgeWanted=false
    S.dredgeRespawnSerial+=1
end
      function onDredgeDeath()
    if not S.alive or not S.dredgeWanted or S.dredgeRespawnPending then return end
    S.dredgeRespawnPending=true
    S.dredgeRespawnSerial+=1
    local serial=S.dredgeRespawnSerial
    S.diagEvent("DREDGE_DEATH","Character died; invalidating old worker, waiting to respawn")
    if S.running then stop() end
    -- Death means the saved departure zone no longer describes where we
    -- physically are. Always navigate from the new spawn location.
    S.dredgeResumeZone=nil
    S.dredgeAt=nil
    task.spawn(function()
        local started=os.clock()
        while S.alive and S.dredgeWanted
            and S.dredgeRespawnSerial==serial do
            local c=P.Character
            local hum=c and c:FindFirstChildOfClass("Humanoid")
            local rr=c and c:FindFirstChild("HumanoidRootPart")
            local bag=P:FindFirstChildOfClass("Backpack")
            if hum and hum.Health>0 and rr and bag then
                -- The custom inventory and equipped pan can replicate later.
                -- Dredge can plan without an equipped pan, but give it a
                -- short window so the first Collect uses the new Tool.
                if os.clock()-started>=3 and (panTool() or S.panInBackpack()
                    or os.clock()-started>=12) then
                    S.dredgeRespawnPending=false
                    S.diagEvent("DREDGE_RESPAWN_READY",string.format(
                        "spawn=%.1f,%.1f,%.1f pan=%s elapsed=%.1fs",
                        rr.Position.X,rr.Position.Y,rr.Position.Z,
                        tostring((panTool() or S.panInBackpack())~=nil),
                        os.clock()-started))
                    startWorker(true)
                    if S.running then
                        S.diagEvent("DREDGE_RESPAWN_RESTART",
                            "Fresh quest plan and route from actual spawn")
                    else
                        S.diagEvent("DREDGE_RESPAWN_START_FAILED",
                            "startWorker did not start; check executor/quest")
                    end
                    return
                end
            end
            task.wait(.35)
        end
        S.dredgeRespawnPending=false
    end)
end
      function watchDredgeCharacter(character)
    local hum=character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid",10)
    if hum then
        bind(hum.Died,function()
            if character==P.Character then onDredgeDeath() end
        end)
    end
end
bind(P.CharacterAdded,function(character)
    -- CharacterAdded may fire before the old Humanoid.Died connection
    -- does, or when the character is replaced without a death event.
    if S.dredgeWanted and not S.dredgeRespawnPending then
        S.diagEvent("DREDGE_CHARACTER_REPLACED",
            "Character changed; preparing fresh Dredge session")
        onDredgeDeath()
    end
    task.spawn(watchDredgeCharacter,character)
end)
if P.Character then task.spawn(watchDredgeCharacter,P.Character) end
bind(farmB.MouseButton1Click,function()
    cancelDredgeRespawn()
    if S.running then stop() else startWorker(false) end
end)
bind(dredgeButton.MouseButton1Click,function()
    if S.running or S.dredgeRespawnPending then
        cancelDredgeRespawn()
        if S.running then stop() end
        S.dredgeRespawnPending=false
        dredgeText("Dredge stopped")
    else
        S.dredgeWanted=true
        startWorker(true)
        if not S.running then S.dredgeWanted=false end
    end
end)
task.spawn(function()
    while S.alive do
        if S.dredge and S.dredgeRiskZone then dredgeHealthWatch() end
        task.wait(.15)
    end
end)

-- Timed-zone Dredge anti-stuck: ASK the active walkRoute to perform a
-- slow noclip recovery. Do not respawn or drive the character from a second
-- movement task; the current navigation coroutine owns each checkpoint.
S.timedZoneStuckSeconds=15
S.timedZoneFlightLastAt=-math.huge
S.timedZoneFlightRequested=false
S.timedZoneFlightActive=false
task.spawn(function()
    local lastRoot=nil
    local lastPosition=nil
    local lastProgressAt=os.clock()
    local lastToken=nil
    local lastTravelKey=nil
    while S.alive do
        task.wait(.35)
        local currentWork=tostring(S.dredgeCurrentWork or "")
        local isWalking=S.traceCurrentAction=="DREDGE_ZONE_TRAVEL"
            or currentWork:find("Walking ",1,true)==1
        local timedZone=S.dredgeAt=="Timelocked Sanctuary"
            or S.dredgeAt=="Infernal Heart"
            or S.dredgeCurrent=="Timelocked Sanctuary"
            or S.dredgeCurrent=="Infernal Heart"
        local c=P.Character
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        local r=root()
        local watching=S.running and S.dredgeWanted and S.dredge
            and not S.treasureBusy and not S.treasureDredgePaused
            and not S.dredgeRespawnPending
            and timedZone and isWalking and hum and hum.Health>0 and r
        local key=tostring(S.dredgeAt).."|"..tostring(S.dredgeCurrent)
        if not watching then
            S.timedZoneFlightRequested=false
            lastRoot=nil;lastPosition=nil;lastToken=nil;lastTravelKey=nil
            lastProgressAt=os.clock()
            continue
        end
        if S.timedZoneFlightActive then
            lastPosition=r.Position
            lastProgressAt=os.clock()
            continue
        end
        if r~=lastRoot or S.token~=lastToken or key~=lastTravelKey then
            lastRoot=r;lastPosition=r.Position
            lastToken=S.token;lastTravelKey=key
            lastProgressAt=os.clock()
            continue
        end
        if (r.Position-lastPosition).Magnitude>=3 then
            lastPosition=r.Position
            lastProgressAt=os.clock()
            S.timedZoneFlightRequested=false
            continue
        end
        if os.clock()-lastProgressAt>=S.timedZoneStuckSeconds
            and not S.timedZoneFlightRequested
            and os.clock()-S.timedZoneFlightLastAt>=45 then
            S.timedZoneFlightRequested=true
            S.timedZoneFlightLastAt=os.clock()
            S.diagEvent("TIMED_ZONE_FLIGHT_REQUEST",string.format(
                "No 3-stud progress in 15s | from=%s to=%s | work=%s",
                tostring(S.dredgeAt),tostring(S.dredgeCurrent),currentWork))
            dredgeText("Timed-zone path stuck 15s; using slow noclip route recovery")
            lastProgressAt=os.clock()
        end
    end
end)
-- X handler was bound at window creation so it works even during startup.
-- C toggles the entire UI without stopping automation or logging.
-- Ignore typing in chat/text inputs and other consumed keypresses.
-- Store transient UI interaction state on the existing S table instead
-- of consuming five more top-level Luau local registers (limit: 200).
S.uiHidden=false
S.ToggleInterface=function()
    if not S.alive then return end
    S.uiHidden=not S.uiHidden
    G.Enabled=not S.uiHidden
end
bind(UIS.InputBegan,function(input,gameProcessed)
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    if gameProcessed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.C then
        S.ToggleInterface()
    elseif input.KeyCode==Enum.KeyCode.R and S.reforgeKeybindEnabled then
        S.reforgeNow()
    end
end)
S.uiMinimized=false
bind(Min.MouseButton1Click,function()
    S.uiMinimized=not S.uiMinimized
    Body.Visible=not S.uiMinimized
    W.Size=S.uiMinimized and UDim2.fromOffset(340,43) or UDim2.fromOffset(340,540)
    Min.Text=S.uiMinimized and "+" or "−"
end)
S.uiDragging=false
S.uiDragStart=nil
S.uiWindowStart=nil
bind(H.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        S.uiDragging=true
        S.uiDragStart=i.Position
        S.uiWindowStart=W.Position
    end
end)
bind(UIS.InputChanged,function(i)
    if S.uiDragging and S.alive and S.uiDragStart and S.uiWindowStart
        and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-S.uiDragStart
        local p=S.uiWindowStart
        W.Position=UDim2.new(p.X.Scale,p.X.Offset+d.X,
            p.Y.Scale,p.Y.Offset+d.Y)
    end
end)
bind(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then S.uiDragging=false end
end)
bind(P.CharacterRemoving,function()
    -- Do not turn the toggle OFF on respawn; the worker will retry when
    -- an equipped pan and character are available again.
    if S.running then
        S.waiting=false
        show("Character changed - recovering")
    end
end)
print("[GALAXIS HUB BETA] Ready | mineral log:",FILE,
    "| verbose Output:",OUTPUT_DEBUG and "ON" or "OFF")
if L.error then
    outputWarning("startup-logger","[GALAXIS HUB BETA] Logger:",L.error)
end
