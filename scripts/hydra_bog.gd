class_name HydraBog
extends Node
## Bagno Hydry - na zachodnim skraju Rozlewisk, pod drogą od wejścia. Czarna, płytka woda (da się brodzić)
## z błotnistym brzegiem, martwe drzewa, kości i szczątki śmiałków; nad bagnem gęsty mrok i trujące opary.
## Pośrodku czeka Hydra (poziom 46 - najsilniejszy boss świata, z ostrzeżeniem dla zbyt słabych).
## Losowane osobnym ziarnem, żeby reszta rozlewisk wyglądała jak dawniej. Planowane przed ułożeniem
## kafelków (woda, rezerwacje), budowane na końcu (Hydra jest ostatnim miejscem potworów - numery
## dawnych miejsc w zapisach się nie zmieniają).

const TILE := 16
const LEVEL := 46
const DEAD_TREES: Array[Texture2D] = [preload("res://assets/drowned/drowned_tree_0.png"), preload("res://assets/drowned/drowned_tree_1.png")]
const STUMP := preload("res://assets/drowned/rotten_stump.png")
const BONES := preload("res://assets/ancient/bone_pile.png")
const REMAINS := preload("res://assets/ancient/remains.png")
const SKULL_TOTEM := preload("res://assets/ancient/skull_totem.png")
const SHADE := Color(0.03, 0.07, 0.03, 0.45)
const RADIUS := 13.0

var w  # świat
var center := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func plan(world) -> void:
	w = world
	_rng.seed = hash([w._seed, "hydra_bog"])
	center = Vector2(w.map_size.x * 0.09, w.map_size.y * 0.37)
	for cell in w._cells_in_radius(center, RADIUS + 2.0):
		var d: float = Vector2(cell).distance_to(center) + w._noise.get_noise_2d(cell.x * 2.5, cell.y * 2.5) * 2.0
		if d < RADIUS - 3.0:
			w._water[cell] = "shallow"
		elif d < RADIUS:
			w._water[cell] = "mud"
		elif d < RADIUS + 1.2 and not w._water.has(cell):
			w._water[cell] = "bank"
	w._reserve_area(center, RADIUS + 2.0)


## Jak głęboko komórka leży w bagnie (0 poza nim) - mrok na mapie i w świecie.
func strength(cell: Vector2i) -> float:
	return clampf((1.15 - Vector2(cell).distance_to(center) / (RADIUS + 4.0)) * 3.0, 0.0, 1.0)


func build() -> void:
	var c := center * TILE
	# martwe drzewa i pnie na brzegu, kości i szczątki śmiałków w błocie
	for i in 14:
		var angle := TAU * i / 14.0 + _rng.randf_range(-0.15, 0.15)
		var pos := c + Vector2.from_angle(angle) * (RADIUS + _rng.randf_range(0.5, 2.5)) * TILE
		var sprite: Sprite2D = w._village_prop(DEAD_TREES[i % 2] if i % 3 != 0 else STUMP, pos, Vector2(10, 5))
		sprite.flip_h = _rng.randf() < 0.5
	for i in 8:
		var pos := c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5.0, RADIUS - 1.0) * TILE
		w._village_prop(BONES if i % 2 == 0 else SKULL_TOTEM, pos)
	for i in 6:
		var remains := Sprite2D.new()
		remains.texture = REMAINS
		remains.hframes = 6
		remains.frame = _rng.randi() % 6
		remains.position = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(4.0, RADIUS) * TILE
		w.entities.add_child(remains)
	_build_shade()
	# trujące opary nad wodą
	for i in 5:
		var fumes := CPUParticles2D.new()
		fumes.position = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, RADIUS * 0.6) * TILE
		fumes.amount = 10
		fumes.lifetime = 3.0
		fumes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fumes.emission_rect_extents = Vector2(50, 30)
		fumes.gravity = Vector2(0, -8)
		fumes.initial_velocity_max = 5.0
		fumes.scale_amount_min = 2.0
		fumes.scale_amount_max = 4.0
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(0.5, 0.9, 0.3, 0.0), Color(0.5, 0.9, 0.3, 0.25), Color(0.5, 0.9, 0.3, 0.0)])
		fumes.color_ramp = ramp
		fumes.z_index = 19
		w.add_child(fumes)
	w._add_goblin_spawn({"type": "hydra", "position": c, "sitting": false, "look_at": c, "respawn": w.boss_respawn_time,
			"level": LEVEL, "warn": true})
	w._map_markers.append({"position": c, "color": w.MAP_BOSS, "size": 5.0})


func _build_shade() -> void:
	var size := int(RADIUS * 2.0 + 10.0)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var origin := Vector2i(center) - Vector2i(size / 2, size / 2)
	for y in size:
		for x in size:
			image.set_pixel(x, y, Color(SHADE, SHADE.a * strength(origin + Vector2i(x, y))))
	var shade := Sprite2D.new()
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.position = Vector2(origin * TILE)
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	w.add_child(shade)
