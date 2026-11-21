-- Galaxis module: 05_tabs.luau
-- Loaded by beta.luau into the shared Galaxis environment.
-- ===== COMPACT 5-TAB INTERFACE =====
-- The existing farm, Dredge and preset controls are the exact same objects
-- (and callbacks). Reparenting them keeps every existing function intact.
      function page()
    return make("Frame",{
        Position=UDim2.fromOffset(0,75),
        Size=UDim2.new(1,0,1,-75),
        BackgroundTransparency=1,
        Visible=false
    },Body)
end
      farmPage,dredgePage,diagnosticPage,treasurePage,reforgePage,livePage,packPage=page(),page(),page(),page(),page(),page(),page()
      TAB_NAMES={"FARM","DREDGE","ZONE","TREASURE","REFORGE","DEBUG","PACK"}
      TAB_PAGES={farmPage,dredgePage,diagnosticPage,treasurePage,reforgePage,livePage,packPage}
      tabButtons={}
for i,name in ipairs(TAB_NAMES) do
    tabButtons[i]=button(name,4+(i-1)*47,36,45,32,Body)
    tabButtons[i].TextSize=8
end
-- Show tabs and make them clickable before constructing the complex
-- diagnostic/reforge pages. A later setup error can no longer leave a
-- blank window with invisible tabs.
      function openTab(n)
    for i,pageFrame in ipairs(TAB_PAGES) do
        pageFrame.Visible=i==n
        tabButtons[i].BackgroundColor3=i==n and Color3.fromRGB(70,74,83) or PANEL
        tabButtons[i].TextColor3=i==n and FG or MUTED
    end
end
for i,tab in ipairs(tabButtons) do
    local index=i
    bind(tab.MouseButton1Click,function() openTab(index) end)
end
openTab(1)
      function relocate(widget,parent,x,y)
    widget.Parent=parent
    widget.Position=UDim2.fromOffset(x,y)
end

-- Auto Farm: retain manual digging/panning, selling, and footer.
relocate(digB,farmPage,14,20)
relocate(waterB,farmPage,177,20)
relocate(digXYZ,farmPage,14,61)
relocate(waterXYZ,farmPage,177,61)
relocate(sellB,farmPage,14,101)
relocate(farmB,farmPage,14,151)
relocate(statsFooter,farmPage,14,210)
S.farmInstructions=label("Save dig and water positions in your selected zone.",14,256,312,37,11,MUTED)
S.farmInstructions.TextWrapped=true
relocate(S.farmInstructions,farmPage,14,256)
-- Anti-AFK is independent of Auto Farm/Auto Dredge.
-- Toggle lives on Auto Farm page but applies globally while Hub is open.
S.antiAfkButton=button("ANTI-AFK: ON",14,313,312,36,farmPage)
S.actionTraceButton=button("ACTION TRACE: ON",14,355,312,30,farmPage)
S.actionTraceButton.TextSize=11
S.turboButton=button("TURBO: ON",14,253,149,36,farmPage)
S.doubleShakeButton=button("DOUBLE SHAKE: ON",177,253,149,36,farmPage)
relocate(S.farmInstructions,farmPage,14,295)
relocate(S.antiAfkButton,farmPage,14,341)
relocate(S.actionTraceButton,farmPage,14,383)
S.actionTraceButton.Size=UDim2.fromOffset(149,25)
S.newMineralLogButton=button("NEW LOG FILE",177,383,149,25,farmPage)
S.newMineralLogButton.TextSize=11
bind(S.newMineralLogButton.MouseButton1Click,function()
    if S.logRotateBusy then return end
    S.logRotateBusy=true
    local ok,fileOrError=S.switchToNewMineralLog()
    if ok then
        show("Mineral log changed: "..fileOrError)
    else
        show("New log FAILED: "..tostring(fileOrError):sub(1,95))
    end
    S.logRotateBusy=false
end)

-- Auto Dredge: objective readout, safety switches, and 100%-quality model.
relocate(dredgeButton,dredgePage,14,20)
dredgeButton.Size=UDim2.fromOffset(312,42)
relocate(ringButton,dredgePage,14,76)
relocate(riskButton,dredgePage,177,76)
relocate(fullQualityLabel,dredgePage,14,122)
relocate(dredgeStatus,dredgePage,14,154)
dredgeStatus.Size=UDim2.fromOffset(312,45)
dredgeStatus.TextWrapped=true
      dredgeObjectiveLabel=label("Reading Dredge objectives...",14,217,312,86,11,FG)
dredgeObjectiveLabel.TextWrapped=true
dredgeObjectiveLabel.TextYAlignment=Enum.TextYAlignment.Top
relocate(dredgeObjectiveLabel,dredgePage,14,217)
      dredgeWorkLabel=label("NOW: Idle\nNEXT: Waiting for quest",14,309,312,65,11,FG)
dredgeWorkLabel.TextWrapped=true
dredgeWorkLabel.TextYAlignment=Enum.TextYAlignment.Top
relocate(dredgeWorkLabel,dredgePage,14,309)
-- Idle / inaccessible-objective fallback mineral selector.
S.fallbackMineral="Emerald"
S.fallbackEnabled=false
S.fallbackTitle=label("FALLBACK MINERAL (WHEN NO QUEST / NO ELIGIBLE QUEST DROP)",14,382,312,25,10,MUTED)
S.fallbackTitle.TextWrapped=true
relocate(S.fallbackTitle,dredgePage,14,382)
S.fallbackInput=make("TextBox",{
    Position=UDim2.fromOffset(14,411),
    Size=UDim2.fromOffset(190,34),
    BackgroundColor3=PANEL,
    BorderSizePixel=0,
    TextColor3=FG,
    PlaceholderColor3=MUTED,
    PlaceholderText="Mineral name (e.g. Emerald)",
    Text=S.fallbackMineral,
    ClearTextOnFocus=false,
    Font=Enum.Font.Gotham,
    TextSize=11
},dredgePage)
S.fallbackToggle=button("FALLBACK: OFF",212,411,114,34,dredgePage)
S.fallbackToggle.TextSize=10
S.fallbackStatus=label("Uses saved routes; Dredge quests stay priority.",14,449,312,30,10,MUTED)
S.fallbackStatus.TextWrapped=true
bind(S.fallbackInput.FocusLost,function()
    local value=S.fallbackInput.Text:gsub("^%s+",""):gsub("%s+$","")
    if value~="" then
        S.fallbackMineral=value
        S.dredgeCurrent=nil;S.dredgeGroup=nil
        S.fallbackStatus.Text="Fallback target: "..value
    end
end)
bind(S.fallbackToggle.MouseButton1Click,function()
    S.fallbackEnabled=not S.fallbackEnabled
    S.fallbackToggle.Text="FALLBACK: "..(S.fallbackEnabled and "ON" or "OFF")
    S.fallbackToggle.BackgroundColor3=S.fallbackEnabled
        and Color3.fromRGB(45,105,67) or PANEL
    S.dredgeCurrent=nil;S.dredgeGroup=nil
    S.fallbackStatus.Text=S.fallbackEnabled
        and ("Will farm "..S.fallbackMineral.." when idle or quest drops are inaccessible.")
        or "Fallback disabled; normal Dredge behaviour."
end)

-- Auto-craft Firefly Flares: equip one Firefly Stone from BackpackTwo,
-- wait until it is actually held, then activate the existing FlareTable prompt.
S.autoFlareCraftEnabled=false
S.autoFlareCraftBusy=false
S.autoFlareCraftNext=0
S.autoFlareCraftButton=button("AUTO CRAFT FIREFLY FLARES: OFF",14,490,312,34,dredgePage)
S.autoFlareCraftButton.TextSize=10
S.autoFlareCraftStatus=label("Equips Firefly Stone, then crafts at the nearby Flare Table.",14,528,312,30,10,MUTED)
S.autoFlareCraftStatus.TextWrapped=true
bind(S.autoFlareCraftButton.MouseButton1Click,function()
    S.autoFlareCraftEnabled=not S.autoFlareCraftEnabled
    S.autoFlareCraftButton.Text="AUTO CRAFT FIREFLY FLARES: "..
        (S.autoFlareCraftEnabled and "ON" or "OFF")
    S.autoFlareCraftButton.BackgroundColor3=S.autoFlareCraftEnabled
        and Color3.fromRGB(45,105,67) or PANEL
    S.autoFlareCraftStatus.Text=S.autoFlareCraftEnabled
        and "Enabled: equips a Firefly Stone before every craft."
        or "Disabled."
    S.diagEvent("AUTO_FLARE_CRAFT_TOGGLE",tostring(S.autoFlareCraftEnabled))
end)
task.spawn(function()
    while S.alive do
        task.wait(.15)
        if S.autoFlareCraftEnabled and not S.autoFlareCraftBusy
            and os.clock()>=(S.autoFlareCraftNext or 0) then
            local map=workspace:FindFirstChild("Map")
            local lush=map and map:FindFirstChild("LushCaverns")
            local abyss= lush and lush:FindFirstChild("AbyssAssets")
            local tableModel=abyss and abyss:FindFirstChild("FlareTable")
            local prompt=tableModel and tableModel:FindFirstChild("Prompt")
            local rr=root()
            local pos
            if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local part=prompt.Parent
                if part and part:IsA("BasePart") then pos=part.Position
                elseif tableModel and tableModel:IsA("Model") then pos=tableModel:GetPivot().Position end
            end
            local maxDistance=prompt and (prompt.MaxActivationDistance or 10) or 10
            if prompt and pos and rr and (rr.Position-pos).Magnitude<=math.min(maxDistance,10) then
                S.autoFlareCraftBusy=true
                S.autoFlareCraftNext=os.clock()+.35
                local ok,err=pcall(function()
                    local backpack=P:FindFirstChild("BackpackTwo")
                    local stone=backpack and backpack:FindFirstChild("Firefly Stone")
                    if not stone then
                        local character=P.Character
                        stone=character and character:FindFirstChild("Firefly Stone")
                    end
                    if not stone then
                        S.autoFlareCraftStatus.Text="No Firefly Stone in BackpackTwo."
                        S.diagEvent("AUTO_FLARE_NO_STONE","Firefly Stone not found")
                        return
                    end
                    local remotes=RS:FindFirstChild("Remotes")
                    local custom=remotes and remotes:FindFirstChild("CustomBackpack")
                    local equip=custom and custom:FindFirstChild("EquipRemote")
                    if not equip or not equip:IsA("RemoteEvent") then
                        error("CustomBackpack.EquipRemote unavailable")
                    end
                    local character=P.Character
                    if not character or stone.Parent~=character then
                        S.autoFlareCraftStatus.Text="Equipping Firefly Stone..."
                        equip:FireServer(stone)
                        local deadline=os.clock()+1.25
                        repeat
                            task.wait(.05)
                            character=P.Character
                        until not S.alive or (character and character:FindFirstChild("Firefly Stone"))
                            or os.clock()>=deadline
                        stone=character and character:FindFirstChild("Firefly Stone")
                    end
                    if not stone then
                        S.autoFlareCraftStatus.Text="Firefly Stone equip did not complete."
                        S.diagEvent("AUTO_FLARE_EQUIP_FAILED","Stone not found in Character")
                        return
                    end
                    -- Recheck range and prompt immediately before crafting.
                    rr=root()
                    if not rr or (rr.Position-pos).Magnitude>math.min(maxDistance,10) then
                        S.autoFlareCraftStatus.Text="Moved out of Flare Table range."
                        return
                    end
                    S.autoFlareCraftStatus.Text="Crafting with equipped Firefly Stone..."
                    if type(fireproximityprompt)=="function" then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(math.max(prompt.HoldDuration,.5)+.05)
                        prompt:InputHoldEnd()
                    end
                    S.autoFlareCraftStatus.Text="Craft prompt sent. Checking again shortly."
                    S.diagEvent("AUTO_FLARE_CRAFT_SENT","Equipped Firefly Stone; prompt activated")
                end)
                if not ok then
                    S.autoFlareCraftStatus.Text="Auto craft error: "..tostring(err):sub(1,90)
                    S.diagEvent("AUTO_FLARE_CRAFT_ERROR",tostring(err))
                end
                S.autoFlareCraftBusy=false
                S.autoFlareCraftNext=os.clock()+.35
            end
        end
    end
end)

function S.getFallbackWants()
    if not S.fallbackEnabled then return nil end
    local target=tostring(S.fallbackMineral or ""):lower()
    if target=="" then return nil end
    for _,zone in ipairs(ALL_ZONES) do
        for _,drop in ipairs(poolFor(zone)) do
            if tostring(drop[1]):lower()==target then
                return {{m=drop[1],n=1}}
            end
        end
    end
    return nil
end

-- Zone Diagnostic: concise by default. All legacy preset controls retained
-- in a hidden, scrollable editor rather than deleted.
S.zoneDiagTitle=label("ZONE DIAGNOSTIC",14,9,312,21,12,FG)
relocate(S.zoneDiagTitle,diagnosticPage,14,9)
S.zoneLiveInfo=label("Reading live deposit...",14,35,312,67,11,MUTED)
S.zoneLiveInfo.TextWrapped=true
S.zoneLiveInfo.TextYAlignment=Enum.TextYAlignment.Top
relocate(S.zoneLiveInfo,diagnosticPage,14,35)

-- Direct zone-selection and position capture; no need to open the editor.
S.diagZoneHeading=label("SAVE POSITIONS FOR ZONE",14,108,312,22,10,MUTED)
relocate(S.diagZoneHeading,diagnosticPage,14,108)
S.diagPrevZone=button("<",14,134,36,32,diagnosticPage)
diagZoneName=label(S.getSelectedZone(),56,134,228,32,12,FG)
diagZoneName.TextXAlignment=Enum.TextXAlignment.Center
diagZoneName.Font=Enum.Font.GothamMedium
relocate(diagZoneName,diagnosticPage,56,134)
S.diagNextZone=button(">",290,134,36,32,diagnosticPage)
S.diagSaveDig=button("SET DIG HERE",14,176,149,36,diagnosticPage)
S.diagSaveWater=button("SET WATER HERE",177,176,149,36,diagnosticPage)
diagSavedStatus=label("",14,218,312,32,11,MUTED)
relocate(diagSavedStatus,diagnosticPage,14,218)
S.debugReportButton=button("COPY DEBUG REPORT",14,252,312,28,diagnosticPage)
S.debugReportButton.TextSize=11
S.editPresets=button("EDIT ZONE PRESETS / WALK ROUTES",14,284,312,36,diagnosticPage)
S.refreshPreset()
S.presetEditor=make("ScrollingFrame",{
    Position=UDim2.fromOffset(10,170),
    Size=UDim2.new(1,-20,1,-181),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    CanvasSize=UDim2.fromOffset(0,680),
    ScrollBarThickness=5,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    Visible=false
},diagnosticPage)
relocate(zoneTitle,S.presetEditor,4,5)
relocate(prevZone,S.presetEditor,4,27)
relocate(zoneName,S.presetEditor,46,27)
relocate(nextZone,S.presetEditor,280,27)
relocate(warpTitle,S.presetEditor,4,67)
relocate(prevWaypoint,S.presetEditor,4,89)
relocate(waypointName,S.presetEditor,46,89)
relocate(nextWaypoint,S.presetEditor,280,89)
relocate(loadZone,S.presetEditor,4,133)
relocate(mapWaypoint,S.presetEditor,167,133)
relocate(travelWaypoint,S.presetEditor,4,176)
relocate(importLegacy,S.presetEditor,167,176)
relocate(presetStatus,S.presetEditor,4,220)
relocate(presetHint,S.presetEditor,4,249)
relocate(exportPresetButton,S.presetEditor,4,286)
-- Fit inherited button positions into the 320 px-wide scroll panel.
loadZone.Size=UDim2.fromOffset(149,36)
mapWaypoint.Size=UDim2.fromOffset(149,36)
travelWaypoint.Size=UDim2.fromOffset(149,36)
importLegacy.Size=UDim2.fromOffset(149,36)
exportPresetButton.Size=UDim2.fromOffset(312,35)
S.morePresetHelp=label(
    "Controls preserved for editing, importing, exporting and traveling.",
    4,334,300,40,10,MUTED)
S.morePresetHelp.TextWrapped=true
relocate(S.morePresetHelp,S.presetEditor,4,334)
S.addWalkPoint=button("ADD WALK POINT",4,382,149,34,S.presetEditor)
S.clearWalkRoute=button("CLEAR SELECTED ROUTE",167,382,149,34,S.presetEditor)
routeCountLabel=label("Inbound 0 | Outbound 0",4,425,306,38,10,MUTED)
routeCountLabel.TextWrapped=true
relocate(routeCountLabel,S.presetEditor,4,425)
S.routeMode="INBOUND"
S.routeModeButton=button("DIRECTION: TO DEPOSIT",4,465,312,34,S.presetEditor)
S.routeRecordButton=button("START WALK RECORDING",4,507,312,36,S.presetEditor)
S.refreshPreset()
S.editPresets.MouseButton1Click:Connect(function()
    S.presetEditor.Visible=not S.presetEditor.Visible
    local showMain=not S.presetEditor.Visible
    for _,control in ipairs({S.zoneLiveInfo,S.zoneDiagTitle,S.diagZoneHeading,
        S.diagPrevZone,diagZoneName,S.diagNextZone,S.diagSaveDig,S.diagSaveWater,diagSavedStatus,
        S.debugReportButton}) do
        control.Visible=showMain
    end
    S.editPresets.Text=S.presetEditor.Visible and "CLOSE PRESET EDITOR" or "EDIT ZONE PRESETS / WALK ROUTES"
    S.editPresets.Position=UDim2.fromOffset(14,S.presetEditor.Visible and 12 or 284)
    S.presetEditor.Position=UDim2.fromOffset(10,S.presetEditor.Visible and 61 or 170)
    S.presetEditor.Size=UDim2.new(1,-20,1,S.presetEditor.Visible and -70 or -181)
end)

-- Treasure maps intentionally have no automation yet.
S.treasureTitle=label("AUTO TREASURE MAP",14,23,312,32,13,FG)
relocate(S.treasureTitle,treasurePage,14,23)
S.treasureNote=label(
    "Coming later. No treasure map remotes are being fired.",
    14,70,312,62,12,MUTED)
S.treasureNote.TextWrapped=true
relocate(S.treasureNote,treasurePage,14,70)
