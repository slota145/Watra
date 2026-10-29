class_name Equipment
extends Node
## Przedmioty założone na postać: broń, hełm, napierśnik, rękawice, buty,
## dwa kolczyki, dwa pierścienie i naszyjnik. Sumuje premie do statystyk
## (z uwzględnieniem poziomu zaklęcia każdego przedmiotu).

signal changed

const SLOTS: Array[String] = [
	"weapon", "helmet", "chest", "gloves", "boots",
	"earring_1", "earring_2", "ring_1", "ring_2", "necklace",
]
## Typ przedmiotu, który pasuje do danego miejsca.
const SLOT_TYPES := {
	"weapon": "weapon", "helmet": "helmet", "chest": "chest", "gloves": "gloves", "boots": "boots",
	"earring_1": "earring", "earring_2": "earring", "ring_1": "ring", "ring_2": "ring", "necklace": "necklace",
}

## Broń, z którą zaczyna się nowa gra.
@export var starting_weapon := "rusty_sword"

## miejsce -> {} (puste) albo {"id": String, "enchant": int}
var items := {}


func _ready() -> void:
	for slot in SLOTS:
		items[slot] = {}
	items["weapon"] = {"id": starting_weapon, "enchant": 0}


func get_item(slot: String) -> String:
	return items.get(slot, {}).get("id", "")


func get_enchant(slot: String) -> int:
	return items.get(slot, {}).get("enchant", 0)


## Miejsce, w które trafi przedmiot: pierwsze wolne pasujące, a jeśli wszystkie zajęte - pierwsze pasujące.
func slot_for(id: String) -> String:
	var type: String = Items.get_data(id).get("slot", "")
	var fallback := ""
	for slot in SLOTS:
		if SLOT_TYPES[slot] != type:
			continue
		if items[slot].is_empty():
			return slot
		if fallback == "":
			fallback = slot
	return fallback


## Zakłada przedmiot i zwraca ten, który wcześniej zajmował miejsce ({} jeśli żaden).
func equip(id: String, enchant := 0) -> Dictionary:
	var slot := slot_for(id)
	if slot == "":
		return {}
	var previous: Dictionary = items[slot]
	items[slot] = {"id": id, "enchant": enchant}
	changed.emit()
	return previous


## Zakłada przedmiot w konkretne miejsce (np. drugi pierścień) i zwraca poprzedni ({} - pusto albo
## przedmiot nie pasuje do tego miejsca; wtedy nic się nie zmienia - sprawdź fits()).
func equip_to(slot: String, id: String, enchant := 0) -> Dictionary:
	if not fits(slot, id):
		return {}
	var previous: Dictionary = items[slot]
	items[slot] = {"id": id, "enchant": enchant}
	changed.emit()
	return previous


## Czy przedmiot pasuje do miejsca na postaci.
func fits(slot: String, id: String) -> bool:
	return SLOT_TYPES.get(slot, "") != "" and SLOT_TYPES[slot] == Items.get_data(id).get("slot", "")


## Zdejmuje przedmiot z miejsca i zwraca go ({} jeśli było puste).
func unequip(slot: String) -> Dictionary:
	var previous: Dictionary = items.get(slot, {})
	if not previous.is_empty():
		items[slot] = {}
		changed.emit()
	return previous


func set_enchant(slot: String, level: int) -> void:
	if items[slot].is_empty():
		return
	items[slot]["enchant"] = level
	changed.emit()


## Dane założonej broni ({} = walka gołymi pięściami).
func weapon() -> Dictionary:
	return Items.get_data(get_item("weapon")).get("weapon", {})


## Obrażenia założonej broni z zaklęciem ([] = brak broni).
func weapon_damage() -> Array:
	return Items.weapon_damage(get_item("weapon"), get_enchant("weapon"))


## Suma premii danej statystyki ze wszystkich założonych przedmiotów.
func bonus(stat: String) -> float:
	var total := 0.0
	for slot in SLOTS:
		if not items[slot].is_empty():
			total += float(Items.stats_of(items[slot]["id"], items[slot]["enchant"]).get(stat, 0.0))
	return total


## Łączna moc efektu legendarnego danego rodzaju z założonych przedmiotów
## (dwa takie same łączą się jak niezależne losowania).
func effect_power(kind: String) -> float:
	var miss := 1.0
	for slot in SLOTS:
		if items[slot].is_empty():
			continue
		var id: String = items[slot]["id"]
		if Items.get_data(id).get("effect", {}).get("kind", "") == kind:
			miss *= 1.0 - Items.effect_chance(id, items[slot]["enchant"])
	return 1.0 - miss


func get_save_data() -> Dictionary:
	var data := {}
	for slot in SLOTS:
		data[slot] = items[slot].duplicate()
	return data


func load_save_data(data: Dictionary) -> void:
	for slot in SLOTS:
		var saved: Variant = data.get(slot, {})
		# starsze zapisy trzymały samo id przedmiotu
		var id := str(saved) if saved is String else str(saved.get("id", ""))
		var enchant := 0 if saved is String else clampi(int(saved.get("enchant", 0)), 0, Enchanting.MAX_LEVEL)
		if id != "" and Items.get_data(id).get("slot", "") == SLOT_TYPES[slot]:
			items[slot] = {"id": id, "enchant": enchant}
		else:
			items[slot] = {}
	changed.emit()
