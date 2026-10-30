class_name SatyrKing
extends Boss
## Faun-Król, Król Satyrów - władca wioski satyrów w Wietrznych Turniach, w królewskim gaju za ogniskiem.
## Ogromne złote rogi, korona z winorośli i złota fletnia Pana. Ataki:
## - Szarża rogami: czerwony pas - król pędzi nim z pochylonymi rogami, rani i odrzuca,
## - Fletnia: gra skoczną melodię - z wioski przybiegają satyrowie, a gracz w zasięgu traci orientację
##   (sterowanie odwrócone na kilka sekund),
## - Pnącza: spod gracza i wokół niego wyrastają winorośle - kto w nich stoi, zostaje oplątany (unieruchomiony),
## - Tupnięcie: kopyta walą w ziemię - fala wokół króla.

@export var charge_damage := 55
@export var vine_damage := 30
@export var stomp_damage := 45

const SATYR_SCENES := ["res://scenes/satyr.tscn", "res://scenes/satyr.tscn", "res://scenes/satyr_piper.tscn"]
const CHARGE_LENGTH := 240.0
const CHARGE_WIDTH := 30.0
const CHARGE_TIME := 0.5
const FLUTE_RADIUS := 220.0
const CONFUSE_TIME := 3.5
const VINE_RADIUS := 26.0
const VINE_HOLD := 1.4
const STOMP_RADIUS := 80.0
const MAX_CALLED := 8
const VINE_COLOR := Color(0.45, 0.8, 0.35)

var _charge_from := Vector2.ZERO
var _charge_to := Vector2.ZERO
var _flute_cooldown := 3.0
var _called: Array = []


func _ready() -> void:
	super()
	map_color = Satyr.SATYR_COLOR
	quest_kind = "satyr"


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("goat_bleat", global_position, 4.0)


func _process_fight(delta: float) -> void:
	_flute_cooldown -= delta
	super(delta)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_face(_player.global_position)
	_called = _called.filter(func(s) -> bool: return is_instance_valid(s) and s.state != State.DEAD)
	if distance < 60.0 and randf() < 0.6:
		_start_attack("stomp", 0.7)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.7)
		circle.radius = STOMP_RADIUS
		_wind_up(0.7)
	elif _flute_cooldown <= 0.0 and distance < FLUTE_RADIUS:
		_start_attack("flute", 1.0)
		_wind_up(1.0, Vector2(0.92, 1.1))
		Sfx.play_at("rusalka_song", global_position, -2.0)
	elif distance < CHARGE_LENGTH and randf() < 0.55:
		var dir := to_player.normalized()
		_charge_from = global_position
		_charge_to = global_position + dir * CHARGE_LENGTH
		_start_attack("charge", 0.75)
		var line := _show_telegraph(Telegraph.Shape.LINE, global_position, dir.angle(), 0.75)
		line.length = CHARGE_LENGTH
		line.width = CHARGE_WIDTH
		_wind_up(0.75, Vector2(1.15, 0.85))
	elif distance < 320.0:
		_start_attack("vines", 0.5)
		_wind_up(0.5)
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["charge", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("goat_bleat", global_position)
				_set_stage("act", CHARGE_TIME)
		["charge", "act"]:
			var t := clampf(1.0 - _stage_timer / CHARGE_TIME, 0.0, 1.0)
			global_position = _charge_from.lerp(_charge_to, t)
			_afterimage(Color(0.9, 0.6, 1.0, 0.45))
			if _player_in_telegraph() and global_position.distance_to(_player.global_position) < 26.0:
				_hurt_player(charge_damage, 360.0)
			if _stage_timer <= 0.0:
				_remove_telegraph()
				_debris(global_position, 10, 120.0)
				_shake_camera(5.0)
				_set_stage("recover", 0.7)
		["flute", "telegraph"]:
			if _stage_timer <= 0.0:
				_flute_cooldown = 11.0
				SkillEffects.shockwave(get_parent(), global_position, FLUTE_RADIUS, Color(1.0, 0.8, 0.35))
				if _player_alive() and _player.global_position.distance_to(global_position) < FLUTE_RADIUS:
					_player.confuse(CONFUSE_TIME)
				if _called.size() < MAX_CALLED:
					for i in 3:
						var satyr: Goblin = load(SATYR_SCENES[i]).instantiate()
						satyr.level = level - 3
						satyr.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(90.0, 140.0)
						get_parent().add_child(satyr)
						satyr.appear()
						satyr.aggro()
						_called.append(satyr)
				_set_stage("recover", 0.6)
		["vines", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				var spots := [_player.global_position]
				for k in (3 if health > max_health * 0.5 else 5):
					spots.append(_player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 100.0))
				for spot: Vector2 in spots:
					_vine(spot)
				_set_stage("recover", 0.9)
		["stomp", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				if _player_in_telegraph():
					_hurt_player(stomp_damage, 260.0)
				_remove_telegraph()
				_ground_crack(global_position, STOMP_RADIUS * 0.8)
				_debris(global_position, 14, 150.0)
				_shake_camera(6.0)
				Sfx.play_at("rock_break", global_position)
				_set_stage("recover", 0.6)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Winorośl spod ziemi: zielone koło, po chwili pnącza oplątują tego, kto w nim stoi.
func _vine(spot: Vector2) -> void:
	var telegraph := Telegraph.new()
	telegraph.radius = VINE_RADIUS
	telegraph.duration = 0.8
	telegraph.modulate = Color(0.6, 1.0, 0.5)
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = spot
	get_tree().create_timer(0.8, false).timeout.connect(func() -> void:
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		if state == State.DEAD:
			return
		for i in 6:
			SkillEffects.spark(get_parent(), spot + Vector2.from_angle(TAU * i / 6.0) * 12.0, VINE_COLOR, 3)
		Sfx.play_at("roots_burst", spot, -6.0)
		if _player_alive() and _player.global_position.distance_to(spot) <= VINE_RADIUS:
			_player.take_damage(vine_damage, spot)
			_player.apply_slow(0.05, VINE_HOLD))


func _cancel_attack() -> void:
	super()


## Klatki: 0-3 chód, 4 spoczynek, 5 zamach (pochylone rogi / fletnia przy ustach), 6 szarża / gra, 7 tupnięcie.
func _animate(delta: float) -> void:
	match _attack:
		"charge":
			sprite.frame = 5 if _attack_stage == "telegraph" else 6
			return
		"flute", "vines":
			sprite.frame = 5 if _attack_stage == "telegraph" else 4
			return
		"stomp":
			sprite.frame = 5 if _attack_stage == "telegraph" else 7
			return
	if velocity.length() > 8.0:
		_anim_time += delta * 7.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("satyr_horn", 6)
