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
var _ghost_time := 0.0
var _dust_time := 0.0


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -24)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	if distance < slam_radius * 0.85:
		_start_attack("slam", SLAM_TELEGRAPH)
		# maczuga w górę: wódz rośnie i czerwienieje z wściekłości
		_wind_up(SLAM_TELEGRAPH * 0.85, Vector2(0.9, 1.14))
		Sfx.play_at("bear_roar", global_position, -8.0)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, SLAM_TELEGRAPH)
		telegraph.radius = slam_radius
	elif distance < 260.0:
		_charge_dir = to_player.normalized()
		_start_attack("charge", CHARGE_TELEGRAPH)
		_wind_up(CHARGE_TELEGRAPH * 0.9, Vector2(1.14, 0.88))
		Sfx.play_at("bear_roar", global_position, -12.0)
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
					_hurt_player(slam_damage, 240.0)
				# uderzenie o ziemię: podwójna fala, pęknięcia, kamienie w powietrze, potężne trzęsienie
				_shake_camera(12.0)
				_snap(Vector2(1.28, 0.78))
				var at := global_position + Vector2(18.0 * (-1.0 if sprite.flip_h else 1.0), 2)
				SkillEffects.shockwave(get_parent(), at, slam_radius, Color(1.0, 0.55, 0.2))
				get_tree().create_timer(0.14).timeout.connect(func() -> void:
					if is_instance_valid(self):
						SkillEffects.shockwave(get_parent(), at, slam_radius * 1.45, Color(0.85, 0.6, 0.35)))
				_ground_crack(at, slam_radius, 4.0)
				_debris(at, 26, 220.0)
				_burst(at, Color(0.6, 0.47, 0.32), 30, 140.0)
				Sfx.play_at("hit_heavy", global_position)
				Sfx.play_at("rock_break", global_position, -2.0)
				Sfx.play_at("shockwave", global_position, -4.0)
				_remove_telegraph()
				_set_stage("recover", 0.7)
		["charge", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_remove_telegraph()
				_charge_travelled = 0.0
				_snap(Vector2(1.2, 0.86))
				Sfx.play_at("dash", global_position)
				_set_stage("act", 1.2)
		["charge", "act"]:
			velocity = _charge_dir * charge_speed
			_charge_travelled += charge_speed * delta
			# taranowanie: powidoki i tuman kurzu za wodzem
			_ghost_time -= delta
			if _ghost_time <= 0.0:
				_ghost_time = 0.05
				_afterimage(Color(1.0, 0.55, 0.3, 0.45))
			_dust_time -= delta
			if _dust_time <= 0.0:
				_dust_time = 0.06
				_burst(global_position - _charge_dir * 10.0, Color(0.62, 0.52, 0.4, 0.8), 4, 40.0)
			if _player_alive() and not _hit_player and _player.global_position.distance_to(global_position) < CHARGE_WIDTH * 0.8:
				_hurt_player(charge_damage, 340.0)
				_shake_camera(8.0)
				SkillEffects.spark(get_parent(), _player.global_position + Vector2(0, -12), Color(1.0, 0.8, 0.4), 14)
				Sfx.play_at("hit_heavy", global_position)
			var blocked := get_slide_collision_count() > 0 and _charge_travelled > 24.0
			if _charge_travelled >= charge_length or blocked or _stage_timer <= 0.0:
				velocity = Vector2.ZERO
				# hamowanie / zderzenie: fala i kurz
				_shake_camera(7.0 if blocked else 4.0)
				SkillEffects.shockwave(get_parent(), global_position, 40.0, Color(0.85, 0.6, 0.35))
				_debris(global_position, 12 if blocked else 6, 150.0)
				_burst(global_position, Color(0.6, 0.47, 0.32), 14, 80.0)
				Sfx.play_at("hit_heavy" if blocked else "rock_break", global_position, -4.0)
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
