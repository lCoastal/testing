-- Galaxis module: 07_reforge.luau
-- Loaded by beta.luau into the shared Galaxis environment.
-- Manual reforge: only the currently held, reforgeable equipment.
-- The game exposes ReforgeEquipment as a RemoteFunction. Invoke exactly
-- once per click; no retry loops and no automatic perfect-token consumption.
S.reforgeTitle=label("REFORGE EQUIPPED ITEM",14,17,312,30,13,FG)
relocate(S.reforgeTitle,reforgePage,14,17)
S.reforgeEquipped=label("Held item: checking...",14,65,312,38,12,FG)
relocate(S.reforgeEquipped,reforgePage,14,65)
S.reforgeEquipped.TextWrapped=true
S.reforgeButton=button("REFORGE HELD ITEM",14,115,312,44,reforgePage)
S.reforgeStatus=label("One normal reforge per click. No auto-repeat.",14,179,312,77,12,MUTED)
relocate(S.reforgeStatus,reforgePage,14,179)
S.reforgeStatus.TextWrapped=true
S.reforgeStatus.TextYAlignment=Enum.TextYAlignment.Top
S.reforgeBusy=false

      function heldReforgeItem()
    local character=P.Character
    if not character then return nil end
    for _,obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") and obj:FindFirstChild("StatRolls")
            and obj:FindFirstChild("ItemData") then
            return obj
        end
    end
    return nil
end

S.reforgeKeybindEnabled=false
S.reforgeKeybindButton=button("R KEYBIND: OFF",14,267,312,34,reforgePage)
S.reforgeKeybindButton.TextSize=11
S.reforgeKeybindButton.BackgroundColor3=PANEL
      function refreshReforgeKeybind()
    S.reforgeKeybindButton.Text="R KEYBIND: "..(S.reforgeKeybindEnabled and "ON" or "OFF")
    S.reforgeKeybindButton.BackgroundColor3=S.reforgeKeybindEnabled
        and Color3.fromRGB(45,105,67) or PANEL
end
bind(S.reforgeKeybindButton.MouseButton1Click,function()
    S.reforgeKeybindEnabled=not S.reforgeKeybindEnabled
    refreshReforgeKeybind()
    S.reforgeStatus.Text=S.reforgeKeybindEnabled
        and "Press R to reforge the equipment currently in your hand."
        or "R keybind disabled. Manual reforge button remains available."
end)
S.reforgeNow=function()
    if not S.alive or S.reforgeBusy then return end
    local item=heldReforgeItem()
    if not item then
        S.reforgeStatus.Text="Hold a reforgeable equipment item first (ItemData + StatRolls)."
        return
    end
    local remotes=RS:FindFirstChild("Remotes")
    local crafting=remotes and remotes:FindFirstChild("Crafting")
    local remote=crafting and crafting:FindFirstChild("ReforgeEquipment")
    if not remote or not remote:IsA("RemoteFunction") then
        S.reforgeStatus.Text="ReforgeEquipment remote unavailable."
        return
    end
    S.reforgeBusy=true
    S.reforgeButton.Text="REFORGING..."
    local name=item.Name
    S.reforgeStatus.Text="Reforging "..name.."..."
    S.diagEvent("REFORGE_START",name)
    task.spawn(function()
        local ok,result,newItem=pcall(function()
            return remote:InvokeServer(item)
        end)
        if not S.alive then return end
        local status
        if not ok then
            status="Reforge failed: "..tostring(result)
        elseif result==true then
            status="Reforged "..name.." successfully."
        elseif typeof(newItem)=="Instance" then
            status="Reforge returned updated equipment: "..newItem.Name
        else
            status="Reforge not confirmed: "..tostring(result)
        end
        S.reforgeStatus.Text=status
        S.diagEvent(ok and "REFORGE_RESULT" or "REFORGE_ERROR",status)
        S.reforgeBusy=false
        S.reforgeButton.Text="REFORGE HELD ITEM"
    end)
end
bind(S.reforgeButton.MouseButton1Click,S.reforgeNow)

-- AUTO REFORGE: stop BEFORE spending when next cost reaches the cap,
-- or when the chosen StatRolls attribute reaches its target.
do
    S.autoReforgeEnabled=false
    S.autoReforgeBusy=false
    S.autoReforgeCount=0
    local function inputBox(parent,x,y,w,placeholder,default)
        local box=make("TextBox",{
            Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,30),
            BackgroundColor3=PANEL,BorderSizePixel=0,TextColor3=FG,
            PlaceholderColor3=MUTED,PlaceholderText=placeholder,
            Text=default or "",ClearTextOnFocus=false,
            Font=Enum.Font.Gotham,TextSize=11
        },parent)
        return box
    end
    S.autoReforgePriceInput=inputBox(reforgePage,14,315,145,"Max cost (e.g. 1B)","1B")
    S.autoReforgeStatInput=inputBox(reforgePage,168,315,92,"Stat name","Luck")
    S.autoReforgeTargetInput=inputBox(reforgePage,267,315,59,"Target","100")
    S.autoReforgeButton=button("AUTO REFORGE: OFF",14,352,312,34,reforgePage)
    S.autoReforgeButton.TextSize=11
    S.autoReforgeStatus=label("Stops before a reroll at max price OR when stat target is reached.",14,391,312,58,10,MUTED)
    S.autoReforgeStatus.TextWrapped=true
    local function parseReforgeNumber(value)
        local raw=tostring(value or ""):upper():gsub("[%$, ]","")
        local number,suffix=raw:match("^([%d%.]+)([KMBT]?)$")
        number=tonumber(number)
        if not number then return nil end
        local multiplier=({K=1e3,M=1e6,B=1e9,T=1e12})[suffix] or 1
        return number*multiplier
    end
    local function formatReforgeNumber(value)
        if value>=1e12 then return string.format("%.3gT",value/1e12) end
        if value>=1e9 then return string.format("%.3gB",value/1e9) end
        if value>=1e6 then return string.format("%.3gM",value/1e6) end
        return tostring(math.floor(value))
    end
    local function stopAutoReforge(message)
        S.autoReforgeEnabled=false
        S.autoReforgeBusy=false
        S.autoReforgeButton.Text="AUTO REFORGE: OFF"
        S.autoReforgeButton.BackgroundColor3=PANEL
        S.autoReforgeStatus.Text=message
        S.diagEvent("AUTO_REFORGE_STOP",message)
    end
    local function statReached(item,statName,target)
        local rolls=item and item:FindFirstChild("StatRolls")
        if not rolls then return false,nil end
        local value=rolls:GetAttribute(statName)
        if type(value)~="number" then return false,value end
        return value>=target,value
    end
    local function autoReforgeLoop()
        if S.autoReforgeBusy then return end
        S.autoReforgeBusy=true
        task.spawn(function()
            while S.alive and S.autoReforgeEnabled do
                local item=heldReforgeItem()
                if not item then stopAutoReforge("Stopped: hold a reforgeable item first.");break end
                local maxCost=parseReforgeNumber(S.autoReforgePriceInput.Text)
                local statName=S.autoReforgeStatInput.Text:gsub("^%s+",""):gsub("%s+$","")
                local target=parseReforgeNumber(S.autoReforgeTargetInput.Text)
                if not maxCost or maxCost<=0 then
                    stopAutoReforge("Invalid max price. Use e.g. 60M, 1B or 1T.");break
                end
                if statName~="" and not target then
                    stopAutoReforge("Invalid target stat value.");break
                end
                if statName~="" then
                    local reached,value=statReached(item,statName,target)
                    if value==nil then
                        stopAutoReforge("Stat '"..statName.."' not found in StatRolls.");break
                    elseif reached then
                        stopAutoReforge(statName.." reached "..tostring(value)..
                            " (target "..tostring(target).."). "..S.autoReforgeCount.." rerolls.");break
                    end
                end
                local remotes=RS:FindFirstChild("Remotes")
                local crafting=remotes and remotes:FindFirstChild("Crafting")
                local costRemote=crafting and crafting:FindFirstChild("GetReforgeCost")
                local reforgeRemote=crafting and crafting:FindFirstChild("ReforgeEquipment")
                if not costRemote or not costRemote:IsA("RemoteFunction")
                    or not reforgeRemote or not reforgeRemote:IsA("RemoteFunction") then
                    stopAutoReforge("GetReforgeCost / ReforgeEquipment unavailable.");break
                end
                local costOK,cost=pcall(function() return costRemote:InvokeServer(item) end)
                if not costOK or type(cost)~="number" then
                    stopAutoReforge("Could not read next reforge cost: "..tostring(cost));break
                end
                if cost>=maxCost then
                    stopAutoReforge("Next cost "..formatReforgeNumber(cost)..
                        " reached max "..formatReforgeNumber(maxCost)..
                        ". "..S.autoReforgeCount.." rerolls completed.");break
                end
                S.autoReforgeStatus.Text=string.format(
                    "Rerolls: %d | next cost: %s | %s target: %s",
                    S.autoReforgeCount,formatReforgeNumber(cost),
                    statName~="" and statName or "No stat",statName~="" and tostring(target) or "off")
                local ok,result=pcall(function() return reforgeRemote:InvokeServer(item) end)
                if not ok or result==false then
                    stopAutoReforge("Reforge failed: "..tostring(result));break
                end
                S.autoReforgeCount+=1
                S.diagEvent("AUTO_REFORGE_ROLL",item.Name.." | cost="..
                    tostring(cost).." | result="..tostring(result))
                task.wait(.65)
            end
            S.autoReforgeBusy=false
        end)
    end
    bind(S.autoReforgeButton.MouseButton1Click,function()
        if S.autoReforgeEnabled then
            stopAutoReforge("Stopped manually after "..S.autoReforgeCount.." rerolls.")
            return
        end
        S.autoReforgeCount=0
        S.autoReforgeEnabled=true
        S.autoReforgeButton.Text="AUTO REFORGE: ON"
        S.autoReforgeButton.BackgroundColor3=Color3.fromRGB(45,105,67)
        S.autoReforgeStatus.Text="Starting; checking price and target before every roll..."
        autoReforgeLoop()
    end)
end


-- Live Debug: one glance at current action, zone, fill and stalled state.