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
	"attack_speed": [0.02, 0.22], "move_speed": [0.02, 0.16], "cast_speed": [0.02, 0.22],
	"physical_damage": [0.03, 0.40], "spell_damage": [0.03, 0.40],
	"damage_percent": [0.02, 0.30], "crit_chance": [0.01, 0.12], "crit_damage": [0.05, 0.60],
	"life_on_hit": [1.0, 15.0], "health_regen": [0.2, 8.0], "mana_regen": [0.2, 6.0], "dodge_chance": [0.01, 0.10],
	"cooldown_reduction": [0.01, 0.15], "gold_find": [0.03, 0.40], "xp_gain": [0.02, 0.25], "area": [0.02, 0.25],
	"potion_power": [0.04, 0.50],
}
## Mnożnik ceny sprzedaży wg jakości.
## Cena skupu przedmiotu z łupu: z poziomu przedmiotu i jakości (nie z poziomu bazy - dawniej rzadki
## przedmiot z Prastarego Lasu szedł za ponad 1600 zł, więcej niż złoto z setek potworów). Sprzedaż ma być
## dodatkiem do złota z potworów (ok. 1/5 dochodu) - sprawdza tests/balance_sim.gd.
const SELL_BASE := 5.0
const SELL_GROWTH := 0.12
const SELL_QUALITY := {COMMON: 1.0, MAGIC: 1.6, RARE: 2.5, LEGENDARY: 6.0}

## Premie możliwe dla rodzaju miejsca na postaci (co najmniej 8 - tyle ma najwięcej legendarny przedmiot).
## Broń i rękawice - walka, zbroja - przetrwanie, biżuteria - wszystkiego po trochu i premie do łupu.
const POOLS := {
	"weapon": ["damage", "attack_speed", "strength", "dexterity", "intelligence", "vitality", "health", "mana",
			"damage_percent", "crit_chance", "crit_damage", "life_on_hit", "mana_regen", "physical_damage", "spell_damage",
			"cast_speed"],
	"helmet": ["armor", "health", "vitality", "mana", "strength", "dexterity", "intelligence", "damage",
			"health_regen", "mana_regen", "cooldown_reduction", "xp_gain"],
	"chest": ["armor", "health", "vitality", "mana", "strength", "dexterity", "intelligence", "damage",
			"health_regen", "dodge_chance"],
	"gloves": ["armor", "health", "attack_speed", "strength", "dexterity", "intelligence", "vitality", "damage",
			"crit_chance", "crit_damage", "life_on_hit", "cast_speed", "physical_damage", "area"],
	"boots": ["armor", "health", "move_speed", "vitality", "mana", "strength", "dexterity", "intelligence",
			"dodge_chance", "health_regen", "gold_find"],
	"ring": ["health", "mana", "damage", "strength", "dexterity", "intelligence", "vitality", "attack_speed",
			"damage_percent", "crit_chance", "crit_damage", "life_on_hit", "mana_regen", "gold_find", "xp_gain",
			"physical_damage", "spell_damage", "cast_speed"],
	"earring": ["health", "mana", "strength", "dexterity", "intelligence", "vitality", "armor", "move_speed",
			"health_regen", "mana_regen", "cooldown_reduction", "dodge_chance", "xp_gain"],
	"belt": ["health", "armor", "vitality", "strength", "dexterity", "intelligence", "mana", "health_regen",
			"mana_regen", "potion_power", "life_on_hit", "dodge_chance"],
	"necklace": ["health", "mana", "damage", "strength", "dexterity", "intelligence", "vitality", "armor",
			"damage_percent", "crit_damage", "cooldown_reduction", "health_regen", "gold_find", "xp_gain", "area"],
}
## Dopisek do nazwy (dopełniacz - pasuje do każdego rodzaju przedmiotu). Tłumaczenie dopisku zawiera przyimek
## ("of the Lynx"), bo nazwa to "<baza> <dopiski>" (compose_name).
const SUFFIXES := {
	"damage": "Rzezi", "attack_speed": "Wiatru", "strength": "Niedźwiedzia", "dexterity": "Rysia",
	"intelligence": "Sowy", "vitality": "Tura", "health": "Dębu", "mana": "Gwiazd", "cast_speed": "Zaklinacza", "physical_damage": "Stali", "spell_damage": "Run",
	"armor": "Żółwia", "move_speed": "Zająca", "damage_percent": "Furii", "crit_chance": "Sokoła",
	"crit_damage": "Kata", "life_on_hit": "Wampira", "health_regen": "Trolla", "mana_regen": "Źródła",
	"dodge_chance": "Cienia", "cooldown_reduction": "Czasu", "gold_find": "Skarbnika", "xp_gain": "Mędrca",
	"area": "Rozmachu", "potion_power": "Zielarza",
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


## Łup z potwora o danym poziomie (Levels): przedmiot z poziomem potwora -1 ... +2.
static func drop_at_level(level: int, quality_bonus := 0.0, min_quality := "", level_bonus := 0) -> String:
	var quality := roll_quality(quality_bonus)
	if min_quality == RARE or (min_quality == MAGIC and quality == COMMON):
		quality = min_quality
	var item_level := clampi(Levels.item_level(level) + level_bonus, 1, MAX_ITEM_LEVEL)
	return generate(base_for(ItemBases.LINES.keys().pick_random(), item_level), quality, item_level)


## Legendarny łup z bossa o danym poziomie.
static func legendary_at_level(base: String, level: int) -> String:
	return generate(base, LEGENDARY, clampi(Levels.item_level(level) + 2, 1, MAX_ITEM_LEVEL))


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
	var recipe := {"base": base, "quality": quality, "level": item_level, "affixes": affixes, "tiers": tiers,
			"name_stats": affixes.keys().slice(0, 2) if quality != LEGENDARY else []}
	# po zadaniu jubilera magiczne i rzadkie przedmioty czasem mają gniazdo na kamień szlachetny
	if Gems.unlocked and quality in [MAGIC, RARE] and randf() < Gems.SOCKET_CHANCE:
		recipe["sockets"] = [{}]
	return register(recipe)


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
			# zaokrąglenie usuwa szum sumy (0.5 + 0.2 = 0.7000000000000001) - po zapisie i odczycie to samo
			stats[stat] = snappedf(float(stats.get(stat, 0.0)) + value, 0.0001)
		else:
			stats[stat] = int(stats.get(stat, 0)) + int(value)
	item["stats"] = stats
	item["base_stats"] = base_stats
	item["affixes"] = affixes
	item["tiers"] = tiers
	item["item_level"] = item_level
	item["rarity"] = recipe["quality"]
	item["name"] = compose_name(recipe)
	item["name_lang"] = TranslationServer.get_locale()
	item["base"] = base
	item["recipe"] = recipe
	# gniazda na kamienie szlachetne (Gems): premie osadzonych kamieni liczą się osobno (Items.stats_of)
	var sockets: Array = recipe.get("sockets", [])
	if not sockets.is_empty():
		var socket_stats := {}
		for gem: Dictionary in sockets:
			var gem_affixes: Dictionary = gem.get("affixes", {})
			for stat: String in gem_affixes:
				var value: float = gem_affixes[stat]
				if _step(stat) == 0.0:
					gem_affixes[stat] = int(value)
				socket_stats[stat] = float(socket_stats.get(stat, 0.0)) + value
		item["sockets"] = sockets
		item["socket_stats"] = socket_stats
	# gniazdo esencji legendy (Essences, kowal): {} - puste, inaczej przepis esencji
	if recipe.has("essence_socket"):
		var essence: Dictionary = recipe["essence_socket"]
		if not essence.is_empty():
			essence["value"] = float(essence["value"])
		item["essence_socket"] = essence
	item.erase("price")  # nie ma go w sklepach
	item["sell_price"] = sell_value(recipe["quality"], item_level)
	Items.generated[id] = item
	return id


## Premie, od których pochodzą dopiski nazwy (pierwsze dwie wylosowane - "name_stats" w przepisie). Starsze
## zapisy trzymały gotową polską nazwę - wtedy dopiski odczytuje się z niej.
static func name_stats(recipe: Dictionary) -> Array:
	if recipe.has("name_stats"):
		return recipe["name_stats"]
	var stats := []
	var old: String = recipe.get("name", "")
	var base_name: String = Items.get_data(recipe.get("base", "")).get("name", "")
	if recipe.get("quality", "") != LEGENDARY and base_name != "" and old.begins_with(base_name):
		for piece: String in old.substr(base_name.length()).split(" i ", false):
			var stat: Variant = SUFFIXES.find_key(piece.strip_edges())
			if stat != null:
				stats.append(stat)
	recipe["name_stats"] = stats
	recipe.erase("name")
	return stats


## Nazwa przedmiotu z przepisu w obecnym języku: baza + dopiski premii (np. "Stalowy miecz Rysia i Sowy");
## legendy - nazwa legendy. Zapis gry nie przechowuje nazwy, tylko przepis.
static func compose_name(recipe: Dictionary) -> String:
	var base_name := Lang.t(Items.get_data(recipe.get("base", "")).get("name", ""))
	if recipe.get("quality", "") == LEGENDARY:
		return base_name
	var suffixes := []
	for stat: String in name_stats(recipe):
		if SUFFIXES.has(stat):
			suffixes.append(Lang.t(SUFFIXES[stat]))
	return base_name if suffixes.is_empty() else "%s %s" % [base_name, Lang.join(suffixes)]


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


static func sell_value(quality: String, item_level: int) -> int:
	return maxi(1, roundi(SELL_BASE * (1.0 + SELL_GROWTH * (item_level - 1)) * SELL_QUALITY.get(quality, 1.0)))


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
		if recipe.has("gem") or recipe.has("essence"):
			if recipe.has("gem"):
				Gems.register(recipe, id)
			else:
				Essences.register(recipe, id)
			Items.generated_serial = maxi(Items.generated_serial, int(id.trim_prefix(PREFIX)))
			continue
		var affixes: Dictionary = recipe.get("affixes", {})
		for stat: String in affixes:
			if _step(stat) == 0.0:
				affixes[stat] = int(affixes[stat])
		register(recipe, id)
		Items.generated_serial = maxi(Items.generated_serial, int(id.trim_prefix(PREFIX)))
