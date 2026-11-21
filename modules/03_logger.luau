-- Galaxis module: 03_logger.luau
-- Loaded by beta.luau into the shared Galaxis environment.
      function cell(v)
    local s=tostring(v==nil and "" or v)
    return (s:gsub("[\t\r\n]"," "))
end
      function search(root,names)
    if not root then return nil end
    local function check(obj)
        for _,name in ipairs(names) do
            local a=obj:GetAttribute(name)
            if a~=nil then return a end
            if obj.Name==name and obj:IsA("ValueBase") then return obj.Value end
        end
    end
    local value=check(root)
    if value~=nil then return value end
    for _,child in ipairs(root:GetDescendants()) do
        value=check(child)
        if value~=nil then return value end
    end
end
      function stat(names)
    local stats=P:FindFirstChild("Stats")
    if stats then
        for _,name in ipairs(names) do
            local v=stats:GetAttribute(name)
            if v~=nil then return v end
            local child=stats:FindFirstChild(name)
            if child and child:IsA("ValueBase") then return child.Value end
        end
        local v=search(stats,names)
        if v~=nil then return v end
    end
    for _,name in ipairs(names) do
        local v=P:GetAttribute(name)
        if v~=nil then return v end
    end
    return "UNKNOWN"
end
      function zone()
    local v=P:GetAttribute("LastDeposit")
    if v==nil then
        local st=P:FindFirstChild("Stats")
        v=st and st:GetAttribute("LastDeposit")
    end
    if v==nil then v=search(P:FindFirstChild("Data"),{"LastDeposit"}) end
    if v==nil then v=P:GetAttribute("CurrentDeposit") end
    if v==nil then v=P:GetAttribute("CurrentArea") end
    if typeof(v)=="Instance" then return v.Name end
    return v==nil and "UNKNOWN" or tostring(v)
end
      function itemData(item)
    local d=item:FindFirstChild("ItemData")
    if not d then return nil,nil,false end
    local weight=d:GetAttribute("Weight")
    local mutation=d:GetAttribute("Modifier")
    if weight==nil then weight=search(d,{"Weight"}) end
    if mutation==nil then mutation=search(d,{"Modifier","Mutation"}) end
    return weight,mutation,true
end
      function flush()
    if L.writing or #L.unsaved==0 then return end
    L.writing=true
    -- Move queued rows aside BEFORE a potentially yielding file operation.
    -- New batches appended during a write must not be erased afterward.
    local batch=L.unsaved
    L.unsaved={}
    local chunk=table.concat(batch)
    local destination=FILE
    local ok,err=pcall(function()
        if type(appendfile)=="function" then
            appendfile(destination,chunk)
        elseif type(readfile)=="function" and type(writefile)=="function" then
            writefile(destination,readfile(destination)..chunk)
        else
            error("Executor lacks appendfile/readfile")
        end
    end)
    if ok then
        L.error=nil
    else
        local retry={}
        for _,line in ipairs(batch) do retry[#retry+1]=line end
        for _,line in ipairs(L.unsaved) do retry[#retry+1]=line end
        L.unsaved=retry
        L.error=tostring(err)
        outputWarning("mineral-file-"..tostring(err),"[GALAXIS HUB LOGGER] Write failure:",err)
    end
    L.writing=false
end
      function finishBatch()
    if #L.pending>0 then
        L.pan+=1
        local lines={}
        for _,d in ipairs(L.pending) do
            local w,m,has=itemData(d.item)
            w=w or d.weight or "UNKNOWN"
            m=m or d.mutation or (has and "None" or "UNKNOWN")
            lines[#lines+1]=table.concat({
                cell(d.time),cell(L.pan),cell(d.name),cell(m),cell(w),
                cell(d.id),cell(d.luck),cell(d.size),cell(d.mod),cell(d.cap),cell(d.zone)
            },"\t")
        end
        L.minerals+=#L.pending
        L.pending={}
        L.unsaved[#L.unsaved+1]=table.concat(lines,"\n").."\n"
    end
    flush()
end
      function logItem(item)
    if not L.running or L.seen[item] or not item:IsA("Tool") then return end
    if item:GetAttribute("ItemType")~="Valuable" then return end
    L.seen[item]=true
    local w,m=itemData(item)
    L.pending[#L.pending+1]={
        item=item,time=os.date("%Y-%m-%d %H:%M:%S"),name=item.Name,weight=w,mutation=m,
        id=item:GetAttribute("ItemID") or "UNKNOWN",
        luck=stat({"TotalLuck","ActiveLuck","MiningLuck","Luck"}),
        size=stat({"SizeBoost","SizeMultiplier"}),
        mod=stat({"ModifierBoost","ModBoost","MutationBoost"}),
        cap=stat({"Capacity","PanCapacity"}),zone=zone()
    }
    L.lastItem=os.clock()
end
-- Read the existing log once at startup to resume pan numbering.
function S.logStats(raw)
    local maxPan,count=0,0
    for line in raw:gmatch("[^\r\n]+") do
        local n=tonumber(line:match("^[^\t]*\t([^\t]+)\t"))
        if n then
            maxPan=math.max(maxPan,n)
            count+=1
        end
    end
    return maxPan,count
end
function S.initializeMineralFile()
    if type(writefile)~="function" then
        L.error="writefile unavailable"
        return
    end
    if fileExists(FILE) then
        if type(readfile)~="function" then
            L.error="readfile required to resume an existing mineral log"
            return
        end
        local ok,raw=pcall(readfile,FILE)
        if not ok then L.error="Cannot read existing log: "..tostring(raw);return end
        if raw~="" then
            if raw:sub(1,#HEADER)~=HEADER then
                L.error="Existing log format differs; cannot safely append"
                return
            end
            L.pan,L.minerals=S.logStats(raw)
        else
            local written,err=pcall(writefile,FILE,HEADER)
            if not written then L.error=tostring(err) end
        end
    else
        local ok,err=pcall(writefile,FILE,HEADER)
        if not ok then L.error=tostring(err) end
    end
end
S.initializeMineralFile()
function S.switchToNewMineralLog()
    if not L.running then return false,"Logger stopped" end
    if L.writing then return false,"Write in progress; try again" end
    finishBatch()
    if L.writing or #L.unsaved>0 or L.error then
        return false,L.error or "Old log couldn't be flushed"
    end
    if type(writefile)~="function" then return false,"writefile unavailable" end
    local base="GalaxisHub_Minerals_"..os.date("%Y%m%d_%H%M%S")
    local candidate=base..".txt"
    local suffix=1
    while fileExists(candidate) do
        suffix+=1
        candidate=base.."_"..suffix..".txt"
    end
    local ok,err=pcall(writefile,candidate,HEADER)
    if not ok then return false,tostring(err) end
    local saved,saveErr=pcall(writefile,ACTIVE_LOG_POINTER,candidate)
    if not saved then
        return false,"Failed to save current log filename: "..tostring(saveErr)
    end
    FILE=candidate
    L.logFile=FILE
    L.pan=0
    L.minerals=0
    L.error=nil
    S.diagEvent("MINERAL_LOG_NEW_FILE",FILE)
    return true,FILE
end
      backpack=P:WaitForChild("BackpackTwo")
for _,item in ipairs(backpack:GetChildren()) do L.seen[item]=true end
      function stopLogger()
    if not L.running then return end
    L.running=false
    finishBatch()
end
E.StopUniversalLogger=stopLogger
bind(backpack.ChildAdded,function(item)
    if L.running then
        logItem(item)
        if item:GetAttribute("ItemType")==nil then
            task.delay(.1,function() if L.running then logItem(item) end end)
        end
    end
    if not S.running or not S.waiting then return end
    local id=S.token
    task.delay(.02,function()
        if not valid(id) or not S.waiting or not item:IsA("Tool") then return end
        if item:GetAttribute("ItemType")=="Valuable" and not S.seen[item] then
            S.seen[item]=true
            S.rewards+=1
            S.lastReward=os.clock()
        end
    end)
end)
task.spawn(function()
    while L.running do
        task.wait(.05)
        if #L.pending>0 and os.clock()-L.lastItem>=CFG.logGap then
            finishBatch()
        elseif #L.unsaved>0 then
            flush()
        end
    end
end)

-- Remove half-initialized GUIs left behind by earlier startup crashes.
-- Also cleans old windows whose Close handler was never installed.