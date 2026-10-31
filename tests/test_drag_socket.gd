extends SceneTree
## Zakładanie kamienia przeciąganiem (okno plecaka): kamień na przedmiot z pustym gniazdem w plecaku i na założony
## przedmiot się osadza; zajęte gniazdo odmawia; kamień na przedmiot bez gniazda to zwykła zamiana miejsc;
## Kamień Promienia nie pasuje; esencja do pustego gniazda esencji tego samego rodzaju, zajęte - odmowa.

var _world: Node
var _frame := 0
var _fails := 0


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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 5:
		return false
	var p = _world.player
	var Gems = load("res://scripts/gems.gd")
	var Ess = load("res://scripts/essences.gd")
	var Items = load("res://scripts/items.gd")
	var Loot = load("res://scripts/loot.gd")
	var window = _world.find_child("HUD", true, false).inventory_window
	# przedmiot w plecaku z pustym gniazdem
	var sword: String = Gems.add_socket(Loot.generate("sword_t2", "rare", 20))
	p.inventory.add_item(sword, 1)
	var ruby: String = Gems.roll("ruby", 1)
	p.inventory.add_item(ruby, 1)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": _index_of(p, ruby)}, _index_of(p, sword))
	check("kamień na przedmiot w plecaku", not (Gems.sockets_of(sword)[0] as Dictionary).is_empty() and p.inventory.count_of(ruby) == 0
			and _index_of(p, sword) >= 0)
	# zajęte gniazdo - odmowa, kamień zostaje w plecaku
	var second: String = Gems.roll("sapphire", 1)
	p.inventory.add_item(second, 1)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": _index_of(p, second)}, _index_of(p, sword))
	check("zajęte gniazdo odmawia", Gems.sockets_of(sword)[0]["kind"] == "ruby" and p.inventory.count_of(second) == 1)
	# Kamień Promienia nie pasuje do przedmiotu
	var armor: String = Gems.add_socket(Loot.generate("leather_armor", "rare", 20))
	p.inventory.add_item(armor, 1)
	var radius: String = Gems.roll_radius(3)
	p.inventory.add_item(radius, 1)
	check("Kamień Promienia nie do przedmiotu", Gems.drag_target(radius, armor) not in ["", "gem"])
	# kamień na założony przedmiot (okno plecaka - miejsce ekwipunku)
	p.equipment.items["chest"] = {"id": armor, "enchant": 0}
	p.inventory.slots[_index_of(p, armor)] = {}
	p.equipment.changed.emit()
	var health: int = p.stats.max_health()
	var onyx: String = ""
	for i in 40:
		onyx = Gems.roll("ruby", 3)
		if Items.get_data(onyx)["stats"].has("health"):
			break
	p.inventory.add_item(onyx, 1)
	var drag := {"inventory": p.inventory, "index": _index_of(p, onyx)}
	check("założony przedmiot przyjmuje kamień", window._can_drop_on_gear(Vector2.ZERO, drag, "chest"))
	window._drop_on_gear(Vector2.ZERO, drag, "chest")
	check("kamień na założony przedmiot", p.equipment.get_item("chest") == armor and not (Gems.sockets_of(armor)[0] as Dictionary).is_empty()
			and p.stats.max_health() > health, "%d -> %d" % [health, p.stats.max_health()])
	# kamień na przedmiot bez gniazda - zwykła zamiana miejsc
	var plain: String = Loot.generate("sword_t2", "magic", 10)
	p.inventory.add_item(plain, 1)
	var from := _index_of(p, second)
	var to := _index_of(p, plain)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": from}, to)
	check("bez gniazda zamiana miejsc", p.inventory.slots[to].get("id", "") == second and p.inventory.slots[from].get("id", "") == plain)
	# esencja: do pustego gniazda esencji tego samego rodzaju
	Ess.add_socket(sword)
	var bow_essence: String = Ess.extract(Loot.legendary_at_level("legend_swarog_bow", 30))
	var pelt_essence: String = Ess.extract(Loot.legendary_at_level("legend_alpha_pelt", 30))
	p.inventory.add_item(pelt_essence, 1)
	p.inventory.add_item(bow_essence, 1)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": _index_of(p, pelt_essence)}, _index_of(p, sword))
	check("esencja innego rodzaju odmawia", (Ess.socket_of(sword) as Dictionary).is_empty() and p.inventory.count_of(pelt_essence) == 1)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": _index_of(p, bow_essence)}, _index_of(p, sword))
	check("esencja w pustym gnieździe", (Ess.socket_of(sword) as Dictionary).get("kind", "") == "seeker_split" and p.inventory.count_of(bow_essence) == 0)
	var third: String = Ess.extract(Loot.legendary_at_level("legend_swarog_bow", 30))
	p.inventory.add_item(third, 1)
	window._drop_on_bag(Vector2.ZERO, {"inventory": p.inventory, "index": _index_of(p, third)}, _index_of(p, sword))
	check("zajęte gniazdo esencji odmawia", p.inventory.count_of(third) == 1)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _index_of(p, id: String) -> int:
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			return i
	return -1
