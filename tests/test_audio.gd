extends SceneTree
## Muzyka i ustawienia: menu gra swój utwór, w lesie gra las, w Ostoi jej temat, przy bossie walka;
## okno ustawień otwiera się (w menu i w pauzie) i zamyka. Ustawień gracza NIE zmienia (settings.cfg).

var _world: Node
var _menu: Node
var _frame := 0
var _fails := 0
var _sfx: Node


func _initialize() -> void:
	Engine.max_fps = 60  # bez okna klatki lecą tysiącami - muzyka sprawdza stan co 0,5 s
	root.get_node("Game").save_path = "user://test_savegame.json"
	_sfx = root.get_node("Sfx")
	_setup.call_deferred()


func _setup() -> void:
	_menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(_menu)


func check(what: String, ok: bool, info := "") -> void:
	print(("OK   " if ok else "FAIL ") + what + (" " + info if info != "" else ""))
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	_frame += 1
	match _frame:
		5:
			check("muzyka menu", _sfx._music_track == "menu", _sfx._music_track)
			_menu._show_settings()
		8:
			var window = _menu.get_child(_menu.get_child_count() - 1)
			check("okno ustawień w menu", window.has_method("close") and window.has_signal("closed"))
			window.close()
			_menu.queue_free()
			root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
			_world = load("res://scenes/world.tscn").instantiate()
			root.add_child(_world)
		20:
			# start gry jest w Ostoi
			check("muzyka w Ostoi", _sfx._music_track == "ostoja", _sfx._music_track)
			_world.player.global_position = _world._goblin_spawns[0]["position"] + Vector2(0, 200)
			_world.player.reset_physics_interpolation()
		60:
			check("muzyka lasu", _sfx._music_track == "forest", _sfx._music_track)
			var boss = null
			for b in root.get_tree().get_nodes_in_group("bosses"):
				boss = b
				break
			_world.player.global_position = boss.global_position + Vector2(-60, 0)
			_world.player.reset_physics_interpolation()
			_world.player.health = 99999
		200:
			_world.player.health = 99999
			check("muzyka walki z bossem", _sfx._music_track == "boss", _sfx._music_track)
			var pause = _world.get_node_or_null("HUD/PauseMenu")
			if pause == null:
				for n in _world.find_children("*", "", true, false):
					if n.has_method("_on_settings"):
						pause = n
						break
			check("pauza ma ustawienia", pause != null and pause.has_method("_on_settings"))
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
