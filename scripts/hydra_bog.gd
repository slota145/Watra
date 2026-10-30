class_name HydraBog
extends Node
## Bagno Hydry - w północno-zachodniej części Rozlewisk, nad drogą od wejścia (pod nią leży Topielcze
## Uroczysko). Czarna, płytka woda (da się brodzić) z błotnistym brzegiem, a wokół kilka mniejszych sadzawek;
## martwe drzewa, kości i szczątki śmiałków; nad bagnem gęsty mrok i trujące opary.
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
## Mniejsze sadzawki wokół głównej: ile, odległość ich środków od brzegu głównej i promienie (w kafelkach).
const SIDE_POOLS := 5
const SIDE_GAP := Vector2(3.0, 7.0)
const SIDE_RADIUS := Vector2(6.0, 8.5)

var w  # świat
var center := Vector2.ZERO
## Sadzawki bagna: [środek, promień] - pierwsza to główna, z Hydrą.
var _pools: Array = []
var _rng := RandomNumberGenerator.new()


func plan(world) -> void:
	w = world
	_rng.seed = hash([w._seed, "hydra_bog"])
	center = _pick_center()
	_make_pool(center, RADIUS)
	# mniejsze sadzawki dookoła: losowy kierunek i odległość, byle zmieściły się przed drogą, rzeką i krawędzią
	# i nie zlały z innymi
	for attempt in 80:
		if _pools.size() > SIDE_POOLS:
			break
		var r := _rng.randf_range(SIDE_RADIUS.x, SIDE_RADIUS.y)
		var spot := center + Vector2.from_angle(_rng.randf() * TAU) * (RADIUS + r + _rng.randf_range(SIDE_GAP.x, SIDE_GAP.y))
		if _room(spot) < r + 4.0:
			continue
		if _pools.any(func(pool: Array) -> bool: return spot.distance_to(pool[0]) < r + pool[1] + 2.5):
			continue
		_make_pool(spot, r)


## Środek bagna: miejsce nad drogą (po stronie wejścia, na zachód od rzeki) najdalej od drogi, rzeki
## i krawędzi mapy - przeszukujemy siatkę w lewej górnej części krainy.
func _pick_center() -> Vector2:
	var size := Vector2(w.map_size)
	var best := Vector2(size.x * 0.3, size.y * 0.18)
	var best_room := -INF
	for y in range(int(size.y * 0.08), int(size.y * 0.45), 2):
		for x in range(int(size.x * 0.08), int(size.x * 0.55), 2):
			var p := Vector2(x, y)
			if p.y > _road_y_at(p.x):
				continue
			var room := _room(p)
			if room > best_room:
				best_room = room
				best = p
	return best


## Ile miejsca jest wokół punktu: odległość do drogi, rzeki i krawędzi mapy (z pasem lasu przy granicy).
func _room(p: Vector2) -> float:
	var size := Vector2(w.map_size)
	var edge: float = w.border_thickness + 3.0
	var room := minf(minf(p.x, p.y), minf(size.x - p.x, size.y - p.y)) - edge
	room = minf(room, Road.distance_to(p, w._road) - 3.0)
	return minf(room, Road.distance_to(p, w._river) - 4.0)


## Wysokość drogi w danej kolumnie (najwyższy punkt drogi w pobliżu) - bagno leży nad nią.
func _road_y_at(x: float) -> float:
	var best := INF
	for point: Vector2 in w._road:
		if absf(point.x - x) < 1.0:
			best = minf(best, point.y)
	return best


## Sadzawka: płytka czarna woda, błotnisty pas (w mniejszych węższy) i brzeg.
func _make_pool(at: Vector2, radius: float) -> void:
	var mud := 3.0 if _pools.is_empty() else 1.5
	for cell in w._cells_in_radius(at, radius + 2.0):
		var d: float = Vector2(cell).distance_to(at) + w._noise.get_noise_2d(cell.x * 2.5, cell.y * 2.5) * 2.0
		if d < radius - mud:
			w._water[cell] = "shallow"
		elif d < radius:
			w._water[cell] = "mud"
		elif d < radius + 1.2 and not w._water.has(cell):
			w._water[cell] = "bank"
	w._reserve_area(at, radius + 2.0)
	_pools.append([at, radius])


## Czy komórka leży w bagnie - zamiast zwykłych drzew rosną tu martwe (jak w Topielczym Uroczysku).
func contains(cell: Vector2i) -> bool:
	return strength(cell) > 0.15


## Jak głęboko komórka leży w bagnie (0 poza nim) - mrok na mapie i w świecie.
func strength(cell: Vector2i) -> float:
	var best := 0.0
	for pool: Array in _pools:
		var r: float = pool[1]
		best = maxf(best, clampf((1.15 - Vector2(cell).distance_to(pool[0]) / (r + 4.0)) * 3.0, 0.0, 1.0))
	return best


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
	# wokół mniejszych sadzawek martwe drzewa, kości i szczątki
	for p in range(1, _pools.size()):
		var at: Vector2 = _pools[p][0] * TILE
		var r: float = _pools[p][1]
		for i in 6:
			var angle := TAU * i / 6.0 + _rng.randf_range(-0.3, 0.3)
			var pos := at + Vector2.from_angle(angle) * (r + _rng.randf_range(0.5, 2.0)) * TILE
			var sprite: Sprite2D = w._village_prop(DEAD_TREES[i % 2] if i % 3 != 0 else STUMP, pos, Vector2(10, 5))
			sprite.flip_h = _rng.randf() < 0.5
		w._village_prop(BONES if p % 2 == 0 else SKULL_TOTEM, at + Vector2.from_angle(_rng.randf() * TAU) * r * 0.5 * TILE)
		var remains := Sprite2D.new()
		remains.texture = REMAINS
		remains.hframes = 6
		remains.frame = _rng.randi() % 6
		remains.position = at + Vector2.from_angle(_rng.randf() * TAU) * r * 0.6 * TILE
		w.entities.add_child(remains)
	_build_shade()
	# trujące opary nad wodą - nad główną sadzawką i nad każdą mniejszą
	for i in 5 + _pools.size() - 1:
		var fumes := CPUParticles2D.new()
		if i < 5:
			fumes.position = c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, RADIUS * 0.6) * TILE
		else:
			fumes.position = _pools[i - 4][0] * TILE
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
	var lo := center
	var hi := center
	for pool: Array in _pools:
		var r: float = pool[1] + 6.0
		lo = lo.min(pool[0] - Vector2(r, r))
		hi = hi.max(pool[0] + Vector2(r, r))
	var origin := Vector2i(lo.floor())
	var extent := Vector2i((hi - lo).ceil())
	var image := Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	for y in extent.y:
		for x in extent.x:
			image.set_pixel(x, y, Color(SHADE, SHADE.a * strength(origin + Vector2i(x, y))))
	var shade := Sprite2D.new()
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.position = Vector2(origin * TILE)
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	w.add_child(shade)
