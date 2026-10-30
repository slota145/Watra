class_name Necromancer
extends Boss
## Mortan, Pan Kości - szkielet nekromanty w koronie z kości, przed swoim mauzoleum w północno-zachodniej
## części Leśnego Cmentarza. Walczy cudzymi rękami: przywołuje całe zastępy szkieletów. Ataki:
## - Wezwanie umarłych: z ziemi wokół niego wypełza krąg szkieletów (poniżej połowy zdrowia także rycerze),
## - Kościane włócznie: wachlarz kościanych pocisków w stronę gracza,
## - Wysysanie duszy: zielony promień w pas przed nim - rani i leczy nekromantę,
## - Groby: pod graczem i wokół niego otwierają się zielone kręgi, z których wystrzelają kościane kolce,
## - Mgnienie: gdy gracz podejdzie za blisko, znika w kłębie dymu i pojawia się kawałek dalej.

@export var bone_damage := 30
@export var beam_damage := 55
@export var spike_damage := 45

const SKELETON_SCENES := ["res://scenes/skeleton.tscn", "res://scenes/skeleton.tscn", "res://scenes/skeleton_archer.tscn"]
const KNIGHT_SCENE := "res://scenes/skeleton_knight.tscn"
const MAX_RAISED := 16
const BEAM_LENGTH := 270.0
const BEAM_WIDTH := 26.0
const BEAM_HEAL := 0.04
const SPIKE_RADIUS := 26.0
const GREEN := Color(0.45, 1.0, 0.55)

var _raised: Array = []
var _raise_cooldown := 0.0
var _beam_dir := Vector2.RIGHT
var _volley := 0
var _volley_timer := 0.0
var _blink_cooldown := 0.0


func _ready() -> void:
	super()
	map_color = Skeleton.BONE_COLOR
	quest_kind = "skeleton"


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("wodnik_laugh", global_position, -2.0)


func _process_fight(delta: float) -> void:
	_raise_cooldown -= delta
	_blink_cooldown -= delta
	super(delta)
	# trzyma dystans - niech walczą jego szkielety
	if _attack == "" and state == State.CHASE and _player_alive():
		var distance := global_position.distance_to(_player.global_position)
		if distance < 110.0:
			velocity = _retreat_velocity() * speed * 0.8
		elif distance < 190.0:
			velocity = Vector2.ZERO


## Odwrót od gracza, ale nie poza leże - przy jego skraju ucieka bokiem (dookoła środka leża).
func _retreat_velocity() -> Vector2:
	var away := (global_position - _player.global_position).normalized()
	if (global_position + away * 24.0).distance_to(home) < leash_radius * 0.45:
		return away
	var side := away.orthogonal()
	if (global_position + side * 24.0).distance_to(home) > (global_position - side * 24.0).distance_to(home):
		side = -side
	return side


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_face(_player.global_position)
	_raised = _raised.filter(func(s) -> bool: return is_instance_valid(s) and s.state != State.DEAD)
	if distance < 55.0 and _blink_cooldown <= 0.0:
		_start_attack("blink", 0.3)
		_wind_up(0.3)
	elif _raise_cooldown <= 0.0 and _raised.size() < MAX_RAISED:
		_start_attack("raise", 1.1)
		_wind_up(1.1, Vector2(0.9, 1.15))
		Sfx.play_at("summon", global_position, -4.0)
	elif distance > 330.0:
		return false
	else:
		var roll := randf()
		if roll < 0.35:
			_start_attack("volley", 0.6)
		elif roll < 0.65:
			_beam_dir = to_player.normalized()
			_start_attack("beam", 1.0)
			var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position + Vector2(0, -6), _beam_dir.angle(), 1.0)
			telegraph.length = BEAM_LENGTH
			telegraph.width = BEAM_WIDTH
		else:
			_start_attack("graves", 0.5)
		_wind_up(_stage_timer)
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["raise", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_raise_dead()
				_raise_cooldown = 9.0 if health > max_health * 0.5 else 6.5
				_set_stage("recover", 0.6)
		["volley", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_volley = 3 if health > max_health * 0.5 else 4
				_volley_timer = 0.0
				_set_stage("act", 2.0)
		["volley", "act"]:
			_volley_timer -= delta
			if _volley_timer <= 0.0 and _volley > 0:
				_volley_timer = 0.3
				_volley -= 1
				var aim := global_position.direction_to(_player.body_center()).angle()
				for k in 5:
					var spear := EnemySpit.new()
					spear.style = "bone"
					spear.position = global_position + Vector2(0, -hurt_height)
					spear.direction = Vector2.from_angle(aim + (k - 2) * 0.2)
					spear.damage = bone_damage
					get_parent().add_child(spear)
				Sfx.play_at("whirl", global_position, -4.0)
			if _volley == 0:
				_set_stage("recover", 0.5)
		["beam", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				var start := global_position + Vector2(0, -6)
				_beam_fx(start, start + _beam_dir * BEAM_LENGTH)
				if _player_in_telegraph():
					_hurt_player(beam_damage)
					health = mini(max_health, health + roundi(max_health * BEAM_HEAL))
					DamageNumber.spawn_text(get_parent(), hurt_center() + Vector2(0, -12), "+%d" % roundi(max_health * BEAM_HEAL), GREEN, 9)
				_remove_telegraph()
				Sfx.play_at("wisp_burst", global_position)
				_set_stage("recover", 0.6)
		["graves", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				var spots := [_player.global_position]
				for k in (4 if health > max_health * 0.5 else 7):
					spots.append(_player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 110.0))
				for spot: Vector2 in spots:
					_grave_spike(spot)
				_set_stage("recover", 0.9)
		["blink", "telegraph"]:
			if _stage_timer <= 0.0:
				_blink()
				_set_stage("recover", 0.4)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


func _raise_dead() -> void:
	var count := 6 if health > max_health * 0.5 else 9
	var offset := randf() * TAU
	for i in count:
		var path: String = KNIGHT_SCENE if health < max_health * 0.5 and i % 4 == 0 else SKELETON_SCENES[i % SKELETON_SCENES.size()]
		var skeleton: Goblin = load(path).instantiate()
		skeleton.level = level - 4
		skeleton.position = global_position + Vector2.from_angle(offset + TAU * i / count) * randf_range(70.0, 110.0)
		get_parent().add_child(skeleton)
		skeleton.rise()
		_raised.append(skeleton)
	SkillEffects.shockwave(get_parent(), global_position, 120.0, GREEN)


## Zielony krąg grobu, z którego po chwili wystrzelają kościane kolce.
func _grave_spike(spot: Vector2) -> void:
	var telegraph := Telegraph.new()
	telegraph.radius = SPIKE_RADIUS
	telegraph.duration = 0.9
	telegraph.modulate = Color(0.5, 1.0, 0.6)
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = spot
	get_tree().create_timer(0.9, false).timeout.connect(func() -> void:
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		if state == State.DEAD:
			return
		_debris(spot, 10, 150.0, Skeleton.BONE_COLOR)
		SkillEffects.spark(get_parent(), spot + Vector2(0, -6), GREEN, 8)
		if _player_alive() and _player.global_position.distance_to(spot) <= SPIKE_RADIUS:
			_player.take_damage(spike_damage, spot))


func _blink() -> void:
	_blink_cooldown = 5.0
	_smoke(global_position)
	var away := (global_position - _player.global_position).normalized()
	var target := global_position + away.rotated(randf_range(-0.8, 0.8)) * 170.0
	if target.distance_to(home) > leash_radius * 0.6:
		target = home + Vector2.from_angle(randf() * TAU) * 80.0
	global_position = target
	reset_physics_interpolation()
	_smoke(global_position)
	Sfx.play_at("magic", global_position)


func _smoke(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.global_position = at + Vector2(0, -12)
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.7
	p.spread = 180.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, -30)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(0.35, 0.2, 0.45, 0.8)
	p.emitting = true
	get_parent().add_child(p)
	p.finished.connect(p.queue_free)


func _beam_fx(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 10.0
	line.default_color = Color(0.5, 1.0, 0.55, 0.8)
	line.z_index = 5
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	line.material = additive
	get_parent().add_child(line)
	var tween := line.create_tween().set_parallel()
	tween.tween_property(line, "width", 1.0, 0.35)
	tween.tween_property(line, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(line.queue_free)


func _die() -> void:
	super()
	# z nekromantą rozsypują się jego szkielety
	for skeleton in _raised:
		if is_instance_valid(skeleton) and skeleton.state != State.DEAD:
			skeleton.take_damage(999999, global_position, 0.0)


## Klatki: 0-3 chód (unoszenie się), 4 spoczynek, 5 wezwanie (ręce w górze), 6 zaklęcie, 7 mgnienie.
func _animate(delta: float) -> void:
	match _attack:
		"raise":
			sprite.frame = 5 if _attack_stage == "telegraph" else 4
			return
		"blink":
			sprite.frame = 7
			return
		"volley", "beam", "graves":
			sprite.frame = 5 if _attack_stage == "telegraph" else 6 if _attack_stage == "act" or _stage_timer > 0.3 else 4
			return
	if velocity.length() > 8.0:
		_anim_time += delta * 6.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("bone_dust", 8)
