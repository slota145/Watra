class_name Talismans
## Talizmany (jak idole w Last Epoch) - łup z Kręgu Żertwy w lochach Watry (scripts/zertwa.gd). Talizman to wylosowany
## przedmiot (Items.generated, przepis z "talisman") wkładany w siatkę talizmanów postaci (GRID kratek, okno
## TalismanWindow; dane w Equipment.talismans). Kształty: mały 1x1, podłużny 1x2, szeroki 2x1 i wielki 2x2 - większy
## zajmuje więcej miejsca, ale ma więcej premii (SHAPES "affixes") i mocniejsze (SHAPES "power").
## Premie: z puli POOL, wartość z tierów łupu (Loot.roll_tier / tier_range) na poziomie przedmiotu, razy VALUE_SCALE
## i moc kształtu. Rzadki talizman (tylko kształty większe niż 1x1) ma dodatkowo efekt warunkowy - jeden z efektów
## legend (EFFECTS, np. żądza krwi po zabójstwach, nieśmiertelność przy śmiertelnym ciosie); efekty z talizmanów
## łączą się z legendami i esencjami w Equipment.effect_power.

## Siatka talizmanów postaci (kolumny x rzędy).
const GRID := Vector2i(4, 3)
## Kształty: rozmiar w kratkach, liczba premii, moc premii i efektu, waga losowania i nazwa.
const SHAPES := {
	"small": {"size": Vector2i(1, 1), "affixes": 1, "power": 1.0, "weight": 4.0, "name": "Mały talizman"},
	"long": {"size": Vector2i(1, 2), "affixes": 2, "power": 1.15, "weight": 3.0, "name": "Podłużny talizman"},
	"wide": {"size": Vector2i(2, 1), "affixes": 2, "power": 1.15, "weight": 3.0, "name": "Szeroki talizman"},
	"large": {"size": Vector2i(2, 2), "affixes": 3, "power": 1.35, "weight": 1.5, "name": "Wielki talizman"},
}
const SHAPE_ORDER: Array[String] = ["small", "long", "wide", "large"]
## Premie talizmanów (wszystkie premie łupu poza obrażeniami płaskimi, pancerzem i pojedynczymi odpornościami - to
## zostaje przedmiotom; odporności na wszystkie żywioły i na Nawię - tak).
const POOL: Array[String] = ["health", "mana", "strength", "dexterity", "intelligence", "vitality", "attack_speed",
		"cast_speed", "move_speed", "physical_damage", "spell_damage", "damage_percent", "crit_chance", "crit_damage",
		"life_on_hit", "health_regen", "mana_regen", "dodge_chance", "cooldown_reduction", "gold_find", "xp_gain",
		"area", "potion_power", "all_resistances", "nawia_resistance", "elemental_damage"]
## Wartość premii talizmanu względem premii przedmiotu z tego samego tieru (przed mocą kształtu).
const VALUE_SCALE := 0.8
## Efekty warunkowe rzadkich talizmanów: rodzaj efektu legendy (Items.EFFECT_TEXTS) -> [najmniej, najwięcej]
## przed mocą kształtu (mniej więcej połowa siły legendy).
const EFFECTS := {
	"bloodlust": [0.02, 0.04],
	"devour": [0.12, 0.22],
	"undying": [0.12, 0.22],
	"bone_armor": [0.05, 0.09],
	"leech": [0.01, 0.02],
	"thorns": [0.12, 0.22],
	"burrow": [0.2, 0.32],
	"kaboom": [0.1, 0.2],
	"potion_saver": [0.1, 0.2],
	"wind_shield": [0.12, 0.22],
}
## Dopiski nazwy rzadkich talizmanów od efektu.
const EFFECT_NAMES := {
	"bloodlust": "Szału", "devour": "Pożeracza", "undying": "Nieśmiertelnego", "bone_armor": "Kościanej Straży",
	"leech": "Upiora", "thorns": "Głogu", "burrow": "Kreta", "kaboom": "Iskry", "potion_saver": "Zielarki",
	"wind_shield": "Strzyboga",
}
## Cena skupu: podstawa wg rzadkości razy liczba kratek, plus za poziom przedmiotu.
const SELL := {"magic": 30, "rare": 80}
const SELL_PER_LEVEL := 2


static func is_talisman(id: String) -> bool:
	return Items.get_data(id).has("talisman")


## Rozmiar talizmanu w kratkach siatki (Vector2i.ZERO - to nie talizman).
static func size_of(id: String) -> Vector2i:
	var data: Dictionary = Items.get_data(id).get("talisman", {})
	return SHAPES[data["shape"]]["size"] if not data.is_empty() else Vector2i.ZERO


## Nowy talizman: `quality` - "magic" albo "rare" (rzadki ma efekt warunkowy - "" losuje), `shape` - kształt
## ("" - losowy wg wag); poziom przedmiotu wyznacza okno tierów premii.
static func roll(item_level: int, quality := "magic", shape := "", rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if shape == "":
		var weights := {}
		for key: String in SHAPES:
			weights[key] = SHAPES[key]["weight"]
		shape = Dungeons.weighted(rng, weights)
	# efekt warunkowy nie mieści się w najmniejszym talizmanie
	if quality == "rare" and shape == "small":
		shape = ["long", "wide"][rng.randi() % 2]
	var power: float = SHAPES[shape]["power"]
	var pool := POOL.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var affixes := {}
	var tiers := {}
	for stat: String in pool.slice(0, SHAPES[shape]["affixes"]):
		var tier := Loot.roll_tier(item_level, quality)
		var span := Loot.tier_range(stat, tier)
		affixes[stat] = _value(stat, rng.randf_range(float(span[0]), float(span[1])) * VALUE_SCALE * power)
		tiers[stat] = tier
	var recipe := {"talisman": true, "shape": shape, "quality": quality, "level": item_level,
			"affixes": affixes, "tiers": tiers}
	if quality == "rare":
		var kinds := EFFECTS.keys()
		var kind: String = kinds[rng.randi() % kinds.size()]
		var span: Array = EFFECTS[kind]
		recipe["effect"] = {"kind": kind, "value": snappedf(rng.randf_range(span[0], span[1]) * power, 0.001)}
	return register(recipe)


static func _value(stat: String, value: float) -> float:
	var step := Loot._step(stat)
	return snappedf(maxf(value, step), step) if step > 0.0 else float(maxi(1, roundi(value)))


## Rejestruje talizman z przepisu (także przy wczytaniu zapisu - Loot.import i po zmianie języka).
static func register(recipe: Dictionary, id := "") -> String:
	var shape: String = recipe.get("shape", "small")
	if not SHAPES.has(shape):
		shape = "small"
	recipe["shape"] = shape
	if id == "":
		Items.generated_serial += 1
		id = Loot.PREFIX + str(Items.generated_serial)
	var quality: String = recipe.get("quality", "magic")
	var item_level := clampi(int(recipe.get("level", 1)), 1, Loot.MAX_ITEM_LEVEL)
	recipe["level"] = item_level
	var stats := {}
	var tiers := {}
	# premie zawsze w kolejności puli (zapis JSON układa klucze alfabetycznie)
	for stat: String in POOL:
		if recipe["affixes"].has(stat):
			var value: float = recipe["affixes"][stat]
			stats[stat] = value if Loot._step(stat) > 0.0 else int(value)
			if recipe.get("tiers", {}).has(stat):
				tiers[stat] = int(recipe["tiers"][stat])
	recipe["affixes"] = stats
	recipe["tiers"] = tiers
	var size: Vector2i = SHAPES[shape]["size"]
	var item := {
		"name": compose_name(recipe),
		"description": "Talizman. Przeciągnij go do siatki talizmanów (przycisk „Talizmany” w ekwipunku) - działa, dopóki w niej leży.",
		"icon": icon_of(shape, quality),
		"rarity": quality,
		"talisman": {"shape": shape},
		"stats": stats.duplicate(),
		"base_stats": {},
		"affixes": stats,
		"tiers": tiers,
		"item_level": item_level,
		"sell_price": (SELL.get(quality, 30) * size.x * size.y) + SELL_PER_LEVEL * item_level,
		"recipe": recipe,
		"name_lang": TranslationServer.get_locale(),
	}
	var effect: Dictionary = recipe.get("effect", {})
	if not effect.is_empty() and EFFECTS.has(effect.get("kind", "")):
		effect["value"] = float(effect["value"])
		item["effect"] = {"kind": effect["kind"], "chance": effect["value"], "per_level": 0.0}
	Items.generated[id] = item
	return id


## Nazwa z przepisu w obecnym języku: kształt, a rzadki - z dopiskiem efektu ("Wielki talizman Szału").
static func compose_name(recipe: Dictionary) -> String:
	var base := Lang.t(SHAPES.get(recipe.get("shape", "small"), SHAPES["small"])["name"])
	var kind: String = recipe.get("effect", {}).get("kind", "")
	return base if not EFFECT_NAMES.has(kind) else "%s %s" % [base, Lang.t(EFFECT_NAMES[kind])]


## Ikona talizmanu: kształt (rozmiar obrazka pasuje do kratek siatki) i rzadkość (assets/items/talismans,
## tools/talisman_art.py).
static func icon_of(shape: String, quality: String) -> Texture2D:
	return load("res://assets/items/talismans/%s_%s.png" % [shape, "rare" if quality == "rare" else "magic"])


## Oferta Kręgu Żertwy: `count` różnych talizmanów; `bonus` 0..1 (danina ponad próg) podnosi szansę na rzadkie
## i większe kształty. Pierwszy talizman w ofercie zawsze jest co najmniej podłużny albo szeroki.
static func roll_offer(item_level: int, bonus: float, count := 3, rng: RandomNumberGenerator = null) -> Array[String]:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	bonus = clampf(bonus, 0.0, 1.0)
	var rare_chance := Dungeons.ZER_RARE_CHANCE + Dungeons.ZER_RARE_BONUS * bonus
	var result: Array[String] = []
	for i in count:
		var quality := "rare" if rng.randf() < rare_chance else "magic"
		var shape := ""
		if rng.randf() < Dungeons.ZER_LARGE_CHANCE + Dungeons.ZER_LARGE_BONUS * bonus:
			shape = "large"
		elif i == 0:
			shape = ["long", "wide"][rng.randi() % 2]
		result.append(roll(item_level, quality, shape, rng))
	return result
