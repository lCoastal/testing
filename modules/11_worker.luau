-- Galaxis module: 11_worker.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function startWorker(asDredge)
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
                reason=ok and (result or "Cycle ended unexpectedly")
                    or ("Runtime error: "..tostring(result))
            end

            if S.completion then
                S.completion:Disconnect()
                S.completion=nil
            end
            S.waiting=false

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
                if S.simpleFailures>=5 then
                    stop()
                    show("Stopped after 5 consecutive failures: "..why:sub(1,50))
                    break
                end
                show("Retrying: "..why:sub(1,70))
                if not pause(.45,id) then break end
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
