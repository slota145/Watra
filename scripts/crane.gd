class_name Crane
extends Node2D
## Żuraw: przylatuje z daleka, ląduje w płyciźnie przy brzegu i przez dłuższą chwilę
## brodzi, przystaje i dziobie w wodzie, czasem zaklangoruje. Potem odlatuje - albo
## wcześniej, jeśli gracz podejdzie za blisko.

enum State { ARRIVE, WADE, LEAVE }

const TEXTURE := preload("res://assets/swamp/crane.png")
const SHADOW := preload("res://assets/shadow.png")
const FLY_SPEED := 85.0
const FLY_HEIGHT := 60.0
const WALK_SPEED := 7.0
const SPOOK_DISTANCE := 85.0
## Klatki: 0 stoi, 1-2 kroczy, 3 dziobie, 4-5 leci.
const FRAME_STAND := 0
const FRAME_PECK := 3

var state := State.ARRIVE
var _wildlife: Wildlife
var _sprite: Sprite2D
var _shadow: Sprite2D
var _fly_from := Vector2.ZERO
var _fly_to := Vector2.ZERO
var _fly_time := 0.0
var _fly_duration := 1.0
var _stay := 0.0
var _target := Vector2.ZERO
var _pause := 0.0
var _pecking := false
var _call_timer := 0.0
var _anim := 0.0


func setup(wildlife: Wildlife, landing: Vector2) -> void:
	_wildlife = wildlife
	_shadow = Sprite2D.new()
	_shadow.texture = SHADOW
	_shadow.scale = Vector2(1.6, 1.0)
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 6
	_sprite.offset = Vector2(0, -16)
	add_child(_sprite)
	_stay = randf_range(45.0, 100.0)
	_call_timer = randf_range(4.0, 12.0)
	_target = landing
	# przylatuje z daleka, z losowej strony
	_start_flight(landing + Vector2.from_angle(randf() * TAU) * 460.0, landing)
	state = State.ARRIVE
	if landing.distance_to(_wildlife.player_position()) < 400.0:
		Sfx.play_at("crane_call", landing, -2.0)


func _process(delta: float) -> void:
	_anim += delta
	match state:
		State.ARRIVE, State.LEAVE:
			_process_flight(delta)
		State.WADE:
			_process_wade(delta)


func _start_flight(from: Vector2, to: Vector2) -> void:
	position = from
	_fly_from = from
	_fly_to = to
	_fly_time = 0.0
	_fly_duration = maxf(1.0, from.distance_to(to) / FLY_SPEED)
	_sprite.flip_h = to.x < from.x
	_shadow.visible = true
	z_index = 10


func _process_flight(delta: float) -> void:
	_fly_time += delta
	var t := minf(_fly_time / _fly_duration, 1.0)
	position = _fly_from.lerp(_fly_to, t)
	var height := FLY_HEIGHT * (1.0 - t) if state == State.ARRIVE else FLY_HEIGHT * t
	if state == State.ARRIVE:
		height = FLY_HEIGHT * minf(1.0, (1.0 - t) * 3.0)
	_sprite.position.y = -height
	_sprite.frame = 4 + int(_anim * 4.0) % 2
	modulate.a = minf(1.0, minf(t * 4.0, (1.0 - t) * 4.0)) if state == State.LEAVE else minf(1.0, t * 4.0 + 0.2)
	if t < 1.0:
		return
	if state == State.LEAVE:
		queue_free()
		return
	state = State.WADE
	_sprite.position.y = 0.0
	z_index = 0
	modulate.a = 1.0
	_wildlife.ripple(position, 10.0)
	_pause = randf_range(1.0, 3.0)


## Brodzi w płyciźnie: kroczy powoli od miejsca do miejsca, przystaje i dziobie.
func _process_wade(delta: float) -> void:
	_stay -= delta
	if position.distance_to(_wildlife.player_position()) < SPOOK_DISTANCE or _stay <= 0.0:
		_leave()
		return
	_call_timer -= delta
	if _call_timer <= 0.0:
		_call_timer = randf_range(18.0, 40.0)
		Sfx.play_at("crane_call", global_position, -3.0)
	if _pause > 0.0:
		_pause -= delta
		_sprite.frame = FRAME_PECK if _pecking else FRAME_STAND
		if _pause <= 0.0:
			var spot := _wildlife.shore_near(position, 3.0)
			_target = spot if spot.is_finite() else position
			if _pecking:
				_wildlife.ripple(position + Vector2(10.0 * (-1.0 if _sprite.flip_h else 1.0), 0), 5.0)
		return
	var to_target := _target - position
	if to_target.length() < 1.0:
		_pause = randf_range(2.0, 5.0)
		_pecking = randf() < 0.6
		return
	position += to_target.normalized() * WALK_SPEED * delta
	_sprite.flip_h = to_target.x < 0.0
	_sprite.frame = 1 + int(_anim * 2.5) % 2


func _leave() -> void:
	state = State.LEAVE
	Sfx.play_at("wing_flap", global_position, -2.0)
	Sfx.play_at("crane_call", global_position, -2.0)
	var away := (position - _wildlife.player_position()).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	_start_flight(position, position + away.rotated(randf_range(-0.6, 0.6)) * 520.0)
