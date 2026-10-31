class_name Building
extends Node2D
## Budynek, do którego można wejść. Składa się z podłogi z wewnętrznymi ścianami
## (rysowanej pod postaciami) i dachu z fasadą (sortowanego razem z postaciami po dolnej krawędzi).
## Gdy gracz wejdzie do środka, dach płynnie znika i widać wnętrze.
## Węzeł stoi w lewym górnym rogu budynku.

const WALL_THICKNESS := 4.0
## Wysokość tylnej ściany widocznej od środka (nie da się po niej chodzić).
const BACK_WALL := 28.0
const FRONT_WALL := 5.0
const DOOR_WIDTH := 20.0
const FADE_TIME := 0.25

var display_name := ""
var size_px := Vector2.ZERO

var _player: Player
var _roof: Sprite2D
var _inside := false
var _tween: Tween
var _walls: StaticBody2D


## floor/roof - tekstury wnętrza i dachu; entities - węzeł sortowany po Y, do którego trafia dach.
func setup(building_name: String, floor_texture: Texture2D, roof_texture: Texture2D, entities: Node2D, player: Player) -> void:
	display_name = building_name
	_player = player
	size_px = floor_texture.get_size()

	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = floor_texture
	floor_sprite.centered = false
	add_child(floor_sprite)

	# dach ma punkt zaczepienia na dolnej krawędzi, żeby sortował się jak postacie
	_roof = Sprite2D.new()
	_roof.texture = roof_texture
	_roof.centered = false
	_roof.offset = Vector2(0, -size_px.y)
	_roof.position = position + Vector2(0, size_px.y)
	# dach chowa się sam po wejściu (_process) - prześwitywanie zasłon (Occlusion) by go z powrotem pokazało
	_roof.set_meta("no_occlusion", true)
	entities.add_child(_roof)

	_build_walls()
	add_to_group("buildings")


func is_player_inside() -> bool:
	return _inside


## Punkt tuż przed drzwiami (na zewnątrz), w koordynatach świata.
func door_outside() -> Vector2:
	return global_position + Vector2(size_px.x / 2.0, size_px.y + 6.0)


## Punkt wewnątrz budynku; `fraction` 0..1 w obrębie podłogi do chodzenia.
func inside_point(fraction: Vector2) -> Vector2:
	var area := _walkable_rect()
	return global_position + area.position + area.size * fraction


## Dodaje dym z komina (pozycja względem lewego górnego rogu).
func add_chimney_smoke(local_pos: Vector2) -> void:
	var smoke := CPUParticles2D.new()
	smoke.amount = 10
	smoke.lifetime = 2.5
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(4, -6)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 10.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 4.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.55, 0.55, 0.6, 0.6), Color(0.7, 0.7, 0.75, 0.0)])
	smoke.color_ramp = fade
	# dach ma początek w lewym dolnym rogu budynku
	smoke.position = local_pos - Vector2(0, size_px.y)
	_roof.add_child(smoke)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var inside := _walkable_rect().grow(2.0).has_point(_player.global_position - global_position)
	if inside != _inside:
		_inside = inside
		Sfx.play("door" if inside else "door_close")
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_roof, "modulate:a", 0.0 if inside else 1.0, FADE_TIME)


func _walkable_rect() -> Rect2:
	return Rect2(WALL_THICKNESS, BACK_WALL, size_px.x - WALL_THICKNESS * 2.0, size_px.y - BACK_WALL)


## Dodatkowa ściana wewnątrz (np. działowa między pokojami), w pikselach od lewego górnego rogu.
func add_wall(wall: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = wall.size
	shape.shape = box
	shape.position = wall.get_center()
	_walls.add_child(shape)


## Ściany jako kolizje: tylna (z widoczną częścią), boczne i przednia z otworem na drzwi.
func _build_walls() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	_walls = body
	var w := size_px.x
	var h := size_px.y
	var door_left := (w - DOOR_WIDTH) / 2.0
	var walls: Array[Rect2] = [
		Rect2(0, 0, w, BACK_WALL - 4.0),
		Rect2(0, 0, WALL_THICKNESS, h),
		Rect2(w - WALL_THICKNESS, 0, WALL_THICKNESS, h),
		Rect2(0, h - FRONT_WALL, door_left, FRONT_WALL),
		Rect2(door_left + DOOR_WIDTH, h - FRONT_WALL, w - door_left - DOOR_WIDTH, FRONT_WALL),
	]
	for wall in walls:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		shape.position = wall.get_center()
		body.add_child(shape)
