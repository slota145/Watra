extends SceneTree
## Kolizja nowej palisady: ściany nie da się przejść, bramy tak.

var _world: Node
var _player: Node2D
var _frame := 0
var _case := -1
var _start := 0
var _cases := [
	# [nazwa, punkt startu (kafelki układu), akcja, oczekiwane: true = wychodzi za palisadę]
	["polnoc", Vector2(30, 7.5), "move_up", false],
	["zachod sciana", Vector2(10, 14), "move_left", false],
	["wschod naprawa", Vector2(55, 29), "move_right", false],
	["brama zachodnia", Vector2(12, 22.8), "move_left", true],
	["brama wschodnia", Vector2(54, 22.8), "move_right", true],
	["brama poludniowa", Vector2(33, 37.5), "move_down", true],
]
var _fails := 0

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _px(p: Vector2) -> Vector2:
	return (Vector2(_world._settlement.origin_tile) + p * 1.375) * 16.0


func _outside(pos: Vector2) -> bool:
	var s = _world._settlement
	return s.outline_distance(pos / 16.0 - Vector2(s.origin_tile)) > 1.0


func _physics_process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame < 10:
		return false
	if _player == null:
		_player = _world.player
	if _case == -1 or _frame - _start > 150:
		if _case >= 0:
			var c: Array = _cases[_case]
			Input.action_release(c[2])
			var out := _outside(_player.global_position)
			var ok: bool = out == c[3]
			if not ok:
				_fails += 1
			print("%s: %s (za palisada: %s)" % [c[0], "OK" if ok else "BLAD", out])
		_case += 1
		if _case >= _cases.size():
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
			return false
		var c: Array = _cases[_case]
		_player.global_position = _px(c[1])
		_player.reset_physics_interpolation()
		Input.action_press(c[2])
		_start = _frame
	return false
