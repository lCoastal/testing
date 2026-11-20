-- GalaxisHub Route Tester (standalone; does not start Auto Dredge)
-- Uses the player's local GalaxisHub_ZonePresets.json. Run only while AUTO FARM/DREDGE are OFF.
-- Stop: getgenv().StopGalaxisRouteTest = true
local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local HS=game:GetService("HttpService")
local PF=game:GetService("PathfindingService")
local PPS=game:GetService("ProximityPromptService")
local E=getgenv()
if E.GalaxisRouteTestRunning then warn("[ROUTE TEST] Already running. Set StopGalaxisRouteTest=true");return end
E.StopGalaxisRouteTest=false
E.GalaxisRouteTestRunning=true
local MAP={
 ["Rubble Creek Sands"]="Rubble Creek",["Rubble Creek Deposits"]="Rubble Creek",
 ["Fortune River"]="Dredge Master",["Fortune River Delta"]="Fortune River Delta",
 ["Sunset Beach"]="Sunset Beach",["Crystal Cavern River"]="Crystal Caverns",
 ["Azuralite Oasis"]="Crystal Caverns",["Volcanic Sands"]="Museum",
 ["Volcanic Springs"]="Museum",["Windswept Beach"]="Volcanic Sands",
 ["Magma Furnace"]="The Magma Furnace",["Infernal Heart"]="The Magma Furnace",
 ["Frostbite River"]="Snowy Shores",["Frostbite Waterfall"]="Frostbitten Path",
 ["Frozen Peak"]="Frozen Peak",["Overgrown Grotto"]="Overgrown Grotto",
 ["Deeproot Spring"]="Deeproot Spring",["Enchanted Ruins"]="Deeproot Spring",
 ["Abyssal Depth"]="Overgrown Grotto",["Rotwood Swamp"]="Rotwood Swamp",
 ["Fungal Marsh"]="Timelocked Sanctuary",["Timelocked Sanctuary"]="Timelocked Sanctuary",
 ["Meteor Falls"]="Meteor Valley Entrance",["Starfall River"]="Meteor Valley",
 ["Astral Caverns"]="Meteor Valley",["Sandstone Stream"]="Sunscorched Desert",
 ["Mystic Floodplains"]="Mystic Floodplains",["Lifespring Oasis"]="Lifespring Oasis"
}
local NAME="GalaxisHub_RouteTest_"..os.date("%Y%m%d_%H%M%S")..".txt"
local lines={}
local function log(s)
 local line=string.format("[%s] %s",os.date("%H:%M:%S"),tostring(s))
 lines[#lines+1]=line
 print("[ROUTE TEST] "..line)
end
local function save()
 local report=table.concat(lines,"\n")
 if type(writefile)=="function" then pcall(writefile,NAME,report) end
 return report
end
local function live() return not E.StopGalaxisRouteTest and E.GalaxisRouteTestRunning end
local function root() local c=P.Character;return c and c:FindFirstChild("HumanoidRootPart") end
local function humanoid() local c=P.Character;return c and c:FindFirstChildOfClass("Humanoid") end
local function healthy()
 local h=humanoid();return h and h.Health>0 and root()~=nil
end
local function position(data)
 if type(data)~="table" or #data<3 then return nil end
 local x,y,z=tonumber(data[1]),tonumber(data[2]),tonumber(data[3])
 if x and y and z then return Vector3.new(x,y,z) end
end
local function world()
 local m=workspace:FindFirstChild("Map")
 return m and m:FindFirstChild("Waypoints")
end
local function pivot(obj)
 if not obj then return nil end
 local ok,cf=pcall(function() return obj:GetPivot() end)
 return ok and cf.Position or nil
end
local function stone(name)
 local w=world();return w and w:FindFirstChild(name)
end
local function waitAlive(maxSec)
 local t=os.clock()
 while live() and os.clock()-t<maxSec do
  if healthy() then return true end
  task.wait(.4)
 end
 return false
end
local function waitNear(pos,radius,maxSec)
 local t=os.clock();local inside
 while live() and os.clock()-t<maxSec do
  local r=root()
  if r and (r.Position-pos).Magnitude<=radius then
   inside=inside or os.clock()
   if os.clock()-inside>.4 then return true end
  else inside=nil end
  task.wait(.1)
 end
 return false
end
local function moveTo(pos,range,maxTime,jump)
 local h=humanoid();local r=root()
 if not h or not r or h.Health<=0 then return false,"character unavailable" end
 if (r.Position-pos).Magnitude<=range then return true end
 local t=os.clock();local last=r.Position;local unchanged=os.clock()
 h:MoveTo(pos)
 if jump then h.Jump=true end
 while live() and os.clock()-t<maxTime do
  r=root();h=humanoid()
  if not r or not h or h.Health<=0 then return false,"died" end
  local distance=(r.Position-pos).Magnitude
  if distance<=range then return true end
  if (r.Position-last).Magnitude>1.1 then last=r.Position;unchanged=os.clock() end
  if os.clock()-unchanged>1.35 then
   h.Jump=true
   h:MoveTo(pos)
   unchanged=os.clock()
  end
  task.wait(.12)
 end
 return false,"MoveTo timed out"
end
local function pathFallback(pos)
 local r=root();local h=humanoid()
 if not r or not h or h.Health<=0 then return false,"character missing" end
 local success,path=pcall(function()
  local p=PF:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=4})
  p:ComputeAsync(r.Position,pos)
  return p
 end)
 if not success or path.Status~=Enum.PathStatus.Success then
  return false,"path unavailable"
 end
 for _,node in ipairs(path:GetWaypoints()) do
  if not live() then return false,"cancelled" end
  local ok,err=moveTo(node.Position,6,5,node.Action==Enum.PathWaypointAction.Jump)
  if not ok then return false,err end
 end
 return true
end
local function visit(pos,jump)
 if not healthy() then return false,"died" end
 local r=root();local dist=(r.Position-pos).Magnitude
 if dist<7 then return true end
 local ok,err=moveTo(pos,6,math.clamp(dist/math.max(humanoid().WalkSpeed,8)*2.5+2,3,14),jump)
 if ok then return true end
 if not healthy() then return false,"died" end
 local repath,why=pathFallback(pos)
 return repath,repath and nil or (err.." / "..tostring(why))
end
local function triggerPrompt(prompt)
 if not prompt or not prompt:IsA("ProximityPrompt") then return false,"prompt missing" end
 local r=root();local at=pivot(prompt.Parent)
 if not r or not at or (r.Position-at).Magnitude>math.max(10,prompt.MaxActivationDistance) then
  return false,"out of prompt range"
 end
 if not prompt.Enabled then return false,"prompt disabled" end
 if type(fireproximityprompt)=="function" then
  local ok,err=pcall(fireproximityprompt,prompt)
  if ok then return true end
  log("PROMPT direct failed: "..tostring(err))
 end
 local ok,err=pcall(function()
  prompt:InputHoldBegin()
  task.wait(math.max(.65,prompt.HoldDuration+.2))
  prompt:InputHoldEnd()
 end)
 return ok,ok and nil or tostring(err)
end
local function climbRope()
 local map=workspace:FindFirstChild("Map")
 local lush=map and map:FindFirstChild("LushCaverns")
 local assets=lush and lush:FindFirstChild("AbyssAssets")
 local rope=assets and assets:FindFirstChild("Rope")
 local interact=rope and rope:FindFirstChild("RopeInteract")
 local prompt=interact and interact:FindFirstChild("Prompt")
 if not prompt then return false,"abyss rope missing" end
 local r=root();if not r then return false,"no character" end
 local before=r.Position.Y
 if before>-160 then return true end
 local at=pivot(interact)
 if not at then return false,"rope position missing" end
 local ok,err=visit(at)
 if not ok then return false,"cannot reach rope: "..tostring(err) end
 ok,err=triggerPrompt(prompt)
 if not ok then return false,err end
 local deadline=os.clock()+16
 while live() and os.clock()<deadline do
  r=root()
  if r and r.Position.Y>-160 then
   log("ABYSS ROPE: climbed to Y="..math.floor(r.Position.Y))
   return true
  end
  task.wait(.2)
 end
 return false,"rope climb not confirmed"
end
local function heldItem(name)
 local c=P.Character
 return c and c:FindFirstChild(name)
end
local function inventoryItem(name)
 local c=P.Character
 local b=P:FindFirstChild("BackpackTwo")
 local bag=P:FindFirstChildOfClass("Backpack")
 return (c and c:FindFirstChild(name))
    or (b and b:FindFirstChild(name))
    or (bag and bag:FindFirstChild(name))
end
local function equipItem(item)
 if not item then return false,"item missing" end
 if item.Parent==P.Character then return true end
 local rem=RS:FindFirstChild("Remotes")
 local cb=rem and rem:FindFirstChild("CustomBackpack")
 local equip=cb and cb:FindFirstChild("EquipRemote")
 if not equip then return false,"EquipRemote missing" end
 local ok,err=pcall(function() equip:FireServer(item) end)
 if not ok then return false,tostring(err) end
 local deadline=os.clock()+2
 while live() and os.clock()<deadline do
  if P.Character and P.Character:FindFirstChild(item.Name) then return true end
  task.wait(.08)
 end
 return false,"equip not confirmed"
end
local function currentPanName()
 for _,container in ipairs({P.Character,P:FindFirstChild("BackpackTwo"),P:FindFirstChildOfClass("Backpack")}) do
  if container then
   for _,child in ipairs(container:GetChildren()) do
    if child.Name:find("Pan",1,true) and child:IsA("Tool") then return child.Name end
   end
  end
 end
 return "Pharaoh's Pan"
end
local function testFlare()
 local savedPan=currentPanName()
 local flare=inventoryItem("Firefly Flare")
 if not flare then return false,"no Firefly Flare in inventory" end
 local ok,err=equipItem(flare)
 if not ok then return false,"flare equip: "..tostring(err) end
 local held=heldItem("Firefly Flare")
 local activated=false
 if held and held:IsA("Tool") then
  activated=pcall(function() held:Activate() end)
 end
 task.wait(.5)
 local pan=inventoryItem(savedPan)
 local panOk,panErr=equipItem(pan)
 local panHeld=heldItem(savedPan)~=nil
 log("ABYSS FLARE: Activate="..tostring(activated)
  .." panRestore="..tostring(panOk and panHeld)
  .." pan="..savedPan.." detail="..tostring(panErr))
 return activated and panOk and panHeld,
  "flare throw/placement not server-confirmed; equip restored="..tostring(panHeld)
end
local function fastestWaypoint(from,to)
 if from==to then return true end
 local rem=RS:FindFirstChild("Remotes")
 local misc=rem and rem:FindFirstChild("Misc")
 local travel=misc and misc:FindFirstChild("FastTravel")
 if not travel then return false,"FastTravel remote missing" end
 local fromPos,toPos=pivot(from),pivot(to)
 local r=root()
 if not r or not fromPos or not toPos then return false,"waypoint missing" end
 local d=(r.Position-fromPos).Magnitude
 if d>80 then return false,string.format("departure stone %.1f studs away",d) end
 if d>53 then
  local ok,err=visit(fromPos)
  r=root()
  d=r and (r.Position-fromPos).Magnitude or math.huge
  if d>53 then return false,"cannot approach departure stone: "..tostring(err) end
 end
 local ok,err=pcall(function() travel:FireServer(from,to) end)
 if not ok then return false,tostring(err) end
 if waitNear(toPos,85,12) then return true end
 return false,"FastTravel arrival not confirmed"
end
local function closestWaypoint(maxDist)
 local r=root();local w=world()
 if not r or not w then return nil,"no character/waypoints" end
 local nearest,d=nil,math.huge
 for _,entry in ipairs(w:GetChildren()) do
  local pos=pivot(entry)
  if pos then
   local dist=(r.Position-pos).Magnitude
   if dist<d then nearest,d=entry,dist end
  end
 end
 if d>maxDist then return nil,string.format("nearest waypoint %.1f studs away",d) end
 return nearest,d
end
local function recoverAtRubbleCreek()
 if not waitAlive(45) then return false,"character did not respawn" end
 local rubble=stone("Rubble Creek")
 local pos=pivot(rubble)
 local r=root()
 if not pos or not r then return false,"Rubble Creek waypoint unavailable" end
 local dist=(r.Position-pos).Magnitude
 log(string.format("RESPAWN RECOVERY: spawn-to-Rubble Creek waypoint %.1f studs",dist))
 if dist>550 then return false,"respawn >550 studs from Rubble Creek stone" end
 if dist<=55 then return true end
 local ok,err=visit(pos)
 if not ok then return false,"cannot walk from respawn to stone: "..tostring(err) end
 if not waitNear(pos,60,3) then return false,"did not reach Rubble Creek waypoint range" end
 log("RESPAWN RECOVERY: reached Rubble Creek waypoint")
 return true
end
-- Samples taken while falling are not pathfinding destinations.
-- Recognize near-vertical descending runs, let gravity complete the fall,
-- and verify that the character reaches the recorded landing level.
local function descendTo(pos,pointNo)
 local r=root()
 if not r then return false,"character missing" end
 local horizontal=Vector3.new(pos.X-r.Position.X,0,pos.Z-r.Position.Z).Magnitude
 if horizontal>10 then return false,"too far horizontally from drop: "..math.floor(horizontal) end
 if r.Position.Y<=pos.Y+6 then return true end
 local started=os.clock()
 local startY=r.Position.Y
 local lowest=startY
 while live() and os.clock()-started<12 do
  r=root()
  if not healthy() or not r then return false,"died during drop" end
  if r.Position.Y<=pos.Y+6 then
   log(string.format("DROP point %d reached Y %.1f (target %.1f)",pointNo,r.Position.Y,pos.Y))
   return true
  end
  lowest=math.min(lowest,r.Position.Y)
  if os.clock()-started>4 and lowest>startY-2 then
   return false,"not falling at vertical checkpoint (still at Y "..math.floor(r.Position.Y)..")"
  end
  task.wait(.08)
 end
 return false,"drop timeout at point "..pointNo
end
local function runRoute(nodes,jumps,zone,direction)
 local marked={}
 for _,i in ipairs(jumps or {}) do marked[i]=true end
 for i,cf in ipairs(nodes) do
  if not live() then return false,"stopped" end
  if not healthy() then return false,"died" end
  local pos=position(cf)
  if not pos then return false,"invalid node "..i end
  local r=root()
  -- The saved Abyss outbound route crosses the vertical shaft by rope.
  if zone=="Abyssal Depth" and direction=="OUT" and r
    and r.Position.Y<-180 and pos.Y>-160 then
   local ok,err=climbRope()
   if not ok then return false,"rope: "..tostring(err) end
  end
  local prev=i>1 and position(nodes[i-1]) or nil
  local vertical=prev and prev.Y-pos.Y>5 and
    (Vector3.new(prev.X-pos.X,0,prev.Z-pos.Z)).Magnitude<9
  local ok,err
  if direction=="IN" and vertical and pos.Y<prev.Y then
   -- If already below this in-air point, don't try to walk back upward.
   ok,err=descendTo(pos,i)
   if not ok then
    return false,string.format("DROP point %d/%d: %s",i,#nodes,tostring(err))
   end
  else
   ok,err=visit(pos,marked[i])
   if not ok then return false,
     string.format("%s point %d/%d: %s",direction,i,#nodes,tostring(err))
   end
  end
  if i%20==0 then log(zone.." "..direction.." "..i.."/"..#nodes) end
 end
 return true
end
local function timedAllowed(zone)
 local minute=os.date("*t").min
 if zone=="Timelocked Sanctuary" then return minute>=45 or minute<15 end
 if zone=="Infernal Heart" then return minute>=15 and minute<45 end
 return true
end
local function run()
 local beta=E.CoastalSafeFarm
 if beta and beta.alive and beta.running then
  error("Turn Auto Dredge / Auto Farm OFF before starting the route tester")
 end
 if type(readfile)~="function" then error("readfile is required to read your recorded routes") end
 local ok,raw=pcall(readfile,"GalaxisHub_ZonePresets.json")
 if not ok then error("Local GalaxisHub_ZonePresets.json not found. Load your uploaded preset into the executor's filesystem first.") end
 local data=HS:JSONDecode(raw)
 local zones=data.zones or {}
 local names={}
 for name,p in pairs(zones) do
  if MAP[name] and p.dig and p.route and #p.route>0 and p.routeOut and #p.routeOut>0 then
   names[#names+1]=name
  end
 end
 table.sort(names)
 -- Test Abyss before other zones so the flare+rope test appears early.
 for i,name in ipairs(names) do
  if name=="Abyssal Depth" then table.remove(names,i);table.insert(names,1,name);break end
 end
 log("START | "..#names.." zones | file=GalaxisHub_ZonePresets.json")
 log("Warning: real walking and warp only; Auto Dredge should be OFF.")
 local passed,failed,skipped=0,0,0
 local results={}
 for i,zone in ipairs(names) do
  if not live() then break end
  local preset=zones[zone]
  local wpName=preset.waypoint or MAP[zone]
  local targetStone=stone(wpName)
  local tpos=pivot(targetStone)
  local start=os.clock()
  log(string.format("ZONE %d/%d: %s | waypoint=%s in=%d out=%d",
   i,#names,zone,wpName,#preset.route,#preset.routeOut))
  if not timedAllowed(zone) then
   skipped+=1
   results[#results+1]=zone.." | SKIP | timed area closed by local schedule"
   log("SKIP (timed): "..zone)
   continue
  end
  if not targetStone or not tpos then
   failed+=1
   results[#results+1]=zone.." | FAIL | target waypoint missing"
   continue
  end
  -- If death occurred during a prior test, character returns to Rubble Creek.
  if not waitAlive(45) then log("STOP: character did not respawn");break end
  local from,dist=closestWaypoint(80)
  if not from then
   -- A fresh character starts in Rubble Creek, possibly farther than
   -- FastTravel range from its stone.
   local recovered,why=recoverAtRubbleCreek()
   if recovered then from,dist=closestWaypoint(80) end
   if not from then
    local msg="no departure stone: "..tostring(why)
    failed+=1
    results[#results+1]=zone.." | FAIL | "..msg
    log("FAIL "..zone.." | "..msg)
    break
   end
  end
  local warp,warpErr=fastestWaypoint(from,targetStone)
  if not warp then
   failed+=1
   results[#results+1]=zone.." | FAIL | travel to zone stone: "..tostring(warpErr)
   log("FAIL "..zone.." | "..tostring(warpErr))
   break -- Cannot assume starting waypoint for the next zone.
  end
  local into,inErr=runRoute(preset.route,preset.routeJumps,zone,"IN")
  if into then
   local digPos=position(preset.dig)
   if digPos then into,inErr=visit(digPos) end
  end
  local flareNote=""
  if into and zone=="Abyssal Depth" then
   local used,note=testFlare()
   flareNote=" | flare="..tostring(used)..": "..tostring(note)
   log("ABYSS FLARE TEST: "..flareNote)
  end
  local outward,outErr=false,"inbound failed"
  if into then
   outward,outErr=runRoute(preset.routeOut,preset.routeOutJumps,zone,"OUT")
  end
  local rr=root()
  local endDist=rr and (rr.Position-tpos).Magnitude or math.huge
  local back=outward and endDist<=65
  local status=into and back and "PASS" or "FAIL"
  local msg=string.format("%s | %s | IN=%s OUT=%s endpointDist=%.1f duration=%.1fs%s",
    zone,status,tostring(into),tostring(outward),endDist,os.clock()-start,flareNote)
  if not into then msg=msg.." | "..tostring(inErr)
  elseif not outward then msg=msg.." | "..tostring(outErr)
  elseif not back then msg=msg.." | did not reach waypoint travel range" end
  log(msg)
  results[#results+1]=msg
  if status=="PASS" then passed+=1 else failed+=1 end
  save()
  if not back then
   -- Do not claim further results after losing the route. Try to recover
   -- to Rubble Creek if death reset the character, otherwise stop.
   if not healthy() then
    log("DEATH: waiting for Rubble Creek respawn")
    local recovered,why=recoverAtRubbleCreek()
    if recovered then
     log("RESPAWN: safely at Rubble Creek waypoint; proceeding to next zone")
    else
     log("RESPAWN: recovery failed: "..tostring(why))
     break
    end
   else
    log("STOP: cannot verify return to waypoint; do not chain unsafe travel")
    break
   end
  end
 end
 log(string.format("SUMMARY: pass=%d fail=%d skip=%d of %d",passed,failed,skipped,#names))
 for _,result in ipairs(results) do log("RESULT "..result) end
end
local success,err=xpcall(run,debug.traceback)
if not success then log("ERROR: "..tostring(err)) end
local report=save()
E.GalaxisRouteTestRunning=false
if type(setclipboard)=="function" then pcall(setclipboard,report) end
log("Report: "..NAME.." (copied if clipboard available)")
save()
