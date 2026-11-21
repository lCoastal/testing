-- Galaxis module: 12_treasure.luau
-- Treasure automation. Runs only after a completed pan cycle.
for _,k in ipairs({"treasureTitle","treasureStatus","treasureToggle","treasureScanButton","treasureOutput"}) do
    if S[k] then pcall(function() S[k]:Destroy() end) end
end
S.treasureEnabled=S.treasureEnabled==true
S.treasureBusy=false
S.treasureCompleted=S.treasureCompleted or {}
S.treasureAttempted=S.treasureAttempted or {}
S.treasureLastError=nil

S.treasureTitle=label("AUTO TREASURE ROUTE",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("OFF | Starts after a completed pan when 2+ maps are held.",14,39,312,38,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureToggle=button("AUTO TREASURE: OFF",14,82,312,36,treasurePage)
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
                    out[#out+1]={tool=tool,pos=pos,region=region,guid=tostring(guid or tool:GetDebugId())}
                end
            end
        end
    end
    return out
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
local function tSort(list,origin)
    local left,ordered=table.clone(list),{}
    local at=origin
    while #left>0 do
        local best,dist=1,math.huge
        for i,m in ipairs(left) do
            local d=(at-m.pos).Magnitude
            if d<dist then best,dist=i,d end
        end
        local m=table.remove(left,best)
        ordered[#ordered+1]=m
        at=m.pos
    end
    return ordered
end
-- Treasure collection is coordinate-driven: the map's Location is the
-- destination. Do not resolve warp stones or invoke zone-routing helpers.
local function tRestore(cp,id)
    if not cp.dig then return false,"Original farming dig position was not saved" end
    tStatus("Running back to the saved farming position")
    local ok,why=walkRoute(cp.dig,id,10000)
    if not ok then return false,"Could not run back to saved dig position: "..tostring(why) end
    if not stableAt(cp.dig,id,12,.45,3) then
        return false,"Could not settle at saved farming position"
    end
    S.dig,S.water=cp.dig,cp.water
    S.activeZone,S.dredgeAt=cp.zone,cp.dredgeAt
    return true
end

local function tRun(id)
    if S.treasureBusy or not S.treasureEnabled or not valid(id) then return end
    local list=tMaps()
    if #list<2 then return end
    S.treasureBusy=true
    local cp={dig=S.dig,water=S.water,zone=S.dredge and S.dredgeAt or S.activeZone,dredgeAt=S.dredgeAt}
    local oldSell=S.sell
    local ordered=tSort(list,root() and root().Position or Vector3.zero)
    local ok,err=true,nil
    S.sell=false
    S.diagEvent("TREASURE_ROUTE_START","maps="..#ordered)

    for i,m in ipairs(ordered) do
        if not valid(id) or not S.treasureEnabled then ok,err=false,"Stopped by user";break end
        if not m.tool.Parent or S.treasureCompleted[m.guid] or S.treasureAttempted[m.guid] then continue end
        -- The map's exact Location is the only destination; no zone/stone routing.
        S.treasureAttempted[m.guid]=true
        tStatus(string.format("Map %d/%d | running directly to map coordinates in %s",i,#ordered,m.region))
        local target=CFrame.new(m.pos)
        -- Map destinations are approached on foot as well; no CFrame move/teleport.
        local walked,walkWhy=walkRoute(target,id,10000)
        if not walked or not stableAt(target,id,12,.45,3) then
            ok,err=false,"Could not run to map destination: "..tostring(walkWhy);break
        end
        local pan=panTool() or S.panInBackpack()
        if not pan or not requirePanEquipped(pan,id) then
            ok,err=false,"Could not equip pan at treasure location";break
        end
        local before=tChestCount()
        S.diagEvent("TREASURE_DIG_ONCE",m.region.." | "..tostring(m.pos))
        local sent,response,why=invoke(pan.dig,id,1)
        if not sent then ok,err=false,"Dig request failed: "..tostring(why);break end
        local found=false
        local deadline=os.clock()+15
        while valid(id) and os.clock()<deadline do
            if tChestCount()>before then found=true;break end
            task.wait(.15)
        end
        if not found then
            ok,err=false,"Dig sent once; chest not verified. This map will not be dug again automatically."
            break
        end
        S.treasureCompleted[m.guid]=true
        S.diagEvent("TREASURE_CHEST_CONFIRMED",m.region.." | "..m.guid)
        tStatus(string.format("Chest collected %d/%d | %s",i,#ordered,m.region))
    end

    local returned,why=tRestore(cp,id)
    if not returned then ok,err=false,(err and err.."; " or "").."RETURN FAILED: "..tostring(why) end
    S.sell=oldSell
    S.treasureBusy=false
    if ok then
        S.diagEvent("TREASURE_ROUTE_COMPLETE","maps="..#ordered)
        tStatus("Treasure route complete. Returned to saved farming location.")
    else
        S.treasureLastError=tostring(err)
        S.diagEvent("TREASURE_ROUTE_FAILED",S.treasureLastError)
        tStatus("Treasure stopped: "..S.treasureLastError)
    end
end

-- Hook called by 09_farming after a complete dig/pan/shake cycle.
S.treasureCycle=function(id,r)
    if not S.treasureEnabled or S.treasureBusy or not valid(id) then return end
    local n=#tMaps()
    if n<2 then tStatus("AUTO ON | Waiting for maps ("..n.."/2)");return end
    local ok,err=pcall(tRun,id)
    if not ok then
        S.treasureBusy=false
        S.treasureLastError=tostring(err)
        tStatus("Treasure error: "..S.treasureLastError)
        S.diagEvent("TREASURE_RUNTIME_ERROR",S.treasureLastError)
    end
end
local function tScan()
    local list=tMaps()
    local lines={"GALAXIS TREASURE MAPS","Found: "..#list,""}
    for i,m in ipairs(list) do
        lines[#lines+1]=string.format("%d. %s | %.1f, %.1f, %.1f | %s",
            i,m.region,m.pos.X,m.pos.Y,m.pos.Z,m.guid)
    end
    lines[#lines+1]=""
    lines[#lines+1]="Auto Treasure: "..tostring(S.treasureEnabled)
    lines[#lines+1]="Last error: "..tostring(S.treasureLastError or "None")
    tStatus(table.concat(lines,"\n"))
end
local function tRefresh()
    S.treasureToggle.Text=S.treasureEnabled and "AUTO TREASURE: ON" or "AUTO TREASURE: OFF"
    S.treasureToggle.BackgroundColor3=S.treasureEnabled and Color3.fromRGB(49,83,62) or PANEL
end
bind(S.treasureToggle.MouseButton1Click,function()
    S.treasureEnabled=not S.treasureEnabled
    tRefresh()
    tStatus(S.treasureEnabled
        and (S.running and "AUTO ON | Waiting for 2 maps and the next completed pan cycle."
            or "AUTO ON | Start Auto Farm/Dredge to process maps.")
        or (S.treasureBusy and "OFF | Stopping after current safe action." or "OFF"))
    S.diagEvent("TREASURE_TOGGLE",tostring(S.treasureEnabled))
end)
bind(S.treasureScanButton.MouseButton1Click,tScan)
tRefresh()
tScan()
