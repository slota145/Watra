extends SceneTree
## Walka: gracz (nieśmiertelny) stoi w największym skupisku wrogów; mierzymy czas klatki.

const ZONES := ["forest", "fields", "swamp", "mountains", "ancient", "cemetery"]
const SECONDS := 12.0
const MOVES := ["move_right", "move_down", "move_left", "move_up"]
var _t0 := 0
var _worst: Array = []

var _zone_i := 0
var _world: Node
var _frame := 0
var _last := 0
var _times: Array[float] = []
var _spot := Vector2.ZERO
var _spikes := 0


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.get_node("Game").save_path = "user://test_savegame.json"
	_start_zone.call_deferred()


func _start_zone() -> void:
	var zone: String = ZONES[_zone_i]
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": zone, "player": {}}
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
	print("%s: spawns %d, densest cluster %d at %s" % [zone, _world._goblin_spawns.size(), best, _spot])
	_frame = 0
	_spikes = 0
	_times.clear()
	_last = Time.get_ticks_usec()


func _process(_delta: float) -> bool:
	if _world == null:
		return false
	var player: Node2D = _world.player
	player._invulnerable_timer = 999.0
	if _frame == 10:
		player.global_position = _spot + Vector2(0, 90)
		player.camera.reset_smoothing()
	var now := Time.get_ticks_usec()
	if _frame == 20:
		_t0 = now
	if _frame >= 20:
		var step := int((now - _t0) / 1500000) % 4
		for i in 4:
			if i == step: Input.action_press(MOVES[i])
			else: Input.action_release(MOVES[i])
	if _frame > 20:
		var t := (now - _last) / 1000.0
		_times.append(t)
		if t > 16.7:
			_spikes += 1
		if t > 8.0:
			_worst.append([snappedf(t, 0.1), snappedf((now - _t0) / 1e6, 0.1)])
	_last = now
	_frame += 1
	if _frame > 20 and now - _t0 > SECONDS * 1e6:
		_times.sort()
		var avg := 0.0
		for t in _times: avg += t
		avg /= _times.size()
		print("=== %s combat: frame avg %.2f ms, p99 %.2f ms, max %.2f ms, klatek >16.7ms: %d, wrogów w grupie enemies: %d, pociski: %d" % [
			ZONES[_zone_i], avg, _times[int(_times.size() * 0.99)], _times[-1], _spikes,
			get_nodes_in_group("enemies").size(), get_nodes_in_group("projectiles").size()])
		print("  klatki > 8 ms [ms, sekunda]: ", _worst.slice(0, 30))
		_worst.clear()
		for m in MOVES: Input.action_release(m)
		_world.queue_free()
		_world = null
		_zone_i += 1
		if _zone_i >= ZONES.size():
			quit()
		else:
			_start_zone.call_deferred()
	return false
