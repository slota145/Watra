extends SceneTree
## Zielarstwo: w każdej krainie rośnie jej zioło (dość roślin, żadna w przeszkodzie), zrywanie klawiszem F daje ziele,
## zielarka warzy z 3 ziół miksturę, wypita mikstura daje premię (jedna naraz, widać ją w efektach), zerwane rośliny
## zapisują się i odrastają.

const ZONES := ["forest", "fields", "swamp", "mountains", "ancient", "cemetery"]

var _world: Node
var _frame := 0
var _fails := 0
var _index := 0
var _Herbs
var _herb_path := ""
## Zapis z zerwanym ziołem (sprawdzany po ponownym wczytaniu lasu).
var _saved := {}
var _picked_at := Vector2.ZERO


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_Herbs = load("res://scripts/herbs.gd")
	_load_next.call_deferred()


func _load_next() -> void:
	var save: Dictionary = _saved if _index >= ZONES.size() else {"seed": 12345, "zone": ZONES[_index], "player": {}}
	root.get_node("Game")._pending_load = save
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _herbs() -> Array:
	var script = load("res://scripts/herb.gd")
	return _world.entities.get_children().filter(func(n: Node) -> bool: return n.get_script() == script)


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _index >= ZONES.size():
		if _frame == 5:
			_check_reload()
		return false
	if _frame == 5:
		_check_zone()
	if _index == 0 and _frame == 6:
		_start_picking()
	if _index == 0 and _frame == 80:
		_check_picking_and_brewing()
	if _frame == 90:
		_world.queue_free()
		_world = null
		_index += 1
		_load_next.call_deferred()
	return false


func _check_zone() -> void:
	var zone: String = ZONES[_index]
	var kind: String = _Herbs.kind_in_zone(zone)
	var herbs := _herbs()
	var want: int = _Herbs.KINDS[kind]["count"]
	check("%s: rośnie %s" % [zone, _Herbs.KINDS[kind]["name"]], herbs.size() >= want * 0.8 and herbs.all(func(h) -> bool: return h.kind == kind),
			"%d/%d" % [herbs.size(), want])
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var blocked := 0
	for herb in herbs:
		query.transform = Transform2D(0.0, herb.global_position)
		if not _world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			blocked += 1
	check("%s: zioła poza przeszkodami" % zone, blocked <= herbs.size() / 20, "%d w przeszkodach" % blocked)


func _start_picking() -> void:
	var player = _world.player
	var herb = _herbs()[0]
	player.global_position = herb.global_position + Vector2(10, 4)
	player._start_harvest(herb)
	_picked_at = herb.global_position


func _check_picking_and_brewing() -> void:
	var player = _world.player
	var herb = _herbs()[0]
	check("zerwane zioło", herb.is_depleted and player.inventory.count_of("herb_wort") >= 1, "%d ziela" % player.inventory.count_of("herb_wort"))
	# warzenie u zielarki
	player.inventory.add_item("herb_wort", 5)
	player.stats.add_gold(500)
	var offers: Dictionary = load("res://scripts/village_services.gd").offers("elixirs", player, _FakeNpc.new())
	check("warsztat zielarki", offers["rows"].size() == 6)
	var row: Dictionary = offers["rows"][0]
	var herbs_before: int = player.inventory.count_of("herb_wort")
	check("można uwarzyć", row["enabled"])
	row["action"].call()
	check("uwarzona mikstura", player.inventory.count_of("elixir_wort") == 1 and player.inventory.count_of("herb_wort") == herbs_before - 3)
	var hp: int = player.stats.max_health()
	check("wypita mikstura", player.use_item("elixir_wort") and player.boons.has_group("elixir") and player.stats.max_health() > hp,
			"%d -> %d" % [hp, player.stats.max_health()])
	var names: Array = load("res://scripts/status_effects.gd").list(player).map(func(e: Dictionary) -> String: return e["name"])
	check("mikstura w efektach", "Wywar z dziurawca" in names)
	player.inventory.add_item("elixir_arnica", 1)
	player.use_item("elixir_arnica")
	check("jedna mikstura naraz", player.boons.active["elixir"]["id"] == "elixir_arnica" and player.boons.active.size() == 1)
	_saved = _world.get_save_data()


func _check_reload() -> void:
	var depleted := _herbs().filter(func(h) -> bool: return h.is_depleted)
	check("zerwane zioło po wczytaniu", depleted.size() == 1 and depleted[0].global_position.distance_to(_picked_at) < 1.0)
	depleted[0].regrow()
	check("zioło odrasta", not depleted[0].is_depleted)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()


## Zastępstwo zielarki do warsztatu (tylko mówi).
class _FakeNpc:
	extends Node
	func say(_text: String) -> void:
		pass
