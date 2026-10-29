class_name Loot
## Losowe przedmioty. Każdy łup to osobny wpis w Items.generated ("gen_<n>") - kopia przedmiotu bazowego
## z poziomem przedmiotu, dolosowanymi premiami (affiksami) i nazwą z dopiskiem ("Żelazny miecz Niedźwiedzia",
## "Skórzane buty Zająca i Dębu"). Dzięki temu zaklinanie, handel, magazyn i mędrzec działają na nich bez
## zmian. Zapis gry przechowuje tylko przepis (baza, jakość, poziom, premie z tierami, nazwa).
##
## Poziom przedmiotu (1-100) skaluje statystyki bazowe (obrażenia broni, pancerz, premie biżuterii)
## i wyznacza okno tierów premii: tier 45 jest najsłabszy, 1 najlepszy. Wyższy poziom odblokowuje lepsze
## tiery i odcina najsłabsze (okno ma TIER_WINDOW tierów). Liczba premii zależy od jakości: zwykły 0-2,
## magiczny 2-4, rzadki 4-6, legendarny 6-8 - a im mniej premii, tym większa szansa na lepsze tiery.

const COMMON := "common"
const MAGIC := "magic"
const RARE := "rare"
const LEGENDARY := "legendary"
const PREFIX := "gen_"

const MAX_ITEM_LEVEL := 100
const TIERS := 45
## Ile tierów obejmuje okno losowania na danym poziomie przedmiotu (od najlepszego dostępnego w dół).
const TIER_WINDOW := 10
## O ile rośnie statystyka bazowa na każdy poziom przedmiotu (poziom 100 - prawie 7 razy więcej niż 1).
const BASE_GROWTH := 0.06
## Liczba premii [min, max] wg jakości.
const AFFIX_COUNTS := {COMMON: [0, 2], MAGIC: [2, 4], RARE: [4, 6], LEGENDARY: [6, 8]}
## Skłonność do lepszych tierów: wykładnik losowania pozycji w oknie (więcej = bliżej najlepszego tieru).
const TIER_BIAS := {COMMON: 3.0, MAGIC: 2.0, RARE: 1.4, LEGENDARY: 1.0}
## Poziom przedmiotów [min, max] wg poziomu łupu potworów (1 - las, 2 - rozlewiska, 3 - góry, Prastary Las
## i bossowie); bossowie dokładają BOSS_LEVEL_BONUS.
const LOOT_ITEM_LEVELS := {1: [1, 12], 2: [10, 24], 3: [20, 36]}
const BOSS_LEVEL_BONUS := 5
## Wartość premii na tierze 45 i na tierze 1 - zakresy tierów pomiędzy rosną geometrycznie.
const TIER_VALUES := {
	"health": [5.0, 200.0], "mana": [4.0, 140.0], "armor": [1.0, 45.0], "damage": [1.0, 35.0],
	"strength": [1.0, 35.0], "dexterity": [1.0, 35.0], "intelligence": [1.0, 35.0], "vitality": [1.0, 35.0],
	"attack_speed": [0.02, 0.22], "move_speed": [0.02, 0.16],
	"damage_percent": [0.02, 0.30], "crit_chance": [0.01, 0.12], "crit_damage": [0.05, 0.60],
	"life_on_hit": [1.0, 15.0], "health_regen": [0.2, 8.0], "mana_regen": [0.2, 6.0], "dodge_chance": [0.01, 0.10],
	"cooldown_reduction": [0.01, 0.15], "gold_find": [0.03, 0.40], "xp_gain": [0.02, 0.25],
}
## Mnożnik ceny sprzedaży wg jakości.
const PRICE_FACTORS := {COMMON: 1, MAGIC: 2, RARE: 4, LEGENDARY: 1}

## Premie możliwe dla rodzaju miejsca na postaci (co najmniej 8 - tyle ma najwięcej legendarny przedmiot).
## Broń i rękawice - walka, zbroja - przetrwanie, biżuteria - wszystkiego po trochu i premie do łupu.
const POOLS := {
	"weapon": ["damage", "attack_speed", "strength", "dexterity", "intelligence", "vitality", "health", "mana",
			"damage_percent", "crit_chance", "crit_damage", "life_on_hit", "mana_regen"],
	"helmet": ["armor", "health", "vitality", "mana", "strength", "dexterity", "intelligence", "damage",
			"health_regen", "mana_regen", "cooldown_reduction", "xp_gain"],
	"chest": ["armor", "health", "vitality", "mana", "strength", "dexterity", "intelligence", "damage",
			"health_regen", "dodge_chance"],
	"gloves": ["armor", "health", "attack_speed", "strength", "dexterity", "intelligence", "vitality", "damage",
			"crit_chance", "crit_damage", "life_on_hit"],
	"boots": ["armor", "health", "move_speed", "vitality", "mana", "strength", "dexterity", "intelligence",
			"dodge_chance", "health_regen", "gold_find"],
	"ring": ["health", "mana", "damage", "strength", "dexterity", "intelligence", "vitality", "attack_speed",
			"damage_percent", "crit_chance", "crit_damage", "life_on_hit", "mana_regen", "gold_find", "xp_gain"],
	"earring": ["health", "mana", "strength", "dexterity", "intelligence", "vitality", "armor", "move_speed",
			"health_regen", "mana_regen", "cooldown_reduction", "dodge_chance", "xp_gain"],
	"necklace": ["health", "mana", "damage", "strength", "dexterity", "intelligence", "vitality", "armor",
			"damage_percent", "crit_damage", "cooldown_reduction", "health_regen", "gold_find", "xp_gain"],
}
## Dopisek do nazwy (dopełniacz - pasuje do każdego rodzaju przedmiotu).
const SUFFIXES := {
	"damage": "Rzezi", "attack_speed": "Wiatru", "strength": "Niedźwiedzia", "dexterity": "Rysia",
	"intelligence": "Sowy", "vitality": "Tura", "health": "Dębu", "mana": "Gwiazd",
	"armor": "Żółwia", "move_speed": "Zająca", "damage_percent": "Furii", "crit_chance": "Sokoła",
	"crit_damage": "Kata", "life_on_hit": "Wampira", "health_regen": "Trolla", "mana_regen": "Źródła",
	"dodge_chance": "Cienia", "cooldown_reduction": "Czasu", "gold_find": "Skarbnika", "xp_gain": "Mędrca",
}


## Mnożnik statystyk bazowych na danym poziomie przedmiotu.
static func base_multiplier(item_level: int) -> float:
	return 1.0 + (clampi(item_level, 1, MAX_ITEM_LEVEL) - 1) * BASE_GROWTH


## Najlepszy tier dostępny na danym poziomie przedmiotu (poziom 1 - tylko 45, poziom 100 - aż do 1).
static func best_tier(item_level: int) -> int:
	return TIERS - roundi((clampi(item_level, 1, MAX_ITEM_LEVEL) - 1) * (TIERS - 1) / float(MAX_ITEM_LEVEL - 1))


## Najsłabszy tier dostępny na danym poziomie przedmiotu.
static func worst_tier(item_level: int) -> int:
	return mini(TIERS, best_tier(item_level) + TIER_WINDOW - 1)


## Losuje tier z okna poziomu przedmiotu - mniej premii (niższa jakość) przesuwa los ku lepszym tierom.
static func roll_tier(item_level: int, quality: String) -> int:
	var best := best_tier(item_level)
	var span := worst_tier(item_level) - best + 1
	var t := pow(randf(), TIER_BIAS.get(quality, 1.0))
	return best + mini(int(t * span), span - 1)


## Zakres wartości premii [min, max] na danym tierze.
static func tier_range(stat: String, tier: int) -> Array:
	var ends: Array = TIER_VALUES[stat]
	var x := float(TIERS - clampi(tier, 1, TIERS)) / TIERS
	var low: float = ends[0] * pow(ends[1] / ends[0], x)
	var high: float = ends[0] * pow(ends[1] / ends[0], x + 1.0 / TIERS)
	var step := _step(stat)
	if step > 0.0:
		return [snappedf(low, step), maxf(snappedf(high, step), snappedf(low, step))]
	return [roundi(low), maxi(roundi(high), roundi(low))]


## Dokładność wartości premii: procenty co 1%, regeneracja co 0,1, reszta w całych (0).
static func _step(stat: String) -> float:
	if stat in Items.PERCENT_STATS:
		return 0.01
	if stat in Items.DECIMAL_STATS:
		return 0.1
	return 0.0


## Losuje jakość: common, magic albo rare. `bonus` zwiększa szanse (bossowie).
static func roll_quality(bonus := 0.0) -> String:
	var r := randf()
	if r < 0.08 + bonus:
		return RARE
	if r < 0.4 + bonus * 2.0:
		return MAGIC
	return COMMON


## Poziom przedmiotu z łupu potwora o danym poziomie łupu.
static func roll_item_level(loot_level: int, bonus := 0) -> int:
	var span: Array = LOOT_ITEM_LEVELS.get(loot_level, [1, 1])
	return clampi(randi_range(span[0], span[1]) + bonus, 1, MAX_ITEM_LEVEL)


## Poziom linii przedmiotów (0-4) pasujący do poziomu przedmiotu - od niego zależy wygląd i nazwa bazy.
static func tier_of(item_level: int) -> int:
	for tier in ItemBases.TIER_LEVELS.size():
		if item_level <= ItemBases.TIER_LEVELS[tier][1]:
			return tier
	return ItemBases.TIER_LEVELS.size() - 1


## Przedmiot bazowy danej linii (miecz, kaptur...) dla poziomu przedmiotu.
static func base_for(line: String, item_level: int) -> String:
	var tiers: Array = ItemBases.LINES[line]
	return tiers[mini(tier_of(item_level), tiers.size() - 1)]


## Łup z potwora: losowy przedmiot z losową jakością i poziomem. `level_bonus` - bossowie.
static func random_drop(loot_level: int, quality_bonus := 0.0, min_quality := "", level_bonus := 0) -> String:
	var quality := roll_quality(quality_bonus)
	if min_quality == RARE or (min_quality == MAGIC and quality == COMMON):
		quality = min_quality
	var item_level := roll_item_level(loot_level, level_bonus)
	return generate(base_for(ItemBases.LINES.keys().pick_random(), item_level), quality, item_level)


## Legendarny łup z bossa: jego unikalny przedmiot z poziomem i premiami.
static func legendary(base: String, loot_level: int) -> String:
	return generate(base, LEGENDARY, roll_item_level(loot_level, BOSS_LEVEL_BONUS))


## Nowy przedmiot z poziomem i dolosowanymi premiami.
static func generate(base: String, quality: String, item_level: int) -> String:
	var data: Dictionary = Items.get_data(base)
	var pool: Array = POOLS[data["slot"]].duplicate()
	pool.shuffle()
	var counts: Array = AFFIX_COUNTS[quality]
	var affixes := {}
	var tiers := {}
	for stat: String in pool.slice(0, mini(randi_range(counts[0], counts[1]), pool.size())):
		var tier := roll_tier(item_level, quality)
		var span := tier_range(stat, tier)
		var step := _step(stat)
		affixes[stat] = snappedf(randf_range(span[0], span[1]), step) if step > 0.0 else randi_range(span[0], span[1])
		tiers[stat] = tier
	var item_name: String = data["name"]
	if quality != LEGENDARY and not affixes.is_empty():
		var names: Array = affixes.keys().slice(0, 2).map(func(stat: String) -> String: return SUFFIXES[stat])
		item_name = "%s %s" % [item_name, " i ".join(names)]
	return register({"base": base, "quality": quality, "level": item_level, "affixes": affixes, "tiers": tiers,
			"name": item_name})


## Rejestruje przedmiot z przepisu; `id` podany przy wczytywaniu zapisu. Dawne przepisy (bez poziomu
## i tierów) dostają poziom 1.
static func register(recipe: Dictionary, id := "") -> String:
	var base: String = recipe["base"]
	if Items.get_data(base).is_empty():
		return ""
	if id == "":
		Items.generated_serial += 1
		id = PREFIX + str(Items.generated_serial)
	var item: Dictionary = Items.get_data(base).duplicate(true)
	# wygląd wersji magicznej albo rzadkiej (ikona i broń w ręku); legendy mają własny
	var look: Dictionary = item.get("looks", {}).get(recipe["quality"], {})
	if look.has("icon"):
		item["icon"] = look["icon"]
	if look.has("weapon"):
		item["weapon"] = look["weapon"].duplicate(true)
	item.erase("looks")
	var item_level := clampi(int(recipe.get("level", 1)), 1, MAX_ITEM_LEVEL)
	recipe["level"] = item_level
	# premie zawsze w tej samej kolejności (zapis JSON układa klucze alfabetycznie)
	var affixes := {}
	var tiers := {}
	for stat: String in POOLS[item["slot"]]:
		if recipe["affixes"].has(stat):
			affixes[stat] = recipe["affixes"][stat]
			if recipe.get("tiers", {}).has(stat):
				tiers[stat] = int(recipe["tiers"][stat])
	recipe["affixes"] = affixes
	recipe["tiers"] = tiers
	# statystyki bazowe rosną z poziomem przedmiotu (procentowe zostają)
	var multiplier := base_multiplier(item_level)
	var base_stats := {}
	for stat: String in item.get("stats", {}):
		var value: float = item["stats"][stat]
		base_stats[stat] = value if stat in Items.PERCENT_STATS else maxi(roundi(value * multiplier), 1)
	if item.has("weapon"):
		var damage: Array = item["weapon"]["damage"]
		item["weapon"]["damage"] = [roundi(damage[0] * multiplier), roundi(damage[1] * multiplier)]
	var stats := base_stats.duplicate()
	for stat: String in affixes:
		var value: float = affixes[stat]
		if _step(stat) > 0.0:
			stats[stat] = float(stats.get(stat, 0.0)) + value
		else:
			stats[stat] = int(stats.get(stat, 0)) + int(value)
	item["stats"] = stats
	item["base_stats"] = base_stats
	item["affixes"] = affixes
	item["tiers"] = tiers
	item["item_level"] = item_level
	item["rarity"] = recipe["quality"]
	item["name"] = recipe["name"]
	item["base"] = base
	item["recipe"] = recipe
	item.erase("price")  # nie ma go w sklepach
	item["sell_price"] = roundi(int(item.get("sell_price", 5)) * PRICE_FACTORS.get(recipe["quality"], 1)
			* (1.0 + (item_level - 1) * 0.05))
	Items.generated[id] = item
	return id


## Przekuwanie u kowala (warsztat płatnerza): jedna losowa premia przedmiotu losowana od nowa (nowy tier
## i wartość wg poziomu i jakości przedmiotu - jak przy łupie). Zwraca {"id": nowe id, "stat": premia,
## "before": stara wartość, "after": nowa} albo {} (brak premii / legenda).
static func reforge(id: String) -> Dictionary:
	var data := Items.get_data(id)
	var recipe: Dictionary = data.get("recipe", {}).duplicate(true)
	if recipe.is_empty() or recipe["quality"] == LEGENDARY or recipe["affixes"].is_empty():
		return {}
	var stat: String = recipe["affixes"].keys().pick_random()
	var before: float = recipe["affixes"][stat]
	var tier := roll_tier(int(recipe["level"]), recipe["quality"])
	var span := tier_range(stat, tier)
	var step := _step(stat)
	recipe["affixes"][stat] = snappedf(randf_range(span[0], span[1]), step) if step > 0.0 else randi_range(span[0], span[1])
	recipe["tiers"][stat] = tier
	var new_id := register(recipe)
	return {"id": new_id, "stat": stat, "before": before, "after": recipe["affixes"][stat]}


static func is_generated(id: String) -> bool:
	return id.begins_with(PREFIX)


## Przepisy przedmiotów, które gracz ma (plecak, postać, magazyn) - do zapisu gry.
static func export_used(ids: Array) -> Dictionary:
	var result := {}
	for id in ids:
		if Items.generated.has(id):
			result[id] = Items.generated[id]["recipe"]
	return result


## Odtwarza przedmioty z zapisu (przed wczytaniem plecaka i postaci).
static func import(data: Dictionary) -> void:
	for id: String in data:
		var recipe: Dictionary = data[id]
		var affixes: Dictionary = recipe.get("affixes", {})
		for stat: String in affixes:
			if _step(stat) == 0.0:
				affixes[stat] = int(affixes[stat])
		register(recipe, id)
		Items.generated_serial = maxi(Items.generated_serial, int(id.trim_prefix(PREFIX)))
