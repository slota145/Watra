class_name Wildlife
extends Node
## Życie przy wodzie w rozlewiskach: stadka kaczek pływających po wodzie (czasem przelatują
## w inne miejsce, a spłoszone zrywają się do lotu), żuraw, który co jakiś czas przylatuje
## i brodzi przy brzegu, ważki śmigające nad wodą w pobliżu gracza i ryby wyskakujące z wody.
## Ważki i ryby pojawiają się tylko w pobliżu gracza, żeby nie obciążać gry.

const DUCK_FLOCKS := 6
const DRAGONFLIES_MAX := 6
## Co ile sekund (losowo) przylatuje żuraw i co ile wyskakuje ryba.
const CRANE_INTERVAL := Vector2(45.0, 120.0)
const FISH_INTERVAL := Vector2(5.0, 12.0)
const FISH_TEXTURE := preload("res://assets/swamp/fish.png")
const DUCK_DRAKE := preload("res://assets/swamp/duck_drake.png")
const DUCK_HEN := preload("res://assets/swamp/duck_hen.png")
const TILE := 16

var world: Node
var entities: Node2D
var _player: Player
var _water: Array[Vector2i] = []
var _shore: Array[Vector2i] = []
var _crane: Crane
var _crane_timer := 0.0
var _fish_timer := 0.0
var _dragonfly_check := 0.0
var _dragonflies: Array[Node2D] = []


func setup(owner_world: Node, entities_node: Node2D) -> void:
	world = owner_world
	entities = entities_node
	_player = world.player
	_water = world.water_cells(["deep", "shallow"] as Array[String])
	_shore = world.shore_cells()
	for i in DUCK_FLOCKS:
		var center := _cell_center(_water.pick_random())
		for k in randi_range(2, 4):
			var spot := random_water_near(center, 0.0, 2.0)
			if spot.is_finite():
				var duck := Duck.new()
				entities.add_child(duck)
				duck.setup(self, spot, DUCK_DRAKE if k % 2 == 0 else DUCK_HEN)
	_crane_timer = randf_range(15.0, 45.0)
	_fish_timer = randf_range(3.0, 8.0)


func _process(delta: float) -> void:
	if _player == null:
		return
	_process_crane(delta)
	_process_fish(delta)
	_process_dragonflies(delta)


# ---------------------------------------------------------------- pomocnicze dla stworzeń
func is_water(pos: Vector2) -> bool:
	return world.water_at(pos) != ""


func player_position() -> Vector2:
	return _player.global_position


## Losowe miejsce na wodzie w odległości od `min_tiles` do `max_tiles` kafelków (INF, gdy brak).
func random_water_near(center: Vector2, min_tiles: float, max_tiles: float, tries := 40) -> Vector2:
	for i in tries:
		var pos := center + Vector2.from_angle(randf() * TAU) * randf_range(min_tiles, max_tiles) * TILE
		if is_water(pos):
			return pos
	return Vector2.INF


## Losowe miejsce na wodzie daleko stąd (np. dla spłoszonych kaczek).
func far_water(from: Vector2, min_tiles: float) -> Vector2:
	for i in 40:
		var pos := _cell_center(_water.pick_random())
		if pos.distance_to(from) >= min_tiles * TILE:
			return pos
	return Vector2.INF


## Płycizna przy brzegu w pobliżu (dla brodzącego żurawia).
func shore_near(center: Vector2, max_tiles: float) -> Vector2:
	for i in 30:
		var pos := center + Vector2.from_angle(randf() * TAU) * randf_range(1.0, max_tiles) * TILE
		if world.water_at(pos) == "shallow":
			return pos
	return Vector2.INF


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(8, 8)


## Rozchodzące się kręgi na wodzie.
func ripple(pos: Vector2, radius := 8.0) -> void:
	var ring := Ripple.new()
	ring.position = pos
	ring.max_radius = radius
	world.decor.add_child(ring)


# ---------------------------------------------------------------- żuraw
func _process_crane(delta: float) -> void:
	if is_instance_valid(_crane):
		return
	_crane_timer -= delta
	if _crane_timer > 0.0 or _shore.is_empty():
		return
	_crane_timer = randf_range(CRANE_INTERVAL.x, CRANE_INTERVAL.y)
	# ląduje przy brzegu niedaleko gracza, żeby było go widać
	for i in 40:
		var spot := _cell_center(_shore.pick_random())
		var d := spot.distance_to(_player.global_position)
		if d > 110.0 and d < 420.0:
			_crane = Crane.new()
			entities.add_child(_crane)
			_crane.setup(self, spot)
			return


# ---------------------------------------------------------------- ryby
func _process_fish(delta: float) -> void:
	_fish_timer -= delta
	if _fish_timer > 0.0:
		return
	_fish_timer = randf_range(FISH_INTERVAL.x, FISH_INTERVAL.y)
	var spot := random_water_near(_player.global_position, 3.0, 13.0)
	if not spot.is_finite():
		return
	var side := 1.0 if randf() < 0.5 else -1.0
	var fish := Sprite2D.new()
	fish.texture = FISH_TEXTURE
	fish.flip_h = side < 0.0
	fish.position = spot
	fish.z_index = 4
	world.decor.add_child(fish)
	ripple(spot, 7.0)
	Sfx.play_at("fish_splash", spot, -4.0)
	var land := spot + Vector2(18.0 * side, 0)
	var tween := fish.create_tween()
	tween.tween_method(_fish_arc.bind(fish, spot, land, side), 0.0, 1.0, 0.55)
	tween.tween_callback(ripple.bind(land, 6.0))
	tween.tween_callback(Sfx.play_at.bind("fish_splash", land, -6.0))
	tween.tween_callback(fish.queue_free)


func _fish_arc(t: float, fish: Sprite2D, from: Vector2, to: Vector2, side: float) -> void:
	fish.position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * 16.0)
	fish.rotation = (t - 0.5) * 1.6 * side


# ---------------------------------------------------------------- ważki
func _process_dragonflies(delta: float) -> void:
	_dragonfly_check -= delta
	if _dragonfly_check > 0.0:
		return
	_dragonfly_check = 0.7
	for fly in _dragonflies.duplicate():
		if not is_instance_valid(fly):
			_dragonflies.erase(fly)
		elif fly.global_position.distance_to(_player.global_position) > 420.0:
			_dragonflies.erase(fly)
			fly.queue_free()
	if _dragonflies.size() >= DRAGONFLIES_MAX:
		return
	var spot := random_water_near(_player.global_position, 2.0, 12.0, 12)
	if spot.is_finite():
		var fly := Dragonfly.new()
		entities.add_child(fly)
		fly.setup(self, spot)
		_dragonflies.append(fly)


## Krąg na wodzie: rośnie i blednie.
class Ripple:
	extends Node2D
	var max_radius := 8.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta / 0.9
		if _t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := max_radius * (0.3 + 0.7 * _t)
		var color := Color(0.85, 0.95, 1.0, 0.6 * (1.0 - _t))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 20, color, 1.0)
