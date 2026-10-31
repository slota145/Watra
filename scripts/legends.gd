class_name Legends
## Legendarne przedmioty bossów na miejsca inne niż pierścień i kolczyk (broń, zbroja, naszyjnik). Każdy stoi
## na przedmiocie bazowym (ItemBases: statystyki rosnące z poziomem, broń w ręku, rodzaj broni) i nadpisuje
## nazwę, opis, ikonę (assets/items/legends/<id>.png, jeśli jest - inaczej ikona bazy), broń w ręku
## (assets/weapons/<id>.png z chwytem z LegendHeld - tools/legend_held.py) i dokłada efekt
## (LegendaryEffects). Dane składane raz, przy pierwszym użyciu (Items.get_data).
## Efekty "skill" działają tylko z daną umiejętnością / rodzajem broni - opis to mówi.

const DATA := {
	# ---------------------------------------------------------------- world bossy (wydarzenia w świecie - WorldBoss)
	"legend_zmij_fang": {"base": "sword_t5", "name": "Kieł Gorynycza",
		"description": "Ostrze z kła środkowej głowy Żmija, wciąż gorące. Pokonani wrogowie wybuchają ogniem.",
		"stats": {"strength": 14, "attack_speed": 0.06}, "effect": {"kind": "kaboom", "chance": 0.35, "per_level": 0.015}},
	"legend_zmij_scales": {"base": "plate_t5", "name": "Łuski Żmija",
		"description": "Pancerz z łusek trójgłowego smoka. Pociski odbijają się od niego jak od skały.",
		"stats": {"vitality": 10, "health": 60}, "effect": {"kind": "wind_shield", "chance": 0.4, "per_level": 0.015}},
	"legend_wij_lids": {"base": "hood_t5", "name": "Powieki Wija",
		"description": "Kaptur z ciężkich powiek Wija. Kto go nosi, raz na jakiś czas nie daje się zabić.",
		"stats": {"vitality": 8, "intelligence": 8, "health": 50}, "effect": {"kind": "undying", "chance": 0.35, "per_level": 0.015}},
	"legend_wij_roots": {"base": "staff_t5", "name": "Korzeń Wija",
		"description": "Kostur z korzenia, na którym stał Wij. Gdy stoisz w miejscu, ziemia leczy twoje rany.",
		"stats": {"intelligence": 14, "mana": 40}, "effect": {"kind": "rooted_regen", "chance": 0.03, "per_level": 0.0015}},
	# ---------------------------------------------------------------- lochy Watry (skarbiec strażnika, Dungeon)
	"legend_endless_amulet": {"base": "amulet_t3", "name": "Amulet Wiecznego Wiru",
		"description": "Wirujący bursztyn ze skarbca w płomieniach Watry. Kto go nosi, nie zatrzymuje się w tańcu ostrzy.",
		"stats": {"dexterity": 4, "strength": 4}, "effect": {"kind": "endless_whirl", "chance": 0.2, "per_level": 0.01}},
	"legend_swarog_bow": {"base": "bow_t3", "name": "Łuk Swaroga",
		"description": "Łuk wykuty w boskim ogniu kuźni Swaroga. Strzała tropiąca rozpada się na iskry, które same szukają celu.",
		"stats": {"dexterity": 8}, "effect": {"kind": "seeker_split", "chance": 2.0, "per_level": 0.1}},
	"legend_engineer_gloves": {"base": "gloves_t3", "name": "Rękawice Cieśli Wojennego",
		"description": "Okute rękawice budowniczego machin oblężniczych. Balista z jego rąk strzela całą salwą.",
		"stats": {"dexterity": 4, "attack_speed": 0.05}, "effect": {"kind": "ballista_volley", "chance": 2.0, "per_level": 0.1}},
	"legend_marzanna_book": {"base": "book_t3", "name": "Księga Marzanny",
		"description": "Księga oprawna w wieczny lód, spisana ręką bogini zimy. Jej śnieżyce skuwają wszystko lodem.",
		"stats": {"intelligence": 8}, "effect": {"kind": "blizzard_freeze", "chance": 1.5, "per_level": 0.05}},
	"legend_perun_crown": {"base": "helm_t3", "name": "Korona Peruna",
		"description": "Złota korona, w której wciąż trzeszczą pioruny. Burza nie cichnie, póki starcza woli.",
		"stats": {"intelligence": 5, "cast_speed": 0.05}, "effect": {"kind": "endless_storm", "chance": 8.0, "per_level": -0.2}},
	"legend_mokosh_belt": {"base": "belt_t3", "name": "Pas Mokoszy",
		"description": "Pas utkany z ziół przez boginię-prządkę. Sakiewki same się napełniają, zanim zdążysz sięgnąć.",
		"stats": {"vitality": 5, "potion_power": 0.15}, "effect": {"kind": "potion_saver", "chance": 0.25, "per_level": 0.012}},
	"legend_bogatyr_girdle": {"base": "girdle_t3", "name": "Pas Bogatyra",
		"description": "Brązowy pas z niedźwiedzią klamrą. Łyk mikstury budzi w nosicielu gniew dawnych bohaterów.",
		"stats": {"strength": 6, "armor": 6}, "effect": {"kind": "potion_fury", "chance": 0.3, "per_level": 0.015}},
	"legend_tracker_talisman": {"base": "talisman_t3", "name": "Talizman Tropiciela",
		"description": "Sokole pióro w bursztynie. Bełty balisty same tropią zwierzynę jak strzały myśliwego.",
		"stats": {"dexterity": 5, "crit_chance": 0.03}, "effect": {"kind": "ballista_seeker", "chance": 3.0, "per_level": 0.1}},
	# ---------------------------------------------------------------- dawni bossowie (po jednej legendzie spoza biżuterii)
	"legend_gruzlog_club": {"base": "mace_t1", "name": "Maczuga Gruzłoga",
		"description": "Nabijana maczuga wodza goblinów, okuta złotem z łupów. Pokonani wrogowie gubią więcej skarbów.",
		"stats": {"strength": 4}, "effect": {"kind": "plunder", "chance": 0.06, "per_level": 0.003}},
	"legend_alpha_pelt": {"base": "leather_armor", "name": "Skóra Szarokła",
		"description": "Futro wilka alfa. Gdy krwawisz, z mroku wyskakuje widmowy wilk z jego watahy.",
		"stats": {"dexterity": 3, "vitality": 3}, "effect": {"kind": "pack_call", "chance": 0.2, "per_level": 0.01}},
	"legend_bulgor_boots": {"base": "boots_t2", "name": "Płetwy Bulgora",
		"description": "Buty z żabiej skóry, wiecznie wilgotne. Z każdym ciosem język Bulgora przyciąga kolejnego wroga.",
		"stats": {"vitality": 3, "move_speed": 0.04}, "effect": {"kind": "tongue", "chance": 0.15, "per_level": 0.008}},
	"legend_storm_bow": {"base": "bow_t2", "name": "Łuk Gromowładnego",
		"description": "Łuk z cięciwą ze skręconych piór Pana Burz. Strzały niosą w sobie piorun.",
		"stats": {"dexterity": 6}, "effect": {"kind": "storm_arrows", "chance": 0.25, "per_level": 0.012}},
	"legend_wodnik_cloak": {"base": "robe_t1", "name": "Płaszcz Topielca",
		"description": "Ociekający wodą płaszcz Wodnika. Każdy unik ciągnie za sobą falę, która porywa wrogów.",
		"stats": {"intelligence": 4, "vitality": 3}, "effect": {"kind": "tidal_dodge", "chance": 0.9, "per_level": 0.045}},
	"legend_leshy_staff": {"base": "staff_t2", "name": "Kostur Leszego",
		"description": "Żywy kostur, z którego wciąż wyrastają liście. Kto stoi w miejscu, czerpie siłę z ziemi.",
		"stats": {"intelligence": 5, "vitality": 3}, "effect": {"kind": "rooted_regen", "chance": 0.02, "per_level": 0.001}},
	"legend_queen_dagger": {"base": "dagger_t2", "name": "Żądło Królowej",
		"description": "Sztylet z kolca Królowej Pająków. Trafieni wrogowie grzęzną w lepkiej sieci.",
		"stats": {"dexterity": 5}, "effect": {"kind": "web_burst", "chance": 0.15, "per_level": 0.008}},
	"legend_bies_axe": {"base": "axe_t2", "name": "Topór Biesa",
		"description": "Topór z rogu Władcy Bestii. Im bliżej śmierci jesteś, tym straszliwiej tnie.",
		"stats": {"strength": 6}, "effect": {"kind": "berserk", "chance": 0.4, "per_level": 0.02}},
	# ---------------------------------------------------------------- Bombardier Kaszlak (Pola Zbożowe)
	"legend_kaszlak_gloves": {"base": "leather_gloves", "name": "Rękawice Podpalacza",
		"description": "Osmalone rękawice Kaszlaka, wciąż pachną prochem. Same wkładają bombę w dłoń.",
		"stats": {"dexterity": 4, "attack_speed": 0.04}, "effect": {"kind": "bomb", "chance": 0.12, "per_level": 0.006}},
	"legend_kaszlak_boots": {"base": "leather_boots", "name": "Buty Sapera",
		"description": "Podkute buty z wszytymi woreczkami prochu. Kto za tobą biegnie, ten pożałuje.",
		"stats": {"vitality": 3, "move_speed": 0.05}, "effect": {"kind": "mine_trail", "chance": 1.0, "per_level": 0.05}},
	"legend_kaszlak_cord": {"base": "amber_necklace", "name": "Naszyjnik z Lontów",
		"description": "Sznur splecionych lontów z zębem kobolda. Pokonani wrogowie czasem wylatują w powietrze.",
		"stats": {"strength": 3, "dexterity": 3}, "effect": {"kind": "kaboom", "chance": 0.25, "per_level": 0.012}},
	"legend_kaszlak_staff": {"base": "staff_t1", "name": "Kostur Bombardiera",
		"description": "Kostur z beczułką prochu zamiast głowicy. Pociski wybuchają przy trafieniu.",
		"stats": {"intelligence": 5}, "effect": {"kind": "blast_shot", "chance": 0.3, "per_level": 0.015}},
	# ---------------------------------------------------------------- Pożeracz Pól (Pola Zbożowe)
	"legend_devourer_helm": {"base": "iron_helmet", "name": "Szczęka Pożeracza",
		"description": "Hełm z pierścienia zębów olbrzymiego czerwia. Każdy pokonany wróg cię karmi.",
		"stats": {"vitality": 4, "health": 20}, "effect": {"kind": "devour", "chance": 0.35, "per_level": 0.015}},
	"legend_devourer_chest": {"base": "chainmail", "name": "Pancerz z Łusek Czerwia",
		"description": "Zrogowaciałe łuski Pożeracza. W chwili śmiertelnego zagrożenia zakopujesz się w ziemi i wystrzelasz z niej.",
		"stats": {"vitality": 5, "armor": 3}, "effect": {"kind": "burrow", "chance": 0.5, "per_level": 0.025}},
	"legend_devourer_bow": {"base": "short_bow", "name": "Łuk z Żuchwy",
		"description": "Łuk z żuchwy czerwia, cięciwa z jego ścięgna. Ziemia pod trafionym wrogiem pęka i wystrzela.",
		"stats": {"dexterity": 5}, "effect": {"kind": "earth_arrow", "chance": 0.2, "per_level": 0.01}},
	"legend_devourer_amulet": {"base": "amber_necklace", "name": "Serce Głębin",
		"description": "Twarde jak kamień serce Pożeracza. Bije powoli - a z każdym uderzeniem ziemia wokół ciebie drży.",
		"stats": {"vitality": 3, "health": 25}, "effect": {"kind": "tremor", "chance": 0.6, "per_level": 0.03}},
	# ---------------------------------------------------------------- Hydra (Rozlewiska, bagno na zachodzie)
	"legend_hydra_fang": {"base": "amulet_t3", "name": "Kieł Hydry",
		"description": "Jadowy kieł jednej z głów Hydry. Każdy wróg padający w pobliżu może wybuchnąć trucizną - także od twoich efektów.",
		"stats": {"vitality": 6, "health": 50}, "effect": {"kind": "corpse_blast", "chance": 0.3, "per_level": 0.015}},
	"legend_hydra_scales": {"base": "plate_t3", "name": "Łuski Hydry",
		"description": "Pancerz z łusek Hydry, z których sączy się jad. Wokół noszącego wisi trująca chmura.",
		"stats": {"vitality": 8, "armor": 5}, "effect": {"kind": "toxic_aura", "chance": 0.2, "per_level": 0.01}},
	"legend_hydra_bow": {"base": "bow_t3", "name": "Łuk Siedmiu Głów",
		"description": "Łuk z kręgosłupa Hydry. Strzała tropiąca wylatuje z niego razem z dwiema siostrami.",
		"stats": {"dexterity": 9}, "effect": {"kind": "hydra_seekers", "chance": 2.0, "per_level": 0.1}},
	"legend_hydra_crown": {"base": "helm_t3", "name": "Korona Odrastających Głów",
		"description": "Hełm z czaszki odciętej głowy Hydry. Gdy krwawisz, rany zasklepiają się same.",
		"stats": {"vitality": 6, "health": 40}, "effect": {"kind": "regrowth", "chance": 0.02, "per_level": 0.001}},
	"legend_hydra_gloves": {"base": "gloves_t3", "name": "Rękawice Jadu",
		"description": "Rękawice z błony szyi Hydry. Jad z trafionego przeskakuje na wrogów obok.",
		"stats": {"dexterity": 6, "attack_speed": 0.05}, "effect": {"kind": "venom_chain", "chance": 0.3, "per_level": 0.015}},
	"legend_hydra_boots": {"base": "boots_t3", "name": "Buty Bagiennego Śladu",
		"description": "Buty ociekające żrącą mazią. Gdzie stąpniesz, ziemia zaczyna dymić.",
		"stats": {"vitality": 4, "move_speed": 0.06}, "effect": {"kind": "acid_trail", "chance": 0.25, "per_level": 0.012}},
	# ---------------------------------------------------------------- Gryf (Pola Zbożowe, wzgórze na zachodzie)
	"legend_gryf_blade": {"base": "sword_t3", "name": "Ostrze Gryfa",
		"description": "Miecz z pióra Gryfa zaklętego w stal. Każde cięcie wypuszcza przed siebie półksiężyc wiatru.",
		"stats": {"strength": 9}, "effect": {"kind": "wind_crescent", "chance": 0.7, "per_level": 0.035}},
	"legend_gryf_talons": {"base": "gauntlets_t3", "name": "Szpony Gryfa",
		"description": "Rękawice ze złotych szponów. Zamach ściąga wrogów przed ciebie, prosto pod ostrze.",
		"stats": {"strength": 6, "attack_speed": 0.05}, "effect": {"kind": "gather", "chance": 1.0, "per_level": 0.05}},
	"legend_gryf_tome": {"base": "book_t3", "name": "Księga Gryfiego Płomienia",
		"description": "Księga oprawna w skórę gryfa. Kula ognia nie wybucha od razu - zawisa i pali wszystko wokół.",
		"stats": {"intelligence": 9}, "effect": {"kind": "fire_turret", "chance": 0.3, "per_level": 0.015}},
	"legend_gryf_wings": {"base": "boots_t3", "name": "Skrzydlate Buty",
		"description": "Buty z lotkami Gryfa. Gdy biegniesz, spod stóp zrywają się trąby powietrzne.",
		"stats": {"dexterity": 5, "move_speed": 0.08}, "effect": {"kind": "tornado_walk", "chance": 0.3, "per_level": 0.015}},
	"legend_gryf_crest": {"base": "helm_t3", "name": "Grzebień Gryfa",
		"description": "Hełm zwieńczony złotymi piórami. Przy trafieniu pióra rozpryskują się ostrym wachlarzem.",
		"stats": {"vitality": 5, "dexterity": 4}, "effect": {"kind": "feather_storm", "chance": 0.2, "per_level": 0.01}},
	"legend_gryf_heart": {"base": "amulet_t3", "name": "Serce Wichru",
		"description": "Złote serce Gryfa, wiecznie ciepłe. Otacza cię wiatr, który odbija pociski.",
		"stats": {"vitality": 5, "dexterity": 5}, "effect": {"kind": "wind_shield", "chance": 0.3, "per_level": 0.015}},
	# ---------------------------------------------------------------- Faun-Król (wioska satyrów, Wietrzne Turnie)
	"legend_faun_flute": {"base": "amulet_t2", "name": "Fletnia Fauna",
		"description": "Złota fletnia Pana na rzemieniu. Gdy uderzasz, wrogowie wokół nie mogą powstrzymać się od tańca.",
		"stats": {"dexterity": 5, "intelligence": 4}, "effect": {"kind": "dance", "chance": 0.15, "per_level": 0.008}},
	"legend_faun_horns": {"base": "helm_t2", "name": "Rogi Króla",
		"description": "Hełm z ogromnymi złotymi rogami Faun-Króla. Każdy unik staje się szarżą.",
		"stats": {"strength": 5, "vitality": 4}, "effect": {"kind": "horn_charge", "chance": 1.0, "per_level": 0.05}},
	"legend_faun_hooves": {"base": "greaves_t2", "name": "Kopyta Fauna",
		"description": "Nagolenice z kozich kopyt oplecione winoroślą. Kto cię zrani, zaplącze się w pnączach.",
		"stats": {"vitality": 5, "move_speed": 0.05}, "effect": {"kind": "vine_snare", "chance": 0.3, "per_level": 0.015}},
	"legend_faun_scepter": {"base": "mace_t2", "name": "Berło Króla Satyrów",
		"description": "Złote berło zwieńczone kozią głową. Każdy cios niesie echo fletni, które płoszy wrogów.",
		"stats": {"strength": 7}, "effect": {"kind": "pan_echo", "chance": 0.2, "per_level": 0.01}},
	# ---------------------------------------------------------------- Mortan, Pan Kości (Leśny Cmentarz)
	"legend_mortan_staff": {"base": "staff_t2", "name": "Kostur Mortana",
		"description": "Kostur zwieńczony zieloną czaszką. Kto padnie z twojej ręki, wstaje, by ci służyć.",
		"stats": {"intelligence": 8}, "effect": {"kind": "raise_dead", "chance": 0.2, "per_level": 0.01}},
	"legend_mortan_robe": {"base": "robe_t2", "name": "Całun Nekromanty",
		"description": "Czarno-fioletowa szata, pod którą szepczą zebrane dusze. Gdy jest ich dość, wyrywają się na wolność.",
		"stats": {"intelligence": 5, "mana": 30}, "effect": {"kind": "soul_harvest", "chance": 2.0, "per_level": 0.1}},
	"legend_mortan_crown": {"base": "helm_t2", "name": "Kościana Korona",
		"description": "Korona z kości palców. Wokół noszącego krążą kości, które przyjmują ciosy za niego.",
		"stats": {"vitality": 5, "armor": 3}, "effect": {"kind": "bone_armor", "chance": 0.15, "per_level": 0.008}},
	"legend_mortan_phylactery": {"base": "amulet_t2", "name": "Filakteria Mortana",
		"description": "Szklana fiolka z drgającą zieloną duszą. Raz na jakiś czas nie pozwala ci umrzeć.",
		"stats": {"vitality": 4, "health": 40}, "effect": {"kind": "undying", "chance": 0.3, "per_level": 0.015}},
	# ---------------------------------------------------------------- Gnilec, Kolosalny Ghul (Leśny Cmentarz)
	"legend_gnilec_gauntlets": {"base": "gauntlets_t2", "name": "Szpony Gnilca",
		"description": "Rękawice z czarnych pazurów ghula. Rany od nich krwawią długo.",
		"stats": {"strength": 6, "attack_speed": 0.04}, "effect": {"kind": "rend", "chance": 0.25, "per_level": 0.012}},
	"legend_gnilec_greaves": {"base": "greaves_t2", "name": "Nagolenice Trupojada",
		"description": "Zszyte ze skór nagolenice. Każdy unik kończy się skokiem, który miażdży ziemię.",
		"stats": {"strength": 4, "move_speed": 0.05}, "effect": {"kind": "corpse_leap", "chance": 1.2, "per_level": 0.06}},
	"legend_gnilec_axe": {"base": "axe_t2", "name": "Rzeźnicki Topór",
		"description": "Topór z trupowiska, z ostrzem pełnym szczerb. Słabnących wrogów dobija jednym ciosem.",
		"stats": {"strength": 8}, "effect": {"kind": "execute", "chance": 0.5, "per_level": 0.025}},
	"legend_gnilec_maw": {"base": "amulet_t2", "name": "Paszcza Gnilca",
		"description": "Szczęka ghula na rzemieniu. Co kilka ciosów plujesz przed siebie żrącą żółcią.",
		"stats": {"strength": 4, "vitality": 4}, "effect": {"kind": "bile_spit", "chance": 0.4, "per_level": 0.02}},
}

static var _cache := {}


static func has(id: String) -> bool:
	return DATA.has(id)


static func data(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var spec: Dictionary = DATA[id]
	var base: Dictionary = ItemBases.DATA.get(spec["base"], {})
	if base.is_empty():
		return {}
	var item := base.duplicate(true)
	item.erase("looks")
	item["name"] = spec["name"]
	item["description"] = spec["description"]
	item["rarity"] = "legendary"
	item["sell_price"] = 400
	var stats: Dictionary = item.get("stats", {}).duplicate()
	for key in spec.get("stats", {}):
		stats[key] = stats.get(key, 0) + spec["stats"][key]
	item["stats"] = stats
	item["effect"] = spec["effect"]
	var icon := "res://assets/items/legends/%s.png" % id
	if ResourceLoader.exists(icon):
		item["icon"] = load(icon)
	# broń w ręku: sama legenda (tools/legend_held.py), a nie broń bazowa
	if item.has("weapon") and LegendHeld.GRIPS.has(id):
		item["weapon"]["held"] = load("res://assets/weapons/%s.png" % id)
		item["weapon"]["grip"] = LegendHeld.GRIPS[id]
	_cache[id] = item
	return item
