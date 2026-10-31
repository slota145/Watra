extends SceneTree
## Kryształ Watry w lochu: pusta komnata do czasu zdarzenia, przebudzenie po podejściu gracza, fale potworów
## idących na kryształ (Goblin.objective), obrona do końca - kamienie zaklinające; wariant z górnikami (polegli
## górnicy - mniejsza nagroda); potwory nie gubią już kamieni; nagroda rośnie ze stopniem lochu.

var _world: Node
var _frame := 0
var _fails := 0
var _crystal: Node
var _stones_before := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	var config: Dictionary = load("res://scripts/dungeons.gd").config("catacombs", 3, [], 4242)
	config["event"] = "crystal"
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _stones() -> int:
	return _world.entities.get_children().filter(func(n: Node) -> bool:
		return n.get("item_id") != null and (str(n.item_id).ends_with("_stone") or str(n.item_id).contains("_stone_"))).size()


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	match _frame:
		5:
			var dungeon = _world._dungeon
			_crystal = dungeon.crystal
			check("loch ma Kryształ Watry", _crystal != null and _crystal.variant == "crystal")
			var room: Rect2i = dungeon.event_room
			var cell: float = dungeon.CELL
			var area := Rect2(Vector2(room.position) * cell, Vector2(room.size) * cell)
			var inside := _world.get_tree().get_nodes_in_group("enemies").filter(func(e) -> bool: return area.has_point(e.global_position))
			check("komnata kryształu pusta", inside.is_empty(), "%d potworów" % inside.size())
			check("kryształ czeka", _crystal.state == "dormant")
			# potwory nie gubią kamieni zaklinających
			var killed := 0
			for e in _world.get_tree().get_nodes_in_group("enemies"):
				if killed >= 40 or e.is_in_group("bosses"):
					continue
				e.take_damage(999999, e.global_position + Vector2(5, 0))
				killed += 1
		20:
			check("potwory bez kamieni", _stones() == 0, "%d kamieni" % _stones())
			p.global_position = _crystal.global_position + Vector2(0, 50)
			p.reset_physics_interpolation()
		22:
			check("kryształ się budzi", _crystal.state == "waves")
			_crystal._wave_timer = 0.0
		24:
			check("pierwsza fala", _crystal.wave == 1 and not _crystal._alive.is_empty(), "%d potworów" % _crystal._alive.size())
			check("fala idzie na kryształ", _crystal._alive.all(func(g) -> bool: return g.objective == _crystal and g.state == 1))
			# gracz odchodzi, potwory przy krysztale go biją
			p.global_position = _crystal.global_position + Vector2(0, 400)
			p.reset_physics_interpolation()
			p._invulnerable_timer = 99.0
			for g in _crystal._alive:
				g.global_position = _crystal.global_position + Vector2(randf_range(-20, 20), randf_range(4, 14))
		90:
			check("potwory biją kryształ", _crystal.health < _crystal.max_health, "%.0f / %.0f" % [_crystal.health, _crystal.max_health])
			_crystal.health = _crystal.max_health
			_stones_before = _stones()
	if _frame >= 90 and _frame < 600 and _crystal.state == "waves":
		# pokonujemy fale jedna po drugiej
		for g in _crystal._alive:
			if is_instance_valid(g) and g.state != 4:
				g.take_damage(999999, g.global_position + Vector2(5, 0))
		_crystal._wave_timer = minf(_crystal._wave_timer, 0.0)
	if _frame > 90 and _crystal.state == "done" and _frame < 1000:
		_frame = 1000
		check("wszystkie fale", _crystal.wave == _crystal.WAVES)
		check("kryształ obroniony - kamienie", _stones() > _stones_before + 4, "%d kamieni" % (_stones() - _stones_before))
		_check_miners()
		_check_rewards()
		print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
		quit()
	if _frame == 700:
		check("zdarzenie się kończy", false, "stan %s, fala %d" % [_crystal.state, _crystal.wave])
		quit()
	return false


func _check_miners() -> void:
	var dungeon = _world._dungeon
	var Crystal = load("res://scripts/watra_crystal.gd")
	var miners = Crystal.new()
	miners.dungeon = dungeon
	miners.variant = "miners"
	miners.room = dungeon.event_room
	miners.level = dungeon.level
	miners.tier = 3
	miners.position = _crystal.position + Vector2(0, -60)
	_world.entities.add_child(miners)
	check("dwóch górników", miners.miners.size() == 2 and miners.targets().size() == 2)
	miners._wake()
	check("górnicy kują", miners.miners.all(func(m) -> bool: return m.mining))
	miners.miners[0].take_hit(999999)
	check("górnik pada", not miners.miners[0].is_alive() and miners.targets().size() == 1)
	var before := _stones()
	miners.miners[1].take_hit(999999)
	miners._process(0.016)
	check("polegli górnicy - koniec z mniejszą nagrodą", miners.state == "done" and _stones() > before, "%d" % (_stones() - before))


func _check_rewards() -> void:
	var Crystal = load("res://scripts/watra_crystal.gd")
	var low: Array = Crystal.reward(1, 1.0)
	var high: Array = Crystal.reward(7, 1.0)
	var ids := high.map(func(e: Array) -> String: return e[0])
	check("stopień 1: bez kamieni miłosierdzia", not low.any(func(e: Array) -> bool: return e[0] == "mercy_stone"))
	check("stopień 7: uświęcone i miłosierdzia", ids.has("blessed_stone") and ids.has("mercy_stone"))
	var blessed_low: int = low.filter(func(e: Array) -> bool: return e[0] == "blessed_stone")[0][1]
	var blessed_high: int = high.filter(func(e: Array) -> bool: return e[0] == "blessed_stone")[0][1]
	check("więcej kamieni na wyższym stopniu", blessed_high > blessed_low, "%d -> %d" % [blessed_low, blessed_high])
