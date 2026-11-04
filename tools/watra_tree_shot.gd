extends SceneTree
## Zrzut okna drzewka Watry (drzewko lochów): postać z kilkoma wybranymi węzłami, widok całego drzewka i przybliżony
## na jeden sektor. Pliki: <prefiks>_calosc.png i <prefiks>_sektor.png.
## Użycie: SCRIPT=tools/watra_tree_shot.gd tools/screenshot.sh /tmp/watra

var _prefix := "/tmp/watra"
var _world: Node
var _frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _process(_delta: float) -> bool:
	if _world == null or _world.player == null:
		return false
	_frame += 1
	var boons = _world.player.boons
	var window = _world.find_child("HUD", true, false).watra_tree_window
	match _frame:
		10:
			for i in 40:
				boons.nawia_cleared.append(i)
			var T = load("res://scripts/watra_tree.gd")
			# najkrótsza droga od Watry do skupiska "b" Uroczyska (przez cudze skupiska)
			for id in _route(T, "uroczysko_b_n"):
				boons.tree_allocate(id)
			window.open()
			window.select("uroczysko_b_n")
			print("droga: ", boons.tree_nodes().size(), " węzłów")
		20:
			_save(_prefix + "_calosc.png")
			var view = window._view
			view._zoom = 1.4
			var at: Vector2 = load("res://scripts/watra_tree.gd").nodes()["uroczysko_b_n"]["pos"] * 0.7
			view._offset = -at * view.UNIT * view._zoom
			view.queue_redraw()
		30:
			_save(_prefix + "_sektor.png")
			quit()
	return false


## Najkrótsza droga od Watry do węzła (przeszukiwanie wszerz) - węzły w kolejności wybierania.
func _route(T, target: String) -> Array:
	var nodes: Dictionary = T.nodes()
	var before := {T.START: ""}
	var queue: Array = [T.START]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == target:
			break
		for other: String in nodes[id]["links"]:
			if not before.has(other):
				before[other] = id
				queue.append(other)
	var route: Array = []
	var at := target
	while at != T.START:
		route.push_front(at)
		at = before[at]
	return route


func _save(path: String) -> void:
	var err := root.get_texture().get_image().save_png(path)
	print("zrzut: ", path, " ", err)
