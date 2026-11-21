-- Galaxis module: 12_treasure.luau
-- Read-only inspection of actual Treasure Map tools in the player's inventory.
if S.treasureTitle then pcall(function() S.treasureTitle:Destroy() end) end
if S.treasureStatus then pcall(function() S.treasureStatus:Destroy() end) end
if S.treasureScanButton then pcall(function() S.treasureScanButton:Destroy() end) end
if S.treasureCopyButton then pcall(function() S.treasureCopyButton:Destroy() end) end
if S.treasureOutput then pcall(function() S.treasureOutput:Destroy() end) end

S.treasureTitle=label("AUTO TREASURE MAP",14,10,312,25,13,FG)
relocate(S.treasureTitle,treasurePage,14,10)
S.treasureStatus=label("First check: do inventory maps contain destination coordinates, or only arrow / clue data?",14,39,312,42,10,MUTED)
relocate(S.treasureStatus,treasurePage,14,39)
S.treasureStatus.TextWrapped=true
S.treasureScanButton=button("INSPECT INVENTORY MAPS",14,86,312,36,treasurePage)
S.treasureCopyButton=button("COPY MAP INSPECTION",14,130,312,32,treasurePage)
S.treasureCopyButton.BackgroundColor3=PANEL
S.treasureOutput=make("TextBox",{
    Position=UDim2.fromOffset(14,170),Size=UDim2.new(1,-28,1,-184),
    BackgroundColor3=PANEL,BorderSizePixel=0,TextColor3=FG,
    PlaceholderColor3=MUTED,PlaceholderText="Put a Treasure Map in your inventory, then inspect it here.",
    Text="",ClearTextOnFocus=false,MultiLine=true,TextWrapped=false,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    Font=Enum.Font.Code,TextSize=9
},treasurePage)
S.treasureLastScan=nil
S.treasureScanBusy=false

local function treasureObjectPath(obj)
    local names={}
    local current=obj
    for _=1,16 do
        if not current then break end
        table.insert(names,1,current.Name)
        current=current.Parent
    end
    return table.concat(names,".")
end

local function treasureIsMapTool(obj)
    if not obj or not obj:IsA("Tool") then return false end
    local n=string.lower(obj.Name)
    local tip=""
    pcall(function() tip=string.lower(obj.ToolTip or "") end)
    return n:find("map",1,true)~=nil or n:find("treasure",1,true)~=nil
        or tip:find("map",1,true)~=nil or tip:find("treasure",1,true)~=nil
end

local function treasureDumpAttributes(lines,obj,prefix)
    local ok,attrs=pcall(function() return obj:GetAttributes() end)
    if ok then
        local keys={}
        for k in pairs(attrs) do table.insert(keys,k) end
        table.sort(keys)
        for _,k in ipairs(keys) do
            table.insert(lines,prefix.."Attribute "..tostring(k).." = "..tostring(attrs[k]))
        end
    end
end

local function treasureInspectMap(lines,tool,index)
    table.insert(lines,"")
    table.insert(lines,"========== MAP "..index.." ==========")
    table.insert(lines,"Name: "..tool.Name)
    table.insert(lines,"Path: "..treasureObjectPath(tool))
    table.insert(lines,"Class: "..tool.ClassName)
    pcall(function() table.insert(lines,"ToolTip: "..tostring(tool.ToolTip)) end)
    pcall(function() table.insert(lines,"TextureId: "..tostring(tool.TextureId)) end)
    pcall(function() table.insert(lines,"RequiresHandle: "..tostring(tool.RequiresHandle)) end)
    treasureDumpAttributes(lines,tool,"")
    local descendants=tool:GetDescendants()
    table.insert(lines,"Descendant count: "..#descendants)
    for _,obj in ipairs(descendants) do
        local path=treasureObjectPath(obj)
        table.insert(lines,"["..obj.ClassName.."] "..path)
        treasureDumpAttributes(lines,obj,"  ")
        if obj:IsA("ValueBase") then
            local valueText="  Value = "..tostring(obj.Value)
            if obj:IsA("ObjectValue") and obj.Value then
                valueText=valueText.." | Target = "..treasureObjectPath(obj.Value)
            end
            table.insert(lines,valueText)
        elseif obj:IsA("Attachment") then
            table.insert(lines,"  Position = "..tostring(obj.Position))
            table.insert(lines,"  WorldPosition = "..tostring(obj.WorldPosition))
        elseif obj:IsA("BasePart") then
            table.insert(lines,"  Position = "..tostring(obj.Position))
            table.insert(lines,"  CFrame = "..tostring(obj.CFrame))
        elseif obj:IsA("ProximityPrompt") then
            table.insert(lines,"  ActionText = "..obj.ActionText.." | ObjectText = "..obj.ObjectText)
        elseif obj:IsA("ModuleScript") or obj:IsA("LocalScript") or obj:IsA("Script") then
            table.insert(lines,"  Script object present (source not read).")
        end
    end
end

local function treasureInspectInventory()
    if S.treasureScanBusy or not S.alive then return end
    S.treasureScanBusy=true
    S.treasureStatus.Text="Inspecting map Tools and every descendant / attribute..."
    task.spawn(function()
        local lines={
            "GALAXIS - INVENTORY TREASURE MAP INSPECTION",
            "Player: "..P.Name,
            "Time: "..os.date("%Y-%m-%d %H:%M:%S"),
            "Purpose: determine whether map objects store coordinates or require arrow navigation.",
            "",
            "=== INVENTORY MAPS ==="
        }
        local backpack=P:FindFirstChild("BackpackTwo") or P:FindFirstChildOfClass("Backpack")
        local character=P.Character
        local containers={}
        if backpack then table.insert(containers,backpack) end
        if character then table.insert(containers,character) end
        local found={}
        local inventoryNames={}
        for _,container in ipairs(containers) do
            for _,obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    table.insert(inventoryNames,obj.Name)
                    if treasureIsMapTool(obj) then table.insert(found,obj) end
                end
            end
        end
        table.insert(lines,"Backpack: "..tostring(backpack and backpack:GetFullName() or "NOT FOUND"))
        table.insert(lines,"Map tools found: "..#found)
        if #found==0 then
            table.insert(lines,"No Tool with 'map' or 'treasure' in its name / tooltip was found.")
        else
            for i,tool in ipairs(found) do treasureInspectMap(lines,tool,i) end
        end
        table.insert(lines,"")
        table.insert(lines,"=== ALL INVENTORY TOOL NAMES (FOR MAP NAME MATCHING) ===")
        table.sort(inventoryNames)
        for _,name in ipairs(inventoryNames) do table.insert(lines,name) end
        table.insert(lines,"")
        table.insert(lines,"=== INTERPRETATION HINTS ===")
        table.insert(lines,"Vector3Value / CFrameValue / coordinate-like attributes may indicate stored destination coordinates.")
        table.insert(lines,"StringValue / clue / direction fields may indicate text clues or arrow navigation.")
        table.insert(lines,"ObjectValue may reference a map target or data object.")
        table.insert(lines,"This scan is read-only: no map is used and no remote is fired.")
        local result=table.concat(lines,"\n")
        S.treasureLastScan=result
        S.treasureOutput.Text=result
        S.treasureStatus.Text=string.format("Inspection complete | map tools: %d | inventory tools: %d",#found,#inventoryNames)
        S.diagEvent("TREASURE_MAP_INVENTORY_SCAN",string.format("maps=%d tools=%d chars=%d",#found,#inventoryNames,#result))
        S.treasureScanBusy=false
    end)
end

bind(S.treasureScanButton.MouseButton1Click,treasureInspectInventory)
bind(S.treasureCopyButton.MouseButton1Click,function()
    if not S.treasureLastScan then
        S.treasureStatus.Text="Inspect your inventory first."
        return
    end
    local ok=false
    if type(setclipboard)=="function" then ok=pcall(setclipboard,S.treasureLastScan) end
    S.treasureStatus.Text=ok and "Map inspection copied to clipboard." or "Clipboard unavailable; select the text below."
end)
