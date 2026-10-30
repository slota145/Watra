class_name GiantWorm
extends Boss
## Pożeracz Pól - olbrzymi czerw w kraterze popękanej ziemi na południowym zachodzie Pól Zbożowych.
## Nie chodzi - przekopuje się. Ataki (każdy zapowiada czerwona poświata):
## - Podkop: zanurza się (pod ziemią nie da się go zranić), sunie pod gracza wielkim kopcem i wystrzela
##   z ziemi w szerokim kole,
## - Uderzenie: wspina się i wali całym cielskiem w pas przed sobą,
## - Kwas: pluje kilkoma kulami kwasu, które zostawiają trujące kałuże,
## - Wstrząs (poniżej połowy zdrowia): z ziemi wokół niego jeden po drugim wystrzelają kolce ziemi,
## - Wylęg: z krateru wypełzają młode czerwie.

@export var erupt_damage := 55
@export var slam_damage := 50
@export var acid_damage := 26
@export var quake_damage := 35
@export var erupt_radius := 58.0

const WORM_SCENE := "res://scenes/field_worm.tscn"
const MOUND := preload("res://assets/fields/mound.png")
const DIVE_TIME := 0.7
const AIM_TIME := 0.9
const SLAM_LENGTH := 170.0
const SLAM_WIDTH := 44.0
const QUAKE_RINGS := 3
const QUAKE_SPOTS := 7
const MAX_BROOD := 5

var _underground := false
var _mound: Sprite2D
var _aim_at := Vector2.ZERO
var _slam_dir := Vector2.RIGHT
var _spits := 0
var _spit_timer := 0.0
var _quake_ring := 0
var _quake_timer := 0.0
var _brood: Array = []
var _brood_cooldown := 10.0


func _ready() -> void:
	super()
	map_color = Color(0.85, 0.6, 0.55)
	quest_kind = "worm"
	hurt_radius = 18.0
	_mound = Sprite2D.new()
	_mound.texture = MOUND
	_mound.scale = Vector2(2.6, 2.2)
	_mound.offset = Vector2(0, -4)
	_mound.visible = false
	add_child(_mound)


func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	if _underground:
		return
	super(amount, from_position, knockback)


func stun(seconds: float) -> void:
	if not _underground:
		super(seconds)


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("tree_rumble", global_position)


func _process_fight(delta: float) -> void:
	_brood_cooldown -= delta
	super(delta)
	# czerw nie chodzi po wierzchu - przemieszcza się tylko podkopem
	if _attack == "":
		velocity = Vector2.ZERO


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_face(_player.global_position)
	_brood = _brood.filter(func(w) -> bool: return is_instance_valid(w) and w.state != State.DEAD)
	if distance > 150.0 or (distance > 60.0 and randf() < 0.3):
		_start_attack("burrow", DIVE_TIME)
		_wind_up(DIVE_TIME, Vector2(1.2, 0.7))
		Sfx.play_at("mine", global_position)
	elif health < max_health * 0.5 and randf() < 0.35:
		_start_attack("quake", 0.8)
		_wind_up(0.8)
		_quake_ring = 0
		_quake_timer = 0.0
	elif _brood_cooldown <= 0.0 and _brood.size() < MAX_BROOD and randf() < 0.4:
		_start_attack("brood", 0.9)
		_wind_up(0.9, Vector2(0.9, 1.15))
	elif randf() < 0.55:
		_slam_dir = to_player.normalized()
		_start_attack("slam", 0.95)
		_wind_up(0.95, Vector2(0.85, 1.2))
		var telegraph := _show_telegraph(Telegraph.Shape.LINE, global_position, _slam_dir.angle(), 0.95)
		telegraph.length = SLAM_LENGTH
		telegraph.width = SLAM_WIDTH
	else:
		_start_attack("acid", 0.7)
		_wind_up(0.7)
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["burrow", "telegraph"]:
			if _stage_timer <= 0.0:
				_go_under()
				_set_stage("act", 5.0)
		["burrow", "act"]:
			# sunie pod ziemią do gracza (szybciej niż gracz biegnie, ale nie w nieskończoność)
			var to_player := _player.global_position - global_position
			_mound.position.y = sin(_stage_timer * 20.0) * 0.8
			if to_player.length() < 20.0 or _stage_timer <= 0.0:
				_aim_at = _player.global_position
				var telegraph := _show_telegraph(Telegraph.Shape.CIRCLE, _aim_at, 0.0, AIM_TIME)
				telegraph.radius = erupt_radius
				_set_stage("aim", AIM_TIME)
			else:
				velocity = to_player.normalized() * speed * 2.2
				if _stage_timer < 4.0 and position.distance_to(home) > leash_radius * 0.8:
					_stage_timer = 0.0
		["burrow", "aim"]:
			global_position = global_position.move_toward(_aim_at, 200.0 * delta)
			if _stage_timer <= 0.0:
				_erupt()
				_set_stage("recover", 1.4)
		["slam", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.25, 0.8))
				if _player_in_telegraph():
					_hurt_player(slam_damage, 260.0)
				_remove_telegraph()
				_shake_camera(7.0)
				for k in 4:
					var spot := global_position + _slam_dir * SLAM_LENGTH * (k + 1) / 4.0
					_ground_crack(spot, 22.0)
					_debris(spot, 6, 110.0)
				Sfx.play_at("rock_break", global_position)
				_set_stage("recover", 1.0)
		["acid", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_spits = 4 if health > max_health * 0.5 else 6
				_spit_timer = 0.0
				_set_stage("act", 2.0)
		["acid", "act"]:
			_spit_timer -= delta
			if _spit_timer <= 0.0 and _spits > 0:
				_spit_timer = 0.15
				var spot := _player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 70.0)
				var glob := KoboldBomb.new()
				glob.style = "acid"
				glob.position = global_position + Vector2(0, -hurt_height - 10)
				glob.target = spot
				glob.damage = acid_damage
				glob.radius = 26.0
				glob.flight = randf_range(0.8, 1.1)
				glob.height = 60.0
				get_parent().add_child(glob)
				Sfx.play_at("spit", global_position, -2.0)
				_spits -= 1
			if _spits == 0:
				_set_stage("recover", 0.7)
		["quake", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_set_stage("act", 3.0)
		["quake", "act"]:
			_quake_timer -= delta
			if _quake_timer <= 0.0 and _quake_ring < QUAKE_RINGS:
				_quake_timer = 0.45
				_quake_ring += 1
				var offset := randf() * TAU
				for k in QUAKE_SPOTS:
					var spot := global_position + Vector2.from_angle(offset + TAU * k / QUAKE_SPOTS) * (50.0 * _quake_ring)
					_earth_spike(spot)
			if _quake_ring >= QUAKE_RINGS and _quake_timer <= 0.0:
				_set_stage("recover", 0.8)
		["brood", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_brood_cooldown = 14.0
				var scene: PackedScene = load(WORM_SCENE)
				for i in 3:
					var worm: Goblin = scene.instantiate()
					worm.level = level - 2
					worm.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 90.0)
					get_parent().add_child(worm)
					worm.appear()
					worm.aggro()
					_brood.append(worm)
				_burst(global_position, Color(0.45, 0.32, 0.2), 20, 120.0)
				_set_stage("recover", 0.6)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Kolec ziemi: czerwone koło, po chwili ziemia wystrzela w górę.
func _earth_spike(spot: Vector2) -> void:
	var telegraph := Telegraph.new()
	telegraph.radius = 22.0
	telegraph.duration = 0.6
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = spot
	get_tree().create_timer(0.6, false).timeout.connect(func() -> void:
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		if state == State.DEAD:
			return
		_debris(spot, 8, 140.0)
		_ground_crack(spot, 18.0, 2.0)
		if _player_alive() and _player.global_position.distance_to(spot) <= 22.0:
			_player.take_damage(quake_damage, spot))


func _go_under() -> void:
	_underground = true
	remove_from_group("enemies")
	sprite.visible = false
	_mound.visible = true
	$CollisionShape2D.set_deferred("disabled", true)
	_burst(global_position, Color(0.45, 0.32, 0.2), 24, 120.0)


func _erupt() -> void:
	global_position = _aim_at
	reset_physics_interpolation()
	_underground = false
	add_to_group("enemies")
	sprite.visible = true
	_mound.visible = false
	$CollisionShape2D.set_deferred("disabled", false)
	_snap(Vector2(0.7, 1.4))
	if _player_alive() and _player.global_position.distance_to(_aim_at) <= erupt_radius:
		_hurt_player(erupt_damage, 300.0)
	_remove_telegraph()
	_shake_camera(9.0)
	_ground_crack(_aim_at, erupt_radius, 4.0)
	_debris(_aim_at, 22, 200.0)
	_burst(_aim_at, Color(0.45, 0.32, 0.2), 30, 160.0)
	Sfx.play_at("rock_break", _aim_at, 2.0)


func _cancel_attack() -> void:
	super()
	if _underground:
		_underground = false
		add_to_group("enemies")
		sprite.visible = true
		_mound.visible = false
		$CollisionShape2D.set_deferred("disabled", false)


## Klatki: 0-3 kołysanie, 4 nisko (zanurzanie), 5 wynurzanie, 6 zamach / ryk, 7 uderzenie.
func _animate(delta: float) -> void:
	match _attack:
		"burrow":
			sprite.frame = 5 if _attack_stage == "telegraph" else 7
			return
		"slam":
			sprite.frame = 6 if _attack_stage == "telegraph" else 7
			return
		"acid", "quake", "brood":
			sprite.frame = 6 if _attack_stage == "telegraph" else 7 if _attack_stage == "act" else 5
			return
	_anim_time += delta * 4.0
	sprite.frame = int(_anim_time) % 4
	if state == State.CHASE and _player != null:
		_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup("worm_tooth", 8)
