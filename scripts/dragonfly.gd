class_name Dragonfly
extends Node2D
## Ważka nad wodą: zawisa w powietrzu, po czym zrywem przeskakuje w inne miejsce
## w pobliżu, z migoczącymi skrzydłami. Czasem słychać brzęczenie. Po chwili odlatuje.

const TEXTURE := preload("res://assets/swamp/dragonfly.png")
const DART_SPEED := 140.0
const RANGE := 30.0
const COLORS: Array[Color] = [Color(1, 1, 1), Color(0.6, 1.0, 0.7), Color(1.0, 0.75, 0.5)]

var _wildlife: Wildlife
var _sprite: Sprite2D
var _anchor := Vector2.ZERO
var _target := Vector2.ZERO
var _hover := 0.0
var _life := 0.0
var _time := 0.0


func setup(wildlife: Wildlife, pos: Vector2) -> void:
	_wildlife = wildlife
	position = pos
	_anchor = pos
	_target = pos
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 2
	_sprite.modulate = COLORS.pick_random()
	add_child(_sprite)
	z_index = 6
	_life = randf_range(20.0, 45.0)
	_hover = randf_range(0.2, 1.0)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func _process(delta: float) -> void:
	_time += delta
	_life -= delta
	_sprite.frame = int(_time * 30.0) % 2
	_sprite.position.y = -12.0 + sin(_time * 3.0) * 2.0
	if _life <= 0.0:
		set_process(false)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.6)
		tween.tween_callback(queue_free)
		return
	if _hover > 0.0:
		_hover -= delta
		position += Vector2(sin(_time * 7.0), cos(_time * 5.0)) * 4.0 * delta  # lekkie drżenie w zawisie
		if _hover <= 0.0:
			_pick_target()
		return
	var to_target := _target - position
	var step := DART_SPEED * delta
	if to_target.length() <= step:
		position = _target
		_hover = randf_range(0.3, 1.5)
		return
	position += to_target.normalized() * step
	_sprite.flip_h = to_target.x < 0.0


func _pick_target() -> void:
	if randf() < 0.15:  # czasem przenosi się trochę dalej, ale zawsze nad wodą
		var spot := _wildlife.random_water_near(_anchor, 1.0, 4.0, 10)
		if spot.is_finite():
			_anchor = spot
	_target = _anchor + Vector2(randf_range(-RANGE, RANGE), randf_range(-RANGE, RANGE) * 0.6)
	if randf() < 0.12 and position.distance_to(_wildlife.player_position()) < 120.0:
		Sfx.play_at("dragonfly", global_position)
