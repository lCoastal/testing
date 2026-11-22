-- Galaxis module: 12_treasure.luau
-- Treasure automation. Runs only after a completed pan cycle.
for _,k in ipairs({"treasureTitle","treasureStatus","treasureToggle","treasureScanButton","treasureOutput"}) do
    if S[k] then pcall(function() S[k]:Destroy() end) end
end
S.treasureEnabled=S.treasureEnabled==true
S.treasureBusy=false
S.treasureRequested=false
S.treasureStandalone=false
S.treasureMinMaps=2
S.treasureNextTryAt=0
S.treasureCompleted=S.treasureCompleted or {}
S.treasureAttempted=S.treasureAttempted or {}
S.treasureLastError=nil

S.treasureTitle=label("AUTO TREASURE ROUTE",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("OFF | Independent auto-dig; starts at 2 treasure maps.",14,39,312,38,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureToggle=button("AUTO DIG MAPS: OFF",14,82,312,36,treasurePage)
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
local function tEligibleMaps()
    local list={}
    for _,m in ipairs(tMaps()) do
        if not S.treasureCompleted[m.guid] and not S.treasureAttempted[m.guid] then
            list[#list+1]=m
        end
    end
    return list
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
    local list=tEligibleMaps()
    if #list<S.treasureMinMaps then return end
    S.treasureBusy=true
    local rr=root()
    local cp={
        dig=S.dig or (rr and rr.CFrame),
        water=S.water,
        zone=S.dredge and S.dredgeAt or S.activeZone,
        dredgeAt=S.dredgeAt
    }
    local oldDredge=S.dredge==true
    local oldSell=S.sell
    -- Suspend the Dredge planner while the treasure route owns movement.
    -- Resume it only after one complete farm cycle at the restored checkpoint.
    S.dredge=false
    local ordered=tSort(list,root() and root().Position or Vector3.zero)
    local ok,err=true,nil
    S.sell=false
    S.diagEvent("TREASURE_ROUTE_START","maps="..#ordered)

    for i,m in ipairs(ordered) do
        if not valid(id) or not S.treasureEnabled then ok,err=false,"Stopped by user";break end
        if not m.tool.Parent or S.treasureCompleted[m.guid] or S.treasureAttempted[m.guid] then continue end
        -- The map's exact Location is the only destination; no zone/stone routing.
        tStatus(string.format("Map %d/%d | running to exact coordinates in %s",i,#ordered,m.region))
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
        -- Only mark attempted when the dig is actually about to be sent.
        S.treasureAttempted[m.guid]=true
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
    -- Restore the controller exactly as it was before the route.
    -- Never turn Auto Farm or Auto Dredge on if they were originally off.
    S.dredge=oldDredge and S.running and returned and true or false
    if not ok then
        S.treasureNextTryAt=os.clock()+20
    else
        S.treasureNextTryAt=os.clock()+2
    end
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

-- One entry point works for the active farm worker and independent travel.
S.treasureCycle=function(id,r)
    if not S.treasureEnabled or S.treasureBusy or not valid(id) then return end
    local n=#tEligibleMaps()
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
        S.dredge=S.treasureWasDredge and S.running or false
        tStatus("Treasure error: "..S.treasureLastError)
    end
end

-- Standalone treasure runner. Auto Farm and Dredge do NOT need to be on.
-- If a farm worker is active, it owns the cycle and calls S.treasureCycle
-- between complete pan cycles. Do not move concurrently with it.
task.spawn(function()
    while S.alive do
        task.wait(1.0)
        if S.treasureEnabled and not S.treasureBusy
            and os.clock()>=(S.treasureNextTryAt or 0) then
            local count=#tEligibleMaps()
            if count>=S.treasureMinMaps then
                if S.running then
                    S.treasureRequested=true
                    -- An active farming worker will yield at a safe boundary.
                elseif not S.treasureStandalone then
                    S.treasureStandalone=true
                    S.token+=1
                    local id=S.token
                    local ok,err=pcall(S.treasureCycle,id,nil)
                    if not ok then
                        S.treasureLastError=tostring(err)
                        S.treasureNextTryAt=os.clock()+20
                        tStatus("Standalone treasure error: "..S.treasureLastError)
                    end
                    S.treasureStandalone=false
                end
            end
        end
    end
end)

local function tScan()
    local list=tMaps()
    local available=tEligibleMaps()
    local lines={"GALAXIS TREASURE MAPS","Maps: "..#list.." | eligible: "..#available,""}
    for i,m in ipairs(list) do
        lines[#lines+1]=string.format("%d. %s | %.1f, %.1f, %.1f | %s",
            i,m.region,m.pos.X,m.pos.Y,m.pos.Z,m.guid)
    end
    lines[#lines+1]=""
    lines[#lines+1]="Auto Dig: "..tostring(S.treasureEnabled)
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
        tStatus(n>=S.treasureMinMaps
            and (S.running and "AUTO DIG ON | Waiting for safe pan-cycle boundary."
                or "AUTO DIG ON | Starting treasure route independently.")
            or string.format("AUTO DIG ON | Waiting for maps (%d/%d)",n,S.treasureMinMaps))
    else
        S.treasureRequested=false
        tStatus(S.treasureBusy and "OFF | Stopping at next safe movement check." or "OFF")
    end
    tRefresh()
end)
bind(S.treasureScanButton.MouseButton1Click,tScan)
tRefresh()
tScan()
