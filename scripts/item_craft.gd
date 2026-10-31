class_name ItemCraft
## Rzemiosło statystyk przedmiotów (warsztat u kowala Bronisława - okno WorkshopWindow; ujście dla trofeów potworów).
## Działania na premiach wylosowanego przedmiotu (przepis Loot):
## - "value": przerzut wartości wybranej premii (ten sam tier - szansa na lepszą i gorszą),
## - "reforge": wybrana premia od nowa (nowy tier i wartość, jak dawne przekuwanie),
## - "remove": usunięcie wybranej premii,
## - "add": nowa losowa premia (gdy jest wolne miejsce - Loot.AFFIX_COUNTS wg rzadkości),
## - "rarity": ulepszenie rzadkości (zwykły -> magiczny -> rzadki) i dolosowanie premii do minimum nowej rzadkości,
## - "chaos" (Runa Zmiany z lochów): wszystkie premie od nowa,
## - "lock" (Runa Pieczęci z lochów i Serce Kryształu): wybrana premia zostaje, wszystkie pozostałe od nowa.
## Koszt: złoto i trofea potworów z krainy pasującej do poziomu przedmiotu (TROPHIES); legendy - LEGEND_FACTOR razy drożej.
## Zwykłe przedmioty ze sklepu dostają przepis przy pierwszym działaniu (nowe id - podmienia je wołający).

const ACTIONS := {
	"value": {"name": "Przerzuć wartość", "trophies": 2, "gold": 1.0, "stat": true,
			"description": "Ta sama premia, nowa wartość w jej zakresie - może wyjść lepsza albo gorsza."},
	"reforge": {"name": "Przekuj premię", "trophies": 3, "gold": 1.5, "stat": true,
			"description": "Wybrana premia losowana od nowa: nowy tier i wartość (rodzaj zostaje)."},
	"remove": {"name": "Usuń premię", "trophies": 3, "gold": 1.5, "stat": true,
			"description": "Wybrana premia znika - zostaje miejsce na nową."},
	"add": {"name": "Dodaj premię", "trophies": 5, "gold": 2.5, "stat": false, "extra": {"iron_ore": 5},
			"description": "Nowa losowa premia, jeśli przedmiot ma wolne miejsce."},
	"rarity": {"name": "Ulepsz rzadkość", "trophies": 8, "gold": 4.0, "stat": false, "extra": {"iron_ore": 10},
			"description": "Zwykły -> magiczny -> rzadki: więcej miejsc na premie, brakujące premie dolosowane."},
	"chaos": {"name": "Runa Zmiany", "trophies": 0, "gold": 1.0, "stat": false, "extra": {"rune_chaos": 1},
			"description": "Wszystkie premie losowane od nowa (rzadkość i poziom zostają)."},
	"lock": {"name": "Pieczęć", "trophies": 0, "gold": 3.0, "stat": true, "extra": {"rune_seal": 1, "crystal_heart": 1},
			"description": "Wybrana premia zostaje zapieczętowana, a wszystkie pozostałe losowane od nowa."},
}
const ORDER: Array[String] = ["value", "reforge", "remove", "add", "rarity", "chaos", "lock"]
## Trofea krain (do kosztu) - kraina wg poziomu przedmiotu.
const TROPHIES := {"forest": "goblin_heart", "fields": "kobold_fuse", "swamp": "frog_tongue", "mountains": "satyr_horn",
		"ancient": "spider_silk", "cemetery": "bone_dust"}
const LEGEND_FACTOR := 3
const GOLD_BASE := 20
const GOLD_PER_LEVEL := 6
## Runy z lochów: szansa w skarbcu strażnika i w nagrodzie Kryształu Watry.
const RUNE_VAULT_CHANCE := 0.35
const RUNE_CRYSTAL_CHANCE := 0.3


static func can_craft(id: String) -> bool:
	return Items.is_equippable(id)


static func quality_of(id: String) -> String:
	return Items.get_data(id).get("recipe", {}).get("quality", Items.get_data(id).get("rarity", "common"))


## Trofeum potworów z krainy pasującej do poziomu przedmiotu.
static func trophy_for(id: String) -> String:
	var level := Items.item_level(id)
	var best := "forest"
	for zone: String in ["forest", "fields", "swamp", "mountains", "ancient", "cemetery"]:
		if level >= Levels.ZONES[zone][0]:
			best = zone
	return TROPHIES[best]


## Koszt działania: {"gold": n, "items": {id: ilość}}.
static func cost(id: String, action: String) -> Dictionary:
	var data: Dictionary = ACTIONS[action]
	var factor := LEGEND_FACTOR if quality_of(id) == Loot.LEGENDARY else 1
	var items := {}
	if int(data["trophies"]) > 0:
		items[trophy_for(id)] = int(data["trophies"]) * factor
	var extra: Dictionary = data.get("extra", {})
	for item: String in extra:
		items[item] = int(items.get(item, 0)) + int(extra[item]) * (factor if item == "iron_ore" else 1)
	var gold := roundi((GOLD_BASE + GOLD_PER_LEVEL * Items.item_level(id)) * float(data["gold"]) * factor)
	return {"gold": gold, "items": items}


## Czy działanie da się wykonać (bez kosztu): "" albo powód.
static func check(id: String, action: String, stat := "") -> String:
	if not can_craft(id):
		return "Tu przerabia się broń, zbroje i biżuterię."
	var affixes: Dictionary = Items.get_data(id).get("recipe", {}).get("affixes", {})
	var quality := quality_of(id)
	if ACTIONS[action]["stat"] and not affixes.has(stat):
		return "Najpierw zaznacz premię."
	match action:
		"add":
			if affixes.size() >= int(Loot.AFFIX_COUNTS[quality][1]):
				return "Brak wolnego miejsca na premię (%s: najwyżej %d)." % [Items.RARITY_NAMES[quality].to_lower(), Loot.AFFIX_COUNTS[quality][1]]
		"rarity":
			if quality in [Loot.RARE, Loot.LEGENDARY]:
				return "Rzadszy już się nie da."
		"chaos":
			if affixes.is_empty() and quality == Loot.COMMON:
				return "Zwykły przedmiot nie ma premii do przerzucenia."
	return ""


## Czy gracz ma czym zapłacić.
static func afford(player: Player, id: String, action: String) -> bool:
	var price := cost(id, action)
	if player.stats.gold < int(price["gold"]):
		return false
	for item: String in price["items"]:
		if player.count_owned(item) < int(price["items"][item]):
			return false
	return true


## Przepis przedmiotu (zwykły przedmiot ze sklepu dostaje go teraz - jak w Gems).
static func recipe_of(id: String) -> Dictionary:
	return Gems._recipe_of(id)


## Wykonuje działanie (bez kosztu - płaci wołający). Zwraca {"id": id przedmiotu po zmianie, "text": opis} albo {}.
static func apply(id: String, action: String, stat := "") -> Dictionary:
	if check(id, action, stat) != "":
		return {}
	var recipe := recipe_of(id)
	var quality: String = recipe["quality"]
	var level := int(recipe.get("level", 1))
	var slot: String = Items.get_data(id)["slot"]
	if not recipe.has("tiers"):
		recipe["tiers"] = {}
	var text := ""
	match action:
		"value":
			var tier := int(recipe["tiers"].get(stat, Loot.roll_tier(level, quality)))
			var before = recipe["affixes"][stat]
			recipe["affixes"][stat] = _roll_value(stat, tier)
			text = "%s: %s -> %s" % [Items.STAT_NAMES.get(stat, stat), Items._stat_text(stat, before), Items._stat_text(stat, recipe["affixes"][stat])]
		"reforge":
			var tier := Loot.roll_tier(level, quality)
			recipe["affixes"][stat] = _roll_value(stat, tier)
			recipe["tiers"][stat] = tier
			text = "Przekuto: %s" % Items._stat_text(stat, recipe["affixes"][stat])
		"remove":
			recipe["affixes"].erase(stat)
			recipe["tiers"].erase(stat)
			text = "Usunięto: %s" % Items.STAT_NAMES.get(stat, stat)
		"add":
			var added := _add_random(recipe, slot, level, quality)
			text = "Nowa premia: %s" % Items._stat_text(added, recipe["affixes"][added])
		"rarity":
			quality = Loot.MAGIC if quality == Loot.COMMON else Loot.RARE
			recipe["quality"] = quality
			while recipe["affixes"].size() < int(Loot.AFFIX_COUNTS[quality][0]):
				_add_random(recipe, slot, level, quality)
			text = "Przedmiot jest teraz: %s" % Items.RARITY_NAMES[quality].to_lower()
		"chaos", "lock":
			var keep := {}
			if action == "lock":
				keep[stat] = [recipe["affixes"][stat], recipe["tiers"].get(stat, 1)]
			recipe["affixes"] = {}
			recipe["tiers"] = {}
			for kept: String in keep:
				recipe["affixes"][kept] = keep[kept][0]
				recipe["tiers"][kept] = keep[kept][1]
			var counts: Array = Loot.AFFIX_COUNTS[quality]
			var target := maxi(randi_range(counts[0], counts[1]), keep.size())
			while recipe["affixes"].size() < target:
				if _add_random(recipe, slot, level, quality) == "":
					break
			text = "Premie przelosowane%s." % (" - %s zostaje" % Items.STAT_NAMES.get(stat, stat) if action == "lock" else "")
	_rename(recipe)
	var new_id := Loot.register(recipe, id if Items.generated.has(id) else "")
	return {"id": new_id, "text": text}


static func _roll_value(stat: String, tier: int) -> Variant:
	var span := Loot.tier_range(stat, tier)
	var step := Loot._step(stat)
	return snappedf(randf_range(span[0], span[1]), step) if step > 0.0 else randi_range(span[0], span[1])


## Losowa premia z puli miejsca, której jeszcze nie ma ("" - pula wyczerpana).
static func _add_random(recipe: Dictionary, slot: String, level: int, quality: String) -> String:
	var pool: Array = Loot.POOLS[slot].filter(func(s: String) -> bool: return not recipe["affixes"].has(s))
	if pool.is_empty():
		return ""
	var stat: String = pool.pick_random()
	var tier := Loot.roll_tier(level, quality)
	recipe["affixes"][stat] = _roll_value(stat, tier)
	recipe["tiers"][stat] = tier
	return stat


## Nazwa jak przy łupie: baza + dopisek z dwóch pierwszych premii (legendy zachowują swoją).
static func _rename(recipe: Dictionary) -> void:
	if recipe["quality"] == Loot.LEGENDARY:
		return
	var name: String = Items.get_data(recipe["base"])["name"]
	if not recipe["affixes"].is_empty():
		var names: Array = recipe["affixes"].keys().slice(0, 2).map(func(s: String) -> String: return Loot.SUFFIXES[s])
		name = "%s %s" % [name, " i ".join(names)]
	recipe["name"] = name
