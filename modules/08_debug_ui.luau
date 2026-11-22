-- Galaxis module: 08_debug_ui.luau
-- Loaded by beta.luau into the shared Galaxis environment.
S.liveTitle=label("LIVE DEBUG  /  DISABLED",14,9,312,26,12,FG)
relocate(S.liveTitle,livePage,14,9)
S.liveStatus=label("Automatic diagnostics are disabled.",14,42,312,222,11,FG)
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
S.liveInfo=label("Automatic logging disabled. Manual report export remains available.",14,385,312,25,10,MUTED)
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
-- Periodic diagnostic UI refresh removed.
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
-- Automatic stall-monitor task removed; no periodic diagnostics.
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
    S.actionTraceButton.Text="ACTION TRACE: OFF"
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
-- Periodic diagnostic sampling worker removed.
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
    S.running=false;S.treasureStandalone=false;S.token+=1;S.waiting=false
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
