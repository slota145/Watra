class_name ForestCemetery
extends Node
## Leśny Cmentarz - najgroźniejsza kraina (poziomy 32-40), na północ od Prastarego Lasu (wejście ścieżką od
## jego rozstajów). Mroczny, zamglony cmentarz w martwym lesie: kwatery grobów za żelaznymi płotami
## (nagrobki, krzyże, otwarte groby), kurhany, mauzolea i krypty, kamienne anioły, latarnie z zielonym
## ogniem. Droga prowadzi od wejścia do zrujnowanej kaplicy (kapliczka odrodzenia). Siedliska:
## - szkielety na całym cmentarzu - im bliżej mauzoleum nekromanty (północny zachód), tym gęściej; podczas
##   walki przy grobach wypełzają z nich kolejne szkielety,
## - na wschodzie trupowisko: dół pełen rozkopanych grobów i trupów, trupojady i zombie,
##   a w jego głębi kolosalny ghul Gnilec.

const TILE := 16
const MAP_GRASS := Color("2e3a2c")
const MAP_SOIL := Color("2a2220")
const MAP_PATH := Color("5a5248")
const MAP_GRAVE := Color("8a8a90")
const MAP_FENCE := Color("404048")
const MAP_CRYPT := Color("6a6470")
## Mrok nad cmentarzem (chłodny, sinawy), gęstszy przy nekromancie i w trupowisku.
const SHADE := Color(0.03, 0.03, 0.09, 0.32)
const FOG := Color(0.75, 0.8, 0.85, 0.06)
const GREEN_FIRE := Color(0.45, 1.0, 0.55)

## Rekwizyty z paczki (tools/cemetery_sheets.py).
const GRAVESTONE := preload("res://assets/cemetery/gravestone.png")
const CELTIC_CROSS := preload("res://assets/cemetery/celtic_cross.png")
const WOOD_CROSS := preload("res://assets/cemetery/wood_cross.png")
const OPEN_GRAVE := preload("res://assets/cemetery/open_grave.png")
const GRAVE_MOUND := preload("res://assets/cemetery/grave_mound.png")
const FENCE := preload("res://assets/cemetery/fence.png")
const FENCE_BROKEN := preload("res://assets/cemetery/fence_broken.png")
const ANGEL := preload("res://assets/cemetery/angel.png")
const SARCOPHAGUS := preload("res://assets/cemetery/sarcophagus.png")
const DEAD_TREE := preload("res://assets/cemetery/dead_tree.png")
const SKULLS := preload("res://assets/cemetery/skulls.png")
const LANTERN := preload("res://assets/cemetery/lantern.png")
const OBELISK := preload("res://assets/cemetery/obelisk.png")
const FALLEN_STONE := preload("res://assets/cemetery/fallen_stone.png")
const RITUAL := preload("res://assets/cemetery/ritual.png")
const CORPSES := preload("res://assets/cemetery/corpses.png")
const MAUSOLEUM := preload("res://assets/cemetery/mausoleum.png")
const BARROW := preload("res://assets/cemetery/barrow.png")
const CHAPEL := preload("res://assets/cemetery/chapel.png")
const CRYPT := preload("res://assets/cemetery/crypt.png")
const PINE := preload("res://scenes/props/tree_pine.tscn")
const HEADSTONES: Array[Texture2D] = [GRAVESTONE, GRAVESTONE, CELTIC_CROSS, WOOD_CROSS, WOOD_CROSS, GRAVE_MOUND, FALLEN_STONE]

const PLOTS := 22
const BARROWS := 6
const GHOUL_GROUPS := 9
## Groby budzą się w walce: co ile sekund kwatera może wypuścić szkielety i ile naraz może ich chodzić.
const RISE_COOLDOWN := 7.0
const RISE_COOLDOWN_NEAR := 4.0
const MAX_RISEN := 8
const MAX_RISEN_NEAR := 14
const SKELETON_SCENES := ["res://scenes/skeleton.tscn", "res://scenes/skeleton.tscn", "res://scenes/skeleton_archer.tscn"]

var w  # świat
var entry := Vector2.ZERO
var chapel := Vector2.ZERO
var necromancer := Vector2.ZERO
var pit := Vector2.ZERO
var ghoul_lair := Vector2.ZERO
## Kwatery: [Rect2i w kafelkach, Array[Vector2] grobów w pikselach, pozostały czas odnowienia]
var plots: Array = []
var _barrows: Array[Vector2] = []
var _plot_cells := {}
var _corners := {}
var _risen: Array = []
var _player: Node2D
var _check := 0.0


func generate(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	_player = w.player
	Goblin.safe_zone = Rect2()
	entry = Vector2(size.x * 0.4, size.y - 1.0)
	chapel = Vector2(size.x * 0.43, size.y * 0.6)
	necromancer = Vector2(size.x * 0.2, size.y * 0.18)
	pit = Vector2(size.x * 0.74, size.y * 0.45)
	ghoul_lair = Vector2(size.x * 0.85, size.y * 0.2)

	w._road = Road.wiggle(entry, chapel + Vector2(0, 6), rng, 4.0, 9.0)
	w._road.append_array(Road.wiggle(chapel + Vector2(0, 6), necromancer + Vector2(10, 12), rng, 5.0, 10.0))
	_mark_path(w._road, 1.3, 2.6)
	_mark_path(Road.wiggle(chapel, pit + Vector2(-14, 4), rng, 5.0, 10.0), 1.0, 2.2)

	w._reserve_area(chapel + Vector2(-5, -3), 5.0)
	w._reserve_area(chapel + Vector2(5, -3), 3.0)
	w._reserve_area(necromancer, 11.0)
	w._reserve_area(pit, 17.0)
	w._reserve_area(ghoul_lair, 10.0)
	_plan_barrows(rng)
	_plan_plots(rng)

	_build_ground(rng)
	_place_nature(rng)
	w._build_bounds()
	for plot: Array in plots:
		_build_plot(rng, plot)
	for barrow in _barrows:
		_build_barrow(rng, barrow)
	_build_chapel(rng)
	_build_necromancer_lair(rng)
	_build_ghoul_pit(rng)
	_build_atmosphere(rng)

	var shrine: Node2D = w.SHRINE.instantiate()
	shrine.position = (chapel + Vector2(5.0, -2.0)) * TILE
	w.entities.add_child(shrine)
	w._register_shrine("grave_chapel", shrine.position)
	w._map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	w._spawn_point = shrine.position + Vector2(0, 20)
	w._add_exit(Rect2(entry.x - 4.5, size.y - 3.5, 9, 3.5), "ancient", "from:cemetery", entry + Vector2(3.0, -4.0))
	w._arrivals["from:ancient"] = (entry + Vector2(0, -6.0)) * TILE


func _mark_path(points: PackedVector2Array, road: float, clear: float) -> void:
	for point in points:
		for cell in w._cells_in_radius(point, road):
			w._road_cells[cell] = true
		for cell in w._cells_in_radius(point, clear):
			w._road_clear[cell] = true


# ---------------------------------------------------------------- plan
func _plan_barrows(rng: RandomNumberGenerator) -> void:
	var area := Rect2(Vector2(14, 14), Vector2(w.map_size) - Vector2(28, 28))
	var ok := func(tile: Vector2) -> bool:
		for c in w._cells_in_radius(tile, 6.0):
			if w._reserved.has(c) or w._road_clear.has(c):
				return false
		return true
	for i in BARROWS:
		var tile: Vector2 = w._pick_spread(area, _barrows, ok)
		if tile.is_finite():
			_barrows.append(tile)
			w._reserve_area(tile, 6.0)


## Kwatery grobów: prostokąty z żelaznym płotem, z odstępem na alejki między nimi.
func _plan_plots(rng: RandomNumberGenerator) -> void:
	var margin: int = w.border_thickness + 4
	for attempt in 900:
		if plots.size() >= PLOTS:
			break
		var pw := rng.randi_range(8, 16)
		var ph := rng.randi_range(6, 11)
		var rect := Rect2i(rng.randi_range(margin, w.map_size.x - margin - pw), rng.randi_range(margin, w.map_size.y - margin - ph), pw, ph)
		var free := true
		for cy in range(rect.position.y - 2, rect.end.y + 2):
			for cx in range(rect.position.x - 2, rect.end.x + 2):
				var c := Vector2i(cx, cy)
				if w._reserved.has(c) or w._road_clear.has(c) or _plot_cells.has(c):
					free = false
					break
			if not free:
				break
		if not free:
			continue
		plots.append([rect, [], 0.0])
		for cy in range(rect.position.y - 1, rect.end.y + 1):
			for cx in range(rect.position.x - 1, rect.end.x + 1):
				_plot_cells[Vector2i(cx, cy)] = true


# ---------------------------------------------------------------- teren
func _build_ground(rng: RandomNumberGenerator) -> void:
	var patch := FastNoiseLite.new()
	patch.seed = rng.randi()
	patch.frequency = 0.08
	var soil := {}
	for cell in w._cells_in_radius(pit, 15.0):
		soil[cell] = true
	for cell in w._cells_in_radius(ghoul_lair, 8.0):
		soil[cell] = true
	for cell in w._cells_in_radius(necromancer + Vector2(0, 3), 7.0):
		soil[cell] = true
	for y in w.map_size.y + 1:
		for x in w.map_size.x + 1:
			var corner := Vector2i(x, y)
			var kind := "c_grass"
			var n := patch.get_noise_2d(x, y)
			if _touches(corner, w._road_cells) >= 2:
				kind = "c_path"
			elif _touches(corner, soil) >= 2 and n > -0.35:
				kind = "c_soil"
			elif _touches(corner, _plot_cells) >= 2 and n > 0.1:
				kind = "c_soil"
			elif n > 0.38:
				kind = "c_leaves"
			_corners[corner] = kind
	w._soft_corners = _corners
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			w.ground.set_cell(cell, 0, Vector2i(0, w.FOREST_WANG_ROW))
			if soil.has(cell):
				w._map_props[cell] = MAP_SOIL
			elif not w._road_cells.has(cell):
				w._map_props[cell] = MAP_GRASS


func _touches(corner: Vector2i, cells: Dictionary) -> int:
	var n := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		n += int(cells.has(corner + d))
	return n


## Martwy las: gęste brzegi, martwe drzewa i zagajniki świerków między kwaterami.
func _place_nature(rng: RandomNumberGenerator) -> void:
	var groves := FastNoiseLite.new()
	groves.seed = rng.randi()
	groves.frequency = 0.05
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var edge_dist := mini(mini(x, y), mini(w.map_size.x - 1 - x, w.map_size.y - 1 - y))
			if w._road_clear.has(cell):
				continue
			if edge_dist < w.border_thickness + 1:
				if rng.randf() < 0.85 - edge_dist * 0.12:
					_tree(rng, cell, 1)
				continue
			if w._reserved.has(cell) or _plot_cells.has(cell):
				continue
			var r := rng.randf()
			if groves.get_noise_2d(x, y) > 0.4 and r < 0.14:
				_tree(rng, cell, 1)
			elif r < 0.008 and _free(cell, 1):
				_mark(cell, 1)
				_prop(DEAD_TREE, w._cell_to_world(cell), Vector2(12, 6)).flip_h = rng.randf() < 0.5
				w._map_props[cell] = w.MAP_TREE
			elif r < 0.012 and _free(cell, 0):
				_mark(cell, 0)
				_prop([FALLEN_STONE, SKULLS, GRAVE_MOUND].pick_random(), w._cell_to_world(cell))


func _tree(rng: RandomNumberGenerator, cell: Vector2i, spacing: int) -> void:
	if rng.randf() < 0.35:
		if _free(cell, 1):
			_mark(cell, 1)
			_prop(DEAD_TREE, w._cell_to_world(cell), Vector2(12, 6)).flip_h = rng.randf() < 0.5
			w._map_props[cell] = w.MAP_TREE
		return
	w._try_place(PINE, cell, spacing)
	if w._occupied.has(cell):
		w._map_props[cell] = w.MAP_PINE


func _free(cell: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var c := cell + Vector2i(dx, dy)
			if w._occupied.has(c) or w._reserved.has(c) or w._road_clear.has(c):
				return false
	return true


func _mark(cell: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			w._occupied[cell + Vector2i(dx, dy)] = true


# ---------------------------------------------------------------- kwatery
func _build_plot(rng: RandomNumberGenerator, plot: Array) -> void:
	var rect: Rect2i = plot[0]
	var px := Rect2(Vector2(rect.position * TILE), Vector2(rect.size * TILE))
	var graves: Array = plot[1]
	# rzędy grobów
	for row in range(1, rect.size.y, 3):
		for col in range(1, rect.size.x - 1, 2):
			if rng.randf() < 0.18:
				continue
			var pos := px.position + Vector2(col + 0.5, row + 1.0) * TILE + Vector2(rng.randf_range(-2, 2), 0)
			var tex: Texture2D = OPEN_GRAVE if rng.randf() < 0.1 else HEADSTONES[rng.randi() % HEADSTONES.size()]
			var sprite := _prop(tex, pos, Vector2(14, 5) if tex != OPEN_GRAVE and tex != GRAVE_MOUND else Vector2.ZERO)
			sprite.flip_h = rng.randf() < 0.5
			graves.append(pos + Vector2(0, 10))
			w._map_props[Vector2i(pos / TILE)] = MAP_GRAVE
	# pomnik w środku większych kwater
	if rect.size.x >= 12 and rng.randf() < 0.6:
		_prop([ANGEL, OBELISK, SARCOPHAGUS].pick_random(), px.get_center() + Vector2(0, 8), Vector2(22, 8))
	# żelazny płot u góry i u dołu (z bramką i wyłomami), latarnie w rogach
	for side in [-1, 1]:
		var y := px.position.y - 4.0 if side < 0 else px.end.y + 6.0
		var step := float(FENCE.get_width()) - 1.0
		var x := px.position.x + step / 2.0
		var gate := px.position.x + px.size.x * rng.randf_range(0.3, 0.7)
		while x < px.end.x - step / 2.0 + 1.0:
			if absf(x - gate) > step * 0.8:
				var broken := rng.randf() < 0.18
				if not (broken and rng.randf() < 0.4):
					_prop(FENCE_BROKEN if broken else FENCE, Vector2(x, y), Vector2(step, 4))
					w._map_props[Vector2i(Vector2(x, y) / TILE)] = MAP_FENCE
			x += step
	if rng.randf() < 0.5:
		_lantern(px.position + Vector2(-6, px.size.y + 6))
	# szkielety: im bliżej nekromanty, tym liczniej
	var center := px.get_center() / TILE
	var near := clampf(1.0 - center.distance_to(necromancer) / 110.0, 0.0, 1.0)
	var groups := 1 + roundi(near * 2.0)
	for g in groups:
		var spot := px.position + Vector2(rng.randf_range(0.2, 0.8) * px.size.x, rng.randf_range(0.2, 0.8) * px.size.y)
		_skeleton_group(rng, spot, rng.randi_range(2, 3) + roundi(near * 3.0), near)


func _skeleton_group(rng: RandomNumberGenerator, center: Vector2, n: int, near: float) -> void:
	for k in n:
		var roll := rng.randf()
		var kind := "skeleton_knight" if roll < 0.08 + near * 0.1 else "skeleton_archer" if roll < 0.35 else "skeleton"
		var pos := center + Vector2(rng.randf_range(-24, 24), rng.randf_range(-18, 18))
		w._add_goblin_spawn({"type": kind, "position": pos, "sitting": false, "look_at": center})


func _build_barrow(rng: RandomNumberGenerator, tile: Vector2) -> void:
	var pos := tile * TILE
	_prop(BARROW, pos, Vector2(80, 24))
	for dy in range(-2, 1):
		for dx in range(-3, 4):
			w._map_props[Vector2i(tile) + Vector2i(dx, dy)] = Color("3a4a32")
	for i in 3:
		_prop(OBELISK if i == 0 else FALLEN_STONE, pos + Vector2.from_angle(rng.randf_range(0.2, PI - 0.2)) * Vector2(80, 50), Vector2(14, 6))
	# strażnicy kurhanu: rycerze-szkielety
	for k in 2:
		var at := pos + Vector2(rng.randf_range(-50, 50), rng.randf_range(30, 56))
		w._add_goblin_spawn({"type": "skeleton_knight", "position": at, "sitting": false, "look_at": pos})
	w._add_goblin_spawn({"type": "skeleton_archer", "position": pos + Vector2(rng.randf_range(-40, 40), 40), "sitting": false, "look_at": pos})


func _build_chapel(rng: RandomNumberGenerator) -> void:
	var pos := (chapel + Vector2(-5.0, -2.0)) * TILE
	_prop(CHAPEL, pos, Vector2(90, 26))
	for dy in range(-4, 1):
		for dx in range(-3, 4):
			w._map_props[Vector2i(pos / TILE) + Vector2i(dx, dy)] = MAP_CRYPT
	_lantern(pos + Vector2(60, 20))
	_lantern(pos + Vector2(-60, 20))


func _build_necromancer_lair(rng: RandomNumberGenerator) -> void:
	var center := necromancer * TILE
	_prop(MAUSOLEUM, center + Vector2(0, -56), Vector2(110, 30))
	for dy in range(-6, -1):
		for dx in range(-4, 5):
			w._map_props[Vector2i(center / TILE) + Vector2i(dx, dy)] = MAP_CRYPT
	_floor_prop(RITUAL, center + Vector2(0, 10))
	for i in 6:
		var angle := PI * 0.1 + PI * 0.8 * i / 5.0
		_lantern(center + Vector2.from_angle(angle) * Vector2(120, 80))
	# krypty i nagrobki po bokach mauzoleum (arena przed nim zostaje wolna)
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := center + Vector2(side * rng.randf_range(150, 200), rng.randf_range(-90, -10))
		_prop(CRYPT if i < 2 else [SARCOPHAGUS, OPEN_GRAVE, SKULLS, ANGEL].pick_random(), pos, Vector2(26, 8))
	w._add_goblin_spawn({"type": "necromancer", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})
	# straż przed mauzoleum
	for i in 4:
		var spot := center + Vector2.from_angle(PI * 0.2 + PI * 0.6 * i / 3.0) * 150.0
		_skeleton_group(rng, spot, 4, 1.0)


func _build_ghoul_pit(rng: RandomNumberGenerator) -> void:
	var center := pit * TILE
	for i in 26:
		var pos := center + Vector2.from_angle(rng.randf() * TAU) * Vector2(200, 150) * sqrt(rng.randf())
		_prop([OPEN_GRAVE, OPEN_GRAVE, CORPSES, SKULLS, FALLEN_STONE, WOOD_CROSS].pick_random(), pos).flip_h = rng.randf() < 0.5
	var spots: Array[Vector2] = []
	for i in GHOUL_GROUPS:
		var spot := pit + Vector2.from_angle(TAU * i / GHOUL_GROUPS + rng.randf_range(-0.2, 0.2)) * Vector2(12, 9) * rng.randf_range(0.4, 1.0)
		spots.append(spot)
		for k in rng.randi_range(3, 5):
			var pos := spot * TILE + Vector2(rng.randf_range(-26, 26), rng.randf_range(-20, 20))
			w._add_goblin_spawn({"type": "ghoul" if rng.randf() < 0.55 else "zombie", "position": pos, "sitting": false, "look_at": spot * TILE})
	w._map_markers.append({"position": center, "color": Ghoul.GHOUL_COLOR, "size": 3.0})
	var lair := ghoul_lair * TILE
	for i in 10:
		var pos := lair + Vector2.from_angle(TAU * i / 10.0) * Vector2(110, 80) * rng.randf_range(0.85, 1.1)
		_prop(CORPSES if i % 2 == 0 else SKULLS, pos)
	w._add_goblin_spawn({"type": "colossal_ghoul", "position": lair, "sitting": false, "look_at": lair, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": lair, "color": w.MAP_BOSS, "size": 4.0})


# ---------------------------------------------------------------- klimat
func _build_atmosphere(rng: RandomNumberGenerator) -> void:
	var size: Vector2i = w.map_size
	var shade := Sprite2D.new()
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var p := Vector2(x, y)
			var extra := clampf(1.0 - p.distance_to(necromancer) / 30.0, 0.0, 1.0) * 0.14 \
					+ clampf(1.0 - p.distance_to(pit) / 24.0, 0.0, 1.0) * 0.04
			image.set_pixel(x, y, Color(SHADE, SHADE.a + extra))
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	add_child(shade)
	# mgła: wielkie, miękkie kłęby powoli dryfujące nad ziemią
	var puff := GradientTexture2D.new()
	puff.width = 64
	puff.height = 64
	puff.fill = GradientTexture2D.FILL_RADIAL
	puff.fill_from = Vector2(0.5, 0.5)
	puff.fill_to = Vector2(1.0, 0.5)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	puff.gradient = fade
	for i in 14:
		var fog := CPUParticles2D.new()
		fog.texture = puff
		fog.position = Vector2(rng.randf_range(10, size.x - 10), rng.randf_range(10, size.y - 10)) * TILE
		fog.amount = 6
		fog.lifetime = 14.0
		fog.preprocess = 14.0
		fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fog.emission_rect_extents = Vector2(220, 120)
		fog.gravity = Vector2.ZERO
		fog.direction = Vector2.RIGHT
		fog.spread = 30.0
		fog.initial_velocity_min = 3.0
		fog.initial_velocity_max = 8.0
		fog.scale_amount_min = 2.5
		fog.scale_amount_max = 5.0
		var ramp := Gradient.new()
		ramp.colors = PackedColorArray([Color(FOG, 0.0), FOG, Color(FOG, 0.0)])
		fog.color_ramp = ramp
		fog.z_index = 19
		add_child(fog)
	# zielone ogniki krążące nad grobami
	for i in 12:
		var wisps := CPUParticles2D.new()
		wisps.position = Vector2(rng.randf_range(10, size.x - 10), rng.randf_range(10, size.y - 10)) * TILE
		wisps.amount = 6
		wisps.lifetime = 3.5
		wisps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		wisps.emission_rect_extents = Vector2(90, 50)
		wisps.gravity = Vector2(0, -4)
		wisps.initial_velocity_min = 3.0
		wisps.initial_velocity_max = 8.0
		wisps.spread = 180.0
		wisps.scale_amount_max = 1.6
		var glow := Gradient.new()
		glow.colors = PackedColorArray([Color(GREEN_FIRE, 0.0), Color(GREEN_FIRE, 0.9), Color(GREEN_FIRE, 0.0)])
		wisps.color_ramp = glow
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		wisps.material = additive
		wisps.z_index = 21
		add_child(wisps)


# ---------------------------------------------------------------- pomocnicze
func _prop(texture: Texture2D, pos: Vector2, collision := Vector2.ZERO) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(texture, pos, collision)
	sprite.offset.y += PropSinks.of(texture)
	return sprite


func _floor_prop(texture: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	w.floors.add_child(sprite)
	return sprite


## Latarnia z zielonym płomieniem (świeci i migocze).
func _lantern(pos: Vector2) -> void:
	_prop(LANTERN, pos, Vector2(6, 4))
	w._glow_at(pos + Vector2(0, -26), GREEN_FIRE)


# ---------------------------------------------------------------- groby budzą się w walce
## Co chwilę: gdy gracz walczy przy kwaterze (wróg goni go w pobliżu), z grobów tej kwatery wypełzają szkielety.
## Przy mauzoleum nekromanty groby budzą się częściej i może ich chodzić więcej.
func _process(delta: float) -> void:
	if _player == null or _player.is_dead:
		return
	for plot: Array in plots:
		plot[2] = maxf(plot[2] - delta, 0.0)
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.5
	_risen = _risen.filter(func(s) -> bool: return is_instance_valid(s) and s.state != Goblin.State.DEAD)
	var feet: Vector2 = _player.global_position
	var near := clampf(1.0 - feet.distance_to(necromancer * TILE) / (70.0 * TILE), 0.0, 1.0)
	if _risen.size() >= roundi(lerpf(MAX_RISEN, MAX_RISEN_NEAR, near)) or not _in_combat(feet):
		return
	for plot: Array in plots:
		if plot[2] > 0.0:
			continue
		var rect: Rect2 = Rect2(Vector2(plot[0].position * TILE), Vector2(plot[0].size * TILE)).grow(120.0)
		if not rect.has_point(feet):
			continue
		var graves: Array = plot[1].filter(func(g: Vector2) -> bool: return g.distance_to(feet) > 50.0 and g.distance_to(feet) < 220.0)
		if graves.is_empty():
			continue
		plot[2] = lerpf(RISE_COOLDOWN, RISE_COOLDOWN_NEAR, near)
		for i in 1 + int(randf() < 0.4 + near * 0.4):
			_raise(graves.pick_random())


func _in_combat(feet: Vector2) -> bool:
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		if enemy.state == Goblin.State.CHASE and enemy.global_position.distance_to(feet) < 220.0:
			return true
	return false


func _raise(grave: Vector2) -> void:
	var skeleton: Goblin = load(SKELETON_SCENES.pick_random()).instantiate()
	skeleton.level = Levels.level_at("cemetery", 0.6)
	skeleton.position = grave + Vector2(randf_range(-6, 6), randf_range(2, 8))
	w.entities.add_child(skeleton)
	skeleton.rise()
	_risen.append(skeleton)
