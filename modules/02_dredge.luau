-- Galaxis module: 02_dredge.luau
-- Loaded by beta.luau into the shared Galaxis environment.
-- ===== DREDGE AUTO: INLINED TOOLKIT OPTIMIZER =====
-- Uses the same FITTED (not server-confirmed) luck model as your site.
-- Embedded mineral odds, no requests to the toolkit or separate Lua files.
      CAPS={1,5,10,25,50,100,250,500,1000,2500,5000,10000,25000,50000,100000}
      DREDGE_ODDS=[==[{"Azuralite Oasis":[["Copper",0.369786],["Gold",0.369786],["Amethyst",0.046223],["Azuralite",0.004622],["Inferlume",7.396e-8],["Ashvein",0.00009245],["Emerald",0.000027729999999999997],["Borealite",0.00004622],["Aetherite",0.000001156],["Silver",0.184893],["Neodymium",0.013867],["Smoky Quartz",0.009245],["Malachite",0.0009245000000000001],["Onyx",0.00046219999999999996],["Prismara",2.773e-8],["Osmium",0.00001387],["Palladium",9.245e-7],["Luminum",0.0000055469999999999996],["Vortessence",7.396e-8],["Uranium",0.000002311],["Starshine",9.245e-7]],"Crystal Cavern River":[["Copper",0.338491],["Gold",0.423114],["Amethyst",0.042310999999999994],["Azuralite",0.0042309999999999995],["Inferlume",6.77e-8],["Ashvein",0.00008462000000000001],["Emerald",0.00002539],["Borealite",0.000042310000000000007],["Aetherite",0.000001269],["Silver",0.169246],["Neodymium",0.012693000000000001],["Smoky Quartz",0.008461999999999999],["Malachite",0.0008462],["Onyx",0.0004231],["Osmium",0.000012689999999999999],["Palladium",8.462e-7],["Luminum",0.000012689999999999999],["Vortessence",6.77e-8],["Starshine",8.462e-7]],"Abyssal Depth":[["Copper",0.242347],["Gold",0.484694],["Azuralite",0.004847000000000001],["Emerald",0.00002908],["Aurorite",0.00001454],["Cobalt",0.00001939],["Aetherite",0.000002423],["Amber",0.0004847],["Gloomberry",0.000004847],["Silver",0.242347],["Neodymium",0.014541],["Smoky Quartz",0.009694000000000001],["Malachite",0.0009694],["Painite",2.908e-8],["Lightshard",0.000004847],["Specterite",0.0000014540000000000002],["Radiant Gold",1.454e-8],["Starshine",4.847e-7],["Umbrite",1.454e-9]],"Deeproot Spring":[["Copper",0.22591999999999998],["Gold",0.45183999999999996],["Azuralite",0.0045179999999999994],["Emerald",0.00002711],["Aurorite",0.00001356],["Cobalt",0.00001807],["Aetherite",0.000002259],["Glowberry",0.067776],["Amber",0.0004518],["Glowmoss",0.000004518],["Chrysoberyl",1.807e-8],["Silver",0.22591999999999998],["Neodymium",0.013555],["Smoky Quartz",0.009037],["Malachite",0.0009037],["Luminum",0.000005422],["Lightshard",0.000004518],["Specterite",0.0000013559999999999998],["Radiant Gold",9.037e-9],["Starshine",4.5179999999999996e-7],["Vineheart",1.807e-9]],"Fungal Marsh":[["Copper",0.271237],["Gold",0.542473],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Bone",0.00010850000000000001],["Electrum",0.027124000000000002],["Diopside",0.0005425],["Bismuth",0.000001627],["Astral Spore",6.509999999999999e-10],["Gloomcap",0.0000027119999999999996],["Smoky Quartz",0.043398000000000006],["Malachite",0.005425],["Onyx",0.001085],["Mythril",3.7969999999999995e-8],["Osmium",0.00002712],["Mercury",0.00001085],["Star Garnet",1.356e-8],["Red Beryl",8.137e-9],["Titanium",0.10849500000000001]],"Overgrown Grotto":[["Copper",0.233408],["Gold",0.466816],["Azuralite",0.004668],["Emerald",0.00002801],["Aurorite",0.000014],["Cobalt",0.00001867],["Aetherite",0.000002334],["Glowberry",0.037345],["Glowmoss",0.000004668],["Chrysoberyl",1.4e-8],["Silver",0.233408],["Neodymium",0.014004],["Smoky Quartz",0.009336],["Malachite",0.0009336],["Prismara",2.801e-8],["Luminum",0.000005602],["Lightshard",0.000004668],["Specterite",0.0000014],["Starshine",4.668e-7]],"Rotwood Swamp":[["Copper",0.271237],["Gold",0.542473],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Chrysoberyl",2.17e-8],["Bone",0.00010850000000000001],["Bloodstone",8.68e-10],["Electrum",0.027124000000000002],["Diopside",0.0005425],["Bismuth",0.000001627],["Smoky Quartz",0.043398000000000006],["Malachite",0.005425],["Onyx",0.001085],["Mythril",3.7969999999999995e-8],["Osmium",0.00002712],["Specterite",0.0000027119999999999996],["Mercury",0.00001085],["Star Garnet",1.085e-8],["Titanium",0.10849500000000001]],"Haunted Creek":[["Copper",0.21613],["Gold",0.432261],["Emerald",0.000034580000000000004],["Aurorite",0.00002161],["Cobalt",0.000017290000000000002],["Diamond",0.000004323],["Aetherite",0.000001297],["Bone",0.00008645],["Silver",0.21613],["Smoky Quartz",0.034581],["Malachite",0.0008645],["Lapis Lazuli",0.0004323],["Painite",3.458e-8],["Lightshard",0.000008645000000000001],["Specterite",0.000002161],["Radiant Gold",1.297e-8],["Rock Candy",0.012968],["Lost Soul",0.000004323],["Pumpkin Soul",4.323e-9],["Moonspire",2.161e-10],["Titanium",0.08645200000000001],["Vortessence",2.1610000000000003e-8]],"Infernal Heart":[["Copper",0.22104700000000002],["Dinosaur Skull",1.842e-8],["Inferlume",1.1049999999999999e-7],["Flarebloom",1.1049999999999999e-7],["Cinnabar",0.00000221],["Fire Opal",0.000002947],["Dragon Bone",0.000014740000000000001],["Obsidian",0.736822],["Peridot",0.0007367999999999999],["Onyx",0.001474],["Pyrelith",0.002947],["Painite",2.2099999999999998e-7],["Pyronium",0.00004421],["Osmium",0.000022100000000000002],["Opal",0.000022100000000000002],["Rose Gold",0.0000044210000000000005],["Topaz",0.022105],["Zircon",0.014736],["Volcanic Core",7.368e-8],["Uranium",0.0000044210000000000005],["Volcanic Key",0.000014740000000000001]],"Volcanic Springs":[["Copper",0.19197399999999998],["Gold",0.383949],["Inferlume",7.679e-8],["Flarebloom",2.7420000000000003e-8],["Cinnabar",0.000001097],["Fire Opal",0.000004388],["Catseye",0.000002742],["Obsidian",0.383949],["Peridot",0.0005485],["Onyx",0.001371],["Meteoric Iron",0.0024679999999999997],["Painite",1.645e-7],["Pyronium",0.00003839],["Osmium",0.00001645],["Opal",0.00001645],["Rose Gold",0.000005485000000000001],["Radium",0.000002194],["Topaz",0.02194],["Zircon",0.013712]],"Magma Furnace":[["Copper",0.17072900000000002],["Gold",0.34145899999999996],["Flarebloom",8.535999999999999e-8],["Cinnabar",0.000001138],["Fire Opal",0.000002845],["Dragon Bone",0.000008536000000000001],["Catseye",0.000002845],["Obsidian",0.455278],["Peridot",0.0005691],["Onyx",0.001138],["Pyrelith",0.002276],["Pyronium",0.00003415],["Osmium",0.00001707],["Opal",0.00001707],["Rose Gold",0.000005691],["Topaz",0.017073],["Zircon",0.011382000000000001],["Volcanic Core",4.5530000000000005e-8],["Volcanic Key",0.000005691]],"Volcanic Sands":[["Copper",0.170732],["Gold",0.34146299999999996],["Inferlume",7.967e-8],["Flarebloom",2.8459999999999998e-8],["Cinnabar",0.000001138],["Fire Opal",0.000002846],["Catseye",0.000002846],["Obsidian",0.455285],["Peridot",0.0005691],["Onyx",0.001138],["Meteoric Iron",0.002276],["Pink Diamond",2.276e-7],["Pyronium",0.00003415],["Osmium",0.00001707],["Opal",0.00001707],["Rose Gold",0.000005691],["Topaz",0.017073],["Zircon",0.011382000000000001]],"Tomb Vein I":[["Copper",0.101946],["Gold",0.34824800000000006],["Amethyst",0.035681],["Azuralite",0.002549],["Inferlume",1.631e-8],["Emerald",0.00003058],["Cinnabar",0.00001784],["Fire Opal",0.00002039],["Catseye",5.097e-7],["Bone",0.00005097],["Electrum",0.025487000000000003],["Aetherium",5.607e-9],["Agate",4.588e-9],["Eye of the Sands",5.097e-11],["Silver",0.07646],["Platinum",0.101946],["Obsidian",0.193698],["Smoky Quartz",0.020389],["Malachite",0.007645999999999999],["Ruby",0.010195000000000001],["Lapis Lazuli",0.003058],["Peridot",0.005097000000000001],["Onyx",0.001019],["Osmium",0.00025489999999999996],["Rose Gold",0.00002549],["Mercury",0.00003568],["Meteoric Gold",0.000010189999999999999],["Sandsteel",0.001529],["Selenite",0.0006117000000000001],["Jasper",0.000005097],["Key of Life",2.549e-11],["Solarium",1.529e-10],["Topaz",0.050973],["Starshine",0.000002549],["Natron Salt",0.010195000000000001],["Blue Faience",0.002039],["Scarab Amber",0.0007646],["Canopic Gold",0.00001529],["Ushabti",2.5490000000000002e-8]],"Tomb Vein II":[["Copper",0.093862],["Gold",0.266829],["Amethyst",0.031286999999999995],["Azuralite",0.004172],["Inferlume",2.607e-8],["Emerald",0.00005215],["Cinnabar",0.0000365],["Fire Opal",0.00004172],["Catseye",7.822000000000001e-7],["Bone",0.00007822],["Electrum",0.041717000000000004],["Aetherium",9.386e-9],["Agate",7.3e-9],["Eye of the Sands",8.343e-11],["Silver",0.073004],["Platinum",0.12515],["Obsidian",0.198154],["Smoky Quartz",0.026073],["Malachite",0.010428999999999999],["Ruby",0.018251],["Lapis Lazuli",0.004693],["Peridot",0.009386],["Onyx",0.001825],["Osmium",0.0004172],["Rose Gold",0.00004693],["Mercury",0.00005215],["Meteoric Gold",0.00001564],["Sandsteel",0.002607],["Selenite",0.001043],["Jasper",0.000007822],["Key of Life",4.172e-11],["Solarium",2.607e-10],["Topaz",0.078219],["Starshine",0.000004172],["Natron Salt",0.007822],["Blue Faience",0.0031290000000000003],["Scarab Amber",0.001564],["Canopic Gold",0.00003129],["Ushabti",1.043e-7]],"Tomb Vein III":[["Copper",0.085018],["Gold",0.20421199999999998],["Amethyst",0.028339],["Azuralite",0.005101],["Inferlume",4.534e-8],["Emerald",0.00011339999999999999],["Cinnabar",0.00007368],["Fire Opal",0.00007934999999999999],["Catseye",0.000001417],["Bone",0.0001417],["Electrum",0.056678],["Aetherium",1.7e-8],["Agate",1.247e-8],["Eye of the Sands",1.474e-10],["Silver",0.068014],["Platinum",0.147364],["Obsidian",0.19270700000000002],["Smoky Quartz",0.028339],["Malachite",0.011335999999999999],["Ruby",0.028339],["Lapis Lazuli",0.005101],["Peridot",0.01417],["Onyx",0.0028339999999999997],["Osmium",0.00045339999999999996],["Rose Gold",0.00009069],["Mercury",0.00008502],["Meteoric Gold",0.000028340000000000003],["Sandsteel",0.004534],["Selenite",0.0017000000000000001],["Jasper",0.000014170000000000002],["Key of Life",7.368e-11],["Solarium",4.534e-10],["Topaz",0.102021],["Starshine",0.000006801],["Natron Salt",0.005667999999999999],["Blue Faience",0.004534],["Scarab Amber",0.0028339999999999997],["Canopic Gold",0.00006801],["Ushabti",2.834e-7],["Sky Iron",1.7e-7],["Eternal Lotus",1.134e-9]],"The Void (when in the loot pool)":[["Copper",0.181132],["Gold",0.181132],["Amethyst",0.181132],["Blue Ice",0.181132],["Coral",0.018113],["Jade",0.0009057],["Azuralite",0.0009057],["Glacial Quartz",0.0009057],["Inferlume",2.536e-8],["Flarebloom",2.536e-8],["Frostshard",2.536e-8],["Iridium",0.00003623],["Ammonite Fossil",0.00003623],["Ashvein",0.00003623],["Emerald",0.00003623],["Golden Pearl",0.00003623],["Borealite",0.00003623],["Aurorite",0.00003623],["Cobalt",0.00003623],["Cinnabar",0.0000018110000000000001],["Diamond",0.0000018110000000000001],["Fire Opal",0.0000018110000000000001],["Dragon Bone",0.0000018110000000000001],["Catseye",0.0000018110000000000001],["Aetherite",0.0000018110000000000001],["Aquamarine",0.0000018110000000000001],["Glowberry",0.018113],["Amber",0.0009057],["Glowmoss",0.00003623],["Chrysoberyl",2.536e-8],["Firefly Stone",0.0000018110000000000001],["Gloomberry",0.0009057],["Bone",0.00003623],["Electrum",0.018113],["Diopside",0.0009057],["Bismuth",0.0000018110000000000001],["Gloomcap",0.0000018110000000000001],["Candy Cane",0.0009057],["Depleted Shard",0.0000018110000000000001],["Aetherium",2.536e-8],["Agate",2.536e-8],["Pyrite",0.181132],["Silver",0.181132],["Platinum",0.181132],["Seashell",0.181132],["Obsidian",0.181132],["Pearl",0.181132],["Neodymium",0.018113],["Smoky Quartz",0.018113],["Malachite",0.018113],["Sapphire",0.018113],["Ruby",0.0009057],["Lapis Lazuli",0.0009057],["Silver Clamshell",0.0009057],["Peridot",0.0009057],["Onyx",0.0009057],["Meteoric Iron",0.0009057],["Pyrelith",0.0009057],["Pink Diamond",2.536e-8],["Painite",2.536e-8],["Prismara",2.536e-8],["Mythril",2.536e-8],["Moonstone",0.00003623],["Pyronium",0.00003623],["Osmium",0.00003623],["Opal",0.00003623],["Rose Gold",0.0000018110000000000001],["Palladium",0.0000018110000000000001],["Luminum",0.0000018110000000000001],["Lightshard",0.00003623],["Specterite",0.0000018110000000000001],["Radiant Gold",2.536e-8],["Rock Candy",0.018113],["Lost Soul",0.0000018110000000000001],["Mercury",0.00003623],["Star Garnet",2.536e-8],["Red Beryl",2.536e-8],["Peppermint Prism",0.0000018110000000000001],["Radium",0.0000018110000000000001],["Nickel",0.018113],["Meteoric Gold",0.00003623],["Nautilus Shell",0.0000018110000000000001],["Sandsteel",0.0009057],["Selenite",0.00003623],["Jasper",0.0000018110000000000001],["Titanium",0.018113],["Topaz",0.018113],["Zircon",0.018113],["Vortessence",2.536e-8],["Volcanic Core",2.536e-8],["Uranium",0.0000018110000000000001],["Volcanic Key",0.0000018110000000000001],["Starshine",0.0000018110000000000001],["Tourmaline",0.0000018110000000000001],["Sunstone",2.536e-8]],"Rubble Creek Sands":[["Gold",0.703167],["Amethyst",0.070317],["Iridium",0.0001406],["Emerald",0.000023440000000000003],["Aurorite",0.00005625],["Diamond",0.000001406],["Aetherite",9.375999999999999e-7],["Platinum",0.187511],["Ruby",0.002344],["Lapis Lazuli",0.0009375999999999999],["Meteoric Iron",0.0003281],["Pink Diamond",1.8749999999999998e-7],["Opal",0.000009376],["Rose Gold",0.000004688],["Titanium",0.023439],["Topaz",0.011719]],"Enchanted Ruins":[["Gold",0.583704],["Azuralite",0.005837],["Emerald",0.00003502],["Aurorite",0.00001751],["Cobalt",0.00002335],["Aetherite",0.000002919],["Glowberry",0.087556],["Amber",0.0005836999999999999],["Glowmoss",0.000005837],["Adamantine",1.167e-9],["Silver",0.291852],["Neodymium",0.017511000000000002],["Smoky Quartz",0.011674],["Malachite",0.001167],["Prismara",7.296e-9],["Mythril",2.919e-8],["Rose Gold",0.000014590000000000001],["Luminum",0.000007004],["Lightshard",0.000005837],["Specterite",0.000001751],["Radiant Gold",1.167e-8],["Starshine",5.837e-7]],"Fortune River":[["Gold",0.572323],["Jade",0.002862],["Iridium",0.00008585],["Emerald",0.00004579],["Aurorite",0.00008585],["Diamond",0.000002289],["Catseye",0.000001145],["Aetherite",5.723e-7],["Platinum",0.286161],["Sapphire",0.005723000000000001],["Ruby",0.002289],["Lapis Lazuli",0.0010299999999999999],["Meteoric Iron",0.0005723],["Pink Diamond",2.862e-7],["Painite",1.717e-7],["Osmium",0.00001431],["Opal",0.00002289],["Rose Gold",0.000005723],["Palladium",2.289e-7],["Titanium",0.114465],["Topaz",0.014308000000000001],["Uranium",0.000001717]],"Fortune River Delta":[["Gold",0.54716],["Coral",0.03283],["Jade",0.002189],["Iridium",0.000054720000000000005],["Golden Pearl",0.0001641],["Aurorite",0.000054720000000000005],["Diamond",0.0000054719999999999994],["Aetherite",0.0000013679999999999999],["Silver",0.27358],["Pearl",0.10943199999999999],["Neodymium",0.016415],["Smoky Quartz",0.010943000000000001],["Silver Clamshell",0.001094],["Onyx",0.0005472],["Pink Diamond",4.377e-7],["Painite",2.1889999999999998e-7],["Moonstone",0.000054720000000000005],["Palladium",8.207e-7],["Topaz",0.005472],["Vortessence",8.206999999999999e-8],["Uranium",0.0000027359999999999997]],"Meteor Falls":[["Gold",0.542536],["Jade",0.001085],["Iridium",0.0000434],["Cobalt",0.0000217],["Diamond",0.0000027129999999999997],["Electrum",0.027127],["Depleted Shard",5.425e-8],["Aetherium",5.425e-9],["Pyrite",0.271268],["Sapphire",0.043403],["Lapis Lazuli",0.005425],["Moonstone",0.000027130000000000003],["Opal",0.0005425],["Mercury",0.00001085],["Star Garnet",1.085e-8],["Radium",5.425e-7],["Nickel",0.10850699999999999],["Vortessence",1.6279999999999998e-8],["Sunstone",5.425e-9],["Starpiercer",2.17e-10]],"Starfall River":[["Gold",0.542536],["Jade",0.001085],["Iridium",0.0000434],["Aurorite",0.0000217],["Aquamarine",0.0000027129999999999997],["Electrum",0.027127],["Depleted Shard",5.425e-8],["Aetherium",5.425e-9],["Pyrite",0.271268],["Sapphire",0.043403],["Lapis Lazuli",0.005425],["Moonstone",0.000027130000000000003],["Opal",0.0005425],["Palladium",5.425e-7],["Star Garnet",1.085e-8],["Singularium",1.085e-10],["Nickel",0.10850699999999999],["Meteoric Gold",0.00001085],["Vortessence",1.6279999999999998e-8],["Sunstone",5.425e-9]],"Timelocked Sanctuary":[["Gold",0.5425260000000001],["Emerald",0.0000434],["Cobalt",0.0000217],["Diamond",0.000005425],["Aetherite",0.0000027129999999999997],["Glowmoss",0.000005425],["Firefly Stone",5.425e-8],["Bloodstone",5.425e-10],["Electrum",0.027126],["Diopside",0.0005425],["Bismuth",0.000001628],["Astral Spore",4.34e-10],["Eternium",2.713e-10],["Silver",0.27126300000000003],["Smoky Quartz",0.043402],["Malachite",0.005425],["Onyx",0.001085],["Osmium",0.000027130000000000003],["Lightshard",0.000005425],["Radiant Gold",1.085e-8],["Mercury",0.00001085],["Star Garnet",1.356e-8],["Red Beryl",8.138e-9],["Topaz",0.108505],["Starshine",5.425e-7]],"Astral Caverns":[["Gold",0.519968],["Jade",0.00104],["Iridium",0.000041599999999999995],["Aurorite",0.000020799999999999997],["Aquamarine",0.0000025999999999999997],["Electrum",0.025998],["Depleted Shard",1.04e-7],["Celestium",5.2e-11],["Aetherium",5.2e-9],["Silver",0.259984],["Sapphire",0.041597],["Lapis Lazuli",0.0052],["Meteoric Iron",0.041597],["Moonstone",0.000026],["Opal",0.00052],["Palladium",5.2e-7],["Red Beryl",9.359e-9],["Nickel",0.103994],["Meteoric Gold",0.000010399999999999999],["Vortessence",1.56e-8],["Sunstone",5.2e-9]],"Rubble Creek Deposits":[["Gold",0.521295],["Iridium",0.0001564],["Emerald",0.000041700000000000004],["Aurorite",0.00007819],["Diamond",0.000002085],["Catseye",0.000001043],["Aetherite",7.819e-7],["Pyrite",0.156389],["Platinum",0.260648],["Sapphire",0.005213],["Ruby",0.002085],["Lapis Lazuli",0.001303],["Meteoric Iron",0.0006256],["Pink Diamond",2.085e-7],["Osmium",0.00001043],["Opal",0.00001564],["Rose Gold",0.000005213000000000001],["Titanium",0.041704],["Topaz",0.010426]],"Lifespring Oasis":[["Gold",0.516447],["Inferlume",1.653e-8],["Catseye",5.164e-7],["Electrum",0.025821999999999998],["Depleted Shard",1.0329999999999999e-7],["Aetherium",5.681e-9],["Agate",4.648e-9],["Platinum",0.129112],["Obsidian",0.258224],["Ruby",0.010329],["Peridot",0.005163999999999999],["Onyx",0.001033],["Mercury",0.000036150000000000005],["Meteoric Gold",0.000010330000000000001],["Sandsteel",0.001549],["Selenite",0.0006196999999999999],["Jasper",0.000005164],["Key of Life",1.549e-11],["Topaz",0.051645],["Starshine",0.000002582]],"Mystic Floodplains":[["Gold",0.516446],["Inferlume",1.653e-8],["Catseye",5.164e-7],["Electrum",0.025821999999999998],["Aetherium",5.681e-9],["Agate",4.648e-9],["Eye of the Sands",3.615e-11],["Platinum",0.129112],["Obsidian",0.258223],["Ruby",0.010329],["Peridot",0.005163999999999999],["Onyx",0.001033],["Mercury",0.000036150000000000005],["Radium",0.000002066],["Meteoric Gold",0.000010330000000000001],["Sandsteel",0.001549],["Selenite",0.0006196999999999999],["Jasper",0.000005164],["Topaz",0.051645],["Starshine",0.000002582]],"Sandstone Stream":[["Gold",0.517301],["Inferlume",1.655e-8],["Fire Opal",5.173e-7],["Electrum",0.025865],["Aetherium",5.69e-9],["Agate",4.656e-9],["Platinum",0.129325],["Obsidian",0.258651],["Ruby",0.010346],["Peridot",0.005173],["Osmium",0.0005172999999999999],["Mercury",0.00003621],["Radium",0.000002069],["Meteoric Gold",0.00001035],["Sandsteel",0.001035],["Jasper",0.000005173],["Solarium",8.277e-11],["Topaz",0.05173],["Starshine",0.000002587]],"North Pole":[["Gold",0.279264],["Blue Ice",0.279264],["Jade",0.013963000000000001],["Glacial Quartz",0.002234],["Frostshard",2.234e-8],["Iridium",0.0001396],["Borealite",0.00004468],["Aurorite",0.00001676],["Cobalt",0.00002234],["Diamond",0.000004468],["Aetherite",0.000002234],["Aquamarine",0.000002234],["Candy Cane",0.0005585],["Silver",0.279264],["Sapphire",0.033512],["Pink Diamond",1.117e-7],["Peppermint Prism",0.000001117],["North Star",2.793e-9],["Titanium",0.111706]],"Frozen Peak":[["Blue Ice",0.51501],["Cryonic Artifact",6.4379999999999995e-9],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Frostshard",1.609e-8],["Iridium",0.00012880000000000001],["Borealite",0.0000515],["Aurorite",0.00001931],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aetherite",0.0000025750000000000003],["Aquamarine",0.0000012879999999999998],["Silver",0.321882],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",3.219e-8],["Titanium",0.128753],["Tourmaline",0.0000016090000000000002]],"Frostbite River":[["Blue Ice",0.51501],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Iridium",0.00012880000000000001],["Emerald",0.00001931],["Borealite",0.0000515],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aquamarine",0.0000012879999999999998],["Silver",0.321882],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",2.575e-8],["Palladium",0.0000025750000000000003],["Titanium",0.128753],["Vortessence",8.369e-8],["Tourmaline",0.0000016090000000000002]],"Frostbite Waterfall":[["Blue Ice",0.51501],["Jade",0.012875000000000001],["Glacial Quartz",0.001288],["Frostshard",1.609e-8],["Iridium",0.00012880000000000001],["Borealite",0.0000515],["Aurorite",0.00001931],["Cobalt",0.00002575],["Diamond",0.000005150000000000001],["Aetherite",0.0000025750000000000003],["Aquamarine",0.0000012879999999999998],["Silver",0.321881],["Sapphire",0.019313],["Lapis Lazuli",0.0006438],["Mythril",2.575e-8],["Titanium",0.128753],["Vortessence",8.369e-8],["Tourmaline",0.0000016090000000000002]],"Windswept Beach":[["Coral",0.060233999999999996],["Inferlume",9.035000000000001e-8],["Ammonite Fossil",0.00006023],["Fire Opal",0.000003012],["Dragon Bone",0.000004819],["Catseye",0.000003012],["Seashell",0.48187199999999997],["Obsidian",0.24093599999999998],["Pearl",0.180702],["Malachite",0.012047],["Silver Clamshell",0.001807],["Peridot",0.0006023],["Onyx",0.001205],["Meteoric Iron",0.002409],["Osmium",0.00001807],["Opal",0.00001807],["Rose Gold",0.000009035],["Topaz",0.01807],["Vortessence",9.035000000000001e-8]],"Sunset Beach":[["Coral",0.056664000000000006],["Inferlume",8.5e-8],["Ashvein",0.0001133],["Golden Pearl",0.00022669999999999998],["Diamond",0.000005666],["Aetherite",0.000001133],["Silver",0.283321],["Seashell",0.453314],["Pearl",0.169993],["Neodymium",0.022666],["Smoky Quartz",0.011333],["Silver Clamshell",0.0017000000000000001],["Onyx",0.0005666],["Painite",2.267e-7],["Moonstone",0.00005666],["Opal",0.000022669999999999998],["Luminum",0.000017]],"Seashell Beach":[["Coral",0.056661],["Inferlume",8.499e-8],["Ammonite Fossil",0.00005666],["Ashvein",0.0001133],["Golden Pearl",0.0002266],["Aetherite",0.000001133],["Forgotten Totem",2.833e-9],["Silver",0.28330500000000003],["Seashell",0.453288],["Pearl",0.169983],["Neodymium",0.022664],["Smoky Quartz",0.011332],["Silver Clamshell",0.0017000000000000001],["Onyx",0.0005666],["Painite",2.266e-7],["Moonstone",0.00005666],["Opal",0.000022659999999999996],["Luminum",0.000017],["Red Beryl",8.499e-9],["Nautilus Shell",0.000005666]],"Overgrown Grotto (inside Firefly Zones)":[["Firefly Stone",2.334e-7]],"Deeproot Spring (inside Firefly Zones)":[["Firefly Stone",2.2589999999999998e-7]],"Enchanted Ruins (outside Firefly Zones)":[["Firefly Stone",5.837e-8]],"Overgrown Grotto (outside Firefly Zones)":[["Firefly Stone",4.668e-8]],"Deeproot Spring (outside Firefly Zones)":[["Firefly Stone",4.518e-8]],"The Void":[["Voidstone",7.245e-9]]}]==]
      DROPS=HttpService:JSONDecode(DREDGE_ODDS)
      ALL_ZONES,POOL,SHARES={},{},{}
S.dredge=false;S.dredgePurifying=false;S.dredgeRisk=false
S.dredgeCurrent=nil;S.dredgeGroup=nil;S.dredgeAppliedCap="UNSET"
S.dredgeUncappedLuck=nil;S.dredgeLuckReadyAt=0
S.dredgeTravelFailed={};S.dredgeWarped={}
S.dredgeReadyAt=0;S.dredgeZoneCycle=0;S.dredgeZoneSince=0
S.dredgeFailureCount=0;S.dredgeFailureZone=nil
S.dredgeCurrentWork="Idle";S.dredgeNextWork="Awaiting plan"
S.dredgeCapLastAt=-math.huge;S.dredgeCapLockedZone=nil
S.dredgeCapLockedKey=nil;S.dredgeTurnAttempts=0
dredgeButton,dredgeStatus,show,stop=nil,nil,nil,nil
      function dredgeText(str)
    if dredgeStatus then dredgeStatus.Text=str end
    -- Update GUI on every change, but keep Output quiet.
    if S.dredgeLastText~=str then
        S.dredgeLastText=str
        S.diagEvent("DREDGE_STATUS",str)
        outputDebug("[GALAXIS DREDGE] "..str)
    end
end
      function baseDrop(s)
    return (s:gsub("%s*%(inside Firefly Zones%)","")
        :gsub("%s*%(outside Firefly Zones%)","")
        :gsub("%s*%(when in the loot pool%)",""))
end
      function poolFor(z)
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
      function rareBand(n)
    local l=math.log(math.max(n,1))/math.log(10)
    return 1+.858*math.min(math.clamp((l-7.26)/.5,0,1),math.clamp((9.67-l)/.5,0,1))
end
      function oddsFor(z,L)
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
      function openNow(z)
    -- Actual hourly schedule is :15 -> :45 for Infernal Heart,
    -- and :45 -> :15 for Timelocked Sanctuary. The previous :16/:44
    -- guard rejected an ACTUALLY OPEN Infernal Heart at minute :15,
    -- making Dinosaur Skull appear to have no eligible deposit.
    -- The client clock is only a schedule estimate, not proof of
    -- a server-side gate; movement/Collect still determine access.
    local minute=os.date("*t").min
    if z=="Timelocked Sanctuary" then return minute>=45 or minute<15 end
    if z=="Infernal Heart" then return minute>=15 and minute<45 end
    return true
end
      function totemNear(pos)
    local checked=0
    for _,obj in ipairs(workspace:GetDescendants()) do
        local n=obj.Name:lower()
        if n:find("totem",1,true)
            and (n:find("lumin",1,true) or n:find("light",1,true)) then
            checked+=1
            if checked>100 then break end
            local cf=S.getWaypointCF(obj)
            if cf and (cf.Position-pos).Magnitude<65
                and (obj:GetAttribute("Active")==true or obj:GetAttribute("Enabled")==true) then
                return true
            end
        end
    end
    return false
end
-- Restore the waypoint mapping omitted from the bundled 28-zone JSON.
-- The first inbound checkpoint was recorded at the departure stone; use
-- the physical stone nearest that point, never the current player position.
-- This does NOT alter any route, dig or water coordinate.
      function resolveDredgeWaypoint(zone)
    local preset=S.presets[zone]
    if not preset then return nil end
    if waypointIndex[preset.waypoint or ""] then return preset.waypoint end
    -- Verified by the 2026-11-20 route test: Windswept Beach
    -- successfully travelled inbound and outbound from Volcanic Sands.
    if zone=="Windswept Beach" and waypointIndex["Volcanic Sands"] then
        preset.waypoint="Volcanic Sands"
        return "Volcanic Sands"
    end
    -- Several zones share an identically named in-game fast-travel stone.
    -- Prefer that exact, verified name before attempting route-coordinate inference.
    if waypointIndex[zone] then
        preset.waypoint=zone
        S.diagEvent("DREDGE_WAYPOINT_RESOLVED",
            tostring(zone).." -> "..tostring(zone).." (exact waypoint name)")
        return zone
    end
    local folder=S.waypointFolder()
    if not folder then return nil end
    -- Route recordings do not always begin beside the warp stone. Compare
    -- every inbound/outbound checkpoint, plus dig/water, against each stone.
    local anchors={}
    for _,field in ipairs({"route","routeOut"}) do
        for _,packed in ipairs(preset[field] or {}) do
            local point=S.unpackCF(packed)
            if point then anchors[#anchors+1]=point.Position end
        end
    end
    for _,field in ipairs({"dig","water"}) do
        local point=S.unpackCF(preset[field])
        if point then anchors[#anchors+1]=point.Position end
    end
    if #anchors==0 then return nil end
    local best,bestDist=nil,math.huge
    for _,name in ipairs(WAYPOINT_NAMES) do
        local obj=folder:FindFirstChild(name)
        local stone=obj and S.getWaypointCF(obj)
        if stone then
            for _,position in ipairs(anchors) do
                local distance=(stone.Position-position).Magnitude
                if distance<bestDist then best,bestDist=name,distance end
            end
        end
    end
    -- Require a reasonably close match; never guess a distant warp stone.
    if best and bestDist<=250 then
        preset.waypoint=best
        S.diagEvent("DREDGE_WAYPOINT_RESOLVED",
            string.format("%s -> %s (nearest recorded point %.1f studs)",
                zone,best,bestDist))
        return best
    end
    S.diagEvent("DREDGE_WAYPOINT_UNRESOLVED",
        string.format("%s: nearest stone=%s distance=%.1f anchors=%d",
            zone,tostring(best),bestDist,#anchors))
    return nil
end
      function eligible(z,tier)
    if z:find("inside Firefly Zones",1,true) then return false end
    local base=baseDrop(z)
    local preset=S.presets[base]
    if not zoneIndex[base] or not preset or not S.unpackCF(preset.dig)
        or not S.unpackCF(preset.water) or not resolveDredgeWaypoint(base) then return false end
    if base=="The Void" or base=="Haunted Creek" or base=="North Pole"
        or base=="Seashell Beach" or base:find("Tomb Vein",1,true) then return false end
    -- Magma Furnace is a permanent deposit. It has its own saved route
    -- and must not inherit Infernal Heart's timed-zone eligibility.
    -- Its heat exposure is handled by the risky-zone health watcher.
    if base=="Magma Furnace" then return true end
    if base=="Fungal Marsh" then return tier>=2 and S.dredgePurifying end
    if base=="Rotwood Swamp" then return tier>=3 and S.dredgeRisk end
    if base=="Timelocked Sanctuary" or base=="Infernal Heart" then return tier>=4 and openNow(base) end
    if base=="Abyssal Depth" then
        -- Risky Zones explicitly opts into Abyssal farming. Do not require
        -- a nearby Luminite Totem just to consider the zone.
        return tier>=5 and S.dredgeRisk
    end
    return true
end
      function groupBest(group,places,L,per)
    local best
    for _,z in ipairs(places) do
        local has={}
        for _,row in ipairs(poolFor(z)) do has[row[1]]=true end
        local matches=true
        for _,q in ipairs(group) do if not has[q.m] then matches=false;break end end
        if matches then
            -- Timelocked Sanctuary is safer than Rotwood Swamp. When the
            -- Sanctuary is open and contains every mineral in this group,
            -- never choose Rotwood for that same group, regardless of the
            -- fitted rarity/pans estimate. Rotwood-only minerals remain
            -- available through Rotwood when risky zones are enabled.
            if baseDrop(z)=="Rotwood Swamp" and openNow("Timelocked Sanctuary")
                and eligible("Timelocked Sanctuary",5) then
                local safePool={}
                for _,entry in ipairs(poolFor("Timelocked Sanctuary")) do
                    safePool[entry[1]]=true
                end
                local covered=true
                for _,q in ipairs(group) do
                    if not safePool[q.m] then covered=false;break end
                end
                if covered then matches=false end
            end
        end
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
                        -- Keep every objective obtainable in this deposit,
                        -- but order the assigned targets by rarity (lowest
                        -- fitted drop probability first). This makes the
                        -- rarest shared-zone objective the first priority.
                        local priorityGroup={}
                        for _,q in ipairs(group) do
                            priorityGroup[#priorityGroup+1]=q
                        end
                        table.sort(priorityGroup,function(a,b)
                            local pa=shares[a.m] or 0
                            local pb=shares[b.m] or 0
                            if math.abs(pa-pb)>1e-15 then return pa<pb end
                            return a.m<b.m
                        end)
                        best={z=z,cap=cap,pans=worst,group=priorityGroup}
                    end
                end
            end
        end
    end
    return best
end
      function partitions(wants)
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
      function optimize(wants,places,L,cap)
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
      function bestRoute(wants,L,cap)
    -- Evaluate ALL currently allowed deposits together. The old tier loop
    -- returned as soon as a safe tier covered every mineral, preventing
    -- Abyssal (tier 5) from ever competing for a faster plan.
    local places,reachable={},{}
    for _,z in ipairs(ALL_ZONES) do
        if eligible(z,5) then
            places[#places+1]=z
            for _,x in ipairs(poolFor(z)) do reachable[x[1]]=true end
        end
    end
    local can={}
    for _,w in ipairs(wants) do
        if reachable[w.m] then can[#can+1]=w end
    end
    if #can==0 then return nil end
    local plan=optimize(can,places,L,cap)
    if plan then
        plan.covered=#can
        plan.needed=#wants
    end
    return plan
end

-- Overrides the normal pans/cost optimizer for time-limited, rare quest
-- objectives. This never overrides zone eligibility, permissions, the
-- actual hourly gate, or the remaining quest requirements.
-- Both can only be sourced from their respective timed deposits.
      function timedRareObjective(wants)
    local priority={
        {mineral="Eternium",zone="Timelocked Sanctuary"},
        {mineral="Dinosaur Skull",zone="Infernal Heart"}
    }
    for _,special in ipairs(priority) do
        if openNow(special.zone) and eligible(special.zone,5) then
            for _,objective in ipairs(wants) do
                if objective.m==special.mineral and objective.n>0 then
                    return objective,special.zone
                end
            end
        end
    end
    return nil,nil
end

      function getQuest()
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
      function remaining(state)
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
      function questsRemote()
    local f=RS:FindFirstChild("Remotes")
    return f and f:FindFirstChild("Quests")
end
-- Read a server step ONLY as a fallback, not once per pan or per mineral.
      function serverQuestStep(id)
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
      function startQuest(id)
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
      function questMode(snapshot)
    if not snapshot then return "unknown" end
    if snapshot.status=="Started" then
        if snapshot.step==2 then return "turnin" end
        return "active"
    end
    if snapshot.canStart==true then return "available" end
    return "unavailable"
end
      function queryQuestStatus(id)
    local rem=questsRemote()
    local questFolder=RS:FindFirstChild("Quests")
    local quest=questFolder and questFolder:FindFirstChild("DredgeMaster")
    local fn=rem and rem:FindFirstChild("CanStartQuest")
    if not quest or not fn or not fn:IsA("RemoteFunction") then
        return nil,"CanStartQuest remote or quest definition missing"
    end
    -- InvokeServer can yield indefinitely during lag, or when this
    -- particular server-side handler stops responding. Never hold the
    -- only Dredge polling worker hostage to one such request.
    local finished,ok,canStart,status,step=false,false,nil,nil,nil
    task.spawn(function()
        ok,canStart,status,step=pcall(function()
            return fn:InvokeServer(quest)
        end)
        finished=true
    end)
    local deadline=os.clock()+4
    while valid(id) and not finished and os.clock()<deadline do
        task.wait(.05)
    end
    if not valid(id) then return nil,"Dredge stopped" end
    if not finished then return nil,"CanStartQuest timed out after 4 seconds" end
    if not ok then return nil,"CanStartQuest: "..tostring(canStart) end
    if canStart==nil and status==nil and step==nil then
        return nil,"CanStartQuest returned no status"
    end
    local result={canStart=canStart,status=status,step=tonumber(step),time=os.clock()}
    return result
end
      function refreshDredgeServerQuest(id)
    local state,err=queryQuestStatus(id)
    if not valid(id) then return end
    if not state then
        S.dredgeQuestPollError=err
        S.diagEvent("QUEST_POLL_ERROR",tostring(err))
        return
    end
    S.dredgeQuestPollError=nil
    S.diagEvent("QUEST_STATUS","canStart="..tostring(state.canStart)..
        " status="..tostring(state.status).." step="..tostring(state.step))
    local old=S.dredgeServerStatus
    S.dredgeServerStatus=state
    if not old or old.status~=state.status or old.step~=state.step
      or old.canStart~=state.canStart then
        outputDebug("[GALAXIS DREDGE QUEST] CanStartQuest:",tostring(state.canStart),
            "status:",tostring(state.status),"step:",tostring(state.step))
    end
    -- Do not invoke GetCurrentQuestStep alongside active Collect/Pan RPCs
    -- when the client already has StepProgress. This extra server query
    -- repeatedly timed out in the same windows as Collect/Sell stalls.
    -- Fallback is still available when the local quest cache is missing.
    local localQuest=getQuest()
    local needsServerProgress=not localQuest
        or type(localQuest.StepProgress)~="table"
    local busyMining=S.traceCurrentAction=="COLLECT_TO_CAPACITY"
        or S.traceCurrentAction=="PAN_INVOKE"
        or S.traceCurrentAction=="SHAKE_LOOP"
    if questMode(state)=="active" and needsServerProgress and not busyMining then
        local qr=questsRemote()
        local fn=qr and qr:FindFirstChild("GetCurrentQuestStep")
        if fn and fn:IsA("RemoteFunction") then
            -- Use the existing bounded InvokeServer helper; a hung
            -- StepProgress query must not block future quest polls.
            local ok,result=invoke(fn,id,"DredgeMaster")
            if ok and type(result)=="table" and type(result.StepProgress)=="table"
              and valid(id) then S.dredgeServerProgress=result end
        end
    elseif questMode(state)~="active" then
        S.dredgeServerProgress=nil
    end
end
task.spawn(function()
    while S.alive do
        if S.dredge and S.running and
            os.clock()>=(S.dredgeNextServerPoll or 0) and
            not S.dredgePollBusy then
            S.dredgePollBusy=true
            S.dredgePollStartedAt=os.clock()
            S.dredgePollAttempts=(S.dredgePollAttempts or 0)+1
            -- While actively farming, keep the authoritative quest mode
            -- checked but avoid hammering the server every five seconds.
            S.dredgeNextServerPoll=os.clock()+
                ((S.traceCurrentAction=="COLLECT_TO_CAPACITY"
                    or S.traceCurrentAction=="PAN_INVOKE"
                    or S.traceCurrentAction=="SHAKE_LOOP") and 10 or 5)
            local current=S.token
            local ok,err=pcall(refreshDredgeServerQuest,current)
            if not ok then
                S.dredgeQuestPollError=tostring(err)
                S.diagEvent("QUEST_POLL_EXCEPTION",tostring(err))
                outputWarning("dredge-server-quest", "[GALAXIS DREDGE] Server quest poll:",err)
            end
            S.dredgePollCompletedAt=os.clock()
            S.dredgePollBusy=false
        end
        task.wait(.2)
    end
end)

-- Walking-first travel. Every segment uses Humanoid:MoveTo and a
-- computed path; this never moves the avatar by artificial flight or
-- stair-step CFrames. Failure is reported rather than looped indefinitely.
      function stableAt(cf,id,radius,hold,maxWait)
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
-- Record the actual walking path into Enchanted Ruins, not just the
-- coarse user-defined preset nodes. Only enabled during inbound travel.
function S.recordEnchantedStep()
    local path=S.enchantedRecording
    if not path then return end
    local r=root()
    if not r then return end
    local last=path[#path]
    if (not last or (r.Position-last).Magnitude>=4) and #path<500 then
        path[#path+1]=r.Position
    end
end
-- Dredge-only fallback flight; called by walkRoute, never concurrently
-- with its Humanoid pathfinding. Restore collisions and humanoid state even
-- after cancellation, timeout, or an unexpected error.
local function timedDredgeFlight(target,id)
    if typeof(target)~="CFrame" or not valid(id) then
        return false,"Invalid recovery target/session"
    end
    local character=P.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health<=0 or not root() then
        return false,"Character unavailable for recovery flight"
    end
    local oldAuto=humanoid.AutoRotate
    local oldPlatform=humanoid.PlatformStand
    local collisions={}
    local function disableCollision(obj)
        if not obj:IsA("BasePart") then return end
        if collisions[obj]==nil then collisions[obj]=obj.CanCollide end
        obj.CanCollide=false
    end
    local hook=nil
    local ok,err=pcall(function()
        for _,part in ipairs(character:GetDescendants()) do disableCollision(part) end
        hook=character.DescendantAdded:Connect(disableCollision)
        humanoid.AutoRotate=false
        humanoid.PlatformStand=true
        local speed=42
        local began=os.clock()
        local previous=os.clock()
        local startDistance=(root().Position-target.Position).Magnitude
        local limit=math.clamp(startDistance/speed*3+12,12,160)
        while valid(id) and S.dredge and S.dredgeWanted
            and not S.treasureBusy and humanoid.Health>0
            and os.clock()-began<limit do
            local avatar=root()
            if not avatar then break end
            local delta=target.Position-avatar.Position
            if delta.Magnitude<=7 then break end
            local now=os.clock()
            local dt=math.clamp(now-previous,1/120,.11)
            previous=now
            local step=math.min(delta.Magnitude,speed*dt)
            avatar.AssemblyLinearVelocity=Vector3.zero
            avatar.AssemblyAngularVelocity=Vector3.zero
            avatar.CFrame=CFrame.new(avatar.Position+delta.Unit*step)*target.Rotation
            task.wait()
        end
    end)
    if hook then hook:Disconnect() end
    for part,canCollide in pairs(collisions) do
        if part.Parent then pcall(function() part.CanCollide=canCollide end) end
    end
    if humanoid.Parent then
        humanoid.AutoRotate=oldAuto
        humanoid.PlatformStand=oldPlatform
    end
    local avatar=root()
    if avatar then
        avatar.AssemblyLinearVelocity=Vector3.zero
        avatar.AssemblyAngularVelocity=Vector3.zero
    end
    if not ok then return false,"Recovery flight exception: "..tostring(err) end
    if not valid(id) then return false,"Recovery flight cancelled" end
    if not avatar or (avatar.Position-target.Position).Magnitude>12 then
        return false,"Flight could not reach checkpoint (server movement correction)"
    end
    if not stableAt(target,id,15,.35,2.5) then
        return false,"Flight checkpoint did not remain stable"
    end
    return true
end

      function walkRoute(cf,id,maxDistance,checkpoint)
    local r=root()
    local character=P.Character
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    if not r or not hum or hum.Health<=0 then return false,"Character unavailable" end
    local distance=(r.Position-cf.Position).Magnitude
    if distance<7 then
        if checkpoint then return true end
        return stableAt(cf,id,9,.55,1.8)
    end
    local limit=maxDistance or 850
    if distance>limit then return false,"Beyond walking limit: "..math.floor(distance) end
    local deadline=os.clock()+math.clamp(distance/math.max(8,hum.WalkSpeed)*2.8+18,17,170)
    local segment=0
    local failures=0
    local recoveryJumps=0
    local lastJumpAt=-math.huge
    local function jumpRecovery(reason)
        local now=os.clock()
        if now-lastJumpAt<1.25 or recoveryJumps>=6 then return end
        if not valid(id) or hum.Health<=0 then return end
        local state=hum:GetState()
        if state==Enum.HumanoidStateType.Seated or
            state==Enum.HumanoidStateType.Dead then return end
        lastJumpAt=now
        recoveryJumps+=1
        hum.Jump=true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        S.diagEvent("WALK_JUMP_RECOVERY",
            string.format("attempt=%d reason=%s",recoveryJumps,tostring(reason)))
    end
    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances={character}
    local function recoverFlightIfRequested()
        if not S.timedZoneFlightRequested or not S.dredge then return nil end
        S.timedZoneFlightRequested=false
        S.timedZoneFlightActive=true
        S.diagEvent("TIMED_ZONE_NOCLIP_START",
            string.format("Target %.1f, %.1f, %.1f",
                cf.Position.X,cf.Position.Y,cf.Position.Z))
        local ok,why=timedDredgeFlight(cf,id)
        S.timedZoneFlightActive=false
        S.timedZoneFlightLastAt=os.clock()
        S.timedZoneFlightLastResult=ok and "Reached checkpoint" or tostring(why)
        S.diagEvent(ok and "TIMED_ZONE_NOCLIP_OK" or "TIMED_ZONE_NOCLIP_FAILED",
            S.timedZoneFlightLastResult)
        if ok then return true end
        -- On failure leave regular retry/replanning active.
        return false,why
    end
    while valid(id) and os.clock()<deadline do
        local flying,flightWhy=recoverFlightIfRequested()
        if flying~=nil then return flying,flightWhy end
        r=root()
        if not r or hum.Health<=0 then return false,"Character lost while walking" end
        distance=(r.Position-cf.Position).Magnitude
        if distance<9 then
            if checkpoint then return true end
            if stableAt(cf,id,11,1.2,2.7) then return true end
            return false,"Destination did not remain stable"
        end
        segment+=1
        if segment>math.ceil(limit/115)+15 then return false,"Walking segments exceeded" end
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
            jumpRecovery("path computation failed")
            S.diagEvent("WALK_REPATH",
                string.format("no path | failure=%d/6 distance=%.1f",
                    failures,distance))
            if failures>=6 then
                return false,"No walkable path after 6 attempts to "..math.floor(distance).." studs"
            end
            if not pause(.4+math.min(failures,4)*.2,id) then return false,"Stopped" end
        else
            local before=(r.Position-cf.Position).Magnitude
            local nodes=path:GetWaypoints()
            if #nodes==0 then
                failures+=1
                jumpRecovery("empty path")
                if failures>=6 then return false,"Path has no walking points after retries" end
                if not pause(.35,id) then return false,"Stopped" end
                continue
            end
            for _,node in ipairs(nodes) do
                if not valid(id) or os.clock()>deadline then return false,"Walk interrupted/timed out" end
                r=root()
                if not r or hum.Health<=0 then return false,"Character lost" end
                if (r.Position-node.Position).Magnitude>4.5 then
                    if node.Action==Enum.PathWaypointAction.Jump then
                        hum.Jump=true
                    end
                    hum:MoveTo(node.Position)
                    local walkingDist=(r.Position-node.Position).Magnitude
                    local perNode=math.clamp(walkingDist/math.max(8,hum.WalkSpeed)*2.5+1.3,2.3,10)
                    local nodeDeadline=math.min(deadline,os.clock()+perNode)
                    local bestNodeDistance=walkingDist
                    local lastAdvance=os.clock()
                    while valid(id) and os.clock()<nodeDeadline do
                        local flying,flightWhy=recoverFlightIfRequested()
                        if flying~=nil then return flying,flightWhy end
                        r=root()
                        if not r or hum.Health<=0 then return false,"Character lost" end
                        local remaining=(r.Position-node.Position).Magnitude
                        if remaining<=4.8 then break end
                        if remaining<bestNodeDistance-1.5 then
                            bestNodeDistance=remaining
                            lastAdvance=os.clock()
                        elseif os.clock()-lastAdvance>1.1 then
                            jumpRecovery("waypoint blocked")
                            hum:MoveTo(node.Position)
                            lastAdvance=os.clock()
                        end
                        task.wait(.075)
                    end
                    if not r or (r.Position-node.Position).Magnitude>6 then
                        failures+=1
                        jumpRecovery("waypoint timed out")
                        S.diagEvent("WALK_REPATH",string.format(
                            "blocked waypoint | failure=%d/6",failures))
                        break
                    end
                    S.recordEnchantedStep()
                end
            end
            r=root()
            if not r then return false,"Character lost" end
            local after=(r.Position-cf.Position).Magnitude
            if before-after>7 then
                failures=0
            else
                failures+=1
                jumpRecovery("insufficient route progress")
                S.diagEvent("WALK_REPATH",string.format(
                    "slow movement | failure=%d/6 remaining=%.1f",
                    failures,after))
            end
            if failures>=6 then
                return false,"Walking stalled after 6 recovery attempts / server corrected movement"
            end
        end
    end
    return false,"Walk timed out"
end
      function pathTo(cf,id)
    -- Short-range walking for NPC prompts and local movement.
    return walkRoute(cf,id,135)
end
-- ONLY normal farming movement: teleport between saved dig/sand and
-- water positions AFTER each phase completes. This is intentionally fast.
-- Zone and waypoint travel below still uses real Humanoid walking.
      function farmMove(cf,id)
    -- DIG and WATER can be 4-6 studs apart. move()'s ordinary
    -- 7-stud arrival tolerance is suitable for travel but silently
    -- skipped these essential phase transitions.
    if typeof(cf)~="CFrame" then return false end
    for attempt=1,3 do
        if not valid(id) then return false end
        local avatar=root()
        if not avatar then return false end
        local before=(avatar.Position-cf.Position).Magnitude
        if before<=1.5 then return true end
        local ok=pcall(function() avatar.CFrame=cf end)
        if not ok or not pause(S.timing("teleport"),id) then return false end
        avatar=root()
        local after=avatar and (avatar.Position-cf.Position).Magnitude or math.huge
        if after<=2.5 then return true end
        if attempt==3 then
            S.diagEvent("FARM_PHASE_POSITION_FAILED",string.format(
                "before=%.1f after=%.1f zone=%s",
                before,after,tostring(S.dredgeAt or S.activeZone)))
        end
    end
    return false
end
-- Normal farm movement is instantaneous. On the next remote call, however,
-- the server may have snapped the character back to the previous location.
-- Verify the actual position before Collect/Pan; correct only when needed.
      function ensureFarmPosition(cf,id,action)
    if not cf or not valid(id) then return false end
    local avatar=root()
    if not avatar then return false end
    local offset=(avatar.Position-cf.Position).Magnitude
    if offset<=7 then return true end
    S.diagEvent("POSITION_DRIFT",string.format(
        "%s %.1f studs away from action spot; correcting",
        tostring(action),offset))
    for attempt=1,3 do
        if not valid(id) then return false end
        local moved=farmMove(cf,id)
        -- Only wait when the prior movement did not stick. The fast path
        -- above adds zero delay for properly positioned farming.
        if moved and not pause(.15+(attempt-1)*.10,id) then return false end
        avatar=root()
        local distance=avatar and (avatar.Position-cf.Position).Magnitude or math.huge
        if moved and distance<=7 then
            S.diagEvent("POSITION_RECOVERED",string.format(
                "%s attempt=%d distance=%.1f",tostring(action),attempt,distance))
            return true
        end
        S.diagEvent("POSITION_BOUNCED",string.format(
            "%s attempt=%d moved=%s distance=%.1f",
            tostring(action),attempt,tostring(moved),distance))
    end
    S.diagEvent("POSITION_UNSTABLE",
        tostring(action).." | "..S.diagSnapshot())
    return false
end
-- Sparse recorded routes can leave 100+ studs between the first
-- checkpoint and its warp stone. Bridge short gaps by ACTUAL walking,
-- never by CFrame jumps. This fallback is used only if Pathfinding fails.
      function walkGroundBridge(cf,id)
    local character=P.Character
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    local r=root()
    if not r or not hum or hum.Health<=0 then return false,"No character to walk" end
    local gap=(r.Position-cf.Position).Magnitude
    if gap>200 then return false,"Gap too large for direct bridge ("..math.floor(gap).." studs)" end
    local deadline=os.clock()+math.clamp(gap/math.max(8,hum.WalkSpeed)*3+5,7,40)
    local rays=RaycastParams.new()
    rays.FilterType=Enum.RaycastFilterType.Exclude
    rays.FilterDescendantsInstances={character}
    local attempts=0
    while valid(id) and os.clock()<deadline do
        r=root()
        if not r or hum.Health<=0 then return false,"Character unavailable" end
        local remaining=(r.Position-cf.Position).Magnitude
        if remaining<=10 then return true end
        attempts+=1
        if attempts>12 then return false,"Bridge step limit reached" end
        local nextPos=r.Position+(cf.Position-r.Position).Unit*math.min(29,remaining)
        local ground=workspace:Raycast(nextPos+Vector3.new(0,40,0),
            Vector3.new(0,-120,0),rays)
        if not ground then return false,"No ground for bridge" end
        nextPos=ground.Position+Vector3.new(0,3,0)
        if math.abs(nextPos.Y-r.Position.Y)>14 then
            return false,"Steep drop/climb needs another saved checkpoint"
        end
        local before=remaining
        hum:MoveTo(nextPos)
        local stepEnd=math.min(deadline,os.clock()+4)
        while valid(id) and os.clock()<stepEnd do
            r=root()
            if not r then return false,"Character disappeared" end
            if (r.Position-nextPos).Magnitude<=7 then break end
            task.wait(.065)
        end
        r=root()
        if not r then return false,"Character disappeared" end
        if before-(r.Position-cf.Position).Magnitude<3 then
            return false,"Walk bridge blocked or server corrected movement"
        end
    end
    return false,"Walk bridge timed out"
end
-- Warp models/pivots may be ABOVE the ground or not on the navmesh.
-- Walk to a reachable point ~25-48 studs from the stone instead.
      function approachStone(stone,id,stoneName)
    local r=root()
    if not r then return false,"No character" end
    if (r.Position-stone.Position).Magnitude<=52 then
        if stableAt(stone,id,56,.4,2) then return true end
    end
    local lastError="No route to stone"
    for _,radius in ipairs({24,36,48}) do
        if not valid(id) then return false,"Stopped" end
        r=root()
        if not r then return false,"Character missing" end
        local away=Vector3.new(r.Position.X-stone.Position.X,0,
            r.Position.Z-stone.Position.Z)
        if away.Magnitude<.1 then away=Vector3.new(1,0,0) end
        local pos=stone.Position+away.Unit*radius
        local rays=RaycastParams.new()
        rays.FilterType=Enum.RaycastFilterType.Exclude
        rays.FilterDescendantsInstances={P.Character}
        local ground=workspace:Raycast(pos+Vector3.new(0,65,0),
            Vector3.new(0,-165,0),rays)
        if ground then
            pos=ground.Position+Vector3.new(0,3,0)
        else
            pos=Vector3.new(pos.X,r.Position.Y,pos.Z)
        end
        S.dredgeCurrentWork="Bridging to warp stone "..tostring(stoneName)
        local destination=CFrame.new(pos)
        local ok,why=walkRoute(destination,id,2000,true)
        if not ok then
            -- Navigation meshes sometimes exclude stone platforms.
            -- For a short, walkable gap, try real MoveTo steps instead.
            local bridged,bridgeWhy=walkGroundBridge(destination,id)
            if not bridged then lastError=tostring(why).." / "..tostring(bridgeWhy) end
        end
        r=root()
        if r and (r.Position-stone.Position).Magnitude<=56
            and stableAt(stone,id,60,.35,1.5) then return true end
    end
    return false,"Could not approach warp stone: "..lastError
end
-- Replay dense user recordings using direct Humanoid movement first.
-- Pathfinding remains a fallback for blocked walkable sections. Midair
-- checkpoints are treated as freefall and marked jump sequences as arcs.
      function replayPoint(cf,id,markedJump,noPathFallback)
    local rr=root()
    local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if not rr or not hum or hum.Health<=0 then return false,"Character unavailable" end
    if markedJump then
        hum.Jump=true
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
    local dist=(rr.Position-cf.Position).Magnitude
    if dist<=7 then return true end
    hum:MoveTo(cf.Position)
    local since=os.clock()
    local deadline=since+math.clamp(dist/math.max(8,hum.WalkSpeed)*1.65+1,2,7)
    local lastPos=rr.Position
    local lastProgress=os.clock()
    while valid(id) and os.clock()<deadline do
        rr=root()
        if not rr or hum.Health<=0 then return false,"Character died" end
        if (rr.Position-cf.Position).Magnitude<=6 then return true end
        if (rr.Position-lastPos).Magnitude>1.1 then
            lastPos=rr.Position
            lastProgress=os.clock()
        elseif os.clock()-lastProgress>.85 then
            S.diagEvent("ROUTE_REPLAY_STALL",
                string.format("distance=%.1f", (rr.Position-cf.Position).Magnitude))
            break
        end
        task.wait(.10)
    end
    if not valid(id) then return false,"Stopped" end
    -- Abyss upper exit is a player-recorded tight route: invoking
    -- PathfindingService here can take the OLD route and stall on
    -- the same cliff/ledge. Let the caller explicitly retry/abort.
    if noPathFallback then
        local after=root()
        return false,string.format(
            "recorded outbound checkpoint blocked: %.1f studs away",
            after and (after.Position-cf.Position).Magnitude or -1)
    end
    return walkRoute(cf,id,1800,true)
end
      function replayJumpArc(nodes,first,last,id,zone)
    local dest=S.unpackCF(nodes[last])
    if not dest then return false,"Jump destination missing" end
    local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false,"Character unavailable" end
    hum:MoveTo(dest.Position)
    hum.Jump=true
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local started=os.clock()
    local lastJump=started
    while valid(id) and os.clock()-started<5.5 do
        local rr=root()
        if not rr or hum.Health<=0 then return false,"Character died" end
        local diff=dest.Position-rr.Position
        local horiz=Vector3.new(diff.X,0,diff.Z).Magnitude
        if horiz<=6 and math.abs(diff.Y)<=11 then
            S.diagEvent("ROUTE_JUMP_ARC_OK",
                string.format("%s %d->%d horizontal=%.1f",zone,first,last,horiz))
            return true
        end
        if os.clock()-lastJump>.5 and
            hum.FloorMaterial~=Enum.Material.Air and horiz>7 then
            hum.Jump=true
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            lastJump=os.clock()
        end
        hum:MoveTo(dest.Position)
        task.wait(.1)
    end
    return false,string.format("Jump arc %d->%d timed out",first,last)
end
      function replayDrop(cf,id,index,zone)
    local rr=root()
    if not rr then return false,"Character missing" end
    local pos=cf.Position
    if rr.Position.Y<=pos.Y+6 then return true end
    local started=os.clock()
    local firstY=rr.Position.Y
    local lowest=firstY
    local lastMove=0
    while valid(id) and os.clock()-started<12 do
        rr=root()
        local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
        if not rr or not hum or hum.Health<=0 then return false,"Died during descent" end
        local horiz=Vector3.new(pos.X-rr.Position.X,0,pos.Z-rr.Position.Z).Magnitude
        if (rr.Position.Y<=pos.Y+6 and horiz<=8) or
            rr.Position.Y<pos.Y-15 then return true end
        if horiz>65 then return false,"Drifted away from drop" end
        if horiz>2 and os.clock()-lastMove>.45 then
            hum:MoveTo(pos)
            lastMove=os.clock()
        end
        lowest=math.min(lowest,rr.Position.Y)
        if os.clock()-started>5 and lowest>firstY-2 then
            return false,"Not descending at checkpoint "..index
        end
        task.wait(.08)
    end
    return false,"Drop timed out at "..tostring(zone).." checkpoint "..index
end
-- Traverse separately recorded stone->deposit and deposit->stone paths.
-- Existing coarse presets still work through pathfinding fallback.
      function followRoutePoints(zoneName,id,reverse,reverseStartIndex)
    local p=S.presets[zoneName]
    local recordedOutbound=reverse and p and p.routeOut and #p.routeOut>=2
    if reverse and zoneName=="Abyssal Depth" and
        (not recordedOutbound or #p.routeOut<50) then
        local count=p and p.routeOut and #p.routeOut or 0
        S.diagEvent("ABYSS_OUTBOUND_MISSING",string.format(
            "Expected dense 61-point recorded routeOut; got %d. Refusing old path.",count))
        return false,"Abyss outbound path incomplete ("..count..
            " checkpoints; expected ~61). Will not replay old path."
    end
    -- Enchanted's recorded inbound points 3-9 form an airborne shortcut.
    -- The server repeatedly corrects the avatar downward at point 5.
    -- Its separate 40-point outbound corridor is a genuine ground route;
    -- traverse that SAME recording backwards when entering the ruins.
    -- Keep both original recordings and every coordinate unchanged.
    local enchantedInbound=not reverse and zoneName=="Enchanted Ruins"
        and p and p.routeOut and #p.routeOut>=30
    local nodes=(recordedOutbound or enchantedInbound) and p.routeOut
        or (p and p.route or {})
    local isReverse=(reverse and not recordedOutbound) or enchantedInbound
    local jumpIndices=(recordedOutbound or enchantedInbound) and p.routeOutJumps
        or (p and p.routeJumps)
    local jumps={}
    for _,j in ipairs(jumpIndices or {}) do jumps[j]=true end
    local startIndex=isReverse and math.clamp(
        enchantedInbound and #nodes or reverseStartIndex or #nodes,
        1,math.max(1,#nodes)) or 1
    if recordedOutbound and zoneName=="Abyssal Depth" then
        local rr=root()
        if rr then
            local nearest,dist=nil,math.huge
            for i,node in ipairs(nodes) do
                local cf=S.unpackCF(node)
                if cf and cf.Position.Y>-160 then
                    local d=(rr.Position-cf.Position).Magnitude
                    if d<dist then nearest,dist=i,d end
                end
            end
            if nearest then startIndex=nearest end
        end
    end
    -- Identify Abyss's complete falling shaft. Individual recorded
    -- positions can be midair, including near-horizontal frames.
    local dropStart,dropEnd
    if zoneName=="Abyssal Depth" and not reverse then
        local minY,minIndex=math.huge,nil
        for i,node in ipairs(nodes) do
            local cf=S.unpackCF(node)
            if cf and cf.Position.Y<minY then
                minY,minIndex=cf.Position.Y,i
            end
        end
        if minIndex and minY<-220 then
            for i=2,minIndex do
                local a,b=S.unpackCF(nodes[i-1]),S.unpackCF(nodes[i])
                if a and b and a.Position.Y-b.Position.Y>4 and
                    a.Position.Y>minY+45 then
                    dropStart=i
                    break
                end
            end
            if dropStart then
                for i=dropStart,#nodes do
                    local cf=S.unpackCF(nodes[i])
                    local nextCF=i<#nodes and S.unpackCF(nodes[i+1]) or nil
                    if cf and cf.Position.Y<=minY+4 and
                        (not nextCF or math.abs(nextCF.Position.Y-cf.Position.Y)<4) then
                        dropEnd=i
                        break
                    end
                end
                dropEnd=dropEnd or minIndex
                S.diagEvent("ABYSS_DESCENT_SEGMENT",
                    string.format("%d-%d bottom=%.1f",dropStart,dropEnd,minY))
            end
        end
    end
    S.diagEvent("WALK_ROUTE_START",string.format(
        "zone=%s direction=%s source=%s checkpoints=%d start=%d",
        tostring(zoneName),reverse and "to warp" or "to sand",
        enchantedInbound and "REVERSED_RECORDED_OUTBOUND" or
        (recordedOutbound and "RECORDED_ROUTE_OUT" or
            (isReverse and "REVERSED_INBOUND" or "RECORDED_ROUTE_IN")),
        #nodes,startIndex))
    if reverse and zoneName=="Abyssal Depth" then
        S.diagEvent("ABYSS_OUTBOUND_ACTIVE",string.format(
            "recorded=%d start=%d end=%d",#nodes,startIndex,#nodes))
    end
    local steps=isReverse and startIndex or
        (recordedOutbound and (#nodes-startIndex+1) or #nodes)
    local skipUntil=0
    for step=1,steps do
        local index=isReverse and (startIndex-step+1) or
            (recordedOutbound and (startIndex+step-1) or step)
        if index<=skipUntil then continue end
        if not valid(id) then return false,"Stopped" end
        local cf=S.unpackCF(nodes[index])
        if cf then
            local rr=root()
            if not rr then return false,"Character missing" end
            if recordedOutbound and zoneName=="Abyssal Depth" and
                (index==startIndex or index%10==0 or index==#nodes) then
                S.diagEvent("ABYSS_OUTBOUND_POINT",string.format(
                    "point=%d/%d distance=%.1f posY=%.1f targetY=%.1f",
                    index,#nodes,(rr.Position-cf.Position).Magnitude,
                    rr.Position.Y,cf.Position.Y))
            end
            -- Azuralite's five outbound jump arcs must be traveled
            -- continuously; stopping at airborne frames causes backtracking.
            if recordedOutbound and zoneName=="Azuralite Oasis" and jumps[index] then
                local landing=math.min(#nodes,index+6)
                for j=index+1,#nodes do
                    if jumps[j] then landing=j;break end
                end
                local ok,err=replayJumpArc(nodes,index,landing,id,zoneName)
                if not ok then return false,
                    "Route jump "..index.."->"..landing..": "..tostring(err) end
                skipUntil=landing-1
                continue
            end
            local prev=index>1 and S.unpackCF(nodes[index-1]) or nil
            local fallFrame=not reverse and prev and
                prev.Position.Y-cf.Position.Y>5 and
                (Vector3.new(prev.Position.X-cf.Position.X,0,
                    prev.Position.Z-cf.Position.Z)).Magnitude<9
            local drop=not reverse and
                ((dropStart and index>=dropStart and index<=dropEnd) or
                (not dropStart and fallFrame))
            local ok,err
            if drop then
                ok,err=replayDrop(cf,id,index,zoneName)
            else
                if jumps[index] then
                    local hum=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
                    local ahead=S.unpackCF(nodes[math.min(index+2,#nodes)])
                    if hum and ahead then
                        hum:MoveTo(ahead.Position)
                        hum.Jump=true
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                        S.diagEvent("WALK_RECORDED_JUMP",
                            zoneName.." point "..index)
                        task.wait(.12)
                    end
                end
                ok,err=replayPoint(cf,id,jumps[index],
                    recordedOutbound and zoneName=="Abyssal Depth")
            end
            if not ok then
                S.diagEvent("WALK_CHECKPOINT_ERROR",
                    zoneName.." point "..index..": "..tostring(err))
                return false,"Route checkpoint "..index.."/"..#nodes..
                    ": "..tostring(err)
            end
        end
    end
    S.diagEvent("WALK_ROUTE_END",zoneName..
        (reverse and " -> warp" or " -> dig")..
        (recordedOutbound and " (recorded outbound)" or ""))
    return valid(id)
end
-- Abyssal Depth exit requires a real rope ProximityPrompt; ordinary
-- walking cannot traverse the vertical shaft. Cobalt's GetData is unrelated.
      function climbAbyssRope(id)
    local map=workspace:FindFirstChild("Map")
    local lush=map and map:FindFirstChild("LushCaverns")
    local assets=lush and lush:FindFirstChild("AbyssAssets")
    local rope=assets and assets:FindFirstChild("Rope")
    local interact=rope and rope:FindFirstChild("RopeInteract")
    local prompt=interact and interact:FindFirstChild("Prompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false,"Abyss rope ProximityPrompt missing"
    end
    local r=root()
    if not r then return false,"Character missing at Abyss rope" end
    local before=r.Position.Y
    local pos=interact.Position
    -- The first upper route checkpoint is around Y=-114. Do not
    -- mistake the start of the rope animation for reaching its exit.
    local upperY=pos.Y+90
    if before>upperY then return true end
    S.dredgeCurrentWork="Climbing Abyssal Depth rope"
    S.diagEvent("ABYSS_ROPE_APPROACH",
        string.format("dist=%.1f y=%.1f", (r.Position-pos).Magnitude,before))
    if (r.Position-pos).Magnitude>math.max(5,prompt.MaxActivationDistance-1) then
        local ok,reason=walkRoute(CFrame.new(pos),id,350,true)
        if not ok then return false,"Cannot reach rope: "..tostring(reason) end
    end
    r=root()
    if not r or (r.Position-pos).Magnitude>prompt.MaxActivationDistance then
        return false,"Not inside Abyss rope prompt range"
    end
    if not prompt.Enabled then return false,"Abyss rope prompt disabled" end
    local used=false
    if type(fireproximityprompt)=="function" then
        used=pcall(fireproximityprompt,prompt)
    end
    if not used then
        used=pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(1.1,prompt.HoldDuration+.15))
            prompt:InputHoldEnd()
        end)
    end
    if not used then return false,"Could not activate rope prompt" end
    S.diagEvent("ABYSS_ROPE_TRIGGERED","Waiting for climb teleport")
    local deadline=os.clock()+15
    while valid(id) and os.clock()<deadline do
        r=root()
        if r and r.Position.Y>upperY then
            S.diagEvent("ABYSS_ROPE_EXIT_OK",
                string.format("top reached at Y=%.1f (gained %.1f)",
                    r.Position.Y,r.Position.Y-before))
            return true
        end
        task.wait(.12)
    end
    return false,"Rope triggered but upper ledge not reached"
end

-- Return along the actual successful inbound steps, in reverse order.
-- Frequent breadcrumbs make steep Enchanted Ruins ramps reversible without
-- asking the navigator to invent a new route around the cliff.
function S.returnViaEnchantedPath(id)
    local steps=S.enchantedInboundRoute
    if not steps or #steps<3 then return false,"No recorded inbound route" end
    S.diagEvent("ENCHANTED_REVERSE_START",
        string.format("recorded=%d points",#steps))
    S.dredgeCurrentWork="Reversing actual Enchanted Ruins entry path"
    for i=#steps,1,-1 do
        if not valid(id) then return false,"Interrupted" end
        local pos=steps[i]
        local r=root()
        if not r then return false,"Character lost" end
        if (r.Position-pos).Magnitude>5.5 then
            local ok,err=walkRoute(CFrame.new(pos),id,1800,true)
            if not ok then
                S.diagEvent("ENCHANTED_REVERSE_FAILED",
                    string.format("point=%d/%d: %s",i,#steps,tostring(err)))
                return false,"Reversing entry path failed at "..i..
                    "/"..#steps..": "..tostring(err)
            end
        end
        if i%20==0 or i==1 then
            S.diagEvent("ENCHANTED_REVERSE_PROGRESS",
                string.format("%d/%d remaining",i-1,#steps))
        end
    end
    S.diagEvent("ENCHANTED_REVERSE_DONE","Reached recorded entry point")
    return true
end

      function returnToMappedStone(id)
    local oldZone=S.dredgeAt
    if not oldZone then return true end
    local p=S.presets[oldZone]
    -- The user's full recorded routes are embedded, so no executor-local
    -- preset file is required to leave Abyssal Depth.
    if oldZone=="Abyssal Depth" then
        local count=p and p.routeOut and #p.routeOut or 0
        S.diagEvent("ABYSS_OUTBOUND_BUILTIN",string.format(
            "Using supplied routeOut (%d checkpoints)",count))
        if count<50 then
            return false,"Abyss outbound recording incomplete ("..count..
                " points); turn-in cannot be sent until real navigation succeeds"
        end
    end
    local folder=S.waypointFolder()
    local obj=p and folder and folder:FindFirstChild(p.waypoint or "")
    local stone=obj and S.getWaypointCF(obj)
    if not stone then return false,"Old zone waypoint missing: "..oldZone end
    local r=root()
    if not r then return false,"Character missing" end
    if (r.Position-stone.Position).Magnitude<=52
        and stableAt(stone,id,60,.35,1.5) then return true end
    S.dredgeCurrentWork="Walking back to "..tostring(p.waypoint).." stone"
    local reverseStartIndex=nil
    if oldZone=="Abyssal Depth" then
        local escaped,escapeErr=climbAbyssRope(id)
        if not escaped then
            S.diagEvent("ABYSS_ROPE_EXIT_FAILED",tostring(escapeErr))
            return false,escapeErr
        end
        -- Rope can release the avatar anywhere along the upper path.
        -- Never retrace the two underground points after climbing, and
        -- do not force a climb back to checkpoint 5 after arriving closer
        -- to an earlier upper checkpoint.
        local nodes=(p.routeOut and #p.routeOut>=2) and p.routeOut or (p.route or {})
        local rr=root()
        if not rr then return false,"Character missing after Abyss rope" end
        local nearestIndex,nearestDist=nil,math.huge
        for i=1,#nodes do
            local cf=S.unpackCF(nodes[i])
            if cf and cf.Position.Y>-160 then
                local dist=(rr.Position-cf.Position).Magnitude
                if dist<nearestDist then
                    nearestDist=dist
                    nearestIndex=i
                end
            end
        end
        if not nearestIndex then
            S.diagEvent("ABYSS_UPPER_ROUTE_MISSING",
                "No upper checkpoints in saved Abyss route")
            return false,"No upper checkpoints after Abyss rope"
        end
        reverseStartIndex=nearestIndex
        S.diagEvent("ABYSS_UPPER_ROUTE_SOURCE",
            (p.routeOut and #p.routeOut>=2) and
            ("RECORDED_ROUTE_OUT nodes="..#p.routeOut) or
            "MISSING_OUTBOUND: old reverse path disabled")
        S.diagEvent("ABYSS_UPPER_ROUTE",string.format(
            "after rope pos=%.1f,%.1f,%.1f | nearest=%d/%d dist=%.1f",
            rr.Position.X,rr.Position.Y,rr.Position.Z,
            nearestIndex,#nodes,nearestDist))
        if nearestDist>135 then
            return false,string.format(
                "Abyss rope exit %.1f studs from nearest upper route point %d",
                nearestDist,nearestIndex)
        end
    end
    local ok,err
    if oldZone=="Enchanted Ruins" and not (p.routeOut and #p.routeOut>=2)
        and S.enchantedInboundRoute and #S.enchantedInboundRoute>=3 then
        ok,err=S.returnViaEnchantedPath(id)
    else
        -- If script was started inside the Ruins or the prior route was
        -- never recorded, retain the preset reverse-route fallback.
        if oldZone=="Enchanted Ruins" then
            S.diagEvent("ENCHANTED_REVERSE_FALLBACK",
                "No complete recorded inbound route; using saved checkpoints")
        end
        ok,err=followRoutePoints(oldZone,id,true,reverseStartIndex)
    end
    if not ok then
        S.diagEvent("DREDGE_RETURN_ROUTE_FAILED",
            tostring(oldZone).." -> "..tostring(p.waypoint).." | "..tostring(err))
        return false,err
    end
    -- The recorded Abyss reverse route ends at a reachable ledge, but the
    -- Overgrown Grotto stone pivot can be inaccessible to pathfinding.
    -- Allow the *mapped* departure stone to be tried from a nearby ledge,
    -- without claiming FastTravel succeeded until arrival is verified.
    local rr=root()
    if oldZone=="Abyssal Depth" and rr and
        (rr.Position-stone.Position).Magnitude<=75 then
        S.diagEvent("ABYSS_STONE_LEDGE",
            string.format("near mapped %s stone at %.1f studs; trying verified travel",
                tostring(p.waypoint),(rr.Position-stone.Position).Magnitude))
        return true
    end
    local atStone,stoneErr=approachStone(stone,id,p.waypoint)
    if oldZone=="Abyssal Depth" then
        local after=root()
        S.diagEvent("ABYSS_RETURN_TO_STONE",
            string.format("success=%s waypoint=%s dist=%.1f err=%s",
                tostring(atStone),tostring(p.waypoint),
                after and (after.Position-stone.Position).Magnitude or -1,
                tostring(stoneErr)))
    end
    return atStone,stoneErr
end
-- Resolve the actual deposit coordinates separately from saved waypoint
-- checkpoints. An old/local override can incorrectly point a zone's dig
-- position thousands of studs away even though its route is correct.
-- Only auto-repair Fortune River when its built-in destination is backed
-- by a nearby recorded route endpoint; do not overwrite user preset files.
function S.resolveDredgeDigWater(zoneName)
    local p=S.presets[zoneName]
    local dig=p and S.unpackCF(p.dig)
    local water=p and S.unpackCF(p.water)
    if zoneName=="Fortune River" and p then
        local built=S.defaultPresets[zoneName]
        local goodDig=built and S.unpackCF(built.dig)
        local goodWater=built and S.unpackCF(built.water)
        local route=p.route or {}
        local endpoint=#route>0 and S.unpackCF(route[#route])
        if goodDig and goodWater and endpoint
            and (endpoint.Position-goodDig.Position).Magnitude<30
            and (not dig or (dig.Position-goodDig.Position).Magnitude>100
                or not water or (water.Position-goodWater.Position).Magnitude>100) then
            S.diagEvent("DREDGE_COORD_REPAIR",string.format(
                "zone=%s badDigDist=%.1f routeToDefault=%.1f; using built-in dig/water",
                zoneName,dig and (dig.Position-goodDig.Position).Magnitude or -1,
                (endpoint.Position-goodDig.Position).Magnitude))
            return goodDig,goodWater
        end
    end
    return dig,water
end
      function walkFromStoneToZone(zoneName,id)
    local p=S.presets[zoneName]
    local target=S.resolveDredgeDigWater(zoneName)
    if not target then return false,"Missing dig coordinates: "..zoneName end
    S.dredgeCurrentWork="Walking from stone to "..zoneName
    local recording=zoneName=="Enchanted Ruins"
    if recording then
        S.enchantedInboundRoute=nil
        S.enchantedRecording={}
        S.recordEnchantedStep()
        S.diagEvent("ENCHANTED_RECORD_START","Recording actual walk to deposit")
    end
    local ok,err=followRoutePoints(zoneName,id,false)
    if not ok then
        S.enchantedRecording=nil
        return false,err
    end
    -- The saved route is the important part of the journey. Its final
    -- checkpoint should already be close to the deposit, so do not let a
    -- second full pathfinding pass stall or time out on the tiny last gap.
    -- Use the normal verified position move when close; only walk the final
    -- leg when the recording ends genuinely far away.
    local rr=root()
    if not rr then
        S.enchantedRecording=nil
        return false,"Character missing after saved route"
    end
    local finalGap=(rr.Position-target.Position).Magnitude
    S.diagEvent("DREDGE_FINAL_DEPOSIT_LEG",string.format(
        "zone=%s gap=%.1f",zoneName,finalGap))
    local reached=false
    local why=nil
    if finalGap<=220 then
        reached=move(target,id)
        if not reached then
            rr=root()
            finalGap=rr and (rr.Position-target.Position).Magnitude or math.huge
            if finalGap<=260 then
                S.diagEvent("DREDGE_FINAL_DEPOSIT_RETRY",
                    string.format("verified move retry gap=%.1f",finalGap))
                reached=move(target,id)
            end
        end
        if not reached then
            rr=root()
            finalGap=rr and (rr.Position-target.Position).Magnitude or math.huge
            if finalGap<=220 then
                reached,why=walkRoute(target,id,300)
            else
                why="Final deposit gap too large after route: "..math.floor(finalGap)
            end
        end
    else
        reached,why=walkRoute(target,id,1150)
        if not reached then
            rr=root()
            finalGap=rr and (rr.Position-target.Position).Magnitude or math.huge
            if finalGap<=220 then
                S.diagEvent("DREDGE_FINAL_DEPOSIT_TELEPORT",
                    string.format("walk fallback gap=%.1f",finalGap))
                reached=move(target,id)
            end
        end
    end
    rr=root()
    local finalDistance=rr and (rr.Position-target.Position).Magnitude or math.huge
    if not reached or finalDistance>14 then
        S.enchantedRecording=nil
        return false,why or string.format(
            "Final deposit position not reached (%.1f studs)",finalDistance)
    end
    local settled=stableAt(target,id,14,.45,1.5)
    if recording then
        S.recordEnchantedStep()
        local steps=S.enchantedRecording
        S.enchantedRecording=nil
        if settled and steps and #steps>=3 then
            S.enchantedInboundRoute=steps
            S.diagEvent("ENCHANTED_RECORD_DONE",
                string.format("%d actual path points saved",#steps))
        end
    end
    if settled then return true end
    return false,"Reached dig position but did not stay there"
end
      function goWaypoint(wp,id)
    local folder=S.waypointFolder()
    local r=root()
    local to=folder and folder:FindFirstChild(wp or "")
    local target=to and S.getWaypointCF(to)
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
    local from=nil
    -- After following a zone's return checkpoints, use THAT zone's mapped
    -- stone, not whichever unrelated stone happens to be geometrically closest.
    if oldZone then
        local preset=S.presets[oldZone]
        local mapped=preset and folder:FindFirstChild(preset.waypoint or "")
        local mappedCF=mapped and S.getWaypointCF(mapped)
        local departureRange=oldZone=="Abyssal Depth" and 75 or 65
        if mappedCF and (r.Position-mappedCF.Position).Magnitude<=departureRange then
            from=mapped
        end
    end
    from=from or S.closestWaypoint(folder,r.Position)
    if not from then return false,"No departure waypoint found" end
    local origin=S.getWaypointCF(from)
    if not origin then return false,"Departure waypoint has no pivot" end
    local fromAbyssLedge=oldZone=="Abyssal Depth" and from.Name=="Overgrown Grotto"
        and (r.Position-origin.Position).Magnitude<=75
    if (r.Position-origin.Position).Magnitude>52 and not fromAbyssLedge then
        S.dredgeCurrentWork="Walking to departure stone "..from.Name
        local ok,err=approachStone(origin,id,from.Name)
        if not ok then return false,"Cannot reach departure stone: "..tostring(err) end
        r=root()
        if not r or (r.Position-origin.Position).Magnitude>65 then
            return false,"Departure stone approach did not stick"
        end
    end
    if from==to then
        return stableAt(target,id,78,1.0,2.7)
    end
    if fromAbyssLedge and (r.Position-origin.Position).Magnitude>44 then
        -- The mapped upper ledge is ~65 studs from the stone, which can be
        -- outside the server's FastTravel range. Use a short ground-checked
        -- hop toward it, not a blind long-range teleport.
        local away=Vector3.new(r.Position.X-origin.Position.X,0,
            r.Position.Z-origin.Position.Z)
        if away.Magnitude<1 then away=Vector3.new(1,0,0) end
        local candidate=origin.Position+away.Unit*33
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={P.Character}
        local ground=workspace:Raycast(candidate+Vector3.new(0,60,0),
            Vector3.new(0,-130,0),params)
        if ground then candidate=ground.Position+Vector3.new(0,3,0)
        else candidate=Vector3.new(candidate.X,r.Position.Y,candidate.Z) end
        local gap=(r.Position-candidate).Magnitude
        S.diagEvent("ABYSS_STONE_CLOSE_APPROACH",string.format(
            "from %.1f studs, gap %.1f", (r.Position-origin.Position).Magnitude,gap))
        if gap<=60 then
            local hopped=move(CFrame.new(candidate),id)
            r=root()
            S.diagEvent("ABYSS_STONE_CLOSE_RESULT",
                string.format("moved=%s distance=%.1f",tostring(hopped),
                    r and (r.Position-origin.Position).Magnitude or -1))
        end
    end
    if fromAbyssLedge then
        r=root()
        if not r or (r.Position-origin.Position).Magnitude>52 then
            return false,"Abyss departure stone out of travel range after close approach"
        end
        S.diagEvent("ABYSS_STONE_TRAVEL_ATTEMPT",string.format(
            "mapped departure=%s distance=%.1f destination=%s",
            from.Name,(r.Position-origin.Position).Magnitude,tostring(wp)))
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
      function approachDredgeNPC(id)
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
    local npcCF=S.getWaypointCF(npc)
    if not npcCF then return true,"NPC has no readable pivot" end
    local r=root()
    if r and (r.Position-npcCF.Position).Magnitude<=12 then return true end
    local target=npcCF*CFrame.new(0,0,5)
    if pathTo(target,id) then return true end
    return false,"Could not approach Dredge Master NPC"
end
      function sendDredgeTalk(id)
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
      function handleDredgeTransition(id,mode)
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
        S.dredgeTurninSent=false
    end
    if mode=="turnin" then
        if os.clock()-(S.dredgeTransitionAt or 0)<8 then
            dredgeText(S.dredgeTurninSent and
                "Talked to Dredge Master; awaiting quest step change" or
                "Navigation to Dredge Master pending; no talk sent")
            return
        end
        if (S.dredgeTransitionAttempts or 0)>=3 then
            -- Only REAL successful nearby talks count. Never disable
            -- automation because movement to the NPC was blocked.
            S.dredgeTransitionAttempts=0
            S.dredgeTransitionAt=os.clock()+22
            S.dredgeTurninSent=false
            dredgeText("Turn-in unconfirmed; retrying NPC after cooldown")
            return
        end
        S.dredgeCurrent=nil;S.dredgeGroup=nil
        S.dredgeCapLockedZone=nil
        local ok,err=sendDredgeTalk(id)
        S.dredgeTransitionAt=os.clock()
        S.dredgeTurninSent=ok
        if ok then
            S.dredgeTransitionAttempts+=1
            dredgeText("Talked to nearby Dredge Master ("..
                S.dredgeTransitionAttempts.."/3); verifying")
        else
            S.diagEvent("DREDGE_TURNIN_NAV_FAILED",tostring(err))
            dredgeText("Going to Dredge Master: "..tostring(err))
        end
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

      function safeDig()
    local x=S.presets["Fortune River"]
    return x and S.unpackCF(x.dig)
end
      function escapeZone()
    -- No long-range CFrame here: this was causing repeated rubber-banding.
    -- Preserve the current zone for the route BACK to its mapped stone.
    S.dredgeRiskZone=false
end
      function dredgeHealthWatch()
    if not S.dredge or not S.running or not S.dredgeRiskZone then return end
    local c=P.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if h and h.Health<h.MaxHealth*.75 then
        escapeZone()
        if stop then stop() end
        dredgeText("STOPPED: risky-zone HP below 75%; no forced teleport; move to safety")
    end
end
      function describeDredgeTargets(group,remaining)
    local parts={}
    for _,v in ipairs(group or {}) do
        parts[#parts+1]=v.m.." ("..tostring(remaining[v.m] or 0).." left)"
    end
    return #parts>0 and table.concat(parts,", ") or "None"
end
-- Abyssal flare maintenance. Runs only in Auto Dredge while stationed
-- inside Abyssal Depth, never inside the fast Collect/Pan/Shake loops.
function S.nearbyFireflyFlare()
    local r=root()
    if not r then return false end
    -- A placed flare is a world object, not a Tool in Character/Backpack.
    -- Restrict to actual lit flare objects near the player.
    for _,obj in ipairs(workspace:GetDescendants()) do
        local name=obj.Name:lower()
        if name:find("firefly",1,true) and name:find("flare",1,true) then
            local pos
            if obj:IsA("BasePart") then
                pos=obj.Position
            elseif obj:IsA("Model") then
                pos=obj:GetPivot().Position
            end
            if pos and (pos-r.Position).Magnitude<=55 then
                local light=obj:FindFirstChildWhichIsA("Light",true)
                local particles=obj:FindFirstChildWhichIsA("ParticleEmitter",true)
                if (light and light.Enabled) or (particles and particles.Enabled) then
                    return true
                end
            end
        end
    end
    return false
end
      function maintainAbyssFlare(id)
    if not S.dredge or S.dredgeAt~="Abyssal Depth" or not valid(id) then return end
    local now=os.clock()
    if now<(S.abyssFlareNextCheck or 0) then return end
    S.abyssFlareNextCheck=now+5
    -- First arrival: reuse an existing nearby flare, if present.
    -- Otherwise activate immediately. Refresh every 570 seconds while
    -- stationed in Abyssal Depth, even when the older visual persists.
    local nextThrow=S.abyssFlareNextThrowAt
    if not nextThrow and S.nearbyFireflyFlare() then
        S.abyssFlareLastSeen=now
        S.abyssFlareNextThrowAt=now+570
        S.diagEvent("ABYSS_FLARE_EXISTING",
            "Existing flare; refresh scheduled in 570s")
        return
    end
    if nextThrow and now<nextThrow then return end
    if now<(S.abyssFlareNextAttempt or 0) then return end
    local c=P.Character
    local b2=P:FindFirstChild("BackpackTwo")
    local bag=P:FindFirstChildOfClass("Backpack")
    local rem=RS:FindFirstChild("Remotes")
    local custom=rem and rem:FindFirstChild("CustomBackpack")
    local equip=custom and custom:FindFirstChild("EquipRemote")
    if not c or not equip or not equip:IsA("RemoteEvent") then
        S.abyssFlareNextAttempt=now+12
        S.diagEvent("ABYSS_ITEM_EQUIP_MISSING","Character or EquipRemote missing")
        return
    end
    local function findItem(name)
        for _,container in ipairs({c,b2 or false,bag or false}) do
            if container then
                local found=container:FindFirstChild(name)
                if found then return found end
            end
        end
    end
    local panBefore=panTool() or S.panInBackpack()
    local panName=panBefore and panBefore.tool.Name
    if not panName then
        local stats=P:FindFirstChild("Stats")
        panName="Pharaoh's Pan"
    end
    local item=findItem("Firefly Flare")
    local isFlare=item~=nil
    if not item then item=findItem("Luminant Totem") end
    if not item then
        S.abyssFlareNextAttempt=now+15
        S.diagEvent("ABYSS_ITEM_UNAVAILABLE","No Firefly Flare or Luminant Totem")
        return
    end
    -- Preserve the pan before changing tools. Restore it in all paths,
    -- including activation errors and totem fallback.
    local panSaved=panBefore and panBefore.tool or findItem(panName)
    local function restorePan()
        if not valid(id) then return end
        local pan=(panTool() or S.panInBackpack())
        local candidate=pan and pan.tool or nil
        if not candidate or candidate.Parent==nil then candidate=panSaved end
        if not candidate or candidate.Parent==nil then
            candidate=findItem(panName)
        end
        if not candidate then
            S.diagEvent("ABYSS_PAN_RESTORE_MISSING",panName)
            return
        end
        if candidate.Parent==c and candidate:IsA("Tool") then
            S.diagEvent("ABYSS_PAN_RESTORED","Already equipped "..candidate.Name)
            return
        end
        local ok,err=pcall(function() equip:FireServer(candidate) end)
        if not ok then
            S.diagEvent("ABYSS_PAN_RESTORE_ERROR",tostring(err))
            return
        end
        local hum=c:FindFirstChildOfClass("Humanoid")
        if bag and candidate:IsA("Tool") and candidate.Parent==bag and hum then
            pcall(function() hum:EquipTool(candidate) end)
        end
        local untilAt=os.clock()+1.25
        while valid(id) and os.clock()<untilAt do
            local current=panTool()
            if current and current.tool.Parent==c then
                S.diagEvent("ABYSS_PAN_RESTORED",current.tool.Name)
                return
            end
            task.wait(.05)
        end
        S.diagEvent("ABYSS_PAN_RESTORE_UNCONFIRMED",
            "EquipRemote sent for "..candidate.Name.." but no held pan confirmed")
    end

    S.abyssFlareBusy=true
    local ok,err=pcall(function()
        S.diagEvent("ABYSS_ITEM_EQUIP_REQUEST",item.Name)
        equip:FireServer(item)
        local held
        local untilAt=os.clock()+1.5
        while valid(id) and os.clock()<untilAt do
            held=c:FindFirstChild(item.Name)
            if held and held:IsA("Tool") then break end
            task.wait(.05)
        end
        if not isFlare then
            S.abyssFlareNextAttempt=os.clock()+20
            S.diagEvent("ABYSS_TOTEM_FALLBACK","Totem equip-only; placement not confirmed")
        elseif held and held:IsA("Tool") and valid(id) then
            local sent,why=pcall(function() held:Activate() end)
            S.diagEvent(sent and "ABYSS_FLARE_ACTIVATE_SENT"
                or "ABYSS_FLARE_ACTIVATE_ERROR",sent and "Tool:Activate" or tostring(why))
            if sent then
                S.abyssFlareLastThrowAt=os.clock()
                S.abyssFlareNextThrowAt=S.abyssFlareLastThrowAt+570
                S.abyssFlareNextAttempt=S.abyssFlareNextThrowAt
                S.diagEvent("ABYSS_FLARE_SCHEDULED",
                    "Flare activated; refresh in 570s if still in Abyss")
            end
            task.wait(.35)
            if S.nearbyFireflyFlare() then
                S.diagEvent("ABYSS_FLARE_CONFIRMED","Lit flare detected")
                S.abyssFlareNextAttempt=S.abyssFlareNextThrowAt or os.clock()+570
            else
                S.diagEvent("ABYSS_FLARE_UNCONFIRMED","No placed flare detected")
                S.abyssFlareNextAttempt=S.abyssFlareNextThrowAt or os.clock()+570
            end
        else
            S.diagEvent("ABYSS_FLARE_NOT_HELD","EquipRemote sent; Tool not held")
            S.abyssFlareNextAttempt=os.clock()+12
        end
    end)
    if not ok then
        S.diagEvent("ABYSS_FLARE_ERROR",tostring(err))
        S.abyssFlareNextAttempt=os.clock()+12
    end
    -- Never leave the consumable selected when farming resumes.
    local restored,why=pcall(restorePan)
    if not restored then S.diagEvent("ABYSS_PAN_RESTORE_ERROR",tostring(why)) end
    S.abyssFlareBusy=false
end
      function dredgeCycle(id)
    if not valid(id) or not S.dredge then return false end
    dredgeHealthWatch()
    if not valid(id) or not S.dredge then return false end
    local status=S.dredgeServerStatus
    -- Wait for the server decision (the UI cache can survive a quest reset).
    if not status or os.clock()-status.time>15 then
        local why=tostring(S.dredgeQuestPollError or "pending")
        -- A nonresponsive quest remote previously left AUTO DREDGE ON
        -- forever with 0 pans. Stop safely and report the actual blocker.
        if not status and S.dredgeInitAt and
            os.clock()-S.dredgeInitAt>35 then
            local reason="Quest status unavailable after 35s: "..why
            S.diagLastFailure=reason
            S.diagEvent("DREDGE_INIT_TIMEOUT",reason.." | "..S.diagSnapshot())
            if stop then stop() end
            dredgeText("STOPPED: "..reason)
            return false
        end
        dredgeText("Checking CanStartQuest: "..why..
            " (poll #"..tostring(S.dredgePollAttempts or 0)..")")
        return false
    end
    local mode=questMode(status)
    if mode=="turnin" or mode=="available" then
        handleDredgeTransition(id,mode)
        return false
    end
    local fallbackMode=false
    local wants,done
    if mode=="unavailable" then
        wants=S.getFallbackWants()
        if not wants then
            S.dredgeCurrentWork="Waiting for Dredge quest"
            S.dredgeNextWork="Check quest availability"
            dredgeText("No quest available; fallback is off or target is unknown")
            return false
        end
        fallbackMode=true
        done=false
        S.dredgeCurrentWork="Fallback mineral: "..S.fallbackMineral
        S.dredgeNextWork="Resume Dredge automatically when a quest appears"
    else
        -- Server now confirms this quest is active, so allow a fresh transition
        -- later without retrying the previous StartQuest or QuestTalked.
        S.dredgeTransitionMode="active"
        S.dredgeTransitionAttempts=0
        local state=getQuest() or S.dredgeServerProgress
        wants,done=remaining(state)
        if not wants then
            dredgeText(tostring(done or "Waiting for StepProgress"))
            return false
        end
    end
    if done then
        S.dredgeCurrentWork="Mineral collection complete"
        S.dredgeNextWork="Turn in at Dredge Master"
        -- If the client reaches full progress a little before CanStartQuest
        -- advances to step 2, hold rather than farming useless extra pans.
        dredgeText("Collection complete; waiting for server's talk step")
        return false
    end
    -- Reset sticky route/group whenever switching between quest work and
    -- fallback work; never keep farming a previous objective by accident.
    if fallbackMode~=(S.dredgeFallbackActive==true) then
        S.dredgeCurrent=nil
        S.dredgeGroup=nil
        S.dredgeNextStop=nil
    end
    S.dredgeFallbackActive=fallbackMode
    S.dredgeStartAt=nil
    local st=P:FindFirstChild("Stats")
    local raw=st and tonumber(st:GetAttribute("Luck"))
    local capacityNow=S.capacity()
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
    local timedPriority,timedPriorityZone=nil,nil
    if not fallbackMode then
        timedPriority,timedPriorityZone=timedRareObjective(wants)
    end
    -- Sticky Dredge zone:
    -- Replanning on 10% progress changes or each Capacity fluctuation
    -- caused costly Volcanic Sands / Volcanic Springs / Sandstone trips.
    -- Keep the selected deposit while ALL of its assigned minerals
    -- still need collecting and the deposit remains available.
    -- As soon as ANY assigned mineral finishes, replan immediately
    -- (including a new Luck Cap for the remaining mineral in this zone).
    local keep=false
    if S.dredgeCurrent and S.dredgeGroup and #S.dredgeGroup>0 then
        local zone=baseDrop(S.dredgeCurrent)
        if openNow(zone) and eligible(S.dredgeCurrent,5) then
            local anyRemaining=false
            local completedAssigned=false
            for _,item in ipairs(S.dredgeGroup) do
                if (need[item.m] or 0)>0 then
                    anyRemaining=true
                else
                    completedAssigned=true
                end
            end
            keep=anyRemaining and not completedAssigned
            if keep then
                -- Update the readout but don't change the chosen zone
                -- or active cap when Capacity/luck/progress fluctuate.
                S.dredgePlanCapacity=capacityNow
            else
                S.diagEvent("DREDGE_REPLAN_REASON",
                    completedAssigned and "assigned objective completed"
                    or "assigned objectives exhausted")
            end
        else
            S.diagEvent("DREDGE_REPLAN_REASON",
                "current zone closed or equipment unavailable: "..tostring(zone))
        end
    end
    if timedPriority and keep then
        local heldZone=baseDrop(S.dredgeCurrent or "")
        local hasPriority=false
        for _,objective in ipairs(S.dredgeGroup or {}) do
            if objective.m==timedPriority.m then hasPriority=true;break end
        end
        if heldZone~=timedPriorityZone or not hasPriority then
            keep=false
            S.diagEvent("DREDGE_TIMED_PRIORITY_SWITCH",
                timedPriority.m.." @ "..timedPriorityZone..
                " supersedes current "..heldZone)
        end
    end
    if not keep then
        local plan=nil
        if timedPriority and timedPriorityZone then
            local per=math.max(1,.6779*math.max(1,capacityNow)^.56474)
            local stop=groupBest({timedPriority},{timedPriorityZone},L,per)
            if stop then
                plan={
                    stops={stop},
                    total=stop.pans,
                    covered=1,
                    needed=#wants,
                    timedPriority=timedPriority.m
                }
                S.diagEvent("DREDGE_TIMED_PRIORITY",
                    timedPriority.m.." first in "..timedPriorityZone..
                    " while its timed gate is open")
            end
        end
        if not plan then plan=bestRoute(wants,L,capacityNow) end
        if (not plan or not plan.stops[1]) and not fallbackMode then
            local fallback=S.getFallbackWants()
            if fallback then
                S.diagEvent("DREDGE_FALLBACK_START",
                    "Quest objective has no eligible zone; fallback="..S.fallbackMineral)
                wants=fallback
                fallbackMode=true
                plan=bestRoute(wants,L,capacityNow)
                S.dredgeCurrent=nil;S.dredgeGroup=nil
            end
        end
        if not plan or not plan.stops[1] then
            -- Being physically inside a deposit and owning a pan do not
            -- make a quest mineral obtainable there. Explain exactly which
            -- remaining objectives have no eligible drop location.
            local eligibleDrops={}
            local eligibleCount=0
            for _,candidate in ipairs(ALL_ZONES) do
                if eligible(candidate,5) then
                    eligibleCount+=1
                    for _,drop in ipairs(poolFor(candidate)) do
                        eligibleDrops[drop[1]]=true
                    end
                end
            end
            local missing={}
            for _,wanted in ipairs(wants) do
                if not eligibleDrops[wanted.m] then
                    missing[#missing+1]=wanted.m.." ("..tostring(wanted.n).." left)"
                end
            end
            S.dredgeCurrentWork="No eligible deposit for: "..
                (#missing>0 and table.concat(missing,", ") or "current objectives")
            S.dredgeNextWork="Eligible zones: "..tostring(eligibleCount)..
                " | inspect quest objective/deposit permissions"
            local explanation="Remaining objectives unavailable: "..
                (#missing>0 and table.concat(missing,", ") or "route optimizer could not form a plan")
            if S.dredgeLastNoPlanText~=explanation then
                S.dredgeLastNoPlanText=explanation
                S.diagEvent("DREDGE_NO_ELIGIBLE_PLAN",
                    explanation.." | eligibleZones="..tostring(eligibleCount))
            end
            dredgeText(explanation)
            -- No blind movement: remain where the player is and replan on
            -- the next quest refresh or time-gated zone opening.
            return false
        end
        S.dredgeLastNoPlanText=nil
        local choice=plan.stops[1]
        -- Unlock the cap only when the active mineral set changes or
        -- objectives are completed. This permits NONE -> 100 in the same
        -- zone without reintroducing cap changes every few pans.
        local oldObjectives={}
        for _,v in ipairs(S.dredgeGroup or {}) do
            -- Include completed objectives in the OLD signature so that
            -- {Aetherium,Ruby} -> {Ruby} forces a cap recalibration.
            oldObjectives[#oldObjectives+1]=v.m
        end
        local newObjectives={}
        for _,v in ipairs(choice.group or {}) do
            if (need[v.m] or 0)>0 then newObjectives[#newObjectives+1]=v.m end
        end
        table.sort(oldObjectives)
        table.sort(newObjectives)
        local oldKey=table.concat(oldObjectives,"|")
        local newKey=table.concat(newObjectives,"|")
        if oldKey~=newKey then
            S.dredgeCapLockedZone=nil
            S.dredgeCapLockedKey=nil
            S.diagEvent("DREDGE_RECALIBRATE",
                "Objectives "..oldKey.." -> "..newKey..
                " | zone="..tostring(baseDrop(choice.z))..
                " | planned cap="..tostring(choice.cap or "NONE"))
        end
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
    S.dredgeCurrentWork=(fallbackMode and "FALLBACK: " or "")..
        describeDredgeTargets(S.dredgeGroup,need).." @ "..targetZone
    if fallbackMode then
        S.dredgeNextWork="Return to quest objectives when eligible / available"
    elseif S.dredgeNextStop then
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
    -- Always reload the target zone's coordinates, even if OFF -> ON
    -- preserved dredgeAt. stop() restores the manual farm positions,
    -- so matching zone names alone do not mean S.dig/S.water are valid.
    local resolvedDig,resolvedWater=S.resolveDredgeDigWater(targetZone)
    if not resolvedDig or not resolvedWater then
        S.diagEvent("DREDGE_COORD_MISSING",tostring(targetZone))
        dredgeText("Zone coordinates missing: "..tostring(targetZone))
        return false
    end
    local zoneChanged=S.dredgeAt~=targetZone
    local oldDig=S.dig
    S.dig,S.water=resolvedDig,resolvedWater
    if not zoneChanged and (not oldDig
        or (oldDig.Position-resolvedDig.Position).Magnitude>30) then
        S.diagEvent("DREDGE_COORD_RESTORED",tostring(targetZone)..
            " | recovered dig/water after restart")
    end
    if not zoneChanged then
        local rr=root()
        if not rr or (rr.Position-resolvedDig.Position).Magnitude>165 then
            zoneChanged=true
            S.diagEvent("DREDGE_RESUME_RELOCATED",tostring(targetZone)..
                " | no longer at saved deposit; navigating again")
        end
    end
    if zoneChanged then
        if S.dredgeTravelRetryAt and os.clock()<S.dredgeTravelRetryAt then
            dredgeText("Travel cooldown - preventing warp spam");return false
        end
        dredgeText("Walking to "..targetZone)
        S.traceBegin("DREDGE_ZONE_TRAVEL",tostring(targetZone))
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
            S.traceEnd("DREDGE_ZONE_TRAVEL","failed: "..tostring(why))
            local tries=(S.dredgeTravelFailed[targetZone] or 0)+1
            S.dredgeTravelFailed[targetZone]=tries
            local failure=tostring(why)
            local travelRejected=failure:find("Server rejected waypoint travel",1,true)~=nil
            if travelRejected then
                -- A late FastTravel reply can move the player AFTER the 8s
                -- arrival test. Hold off before making any new request.
                -- If they arrive at the destination stone during that time,
                -- the next goWaypoint() call detects the arrival and walks
                -- the route normally, without firing another FastTravel.
                local retryDelay=tries==1 and 18 or 35
                S.dredgeTravelRetryAt=os.clock()+retryDelay
                S.dredgeWarped[targetZone]=nil
                S.dredgeCurrentWork="Waiting for delayed fast travel to "..targetZone
                S.dredgeNextWork="Recheck location after travel cooldown"
                S.diagEvent("DREDGE_TRAVEL_COOLDOWN",
                    string.format("%s | attempt=%d | cooldown=%ds | %s",
                        targetZone,tries,retryDelay,failure))
                if tries<3 then
                    dredgeText("Fast travel not confirmed; checking again in "..
                        retryDelay.."s (attempt "..tries.."/3)")
                    return false
                end
            end
            -- Ordinary pathfinding failures are recoverable. Re-plan from
            -- the actual current position after a cooldown instead of
            -- switching off Auto Dredge after a single blocked checkpoint.
            -- Never stack FastTravel requests while an old attempt is being
            -- checked; retries are separate bounded travel sessions.
            local retryDelay=math.min(12+tries*8,45)
            S.dredgeTravelRetryAt=os.clock()+retryDelay
            S.dredgeWarped[targetZone]=nil
            S.dredgeCurrentWork="Repathing to "..targetZone
            S.dredgeNextWork="Retry route after "..retryDelay.."s"
            S.diagEvent("DREDGE_WALK_RETRY",string.format(
                "zone=%s attempt=%d reason=%s",
                tostring(targetZone),tries,failure))
            if tries<=5 then
                dredgeText(string.format(
                    "Route stalled: retrying %s in %ds (%d/5)",
                    targetZone,retryDelay,tries))
                return false
            end
            S.dredgeCurrentWork="Route blocked: "..targetZone
            S.dredgeNextWork="Check saved stone route or move manually"
            dredgeText("Route blocked after repeated attempts: "..targetZone..": "..failure)
            if stop then stop() end
            return false
        end
        S.traceEnd("DREDGE_ZONE_TRAVEL","arrived at "..tostring(targetZone))
        S.dredgeTravelRetryAt=nil
        -- After a successful arrival, allow one new fallback warp on a
        -- separate FUTURE visit, not repeatedly during this visit.
        S.dredgeWarped[targetZone]=nil
        S.dredgeTravelFailed[targetZone]=nil
        if targetZone=="Abyssal Depth" then
            S.abyssFlareNextThrowAt=nil
            S.abyssFlareNextAttempt=nil
            S.abyssFlareNextCheck=nil
        end
        S.dredgeAt=targetZone
        S.dredgeZoneSince=os.clock()
        S.dredgeZoneCycle=S.cycles
        S.dredgeReadyAt=os.clock()+1.2
        S.dredgeFailureCount=0
        S.dredgeFailureZone=targetZone
        S.dredgeRiskZone=(targetZone=="Rotwood Swamp"
            or targetZone=="Abyssal Depth" or targetZone=="Magma Furnace")
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
    -- Freeze cap only while mining the same objective set. On objective
    -- completion, the replan above clears the lock even within one zone.
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
        outputDebug("[GALAXIS DREDGE] Luck Cap applied once for zone:",targetZone,capText)
        if not pause(.2,id) then return false end
    end
    if os.clock()<(S.dredgeReadyAt or 0) then
        dredgeText("Settling "..targetZone.." deposit/water before collecting")
        return false
    end
    if targetZone=="Abyssal Depth" then
        maintainAbyssFlare(id)
    end
    dredgeText(targetZone.." | cap "..tostring(S.dredgeTargetCap or "NONE")
        .." | "..tostring(S.dredgePlanText))
    return true
end

-- Persistent tab-separated logger