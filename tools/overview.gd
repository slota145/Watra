extends SceneTree
## Widok z góry na fragment krainy: wczytuje krainę z ustalonego ziarna, odpina kamerę od gracza,
## ustawia ją na podanym kafelku z podanym przybliżeniem i zapisuje zrzut (bez interfejsu).
## Gracz czeka w kafelku (30, 30), żeby potwory w kadrze stały na swoich miejscach - nie w rogu mapy,
## gdzie bywają wyjścia do innych krain.
## Użycie: -s tools/overview.gd -- <plik.png> <kraina> <kafelek x> <kafelek y> <przybliżenie> [ziarno]
## Na Linuksie bez ekranu: SCRIPT=tools/overview.gd tools/screenshot.sh /tmp/wioska.png mountains 148 57 0.32

var _world: Node
var _frame := 0
var _args: PackedStringArray


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	var world_seed := int(_args[5]) if _args.size() > 5 else 12345
	root.get_node("Game").save_path = "user://test_savegame.json"
	root.get_node("Game")._pending_load = {"seed": world_seed, "zone": _args[1], "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func _process(_delta: float) -> bool:
	if _world == null or not _world.is_inside_tree():
		return false
	_frame += 1
	_world.player.global_position = Vector2(30, 30) * 16.0
	_world.player.health = 99999
	_world.hud.visible = false
	var camera: Camera2D = root.get_viewport().get_camera_2d()
	if camera != null:
		camera.top_level = true
		camera.global_position = Vector2(float(_args[2]), float(_args[3])) * 16.0
		camera.zoom = Vector2.ONE * float(_args[4])
		camera.position_smoothing_enabled = false
		camera.limit_left = -100000
		camera.limit_top = -100000
		camera.limit_right = 100000
		camera.limit_bottom = 100000
	if _frame == 40:
		root.get_texture().get_image().save_png(_args[0])
		quit()
	return false
