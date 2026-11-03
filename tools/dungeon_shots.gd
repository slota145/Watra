extends SceneTree
## Zrzuty wszystkich komnat lochu: generuje loch klimatu z podanego ziarna, ustawia kamerę po kolei na środku
## każdej komnaty (bez interfejsu, gracz z dala) i zapisuje <prefiks>_<nr>_<rodzaj komnaty>.png.
## Użycie: -s tools/dungeon_shots.gd -- <prefiks> <klimat> [ziarno] [stopień] [przybliżenie]
## Na Linuksie bez ekranu: SCRIPT=tools/dungeon_shots.gd tools/screenshot.sh /tmp/kopalnia mine 7 3 0.8
## Szósty argument "mechaniki" - loch ze wszystkimi mechanikami i zrzuty każdej skrzyni, kapliczki i elity z bliska
## (<prefiks>_<nr>_chest.png / _shrine.png); Uroczysko z bliska zgaszone i z otwartym kręgiem pełnym upiorów
## (_uroczysko.png, _uroczysko_open.png).

var _world: Node
var _frame := 0
var _args: PackedStringArray
var _rooms: Array = []
var _index := 0
## Klatki do odczekania przed następnym zrzutem (otwarte Uroczysko).
var _wait := 0
## Rozmiar komórki lochu (Dungeon.CELL - skrypt narzędzia nie może odwołać się do klas gry przed autoloadami).
const CELL := 64.0


func _initialize() -> void:
	_args = OS.get_cmdline_user_args()
	var seed_value := int(_args[2]) if _args.size() > 2 else 7
	var tier := int(_args[3]) if _args.size() > 3 else 1
	root.get_node("Game").save_path = "user://test_savegame.json"
	root.get_node("Game")._pending_load = {"seed": seed_value, "zone": "dungeon", "player": {},
			"dungeon": {"climate": _args[1], "tier": tier, "mods": [], "seed": seed_value}}
	if _args.size() > 5 and _args[5] == "mechaniki":
		root.get_node("Game")._pending_load["dungeon"]["mechanics"] = ["chests", "shrine", "crystal", "elites", "uroczysko"]
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func _process(_delta: float) -> bool:
	if _world == null or not _world.is_inside_tree() or _world._dungeon == null:
		return false
	_frame += 1
	if _rooms.is_empty():
		if _args.size() > 5 and _args[5] == "mechaniki":
			for node in _world._dungeon.chests + _world._dungeon.shrines + _world._dungeon.elites:
				_rooms.append(node)
			for node in _world._dungeon.uroczyska:
				_rooms.append(node)
				_rooms.append(node)
		else:
			_rooms = _world._dungeon.rooms.duplicate()
	_world.player.health = 99999
	_world.player.global_position = Vector2(-4000, -4000)
	_world.hud.visible = false
	var target = _rooms[_index]
	var camera: Camera2D = root.get_viewport().get_camera_2d()
	if camera != null:
		camera.top_level = true
		if target is Rect2i:
			camera.global_position = (Vector2(target.position) + Vector2(target.size) / 2.0) * CELL
		else:
			camera.global_position = target.global_position + Vector2(0, -20)
		camera.zoom = Vector2.ONE * (float(_args[4]) if _args.size() > 4 else 0.8)
		camera.position_smoothing_enabled = false
		camera.limit_left = -100000
		camera.limit_top = -100000
		camera.limit_right = 100000
		camera.limit_bottom = 100000
	if _wait > 0:
		_wait -= 1
	elif _frame % 12 == 0:
		var theme: String = _world._dungeon.room_themes.get(target, "room") if target is Rect2i else ("elite" if target.get("goblin") != null \
				else "chest" if target.get("traits") != null else "uroczysko" if target.get("kills") != null else "shrine")
		if theme == "uroczysko" and target.state == "open":
			theme = "uroczysko_open"
		root.get_texture().get_image().save_png("%s_%02d_%s.png" % [_args[0], _index, theme])
		_index += 1
		# drugi zrzut Uroczyska: krąg otwarty i pełen upiorów
		if _index < _rooms.size() and _rooms[_index] == target and target.get("kills") != null:
			target.open()
			for i in 40:
				target._spawn_timer = 0.0
				target._process(0.0)
			_wait = 120  # upiory zdążą się pojawić i podejść
		if _index >= _rooms.size():
			quit()
	return false
