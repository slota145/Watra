class_name FieldWorm
extends Goblin
## Czerw polny: spokojny wystaje do połowy z ziemi i kołysze się nad swoją norą. Gdy zauważy gracza,
## chowa się i przekopuje pod ziemią (widać tylko sunący kopczyk ziemi - wtedy nie da się go zranić),
## podpełza pod gracza, a miejsce ataku świeci czerwonym kołem - po chwili wystrzela z ziemi i gryzie
## wszystko w kole. Potem chwilę zostaje na wierzchu (wtedy można go bić, a z bliska kąsa) i znów się zakopuje.

enum Phase { UP, DIVE, UNDER, AIM, RISE }

## Klatki: 0-3 kołysanie, 4 wynurzanie (nisko), 5 wynurzanie (wyżej), 6 zamach, 7 kąsanie.
const MOUND := preload("res://assets/fields/mound.png")
const HOLE := preload("res://assets/fields/hole.png")
const DIVE_TIME := 0.45
const AIM_TIME := 0.75
const RISE_TIME := 0.25

@export var erupt_damage := 18
@export var erupt_radius := 22.0
## Ile sekund czerw zostaje na wierzchu po ataku, zanim znów się zakopie.
@export var surface_time := 1.8
## Jak blisko gracza musi podpełznąć pod ziemią, żeby zaatakować.
@export var strike_distance := 30.0

var phase := Phase.UP
var _phase_time := 0.0
var _aim_at := Vector2.ZERO
var _aim_telegraph: Telegraph
var _mound: Sprite2D
var _hole: Sprite2D
var _dust: AnimatedSprite2D


func _ready() -> void:
	super()
	hurt_radius = 8.0
	heart_drop_chance = 0.0
	equipment_drop_chance = 0.05
	map_color = Color(0.85, 0.6, 0.55)
	quest_kind = "worm"
	fearless = true
	_hole = Sprite2D.new()
	_hole.texture = HOLE
	_hole.z_index = -1
	_hole.position = Vector2(0, 1)
	add_child(_hole)
	move_child(_hole, 0)
	_mound = Sprite2D.new()
	_mound.texture = MOUND
	_mound.offset = Vector2(0, -4)
	_mound.visible = false
	add_child(_mound)
	# pył i grudy nad kopcem, gdy robak ryje pod ziemią
	_dust = MonsterFx.dust()
	_dust.visible = false
	add_child(_dust)


func is_underground() -> bool:
	return phase == Phase.UNDER or phase == Phase.AIM


func take_damage(amount: int, from_position: Vector2, knockback := 0.0) -> void:
	if is_underground():
		return
	# czerw siedzi w norze - ciosy go nie odpychają
	super(amount, from_position, 0.0)


func stun(seconds: float) -> void:
	if not is_underground():
		super(seconds)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if state == State.IDLE or state == State.RETURN:
		if state == State.IDLE and phase != Phase.UP:
			_surface(global_position)
		if state == State.RETURN:
			_go_home(delta)
			return
		super(delta)
		return
	if not is_underground() and _process_stun(delta):
		return
	if not _player_alive() or _player_is_safe() or position.distance_to(home) > leash_radius:
		state = State.RETURN
		return
	_phase_time += delta
	velocity = Vector2.ZERO
	match phase:
		Phase.UP:
			_cooldown = maxf(_cooldown - delta, 0.0)
			_strike_anim = maxf(_strike_anim - delta, 0.0)
			# z bliska kąsa, potem znowu pod ziemię
			var near := global_position.distance_to(_player.global_position) < attack_range + 6.0
			if near and _cooldown == 0.0:
				_strike_anim = 0.25
				_cooldown = attack_cooldown
				_player.take_damage(damage, global_position)
			if _phase_time > surface_time:
				_set_phase(Phase.DIVE)
		Phase.DIVE:
			if _phase_time >= DIVE_TIME:
				_go_under()
		Phase.UNDER:
			var to_player := _player.global_position - global_position
			if to_player.length() < strike_distance or _phase_time > 6.0:
				_start_aim()
			else:
				velocity = to_player.normalized() * speed
				move_and_slide()
		Phase.AIM:
			if _phase_time >= AIM_TIME:
				_erupt()
		Phase.RISE:
			if _phase_time >= RISE_TIME:
				_set_phase(Phase.UP)
	_animate(delta)


## Spokojny czerw nie chodzi - tylko kołysze się nad norą.
func _process_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _player_alive() and global_position.distance_to(_player.global_position) < aggro_radius:
		aggro()


func aggro() -> void:
	var calm := state == State.IDLE
	super()
	if calm and state == State.CHASE:
		_set_phase(Phase.DIVE)


func _set_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0


func _go_under() -> void:
	_set_phase(Phase.UNDER)
	remove_from_group("enemies")
	sprite.visible = false
	_hole.visible = false
	_mound.visible = true
	_dust.visible = true
	$CollisionShape2D.set_deferred("disabled", true)
	Sfx.play_at("mine", global_position, -8.0)


func _start_aim() -> void:
	_set_phase(Phase.AIM)
	_aim_at = _player.global_position
	_aim_telegraph = Telegraph.new()
	_aim_telegraph.radius = erupt_radius
	_aim_telegraph.duration = AIM_TIME
	var layer := get_tree().get_first_node_in_group("floor_layer")
	(layer if layer != null else get_parent()).add_child(_aim_telegraph)
	_aim_telegraph.global_position = _aim_at
	# kopczyk podjeżdża pod środek koła
	var tween := create_tween()
	tween.tween_property(self, "global_position", _aim_at, AIM_TIME * 0.6)


func _erupt() -> void:
	if is_instance_valid(_aim_telegraph):
		_aim_telegraph.queue_free()
	_surface(_aim_at)
	_set_phase(Phase.RISE)
	_strike_anim = 0.3
	Sfx.play_at("rock_break", global_position, -4.0)
	if _player_alive() and _player.global_position.distance_to(_aim_at) <= erupt_radius:
		_player.take_damage(erupt_damage, _aim_at)
		_player._knockback = (_player.global_position - _aim_at).normalized() * 160.0
	BossFx.burrow(get_parent(), global_position, 0.6)
	if _player != null and _player.global_position.distance_to(global_position) < 200.0:
		_player.add_shake(2.0)


func _surface(at: Vector2) -> void:
	global_position = at
	reset_physics_interpolation()
	add_to_group("enemies")
	sprite.visible = true
	_hole.visible = true
	_mound.visible = false
	_dust.visible = false
	$CollisionShape2D.set_deferred("disabled", false)
	if phase != Phase.RISE:
		_set_phase(Phase.UP)


## Powrót do nory pod ziemią (gracz uciekł).
func _go_home(_delta: float) -> void:
	if phase == Phase.UP and position.distance_to(home) < 3.0:
		state = State.IDLE
		health = max_health
		return
	if phase != Phase.UNDER:
		if is_instance_valid(_aim_telegraph):
			_aim_telegraph.queue_free()
		_go_under()
	velocity = position.direction_to(home) * speed
	move_and_slide()
	if position.distance_to(home) < 4.0:
		_surface(home)
		state = State.IDLE
		health = max_health


func _animate(delta: float) -> void:
	if not sprite.visible:
		_mound.position.y = sin(_phase_time * 18.0) * 0.6
		return
	sprite.flip_h = _player != null and _player.global_position.x < global_position.x
	match phase:
		Phase.DIVE:
			sprite.frame = 5 if _phase_time < DIVE_TIME * 0.5 else 4
			return
		Phase.RISE:
			sprite.frame = 5 if _phase_time < RISE_TIME * 0.5 else 7
			return
	if _strike_anim > 0.0:
		sprite.frame = 7 if _strike_anim < 0.18 else 6
		return
	_anim_time += delta * 5.0
	sprite.frame = int(_anim_time) % 4


func _drop_loot() -> void:
	super()
	if randf() < 0.25:
		_spawn_pickup("worm_tooth", 1)


func _die() -> void:
	if is_instance_valid(_aim_telegraph):
		_aim_telegraph.queue_free()
	super()
