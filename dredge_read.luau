-- COASTAL PROSPECTING: READ-ONLY DREDGE QUEST DIAGNOSTIC
-- No remotes fired/invoked, no quest modifications, no farming changes.
-- Reads client quest state and visible quest UI, prints results and copies ONCE.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local lines={}
local found=false
local MAX_LINES=260

local function add(line)
    if #lines<MAX_LINES then
        lines[#lines+1]=tostring(line)
    end
end
local function nice(value)
    local kind=typeof(value)
    if kind=="Instance" then return value:GetFullName() end
    if kind=="string" then return string.format("%q",value) end
    return tostring(value)
end
local function dump(value,level,seen)
    if #lines>=MAX_LINES then return end
    if typeof(value)~="table" then
        add(string.rep("  ",level)..nice(value))
        return
    end
    if seen[value] then
        add(string.rep("  ",level).."<already visited table>")
        return
    end
    if level>=8 then
        add(string.rep("  ",level).."<max depth>")
        return
    end
    seen[value]=true
    local keys={}
    for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local n=0
    for _,key in ipairs(keys) do
        if #lines>=MAX_LINES then return end
        n+=1
        if n>75 then add(string.rep("  ",level).."... more fields");break end
        local v=value[key]
        local prefix=string.rep("  ",level)..tostring(key).." = "
        if typeof(v)=="table" then
            add(prefix.."{")
            dump(v,level+1,seen)
            add(string.rep("  ",level).."}")
        else
            add(prefix..nice(v))
        end
    end
end
local loggedTables=setmetatable({},{__mode="k"})
local function record(path,v)
    if v==nil then return end
    if typeof(v)=="table" and loggedTables[v] then return end
    if typeof(v)=="table" then loggedTables[v]=true end
    found=true
    add("")
    add("=== "..path.." ===")
    dump(v,1,{})
end
local function probe(root,path)
    if typeof(root)~="table" then return end
    local containers={
        "currentQuestData","localQuestData","DredgeMasterQuestData",
        "currentQuest","questData","QuestData","quests","Quests"
    }
    local master=root.DredgeMaster or root.DredgeMasterQuest or root.DredgeMasterQuestData
    if master~=nil then record(path..".DredgeMaster",master) end
    for _,key in ipairs(containers) do
        local v=rawget(root,key)
        if typeof(v)=="table" then
            local dredge=v.DredgeMaster or v.DredgeMasterQuest or v.dredgeMaster or v.dredge
            if dredge~=nil then
                record(path.."."..key..".DredgeMaster",dredge)
            elseif key=="DredgeMasterQuestData" then
                record(path.."."..key,v)
            end
        end
    end
    local nested=rawget(root,"_G")
    if typeof(nested)=="table" and nested~=root then
        local c=nested.currentQuestData
        if typeof(c)=="table" and c.DredgeMaster~=nil then
            record(path.."._G.currentQuestData.DredgeMaster",c.DredgeMaster)
        end
        probeShallow(nested,path.."._G")
    end
end

-- Deliberately shallow secondary lookup, avoiding recursive env traversal.
function probeShallow(root,path)
    for _,key in ipairs({"currentQuestData","localQuestData","DredgeMasterQuestData"}) do
        local data=rawget(root,key)
        if typeof(data)=="table" then
            local v=data.DredgeMaster or data.dredgeMaster or data.DredgeMasterQuest
            if v~=nil then record(path.."."..key..".DredgeMaster",v) end
            if key=="DredgeMasterQuestData" then record(path.."."..key,data) end
        end
    end
end

add("DREDGE QUEST DIAGNOSTIC | "..os.date("%Y-%m-%d %H:%M:%S"))
add("Player: "..player.Name)
add("Mode: READ ONLY (no server requests)")

probe(_G,"executor._G")
if type(getgenv)=="function" then
    local ok,env=pcall(getgenv)
    if ok then probe(env,"getgenv()") end
end
if typeof(shared)=="table" then probe(shared,"shared") end

local folders={player:FindFirstChild("PlayerScripts"),player:FindFirstChild("PlayerGui")}
local seenScript={}
local scripts={}
for _,folder in ipairs(folders) do
    if folder then
        for _,obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("LocalScript") and not seenScript[obj] then
                local fullName=obj:GetFullName()
                local lo=fullName:lower()
                if lo:find("dredge",1,true) or lo:find("quest",1,true) then
                    seenScript[obj]=true
                    scripts[#scripts+1]=obj
                end
            end
        end
    end
end
table.sort(scripts,function(a,b) return a:GetFullName()<b:GetFullName() end)
add("")
add("Candidate quest LocalScripts: "..#scripts)
if type(getsenv)=="function" then
    for i,obj in ipairs(scripts) do
        if i>60 then add("... script scan limited to 60");break end
        local ok,env=pcall(getsenv,obj)
        if ok and typeof(env)=="table" then
            probe(env,"getsenv("..obj:GetFullName()..")")
        end
    end
else
    add("getsenv unavailable in this executor (needed for client quest cache).")
end

-- Look for quest data attached to player objects (attributes / ValueBases).
local objectHits=0
for _,obj in ipairs(player:GetDescendants()) do
    if objectHits>=50 then break end
    local path=obj:GetFullName()
    local lo=path:lower()
    if lo:find("dredge",1,true) then
        objectHits+=1
        add("")
        add("Instance: "..path.." ["..obj.ClassName.."]")
        if obj:IsA("ValueBase") then add("  Value: "..nice(obj.Value)) end
        local ok,attrs=pcall(function() return obj:GetAttributes() end)
        if ok and next(attrs) then dump(attrs,1,{}) end
    elseif (lo:find("quest",1,true) and not lo:find("playergui",1,true)) and obj:IsA("ValueBase") then
        objectHits+=1
        add("Quest value: "..path.." = "..nice(obj.Value))
    end
end

-- UI fallback: textual quest progress may be present even without getsenv.
local uiHits=0
local pg=player:FindFirstChild("PlayerGui")
if pg then
    for _,obj in ipairs(pg:GetDescendants()) do
        if uiHits>=80 then break end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t=obj.Text or ""
            local lowered=t:lower()
            local path=obj:GetFullName():lower()
            if t~="" and (
                lowered:find("dredge",1,true)
                or (path:find("quest",1,true) and (
                    lowered:find("collect",1,true)
                    or lowered:find("mineral",1,true)
                    or t:find("%d+%s*/%s*%d+")
                ))
            ) then
                uiHits+=1
                add("Quest UI: "..obj:GetFullName().." = "..t:gsub("[\r\n\t]"," "):sub(1,240))
            end
        end
    end
end
if not found then
    add("")
    add("No cached DredgeMaster quest table found.")
    add("Try opening your Dredge/Quest UI and run this script again.")
    add("Client files alone cannot retrieve server-only quest progress.")
end
add("")
add(string.format("Summary: found quest data=%s, matching instances=%d, GUI labels=%d",
    tostring(found),objectHits,uiHits))
local report=table.concat(lines,"\n")
print(report)
if type(setclipboard)=="function" then
    local ok=pcall(setclipboard,report)
    if ok then print("[DREDGE] Report copied to clipboard once.") end
end
