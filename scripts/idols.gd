class_name Idols
## Bożki (jak skaraby w Path of Exile): małe figurki wypadające rzadko z każdego potwora (po otwarciu lochów Watry -
## MainQuests.dungeons_unlocked). Przed wejściem do lochu gracz wkłada je w sloty w oknie lochów (DungeonWindow);
## przy wejściu bożki się zużywają i zmieniają loch.
## Przedmiot bożka to stały identyfikator "idol_<rodzaj>_<rzadkość>" (Items.get_data -> Idols.data), więc bożki
## układają się w stosy. Rodzaje (KINDS) dzielą się na grupy:
## - "mechanic" - jedna mechanika lochu (Dungeons.MECHANICS): zwykły częściej ją losuje, rzadki zawsze ją daje,
##   legendarny daje ją wzmocnioną (MECHANIC_POWER - więcej skrzyń, run, talizmanów do wyboru…),
## - "monsters" - więcej albo silniejszych potworów, za to więcej doświadczenia i łupu,
## - "loot" - więcej łupu danego rodzaju,
## - "risk" - mocne utrudnienie za lepszy łup.
## Siła rośnie z rzadkością (wartości w KINDS: [zwykły, rzadki, legendarny]). Mnożniki łączą się z modyfikatorami
## za żar (Dungeons.mult), premie mechanik idą do Dungeons.roll_mechanics (Dungeons.mechanic_bonus).
## Slotów jest 2, kolejne odblokowuje poziom Watry (SLOT_LEVELS); miejsce na premie z drzewka Watry: `extra_slots`
## w slot_count i `chance_bonus` w drop_chance.

const PREFIX := "idol_"
const RARITIES: Array[String] = ["common", "rare", "legendary"]
## Nazwy materiału według rzadkości (część nazwy bożka).
const MATERIAL_NAMES := {"common": "Gliniany", "rare": "Rzeźbiony", "legendary": "Złocony"}
## Szansa na bożka z każdego potwora (bossowie BOSS_MULT razy więcej) i wagi rzadkości.
const DROP_CHANCE := 0.0035
const BOSS_MULT := 15.0
const RARITY_WEIGHTS := {"common": 70.0, "rare": 25.0, "legendary": 5.0}
## Od którego poziomu Watry działa kolejny slot (dwa pierwsze od początku).
const SLOT_LEVELS: Array[int] = [1, 1, 4, 6]
## Mechanika z bożka: mnożnik wagi zwykłego bożka, moc mechaniki z legendarnego (Dungeon.mechanic_power).
const MECHANIC_WEIGHT := 4.0
const MECHANIC_POWER := 1.5
## Cena skupu według rzadkości.
const SELL := {"common": 25, "rare": 70, "legendary": 200}

## Rodzaje bożków. "mult" - mnożniki lochu (klucze jak w Dungeons.MODIFIERS: count, health, damage, xp, gold, loot,
## treasure, oraz gems - kamienie szlachetne z potworów, legend - legendy z potworów i skarbca), "add" - premie
## dodawane (item_level - poziom przedmiotów z lochu, quality - szansa na lepszą rzadkość, vault_runes - runy w skarbcu).
## Każda wartość to [zwykły, rzadki, legendarny]. "weight" - jak często wypada.
const KINDS := {
	"chests": {"group": "mechanic", "mechanic": "chests", "name": "Bożek Skrzyń", "weight": 1.0,
			"description": "Pachnie kurzem starych skarbców."},
	"shrine": {"group": "mechanic", "mechanic": "shrine", "name": "Bożek Kapliczek", "weight": 1.0,
			"description": "Szepcze modlitwy, których nikt już nie pamięta."},
	"crystal": {"group": "mechanic", "mechanic": "crystal", "name": "Bożek Kryształu", "weight": 1.0,
			"description": "W jego oczach tli się żar Kryształu Watry."},
	"elites": {"group": "mechanic", "mechanic": "elites", "name": "Bożek Wybrańców", "weight": 1.0,
			"description": "Przyciąga najsilniejsze bestie z głębin."},
	"uroczysko": {"group": "mechanic", "mechanic": "uroczysko", "name": "Bożek Uroczyska", "weight": 0.8,
			"description": "Zimny w dłoni, jakby przyszedł z innego świata."},
	"zertwa": {"group": "mechanic", "mechanic": "zertwa", "name": "Bożek Żertwy", "weight": 0.8,
			"description": "Na jego dłoniach zaschła dawna danina."},
	"skarbnik": {"group": "mechanic", "mechanic": "skarbnik", "name": "Bożek Skarbnika", "weight": 0.8,
			"description": "Chichocze cicho, gdy brzęczy złoto."},
	"horde": {"group": "monsters", "name": "Bożek Hordy", "weight": 1.2,
			"description": "Woła potwory z całej okolicy.",
			"mult": {"count": [1.2, 1.4, 1.7]}},
	"fury": {"group": "monsters", "name": "Bożek Gniewu", "weight": 1.2,
			"description": "Budzi w potworach wściekłość.",
			"mult": {"health": [1.15, 1.3, 1.5], "damage": [1.1, 1.2, 1.35], "xp": [1.25, 1.5, 1.8], "loot": [1.1, 1.2, 1.35]}},
	"gold": {"group": "loot", "name": "Bożek Złota", "weight": 1.2,
			"description": "Potwory w lochu noszą pełniejsze sakwy.",
			"mult": {"gold": [1.3, 1.6, 2.0]}},
	"items": {"group": "loot", "name": "Bożek Łupu", "weight": 1.2,
			"description": "Z potworów i skarbca sypie się więcej przedmiotów.",
			"mult": {"loot": [1.25, 1.5, 2.0]}},
	"runes": {"group": "loot", "name": "Bożek Run", "weight": 0.9,
			"description": "Skarbiec strażnika kryje dodatkowe runy.",
			"add": {"vault_runes": [1, 2, 4]}},
	"gems": {"group": "loot", "name": "Bożek Klejnotów", "weight": 0.9,
			"description": "Potwory częściej gubią kamienie szlachetne (po zadaniu jubilera).",
			"mult": {"gems": [2.0, 3.0, 5.0]}},
	"legends": {"group": "loot", "name": "Bożek Legend", "weight": 0.5,
			"description": "Przyciąga przedmioty z dawnych opowieści.",
			"mult": {"legend": [1.5, 2.0, 3.0]}},
	"pride": {"group": "risk", "name": "Bożek Pychy", "weight": 0.8,
			"description": "Potwory biją mocniej, ale łup z lochu ma wyższy poziom.",
			"mult": {"damage": [1.4, 1.6, 1.8]}, "add": {"item_level": [2, 4, 6]}},
	"gloom": {"group": "risk", "name": "Bożek Mroku", "weight": 0.8,
			"description": "Potwory są twardsze, ale łup z lochu bywa rzadszy i cenniejszy.",
			"mult": {"health": [1.5, 1.75, 2.0]}, "add": {"quality": [0.15, 0.25, 0.4]}},
}
const KIND_ORDER: Array[String] = ["chests", "shrine", "crystal", "elites", "uroczysko", "zertwa", "skarbnik",
		"horde", "fury", "gold", "items", "runes", "gems", "legends", "pride", "gloom"]
## Grupy w kolejności pokazywania i ich nazwy.
const GROUP_NAMES := {"mechanic": "Bożek mechaniki", "monsters": "Bożek potworów", "loot": "Bożek łupu",
		"risk": "Bożek ryzyka"}
## Opisy działania (jeden wzór na wartość). Mnożniki pokazywane jako "+N%".
const EFFECT_TEXTS := {
	"count": "+%d%% potworów",
	"health": "Potwory: +%d%% zdrowia",
	"damage": "Potwory: +%d%% obrażeń",
	"xp": "+%d%% doświadczenia",
	"gold": "+%d%% złota",
	"loot": "+%d%% przedmiotów",
	"gems": "+%d%% kamieni szlachetnych z potworów",
	"legend": "+%d%% szansy na legendy",
	"vault_runes": "Skarbiec: +%d run",
	"item_level": "Łup z lochu: +%d poziomu przedmiotu",
	"quality": "Łup z lochu: +%d%% szansy na lepszą rzadkość",
}
## Opisy wzmocnionej mechaniki (legendarny bożek mechaniki).
const POWER_TEXTS := {
	"chests": "Więcej skrzyń",
	"shrine": "Dodatkowa kapliczka",
	"crystal": "Kryształ daje o połowę więcej kamieni",
	"elites": "Więcej elitarnych potworów",
	"uroczysko": "Uroczysko daje o połowę więcej run",
	"zertwa": "Krąg Żertwy: jeden talizman więcej do wyboru",
	"skarbnik": "Dodatkowy Skarbnik",
}

static var _cache := {}


static func id_of(kind: String, rarity: String) -> String:
	return "%s%s_%s" % [PREFIX, kind, rarity]


static func is_idol(id: String) -> bool:
	return id.begins_with(PREFIX) and not data(id).is_empty()


## [rodzaj, rzadkość] z identyfikatora (puste - to nie bożek).
static func parse(id: String) -> Array:
	if not id.begins_with(PREFIX):
		return []
	var rest := id.substr(PREFIX.length())
	for rarity in RARITIES:
		if rest.ends_with("_" + rarity):
			var kind := rest.substr(0, rest.length() - rarity.length() - 1)
			if KINDS.has(kind):
				return [kind, rarity]
	return []


static func kind_of(id: String) -> String:
	var parts := parse(id)
	return parts[0] if not parts.is_empty() else ""


## Dane przedmiotu bożka dla Items.get_data ({} - nie ma takiego bożka). Nazwa i opis po polsku - tłumaczone
## przy pokazywaniu (Items.display_name, Items.describe).
static func data(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var parts := parse(id)
	if parts.is_empty():
		return {}
	var kind: String = parts[0]
	var rarity: String = parts[1]
	var item := {
		"name": "%s %s" % [MATERIAL_NAMES[rarity], KINDS[kind]["name"]],
		"description": KINDS[kind]["description"],
		"icon": load("res://assets/items/idols/%s_%s.png" % [kind, rarity]),
		"rarity": rarity, "sell_price": SELL[rarity], "idol": kind,
	}
	_cache[id] = item
	return item


## Nazwa do pokazania: materiał i rodzaj tłumaczone osobno ("Gliniany" + "Bożek Skrzyń").
static func display_name(id: String) -> String:
	var parts := parse(id)
	if parts.is_empty():
		return ""
	return "%s %s" % [Lang.t(MATERIAL_NAMES[parts[1]]), Lang.t(KINDS[parts[0]]["name"])]


## Linie opisu działania bożka (już przetłumaczone).
static func effect_lines(id: String) -> Array[String]:
	var lines: Array[String] = []
	var parts := parse(id)
	if parts.is_empty():
		return lines
	var kind: Dictionary = KINDS[parts[0]]
	var index := RARITIES.find(parts[1])
	lines.append(Lang.t("%s - %s") % [Lang.t(Items.RARITY_NAMES[parts[1]]), Lang.t(GROUP_NAMES[kind["group"]])])
	if kind["group"] == "mechanic":
		var mechanic: String = Lang.t(Dungeons.MECHANICS[kind["mechanic"]]["name"])
		match index:
			0: lines.append(Lang.t("Mechanika „%s” pojawia się dużo częściej") % mechanic)
			1: lines.append(Lang.t("Mechanika „%s” jest zawsze w lochu") % mechanic)
			_:
				lines.append(Lang.t("Mechanika „%s” jest zawsze w lochu") % mechanic)
				lines.append(Lang.t(POWER_TEXTS[kind["mechanic"]]))
	for key: String in kind.get("mult", {}):
		lines.append(Lang.t(EFFECT_TEXTS[key]) % roundi((float(kind["mult"][key][index]) - 1.0) * 100.0))
	for key: String in kind.get("add", {}):
		var value: float = kind["add"][key][index]
		lines.append(Lang.t(EFFECT_TEXTS[key]) % (roundi(value * 100.0) if key == "quality" else int(value)))
	lines.append(Lang.t("Włóż w slot w oknie lochów Watry - zużywa się przy wejściu."))
	return lines


# ---------------------------------------------------------------- sloty i wypadanie
## Ile slotów na bożki przy danym poziomie Watry. `extra_slots` - na później (drzewko Watry).
static func slot_count(watra_level: int, extra_slots := 0) -> int:
	var count := 0
	for level in SLOT_LEVELS:
		if watra_level >= level:
			count += 1
	return count + extra_slots


## Od którego poziomu Watry działa slot o numerze `index` (0 - nie odblokowuje go poziom Watry).
static func slot_unlock(index: int) -> int:
	return SLOT_LEVELS[index] if index < SLOT_LEVELS.size() else 0


## Szansa na bożka z jednego potwora. `chance_bonus` - mnożnik na później (drzewko Watry).
static func drop_chance(boss: bool, chance_bonus := 1.0) -> float:
	return DROP_CHANCE * (BOSS_MULT if boss else 1.0) * chance_bonus


## Losowy bożek (rodzaj według KINDS "weight", rzadkość według RARITY_WEIGHTS).
static func roll(rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var kinds := {}
	for kind: String in KINDS:
		kinds[kind] = KINDS[kind]["weight"]
	return id_of(Dungeons.weighted(rng, kinds), Dungeons.weighted(rng, RARITY_WEIGHTS))


# ---------------------------------------------------------------- działanie w lochu
## Łączny mnożnik danego rodzaju z bożków (1 - bez zmian).
static func multiplier(ids: Array, key: String) -> float:
	var total := 1.0
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty():
			continue
		var values: Array = KINDS[parts[0]].get("mult", {}).get(key, [])
		if not values.is_empty():
			total *= float(values[RARITIES.find(parts[1])])
	return total


## Suma premii dodawanych danego rodzaju z bożków (0 - bez zmian).
static func added(ids: Array, key: String) -> float:
	var total := 0.0
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty():
			continue
		var values: Array = KINDS[parts[0]].get("add", {}).get(key, [])
		if not values.is_empty():
			total += float(values[RARITIES.find(parts[1])])
	return total


## Premie mechanik z bożków dla Dungeons.roll_mechanics: {"weights", "forced", "power"}.
static func mechanic_bonus(ids: Array) -> Dictionary:
	var weights := {}
	var forced: Array[String] = []
	var power := {}
	for id: String in ids:
		var parts := parse(id)
		if parts.is_empty() or KINDS[parts[0]]["group"] != "mechanic":
			continue
		var mechanic: String = KINDS[parts[0]]["mechanic"]
		match parts[1]:
			"common":
				weights[mechanic] = float(weights.get(mechanic, 1.0)) * MECHANIC_WEIGHT
			"rare":
				if not forced.has(mechanic):
					forced.append(mechanic)
			_:
				if not forced.has(mechanic):
					forced.append(mechanic)
				power[mechanic] = MECHANIC_POWER
	return {"weights": weights, "forced": forced, "power": power}


## Czy bożki można włożyć razem (każdy rodzaj najwyżej raz).
static func can_combine(ids: Array) -> bool:
	var kinds := {}
	for id: String in ids:
		var kind := kind_of(id)
		if kind == "" or kinds.has(kind):
			return false
		kinds[kind] = true
	return true
