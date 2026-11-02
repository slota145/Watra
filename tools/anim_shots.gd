extends SceneTree
## Zrzuty klatek animacji ataków Wojciecha w grze: seria zwykłych cięć mieczem i umiejętności miecza
## (Rozpłatanie, Rozłupanie Ziemi, Szarża, Półksiężyc, Młynek) w wybranym kierunku. Każdy ruch to jeden rząd
## klatek wyciętych wokół postaci (kamera mocno przybliżona), wszystko w jednym obrazie.
## Uruchamianie (z oknem, najpierw import zasobów). Stały krok czasu (--fixed-fps 60) jest potrzebny, bo programowe
## renderowanie w chmurze jest wolne i bez niego atak łapie się w jednej-dwóch klatkach:
##   xvfb-run -a -s "-screen 0 3840x2160x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       --fixed-fps 60 -s res://tools/anim_shots.gd -- <plik.png> [kierunek x] [kierunek y] [ruchy]
## np. ... -- /tmp/ataki.png 1 0   albo   ... -- /tmp/szarza.png 0 1 lunge
## Ruchy (po przecinku): chain, rend, slam, lunge, crescent, whirl, thrust (pchnięcie po skoku Mgnienia;
## domyślnie wszystkie).
## Zmienna ANIM_DEBUG=1: zrzut co klatkę i wypisane położenie miecza (klatka postaci, pozycja, obrót).

const ZOOM := 4.0
## Wycinek wokół postaci (piksele ekranu) i liczba zrzutów w rzędzie obrazu.
const CROP := 400
const COLS := 8
## Wolne miejsce w Goblińskim Lesie (ziarno 12345).
const SPOT := Vector2(1500, 1500)

var _world: Node
var _out := "/tmp/anim_shots.png"
var _aim := Vector2.RIGHT
var _moves: Array = ["chain", "rend", "slam", "lunge", "crescent", "whirl", "thrust"]
var _frame := 0
var _rows: Array = []  # [nazwa, [Image]]
var _move_i := -1
var _move_frame := 0
var _shots: Array[Image] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 2:
		_aim = Vector2(float(args[1]), float(args[2])).normalized()
	if args.size() > 3:
		_moves = args[3].split(",")
	root.get_node("Game").save_path = "user://test_savegame.json"
	_start.call_deferred()


func _start() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _gear(p: Node) -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	p.stats.level = 30
	p.equipment.equip_to("weapon", loot.generate(loot.base_for("sword", 30), "rare", 30), 0)
	p.skills.character_level = 99
	for id in ["rend", "ground_slam", "lunge", "crescent", "whirlwind"]:
		p.skills.levels[id] = 5
	# drzewko: ścieżka do każdej umiejętności (Młynek, Szarża i Półksiężyc wymagają węzłów)
	var tree: GDScript = load("res://scripts/skill_tree.gd")
	for id in ["rend", "ground_slam", "lunge", "crescent", "whirlwind"]:
		var node: String = tree.node_for_skill(id)
		if node == "":
			continue
		if not p.skills.nodes.has("melee"):
			p.skills.nodes["melee"] = {}
		for step in tree.path_to("melee", node):
			p.skills.nodes["melee"][step] = true


## Ile klatek gry trwa ruch i co ile klatek robić zrzut.
func _plan(move: String) -> Vector2i:
	match move:
		"chain":
			return Vector2i(3 * 26, 1 if OS.has_environment("ANIM_DEBUG") else 2)
		"lunge":
			return Vector2i(24, 1)
		"whirl":
			return Vector2i(24, 1)
	return Vector2i(30, 2)


func _begin(p: Node, move: String) -> void:
	p.aim_override = _aim * 100.0
	match move:
		"rend":
			p.sword_skills._rend()
		"slam":
			p.sword_skills._ground_slam()
		"lunge":
			p._start_lunge(5)
		"crescent":
			p._start_crescent(5)
		"whirl":
			p._skill_held = true
		"thrust":
			p._face_direction(_aim)
			p.play_thrust(_aim)


func _step(p: Node, move: String, f: int) -> void:
	if move == "chain" and f % 26 == 0:
		p._start_attack()


func _process(_delta: float) -> bool:
	if _world == null:
		return false
	var p: Node = _world.player
	paused = false
	p._invulnerable_timer = 0.0  # bez mrugania postaci (zdrowie i tak jest uzupełniane)
	p.health = p.stats.max_health()
	p.mana = p.stats.max_mana()
	_frame += 1
	for e: Node2D in get_nodes_in_group("enemies"):
		if e.global_position.distance_to(p.global_position) < 400.0:
			e.queue_free()
	if _frame == 10:
		_gear(p)
	if _frame >= 10 and _frame < 40:
		# z dala od osady: ludzie i napisy nad nimi zasłaniałyby postać
		p.global_position = SPOT
	if _frame < 40:
		p.camera.zoom = Vector2.ONE * ZOOM
		p.camera.position_smoothing_enabled = false
		p.camera.reset_smoothing()
		# bez interfejsu (napisy i okna zasłaniałyby postać)
		for layer in _world.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		return false
	if _move_i < 0 or _move_frame >= _plan(_moves[_move_i]).x:
		if _move_i >= 0:
			_rows.append([_moves[_move_i], _shots])
			p._skill_held = false
		_move_i += 1
		_move_frame = -30  # przerwa: postać wraca do spoczynku, a ostatnie zrzuty pokazują powrót broni
		_shots = []
		if _move_i >= _moves.size():
			_save()
			quit()
			return false
		return false
	if _move_frame == 0:
		_begin(p, _moves[_move_i])
	if _move_frame >= 0:
		_step(p, _moves[_move_i], _move_frame)
		if _move_frame % _plan(_moves[_move_i]).y == 0:
			_shots.append(_grab(p))
			if OS.has_environment("ANIM_DEBUG"):
				print("%s %d: klatka %d, miecz %s obrót %.2f widoczny %s, pivot %.2f z %d" % [_moves[_move_i], _move_frame, p.sprite.frame % 8, p.sword.position, p.sword.rotation, p.sword.visible, p.pivot.rotation, p.pivot.z_index])
	_move_frame += 1
	return false


func _grab(p: Node) -> Image:
	var img := root.get_texture().get_image()
	# kamera trzyma postać na środku obrazu
	var center := Vector2(img.get_size()) / 2.0 + Vector2(0, -13) * ZOOM * img.get_size().y / 720.0
	var rect := Rect2i(Vector2i(center) - Vector2i(CROP, CROP) / 2, Vector2i(CROP, CROP))
	rect = rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(rect)


func _save() -> void:
	var rows := 0
	for r in _rows:
		rows += ceili(r[1].size() / float(COLS))
	var out := Image.create(COLS * CROP, rows * CROP, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	var y := 0
	for r in _rows:
		var shots: Array = r[1]
		for i in shots.size():
			var img: Image = shots[i]
			img.convert(Image.FORMAT_RGBA8)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((i % COLS) * CROP, y + (i / COLS) * CROP))
		y += ceili(shots.size() / float(COLS)) * CROP
		print("%s: %d klatek" % [r[0], shots.size()])
	out.save_png(_out)
	print("zapisano ", _out)
