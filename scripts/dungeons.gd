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
	},
}
const CLIMATE_ORDER: Array[String] = ["catacombs", "mine", "flooded", "roots"]

## Kryształ Watry (scripts/watra_crystal.gd): szansa, że loch ma komnatę z kryształem, i warianty zdarzenia
## (obrona kryształu albo górników). W trybie deweloperskim kryształ jest w każdym lochu.
const EVENT_CHANCE := 0.25
const EVENTS: Array[String] = ["crystal", "miners"]

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
const VAULT_LEGEND_CHANCE := 0.12


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
