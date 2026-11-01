extends SceneTree
## Płynność przesuwania tła menu: mysz udaje ruch (wymuszamy pozycję), mierzymy przesunięcie co klatkę.
var _menu: Node
var _frame := 0
var _last := Vector2.ZERO
var _steps: Array = []
func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()
func _setup() -> void:
	_menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(_menu)
func _process(delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	var shift: Vector2 = (_menu._view.material as ShaderMaterial).get_shader_parameter("shift")
	if _frame > 12:
		# krok przeliczony na 60 klatek na sekundę - na wolnym komputerze klatki są dłuższe, a kroki większe
		_steps.append(((shift - _last) * Vector2(640, 360) * 4.0).length() / maxf(delta * 60.0, 1.0))
	_last = shift
	if _frame == 10:
		root.get_viewport().warp_mouse(Vector2(1270, 700))
	if _frame == 90:
		# płynnie: tło rusza się w każdej klatce, najwyżej o półtora piksela (1 px wypadał na samej granicy)
		var zero := _steps.filter(func(v): return v < 0.001).size()
		print("klatek: ", _steps.size(), " bez ruchu: ", zero, " max krok px ekranu: ", _steps.max())
		print(("OK   " if zero == 0 and _steps.max() < 1.5 else "FAIL ") + "płynne przesuwanie tła menu")
		if not OS.get_cmdline_user_args().is_empty():
			root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		quit()
	return false
