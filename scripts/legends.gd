class_name Legends
## Legendarne przedmioty bossów na miejsca inne niż pierścień i kolczyk (broń, zbroja, naszyjnik). Każdy stoi
## na przedmiocie bazowym (ItemBases: statystyki rosnące z poziomem, broń w ręku, rodzaj broni) i nadpisuje
## nazwę, opis, ikonę (assets/items/legends/<id>.png, jeśli jest - inaczej ikona bazy) i dokłada efekt
## (LegendaryEffects). Dane składane raz, przy pierwszym użyciu (Items.get_data).
## Efekty "skill" działają tylko z daną umiejętnością / rodzajem broni - opis to mówi.

const DATA := {
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
