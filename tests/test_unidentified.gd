extends SceneTree
## Przedmioty niezidentyfikowane (Unidentified): opcja wyłączona - łup bez zmian; włączona - magiczne i rzadkie
## przedmioty z łupu (Pickup) zamieniają się w niezidentyfikowane (rodzaj, rzadkość, poziom), zwykłe i legendy nie;
## stosy w plecaku, cena skupu, identyfikacja PPM (jeden) i Shift+PPM (cały stos) w oknie plecaka, pełny plecak,
## „Zidentyfikuj wszystko”, zapis plecaka.

var _world: Node
var _frame := 0
var _fails := 0
var U = null
var I = null
var L = null


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _click(window, index: int, shift: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.shift_pressed = shift
	window._on_bag_input(event, index)


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame == 3:
		U = load("res://scripts/unidentified.gd")
		I = load("res://scripts/items.gd")
		L = load("res://scripts/loot.gd")
	if _frame != 6:
		return false
	var p = _world.player
	var window = _world.hud.inventory_window
	window.visible = true  # zamknięte okno się nie odświeża
	for i in p.inventory.slots.size():
		p.inventory.slots[i] = {}
	p.inventory.changed.emit()
	# opcja wyłączona
	U.enabled = false
	var rare: String = L.drop_at_level(20, 0.0, "rare")
	check("wyłączone - bez zmian", U.convert(rare) == rare)
	# opcja włączona
	U.enabled = true
	var unid: String = U.convert(rare)
	var info: Dictionary = U.parse(unid)
	var category: String = U.category_of_slot(I.get_data(rare).get("slot", "")) if I.generated.has(rare) else info.get("category", "")
	check("rzadki - niezidentyfikowany", U.is_unidentified(unid) and info["quality"] == "rare" and info["level"] >= 1
			and not I.generated.has(rare), unid)
	var data: Dictionary = I.get_data(unid)
	check("dane przedmiotu", data["name"].begins_with("Niezidentyfikowan") and data["icon"] != null and data["rarity"] == "rare"
			and int(data["sell_price"]) > 0 and I.item_level(unid) == info["level"] and not I.is_equippable(unid), data["name"])
	var common: String = L.generate(L.base_for("sword", 10), "common", 10)
	check("zwykły zostaje", U.convert(common) == common)
	var legend: String = L.legendary_at_level("legend_amber_amulet" if I.get_data("legend_amber_amulet").size() > 0 else
			load("res://scripts/dungeons.gd").VAULT_LEGENDS[0], 20)
	check("legenda zostaje", U.convert(legend) == legend)
	check("tylko broń, zbroja i biżuteria", U.convert("health_potion") == "health_potion" and U.convert("gold") == "gold")
	# łup z ziemi
	var pickup = load("res://scenes/pickup.tscn").instantiate()
	pickup.item_id = L.drop_at_level(15, 0.0, "magic")
	pickup.position = p.global_position + Vector2(300, 0)
	_world.entities.add_child(pickup)
	check("łup na ziemi zawinięty", U.is_unidentified(pickup.item_id) and U.parse(pickup.item_id)["quality"] == "magic")
	pickup.queue_free()
	# stosy
	var weapon: String = U.id_for("weapon", "rare", 20)
	p.inventory.add_item(weapon, 5)
	p.inventory.add_item(U.id_for("jewelry", "magic", 12), 2)
	var index := _index_of(p, weapon)
	check("stos w plecaku", index >= 0 and p.inventory.slots[index]["count"] == 5)
	# PPM - jeden
	_click(window, index, false)
	check("PPM identyfikuje jeden", p.inventory.slots[index]["count"] == 4)
	var found := ""
	for slot: Dictionary in p.inventory.slots:
		if not slot.is_empty() and I.is_equippable(slot["id"]):
			found = slot["id"]
	check("zidentyfikowana broń", found != "" and I.get_data(found)["slot"] == "weapon" and I.rarity_of(found) == "rare"
			and I.item_level(found) == 20, found)
	# Shift+PPM - cały stos
	_click(window, index, true)
	check("Shift+PPM - cały stos", _index_of(p, weapon) == -1
			and p.inventory.slots.filter(func(s: Dictionary) -> bool: return not s.is_empty() and I.is_equippable(s["id"])).size() == 5)
	# pełny plecak: identyfikuje tyle, ile się zmieści (ostatnia sztuka zwalnia swoją kratkę)
	var armor: String = U.id_for("armor", "magic", 8)
	p.inventory.add_item(armor, 3)
	for i in p.inventory.slots.size():
		if p.inventory.slots[i].is_empty():
			p.inventory.slots[i] = {"id": "stone", "count": 1}
	p.inventory.changed.emit()
	var armor_index := _index_of(p, armor)
	check("pełny plecak - nic", p.identify(armor_index, true) == 0 and p.inventory.slots[armor_index]["count"] == 3)
	p.inventory.slots[_index_of(p, "stone")] = {}
	check("pełny plecak - jedna kratka", p.identify(armor_index, true) == 1 and p.inventory.slots[armor_index]["count"] == 2)
	# zidentyfikuj wszystko
	var jewelry_index := _index_of(p, U.id_for("jewelry", "magic", 12))
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == "stone":
			p.inventory.slots[i] = {}
	p.inventory.changed.emit()
	check("przycisk widoczny", window._identify_button.visible)
	check("zidentyfikuj wszystko", p.identify_all() == 4 and jewelry_index >= 0 and not p.inventory.slots.any(
			func(s: Dictionary) -> bool: return not s.is_empty() and U.is_unidentified(s["id"])))
	window._refresh()
	check("przycisk schowany", not window._identify_button.visible)
	# zapis plecaka
	p.inventory.add_item(U.id_for("armor", "rare", 30), 4)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(p.get_save_data()))
	var stack: Array = (saved.get("inventory", []) as Array).filter(func(s) -> bool: return s is Dictionary and s.get("id", "") == U.id_for("armor", "rare", 30))
	check("zapis plecaka", not stack.is_empty() and int(stack[0]["count"]) == 4 and I.get_data(stack[0]["id"])["name"].contains("poz. 30"))
	U.enabled = false
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
