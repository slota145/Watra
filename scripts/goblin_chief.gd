class_name GoblinChief
extends Boss
## Wódz goblinów - olbrzymi goblin z kolczastą maczugą. Ataki:
## - Uderzenie o ziemię: czerwone koło wokół wodza, maczuga w górze, potem trzęsienie.
## - Szarża: czerwony pas w stronę gracza, wódz pochyla się i taranuje wszystko na drodze.

@export var slam_damage := 30
@export var slam_radius := 64.0
@export var charge_damage := 26
@export var charge_length := 180.0
@export var charge_speed := 330.0

const SLAM_TELEGRAPH := 1.1
const CHARGE_TELEGRAPH := 0.85
const CHARGE_WIDTH := 30.0

var _charge_dir := Vector2.RIGHT
var _charge_travelled := 0.0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -24)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if distance < slam_radius * 0.85:
		_start_attack("slam", SLAM_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, SLAM_TELEGRAPH)
		telegraph.radius = slam_radius
	elif distance < 260.0:
		_charge_dir = to_player.normalized()
		_start_attack("charge", CHARGE_TELEGRAPH)
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _charge_dir.angle(), CHARGE_TELEGRAPH)
		telegraph.length = charge_length + 16.0
		telegraph.width = CHARGE_WIDTH
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["slam", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(slam_damage, 180.0)
				_shake_camera(7.0)
				_burst(global_position, Color(0.6, 0.47, 0.32), 30, 140.0)
				_remove_telegraph()
				_set_stage("recover", 0.7)
		["charge", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_remove_telegraph()
				_charge_travelled = 0.0
				_set_stage("act", 1.2)
		["charge", "act"]:
			velocity = _charge_dir * charge_speed
			_charge_travelled += charge_speed * delta
			if _player_alive() and _player.global_position.distance_to(global_position) < CHARGE_WIDTH * 0.8:
				_hurt_player(charge_damage, 280.0)
			var blocked := get_slide_collision_count() > 0 and _charge_travelled > 24.0
			if _charge_travelled >= charge_length or blocked or _stage_timer <= 0.0:
				velocity = Vector2.ZERO
				_shake_camera(4.0)
				_burst(global_position, Color(0.6, 0.47, 0.32), 14, 80.0)
				_set_stage("recover", 0.8)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


## Klatki: 0-3 chód, 4 spoczynek, 5 zamach, 6 uderzenie, 7 szarża.
func _animate(delta: float) -> void:
	if _attack == "slam":
		sprite.frame = 5 if _attack_stage == "telegraph" else 6
	elif _attack == "charge":
		sprite.frame = 4 if _attack_stage == "recover" else 7
		sprite.flip_h = _charge_dir.x < 0.0
	elif velocity.length() > 8.0:
		_anim_time += delta * 7.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("goblin_heart", 5)
