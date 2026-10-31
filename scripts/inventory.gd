class_name Inventory
extends Node
## Ekwipunek: stała liczba slotów, przedmioty łączą się w stosy.
## Przedmioty do założenia nie łączą się i mogą mieć poziom zaklęcia.
## Liczbę miejsc można zmieniać (torby gracza, rozbudowa magazynu).

signal changed
## Przedmioty zmieniły miejsca (przeciąganie, sortowanie): stary indeks -> nowy - np. okno zaklinania
## podąża za przedmiotem, który trzyma.
signal rearranged(old_to_new: Dictionary)

## Kolejność przy sortowaniu: najpierw wyposażenie (w kolejności miejsc na postaci), potem torby,
## przedmioty do użycia, kamienie zaklinające i wspierające, a na końcu reszta.
const SORT_SLOTS: Array[String] = ["weapon", "helmet", "chest", "gloves", "boots", "belt", "earring", "ring", "necklace"]
const SORT_RARITY: Array[String] = ["legendary", "rare", "magic", "common"]

@export var slot_count := 20

## Każdy slot to {} (pusty) albo {"id": String, "count": int}, opcjonalnie z "enchant": int.
var slots: Array[Dictionary] = []


func _ready() -> void:
	for i in slot_count:
		slots.append({})


## Dodaje przedmioty i zwraca liczbę tych, które się nie zmieściły.
func add_item(id: String, amount: int, enchant := 0) -> int:
	var max_stack := Items.max_stack(id)
	# najpierw dopełniamy istniejące stosy (zaklęte przedmioty się nie łączą)
	if enchant == 0:
		for slot in slots:
			if amount == 0:
				break
			if slot.get("id") == id and slot.get("enchant", 0) == 0 and slot["count"] < max_stack:
				var added := mini(amount, max_stack - slot["count"])
				slot["count"] += added
				amount -= added
	# potem zajmujemy puste sloty
	for i in slots.size():
		if amount == 0:
			break
		if slots[i].is_empty():
			var added := mini(amount, max_stack)
			slots[i] = {"id": id, "count": added}
			if enchant > 0:
				slots[i]["enchant"] = enchant
			amount -= added
	changed.emit()
	return amount


## Usuwa `amount` sztuk przedmiotu (od ostatnich slotów, zaklęte na samym końcu).
## Zwraca false, jeśli jest ich za mało.
func remove_item(id: String, amount: int) -> bool:
	if count_of(id) < amount:
		return false
	for enchanted in [false, true]:
		for i in range(slots.size() - 1, -1, -1):
			if amount == 0:
				break
			if slots[i].get("id") == id and (slots[i].get("enchant", 0) > 0) == enchanted:
				var taken := mini(amount, slots[i]["count"])
				slots[i]["count"] -= taken
				amount -= taken
				if slots[i]["count"] == 0:
					slots[i] = {}
	changed.emit()
	return true


## Wyjmuje jedną sztukę z podanego slotu: {"id": String, "enchant": int} ({} jeśli slot pusty).
func take_one(index: int) -> Dictionary:
	return take(index, 1)


## Zabiera do `amount` sztuk ze stosu naraz (jeden sygnał zmiany) - {"id", "enchant", "count"} albo {}.
func take(index: int, amount: int) -> Dictionary:
	var slot := slots[index]
	if slot.is_empty() or amount <= 0:
		return {}
	var count := mini(amount, int(slot.get("count", 1)))
	var taken := {"id": slot["id"], "enchant": slot.get("enchant", 0), "count": count}
	slot["count"] = int(slot.get("count", 1)) - count
	if slot["count"] <= 0:
		slots[index] = {}
	changed.emit()
	return taken


func set_enchant(index: int, level: int) -> void:
	if slots[index].is_empty():
		return
	if level > 0:
		slots[index]["enchant"] = level
	else:
		slots[index].erase("enchant")
	changed.emit()


## Przenosi cały stos ze slotu do innego ekwipunku (np. magazynu). Zwraca liczbę przeniesionych sztuk.
func move_slot_to(index: int, target: Inventory) -> int:
	var slot := slots[index]
	if slot.is_empty():
		return 0
	var left := target.add_item(slot["id"], slot["count"], slot.get("enchant", 0))
	var moved: int = slot["count"] - left
	if left == 0:
		slots[index] = {}
	else:
		slot["count"] = left
	changed.emit()
	return moved


## Przenosi stos na inne miejsce: na puste, na taki sam przedmiot (dopełnia stos) albo zamienia miejscami.
func move(from: int, to: int) -> void:
	if from == to or slots[from].is_empty():
		return
	var moving := slots[from]
	var target := slots[to]
	var max_stack := Items.max_stack(moving["id"])
	if not target.is_empty() and target["id"] == moving["id"] and moving.get("enchant", 0) == 0 \
			and target.get("enchant", 0) == 0 and target["count"] < max_stack:
		var added := mini(moving["count"], max_stack - target["count"])
		target["count"] += added
		moving["count"] -= added
		if moving["count"] <= 0:
			slots[from] = {}
		changed.emit()
		return
	slots[from] = target
	slots[to] = moving
	rearranged.emit({from: to, to: from})
	changed.emit()


## Przenosi stos do innego ekwipunku (plecak <-> magazyn): na wskazane miejsce, jeśli jest wolne,
## inaczej jak move_slot_to (dopełnia stosy, potem pierwsze wolne). W tym samym ekwipunku - move().
## Zwraca liczbę przeniesionych sztuk.
func transfer(index: int, target: Inventory, to_index := -1) -> int:
	var slot := slots[index]
	if slot.is_empty():
		return 0
	if target == self:
		move(index, to_index)
		return int(slot["count"])
	if to_index >= 0 and to_index < target.slots.size() and target.slots[to_index].is_empty():
		target.slots[to_index] = slot.duplicate()
		slots[index] = {}
		target.changed.emit()
		changed.emit()
		return int(target.slots[to_index]["count"])
	return move_slot_to(index, target)


## Kładzie pojedynczy przedmiot na wskazanym miejscu, jeśli jest wolne (zdejmowanie z postaci w wybraną kratkę).
func put(index: int, id: String, enchant := 0) -> bool:
	if index < 0 or index >= slots.size() or not slots[index].is_empty():
		return false
	slots[index] = {"id": id, "count": 1}
	if enchant > 0:
		slots[index]["enchant"] = enchant
	changed.emit()
	return true


## Wyrzuca cały stos z miejsca.
func discard(index: int) -> void:
	if slots[index].is_empty():
		return
	slots[index] = {}
	changed.emit()


## Sortuje plecak (patrz SORT_SLOTS) i łączy niepełne stosy tego samego przedmiotu.
func sort() -> void:
	var entries: Array = []  # [slot, stary indeks]
	var stacks := {}  # id -> łączna liczba sztuk przedmiotów, które się łączą
	for i in slots.size():
		var slot := slots[i]
		if slot.is_empty():
			continue
		if Items.max_stack(slot["id"]) > 1 and slot.get("enchant", 0) == 0:
			stacks[slot["id"]] = stacks.get(slot["id"], 0) + int(slot["count"])
		else:
			entries.append([slot, i])
	for id: String in stacks:
		var left: int = stacks[id]
		while left > 0:
			var count := mini(left, Items.max_stack(id))
			entries.append([{"id": id, "count": count}, -1])
			left -= count
	entries.sort_custom(func(a: Array, b: Array) -> bool: return _sorts_before(_sort_key(a[0]), _sort_key(b[0])))
	var moved := {}
	for i in slots.size():
		slots[i] = entries[i][0] if i < entries.size() else {}
		if i < entries.size() and entries[i][1] >= 0 and entries[i][1] != i:
			moved[entries[i][1]] = i
	if not moved.is_empty():
		rearranged.emit(moved)
	changed.emit()


## Klucz sortowania: [grupa, miejsce, jakość, -poziom przedmiotu, -zaklęcie, nazwa].
static func _sort_key(slot: Dictionary) -> Array:
	var id: String = slot["id"]
	var item := Items.get_data(id)
	if Items.is_equippable(id):
		return [0, SORT_SLOTS.find(item["slot"]), SORT_RARITY.find(item.get("rarity", "common")), -Items.item_level(id),
				-int(slot.get("enchant", 0)), item["name"]]
	var group := 4
	if Items.is_bag(id):
		group = 1
	elif Items.is_usable(id):
		group = 2
	elif item.has("stone") or item.has("enchant_aid"):
		group = 3
	return [group, 0, 0, 0, 0, item["name"]]


static func _sorts_before(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != b[i]:
			return a[i] < b[i]
	return false


## Czy zmieści się jeszcze `amount` sztuk przedmiotu.
func can_add(id: String, amount: int) -> bool:
	var max_stack := Items.max_stack(id)
	var space := 0
	for slot in slots:
		if slot.is_empty():
			space += max_stack
		elif slot["id"] == id and slot.get("enchant", 0) == 0:
			space += max_stack - slot["count"]
	return space >= amount


## Zmienia liczbę miejsc. Przy zmniejszaniu ucina ostatnie miejsca (muszą być puste).
func resize(count: int) -> void:
	while slots.size() < count:
		slots.append({})
	while slots.size() > count:
		slots.pop_back()
	slot_count = count
	changed.emit()


## Czy miejsca od `from` do końca są puste (np. przed zdjęciem torby).
func is_empty_from(from: int) -> bool:
	for i in range(from, slots.size()):
		if not slots[i].is_empty():
			return false
	return true


func get_save_data() -> Array:
	return slots.map(func(slot: Dictionary) -> Dictionary: return slot.duplicate())


func load_save_data(data: Array) -> void:
	if data.size() > slots.size():
		resize(data.size())
	for i in slots.size():
		var saved: Dictionary = data[i] if i < data.size() else {}
		if saved.is_empty() or Items.get_data(str(saved.get("id"))).is_empty():
			slots[i] = {}
		else:
			slots[i] = {"id": str(saved["id"]), "count": int(saved["count"])}
			var enchant := clampi(int(saved.get("enchant", 0)), 0, Enchanting.MAX_LEVEL)
			if enchant > 0:
				slots[i]["enchant"] = enchant
	changed.emit()


func count_of(id: String) -> int:
	var total := 0
	for slot in slots:
		if slot.get("id") == id:
			total += slot["count"]
	return total
