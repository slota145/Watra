extends SceneTree
## Okna interfejsu: przesuwanie i skalowanie (WindowDrag) oraz skalowanie interfejsu (Game.ui_scale).
## Test z oknem (tools/screenshot.sh albo zwykły Godot). Ustawienia gracza (user://settings.cfg) wracają na koniec.

const SETTINGS := "user://settings.cfg"

var _world: Node
var _frame := 0
var _out := ""
var _fails := 0
var _backup := PackedByteArray()
var _had_settings := false
var _moved_to := Vector2.ZERO


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else ""
	_had_settings = FileAccess.file_exists(SETTINGS)
	if _had_settings:
		_backup = FileAccess.get_file_as_bytes(SETTINGS)
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
	print(("OK   " if ok else "FAIL ") + what)


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _click(window: Control, at: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT, ctrl := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.ctrl_pressed = ctrl
	event.global_position = at
	event.position = at
	window.get_node("WindowDrag")._on_gui_input(event)


func _move(window: Control, at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.global_position = at
	event.position = at
	window.get_node("WindowDrag")._on_gui_input(event)


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var game: Node = root.get_node("Game")
	var inv: Control = _world.hud.inventory_window
	match _frame:
		5:
			game.window_layouts = {}
			game.ui_scale = 1.25
			game._apply_ui_scale()
			game.ui_scale_changed.emit(1.25)
			_check(_world.player.camera.zoom.is_equal_approx(Vector2.ONE * 0.8), "kamera oddala się przy większym interfejsie")
			if DisplayServer.get_name() != "headless":
				var raw := minf(root.size.x / 640.0, root.size.y / 360.0)
				var expected: float = root.size.x / (maxf(floorf(raw), 1.0) * 1.25)
				_check(absf(root.get_visible_rect().size.x - expected) < 1.0, "interfejs powiększony 1,25x (%.0f px szerokości)" % root.get_visible_rect().size.x)
			inv.toggle()
		8:
			var start := inv.position
			_click(inv, start + Vector2(6, 6), true)
			_move(inv, start + Vector2(26, 16))
			_move(inv, start + Vector2(-34, 26))
			_click(inv, start + Vector2(-34, 26), false)
			_moved_to = inv.position
			_check(_moved_to == (start + Vector2(-40, 20)).floor(), "okno przesunięte za tło")
			_check(game.window_layouts.has("InventoryWindow"), "położenie okna zapamiętane")
			_click(inv, inv.position + Vector2(10, 10), true, MOUSE_BUTTON_WHEEL_UP, true)
			_check(is_equal_approx(inv.scale.x, 1.1), "Ctrl + kółko powiększa okno")
			inv.toggle()
			inv.position = Vector2.ZERO
			inv.scale = Vector2.ONE
			inv.toggle()
		10:
			_check(is_equal_approx(inv.scale.x, 1.1) and inv.position.distance_to(_moved_to) < 3.0,
					"po ponownym otwarciu okno wraca na swoje miejsce")
			if _out != "":
				root.get_texture().get_image().save_png(_out)
		11:
			game.ui_scale = 1.0
			game._apply_ui_scale()
			game.window_layouts = {}
			if _had_settings:
				var file := FileAccess.open(SETTINGS, FileAccess.WRITE)
				file.store_buffer(_backup)
				file.close()
			else:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false
