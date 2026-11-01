class_name Gryf
extends Boss
## Gryf - złoty władca wzgórza na zachodzie Pól Zbożowych (poziom 42). Krąży w powietrzu nad swoim wzgórzem,
## machając skrzydłami, a jego cień sunie po ziemi. Zbyt słaby śmiałek dostaje ostrzeżenie (World._process_warnings);
## kto podejdzie mimo to, zostaje zaatakowany. Gryf lata nad przeszkodami i w walce krąży wokół gracza. Ataki:
## - Pikowanie: czerwony pas przez gracza - gryf przelatuje nim z wyciągniętymi szponami,
## - Podmuch: machnięcie skrzydłami - stożek wiatru odpycha i rani, z wiatrem lecą ostre pióra,
## - Uderzenie szponami: spada z góry na miejsce gracza,
## - Trąby powietrzne: zrywa kilka trąb, które suną za graczem,
## - Krzyk: ogłuszający wrzask - gracz w pobliżu na chwilę zwalnia.

@export var dive_damage := 60
@export var gust_damage := 40
@export var feather_damage := 30
@export var slam_damage := 65
@export var tornado_damage := 25

const FLY_HEIGHT := 34.0
const PATROL_RADIUS := 210.0
const ORBIT_RADIUS := 120.0
const DIVE_LENGTH := 260.0
const DIVE_WIDTH := 34.0
const DIVE_TIME := 0.45
const GUST_RADIUS := 170.0
const GUST_ARC := 0.6
const SLAM_RADIUS := 62.0
const SLAM_TIME := 0.6
const GOLD := Color(1.0, 0.85, 0.45)
## Efekty z kreatora efektów PixelLab: stożek wiatru (ten sam co Strzała Wichru, długość w klatce WIND_FX_LENGTH),
## złote szpony z pyłem (promień w klatce SLAM_FX_RADIUS), krzyk - złote fale dźwięku (promień w klatce
## SCREECH_FX_RADIUS) i zapętlona trąba powietrzna.
const WIND_FX := preload("res://assets/effects/bow_wind_cone.png")
const WIND_FX_LENGTH := 104.0
const SLAM_FX := preload("res://assets/effects/gryf_slam.png")
const SLAM_FX_RADIUS := 36.0
const SCREECH_FX := preload("res://assets/effects/gryf_screech.png")
const SCREECH_FX_RADIUS := 104.0
const TORNADO_FX := preload("res://assets/effects/gryf_tornado.png")

var _patrol_angle := 0.0
var _orbit_sign := 1.0
var _dive_from := Vector2.ZERO
var _dive_to := Vector2.ZERO
var _dir := Vector2.RIGHT
var _slam_from := Vector2.ZERO
var _slam_to := Vector2.ZERO
var _bob := 0.0


func _ready() -> void:
	super()
	map_color = GOLD
	quest_kind = "gryf"
	hurt_radius = 20.0
	# lata nad drzewami i murkami
	collision_mask = 0
	_patrol_angle = randf() * TAU
	_orbit_sign = 1.0 if randf() < 0.5 else -1.0


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("storm_eagle_screech", global_position)


func _physics_process(delta: float) -> void:
	_bob += delta
	if state == State.IDLE:
		# krąży nad wzgórzem
		_patrol_angle += delta * 0.35
		var target := home + Vector2.from_angle(_patrol_angle) * PATROL_RADIUS
		velocity = (target - global_position).limit_length(speed * 1.2)
		move_and_slide()
		if _player_alive() and not _player_is_safe() and global_position.distance_to(_player.global_position) < aggro_radius:
			aggro()
		_animate(delta)
		return
	super(delta)


func _process_fight(delta: float) -> void:
	super(delta)
	# w walce krąży wokół gracza, zamiast podchodzić do zwarcia
	if _attack == "" and state == State.CHASE and _player_alive():
		var rel := global_position - _player.global_position
		var target := _player.global_position + rel.normalized().rotated(_orbit_sign * 0.6) * ORBIT_RADIUS
		velocity = (target - global_position).limit_length(speed)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_dir = to_player.normalized()
	_face(_player.global_position)
	if distance > 380.0:
		return false
	var roll := randf()
	if roll < 0.3:
		_dive_from = global_position
		_dive_to = global_position + _dir * DIVE_LENGTH
		_start_attack("dive", 0.8)
		var line := _show_telegraph(Telegraph.Shape.LINE, global_position, _dir.angle(), 0.8)
		line.length = DIVE_LENGTH
		line.width = DIVE_WIDTH
		_wind_up(0.8)
	elif roll < 0.5 and distance < GUST_RADIUS:
		_start_attack("gust", 0.75)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.75)
		cone.radius = GUST_RADIUS
		cone.half_arc = GUST_ARC
		_wind_up(0.75)
	elif roll < 0.7:
		_slam_to = _player.global_position
		_start_attack("slam", 0.6)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _slam_to, 0.0, 0.6 + SLAM_TIME)
		circle.radius = SLAM_RADIUS
		_wind_up(0.6)
	elif roll < 0.85:
		_start_attack("tornado", 0.8)
		_wind_up(0.8, Vector2(0.9, 1.12))
	else:
		_start_attack("screech", 0.7)
		_wind_up(0.7, Vector2(0.9, 1.12))
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["dive", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("wing_gust", global_position)
				_set_stage("act", DIVE_TIME)
		["dive", "act"]:
			var t := clampf(1.0 - _stage_timer / DIVE_TIME, 0.0, 1.0)
			global_position = _dive_from.lerp(_dive_to, t)
			_afterimage(Color(1.0, 0.9, 0.5, 0.45))
			if _player_in_telegraph() and global_position.distance_to(_player.global_position) < 34.0:
				_hurt_player(dive_damage, 260.0)
			if _stage_timer <= 0.0:
				_remove_telegraph()
				_set_stage("recover", 0.5)
		["gust", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.9))
				if _player_in_telegraph():
					_hurt_player(gust_damage, 420.0)
				_remove_telegraph()
				SkillEffects.sheet_once(get_parent(), WIND_FX, 9, 18.0, global_position, Vector2(4, 53), _dir.angle(), 1.0,
						GUST_RADIUS / WIND_FX_LENGTH)
				for k in 5:
					var feather := EnemySpit.new()
					feather.style = "feather"
					feather.position = global_position + Vector2(0, -FLY_HEIGHT * 0.5)
					feather.direction = _dir.rotated((k - 2) * 0.22)
					feather.damage = feather_damage
					get_parent().add_child(feather)
				Sfx.play_at("wing_gust", global_position, 2.0)
				_set_stage("recover", 0.6)
		["slam", "telegraph"]:
			if _stage_timer <= 0.0:
				_slam_from = global_position
				_set_stage("act", SLAM_TIME)
		["slam", "act"]:
			var t := clampf(1.0 - _stage_timer / SLAM_TIME, 0.0, 1.0)
			global_position = _slam_from.lerp(_slam_to, t)
			sprite.position.y = -FLY_HEIGHT - sin(t * PI) * 40.0 + t * FLY_HEIGHT
			if _stage_timer <= 0.0:
				_snap(Vector2(1.3, 0.75))
				if _player_in_telegraph():
					_hurt_player(slam_damage, 300.0)
				_remove_telegraph()
				_ground_crack(global_position, SLAM_RADIUS, 3.0)
				SkillEffects.sheet_once(get_parent(), SLAM_FX, 10, 16.0, global_position, Vector2(36, 25), 0.0, 1.0,
						SLAM_RADIUS / SLAM_FX_RADIUS)
				_shake_camera(8.0)
				Sfx.play_at("rock_break", global_position)
				_set_stage("recover", 0.8)
		["tornado", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				for k in (2 if health > max_health * 0.5 else 4):
					var twister := GryfTornado.new()
					twister.damage = tornado_damage
					twister.target = _player
					get_parent().add_child(twister)
					twister.global_position = global_position + Vector2.from_angle(randf() * TAU) * 40.0
				Sfx.play_at("wing_gust", global_position, 4.0)
				_set_stage("recover", 0.6)
		["screech", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("storm_eagle_screech", global_position, 4.0)
				SkillEffects.sheet_once(get_parent(), SCREECH_FX, 12, 16.0, global_position, Vector2(110, 70), 0.0, 1.0,
						200.0 / SCREECH_FX_RADIUS)
				_shake_camera(5.0)
				if _player_alive() and _player.global_position.distance_to(global_position) < 200.0:
					_player.apply_slow(0.4, 2.0)
				_set_stage("recover", 0.5)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Klatki: 0-3 machanie skrzydłami, 4 szybowanie, 5 krzyk (skrzydła szeroko), 6 pikowanie, 7 szpony.
func _animate(delta: float) -> void:
	if _attack == "slam" and _attack_stage == "act":
		sprite.frame = 7
		return
	sprite.position.y = -FLY_HEIGHT + sin(_bob * 3.0) * 3.0
	match _attack:
		"dive":
			sprite.frame = 6 if _attack_stage == "act" else 5
			return
		"slam":
			sprite.frame = 5 if _attack_stage == "telegraph" else 7
			return
		"gust", "tornado", "screech":
			sprite.frame = 5 if _attack_stage == "telegraph" else int(_bob * 12.0) % 4
			return
	_anim_time += delta * 7.0
	sprite.frame = int(_anim_time) % 4
	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0


func _cancel_attack() -> void:
	super()
	sprite.position.y = -FLY_HEIGHT


func _die() -> void:
	super()
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "position:y", 0.0, 0.3)


func _drop_trophies() -> void:
	_spawn_pickup("gryf_feather", 6)


## Trąba powietrzna Gryfa: sunie za graczem przez kilka sekund i rani go przy zetknięciu.
class GryfTornado extends Node2D:
	const LIFE := 4.0
	const SPEED := 75.0
	var damage := 20
	var target: Node2D
	var _time := 0.0
	var _hit_cd := 0.0

	func _ready() -> void:
		var fx := SkillEffects.looping(TORNADO_FX, 8, 14.0, Vector2(23, 64))
		fx.name = "Fx"
		add_child(fx)

	func _process(delta: float) -> void:
		_time += delta
		_hit_cd -= delta
		# trąba pojawia się i znika płynnie (rysuje ją zapętlona animacja "Fx")
		modulate.a = clampf(minf(_time * 4.0, (LIFE - _time) * 3.0), 0.0, 1.0)
		if is_instance_valid(target):
			global_position += (target.global_position - global_position).normalized() * SPEED * delta
			if _hit_cd <= 0.0 and target.global_position.distance_to(global_position) < 18.0 and not target.is_dead:
				_hit_cd = 0.8
				target.take_damage(damage, global_position)
		if _time >= LIFE:
			queue_free()
