playerItemDatabase = {
	data = {}
}

function playerItemDatabase:get(itemId, itemSubType)
	local data = self.data[itemId]

	if itemSubType == nil or itemSubType == -1 then
		return data
	end

	if data ~= nil and data.subTypes ~= nil and itemSubType ~= nil and itemSubType ~= -1 then
		return data.subTypes[itemSubType]
	end

	return nil
end

function playerItemDatabase:clean()
	self.data = {}
end

function playerItemDatabase:set(itemId, itemInfo)
	if itemInfo ~= nil then
		self.data[itemId] = copyTable(itemInfo)
	else
		self.data[itemId] = nil
	end
end

function playerItemDatabase:setPriceBuy(itemId, price)
	self.data[itemId].priceBuy = price
end

function playerItemDatabase:setPriceSell(itemId, price)
	self.data[itemId].priceSell = price
end

itemDatabase = {
		-----------Value------------
	[2148] = {
		clientId = 3031,
		name = "gold coin",
		priceSell = 1,
		priceBuy = 1
	},
	[2152] = {
		clientId = 3035,
		name = "platinum coin",
		priceSell = 100,
		priceBuy = 100
	},
	[2160] = {
		clientId = 3043,
		name = "crystal coin",
		priceSell = 10000,
		priceBuy = 10000
	},
	[2033] = {
		clientId = 2903,
		name = "golden mug",
		priceSell = 950,
		priceBuy = 0
	},
	[2144] = {
		clientId = 3027,
		name = "black pearl",
		priceSell = 280,
		priceBuy = 560
	},
	[2458] = {
		clientId = 3041,
		name = "blue gem",
		priceSell = 5000,
		priceBuy = 0
	},
	[2344] = {
		clientId = 3231,
		name = "gemmed lamp",
		priceSell = 350,
		priceBuy = 0
	},
	[2157] = {
		clientId = 3040,
		name = "gold nugget",
		priceSell = 0,
		priceBuy = 0
	},
	[2155] = {
		clientId = 3038,
		name = "green gem",
		priceSell = 5000,
		priceBuy = 0
	},
	[2141] = {
		clientId = 3024,
		name = "holy falcon",
		priceSell = 0,
		priceBuy = 0
	},

	[2140] = {
		clientId = 3023,
		name = "holy scarab",
		priceSell = 0,
		priceBuy = 0
	},
	[2177] = {
		clientId = 3061,
		name = "life crystal",
		priceSell = 450,
		priceBuy = 0
	},
	[5022] = {
		clientId = 5021,
		name = "orichalcum pearl",
		priceSell = 0,
		priceBuy = 0
	},
	[2156] = {
		clientId = 3039,
		name = "red gem",
		priceSell = 1000,
		priceBuy = 0
	},
	[2159] = {
		clientId = 3042,
		name = "scarab coin",
		priceSell = 0,
		priceBuy = 0
	},
	[2134] = {
		clientId = 3017,
		name = "silver brooch",
		priceSell = 0,
		priceBuy = 0
	},
	[2150] = {
		clientId = 3033,
		name = "small amethyst",
		priceSell = 200,
		priceBuy = 400
	},
	[2145] = {
		clientId = 3028,
		name = "small diamond",
		priceSell = 300,
		priceBuy = 600
	},
	[2149] = {
		clientId = 3032,
		name = "small emerald",
		priceSell = 250,
		priceBuy = 500
	},
	[2147] = {
		clientId = 3030,
		name = "small ruby",
		priceSell = 250,
		priceBuy = 500
	},	
	[2146] = {
		clientId = 3029,
		name = "small sapphire",
		priceSell = 250,
		priceBuy = 500
	},
	[2137] = {
		clientId = 3020,
		name = "some golden fruits",
		priceSell = 0,
		priceBuy = 0
	},
	[2151] = {
		clientId = 3034,
		name = "talon",
		priceSell = 320,
		priceBuy = 0
	},
	[2153] = {
		clientId = 3036,
		name = "violet gem",
		priceSell = 10000,
		priceBuy = 0
	},
	[2143] = {
		clientId = 3026,
		name = "white pearl",
		priceSell = 160,
		priceBuy = 320
	},
	[2154] = {
		clientId = 3037,
		name = "yellow gem",
		priceSell = 1000,
		priceBuy = 0
	},	
	[2178] = {
		clientId = 3062,
		name = "mind stone",
		priceSell = 200,
		priceBuy = 0
	},
	[2176] = {
		clientId = 3060,
		name = "orb",
		priceSell = 750,
		priceBuy = 0
	},
	-----------Runes------------
	[2316] = {
		clientId = 3203,
		name = "animate dead rune",
		priceSell = 0,
		priceBuy = 375
	},
	[2266] = {
		clientId = 3153,
		name = "antidote rune",
		priceSell = 0,
		priceBuy = 65
	},
	[2260] = {
		clientId = 3147,
		name = "blank rune",
		priceSell = 10,
		priceBuy = 10
	},
	[2291] = {
		clientId = 3178,
		name = "chameleon rune",
		priceSell = 0,
		priceBuy = 210
	},
	[2290] = {
		clientId = 3177,
		name = "convince creature rune",
		priceSell = 0,
		priceBuy = 80
	},
	[2310] = {
		clientId = 3197,
		name = "desintegrate runee",
		priceSell = 0,
		priceBuy = 80
	},
	[2261] = {
		clientId = 3148,
		name = "destroy field rune",
		priceSell = 0,
		priceBuy = 45
	},
	[2262] = {
		clientId = 3149,
		name = "energy bomb rune",
		priceSell = 0,
		priceBuy = 325
	},
	[2277] = {
		clientId = 3164,
		name = "energy field rune",
		priceSell = 0,
		priceBuy = 115
	},
	[2279] = {
		clientId = 3166,
		name = "energy wall rune",
		priceSell = 0,
		priceBuy = 340
	},
	[2292] = {
		clientId = 3179,
		name = "envenom rune",
		priceSell = 0,
		priceBuy = 130
	},
	[2313] = {
		clientId = 3200,
		name = "explosion rune",
		priceSell = 0,
		priceBuy = 250
	},
	[2301] = {
		clientId = 3188,
		name = "fire field rune",
		priceSell = 0,
		priceBuy = 85
	},
	[2303] = {
		clientId = 3190,
		name = "fire wall rune",
		priceSell = 0,
		priceBuy = 245
	},
	[2302] = {
		clientId = 3189,
		name = "fireball rune",
		priceSell = 0,
		priceBuy = 95
	},
	[2305] = {
		clientId = 3192,
		name = "firebomb rune",
		priceSell = 0,
		priceBuy = 235
	},
	[2304] = {
		clientId = 3191,
		name = "great fireball rune",
		priceSell = 0,
		priceBuy = 180
	},
	[2311] = {
		clientId = 3198,
		name = "heavy magic missile rune",
		priceSell = 0,
		priceBuy = 125
	},
	[2265] = {
		clientId = 3152,
		name = "intense healing rune",
		priceSell = 0,
		priceBuy = 95
	},
	[2287] = {
		clientId = 3174,
		name = "light magic missile rune",
		priceSell = 0,
		priceBuy = 40
	},
	[2293] = {
		clientId = 3180,
		name = "magic wall rune",
		priceSell = 0,
		priceBuy = 350
	},
	[2278] = {
		clientId = 3165,
		name = "paralyze rune",
		priceSell = 0,
		priceBuy = 700
	},
	[2286] = {
		clientId = 3173,
		name = "poison bomb rune",
		priceSell = 0,
		priceBuy = 170
	},
	[2285] = {
		clientId = 3172,
		name = "poison field rune",
		priceSell = 0,
		priceBuy = 65
	},
	[2289] = {
		clientId = 3176,
		name = "poison wall rune",
		priceSell = 0,
		priceBuy = 210
	},
	[2308] = {
		clientId = 3195,
		name = "soulfire rune",
		priceSell = 0,
		priceBuy = 210
	},
	[2268] = {
		clientId = 3155,
		name = "sudden death rune",
		priceSell = 0,
		priceBuy = 325
	},
	[2273] = {
		clientId = 3160,
		name = "ultimate healing rune",
		priceSell = 0,
		priceBuy = 175
	},

	-------Backpack and Bags--------
	[1987] = {
		clientId = 2853,
		name = "bag",
		priceSell = 0,
		priceBuy = 4
	},
	[1988] = {
		clientId = 2854,
		name = "backpack",
		priceSell = 0,
		priceBuy = 10
	},
	[1998] = {
		clientId = 2865,
		name = "green backpack",
		priceSell = 0,
		priceBuy = 20
	},
	[1999] = {
		clientId = 2866,
		name = "yellow backpack",
		priceSell = 0,
		priceBuy = 10
	},
	[2000] = {
		clientId = 2867,
		name = "red backpack",
		priceSell = 0,
		priceBuy = 20
	},
	[2001] = {
		clientId = 2868,
		name = "purple backpack",
		priceSell = 0,
		priceBuy = 20
	},
	[2002] = {
		clientId = 2869,
		name = "blue backpack",
		priceSell = 0,
		priceBuy = 20
	},
	[2003] = {
		clientId = 2870,
		name = "grey backpack",
		priceSell = 0,
		priceBuy = 10
	},
	[2004] = {
		clientId = 2871,
		name = "golden backpack",
		priceSell = 0,
		priceBuy = 10
	},
	-------ammunition--------
	[2543] = {
		clientId = 3446,
		name = "bolt",
		priceSell = 0,
		priceBuy = 4
	},
	[2544] = {
		clientId = 3447,
		name = "arrow",
		priceSell = 0,
		priceBuy = 2
	},
	[2545] = {
		clientId = 3448,
		name = "poison arrow",
		priceSell = 0,
		priceBuy = 1
	},
	[2546] = {
		clientId = 3449,
		name = "burst arrow",
		priceSell = 0,
		priceBuy = 15
	},
	[2547] = {
		clientId = 3450,
		name = "power bolt",
		priceSell = 0,
		priceBuy = 7
	},
	[5091] = {
		clientId = 5091,
		name = "bolt quiver",
		priceSell = 800,
		priceBuy = 0
	},
	[5490] = {
		clientId = 5634,
		name = "bolt quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5491] = {
		clientId = 5638,
		name = "bolt quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5492] = {
		clientId = 5640,
		name = "bolt quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5487] = {
		clientId = 5633,
		name = "arrow quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5488] = {
		clientId = 5637,
		name = "arrow quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5489] = {
		clientId = 5639,
		name = "arrow quiver",
		priceSell = 0,
		priceBuy = 0
	},
	[5090] = {
		clientId = 5090,
		name = "arrow quiver",
		priceSell = 800,
		priceBuy = 0
	},
	[5493] = {
		clientId = 5628,
		name = "hunting bolt",
		priceSell = 8,
		priceBuy = 8
	},
	[5494] = {
		clientId = 5616,
		name = "hunting arrow",
		priceSell = 6,
		priceBuy = 6
	},
    ----------Axe---------
	[2386] = {
		clientId = 3274,
		name = "axe",
		priceSell = 6,
		priceBuy = 20
	},
	[2429] = {
		clientId = 3317,
		name = "barbarian axe",
		priceSell = 590,
		priceBuy = 185
	},
	[2378] = {
		clientId = 3266,
		name = "battle axe",
		priceSell = 470,
		priceBuy = 160
	},
	[2441] = {
		clientId = 3329,
		name = "daramanian axe",
		priceSell = 0,
		priceBuy = 0
	},
	[2440] = {
		clientId = 3328,
		name = "daramanian waraxe",
		priceSell = 2000,
		priceBuy = 0
	},
	[2387] = {
		clientId = 3275,
		name = "double axe",
		priceSell = 520,
		priceBuy = 0
	},
	[2414] = {
		clientId = 3302,
		name = "dragon lance",
		priceSell = 18000,
		priceBuy = 0
	},
	[2435] = {
		clientId = 3323,
		name = "dwarven axe",
		priceSell = 900,
		priceBuy = 0
	},
	[2432] = {
		clientId = 3320,
		name = "fire axe",
		priceSell = 8000,
		priceBuy = 0
	},
	[2418] = {
		clientId = 3306,
		name = "golden sickle",
		priceSell = 10,
		priceBuy = 0
	},
	[2415] = {
		clientId = 3303,
		name = "great axe",
		priceSell = 600,
		priceBuy = 0
	},
	[2427] = {
		clientId = 3315,
		name = "guardian halberd",
		priceSell = 22000,
		priceBuy = 0
	},
	[2381] = {
		clientId = 3269,
		name = "halberd",
		priceSell = 800,
		priceBuy = 0
	},
	[2380] = {
		clientId = 3268,
		name = "hand axe",
		priceSell = 5,
		priceBuy = 8
	},
	[2388] = {
		clientId = 3276,
		name = "hatchet",
		priceSell = 25,
		priceBuy = 85
	},
	[2430] = {
		clientId = 3318,
		name = "knight axe",
		priceSell = 2000,
		priceBuy = 0
	},
	[2426] = {
		clientId = 3314,
		name = "naginata",
		priceSell = 4000,
		priceBuy = 0
	},
	[2425] = {
		clientId = 3313,
		name = "obsidian lance",
		priceSell = 1000,
		priceBuy = 6000
	},
	[2428] = {
		clientId = 3316,
		name = "orcish axe",
		priceSell = 300,
		priceBuy = 0
	},
	[2443] = {
		clientId = 3331,
		name = "ravagers axe",
		priceSell = 80000,
		priceBuy = 0
	},
	[2405] = {
		clientId = 3293,
		name = "sickle",
		priceSell = 3,
		priceBuy = 8
	},
	[2431] = {
		clientId = 3319,
		name = "stonecutter axe",
		priceSell = 300000,
		priceBuy = 0
	},
	[2447] = {
		clientId = 3335,
		name = "twin axe",
		priceSell = 20000,
		priceBuy = 0
	},
	[2454] = {
		clientId = 3342,
		name = "war axe",
		priceSell = 24000,
		priceBuy = 0
	},
    ----------Armors---------
	[2500] = {
		clientId = 3394,
		name = "amazon armor",
		priceSell = 55000,
		priceBuy = 0
	},
	[2659] = {
		clientId = 3570,
		name = "ball gown",
		priceSell = 0,
		priceBuy = 0
	},
	[2656] = {
		clientId = 3567,
		name = "blue robe",
		priceSell = 10000,
		priceBuy = 0
	},
	[2465] = {
		clientId = 3359,
		name = "brass armor",
		priceSell = 150,
		priceBuy = 450
	},
	[2654] = {
		clientId = 3565,
		name = "cape",
		priceSell = 0,
		priceBuy = 9
	},
	[2464] = {
		clientId = 3358,
		name = "chain armor",
		priceSell = 70,
		priceBuy = 200
	},
	[2651] = {
		clientId = 3562,
		name = "coat",
		priceSell = 1,
		priceBuy = 8
	},
	[2487] = {
		clientId = 3381,
		name = "crown armor",
		priceSell = 12000,
		priceBuy = 0
	},
	[2489] = {
		clientId = 3383,
		name = "dark armor",
		priceSell = 400,
		priceBuy = 1500
	},
	[2494] = {
		clientId = 3388,
		name = "demon armor",
		priceSell = 300000,
		priceBuy = 0
	},
	[2485] = {
		clientId = 3379,
		name = "doublet",
		priceSell = 3,
		priceBuy = 16
	},
	[2492] = {
		clientId = 3386,
		name = "dragon scale mail",
		priceSell = 40000,
		priceBuy = 0
	},
	[2503] = {
		clientId = 3397,
		name = "dwarven armor",
		priceSell = 30000,
		priceBuy = 0
	},
	[2505] = {
		clientId = 3399,
		name = "elven mail",
		priceSell = 0,
		priceBuy = 0
	},
	[2466] = {
		clientId = 3360,
		name = "golden armor",
		priceSell = 20000,
		priceBuy = 0
	},
	[2652] = {
		clientId = 3563,
		name = "green tunic",
		priceSell = 0,
		priceBuy = 10
	},
	[2650] = {
		clientId = 3561,
		name = "jacket",
		priceSell = 1,
		priceBuy = 10
	},
	[2476] = {
		clientId = 3370,
		name = "knight armor",
		priceSell = 5000,
		priceBuy = 0
	},
	[2467] = {
		clientId = 3361,
		name = "leather armor",
		priceSell = 12,
		priceBuy = 25
	},
	[2472] = {
		clientId = 3366,
		name = "magic plate armor",
		priceSell = 140000,
		priceBuy = 0
	},
	[2508] = {
		clientId = 3402,
		name = "native armor",
		priceSell = 0,
		priceBuy = 0
	},
	[2486] = {
		clientId = 3380,
		name = "noble armor",
		priceSell = 900,
		priceBuy = 8000
	},
	[2463] = {
		clientId = 3357,
		name = "plate armor",
		priceSell = 400,
		priceBuy = 1200
	},
	[2660] = {
		clientId = 3571,
		name = "ranger's cloak",
		priceSell = 0,
		priceBuy = 0
	},
	[2655] = {
		clientId = 3566,
		name = "red robe",
		priceSell = 45000,
		priceBuy = 0
	},
	[2653] = {
		clientId = 3564,
		name = "red tunic",
		priceSell = 0,
		priceBuy = 0
	},
	[2483] = {
		clientId = 3377,
		name = "scale armor",
		priceSell = 75,
		priceBuy = 260
	},
	[2657] = {
		clientId = 3568,
		name = "simple dress",
		priceSell = 0,
		priceBuy = 0
	},
	[4847] = {
		clientId = 4836,
		name = "spectral dress",
		priceSell = 0,
		priceBuy = 0
	},
	[2484] = {
		clientId = 3378,
		name = "studded armor",
		priceSell = 18,
		priceBuy = 90
	},
	[2658] = {
		clientId = 3569,
		name = "white dress",
		priceSell = 0,
		priceBuy = 0
	},
	----------Clubs---------
	[2453] = {
		clientId = 3341,
		name = "arcane staff",
		priceSell = 86000,
		priceBuy = 0
	},
	[2417] = {
		clientId = 3305,
		name = "battle hammer",
		priceSell = 120,
		priceBuy = 350
	},
	[2449] = {
		clientId = 3337,
		name = "bone club",
		priceSell = 0,
		priceBuy = 0
	},
	[2423] = {
		clientId = 3311,
		name = "clerical mace",
		priceSell = 170,
		priceBuy = 540
	},
	[2382] = {
		clientId = 3270,
		name = "club",
		priceSell = 1,
		priceBuy = 5
	},
	[2416] = {
		clientId = 3304,
		name = "crowbar",
		priceSell = 50,
		priceBuy = 260
	},
	[2445] = {
		clientId = 3333,
		name = "crystal mace",
		priceSell = 12000,
		priceBuy = 0
	},
	[2439] = {
		clientId = 3327,
		name = "daramanian mace",
		priceSell = 0,
		priceBuy = 0
	},
	[2434] = {
		clientId = 3322,
		name = "dragon hammer",
		priceSell = 2000,
		priceBuy = 0
	},
	[2433] = {
		clientId = 3321,
		name = "enchanted staff",
		priceSell = 0,
		priceBuy = 0
	},
	[2321] = {
		clientId = 3208,
		name = "giant smithhammer",
		priceSell = 0,
		priceBuy = 0
	},
	[2444] = {
		clientId = 3332,
		name = "hammer of wrath",
		priceSell = 60000,
		priceBuy = 0
	},
	[2452] = {
		clientId = 3340,
		name = "heavy mace",
		priceSell = 100000,
		priceBuy = 0
	},
	[2422] = {
		clientId = 3310,
		name = "iron hammer",
		priceSell = 0,
		priceBuy = 9
	},
	[2437] = {
		clientId = 3325,
		name = "light mace",
		priceSell = 0,
		priceBuy = 0
	},
	[2398] = {
		clientId = 3286,
		name = "mace",
		priceSell = 30,
		priceBuy = 90
	},
	[2394] = {
		clientId = 3282,
		name = "morning star",
		priceSell = 100,
		priceBuy = 430
	},
	[2550] = {
		clientId = 3453,
		name = "scythe",
		priceSell = 0,
		priceBuy = 0
	},
	[2424] = {
		clientId = 3312,
		name = "silver mace",
		priceSell = 12000,
		priceBuy = 0
	},
	[2436] = {
		clientId = 3324,
		name = "skull staff",
		priceSell = 6000,
		priceBuy = 0
	},
	[2401] = {
		clientId = 3289,
		name = "staff",
		priceSell = 2,
		priceBuy = 80
	},
	[2448] = {
		clientId = 3336,
		name = "studded club",
		priceSell = 0,
		priceBuy = 0
	},
	[2421] = {
		clientId = 3309,
		name = "thunder hammer",
		priceSell = 400000,
		priceBuy = 0
	},
	[2391] = {
		clientId = 3279,
		name = "war hammer",
		priceSell = 2400,
		priceBuy = 20000
	},
	----------Distance---------
	[2456] = {
		clientId = 3350,
		name = "bow",
		priceSell = 130,
		priceBuy = 350
	},
	[5484] = {
		clientId = 5625,
		name = "modified bow",
		priceSell = 0,
		priceBuy = 0
	},
	[5485] = {
		clientId = 3350,
		name = "elven bow",
		priceSell = 0,
		priceBuy = 0
	},
	[5486] = {
		clientId = 5631,
		name = "sacred bow",
		priceSell = 0,
		priceBuy = 0
	},
	[2455] = {
		clientId = 3349,
		name = "crossbow",
		priceSell = 160,
		priceBuy = 450
	},
	[5481] = {
		clientId = 5613,
		name = "modified crossbow",
		priceSell = 0,
		priceBuy = 0
	},
	[5482] = {
		clientId = 5615,
		name = "elven crossbow",
		priceSell = 160,
		priceBuy = 450
	},
	[5483] = {
		clientId = 5627,
		name = "sacred crossbow",
		priceSell = 160,
		priceBuy = 450
	},
	[1294] = {
		clientId = 1781,
		name = "small stone",
		priceSell = 0,
		priceBuy = 0
	},
	[2111] = {
		clientId = 2992,
		name = "snowball",
		priceSell = 0,
		priceBuy = 0
	},
	[2389] = {
		clientId = 3277,
		name = "spear",
		priceSell = 3,
		priceBuy = 10
	},
	[2410] = {
		clientId = 3298,
		name = "throwing knife",
		priceSell = 2,
		priceBuy = 25
	},
	[2399] = {
		clientId = 3287,
		name = "throwing star",
		priceSell = 2,
		priceBuy = 50
	},	
	----------Boots---------
	[2195] = {
		clientId = 3079,
		name = "boots of haste",
		priceSell = 30000,
		priceBuy = 0
	},
	[2358] = {
		clientId = 3246,
		name = "boots of waterwalking",
		priceSell = 0,
		priceBuy = 0
	},
	[2644] = {
		clientId = 3553,
		name = "bunnyslippers",
		priceSell = 0,
		priceBuy = 0
	},
	[2646] = {
		clientId = 3555,
		name = "golden boots",
		priceSell = 0,
		priceBuy = 0
	},
	[2643] = {
		clientId = 3552,
		name = "leather boots",
		priceSell = 2,
		priceBuy = 2
	},
	[2641] = {
		clientId = 3550,
		name = "patched boots",
		priceSell = 0,
		priceBuy = 0
	},
	[2642] = {
		clientId = 3551,
		name = "sandals",
		priceSell = 0,
		priceBuy = 2
	},
	[2640] = {
		clientId = 3549,
		name = "soft boots",
		priceSell = 0,
		priceBuy = 0
	},
	[2645] = {
		clientId = 3554,
		name = "steel boots",
		priceSell = 30000,
		priceBuy = 0
	},	
	----------Food---------
	[2676] = {
		clientId = 3587,
		name = "banana",
		priceSell = 0,
		priceBuy = 2
	},
	[2677] = {
		clientId = 3588,
		name = "blueberry",
		priceSell = 0,
		priceBuy = 1
	},
	[2689] = {
		clientId = 3600,
		name = "bread",
		priceSell = 2,
		priceBuy = 3
	},
	[2691] = {
		clientId = 3602,
		name = "brown bread",
		priceSell = 0,
		priceBuy = 3
	},
	[2789] = {
		clientId = 3725,
		name = "brown mushroom",
		priceSell = 0,
		priceBuy = 10
	},
	[2688] = {
		clientId = 3599,
		name = "candy cane",
		priceSell = 0,
		priceBuy = 0
	},
	[2684] = {
		clientId = 3595,
		name = "carrot",
		priceSell = 0,
		priceBuy = 2
	},
	[2696] = {
		clientId = 3607,
		name = "cheese",
		priceSell = 2,
		priceBuy = 5
	},
	[2679] = {
		clientId = 3590,
		name = "cherry",
		priceSell = 0,
		priceBuy = 1
	},
	[2678] = {
		clientId = 3589,
		name = "coconut",
		priceSell = 0,
		priceBuy = 0
	},
	[2687] = {
		clientId = 3598,
		name = "cookie",
		priceSell = 0,
		priceBuy = 2
	},
	[2686] = {
		clientId = 3597,
		name = "corncob",
		priceSell = 0,
		priceBuy = 0
	},
	[2792] = {
		clientId = 3728,
		name = "dark mushroom",
		priceSell = 0,
		priceBuy = 0
	},
	[2672] = {
		clientId = 3583,
		name = "dragon ham",
		priceSell = 0,
		priceBuy = 25
	},
	[2695] = {
		clientId = 3606,
		name = "egg",
		priceSell = 0,
		priceBuy = 2
	},
	[2667] = {
		clientId = 3578,
		name = "fish",
		priceSell = 0,
		priceBuy = 5
	},
	[2669] = {
		clientId = 3580,
		name = "fish",
		priceSell = 0,
		priceBuy = 5
	},
	[2681] = {
		clientId = 3592,
		name = "grapes",
		priceSell = 0,
		priceBuy = 0
	},
	[2671] = {
		clientId = 3582,
		name = "ham",
		priceSell = 4,
		priceBuy = 6
	},
	[2666] = {
		clientId = 3577,
		name = "meat",
		priceSell = 2,
		priceBuy = 4
	},
	[2682] = {
		clientId = 3593,
		name = "melon",
		priceSell = 0,
		priceBuy = 8
	},
	[2675] = {
		clientId = 3586,
		name = "orange",
		priceSell = 0,
		priceBuy = 5
	},
	[2790] = {
		clientId = 3726,
		name = "orange mushroom",
		priceSell = 0,
		priceBuy = 0
	},
	[2673] = {
		clientId = 3584,
		name = "pear",
		priceSell = 0,
		priceBuy = 4
	},
	[2683] = {
		clientId = 3594,
		name = "pumpkin",
		priceSell = 0,
		priceBuy = 10
	},
	[2674] = {
		clientId = 3585,
		name = "red apple",
		priceSell = 0,
		priceBuy = 3
	},
	[2788] = {
		clientId = 3724,
		name = "red mushroom",
		priceSell = 0,
		priceBuy = 12
	},
	[2690] = {
		clientId = 3601,
		name = "roll",
		priceSell = 0,
		priceBuy = 2
	},
	[2668] = {
		clientId = 3579,
		name = "salmon",
		priceSell = 2,
		priceBuy = 4
	},
	[2670] = {
		clientId = 3581,
		name = "shrimp",
		priceSell = 0,
		priceBuy = 0
	},
	[2680] = {
		clientId = 3591,
		name = "strawberry",
		priceSell = 0,
		priceBuy = 1
	},
	[2362] = {
		clientId = 3250,
		name = "the carrot of doom",
		priceSell = 0,
		priceBuy = 0
	},
	[2685] = {
		clientId = 3596,
		name = "tomato",
		priceSell = 0,
		priceBuy = 5
	},
	[2787] = {
		clientId = 3723,
		name = "white mushroom",
		priceSell = 0,
		priceBuy = 6
	},	
	----------Helmet---------
	[2499] = {
		clientId = 3393,
		name = "amazon helmet",
		priceSell = 45000,
		priceBuy = 0
	},
	[2139] = {
		clientId = 3022,
		name = "ancient tiara",
		priceSell = 0,
		priceBuy = 0
	},
	[2460] = {
		clientId = 3354,
		name = "brass helmet",
		priceSell = 30,
		priceBuy = 120
	},
	[2501] = {
		clientId = 3395,
		name = "ceremonial mask",
		priceSell = 55000,
		priceBuy = 0
	},
	[2458] = {
		clientId = 3352,
		name = "chain helmet",
		priceSell = 17,
		priceBuy = 52
	},
	[2128] = {
		clientId = 3011,
		name = "crown",
		priceSell = 0,
		priceBuy = 0
	},
	[2491] = {
		clientId = 3385,
		name = "crown helmet",
		priceSell = 2500,
		priceBuy = 0
	},
	[2497] = {
		clientId = 3391,
		name = "crusader helmet",
		priceSell = 6000,
		priceBuy = 0
	},
	[2339] = {
		clientId = 3226,
		name = "damaged helmet",
		priceSell = 0,
		priceBuy = 0
	},
	[2490] = {
		clientId = 3384,
		name = "dark helmet",
		priceSell = 250,
		priceBuy = 1000
	},
	[2493] = {
		clientId = 3387,
		name = "demon helmet",
		priceSell = 125000,
		priceBuy = 0
	},
	[2462] = {
		clientId = 3356,
		name = "devil helmet",
		priceSell = 1000,
		priceBuy = 0
	},
	[2506] = {
		clientId = 3400,
		name = "dragon scale helmet",
		priceSell = 0,
		priceBuy = 0
	},
	[2502] = {
		clientId = 3396,
		name = "dwarven helmet",
		priceSell = 0,
		priceBuy = 0
	},
	[2471] = {
		clientId = 3365,
		name = "golden helmet",
		priceSell = 420,
		priceBuy = 0
	},
	[2323] = {
		clientId = 3210,
		name = "hat of the mad",
		priceSell = 0,
		priceBuy = 0
	},
	[2342] = {
		clientId = 3229,
		name = "helmet of the ancients",
		priceSell = 0,
		priceBuy = 0
	},
	[2343] = {
		clientId = 3230,
		name = "helmet of the ancients",
		priceSell = 0,
		priceBuy = 0
	},
	[2496] = {
		clientId = 3390,
		name = "horned helmet",
		priceSell = 175000,
		priceBuy = 0
	},
	[2459] = {
		clientId = 3353,
		name = "iron helmet",
		priceSell = 150,
		priceBuy = 390
	},
	[2461] = {
		clientId = 3355,
		name = "leather helmet",
		priceSell = 4,
		priceBuy = 12
	},
	[2480] = {
		clientId = 3374,
		name = "legion helmet",
		priceSell = 8,
		priceBuy = 0
	},
	[2662] = {
		clientId = 3573,
		name = "magician hat",
		priceSell = 0,
		priceBuy = 0
	},
	[2663] = {
		clientId = 3574,
		name = "mystic turban",
		priceSell = 150,
		priceBuy = 0
	},
	[2665] = {
		clientId = 3576,
		name = "post officer's hat",
		priceSell = 0,
		priceBuy = 0
	},
	[2498] = {
		clientId = 3392,
		name = "royal helmet",
		priceSell = 30000,
		priceBuy = 0
	},
	[2481] = {
		clientId = 3375,
		name = "soldier helmet",
		priceSell = 16,
		priceBuy = 110
	},
	[2457] = {
		clientId = 3351,
		name = "steel helmet",
		priceSell = 293,
		priceBuy = 580
	},
	[2479] = {
		clientId = 3373,
		name = "strange helmet",
		priceSell = 500,
		priceBuy = 0
	},
	[2482] = {
		clientId = 3376,
		name = "studded helmet",
		priceSell = 20,
		priceBuy = 60
	},
	[2473] = {
		clientId = 3367,
		name = "viking helmet",
		priceSell = 66,
		priceBuy = 265
	},
	[2475] = {
		clientId = 3369,
		name = "warrior helmet",
		priceSell = 5000,
		priceBuy = 0
	},
	[2474] = {
		clientId = 3368,
		name = "winged helmet",
		priceSell = 150000,
		priceBuy = 0
	},
	[2664] = {
		clientId = 3575,
		name = "wood cape",
		priceSell = 0,
		priceBuy = 0
	},	
	----------Legs---------
	[2478] = {
    clientId = 3372,
    name = "brass legs",
    priceSell = 49,
    priceBuy = 195
},
[2648] = {
    clientId = 3558,
    name = "chain legs",
    priceSell = 25,
    priceBuy = 80
},
[2488] = {
    clientId = 3382,
    name = "crown legs",
    priceSell = 12000,
    priceBuy = 0
},
[2495] = {
    clientId = 3389,
    name = "demon legs",
    priceSell = 400000,
    priceBuy = 0
},
[2469] = {
    clientId = 3363,
    name = "dragon scale legs",
    priceSell = 0,
    priceBuy = 0
},
[2504] = {
    clientId = 3398,
    name = "dwarven legs",
    priceSell = 40000,
    priceBuy = 0
},
[2507] = {
    clientId = 3401,
    name = "elven legs",
    priceSell = 0,
    priceBuy = 0
},
[2470] = {
    clientId = 3364,
    name = "golden legs",
    priceSell = 70000,
    priceBuy = 0
},
[2477] = {
    clientId = 3371,
    name = "knight legs",
    priceSell = 5000,
    priceBuy = 0
},
[2649] = {
    clientId = 3559,
    name = "leather legs",
    priceSell = 1,
    priceBuy = 10
},
[2647] = {
    clientId = 3557,
    name = "plate legs",
    priceSell = 400,
    priceBuy = 0
},
[2468] = {
    clientId = 3362,
    name = "studded legs",
    priceSell = 15,
    priceBuy = 60
},
	----------Amulets---------
	[2173] = {
    clientId = 3057,
    name = "amulet of loss",
    priceSell = 0,
    priceBuy = 50000
},
[2142] = {
    clientId = 3025,
    name = "ancient amulet",
    priceSell = 200,
    priceBuy = 0
},
[2196] = {
    clientId = 3080,
    name = "broken amulet",
    priceSell = 0,
    priceBuy = 0
},
[2172] = {
    clientId = 3056,
    name = "bronze amulet",
    priceSell = 50,
    priceBuy = 0
},
[2126] = {
    clientId = 3009,
    name = "bronze necklace",
    priceSell = 0,
    priceBuy = 0
},
[2125] = {
    clientId = 3008,
    name = "crystal necklace",
    priceSell = 0,
    priceBuy = 0
},
[2136] = {
    clientId = 3019,
    name = "demonbone amulet",
    priceSell = 0,
    priceBuy = 0
},
[2201] = {
    clientId = 3085,
    name = "dragon necklace",
    priceSell = 100,
    priceBuy = 0
},
[2198] = {
    clientId = 3082,
    name = "elven amulet",
    priceSell = 100,
    priceBuy = 0
},
[2199] = {
    clientId = 3083,
    name = "garlic necklace",
    priceSell = 50,
    priceBuy = 0
},
[2130] = {
    clientId = 3013,
    name = "golden amulet",
    priceSell = 6600,
    priceBuy = 0
},
[2218] = {
    clientId = 3102,
    name = "paw amulet",
    priceSell = 0,
    priceBuy = 0
},
[2171] = {
    clientId = 3055,
    name = "platinum amulet",
    priceSell = 2500,
    priceBuy = 0
},
[2200] = {
    clientId = 3084,
    name = "protection amulet",
    priceSell = 100,
    priceBuy = 700
},
[2133] = {
    clientId = 3016,
    name = "ruby necklace",
    priceSell = 3560,
    priceBuy = 2000
},
[2138] = {
    clientId = 3021,
    name = "sapphire amulet",
    priceSell = 0,
    priceBuy = 0
},
[2135] = {
    clientId = 3018,
    name = "scarab amulet",
    priceSell = 200,
    priceBuy = 0
},
[2661] = {
    clientId = 3572,
    name = "scarf",
    priceSell = 0,
    priceBuy = 15
},
[2170] = {
    clientId = 3054,
    name = "silver amulet",
    priceSell = 50,
    priceBuy = 0
},
[2132] = {
    clientId = 3015,
    name = "silver necklace",
    priceSell = 0,
    priceBuy = 0
},
[2131] = {
    clientId = 3014,
    name = "star amulet",
    priceSell = 0,
    priceBuy = 0
},
[2197] = {
    clientId = 3081,
    name = "stone skin amulet",
    priceSell = 500,
    priceBuy = 10000
},
[2161] = {
    clientId = 3045,
    name = "strange talisman",
    priceSell = 30,
    priceBuy = 0
},
[2129] = {
    clientId = 3012,
    name = "wolf tooth chain",
    priceSell = 0,
    priceBuy = 0
},
	----------Rings---------
	[2208] = {
    clientId = 3092,
    name = "axe ring",
    priceSell = 100,
    priceBuy = 500
},
[2209] = {
    clientId = 3093,
    name = "club ring",
    priceSell = 100,
    priceBuy = 500
},
[2124] = {
    clientId = 3007,
    name = "crystal ring",
    priceSell = 250,
    priceBuy = 0
},
[2213] = {
    clientId = 3097,
    name = "dwarven ring",
    priceSell = 100,
    priceBuy = 2000
},
[2167] = {
    clientId = 3051,
    name = "energy ring",
    priceSell = 100,
    priceBuy = 2000
},
[2179] = {
    clientId = 3063,
    name = "gold ring",
    priceSell = 8000,
    priceBuy = 0
},
[2168] = {
    clientId = 3052,
    name = "life ring",
    priceSell = 50,
    priceBuy = 900
},
[2164] = {
    clientId = 3048,
    name = "might ring",
    priceSell = 250,
    priceBuy = 0
},
[2166] = {
    clientId = 3050,
    name = "power ring",
    priceSell = 50,
    priceBuy = 100
},
[2214] = {
    clientId = 3098,
    name = "ring of healing",
    priceSell = 100,
    priceBuy = 2000
},
[2123] = {
    clientId = 3006,
    name = "ring of the sky",
    priceSell = 30000,
    priceBuy = 0
},
[2357] = {
    clientId = 3245,
    name = "ring of wishes",
    priceSell = 0,
    priceBuy = 0
},
[2165] = {
    clientId = 3049,
    name = "stealth ring",
    priceSell = 200,
    priceBuy = 5000
},
[2207] = {
    clientId = 3091,
    name = "sword ring",
    priceSell = 100,
    priceBuy = 500
},
[2169] = {
    clientId = 3053,
    name = "time ring",
    priceSell = 100,
    priceBuy = 2000
},
[2121] = {
    clientId = 3004,
    name = "wedding ring",
    priceSell = 0,
    priceBuy = 990
},
	----------Shields---------
	[2537] = {
    clientId = 3437,
    name = "amazon shield",
    priceSell = 50000,
    priceBuy = 0
},
[2532] = {
    clientId = 3432,
    name = "ancient shield",
    priceSell = 900,
    priceBuy = 5000
},
[2513] = {
    clientId = 3413,
    name = "battle shield",
    priceSell = 95,
    priceBuy = 0
},
[2518] = {
    clientId = 3418,
    name = "beholder shield",
    priceSell = 1200,
    priceBuy = 7000
},
[2529] = {
    clientId = 3429,
    name = "black shield",
    priceSell = 800,
    priceBuy = 0
},
[2523] = {
    clientId = 3423,
    name = "blessed shield",
    priceSell = 650,
    priceBuy = 0
},
[2541] = {
    clientId = 3441,
    name = "bone shield",
    priceSell = 0,
    priceBuy = 0
},
[2511] = {
    clientId = 3411,
    name = "brass shield",
    priceSell = 25,
    priceBuy = 65
},
[2535] = {
    clientId = 3435,
    name = "castle shield",
    priceSell = 5000,
    priceBuy = 0
},
[2530] = {
    clientId = 3430,
    name = "copper shield",
    priceSell = 50,
    priceBuy = 0
},
[2519] = {
    clientId = 3419,
    name = "crown shield",
    priceSell = 8000,
    priceBuy = 0
},
[2521] = {
    clientId = 3421,
    name = "dark shield",
    priceSell = 400,
    priceBuy = 0
},
[2520] = {
    clientId = 3420,
    name = "demon shield",
    priceSell = 30000,
    priceBuy = 0
},
[2516] = {
    clientId = 3416,
    name = "dragon shield",
    priceSell = 4000,
    priceBuy = 0
},
[2525] = {
    clientId = 3425,
    name = "dwarven shield",
    priceSell = 100,
    priceBuy = 500
},
[2538] = {
    clientId = 3438,
    name = "eagle shield",
    priceSell = 0,
    priceBuy = 0
},
[2522] = {
    clientId = 3422,
    name = "great shield",
    priceSell = 175000,
    priceBuy = 0
},
[2533] = {
    clientId = 3433,
    name = "griffin shield",
    priceSell = 59,
    priceBuy = 0
},
[2515] = {
    clientId = 3415,
    name = "guardian shield",
    priceSell = 2000,
    priceBuy = 0
},
[2514] = {
    clientId = 3414,
    name = "mastermind shield",
    priceSell = 80000,
    priceBuy = 0
},
[2536] = {
    clientId = 3436,
    name = "medusa shield",
    priceSell = 9000,
    priceBuy = 0
},
[2524] = {
    clientId = 3424,
    name = "ornamented shield",
    priceSell = 45,
    priceBuy = 0
},
[2539] = {
    clientId = 3439,
    name = "phoenix shield",
    priceSell = 16000,
    priceBuy = 0
},
[2510] = {
    clientId = 3410,
    name = "plate shield",
    priceSell = 45,
    priceBuy = 125
},
[2527] = {
    clientId = 3427,
    name = "rose shield",
    priceSell = 49,
    priceBuy = 0
},
[2540] = {
    clientId = 3440,
    name = "scarab shield",
    priceSell = 2000,
    priceBuy = 0
},
[2517] = {
    clientId = 3417,
    name = "shield of honour",
    priceSell = 0,
    priceBuy = 0
},
[2509] = {
    clientId = 3409,
    name = "steel shield",
    priceSell = 80,
    priceBuy = 240
},
[2526] = {
    clientId = 3426,
    name = "studded shield",
    priceSell = 16,
    priceBuy = 50
},
[2542] = {
    clientId = 3442,
    name = "tempest shield",
    priceSell = 35000,
    priceBuy = 0
},
[2528] = {
    clientId = 3428,
    name = "tower shield",
    priceSell = 8000,
    priceBuy = 0
},
[2534] = {
    clientId = 3434,
    name = "vampire shield",
    priceSell = 15000,
    priceBuy = 0
},
[2531] = {
    clientId = 3431,
    name = "viking shield",
    priceSell = 85,
    priceBuy = 260
},
[2512] = {
    clientId = 3412,
    name = "wooden shield",
    priceSell = 5,
    priceBuy = 15
},
	----------Swords---------
	[2450] = {
		clientId = 3338,
		name = "bone sword",
		priceSell = 0,
		priceBuy = 0
	},
	[2407] = {
		clientId = 3295,
		name = "bright sword",
		priceSell = 6000,
		priceBuy = 0
	},
	[2413] = {
		clientId = 3301,
		name = "broadsword",
		priceSell = 1000,
		priceBuy = 0
	},
	[2395] = {
		clientId = 3283,
		name = "carlin sword",
		priceSell = 118,
		priceBuy = 473
	},
	[2404] = {
		clientId = 3292,
		name = "combat knife",
		priceSell = 1,
		priceBuy = 0
	},
	[2379] = {
		clientId = 3267,
		name = "dagger",
		priceSell = 2,
		priceBuy = 5
	},
	[2451] = {
		clientId = 3339,
		name = "djinn blade",
		priceSell = 15000,
		priceBuy = 0
	},
	[2392] = {
		clientId = 3280,
		name = "fire sword",
		priceSell = 4000,
		priceBuy = 0
	},
	[2438] = {
		clientId = 3326,
		name = "foil",
		priceSell = 0,
		priceBuy = 0
	},
	[2393] = {
		clientId = 3281,
		name = "giant sword",
		priceSell = 34000,
		priceBuy = 0
	},
	[2442] = {
		clientId = 3330,
		name = "heavy machete",
		priceSell = 0,
		priceBuy = 0
	},
	[2396] = {
		clientId = 3284,
		name = "ice rapier",
		priceSell = 1000,
		priceBuy = 5000
	},
	[2412] = {
		clientId = 3300,
		name = "katana",
		priceSell = 0,
		priceBuy = 8
	},
	[2403] = {
		clientId = 3291,
		name = "knife",
		priceSell = 1,
		priceBuy = 0
	},
	[2397] = {
		clientId = 3285,
		name = "longsword",
		priceSell = 51,
		priceBuy = 160
	},
	[2420] = {
		clientId = 3308,
		name = "machete",
		priceSell = 6,
		priceBuy = 35
	},
	[2390] = {
		clientId = 3278,
		name = "magic longsword",
		priceSell = 920,
		priceBuy = 0
	},
	[2400] = {
		clientId = 3288,
		name = "magic sword",
		priceSell = 300000,
		priceBuy = 0
	},
	[2446] = {
		clientId = 3334,
		name = "pharaoh sword",
		priceSell = 23000,
		priceBuy = 0
	},
	[2411] = {
		clientId = 3299,
		name = "poison dagger",
		priceSell = 50,
		priceBuy = 0
	},
	[2384] = {
		clientId = 3272,
		name = "rapier",
		priceSell = 5,
		priceBuy = 15
	},
	[2385] = {
		clientId = 3273,
		name = "sabre",
		priceSell = 12,
		priceBuy = 25
	},
	[2419] = {
		clientId = 3307,
		name = "scimitar",
		priceSell = 150,
		priceBuy = 0
	},
	[2409] = {
		clientId = 3297,
		name = "serpent sword",
		priceSell = 900,
		priceBuy = 6000
	},
	[2406] = {
		clientId = 3294,
		name = "short sword",
		priceSell = 10,
		priceBuy = 30
	},
	[2402] = {
		clientId = 3290,
		name = "silver dagger",
		priceSell = 1,
		priceBuy = 0
	},
	[2383] = {
		clientId = 3271,
		name = "spike sword",
		priceSell = 1000,
		priceBuy = 8000
	},
	[2376] = {
		clientId = 3264,
		name = "sword",
		priceSell = 25,
		priceBuy = 85
	},
	[2377] = {
		clientId = 3265,
		name = "two handed sword",
		priceSell = 900,
		priceBuy = 1900
	},
	[2408] = {
		clientId = 3296,
		name = "warlord sword",
		priceSell = 720,
		priceBuy = 0
	},
	----------Tools---------
	[2551] = {
    clientId = 3454,
    name = "broom",
    priceSell = 0,
    priceBuy = 12
},
[2580] = {
    clientId = 3483,
    name = "fishing rod",
    priceSell = 40,
    priceBuy = 150
},
[2552] = {
    clientId = 3455,
    name = "hoe",
    priceSell = 0,
    priceBuy = 15
},
[2553] = {
    clientId = 3456,
    name = "pick",
    priceSell = 15,
    priceBuy = 50
},
[2548] = {
    clientId = 3451,
    name = "pitchfork",
    priceSell = 0,
    priceBuy = 25
},
[2549] = {
    clientId = 3452,
    name = "rake",
    priceSell = 0,
    priceBuy = 20
},
[2120] = {
    clientId = 3003,
    name = "rope",
    priceSell = 15,
    priceBuy = 50
},
[2558] = {
    clientId = 3461,
    name = "saw",
    priceSell = 0,
    priceBuy = 0
},
[2554] = {
    clientId = 3457,
    name = "shovel",
    priceSell = 8,
    priceBuy = 10
},
[2036] = {
    clientId = 2906,
    name = "watch",
    priceSell = 0,
    priceBuy = 0
},
	----------Potions---------
	[2006] = {
		clientId = 2874,
		name = "vial",
		priceSell = 5,
		priceBuy = 8,
		subTypes = {
			[1] = {
				clientId = 2874,
				name = "water",
				priceSell = 10,
				priceBuy = 15,
			},
			[2] = {
				clientId = 2874,
				name = "wine",
				priceSell = 20,
				priceBuy = 25,
			},
			[3] = {
				clientId = 2874,
				name = "beer",
				priceSell = 30,
				priceBuy = 35,
			},
			[4] = {
				clientId = 2874,
				name = "mud",
				priceSell = 40,
				priceBuy = 45,
			},
			[5] = {
				clientId = 2874,
				name = "blood",
				priceSell = 50,
				priceBuy = 55,
			},
			[6] = {
				clientId = 2874,
				name = "slime",
				priceSell = 60,
				priceBuy = 65,
			},
			[7] = {
				clientId = 2874,
				name = "oil",
				priceSell = 70,
				priceBuy = 75,
			},
			[8] = {
				clientId = 2874,
				name = "urine",
				priceSell = 80,
				priceBuy = 85,
			},
			[9] = {
				clientId = 2874,
				name = "milk",
				priceSell = 90,
				priceBuy = 95,
			},
			[10] = {
				clientId = 2874,
				name = "mana fluid",
				priceSell = 0,
				priceBuy = 100,
			},
			[11] = {
				clientId = 2874,
				name = "life fluid",
				priceSell = 0,
				priceBuy = 60,
			},
			[12] = {
				clientId = 2874,
				name = "lemonade",
				priceSell = 120,
				priceBuy = 125,
			}
		}
	}
}

function itemDatabase:get(itemId, itemSubType)
	local data = self[itemId]

	if itemSubType == nil or itemSubType == -1 then
		return data
	end

	if data ~= nil and data.subTypes ~= nil and itemSubType ~= nil and itemSubType ~= -1 then
		return data.subTypes[itemSubType]
	end

	return nil
end

function itemDatabase:getPrice(category, itemId, itemSubType)
	local price = 0
	local data = playerItemDatabase:get(itemId, itemSubType)
	data = data or self:get(itemId, itemSubType)
	if data ~= nil then
		if category == "loot" then
			price = data.priceSell
		elseif category == "supply" then
			price = data.priceBuy
		end
	end
	return price
end

function itemDatabase:getClientId(itemId, itemSubType)	
	local clientId = 0
	local data = self:get(itemId, itemSubType)
	if data ~= nil then
		clientId = data.clientId
	end
	return clientId
end

function itemDatabase:hasData(itemId, itemSubType)
	return self[itemId] ~= nil
end

function itemDatabase:getItemsByName(name)
	local itemDataList = {}

	for itemId, itemData in pairs(itemDatabase) do
		if type(itemData) ~= 'function' then
			if itemData.name ~= nil then
				if string.find(itemData.name, name) then
					itemDataList[itemId] = copyTable(itemData)
				end

				if itemData.subTypes ~= nil then
					local tempItemDataList = {}
					tempItemDataList[itemId] = copyTable(itemData)
					tempItemDataList[itemId].subTypes = {}

					for subTypeId, subTypeData in pairs(itemData.subTypes) do
						if string.find(subTypeData.name, name) then
							tempItemDataList[itemId].subTypes[subTypeId] = subTypeData
							itemDataList[itemId] = tempItemDataList[itemId]
						end
					end
				end

			end
		end
	end

	return itemDataList
end
