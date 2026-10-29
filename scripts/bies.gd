class_name Bies
extends Boss
## Bies - czarny demon puszczy, władca siedliska bestii. Kozie rogi, czerwone ślepia,
## żarzące się pęknięcia na piersi, długie szpony i dym u stóp. Ataki:
## - Szarża: czerwony pas - Bies przebiega nim z ogromną prędkością,
## - Ryk: koło wokół niego - rani, spowalnia i zatruwa strachem (czarny dym),
## - Krok w cień: znika w dymie i pojawia się za plecami gracza, od razu tnąc stożkiem.

@export var charge_damage := 40
@export var roar_damage := 24
@export var slash_damage := 36

const CHARGE_LENGTH := 260.0
const CHARGE_SPEED := 520.0
const ROAR_RADIUS := 110.0
const SLASH_RADIUS := 70.0
const SLASH_ARC := 0.9

var _dir := Vector2.RIGHT
var _travel_left := 0.0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -40)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("bies_roar", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	var roll := randf()
	_dir = to_player.normalized()
	if distance < ROAR_RADIUS * 0.85 and roll < 0.4:
		_start_attack("roar", 0.85)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.85)
		telegraph.radius = ROAR_RADIUS
	elif roll < 0.7 and distance < 320.0:
		_start_attack("shadow", 0.45)
		_smoke(global_position)
		Sfx.play_at("wing_gust", global_position, -4.0)
	elif distance < CHARGE_LENGTH * 0.9:
		_face(_player.global_position)
		_start_attack("charge", 0.8)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _dir.angle(), 0.8)
		telegraph.length = CHARGE_LENGTH
		telegraph.width = 36.0
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["roar", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(roar_damage, 200.0)
					_player.apply_slow(0.5, 2.5)
					_player.apply_poison(8.0, 3.0)
				_remove_telegraph()
				_smoke(global_position)
				_shake_camera(6.0)
				Sfx.play_at("bies_roar", global_position)
				_set_stage("recover", 0.7)
		["charge", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_travel_left = CHARGE_LENGTH
				_set_stage("act", CHARGE_LENGTH / CHARGE_SPEED + 0.2)
		["charge", "act"]:
			var step := minf(CHARGE_SPEED * delta, _travel_left)
			_travel_left -= step
			velocity = _dir * CHARGE_SPEED
			if not _hit_player and _player_alive() and global_position.distance_to(_player.global_position) < 26.0:
				_hurt_player(charge_damage, 340.0)
				_shake_camera(6.0)
			if _travel_left <= 0.0 or _stage_timer <= 0.0:
				_remove_telegraph()
				_set_stage("recover", 0.8)
		["shadow", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0 and _player_alive():
				# pojawia się za plecami gracza i od razu tnie
				var behind: Vector2 = -_player._facing_vector()
				global_position = _player.global_position + behind * 44.0
				reset_physics_interpolation()
				_smoke(global_position)
				_dir = (_player.global_position - global_position).normalized()
				_face(_player.global_position)
				var telegraph := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.4)
				telegraph.radius = SLASH_RADIUS
				telegraph.half_arc = SLASH_ARC
				_set_stage("act", 0.4)
		["shadow", "act"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(slash_damage, 220.0)
				_remove_telegraph()
				for side in [-1.0, 1.0]:
					SkillEffects.claw(get_parent(), global_position + _dir * 34.0 + Vector2(0, -18), side, 34.0, Color(1.0, 0.4, 0.3))
				Sfx.play_at("claw", global_position)
				_set_stage("recover", 0.7)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Kłąb czarnego dymu (krok w cień, ryk).
func _smoke(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.global_position = at + Vector2(0, -16)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 26
	p.lifetime = 0.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(0.08, 0.05, 0.07, 0.75)
	p.emitting = true
	get_parent().add_child(p)
	p.finished.connect(p.queue_free)


## Klatki: 0-3 chód, 4 spoczynek, 5 ryk, 6 zamach, 7 cięcie.
func _animate(delta: float) -> void:
	match _attack:
		"roar":
			sprite.frame = 5
		"charge":
			sprite.frame = 6 if _attack_stage == "telegraph" else 7
			sprite.flip_h = _dir.x < 0.0
		"shadow":
			sprite.frame = 7 if _attack_stage != "telegraph" else 6
			sprite.modulate.a = 0.35 if _attack_stage == "telegraph" else 1.0
		_:
			sprite.modulate.a = 1.0
			if velocity.length() > 8.0:
				_anim_time += delta * 7.0
				sprite.frame = int(_anim_time) % 4
				sprite.flip_h = velocity.x < 0.0
			else:
				sprite.frame = 4
				if state == State.CHASE and _player != null:
					_face(_player.global_position)


func _cancel_attack() -> void:
	super()
	sprite.modulate.a = 1.0


func _die() -> void:
	super()
	_smoke(global_position)
	Sfx.play_at("bies_roar", global_position, 3.0)


func _drop_trophies() -> void:
	_spawn_pickup("beast_fang", 8)
