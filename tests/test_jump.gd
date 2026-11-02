extends SceneTree
## Skoki przez przeszkody: zryw / odskok (Player.leap) i lądowanie po teleporcie (Player.free_landing) przeskakują
## zwykłe przeszkody (płot, klif - warstwa 1), ale nie granicę (BOUNDS_LAYER): brzegi mapy i ściany podziemi.
## Loch na zewnątrz (Winnica satyrów) ma teren jako zwykłe przeszkody.

var _world: Node
var _frame := 0
var _fails := 0
var _stage := 0
var _fence: StaticBody2D
var _start := Vector2.ZERO
var _wall_vertex := Vector2i.ZERO


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_load("catacombs")


func _load(climate: String) -> void:
	var config := {"climate": climate, "tier": 1, "mods": [], "seed": 4242}
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var player = _world.player
	var d = _world._dungeon
	if _stage == 0 and _frame == 5:
		check("brzegi mapy to granica", _world.get_node("Bounds").collision_layer & 16 != 0)
		check("ściany podziemi to granica", _world.get_node("DungeonWalls").collision_layer & 16 != 0)
		# płot (zwykła przeszkoda) tuż na prawo od gracza w komnacie wejściowej
		_start = player.global_position
		_fence = StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(10, 120)
		shape.shape = box
		_fence.add_child(shape)
		_fence.position = _start + Vector2(24, 0)
		_world.add_child(_fence)
		player.leap(Vector2.RIGHT, 0.25)
		_stage = 1
		_frame = 0
	elif _stage == 1 and _frame == 30:
		check("zryw przeskakuje płot", player.global_position.x > _fence.position.x + 5.0,
				"x %.0f, płot %.0f" % [player.global_position.x, _fence.position.x])
		check("po skoku maska zwykłych przeszkód", player.collision_mask == player.SOLID_MASK)
		var inside: Vector2 = player.free_landing(_fence.position, _start)
		check("lądowanie w płocie przesuwa obok", absf(inside.x - _fence.position.x) > 5.0, "x %.0f" % inside.x)
		_fence.queue_free()
		# wierzchołek podłogi tuż przy ścianie (skała po prawej) - skok w ścianę
		for v: Vector2i in d.floor_cells:
			if d._label(v) == "l" and d._label(v + Vector2i.LEFT) == "l" and d._label(v + Vector2i.RIGHT) == "u" \
					and d._label(v + Vector2i.UP) == "l" and d._label(v + Vector2i.DOWN) == "l":
				_wall_vertex = v
				break
		player.global_position = Vector2(_wall_vertex) * d.CELL
		player.reset_physics_interpolation()
		player.leap(Vector2.RIGHT, 0.4)
		_stage = 2
		_frame = 0
	elif _stage == 2 and _frame == 40:
		var at := Vector2i((player.global_position / d.CELL).round())
		check("zryw nie przechodzi przez ścianę podziemi", d._label(at) == "l" and player.global_position.x < (_wall_vertex.x + 0.5) * d.CELL,
				"wierzchołek %s, ściana na prawo od %s" % [at, _wall_vertex])
		var beyond: Vector2 = player.free_landing(Vector2(_wall_vertex + Vector2i(3, 0)) * d.CELL, Vector2(_wall_vertex) * d.CELL)
		check("teleport nie ląduje za ścianą podziemi", beyond.x < (_wall_vertex.x + 0.5) * d.CELL, "x %.0f" % beyond.x)
		var edge: Vector2 = player.free_landing(Vector2(-200, 300), Vector2(40, 300))
		check("teleport nie wychodzi za brzeg mapy", edge.x >= 0.0, "x %.0f" % edge.x)
		_world.queue_free()
		_world = null
		_load.call_deferred("vineyard")
		_stage = 3
	elif _stage == 3 and _frame == 5:
		check("winnica: teren to zwykłe przeszkody", _world.get_node("DungeonWalls").collision_layer & 16 == 0)
		print("WYNIK: %s" % ("OK" if _fails == 0 else "%d bledow" % _fails))
		quit(1 if _fails > 0 else 0)
	return false
