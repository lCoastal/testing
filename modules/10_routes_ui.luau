-- Galaxis module: 10_routes_ui.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function applyZone()
    local name=S.getSelectedZone()
    local p=S.presets[name]
    S.dig=p and S.unpackCF(p.dig) or nil
    S.water=p and S.unpackCF(p.water) or nil
    S.activeZone=name
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    S.refreshPreset()
end
      function capture(key)
    if S.running then show("Turn AUTO FARM OFF before editing");return end
    local r=root()
    if not r then show("Character root unavailable");return end
    if S.activeZone~=S.getSelectedZone() then applyZone() end
    local name=S.getSelectedZone()
    S.presets[name]=S.presets[name] or {}
    local packed=S.packCF(r.CFrame)
    S.presets[name][key]=packed
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name][key]=packed
    if key=="dig" then S.dig=r.CFrame else S.water=r.CFrame end
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    S.refreshPreset()
    local ok,err=S.savePresets()
    show(ok and (name.." "..key.." saved") or ("Session only: "..tostring(err)))
end
bind(digB.MouseButton1Click,function() capture("dig") end)
bind(waterB.MouseButton1Click,function() capture("water") end)
bind(S.diagSaveDig.MouseButton1Click,function() capture("dig") end)
bind(S.diagSaveWater.MouseButton1Click,function() capture("water") end)
      function selectZone(i)
    S.selectedZone=(i-1)%#ZONE_NAMES+1
    local p=S.presets[S.getSelectedZone()]
    if p and p.waypoint and waypointIndex[p.waypoint] then
        S.selectedWaypoint=waypointIndex[p.waypoint]
    end
    S.refreshPreset()
    -- Selecting a deposit should also load its farming coordinates.
    -- Previously selection only changed the label, leaving S.dig/water
    -- pointed at the last loaded zone until LOAD ZONE was pressed.
    if not S.running then applyZone() end
    S.savePresets()
end
bind(prevZone.MouseButton1Click,function() selectZone(S.selectedZone-1) end)
bind(nextZone.MouseButton1Click,function() selectZone(S.selectedZone+1) end)
bind(S.diagPrevZone.MouseButton1Click,function() selectZone(S.selectedZone-1) end)
bind(S.diagNextZone.MouseButton1Click,function() selectZone(S.selectedZone+1) end)
bind(prevWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=(S.selectedWaypoint-2)%#WAYPOINT_NAMES+1
    S.refreshPreset()
    S.savePresets()
end)
bind(nextWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=S.selectedWaypoint%#WAYPOINT_NAMES+1
    S.refreshPreset()
    S.savePresets()
end)
-- Automatic route recorder: separate stone->deposit and deposit->stone
-- traces, sampled while the player walks. Never overwrites a preset until
-- STOP & SAVE is pressed. The user's saved JSON remains v2-compatible.
      function captureRoutePoint(rec,forceJump)
    if not rec or S.routeRecording~=rec then return end
    local rr=root()
    if not rr then return end
    local nodes=rec.nodes
    local last=nodes[#nodes] and S.unpackCF(nodes[#nodes])
    local moved=last and (rr.Position-last.Position).Magnitude or math.huge
    local turn=false
    if #nodes>=2 then
        local prev=S.unpackCF(nodes[#nodes-1])
        if prev and last and moved>=2 then
            local a=last.Position-prev.Position
            local b=rr.Position-last.Position
            if a.Magnitude>1 and b.Magnitude>1 then
                turn=a.Unit:Dot(b.Unit)<.8
            end
        end
    end
    if moved<4 and not forceJump and not turn then return end
    if #nodes>=500 then
        S.diagEvent("ROUTE_RECORD_LIMIT",rec.zone.." reached 500 points")
        return
    end
    nodes[#nodes+1]=S.packCF(rr.CFrame)
    if forceJump then
        rec.jumps[#rec.jumps+1]=#nodes
    end
end
      function stopRouteRecording(save)
    local rec=S.routeRecording
    if not rec then return end
    if rec.jumpConnection then rec.jumpConnection:Disconnect() end
    if save then captureRoutePoint(rec,false) end
    S.routeRecording=nil
    S.routeRecordButton.Text="START WALK RECORDING"
    if not save or #rec.nodes<2 then
        show("Recording discarded (need at least 2 positions)")
        S.refreshPreset()
        return
    end
    local key=rec.mode=="INBOUND" and "route" or "routeOut"
    local jumpKey=rec.mode=="INBOUND" and "routeJumps" or "routeOutJumps"
    S.presets[rec.zone]=S.presets[rec.zone] or {}
    S.overrides[rec.zone]=S.overrides[rec.zone] or {}
    S.presets[rec.zone][key]=rec.nodes
    S.overrides[rec.zone][key]=rec.nodes
    S.presets[rec.zone][jumpKey]=rec.jumps
    S.overrides[rec.zone][jumpKey]=rec.jumps
    local ok,err=S.savePresets()
    S.diagEvent("ROUTE_RECORDED",string.format(
        "%s %s points=%d jumps=%d saved=%s",
        rec.zone,rec.mode,#rec.nodes,#rec.jumps,tostring(ok)))
    S.refreshPreset()
    show(ok and string.format("Saved %s %s: %d points, %d jumps",
        rec.zone,rec.mode,#rec.nodes,#rec.jumps) or
        "Recorded in session only: "..tostring(err))
end
bind(S.routeModeButton.MouseButton1Click,function()
    if S.routeRecording then show("Stop recording before changing direction");return end
    S.routeMode=S.routeMode=="INBOUND" and "OUTBOUND" or "INBOUND"
    S.routeModeButton.Text=S.routeMode=="INBOUND"
        and "DIRECTION: TO DEPOSIT" or "DIRECTION: TO WAYPOINT"
end)
bind(S.routeRecordButton.MouseButton1Click,function()
    if S.routeRecording then stopRouteRecording(true);return end
    if S.running then show("Stop automation before recording");return end
    local rr=root()
    local name=S.getSelectedZone()
    local preset=S.presets[name]
    if not rr or not preset or not preset.waypoint then
        show("Select a mapped zone and spawn character first");return
    end
    local rec={zone=name,mode=S.routeMode,nodes={},jumps={}}
    S.routeRecording=rec
    captureRoutePoint(rec,false)
    local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        rec.jumpConnection=hum.StateChanged:Connect(function(_,state)
            if state==Enum.HumanoidStateType.Jumping then
                captureRoutePoint(rec,true)
            end
        end)
    end
    S.routeRecordButton.Text="STOP & SAVE RECORDING"
    show("Recording "..name.." "..S.routeMode.."; walk normally")
    S.diagEvent("ROUTE_RECORD_START",name.." "..S.routeMode)
    task.spawn(function()
        while S.alive and S.routeRecording==rec do
            captureRoutePoint(rec,false)
            task.wait(.12)
        end
    end)
end)
bind(S.addWalkPoint.MouseButton1Click,function()
    if S.running then show("Stop the farm before recording a route");return end
    local r=root()
    if not r then show("Character position unavailable");return end
    local name=S.getSelectedZone()
    local p=S.presets[name] or {}
    if not p.waypoint then show("Map this zone to a waypoint first");return end
    local key=S.routeMode=="INBOUND" and "route" or "routeOut"
    local nodes=p[key] or {}
    if #nodes>=500 then show("Maximum 500 route points");return end
    local previous=nodes[#nodes]
    local cf=S.packCF(r.CFrame)
    if previous then
        local last=S.unpackCF(previous)
        if last and (last.Position-r.Position).Magnitude<5 then
            show("Walk at least 5 studs before adding another point")
            return
        end
    end
    local newRoute={}
    for _,v in ipairs(nodes) do newRoute[#newRoute+1]=v end
    newRoute[#newRoute+1]=cf
    p[key]=newRoute
    S.presets[name]=p
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name][key]=newRoute
    local ok,err=S.savePresets()
    S.refreshPreset()
    show(ok and ("Saved walk point "..#newRoute.." for "..name) or
        ("Route saved only in session: "..tostring(err)))
end)
bind(S.clearWalkRoute.MouseButton1Click,function()
    if S.running then show("Stop the farm before changing routes");return end
    local name=S.getSelectedZone()
    S.presets[name]=S.presets[name] or {}
    local key=S.routeMode=="INBOUND" and "route" or "routeOut"
    local jumpKey=S.routeMode=="INBOUND" and "routeJumps" or "routeOutJumps"
    S.presets[name][key]={}
    S.presets[name][jumpKey]={}
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name][key]={}
    S.overrides[name][jumpKey]={}
    local ok,err=S.savePresets()
    S.refreshPreset()
    show(ok and ("Cleared walk route for "..name) or
        ("Cleared only in session: "..tostring(err)))
end)
bind(mapWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before editing mappings");return end
    local name,wp=S.getSelectedZone(),S.getSelectedWaypoint()
    S.presets[name]=S.presets[name] or {}
    S.presets[name].waypoint=wp
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name].waypoint=wp
    local ok,err=S.savePresets()
    S.refreshPreset()
    show(ok and (name.." -> "..wp) or ("Mapping session only: "..tostring(err)))
end)
bind(loadZone.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before loading");return end
    local name=S.getSelectedZone()
    local p=S.presets[name]
    if not p or not S.unpackCF(p.dig) or not S.unpackCF(p.water) then
        show("Save both positions for "..name)
        return
    end
    applyZone()
    show("Loaded "..name.." zone")
end)
bind(importLegacy.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before importing");return end
    local name,wp=S.getSelectedZone(),S.getSelectedWaypoint()
    local old=S.legacyWaypoints[wp]
    if not old or not (old.dig or old.water) then
        show("No legacy positions for "..wp);return
    end
    local existing=S.presets[name]
    if existing and (S.unpackCF(existing.dig) or S.unpackCF(existing.water)) then
        show("Zone already has positions; won't overwrite");return
    end
    local imported={dig=old.dig,water=old.water,waypoint=wp}
    S.presets[name]=mergePreset(S.presets[name],imported)
    S.overrides[name]=mergePreset(S.overrides[name],imported)
    local ok,err=S.savePresets()
    S.refreshPreset()
    show(ok and ("Imported old "..wp.." to "..name) or ("Imported in session: "..tostring(err)))
end)
bind(travelWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before traveling");return end
    local folder=S.waypointFolder()
    local r=root()
    if not folder or not r then show("Waypoints or character unavailable");return end
    local to=folder:FindFirstChild(S.getSelectedWaypoint())
    if not to then show("Selected waypoint not found");return end
    local from=S.closestWaypoint(folder,r.Position)
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


-- Export all zone mappings and full-precision coordinates as a shareable text report.
-- Includes all 21 in-game waypoint pivots for reference, but the warp remote uses Instances.
-- Export is ONLY triggered by clicking the button (never on every mineral).
function S.exportCFrame(cf)
    if typeof(cf)~="CFrame" then return "" end
    local parts={cf:GetComponents()}
    local out={}
    for i=1,#parts do out[i]=string.format("%.17g",parts[i]) end
    return table.concat(out,",")
end
function S.exportZoneCFrame(serialized)
    return S.exportCFrame(S.unpackCF(serialized))
end
bind(exportPresetButton.MouseButton1Click,function()
    local lines={
        "GALAXIS HUB ZONE PRESETS | VERSION 2",
        "Export: "..os.date("%Y-%m-%d %H:%M:%S"),
        "Note: Each CFrame is 12 comma-separated numbers (position + rotation).",
        "Route points are ordered from mapped stone to digging spot; reverse on return.",
        "An empty field means not configured. This is NOT a complete farming preset until both positions are saved.",
        "",
        "=== MINING ZONES (35) ===",
        "Zone\tMapped Waypoint\tDig CFrame\tWater CFrame\tRoute CFrames (stone -> dig)"
    }
    local mapped,complete=0,0
    for _,name in ipairs(ZONE_NAMES) do
        local p=S.presets[name] or {}
        local wp=p.waypoint or ""
        local dig,water=S.exportZoneCFrame(p.dig),S.exportZoneCFrame(p.water)
        local routeParts={}
        for _,point in ipairs(p.route or {}) do
            routeParts[#routeParts+1]=S.exportZoneCFrame(point)
        end
        if wp~="" then mapped+=1 end
        if dig~="" and water~="" then complete+=1 end
        lines[#lines+1]=table.concat({name,wp,dig,water,table.concat(routeParts," ; ")},"\t")
    end
    lines[#lines+1]=""
    lines[#lines+1]="=== FAST TRAVEL WAYPOINTS (21) ==="
    lines[#lines+1]="Waypoint\\tWorld CFrame"
    local folder=S.waypointFolder()
    for _,name in ipairs(WAYPOINT_NAMES) do
        local obj=folder and folder:FindFirstChild(name)
        local cf=obj and S.getWaypointCF(obj)
        lines[#lines+1]=name.."\t"..exportCFrame(cf)
    end
    lines[#lines+1]=""
    lines[#lines+1]=string.format("Summary: %d/35 mapped zones; %d/35 with dig+water positions.",
        mapped,complete)
    local contents=table.concat(lines,"\n")
    local saveOk=false
    if type(writefile)=="function" then
        saveOk=pcall(writefile,"GalaxisHub_PresetExport.txt",contents)
    end
    local copyOk=false
    if type(setclipboard)=="function" then
        copyOk=pcall(setclipboard,contents)
    end
    show(string.format("Exported %d mapped / %d complete; TXT: %s, copied: %s",
        mapped,complete,saveOk and "yes" or "no",copyOk and "yes" or "no"))
    if not saveOk and not copyOk then
        outputWarning("preset-export","[GALAXIS HUB] Preset export could not be saved or copied")
    end
end)

bind(ringButton.MouseButton1Click,function()
    S.dredgePurifying=not S.dredgePurifying
    ringButton.Text="PURIFYING RING: "..(S.dredgePurifying and "YES" or "NO")
    S.dredgeGroup=nil
    dredgeText(S.dredgePurifying and "Ring confirmation ON (must be equipped)" or "Fungal Marsh excluded")
end)
bind(riskButton.MouseButton1Click,function()
    S.dredgeRisk=not S.dredgeRisk
    riskButton.Text="RISKY ZONES: "..(S.dredgeRisk and "ON" or "OFF")
    S.dredgeGroup=nil
    dredgeText(S.dredgeRisk and "Rotwood + Abyssal allowed with HP retreat; risk remains" or "Rotwood and Abyssal excluded")
end)
bind(sellB.MouseButton1Click,function()
    if not S.sell and not getSell() then show("SellAll unavailable");return end
    S.sell=not S.sell
    sellB.Text="AUTO SELL: "..(S.sell and "ON" or "OFF")
end)
-- ON is a persistent user request. A transient farm failure does not turn
-- the toggle off: we re-resolve the equipped pan and retry quickly.