extends SceneTree
## Przeciąganie (plecak <-> postać, plecak <-> magazyn) i dymek łupu na ziemi.

var _world: Node
var _frame := 0
var _out := ""
var _pickup: Node2D

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else ""
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var player: Node = _world.player
	var loot: GDScript = load("res://scripts/loot.gd")
	var inv_window: Node = _world.hud.inventory_window
	if _frame == 5:
		var ring_a: String = loot.generate("copper_ring", "magic", 10)
		var ring_b: String = loot.generate("band_t2", "rare", 25)
		var sword: String = loot.generate("sword_t2", "rare", 25)
		player.inventory.add_item(ring_a, 1)
		player.inventory.add_item(ring_b, 1)
		player.inventory.add_item(sword, 1)
		player.inventory.add_item("wood", 30)
		# plecak -> drugi pierścień (konkretne miejsce)
		var data := {"inventory": player.inventory, "index": 1}
		_check(inv_window._can_drop_on_gear(Vector2.ZERO, data, "ring_2"), "pierścień pasuje do ring_2")
		_check(not inv_window._can_drop_on_gear(Vector2.ZERO, data, "helmet"), "pierścień nie pasuje do hełmu")
		inv_window._drop_on_gear(Vector2.ZERO, data, "ring_2")
		_check(player.equipment.get_item("ring_2") == ring_b and player.equipment.get_item("ring_1") == "", "założony w ring_2, ring_1 wolny")
		# miecz na broń: stary (zardzewiały) wraca na zwolnione miejsce w plecaku
		inv_window._drop_on_gear(Vector2.ZERO, {"inventory": player.inventory, "index": 2}, "weapon")
		_check(player.equipment.get_item("weapon") == sword and player.inventory.slots[2].get("id") == "rusty_sword", "zamiana broni, stara na tym samym miejscu")
		# z postaci do plecaka: na wolną kratkę 10
		inv_window._drop_on_bag(Vector2.ZERO, {"gear_slot": "ring_2"}, 10)
		_check(player.inventory.slots[10].get("id") == ring_b and player.equipment.get_item("ring_2") == "", "zdjęty pierścień na kratce 10")
		# z postaci na pasujący przedmiot w plecaku: zamiana
		inv_window._drop_on_gear(Vector2.ZERO, {"inventory": player.inventory, "index": 10}, "ring_1")
		inv_window._drop_on_bag(Vector2.ZERO, {"gear_slot": "ring_1"}, 0)
		_check(player.equipment.get_item("ring_1") == ring_a and player.inventory.slots[0].get("id") == ring_b, "zamiana pierścieni przez przeciągnięcie na plecak")
		# plecak -> magazyn (kratka 5) i z powrotem (kratka 7 plecaka)
		var storage_window: Node = _world.hud.storage_window
		var wood_index := -1
		for i in player.inventory.slots.size():
			if player.inventory.slots[i].get("id") == "wood":
				wood_index = i
		storage_window._drop(Vector2.ZERO, {"inventory": player.inventory, "index": wood_index}, player.storage, 5)
		_check(player.storage.slots[5].get("id") == "wood" and player.inventory.count_of("wood") == 0, "drewno przeciągnięte do magazynu na kratkę 5")
		inv_window._drop_on_bag(Vector2.ZERO, {"inventory": player.storage, "index": 5}, 7)
		_check(player.inventory.slots[7].get("id") == "wood" and player.inventory.slots[7]["count"] == 30, "drewno z magazynu na kratkę 7 plecaka")
		_check(not inv_window._can_drop_on_trash(Vector2.ZERO, {"inventory": player.storage, "index": 0}), "kosz plecaka nie przyjmuje przedmiotów z magazynu")
		# łup na ziemi obok gracza (poza zasięgiem przyciągania)
		_pickup = load("res://scenes/pickup.tscn").instantiate()
		_pickup.item_id = loot.generate("ring_storm", "legendary", 30)
		_pickup.position = player.position + Vector2(70, 0)
		player.get_parent().add_child(_pickup)
	if _frame >= 40 and _frame < 50:
		# łup pod kursorem (pozycja prawdziwego kursora - sztuczne zdarzenia myszy nadpisuje system)
		_pickup.global_position = _world.player.get_global_mouse_position() - Vector2(0, -3)
	if _frame == 50:
		var tip: Node = null
		for child in _world.hud.get_children():
			if child.has_method("_hovered"):
				tip = child
		print("  mysz w swiecie: ", _world.player.get_global_mouse_position(), " lup: ", _pickup.global_position, " nad kontrolka: ", root.gui_get_hovered_control())
		_check(tip != null and tip.visible, "dymek łupu na ziemi widoczny po najechaniu")
		if _out != "":
			root.get_viewport().get_texture().get_image().save_png(_out)
		quit()
	return false
