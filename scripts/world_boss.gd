class_name WorldBoss
extends Boss
## World boss - wielki potwór z wydarzenia w świecie (WorldEvents, EventSite "world_boss"), ogłaszany minutę
## wcześniej, z gromadą 10-15 podróżników. Ogromne zdrowie (EventSite.WORLD_BOSS_HEALTH) i trzy fazy: przy 66% i 33%
## zdrowia nowe ataki i krótsze przerwy (komunikat na ekranie). Dwa rodzaje (`kind`):
## - "zmij" - Żmij Gorynycz, trójgłowy smok (wyższe krainy): Zionięcie (stożek ognia, zostawia płonącą ziemię),
##   Trzy Głowy (trzy kule ognia spadają na gracza i obok), Uderzenie (skok i lądowanie z wstrząsem); faza 2 -
##   zionięcie w dwie strony, faza 3 - ognisty krąg wokół smoka,
## - "wij" - Wij, olbrzym o powiekach do ziemi (niższe krainy): Wzrok Wija (unosi powieki - długi stożek, rani
##   i spowalnia), Szpony (korzenie wokół niego chwytają), Wezwanie upiorów (potwory krainy - przez EventSite);
##   faza 3 - wzrok dwa razy z rzędu.
## Animacja: Żmij ciągle macha skrzydłami (8 klatek), Wij unosi powieki przy Wzroku (klatki 0-8).

@export var kind := "zmij"
@export var breath_damage := 90
@export var fireball_damage := 70
@export var slam_damage := 80
@export var gaze_damage := 110
@export var claw_damage := 60

const BREATH_RANGE := 210.0
const BREATH_ARC := deg_to_rad(35.0)
const FIREBALL_RADIUS := 48.0
const SLAM_RADIUS := 95.0
const SLAM_TIME := 0.7
const GAZE_RANGE := 300.0
const GAZE_ARC := deg_to_rad(22.0)
const CLAW_RADIUS := 85.0
const FIRE := Color(1.0, 0.55, 0.2)
const GAZE := Color(1.0, 0.9, 0.35)
const PHASES := [0.66, 0.33]

## Faza walki 1-3 (EventSite pokazuje komunikat przy zmianie - sygnał phase_changed).
signal phase_changed(phase: int)
var phase := 1
var site: Node
var _slam_from := Vector2.ZERO
var _slam_to := Vector2.ZERO
var _aim := Vector2.DOWN
var _second := false
var _spots: Array[Vector2] = []


func _ready() -> void:
	super()
	add_to_group("world_bosses")
	hurt_radius = 34.0
	map_color = FIRE if kind == "zmij" else GAZE
	quest_kind = "world_boss"
	set_meta("world_boss", true)


## Po powrocie do miejsca (np. gdy gracz padł) world boss nie leczy ran - podróżnicy walczą dalej, gracz może wrócić.
func _physics_process(delta: float) -> void:
	var before := health
	super(delta)
	if health > before and state == State.IDLE:
		health = before


func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	super(amount, from_position, knockback)
	if state == State.DEAD:
		return
	for i in PHASES.size():
		if phase == i + 1 and health < max_health * PHASES[i]:
			phase = i + 2
			attack_interval *= 0.75
			speed *= 1.1
			Sfx.play_at("bear_roar" if kind == "wij" else "storm_eagle_screech", global_position)
			_shake_camera(8.0)
			phase_changed.emit(phase)


func _choose_attack(to_player: Vector2) -> bool:
	var distance := to_player.length()
	_face(_player.global_position)
	_aim = to_player.normalized()
	if kind == "zmij":
		if distance < BREATH_RANGE and randf() < 0.45:
			_start_attack("breath", 1.0)
			var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 1.0)
			cone.radius = BREATH_RANGE
			cone.half_arc = BREATH_ARC
			_wind_up(1.0)
		elif distance < 360.0 and randf() < 0.5:
			_start_attack("fireballs", 1.1)
			_spots = [_player.global_position]
			for i in 2 + phase:
				_spots.append(_player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 110.0))
			for spot: Vector2 in _spots:
				_marker(spot, FIREBALL_RADIUS, 1.1, FIRE)
			_wind_up(1.1, Vector2(0.9, 1.12))
		elif distance < 420.0:
			_slam_from = global_position
			_slam_to = _player.global_position
			_start_attack("slam", 0.8)
			var circle := _show_telegraph(Telegraph.Shape.CIRCLE, _slam_to, 0.0, 0.8 + SLAM_TIME)
			circle.radius = SLAM_RADIUS
			_wind_up(0.8)
		else:
			return false
		return true
	# Wij
	if distance < GAZE_RANGE and randf() < 0.5:
		_start_attack("gaze", 1.3)
		var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 1.3)
		cone.radius = GAZE_RANGE
		cone.half_arc = GAZE_ARC
		cone.modulate = Color(1.0, 0.95, 0.5)
		Sfx.play_at("leshy_whisper", global_position)
	elif distance < CLAW_RADIUS * 1.2 and randf() < 0.6:
		_start_attack("claws", 0.8)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.8)
		circle.radius = CLAW_RADIUS
		_wind_up(0.8)
	elif randf() < 0.35:
		_start_attack("summon", 0.9)
		_wind_up(0.9, Vector2(0.92, 1.1))
		Sfx.play_at("ghost_wail", global_position)
	elif distance > 60.0:
		return false
	else:
		_start_attack("claws", 0.8)
		var circle := _show_telegraph(Telegraph.Shape.CIRCLE, global_position, 0.0, 0.8)
		circle.radius = CLAW_RADIUS
		_wind_up(0.8)
	return true


func _update_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["breath", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				Sfx.play_at("fireball_full", global_position)
				if _player_in_telegraph():
					_hurt_player(breath_damage, 120.0)
				_remove_telegraph()
				for i in 6:
					var at := global_position + _aim.rotated(randf_range(-BREATH_ARC, BREATH_ARC)) * randf_range(40.0, BREATH_RANGE)
					_fire_patch(at)
				SkillEffects.spark(get_parent(), global_position + _aim * 60.0, FIRE, 24)
				# faza 2+: zionięcie także za siebie
				if phase >= 2 and not _second:
					_second = true
					_aim = -_aim
					_hit_player = false
					var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 0.7)
					cone.radius = BREATH_RANGE
					cone.half_arc = BREATH_ARC
					_set_stage("telegraph", 0.7)
					return
				_second = false
				_set_stage("recover", 0.8)
		["fireballs", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				for spot: Vector2 in _spots:
					SkillEffects.shockwave(get_parent(), spot, FIREBALL_RADIUS, FIRE)
					_burst(spot, FIRE, 12, 120.0)
					if _player_alive() and _player.global_position.distance_to(spot) <= FIREBALL_RADIUS:
						_hurt_player(fireball_damage, 160.0)
				Sfx.play_at("explosion", _spots[0])
				_shake_camera(4.0)
				_set_stage("recover", 0.7)
		["slam", "telegraph"]:
			if _stage_timer <= 0.0:
				_set_stage("act", SLAM_TIME)
				Sfx.play_at("wing_gust", global_position)
		["slam", "act"]:
			var t := clampf(1.0 - _stage_timer / SLAM_TIME, 0.0, 1.0)
			global_position = _slam_from.lerp(_slam_to, t)
			sprite.position.y = -sin(t * PI) * 60.0
			if _stage_timer <= 0.0:
				sprite.position.y = 0.0
				if _player_in_telegraph():
					_hurt_player(slam_damage, 300.0)
				_remove_telegraph()
				_ground_crack(global_position, SLAM_RADIUS * 0.8)
				_debris(global_position, 18, 180.0)
				_shake_camera(9.0)
				Sfx.play_at("rock_break", global_position)
				if phase >= 3:
					for i in 8:
						_fire_patch(global_position + Vector2.from_angle(TAU * i / 8.0) * SLAM_RADIUS)
				_set_stage("recover", 0.9)
		["gaze", "telegraph"]:
			if _stage_timer <= 0.0:
				Sfx.play_at("thunder", global_position)
				if _player_in_telegraph():
					_hurt_player(gaze_damage, 80.0)
					_player.apply_slow(0.45, 3.0)
				for i in 10:
					SkillEffects.spark(get_parent(), global_position + _aim * (30.0 + i * 26.0), GAZE, 4)
				_shake_camera(5.0)
				if phase >= 3 and not _second:
					_second = true
					_hit_player = false
					_aim = (_player.global_position - global_position).normalized()
					var cone := _show_telegraph(Telegraph.Shape.CONE, global_position, _aim.angle(), 0.8)
					cone.radius = GAZE_RANGE
					cone.half_arc = GAZE_ARC
					cone.modulate = Color(1.0, 0.95, 0.5)
					_set_stage("telegraph", 0.8)
					return
				_second = false
				_remove_telegraph()
				_set_stage("recover", 1.0)
		["claws", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(1.2, 0.85))
				if _player_in_telegraph():
					_hurt_player(claw_damage, 200.0)
					_player.apply_slow(0.1, 1.2)
				_remove_telegraph()
				_ground_crack(global_position, CLAW_RADIUS * 0.8)
				_debris(global_position, 14, 150.0, Color(0.35, 0.25, 0.15))
				Sfx.play_at("roots_burst", global_position)
				_set_stage("recover", 0.6)
		["summon", "telegraph"]:
			if _stage_timer <= 0.0:
				if site != null and is_instance_valid(site):
					site.summon_minions(global_position, 3 + phase)
				_set_stage("recover", 0.6)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


## Płonąca ziemia po zionięciu (BurningPatch).
func _fire_patch(at: Vector2) -> void:
	var patch := BurningPatch.new()
	patch.radius = 20.0
	patch.damage = maxi(1, roundi(breath_damage * 0.12))
	patch.life = 4.0
	patch.position = at
	get_parent().add_child(patch)


## Znacznik miejsca uderzenia (kula ognia) - czerwony krąg, znika sam.
func _marker(spot: Vector2, radius: float, time: float, color: Color) -> void:
	var telegraph := Telegraph.new()
	telegraph.radius = radius
	telegraph.duration = time
	telegraph.modulate = color
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = spot
	get_tree().create_timer(time + 0.1, false).timeout.connect(func() -> void:
		if is_instance_valid(telegraph):
			telegraph.queue_free())


func _cancel_attack() -> void:
	super()
	_second = false
	if sprite != null:
		sprite.position = Vector2.ZERO


## Żmij: skrzydła cały czas (szybciej w ataku); Wij: klatka 0, a przy Wzroku unosi powieki (klatki 1-8).
func _animate(delta: float) -> void:
	if kind == "zmij":
		_anim_time += delta * (12.0 if _attack != "" else 7.0)
		sprite.frame = int(_anim_time) % sprite.hframes
	elif _attack == "gaze":
		var total := 1.3 if not _second else 0.8
		var t := clampf(1.0 - _stage_timer / total, 0.0, 1.0) if _attack_stage == "telegraph" else 1.0
		sprite.frame = mini(sprite.hframes - 1, int(t * (sprite.hframes - 1)))
	else:
		sprite.frame = 0
	if _attack == "" and velocity.length() > 5.0:
		sprite.flip_h = velocity.x < 0.0
	elif _attack == "" and state == State.CHASE and _player != null:
		_face(_player.global_position)


func _drop_trophies() -> void:
	_spawn_pickup(WorldEvents.MARK, 3)
	_spawn_pickup(Essences.HEART, 1)
