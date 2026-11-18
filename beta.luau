-- GALAXIS HUB | PROSPECTING BETA AUTO RECOVERY
-- Experimental fast farm + independent TSV mineral logger
-- Requires an executor with file APIs. Never toggles shovel activation.
-- Close button stops loops, disconnects listeners, flushes pending log entries.

local P = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local E = getgenv()
if E.CoastalSafeFarm and E.CoastalSafeFarm.Close then
    pcall(function() E.CoastalSafeFarm:Close() end)
end
if E.StopUniversalLogger then pcall(E.StopUniversalLogger) end

-- New timestamped .txt file on EVERY launch; never overwrite previous runs.
local BASE=os.date("%H-%M-%S")
local FILE=BASE..".txt"
local function fileExists(path)
    if type(isfile)=="function" then
        local ok,exists=pcall(isfile,path)
        if ok then return exists end
    end
    if type(readfile)=="function" then
        return pcall(readfile,path)
    end
    return false
end
local suffix=1
while fileExists(FILE) do
    suffix+=1
    FILE=BASE.."_"..suffix..".txt"
end
local HEADER="Time\tPan\tMineral\tMutation\tWeight (kg)\tItemID\tLuck\tSize Boost\tModifier Boost\tCapacity\tZone\n"
local CFG={dig=.025,shake=.028,shakeGap=.008,teleport=.06,panRetry=.035,rewardGap=.3,logGap=.5,timeout=3,digStall=1.25,recoveryDelay=.25,maxDig=600,maxShake=180}
-- Turbo timings are optional; regular timings remain available for comparison.
local TURBO={dig=.012,shake=.015,shakeGap=.005,teleport=.04,panRetry=.018}
local S={alive=true,running=false,token=0,cycles=0,dig=nil,water=nil,sell=false,selling=false,doubleShake=true,
    earlyTP=true,turbo=true,recentTimes={},totalCycleTime=0,
    waiting=false,completed=false,rewards=0,lastReward=0,seen={},links={},completion=nil,
    sellQueue={},lastQueuedCycle=0}
local L={running=true,pending={},unsaved={},seen=setmetatable({},{__mode="k"}),pan=0,minerals=0,lastItem=0,error=nil,writing=false}
E.CoastalSafeFarm=S
-- Exact Waypoints names: saved as human-selected dig/water position presets.
-- Only explicit LOAD PRESET changes the active farm coordinates.
-- The game has 21 FAST-TRAVEL WAYPOINTS but the toolkit has 35 MINING ZONES.
-- Zones own dig/water coordinates; many zones can map to the same waypoint.
local WAYPOINT_NAMES={
    "Crystal Caverns","Deeproot Spring","Dredge Master","Fortune River",
    "Fortune River Delta","Frostbitten Path","Frozen Peak","Lifespring Oasis",
    "Meteor Valley","Meteor Valley Entrance","Museum","Mystic Floodplains",
    "Overgrown Grotto","Rotwood Swamp","Rubble Creek","Snowy Shores",
    "Sunscorched Desert","Sunset Beach","The Magma Furnace",
    "Timelocked Sanctuary","Volcanic Sands"
}
-- Source: toolkit src/data/locs.js; keep the independent drop-location identifiers.
local ZONE_NAMES={
    "Rubble Creek Sands","Rubble Creek Deposits","Fortune River",
    "Fortune River Delta","Sunset Beach","Crystal Cavern River","Azuralite Oasis",
    "Volcanic Sands","Volcanic Springs","Windswept Beach","Magma Furnace",
    "Infernal Heart","Frostbite River","Frostbite Waterfall","Frozen Peak",
    "Overgrown Grotto","Deeproot Spring","Enchanted Ruins","Abyssal Depth",
    "Rotwood Swamp","Fungal Marsh","Timelocked Sanctuary","Meteor Falls",
    "Starfall River","Astral Caverns","Sandstone Stream","Mystic Floodplains",
    "Lifespring Oasis","Tomb Vein I","Tomb Vein II","Tomb Vein III",
    "The Void","Haunted Creek","North Pole","Seashell Beach"
}
local PRESET_FILE="GalaxisHub_ZonePresets.json" -- v2: separate zone -> waypoint map
local OLD_PRESET_FILE="GalaxisHub_FarmPresets.json" -- v1: waypoint presets, read-only
local waypointIndex,zoneIndex={},{}
for i,name in ipairs(WAYPOINT_NAMES) do waypointIndex[name]=i end
for i,name in ipairs(ZONE_NAMES) do zoneIndex[name]=i end
S.presets={}
S.defaultPresets={}
S.overrides={} -- Only user changes written to the local file
S.legacyWaypoints={}
S.selectedWaypoint=waypointIndex["Fortune River"]
S.selectedZone=zoneIndex["Fortune River"]
S.activeZone=nil

local function packCF(cf)
    if typeof(cf)~="CFrame" then return nil end
    return {cf:GetComponents()}
end
local function unpackCF(t)
    if type(t)~="table" or #t~=12 then return nil end
    for i=1,12 do
        if type(t[i])~="number" or t[i]~=t[i] or math.abs(t[i])>1e12 then return nil end
    end
    local ok,cf=pcall(function() return CFrame.new(table.unpack(t)) end)
    return ok and cf or nil
end
local function decodePresetFile(name)
    if type(readfile)~="function" then return nil end
    if type(isfile)=="function" then
        local ok,exists=pcall(isfile,name)
        if ok and not exists then return nil end
    end
    local ok,raw=pcall(readfile,name)
    if not ok then return nil end
    local decoded,data=pcall(function() return HttpService:JSONDecode(raw) end)
    return decoded and type(data)=="table" and data or nil
end
local function savePresets()
    if type(writefile)~="function" then return false,"writefile unavailable" end
    local ok,json=pcall(function()
        return HttpService:JSONEncode({
            version=2,
            selectedZone=ZONE_NAMES[S.selectedZone],
            selectedWaypoint=WAYPOINT_NAMES[S.selectedWaypoint],
            zones=S.overrides
        })
    end)
    if not ok then return false,tostring(json) end
    local written,err=pcall(writefile,PRESET_FILE,json)
    return written,written and nil or tostring(err)
end
local function validPreset(p)
    if type(p)~="table" then return nil end
    local dig,water=unpackCF(p.dig),unpackCF(p.water)
    local waypoint=type(p.waypoint)=="string" and waypointIndex[p.waypoint] and p.waypoint or nil
    if dig or water or waypoint then
        return {dig=packCF(dig),water=packCF(water),waypoint=waypoint}
    end
    return nil
end
-- Base presets supplied by the player: 28 configured zones.
-- Tomb Veins and limited-time areas remain unset; users may add their own.
-- New defaults are merged underneath the player's local saved overrides.
local DEFAULT_ZONE_PRESETS_JSON=[==[{"version":2,"zones":{"Volcanic Springs":{"water":[-891.6001586914062,16.129730224609375,-463.9439697265625,0.9738182425498962,4.684348020589368e-9,0.22732797265052795,7.601348439578715e-10,1,-2.3862357423354297e-8,-0.22732797265052795,2.341039895270569e-8,0.9738182425498962],"dig":[-888.2327880859375,19.946598052978516,-450.4830322265625,0.9378904700279236,7.006035929180143e-8,-0.34693145751953125,-5.8438928363102605e-8,1,4.3959808238014375e-8,0.34693145751953125,-2.0955184254489723e-8,0.9378904700279236],"waypoint":"Museum"},"Timelocked Sanctuary":{"waypoint":"Timelocked Sanctuary","dig":[-2797.513671875,-58.471378326416016,1378.9716796875,0.9821836948394775,-5.667398639275234e-8,0.18792344629764557,5.4878366739785633e-8,1,1.4757874922111114e-8,-0.18792344629764557,-4.1820120699753716e-9,0.9821836948394775],"water":[-2781.85498046875,-61.000614166259766,1386.852783203125,-0.747072160243988,6.357750237384607e-8,-0.6647429466247559,6.0187739236994275e-9,1,8.887803204515876e-8,0.6647429466247559,6.239736904944948e-8,-0.747072160243988]},"Frostbite River":{"waypoint":"Snowy Shores","dig":[-1463.9600830078125,14.248823165893555,-2312.603515625,-0.9989777207374573,-1.9932404171640883e-8,-0.04520475119352341,-1.892527023983348e-8,1,-2.270735599552154e-8,0.04520475119352341,-2.18286313469207e-8,-0.9989777207374573],"water":[-1463.7332763671875,11.663053512573242,-2326.898681640625,0.998001217842102,-6.150593367948431e-10,-0.0631951093673706,-9.83211179139687e-10,1,-2.525995057567343e-8,0.0631951093673706,2.5271594594755697e-8,0.998001217842102]},"Mystic Floodplains":{"waypoint":"Mystic Floodplains","dig":[-5952.4365234375,157.4579620361328,-723.9244384765625,0.13070929050445557,-1.4352758093139073e-8,-0.9914207458496094,-2.7243970635026926e-8,1,-1.8068815776928204e-8,0.9914207458496094,2.9371999943350602e-8,0.13070929050445557],"water":[-5941.9765625,154.3866424560547,-735.4666137695312,0.7313604950904846,-8.181835653431335e-9,-0.6819911003112793,5.222612564637075e-9,1,-6.396305263223212e-9,0.6819911003112793,1.1162297752775885e-9,0.7313604950904846]},"Fortune River":{"water":[-535.3941040039062,8.999999046325684,-59.93074417114258,-0.15197649598121643,9.882730722665656e-8,-0.9883841276168823,2.5226734590155786e-10,1,9.994997185458487e-8,0.9883841276168823,1.4940710002520063e-8,-0.15197649598121643],"dig":[-550.1090698242188,11.829303741455078,-61.64445877075195,-0.9968495965003967,1.8876454177529922e-8,-0.07931512594223022,1.9152615493567282e-8,1,-2.721075587075461e-9,0.07931512594223022,-4.231595074344341e-9,-0.9968495965003967],"waypoint":"Dredge Master"},"Rubble Creek Deposits":{"water":[-105.99281311035156,9,33.946773529052734,-0.04471517354249954,8.365498160856077e-8,-0.9989997744560242,1.3587669878134534e-9,1,8.367791792807111e-8,0.9989997744560242,2.384264785604273e-9,-0.04471517354249954],"dig":[-121.72286987304688,11.053008079528809,32.64851760864258,0.9974461197853088,-1.6323816964813886e-8,0.07142266631126404,1.88620621344171e-8,1,-3.4863909093019174e-8,-0.07142266631126404,3.612204935166119e-8,0.9974461197853088],"waypoint":"Rubble Creek"},"Rotwood Swamp":{"waypoint":"Rotwood Swamp","dig":[-1964.138916015625,23.5592041015625,1174.0201416015625,0.5378245711326599,3.249122570991858e-8,-0.8430567979812622,6.737462143746598e-8,1,8.152114361337226e-8,0.8430567979812622,-1.0064470501447431e-7,0.5378245711326599],"water":[-1951.542236328125,18.35124969482422,1170.722412109375,0.19294562935829163,-4.8913321393229126e-8,-0.9812094569206238,-6.697661980581415e-9,1,-5.116706347507716e-8,0.9812094569206238,1.6444269945736778e-8,0.19294562935829163]},"Deeproot Spring":{"waypoint":"Deeproot Spring","dig":[262.697265625,-163.9412078857422,1128.542724609375,0.6791316270828247,9.476055495838409e-9,-0.734016478061676,3.2711624520231908e-9,1,1.5936434394347998e-8,0.734016478061676,-1.3224023653890526e-8,0.6791316270828247],"water":[248.22486877441406,-165.8150634765625,1123.1802978515625,0.7444959282875061,-2.4664837283694396e-8,0.6676269769668579,-4.9500656018608424e-8,1,9.214408436264421e-8,-0.6676269769668579,-1.0164887243035992e-7,0.7444959282875061]},"Fungal Marsh":{"waypoint":"Timelocked Sanctuary","dig":[-2668.52685546875,20.703285217285156,1254.68212890625,0.2831985056400299,-3.466764297854752e-8,-0.959061324596405,-1.0889387880297363e-7,1,-6.830244103639416e-8,0.959061324596405,1.2377905989069404e-7,0.2831985056400299],"water":[-2667.951171875,18.37548065185547,1244.6072998046875,0.4163704216480255,-8.652551031218536e-8,-0.909195065498352,-4.267471709340498e-8,1,-1.1471026084564073e-7,0.909195065498352,8.656159877773462e-8,0.4163704216480255]},"Frozen Peak":{"waypoint":"Frozen Peak","dig":[-1456.450927734375,359.48321533203125,-3109.02734375,-0.3760899305343628,5.418522164291062e-8,-0.9265831708908081,8.020072073122719e-8,1,2.5925938729187692e-8,0.9265831708908081,-6.45621582862077e-8,-0.3760899305343628],"water":[-1462.328857421875,354.77386474609375,-3121.185546875,0.9173180460929871,5.374394262958049e-8,0.39815521240234375,-2.4330804038186216e-9,1,-1.2937677240643097e-7,-0.39815521240234375,1.1771090413503771e-7,0.9173180460929871]},"Windswept Beach":{"water":[-971.2080078125,9.163822174072266,-804.7001342773438,0.9628453254699707,-1.0572350106485828e-8,-0.2700534462928772,1.7250951778180479e-9,1,-3.2998467958123e-8,0.2700534462928772,3.130655201744048e-8,0.9628453254699707],"dig":[-979.2021484375,14.064384460449219,-783.4978637695312,-0.9517496824264526,-5.644607625754361e-8,0.30687540769577026,-6.257167228795879e-8,1,-1.0122981564109068e-8,-0.30687540769577026,-2.8836252496944326e-8,-0.9517496824264526],"waypoint":"Volcanic Sands"},"Sunset Beach":{"waypoint":"Sunset Beach","dig":[-73.40966796875,11.488126754760742,-481.25384521484375,0.9927338361740112,-1.0855862875303046e-8,0.12033078074455261,3.956567518059728e-9,1,5.757499721426029e-8,-0.12033078074455261,-5.6680551807630764e-8,0.9927338361740112],"water":[-75.18217468261719,9,-499.81402587890625,0.9954444766044617,2.087231498748565e-9,0.095343217253685,2.65547472899641e-9,1,-4.961662725122551e-8,-0.095343217253685,4.964378064187258e-8,0.9954444766044617]},"Overgrown Grotto":{"waypoint":"Overgrown Grotto","dig":[114.39781188964844,-131.63876342773438,896.1094360351562,0.6101309061050415,2.036335544630674e-8,0.7923006415367126,4.2163289526442327e-10,1,-2.6026238941767588e-8,-0.7923006415367126,1.6213473230664022e-8,0.6101309061050415],"water":[107.11598205566406,-133.7900848388672,890.5596923828125,0.6065621972084045,6.468681590376946e-8,0.7950360178947449,9.386144306233746e-9,1,-8.852441624185303e-8,-0.7950360178947449,6.115788409033485e-8,0.6065621972084045]},"Sandstone Stream":{"water":[-6511.142578125,154.3866424560547,-286.5010070800781,-0.32213497161865234,-4.9084100339769066e-8,-0.9466937780380249,-3.9770634008284844e-10,1,-5.171258976588433e-8,0.9466937780380249,-1.628192691782715e-8,-0.32213497161865234],"dig":[-6532.244140625,157.79470825195312,-293.44329833984375,-0.43457335233688354,2.1864510202362908e-8,0.9006364345550537,4.536166109403439e-9,1,-2.208794924740687e-8,-0.9006364345550537,-5.513398182444007e-9,-0.43457335233688354],"waypoint":"Sunscorched Desert"},"Astral Caverns":{"water":[-5518.2138671875,104.18557739257812,1475.530029296875,0.19619199633598328,9.097912823108345e-8,0.9805654883384705,1.2795112191987812e-10,1,-9.280790891352808e-8,-0.9805654883384705,1.8333633278189154e-8,0.19619199633598328],"dig":[-5503.5810546875,109.58366394042969,1479.0711669921875,-0.9490302801132202,-8.81357422599649e-8,-0.31518495082855225,-6.699248444874684e-8,1,-7.791566503101421e-8,0.31518495082855225,-5.282930004568698e-8,-0.9490302801132202],"waypoint":"Meteor Valley"},"Lifespring Oasis":{"waypoint":"Lifespring Oasis","dig":[-5847.04296875,157.95791625976562,-148.60360717773438,0.9648867249488831,3.7013457188095344e-8,-0.2626663148403168,-3.224290878733882e-8,1,2.2472248062399558e-8,0.2626663148403168,-1.3214047633880455e-8,0.9648867249488831],"water":[-5832.2060546875,154.3866424560547,-134.9605255126953,-0.6665259003639221,4.873164982654998e-8,-0.7454818487167358,-2.710463853361489e-9,1,6.779271899404193e-8,0.7454818487167358,4.72062069434287e-8,-0.6665259003639221]},"Meteor Falls":{"waypoint":"Meteor Valley Entrance","dig":[-4824.78271484375,109.67481994628906,1605.961669921875,0.06301112473011017,-1.8004751467515234e-8,0.9980128407478333,-4.123866581551283e-9,1,1.8300967852269423e-8,-0.9980128407478333,-5.268836478222738e-9,0.06301112473011017],"water":[-4838.6513671875,106.97921752929688,1604.2056884765625,0.12369923293590546,1.06490148255034e-7,0.9923197627067566,-1.761234214026075e-10,1,-1.072923936362713e-7,-0.9923197627067566,1.309721575637468e-8,0.12369923293590546]},"Abyssal Depth":{"water":[245.873779296875,-258.7674560546875,768.91796875,0.2747102677822113,-2.646487473612069e-8,0.9615270495414734,-2.382970620828928e-8,1,3.4331993248315484e-8,-0.9615270495414734,-3.234425705045396e-8,0.2747102677822113],"dig":[257.52960205078125,-256.7026672363281,768.1597290039062,-0.8952816128730774,5.338381292574468e-9,0.4455006718635559,1.4275093107585235e-8,1,1.670445826107425e-8,-0.4455006718635559,2.13147579586348e-8,-0.8952816128730774],"waypoint":"Overgrown Grotto"},"Enchanted Ruins":{"water":[319.21575927734375,-209.642333984375,1133.5440673828125,0.9895275235176086,1.1972348445965508e-8,0.14434431493282318,2.4658173281011386e-9,1,-9.984697157960909e-8,-0.14434431493282318,9.915725485143412e-8,0.9895275235176086],"dig":[322.2826843261719,-207.07125854492188,1147.1417236328125,-0.9506480097770691,-1.659419446298216e-8,-0.31027141213417053,4.168923262160007e-10,1,-5.476016085026458e-8,0.31027141213417053,-5.218698717612824e-8,-0.9506480097770691],"waypoint":"Deeproot Spring"},"Azuralite Oasis":{"water":[-142.69296264648438,-40.575233459472656,531.5817260742188,-0.3794470429420471,1.841604380103945e-8,0.9252134561538696,1.1323890269920867e-8,1,-1.526050752431729e-8,-0.9252134561538696,4.686460997049835e-9,-0.3794470429420471],"dig":[-138.9603729248047,-35.8428955078125,518.2411499023438,-0.7203456163406372,-6.894685355973706e-8,0.6936153173446655,-4.9125478795986055e-8,1,4.838349099145489e-8,-0.6936153173446655,7.78651421118326e-10,-0.7203456163406372],"waypoint":"Crystal Caverns"},"Frostbite Waterfall":{"water":[-1469.921142578125,147.05563354492188,-2702.021240234375,-0.971365749835968,5.3586941106686936e-8,0.23758921027183533,5.011078130223723e-8,1,-2.0670336553507695e-8,-0.23758921027183533,-8.172676757567388e-9,-0.971365749835968],"dig":[-1466.429443359375,149.9092254638672,-2714.98828125,0.353004515171051,-5.395235902483364e-8,0.9356216192245483,-7.397958512456171e-8,1,8.557677944054376e-8,-0.9356216192245483,-9.942588974354294e-8,0.353004515171051],"waypoint":"Frostbitten Path"},"Infernal Heart":{"water":[-1152.23876953125,-90.15330505371094,53.036827087402344,-0.8495063781738281,-2.6581373546719078e-8,-0.5275783538818359,4.203474901487425e-9,1,-5.715217810120521e-8,0.5275783538818359,-5.076880071896994e-8,-0.8495063781738281],"dig":[-1154.800537109375,-87.84814453125,44.64744567871094,0.9450898170471191,1.2503302571076347e-7,-0.32681071758270264,-1.160604625738415e-7,1,4.695521127473512e-8,0.32681071758270264,-6.447089084815616e-9,0.9450898170471191],"waypoint":"The Magma Furnace"},"Magma Furnace":{"water":[-1228.495361328125,-90.15330505371094,-88.44580841064453,0.28390851616859436,7.151187730869424e-8,-0.9588513970375061,5.740499986472969e-8,1,9.157795233249999e-8,0.9588513970375061,-8.104262150254726e-8,0.28390851616859436],"dig":[-1223.5780029296875,-89.00021362304688,-97.9509506225586,-0.9903417825698853,9.394377542548682e-8,-0.13864776492118835,9.40054505349508e-8,1,6.103621164044171e-9,0.13864776492118835,-6.98897473228044e-9,-0.9903417825698853],"waypoint":"The Magma Furnace"},"Rubble Creek Sands":{"water":[-81.39066314697266,8.999999046325684,40.63431167602539,0.10888993740081787,-8.738888723769378e-9,0.994053840637207,3.674560655753112e-11,1,8.787137240062748e-9,-0.994053840637207,-9.203036666072251e-10,0.10888993740081787],"dig":[-66.95266723632812,10.668807983398438,31.711631774902344,0.007483333349227905,-4.912990192451616e-8,-0.9999719858169556,1.2491962325666961e-11,1,-4.913118445415421e-8,0.9999719858169556,3.5517344620927815e-10,0.007483333349227905],"waypoint":"Rubble Creek"},"Starfall River":{"water":[-5404.41650390625,106.97864532470703,1510.4541015625,0.9514889121055603,4.989977497871223e-8,0.3076830506324768,-3.15993524679925e-8,1,-6.44603019850365e-8,-0.3076830506324768,5.161067662129426e-8,0.9514889121055603],"dig":[-5395.7939453125,109.26429748535156,1522.481201171875,0.9356088042259216,1.9484214242027065e-9,0.3530384600162506,-5.74576053402609e-10,1,-3.996286856988718e-9,-0.3530384600162506,3.5361136241363056e-9,0.9356088042259216],"waypoint":"Meteor Valley"},"Crystal Cavern River":{"water":[-109.16580200195312,-11.244487762451172,423.5841979980469,-0.7521693110466003,4.866406300152448e-8,0.6589698791503906,-1.1224072782312078e-9,1,-7.512984012691959e-8,-0.6589698791503906,-5.7249991414209944e-8,-0.7521693110466003],"dig":[-101.75530242919922,-8.561837196350098,416.5581359863281,-0.9096121191978455,2.9759432695897203e-9,-0.4154585897922516,-4.363401640006259e-9,1,1.671633853561616e-8,0.4154585897922516,1.7018194853335444e-8,-0.9096121191978455],"waypoint":"Crystal Caverns"},"Volcanic Sands":{"waypoint":"Museum","dig":[-723.4058837890625,12.685310363769531,-272.84515380859375,-0.41539236903190613,-9.255173694100449e-8,-0.9096423387527466,7.34400718016559e-9,1,-1.0509887005127894e-7,0.9096423387527466,-5.033768957218854e-8,-0.41539236903190613],"water":[-718.4039916992188,9.16382122039795,-284.1190185546875,0.8849422335624695,1.8496555398428427e-8,-0.46570077538490295,-5.509117606550262e-9,1,2.9249049404711513e-8,0.46570077538490295,-2.3318118991255687e-8,0.8849422335624695]},"Fortune River Delta":{"water":[-266.49420166015625,9,-770.8576049804688,0.6402298808097839,5.912781020356306e-8,-0.7681833505630493,3.0562766539787845e-8,1,1.0244299630812748e-7,0.7681833505630493,-8.906487636295424e-8,0.6402298808097839],"dig":[-283.9589538574219,12.91366195678711,-779.0611572265625,0.9324533939361572,5.163301608490656e-8,-0.3612902760505676,-1.167207486219013e-8,1,1.1278839195938417e-7,0.3612902760505676,-1.0095291003153761e-7,0.9324533939361572],"waypoint":"Fortune River Delta"}}}]==]
local function mergePreset(base,extra)
    base=base or {}
    if not extra then return base end
    if extra.dig~=nil then base.dig=extra.dig end
    if extra.water~=nil then base.water=extra.water end
    if extra.waypoint~=nil then base.waypoint=extra.waypoint end
    return base
end
local function loadPresets()
    local ok,builtin=pcall(function() return HttpService:JSONDecode(DEFAULT_ZONE_PRESETS_JSON) end)
    if ok and type(builtin)=="table" and type(builtin.zones)=="table" then
        for _,name in ipairs(ZONE_NAMES) do
            local p=validPreset(builtin.zones[name])
            if p then
                S.defaultPresets[name]=p
                S.presets[name]=mergePreset({},p)
            end
        end
    end
    -- Preserve waypoint presets created by earlier versions as optional manual imports.
    local legacy=decodePresetFile(OLD_PRESET_FILE)
    if legacy and type(legacy.points)=="table" then
        for _,wp in ipairs(WAYPOINT_NAMES) do
            local old=validPreset(legacy.points[wp])
            if old then
                S.legacyWaypoints[wp]=old
                if zoneIndex[wp] then
                    local moved={dig=old.dig,water=old.water,waypoint=wp}
                    S.overrides[wp]=mergePreset(S.overrides[wp],moved)
                    S.presets[wp]=mergePreset(S.presets[wp],moved)
                end
            end
        end
    end
    -- Existing v2 files are user-specific and override only fields they contain.
    local saved=decodePresetFile(PRESET_FILE)
    if saved and saved.version==2 and type(saved.zones)=="table" then
        for _,name in ipairs(ZONE_NAMES) do
            local parsed=validPreset(saved.zones[name])
            if parsed then
                S.overrides[name]=mergePreset(S.overrides[name],parsed)
                S.presets[name]=mergePreset(S.presets[name],parsed)
            end
        end
        if zoneIndex[saved.selectedZone] then S.selectedZone=zoneIndex[saved.selectedZone] end
        if waypointIndex[saved.selectedWaypoint] then S.selectedWaypoint=waypointIndex[saved.selectedWaypoint] end
    end
    -- Exact name matches are safe defaults for zones not configured elsewhere.
    for _,name in ipairs(ZONE_NAMES) do
        if waypointIndex[name] and not S.presets[name] then
            S.presets[name]={waypoint=name}
        end
    end
end
loadPresets()
local function waypointFolder()
    local map=workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Waypoints")
end
local function getWaypointCF(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then
        obj=obj:FindFirstChildWhichIsA("BasePart",true)
    end
    if not obj then return nil end
    local ok,cf=pcall(function() return obj:GetPivot() end)
    return ok and cf or nil
end
local function closestWaypoint(folder,pos)
    local best,dist=nil,math.huge
    for _,node in ipairs(folder:GetChildren()) do
        local cf=getWaypointCF(node)
        if cf then
            local d=(cf.Position-pos).Magnitude
            if d<dist then best=node;dist=d end
        end
    end
    return best
end

local function timing(key)
    return (S.turbo and TURBO[key]) or CFG[key]
end

local function valid(id) return S.alive and S.running and S.token==id end
local function bind(sig,fn) local c=sig:Connect(fn);S.links[#S.links+1]=c;return c end
local function root() local c=P.Character;return c and c:FindFirstChild("HumanoidRootPart") end
local function panTool()
    local c=P.Character
    if not c then return end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local x=t:FindFirstChild("Scripts")
            local d=x and x:FindFirstChild("Collect")
            local p=x and x:FindFirstChild("Pan")
            local s=x and x:FindFirstChild("Shake")
            if d and p and s and d:IsA("RemoteFunction") and p:IsA("RemoteFunction") and s:IsA("RemoteEvent") then
                return {tool=t,dig=d,pan=p,shake=s,done=x:FindFirstChild("PanningComplete")}
            end
        end
    end
end
local function fill(r) return tonumber(r.tool:GetAttribute("Fill")) end
local function capacity()
    local a=P:FindFirstChild("Stats")
    return a and tonumber(a:GetAttribute("Capacity"))
end
local function pause(sec,id,ready)
    local deadline=os.clock()+sec
    while os.clock()<deadline do
        if not valid(id) then return false end
        if ready and ready() then return true end
        task.wait(.01)
    end
    return valid(id)
end
local function invoke(r,id,...)
    if not valid(id) then return false end
    local args=table.pack(...)
    local done,ok,res=false,false,nil
    task.spawn(function()
        if valid(id) then
            ok,res=pcall(function() return r:InvokeServer(table.unpack(args,1,args.n)) end)
        end
        done=true
    end)
    local deadline=os.clock()+CFG.timeout
    while not done and valid(id) and os.clock()<deadline do task.wait(.01) end
    return done and ok and valid(id),res
end
local function move(cf,id)
    for _=1,2 do
        if not valid(id) then return false end
        local r=root()
        if not r then return false end
        if (r.Position-cf.Position).Magnitude<7 then return true end
        local ok=pcall(function() r.CFrame=cf end)
        if not ok or not pause(timing("teleport"),id) then return false end
        r=root()
        if r and (r.Position-cf.Position).Magnitude<10 then return true end
    end
    return false
end

-- Persistent tab-separated logger
local function cell(v)
    local s=tostring(v==nil and "" or v)
    return (s:gsub("[\t\r\n]"," "))
end
local function search(root,names)
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
local function stat(names)
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
local function zone()
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
local function itemData(item)
    local d=item:FindFirstChild("ItemData")
    if not d then return nil,nil,false end
    local weight=d:GetAttribute("Weight")
    local mutation=d:GetAttribute("Modifier")
    if weight==nil then weight=search(d,{"Weight"}) end
    if mutation==nil then mutation=search(d,{"Modifier","Mutation"}) end
    return weight,mutation,true
end
local function flush()
    if L.writing or #L.unsaved==0 then return end
    L.writing=true
    -- Move queued rows aside BEFORE a potentially yielding file operation.
    -- New batches appended during a write must not be erased afterward.
    local batch=L.unsaved
    L.unsaved={}
    local chunk=table.concat(batch)
    local ok,err=pcall(function()
        if type(appendfile)=="function" then
            appendfile(FILE,chunk)
        elseif type(readfile)=="function" and type(writefile)=="function" then
            writefile(FILE,readfile(FILE)..chunk)
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
        warn("[GALAXIS HUB LOGGER] Write failure:",err)
    end
    L.writing=false
end
local function finishBatch()
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
local function logItem(item)
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
-- Start a new session file now, including the TSV column names.
if type(writefile)=="function" then
    local ok,err=pcall(writefile,FILE,HEADER)
    if not ok then L.error=tostring(err) end
else
    L.error="Executor lacks writefile"
end
local backpack=P:WaitForChild("BackpackTwo")
for _,item in ipairs(backpack:GetChildren()) do L.seen[item]=true end
local function stopLogger()
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

-- Minimal monochrome UI
local G=Instance.new("ScreenGui")
G.Name="GalaxisHubBeta";G.ResetOnSpawn=false;G.DisplayOrder=9999
local parent=P:WaitForChild("PlayerGui")
if type(gethui)=="function" then
    local ok,v=pcall(gethui)
    if ok and v then parent=v end
end
G.Parent=parent
local BG=Color3.fromRGB(22,23,27)
local PANEL=Color3.fromRGB(39,41,47)
local FG=Color3.fromRGB(237,237,241)
local MUTED=Color3.fromRGB(145,148,158)
local function make(class,props,par)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=par
    return o
end
local function rounded(o)
    make("UICorner",{CornerRadius=UDim.new(0,7)},o)
    return o
end
local W=rounded(make("Frame",{
    Size=UDim2.fromOffset(340,610),
    Position=UDim2.new(.5,-170,.5,-305),
    BackgroundColor3=BG,BorderSizePixel=0,Active=true
},G))
make("UIStroke",{Color=Color3.fromRGB(69,71,79),Thickness=1},W)
local H=make("Frame",{Size=UDim2.new(1,0,0,43),BackgroundTransparency=1,Active=true},W)
make("TextLabel",{
    Position=UDim2.fromOffset(14,0),Size=UDim2.fromOffset(245,43),
    BackgroundTransparency=1,Text="GALAXIS HUB  /  BETA",
    TextColor3=FG,Font=Enum.Font.GothamBold,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
},H)
local function button(txt,x,y,w,h,par)
    return rounded(make("TextButton",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundColor3=PANEL,BorderSizePixel=0,Text=txt,
        TextColor3=FG,Font=Enum.Font.GothamMedium,TextSize=12,AutoButtonColor=true
    },par or W))
end
local X=button("×",302,7,29,29,H)
local Min=button("−",269,7,29,29,H)
local Body=make("Frame",{Position=UDim2.fromOffset(0,43),Size=UDim2.new(1,0,1,-43),BackgroundTransparency=1},W)
local function label(txt,x,y,w,h,size,color)
    return make("TextLabel",{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundTransparency=1,Text=txt,TextColor3=color or FG,
        Font=Enum.Font.Gotham,TextSize=size or 11,TextXAlignment=Enum.TextXAlignment.Left
    },Body)
end
local status=label("Idle",14,7,312,24,12,MUTED)
local digB=button("SET DIG",14,38,149,36,Body)
local waterB=button("SET WATER",177,38,149,36,Body)
local digXYZ=label("Not saved",14,78,149,22,10,MUTED)
local waterXYZ=label("Not saved",177,78,149,22,10,MUTED)
digXYZ.TextXAlignment=Enum.TextXAlignment.Center
waterXYZ.TextXAlignment=Enum.TextXAlignment.Center
local sellB=button("AUTO SELL: OFF",14,110,312,36,Body)
local farmB=button("AUTO FARM: OFF",14,157,312,40,Body)
-- Compact footer: the only stats shown are current pan, total minerals, and average time.
local statsFooter=label("Pan: 0 | Minerals: 0 | Avg: --",14,213,312,27,12,FG)
statsFooter.Font=Enum.Font.GothamBold

-- Zone and waypoint selectors are separate: one warp may serve multiple deposits.
local zoneTitle=label("MINING ZONE",14,247,312,18,10,MUTED)
local prevZone=button("<",14,271,36,32,Body)
local zoneName=label("",56,271,228,32,12,FG)
zoneName.TextXAlignment=Enum.TextXAlignment.Center
zoneName.Font=Enum.Font.GothamMedium
local nextZone=button(">",290,271,36,32,Body)

local warpTitle=label("FAST TRAVEL WAYPOINT",14,312,312,18,10,MUTED)
local prevWaypoint=button("<",14,335,36,32,Body)
local waypointName=label("",56,335,228,32,12,FG)
waypointName.TextXAlignment=Enum.TextXAlignment.Center
waypointName.Font=Enum.Font.GothamMedium
local nextWaypoint=button(">",290,335,36,32,Body)
local loadZone=button("LOAD ZONE",14,380,149,36,Body)
local mapWaypoint=button("MAP TO WAYPOINT",177,380,149,36,Body)
local travelWaypoint=button("FAST TRAVEL",14,423,149,36,Body)
local importLegacy=button("IMPORT OLD WP",177,423,149,36,Body)
local presetStatus=label("",14,466,312,21,11,MUTED)
label("SET DIG / WATER saves to MINING ZONE",14,491,312,19,10,MUTED)
local exportPresetButton=button("EXPORT PRESETS TO TXT + CLIPBOARD",14,519,312,35,Body)
local function selectedZone() return ZONE_NAMES[S.selectedZone] end
local function selectedWaypoint() return WAYPOINT_NAMES[S.selectedWaypoint] end
local function refreshPreset()
    local name=selectedZone()
    local p=S.presets[name]
    zoneName.Text=name
    waypointName.Text=selectedWaypoint()
    local mapping=p and p.waypoint or nil
    presetStatus.Text=((p and unpackCF(p.dig)) and "Dig saved" or "Dig missing")..
        " | "..((p and unpackCF(p.water)) and "Water saved" or "Water missing")..
        (mapping and (" | WP: "..mapping) or " | WP: NOT MAPPED")
    -- Only explicit MAP TO WAYPOINT commits the selector to this zone.
end
refreshPreset()
local function show(t) if S.alive then status.Text=t end end
local function xyz(cf)
    local p=cf.Position
    return string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
end
task.spawn(function()
    while S.alive do
        local currentPan=S.cycles+(S.running and 1 or 0)
        local collected=L.minerals+#L.pending
        local avg=S.cycles>0 and string.format("%.2fs",S.totalCycleTime/S.cycles) or "--"
        statsFooter.Text=string.format("Pan: %d  |  Minerals: %d  |  Avg: %s",currentPan,collected,avg)
        task.wait(.25)
    end
end)

local function stop()
    if not S.alive then return end
    -- This invalidates all current farm cycles and pending recovery retries.
    S.running=false;S.token+=1;S.waiting=false
    S.sellQueue={}
    if S.completion then S.completion:Disconnect();S.completion=nil end
    farmB.Text="AUTO FARM: OFF"
    finishBatch()
    show("Stopped")
end
local function close()
    if not S.alive then return end
    stop()
    stopLogger()
    S.alive=false
    for _,c in ipairs(S.links) do pcall(function() c:Disconnect() end) end
    G:Destroy()
    if E.CoastalSafeFarm==S then E.CoastalSafeFarm=nil end
    if E.StopUniversalLogger==stopLogger then E.StopUniversalLogger=nil end
end
S.Stop=stop;S.Close=close

local function getSell()
    local rem=RS:FindFirstChild("Remotes")
    local shop=rem and rem:FindFirstChild("Shop")
    local r=shop and shop:FindFirstChild("SellAll")
    return r and r:IsA("RemoteFunction") and r or nil
end
-- Exactly one SellAll request for each successfully completed pan
-- while Auto Sell is enabled. Sequential queue prevents dropped pans.
-- Sales run separately, so digging is never blocked by selling.
local function autoSell(id,cycle)
    if not S.sell or not valid(id) or S.lastQueuedCycle==cycle then return end
    S.lastQueuedCycle=cycle
    S.sellQueue[#S.sellQueue+1]={id=id,cycle=cycle,queuedAt=os.clock()}
    if S.selling then return end
    S.selling=true
    task.spawn(function()
        while S.alive and #S.sellQueue>0 do
            local job=table.remove(S.sellQueue,1)
            if valid(job.id) and S.sell then
                -- Let rewards replicate and the logger flush before selling.
                -- Do not wait for newer pans indefinitely.
                local deadline=os.clock()+2.5
                while valid(job.id) and S.sell and os.clock()<deadline do
                    if os.clock()-job.queuedAt>=CFG.logGap
                        and #L.pending==0 and #L.unsaved==0 and not L.writing then
                        break
                    end
                    task.wait(.025)
                end
                if valid(job.id) and S.sell then
                    local r=getSell()
                    if r then
                        local ok=pcall(function() r:InvokeServer() end)
                        if not ok then show("Auto Sell failed on pan "..job.cycle) end
                    else
                        S.sell=false
                        sellB.Text="AUTO SELL: OFF"
                        show("SellAll unavailable")
                    end
                end
            end
        end
        S.selling=false
    end)
end
local function farming(id,r,target)
    while valid(id) do
        -- Refresh capacity each cycle, including equipment/buff changes.
        local newCapacity=capacity()
        if newCapacity and newCapacity>0 then target=newCapacity end
        local cycleStart=os.clock()
        show("Digging")
        if not move(S.dig,id) then return "Dig teleport failed" end
        local lastProgress=os.clock()
        for _=1,CFG.maxDig do
            if not valid(id) then return end
            local before=fill(r)
            if before==nil then return "Fill unavailable" end
            if before>=target-.01 then break end
            local ok=invoke(r.dig,id,1)
            if not ok then return "Collect failed" end
            -- InvokeServer already waits for a server reply. On acknowledged
            -- Fill progress, go straight to the next Collect with no extra sleep.
            -- Only back off when replication/progress has not caught up.
            local after=fill(r)
            if after and after>before+.001 then
                lastProgress=os.clock()
            elseif not pause(timing("dig"),id) then
                return
            end
            if os.clock()-lastProgress>CFG.digStall then return "Digging stalled" end
        end
        if not valid(id) then return end
        if (fill(r) or 0)<target-.01 then return "Pan not full" end
        local digTime=os.clock()-cycleStart

        show("Panning")
        local waterStart=os.clock()
        if not move(S.water,id) then return "Water teleport failed" end
        local waterTime=os.clock()-waterStart
        S.rewards=0;S.lastReward=0;S.completed=false;S.waiting=true;S.seen={}
        local panStart=os.clock()
        local accepted=false
        for _=1,15 do
            if not valid(id) then return end
            local ok,result=invoke(r.pan,id)
            if not ok then return "Pan call failed" end
            if result==true then accepted=true;break end
            if not pause(timing("panRetry"),id) then return end
        end
        if not accepted then return "Pan rejected" end
        local panTime=os.clock()-panStart

        show("Shaking")
        local shakeStart=os.clock()
        local earlyMoved=false
        local earlyTime=0
        local function finished()
            return S.completed or (S.rewards>0 and os.clock()-S.lastReward>=CFG.rewardGap)
        end
        -- Experimental early travel after first two rewards and a very short lull.
        -- Starts at ~30ms of quiet instead of ~165ms. If leaving water
        -- interrupts remaining rewards, switch Early TP OFF for that zone.
        -- No further shake packets are sent after teleporting.
        local function tryEarlyMove()
            if not S.earlyTP or earlyMoved or S.completed or S.rewards<2 then return false end
            if os.clock()-S.lastReward < math.max(.03,CFG.rewardGap*.10) then return false end
            show("Early teleport (test)")
            local t=os.clock()
            if not move(S.dig,id) then return nil,"Early teleport failed" end
            earlyTime=os.clock()-t
            earlyMoved=true
            return true
        end

        local done=false
        for _=1,CFG.maxShake do
            if not valid(id) then return end
            if finished() then done=true;break end
            local jumped,err=tryEarlyMove()
            if err then return err end
            if jumped then break end

            local ok=pcall(function() r.shake:FireServer() end)
            if not ok then return "Shake failed" end
            if S.doubleShake then
                if not pause(timing("shakeGap"),id,finished) then return end
                if finished() then done=true;break end
                jumped,err=tryEarlyMove()
                if err then return err end
                if jumped then break end
                ok=pcall(function() r.shake:FireServer() end)
                if not ok then return "Shake failed" end
            end
            if not pause(timing("shake"),id,finished) then return end
        end

        if not done then
            local deadline=os.clock()+(earlyMoved and 3 or 1.5)
            while valid(id) and os.clock()<deadline do
                if finished() then done=true;break end
                task.wait(.02)
            end
        end
        if not done then return "No completion detected" end
        if not valid(id) then return end
        local shakeTime=os.clock()-shakeStart

        S.waiting=false
        S.cycles+=1
        local total=os.clock()-cycleStart
        S.totalCycleTime+=total
        local recent=S.recentTimes
        recent[#recent+1]=total
        if #recent>10 then table.remove(recent,1) end
        local sum=0
        for _,v in ipairs(recent) do sum+=v end
        local ppm=sum>0 and (60*#recent/sum) or 0
        -- Footer refreshes independently every 0.25s.
        autoSell(id,S.cycles)
    end
end
local function applyZone()
    local name=selectedZone()
    local p=S.presets[name]
    S.dig=p and unpackCF(p.dig) or nil
    S.water=p and unpackCF(p.water) or nil
    S.activeZone=name
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    refreshPreset()
end
local function capture(key)
    if S.running then show("Turn AUTO FARM OFF before editing");return end
    local r=root()
    if not r then show("Character root unavailable");return end
    if S.activeZone~=selectedZone() then applyZone() end
    local name=selectedZone()
    S.presets[name]=S.presets[name] or {}
    local packed=packCF(r.CFrame)
    S.presets[name][key]=packed
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name][key]=packed
    if key=="dig" then S.dig=r.CFrame else S.water=r.CFrame end
    digB.Text=S.dig and "DIG SAVED" or "SET DIG"
    waterB.Text=S.water and "WATER SAVED" or "SET WATER"
    digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
    waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
    refreshPreset()
    local ok,err=savePresets()
    show(ok and (name.." "..key.." saved") or ("Session only: "..tostring(err)))
end
bind(digB.MouseButton1Click,function() capture("dig") end)
bind(waterB.MouseButton1Click,function() capture("water") end)
local function selectZone(i)
    S.selectedZone=(i-1)%#ZONE_NAMES+1
    local p=S.presets[selectedZone()]
    if p and p.waypoint and waypointIndex[p.waypoint] then
        S.selectedWaypoint=waypointIndex[p.waypoint]
    end
    refreshPreset()
    savePresets()
end
bind(prevZone.MouseButton1Click,function() selectZone(S.selectedZone-1) end)
bind(nextZone.MouseButton1Click,function() selectZone(S.selectedZone+1) end)
bind(prevWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=(S.selectedWaypoint-2)%#WAYPOINT_NAMES+1
    refreshPreset()
    savePresets()
end)
bind(nextWaypoint.MouseButton1Click,function()
    S.selectedWaypoint=S.selectedWaypoint%#WAYPOINT_NAMES+1
    refreshPreset()
    savePresets()
end)
bind(mapWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before editing mappings");return end
    local name,wp=selectedZone(),selectedWaypoint()
    S.presets[name]=S.presets[name] or {}
    S.presets[name].waypoint=wp
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name].waypoint=wp
    local ok,err=savePresets()
    refreshPreset()
    show(ok and (name.." -> "..wp) or ("Mapping session only: "..tostring(err)))
end)
bind(loadZone.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before loading");return end
    local name=selectedZone()
    local p=S.presets[name]
    if not p or not unpackCF(p.dig) or not unpackCF(p.water) then
        show("Save both positions for "..name)
        return
    end
    applyZone()
    show("Loaded "..name.." zone")
end)
bind(importLegacy.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before importing");return end
    local name,wp=selectedZone(),selectedWaypoint()
    local old=S.legacyWaypoints[wp]
    if not old or not (old.dig or old.water) then
        show("No legacy positions for "..wp);return
    end
    local existing=S.presets[name]
    if existing and (unpackCF(existing.dig) or unpackCF(existing.water)) then
        show("Zone already has positions; won't overwrite");return
    end
    local imported={dig=old.dig,water=old.water,waypoint=wp}
    S.presets[name]=mergePreset(S.presets[name],imported)
    S.overrides[name]=mergePreset(S.overrides[name],imported)
    local ok,err=savePresets()
    refreshPreset()
    show(ok and ("Imported old "..wp.." to "..name) or ("Imported in session: "..tostring(err)))
end)
bind(travelWaypoint.MouseButton1Click,function()
    if S.running then show("Turn AUTO FARM OFF before traveling");return end
    local folder=waypointFolder()
    local r=root()
    if not folder or not r then show("Waypoints or character unavailable");return end
    local to=folder:FindFirstChild(selectedWaypoint())
    if not to then show("Selected waypoint not found");return end
    local from=closestWaypoint(folder,r.Position)
    if not from then show("Current waypoint could not be resolved");return end
    if from==to then show("Already nearest to "..to.Name);return end
    local remotes=RS:FindFirstChild("Remotes")
    local misc=remotes and remotes:FindFirstChild("Misc")
    local remote=misc and misc:FindFirstChild("FastTravel")
    if not remote or not remote:IsA("RemoteEvent") then
        show("FastTravel remote unavailable");return
    end
    local ok,err=pcall(function() remote:FireServer(from,to) end)
    -- FireServer is one-way; this only confirms that the request was sent.
    show(ok and ("Travel requested: "..from.Name.." -> "..to.Name)
        or ("FastTravel failed: "..tostring(err):sub(1,65)))
end)


-- Export all zone mappings and full-precision coordinates as a shareable text report.
-- Includes all 21 in-game waypoint pivots for reference, but the warp remote uses Instances.
-- Export is ONLY triggered by clicking the button (never on every mineral).
local function exportCFrame(cf)
    if typeof(cf)~="CFrame" then return "" end
    local parts={cf:GetComponents()}
    local out={}
    for i=1,#parts do out[i]=string.format("%.17g",parts[i]) end
    return table.concat(out,",")
end
local function exportZoneCFrame(serialized)
    return exportCFrame(unpackCF(serialized))
end
bind(exportPresetButton.MouseButton1Click,function()
    local lines={
        "GALAXIS HUB ZONE PRESETS | VERSION 2",
        "Export: "..os.date("%Y-%m-%d %H:%M:%S"),
        "Note: Each CFrame is 12 comma-separated numbers (position + rotation).",
        "An empty field means not configured. This is NOT a complete farming preset until both positions are saved.",
        "",
        "=== MINING ZONES (35) ===",
        "Zone\tMapped Waypoint\tDig CFrame\tWater CFrame"
    }
    local mapped,complete=0,0
    for _,name in ipairs(ZONE_NAMES) do
        local p=S.presets[name] or {}
        local wp=p.waypoint or ""
        local dig,water=exportZoneCFrame(p.dig),exportZoneCFrame(p.water)
        if wp~="" then mapped+=1 end
        if dig~="" and water~="" then complete+=1 end
        lines[#lines+1]=table.concat({name,wp,dig,water},"\t")
    end
    lines[#lines+1]=""
    lines[#lines+1]="=== FAST TRAVEL WAYPOINTS (21) ==="
    lines[#lines+1]="Waypoint\\tWorld CFrame"
    local folder=waypointFolder()
    for _,name in ipairs(WAYPOINT_NAMES) do
        local obj=folder and folder:FindFirstChild(name)
        local cf=obj and getWaypointCF(obj)
        lines[#lines+1]=name.."\t"..exportCFrame(cf)
    end
    lines[#lines+1]=""
    lines[#lines+1]=string.format("Summary: %d/35 mapped zones; %d/35 with dig+water positions.",
        mapped,complete)
    local contents=table.concat(lines,"\n")
    local saveOk=false
    if type(writefile)=="function" then
        saveOk=pcall(writefile,"GalaxisHub_PresetExport.txt",contents)
    end
    local copyOk=false
    if type(setclipboard)=="function" then
        copyOk=pcall(setclipboard,contents)
    end
    show(string.format("Exported %d mapped / %d complete; TXT: %s, copied: %s",
        mapped,complete,saveOk and "yes" or "no",copyOk and "yes" or "no"))
    if not saveOk then
        print("[GALAXIS HUB] Preset export (file API unavailable):\n"..contents)
    end
end)

bind(sellB.MouseButton1Click,function()
    if not S.sell and not getSell() then show("SellAll unavailable");return end
    S.sell=not S.sell
    sellB.Text="AUTO SELL: "..(S.sell and "ON" or "OFF")
end)
-- ON is a persistent user request. A transient farm failure does not turn
-- the toggle off: we re-resolve the equipped pan and retry quickly.
bind(farmB.MouseButton1Click,function()
    if S.running then
        stop()
        return
    end
    if not S.dig or not S.water then show("Save both positions");return end
    S.running=true
    S.token+=1
    local id=S.token
    farmB.Text="AUTO FARM: ON"
    S.waiting=false
    show("Starting")

    task.spawn(function()
        while valid(id) do
            local r=panTool()
            local target=capacity()
            local reason
            if not r then
                reason="Pan not equipped"
            elseif not target or target<=0 then
                reason="Capacity unavailable"
            elseif fill(r)==nil then
                reason="Fill unavailable"
            else
                if S.completion then
                    S.completion:Disconnect()
                    S.completion=nil
                end
                if r.done and r.done:IsA("RemoteEvent") then
                    S.completion=r.done.OnClientEvent:Connect(function()
                        if valid(id) and S.waiting then S.completed=true end
                    end)
                end
                local ok,result=pcall(farming,id,r,target)
                reason=ok and (result or "Cycle ended unexpectedly")
                    or ("Runtime error: "..tostring(result))
            end

            if S.completion then
                S.completion:Disconnect()
                S.completion=nil
            end
            S.waiting=false

            if valid(id) then
                show("Recovering in 0.25s: "..tostring(reason):sub(1,58))
                warn("[GALAXIS HUB] Auto recovery:",reason)
                if not pause(CFG.recoveryDelay,id) then break end
            end
        end
    end)
end)
bind(X.MouseButton1Click,close)
local minimized=false
bind(Min.MouseButton1Click,function()
    minimized=not minimized
    Body.Visible=not minimized
    W.Size=minimized and UDim2.fromOffset(340,43) or UDim2.fromOffset(340,610)
    Min.Text=minimized and "+" or "−"
end)
local dragging=false
local dragStart,windowStart
bind(H.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true;dragStart=i.Position;windowStart=W.Position
    end
end)
bind(UIS.InputChanged,function(i)
    if dragging and S.alive and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        W.Position=UDim2.new(windowStart.X.Scale,windowStart.X.Offset+d.X,
            windowStart.Y.Scale,windowStart.Y.Offset+d.Y)
    end
end)
bind(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
bind(P.CharacterRemoving,function()
    -- Do not turn the toggle OFF on respawn; the worker will retry when
    -- an equipped pan and character are available again.
    if S.running then
        S.waiting=false
        show("Character changed - recovering")
    end
end)
print("[GALAXIS HUB BETA] Loaded. TSV:",FILE)
if L.error then warn("[GALAXIS HUB BETA] Logger:",L.error) end
