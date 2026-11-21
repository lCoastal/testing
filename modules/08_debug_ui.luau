-- Galaxis module: 08_debug_ui.luau
-- Loaded by beta.luau into the shared Galaxis environment.
S.liveTitle=label("LIVE DEBUG  /  AUTO-SAVING",14,9,312,26,12,FG)
relocate(S.liveTitle,livePage,14,9)
S.liveStatus=label("Starting diagnostics...",14,42,312,222,11,FG)
relocate(S.liveStatus,livePage,14,42)
S.liveStatus.TextWrapped=true
S.liveStatus.TextYAlignment=Enum.TextYAlignment.Top
S.liveFileLabel=label("TXT: "..S.liveDebugFile,14,269,312,34,10,MUTED)
relocate(S.liveFileLabel,livePage,14,269)
S.liveFileLabel.TextWrapped=true
S.liveCopyButton=button("COPY LIVE DEBUG REPORT",14,314,312,36,livePage)
S.mineralFileLabel=label("MINERAL LOG: "..FILE,14,352,312,30,10,MUTED)
relocate(S.mineralFileLabel,livePage,14,352)
S.mineralFileLabel.TextWrapped=true
S.liveInfo=label("Log writes automatically. Copy report for support.",14,385,312,25,10,MUTED)
relocate(S.liveInfo,livePage,14,385)
S.liveInfo.TextWrapped=true
S.perfLabel=label("FPS: measuring... | Frame: measuring...",14,413,312,23,11,FG)
relocate(S.perfLabel,livePage,14,413)
bind(S.liveCopyButton.MouseButton1Click,function()
    S.liveDebugRecord("MANUAL_EXPORT",S.liveDebugDetails())
    S.flushLiveDebug()
    local report=string.format(
        "PERFORMANCE: FPS %.1f | average frame %.1fms | Auto mode %s\\n",
        S.perfFPS or 0,S.perfFrameMs or 0,
        S.running and (S.dredge and "DREDGE" or "FARM") or "OFF")..
        S.diagReport().."\n--- LIVE DEBUG RECENT ---\n"..
        table.concat(S.liveDebugRecent)
    local copied=false
    if type(setclipboard)=="function" then copied=pcall(setclipboard,report) end
    S.liveInfo.Text=copied and "Report copied to clipboard."
        or "Clipboard unavailable; TXT log is still being saved."
end)

-- Quest and live zone diagnostics refresh independently of farming.
task.spawn(function()
    while S.alive do
        if livePage.Visible then
            S.perfLabel.Text=string.format("FPS: %.1f | Frame: %.1f ms | Auto: %s",
                S.perfFPS or 0,S.perfFrameMs or 0,S.running and "ON" or "OFF")
            S.mineralFileLabel.Text="MINERAL LOG: "..FILE
            local action=S.traceCurrentAction or "Idle / no active action"
            local age=S.traceActionStartedAt and
                string.format("%.1fs",os.clock()-S.traceActionStartedAt) or "N/A"
            local pan=panTool()
            local pos=root()
            local hp=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
            local function d(cf)
                return pos and cf and string.format("%.1f studs",
                    (pos.Position-cf.Position).Magnitude) or "N/A"
            end
            local idleFor=os.clock()-(S.liveDebugLastChangeAt or os.clock())
            S.liveStatus.Text=
                "Running: "..tostring(S.running).." | Mode: "..(S.dredge and "DREDGE" or "FARM")..
                "\nPhase: "..tostring(S.diagPhase or "Idle")..
                "\nAction: "..action.." ("..age..")"..
                "\nSelected: "..tostring(S.getSelectedZone())..
                "\nLoaded: "..tostring(S.dredgeAt or S.activeZone or "none")..
                "\nPan: "..tostring(pan and pan.tool.Name or "NOT EQUIPPED")..
                "\nFill: "..tostring(pan and fill(pan) or "N/A")..
                    " / "..tostring(S.capacity() or "N/A")..
                "\nDistance: dig "..d(S.dig).." | water "..d(S.water)..
                "\nHP: "..tostring(hp and math.floor(hp.Health) or "N/A")..
                "\nLast Collect: "..tostring(S.diagLastCollectMs or "N/A").." ms"..
                "\nLuck cap: "..tostring(S.dredgeAppliedCap or "N/A")..
                "\nState unchanged: "..string.format("%.1fs",idleFor)..
                "\nLast failure: "..tostring(S.diagLastFailure or "None"):sub(1,85)
            S.liveInfo.Text=S.liveDebugError and
                ("FILE ERROR: "..S.liveDebugError):sub(1,125) or
                "Saving snapshots every 2s active / 8s idle"
        end
        if reforgePage.Visible then
            local item=heldReforgeItem()
            S.reforgeEquipped.Text="Held item: "..(item and item.Name or "none / not reforgeable")
        end
        if diagnosticPage.Visible then
            local r=root()
            local pos=r and r.Position
            S.zoneLiveInfo.Text="Current deposit: "..tostring(zone())..
                "\nCharacter: "..(pos and string.format("%.1f, %.1f, %.1f",pos.X,pos.Y,pos.Z) or "not spawned")..
                "\nLoaded farm zone: "..tostring(S.activeZone or "none")
        end
        if dredgePage.Visible then
            dredgeWorkLabel.Text="NOW: "..tostring(S.dredgeCurrentWork or "Idle")..
                "\nNEXT: "..tostring(S.dredgeNextWork or "Awaiting plan")
            local quest=getQuest()
            if quest then
                local progress={}
                local data=quest.StepProgress
                if type(data)=="table" then
                    for _,v in pairs(data) do
                        if type(v)=="table" then
                            if v.Talk=="DredgeMaster" then
                                progress[#progress+1]="Talk to Dredge Master (turn-in)"
                            elseif type(v.Collect)=="string" then
                                progress[#progress+1]=v.Collect..": "..
                                    tostring(v.Progress or 0).."/"..tostring(v.Amount or "?")
                            end
                        end
                    end
                end
                table.sort(progress)
                dredgeObjectiveLabel.Text=#progress>0 and
                    ("QUEST OBJECTIVES\n"..table.concat(progress,"\n"))
                    or "Quest data found; objectives not available"
            else
                dredgeObjectiveLabel.Text="Quest data not yet available"
            end
        end
        task.wait(1)
    end
end)

show=function(t)
    if S.alive then
        status.Text=t
        if S.diagPhase~=t then
            S.diagPhase=t
            S.diagPhaseStartedAt=os.clock()
            S.tracePhaseNextStallAt=S.diagPhaseStartedAt+4
            S.diagEvent("PHASE",t)
        end
    end
end
-- Diagnostic-only stall checks. Does not change farming timing or state.
task.spawn(function()
    while S.alive do
        task.wait(.5)
        if S.running and S.actionTraceEnabled then
            local now=os.clock()
            local stage=S.traceCurrentAction
            local since=stage and S.traceActionStartedAt or S.diagPhaseStartedAt
            local due=stage and S.traceNextStallAt or S.tracePhaseNextStallAt
            if since and due and now>=due then
                S.diagEvent("STALL",string.format("action=%s elapsed=%.2fs | %s",
                    tostring(stage or S.diagPhase or "unknown"),
                    now-since,S.diagSnapshot()))
                if stage then S.traceNextStallAt=now+6
                else S.tracePhaseNextStallAt=now+6 end
            end
            local work=tostring(S.dredgeCurrentWork or "")
            if S.dredge and S.traceLastDredgeWork~=work then
                S.traceLastDredgeWork=work
                S.diagEvent("DREDGE_TASK",work)
            end
        end
    end
end)
bind(S.antiAfkButton.MouseButton1Click,function()
    S.antiAfk=not S.antiAfk
    S.antiAfkButton.Text="ANTI-AFK: "..(S.antiAfk and "ON" or "OFF")
    S.diagEvent("ANTI_AFK_TOGGLE",S.antiAfk and "ON" or "OFF")
end)
bind(S.turboButton.MouseButton1Click,function()
    S.turbo=not S.turbo
    S.turboButton.Text="TURBO: "..(S.turbo and "ON" or "OFF")
    S.diagEvent("TURBO_TOGGLE",tostring(S.turbo))
end)
bind(S.doubleShakeButton.MouseButton1Click,function()
    S.doubleShake=not S.doubleShake
    S.doubleShakeButton.Text="DOUBLE SHAKE: "..(S.doubleShake and "ON" or "OFF")
    S.diagEvent("DOUBLE_SHAKE_TOGGLE",tostring(S.doubleShake))
end)
bind(S.actionTraceButton.MouseButton1Click,function()
    if S.actionTraceEnabled then S.traceAction("TRACE_DISABLED","Disabled in GUI") end
    S.actionTraceEnabled=not S.actionTraceEnabled
    S.actionTraceButton.Text="ACTION TRACE: "..(S.actionTraceEnabled and "ON" or "OFF")
    if S.actionTraceEnabled then S.traceAction("TRACE_RESUMED","Enabled in GUI") end
end)
-- Idle signal only: no per-frame input, no extra farming calls.
-- bind() tracks the connection so closing/reloading Beta disconnects it.
bind(P.Idled,function()
    if not S.alive or not S.antiAfk then return end
    local ok,err=pcall(function()
        local virtualUser=game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new(0,0))
    end)
    if ok then
        S.antiAfkLastAt=os.date("%Y-%m-%d %H:%M:%S")
        S.diagEvent("ANTI_AFK_TRIGGERED","virtual right-click")
    else
        S.diagEvent("ANTI_AFK_FAILED",tostring(err))
        outputWarning("anti-afk","[GALAXIS HUB BETA] Anti-AFK unavailable:",err)
    end
end)
bind(S.debugReportButton.MouseButton1Click,function()
    S.diagEvent("USER_EXPORT",S.diagSnapshot())
    local report=S.diagReport()
    local saved,copied=false,false
    if type(writefile)=="function" then
        saved=pcall(writefile,"GalaxisHub_DebugReport.txt",report)
    end
    if type(setclipboard)=="function" then copied=pcall(setclipboard,report) end
    show("Debug "..(copied and "COPIED" or "not copied")..
        " | TXT "..(saved and "saved" or "unavailable"))
end)
      function xyz(cf)
    local p=cf.Position
    return string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
end
task.spawn(function()
    while S.alive do
        local currentPan=S.cycles+(S.running and 1 or 0)
        local collected=L.minerals+#L.pending
        local avg=S.cycles>0 and string.format("%.2fs",S.totalCycleTime/S.cycles) or "--"
        statsFooter.Text=string.format("Pan: %d  |  Minerals: %d  |  Avg: %s",currentPan,collected,avg)
        if S.running and os.clock()-(S.diagSampleAt or 0)>=1 then
            S.diagSampleAt=os.clock()
            S.diagEvent("SAMPLE",S.diagSnapshot())
        end
        task.wait(.25)
    end
end)

stop=function()
    if not S.alive then return end
    S.diagEvent("STOP",S.diagSnapshot())
    S.traceCurrentAction=nil
    S.traceActionStartedAt=nil
    local hadDredge=S.dredge
    -- Remember where we physically stopped. The return path to the Dredge
    -- Master must still know its departure zone after OFF -> ON.
    if hadDredge and S.dredgeAt then
        S.dredgeResumeZone=S.dredgeAt
        S.diagEvent("DREDGE_RESUME_SAVED",S.dredgeResumeZone)
    end
    S.dredge=false;S.dredgeCurrent=nil;S.dredgeGroup=nil
    S.dredgeAt=nil;S.dredgeRiskZone=false
    if hadDredge and S.dredgeAppliedCap~="NONE" then
        local rem=RS:FindFirstChild("Remotes")
        local setting=rem and rem:FindFirstChild("Settings")
        local change=setting and setting:FindFirstChild("ChangeSetting")
        if change and change:IsA("RemoteEvent") then
            pcall(function() change:FireServer("MaximumLuck","None") end)
        end
    end
    S.dredgeAppliedCap="UNSET";S.dredgeUncappedLuck=nil
    S.dredgeServerStatus=nil;S.dredgeServerProgress=nil
    S.dredgeCapLockedZone=nil;S.dredgeCapLockedKey=nil
    S.dredgePlanLuck=nil;S.dredgePlanCapacity=nil
        S.dredgePlannedRemaining=nil
    if hadDredge and S.dredgeRestore then
        S.dig=S.dredgeRestore.dig;S.water=S.dredgeRestore.water
        S.activeZone=S.dredgeRestore.zone
        digB.Text=S.dig and "DIG SAVED" or "SET DIG"
        waterB.Text=S.water and "WATER SAVED" or "SET WATER"
        digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
        waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
        S.dredgeRestore=nil
    end
    if dredgeButton then dredgeButton.Text="AUTO DREDGE: OFF" end
    -- This invalidates all current farm cycles and pending recovery retries.
    S.running=false;S.token+=1;S.waiting=false
    S.sellQueue={}
    if S.completion then S.completion:Disconnect();S.completion=nil end
    farmB.Text="AUTO FARM: OFF"
    finishBatch()
    show("Stopped")
end
      function close()
    if not S.alive then return end
    stop()
    stopLogger()
    S.traceAction("TRACE_CLOSE","Hub closing; remaining trace will flush")
    S.liveDebugRecord("CLOSE",S.liveDebugDetails())
    S.flushLiveDebug()
    S.alive=false
    if perfConnection then perfConnection:Disconnect();perfConnection=nil end
    for _,c in ipairs(S.links) do pcall(function() c:Disconnect() end) end
    G:Destroy()
    if E.CoastalSafeFarm==S then E.CoastalSafeFarm=nil end
    if E.StopUniversalLogger==stopLogger then E.StopUniversalLogger=nil end
end
S.Stop=stop;S.Close=close
