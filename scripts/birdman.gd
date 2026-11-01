class_name Birdman
extends Goblin
## Ptakoczłek z Wietrznych Turni - dużo groźniejszy od żaboludzi. Siedzi w wiosce na palach,
## a gdy zauważy gracza, wrzeszczy i rusza z całą gromadą. Odmiany:
## - wojownik (warrior): oprócz zwykłego pchnięcia oszczepem doskakuje do gracza z rozpędu,
## - miotacz (thrower): trzyma dystans i rzuca oszczepami, które lecą prosto (da się uskoczyć),
## - szaman burzy (shaman): wskazuje laską miejsce pod graczem - po chwili uderza tam piorun.
## Zostawiają pióra burzy.

@export_enum("warrior", "thrower", "shaman") var kind := "warrior"
@export var ranged_damage := 24
@export_range(0.0, 1.0) var feather_drop_chance := 0.5

const BIRD_COLOR := Color(0.55, 0.75, 1.0)
## Doskok wojownika: odległość, z jakiej skacze, prędkość i czas odnowienia.
const LEAP_RANGE := Vector2(40.0, 120.0)
const LEAP_SPEED := 300.0
const LEAP_COOLDOWN := 3.5
## Piorun szamana: promień i czas od wskazania do uderzenia.
const BOLT_RADIUS := 26.0
const BOLT_DELAY := 0.85

var _leap_cooldown := 0.0
var _leap_time := 0.0
var _leap_dir := Vector2.ZERO
var _leap_hit := false


func _ready() -> void:
	super()
	equipment_drop_chance = 0.08
	hurt_radius = 8.0
	map_color = BIRD_COLOR
	quest_kind = "birdman"
	_leap_cooldown = randf_range(0.5, 2.0)


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -hurt_height)


func aggro() -> void:
	var was_calm := state != State.CHASE and state != State.ATTACK
	super()
	if was_calm and state == State.CHASE and randf() < 0.5:
		Sfx.play_at("birdman_screech", global_position)


func _physics_process(delta: float) -> void:
	_leap_cooldown = maxf(_leap_cooldown - delta, 0.0)
	if _leap_time > 0.0 and state != State.DEAD and not is_stunned():
		_process_leap(delta)
		return
	super(delta)


## Wojownik: z pewnej odległości doskakuje do gracza zamiast iść.
func _process_chase() -> void:
	if kind == "warrior" and _leap_cooldown == 0.0 and _player_alive() and not _player_is_safe():
		var distance := global_position.distance_to(_player.global_position)
		if distance > LEAP_RANGE.x and distance < LEAP_RANGE.y and position.distance_to(home) < leash_radius:
			_leap_dir = global_position.direction_to(_player.global_position)
			_leap_time = distance / LEAP_SPEED + 0.05
			_leap_hit = false
			_leap_cooldown = LEAP_COOLDOWN
			_strike_anim = _leap_time
			Sfx.play_at("wing_flap", global_position)
			return
	super()


func _process_leap(delta: float) -> void:
	_leap_time -= delta
	velocity = _leap_dir * LEAP_SPEED
	move_and_slide()
	sprite.frame = 7
	sprite.flip_h = _leap_dir.x < 0.0
	if not _leap_hit and _player_alive() and global_position.distance_to(_player.global_position) < 18.0:
		_leap_hit = true
		_player.take_damage(damage, global_position - _leap_dir * 10.0)
		_player._knockback = _leap_dir * 220.0
	if _leap_time <= 0.0:
		_cooldown = 0.5


func _process_attack(delta: float) -> void:
	if kind == "warrior":
		var before := _attack_timer
		super(delta)
		if before > 0.0 and _attack_timer <= 0.0:
			Sfx.play_at("frog_attack", global_position)
		return
	velocity = _separation() * speed * 0.5
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_strike_anim = 0.3
	_cooldown = attack_cooldown
	state = State.CHASE
	if not _player_alive():
		return
	if kind == "thrower":
		_throw()
	else:
		_call_lightning()


## Oszczep leci prosto w stronę gracza.
func _throw() -> void:
	var side := -1.0 if _player.global_position.x < global_position.x else 1.0
	var javelin := EnemySpit.new()
	javelin.style = "javelin"
	javelin.position = global_position + Vector2(8.0 * side, -14.0)
	javelin.direction = (_player.body_center() - javelin.position).normalized()
	javelin.damage = ranged_damage
	get_parent().add_child(javelin)
	Sfx.play_at("bow", global_position, -4.0)


## Piorun: koło ostrzegawcze pod graczem, po chwili uderzenie z nieba.
func _call_lightning() -> void:
	var target := _player.global_position
	var telegraph := Telegraph.new()
	telegraph.shape = Telegraph.Shape.CIRCLE
	telegraph.radius = BOLT_RADIUS
	telegraph.duration = BOLT_DELAY
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(telegraph)
	telegraph.global_position = target
	Sfx.play_at("zap", global_position, -6.0)
	var timer := get_tree().create_timer(BOLT_DELAY)
	timer.timeout.connect(_strike.bind(telegraph, target))
	# koło znika też wtedy, gdy ptakoczłowieka już nie ma (zginął i zniknął przed uderzeniem)
	timer.timeout.connect(telegraph.queue_free)


func _strike(telegraph: Telegraph, target: Vector2) -> void:
	if is_instance_valid(telegraph):
		if _player_alive() and telegraph.contains(_player.global_position):
			_player.take_damage(ranged_damage, target)
		telegraph.queue_free()
	if not is_inside_tree():
		return
	MonsterFx.sky_bolt(get_parent(), target)
	Sfx.play_at("zap", target)


func _animate(delta: float) -> void:
	if _leap_time > 0.0:
		return
	super(delta)


func _die() -> void:
	super()
	Sfx.play_at("birdman_death", global_position)


func _drop_loot() -> void:
	super()
	if randf() < feather_drop_chance:
		_spawn_pickup("storm_feather", 1)
