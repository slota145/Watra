extends SceneTree
## Pomiar fal Skarbnika Z RYSOWANIEM: loch 7. stopnia, wzmocnienie Skarbnika z ustaloną liczbą żywych wrogów naraz
## (ciągły strumień z bram), postać nieśmiertelna kosi ich umiejętnościami obszarowymi. Sceny: "mgnienie" (Młynek
## z wirującym Mgnieniem bez odnowienia - Amulet Wiecznego Wiru), "miecz" (atak + Młynek). Wypisuje średni i p95 czas
## klatki, czas skryptów i fizyki, liczbę zabitych na sekundę i ilu wrogów faktycznie żyło. Sufit żywych naraz to
## propozycja SKA_ALIVE na najwyższym wzmocnieniu.
## Uruchamiaj z oknem: SCRIPT=tests/bench_skarbnik.gd tools/screenshot.sh -- [scena] [żywych naraz] [sekundy]

const SCENES := ["mgnienie", "miecz"]

var _world: Node
var _scene := "mgnienie"
var _alive := 100
var _seconds := 12.0
var _frame := 0
var _spirit: Node
var _t0 := 0
var _last := 0
var _samples: Array[Dictionary] = []
var _marks := {"proc": 0, "phys": 0, "proc_t": 0, "phys_t": 0}


class Mark extends Node:
	var marks: Dictionary
	var first := false
	func _process(_d: float) -> void:
		var now := Time.get_ticks_usec()
		if first:
			marks["proc_t"] = now
		else:
			marks["proc"] += now - marks["proc_t"]
	func _physics_process(_d: float) -> void:
		var now := Time.get_ticks_usec()
		if first:
			marks["phys_t"] = now
		else:
			marks["phys"] += now - marks["phys_t"]


func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return a != "--")
	if args.size() > 0 and args[0] in SCENES:
		_scene = args[0]
	if args.size() > 1:
		_alive = int(args[1])
	if args.size() > 2:
		_seconds = float(args[2])
	for first in [true, false]:
		var mark := Mark.new()
		mark.marks = _marks
		mark.first = first
		mark.process_priority = -100000 if first else 100000
		mark.process_physics_priority = -100000 if first else 100000
		root.add_child.call_deferred(mark)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.get_node("Game").save_path = "user://test_savegame.json"
	load("res://scripts/skarbnik_offer.gd").ledger_path = "user://test_skarbnik.json"
	var config: Dictionary = load("res://scripts/dungeons.gd").config("catacombs", 7, [], 9001)
	config["mechanics"] = ["skarbnik"]
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child.call_deferred(_world)


func _gear(p: Node) -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var level := 41
	p.stats.level = level
	var weapon: String = loot.generate(loot.base_for("sword", level), "rare", level)
	p.equipment.equip_to("weapon", weapon, 10)
	for id in ["whirlwind", "flicker"]:
		p.skills.levels[id] = 5
	p.skills.character_level = 99
	# punkty umiejętności daje pasek umiejętności, nie poziom postaci
	p.skills.bonus_points += 99
	if _scene == "mgnienie":
		p.equipment.equip_to("necklace", loot.legendary_at_level("legend_endless_amulet", level), 0)
	var tree: GDScript = load("res://scripts/skill_tree.gd")
	for id in ["whirlwind", "flicker"]:
		p.skills.grant_node(tree.node_for_skill(id))
	# mocniejsze obrażenia - postać ma kosić wrogów 43. poziomu jak w końcówce gry
	p.stats.set_temp("bench", {"damage_percent": 30.0})


func _process(_delta: float) -> bool:
	if _world == null or not _world.is_inside_tree() or _world.get("_dungeon") == null:
		return false
	var p: Node = _world.player
	p._invulnerable_timer = 999.0
	paused = false
	p.health = p.stats.max_health()
	p.mana = p.stats.max_mana()
	_frame += 1
	if _frame == 10:
		_gear(p)
		_spirit = _world._dungeon.skarbniki[0]
		_spirit.alive_override = _alive
		_spirit.quota_override = 1000000
		_spirit.current_offer()
		_spirit.strengthen()
	if _frame >= 10 and _frame < 60:
		p.global_position = _spirit.global_position + Vector2(0, 40)
		p.camera.reset_smoothing()
	if _frame < 60:
		_last = Time.get_ticks_usec()
		_t0 = _last
		return false
	var target: Node2D = null
	var best := 400.0
	for e: Node2D in get_nodes_in_group("enemies"):
		var d := e.global_position.distance_to(p.global_position)
		if d < best:
			best = d
			target = e
	if target != null:
		p.aim_override = target.global_position - p.global_position
	if _scene == "mgnienie":
		p._skill_held = true
		p._held_ids["flicker"] = true
	else:
		p._attack_held = true
		p._skill_held = (_frame / 90) % 2 == 0
	# postać wraca w pobliże Skarbnika (Mgnienie potrafi wynieść ją daleko)
	if p.global_position.distance_to(_spirit.global_position) > 500.0:
		p.global_position = _spirit.global_position + Vector2(0, 40)
	var now := Time.get_ticks_usec()
	_samples.append({
		"frame": (now - _last) / 1000.0,
		"process": _marks["proc"] / 1000.0,
		"physics": _marks["phys"] / 1000.0,
		"kills": _spirit.kills,
		"alive": _spirit.attackers.size(),
	})
	_marks["proc"] = 0
	_marks["phys"] = 0
	_last = now
	if now - _t0 < _seconds * 1e6:
		return false
	_report()
	quit()
	return false


func _report() -> void:
	var frames: Array[float] = []
	var process := 0.0
	var physics := 0.0
	var alive := 0.0
	for s in _samples:
		frames.append(s["frame"])
		process += s["process"]
		physics += s["physics"]
		alive += s["alive"]
	var n := float(_samples.size())
	var avg := 0.0
	for f in frames:
		avg += f
	avg /= n
	frames.sort()
	var kills: int = _samples[-1]["kills"] - _samples[0]["kills"]
	print("=== %s, sufit %d: klatka śr %.2f ms (%.0f FPS), p95 %.2f, max %.2f | skrypty _process %.2f ms, _physics %.2f ms | żywych śr %.0f | zabitych %d (%.1f/s)" % [
		_scene, _alive, avg, 1000.0 / avg, frames[int(n * 0.95)], frames[-1], process / n, physics / n, alive / n, kills, kills / _seconds])
