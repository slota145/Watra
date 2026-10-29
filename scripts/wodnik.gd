class_name Wodnik
extends Boss
## Wodnik, Pan Topieli - władca Topielczego Uroczyska: pękaty staruch w ociekającym surducie
## i czerwonej czapce, z brodą z wodorostów i fajką. Mieszka na wysepce pośrodku czarnej
## sadzawki, otoczony garnkami z duszami topielców. Ataki:
## - Wir: czerwone koło pod graczem, potem wir, który wciąga do środka i rani,
## - Fala: czerwony pas przed Wodnikiem, potem przetacza się nim fala wody (rani i odrzuca),
## - Topielcy: trzy kałuże wokół gracza - po chwili wyskakują z nich utopce (najwyżej kilku naraz).

@export var whirl_damage := 12
@export var wave_damage := 36
@export var max_adds := 6

const WHIRL_TELEGRAPH := 1.0
const WHIRL_RADIUS := 62.0
const WHIRL_TIME := 2.2
const WHIRL_PULL := 140.0
const WAVE_TELEGRAPH := 0.85
const WAVE_LENGTH := 230.0
const WAVE_WIDTH := 44.0
const SUMMON_TELEGRAPH := 1.1
const DROWNER := preload("res://scenes/drowner.tscn")

var _whirl_center := Vector2.ZERO
var _whirl_left := 0.0
var _whirl_tick := 0.0
var _whirl_fx: Node2D
var _wave_dir := Vector2.RIGHT
var _puddles: Array[Telegraph] = []
var _adds: Array[Node] = []


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("wodnik_laugh", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_adds.assign(_adds.filter(func(a) -> bool: return is_instance_valid(a) and a.state != State.DEAD))
	var roll := randf()
	if _adds.size() < max_adds and roll < 0.3 and distance < 260.0:
		_start_attack("summon", SUMMON_TELEGRAPH)
		_puddles.clear()
		for i in 3:
			var spot := _player.global_position + Vector2.from_angle(TAU * i / 3.0 + randf()) * 46.0
			var puddle := Telegraph.new()
			puddle.shape = Telegraph.Shape.CIRCLE
			puddle.radius = 16.0
			puddle.duration = SUMMON_TELEGRAPH
			var layer := get_tree().get_first_node_in_group("floor_layer")
			(layer if layer != null else get_parent()).add_child(puddle)
			puddle.global_position = spot
			_puddles.append(puddle)
		Sfx.play_at("wodnik_laugh", global_position, -3.0)
	elif distance < WAVE_LENGTH * 0.85 and roll < 0.65:
		_wave_dir = to_player.normalized()
		_face(_player.global_position)
		_start_attack("wave", WAVE_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _wave_dir.angle(), WAVE_TELEGRAPH)
		telegraph.length = WAVE_LENGTH
		telegraph.width = WAVE_WIDTH
	elif distance < 320.0:
		_whirl_center = _player.global_position
		_start_attack("whirl", WHIRL_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _whirl_center, 0.0, WHIRL_TELEGRAPH)
		telegraph.radius = WHIRL_RADIUS
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["whirl", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_remove_telegraph()
				_whirl_left = WHIRL_TIME
				_whirl_tick = 0.0
				_whirl_fx = _make_whirl(_whirl_center)
				Sfx.play_at("whirlpool", _whirl_center)
				_set_stage("act", WHIRL_TIME)
		["whirl", "act"]:
			velocity = Vector2.ZERO
			_whirl_left -= delta
			_whirl_tick -= delta
			if _player_alive():
				var to_center := _whirl_center - _player.global_position
				if to_center.length() < WHIRL_RADIUS:
					# wciąga do środka - tym mocniej, im bliżej brzegu
					_player._knockback = to_center.normalized() * WHIRL_PULL
					if _whirl_tick <= 0.0:
						_whirl_tick = 0.5
						_player.take_damage(whirl_damage, _whirl_center)
			if _stage_timer <= 0.0:
				if is_instance_valid(_whirl_fx):
					_whirl_fx.queue_free()
				_set_stage("recover", 0.5)
		["wave", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(wave_damage, 320.0)
				_remove_telegraph()
				SkillEffects.tide(get_parent(), global_position, _wave_dir.angle(), 0.28, WAVE_LENGTH)
				Sfx.play_at("tide_wave", global_position)
				_shake_camera(5.0)
				_set_stage("recover", 0.8)
		["summon", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				for puddle in _puddles:
					if not is_instance_valid(puddle):
						continue
					var drowner: Node = DROWNER.instantiate()
					drowner.lurk = false
					drowner.position = puddle.global_position
					drowner.leash_radius = 300.0
					drowner.xp_reward = 20
					drowner.algae_drop_chance = 0.2
					drowner.pearl_drop_chance = 0.0
					drowner.equipment_drop_chance = 0.0
					get_parent().add_child(drowner)
					drowner.emerge_now()
					_adds.append(drowner)
					puddle.queue_free()
				_puddles.clear()
				_set_stage("recover", 0.6)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Wir na ziemi: obracające się, zwężające kręgi wody.
func _make_whirl(center: Vector2) -> Node2D:
	var fx := WhirlFx.new()
	fx.radius = WHIRL_RADIUS
	fx.life = WHIRL_TIME
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(fx)
	fx.global_position = center
	return fx


func _cancel_attack() -> void:
	super()
	if is_instance_valid(_whirl_fx):
		_whirl_fx.queue_free()
	for puddle in _puddles:
		if is_instance_valid(puddle):
			puddle.queue_free()
	_puddles.clear()


## Klatki: 0-3 chód, 4 spoczynek (pykanie fajki), 5 wezwanie, 6 wir, 7 fala.
func _animate(delta: float) -> void:
	if _attack == "summon":
		sprite.frame = 5
	elif _attack == "whirl":
		sprite.frame = 6
	elif _attack == "wave":
		sprite.frame = 7 if _attack_stage != "telegraph" else 4
	elif velocity.length() > 8.0:
		_anim_time += delta * 6.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _die() -> void:
	super()
	for add in _adds:
		if is_instance_valid(add) and add.state != State.DEAD:
			add.take_damage(99999, global_position)
	Sfx.play_at("wodnik_laugh", global_position, 2.0)
	Sfx.play_at("boss_splash", global_position)


func _drop_trophies() -> void:
	_spawn_pickup("drowned_algae", 8)
	_spawn_pickup("drowned_pearl", 3)


class WhirlFx:
	extends Node2D
	var radius := 60.0
	var life := 2.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var fade := minf(1.0, minf(_t / 0.3, (life - _t) / 0.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius, Color(0.1, 0.3, 0.4, 0.35 * fade))
		for k in 4:
			var r := radius * (1.0 - fmod(_t * 0.8 + k * 0.25, 1.0))
			var start := _t * 4.0 + k * 1.5
			draw_arc(Vector2.ZERO, r, start, start + 4.0, 24, Color(0.6, 0.9, 1.0, 0.8 * fade), 2.0)
		draw_circle(Vector2.ZERO, 6.0, Color(0.05, 0.15, 0.2, 0.8 * fade))
