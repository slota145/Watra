extends SceneTree
## Portal do miasta: loch -> część potworów pokonana, skrzynia otwarta, łup na ziemi -> portal_state ->
## ten sam loch od nowa z portalem (Dungeon.restore_portal): te same potwory nie żyją, skrzynia zniknęła, łup leży,
## gracz obok płomienia portalu. Do tego: zapis portalu w zapisie gracza, portal w Ostoi przy otwartym portalu
## i nowa wyprawa przez Watrę gasi stary portal.

var _world: Node
var _frame := 0
var _fails := 0
var _step := 0
var _config: Dictionary
var _state: Dictionary
var _alive := 0
var _chest_count := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_config = load("res://scripts/dungeons.gd").config("catacombs", 3, [], 4242)
	_config["mechanics"] = ["chests", "shrine"]
	_open({"seed": 12345, "zone": "dungeon", "dungeon": _config.duplicate(true), "arrive": "start", "player": {}})


func _open(data: Dictionary) -> void:
	root.get_node("Game")._pending_load = data
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _is_portal(node: Node) -> bool:
	return node.get_script() != null and node.get_script().resource_path == "res://scripts/town_portal.gd"


func _live_count() -> int:
	var n := 0
	for e in _world._live_goblins.values():
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			n += 1
	return n


func _process(_d: float) -> bool:
	if _world == null or not _world.is_inside_tree():
		return false
	_frame += 1
	if _frame < 5:
		return false
	match _step:
		0:
			_first_visit()
		1:
			if _frame >= 8:
				_return_visit()
		2:
			if _frame >= 8:
				_town_visit()
		3:
			_world.player._invulnerable_timer = 999.0
			if _frame == 8:
				_world.player._start_portal()
				check("otwieranie portalu klawiszem B", _world.player._portal_cast >= 0.0)
			if _frame > 8 and (not _world.player.town_portal.is_empty() or _frame > 8 + 400):
				check("gotowy portal zabiera do Ostoi", _world._traveling and not _world.player.town_portal.is_empty())
				print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
				quit()
	return false


func _first_visit() -> void:
	var dungeon = _world._dungeon
	# pokonane: co trzeci potwór
	var killed := 0
	for id in _world._live_goblins.keys():
		if id % 3 == 0:
			var goblin = _world._live_goblins[id]
			if not is_instance_of(goblin, load("res://scripts/boss.gd")):
				goblin.take_damage(10000000, goblin.global_position)
				killed += 1
	_chest_count = dungeon.chests.size()
	if _chest_count > 0:
		dungeon.chests[0].state = "open"
	var pickup = load("res://scripts/goblin.gd").pickup_scene().instantiate()
	pickup.item_id = load("res://scripts/loot.gd").drop_at_level(20)
	pickup.amount = 1
	pickup.position = _world.player.global_position + Vector2(30, 0)
	_world.entities.add_child(pickup)
	_alive = _live_count()
	check("w lochu są potwory i część pokonana", killed > 0 and _alive > 0, "%d pokonanych, %d żywych" % [killed, _alive])
	var at: Vector2 = _world.player.global_position
	_state = dungeon.portal_state(at)
	_world.player.town_portal = {"config": _config.duplicate(true), "state": _state}
	# zapis gracza zachowuje portal (JSON jak w pliku zapisu)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(_world.player.get_save_data()))
	check("portal w zapisie gracza", saved.get("town_portal", {}).has("state"))
	_state = saved["town_portal"]["state"]
	check("stan: pokonane i łup", _state["dead"].size() >= killed and _state["items"].size() >= 1)
	_world.queue_free()
	var config := _config.duplicate(true)
	config["portal"] = _state
	_step = 1
	_open({"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": saved})


func _return_visit() -> void:
	var dungeon = _world._dungeon
	check("po powrocie żyje tyle samo potworów", _live_count() == _alive, "%d zamiast %d" % [_live_count(), _alive])
	var chests := 0
	for chest in dungeon.chests:
		if is_instance_valid(chest) and not chest.is_queued_for_deletion():
			chests += 1
	check("otwarta skrzynia zniknęła", _chest_count == 0 or chests == _chest_count - 1, "%d z %d" % [chests, _chest_count])
	var portals := 0
	for node in _world.entities.get_children():
		if _is_portal(node) and node.kind == "town":
			portals += 1
	check("płomień portalu do Ostoi w lochu", portals == 1)
	var at := Vector2(float(_state["position"][0]), float(_state["position"][1]))
	check("gracz obok portalu", _world.player.global_position.distance_to(at) < 60.0)
	var items := 0
	for node in get_nodes_in_group("pickups"):
		if not node.is_queued_for_deletion():
			items += 1
	check("łup leży na ziemi", items >= 1)
	var saved: Dictionary = _world.player.get_save_data()
	saved["town_portal"] = {"config": _config.duplicate(true), "state": _state}
	_world.queue_free()
	_step = 2
	_open({"seed": 12345, "zone": "forest", "arrive": "town_portal", "player": saved})


func _town_visit() -> void:
	var portal = null
	for node in _world.entities.get_children():
		if _is_portal(node):
			portal = node
	check("portal do lochu w Ostoi", portal != null and portal.kind == "dungeon")
	check("gracz przybywa obok portalu", portal != null and _world.player.global_position.distance_to(portal.global_position) < 60.0)
	# nowa wyprawa przez Watrę gasi portal (podróż przerwana zaraz po wywołaniu)
	_world.enter_dungeon(_config.duplicate(true))
	check("nowa wyprawa gasi portal", _world.player.town_portal.is_empty())
	_world.queue_free()
	_step = 3
	_open({"seed": 12345, "zone": "dungeon", "dungeon": _config.duplicate(true), "arrive": "start", "player": {}})
