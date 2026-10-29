class_name ForestBeast
extends Boss
## Bestia z siedliska bestii w Prastarym Lesie - mini-boss. Jest ich niewiele, żyją z dala
## od siebie i każda pilnuje swojego rewiru (ślady pazurów, złamane drzewa, krew).
## Ma pasek życia jak boss i dwa ataki zapowiadane czerwoną poświatą:
## - niedźwiedź (bear): Uderzenie (koło wokół siebie) i Szarża (pas w stronę gracza),
## - wilkołak (werewolf): Skok (koło pod graczem, ląduje na nim) i Szał (stożek trzech cięć).
## Zostawia kły bestii i zawsze przedmiot.

@export_enum("bear", "werewolf") var kind := "bear"
@export var slam_damage := 30
@export var charge_damage := 34

const SLAM_RADIUS := 58.0
const CHARGE_LENGTH := 200.0
const CHARGE_SPEED := 420.0
const POUNCE_RADIUS := 40.0
const POUNCE_TIME := 0.5
const FRENZY_RADIUS := 64.0
const FRENZY_ARC := 0.9

var _dir := Vector2.RIGHT
var _travel_left := 0.0
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_time := 0.0


func _ready() -> void:
	super()
	hurt_radius = 12.0
	map_color = Color(0.85, 0.45, 0.3)
	quest_kind = "beast"


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -28)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("bear_roar" if kind == "bear" else "werewolf_howl", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if kind == "bear":
		if distance < SLAM_RADIUS * 0.9:
			_start_attack("slam", 0.75)
			var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.75)
			telegraph.radius = SLAM_RADIUS
		elif distance < CHARGE_LENGTH * 0.9:
			_dir = to_player.normalized()
			_face(_player.global_position)
			_start_attack("charge", 0.8)
			var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _dir.angle(), 0.8)
			telegraph.length = CHARGE_LENGTH
			telegraph.width = 34.0
		else:
			return false
	else:
		if distance < FRENZY_RADIUS * 0.85:
			_dir = to_player.normalized()
			_face(_player.global_position)
			_start_attack("frenzy", 0.55)
			var telegraph := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.55)
			telegraph.radius = FRENZY_RADIUS
			telegraph.half_arc = FRENZY_ARC
		elif distance < 240.0:
			_leap_to = _player.global_position
			_face(_leap_to)
			_start_attack("pounce", 0.5)
			var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _leap_to, 0.0, 0.5 + POUNCE_TIME)
			telegraph.radius = POUNCE_RADIUS
		else:
			return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["slam", "telegraph"], ["frenzy", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(slam_damage, 260.0 if _attack == "slam" else 160.0)
				_remove_telegraph()
				_shake_camera(5.0 if _attack == "slam" else 3.0)
				_burst(global_position, Color(0.4, 0.3, 0.2), 20, 120.0)
				if _attack == "frenzy":
					for side in [-1.0, 0.0, 1.0]:
						SkillEffects.claw(get_parent(), global_position + _dir * 30.0 + Vector2(0, -12), side if side != 0.0 else -1.0, 30.0, Color(0.9, 0.5, 0.4))
					Sfx.play_at("claw", global_position)
				else:
					Sfx.play_at("hit_heavy", global_position)
				_set_stage("recover", 0.7)
		["charge", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_travel_left = CHARGE_LENGTH
				Sfx.play_at("bear_roar", global_position, -4.0)
				_set_stage("act", CHARGE_LENGTH / CHARGE_SPEED + 0.2)
		["charge", "act"]:
			var step := minf(CHARGE_SPEED * delta, _travel_left)
			_travel_left -= step
			velocity = _dir * CHARGE_SPEED
			if not _hit_player and _player_alive() and global_position.distance_to(_player.global_position) < 24.0:
				_hurt_player(charge_damage, 320.0)
				_shake_camera(5.0)
			if _travel_left <= 0.0 or _stage_timer <= 0.0:
				_remove_telegraph()
				_set_stage("recover", 0.8)
		["pounce", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_leap_from = global_position
				_leap_time = 0.0
				$CollisionShape2D.set_deferred("disabled", true)
				_set_stage("act", POUNCE_TIME)
		["pounce", "act"]:
			velocity = Vector2.ZERO
			_leap_time += delta
			var t := minf(_leap_time / POUNCE_TIME, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = -sin(t * PI) * 30.0
			if t >= 1.0:
				sprite.position.y = 0.0
				$CollisionShape2D.set_deferred("disabled", false)
				if _player_in_telegraph():
					_hurt_player(charge_damage, 200.0)
				_remove_telegraph()
				_shake_camera(4.0)
				_burst(global_position, Color(0.4, 0.3, 0.2), 16, 100.0)
				_set_stage("recover", 0.6)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


func _cancel_attack() -> void:
	super()
	$CollisionShape2D.set_deferred("disabled", false)


## Klatki: 0-3 chód, 4 spoczynek, 5 ryk / staje dęba, 6 zamach, 7 cios.
func _animate(delta: float) -> void:
	if _attack != "":
		sprite.frame = 7 if _attack_stage == "act" or _attack_stage == "recover" else (5 if kind == "bear" else 6)
		if _attack in ["charge", "frenzy", "pounce"]:
			sprite.flip_h = (_leap_to.x < global_position.x) if _attack == "pounce" else _dir.x < 0.0
	elif velocity.length() > 8.0:
		_anim_time += delta * 8.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_loot() -> void:
	for i in gold_coins:
		_spawn_pickup("gold", randi_range(gold_min, gold_max))
	_spawn_pickup("beast_fang", randi_range(2, 3))
	_spawn_pickup(Loot.random_drop(3, 0.1, Loot.MAGIC, Loot.BOSS_LEVEL_BONUS), 1)
	if randf() < 0.5:
		_spawn_pickup(Enchanting.stone_id(["weapon", "armor", "jewelry"].pick_random(), randf() < 0.15), 1)
	_spawn_pickup("blessed_stone", randi_range(3, 6))
