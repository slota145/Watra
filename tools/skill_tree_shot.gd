extends SceneTree
## Zrzut okna umiejętności (K) ze wspólnym drzewkiem: postać z kilkoma wybranymi węzłami, widok na starcie
## i oddalony (całe drzewko). Pliki: <prefiks>_start.png i <prefiks>_calosc.png.
## Użycie: SCRIPT=tools/skill_tree_shot.gd tools/screenshot.sh /tmp/drzewko

var _prefix := "/tmp/drzewko"
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
	var p = _world.player
	var window = _world.find_child("HUD", true, false).skill_window
	match _frame:
		10:
			p.skills.bonus_points += 40
			for id in ["cyclone_eye", "crescent", "rend"]:
				p.skills.grant_node(id)
			window.toggle()
			window._tree["view"].selected_id = "flicker"
			window._refresh()
		20:
			_save(_prefix + "_start.png")
			window._tree["view"].focus("start", 0.25)
		30:
			_save(_prefix + "_calosc.png")
			quit()
	return false


func _save(path: String) -> void:
	var err := root.get_texture().get_image().save_png(path)
	print("zrzut: ", path, " ", err)
