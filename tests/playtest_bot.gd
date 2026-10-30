extends SceneTree
## Tester-gracz: bot przechodzi krainę jak człowiek - podchodzi do najbliższych potworów (prawdziwe klawisze
## ruchu), celuje, atakuje i używa umiejętności, zbiera łup, a co jakiś czas przenosi się w inne miejsce
## (kolejne siedliska), żeby obejść całą mapę. Zdrowie gracza jest uzupełniane (liczymy tylko, ile razy by
## zginął). Zgłasza: zablokowanie postaci (stoi mimo ruchu), potwory poza mapą lub z NaN, zbyt długie
## klatki, i - przez stderr w run_tests.ps1 - każdy błąd skryptu. Na koniec zapis i odczyt stanu krainy.
## Użycie: -s tests/playtest_bot.gd -- <kraina> [sekundy]

const VISIT_TIME := 14.0
const STUCK_TIME := 2.5
const ATTACK_RANGE := 34.0

var _world: Node
var _zone := "forest"
var _duration := 70.0
var _time := 0.0
var _frame := 0
var _visit_left := 0.0
var _spots: Array = []
var _spot := 0
var _last_pos := Vector2.ZERO
var _still := 0.0
var _stuck := 0
var _stuck_at: Array = []
var _deaths := 0
var _kills_start := 0
var _slow_frames := 0
var _bad_enemies := 0
var _fails := 0
var _skill_timer := 0.0
var _game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_zone = args[0]
	if args.size() > 1:
		_duration = float(args[1])
	Engine.max_fps = 60
	_game = root.get_node("Game")
	_game.save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	_game._pending_load = {"seed": 4242, "zone": _zone, "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func _check(what: String, ok: bool, info := "") -> void:
	print(("OK   " if ok else "FAIL ") + what + (" " + info if info != "" else ""))
	if not ok:
		_fails += 1


func _process(delta: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame < 5:
		return false
	var p: Node2D = _world.player
	if _frame == 5:
		for spawn in _world._goblin_spawns:
			# bossowie z ostrzeżeniem (Hydra, Gryf) są dużo powyżej poziomu krainy - nie dla testera
			if not spawn.get("warn", false):
				_spots.append(spawn["position"])
		_spots.shuffle()
		_kills_start = _world.hud.kills
		_gear_up(p)
		_last_pos = p.global_position
	if delta > 0.05 and _frame > 30:
		_slow_frames += 1
	_time += delta
	_visit_left -= delta
	if p.is_dead:
		_deaths += 1
		p.respawn() if p.has_method("respawn") else null
		return false
	# zdrowie uzupełniane - liczymy tylko, czy by zginął
	if p.health < p.stats.max_health() * 0.25:
		_deaths += 1
		p.health = p.stats.max_health()
	if _visit_left <= 0.0 and not _spots.is_empty():
		_visit_left = VISIT_TIME
		p.global_position = _spots[_spot % _spots.size()] + Vector2(randf_range(-60, 60), randf_range(40, 80))
		p.reset_physics_interpolation()
		_spot += 1
		_last_pos = p.global_position
		_still = 0.0
	var target := _nearest_enemy(p)
	var to: Vector2 = (target.global_position - p.global_position) if target != null else Vector2.ZERO
	_release_moves()
	if target != null and to.length() > ATTACK_RANGE:
		var dir: Vector2 = to.normalized()
		if dir.x < -0.3: Input.action_press("move_left")
		if dir.x > 0.3: Input.action_press("move_right")
		if dir.y < -0.3: Input.action_press("move_up")
		if dir.y > 0.3: Input.action_press("move_down")
		# zablokowany: chce iść, a stoi w miejscu
		if p.global_position.distance_to(_last_pos) < 0.5:
			_still += delta
			if _still > STUCK_TIME:
				_stuck += 1
				_stuck_at.append(Vector2i((p.global_position / 16.0).floor()))
				_visit_left = 0.0
				_still = 0.0
		else:
			_still = 0.0
	if target != null:
		p.aim_override = to
		p._attack_held = to.length() < ATTACK_RANGE * 1.5
		_skill_timer -= delta
		if _skill_timer <= 0.0 and to.length() < 120.0:
			_skill_timer = 3.0
			p._skill_held = true
		elif _skill_timer < 2.6:
			p._skill_held = false
	_last_pos = p.global_position
	# porządek wśród potworów
	if _frame % 30 == 0:
		var bounds := Rect2(Vector2.ZERO, Vector2(_world.map_size) * 16.0).grow(64)
		for e in root.get_tree().get_nodes_in_group("enemies"):
			if not bounds.has_point(e.global_position) or is_nan(e.global_position.x):
				_bad_enemies += 1
	if _time >= _duration:
		_finish(p)
	return false


## Postać typowa dla krainy: poziom jak potwory przy jej wejściu (+1), punkty w sile, broń i zbroja z łupu
## tego poziomu z zaklęciem jak w symulacji balansu (ok. +poziom/4).
func _gear_up(p) -> void:
	var levels = load("res://scripts/levels.gd")
	var loot = load("res://scripts/loot.gd")
	var level: int = levels.ZONES[_zone][0] + 1
	p.stats.level = level
	p.stats.attributes["strength"] = level - 1
	var enchant := level / 4
	for entry in [["weapon", "sword"], ["helmet", "helm"], ["chest", "plate"], ["gloves", "gauntlets"], ["boots", "greaves"]]:
		var id: String = loot.generate(loot.base_for(entry[1], level), "magic", level)
		p.equipment.equip_to(entry[0], id, enchant if entry[0] == "weapon" else 0)
	p.health = p.stats.max_health()


func _nearest_enemy(p) -> Node2D:
	var best: Node2D = null
	var best_d := 420.0
	for e in root.get_tree().get_nodes_in_group("enemies"):
		if e.get("quest_kind") == "animal":
			continue
		var d: float = e.global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _release_moves() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


func _finish(p) -> void:
	_release_moves()
	p._attack_held = false
	var kills: int = _world.hud.kills - _kills_start
	print("kraina %s: %.0f s, zabitych %d, poziom %d, 'śmierci' %d, zablokowań %d %s, długich klatek %d" % [
			_zone, _time, kills, p.stats.level, _deaths, _stuck, str(_stuck_at.slice(0, 6)), _slow_frames])
	_check("bot walczy (zabija potwory)", kills >= 5, str(kills))
	_check("postać się nie blokuje", _stuck <= 3, str(_stuck))
	_check("potwory w granicach mapy", _bad_enemies == 0, str(_bad_enemies))
	_check("płynność (klatki > 50 ms)", _slow_frames <= 10, str(_slow_frames))
	# zapis i odczyt stanu krainy w biegu
	var data: Dictionary = _world.get_save_data() if _world.has_method("get_save_data") else {}
	_check("zapis stanu krainy", not data.is_empty())
	var text := JSON.stringify(data)
	var back = JSON.parse_string(text)
	_check("zapis da się odczytać (JSON)", back is Dictionary and (back as Dictionary).size() == data.size())
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
