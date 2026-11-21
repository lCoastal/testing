-- Galaxis module: 06_pack.luau
-- Loaded by beta.luau into the shared Galaxis environment.
do
-- ===== INFINITE / FOREVER PACK: READ-ONLY REWARD INSPECTOR =====
-- GetForeverPackData exposes the current, next and all pre-generated
-- rewards; never claim or purchase a tier. No reward odds are fabricated.
S.packTitle=label("INFINITE PACK REWARDS",14,10,312,24,13,FG)
relocate(S.packTitle,packPage,14,10)
S.packSummary=label("Open PACK to read visible rewards.",14,40,312,70,11,FG)
relocate(S.packSummary,packPage,14,40)
S.packSummary.TextWrapped=true
S.packSummary.TextYAlignment=Enum.TextYAlignment.Top
S.packRefresh=button("REFRESH REWARDS",14,116,312,32,packPage)
S.packScroll=make("ScrollingFrame",{
    Position=UDim2.fromOffset(14,158),
    Size=UDim2.new(1,-28,1,-168),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=5,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.None
},packPage)
local packLayout=make("UIListLayout",{
    Padding=UDim.new(0,5),
    SortOrder=Enum.SortOrder.LayoutOrder
},S.packScroll)
local function packCell(txt,order,highlight)
    local row=rounded(make("TextLabel",{
        Size=UDim2.new(1,-8,0,37),
        BackgroundColor3=highlight and Color3.fromRGB(58,61,70) or PANEL,
        BorderSizePixel=0,
        TextColor3=highlight and FG or MUTED,
        Font=Enum.Font.GothamMedium,
        TextSize=11,
        TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,
        Text="  "..txt,
        LayoutOrder=order
    },S.packScroll))
    return row
end
local function clearPackRows()
    for _,child in ipairs(S.packScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end
local function sortedPackEntries(entries)
    local result={}
    if type(entries)~="table" then return result end
    for key,item in pairs(entries) do
        if type(item)=="table" then
            local tier=tonumber(item.Tier) or tonumber(key)
            if tier then result[#result+1]={tier=tier,data=item} end
        end
    end
    table.sort(result,function(a,b) return a.tier<b.tier end)
    return result
end
local function packEntryName(item)
    if type(item)~="table" then return "Unknown reward" end
    local reward=item.Item
    if type(reward)=="string" or type(reward)=="number" then return tostring(reward) end
    if type(reward)=="table" then
        return tostring(reward.Name or reward.Item or reward.Id or "Unknown reward")
    end
    return "Unknown reward"
end
local function packEntryText(entry,state)
    local item=entry.data
    local pay=item.Paid==true and "PAID" or
        (item.Paid==false and "FREE" or "UNKNOWN")
    local price=item.PriceTier~=nil and (" | price tier "..tostring(item.PriceTier)) or ""
    return string.format("TIER %d  |  %s\n  %s | %s%s",
        entry.tier,packEntryName(item),state,pay,price)
end
local function findPackTier(entries,n)
    for _,e in ipairs(entries) do if e.tier==n then return e end end
end
S.packBusy=false
S.packLastRefresh=0
S.packLastData=nil
function S.refreshInfinitePack()
    if not S.alive or S.packBusy then return end
    local remotes=RS:FindFirstChild("Remotes")
    local market=remotes and remotes:FindFirstChild("Market")
    local remote=market and market:FindFirstChild("GetForeverPackData")
    if not remote or not remote:IsA("RemoteFunction") then
        S.packSummary.Text="GetForeverPackData unavailable.\nOpen the game's Forever Pack once and refresh."
        return
    end
    S.packBusy=true
    S.packRefresh.Text="REFRESHING..."
    task.spawn(function()
        local ok,data=pcall(function() return remote:InvokeServer() end)
        if not S.alive then return end
        S.packBusy=false
        S.packLastRefresh=os.clock()
        S.packRefresh.Text="REFRESH REWARDS"
        if not ok or type(data)~="table" then
            S.packSummary.Text="Could not read Forever Pack: "..tostring(data):sub(1,110)
            S.diagEvent("PACK_READ_FAILED",tostring(data):sub(1,100))
            return
        end
        S.packLastData=data
        local current=tonumber(data.CurrentTier)
        local nextGenerated=tonumber(data.NextGeneratedTier)
        local upcoming=sortedPackEntries(data.Tiers)
        local claimed=sortedPackEntries(data.ClaimedTiers)
        local byTier={}
        for _,e in ipairs(claimed) do byTier[e.tier]=e end
        for _,e in ipairs(upcoming) do byTier[e.tier]=e end
        local currentEntry=current and byTier[current]
        local nextEntry=current and byTier[current+1]
        local currentName=currentEntry and packEntryName(currentEntry.data) or "Not exposed"
        local nextName=nextEntry and packEntryName(nextEntry.data) or "Not generated / unavailable"
        S.packSummary.Text=string.format(
            "CURRENT  #%s: %s\nNEXT  #%s: %s\nGenerated through tier %s | %d visible rewards",
            tostring(current or "?"),currentName,
            tostring(current and current+1 or "?"),nextName,
            tostring(nextGenerated and nextGenerated-1 or "?"),
            #upcoming+#claimed)
        clearPackRows()
        local order=0
        local function append(label,highlight)
            order+=1
            packCell(label,order,highlight)
        end
        if #upcoming>0 then
            append("VISIBLE CURRENT / UPCOMING",true)
            for _,entry in ipairs(upcoming) do
                append(packEntryText(entry,
                    entry.tier==current and "CURRENT" or
                    (current and entry.tier==current+1 and "NEXT" or "UPCOMING")),
                    entry.tier==current or (current and entry.tier==current+1))
            end
        end
        if #claimed>0 then
            append("ALREADY CLAIMED / PAST",true)
            for _,entry in ipairs(claimed) do
                append(packEntryText(entry,"PAST"),false)
            end
        end
        if order==0 then append("No visible tier rewards returned.",false) end
        S.packScroll.CanvasSize=UDim2.fromOffset(0,order*42+8)
        S.diagEvent("PACK_READ_OK",string.format(
            "current=%s nextGenerated=%s visible=%d claimed=%d",
            tostring(current),tostring(nextGenerated),#upcoming,#claimed))
    end)
end
bind(S.packRefresh.MouseButton1Click,function() S.refreshInfinitePack() end)
-- Passive display refresh while this tab is open; never spam the
-- market remote during ordinary farming or when the panel is hidden.
task.spawn(function()
    while S.alive do
        if packPage.Visible and not S.packBusy and
            os.clock()-S.packLastRefresh>=30 then
            S.refreshInfinitePack()
        end
        task.wait(2)
    end
end)

end -- PACK feature local scope; release locals before remaining UI setup.
