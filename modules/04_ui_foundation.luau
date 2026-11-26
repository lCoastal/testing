-- Galaxis module: 04_ui_foundation.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function clearOldBetaGui(container)
    if not container then return end
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA("ScreenGui") and child.Name=="GalaxisHubBeta" then
            pcall(function() child:Destroy() end)
        end
    end
end
clearOldBetaGui(P:FindFirstChild("PlayerGui"))
if type(gethui)=="function" then
    local ok,container=pcall(gethui)
    if ok then clearOldBetaGui(container) end
end
-- Minimal monochrome UI
      G=Instance.new("ScreenGui")
G.Name="GalaxisHubBeta";G.ResetOnSpawn=false;G.DisplayOrder=9999
      parent=P:WaitForChild("PlayerGui")
if type(gethui)=="function" then
    local ok,v=pcall(gethui)
    if ok and v then parent=v end
end
G.Parent=parent
S.Gui=G
      BG=Color3.fromRGB(20,26,34)
      PANEL=Color3.fromRGB(40,51,63)
      FG=Color3.fromRGB(237,237,241)
      MUTED=Color3.fromRGB(174,189,201)
      function make(class,props,par)
    local o=Instance.new(class)
    if o:IsA("TextLabel") or o:IsA("TextButton") then
        o.TextTruncate=Enum.TextTruncate.AtEnd
        o.ClipsDescendants=true
    elseif o:IsA("TextBox") then
        o.ClipsDescendants=true
    end
    for k,v in pairs(props) do o[k]=v end
    o.Parent=par
    return o
end
      function rounded(o)
    make("UICorner",{CornerRadius=UDim.new(0,7)},o)
    return o
end
      W=rounded(make("Frame",{
    Size=UDim2.fromOffset(340,540),
    Position=UDim2.new(.5,-170,.5,-270),
    BackgroundColor3=BG,BorderSizePixel=0,Active=true,ClipsDescendants=true
},G))
make("UIStroke",{Color=Color3.fromRGB(64,81,94),Thickness=1},W)
      H=make("Frame",{Size=UDim2.new(1,0,0,43),BackgroundTransparency=1,Active=true},W)
make("TextLabel",{
    Position=UDim2.fromOffset(14,0),Size=UDim2.fromOffset(245,43),
    BackgroundTransparency=1,Text="Galaxis Hub   /   Beta",
    TextColor3=FG,Font=Enum.Font.GothamBold,TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left
},H)
      function button(txt,x,y,w,h,par)
    return rounded(make("TextButton",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundColor3=PANEL,BorderSizePixel=0,Text=txt,
        TextColor3=FG,Font=Enum.Font.GothamMedium,TextSize=12,AutoButtonColor=true
    },par or W))
end
      X=button("×",302,7,29,29,H)
      Min=button("−",269,7,29,29,H)
X.Position=UDim2.new(1,-38,0,7)
Min.Position=UDim2.new(1,-71,0,7)
-- Install a working close button BEFORE any later UI setup can fail.
-- When initialization finishes, S.Close performs normal cleanup.
bind(X.MouseButton1Click,function()
    if S.Close then
        S.Close()
        return
    end
    S.alive=false
    S.running=false
    S.token+=1
    L.running=false
    for _,connection in ipairs(S.links) do
        pcall(function() connection:Disconnect() end)
    end
    pcall(function() G:Destroy() end)
    if E.CoastalSafeFarm==S then E.CoastalSafeFarm=nil end
    if E.StopUniversalLogger then pcall(E.StopUniversalLogger) end
end)
      Body=make("Frame",{Position=UDim2.fromOffset(0,43),Size=UDim2.new(1,0,1,-43),BackgroundTransparency=1},W)
      function label(txt,x,y,w,h,size,color)
    return make("TextLabel",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundTransparency=1,Text=txt,TextColor3=color or FG,
        Font=Enum.Font.Gotham,TextSize=size or 11,TextXAlignment=Enum.TextXAlignment.Left
    },Body)
end
      status=label("Idle",14,1,312,33,12,MUTED)
status.TextWrapped=true
      digB=button("SET DIG",14,38,149,36,Body)
      waterB=button("SET WATER",177,38,149,36,Body)
      digXYZ=label("Not saved",14,78,149,22,10,MUTED)
      waterXYZ=label("Not saved",177,78,149,22,10,MUTED)
digXYZ.TextXAlignment=Enum.TextXAlignment.Center
waterXYZ.TextXAlignment=Enum.TextXAlignment.Center
      sellB=button("AUTO SELL: ON",14,110,312,36,Body)
      farmB=button("AUTO FARM: OFF",14,157,312,40,Body)
-- Compact footer: the only stats shown are current pan, total minerals, and average time.
      statsFooter=label("Pan: 0 | Minerals: 0 | Avg: --",14,213,312,27,12,FG)
statsFooter.Font=Enum.Font.GothamBold

-- Zone and waypoint selectors are separate: one warp may serve multiple deposits.
      zoneTitle=label("MINING ZONE",14,247,312,18,10,MUTED)
      prevZone=button("<",14,271,36,32,Body)
      zoneName=label("",56,271,228,32,12,FG)
zoneName.TextXAlignment=Enum.TextXAlignment.Center
zoneName.Font=Enum.Font.GothamMedium
      nextZone=button(">",290,271,36,32,Body)

      warpTitle=label("FAST TRAVEL WAYPOINT",14,312,312,18,10,MUTED)
      prevWaypoint=button("<",14,335,36,32,Body)
      waypointName=label("",56,335,228,32,12,FG)
waypointName.TextXAlignment=Enum.TextXAlignment.Center
waypointName.Font=Enum.Font.GothamMedium
      nextWaypoint=button(">",290,335,36,32,Body)
      loadZone=button("LOAD ZONE",14,380,149,36,Body)
      mapWaypoint=button("MAP TO WAYPOINT",177,380,149,36,Body)
      travelWaypoint=button("FAST TRAVEL",14,423,149,36,Body)
      importLegacy=button("IMPORT OLD WP",177,423,149,36,Body)
      presetStatus=label("",14,466,312,21,11,MUTED)
      presetHint=label("SET DIG / WATER saves to MINING ZONE",14,491,312,19,10,MUTED)
      exportPresetButton=button("EXPORT PRESETS TO TXT + CLIPBOARD",14,519,312,35,Body)
dredgeButton=button("AUTO DREDGE: OFF",14,563,312,35,Body)
      ringButton=button("PURIFYING RING: NO",14,606,149,32,Body)
      riskButton=button("RISKY ZONES: OFF",177,606,149,32,Body)
      fullQualityLabel=label("PAN QUALITY: 100%  |  LUCK: FULL (1x)",14,647,312,32,11,FG)
dredgeStatus=label("Dredge idle",14,684,312,22,11,MUTED)
dredgeStatus.TextTruncate=Enum.TextTruncate.AtEnd
function S.getSelectedZone() return ZONE_NAMES[S.selectedZone] end
function S.getSelectedWaypoint() return WAYPOINT_NAMES[S.selectedWaypoint] end
routeCountLabel,diagZoneName,diagSavedStatus=nil,nil,nil
function S.refreshPreset()
    local name=S.getSelectedZone()
    local p=S.presets[name]
    zoneName.Text=name
    waypointName.Text=S.getSelectedWaypoint()
    local mapping=p and p.waypoint or nil
    presetStatus.Text=((p and S.unpackCF(p.dig)) and "Dig saved" or "Dig missing")..
        " | "..((p and S.unpackCF(p.water)) and "Water saved" or "Water missing")..
        (mapping and (" | WP: "..mapping) or " | WP: NOT MAPPED")
    if routeCountLabel then
        routeCountLabel.Text="Inbound "..tostring(p and p.route and #p.route or 0)..
            " | Outbound "..tostring(p and p.routeOut and #p.routeOut or 0)..
            " pts | "..tostring(S.routeRecording and "RECORDING" or "idle")
    end
    if diagZoneName then diagZoneName.Text=name end
    if diagSavedStatus then
        diagSavedStatus.Text=((p and S.unpackCF(p.dig)) and "DIG: SAVED" or "DIG: NOT SAVED")..
            "    |    "..((p and S.unpackCF(p.water)) and "WATER: SAVED" or "WATER: NOT SAVED")
    end
    -- Only explicit MAP TO WAYPOINT commits the selector to this zone.
end
S.refreshPreset()
