extends SceneTree
## Zrzut ekranu dowolnej sceny: ładuje scenę, czeka podaną liczbę sekund (animacje, wczytywanie)
## i zapisuje widok do PNG, po czym zamyka grę.
## Użycie: -s tools/screenshot.gd -- <plik.png> [scena] [sekundy]
## Bez sceny bierze główną scenę projektu (menu). Na Linuksie bez ekranu: tools/screenshot.sh

var _out := "screenshot.png"
var _wait := 1.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	if args.size() > 1 and args[1] != "":
		scene = args[1]
	if args.size() > 2:
		_wait = float(args[2])
	root.add_child.call_deferred(load(scene).instantiate())
	_capture.call_deferred()


func _capture() -> void:
	await create_timer(_wait).timeout
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(_out)
	if err != OK:
		push_error("Nie udało się zapisać %s (błąd %d)" % [_out, err])
	quit(err)
