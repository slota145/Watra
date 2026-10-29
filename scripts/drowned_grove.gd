class_name DrownedGrove
extends Node
## Topielcze Uroczysko - zamglony, martwy las nad czarną wodą w lewym dolnym rogu rozlewisk.
## Sadzawki (płycizna z błotnistym brzegiem), w których czają się utopce, nad wodą dryfują
## błędne ogniki, na brzegach śpiewają topielice. Zamiast zwykłych drzew - martwe, poczerniałe,
## z brodami mchu; tu i ówdzie zatopione krzyże i spróchniałe pnie. Pośrodku największa
## sadzawka z wysepką - leże Wodnika, z garnkami, pod którymi trzyma dusze topielców,
## i zbutwiałą łodzią. Nad uroczyskiem wisi mrok i snuje się mgła.
##
## Planowane przed ułożeniem kafelków rozlewisk (woda, rezerwacje), budowane po nich.

const TILE := 16
const POOLS := 7
const DEAD_TREES: Array[Texture2D] = [preload("res://assets/drowned/drowned_tree_0.png"), preload("res://assets/drowned/drowned_tree_1.png")]
const CROSS := preload("res://assets/drowned/sunken_cross.png")
const STUMP := preload("res://assets/drowned/rotten_stump.png")
const SOUL_JARS := preload("res://assets/drowned/soul_jars.png")
const BOAT := preload("res://assets/drowned/sunken_boat.png")
const SHADE := Color(0.02, 0.06, 0.05, 0.5)
const MAP_SHADE := Color(0.04, 0.1, 0.08)
const FOG_PATCHES := 18

var w  # świat
var center := Vector2.ZERO
var radii := Vector2(30, 23)
var _pools: Array[Vector2] = []
var _pool_radius: Array[float] = []
var _fog: Array[Sprite2D] = []
var _fog_drift: Array[Vector2] = []


func plan(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	center = Vector2(size.x * 0.21, size.y * 0.79)
	# leże Wodnika: duża sadzawka z błotnistą wysepką pośrodku
	_make_pool(center, 8.5)
	for cell in w._cells_in_radius(center, 2.8):
		w._water[cell] = "mud"
	_pools.append(center)
	_pool_radius.append(8.5)
	var base := rng.randf() * TAU
	for i in POOLS - 1:
		var angle := base + TAU * i / (POOLS - 1) + rng.randf_range(-0.25, 0.25)
		var spot := center + Vector2.from_angle(angle) * radii * rng.randf_range(0.55, 0.72)
		spot = spot.clamp(Vector2(10, 10), size - Vector2(10, 10))
		var r := rng.randf_range(3.5, 5.0)
		_make_pool(spot, r)
		_pools.append(spot)
		_pool_radius.append(r)


func _make_pool(at: Vector2, radius: float) -> void:
	for cell in w._cells_in_radius(at, radius + 1.5):
		var d: float = Vector2(cell).distance_to(at) + w._noise.get_noise_2d(cell.x * 3.0, cell.y * 3.0) * 1.2
		if d < radius:
			w._water[cell] = "shallow"
		elif d < radius + 1.2 and not w._water.has(cell):
			w._water[cell] = "bank"
	w._reserve_area(at, radius + 1.0)


## Jak głęboko komórka leży w uroczysku: 0 poza nim, 1 w środku (łagodny brzeg).
func strength(cell: Vector2i) -> float:
	var d := ((Vector2(cell) - center) / radii).length()
	return clampf((1.1 - d) * 3.0, 0.0, 1.0)


func contains(cell: Vector2i) -> bool:
	return strength(cell) > 0.15


## Zamiast zwykłych drzew i krzaków: martwe drzewa, spróchniałe pnie, zatopione krzyże.
func place_land_prop(cell: Vector2i, r: float) -> void:
	if r < 0.07:
		_obstacle(DEAD_TREES[w._rng.randi() % DEAD_TREES.size()], cell, Vector2(8, 5))
	elif r < 0.085:
		_obstacle(STUMP, cell, Vector2(14, 5))
	elif r < 0.095:
		_obstacle(CROSS, cell, Vector2(4, 3))
	else:
		w._maybe_decor(cell, 0.03)


func _obstacle(texture: Texture2D, cell: Vector2i, collision: Vector2) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if w._occupied.has(cell + Vector2i(dx, dy)):
				return
	w._occupied[cell] = true
	var sprite: Sprite2D = w._village_prop(texture, w._cell_to_world(cell), collision)
	sprite.flip_h = w._rng.randf() < 0.5
	w._map_props[cell] = Color("2a2420")


func build() -> void:
	var rng: RandomNumberGenerator = w._rng
	var lair := center * TILE
	# leże Wodnika
	w._add_goblin_spawn({"type": "wodnik", "position": lair, "sitting": false, "look_at": lair, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": lair, "color": w.MAP_BOSS, "size": 4.0})
	for i in 3:
		var angle := -PI / 2.0 + (i - 1) * 0.9
		w._village_prop(SOUL_JARS, lair + Vector2.from_angle(angle) * Vector2(30, 22), Vector2(26, 5))
	w._village_prop(BOAT, lair + Vector2(-96, 40))
	w._village_prop(CROSS, lair + Vector2(80, -60))
	for i in 2:
		var pos := lair + Vector2(-40 + i * 80, 46)
		w._add_goblin_spawn({"type": "rusalka", "position": pos, "sitting": false, "look_at": lair})
	# sadzawki: utopce pod wodą, ogniki nad nią, topielice na brzegach
	for p in _pools.size():
		var pool := _pools[p] * TILE
		var r := _pool_radius[p] * TILE
		var drowners := 8 if p == 0 else rng.randi_range(6, 8)
		for k in drowners:
			var spot := _water_spot(pool, r * 0.75 if p > 0 else r * 0.85, r * 0.45 if p == 0 else 0.0, rng)
			w._add_goblin_spawn({"type": "drowner", "position": spot, "sitting": false, "look_at": pool})
		if p > 0:
			for k in rng.randi_range(1, 2):
				var spot := pool + Vector2.from_angle(rng.randf() * TAU) * r * 0.5
				w._add_goblin_spawn({"type": "wisp", "position": spot, "sitting": false, "look_at": pool})
			if p % 2 == 1:
				var bank := pool + Vector2.from_angle(rng.randf() * TAU) * (r + 18.0)
				w._add_goblin_spawn({"type": "rusalka", "position": bank, "sitting": false, "look_at": pool})
			if rng.randf() < 0.7:
				w._village_prop(CROSS, pool + Vector2.from_angle(rng.randf() * TAU) * (r + 10.0), Vector2(4, 3))
	_build_shade()
	_build_fog(rng)


## Losowe miejsce na płyciźnie sadzawki (w pikselach), w pierścieniu od `inner` do `outer`.
func _water_spot(pool: Vector2, outer: float, inner: float, rng: RandomNumberGenerator) -> Vector2:
	for i in 30:
		var spot := pool + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(inner, outer)
		if w._water.get(Vector2i(spot / TILE), "") == "shallow":
			return spot
	return pool


func _build_shade() -> void:
	var size: Vector2i = w.map_size
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			image.set_pixel(x, y, Color(SHADE, SHADE.a * strength(Vector2i(x, y))))
	var shade := Sprite2D.new()
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	add_child(shade)


## Mgła: wielkie, miękkie płaty dryfujące powoli nad uroczyskiem.
func _build_fog(rng: RandomNumberGenerator) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.85, 0.95, 0.9, 0.22), Color(0.85, 0.95, 0.9, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 192
	texture.height = 96
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	for i in FOG_PATCHES:
		var fog := Sprite2D.new()
		fog.texture = texture
		fog.position = (center + Vector2.from_angle(rng.randf() * TAU) * radii * sqrt(rng.randf()) * 0.9) * TILE
		fog.scale = Vector2.ONE * rng.randf_range(0.9, 1.6)
		fog.z_index = 21
		add_child(fog)
		_fog.append(fog)
		_fog_drift.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 9.0))


func _process(delta: float) -> void:
	for i in _fog.size():
		var fog := _fog[i]
		fog.position += _fog_drift[i] * delta
		# mgła nie wypływa poza uroczysko - zawraca łagodnie
		var rel := (fog.position / TILE - center) / radii
		if rel.length() > 0.95:
			_fog_drift[i] = (-rel.normalized() * _fog_drift[i].length()).rotated(randf_range(-0.6, 0.6))
