-- Galaxis module: 12_treasure.luau
-- Phase 1: read-only Treasure Map diagnostics. No remotes are fired.
if S.treasureTitle then pcall(function() S.treasureTitle:Destroy() end) end
if S.treasureNote then pcall(function() S.treasureNote:Destroy() end) end

S.treasureTitle=label("AUTO TREASURE MAP",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("Phase 1: identify map items, destinations, prompts and remotes.",14,39,312,42,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureScanButton=button("SCAN TREASURE SYSTEM",14,86,312,36,treasurePage)
S.treasureCopyButton=button("COPY LAST SCAN",14,130,312,32,treasurePage)
S.treasureCopyButton.BackgroundColor3=PANEL
S.treasureOutput=make("TextBox",{
    Position=UDim2.fromOffset(14,170),Size=UDim2.new(1,-28,1,-184),
    BackgroundColor3=PANEL,BorderSizePixel=0,TextColor3=FG,
    PlaceholderColor3=MUTED,PlaceholderText="Run a scan to inspect treasure-related game objects.",
    Text="",ClearTextOnFocus=false,MultiLine=true,TextWrapped=false,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    Font=Enum.Font.Code,TextSize=9
},treasurePage)
S.treasureLastScan=nil
S.treasureScanBusy=false

local function treasurePath(obj)
    local names={}
    local current=obj
    for _=1,12 do
        if not current then break end
        table.insert(names,1,current.Name)
        current=current.Parent
    end
    return table.concat(names,".")
end

local function treasureInteresting(name)
    local n=string.lower(tostring(name))
    return n:find("treasure",1,true) or n:find("buried",1,true)
        or n:find("chest",1,true) or n:find("cache",1,true)
        or n:find("crate",1,true) or n:find("map",1,true)
        or n:find("digsite",1,true) or n:find("deposit",1,true)
        or n:find("pharaoh",1,true) or n:find("sarcophagus",1,true)
        or n:find("mastery",1,true)
end

local function treasureDescribe(obj)
    local bits={obj.ClassName.." "..treasurePath(obj)}
    if obj:IsA("Tool") then
        local ok,tip=pcall(function() return obj.ToolTip end)
        if ok and tip and tip~="" then table.insert(bits,"ToolTip="..tostring(tip)) end
    end
    local ok,attrs=pcall(function() return obj:GetAttributes() end)
    if ok then
        for k,v in pairs(attrs) do
            table.insert(bits,"@"..tostring(k).."="..tostring(v))
        end
    end
    if obj:IsA("ProximityPrompt") then
        table.insert(bits,"ActionText="..tostring(obj.ActionText))
        table.insert(bits,"ObjectText="..tostring(obj.ObjectText))
        table.insert(bits,"Enabled="..tostring(obj.Enabled))
        table.insert(bits,"Distance="..tostring(obj.MaxActivationDistance))
        table.insert(bits,"Hold="..tostring(obj.HoldDuration))
    elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        table.insert(bits,"REMOTE="..obj.ClassName)
    elseif obj:IsA("ModuleScript") or obj:IsA("Script") or obj:IsA("LocalScript") then
        table.insert(bits,"SCRIPT_SOURCE_READABLE="..tostring(pcall(function() return obj.Source end)))
    end
    return table.concat(bits," | ")
end

local function treasureScan()
    if S.treasureScanBusy or not S.alive then return end
    S.treasureScanBusy=true
    S.treasureStatus.Text="Scanning ReplicatedStorage, player inventory and treasure-related world objects..."
    task.spawn(function()
        local lines={
            "GALAXIS TREASURE DIAGNOSTIC",
            "Time: "..os.date("%Y-%m-%d %H:%M:%S"),
            "Player: "..P.Name,
            "",
            "=== PLAYER INVENTORY / CHARACTER ==="
        }
        local seen={}
        local function add(obj)
            if not obj or seen[obj] then return end
            seen[obj]=true
            table.insert(lines,treasureDescribe(obj))
        end
        local backpack=P:FindFirstChild("BackpackTwo") or P:FindFirstChildOfClass("Backpack")
        if backpack then
            for _,obj in ipairs(backpack:GetDescendants()) do
                if treasureInteresting(obj.Name) or obj:IsA("Tool") and treasureInteresting(obj.Name) then add(obj) end
            end
            for _,obj in ipairs(backpack:GetChildren()) do
                if treasureInteresting(obj.Name) then add(obj) end
            end
        else
            table.insert(lines,"Backpack not found")
        end
        if P.Character then
            for _,obj in ipairs(P.Character:GetDescendants()) do
                if treasureInteresting(obj.Name) then add(obj) end
            end
        end
        table.insert(lines,"")
        table.insert(lines,"=== REPLICATED STORAGE: TREASURE-RELATED OBJECTS ===")
        local replicatedCount=0
        for _,obj in ipairs(RS:GetDescendants()) do
            if treasureInteresting(obj.Name) then
                replicatedCount+=1
                if replicatedCount<=500 then add(obj) end
            end
        end
        table.insert(lines,"ReplicatedStorage matches: "..replicatedCount)
        table.insert(lines,"")
        table.insert(lines,"=== REMOTES WITH TREASURE / MAP / CHEST NAMES ===")
        local remoteCount=0
        for _,obj in ipairs(RS:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
                and treasureInteresting(obj.Name) then
                remoteCount+=1
                add(obj)
            end
        end
        if remoteCount==0 then table.insert(lines,"No directly named treasure remotes found.") end
        table.insert(lines,"")
        table.insert(lines,"=== WORLD PROMPTS / TREASURE OBJECTS ===")
        local map=workspace:FindFirstChild("Map")
        local worldCount=0
        if map then
            for _,obj in ipairs(map:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local parentName=obj.Parent and obj.Parent.Name or ""
                    if treasureInteresting(obj.Name) or treasureInteresting(parentName)
                        or treasureInteresting(treasurePath(obj.Parent or obj)) then
                        worldCount+=1
                        if worldCount<=300 then add(obj) end
                    end
                elseif treasureInteresting(obj.Name) then
                    worldCount+=1
                    if worldCount<=300 then add(obj) end
                end
            end
        else
            table.insert(lines,"Workspace.Map not found")
        end
        table.insert(lines,"World matches: "..worldCount)
        table.insert(lines,"")
        table.insert(lines,"=== PLAYER DATA TREASURE REFERENCES ===")
        for _,child in ipairs(P:GetChildren()) do
            if treasureInteresting(child.Name) then
                add(child)
                for _,obj in ipairs(child:GetDescendants()) do
                    if treasureInteresting(obj.Name) then add(obj) end
                end
            end
        end
        table.insert(lines,"")
        table.insert(lines,"NOTE: Read-only scan. No map, chest, or reward remote was invoked.")
        local result=table.concat(lines,"\n")
        S.treasureLastScan=result
        S.treasureOutput.Text=result
        S.treasureStatus.Text=string.format(
            "Scan complete | RS matches: %d | world matches: %d | remotes: %d",
            replicatedCount,worldCount,remoteCount)
        S.diagEvent("TREASURE_DIAGNOSTIC",string.format(
            "RS=%d world=%d remotes=%d chars=%d",
            replicatedCount,worldCount,remoteCount,#result))
        S.treasureScanBusy=false
    end)
end

bind(S.treasureScanButton.MouseButton1Click,treasureScan)
bind(S.treasureCopyButton.MouseButton1Click,function()
    if not S.treasureLastScan then
        S.treasureStatus.Text="Run the scan first."
        return
    end
    local ok=false
    if type(setclipboard)=="function" then ok=pcall(setclipboard,S.treasureLastScan) end
    S.treasureStatus.Text=ok and "Diagnostic copied to clipboard." or "Clipboard unavailable; select the text below."
end)
