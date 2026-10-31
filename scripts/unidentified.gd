class_name Unidentified
## Przedmioty niezidentyfikowane (opcja w Ustawieniach - Game.unidentified_loot, domyślnie wyłączona). Gdy włączona,
## magiczna i rzadka broń, zbroja i biżuteria z łupu (Pickup) wypada jako „niezidentyfikowany” przedmiot: rodzaj
## (CATEGORIES) + rzadkość + poziom przedmiotu, np. „Niezidentyfikowana broń (rzadka, poz. 20)”. Takie przedmioty
## układają się w stosy (oszczędzają miejsce w plecaku); identyfikacja (Player.identify - PPM na stosie: jeden,
## Shift+PPM: cały stos, przycisk w plecaku: wszystkie) losuje konkretny przedmiot tego rodzaju, rzadkości i poziomu
## (Loot.generate). Legendy i zwykłe przedmioty wypadają zawsze zidentyfikowane.
## Id: "unid_<rodzaj>_<rzadkość>_<poziom>" - dane przedmiotu powstają z id (Items.get_data), więc zapis nic nie zmienia.

const PREFIX := "unid_"
const CATEGORIES := {
	"weapon": {"name": "Niezidentyfikowana broń", "slots": ["weapon"]},
	"armor": {"name": "Niezidentyfikowana zbroja", "slots": ["helmet", "chest", "gloves", "boots", "belt"]},
	"jewelry": {"name": "Niezidentyfikowana biżuteria", "slots": ["ring", "earring", "necklace"]},
}
const ICONS := {
	"weapon": preload("res://assets/items/unid_weapon.png"),
	"armor": preload("res://assets/items/unid_armor.png"),
	"jewelry": preload("res://assets/items/unid_jewelry.png"),
}
const QUALITY_NAMES := {"magic": "magiczna", "rare": "rzadka"}
## Niezidentyfikowany przedmiot kupiec skupuje taniej niż zidentyfikowany.
const SELL_FACTOR := 0.6

## Czy łup wypada niezidentyfikowany (ustawia Game z ustawień).
static var enabled := false
static var _cache := {}


static func is_unidentified(id: String) -> bool:
	return id.begins_with(PREFIX)


static func id_for(category: String, quality: String, level: int) -> String:
	return "%s%s_%s_%d" % [PREFIX, category, quality, level]


## {"category", "quality", "level"} albo {} (zły id).
static func parse(id: String) -> Dictionary:
	if not is_unidentified(id):
		return {}
	var parts := id.trim_prefix(PREFIX).split("_")
	if parts.size() != 3 or not CATEGORIES.has(parts[0]) or not QUALITY_NAMES.has(parts[1]) or not parts[2].is_valid_int():
		return {}
	return {"category": parts[0], "quality": parts[1], "level": int(parts[2])}


static func category_of_slot(slot: String) -> String:
	for category: String in CATEGORIES:
		if slot in CATEGORIES[category]["slots"]:
			return category
	return ""


## Dane przedmiotu (do Items.get_data): nazwa, opis, ikona rodzaju, rzadkość, poziom i cena skupu.
static func data(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var info := parse(id)
	if info.is_empty():
		return {}
	var category: Dictionary = CATEGORIES[info["category"]]
	var result := {
		"name": "%s (%s, poz. %d)" % [category["name"], QUALITY_NAMES[info["quality"]], info["level"]],
		"description": "Zawinięta w płótno i zapieczętowana - nie wiadomo, co kryje. PPM identyfikuje jeden przedmiot, Shift+PPM cały stos.",
		"icon": ICONS[info["category"]], "rarity": info["quality"], "item_level": info["level"],
		"sell_price": maxi(1, roundi(Loot.sell_value(info["quality"], info["level"]) * SELL_FACTOR)),
		"unidentified": info,
	}
	_cache[id] = result
	return result


## Łup z ziemi: magiczny albo rzadki przedmiot do założenia zamienia się w niezidentyfikowany (gdy opcja włączona).
static func convert(id: String) -> String:
	if not enabled or id == "" or is_unidentified(id):
		return id
	var item := Items.get_data(id)
	var recipe: Dictionary = item.get("recipe", {})
	var quality: String = recipe.get("quality", "")
	if recipe.is_empty() or not QUALITY_NAMES.has(quality):
		return id
	var category := category_of_slot(item.get("slot", ""))
	if category == "":
		return id
	var level := int(recipe.get("level", item.get("item_level", 1)))
	Items.generated.erase(id)
	return id_for(category, quality, level)


## Identyfikacja: nowy przedmiot losowej linii tego rodzaju, z tą rzadkością i poziomem ("" - zły id).
static func identify(id: String) -> String:
	var info := parse(id)
	if info.is_empty():
		return ""
	var lines: Array = []
	for line: String in ItemBases.LINES:
		var first: String = ItemBases.LINES[line][0]
		if category_of_slot(ItemBases.DATA[first]["slot"]) == info["category"]:
			lines.append(line)
	return Loot.generate(Loot.base_for(lines.pick_random(), info["level"]), info["quality"], info["level"])
