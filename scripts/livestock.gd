class_name Livestock
extends Node2D
## Zwierzę gospodarskie w zagrodzie osady (świnie). Nie da się go zaatakować - żyje własnym rytmem:
## spaceruje po zagrodzie, ryje w błocie albo przy korycie, kładzie się spać (z "z" nad głową) i wstaje.
## Gdy gracz podejdzie, czasem chrząknie i odwróci się w jego stronę. Arkusz z tools/village_animals.py:
## rząd 0 - chód (4 klatki), 1 - rycie (4), 2 - kładzenie się (SLEEP_FRAMES, ostatnie = leży).
## Grafika patrzy w prawo w dół, w lewo odbijamy.

enum State { STAND, WALK, EAT, LIE_DOWN, SLEEP, GET_UP }

const SPEED := 14.0
const WALK_FPS := 6.0
const EAT_FPS := 4.0
const SLEEP_FRAMES := 8
const LIE_FPS := 6.0
const VOICE_DISTANCE := 110.0

## Zagroda w pikselach świata (zwierzę nie wychodzi poza nią) i miejsca, przy których lubi ryć.
var pen := Rect2()
var feeding_spots: Array[Vector2] = []
var sheet: Texture2D
var columns := 8
## Przesunięcie grafiki nad stopy (piksele).
var sprite_offset := Vector2(0, -12)

var state := State.STAND
var _target := Vector2.ZERO
var _timer := 0.0
var _anim := 0.0
var _voice_timer := 0.0
var _zzz_timer := 0.0
var _player: Node2D
var _sprite: Sprite2D
## Idzie do koryta / błota - po dojściu zacznie ryć.
var _eat_after := false


func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	var shadow := Sprite2D.new()
	shadow.texture = preload("res://assets/shadow.png")
	shadow.scale = Vector2(2.0, 1.1)
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = columns
	_sprite.vframes = 3
	_sprite.offset = sprite_offset
	add_child(_sprite)
	_sprite.flip_h = randf() < 0.5
	_timer = randf_range(0.5, 4.0)
	_voice_timer = randf_range(4.0, 14.0)


func _process(delta: float) -> void:
	_timer -= delta
	match state:
		State.STAND:
			_frame(0, 0)
			if _timer <= 0.0:
				_choose_next()
		State.WALK:
			var to_target := _target - position
			var step := SPEED * delta
			if to_target.length() <= step:
				position = _target
				if _eat_after:
					_eat_after = false
					_eat()
				else:
					_stand(randf_range(0.5, 2.5))
			else:
				position += to_target.normalized() * step
				if absf(to_target.x) > 0.5:
					_sprite.flip_h = to_target.x < 0.0
				_anim += delta * WALK_FPS
				_frame(0, int(_anim) % 4)
		State.EAT:
			_anim += delta * EAT_FPS
			_frame(1, int(_anim) % 4)
			if _timer <= 0.0:
				_stand(randf_range(1.0, 3.0))
		State.LIE_DOWN:
			_anim += delta * LIE_FPS
			if _anim >= SLEEP_FRAMES - 1:
				state = State.SLEEP
				_timer = randf_range(12.0, 30.0)
				_anim = 0.0
			_frame(2, mini(int(_anim), SLEEP_FRAMES - 1))
		State.SLEEP:
			# oddycha: dwie ostatnie klatki leżenia na zmianę, powoli
			_anim += delta * 0.8
			_frame(2, SLEEP_FRAMES - 1 - int(_anim) % 2)
			_zzz_timer -= delta
			if _zzz_timer <= 0.0:
				_zzz_timer = randf_range(1.6, 2.6)
				_zzz()
			if _timer <= 0.0:
				state = State.GET_UP
				_anim = SLEEP_FRAMES - 1
		State.GET_UP:
			_anim -= delta * LIE_FPS
			if _anim <= 0.0:
				_stand(randf_range(1.0, 2.0))
			else:
				_frame(2, int(_anim))
	_process_voice(delta)


func _choose_next() -> void:
	var roll := randf()
	if roll < 0.45:
		state = State.WALK
		_target = _random_point()
		_anim = 0.0
	elif roll < 0.8:
		# ryje przy korycie albo w błocie, czasem tam, gdzie stoi
		if not feeding_spots.is_empty() and randf() < 0.6:
			state = State.WALK
			_target = feeding_spots.pick_random() + Vector2(randf_range(-10, 10), randf_range(-4, 4))
			_target = _target.clamp(pen.position, pen.end)
			_eat_after = true
			return
		_eat()
	elif roll < 0.92:
		state = State.LIE_DOWN
		_anim = 0.0
	else:
		_stand(randf_range(2.0, 5.0))


func _eat() -> void:
	state = State.EAT
	_anim = 0.0
	_timer = randf_range(3.0, 7.0)


func _stand(time: float) -> void:
	state = State.STAND
	_timer = time


func _random_point() -> Vector2:
	return Vector2(randf_range(pen.position.x, pen.end.x), randf_range(pen.position.y, pen.end.y))


func _frame(row: int, column: int) -> void:
	_sprite.frame = row * columns + column


## Chrząkanie, gdy gracz jest blisko (i czasem odwrócenie się do niego).
func _process_voice(delta: float) -> void:
	if _player == null or state == State.SLEEP or state == State.LIE_DOWN:
		return
	_voice_timer -= delta
	if _voice_timer > 0.0:
		return
	_voice_timer = randf_range(5.0, 14.0)
	if _player.global_position.distance_to(global_position) < VOICE_DISTANCE:
		Sfx.play_at("boar_grunt", global_position, -6.0)
		if state == State.STAND:
			_sprite.flip_h = _player.global_position.x < global_position.x


## Unoszące się "z" nad śpiącym zwierzęciem.
func _zzz() -> void:
	var label := Label.new()
	label.text = "z"
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	label.add_theme_constant_override("outline_size", 3)
	var side := -1.0 if _sprite.flip_h else 1.0
	label.position = Vector2(6.0 * side, -22)
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position", label.position + Vector2(5.0 * side, -12), 1.6)
	tween.tween_property(label, "modulate:a", 0.0, 1.6).set_delay(0.6)
	tween.chain().tween_callback(label.queue_free)
