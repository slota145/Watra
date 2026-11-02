class_name Dungeons
## Lochy w płomieniach Watry - dane: klimaty (zestaw kafelków z PixelLab, potwory, strażnik, wystrój, kolory),
## stopnie trudności i modyfikatory kupowane za żar. Generator lochu to scripts/dungeon.gd, okno wyboru -
## scripts/ui/dungeon_window.gd. Poziom Watry odblokowuje kolejne stopnie (stopień <= poziom Watry) i modyfikatory.

## Rozmiar lochu w kafelkach gry (siatka lochu: 40x30 wierzchołków co 64 px = 39x29 kafelków Wang).
const SIZE := Vector2i(156, 116)
const NAME := "Lochy Watry"

## klimat: nazwa, opis, arkusz Wang (assets/dungeons/<klimat>.png, tools/dungeon_tiles.py), potwory z wagami,
## strażnik (boss), przyciemnienie świata, kolor światła, lampa (pochodnia, koksownik, grzyby - liczba klatek),
## wystrój (porozrzucany i pod ścianami) i kolory minimapy.
const CLIMATES := {
	"catacombs": {
		"name": "Katakumby", "description": "Kamienne krypty pełne kości. Szkielety, trupojady i zombie; strzeże ich nekromanta.",
		"tiles": preload("res://assets/dungeons/catacombs.png"),
		"monsters": {"skeleton": 5, "skeleton_archer": 3, "zombie": 2, "ghoul": 1.5, "skeleton_knight": 1},
		"boss": "necromancer", "tint": Color(0.62, 0.62, 0.74), "light": Color(1.0, 0.62, 0.3, 0.6),
		"lamp": "res://assets/village/torch_stand.png", "lamp_frames": 2,
		"props": ["res://assets/cemetery/skulls.png", "res://assets/cemetery/sarcophagus.png", "res://assets/forest/props/bones.png",
				"res://assets/wild/bones.png", "res://assets/cemetery/fallen_stone.png", "res://assets/cemetery/corpses.png",
				"res://assets/cemetery/open_grave.png", "res://assets/forest/props/ribcage.png", "res://assets/forest/props/bone_pile.png",
				"res://assets/forest/props/skull_bones.png", "res://assets/forest/props/cage.png"],
		"wall_props": ["res://assets/cemetery/candle.png", "res://assets/cemetery/sarcophagus.png", "res://assets/forest/props/cage.png",
				"res://assets/cemetery/skulls.png"],
		"map_floor": Color("5c5650"), "map_wall": Color("16151a"),
		# wystrój komnat (scripts/decor_<klimat>.gd): rodzaje komnat i grafiki z tools/dungeon_props.py
		"decor": {"dir": "res://assets/dungeons/catacombs/", "tint": Color(0.6, 0.6, 0.72),
				"themes": ["crypt", "pillars", "ossuary", "chapel", "collapsed", "prison"]},
	},
	"mine": {
		"name": "Kopalnia goblinów", "description": "Chodniki z belkami, porzucone wózki i beczki prochu. Gobliny i koboldy; rządzi nimi wódz.",
		"tiles": preload("res://assets/dungeons/mine.png"),
		"monsters": {"goblin": 4, "archer": 2, "kobold": 3, "kobold_slinger": 2, "kobold_bomber": 1, "brute": 1},
		"boss": "chief", "tint": Color(0.74, 0.66, 0.56), "light": Color(1.0, 0.66, 0.3, 0.6),
		"lamp": "res://assets/village/torch_stand.png", "lamp_frames": 2,
		"props": ["res://assets/forest/props/barrel.png", "res://assets/fields/powder_barrel.png", "res://assets/village/handcart.png",
				"res://assets/fields/cart.png", "res://assets/fields/rubble.png", "res://assets/forest/props/boulders.png",
				"res://assets/village/deco_wheelbarrow.png", "res://assets/fields/sacks.png", "res://assets/forest/props/pots.png"],
		"wall_props": ["res://assets/village/crate.png", "res://assets/village/coal_sack.png", "res://assets/village/deco_tools.png",
				"res://assets/fields/bomb_crate.png", "res://assets/forest/props/weapon_rack.png", "res://assets/village/barrel.png"],
		"map_floor": Color("755433"), "map_wall": Color("1b1613"),
		"decor": {"dir": "res://assets/dungeons/mine/", "tint": Color(0.68, 0.6, 0.52),
				"themes": ["tracks", "powder", "forge", "camp", "shaft", "cavein", "vein"]},
	},
	"flooded": {
		"name": "Zatopione podziemia", "description": "Zalane, omszałe ruiny. Topielce, żabołaki, ogniki i topielice; w głębi czeka wodnik.",
		"tiles": preload("res://assets/dungeons/flooded.png"),
		"monsters": {"drowner": 4, "frogman": 3, "frog_spitter": 2, "wisp": 1.5, "rusalka": 1},
		"boss": "wodnik", "tint": Color(0.56, 0.68, 0.64), "light": Color(0.45, 1.0, 0.7, 0.55),
		"lamp": "res://assets/frogs/brazier.png", "lamp_frames": 2,
		"props": ["res://assets/swamp/v2_rocks.png", "res://assets/drowned/sunken_cross.png", "res://assets/drowned/soul_jars.png",
				"res://assets/swamp/v2_lilies.png", "res://assets/drowned/rotten_stump.png", "res://assets/drowned/sunken_boat.png",
				"res://assets/swamp/v2_reeds.png", "res://assets/ancient/v2_mossy_rocks.png"],
		"wall_props": ["res://assets/frogs/clay_pots.png", "res://assets/frogs/fish_net.png", "res://assets/swamp/v2_pillar.png",
				"res://assets/drowned/soul_jars.png"],
		"map_floor": Color("455844"), "map_wall": Color("0c120b"),
		"decor": {"dir": "res://assets/dungeons/flooded/", "tint": Color(0.6, 0.7, 0.68),
				"themes": ["temple", "boardwalk", "wrecks", "nest", "wisps", "frogs", "rusalka", "spring"]},
	},
	"roots": {
		"name": "Pajęcze korzenie", "description": "Podziemia pod Prastarym Lasem, oplecione korzeniami i siecią. Pająki i drzewce; w gnieździe królowa pająków.",
		"tiles": preload("res://assets/dungeons/roots.png"),
		"monsters": {"spider": 4, "web_spider": 2, "spiderling": 3, "treant": 1},
		"boss": "spider_queen", "tint": Color(0.6, 0.64, 0.56), "light": Color(0.45, 0.75, 1.0, 0.55),
		"lamp": "res://assets/ancient/v2_mushroom_ring.png", "lamp_frames": 1,
		"props": ["res://assets/ancient/web_small.png", "res://assets/ancient/web_big.png", "res://assets/forest/props/bones.png",
				"res://assets/ancient/v2_mushroom_ring.png", "res://assets/ancient/v2_roots.png", "res://assets/ancient/glow_shroom.png",
				"res://assets/ancient/bone_pile.png", "res://assets/ancient/v2_mossy_rocks.png", "res://assets/ancient/wrapped_victim.png"],
		"wall_props": ["res://assets/ancient/egg_sac.png", "res://assets/ancient/web_small.png", "res://assets/ancient/v2_roots.png",
				"res://assets/ancient/glow_shroom.png"],
		"map_floor": Color("47492c"), "map_wall": Color("1a130f"),
		"decor": {"dir": "res://assets/dungeons/roots/", "tint": Color(0.58, 0.64, 0.6),
				"themes": ["hatchery", "larder", "roots", "mycelium", "webhall", "treants", "camp", "altar"]},
	},
	# loch na zewnątrz (Dungeon.outdoor): polany i kręte ścieżki, granicą klify, ściana drzew i stawy (progi szumu
	# w "terrain"); kafelki to klify Wietrznych Turni (tools/dungeon_tiles.py), podłoże - tekstury gór (SoftGround)
	"vineyard": {
		"name": "Winnica satyrów", "description": "Dzika winnica na skalnych tarasach. Satyrowie upili się winem z płomieni Watry i świętują bez końca; ucztą rządzi Król Satyrów.",
		"tiles": preload("res://assets/dungeons/vineyard.png"), "outdoor": true,
		"monsters": {"satyr": 5, "satyr_piper": 2, "satyr_brute": 1.5},
		"boss": "satyr_king", "tint": Color(0.9, 0.78, 0.72), "light": Color(1.0, 0.7, 0.35, 0.55),
		"terrain": {"cliff_below": -0.28, "water_above": 0.32,
				"trees": ["res://assets/forest/trees/oak_0.png", "res://assets/forest/trees/oak_1.png", "res://assets/forest/trees/oak_2.png",
						"res://assets/forest/trees/oak_3.png", "res://assets/forest/trees/oak_4.png", "res://assets/forest/trees/oak_5.png",
						"res://assets/forest/trees/oak_6.png", "res://assets/forest/trees/oak_7.png", "res://assets/forest/trees/pine_0.png",
						"res://assets/forest/trees/pine_1.png", "res://assets/forest/trees/pine_2.png"],
				"plateau": ["res://assets/forest/trees/bush_0.png", "res://assets/forest/trees/bush_1.png", "res://assets/forest/trees/bush_2.png",
						"res://assets/forest/trees/rock_0.png", "res://assets/forest/trees/rock_1.png"],
				"reeds": "res://assets/swamp/v2_reeds.png", "lilies": "res://assets/swamp/v2_lilies.png",
				# pola winorośli na terenie niedostępnym (Dungeon._vine_fields)
				"vines": ["res://assets/mountains/satyr/vine_row.png", "res://assets/mountains/satyr/vine_row_2.png"], "vines_above": -0.45},
		"map_floor": Color("4f8a2c"), "map_wall": Color("6e6652"), "map_trees": Color("1f3a17"), "map_water": Color("2f5f6e"),
		"map_path": Color("8a7048"), "map_vines": Color("3e5a26"),
		"decor": {"dir": "res://assets/dungeons/vineyard/", "tint": Color(0.92, 0.8, 0.74),
				"themes": ["vines", "vines", "press", "feast", "dance", "vines", "orchard", "goats", "camp", "pond"]},
	},
	# drugi loch na zewnątrz: granicą palisada (Dungeon.palisades - pale wzdłuż gładkiego obrysu, za nią spalone
	# zagrody), las i stawy; bez klifów (kafelki Wang nieużywane)
	"stronghold": {
		"name": "Oblężony gród", "description": "Gród zdobyty i spalony przez hordę koboldów. Za połamaną palisadą dymią zgliszcza zagród, na majdanie stoi obóz najeźdźców, a z ruin dworu rządzi nimi Bombardier Kaszlak.",
		"tiles": preload("res://assets/dungeons/vineyard.png"), "outdoor": true,
		"monsters": {"kobold": 5, "kobold_slinger": 3, "kobold_bomber": 2},
		"boss": "bombardier", "tint": Color(0.86, 0.74, 0.7), "light": Color(1.0, 0.6, 0.3, 0.55),
		"terrain": {"cliff_below": -2.0, "water_above": 0.45, "palisade_below": 0.15,
				"trees": ["res://assets/forest/trees/oak_0.png", "res://assets/forest/trees/oak_1.png", "res://assets/forest/trees/oak_2.png",
						"res://assets/forest/trees/oak_3.png", "res://assets/forest/trees/pine_0.png", "res://assets/forest/trees/pine_1.png",
						"res://assets/forest/trees/pine_2.png"],
				"plateau": [], "reeds": "res://assets/swamp/v2_reeds.png", "lilies": "res://assets/swamp/v2_lilies.png",
				# pale palisady (klatki jak w Ostoi - Settlement.STAKE_WEIGHTS) i pale złamane
				"stakes": "res://assets/village/palisade_stake.png", "stakes_broken": "res://assets/village/palisade_stake_broken.png"},
		"map_floor": Color("5a7a34"), "map_wall": Color("5c4632"), "map_trees": Color("1f3a17"), "map_water": Color("2f5f6e"),
		"map_path": Color("8a7048"), "map_yard": Color("4a3a2c"),
		"decor": {"dir": "res://assets/village/", "tint": Color(0.86, 0.74, 0.7),
				"themes": ["burned", "camp", "gate", "square", "burned", "camp", "burned", "gate", "square", "camp"]},
	},
}
const CLIMATE_ORDER: Array[String] = ["catacombs", "mine", "flooded", "roots", "vineyard", "stronghold"]

## Mechaniki lochu - powód, żeby robić lochy. Każdy loch ma co najmniej jedną, z małą szansą drugą i trzecią
## (bez powtórzeń); proste ("small") mają większą wagę niż duże ("large"). "room" - mechanika zajmuje własną
## komnatę (bez zwykłych potworów). Losuje je Dungeons.roll_mechanics, buduje Dungeon._build_mechanics.
## Nowa mechanika: wpis tutaj i gałąź w Dungeon._build_mechanics.
const MECHANICS := {
	"chests": {"name": "Skrzynie", "weight": 10.0, "size": "small"},
	"shrine": {"name": "Kapliczka", "weight": 8.0, "size": "small"},
	"crystal": {"name": "Kryształ Watry", "weight": 5.0, "size": "large", "room": true},
}
## Szansa na drugą i trzecią mechanikę.
const MECHANIC_EXTRA: Array[float] = [0.25, 0.08]
## Kryształ Watry (scripts/watra_crystal.gd): warianty zdarzenia (obrona kryształu albo górników).
const EVENTS: Array[String] = ["crystal", "miners"]

## Skrzynie (scripts/dungeon_chest.gd) - jak strongboxy w PoE: rodzaj mówi, jaki łup jest w środku.
## "weight" - jak często, "tint" - kolor skrzyni, "glow" - poświata.
const CHEST_KINDS := {
	"common": {"name": "Skrzynia", "weight": 5.0, "tint": Color(1.0, 1.0, 1.0), "glow": Color(1.0, 0.85, 0.5, 0.35)},
	"smith": {"name": "Skrzynia kowala", "weight": 3.0, "tint": Color(0.75, 0.82, 0.95), "glow": Color(0.6, 0.75, 1.0, 0.4)},
	"jeweler": {"name": "Szkatuła jubilera", "weight": 2.0, "tint": Color(0.9, 0.7, 1.0), "glow": Color(0.85, 0.5, 1.0, 0.4)},
	"gold": {"name": "Skarbnica", "weight": 2.0, "tint": Color(1.0, 0.88, 0.45), "glow": Color(1.0, 0.8, 0.25, 0.45)},
}
## Cechy skrzyń: strzeżona (po otwarciu wyskakują strażnicy, skrzynia otwiera się po ich pokonaniu, łupu więcej),
## obfita (więcej łupu), cenna (lepsze rzadkości). "chance" - szansa na cechę, "loot" - mnożnik ilości łupu.
const CHEST_TRAITS := {
	"guarded": {"name": "Strzeżona", "chance": 0.3, "loot": 1.4},
	"rich": {"name": "Obfita", "chance": 0.25, "loot": 1.6},
	"rare": {"name": "Cenna", "chance": 0.2, "loot": 1.0},
}
## Ile skrzyń w lochu z tą mechaniką.
const CHESTS := Vector2i(2, 4)

## Kapliczki (scripts/dungeon_shrine.gd): krótki, mocny dar (Boons, grupa "shrine") po modlitwie.
const SHRINES: Array[String] = ["shrine_might", "shrine_ward", "shrine_haste", "shrine_fortune", "shrine_wisdom", "shrine_moon"]
## Ile kapliczek w lochu z tą mechaniką (każda daje inny dar).
const SHRINE_COUNT := Vector2i(1, 2)
## Kamienie zaklinające ze skarbca strażnika (rzadko i po jednym - ich głównym źródłem jest Kryształ Watry):
## szansa na kamień każdego rodzaju (plus szansa z poziomu, Levels.stone_chances) i szansa na doskonały.
const VAULT_STONE_CHANCE := 0.15
const VAULT_STONE_LEVEL := 1.5
const VAULT_STONE_PERFECT := 2.0

## Poziom potworów na stopniach 1-7 (stopień wybiera gracz, najwyżej poziom Watry); strażnik ma o 2 więcej.
const TIER_LEVELS: Array[int] = [5, 11, 17, 23, 29, 35, 41]
const BOSS_BONUS := 2
## O ile więcej potworów na każdym kolejnym stopniu (stopień 7: +42%).
const TIER_COUNT_BONUS := 0.07

## Modyfikatory za żar (dostępny żar = zebrany minus wydany - wydawanie nie obniża poziomu Watry).
## "unlock" - od którego poziomu Watry; reszta to mnożniki dla potworów (Goblin.dungeon_mods) i skarbca.
const MODIFIERS := {
	"horde": {"name": "Hordy", "description": "+60% potworów", "cost": 40, "unlock": 1, "count": 1.6},
	"wealth": {"name": "Bogactwo", "description": "+50% złota, dwa razy częściej przedmioty", "cost": 60, "unlock": 2,
			"gold": 1.5, "loot": 2.0},
	"fury": {"name": "Wściekłość", "description": "Potwory +25% zdrowia i obrażeń, +50% doświadczenia", "cost": 50, "unlock": 3,
			"health": 1.25, "damage": 1.25, "xp": 1.5},
	"treasure": {"name": "Pełny skarbiec", "description": "Skarbiec strażnika: dwa razy więcej łupu, w tym rzadkie przedmioty",
			"cost": 80, "unlock": 4, "treasure": 2.0},
}
const MODIFIER_ORDER: Array[String] = ["horde", "wealth", "fury", "treasure"]
## Legendarne przedmioty ze skarbca strażnika (tylko z lochów) i szansa na jeden z nich (Pełny skarbiec ją podwaja).
const VAULT_LEGENDS: Array[String] = ["legend_endless_amulet", "legend_swarog_bow", "legend_engineer_gloves", "legend_tracker_talisman",
		"legend_marzanna_book", "legend_perun_crown", "legend_mokosh_belt", "legend_bogatyr_girdle"]
const VAULT_LEGEND_CHANCE := 0.07


## Losuje mechaniki lochu: pierwsza zawsze, druga i trzecia z szansą MECHANIC_EXTRA (bez powtórzeń).
## `bonus` - na później (drzewko Watry, bożki): "weights" {id: mnożnik wagi}, "extra" [premia do szansy drugiej,
## trzeciej], "forced" [mechaniki zawsze obecne - nie liczą się do limitu].
static func roll_mechanics(rng: RandomNumberGenerator, bonus := {}) -> Array[String]:
	var result: Array[String] = []
	for id: String in bonus.get("forced", []):
		if MECHANICS.has(id) and not result.has(id):
			result.append(id)
	var weights: Dictionary = bonus.get("weights", {})
	var extra: Array = bonus.get("extra", [])
	for i in 1 + MECHANIC_EXTRA.size():
		if i > 0:
			var chance: float = MECHANIC_EXTRA[i - 1] + float(extra[i - 1] if extra.size() >= i else 0.0)
			if rng.randf() >= chance:
				break
		var pool := {}
		for id: String in MECHANICS:
			if not result.has(id):
				pool[id] = float(MECHANICS[id]["weight"]) * float(weights.get(id, 1.0))
		var id := weighted(rng, pool)
		if id == "":
			break
		result.append(id)
	return result


## Jak często loch ma daną mechanikę (próba wielu losowań - do symulacji balansu i testów).
static func mechanic_chance(id: String, samples := 4000) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var hits := 0
	for i in samples:
		if roll_mechanics(rng).has(id):
			hits += 1
	return float(hits) / samples


## Losowy klucz słownika {klucz: waga} ("" - pusty albo same zera).
static func weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for key: String in weights:
		total += maxf(float(weights[key]), 0.0)
	if total <= 0.0:
		return ""
	var roll := rng.randf() * total
	for key: String in weights:
		roll -= maxf(float(weights[key]), 0.0)
		if roll <= 0.0 and float(weights[key]) > 0.0:
			return key
	return weights.keys().back()


static func tier_level(tier: int) -> int:
	return TIER_LEVELS[clampi(tier, 1, TIER_LEVELS.size()) - 1]


static func mods_cost(mods: Array) -> int:
	var total := 0
	for id: String in mods:
		total += int(MODIFIERS[id]["cost"])
	return total


## Łączny mnożnik danego rodzaju z wybranych modyfikatorów (1 - bez zmian).
static func multiplier(mods: Array, key: String) -> float:
	var total := 1.0
	for id: String in mods:
		total *= float(MODIFIERS[id].get(key, 1.0))
	return total


## Ustawienia wyprawy: {"climate", "tier", "mods", "seed"} - zapisywane przy przejściu do lochu.
static func config(climate: String, tier: int, mods: Array, seed_value: int) -> Dictionary:
	return {"climate": climate, "tier": tier, "mods": mods.duplicate(), "seed": seed_value}


static func title(config_data: Dictionary) -> String:
	return Lang.t("%s - stopień %d (poz. %d)") % [Lang.t(CLIMATES[config_data["climate"]]["name"]), config_data["tier"], tier_level(config_data["tier"])]
