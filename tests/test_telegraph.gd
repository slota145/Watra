extends SceneTree
## Czerwone poświaty zapowiadające ataki (Telegraph) nie zostają na ziemi: koło pioruna ptakoczłowieka i Orła Burzy
## znika także wtedy, gdy potwór zniknął przed uderzeniem, a każda poświata sama znika chwilę po wypełnieniu.

var _world: Node
var _frame := 0
var _fails := 0
var _lonely: Telegraph


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _telegraphs() -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Telegraph and not node.is_queued_for_deletion():
			count += 1
		stack.append_array(node.get_children())
	return count


## Potwór obok gracza rzuca piorun i od razu znika (jak zabity przez podróżników).
func _cast_and_vanish(scene: String, method: String) -> void:
	var p = _world.player
	var monster = load(scene).instantiate()
	_world.add_child(monster)
	monster.global_position = p.global_position + Vector2(400, 0)
	monster._player = p
	if method == "_call_lightning":
		monster._call_lightning()
	else:
		monster.call(method, p.global_position)
	monster.queue_free()


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	match _frame:
		5:
			_cast_and_vanish("res://scenes/birdman.tscn", "_call_lightning")
			_cast_and_vanish("res://scenes/storm_eagle.tscn", "_call_bolt")
			check("koła piorunów się pojawiają", _telegraphs() >= 2, str(_telegraphs()))
		80:
			check("koła znikają bez ptakoczłowieka i orła", _telegraphs() == 0, str(_telegraphs()))
			_lonely = Telegraph.new()
			_lonely.duration = 0.2
			_world.add_child(_lonely)
		150:
			check("poświata bez właściciela jeszcze leży", is_instance_valid(_lonely))
		330:
			check("poświata sama znika po chwili", not is_instance_valid(_lonely))
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
