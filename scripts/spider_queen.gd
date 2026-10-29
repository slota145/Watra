class_name SpiderQueen
extends Boss
## Królowa Pająków - olbrzymia, nabrzmiała matka leża na północnym zachodzie Prastarego Lasu,
## z czerwoną klepsydrą na odwłoku i koroną kolców. Siedzi przed ogromną pajęczyną. Ataki:
## - Sieć: stożek lepkiej sieci - rani i mocno spowalnia,
## - Wylęg: z jaj wokół gracza wybiegają pajęczaki,
## - Skok: czerwone koło pod graczem, królowa spada na nie całym ciężarem i zatruwa.

@export var web_damage := 22
@export var leap_damage := 36
@export var max_adds := 8

const WEB_RADIUS := 150.0
const WEB_ARC := 0.55
const LEAP_RADIUS := 56.0
const LEAP_TIME := 0.6
const SPIDERLING := preload("res://scenes/spiderling.tscn")

var _dir := Vector2.RIGHT
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _leap_time := 0.0
var _eggs: Array[Telegraph] = []
var _adds: Array[Node] = []


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -46)


func aggro() -> void:
	var was_calm := state != State.CHASE
	super()
	if was_calm and state == State.CHASE:
		Sfx.play_at("queen_screech", global_position)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_adds.assign(_adds.filter(func(a) -> bool: return is_instance_valid(a) and a.state != State.DEAD))
	var roll := randf()
	_dir = to_player.normalized()
	if _adds.size() < max_adds and roll < 0.28 and distance < 260.0:
		_start_attack("summon", 1.0)
		_eggs.clear()
		for i in 4:
			var egg := Telegraph.new()
			egg.shape = Telegraph.Shape.CIRCLE
			egg.radius = 12.0
			egg.duration = 1.0
			var layer := get_tree().get_first_node_in_group("floor_layer")
			(layer if layer != null else get_parent()).add_child(egg)
			egg.global_position = _player.global_position + Vector2.from_angle(TAU * i / 4.0 + randf()) * 50.0
			_eggs.append(egg)
		Sfx.play_at("queen_screech", global_position, -4.0)
	elif distance < WEB_RADIUS * 0.85 and roll < 0.65:
		_face(_player.global_position)
		_start_attack("spray", 0.75)
		var telegraph := _show_telegraph(Telegraph.Shape.CONE, global_position, _dir.angle(), 0.75)
		telegraph.radius = WEB_RADIUS
		telegraph.half_arc = WEB_ARC
	elif distance < 300.0:
		_leap_to = _player.global_position
		_face(_leap_to)
		_start_attack("leap", 0.55)
		var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _leap_to, 0.0, 0.55 + LEAP_TIME)
		telegraph.radius = LEAP_RADIUS
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	match [_attack, _attack_stage]:
		["spray", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				if _player_in_telegraph():
					_hurt_player(web_damage)
					_player.apply_slow(0.35, 3.0)
				_remove_telegraph()
				SkillEffects.cone(get_parent(), global_position, _dir.angle(), WEB_ARC, WEB_RADIUS)
				for i in 4:
					_burst(global_position + _dir.rotated(randf_range(-WEB_ARC, WEB_ARC)) * randf_range(40, WEB_RADIUS),
							Color(0.92, 0.92, 0.96), 8, 50.0)
				Sfx.play_at("spit", global_position)
				_set_stage("recover", 0.6)
		["summon", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				for egg in _eggs:
					if not is_instance_valid(egg):
						continue
					var spiderling: Node = SPIDERLING.instantiate()
					spiderling.position = egg.global_position
					spiderling.xp_reward = 5
					spiderling.silk_drop_chance = 0.1
					spiderling.venom_drop_chance = 0.0
					spiderling.leash_radius = 300.0
					get_parent().add_child(spiderling)
					spiderling.aggro()
					_adds.append(spiderling)
					egg.queue_free()
				_eggs.clear()
				Sfx.play_at("cocoon_burst", global_position)
				_set_stage("recover", 0.6)
		["leap", "telegraph"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_leap_from = global_position
				_leap_time = 0.0
				$CollisionShape2D.set_deferred("disabled", true)
				_set_stage("act", LEAP_TIME)
		["leap", "act"]:
			velocity = Vector2.ZERO
			_leap_time += delta
			var t := minf(_leap_time / LEAP_TIME, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = -sin(t * PI) * 40.0
			if t >= 1.0:
				sprite.position.y = 0.0
				$CollisionShape2D.set_deferred("disabled", false)
				if _player_in_telegraph():
					_hurt_player(leap_damage, 220.0)
					_player.apply_poison(10.0, 4.0)
				_remove_telegraph()
				_shake_camera(7.0)
				_burst(global_position, Color(0.3, 0.25, 0.2), 24, 140.0)
				Sfx.play_at("hit_heavy", global_position)
				_set_stage("recover", 0.8)
		[_, "recover"]:
			velocity = Vector2.ZERO
			if _stage_timer <= 0.0:
				_end_attack()


func _cancel_attack() -> void:
	super()
	$CollisionShape2D.set_deferred("disabled", false)
	for egg in _eggs:
		if is_instance_valid(egg):
			egg.queue_free()
	_eggs.clear()


## Klatki: 0-3 chód, 4 spoczynek, 5 sieć, 6 wylęg, 7 skok.
func _animate(delta: float) -> void:
	match _attack:
		"spray":
			sprite.frame = 5
		"summon":
			sprite.frame = 6
		"leap":
			sprite.frame = 7 if _attack_stage == "act" else 4
		_:
			if velocity.length() > 8.0:
				_anim_time += delta * 8.0
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
	Sfx.play_at("queen_screech", global_position, 3.0)


func _drop_trophies() -> void:
	_spawn_pickup("spider_silk", 10)
	_spawn_pickup("spider_venom", 4)
