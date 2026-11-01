class_name ColossalGhoul
extends Boss
## Gnilec - kolosalny ghul zszyty z trupów, w dole trupowiska na wschodzie Leśnego Cmentarza. Ataki:
## - Zamach: szeroki łuk pazurów przed nim,
## - Miażdżenie: oba łapska walą w ziemię w kręgu przed nim,
## - Skok: wybija się i spada całym cielskiem tam, gdzie stał gracz,
## - Wymiociny: stożek żółci przed nim - rani i zostawia trujące kałuże,
## - Ryk (poniżej połowy zdrowia): z trupowiska wypełzają trupojady i zombie, a gracz w pobliżu na chwilę
##   zastyga ze strachu (spowolnienie).

@export var sweep_damage := 50
@export var slam_damage := 65
@export var leap_damage := 60
@export var bile_damage := 40

const SWEEP_RADIUS := 74.0
const SLAM_RADIUS := 56.0
const LEAP_RADIUS := 70.0
const LEAP_TIME := 0.7
const BILE_RADIUS := 150.0
const BILE_ARC := 0.6
const MINION_SCENES := ["res://scenes/ghoul.tscn", "res://scenes/zombie.tscn"]
const MAX_MINIONS := 6
const BILE := Color(0.6, 0.8, 0.25)
## Efekty z kreatora efektów PixelLab (tools/vfx_art.py): zamach pazurami, uderzenie w ziemię, żółć i ryk.
const FX_SWEEP := preload("res://assets/effects/ghoul_sweep.png")
const FX_SLAM := preload("res://assets/effects/ghoul_slam.png")
const FX_BILE := preload("res://assets/effects/ghoul_bile.png")
const FX_ROAR := preload("res://assets/effects/ghoul_roar.png")

var _dir := Vector2.RIGHT
var _slam_at := Vector2.ZERO
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _roar_cooldown := 6.0
var _minions: Array = []


func _ready() -> void:
	super()
	map_color = Ghoul.GHOUL_COLOR
	quest_kind = "ghoul"
	hurt_radius = 18.0


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("bies_roar", global_position)


func _process_fight(delta: float) -> void:
	_roar_cooldown -= delta
	super(delta)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_dir = to_player.normalized()
	_face(_player.global_position)
	_minions = _minions.filter(func(m) -> bool: return is_instance_valid(m) and m.state != State.DEAD)
	if health < max_health * 0.5 and _roar_cooldown <= 0.0 and _minions.size() < MAX_MINIONS:
		_start_attack("roar", 0.9)
		_wind_up(0.9, Vector2(0.9, 1.15))
	elif distance < 70.0:
		if randf() < 0.5:
			_start_attack("sweep", 0.7)
			var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.7)
			cone.radius = SWEEP_RADIUS
			cone.half_arc = 1.1
		else:
			_slam_at = global_position + _dir * 36.0
			_start_attack("slam", 0.9)
			var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _slam_at, 0.0, 0.9)
			circle.radius = SLAM_RADIUS
		_wind_up(_stage_timer)
	elif distance < 170.0 and randf() < 0.5:
		_start_attack("bile", 0.9)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.9)
		cone.radius = BILE_RADIUS
		cone.half_arc = BILE_ARC
		_wind_up(0.9)
	elif distance < 320.0:
		_leap_to = _player.global_position
		_start_attack("leap", 0.55)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _leap_to, 0.0, 0.55 + LEAP_TIME)
		circle.radius = LEAP_RADIUS
		_wind_up(0.55, Vector2(1.2, 0.8))
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["sweep", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				SkillEffects.sheet_once(get_parent(), FX_SWEEP, 8, 18.0, global_position + Vector2(0, -14), Vector2(-10, 59),
						_dir.angle(), 1.0, 1.1)
				if _player_in_telegraph():
					_hurt_player(sweep_damage, 220.0)
				_remove_telegraph()
				Sfx.play_at("claw", global_position)
				_set_stage("recover", 0.6)
		["slam", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.25, 0.8))
				if _player_in_telegraph():
					_hurt_player(slam_damage, 260.0)
				_remove_telegraph()
				_ground_crack(_slam_at, SLAM_RADIUS)
				_debris(_slam_at, 10, 150.0)
				SkillEffects.sheet_once(get_parent(), FX_SLAM, 11, 16.0, _slam_at, Vector2(62, 33), 0.0, 1.0, 1.25)
				_shake_camera(8.0)
				Sfx.play_at("rock_break", _slam_at)
				_set_stage("recover", 0.8)
		["bile", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				if _player_in_telegraph():
					_hurt_player(bile_damage)
					_player.apply_poison(maxi(1, bile_damage / 6), 3.0)
				_remove_telegraph()
				_spray_bile()
				_set_stage("recover", 0.8)
		["leap", "telegraph"]:
			if _stage_timer <= 0.0:
				_leap_from = global_position
				$CollisionShape2D.set_deferred("disabled", true)
				_set_stage("act", LEAP_TIME)
		["leap", "act"]:
			var t := clampf(1.0 - _stage_timer / LEAP_TIME, 0.0, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = -sin(t * PI) * 60.0
			_afterimage(Color(0.6, 0.9, 0.4, 0.4))
			if _stage_timer <= 0.0:
				sprite.position.y = 0.0
				$CollisionShape2D.set_deferred("disabled", false)
				_snap(Vector2(1.3, 0.75))
				if _player_in_telegraph():
					_hurt_player(leap_damage, 300.0)
				_remove_telegraph()
				_ground_crack(global_position, LEAP_RADIUS, 4.0)
				_debris(global_position, 14, 180.0)
				SkillEffects.sheet_once(get_parent(), FX_SLAM, 11, 16.0, global_position, Vector2(62, 33), 0.0, 1.0, 1.55)
				_shake_camera(10.0)
				Sfx.play_at("rock_break", global_position, 2.0)
				_set_stage("recover", 1.0)
		["roar", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_roar_cooldown = 15.0
				Sfx.play_at("bies_roar", global_position, 2.0)
				SkillEffects.sheet_once(get_parent(), FX_ROAR, 11, 16.0, global_position, Vector2(77, 66), 0.0, 1.0, 1.9)
				_shake_camera(6.0)
				if _player_alive() and _player.global_position.distance_to(global_position) < 160.0:
					_player.apply_slow(0.5, 2.0)
				for i in 3:
					var minion: Goblin = load(MINION_SCENES[i % 2]).instantiate()
					minion.level = level - 4
					minion.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(80.0, 130.0)
					get_parent().add_child(minion)
					minion.appear()
					minion.aggro()
					_minions.append(minion)
				_set_stage("recover", 0.7)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Żółć: kałuże trucizny w stożku przed ghulem.
func _spray_bile() -> void:
	Sfx.play_at("spit", global_position, 2.0)
	var layer := get_tree().get_first_node_in_group("floor_layer")
	for i in 4:
		var patch := BurningPatch.new()
		patch.style = "poison"
		patch.radius = 26.0
		patch.damage = maxi(1, bile_damage / 5)
		(layer if layer != null else get_parent()).add_child(patch)
		patch.global_position = global_position + _dir.rotated(randf_range(-BILE_ARC, BILE_ARC) * 0.8) * randf_range(50.0, BILE_RADIUS - 20.0)
	_burst(global_position + _dir * 30.0 + Vector2(0, -20), BILE, 14, 140.0)
	SkillEffects.sheet_once(get_parent(), FX_BILE, 10, 16.0, global_position + _dir * 10.0 + Vector2(0, -20), Vector2(3, 29),
			_dir.angle(), 1.0, 2.0)


## Wejście do walki: ryk z zielonymi falami.
func _fx_engage() -> void:
	SkillEffects.sheet_once(get_parent(), FX_ROAR, 11, 16.0, global_position, Vector2(77, 66), 0.0, 1.0, 1.4)


func _cancel_attack() -> void:
	super()
	$CollisionShape2D.set_deferred("disabled", false)


## Klatki: 0-3 chód, 4 spoczynek, 5 zamach, 6 uderzenie, 7 ryk / wymiociny.
func _animate(delta: float) -> void:
	match _attack:
		"sweep", "slam":
			sprite.frame = 5 if _attack_stage == "telegraph" else 6
			return
		"leap":
			sprite.frame = 5 if _attack_stage == "telegraph" else 6
			return
		"bile", "roar":
			sprite.frame = 5 if _attack_stage == "telegraph" else 7
			return
	if velocity.length() > 8.0:
		_anim_time += delta * 5.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("ghoul_claw", 8)
