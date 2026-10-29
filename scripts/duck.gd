class_name Duck
extends Node2D
## Kaczka z rozlewisk: pływa powoli po wodzie zostawiając kręgi i czasem kwacze. Od czasu
## do czasu sama przelatuje w inne miejsce na wodzie, a gdy gracz podejdzie za blisko,
## zrywa się z łopotem skrzydeł i kwakaniem, i odlatuje daleko - razem z całym stadem,
## które podrywa się chwilę po niej i leci w to samo miejsce.

enum State { SWIM, FLY }

const SWIM_SPEED := 9.0
const FLY_SPEED := 110.0
const FLY_HEIGHT := 34.0
const SPOOK_DISTANCE := 56.0
## Kaczki w tej odległości to jedno stado - płoszą się razem.
const FLOCK_RADIUS := 80.0
const SHADOW := preload("res://assets/shadow.png")

var state := State.SWIM
var _wildlife: Wildlife
var _sprite: Sprite2D
var _shadow: Sprite2D
var _target := Vector2.ZERO
var _timer := 0.0
var _anim := 0.0
var _ripple_timer := 0.0
var _quack_timer := 0.0
var _fly_from := Vector2.ZERO
var _fly_to := Vector2.ZERO
var _fly_time := 0.0
var _fly_duration := 1.0
## Spłoszona przez stado: za ile sekund się poderwie i dokąd poleci.
var _scare_delay := -1.0
var _scare_to := Vector2.ZERO


func setup(wildlife: Wildlife, pos: Vector2, texture: Texture2D) -> void:
	_wildlife = wildlife
	add_to_group("ducks")
	position = pos
	_target = pos
	_shadow = Sprite2D.new()
	_shadow.texture = SHADOW
	_shadow.scale = Vector2(1.1, 0.8)
	_shadow.visible = false
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = 4
	_sprite.offset = Vector2(0, -5)
	add_child(_sprite)
	_timer = randf_range(0.5, 5.0)
	_anim = randf() * 10.0
	_quack_timer = randf_range(10.0, 40.0)


func _process(delta: float) -> void:
	_anim += delta
	if state == State.FLY:
		_process_fly(delta)
	else:
		_process_swim(delta)


func _process_swim(delta: float) -> void:
	_sprite.frame = int(_anim * 1.5) % 2
	if _scare_delay >= 0.0:
		_scare_delay -= delta
		if _scare_delay < 0.0:
			_fly(_scare_to, randf() < 0.4, false)
		return
	if position.distance_to(_wildlife.player_position()) < SPOOK_DISTANCE:
		_fly(_wildlife.far_water(position, 18.0), true, true)
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(3.0, 8.0)
		if randf() < 0.06:  # sama z siebie przelatuje gdzie indziej
			_fly(_wildlife.far_water(position, 12.0), false)
			return
		var spot := _wildlife.random_water_near(position, 0.5, 3.0)
		_target = spot if spot.is_finite() else position
	var to_target := _target - position
	if to_target.length() > 1.0:
		var step := to_target.normalized() * SWIM_SPEED * delta
		if _wildlife.is_water(position + step * 8.0):
			position += step
			_sprite.flip_h = to_target.x < 0.0
		else:
			_target = position
		_ripple_timer -= delta
		if _ripple_timer <= 0.0:
			_ripple_timer = randf_range(1.2, 2.2)
			_wildlife.ripple(position + Vector2(0, 1), 6.0)
	_quack_timer -= delta
	if _quack_timer <= 0.0:
		_quack_timer = randf_range(15.0, 45.0)
		if position.distance_to(_wildlife.player_position()) < 260.0:
			Sfx.play_at("duck_quack", global_position, -3.0)


## Stado podrywa się chwilę po spłoszonej kaczce i leci w to samo miejsce.
func scare(destination: Vector2, delay: float) -> void:
	if state == State.SWIM and _scare_delay < 0.0:
		_scare_delay = delay
		_scare_to = destination


func _fly(destination: Vector2, spooked: bool, alarm_flock := false) -> void:
	if not destination.is_finite():
		return
	if alarm_flock:
		for other: Duck in get_tree().get_nodes_in_group("ducks"):
			if other != self and other.position.distance_to(position) < FLOCK_RADIUS:
				var spot := _wildlife.random_water_near(destination, 0.0, 2.0, 15)
				other.scare(spot if spot.is_finite() else destination, randf_range(0.08, 0.45))
	state = State.FLY
	_fly_from = position
	_fly_to = destination
	_fly_time = 0.0
	_fly_duration = maxf(0.8, position.distance_to(destination) / FLY_SPEED)
	_sprite.flip_h = destination.x < position.x
	_shadow.visible = true
	z_index = 10
	Sfx.play_at("wing_flap", global_position)
	if spooked or randf() < 0.4:
		Sfx.play_at("duck_quack", global_position)
	_wildlife.ripple(position, 9.0)


func _process_fly(delta: float) -> void:
	_fly_time += delta
	var t := minf(_fly_time / _fly_duration, 1.0)
	position = _fly_from.lerp(_fly_to, t)
	# szybko się wznosi, leci wysoko i łagodnie siada na wodzie
	var height := FLY_HEIGHT * minf(1.0, minf(t * 5.0, (1.0 - t) * 4.0))
	_sprite.position.y = -height
	_sprite.frame = 2 + int(_anim * 9.0) % 2
	_shadow.scale = Vector2(1.1, 0.8) * (1.0 - height / FLY_HEIGHT * 0.4)
	if t >= 1.0:
		state = State.SWIM
		_sprite.position.y = 0.0
		_shadow.visible = false
		z_index = 0
		_target = position
		_timer = randf_range(2.0, 5.0)
		_wildlife.ripple(position, 9.0)
