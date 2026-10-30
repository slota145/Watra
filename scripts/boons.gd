class_name Boons
extends Node
## Premie z osady: czasowe (posiłek z karczmy, błogosławieństwo z kaplicy, wypoczynek po łaźni, dar Watry - z każdej
## grupy działa naraz jedna, nowa zastępuje starą) i stałe (bestiariusz mędrca: za trofea z danego
## gatunku potworów rośnie zadawane mu obrażenie). CharacterStats dolicza premie czasowe do statystyk,
## a Player.hit_enemy mnoży obrażenia przez premię z bestiariusza.
## Watra: ofiary (złoto i przedmioty) dokładają żaru; od zebranego żaru zależy poziom Watry, a od niego stałe premie
## postaci (WATRA_PERKS) i rozwój Ostoi (Settlement: podatek, szybsze budowy). Później także poziom lochów.

signal changed

## id: nazwa, opis, grupa, czas (s), premie do statystyk (jak na przedmiotach), koszt
## (mięso z plecaka/magazynu, złoto - przy błogosławieństwie rośnie z poziomem postaci).
const DEFS := {
	"stew": {"name": "Gulasz myśliwski", "group": "meal", "time": 900.0, "stats": {"health_percent": 0.10},
			"description": "+10% maks. zdrowia", "meat": 2, "gold": 30, "gold_per_level": 3},
	"roast": {"name": "Pieczeń z dziczyzny", "group": "meal", "time": 900.0, "stats": {"health_regen": 3.0},
			"description": "+3 zdrowia na sekundę", "meat": 3, "gold": 50, "gold_per_level": 4},
	"broth": {"name": "Rosół z ziołami", "group": "meal", "time": 900.0, "stats": {"mana_regen": 2.0, "move_speed": 0.03},
			"description": "+2 many na sekundę, +3% szybkości ruchu", "meat": 1, "gold": 20, "gold_per_level": 2},
	"bless_wisdom": {"name": "Błogosławieństwo mądrości", "group": "blessing", "time": 1200.0, "stats": {"xp_gain": 0.10},
			"description": "+10% doświadczenia", "gold": 40, "gold_per_level": 8},
	"bless_might": {"name": "Błogosławieństwo siły", "group": "blessing", "time": 1200.0, "stats": {"damage_percent": 0.05},
			"description": "+5% zadawanych obrażeń", "gold": 40, "gold_per_level": 8},
	"watra_fire": {"name": "Żar Watry", "group": "watra", "time": 1200.0, "stats": {"damage_percent": 0.08, "crit_chance": 0.03},
			"description": "+8% zadawanych obrażeń, +3% szansy na trafienie krytyczne", "gold": 60, "gold_per_level": 10},
	"watra_warmth": {"name": "Ciepło Watry", "group": "watra", "time": 1200.0, "stats": {"health_regen": 4.0, "mana_regen": 2.0, "health_percent": 0.05},
			"description": "+4 zdrowia i +2 many na sekundę, +5% maks. zdrowia", "gold": 60, "gold_per_level": 10},
	"watra_glow": {"name": "Blask Watry", "group": "watra", "time": 1200.0, "stats": {"gold_find": 0.15, "xp_gain": 0.08},
			"description": "+15% znajdowanego złota, +8% doświadczenia", "gold": 60, "gold_per_level": 10},
	"rested": {"name": "Wypoczęty", "group": "rest", "time": 600.0,
			"stats": {"health_regen": 2.0, "mana_regen": 1.0, "move_speed": 0.05},
			"description": "+2 zdrowia i +1 many na sekundę, +5% szybkości ruchu"},
}
const GROUP_NAMES := {"meal": "Posiłek", "blessing": "Błogosławieństwo", "rest": "Łaźnia", "watra": "Dar Watry"}
const GROUP_COLORS := {"meal": Color(1.0, 0.72, 0.4), "blessing": Color(1.0, 0.92, 0.55), "rest": Color(0.6, 0.85, 1.0),
		"watra": Color(1.0, 0.5, 0.22)}

## Watra: ile żaru trzeba do kolejnych poziomów (poziom 1 na start) i co daje każdy poziom.
const WATRA_LEVELS: Array[int] = [0, 300, 900, 2200, 5000, 11000, 24000]
## Stałe premie postaci za każdy poziom Watry ponad pierwszy (sumują się).
const WATRA_PERKS := {"gold_find": 0.03, "xp_gain": 0.02, "health_regen": 0.5}
## Rozwój Ostoi za każdy poziom ponad pierwszy: podatek osadników i szybkość budów.
const WATRA_TAX := 0.2
const WATRA_BUILD_SPEED := 0.12
## Ile żaru daje złoto (1 żaru za tyle złota) i spalony przedmiot (wartość u kupca razy mnożnik).
const EMBER_PER_GOLD := 0.1
const EMBER_PER_ITEM_VALUE := 0.15

## Bestiariusz: gatunek -> nazwa, trofeum, ile trofeów kosztuje kolejny stopień. Każdy stopień: +3% obrażeń.
const BESTIARY := {
	"goblin": {"name": "Gobliny", "trophy": "goblin_heart"},
	"wolf": {"name": "Wilki i wargi", "trophy": "wolf_pelt"},
	"frog": {"name": "Żabołaki", "trophy": "frog_tongue"},
	"drowner": {"name": "Topielce", "trophy": "drowned_algae"},
	"birdman": {"name": "Ptakoludzie", "trophy": "storm_feather"},
	"spider": {"name": "Pająki", "trophy": "spider_silk"},
	"treant": {"name": "Drzewce", "trophy": "ancient_bark"},
	"beast": {"name": "Bestie", "trophy": "beast_fang"},
	"kobold": {"name": "Koboldy", "trophy": "kobold_fuse"},
	"worm": {"name": "Czerwie", "trophy": "worm_tooth"},
	"skeleton": {"name": "Szkielety", "trophy": "bone_dust"},
	"ghoul": {"name": "Trupojady i zombie", "trophy": "ghoul_claw"},
	"satyr": {"name": "Satyrowie", "trophy": "satyr_horn"},
}
const BESTIARY_COSTS: Array[int] = [10, 25, 50, 100, 200]
const BESTIARY_STEP := 0.03

## grupa -> {"id": String, "left": float}
var active := {}
## gatunek -> zdobyty stopień (0..5)
var bestiary := {}
## Żar złożony w Watrze (ofiary) - stały, rośnie z każdą ofiarą.
var ember := 0


func _process(delta: float) -> void:
	var expired: Array = []
	for group: String in active:
		active[group]["left"] -= delta
		if active[group]["left"] <= 0.0:
			expired.append(group)
	for group: String in expired:
		active.erase(group)
	if not expired.is_empty():
		changed.emit()


func grant(id: String) -> void:
	var data: Dictionary = DEFS[id]
	active[data["group"]] = {"id": id, "left": float(data["time"])}
	changed.emit()


func has_group(group: String) -> bool:
	return active.has(group)


## Suma premii czasowych do statystyki (jak Equipment.bonus) i stałych premii z poziomu Watry.
func bonus(stat: String) -> float:
	var total := float(WATRA_PERKS.get(stat, 0.0)) * (watra_level() - 1)
	for group: String in active:
		total += float(DEFS[active[group]["id"]]["stats"].get(stat, 0.0))
	return total


## Ile złota kosztuje premia dla postaci na danym poziomie.
static func gold_cost(id: String, level: int) -> int:
	var data: Dictionary = DEFS[id]
	return int(data.get("gold", 0)) + int(data.get("gold_per_level", 0)) * (level - 1)


# ---------------------------------------------------------------- Watra
func watra_level() -> int:
	var level := 1
	for i in range(1, WATRA_LEVELS.size()):
		if ember >= WATRA_LEVELS[i]:
			level = i + 1
	return level


## Żar potrzebny do następnego poziomu (0 - najwyższy poziom).
func watra_next() -> int:
	var level := watra_level()
	return WATRA_LEVELS[level] if level < WATRA_LEVELS.size() else 0


## Dokłada żaru; zwraca true, gdy Watra wskoczyła na wyższy poziom.
func add_ember(amount: int) -> bool:
	var before := watra_level()
	ember += maxi(amount, 0)
	changed.emit()
	return watra_level() > before


# ---------------------------------------------------------------- bestiariusz
static func kind_of(enemy: Node) -> String:
	if enemy is Animal:
		return ""
	if enemy is Wolf or enemy is AlphaWolf:
		return "wolf"
	if enemy is Frogman or enemy is FrogChief:
		return "frog"
	if enemy is Drowner:
		return "drowner"
	if enemy is Birdman:
		return "birdman"
	if enemy is Spider or enemy is SpiderQueen:
		return "spider"
	if enemy is Treant:
		return "treant"
	if enemy is ForestBeast or enemy is Bies:
		return "beast"
	if enemy is Kobold or enemy is KoboldBombardier:
		return "kobold"
	if enemy is FieldWorm or enemy is GiantWorm:
		return "worm"
	if enemy is Satyr or enemy is SatyrKing:
		return "satyr"
	if enemy is Skeleton or enemy is Necromancer:
		return "skeleton"
	if enemy is Ghoul or enemy is Zombie or enemy is ColossalGhoul:
		return "ghoul"
	if enemy is Goblin and enemy.get_script().resource_path.get_file().begins_with("goblin"):
		return "goblin"
	return ""


func rank(kind: String) -> int:
	return int(bestiary.get(kind, 0))


## Ile trofeów kosztuje następny stopień (0 - wszystkie zdobyte).
func next_cost(kind: String) -> int:
	var r := rank(kind)
	return BESTIARY_COSTS[r] if r < BESTIARY_COSTS.size() else 0


func advance(kind: String) -> void:
	bestiary[kind] = rank(kind) + 1
	changed.emit()


func damage_multiplier(enemy: Node) -> float:
	var kind := kind_of(enemy)
	return 1.0 + rank(kind) * BESTIARY_STEP if kind != "" else 1.0


# ---------------------------------------------------------------- zapis
func get_save_data() -> Dictionary:
	var timed := {}
	for group: String in active:
		timed[group] = [active[group]["id"], active[group]["left"]]
	return {"active": timed, "bestiary": bestiary.duplicate(), "ember": ember}


func load_save_data(data: Dictionary) -> void:
	active.clear()
	var timed: Dictionary = data.get("active", {})
	for group: String in timed:
		var entry: Array = timed[group]
		if DEFS.has(str(entry[0])):
			active[group] = {"id": str(entry[0]), "left": float(entry[1])}
	ember = int(data.get("ember", 0))
	bestiary.clear()
	var saved: Dictionary = data.get("bestiary", {})
	for kind: String in saved:
		if BESTIARY.has(kind):
			bestiary[kind] = clampi(int(saved[kind]), 0, BESTIARY_COSTS.size())
	changed.emit()
