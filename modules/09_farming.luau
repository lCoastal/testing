-- Galaxis module: 09_farming.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function getSell()
    local rem=RS:FindFirstChild("Remotes")
    local shop=rem and rem:FindFirstChild("Shop")
    local r=shop and shop:FindFirstChild("SellAll")
    return r and r:IsA("RemoteFunction") and r or nil
end
-- Exactly one SellAll request for each successfully completed pan
-- while Auto Sell is enabled. Sequential queue prevents dropped pans.
-- Sales run separately, so digging is never blocked by selling.
      function autoSell(id,cycle)
    if not S.sell or not valid(id) or S.lastQueuedCycle==cycle then return end
    local chestContainers={}
    local customBag=P:FindFirstChild("BackpackTwo")
    local normalBag=P:FindFirstChildOfClass("Backpack")
    if customBag then chestContainers[#chestContainers+1]=customBag end
    if normalBag then chestContainers[#chestContainers+1]=normalBag end
    if P.Character then chestContainers[#chestContainers+1]=P.Character end
    for _,container in ipairs(chestContainers) do
        for _,item in ipairs(container:GetChildren()) do
            local name=string.lower(item.Name)
            if item:IsA("Tool") and name:find("chest",1,true)
                and not name:find("map",1,true) then
                S.diagEvent("SELL_SKIPPED_TREASURE_CHEST","Chest present; preserving inventory")
                return
            end
        end
    end
    S.lastQueuedCycle=cycle
    S.sellQueue[#S.sellQueue+1]={id=id,cycle=cycle,queuedAt=os.clock()}
    S.diagEvent("SELL_QUEUED","pan "..tostring(cycle))
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
                        local startedAt=os.clock()
                        S.diagEvent("SELL_START","pan "..tostring(job.cycle))
                        local ok,err=pcall(function() r:InvokeServer() end)
                        S.diagEvent(ok and "SELL_END" or "SELL_ERROR",
                            string.format("pan %s | %.3fs | %s",
                                tostring(job.cycle),os.clock()-startedAt,
                                ok and "success" or tostring(err)))
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
-- TURBO / DOUBLE SHAKE CLASSIC FARM: the older, reliable core.
-- Deliberately no adaptive Pan delays, per-call position corrections,
-- early movement, automatic tuning, or nested recovery state machine.
      function farming(id,r,target)
    while valid(id) do
        if S.dredge and not dredgeCycle(id) then
            if not valid(id) then return end
            if not pause(.3,id) then return end
            continue
        end
        target=S.capacity() or target
        local cycleStart=os.clock()
        S.diagEvent("CYCLE_START","fill="..tostring(fill(r))..
            " target="..tostring(target).." zone="..tostring(S.dredgeAt or S.activeZone))
        show("Digging")
        S.traceBegin("MOVE_TO_DIG","")
        local moved=farmMove(S.dig,id)
        S.traceEnd("MOVE_TO_DIG","success="..tostring(moved))
        if not moved then return "Dig teleport failed" end

        S.traceBegin("COLLECT_TO_CAPACITY",tostring(fill(r)).." / "..tostring(target))
        local lastProgress=os.clock()
        S.diagDigProgressAt=lastProgress
        S.diagDigCalls=0
        for _=1,CFG.maxDig do
            if not valid(id) then return end
            local before=fill(r)
            if before==nil then return "Fill unavailable" end
            if before>=target-.01 then break end
            local sent=os.clock()
            S.diagCollectPendingAt=sent
            local ok,response,err=invoke(r.dig,id,1)
            S.diagCollectPendingAt=nil
            S.diagDigCalls+=1
            S.diagLastCollectMs=math.floor((os.clock()-sent)*1000+.5)
            S.diagLastCollectResult=ok and tostring(response) or tostring(err)
            if not ok then
                if tostring(err):find("Prior Collect request settled",1,true) then
                    S.diagEvent("COLLECT_RECOVERY_RECHECK", "Prior result settled; checking Fill")
                    -- Re-evaluate Fill before sending any new Collect.
                    lastProgress=os.clock()
                    S.diagDigProgressAt=lastProgress
                    continue
                end
                return "Collect failed: "..tostring(err)
            end
            if not pause(S.timing("dig"),id) then return end
            local after=fill(r)
            if after and after>before+.001 then
                lastProgress=os.clock()
                S.diagDigProgressAt=lastProgress
            elseif os.clock()-lastProgress>3 then
                -- The player can be rubber-banded to water after a recent
                -- teleport. Fix position only on a real stall, never per dig.
                local avatar=root()
                local drift=avatar and S.dig and
                    (avatar.Position-S.dig.Position).Magnitude or math.huge
                if drift>7 then
                    S.diagEvent("DIG_DRIFT_REPAIR",string.format("%.1f studs",drift))
                    if not farmMove(S.dig,id) then return "Dig position correction failed" end
                    lastProgress=os.clock()
                    S.diagDigProgressAt=lastProgress
                else
                    return "Digging stalled (3s without Fill progress)"
                end
            end
        end
        S.traceEnd("COLLECT_TO_CAPACITY","fill="..tostring(fill(r))..
            " / "..tostring(target).." calls="..tostring(S.diagDigCalls))
        if (fill(r) or 0)<target-.01 then return "Pan not full" end
        local digTime=os.clock()-cycleStart

        show("Panning")
        local waterStart=os.clock()
        S.traceBegin("MOVE_TO_WATER","")
        moved=farmMove(S.water,id)
        S.traceEnd("MOVE_TO_WATER","success="..tostring(moved))
        if not moved then return "Water teleport failed" end
        if S.dredge and S.water then
            local avatar=root()
            local remaining=avatar and
                (avatar.Position-S.water.Position).Magnitude or math.huge
            S.diagEvent("PAN_WATER_POSITION",string.format(
                "zone=%s distance=%.2f",
                tostring(S.dredgeAt),remaining))
        end
        -- Dredge changes zones and Luck Cap, so a one-time settle check
        -- after new-zone arrival avoids racing a server position update.
        -- Ordinary Auto Farm gets no extra wait.
        if S.dredge and S.dredgeAt and
            (S.cycles-(S.dredgeZoneCycle or 0))<1 then
            if not pause(.18,id) then return end
        end
        local waterTime=os.clock()-waterStart
        S.rewards=0;S.lastReward=0;S.completed=false;S.waiting=true;S.seen={}
        local panStart=os.clock()
        S.traceBegin("PAN_INVOKE","fill="..tostring(fill(r)))
        local accepted=false
        local panAttempts=0
        for _=1,15 do
            if not valid(id) then return end
            if not requirePanEquipped(r,id) then return "Pan not equipped" end
            -- Immediately try Pan after arriving at water.
            -- Position checks are reserved for rejected Dredge calls.
            panAttempts+=1
            local ok,response,err=invoke(r.pan,id)
            if not ok then return "Pan call failed: "..tostring(err) end
            if response==true then accepted=true;break end
            -- Dredge only: correct a server snapback after a rejection.
            -- Regular Auto Farm keeps the original turbo retry loop.
            if S.dredge then
                local avatar=root()
                local drift=avatar and S.water and
                    (avatar.Position-S.water.Position).Magnitude or math.huge
                if drift>2.5 then
                    S.diagEvent("PAN_REJECT_DRIFT",string.format(
                        "attempt=%d distWater=%.1f",panAttempts,drift))
                    if not farmMove(S.water,id) then return "Water recovery failed" end
                end
            end
            if not pause(S.timing("panRetry"),id) then return end
        end
        if not accepted then return "Pan rejected" end
        S.traceEnd("PAN_INVOKE",string.format(
            "accepted after %d attempt(s), %.3fs",panAttempts,os.clock()-panStart))
        local panTime=os.clock()-panStart

        show("Shaking")
        S.traceBegin("SHAKE_LOOP","doubleShake="..tostring(S.doubleShake))
        local shakeStart=os.clock()
        local function finished()
            return S.completed or
                (S.rewards>0 and os.clock()-S.lastReward>=CFG.rewardGap)
        end
        local done=false
        for _=1,CFG.maxShake do
            if not valid(id) then return end
            if finished() then done=true;break end
            if not requirePanEquipped(r,id) then return "Pan unequipped during shake" end
            if not pcall(function() r.shake:FireServer() end) then return "Shake failed" end
            if S.doubleShake then
                if not pause(S.timing("shakeGap"),id,finished) then return end
                if not finished() then
                    if not pcall(function() r.shake:FireServer() end) then
                        return "Shake failed"
                    end
                end
            end
            if not pause(S.timing("shake"),id,finished) then return end
        end
        if not done then
            local deadline=os.clock()+1.5
            while valid(id) and os.clock()<deadline do
                if finished() then done=true;break end
                task.wait(.02)
            end
        end
        if not done then return "No completion detected" end
        S.traceEnd("SHAKE_LOOP","completed="..tostring(S.completed)..
            " locallyObservedRewards="..tostring(S.rewards))
        S.waiting=false
        if S.dredge then
            S.dredgeFailureCount=0
            S.dredgeFailureZone=S.dredgeAt
        end
        S.cycles+=1
        S.simpleFailures=0
        local total=os.clock()-cycleStart
        S.totalCycleTime+=total
        local recent=S.recentTimes
        recent[#recent+1]=total
        if #recent>10 then table.remove(recent,1) end
        S.diagEvent("CYCLE_DONE",string.format(
            "cycle=%d total=%.3fs dig=%.3fs water=%.3fs pan=%.3fs shake=%.3fs",
            S.cycles,total,digTime,waterTime,panTime,os.clock()-shakeStart))
        autoSell(id,S.cycles)
        -- Run treasure routing only after the full pan cycle has completed.
        if S.treasureCycle then
            local ok,err=pcall(S.treasureCycle,id,r)
            if not ok then S.diagEvent("TREASURE_HOOK_ERROR",tostring(err)) end
        end
        -- Once treasure has returned to the saved dig position, allow one
        -- complete normal farm cycle before restoring the Dredge planner.
        if S.treasureResumeDredgeAfterCycle
            and S.cycles>=S.treasureResumeDredgeAfterCycle then
            S.treasureResumeDredgeAfterCycle=nil
            S.dredge=true
            S.dredgeReadyAt=os.clock()+1.2
            S.dredgeCurrentWork="Resuming Dredge after treasure route"
        end
    end
end
