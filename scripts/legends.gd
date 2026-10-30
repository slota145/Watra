class_name Legends
## Legendarne przedmioty bossów na miejsca inne niż pierścień i kolczyk (broń, zbroja, naszyjnik). Każdy stoi
## na przedmiocie bazowym (ItemBases: statystyki rosnące z poziomem, broń w ręku, rodzaj broni) i nadpisuje
## nazwę, opis, ikonę (assets/items/legends/<id>.png, jeśli jest - inaczej ikona bazy) i dokłada efekt
## (LegendaryEffects). Dane składane raz, przy pierwszym użyciu (Items.get_data).
## Efekty "skill" działają tylko z daną umiejętnością / rodzajem broni - opis to mówi.

const DATA := {
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
	_cache[id] = item
	return item
