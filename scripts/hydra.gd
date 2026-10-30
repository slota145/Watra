class_name Hydra
extends Boss
## Hydra - pięciogłowa bestia z bagna na zachodnim skraju Rozlewisk. Najsilniejszy boss świata (poziom 46):
## śmiałek o zbyt niskim poziomie dostaje ostrzeżenie, zanim podejdzie (World._process_warnings).
## Nie rusza się z bagna - walczy głowami. Ataki (każdy zapowiada czerwona poświata):
## - Kąsanie: trzy głowy naraz kąsają w trzech pasach w stronę gracza,
## - Deszcz jadu: głowy plują kulami kwasu, które zostawiają trujące kałuże,
## - Uderzenie fali: cielsko wali w bagno - fala wokół Hydry odrzuca i rani (kara za stanie tuż przy niej),
## - Zionięcie: stożek trującego oddechu przed nią,
## - Odrastanie: przy 75%, 50% i 25% zdrowia ryczy, odzyskuje trochę zdrowia, atakuje coraz szybciej
##   i z bagna wypełzają topielce.

@export var bite_damage := 60
@export var venom_damage := 40
@export var wave_damage := 55
@export var breath_damage := 45

const BITE_LENGTH := 160.0
const BITE_WIDTH := 26.0
const BITE_SPREAD := 0.38
const WAVE_RADIUS := 115.0
const BREATH_RADIUS := 175.0
const BREATH_ARC := 0.55
const REGROW_HEAL := 0.04
const DROWNER_SCENE := "res://scenes/drowner.tscn"
const VENOM := Color(0.55, 0.95, 0.35)

var _bites: Array[Telegraph] = []
var _venom_left := 0
var _venom_timer := 0.0
var _dir := Vector2.RIGHT
var _thresholds := [0.75, 0.5, 0.25]


func _ready() -> void:
	super()
	map_color = Color(0.35, 0.8, 0.45)
	quest_kind = "hydra"
	hurt_radius = 22.0


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("bies_roar", global_position, 2.0)


func _process_fight(delta: float) -> void:
	super(delta)
	# Hydra nie wychodzi z bagna
	velocity = Vector2.ZERO


func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	super(amount, from_position, knockback)
	if state != State.DEAD and not _thresholds.is_empty() and health < max_health * _thresholds[0] and _attack == "":
		_thresholds.pop_front()
		_start_attack("regrow", 1.0)
		_wind_up(1.0, Vector2(0.9, 1.15))


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_dir = to_player.normalized()
	_face(_player.global_position)
	if distance > 360.0:
		return false
	if distance < WAVE_RADIUS * 0.8 and randf() < 0.45:
		_start_attack("wave", 1.0)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 1.0)
		circle.radius = WAVE_RADIUS
		_wind_up(1.0)
	elif distance < BITE_LENGTH and randf() < 0.55:
		_start_attack("bite", 0.85)
		_wind_up(0.85, Vector2(0.88, 1.15))
		for k in 3:
			var line := Telegraph.new()
			line.shape = Telegraph.Shape.LINE
			line.length = BITE_LENGTH
			line.width = BITE_WIDTH
			line.duration = 0.85
			var layer := get_tree().get_first_node_in_group("floor_layer")
			(layer if layer != null else get_parent()).add_child(line)
			line.global_position = global_position
			line.rotation = _dir.angle() + (k - 1) * BITE_SPREAD
			_bites.append(line)
		Sfx.play_at("telegraph", global_position)
	elif distance < BREATH_RADIUS and randf() < 0.5:
		_start_attack("breath", 0.9)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.9)
		cone.radius = BREATH_RADIUS
		cone.half_arc = BREATH_ARC
		_wind_up(0.9)
	else:
		_start_attack("venom", 0.6)
		_wind_up(0.6)
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["bite", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(0.85, 1.2))
				for line in _bites:
					if is_instance_valid(line):
						if _player_alive() and line.contains(_player.global_position):
							_hurt_player(bite_damage, 200.0)
						SkillEffects.spark(get_parent(), line.global_position + Vector2.from_angle(line.rotation) * BITE_LENGTH * 0.8, VENOM, 6)
				_clear_bites()
				Sfx.play_at("claw", global_position)
				_shake_camera(4.0)
				_set_stage("recover", 0.6)
		["wave", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.25, 0.8))
				if _player_in_telegraph():
					_hurt_player(wave_damage, 340.0)
				_remove_telegraph()
				for side in [0.0, PI]:
					SkillEffects.tide(get_parent(), global_position, side, 1.4, WAVE_RADIUS)
				SkillEffects.shockwave(get_parent(), global_position, WAVE_RADIUS, Color(0.5, 0.8, 0.7))
				_burst(global_position, Color(0.5, 0.75, 0.6), 30, 180.0)
				Sfx.play_at("boss_splash", global_position)
				_shake_camera(7.0)
				_set_stage("recover", 0.8)
		["breath", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				if _player_in_telegraph():
					_hurt_player(breath_damage)
					_player.apply_poison(maxi(1, breath_damage / 5), 4.0)
				_remove_telegraph()
				var layer := get_tree().get_first_node_in_group("floor_layer")
				for i in 5:
					var patch := BurningPatch.new()
					patch.style = "poison"
					patch.radius = 26.0
					patch.damage = maxi(1, breath_damage / 5)
					(layer if layer != null else get_parent()).add_child(patch)
					patch.global_position = global_position + _dir.rotated(randf_range(-BREATH_ARC, BREATH_ARC) * 0.8) * randf_range(50.0, BREATH_RADIUS - 20.0)
				_burst(global_position + _dir * 30.0 + Vector2(0, -30), VENOM, 36, 200.0)
				Sfx.play_at("spit", global_position, 4.0)
				_set_stage("recover", 0.7)
		["venom", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_venom_left = 6 if health > max_health * 0.5 else 9
				_venom_timer = 0.0
				_set_stage("act", 3.0)
		["venom", "act"]:
			_venom_timer -= delta
			if _venom_timer <= 0.0 and _venom_left > 0:
				_venom_timer = 0.12
				_venom_left -= 1
				var glob := KoboldBomb.new()
				glob.style = "acid"
				glob.position = global_position + Vector2(randf_range(-30, 30), -hurt_height - 30)
				glob.target = _player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 80.0)
				glob.damage = venom_damage
				glob.radius = 28.0
				glob.flight = randf_range(0.8, 1.2)
				glob.height = 80.0
				get_parent().add_child(glob)
				Sfx.play_at("spit", global_position, -2.0)
			if _venom_left == 0:
				_set_stage("recover", 0.6)
		["regrow", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				health = mini(max_health, health + roundi(max_health * REGROW_HEAL))
				attack_interval *= 0.85
				DamageNumber.spawn_text(get_parent(), hurt_center() + Vector2(0, -20), "Głowy odrastają!", VENOM, 10)
				Sfx.play_at("bies_roar", global_position, 3.0)
				SkillEffects.shockwave(get_parent(), global_position, 140.0, VENOM)
				_shake_camera(6.0)
				var scene: PackedScene = load(DROWNER_SCENE)
				for i in 3:
					var drowner: Goblin = scene.instantiate()
					drowner.level = level - 6
					drowner.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 120.0)
					get_parent().add_child(drowner)
					drowner.appear()
					drowner.aggro()
				_set_stage("recover", 0.8)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


func _clear_bites() -> void:
	for line in _bites:
		if is_instance_valid(line):
			line.queue_free()
	_bites.clear()


func _cancel_attack() -> void:
	super()
	_clear_bites()


## Klatki: 0-3 kołysanie głów, 4 spoczynek, 5 zamach (głowy w tył), 6 kąsanie, 7 ryk.
func _animate(delta: float) -> void:
	match _attack:
		"bite", "wave":
			sprite.frame = 5 if _attack_stage == "telegraph" else 6
			return
		"breath", "venom", "regrow":
			sprite.frame = 5 if _attack_stage == "telegraph" else 7
			return
	_anim_time += delta * 4.0
	sprite.frame = int(_anim_time) % 4
	if state == State.CHASE and _player != null:
		_face(_player.global_position)


func _die() -> void:
	_clear_bites()
	super()
	Sfx.play_at("boss_splash", global_position, 4.0)


func _drop_trophies() -> void:
	_spawn_pickup("hydra_scale", 6)
