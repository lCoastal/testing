-- GALAXIS HUB | PROSPECTING BETA AUTO RECOVERY
-- Experimental fast farm + independent TSV mineral logger
-- Requires an executor with file APIs. Never toggles shovel activation.
-- Close button stops loops, disconnects listeners, flushes pending log entries.

local P = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
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
local S={alive=true,running=false,token=0,cycles=0,dig=nil,water=nil,sell=true,selling=false,doubleShake=true,
    earlyTP=false,turbo=true,recentTimes={},totalCycleTime=0,
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
    -- Optional sparse points, ordered from the mapped stone to the dig
    -- location. The same points are used backward when returning.
    local route=nil
    if type(p.route)=="table" then
        route={}
        for _,node in ipairs(p.route) do
            local cf=unpackCF(node)
            if cf and #route<12 then route[#route+1]=packCF(cf) end
        end
    end
    if dig or water or waypoint or route then
        return {dig=packCF(dig),water=packCF(water),waypoint=waypoint,route=route}
    end
    return nil
end
-- Base presets supplied by the player: 28 configured zones.
-- Tomb Veins and limited-time areas remain unset; users may add their own.
-- New defaults are merged underneath the player's local saved overrides.
local DEFAULT_ZONE_PRESETS_JSON=[==[{"version":2,"zones":{"Rubble Creek Sands":{"waypoint":"Rubble Creek","dig":[-66.95266723632812,10.668807983398438,31.711631774902344,0.007483333349227905,-4.912990192451616e-8,-0.9999719858169556,1.2491962325666961e-11,1,-4.913118445415421e-8,0.9999719858169556,3.5517344620927815e-10,0.007483333349227905],"water":[-81.39066314697266,8.999999046325684,40.63431167602539,0.10888993740081787,-8.738888723769378e-9,0.994053840637207,3.674560655753112e-11,1,8.787137240062748e-9,-0.994053840637207,-9.203036666072251e-10,0.10888993740081787]},"Rubble Creek Deposits":{"waypoint":"Rubble Creek","dig":[-121.72286987304688,11.053008079528809,32.64851760864258,0.9974461197853088,-1.6323816964813886e-8,0.07142266631126404,1.88620621344171e-8,1,-3.4863909093019174e-8,-0.07142266631126404,3.612204935166119e-8,0.9974461197853088],"water":[-105.99281311035156,9,33.946773529052734,-0.04471517354249954,8.365498160856077e-8,-0.9989997744560242,1.3587669878134534e-9,1,8.367791792807111e-8,0.9989997744560242,2.384264785604273e-9,-0.04471517354249954]},"Fortune River":{"waypoint":"Dredge Master","dig":[-550.1090698242188,11.829303741455078,-61.64445877075195,-0.9968495965003967,1.8876454177529922e-8,-0.07931512594223022,1.9152615493567282e-8,1,-2.721075587075461e-9,0.07931512594223022,-4.231595074344341e-9,-0.9968495965003967],"water":[-535.3941040039062,8.999999046325684,-59.93074417114258,-0.15197649598121643,9.882730722665656e-8,-0.9883841276168823,2.5226734590155786e-10,1,9.994997185458487e-8,0.9883841276168823,1.4940710002520063e-8,-0.15197649598121643]},"Fortune River Delta":{"waypoint":"Fortune River Delta","dig":[-283.9589538574219,12.91366195678711,-779.0611572265625,0.9324533939361572,5.163301608490656e-8,-0.3612902760505676,-1.167207486219013e-8,1,1.1278839195938417e-7,0.3612902760505676,-1.0095291003153761e-7,0.9324533939361572],"water":[-266.49420166015625,9,-770.8576049804688,0.6402298808097839,5.912781020356306e-8,-0.7681833505630493,3.0562766539787845e-8,1,1.0244299630812748e-7,0.7681833505630493,-8.906487636295424e-8,0.6402298808097839]},"Sunset Beach":{"waypoint":"Sunset Beach","dig":[-73.40966796875,11.488126754760742,-481.25384521484375,0.9927338361740112,-1.0855862875303046e-8,0.12033078074455261,3.956567518059728e-9,1,5.757499721426029e-8,-0.12033078074455261,-5.6680551807630764e-8,0.9927338361740112],"water":[-75.18217468261719,9,-499.81402587890625,0.9954444766044617,2.087231498748565e-9,0.095343217253685,2.65547472899641e-9,1,-4.961662725122551e-8,-0.095343217253685,4.964378064187258e-8,0.9954444766044617]},"Crystal Cavern River":{"waypoint":"Crystal Caverns","dig":[-101.75530242919922,-8.561837196350098,416.5581359863281,-0.9096121191978455,2.9759432695897203e-9,-0.4154585897922516,-4.363401640006259e-9,1,1.671633853561616e-8,0.4154585897922516,1.7018194853335444e-8,-0.9096121191978455],"water":[-109.16580200195312,-11.244487762451172,423.5841979980469,-0.7521693110466003,4.866406300152448e-8,0.6589698791503906,-1.1224072782312078e-9,1,-7.512984012691959e-8,-0.6589698791503906,-5.7249991414209944e-8,-0.7521693110466003]},"Azuralite Oasis":{"waypoint":"Crystal Caverns","dig":[-138.9603729248047,-35.8428955078125,518.2411499023438,-0.7203456163406372,-6.894685355973706e-8,0.6936153173446655,-4.9125478795986055e-8,1,4.838349099145489e-8,-0.6936153173446655,7.78651421118326e-10,-0.7203456163406372],"water":[-142.69296264648438,-40.575233459472656,531.5817260742188,-0.3794470429420471,1.841604380103945e-8,0.9252134561538696,1.1323890269920867e-8,1,-1.526050752431729e-8,-0.9252134561538696,4.686460997049835e-9,-0.3794470429420471]},"Volcanic Sands":{"waypoint":"Museum","dig":[-723.4058837890625,12.685310363769531,-272.84515380859375,-0.41539236903190613,-9.255173694100449e-8,-0.9096423387527466,7.34400718016559e-9,1,-1.0509887005127894e-7,0.9096423387527466,-5.033768957218854e-8,-0.41539236903190613],"water":[-718.4039916992188,9.16382122039795,-284.1190185546875,0.8849422335624695,1.8496555398428427e-8,-0.46570077538490295,-5.509117606550262e-9,1,2.9249049404711513e-8,0.46570077538490295,-2.3318118991255687e-8,0.8849422335624695]},"Volcanic Springs":{"waypoint":"Museum","dig":[-888.2327880859375,19.946598052978516,-450.4830322265625,0.9378904700279236,7.006035929180143e-8,-0.34693145751953125,-5.8438928363102605e-8,1,4.3959808238014375e-8,0.34693145751953125,-2.0955184254489723e-8,0.9378904700279236],"water":[-891.6001586914062,16.129730224609375,-463.9439697265625,0.9738182425498962,4.684348020589368e-9,0.22732797265052795,7.601348439578715e-10,1,-2.3862357423354297e-8,-0.22732797265052795,2.341039895270569e-8,0.9738182425498962]},"Windswept Beach":{"waypoint":"Volcanic Sands","dig":[-979.2021484375,14.064384460449219,-783.4978637695312,-0.9517496824264526,-5.644607625754361e-8,0.30687540769577026,-6.257167228795879e-8,1,-1.0122981564109068e-8,-0.30687540769577026,-2.8836252496944326e-8,-0.9517496824264526],"water":[-971.2080078125,9.163822174072266,-804.7001342773438,0.9628453254699707,-1.0572350106485828e-8,-0.2700534462928772,1.7250951778180479e-9,1,-3.2998467958123e-8,0.2700534462928772,3.130655201744048e-8,0.9628453254699707]},"Magma Furnace":{"waypoint":"The Magma Furnace","dig":[-1223.5780029296875,-89.00021362304688,-97.9509506225586,-0.9903417825698853,9.394377542548682e-8,-0.13864776492118835,9.40054505349508e-8,1,6.103621164044171e-9,0.13864776492118835,-6.98897473228044e-9,-0.9903417825698853],"water":[-1228.495361328125,-90.15330505371094,-88.44580841064453,0.28390851616859436,7.151187730869424e-8,-0.9588513970375061,5.740499986472969e-8,1,9.157795233249999e-8,0.9588513970375061,-8.104262150254726e-8,0.28390851616859436]},"Infernal Heart":{"waypoint":"The Magma Furnace","dig":[-1154.800537109375,-87.84814453125,44.64744567871094,0.9450898170471191,1.2503302571076347e-7,-0.32681071758270264,-1.160604625738415e-7,1,4.695521127473512e-8,0.32681071758270264,-6.447089084815616e-9,0.9450898170471191],"water":[-1152.23876953125,-90.15330505371094,53.036827087402344,-0.8495063781738281,-2.6581373546719078e-8,-0.5275783538818359,4.203474901487425e-9,1,-5.715217810120521e-8,0.5275783538818359,-5.076880071896994e-8,-0.8495063781738281]},"Frostbite River":{"waypoint":"Snowy Shores","dig":[-1455.94287109375,14.811209678649902,-2314.61865234375,-0.9400432705879211,1.8108203825306646e-9,-0.3410552442073822,-3.6624985266797694e-9,1,1.5404330255819332e-8,0.3410552442073822,1.5729851199353106e-8,-0.9400432705879211],"water":[-1456.4041748046875,11.663053512573242,-2326.5673828125,0.9516045451164246,1.005325600544893e-8,0.307325154542923,2.1174713094040953e-9,1,-3.926867364612008e-8,-0.307325154542923,3.8018999504174644e-8,0.9516045451164246]},"Frostbite Waterfall":{"waypoint":"Frostbitten Path","dig":[-1466.429443359375,149.9092254638672,-2714.98828125,0.353004515171051,-5.395235902483364e-8,0.9356216192245483,-7.397958512456171e-8,1,8.557677944054376e-8,-0.9356216192245483,-9.942588974354294e-8,0.353004515171051],"water":[-1469.921142578125,147.05563354492188,-2702.021240234375,-0.971365749835968,5.3586941106686936e-8,0.23758921027183533,5.011078130223723e-8,1,-2.0670336553507695e-8,-0.23758921027183533,-8.172676757567388e-9,-0.971365749835968]},"Frozen Peak":{"waypoint":"Frozen Peak","dig":[-1456.450927734375,359.48321533203125,-3109.02734375,-0.3760899305343628,5.418522164291062e-8,-0.9265831708908081,8.020072073122719e-8,1,2.5925938729187692e-8,0.9265831708908081,-6.45621582862077e-8,-0.3760899305343628],"water":[-1462.328857421875,354.77386474609375,-3121.185546875,0.9173180460929871,5.374394262958049e-8,0.39815521240234375,-2.4330804038186216e-9,1,-1.2937677240643097e-7,-0.39815521240234375,1.1771090413503771e-7,0.9173180460929871]},"Overgrown Grotto":{"waypoint":"Overgrown Grotto","dig":[114.39781188964844,-131.63876342773438,896.1094360351562,0.6101309061050415,2.036335544630674e-8,0.7923006415367126,4.2163289526442327e-10,1,-2.6026238941767588e-8,-0.7923006415367126,1.6213473230664022e-8,0.6101309061050415],"water":[107.11598205566406,-133.7900848388672,890.5596923828125,0.6065621972084045,6.468681590376946e-8,0.7950360178947449,9.386144306233746e-9,1,-8.852441624185303e-8,-0.7950360178947449,6.115788409033485e-8,0.6065621972084045]},"Deeproot Spring":{"waypoint":"Deeproot Spring","dig":[215.3380889892578,-163.33810424804688,1140.50439453125,-0.9946808815002441,-4.631068861726817e-8,0.10300444811582565,-5.1048658633590094e-8,1,-4.336158454520955e-8,-0.10300444811582565,-4.838917888605465e-8,-0.9946808815002441],"water":[219.36634826660156,-165.8150634765625,1130.2984619140625,0.9261543154716492,9.857313187922045e-8,-0.37714478373527527,-6.290514420470572e-8,1,1.0689068119518197e-7,0.37714478373527527,-7.527291501219224e-8,0.9261543154716492]},"Enchanted Ruins":{"waypoint":"Deeproot Spring","dig":[322.2826843261719,-207.07125854492188,1147.1417236328125,-0.9506480097770691,-1.659419446298216e-8,-0.31027141213417053,4.168923262160007e-10,1,-5.476016085026458e-8,0.31027141213417053,-5.218698717612824e-8,-0.9506480097770691],"water":[319.21575927734375,-209.642333984375,1133.5440673828125,0.9895275235176086,1.1972348445965508e-8,0.14434431493282318,2.4658173281011386e-9,1,-9.984697157960909e-8,-0.14434431493282318,9.915725485143412e-8,0.9895275235176086]},"Abyssal Depth":{"waypoint":"Overgrown Grotto","dig":[257.52960205078125,-256.7026672363281,768.1597290039062,-0.8952816128730774,5.338381292574468e-9,0.4455006718635559,1.4275093107585235e-8,1,1.670445826107425e-8,-0.4455006718635559,2.13147579586348e-8,-0.8952816128730774],"water":[245.873779296875,-258.7674560546875,768.91796875,0.2747102677822113,-2.646487473612069e-8,0.9615270495414734,-2.382970620828928e-8,1,3.4331993248315484e-8,-0.9615270495414734,-3.234425705045396e-8,0.2747102677822113]},"Rotwood Swamp":{"waypoint":"Rotwood Swamp","dig":[-1964.138916015625,23.5592041015625,1174.0201416015625,0.5378245711326599,3.249122570991858e-8,-0.8430567979812622,6.737462143746598e-8,1,8.152114361337226e-8,0.8430567979812622,-1.0064470501447431e-7,0.5378245711326599],"water":[-1951.542236328125,18.35124969482422,1170.722412109375,0.19294562935829163,-4.8913321393229126e-8,-0.9812094569206238,-6.697661980581415e-9,1,-5.116706347507716e-8,0.9812094569206238,1.6444269945736778e-8,0.19294562935829163]},"Fungal Marsh":{"waypoint":"Timelocked Sanctuary","dig":[-2668.52685546875,20.703285217285156,1254.68212890625,0.2831985056400299,-3.466764297854752e-8,-0.959061324596405,-1.0889387880297363e-7,1,-6.830244103639416e-8,0.959061324596405,1.2377905989069404e-7,0.2831985056400299],"water":[-2667.951171875,18.37548065185547,1244.6072998046875,0.4163704216480255,-8.652551031218536e-8,-0.909195065498352,-4.267471709340498e-8,1,-1.1471026084564073e-7,0.909195065498352,8.656159877773462e-8,0.4163704216480255]},"Timelocked Sanctuary":{"waypoint":"Timelocked Sanctuary","dig":[-2797.513671875,-58.471378326416016,1378.9716796875,0.9821836948394775,-5.667398639275234e-8,0.18792344629764557,5.4878366739785633e-8,1,1.4757874922111114e-8,-0.18792344629764557,-4.1820120699753716e-9,0.9821836948394775],"water":[-2781.85498046875,-61.000614166259766,1386.852783203125,-0.747072160243988,6.357750237384607e-8,-0.6647429466247559,6.0187739236994275e-9,1,8.887803204515876e-8,0.6647429466247559,6.239736904944948e-8,-0.747072160243988]},"Meteor Falls":{"waypoint":"Meteor Valley Entrance","dig":[-4824.78271484375,109.67481994628906,1605.961669921875,0.06301112473011017,-1.8004751467515234e-8,0.9980128407478333,-4.123866581551283e-9,1,1.8300967852269423e-8,-0.9980128407478333,-5.268836478222738e-9,0.06301112473011017],"water":[-4838.6513671875,106.97921752929688,1604.2056884765625,0.12369923293590546,1.06490148255034e-7,0.9923197627067566,-1.761234214026075e-10,1,-1.072923936362713e-7,-0.9923197627067566,1.309721575637468e-8,0.12369923293590546]},"Starfall River":{"waypoint":"Meteor Valley","dig":[-5395.7939453125,109.26429748535156,1522.481201171875,0.9356088042259216,1.9484214242027065e-9,0.3530384600162506,-5.74576053402609e-10,1,-3.996286856988718e-9,-0.3530384600162506,3.5361136241363056e-9,0.9356088042259216],"water":[-5404.41650390625,106.97864532470703,1510.4541015625,0.9514889121055603,4.989977497871223e-8,0.3076830506324768,-3.15993524679925e-8,1,-6.44603019850365e-8,-0.3076830506324768,5.161067662129426e-8,0.9514889121055603]},"Astral Caverns":{"waypoint":"Meteor Valley","dig":[-5503.5810546875,109.58366394042969,1479.0711669921875,-0.9490302801132202,-8.81357422599649e-8,-0.31518495082855225,-6.699248444874684e-8,1,-7.791566503101421e-8,0.31518495082855225,-5.282930004568698e-8,-0.9490302801132202],"water":[-5518.2138671875,104.18557739257812,1475.530029296875,0.19619199633598328,9.097912823108345e-8,0.9805654883384705,1.2795112191987812e-10,1,-9.280790891352808e-8,-0.9805654883384705,1.8333633278189154e-8,0.19619199633598328]},"Sandstone Stream":{"waypoint":"Sunscorched Desert","dig":[-6532.244140625,157.79470825195312,-293.44329833984375,-0.43457335233688354,2.1864510202362908e-8,0.9006364345550537,4.536166109403439e-9,1,-2.208794924740687e-8,-0.9006364345550537,-5.513398182444007e-9,-0.43457335233688354],"water":[-6511.142578125,154.3866424560547,-286.5010070800781,-0.32213497161865234,-4.9084100339769066e-8,-0.9466937780380249,-3.9770634008284844e-10,1,-5.171258976588433e-8,0.9466937780380249,-1.628192691782715e-8,-0.32213497161865234]},"Mystic Floodplains":{"waypoint":"Mystic Floodplains","dig":[-5952.4365234375,157.4579620361328,-723.9244384765625,0.13070929050445557,-1.4352758093139073e-8,-0.9914207458496094,-2.7243970635026926e-8,1,-1.8068815776928204e-8,0.9914207458496094,2.9371999943350602e-8,0.13070929050445557],"water":[-5941.9765625,154.3866424560547,-735.4666137695312,0.7313604950904846,-8.181835653431335e-9,-0.6819911003112793,5.222612564637075e-9,1,-6.396305263223212e-9,0.6819911003112793,1.1162297752775885e-9,0.7313604950904846]},"Lifespring Oasis":{"waypoint":"Lifespring Oasis","dig":[-5847.04296875,157.95791625976562,-148.60360717773438,0.9648867249488831,3.7013457188095344e-8,-0.2626663148403168,-3.224290878733882e-8,1,2.2472248062399558e-8,0.2626663148403168,-1.3214047633880455e-8,0.9648867249488831],"water":[-5832.2060546875,154.3866424560547,-134.9605255126953,-0.6665259003639221,4.873164982654998e-8,-0.7454818487167358,-2.710463853361489e-9,1,6.779271899404193e-8,0.7454818487167358,4.72062069434287e-8,-0.6665259003639221]}}}]==]
local function mergePreset(base,extra)
    base=base or {}
    if not extra then return base end
    if extra.dig~=nil then base.dig=extra.dig end
    if extra.water~=nil then base.water=extra.water end
    if extra.waypoint~=nil then base.waypoint=extra.waypoint end
    if extra.route~=nil then base.route=extra.route end
    return base
end
-- Upgrade only the outdated Frostbite River built-in.
-- Personalized coordinates take priority; an exact copy of the OLD
-- built-in should not mask the corrected snow location.
local OLD_FROSTBITE_JSON=[==[{"dig":[-1463.9600830078125,14.248823165893555,-2312.603515625,-0.9989777207374573,-1.9932404171640883e-8,-0.04520475119352341,-1.892527023983348e-8,1,-2.270735599552154e-8,0.04520475119352341,-2.18286313469207e-8,-0.9989777207374573],"water":[-1463.7332763671875,11.663053512573242,-2326.898681640625,0.998001217842102,-6.150593367948431e-10,-0.0631951093673706,-9.83211179139687e-10,1,-2.525995057567343e-8,0.0631951093673706,2.5271594594755697e-8,0.998001217842102]}]==]
local OLD_FROSTBITE=HttpService:JSONDecode(OLD_FROSTBITE_JSON)
local OLD_DEEPROOT_JSON=[==[{"dig":[262.697265625,-163.9412078857422,1128.542724609375,0.6791316270828247,9.476055495838409e-9,-0.734016478061676,3.2711624520231908e-9,1,1.5936434394347998e-8,0.734016478061676,-1.3224023653890526e-8,0.6791316270828247],"water":[248.22486877441406,-165.8150634765625,1123.1802978515625,0.7444959282875061,-2.4664837283694396e-8,0.6676269769668579,-4.9500656018608424e-8,1,9.214408436264421e-8,-0.6676269769668579,-1.0164887243035992e-7,0.7444959282875061]}]==]
local OLD_DEEPROOT=HttpService:JSONDecode(OLD_DEEPROOT_JSON)
local function isPreviousCF(a,b)
    if type(a)~="table" or type(b)~="table" or #a~=12 or #b~=12 then return false end
    for i=1,12 do if math.abs(a[i]-b[i])>.001 then return false end end
    return true
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
                    -- Ignore only the old Deeproot default, not user customization.
                    if wp=="Deeproot Spring" then
                        if isPreviousCF(moved.dig,OLD_DEEPROOT.dig) then moved.dig=nil end
                        if isPreviousCF(moved.water,OLD_DEEPROOT.water) then moved.water=nil end
                    end
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
                if name=="Frostbite River" then
                    if isPreviousCF(parsed.dig,OLD_FROSTBITE.dig) then parsed.dig=nil end
                    if isPreviousCF(parsed.water,OLD_FROSTBITE.water) then parsed.water=nil end
                elseif name=="Deeproot Spring" then
                    if isPreviousCF(parsed.dig,OLD_DEEPROOT.dig) then parsed.dig=nil end
                    if isPreviousCF(parsed.water,OLD_DEEPROOT.water) then parsed.water=nil end
                end
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

-- ===== DREDGE AUTO: INLINED TOOLKIT OPTIMIZER =====
-- Uses the same FITTED (not server-confirmed) luck model as your site.
-- Embedded mineral odds, no requests to the toolkit or separate Lua files.
local CAPS={1,5,10,25,50,100,250,500,1000,2500,5000,10000,25000,50000,100000}
local DREDGE_ODDS=[==[{"Azuralite Oasis":[["Copper",0.369786],["Gold",0.369786],["Amethyst",0.046223],["Azuralite",0.004622],["Inferlume",7.396e-8],["Ashvein",0.00009245],["Emerald",0.000027729999999999997],["Borealite",0.00004622],["Aetherite",0.000001156],["Silver",0.184893],["Neodymium",0.013867],["Smoky Quartz",0.009245],["Malachite",0.0009245000000000001],["Onyx",0.00046219999999999996],["Prismara",2.773e-8],["Osmium",0.00001387],["Palladium",9.245e-7],["Luminum",0.0000055469999999999996],["Vortessence",7.396e-8],["Uranium",0.000002311],["Starshine",9.245e-7]],"Crystal Cavern River":[["Copper",0.338491],["Gold",0.423114],["Amethyst",0.042310999999999994],["Azuralite",0.0042309999999999995],["Inferlume",6.77e-8],["Ashvein",0.00008462000000000001],["Emerald",0.00002539],["Borealite",0.000042310000000000007],["Aetherite",0.000001269],["Silver",0.169246],["Neodymium",0.012693000000000001],["Smoky Quartz",0.008461999999999999],["Malachite",0.0008462],["Onyx",0.0004231],["Osmium",0.000012689999999999999],["Palladium",8.462e-7],["Luminum",0.000012689999999999999],["Vortessence",6.77e-8],["Starshine",8.462e-7]],"Abyssal Depth":[["Copper",0.242347],["Gold",0.484694],["Azuralite",0.004847000000000001],["Emerald",0.00002908],["Aurorite",0.00001454],["Cobalt",0.00001939],["Aetherite",0.000002423],["Amber",0.0004847],["Gloomberry",0.000004847],["Silver",0.242347],["Neodymium",0.014541],["Smoky Quartz",0.009694000000000001],["Malachite",0.0009694],["Painite",2.908e-8],["Lightshard",0.000004847],["Specterite",0.0000014540000000000002],["Radiant Gold",1.454e-8],["Starshine",4.847e-7],["Umbrite",1.454e-9]],"Deeproot Spring":[["Copper",0.22591999999999998],["Gold",0.45183999999999996],["Azuralite",0.0045179999999999994],["Emerald",0.00002711],["Aurorite",0.00001356],["Cobalt",0.00001807],["Aetherite",0.000002259],["Glowberry",0.067776],["Amber",0.0004518],["Glowmoss",0.000004518],["Chrysoberyl",1.807e-8],["Silver",0.22591999999999998],["Neodymium",0.013555],["Smoky Quartz",0.009037],["Malachite",0.0009037],["Luminum",0.000005422],["Lightshard",0.000004518],["Specterite",0.0000013559999999999998],["Radiant Gold",9.037e-9],["Starshine",4.5179999999999996e-7],["Vineheart",1.807e-9]],"Fungal Marsh":[["Copper",0.271237],["Gold",0.542473],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Bone",0.00010850000000000001],["Electrum",0.027124000000000002],["Diopside",0.0005425],["Bismuth",0.000001627],["Astral Spore",6.509999999999999e-10],["Gloomcap",0.0000027119999999999996],["Smoky Quartz",0.043398000000000006],["Malachite",0.005425],["Onyx",0.001085],["Mythril",3.7969999999999995e-8],["Osmium",0.00002712],["Mercury",0.00001085],["Star Garnet",1.356e-8],["Red Beryl",8.137e-9],["Titanium",0.10849500000000001]],"Overgrown Grotto":[["Copper",0.233408],["Gold",0.466816],["Azuralite",0.004668],["Emerald",0.00002801],["Aurorite",0.000014],["Cobalt",0.00001867],["Aetherite",0.000002334],["Glowberry",0.037345],["Glowmoss",0.000004668],["Chrysoberyl",1.4e-8],["Silver",0.233408],["Neodymium",0.014004],["Smoky Quartz",0.009336],["Malachite",0.0009336],["Prismara",2.801e-8],["Luminum",0.000005602],["Lightshard",0.000004668],["Specterite",0.0000014],["Starshine",4.668e-7]],"Rotwood Swamp":[["Copper",0.271237],["Gold",0.542473],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Chrysoberyl",2.17e-8],["Bone",0.00010850000000000001],["Bloodstone",8.68e-10],["Electrum",0.027124000000000002],["Diopside",0.0005425],["Bismuth",0.000001627],["Smoky Quartz",0.043398000000000006],["Malachite",0.005425],["Onyx",0.001085],["Mythril",3.7969999999999995e-8],["Osmium",0.00002712],["Specterite",0.0000027119999999999996],["Mercury",0.00001085],["Star Garnet",1.085e-8],["Titanium",0.10849500000000001]],"Haunted Creek":[["Copper",0.21613],["Gold",0.432261],["Emerald",0.000034580000000000004],["Aurorite",0.00002161],["Cobalt",0.000017290000000000002],["Diamond",0.000004323],["Aetherite",0.000001297],["Bone",0.00008645],["Silver",0.21613],["Smoky Quartz",0.034581],["Malachite",0.0008645],["Lapis Lazuli",0.0004323],["Painite",3.458e-8],["Lightshard",0.000008645000000000001],["Specterite",0.000002161],["Radiant Gold",1.297e-8],["Rock Candy",0.012968],["Lost Soul",0.000004323],["Pumpkin Soul",4.323e-9],["Moonspire",2.161e-10],["Titanium",0.08645200000000001],["Vortessence",2.1610000000000003e-8]],"Infernal Heart":[["Copper",0.22104700000000002],["Dinosaur Skull",1.842e-8],["Inferlume",1.1049999999999999e-7],["Flarebloom",1.1049999999999999e-7],["Cinnabar",0.00000221],["Fire Opal",0.000002947],["Dragon Bone",0.000014740000000000001],["Obsidian",0.736822],["Peridot",0.0007367999999999999],["Onyx",0.001474],["Pyrelith",0.002947],["Painite",2.2099999999999998e-7],["Pyronium",0.00004421],["Osmium",0.000022100000000000002],["Opal",0.000022100000000000002],["Rose Gold",0.0000044210000000000005],["Topaz",0.022105],["Zircon",0.014736],["Volcanic Core",7.368e-8],["Uranium",0.0000044210000000000005],["Volcanic Key",0.000014740000000000001]],"Volcanic Springs":[["Copper",0.19197399999999998],["Gold",0.383949],["Inferlume",7.679e-8],["Flarebloom",2.7420000000000003e-8],["Cinnabar",0.000001097],["Fire Opal",0.000004388],["Catseye",0.000002742],["Obsidian",0.383949],["Peridot",0.0005485],["Onyx",0.001371],["Meteoric Iron",0.0024679999999999997],["Painite",1.645e-7],["Pyronium",0.00003839],["Osmium",0.00001645],["Opal",0.00001645],["Rose Gold",0.000005485000000000001],["Radium",0.000002194],["Topaz",0.02194],["Zircon",0.013712]],"Magma Furnace":[["Copper",0.17072900000000002],["Gold",0.34145899999999996],["Flarebloom",8.535999999999999e-8],["Cinnabar",0.000001138],["Fire Opal",0.000002845],["Dragon Bone",0.000008536000000000001],["Catseye",0.000002845],["Obsidian",0.455278],["Peridot",0.0005691],["Onyx",0.001138],["Pyrelith",0.002276],["Pyronium",0.00003415],["Osmium",0.00001707],["Opal",0.00001707],["Rose Gold",0.000005691],["Topaz",0.017073],["Zircon",0.011382000000000001],["Volcanic Core",4.5530000000000005e-8],["Volcanic Key",0.000005691]],"Volcanic Sands":[["Copper",0.170732],["Gold",0.34146299999999996],["Inferlume",7.967e-8],["Flarebloom",2.8459999999999998e-8],["Cinnabar",0.000001138],["Fire Opal",0.000002846],["Catseye",0.000002846],["Obsidian",0.455285],["Peridot",0.0005691],["Onyx",0.001138],["Meteoric Iron",0.002276],["Pink Diamond",2.276e-7],["Pyronium",0.00003415],["Osmium",0.00001707],["Opal",0.00001707],["Rose Gold",0.000005691],["Topaz",0.017073],["Zircon",0.011382000000000001]],"Tomb Vein I":[["Copper",0.101946],["Gold",0.34824800000000006],["Amethyst",0.035681],["Azuralite",0.002549],["Inferlume",1.631e-8],["Emerald",0.00003058],["Cinnabar",0.00001784],["Fire Opal",0.00002039],["Catseye",5.097e-7],["Bone",0.00005097],["Electrum",0.025487000000000003],["Aetherium",5.607e-9],["Agate",4.588e-9],["Eye of the Sands",5.097e-11],["Silver",0.07646],["Platinum",0.101946],["Obsidian",0.193698],["Smoky Quartz",0.020389],["Malachite",0.007645999999999999],["Ruby",0.010195000000000001],["Lapis Lazuli",0.003058],["Peridot",0.005097000000000001],["Onyx",0.001019],["Osmium",0.00025489999999999996],["Rose Gold",0.00002549],["Mercury",0.00003568],["Meteoric Gold",0.000010189999999999999],["Sandsteel",0.001529],["Selenite",0.0006117000000000001],["Jasper",0.000005097],["Key of Life",2.549e-11],["Solarium",1.529e-10],["Topaz",0.050973],["Starshine",0.000002549],["Natron Salt",0.010195000000000001],["Blue Faience",0.002039],["Scarab Amber",0.0007646],["Canopic Gold",0.00001529],["Ushabti",2.5490000000000002e-8]],"Tomb Vein II":[["Copper",0.093862],["Gold",0.266829],["Amethyst",0.031286999999999995],["Azuralite",0.004172],["Inferlume",2.607e-8],["Emerald",0.00005215],["Cinnabar",0.0000365],["Fire Opal",0.00004172],["Catseye",7.822000000000001e-7],["Bone",0.00007822],["Electrum",0.041717000000000004],["Aetherium",9.386e-9],["Agate",7.3e-9],["Eye of the Sands",8.343e-11],["Silver",0.073004],["Platinum",0.12515],["Obsidian",0.198154],["Smoky Quartz",0.026073],["Malachite",0.010428999999999999],["Ruby",0.018251],["Lapis Lazuli",0.004693],["Peridot",0.009386],["Onyx",0.001825],["Osmium",0.0004172],["Rose Gold",0.00004693],["Mercury",0.00005215],["Meteoric Gold",0.00001564],["Sandsteel",0.002607],["Selenite",0.001043],["Jasper",0.000007822],["Key of Life",4.172e-11],["Solarium",2.607e-10],["Topaz",0.078219],["Starshine",0.000004172],["Natron Salt",0.007822],["Blue Faience",0.0031290000000000003],["Scarab Amber",0.001564],["Canopic Gold",0.00003129],["Ushabti",1.043e-7]],"Tomb Vein III":[["Copper",0.085018],["Gold",0.20421199999999998],["Amethyst",0.028339],["Azuralite",0.005101],["Inferlume",4.534e-8],["Emerald",0.00011339999999999999],["Cinnabar",0.00007368],["Fire Opal",0.00007934999999999999],["Catseye",0.000001417],["Bone",0.0001417],["Electrum",0.056678],["Aetherium",1.7e-8],["Agate",1.247e-8],["Eye of the Sands",1.474e-10],["Silver",0.068014],["Platinum",0.147364],["Obsidian",0.19270700000000002],["Smoky Quartz",0.028339],["Malachite",0.011335999999999999],["Ruby",0.028339],["Lapis Lazuli",0.005101],["Peridot",0.01417],["Onyx",0.0028339999999999997],["Osmium",0.00045339999999999996],["Rose Gold",0.00009069],["Mercury",0.00008502],["Meteoric Gold",0.000028340000000000003],["Sandsteel",0.004534],["Selenite",0.0017000000000000001],["Jasper",0.000014170000000000002],["Key of Life",7.368e-11],["Solarium",4.534e-10],["Topaz",0.102021],["Starshine",0.000006801],["Natron Salt",0.005667999999999999],["Blue Faience",0.004534],["Scarab Amber",0.0028339999999999997],["Canopic Gold",0.00006801],["Ushabti",2.834e-7],["Sky Iron",1.7e-7],["Eternal Lotus",1.134e-9]],"The Void (when in the loot pool)":[["Copper",0.181132],["Gold",0.181132],["Amethyst",0.181132],["Blue Ice",0.181132],["Coral",0.018113],["Jade",0.0009057],["Azuralite",0.0009057],["Glacial Quartz",0.0009057],["Inferlume",2.536e-8],["Flarebloom",2.536e-8],["Frostshard",2.536e-8],["Iridium",0.00003623],["Ammonite Fossil",0.00003623],["Ashvein",0.00003623],["Emerald",0.00003623],["Golden Pearl",0.00003623],["Borealite",0.00003623],["Aurorite",0.00003623],["Cobalt",0.00003623],["Cinnabar",0.0000018110000000000001],["Diamond",0.0000018110000000000001],["Fire Opal",0.0000018110000000000001],["Dragon Bone",0.0000018110000000000001],["Catseye",0.0000018110000000000001],["Aetherite",0.0000018110000000000001],["Aquamarine",0.0000018110000000000001],["Glowberry",0.018113],["Amber",0.0009057],["Glowmoss",0.00003623],["Chrysoberyl",2.536e-8],["Firefly Stone",0.0000018110000000000001],["Gloomberry",0.0009057],["Bone",0.00003623],["Electrum",0.018113],["Diopside",0.0009057],["Bismuth",0.0000018110000000000001],["Gloomcap",0.0000018110000000000001],["Candy Cane",0.0009057],["Depleted Shard",0.0000018110000000000001],["Aetherium",2.536e-8],["Agate",2.536e-8],["Pyrite",0.181132],["Silver",0.181132],["Platinum",0.181132],["Seashell",0.181132],["Obsidian",0.181132],["Pearl",0.181132],["Neodymium",0.018113],["Smoky Quartz",0.018113],["Malachite",0.018113],["Sapphire",0.018113],["Ruby",0.0009057],["Lapis Lazuli",0.0009057],["Silver Clamshell",0.0009057],["Peridot",0.0009057],["Onyx",0.0009057],["Meteoric Iron",0.0009057],["Pyrelith",0.0009057],["Pink Diamond",2.536e-8],["Painite",2.536e-8],["Prismara",2.536e-8],["Mythril",2.536e-8],["Moonstone",0.00003623],["Pyronium",0.00003623],["Osmium",0.00003623],["Opal",0.00003623],["Rose Gold",0.0000018110000000000001],["Palladium",0.0000018110000000000001],["Luminum",0.0000018110000000000001],["Lightshard",0.00003623],["Specterite",0.0000018110000000000001],["Radiant Gold",2.536e-8],["Rock Candy",0.018113],["Lost Soul",0.0000018110000000000001],["Mercury",0.00003623],["Star Garnet",2.536e-8],["Red Beryl",2.536e-8],["Peppermint Prism",0.0000018110000000000001],["Radium",0.0000018110000000000001],["Nickel",0.018113],["Meteoric Gold",0.00003623],["Nautilus Shell",0.0000018110000000000001],["Sandsteel",0.0009057],["Selenite",0.00003623],["Jasper",0.0000018110000000000001],["Titanium",0.018113],["Topaz",0.018113],["Zircon",0.018113],["Vortessence",2.536e-8],["Volcanic Core",2.536e-8],["Uranium",0.0000018110000000000001],["Volcanic Key",0.0000018110000000000001],["Starshine",0.0000018110000000000001],["Tourmaline",0.0000018110000000000001],["Sunstone",2.536e-8]],"Rubble Creek Sands":[["Gold",0.703167],["Amethyst",0.070317],["Iridium",0.0001406],["Emerald",0.000023440000000000003],["Aurorite",0.00005625],["Diamond",0.000001406],["Aetherite",9.375999999999999e-7],["Platinum",0.187511],["Ruby",0.002344],["Lapis Lazuli",0.0009375999999999999],["Meteoric Iron",0.0003281],["Pink Diamond",1.8749999999999998e-7],["Opal",0.000009376],["Rose Gold",0.000004688],["Titanium",0.023439],["Topaz",0.011719]],"Enchanted Ruins":[["Gold",0.583704],["Azuralite",0.005837],["Emerald",0.00003502],["Aurorite",0.00001751],["Cobalt",0.00002335],["Aetherite",0.000002919],["Glowberry",0.087556],["Amber",0.0005836999999999999],["Glowmoss",0.000005837],["Adamantine",1.167e-9],["Silver",0.291852],["Neodymium",0.017511000000000002],["Smoky Quartz",0.011674],["Malachite",0.001167],["Prismara",7.296e-9],["Mythril",2.919e-8],["Rose Gold",0.000014590000000000001],["Luminum",0.000007004],["Lightshard",0.000005837],["Specterite",0.000001751],["Radiant Gold",1.167e-8],["Starshine",5.837e-7]],"Fortune River":[["Gold",0.572323],["Jade",0.002862],["Iridium",0.00008585],["Emerald",0.00004579],["Aurorite",0.00008585],["Diamond",0.000002289],["Catseye",0.000001145],["Aetherite",5.723e-7],["Platinum",0.286161],["Sapphire",0.005723000000000001],["Ruby",0.002289],["Lapis Lazuli",0.0010299999999999999],["Meteoric Iron",0.0005723],["Pink Diamond",2.862e-7],["Painite",1.717e-7],["Osmium",0.00001431],["Opal",0.00002289],["Rose Gold",0.000005723],["Palladium",2.289e-7],["Titanium",0.114465],["Topaz",0.014308000000000001],["Uranium",0.000001717]],"Fortune River Delta":[["Gold",0.54716],["Coral",0.03283],["Jade",0.002189],["Iridium",0.000054720000000000005],["Golden Pearl",0.0001641],["Aurorite",0.000054720000000000005],["Diamond",0.0000054719999999999994],["Aetherite",0.0000013679999999999999],["Silver",0.27358],["Pearl",0.10943199999999999],["Neodymium",0.016415],["Smoky Quartz",0.010943000000000001],["Silver Clamshell",0.001094],["Onyx",0.0005472],["Pink Diamond",4.377e-7],["Painite",2.1889999999999998e-7],["Moonstone",0.000054720000000000005],["Palladium",8.207e-7],["Topaz",0.005472],["Vortessence",8.206999999999999e-8],["Uranium",0.0000027359999999999997]],"Meteor Falls":[["Gold",0.542536],["Jade",0.001085],["Iridium",0.0000434],["Cobalt",0.0000217],["Diamond",0.0000027129999999999997],["Electrum",0.027127],["Depleted Shard",5.425e-8],["Aetherium",5.425e-9],["Pyrite",0.271268],["Sapphire",0.043403],["Lapis Lazuli",0.005425],["Moonstone",0.000027130000000000003],["Opal",0.0005425],["Mercury",0.00001085],["Star Garnet",1.085e-8],["Radium",5.425e-7],["Nickel",0.10850699999999999],["Vortessence",1.6279999999999998e-8],["Sunstone",5.425e-9],["Starpiercer",2.17e-10]],"Starfall River":[["Gold",0.542536],["Jade",0.001085],["Iridium",0.0000434],["Aurorite",0.0000217],["Aquamarine",0.0000027129999999999997],["Electrum",0.027127],["Depleted Shard",5.425e-8],["Aetherium",5.425e-9],["Pyrite",0.271268],["Sapphire",0.043403],["Lapis Lazuli",0.005425],["Moonstone",0.000027130000000000003],["Opal",0.0005425],["Palladium",5.425e-7],["Star Garnet",1.085e-8],["Singularium",1.085e-10],["Nickel",0.10850699999999999],["Meteoric Gold",0.00001085],["Vortessence",1.6279999999999998e-8],["Sunstone",5.425e-9]],"Timelocked Sanctuary":[["Gold",0.5425260000000001],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Aetherite",0.0000027129999999999997],["Glowmoss",0.000005425],["Firefly Stone",5.425e-8],["Bloodstone",5.425e-10],["Electrum",0.027126],["Diopside",0.0005425],["Bismuth",0.000001628],["Astral Spore",4.34e-10],["Eternium",2.713e-10],["Silver",0.27126300000000003],["Smoky Quartz",0.043402],["Malachite",0.005425],["Onyx",0.001085],["Osmium",0.000027130000000000003],["Lightshard",0.000005425],["Radiant Gold",1.085e-8],["Mercury",0.00001085],["Star Garnet",1.356e-8],["Red Beryl",8.138e-9],["Topaz",0.108505],["Starshine",5.425e-7]],"Astral Caverns":[["Gold",0.519968],["Jade",0.00104],["Iridium",0.000041599999999999995],["Aurorite",0.000020799999999999997],["Aquamarine",0.0000025999999999999997],["Electrum",0.025998],["Depleted Shard",1.04e-7],["Celestium",5.2e-11],["Aetherium",5.2e-9],["Silver",0.259984],["Sapphire",0.041597],["Lapis Lazuli",0.0052],["Meteoric Iron",0.041597],["Moonstone",0.000026],["Opal",0.00052],["Palladium",5.2e-7],["Red Beryl",9.359e-9],["Nickel",0.103994],["Meteoric Gold",0.000010399999999999999],["Vortessence",1.56e-8],["Sunstone",5.2e-9]],"Rubble Creek Deposits":[["Gold",0.521295],["Iridium",0.0001564],["Emerald",0.000041700000000000004],["Aurorite",0.00007819],["Diamond",0.000002085],["Catseye",0.000001043],["Aetherite",7.819e-7],["Pyrite",0.156389],["Platinum",0.260648],["Sapphire",0.005213],["Ruby",0.002085],["Lapis Lazuli",0.001303],["Meteoric Iron",0.0006256],["Pink Diamond",2.085e-7],["Osmium",0.00001043],["Opal",0.00001564],["Rose Gold",0.000005213000000000001],["Titanium",0.041704],["Topaz",0.010426]],"Lifespring Oasis":[["Gold",0.516447],["Inferlume",1.653e-8],["Catseye",5.164e-7],["Electrum",0.025821999999999998],["Depleted Shard",1.0329999999999999e-7],["Aetherium",5.681e-9],["Agate",4.648e-9],["Platinum",0.129112],["Obsidian",0.258224],["Ruby",0.010329],["Peridot",0.005163999999999999],["Onyx",0.001033],["Mercury",0.000036150000000000005],["Meteoric Gold",0.000010330000000000001],["Sandsteel",0.001549],["Selenite",0.0006196999999999999],["Jasper",0.000005164],["Key of Life",1.549e-11],["Topaz",0.051645],["Starshine",0.000002582]],"Mystic Floodplains":[["Gold",0.516446],["Inferlume",1.653e-8],["Catseye",5.164e-7],["Electrum",0.025821999999999998],["Aetherium",5.681e-9],["Agate",4.648e-9],["Eye of the Sands",3.615e-11],["Platinum",0.129112],["Obsidian",0.258223],["Ruby",0.010329],["Peridot",0.005163999999999999],["Onyx",0.001033],["Mercury",0.000036150000000000005],["Radium",0.000002066],["Meteoric Gold",0.000010330000000000001],["Sandsteel",0.001549],["Selenite",0.0006196999999999999],["Jasper",0.000005164],["Topaz",0.051645],["Starshine",0.000002582]],"Sandstone Stream":[["Gold",0.517301],["Inferlume",1.655e-8],["Fire Opal",5.173e-7],["Electrum",0.025865],["Aetherium",5.69e-9],["Agate",4.656e-9],["Platinum",0.129325],["Obsidian",0.258651],["Ruby",0.010346],["Peridot",0.005173],["Osmium",0.0005172999999999999],["Mercury",0.00003621],["Radium",0.000002069],["Meteoric Gold",0.00001035],["Sandsteel",0.001035],["Jasper",0.000005173],["Solarium",8.277e-11],["Topaz",0.05173],["Starshine",0.000002587]],"North Pole":[["Gold",0.279264],["Blue Ice",0.279264],["Jade",0.013963000000000001],["Glacial Quartz",0.002234],["Frostshard",2.234e-8],["Iridium",0.0001396],["Borealite",0.00004468],["Aurorite",0.00001676],["Cobalt",0.00002234],["Diamond",0.000004468],["Aetherite",0.000002234],["Aquamarine",0.000002234],["Candy Cane",0.0005585],["Silver",0.279264],["Sapphire",0.033512],["Pink Diamond",1.117e-7],["Peppermint Prism",0.000001117],["North Star",2.793e-9],["Titanium",0.111706]],"Frozen Peak":[["Blue Ice",0.51501],["Cryonic Artifact",6.4379999999999995e-9],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Frostshard",1.609e-8],["Iridium",0.00012880000000000001],["Borealite",0.0000515],["Aurorite",0.00001931],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aetherite",0.0000025750000000000003],["Aquamarine",0.0000012879999999999998],["Silver",0.321882],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",3.219e-8],["Titanium",0.128753],["Tourmaline",0.0000016090000000000002]],"Frostbite River":[["Blue Ice",0.51501],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Iridium",0.00012880000000000001],["Emerald",0.00001931],["Borealite",0.0000515],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aquamarine",0.0000012879999999999998],["Silver",0.321882],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",2.575e-8],["Palladium",0.0000025750000000000003],["Titanium",0.128753],["Vortessence",8.369e-8],["Tourmaline",0.0000016090000000000002]],"Frostbite Waterfall":[["Blue Ice",0.51501],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Frostshard",1.609e-8],["Iridium",0.00012880000000000001],["Borealite",0.0000515],["Aurorite",0.00001931],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aetherite",0.0000025750000000000003],["Aquamarine",0.0000012879999999999998],["Silver",0.321881],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",2.575e-8],["Titanium",0.128753],["Vortessence",8.369e-8],["Tourmaline",0.0000016090000000000002]],"Windswept Beach":[["Coral",0.060233999999999996],["Inferlume",9.035000000000001e-8],["Ammonite Fossil",0.00006023],["Fire Opal",0.000003012],["Dragon Bone",0.000004819],["Catseye",0.000003012],["Seashell",0.48187199999999997],["Obsidian",0.24093599999999998],["Pearl",0.180702],["Malachite",0.012047],["Silver Clamshell",0.001807],["Peridot",0.0006023],["Onyx",0.001205],["Meteoric Iron",0.002409],["Osmium",0.00001807],["Opal",0.00001807],["Rose Gold",0.000009035],["Topaz",0.01807],["Vortessence",9.035000000000001e-8]],"Sunset Beach":[["Coral",0.056664000000000006],["Inferlume",8.5e-8],["Ashvein",0.0001133],["Golden Pearl",0.00022669999999999998],["Diamond",0.000005666],["Aetherite",0.000001133],["Silver",0.283321],["Seashell",0.453314],["Pearl",0.169993],["Neodymium",0.022666],["Smoky Quartz",0.011333],["Silver Clamshell",0.0017000000000000001],["Onyx",0.0005666],["Painite",2.267e-7],["Moonstone",0.00005666],["Opal",0.000022669999999999998],["Luminum",0.000017]],"Seashell Beach":[["Coral",0.056661],["Inferlume",8.499e-8],["Ammonite Fossil",0.00005666],["Ashvein",0.0001133],["Golden Pearl",0.0002266],["Aetherite",0.000001133],["Forgotten Totem",2.833e-9],["Silver",0.28330500000000003],["Seashell",0.453288],["Pearl",0.169983],["Neodymium",0.022664],["Smoky Quartz",0.011332],["Silver Clamshell",0.0017000000000000001],["Onyx",0.0005666],["Painite",2.266e-7],["Moonstone",0.00005666],["Opal",0.000022659999999999996],["Luminum",0.000017],["Red Beryl",8.499e-9],["Nautilus Shell",0.000005666]],"Overgrown Grotto (inside Firefly Zones)":[["Firefly Stone",2.334e-7]],"Deeproot Spring (inside Firefly Zones)":[["Firefly Stone",2.2589999999999998e-7]],"Enchanted Ruins (outside Firefly Zones)":[["Firefly Stone",5.837e-8]],"Overgrown Grotto (outside Firefly Zones)":[["Firefly Stone",4.668e-8]],"Deeproot Spring (outside Firefly Zones)":[["Firefly Stone",4.518e-8]],"The Void":[["Voidstone",7.245e-9]]}]==]
local DROPS=HttpService:JSONDecode(DREDGE_ODDS)
local ALL_ZONES,POOL,SHARES={},{},{}
S.dredge=false;S.dredgePurifying=false;S.dredgeRisk=false
S.dredgeCurrent=nil;S.dredgeGroup=nil;S.dredgeAppliedCap="UNSET"
S.dredgeUncappedLuck=nil;S.dredgeLuckReadyAt=0
S.dredgeTravelFailed={};S.dredgeWarped={}
S.dredgeReadyAt=0;S.dredgeZoneCycle=0;S.dredgeZoneSince=0
S.dredgeFailureCount=0;S.dredgeFailureZone=nil
S.dredgeCurrentWork="Idle";S.dredgeNextWork="Awaiting plan"
S.dredgeCapLastAt=-math.huge;S.dredgeCapLockedZone=nil
S.dredgeCapLockedKey=nil;S.dredgeTurnAttempts=0
local dredgeButton,dredgeStatus,show,stop
local function dredgeText(str)
    if dredgeStatus then dredgeStatus.Text=str end
    if S.dredgeLastText~=str then S.dredgeLastText=str;print("[GALAXIS DREDGE] "..str) end
end
local function baseDrop(s)
    return (s:gsub("%s*%(inside Firefly Zones%)","")
        :gsub("%s*%(outside Firefly Zones%)","")
        :gsub("%s*%(when in the loot pool%)",""))
end
local function poolFor(z)
    if POOL[z] then return POOL[z] end
    local own=DROPS[z] or {};local base=baseDrop(z)
    local out={}
    if base~=z and DROPS[base] then
        local replace={}
        for _,x in ipairs(own) do replace[x[1]]=true end
        for _,x in ipairs(DROPS[base]) do if not replace[x[1]] then out[#out+1]=x end end
        for _,x in ipairs(own) do out[#out+1]=x end
    elseif #own<2 then
        local seen={}
        for other,xs in pairs(DROPS) do
            if other~=z and baseDrop(other)==z then
                for _,x in ipairs(xs) do
                    if not seen[x[1]] then seen[x[1]]=true;out[#out+1]=x end
                end
                for _,x in ipairs(own) do
                    if not seen[x[1]] then seen[x[1]]=true;out[#out+1]=x end
                end
            end
        end
    else
        for _,x in ipairs(own) do out[#out+1]=x end
    end
    if #out<2 then out={} end
    table.sort(out,function(a,b) return a[2]<b[2] end)
    POOL[z]=out
    return out
end
for z,rows in pairs(DROPS) do
    if #poolFor(z)>0 and (#rows>1 or baseDrop(z)~=z) then
        ALL_ZONES[#ALL_ZONES+1]=z
    end
end
table.sort(ALL_ZONES)
local function rareBand(n)
    local l=math.log(math.max(n,1))/math.log(10)
    return 1+.858*math.min(math.clamp((l-7.26)/.5,0,1),math.clamp((9.67-l)/.5,0,1))
end
local function oddsFor(z,L)
    L=math.max(1,L)
    local key=z.."|"..string.format("%.12g",L)
    if SHARES[key] then return SHARES[key] end
    local rows=poolFor(z)
    local total=0
    for _,x in ipairs(rows) do total+=x[2] end
    local ties,c={},0
    for _,x in ipairs(rows) do
        local p=x[2];local t=ties[p]
        if t then t[2]+=p;t[3]+=1 else ties[p]={c,c+p,1} end
        c+=p
    end
    local results={}
    if total>0 then
        local function f(a,b,l) return (1-a)^l-(1-b)^l end
        for _,x in ipairs(rows) do
            local p=x[2];local t=ties[p]
            local lo,hi=t[1]/total,t[2]/total
            results[x[1]]=(.2891*f(lo,hi,1)
                +.0280*f(lo,hi,math.max(1,.04317*L))
                +.1905*f(lo,hi,math.max(1,.40579*L))
                +.4924*f(lo,hi,math.max(1,1.74153*L)))
                /t[3]*rareBand(total/p)
        end
    end
    SHARES[key]=results
    return results
end
local function openNow(z)
    local t=os.date("*t")
    local min=t.min+t.sec/60
    if z=="Timelocked Sanctuary" then return min>=46 or min<14 end
    if z=="Infernal Heart" then return min>=16 and min<44 end
    return true
end
local function totemNear(pos)
    local checked=0
    for _,obj in ipairs(workspace:GetDescendants()) do
        local n=obj.Name:lower()
        if n:find("totem",1,true)
            and (n:find("lumin",1,true) or n:find("light",1,true)) then
            checked+=1
            if checked>100 then break end
            local cf=getWaypointCF(obj)
            if cf and (cf.Position-pos).Magnitude<65
                and (obj:GetAttribute("Active")==true or obj:GetAttribute("Enabled")==true) then
                return true
            end
        end
    end
    return false
end
local function eligible(z,tier)
    if z:find("inside Firefly Zones",1,true) then return false end
    local base=baseDrop(z)
    local preset=S.presets[base]
    if not zoneIndex[base] or not preset or not unpackCF(preset.dig)
        or not unpackCF(preset.water) or not waypointIndex[preset.waypoint or ""] then return false end
    if base=="The Void" or base=="Haunted Creek" or base=="North Pole"
        or base=="Seashell Beach" or base:find("Tomb Vein",1,true) then return false end
    if base=="Magma Furnace" then return false end -- Cannot verify fire protection
    if base=="Fungal Marsh" then return tier>=2 and S.dredgePurifying end
    if base=="Rotwood Swamp" then return tier>=3 and S.dredgeRisk end
    if base=="Timelocked Sanctuary" or base=="Infernal Heart" then return tier>=4 and openNow(base) end
    if base=="Abyssal Depth" then
        return tier>=5 and S.dredgeRisk and totemNear(unpackCF(preset.dig).Position)
    end
    return true
end
local function groupBest(group,places,L,per)
    local best
    for _,z in ipairs(places) do
        local has={}
        for _,row in ipairs(poolFor(z)) do has[row[1]]=true end
        local matches=true
        for _,q in ipairs(group) do if not has[q.m] then matches=false;break end end
        if matches then
            for c=0,#CAPS do
                local cap=c==0 and nil or CAPS[c]
                if cap==nil or cap<L then
                    local shares=oddsFor(z,cap and cap*.63 or L)
                    local worst=0
                    for _,q in ipairs(group) do
                        local p=shares[q.m] or 0
                        worst=p>0 and math.max(worst,q.n/(p*per)) or math.huge
                    end
                    if worst<math.huge and (not best or worst<best.pans*(1-1e-9)
                        or (math.abs(worst-best.pans)<=best.pans*1e-9
                        and cap==nil and best.cap~=nil)) then
                        best={z=z,cap=cap,pans=worst,group=group}
                    end
                end
            end
        end
    end
    return best
end
local function partitions(wants)
    local out,sets={},{}
    local function rec(i)
        if i>#wants then
            local clone={}
            for _,group in ipairs(sets) do
                local arr={}
                for _,v in ipairs(group) do arr[#arr+1]=v end
                clone[#clone+1]=arr
            end
            out[#out+1]=clone;return
        end
        for _,g in ipairs(sets) do
            g[#g+1]=wants[i];rec(i+1);table.remove(g)
        end
        sets[#sets+1]={wants[i]};rec(i+1);table.remove(sets)
    end
    rec(1)
    return out
end
local function optimize(wants,places,L,cap)
    local per=math.max(1,.6779*math.max(1,cap)^.56474)
    local options={}
    for _,groups in ipairs(partitions(wants)) do
        local stops,total,valid={},0,true
        for _,group in ipairs(groups) do
            local v=groupBest(group,places,L,per)
            if not v then valid=false;break end
            stops[#stops+1]=v;total+=v.pans
        end
        if valid then options[#options+1]={stops=stops,total=total} end
    end
    if #options==0 then return nil end
    local cheapest=math.huge
    for _,v in ipairs(options) do
        v.cost=v.total+2*(#v.stops-1)
        cheapest=math.min(cheapest,v.cost)
    end
    table.sort(options,function(a,b)
        local aa,bb=a.cost<=cheapest*1.15,b.cost<=cheapest*1.15
        if aa~=bb then return aa end
        if aa and bb and #a.stops~=#b.stops then return #a.stops<#b.stops end
        return a.cost<b.cost
    end)
    return options[1]
end
local function bestRoute(wants,L,cap)
    local fallback
    for tier=1,5 do
        local places,reachable={},{}
        for _,z in ipairs(ALL_ZONES) do
            if eligible(z,tier) then
                places[#places+1]=z
                for _,x in ipairs(poolFor(z)) do reachable[x[1]]=true end
            end
        end
        local can={}
        for _,w in ipairs(wants) do if reachable[w.m] then can[#can+1]=w end end
        if #can>0 then
            local plan=optimize(can,places,L,cap)
            if plan then
                plan.covered=#can;plan.needed=#wants
                if #can==#wants then return plan end
                if not fallback or plan.covered>fallback.covered then fallback=plan end
            end
        end
    end
    return fallback
end
local function getQuest()
    if type(getsenv)~="function" then return nil end
    local gui=P:FindFirstChild("PlayerGui")
    local main=gui and gui:FindFirstChild("MainUI")
    if not main then return nil end
    local candidates={}
    local view=main:FindFirstChild("QuestView")
    local questScript=view and view:FindFirstChild("QuestUILocal",true)
    if questScript then candidates[#candidates+1]=questScript end
    local questPanel=main:FindFirstChild("Quests")
    local disp=questPanel and questPanel:FindFirstChild("QuestDisplayLocal",true)
    if disp then candidates[#candidates+1]=disp end
    for _,obj in ipairs(candidates) do
        local ok,env=pcall(getsenv,obj)
        if ok and type(env)=="table" then
            local function from(rootTable)
                if type(rootTable)~="table" then return nil end
                local a=rootTable.currentQuestData
                local b=rootTable.localQuestData
                if type(a)=="table" and type(a.DredgeMaster)=="table" then return a.DredgeMaster end
                if type(b)=="table" and type(b.DredgeMaster)=="table" then return b.DredgeMaster end
            end
            local quest=from(env._G) or from(env)
            if quest then return quest end
        end
    end
    return nil
end
local function remaining(state)
    if type(state)~="table" or type(state.StepProgress)~="table" then
        return nil,"Progress not available"
    end
    local merged,collectSeen,hasTalk,done={},false,false,true
    -- Dredge quests have a collection step followed by a separate Talk step.
    -- When the collection step advances, the cache no longer has Collect entries.
    for _,p in pairs(state.StepProgress) do
        if type(p)=="table" then
            local qty=tonumber(p.Amount)
            local progress=tonumber(p.Progress) or 0
            if p.Talk=="DredgeMaster" then
                hasTalk=true
            elseif type(p.Collect)=="string" and p.Collect~="" and qty then
                collectSeen=true
                local left=math.max(0,math.ceil(qty-progress-1e-7))
                merged[p.Collect]=(merged[p.Collect] or 0)+left
                if left>0 then done=false end
            elseif qty and qty>progress then
                return nil,"Unexpected non-mineral objective"
            end
        end
    end
    if hasTalk then return {},true end
    local step=tonumber(state.Step or state.CurrentStep or state.StepNumber)
    if step and step>=2 then return {},true end
    if not collectSeen then return nil,"No collect entries; checking server step" end
    local list={}
    for name,n in pairs(merged) do if n>0 then list[#list+1]={m=name,n=n} end end
    table.sort(list,function(a,b) return a.m<b.m end)
    return list,done
end
local function questsRemote()
    local f=RS:FindFirstChild("Remotes")
    return f and f:FindFirstChild("Quests")
end
-- Read a server step ONLY as a fallback, not once per pan or per mineral.
local function serverQuestStep(id)
    if os.clock()-(S.dredgeLastStepQuery or -math.huge)<5 then return nil end
    S.dredgeLastStepQuery=os.clock()
    local qr=questsRemote()
    local remote=qr and qr:FindFirstChild("GetCurrentQuestStep")
    if not remote or not remote:IsA("RemoteFunction") then return nil end
    local ok,result=invoke(remote,id,"DredgeMaster")
    if not ok then return nil end
    if type(result)=="number" then return result end
    if type(result)=="table" then
        return tonumber(result.Step or result.CurrentStep or result.StepNumber)
    end
    return tonumber(result)
end
local function startQuest(id)
    local container=RS:FindFirstChild("Quests")
    local obj=container and container:FindFirstChild("DredgeMaster")
    local r=questsRemote()
    local f=r and r:FindFirstChild("StartQuest")
    if not obj or not f or not f:IsA("RemoteFunction") then return false end
    return invoke(f,id,obj,nil,"DredgeMaster")
end
-- The game's dialog decision is authoritative:
-- local canStart,status,step = CanStartQuest:InvokeServer(DredgeMaster)
-- status=="Started" and step==2 => QuestCompleting / QuestTalked
-- status=="Started" and step==1 => actively collecting
-- canStart==true otherwise => InitialPrompt / StartQuest.
-- Poll this at a low rate OUTSIDE the farm worker so panning stays fast.
local function questMode(snapshot)
    if not snapshot then return "unknown" end
    if snapshot.status=="Started" then
        if snapshot.step==2 then return "turnin" end
        return "active"
    end
    if snapshot.canStart==true then return "available" end
    return "unavailable"
end
local function queryQuestStatus(id)
    local rem=questsRemote()
    local questFolder=RS:FindFirstChild("Quests")
    local quest=questFolder and questFolder:FindFirstChild("DredgeMaster")
    local fn=rem and rem:FindFirstChild("CanStartQuest")
    if not quest or not fn or not fn:IsA("RemoteFunction") then
        return nil,"CanStartQuest remote or quest definition missing"
    end
    local ok,canStart,status,step=pcall(function()
        return fn:InvokeServer(quest)
    end)
    if not ok then return nil,"CanStartQuest: "..tostring(canStart) end
    if not valid(id) then return nil,"Dredge stopped" end
    local result={canStart=canStart,status=status,step=tonumber(step),time=os.clock()}
    return result
end
local function refreshDredgeServerQuest(id)
    local state,err=queryQuestStatus(id)
    if not valid(id) then return end
    if not state then
        S.dredgeQuestPollError=err
        return
    end
    S.dredgeQuestPollError=nil
    local old=S.dredgeServerStatus
    S.dredgeServerStatus=state
    if not old or old.status~=state.status or old.step~=state.step
      or old.canStart~=state.canStart then
        print("[GALAXIS DREDGE QUEST] CanStartQuest:",tostring(state.canStart),
            "status:",tostring(state.status),"step:",tostring(state.step))
    end
    -- The server can supply current StepProgress even if the UI cache is stale.
    if questMode(state)=="active" then
        local qr=questsRemote()
        local fn=qr and qr:FindFirstChild("GetCurrentQuestStep")
        if fn and fn:IsA("RemoteFunction") then
            local ok,result=pcall(function() return fn:InvokeServer("DredgeMaster") end)
            if ok and type(result)=="table" and type(result.StepProgress)=="table"
              and valid(id) then S.dredgeServerProgress=result end
        end
    else
        S.dredgeServerProgress=nil
    end
end
task.spawn(function()
    while S.alive do
        if S.dredge and S.running and
            os.clock()>=(S.dredgeNextServerPoll or 0) and
            not S.dredgePollBusy then
            S.dredgePollBusy=true
            S.dredgeNextServerPoll=os.clock()+5
            local current=S.token
            local ok,err=pcall(refreshDredgeServerQuest,current)
            if not ok then
                S.dredgeQuestPollError=tostring(err)
                warn("[GALAXIS DREDGE] Server quest poll:",err)
            end
            S.dredgePollBusy=false
        end
        task.wait(.2)
    end
end)

-- Walking-first travel. Every segment uses Humanoid:MoveTo and a
-- computed path; this never moves the avatar by artificial flight or
-- stair-step CFrames. Failure is reported rather than looped indefinitely.
local function stableAt(cf,id,radius,hold,maxWait)
    local start=os.clock()
    local inside=nil
    while valid(id) and os.clock()-start<(maxWait or 3) do
        local r=root()
        if not r then return false end
        if (r.Position-cf.Position).Magnitude<radius then
            inside=inside or os.clock()
            if os.clock()-inside>=(hold or .8) then return true end
        else
            inside=nil
        end
        task.wait(.07)
    end
    return false
end
local function walkRoute(cf,id,maxDistance)
    local r=root()
    local character=P.Character
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    if not r or not hum or hum.Health<=0 then return false,"Character unavailable" end
    local distance=(r.Position-cf.Position).Magnitude
    if distance<7 then return stableAt(cf,id,9,.55,1.8) end
    local limit=maxDistance or 850
    if distance>limit then return false,"Beyond walking limit: "..math.floor(distance) end
    local deadline=os.clock()+math.clamp(distance/math.max(8,hum.WalkSpeed)*2.8+18,17,170)
    local segment=0
    local failures=0
    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances={character}
    while valid(id) and os.clock()<deadline do
        r=root()
        if not r or hum.Health<=0 then return false,"Character lost while walking" end
        distance=(r.Position-cf.Position).Magnitude
        if distance<9 then
            if stableAt(cf,id,11,1.2,2.7) then return true end
            return false,"Destination did not remain stable"
        end
        segment+=1
        if segment>math.ceil(limit/115)+7 then return false,"Walking segments exceeded" end
        local endpoint
        if distance<=160 then
            endpoint=cf.Position
        else
            local point=r.Position+(cf.Position-r.Position).Unit*125
            local hit=workspace:Raycast(point+Vector3.new(0,70,0),
                Vector3.new(0,-210,0),rayParams)
            endpoint=hit and (hit.Position+Vector3.new(0,3,0)) or point
        end
        local ok,path=pcall(function()
            local p=PathfindingService:CreatePath({
                AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5
            })
            p:ComputeAsync(r.Position,endpoint)
            return p
        end)
        if not ok or not path or path.Status~=Enum.PathStatus.Success then
            failures+=1
            if failures>=2 then return false,"No walkable path to "..math.floor(distance).." studs" end
            if not pause(.6,id) then return false,"Stopped" end
        else
            local before=(r.Position-cf.Position).Magnitude
            local nodes=path:GetWaypoints()
            if #nodes==0 then return false,"Path has no walking points" end
            for _,node in ipairs(nodes) do
                if not valid(id) or os.clock()>deadline then return false,"Walk interrupted/timed out" end
                r=root()
                if not r or hum.Health<=0 then return false,"Character lost" end
                if (r.Position-node.Position).Magnitude>4.5 then
                    if node.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
                    hum:MoveTo(node.Position)
                    local walkingDist=(r.Position-node.Position).Magnitude
                    local perNode=math.clamp(walkingDist/math.max(8,hum.WalkSpeed)*2.5+1.3,2.3,10)
                    local nodeDeadline=math.min(deadline,os.clock()+perNode)
                    while valid(id) and os.clock()<nodeDeadline do
                        r=root()
                        if not r or hum.Health<=0 then return false,"Character lost" end
                        if (r.Position-node.Position).Magnitude<=4.8 then break end
                        task.wait(.075)
                    end
                    if not r or (r.Position-node.Position).Magnitude>6 then
                        failures+=1
                        break
                    end
                end
            end
            r=root()
            if not r then return false,"Character lost" end
            local after=(r.Position-cf.Position).Magnitude
            if before-after>7 then failures=0 else failures+=1 end
            if failures>=2 then return false,"Walking stalled / server corrected movement" end
        end
    end
    return false,"Walk timed out"
end
local function pathTo(cf,id)
    -- Short-range walking for NPC prompts and local movement.
    return walkRoute(cf,id,135)
end
-- In Dredge mode, walk between the saved dig/water coordinates.
-- Manual Auto Farm still uses its original fast move().
local function farmMove(cf,id)
    if not S.dredge then return move(cf,id) end
    local r=root()
    local humanoid=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if not r or not humanoid or humanoid.Health<=0 then return false end
    local dist=(r.Position-cf.Position).Magnitude
    if dist<7 then return stableAt(cf,id,9,.45,2) end
    if dist<=46 and math.abs(r.Position.Y-cf.Position.Y)<=13 then
        humanoid:MoveTo(cf.Position)
        local deadline=os.clock()+math.clamp(dist/math.max(8,humanoid.WalkSpeed)*2.8+2,4,13)
        while valid(id) and os.clock()<deadline do
            r=root()
            if not r then return false end
            if (r.Position-cf.Position).Magnitude<8 then
                return stableAt(cf,id,10,.45,1.6)
            end
            task.wait(.075)
        end
    end
    local arrived,err=walkRoute(cf,id,215)
    if not arrived then warn("[GALAXIS DREDGE] Local walk failed:",tostring(err)) end
    return arrived
end
-- Traverse optionally recorded coarse checkpoints (stone -> dig).
-- Reversing the same list returns the avatar to the fast-travel stone.
local function followRoutePoints(zoneName,id,reverse)
    local p=S.presets[zoneName]
    local nodes=p and p.route or {}
    for i=1,#nodes do
        local index=reverse and (#nodes-i+1) or i
        local cf=unpackCF(nodes[index])
        if cf then
            local r=root()
            if not r then return false,"Character missing" end
            if (r.Position-cf.Position).Magnitude>14 then
                local ok,err=walkRoute(cf,id,925)
                if not ok then
                    return false,"Route checkpoint "..index.."/"..#nodes..": "..tostring(err)
                end
            end
        end
    end
    return valid(id)
end
local function returnToMappedStone(id)
    local oldZone=S.dredgeAt
    if not oldZone then return true end
    local p=S.presets[oldZone]
    local folder=waypointFolder()
    local obj=p and folder and folder:FindFirstChild(p.waypoint or "")
    local stone=obj and getWaypointCF(obj)
    if not stone then return false,"Old zone waypoint missing: "..oldZone end
    local r=root()
    if not r then return false,"Character missing" end
    if (r.Position-stone.Position).Magnitude<=65 then return true end
    S.dredgeCurrentWork="Walking back to "..tostring(p.waypoint).." stone"
    local ok,err=followRoutePoints(oldZone,id,true)
    if not ok then return false,err end
    return walkRoute(stone,id,1150)
end
local function walkFromStoneToZone(zoneName,id)
    local p=S.presets[zoneName]
    local target=p and unpackCF(p.dig)
    if not target then return false,"Missing dig coordinates: "..zoneName end
    S.dredgeCurrentWork="Walking from stone to "..zoneName
    local ok,err=followRoutePoints(zoneName,id,false)
    if not ok then return false,err end
    local reached,why=walkRoute(target,id,1150)
    if not reached then return false,why end
    if stableAt(target,id,12,1.0,3.1) then return true end
    return false,"Reached dig position but did not stay there"
end
local function goWaypoint(wp,id)
    local folder=waypointFolder()
    local r=root()
    local to=folder and folder:FindFirstChild(wp or "")
    local target=to and getWaypointCF(to)
    if not r or not target then return false,"Waypoint missing: "..tostring(wp) end
    if (r.Position-target.Position).Magnitude<65 then
        return stableAt(target,id,78,1.0,2.5)
    end

    -- Never fire FastTravel from the middle of a mining zone. Walk the
    -- saved route BACK to its mapped stone, in reverse order, first.
    local oldZone=S.dredgeAt
    if oldZone then
        local ok,err=returnToMappedStone(id)
        if not ok then return false,"Could not return from "..oldZone..": "..tostring(err) end
    end
    r=root()
    if not r then return false,"Character missing" end
    local from=closestWaypoint(folder,r.Position)
    if not from then return false,"No departure waypoint found" end
    local origin=getWaypointCF(from)
    if not origin then return false,"Departure waypoint has no pivot" end
    if (r.Position-origin.Position).Magnitude>62 then
        -- In initial startup, reach a nearby stone using NORMAL walking.
        -- Fail rather than firing a remote from far away.
        S.dredgeCurrentWork="Walking to departure stone "..from.Name
        local ok,err=walkRoute(origin,id,800)
        if not ok then return false,"Cannot walk to departure stone: "..tostring(err) end
        r=root()
        if not r or (r.Position-origin.Position).Magnitude>75 then
            return false,"Departure stone approach did not stick"
        end
    end
    if from==to then
        return stableAt(target,id,78,1.0,2.7)
    end
    local rem=RS:FindFirstChild("Remotes")
    local misc=rem and rem:FindFirstChild("Misc")
    local travel=misc and misc:FindFirstChild("FastTravel")
    if not travel or not travel:IsA("RemoteEvent") then
        return false,"FastTravel remote missing"
    end
    S.dredgeCurrentWork="Fast Travel: "..from.Name.." -> "..wp
    if not pcall(function() travel:FireServer(from,to) end) then
        return false,"FastTravel request failed"
    end
    if stableAt(target,id,85,1.4,8.0) then return true end
    return false,"Server rejected waypoint travel / pulled character back"
end
local function approachDredgeNPC(id)
    -- NPC proximity matters for some quests. Do not confuse a waypoint
    -- arrival with reaching the actual NPC/dialogue prompt.
    local npcFolder=workspace:FindFirstChild("NPCs")
    local npc=npcFolder and (npcFolder:FindFirstChild("DredgeMaster",true)
            or npcFolder:FindFirstChild("Dredge Master",true))
    if not npc then
        -- Some maps put NPCs in a nested folder; don't scan the whole workspace.
        local map=workspace:FindFirstChild("Map")
        local actors=map and map:FindFirstChild("NPCs",true)
        npc=actors and (actors:FindFirstChild("DredgeMaster",true)
            or actors:FindFirstChild("Dredge Master",true))
    end
    if not npc then return true,"NPC model not exposed; relying on QuestTalked" end
    local npcCF=getWaypointCF(npc)
    if not npcCF then return true,"NPC has no readable pivot" end
    local r=root()
    if r and (r.Position-npcCF.Position).Magnitude<=12 then return true end
    local target=npcCF*CFrame.new(0,0,5)
    if pathTo(target,id) then return true end
    return false,"Could not approach Dredge Master NPC"
end
local function sendDredgeTalk(id)
    local rem=questsRemote()
    local talk=rem and rem:FindFirstChild("QuestTalked")
    if not talk or not talk:IsA("RemoteEvent") then
        return false,"QuestTalked remote unavailable"
    end
    local traveled,reason=goWaypoint("Dredge Master",id)
    if not traveled then
        return false,"Travel to Dredge Master: "..tostring(reason)
    end
    S.dredgeAt=nil
    local ok,why=approachDredgeNPC(id)
    if not ok then return false,why end
    local sent,err=pcall(function() talk:FireServer("DredgeMaster") end)
    if not sent then return false,tostring(err) end
    return true
end
local function handleDredgeTransition(id,mode)
    if mode=="turnin" then
        S.dredgeCurrentWork="Talk to Dredge Master (turn-in)"
        S.dredgeNextWork="Accept next quest"
    elseif mode=="available" then
        S.dredgeCurrentWork="Start Dredge quest"
        S.dredgeNextWork="Plan mineral objectives"
    end
    if S.dredgeTransitionMode~=mode then
        S.dredgeTransitionMode=mode
        S.dredgeTransitionAttempts=0
        S.dredgeTransitionAt=0
    end
    if mode=="turnin" then
        if os.clock()-(S.dredgeTransitionAt or 0)<8 then
            dredgeText("Turn-in sent; awaiting CanStartQuest step change")
            return
        end
        if (S.dredgeTransitionAttempts or 0)>=3 then
            dredgeText("Turn-in did not confirm after 3 talks; stopped")
            if stop then stop() end
            return
        end
        S.dredgeTransitionAttempts+=1
        S.dredgeTransitionAt=os.clock()
        S.dredgeCurrent=nil;S.dredgeGroup=nil
        -- Keep S.dredgeAt until we have walked BACK to the mapped stone.
        S.dredgeCapLockedZone=nil
        local ok,err=sendDredgeTalk(id)
        dredgeText(ok and
            ("Talked to Dredge Master ("..S.dredgeTransitionAttempts.."/3); verifying")
            or ("Turn-in attempt "..S.dredgeTransitionAttempts.."/3: "..tostring(err)))
    elseif mode=="available" then
        if os.clock()-(S.dredgeTransitionAt or 0)<7 then
            dredgeText("StartQuest sent; awaiting Started step 1")
            return
        end
        if (S.dredgeTransitionAttempts or 0)>=3 then
            dredgeText("Quest start not confirmed after 3 tries; stopped")
            if stop then stop() end
            return
        end
        S.dredgeTransitionAttempts+=1
        S.dredgeTransitionAt=os.clock()
        -- Observed Cobalt args: quest, nil, "DredgeMaster".
        local ok,res=startQuest(id)
        dredgeText(ok and res~=false and
            ("StartQuest requested ("..S.dredgeTransitionAttempts.."/3); verifying")
            or ("StartQuest attempt "..S.dredgeTransitionAttempts.."/3 not confirmed"))
    end
    -- Query the authoritative status again soon, without a remote spam loop.
    S.dredgeNextServerPoll=math.min(S.dredgeNextServerPoll or math.huge,os.clock()+1.2)
end

local function safeDig()
    local x=S.presets["Fortune River"]
    return x and unpackCF(x.dig)
end
local function escapeZone()
    -- No long-range CFrame here: this was causing repeated rubber-banding.
    -- Preserve the current zone for the route BACK to its mapped stone.
    S.dredgeRiskZone=false
end
local function dredgeHealthWatch()
    if not S.dredge or not S.running or not S.dredgeRiskZone then return end
    local c=P.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if h and h.Health<h.MaxHealth*.75 then
        escapeZone()
        if stop then stop() end
        dredgeText("STOPPED: Rotwood HP below 75%; no forced teleport; move to safety")
    end
end
local function describeDredgeTargets(group,remaining)
    local parts={}
    for _,v in ipairs(group or {}) do
        parts[#parts+1]=v.m.." ("..tostring(remaining[v.m] or 0).." left)"
    end
    return #parts>0 and table.concat(parts,", ") or "None"
end
local function dredgeCycle(id)
    if not valid(id) or not S.dredge then return false end
    dredgeHealthWatch()
    if not valid(id) or not S.dredge then return false end
    local status=S.dredgeServerStatus
    -- Wait for the server decision (the UI cache can survive a quest reset).
    if not status or os.clock()-status.time>15 then
        dredgeText("Checking CanStartQuest: "..tostring(S.dredgeQuestPollError or "pending"))
        return false
    end
    local mode=questMode(status)
    if mode=="turnin" or mode=="available" then
        handleDredgeTransition(id,mode)
        return false
    end
    if mode=="unavailable" then
        S.dredgeCurrentWork="Waiting for Dredge quest"
        S.dredgeNextWork="Check quest availability"
        dredgeText("Dredge Master not offering a quest: "..tostring(status.status))
        return false
    end
    -- Server now confirms this quest is active, so allow a fresh transition
    -- later without retrying the previous StartQuest or QuestTalked.
    S.dredgeTransitionMode="active"
    S.dredgeTransitionAttempts=0
    local state=getQuest() or S.dredgeServerProgress
    local wants,done=remaining(state)
    if not wants then
        dredgeText(tostring(done or "Waiting for StepProgress"))
        return false
    end
    if done then
        S.dredgeCurrentWork="Mineral collection complete"
        S.dredgeNextWork="Turn in at Dredge Master"
        -- If the client reaches full progress a little before CanStartQuest
        -- advances to step 2, hold rather than farming useless extra pans.
        dredgeText("Collection complete; waiting for server's talk step")
        return false
    end
    S.dredgeStartAt=nil
    local st=P:FindFirstChild("Stats")
    local raw=st and tonumber(st:GetAttribute("Luck"))
    local capacityNow=capacity()
    if not raw or raw<=0 or not capacityNow or capacityNow<=0 then
        dredgeText("Stats.Luck/Capacity unavailable");return false
    end
    -- Script-controlled Pan/Shake reaches 100% quality: no built-in Auto Pan 2/3 penalty.
    -- Capture uncapped Luck once. A capped Stats.Luck value must NOT feed
    -- back into the optimizer (that caused Luck Cap oscillation).
    if os.clock()<S.dredgeLuckReadyAt then
        dredgeText("Waiting for uncapped Luck to replicate")
        return false
    end
    if not S.dredgeUncappedLuck then
        S.dredgeUncappedLuck=raw
        dredgeText("Planning from uncapped Luck "..string.format("%.1f",raw))
    elseif S.dredgeAppliedCap=="NONE" and raw>S.dredgeUncappedLuck*1.01 then
        S.dredgeUncappedLuck=raw
    end
    local L=math.max(1,S.dredgeUncappedLuck)
    local need={}
    for _,w in ipairs(wants) do need[w.m]=w.n end
    local keep=false
    if S.dredgeCurrent and S.dredgeGroup and openNow(baseDrop(S.dredgeCurrent))
        and eligible(S.dredgeCurrent,5)
        and S.dredgePlanLuck and math.abs(L-S.dredgePlanLuck)/math.max(1,S.dredgePlanLuck)<.01
        and S.dredgePlanCapacity==capacityNow then
        local progressShift=false
        for _,g in ipairs(S.dredgeGroup) do
            local planned=S.dredgePlannedRemaining and S.dredgePlannedRemaining[g.m] or 0
            local left=need[g.m] or 0
            if planned>0 and math.abs(planned-left)/planned>=.10 then
                progressShift=true
                break
            end
            if left>0 then keep=true end
        end
        if progressShift then keep=false end
    end
    -- Give a freshly reached deposit three successful pans before changing
    -- zones due to small progress-ratio shifts; do not hold if its quest
    -- objectives are all finished or a timed/safety restriction has changed.
    if not keep and S.dredgeAt and S.dredgeCurrent and S.dredgeGroup
        and S.dredgeAt==baseDrop(S.dredgeCurrent)
        and S.cycles-(S.dredgeZoneCycle or 0)<3
        and openNow(S.dredgeAt) and eligible(S.dredgeCurrent,5)
        and S.dredgePlanLuck and
        math.abs(L-S.dredgePlanLuck)/math.max(1,S.dredgePlanLuck)<.01
        and S.dredgePlanCapacity==capacityNow then
        for _,item in ipairs(S.dredgeGroup) do
            if (need[item.m] or 0)>0 then keep=true;break end
        end
    end
    if not keep then
        local plan=bestRoute(wants,L,capacityNow)
        if not plan or not plan.stops[1] then
            S.dredgeCurrentWork="No accessible safe deposit"
            S.dredgeNextWork="Wait for equipment, coordinates or opening"
            escapeZone()
            dredgeText("Waiting: missing safe zones / ring / timed opening")
            return false
        end
        local choice=plan.stops[1]
        S.dredgeCurrent=choice.z;S.dredgeGroup=choice.group
        S.dredgeTargetCap=choice.cap
        S.dredgePlanLuck=L
        S.dredgePlanCapacity=capacityNow
        S.dredgePlannedRemaining={}
        for _,v in ipairs(wants) do S.dredgePlannedRemaining[v.m]=v.n end
        S.dredgePlanText=string.format("%d/%d goals, ~%.0f pans",
            plan.covered,plan.needed,plan.total)
        S.dredgeNextStop=plan.stops[2]
        S.dredgePlanCoverage=plan.covered
        S.dredgePlanRequired=plan.needed
    end
    local targetZone=baseDrop(S.dredgeCurrent)
    S.dredgeCurrentWork=describeDredgeTargets(S.dredgeGroup,need).." @ "..targetZone
    if S.dredgeNextStop then
        S.dredgeNextWork=describeDredgeTargets(S.dredgeNextStop.group,need)..
            " @ "..baseDrop(S.dredgeNextStop.z)
    elseif (S.dredgePlanCoverage or 0)<(S.dredgePlanRequired or 0) then
        S.dredgeNextWork="Wait for inaccessible or timed minerals"
    else
        S.dredgeNextWork="Turn in Dredge quest when complete"
    end
    local p=S.presets[targetZone]
    if not p or not openNow(targetZone) then
        S.dredgeCurrent=nil;S.dredgeGroup=nil
        escapeZone()
        dredgeText("Timed zone closed; waiting without forced teleport")
        return false
    end
    if S.dredgeAt~=targetZone then
        S.dig=unpackCF(p.dig);S.water=unpackCF(p.water)
        if not S.dig or not S.water then
            dredgeText("Zone coordinates missing");return false
        end
        if S.dredgeTravelRetryAt and os.clock()<S.dredgeTravelRetryAt then
            dredgeText("Travel cooldown - preventing warp spam");return false
        end
        dredgeText("Walking to "..targetZone)
        local r=root()
        local closeEnough=r and (r.Position-S.dig.Position).Magnitude<165
        local arrived,why=false,nil
        if closeEnough then
            arrived,why=walkRoute(S.dig,id,230)
            if arrived then arrived=stableAt(S.dig,id,12,1,3) end
        end
        if not arrived and not S.dredgeWarped[targetZone] then
            -- One attempt: return to OLD stone via reversed checkpoints,
            -- official game warp, then forward checkpoints into the new zone.
            S.dredgeWarped[targetZone]=true
            dredgeText("Following stone route: "..tostring(p.waypoint))
            local warped,err=goWaypoint(p.waypoint,id)
            if warped then arrived,why=walkFromStoneToZone(targetZone,id)
            else why=err end
        end
        if not arrived then
            S.dredgeCurrentWork="Route blocked: "..targetZone
            S.dredgeNextWork="Record checkpoints (stone -> dig) or move manually"
            local tries=(S.dredgeTravelFailed[targetZone] or 0)+1
            S.dredgeTravelFailed[targetZone]=tries
            S.dredgeTravelRetryAt=os.clock()+8
            dredgeText("Zone route blocked: "..targetZone..": "..tostring(why))
            -- A rejected/blocked route will not repair itself after a fast
            -- retry. Stop immediately rather than continuously warping.
            if stop then stop() end
            dredgeText("Stopped: no stable walking route to "..targetZone)
            return false
        end
        S.dredgeTravelRetryAt=nil
        -- After a successful arrival, allow one new fallback warp on a
        -- separate FUTURE visit, not repeatedly during this visit.
        S.dredgeWarped[targetZone]=nil
        S.dredgeTravelFailed[targetZone]=nil
        S.dredgeAt=targetZone
        S.dredgeZoneSince=os.clock()
        S.dredgeZoneCycle=S.cycles
        S.dredgeReadyAt=os.clock()+1.2
        S.dredgeFailureCount=0
        S.dredgeFailureZone=targetZone
        S.dredgeRiskZone=(targetZone=="Rotwood Swamp")
        if S.dredgeCapLockedZone~=targetZone then
            S.dredgeCapLockedZone=nil
            S.dredgeCapLockedKey=nil
        end
        S.dredgeCapLastAt=-math.huge -- a new zone needs its optimal cap immediately
        S.activeZone=targetZone
    end
    local capKey=S.dredgeTargetCap and tostring(S.dredgeTargetCap) or "NONE"
    -- Also lock when the previously active cap happens to match the new
    -- deposit's cap; no new remote call is needed in that case.
    if not S.dredgeCapLockedZone and S.dredgeAppliedCap==capKey then
        S.dredgeCapLockedZone=targetZone
        S.dredgeCapLockedKey=capKey
    end
    -- Once a cap is selected for a deposit, freeze it there.
    -- A 10% quest progress replan can change odds, but should not repeatedly
    -- send cap updates for the SAME zone. A new zone/quest unlocks a new cap.
    if S.dredgeCapLockedZone==targetZone and S.dredgeCapLockedKey then
        capKey=S.dredgeCapLockedKey
        S.dredgeTargetCap=capKey=="NONE" and nil or tonumber(capKey)
    end
    if S.dredgeAppliedCap~=capKey then
        local rs=RS:FindFirstChild("Remotes")
        local settings=rs and rs:FindFirstChild("Settings")
        local remote=settings and settings:FindFirstChild("ChangeSetting")
        if not remote or not remote:IsA("RemoteEvent") then
            dredgeText("ChangeSetting unavailable");return false
        end
        local capText="None"
        if S.dredgeTargetCap~=nil then
            capText=tostring(S.dredgeTargetCap):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
        end
        if not pcall(function() remote:FireServer("MaximumLuck",capText) end) then return false end
        S.dredgeAppliedCap=capKey
        S.dredgeCapLastAt=os.clock()
        S.dredgeCapLockedZone=targetZone
        S.dredgeCapLockedKey=capKey
        print("[GALAXIS DREDGE] Luck Cap applied once for zone:",targetZone,capText)
        if not pause(.2,id) then return false end
    end
    if os.clock()<(S.dredgeReadyAt or 0) then
        dredgeText("Settling "..targetZone.." deposit/water before collecting")
        return false
    end
    dredgeText(targetZone.." | cap "..tostring(S.dredgeTargetCap or "NONE")
        .." | "..tostring(S.dredgePlanText))
    return true
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
    Size=UDim2.fromOffset(340,463),
    Position=UDim2.new(.5,-170,.5,-231),
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
local sellB=button("AUTO SELL: ON",14,110,312,36,Body)
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
local presetHint=label("SET DIG / WATER saves to MINING ZONE",14,491,312,19,10,MUTED)
local exportPresetButton=button("EXPORT PRESETS TO TXT + CLIPBOARD",14,519,312,35,Body)
dredgeButton=button("AUTO DREDGE: OFF",14,563,312,35,Body)
local ringButton=button("PURIFYING RING: NO",14,606,149,32,Body)
local riskButton=button("RISKY ZONES: OFF",177,606,149,32,Body)
local fullQualityLabel=label("PAN QUALITY: 100%  |  LUCK: FULL (1x)",14,647,312,32,11,FG)
dredgeStatus=label("Dredge idle",14,684,312,22,11,MUTED)
dredgeStatus.TextTruncate=Enum.TextTruncate.AtEnd
local function selectedZone() return ZONE_NAMES[S.selectedZone] end
local function selectedWaypoint() return WAYPOINT_NAMES[S.selectedWaypoint] end
local routeCountLabel
local function refreshPreset()
    local name=selectedZone()
    local p=S.presets[name]
    zoneName.Text=name
    waypointName.Text=selectedWaypoint()
    local mapping=p and p.waypoint or nil
    presetStatus.Text=((p and unpackCF(p.dig)) and "Dig saved" or "Dig missing")..
        " | "..((p and unpackCF(p.water)) and "Water saved" or "Water missing")..
        (mapping and (" | WP: "..mapping) or " | WP: NOT MAPPED")
    if routeCountLabel then
        routeCountLabel.Text="Route: "..tostring(p and p.route and #p.route or 0)..
            " points (stone -> dig; reverse to return)"
    end
    -- Only explicit MAP TO WAYPOINT commits the selector to this zone.
end
refreshPreset()

-- ===== COMPACT 4-TAB INTERFACE =====
-- The existing farm, Dredge and preset controls are the exact same objects
-- (and callbacks). Reparenting them keeps every existing function intact.
local function page()
    return make("Frame",{
        Position=UDim2.fromOffset(0,75),
        Size=UDim2.new(1,0,1,-75),
        BackgroundTransparency=1,
        Visible=false
    },Body)
end
local farmPage,dredgePage,diagnosticPage,treasurePage=page(),page(),page(),page()
local TAB_NAMES={"AUTO FARM","AUTO DREDGE","ZONE DIAG.","TREASURE"}
local TAB_PAGES={farmPage,dredgePage,diagnosticPage,treasurePage}
local tabButtons={}
for i,name in ipairs(TAB_NAMES) do
    tabButtons[i]=button(name,5+(i-1)*84,36,80,32,Body)
    tabButtons[i].TextSize=10
end
local function relocate(widget,parent,x,y)
    widget.Parent=parent
    widget.Position=UDim2.fromOffset(x,y)
end

-- Auto Farm: retain manual digging/panning, selling, and footer.
relocate(digB,farmPage,14,20)
relocate(waterB,farmPage,177,20)
relocate(digXYZ,farmPage,14,61)
relocate(waterXYZ,farmPage,177,61)
relocate(sellB,farmPage,14,101)
relocate(farmB,farmPage,14,151)
relocate(statsFooter,farmPage,14,210)
local farmInstructions=label("Save dig and water positions in your selected zone.",14,256,312,37,11,MUTED)
farmInstructions.TextWrapped=true
relocate(farmInstructions,farmPage,14,256)

-- Auto Dredge: objective readout, safety switches, and 100%-quality model.
relocate(dredgeButton,dredgePage,14,20)
dredgeButton.Size=UDim2.fromOffset(312,42)
relocate(ringButton,dredgePage,14,76)
relocate(riskButton,dredgePage,177,76)
relocate(fullQualityLabel,dredgePage,14,122)
relocate(dredgeStatus,dredgePage,14,154)
dredgeStatus.Size=UDim2.fromOffset(312,45)
dredgeStatus.TextWrapped=true
local dredgeObjectiveLabel=label("Reading Dredge objectives...",14,217,312,86,11,FG)
dredgeObjectiveLabel.TextWrapped=true
dredgeObjectiveLabel.TextYAlignment=Enum.TextYAlignment.Top
relocate(dredgeObjectiveLabel,dredgePage,14,217)
local dredgeWorkLabel=label("NOW: Idle\nNEXT: Waiting for quest",14,309,312,65,11,FG)
dredgeWorkLabel.TextWrapped=true
dredgeWorkLabel.TextYAlignment=Enum.TextYAlignment.Top
relocate(dredgeWorkLabel,dredgePage,14,309)

-- Zone Diagnostic: concise by default. All legacy preset controls retained
-- in a hidden, scrollable editor rather than deleted.
local zoneDiagTitle=label("ZONE DIAGNOSTIC",14,12,312,23,12,FG)
relocate(zoneDiagTitle,diagnosticPage,14,12)
local zoneLiveInfo=label("Reading live deposit...",14,48,312,66,11,MUTED)
zoneLiveInfo.TextWrapped=true
zoneLiveInfo.TextYAlignment=Enum.TextYAlignment.Top
relocate(zoneLiveInfo,diagnosticPage,14,48)
local editPresets=button("EDIT ZONE PRESETS",14,124,312,36,diagnosticPage)
local presetEditor=make("ScrollingFrame",{
    Position=UDim2.fromOffset(10,170),
    Size=UDim2.new(1,-20,1,-181),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    CanvasSize=UDim2.fromOffset(0,520),
    ScrollBarThickness=5,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    Visible=false
},diagnosticPage)
relocate(zoneTitle,presetEditor,4,5)
relocate(prevZone,presetEditor,4,27)
relocate(zoneName,presetEditor,46,27)
relocate(nextZone,presetEditor,280,27)
relocate(warpTitle,presetEditor,4,67)
relocate(prevWaypoint,presetEditor,4,89)
relocate(waypointName,presetEditor,46,89)
relocate(nextWaypoint,presetEditor,280,89)
relocate(loadZone,presetEditor,4,133)
relocate(mapWaypoint,presetEditor,167,133)
relocate(travelWaypoint,presetEditor,4,176)
relocate(importLegacy,presetEditor,167,176)
relocate(presetStatus,presetEditor,4,220)
relocate(presetHint,presetEditor,4,249)
relocate(exportPresetButton,presetEditor,4,286)
-- Fit inherited button positions into the 320 px-wide scroll panel.
loadZone.Size=UDim2.fromOffset(149,36)
mapWaypoint.Size=UDim2.fromOffset(149,36)
travelWaypoint.Size=UDim2.fromOffset(149,36)
importLegacy.Size=UDim2.fromOffset(149,36)
exportPresetButton.Size=UDim2.fromOffset(312,35)
local morePresetHelp=label(
    "Controls preserved for editing, importing, exporting and traveling.",
    4,334,300,40,10,MUTED)
morePresetHelp.TextWrapped=true
relocate(morePresetHelp,presetEditor,4,334)
local addWalkPoint=button("ADD WALK POINT",4,382,149,34,presetEditor)
local clearWalkRoute=button("CLEAR WALK ROUTE",167,382,149,34,presetEditor)
routeCountLabel=label("Route: 0 points (stone -> dig)",4,425,306,40,10,MUTED)
routeCountLabel.TextWrapped=true
relocate(routeCountLabel,presetEditor,4,425)
refreshPreset()
editPresets.MouseButton1Click:Connect(function()
    presetEditor.Visible=not presetEditor.Visible
    zoneLiveInfo.Visible=not presetEditor.Visible
    zoneDiagTitle.Visible=not presetEditor.Visible
    editPresets.Text=presetEditor.Visible and "CLOSE PRESET EDITOR" or "EDIT ZONE PRESETS"
    editPresets.Position=UDim2.fromOffset(14,presetEditor.Visible and 12 or 124)
    presetEditor.Position=UDim2.fromOffset(10,presetEditor.Visible and 61 or 170)
    presetEditor.Size=UDim2.new(1,-20,1,presetEditor.Visible and -70 or -181)
end)

-- Treasure maps intentionally have no automation yet.
local treasureTitle=label("AUTO TREASURE MAP",14,23,312,32,13,FG)
relocate(treasureTitle,treasurePage,14,23)
local treasureNote=label(
    "Coming later. No treasure map remotes are being fired.",
    14,70,312,62,12,MUTED)
treasureNote.TextWrapped=true
relocate(treasureNote,treasurePage,14,70)

local activeTab=1
local function openTab(n)
    activeTab=n
    for i,p in ipairs(TAB_PAGES) do
        p.Visible=i==n
        tabButtons[i].BackgroundColor3=i==n and Color3.fromRGB(70,74,83) or PANEL
        tabButtons[i].TextColor3=i==n and FG or MUTED
    end
end
for i,tab in ipairs(tabButtons) do
    local index=i
    bind(tab.MouseButton1Click,function() openTab(index) end)
end
openTab(1)

-- Quest and live zone diagnostics refresh independently of farming.
task.spawn(function()
    while S.alive do
        if diagnosticPage.Visible then
            local r=root()
            local pos=r and r.Position
            zoneLiveInfo.Text="Current deposit: "..tostring(zone())..
                "\nCharacter: "..(pos and string.format("%.1f, %.1f, %.1f",pos.X,pos.Y,pos.Z) or "not spawned")..
                "\nLoaded farm zone: "..tostring(S.activeZone or "none")
        end
        if dredgePage.Visible then
            dredgeWorkLabel.Text="NOW: "..tostring(S.dredgeCurrentWork or "Idle")..
                "\nNEXT: "..tostring(S.dredgeNextWork or "Awaiting plan")
            local quest=getQuest()
            if quest then
                local progress={}
                local data=quest.StepProgress
                if type(data)=="table" then
                    for _,v in pairs(data) do
                        if type(v)=="table" then
                            if v.Talk=="DredgeMaster" then
                                progress[#progress+1]="Talk to Dredge Master (turn-in)"
                            elseif type(v.Collect)=="string" then
                                progress[#progress+1]=v.Collect..": "..
                                    tostring(v.Progress or 0).."/"..tostring(v.Amount or "?")
                            end
                        end
                    end
                end
                table.sort(progress)
                dredgeObjectiveLabel.Text=#progress>0 and
                    ("QUEST OBJECTIVES\n"..table.concat(progress,"\n"))
                    or "Quest data found; objectives not available"
            else
                dredgeObjectiveLabel.Text="Quest data not yet available"
            end
        end
        task.wait(1)
    end
end)

show=function(t) if S.alive then status.Text=t end end
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

stop=function()
    if not S.alive then return end
    local hadDredge=S.dredge
    S.dredge=false;S.dredgeCurrent=nil;S.dredgeGroup=nil
    S.dredgeAt=nil;S.dredgeRiskZone=false
    if hadDredge and S.dredgeAppliedCap~="NONE" then
        local rem=RS:FindFirstChild("Remotes")
        local setting=rem and rem:FindFirstChild("Settings")
        local change=setting and setting:FindFirstChild("ChangeSetting")
        if change and change:IsA("RemoteEvent") then
            pcall(function() change:FireServer("MaximumLuck","None") end)
        end
    end
    S.dredgeAppliedCap="UNSET";S.dredgeUncappedLuck=nil
    S.dredgeServerStatus=nil;S.dredgeServerProgress=nil
    S.dredgeCapLockedZone=nil;S.dredgeCapLockedKey=nil
    S.dredgePlanLuck=nil;S.dredgePlanCapacity=nil
        S.dredgePlannedRemaining=nil
    if hadDredge and S.dredgeRestore then
        S.dig=S.dredgeRestore.dig;S.water=S.dredgeRestore.water
        S.activeZone=S.dredgeRestore.zone
        digB.Text=S.dig and "DIG SAVED" or "SET DIG"
        waterB.Text=S.water and "WATER SAVED" or "SET WATER"
        digXYZ.Text=S.dig and xyz(S.dig) or "Not saved"
        waterXYZ.Text=S.water and xyz(S.water) or "Not saved"
        S.dredgeRestore=nil
    end
    if dredgeButton then dredgeButton.Text="AUTO DREDGE: OFF" end
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
        if S.dredge and not dredgeCycle(id) then
            if not valid(id) then return end
            if not pause(1.5,id) then return end
            continue
        end
        -- Refresh capacity each cycle, including equipment/buff changes.
        local newCapacity=capacity()
        if newCapacity and newCapacity>0 then target=newCapacity end
        local cycleStart=os.clock()
        show("Digging")
        if not farmMove(S.dig,id) then return "Could not reach dig position" end
        local freshlyChanged=S.dredge and S.dredgeAt and
            (S.cycles-(S.dredgeZoneCycle or 0))<2
        -- After a zone switch, give the new deposit enough time to register
        -- before firing the normal rapid Collect calls. Normal pans unchanged.
        if freshlyChanged and not pause(.42,id) then return end
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
        if S.dredge then
            if not pause(.28,id) then return end
            local finalFill=fill(r)
            if not finalFill or finalFill<target-.01 then
                return "Dig fill not confirmed"
            end
        end
        local digTime=os.clock()-cycleStart

        show("Panning")
        local waterStart=os.clock()
        if not farmMove(S.water,id) then return "Could not reach water" end
        if freshlyChanged and not pause(.5,id) then return end
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
            local now=os.clock()
            if not S.dredge then
                return S.completed or (S.rewards>0 and now-S.lastReward>=CFG.rewardGap)
            end
            if S.completed then
                return S.rewards==0 or now-S.lastReward>=.52
            end
            return S.rewards>0 and now-panStart>=2 and
                now-S.lastReward>=1.4
        end
        -- Experimental early travel after first two rewards and a very short lull.
        -- Starts at ~30ms of quiet instead of ~165ms. If leaving water
        -- interrupts remaining rewards, switch Early TP OFF for that zone.
        -- No further shake packets are sent after teleporting.
        local function tryEarlyMove()
            if S.dredge or not S.earlyTP or earlyMoved or S.completed or S.rewards<2
                or freshlyChanged then return false end
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
        if S.dredge then
            local untilQuiet=os.clock()+.52
            while valid(id) and os.clock()<untilQuiet do
                if S.rewards>0 and os.clock()-S.lastReward<.52 then
                    untilQuiet=os.clock()+.52
                end
                task.wait(.05)
            end
            if not valid(id) then return end
        end
        local shakeTime=os.clock()-shakeStart

        S.waiting=false
        if S.dredge then
            S.dredgeFailureCount=0
            S.dredgeFailureZone=S.dredgeAt
        end
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
bind(addWalkPoint.MouseButton1Click,function()
    if S.running then show("Stop the farm before recording a route");return end
    local r=root()
    if not r then show("Character position unavailable");return end
    local name=selectedZone()
    local p=S.presets[name] or {}
    if not p.waypoint then show("Map this zone to a waypoint first");return end
    local nodes=p.route or {}
    if #nodes>=12 then show("Maximum 12 route points");return end
    local previous=nodes[#nodes]
    local cf=packCF(r.CFrame)
    if previous then
        local last=unpackCF(previous)
        if last and (last.Position-r.Position).Magnitude<5 then
            show("Walk at least 5 studs before adding another point")
            return
        end
    end
    local newRoute={}
    for _,v in ipairs(nodes) do newRoute[#newRoute+1]=v end
    newRoute[#newRoute+1]=cf
    p.route=newRoute
    S.presets[name]=p
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name].route=newRoute
    local ok,err=savePresets()
    refreshPreset()
    show(ok and ("Saved walk point "..#newRoute.." for "..name) or
        ("Route saved only in session: "..tostring(err)))
end)
bind(clearWalkRoute.MouseButton1Click,function()
    if S.running then show("Stop the farm before changing routes");return end
    local name=selectedZone()
    S.presets[name]=S.presets[name] or {}
    S.presets[name].route={}
    S.overrides[name]=S.overrides[name] or {}
    S.overrides[name].route={}
    local ok,err=savePresets()
    refreshPreset()
    show(ok and ("Cleared walk route for "..name) or
        ("Cleared only in session: "..tostring(err)))
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
        "Route points are ordered from mapped stone to digging spot; reverse on return.",
        "An empty field means not configured. This is NOT a complete farming preset until both positions are saved.",
        "",
        "=== MINING ZONES (35) ===",
        "Zone\tMapped Waypoint\tDig CFrame\tWater CFrame\tRoute CFrames (stone -> dig)"
    }
    local mapped,complete=0,0
    for _,name in ipairs(ZONE_NAMES) do
        local p=S.presets[name] or {}
        local wp=p.waypoint or ""
        local dig,water=exportZoneCFrame(p.dig),exportZoneCFrame(p.water)
        local routeParts={}
        for _,point in ipairs(p.route or {}) do
            routeParts[#routeParts+1]=exportZoneCFrame(point)
        end
        if wp~="" then mapped+=1 end
        if dig~="" and water~="" then complete+=1 end
        lines[#lines+1]=table.concat({name,wp,dig,water,table.concat(routeParts," ; ")},"\t")
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

bind(ringButton.MouseButton1Click,function()
    S.dredgePurifying=not S.dredgePurifying
    ringButton.Text="PURIFYING RING: "..(S.dredgePurifying and "YES" or "NO")
    S.dredgeGroup=nil
    dredgeText(S.dredgePurifying and "Ring confirmation ON (must be equipped)" or "Fungal Marsh excluded")
end)
bind(riskButton.MouseButton1Click,function()
    S.dredgeRisk=not S.dredgeRisk
    riskButton.Text="RISKY ZONES: "..(S.dredgeRisk and "ON" or "OFF")
    S.dredgeGroup=nil
    dredgeText(S.dredgeRisk and "Rotwood allowed with HP retreat; risk remains" or "Rotwood and Abyssal excluded")
end)
bind(sellB.MouseButton1Click,function()
    if not S.sell and not getSell() then show("SellAll unavailable");return end
    S.sell=not S.sell
    sellB.Text="AUTO SELL: "..(S.sell and "ON" or "OFF")
end)
-- ON is a persistent user request. A transient farm failure does not turn
-- the toggle off: we re-resolve the equipped pan and retry quickly.
local function startWorker(asDredge)
    if S.running then return end
    if not asDredge and (not S.dig or not S.water) then show("Save both positions");return end
    if asDredge then
        if type(getsenv)~="function" then dredgeText("Executor requires getsenv");return end
        S.dredgeRestore={dig=S.dig,water=S.water,zone=S.activeZone}
        S.dredge=true;S.dredgeCurrent=nil;S.dredgeGroup=nil
        S.dredgeAt=nil;S.dredgeAppliedCap="UNSET"
        S.dredgeCapLockedZone=nil;S.dredgeCapLockedKey=nil
        S.dredgeTurnAttempts=0;S.dredgeTurnRetryAt=nil
        S.dredgeCapLastAt=-math.huge
        S.dredgeLastStepQuery=-math.huge
        S.dredgeUncappedLuck=nil
        S.dredgeWarped={};S.dredgeTravelFailed={};S.dredgeTravelRetryAt=nil
        S.dredgeReadyAt=0;S.dredgeZoneCycle=S.cycles
        S.dredgeFailureCount=0;S.dredgeFailureZone=nil
        S.dredgePlanLuck=nil;S.dredgePlanCapacity=nil
        S.dredgePlannedRemaining=nil
        S.dredgeTalkAt=nil;S.dredgeNextAt=nil;S.dredgeStartAt=nil
        S.dredgeServerStatus=nil;S.dredgeServerProgress=nil
        S.dredgeCurrentWork="Reading quest"
        S.dredgeNextWork="Choose a zone and Luck Cap"
        S.dredgeNextStop=nil
        S.dredgeNextServerPoll=0;S.dredgeQuestPollError=nil
        S.dredgePollBusy=false;S.dredgeTransitionMode=nil
        S.dredgeTransitionAttempts=0;S.dredgeTransitionAt=0
        -- Remove preexisting Luck Caps before the first planning snapshot.
        local rem=RS:FindFirstChild("Remotes")
        local setting=rem and rem:FindFirstChild("Settings")
        local change=setting and setting:FindFirstChild("ChangeSetting")
        if not change or not change:IsA("RemoteEvent") then
            S.dredge=false;dredgeText("Luck Cap remote missing");return
        end
        if not pcall(function() change:FireServer("MaximumLuck","None") end) then
            S.dredge=false;dredgeText("Failed to clear previous cap");return
        end
        S.dredgeAppliedCap="NONE"
        S.dredgeLuckReadyAt=os.clock()+2.0
        dredgeButton.Text="AUTO DREDGE: ON"
        dredgeText("Starting / reading Dredge quest")
    else
        S.dredge=false
    end
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
                if S.dredge and S.dredgeAt then
                    local zoneName=S.dredgeAt
                    if S.dredgeFailureZone~=zoneName then
                        S.dredgeFailureZone=zoneName
                        S.dredgeFailureCount=0
                    end
                    S.dredgeFailureCount=(S.dredgeFailureCount or 0)+1
                    local attempts=S.dredgeFailureCount
                    warn("[GALAXIS DREDGE] Zone recovery",zoneName,
                        attempts,tostring(reason))
                    if attempts>=5 then
                        stop()
                        dredgeText("Stopped after 5 failed cycles at "..zoneName..
                            ": "..tostring(reason))
                        break
                    end
                    -- Reposition locally, without another FastTravel request.
                    -- Pan/shake failures return to water; Collect failures to dig.
                    local info=tostring(reason):lower()
                    local toWater=info:find("pan",1,true) or
                        info:find("shake",1,true) or
                        info:find("completion",1,true)
                    local targetCF=toWater and S.water or S.dig
                    if targetCF then
                        local r=root()
                        if r and (r.Position-targetCF.Position).Magnitude>8 then
                            if not farmMove(targetCF,id) then
                                stop()
                                dredgeText("Stopped: recovery walking route blocked at "..zoneName)
                                break
                            end
                        end
                    end
                    S.dredgeReadyAt=os.clock()+math.min(2.5,.65*attempts)
                    show(string.format("Zone recovery %d/4: %s",
                        attempts,zoneName))
                    if not pause(math.min(2.5,.65*attempts),id) then break end
                else
                    show("Recovering in 0.25s: "..tostring(reason):sub(1,58))
                    warn("[GALAXIS HUB] Auto recovery:",reason)
                    if not pause(CFG.recoveryDelay,id) then break end
                end
            end
        end
    end)
end
bind(farmB.MouseButton1Click,function()
    if S.running then stop() else startWorker(false) end
end)
bind(dredgeButton.MouseButton1Click,function()
    if S.running then stop();dredgeText("Dredge stopped")
    else startWorker(true) end
end)
task.spawn(function()
    while S.alive do
        if S.dredge and S.dredgeRiskZone then dredgeHealthWatch() end
        task.wait(.15)
    end
end)
bind(X.MouseButton1Click,close)
local minimized=false
bind(Min.MouseButton1Click,function()
    minimized=not minimized
    Body.Visible=not minimized
    W.Size=minimized and UDim2.fromOffset(340,43) or UDim2.fromOffset(340,463)
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
