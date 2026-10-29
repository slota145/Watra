class_name Eagle
extends Node2D
## Orzeł z Wietrznych Turni: szybuje wysoko zataczając szerokie kręgi (cień przesuwa się po
## ziemi), co jakiś czas pokrzykuje, a czasem przysiada na gałęzi martwego drzewa albo na
## krawędzi skarpy. Siedzi chwilę, rozgląda się i odlatuje - wcześniej, gdy gracz podejdzie.

enum State { SOAR, LAND, PERCH, TAKEOFF }

const SOAR_SPEED := 70.0
const SOAR_HEIGHT := 90.0
const SPOOK_DISTANCE := 70.0
const FLY_SHEET := preload("res://assets/mountains/eagle_fly.png")
const PERCH_SHEET := preload("res://assets/mountains/eagle_perch.png")
const SHADOW := preload("res://assets/shadow.png")

var state := State.SOAR
## Gdzie może przysiąść: [pozycja stóp na ziemi, wysokość grzędy nad ziemią].
var perches: Array = []
var _bounds := Rect2()
var _player: Node2D
var _center := Vector2.ZERO
var _radius := 120.0
var _angle := 0.0
var _height := SOAR_HEIGHT
var _timer := 0.0
var _anim := 0.0
var _cry_timer := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _from_height := 0.0
var _to_height := 0.0
var _travel := 0.0
var _travel_time := 1.0
var _perch_height := 0.0
var _sprite: Sprite2D
var _shadow: Sprite2D


func setup(bounds: Rect2, perch_spots: Array, player: Node2D) -> void:
	_bounds = bounds
	perches = perch_spots
	_player = player
	z_index = 20  # w powietrzu - nad wszystkim
	_shadow = Sprite2D.new()
	_shadow.texture = SHADOW
	_shadow.scale = Vector2(1.6, 0.8)
	_shadow.modulate = Color(1, 1, 1, 0.5)
	_shadow.z_as_relative = false  # cień na ziemi, jak postacie
	_shadow.z_index = 0
	add_child(_shadow)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_new_circle(Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y)))
	_timer = randf_range(8.0, 25.0)
	_cry_timer = randf_range(5.0, 20.0)
	_anim = randf() * 10.0


func _new_circle(center: Vector2) -> void:
	_center = center
	_radius = randf_range(80.0, 180.0)
	_angle = randf() * TAU
	position = _center + Vector2.from_angle(_angle) * _radius


func _process(delta: float) -> void:
	_anim += delta
	_cry_timer -= delta
	if _cry_timer <= 0.0 and state != State.PERCH:
		_cry_timer = randf_range(12.0, 30.0)
		Sfx.play_at("eagle_cry", global_position)
	match state:
		State.SOAR:
			_angle += SOAR_SPEED / _radius * delta
			position = _center + Vector2.from_angle(_angle) * _radius
			_height = SOAR_HEIGHT + sin(_anim * 0.7) * 10.0
			_timer -= delta
			if _timer <= 0.0:
				_try_land()
		State.LAND, State.TAKEOFF:
			_travel += delta
			var t := minf(_travel / _travel_time, 1.0)
			position = _from.lerp(_to, t)
			_height = lerpf(_from_height, _to_height, t * t if state == State.LAND else sqrt(t))
			if t >= 1.0:
				if state == State.LAND:
					state = State.PERCH
					_timer = randf_range(6.0, 16.0)
				else:
					state = State.SOAR
					_timer = randf_range(15.0, 40.0)
		State.PERCH:
			_timer -= delta
			var near := _player != null and _player.global_position.distance_to(global_position) < SPOOK_DISTANCE
			if _timer <= 0.0 or near:
				if near:
					Sfx.play_at("wing_flap", global_position)
					Sfx.play_at("eagle_cry", global_position, -3.0)
				_take_off()
	_draw_state()


func _try_land() -> void:
	if perches.is_empty():
		_timer = randf_range(10.0, 20.0)
		return
	var spot: Array = perches.pick_random()
	if _player != null and _player.global_position.distance_to(spot[0]) < SPOOK_DISTANCE * 1.5:
		_timer = randf_range(5.0, 10.0)
		return
	_from = position
	_to = spot[0]
	_from_height = _height
	_to_height = spot[1]
	_perch_height = spot[1]
	_travel = 0.0
	_travel_time = maxf(1.2, _from.distance_to(_to) / 110.0)
	state = State.LAND


func _take_off() -> void:
	var angle := randf() * TAU
	var target := (position + Vector2.from_angle(angle) * randf_range(200.0, 400.0)).clamp(_bounds.position, _bounds.end)
	_from = position
	_to = target
	_from_height = _height
	_to_height = SOAR_HEIGHT
	_travel = 0.0
	_travel_time = maxf(1.5, _from.distance_to(_to) / 120.0)
	state = State.TAKEOFF
	_center = target - Vector2.from_angle(angle) * 120.0
	_radius = 120.0
	_angle = angle


func _draw_state() -> void:
	var perched := state == State.PERCH
	_sprite.texture = PERCH_SHEET if perched else FLY_SHEET
	_sprite.hframes = 2 if perched else 4
	if perched:
		_sprite.frame = 1 if fmod(_anim, 3.0) > 2.2 else 0  # rozgląda się
		_sprite.offset = Vector2(0, -9)
	else:
		var flap_speed := 10.0 if state != State.SOAR else 3.0
		_sprite.frame = int(_anim * flap_speed) % 4 if state != State.SOAR or fmod(_anim, 4.0) < 1.2 else 1
		_sprite.offset = Vector2.ZERO
		var dir := _to - _from if state != State.SOAR else Vector2.from_angle(_angle + PI / 2.0)
		_sprite.flip_h = dir.x < 0.0
	_sprite.position.y = -_height
	_shadow.visible = not perched or _perch_height > 4.0
	_shadow.position = Vector2.ZERO
	_shadow.scale = Vector2(1.6, 0.8) * clampf(1.2 - _height / 200.0, 0.5, 1.2)
