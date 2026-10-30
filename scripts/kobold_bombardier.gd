class_name KoboldBombardier
extends Boss
## Bombardier Kaszlak - herszt koboldów z Pól Zbożowych, gruby kobold z workiem bomb na plecach, siedzi
## na barykadzie ze skrzyń prochu. Każda bomba pokazuje czerwone koło tam, gdzie spadnie. Ataki:
## - Grad bomb: kilka bomb naraz wokół gracza (jedna dokładnie pod nim),
## - Beczka prochu: ciężka beczka o ogromnym promieniu wybuchu i długim locie - trzeba uciec daleko,
## - Dywan: rząd bomb od bombardiera przez gracza, wybuchających jedna po drugiej,
## - Odskok: gdy gracz podejdzie za blisko, bombardier odskakuje w tył, zostawiając za sobą bomby zapalające,
## - Gwizd: przywołuje kilku koboldów z łanów (gdy ma mniej niż połowę zdrowia).
## Poniżej połowy zdrowia jego bomby są zapalające - po wybuchu zostaje płonąca plama.

@export var bomb_damage := 30
@export var barrel_damage := 60
@export var bomb_radius := 30.0
@export var barrel_radius := 72.0

const KOBOLD_SCENE := "res://scenes/kobold.tscn"
const VOLLEY_BOMBS := 5
const CARPET_BOMBS := 7
const LEAP_TIME := 0.5
const LEAP_DISTANCE := 110.0
const CALL_COOLDOWN := 16.0
const MAX_CALLED := 6

var _throws_left := 0
var _throw_timer := 0.0
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _call_cooldown := 4.0
var _called: Array = []


func _ready() -> void:
	super()
	map_color = Color(1.0, 0.45, 0.2)
	quest_kind = "kobold"


func aggro() -> void:
	var calm := state != State.CHASE
	super()
	if calm and state == State.CHASE:
		Sfx.play_at("birdman_screech", global_position, -2.0)


func _enraged() -> bool:
	return health < max_health * 0.5


func _process_fight(delta: float) -> void:
	_call_cooldown -= delta
	super(delta)
	# trzyma dystans - podchodzi tylko na odległość rzutu
	if _attack == "" and state == State.CHASE and _player_alive():
		var distance := global_position.distance_to(_player.global_position)
		if distance < 120.0:
			velocity = _retreat_velocity() * speed * 0.7
		elif distance < 200.0:
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
	_called = _called.filter(func(k) -> bool: return is_instance_valid(k) and k.state != State.DEAD)
	if distance < 60.0:
		_leap_from = global_position
		var away := -to_player.normalized()
		_leap_to = global_position + away * LEAP_DISTANCE
		# nie wyskakuje poza swoje leże
		if _leap_to.distance_to(home) > leash_radius * 0.6:
			_leap_to = home + (_leap_to - home).limit_length(leash_radius * 0.6)
		_start_attack("leap", 0.35)
		_wind_up(0.35)
	elif _enraged() and _call_cooldown <= 0.0 and _called.size() < MAX_CALLED:
		_start_attack("call", 0.8)
		_wind_up(0.8, Vector2(0.92, 1.1))
	elif distance < 340.0:
		var roll := randf()
		if roll < 0.4:
			_start_attack("volley", 0.6)
		elif roll < 0.7:
			_start_attack("carpet", 0.7)
		else:
			_start_attack("barrel", 0.9)
		_wind_up(_stage_timer)
	else:
		return false
	return true


func _update_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	match [_attack, _attack_stage]:
		["volley", "telegraph"], ["carpet", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_throws_left = VOLLEY_BOMBS if _attack == "volley" else CARPET_BOMBS
				_throw_timer = 0.0
				_set_stage("act", 2.0)
		["volley", "act"]:
			_throw_timer -= delta
			if _throw_timer <= 0.0 and _throws_left > 0:
				_throw_timer = 0.12
				var spot := _player.global_position if _throws_left == VOLLEY_BOMBS \
						else _player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 90.0)
				_throw(spot, bomb_damage, bomb_radius, randf_range(0.8, 1.0))
				_throws_left -= 1
			if _throws_left == 0:
				_set_stage("recover", 0.6)
		["carpet", "act"]:
			_throw_timer -= delta
			if _throw_timer <= 0.0 and _throws_left > 0:
				_throw_timer = 0.08
				var k := CARPET_BOMBS - _throws_left
				var dir := global_position.direction_to(_player.global_position)
				var reach := global_position.distance_to(_player.global_position) + 60.0
				var spot := global_position + dir * (40.0 + reach * k / float(CARPET_BOMBS - 1))
				# bomby dalej lecą dłużej - wybuchają jedna po drugiej od bombardiera
				_throw(spot, bomb_damage, bomb_radius * 0.9, 0.6 + 0.12 * k)
				_throws_left -= 1
			if _throws_left == 0:
				_set_stage("recover", 0.8)
		["barrel", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap(Vector2(0.8, 1.25))
				var bomb := _throw(_player.global_position, barrel_damage, barrel_radius, 1.4)
				bomb.style = "barrel"
				bomb.fuse = 0.5
				bomb.height = 70.0
				_set_stage("recover", 1.0)
		["leap", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				$CollisionShape2D.set_deferred("disabled", true)
				for i in 3:
					var bomb := _throw(_leap_from + Vector2.from_angle(TAU * i / 3.0) * 26.0, bomb_damage, bomb_radius, 0.5 + i * 0.1)
					bomb.style = "fire"
				_set_stage("act", LEAP_TIME)
		["leap", "act"]:
			var t := clampf(1.0 - _stage_timer / LEAP_TIME, 0.0, 1.0)
			global_position = _leap_from.lerp(_leap_to, t)
			sprite.position.y = -sin(t * PI) * 30.0
			if int(t * 10) % 2 == 0:
				_afterimage(Color(1.0, 0.6, 0.3, 0.45))
			if _stage_timer <= 0.0:
				sprite.position.y = 0.0
				$CollisionShape2D.set_deferred("disabled", false)
				_debris(global_position, 10, 120.0)
				_shake_camera(4.0)
				_set_stage("recover", 0.5)
		["call", "telegraph"]:
			if _stage_timer <= 0.0:
				_snap()
				_call_cooldown = CALL_COOLDOWN
				Sfx.play_at("eagle_cry", global_position, -2.0)
				_call_kobolds()
				_set_stage("recover", 0.6)
		[_, "recover"]:
			if _stage_timer <= 0.0:
				_end_attack()


func _throw(spot: Vector2, amount: int, radius: float, flight: float) -> KoboldBomb:
	var bomb := KoboldBomb.new()
	bomb.position = global_position + Vector2(0, -hurt_height - 6)
	bomb.target = spot
	bomb.damage = amount
	bomb.radius = radius
	bomb.flight = flight
	bomb.height = 55.0
	if _enraged():
		bomb.style = "fire"
	get_parent().add_child(bomb)
	Sfx.play_at("swing", global_position, -4.0)
	return bomb


func _call_kobolds() -> void:
	var scene: PackedScene = load(KOBOLD_SCENE)
	for i in 3:
		var kobold: Goblin = scene.instantiate()
		kobold.level = level - 2
		kobold.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 100.0)
		get_parent().add_child(kobold)
		kobold.appear()
		kobold.aggro()
		_called.append(kobold)


func _cancel_attack() -> void:
	super()
	_throws_left = 0
	$CollisionShape2D.set_deferred("disabled", false)


## Klatki: 0-3 chód, 4 spoczynek, 5 zamach do rzutu, 6 rzut, 7 skok.
func _animate(delta: float) -> void:
	if _attack == "leap":
		sprite.frame = 7 if _attack_stage == "act" else 5
	elif _attack != "":
		sprite.frame = 5 if _attack_stage == "telegraph" else 6 if _attack_stage == "act" else 4
	elif velocity.length() > 8.0:
		_anim_time += delta * 7.0
		sprite.frame = int(_anim_time) % 4
		sprite.flip_h = velocity.x < 0.0
	else:
		sprite.frame = 4
		if state == State.CHASE and _player != null:
			_face(_player.global_position)


func _die() -> void:
	super()
	# ostatnia bomba z worka wybucha przy upadku (już nie rani gracza - tylko efekt)
	SkillEffects.shockwave(get_parent(), global_position, 60.0, Color(1.0, 0.55, 0.2))
	Sfx.play_at("explosion", global_position)


func _drop_trophies() -> void:
	_spawn_pickup("kobold_fuse", 8)
