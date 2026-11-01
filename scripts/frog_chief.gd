class_name FrogChief
extends Boss
## Wódz żaboludzi - olbrzymia ropucha w koronie z muszli, na wyspie w środku rozlewiska. Ataki:
## - Bicz języka: czerwony pas w stronę gracza, potem język wystrzeliwuje, rani i przyciąga
##   gracza do wodza.
## - Skok i plusk: czerwone koło pod graczem, wódz wybija się w powietrze i spada na to miejsce
##   z ogromnym pluskiem.

@export var tongue_damage := 28
@export var tongue_length := 170.0
@export var leap_damage := 34
@export var leap_radius := 58.0

const TONGUE_TELEGRAPH := 0.9
const TONGUE_WIDTH := 22.0
const TONGUE_OUT := 0.12
const TONGUE_TIME := 0.4
const LEAP_CROUCH := 0.5
const LEAP_TIME := 0.65
const LEAP_HEIGHT := 46.0
## Wysokość pyska nad stopami (skąd wystrzeliwuje język).
const MOUTH := Vector2(16, -30)
## Plusk wody i błota z kreatora efektów PixelLab (lądowanie po skoku; promień kręgów w klatce SPLASH_RADIUS).
const SPLASH_FX := preload("res://assets/effects/bulgor_splash.png")
const SPLASH_RADIUS := 45.0

var _tongue_dir := Vector2.RIGHT
var _tongue: Line2D
var _tongue_time := 0.0
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_time := 0.0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("frog_boss_roar", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if distance < tongue_length * 0.9 and (distance < 70.0 or randf() < 0.55):
		_tongue_dir = to_player.normalized()
		_face(_player.global_position)
		_start_attack("tongue", TONGUE_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _tongue_dir.angle(), TONGUE_TELEGRAPH)
		telegraph.length = tongue_length
		telegraph.width = TONGUE_WIDTH
	elif distance < 300.0:
		_leap_to = _player.global_position
		_face(_leap_to)
		_start_attack("leap", LEAP_CROUCH)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _leap_to, 0.0, LEAP_CROUCH + LEAP_TIME)
		telegraph.radius = leap_radius
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["tongue", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_tongue = Line2D.new()
				_tongue.width = 5.0
				_tongue.default_color = Color(0.85, 0.35, 0.45)
				_tongue.begin_cap_mode = Line2D.LINE_CAP_ROUND
				_tongue.end_cap_mode = Line2D.LINE_CAP_ROUND
				_tongue.position = Vector2(MOUTH.x * (-1.0 if sprite.flip_h else 1.0), MOUTH.y)
				_tongue.z_index = 3
				add_child(_tongue)
				_tongue_time = 0.0
				Sfx.play_at("tongue_lash", global_position)
				_set_stage("act", TONGUE_TIME)
		["tongue", "act"]:
			velocity = Vector2.ZERO
			_tongue_time += delta
			var reach := minf(1.0, _tongue_time / TONGUE_OUT)
			if _tongue_time > TONGUE_OUT:
				reach = maxf(0.0, 1.0 - (_tongue_time - TONGUE_OUT) / (TONGUE_TIME - TONGUE_OUT))
				# trafienie w chwili pełnego wysunięcia - język przyciąga gracza do wodza
				if is_instance_valid(_telegraph):
					if _player_in_telegraph():
						_hurt_player(tongue_damage)
						_player._knockback = (global_position - _player.global_position).normalized() * 420.0
						SkillEffects.sheet_once(get_parent(), SPLASH_FX, 12, 14.0, _player.global_position, Vector2(46, 35), 0.0, 1.0, 0.45)
					_remove_telegraph()
			_tongue.points = PackedVector2Array([Vector2.ZERO, _tongue_dir * tongue_length * reach])
			if _stage_timer <= 0.0:
				_remove_tongue()
				_set_stage("recover", 0.5)
		["leap", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_leap_from = global_position
				_leap_time = 0.0
				$CollisionShape2D.set_deferred("disabled", true)
				Sfx.play_at("frog_boss_roar", global_position, -3.0)
				_set_stage("act", LEAP_TIME)
		["leap", "act"]:
			velocity = Vector2.ZERO
			_leap_time += delta
			var t := minf(_leap_time / LEAP_TIME, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = -sin(t * PI) * LEAP_HEIGHT
			if t >= 1.0:
				_land()
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Lądowanie po skoku: wielki plusk, fala wody i błota.
func _land() -> void:
	sprite.position.y = 0.0
	$CollisionShape2D.set_deferred("disabled", false)
	if _player_in_telegraph():
		_hurt_player(leap_damage, 220.0)
	_remove_telegraph()
	_shake_camera(8.0)
	SkillEffects.sheet_once(get_parent(), SPLASH_FX, 12, 14.0, global_position, Vector2(46, 35), 0.0, 1.0,
			leap_radius / SPLASH_RADIUS)
	Sfx.play_at("boss_splash", global_position)
	_set_stage("recover", 0.9)


func _cancel_attack() -> void:
	super()
	_remove_tongue()
	$CollisionShape2D.set_deferred("disabled", false)


func _remove_tongue() -> void:
	if is_instance_valid(_tongue):
		_tongue.queue_free()
	_tongue = null


## Klatki: 0-3 chód, 4 spoczynek (i przysiad przed skokiem), 5 nabieranie powietrza, 6 język, 7 skok.
func _animate(delta: float) -> void:
	if _attack == "tongue":
		sprite.frame = 5 if _attack_stage == "telegraph" else 6 if _attack_stage == "act" else 4
	elif _attack == "leap":
		sprite.frame = 7 if _attack_stage == "act" else 4
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
	Sfx.play_at("frog_death", global_position, 4.0)
	Sfx.play_at("boss_splash", global_position, -4.0)


func _drop_trophies() -> void:
	_spawn_pickup("frog_tongue", 6)
	_spawn_pickup("fish", 4)
