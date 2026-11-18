-- GALAXIS HUB | DREDGE STEP 2: READ-ONLY CONTROLS DIAGNOSTIC
-- Finds Luck Cap controls, quest/turn-in UI, related remotes and client script environments.
-- NO FireServer, InvokeServer, GUI clicks, hooks, teleporting or mutations.
-- Prints a bounded report and copies it to clipboard ONCE (if supported).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:FindFirstChild("PlayerGui")
local ps = player:FindFirstChild("PlayerScripts")
local report = {}
local MAX = 320

local function add(v)
    if #report < MAX then report[#report + 1] = tostring(v) end
end
local function value(v)
    if typeof(v) == "Instance" then return v:GetFullName() end
    local t = tostring(v)
    return t:gsub("[\r\n\t]", " "):sub(1,200)
end
local function contains(text, patterns)
    local s = tostring(text):lower()
    for _,p in ipairs(patterns) do
        if s:find(p, 1, true) then return true end
    end
    return false
end
local focus = {
    "luckcap", "luck cap", "lucklimit", "luck limit", "capluck",
    "dredge", "quest", "claim", "redeem", "turnin", "turn in",
    "submit", "complete", "setting", "luck"
}
local remoteFocus = {
    "luck", "cap", "quest", "dredge", "claim", "submit", "redeem",
    "complete", "setting", "dialogue", "interact", "npc"
}
local function attrs(inst, limit)
    local ok,t = pcall(function() return inst:GetAttributes() end)
    if not ok then return end
    local count=0
    for k,v in pairs(t) do
        if contains(k,focus) then
            add("  @"..tostring(k).." = "..value(v))
            count+=1
            if count >= (limit or 12) then break end
        end
    end
end
local function envInfo(scr)
    if type(getsenv) ~= "function" then return end
    local ok,e=pcall(getsenv,scr)
    if not ok or typeof(e) ~= "table" then return end
    add("  getsenv: available")
    local n=0
    for k,v in pairs(e) do
        if contains(k,focus) then
            add("    "..value(k).." = ["..typeof(v).."] "..(typeof(v) == "table" and "" or value(v)))
            n+=1
            if n>=25 then break end
        end
    end
    local g=rawget(e,"_G")
    if typeof(g)=="table" then
        local q=rawget(g,"currentQuestData")
        if typeof(q)=="table" and typeof(q.DredgeMaster)=="table" then
            add("  DredgeMaster quest cache: FOUND")
            local d=q.DredgeMaster
            local steps=d.StepProgress
            if typeof(steps)=="table" then
                for i,x in pairs(steps) do
                    if typeof(x)=="table" then
                        add(string.format("    %s: %s %s (%s/%s)",tostring(i),
                            tostring(x.Amount),tostring(x.Collect),
                            tostring(x.Progress),tostring(x.Amount)))
                    end
                end
            end
        end
    end
end

add("GALAXIS HUB DREDGE CONTROLS DIAGNOSTIC")
add("Date: "..os.date("%Y-%m-%d %H:%M:%S"))
add("Mode: READ ONLY. No remote requests sent.")
add("Player: "..player.Name)

add("")
add("=== PLAYER / STATS / SETTINGS ATTRIBUTES ===")
local targets={
    player,
    player:FindFirstChild("Stats"),
    player:FindFirstChild("BaseStats"),
    pg and pg:FindFirstChild("MainUI"),
    pg and pg:FindFirstChild("MainUI") and pg.MainUI:FindFirstChild("Settings")
}
for _,obj in ipairs(targets) do
    add(obj:GetFullName())
    attrs(obj,20)
end

add("")
add("=== POTENTIAL LUCK CAP + DREDGE UI ELEMENTS ===")
local guiHits=0
if pg then
    for _,obj in ipairs(pg:GetDescendants()) do
        if guiHits>=110 or #report>=MAX-70 then break end
        if obj:IsA("GuiObject") then
            local path=obj:GetFullName()
            local nameHit=contains(obj.Name,{"luckcap","luck cap","lucklimit","luck limit","dredge","turnin","turn in","claim"})
            local labelText=""
            if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
                local ok,t=pcall(function() return obj.Text end)
                if ok then labelText=t end
            end
            local textHit=contains(labelText,{"luck cap","luck limit","dredge master","claim","complete quest","turn in"})
            if nameHit or textHit then
                guiHits+=1
                add("UI "..obj.ClassName..": "..path)
                if labelText~="" then add("  Text: "..value(labelText)) end
                attrs(obj,8)
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    add("  Interactable button; no click attempted.")
                end
            end
        end
    end
end
add("UI matches: "..guiHits)

add("")
add("=== RELEVANT REMOTE EVENTS / FUNCTIONS ===")
local remoteHits=0
local allRemotes=0
local fallback={}
for _,obj in ipairs(RS:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        allRemotes+=1
        if contains(obj.Name,remoteFocus) or contains(obj.Parent.Name,{"quest","dredge","setting","npc","shop"}) then
            if remoteHits<110 then
                remoteHits+=1
                add("REMOTE "..obj.ClassName..": "..obj:GetFullName())
                attrs(obj,5)
            end
        elseif #fallback<70 then
            fallback[#fallback+1]=obj
        end
    end
    if #report>=MAX-70 then break end
end
add("Related remotes: "..remoteHits.." | Scanned remote total: "..allRemotes)
if remoteHits<5 then
    add("Few named matches. Other remotes (sample, no requests sent):")
    for _,obj in ipairs(fallback) do
        if #report>=MAX-30 then break end
        add("  "..obj.ClassName..": "..obj:GetFullName())
    end
end

add("")
add("=== RELEVANT LOCAL SCRIPT ENVIRONMENTS ===")
local scriptHits=0
for _,dir in ipairs({ps,pg}) do
    if dir then
        for _,obj in ipairs(dir:GetDescendants()) do
            if scriptHits>=38 or #report>=MAX-20 then break end
            if obj:IsA("LocalScript") and
                contains(obj.Name,{"quest","dredge","luck","cap","setting","npc","dialogue"}) then
                scriptHits+=1
                add("SCRIPT: "..obj:GetFullName())
                envInfo(obj)
            end
        end
    end
end
add("Script matches: "..scriptHits)
if type(getsenv)~="function" then add("getsenv is unavailable in this executor.") end

add("")
add("NEXT: determine Luck Cap update UI/remote and Dredge claim/accept action.")
add("Nothing was modified in game.")
local out=table.concat(report,"\n")
print(out)
if type(setclipboard)=="function" then
    local ok=pcall(setclipboard,out)
    if ok then print("[GALAXIS DREDGE] Report copied to clipboard once.") end
end
