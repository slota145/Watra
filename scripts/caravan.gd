class_name Caravan
extends Node
## Wóz kupiecki z eskortą strażników, jadący drogą przez osadę od jednego krańca mapy
## do drugiego. Po dojechaniu do końca znika (sygnał `finished`). W wydarzeniu „karawana” (EventSite) wóz stoi,
## gdy `waiting` (gracz został w tyle), a `wagon_position` / `progress` mówią, gdzie jest.

signal finished

const SPEED := 30.0
## Wóz jadący po skosie w dół (w prawo) i po skosie w górę (w prawo); w lewo - odbicie.
const WAGON := preload("res://assets/village/wagon.png")
const WAGON_UP := preload("res://assets/village/wagon_up.png")
const GUARD := preload("res://assets/npc/guard.png")
const SHADOW := preload("res://assets/shadow.png")
## Eskorta: [odległość od wozu wzdłuż drogi (+ przed, - za), przesunięcie w bok].
const ESCORT := [[58.0, 0.0], [-54.0, -16.0], [-54.0, 16.0]]
## Klatki wozu (koń idzie, koła się toczą) i ich długość w pikselach drogi.
const WAGON_FRAMES := 4
const WAGON_STEP := 7.0
const GUARD_ROW_DOWN := 0
const GUARD_ROW_UP := 1
const GUARD_ROW_SIDE := 2

var _points := PackedVector2Array()
## Odległość od początku drogi do każdego punktu.
var _cumulative := PackedFloat32Array()
var _length := 0.0
var _distance := 0.0
var _anim := 0.0
var _wagon: Sprite2D
var _guards: Array[Sprite2D] = []
## Eskorta: wóz czeka na gracza.
var waiting := false


## points - droga w pikselach świata; entities - węzeł sortowany po Y.
func setup(points: PackedVector2Array, entities: Node2D) -> void:
	_points = points
	_cumulative.resize(points.size())
	for i in points.size():
		_length += 0.0 if i == 0 else points[i].distance_to(points[i - 1])
		_cumulative[i] = _length

	_wagon = Sprite2D.new()
	_wagon.texture = WAGON
	_wagon.hframes = WAGON_FRAMES
	# punkt zaczepienia u dołu kół (grafika ma 3 piksele zapasu pod kołami)
	_set_wagon_texture(WAGON)
	entities.add_child(_wagon)
	for escort in ESCORT:
		var guard := Sprite2D.new()
		guard.texture = GUARD
		guard.hframes = 4
		guard.vframes = 4
		guard.offset = Vector2(0, -19)
		var shadow := Sprite2D.new()
		shadow.texture = SHADOW
		shadow.position = Vector2(0, -1)
		shadow.show_behind_parent = true
		guard.add_child(shadow)
		entities.add_child(guard)
		_guards.append(guard)
	_update()


func _process(delta: float) -> void:
	if waiting:
		return
	_distance += SPEED * delta
	_anim += delta
	if _distance > _length + 80.0:
		_wagon.queue_free()
		for guard in _guards:
			guard.queue_free()
		finished.emit()
		queue_free()
		return
	_update()


func _update() -> void:
	var direction := (_sample(_distance + 4.0) - _sample(_distance - 4.0)).normalized()
	_wagon.position = _sample(_distance)
	# pod górę widać wóz od tyłu, z koniem z przodu u góry (z zapasem, żeby na krętej drodze
	# przy jeździe prawie w poziomie grafika nie przeskakiwała co chwilę)
	if direction.y < -0.3:
		_set_wagon_texture(WAGON_UP)
	elif direction.y > -0.1:
		_set_wagon_texture(WAGON)
	_wagon.flip_h = direction.x < 0.0
	_wagon.frame = int(_distance / WAGON_STEP) % WAGON_FRAMES  # koła i nogi konia

	var row := GUARD_ROW_SIDE
	if absf(direction.y) > absf(direction.x):
		row = GUARD_ROW_DOWN if direction.y > 0.0 else GUARD_ROW_UP
	for i in _guards.size():
		var guard := _guards[i]
		guard.position = _sample(_distance + ESCORT[i][0]) + direction.orthogonal() * ESCORT[i][1]
		guard.flip_h = direction.x < 0.0
		guard.frame = row * 4 + int(_anim * 7.0) % 4


func wagon_position() -> Vector2:
	return _wagon.position if is_instance_valid(_wagon) else Vector2.ZERO


## Ile drogi przejechał (0..1).
func progress() -> float:
	return clampf(_distance / maxf(_length, 1.0), 0.0, 1.0)


## Koniec bez dojazdu (wóz zniszczony): wóz i strażnicy znikają.
func _exit_tree() -> void:
	var nodes: Array = [_wagon]
	nodes.append_array(_guards)
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()


func _set_wagon_texture(texture: Texture2D) -> void:
	if _wagon.texture == texture:
		return
	_wagon.texture = texture
	_wagon.offset = Vector2(0, -texture.get_height() / 2.0 + 3.0)


## Punkt na drodze w danej odległości od początku.
func _sample(distance: float) -> Vector2:
	distance = clampf(distance, 0.0, _length)
	var index := _cumulative.bsearch(distance)
	if index <= 0:
		return _points[0]
	if index >= _points.size():
		return _points[_points.size() - 1]
	var segment := _cumulative[index] - _cumulative[index - 1]
	var t := 0.0 if segment <= 0.0 else (distance - _cumulative[index - 1]) / segment
	return _points[index - 1].lerp(_points[index], t)
