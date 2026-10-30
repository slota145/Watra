extends SceneTree
## Lochy w płomieniach Watry: każdy klimat (kafelki dla wszystkich komórek, komnaty połączone, gracz na podłodze,
## potwory klimatu na poziomie stopnia, strażnik), modyfikatory, otwarcie skarbca po pokonaniu strażnika,
## zapis gry z lochu (wraca do Ostoi), żar do wydania, a na koniec pełna droga: okno lochów przy Watrze ->
## wejście w płomienie (żar wydany, modyfikatory działają) -> płomienie w lochu -> powrót przed Watrę.

const CLIMATES := ["catacombs", "mine", "flooded", "roots"]

var _world: Node
var _frame := 0
var _fails := 0
var _index := 0
var _Dungeons
## Etap pełnej drogi: 0 - jeszcze nie, 1 - las z oknem, 2 - w lochu, 3 - z powrotem w lesie.
var _flow := 0
var _flow_frame := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_Dungeons = load("res://scripts/dungeons.gd")
	_load_next.call_deferred()


func _load_next() -> void:
	var mods: Array = ["horde", "fury"] if _index == 0 else []
	var config: Dictionary = _Dungeons.config(CLIMATES[_index], 2 + _index, mods, 1000 + _index * 77)
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _flow > 0:
		_process_flow()
		return false
	if _world == null:
		return false
	_frame += 1
	if _frame == 5:
		_check_dungeon()
	if _frame == 8 and _index == 0:
		_check_vault_and_save()
	if _frame == 20:
		_world.queue_free()
		_world = null
		_index += 1
		if _index >= CLIMATES.size():
			_check_window()
			_start_flow.call_deferred()
		else:
			_load_next.call_deferred()
	return false


func _check_dungeon() -> void:
	var climate: String = CLIMATES[_index]
	var d = _world._dungeon
	check("%s: kraina lochu" % climate, _world.zone == "dungeon" and d != null)
	var layer: TileMapLayer = _world.get_node("DungeonTiles")
	check("%s: kafelek w każdej komórce" % climate, layer.get_used_cells().size() == (d.GRID.x - 1) * (d.GRID.y - 1))
	var distance: Dictionary = d._distances(d.start_room.position + d.start_room.size / 2)
	var connected := true
	for room: Rect2i in d.rooms:
		if not distance.has(room.position + room.size / 2):
			connected = false
	check("%s: wszystkie komnaty połączone" % climate, connected, "%d komnat" % d.rooms.size())
	var player = _world.player
	var vertex := Vector2i((player.global_position / d.CELL).round())
	check("%s: gracz na podłodze przy wejściu" % climate, d._label(vertex) == "l" and d.start_room.grow(1).has_point(vertex))
	var kinds := {}
	var levels := {}
	var count := 0
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		count += 1
		kinds[enemy.scene_file_path.get_file().get_basename()] = true
		levels[enemy.level] = true
	var tier_level: int = _Dungeons.tier_level(2 + _index)
	check("%s: dużo potworów" % climate, count >= 60, "%d" % count)
	check("%s: poziomy wg stopnia" % climate, levels.has(tier_level) and levels.keys().all(func(l: int) -> bool: return l >= tier_level and l <= tier_level + 2), str(levels.keys()))
	var boss = d._boss
	check("%s: strażnik" % climate, boss != null and boss.is_in_group("bosses") and boss.level == tier_level + 2,
			boss.scene_file_path.get_file() if boss != null else "brak")
	check("%s: potwory klimatu" % climate, kinds.size() >= 3, str(kinds.keys()))
	if _index == 0:
		check("modyfikatory: wściekłość", is_equal_approx(_mods()["health"], 1.25) and is_equal_approx(_mods()["xp"], 1.5))
	else:
		check("%s: bez modyfikatorów" % climate, is_equal_approx(_mods()["health"], 1.0))


func _mods() -> Dictionary:
	return load("res://scripts/goblin.gd").dungeon_mods


func _pickups() -> int:
	var script = load("res://scripts/pickup.gd")
	return _world.entities.get_children().filter(func(n: Node) -> bool: return n.get_script() == script).size()


func _check_vault_and_save() -> void:
	var d = _world._dungeon
	var before := _pickups()
	d._boss.take_damage(999999, d._boss.global_position)
	var after := _pickups()
	check("skarbiec po strażniku", d._vault_open and after - before >= 5, "%d łupów" % (after - before))
	check("płomienie powrotu w komnacie strażnika", d._portals.size() == 2)
	var save: Dictionary = _world.get_save_data()
	check("zapis z lochu wraca do Ostoi", save["zone"] == "forest" and save["arrive"] == "watra" and not save["zones"].has("dungeon"))
	check("potwory w lochu się nie odradzają", _world._respawn_queue.is_empty())


func _start_flow() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	var world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	_flow = 1
	_flow_frame = 0


func _process_flow() -> void:
	_flow_frame += 1
	var w = root.get_tree().get_first_node_in_group("world")
	if w == null:
		return
	if _flow == 1 and _flow_frame == 10:
		w.player.boons.ember = 2400
		w.hud.watra_window.open()
		w.hud.watra_window.dungeon_requested.emit()
		var win = w.hud.dungeon_window
		check("okno lochów z okna Watry", win.visible)
		win._choose_climate("flooded")
		win._change_tier(5)
		check("stopień najwyżej poziom Watry", win._tier == 4, "%d" % win._tier)
		win._mod_boxes["fury"].button_pressed = true
		win._on_enter()
		check("wydany żar", w.player.boons.ember_spent == 50 and w.player.boons.watra_level() == 4)
		_flow = 2
		_flow_frame = 0
	elif _flow == 2 and _flow_frame == 60:
		check("w lochu po wejściu w płomienie", w.zone == "dungeon" and w._dungeon_config["climate"] == "flooded" and w._dungeon_config["tier"] == 4)
		check("modyfikator działa", is_equal_approx(_mods()["damage"], 1.25))
		w.player.global_position = w._dungeon._portals[0]["rect"].get_center()
		_flow = 3
		_flow_frame = 0
	elif _flow == 3 and _flow_frame == 60:
		check("powrót przed Watrę", w.zone == "forest" and w.player.global_position.distance_to(w._settlement.watra_arrival()) < 8.0)
		check("poza lochem bez modyfikatorów", _mods().is_empty())
		print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
		quit()


func _check_window() -> void:
	var Boons = load("res://scripts/boons.gd")
	var boons = Boons.new()
	boons.ember = 1000
	check("żar do wydania", boons.available_ember() == 1000 and boons.watra_level() == 3)
	check("wydanie żaru", boons.spend_ember(150) and boons.available_ember() == 850 and boons.watra_level() == 3)
	check("za mało żaru", not boons.spend_ember(5000))
	var copy = Boons.new()
	copy.load_save_data(boons.get_save_data())
	check("zapis wydanego żaru", copy.ember_spent == 150)
	boons.free()
	copy.free()
	check("koszt modyfikatorów", _Dungeons.mods_cost(["horde", "wealth"]) == 100)
	check("stopnie", _Dungeons.tier_level(1) == 5 and _Dungeons.tier_level(7) == 41)
