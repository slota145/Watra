extends SceneTree
## Pomiar walki w największej gromadzie krainy Z RYSOWANIEM i umiejętnościami (bench_combat mierzy tylko stanie):
## jedna scena na uruchomienie (dwa światy naraz się gryzą) - stanie, miecz (atak + Młynek), księga (Łańcuch
## błyskawic, Zamieć, Burza Peruna, Spadająca Gwiazda), mgnienie (Młynek z wirującym Mgnieniem bez odnowienia -
## Amulet Wiecznego Wiru). Dla każdej: średni i p95 czas klatki, czas skryptów i fizyki (Performance),
## wywołania rysowania, liczba węzłów, wrogowie w pościgu, pociski i efekty.
## Uruchamiaj z oknem: Godot --path . -s res://tests/bench_village.gd -- [scena] [kraina] [sekundy]

const SCENES := ["stoi", "miecz", "ksiega", "mgnienie"]
const SPELLS := ["chain_lightning", "blizzard", "storm_call", "meteor"]

var _world: Node
var _zone := "mountains"
var _seconds := 10.0
var _scene_i := 0
var _frame := 0
var _spot := Vector2.ZERO
var _t0 := 0
var _last := 0
var _samples: Array[Dictionary] = []
## Stopery: węzeł z najniższym priorytetem zaczyna, z najwyższym kończy pomiar _process i _physics_process.
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
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_scene_i = maxi(SCENES.find(args[0]), 0)
	if args.size() > 1:
		_zone = args[1]
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
	_start.call_deferred()


func _start() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": _zone, "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	var best := 0
	for a: Dictionary in _world._goblin_spawns:
		var n := 0
		for b: Dictionary in _world._goblin_spawns:
			if a["position"].distance_to(b["position"]) < 260.0:
				n += 1
		if n > best:
			best = n
			_spot = a["position"]
	print("%s: gromada %d wrogów w %s, okno %s" % [_zone, best, _spot, root.size])
	_frame = 0


func _gear(p: Node, scene: String) -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var level: int = load("res://scripts/levels.gd").ZONES[_zone][0] + 2
	p.stats.level = level
	var base := "sword" if scene != "ksiega" else "book"
	var weapon: String = loot.generate(loot.base_for(base, level), "rare", level)
	p.equipment.equip_to("weapon", weapon, level / 4)
	for id in ["whirlwind", "flicker"] + SPELLS:
		p.skills.levels[id] = 5
	p.skills.character_level = 99
	if scene == "mgnienie":
		p.equipment.equip_to("necklace", loot.legendary_at_level("legend_endless_amulet", level), 0)
	var tree: GDScript = load("res://scripts/skill_tree.gd")
	var skills: GDScript = load("res://scripts/skills.gd")
	for id in ["whirlwind", "flicker"] + SPELLS:
		var node: String = tree.node_for_skill(id)
		var weapon_type: String = skills.get_data(id)["weapon"]
		for step in tree.path_to(weapon_type, node):
			if not p.skills.nodes.has(weapon_type):
				p.skills.nodes[weapon_type] = {}
			p.skills.nodes[weapon_type][step] = true


func _process(_delta: float) -> bool:
	if _world == null:
		return false
	var p: Node = _world.player
	var scene: String = SCENES[_scene_i]
	p._invulnerable_timer = 999.0
	paused = false  # np. okno awansu po _gear pauzuje grę
	p.health = p.stats.max_health()
	p.mana = p.stats.max_mana()
	_frame += 1
	if _frame == 10:
		_gear(p, scene)
	if _frame >= 10 and _frame < 40:
		p.global_position = _spot + Vector2(0, 60)
		p.camera.reset_smoothing()
	if _frame < 40:
		_last = Time.get_ticks_usec()
		_t0 = _last
		return false
	# celuj w najbliższego wroga i walcz
	var target: Node2D = null
	var best := 300.0
	for e: Node2D in get_nodes_in_group("enemies"):
		var d := e.global_position.distance_to(p.global_position)
		if d < best:
			best = d
			target = e
	if target != null:
		p.aim_override = target.global_position - p.global_position
	match scene:
		"miecz":
			p._attack_held = true
			p._skill_held = (_frame / 90) % 2 == 0
		"mgnienie":
			p._skill_held = true
			p._held_ids["flicker"] = true
		"ksiega":
			p._held_ids["chain_lightning"] = true
			if _frame % 20 == 0:
				p.spell_skills.press(SPELLS[1 + (_frame / 20) % 3])
	var now := Time.get_ticks_usec()
	_samples.append({
		"frame": (now - _last) / 1000.0,
		"pos": p.global_position.distance_to(_spot),
		"kills": _world.hud.kills,
		"prof": Engine.get_meta("prof_frame", {}).duplicate(),
		"t": (now - _t0) / 1e6,
		"process": _marks["proc"] / 1000.0,
		"physics": _marks["phys"] / 1000.0,
		"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
	})
	Engine.set_meta("prof_frame", {})
	_marks["proc"] = 0
	_marks["phys"] = 0
	_last = now
	if now - _t0 < _seconds * 1e6:
		return false
	_report(scene, p)
	quit()
	return false


func _report(scene: String, _p: Node) -> void:
	var frames: Array[float] = []
	var sums := {"process": 0.0, "physics": 0.0, "draws": 0.0, "objects": 0.0, "nodes": 0.0}
	for s in _samples:
		frames.append(s["frame"])
		for k: String in sums:
			sums[k] += s[k]
	frames.sort()
	var n := float(_samples.size())
	var avg := 0.0
	for f in frames:
		avg += f
	avg /= n
	var chasing := 0
	for e in get_nodes_in_group("enemies"):
		if e.state in [1, 2]:  # CHASE, ATTACK
			chasing += 1
	var worst := _samples.duplicate()
	for i in worst.size():
		worst[i]["killed"] = worst[i]["kills"] - (worst[i - 1]["kills"] if i > 0 else worst[i]["kills"])
		worst[i]["dn"] = worst[i]["nodes"] - (worst[i - 1]["nodes"] if i > 0 else worst[i]["nodes"])
	worst.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["frame"] > b["frame"])
	for w in worst.slice(0, 12):
		var parts := ""
		for k: String in w["prof"]:
			parts += " %s %.1f" % [k, w["prof"][k] / 1000.0]
		print("  wolna klatka %.1f ms w %.2f s (skrypty %.1f, fizyka skryptów %.1f): zabitych %d, węzłów %+d |%s" % [w["frame"], w["t"], w["process"], w["physics"], w["killed"], w["dn"], parts])
	var kinds := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node.is_physics_processing() or node.is_processing():
			var script: Script = node.get_script()
			var key := (script.resource_path.get_file() if script != null else node.get_class()) + (" P" if node.is_physics_processing() else "") + (" I" if node.is_processing() else "")
			kinds[key] = kinds.get(key, 0) + 1
	var keys := kinds.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return kinds[a] > kinds[b])
	for k in keys.slice(0, 15):
		print("  przetwarzane: %s x%d" % [k, kinds[k]])
	var prof: Dictionary = Engine.get_meta("prof", {})
	for k in prof:
		print("  razem %s: %.1f ms" % [k, prof[k] / 1000.0])
	print("  zabitych razem: %d" % (_samples[-1]["kills"] - _samples[0]["kills"]))
	print("  odległość od gromady na końcu: %.0f px" % _samples[-1]["pos"])
	print("=== %s: klatka śr %.2f ms (%.0f FPS), p95 %.2f, max %.2f | skrypty _process %.2f ms, skrypty _physics %.2f ms | rysowania %.0f, obiekty %.0f, węzły %.0f | w walce %d, pociski %d" % [
		scene, avg, 1000.0 / avg, frames[int(n * 0.95)], frames[-1], sums["process"] / n, sums["physics"] / n,
		sums["draws"] / n, sums["objects"] / n, sums["nodes"] / n, chasing, get_nodes_in_group("projectiles").size()])
