class_name GrainFields
extends Node
## Pola Zbożowe - kraina na zachód od Goblińskiego Lasu (wejście na końcu leśnej drogi, w prawym dolnym rogu).
## Dawny spichlerz okolicy: łany gęstego zboża (rząd zboża to jeden kołyszący się pas - postacie chowają się
## w nim do pasa, a gracz brnie wolniej), ścierniska ze snopkami, zaorane zagony, część pól otoczona
## walącymi się murkami z polnych kamieni, a między nimi opuszczone gospodarstwa (chałupy, stodoły, studnie).
## Droga prowadzi od wejścia do rozstajów przy ruinie wiatraka (kapliczka Starego Młyna). Siedliska:
## - na północy: obozowisko koboldów w łanach (namioty ze skór, ogniska, skrzynie bomb), a za nim
##   barykada Bombardiera,
## - na południowym zachodzie: ryjowisko czerwi polnych (kopce, nory, popękana ziemia) z kraterem
##   Pożeracza Pól,
## - w lewym górnym rogu, najdalej od wejścia: wzgórze, nad którym krąży gryf (zostawione na później).

const TILE := 16
const MAP_GRAIN := Color("c9a54a")
const MAP_STUBBLE := Color("b39a5e")
const MAP_SOIL := Color("7a5a3a")
const MAP_HOUSE := Color("8a6a4a")
const MAP_WALL := Color("8c8778")
const MAP_TENT := Color("a0784a")

const GRAIN := preload("res://assets/fields/grain.png")
const GRAIN_HEIGHT := 30
const GRAIN_VARIANTS := 3
const SWAY := preload("res://shaders/grain_sway.gdshader")
const FARMHOUSE := preload("res://assets/fields/farmhouse.png")
const BARN := preload("res://assets/fields/barn.png")
const WINDMILL := preload("res://assets/fields/windmill.png")
const TENT := preload("res://assets/fields/kobold_tent.png")
const HAYSTACK := preload("res://assets/fields/haystack.png")
const HAY_BALE := preload("res://assets/fields/hay_bale.png")
const SCARECROW := preload("res://assets/fields/scarecrow.png")
const WELL := preload("res://assets/fields/well.png")
const CART := preload("res://assets/fields/cart.png")
const STOOK := preload("res://assets/fields/stook.png")
const TROUGH := preload("res://assets/fields/trough.png")
const PLOUGH := preload("res://assets/fields/plough.png")
const SACKS := preload("res://assets/fields/sacks.png")
const FENCE := preload("res://assets/fields/fence.png")
const WALL := preload("res://assets/fields/wall.png")
const WALL_END := preload("res://assets/fields/wall_end.png")
const RUBBLE := preload("res://assets/fields/rubble.png")
const TOTEM := preload("res://assets/fields/totem.png")
const BOMB_CRATE := preload("res://assets/fields/bomb_crate.png")
const POWDER := preload("res://assets/fields/powder_barrel.png")
const MOUND := preload("res://assets/fields/mound.png")
const HOLE := preload("res://assets/fields/hole.png")
## Drobiazgi (płótno 32x32, rząd klatek): 0 kopiec, 1 nora, 2 popękana ziemia, 3 maki, 4 chabry, 5 kłosy,
## 6 kamyki, 7 osmalenie, 8 lej po bombie, 9 widły, 10 wiadro, 11 pierze, 12 skorupy, 13 kępka, 14 kretowisko, 15 kości.
const DECOR := preload("res://assets/fields/decor.png")
const DECOR_FRAMES := 16
const AERIE := preload("res://assets/mountains/aerie.png")
const GRYF_BONES := preload("res://assets/mountains/bone_pile.png")
const CAIRN := preload("res://assets/mountains/cairn.png")
const OAK := preload("res://scenes/props/tree_oak.tscn")
const PINE := preload("res://scenes/props/tree_pine.tscn")
const BUSH := preload("res://scenes/props/bush.tscn")
const CAMPFIRE := preload("res://scenes/props/campfire.tscn")

const FIELD_COUNT := 34
const FARMS := 6
const KOBOLD_GROUPS := 9
const WORMS := 26
## Gracz brnie przez łan wolniej (mnożnik prędkości).
const GRAIN_SLOW := 0.82

var w  # świat
var entry := Vector2.ZERO
var cross := Vector2.ZERO
var kobolds := Vector2.ZERO
var bombardier := Vector2.ZERO
var worms := Vector2.ZERO
var worm_lair := Vector2.ZERO
var gryf_hill := Vector2.ZERO
## [Rect2i pola w kafelkach, rodzaj: "grain" / "stubble" / "soil"]
var fields: Array = []
var _farms: Array[Vector2] = []
## Teren narożników (Vector2i -> nazwa terenu SoftGround); brak wpisu = trawa.
var _corners := {}
var _yard_cells := {}
var _field_cells := {}
## Łany w pikselach (do spowalniania gracza).
var _grain_rects: Array[Rect2] = []
var _sway: ShaderMaterial
var _player: Node2D


func generate(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	_player = w.player
	Goblin.safe_zone = Rect2()
	entry = Vector2(size.x - 1.0, size.y - 3.0)
	cross = Vector2(size.x * 0.58, size.y * 0.6)
	kobolds = Vector2(size.x * 0.56, size.y * 0.26)
	bombardier = Vector2(size.x * 0.4, size.y * 0.1)
	worms = Vector2(size.x * 0.3, size.y * 0.72)
	worm_lair = Vector2(size.x * 0.1, size.y * 0.83)
	gryf_hill = Vector2(size.x * 0.12, size.y * 0.26)
	_sway = ShaderMaterial.new()
	_sway.shader = SWAY

	# droga od wejścia do rozstajów i dalej do koboldów; ścieżki do czerwi i na wzgórze gryfa
	w._road = Road.wiggle(entry, cross, rng, 5.0, 11.0)
	w._road.append_array(Road.wiggle(cross, kobolds + Vector2(0, 12), rng, 5.0, 11.0))
	_mark_path(w._road, 1.3, 2.8)
	_mark_path(Road.wiggle(cross, worms + Vector2(14, -4), rng, 5.0, 11.0), 0.9, 2.2)
	_mark_path(Road.wiggle(cross, gryf_hill + Vector2(16, 6), rng, 5.0, 11.0), 0.9, 2.2)

	var shrine_tile := cross + Vector2(4.5, -4.0)
	w._reserve_area(shrine_tile, 3.0)
	w._reserve_area(cross + Vector2(-6.0, -6.0), 4.0)  # wiatrak
	w._reserve_area(kobolds, 10.0)
	w._reserve_area(bombardier, 9.0)
	w._reserve_area(worm_lair, 9.0)
	w._reserve_area(gryf_hill, 14.0)
	_plan_farms(rng)
	_plan_fields(rng)

	_build_ground(rng)
	_place_nature(rng)
	w._build_bounds()
	for farm in _farms:
		_build_farm(rng, farm)
	for field: Array in fields:
		_build_field(rng, field[0], field[1])
	_build_kobold_camp(rng)
	_build_bombardier_lair(rng)
	_build_worm_grounds(rng)
	_build_gryf_hill(rng)

	var shrine: Node2D = w.SHRINE.instantiate()
	shrine.position = shrine_tile * TILE
	w.entities.add_child(shrine)
	w._register_shrine("old_mill", shrine.position)
	w._map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	_prop(WINDMILL, (cross + Vector2(-6.0, -5.0)) * TILE, Vector2(54, 18))
	w._spawn_point = shrine.position + Vector2(0, 20)
	w._add_exit(Rect2(size.x - 3.5, size.y - 9, 3.5, 9), "forest", "from:fields", entry + Vector2(-4.0, -2.5))
	w._arrivals["from:forest"] = w._road_point_from_edge(true, 7.0)


func _mark_path(points: PackedVector2Array, road: float, clear: float) -> void:
	for point in points:
		for cell in w._cells_in_radius(point, road):
			w._road_cells[cell] = true
		for cell in w._cells_in_radius(point, clear):
			w._road_clear[cell] = true


# ---------------------------------------------------------------- plan
func _plan_farms(rng: RandomNumberGenerator) -> void:
	var area := Rect2(Vector2(12, 12), Vector2(w.map_size) - Vector2(24, 24))
	var ok := func(tile: Vector2) -> bool:
		return _free(Vector2i(tile), 8) and Road.distance_to(tile, w._road) > 4.0 and Road.distance_to(tile, w._road) < 18.0
	for i in FARMS:
		var tile: Vector2 = w._pick_spread(area, _farms, ok)
		if not tile.is_finite():
			continue
		_farms.append(tile)
		w._reserve_area(tile, 8.0)
		for cell in w._cells_in_radius(tile + Vector2(0, 1), 6.0):
			_yard_cells[cell] = true


## Pola: prostokąty w wolnym terenie (nie na drodze, w siedliskach ani gospodarstwach), z odstępem
## na miedze między nimi.
func _plan_fields(rng: RandomNumberGenerator) -> void:
	var margin: int = w.border_thickness + 4
	for attempt in 900:
		if fields.size() >= FIELD_COUNT:
			break
		var fw := rng.randi_range(9, 22)
		var fh := rng.randi_range(6, 13)
		var x := rng.randi_range(margin, w.map_size.x - margin - fw)
		var y := rng.randi_range(margin, w.map_size.y - margin - fh)
		var rect := Rect2i(x, y, fw, fh)
		if not _rect_free(rect.grow(2)):
			continue
		var roll := rng.randf()
		var kind := "grain" if roll < 0.68 else "stubble" if roll < 0.88 else "soil"
		fields.append([rect, kind])
		for cy in range(rect.position.y - 1, rect.end.y + 1):
			for cx in range(rect.position.x - 1, rect.end.x + 1):
				_field_cells[Vector2i(cx, cy)] = true


func _free(cell: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var c := cell + Vector2i(dx, dy)
			if w._reserved.has(c) or w._road_clear.has(c) or _field_cells.has(c):
				return false
	return true


func _rect_free(rect: Rect2i) -> bool:
	for cy in range(rect.position.y, rect.end.y):
		for cx in range(rect.position.x, rect.end.x):
			var c := Vector2i(cx, cy)
			if w._reserved.has(c) or w._road_clear.has(c) or _field_cells.has(c) or _yard_cells.has(c):
				return false
	return true


# ---------------------------------------------------------------- teren
func _build_ground(rng: RandomNumberGenerator) -> void:
	var patch := FastNoiseLite.new()
	patch.seed = rng.randi()
	patch.frequency = 0.07
	var flowers := FastNoiseLite.new()
	flowers.seed = rng.randi()
	flowers.frequency = 0.1
	var soil := {}
	var stubble := {}
	for field: Array in fields:
		var rect: Rect2i = field[0]
		for cy in range(rect.position.y, rect.end.y):
			for cx in range(rect.position.x, rect.end.x):
				if field[1] == "stubble":
					stubble[Vector2i(cx, cy)] = true
				else:
					soil[Vector2i(cx, cy)] = true
	var dirt := {}
	for cell in w._road_cells:
		dirt[cell] = true
	for cell in _yard_cells:
		dirt[cell] = true
	for cell in w._cells_in_radius(kobolds, 8.0):
		dirt[cell] = true
	for cell in w._cells_in_radius(bombardier, 6.0):
		dirt[cell] = true
	for cell in w._cells_in_radius(worm_lair, 6.5):
		dirt[cell] = true
	for cell in w._cells_in_radius(gryf_hill, 8.0):
		dirt[cell] = true
	for y in w.map_size.y + 1:
		for x in w.map_size.x + 1:
			var corner := Vector2i(x, y)
			var kind := "grass"
			if _touches(corner, dirt) >= 2:
				kind = "road"
			elif _touches(corner, soil) >= 2:
				kind = "f_soil"
			elif _touches(corner, stubble) >= 2:
				kind = "f_stubble"
			elif patch.get_noise_2d(x, y) > 0.3:
				kind = "dark"
			elif flowers.get_noise_2d(x, y) > 0.45:
				kind = "flowers"
			_corners[corner] = kind
	w._soft_corners = _corners
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			w.ground.set_cell(cell, 0, Vector2i(0, w.FOREST_WANG_ROW))
			if soil.has(cell):
				w._map_props[cell] = MAP_SOIL
			elif stubble.has(cell):
				w._map_props[cell] = MAP_STUBBLE
			elif dirt.has(cell) and not w._road_cells.has(cell):
				w._camp_cells[cell] = true


## Ile z czterech komórek wokół narożnika należy do zbioru.
func _touches(corner: Vector2i, cells: Dictionary) -> int:
	var n := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		n += int(cells.has(corner + d))
	return n


## Kolor terenu na mapie (pola i podwórka mają własne kolory w _map_props).
static func map_color(_atlas: Vector2i) -> Color:
	return Color("6a9a3e")


# ---------------------------------------------------------------- przyroda: brzegi, zadrzewienia, miedze
func _place_nature(rng: RandomNumberGenerator) -> void:
	var groves := FastNoiseLite.new()
	groves.seed = rng.randi()
	groves.frequency = 0.045
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
			if w._reserved.has(cell) or _field_cells.has(cell) or _yard_cells.has(cell):
				continue
			var r := rng.randf()
			# zadrzewienia śródpolne i pojedyncze drzewa na miedzach
			if groves.get_noise_2d(x, y) > 0.42 and r < 0.16:
				_tree(rng, cell, 1)
			elif r < 0.004:
				_tree(rng, cell, 2)
			elif r < 0.012:
				w._try_place(BUSH, cell, 1)
			elif r < 0.045:
				_decor(rng, w._cell_to_world(cell), [3, 4, 6, 13, 13, 14].pick_random())


func _tree(rng: RandomNumberGenerator, cell: Vector2i, spacing: int) -> void:
	var oak := rng.randf() < 0.75
	w._try_place(OAK if oak else PINE, cell, spacing)
	if w._occupied.has(cell):
		w._map_props[cell] = w.MAP_TREE if oak else w.MAP_PINE


# ---------------------------------------------------------------- pola
func _build_field(rng: RandomNumberGenerator, rect: Rect2i, kind: String) -> void:
	var px := Rect2(Vector2(rect.position * TILE), Vector2(rect.size * TILE))
	if kind == "grain":
		_grain_rects.append(px)
		var variant := rng.randi() % GRAIN_VARIANTS
		for row in rect.size.y:
			_grain_row(rng, Vector2(px.position.x, px.position.y + (row + 1) * TILE + 2), px.size.x, variant)
		for cy in range(rect.position.y, rect.end.y):
			for cx in range(rect.position.x, rect.end.x):
				w._map_props[Vector2i(cx, cy)] = MAP_GRAIN
		# strach na wróble i maki na skraju łanu
		if rng.randf() < 0.45:
			_prop(SCARECROW, px.position + Vector2(rng.randf_range(0.3, 0.7) * px.size.x, rng.randf_range(0.4, 0.8) * px.size.y))
		for i in rng.randi_range(2, 6):
			_decor(rng, px.position + Vector2(rng.randf() * px.size.x, px.size.y + 6), [3, 4, 5].pick_random())
	elif kind == "stubble":
		# ściernisko: snopki w rzędach, czasem bele i stóg
		for row in range(1, rect.size.y, 3):
			for col in range(1, rect.size.x, 3):
				if rng.randf() < 0.55:
					var pos := px.position + Vector2(col, row) * TILE + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2))
					_prop(STOOK if rng.randf() < 0.8 else HAY_BALE, pos, Vector2(12, 5))
		if rng.randf() < 0.4:
			_prop(HAYSTACK, px.get_center(), Vector2(30, 10))
	else:
		# zaorany zagon: pług porzucony w bruździe
		if rng.randf() < 0.5:
			_prop(PLOUGH, px.position + Vector2(rng.randf() * px.size.x, rng.randf() * px.size.y))
		for i in 3:
			_decor(rng, px.position + Vector2(rng.randf() * px.size.x, rng.randf() * px.size.y), [6, 14].pick_random())
	# walące się murki z polnych kamieni na dłuższych bokach części pól (z wyłomami)
	if rng.randf() < 0.45:
		for side in [-1, 1]:
			if rng.randf() < 0.75:
				var y := px.position.y - 10.0 if side < 0 else px.end.y + 14.0
				_wall_line(rng, px.position.x - 8.0, px.end.x + 8.0, y)


## Jeden rząd zboża: pas tekstury powtarzany na szerokość pola, kołysany shaderem; postacie sortują się
## z nim wg wysokości, więc stojący w łanie chowają się w nim do pasa.
func _grain_row(rng: RandomNumberGenerator, bottom_left: Vector2, width: float, variant: int) -> void:
	var row := Sprite2D.new()
	row.texture = GRAIN
	row.region_enabled = true
	row.region_rect = Rect2(rng.randi() % GRAIN.get_width(), variant * GRAIN_HEIGHT, width, GRAIN_HEIGHT)
	row.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	row.centered = false
	row.offset = Vector2(0, -GRAIN_HEIGHT)
	row.position = bottom_left
	row.material = _sway
	row.set_meta("no_occlusion", true)
	w.entities.add_child(row)


## Murek: odcinki ściany z wyłomami i gruzem, zakończone osypującym się końcem.
func _wall_line(rng: RandomNumberGenerator, from_x: float, to_x: float, y: float) -> void:
	var step := float(WALL.get_width()) - 2.0
	var x := from_x + step / 2.0
	var broken := true
	while x < to_x - step / 2.0:
		if rng.randf() < 0.22:
			# wyłom: gruz albo nic
			if rng.randf() < 0.5:
				_prop(RUBBLE, Vector2(x, y), Vector2.ZERO)
			broken = true
		else:
			var end := broken or rng.randf() < 0.1
			var piece := _prop(WALL_END if end else WALL, Vector2(x, y), Vector2(step, 8))
			piece.flip_h = end and rng.randf() < 0.5
			w._map_props[Vector2i(Vector2(x, y) / TILE)] = MAP_WALL
			broken = false
		x += step


# ---------------------------------------------------------------- gospodarstwa
func _build_farm(rng: RandomNumberGenerator, center: Vector2) -> void:
	var c := center * TILE
	var flip := rng.randf() < 0.5
	var side := -1.0 if flip else 1.0
	var house := _prop(FARMHOUSE, c + Vector2(-40 * side, -18), Vector2(76, 22))
	house.flip_h = flip
	_map_rect(c + Vector2(-40 * side, -30), Vector2(5, 3), MAP_HOUSE)
	if rng.randf() < 0.7:
		var barn := _prop(BARN, c + Vector2(48 * side, -14), Vector2(80, 22))
		barn.flip_h = rng.randf() < 0.5
		_map_rect(c + Vector2(48 * side, -26), Vector2(5, 3), MAP_HOUSE)
	_prop(WELL, c + Vector2(10 * side, 30), Vector2(22, 8))
	var clutter := [CART, SACKS, TROUGH, HAY_BALE, HAYSTACK, HAY_BALE]
	clutter.shuffle()
	for i in rng.randi_range(3, 5):
		var tex: Texture2D = clutter[i % clutter.size()]
		var pos := c + Vector2(rng.randf_range(-70, 70), rng.randf_range(22, 52))
		var blocking := tex in [CART, HAYSTACK, TROUGH]
		_prop(tex, pos, Vector2(26, 8) if blocking else Vector2.ZERO).flip_h = rng.randf() < 0.5
	# płot wokół podwórka - połamany, z dziurami
	for i in 9:
		if rng.randf() < 0.65:
			var pos := c + Vector2(-96 + i * 24, 70)
			_prop(FENCE, pos, Vector2(22, 4)).flip_h = rng.randf() < 0.5
	for i in 6:
		_decor(rng, c + Vector2(rng.randf_range(-80, 80), rng.randf_range(-10, 60)), [9, 10, 11, 12, 13].pick_random())
	# w opuszczonym gospodarstwie gnieżdżą się koboldy (północ) albo ryją czerwie (południe)
	var tile := center + Vector2(0, 2.5)
	if center.y < w.map_size.y * 0.5:
		_kobold_group(rng, tile, rng.randi_range(4, 6), false)
	else:
		for i in 2:
			var pos := (tile + Vector2(rng.randf_range(-5, 5), rng.randf_range(-2, 3))) * TILE
			w._add_goblin_spawn({"type": "field_worm", "position": pos, "sitting": false, "look_at": pos})


func _map_rect(top_left_center: Vector2, half: Vector2, color: Color) -> void:
	var c := Vector2i(top_left_center / TILE)
	for dy in range(-int(half.y) + 1, int(half.y)):
		for dx in range(-int(half.x) + 1, int(half.x)):
			w._map_props[c + Vector2i(dx, dy)] = color


# ---------------------------------------------------------------- koboldy
## Zgraja koboldów: włócznicy, procarze i saperzy. `camp` - siedzą wokół (ogniska).
func _kobold_group(rng: RandomNumberGenerator, tile: Vector2, n: int, camp: bool) -> void:
	var center := tile * TILE
	for k in n:
		var roll := rng.randf()
		var kind := "kobold" if roll < 0.6 else "kobold_slinger" if roll < 0.85 else "kobold_bomber"
		var pos: Vector2
		if camp:
			pos = center + Vector2.from_angle(TAU * k / n + rng.randf_range(-0.2, 0.2)) * rng.randf_range(22, 30)
		else:
			pos = center + Vector2(rng.randf_range(-22, 22), rng.randf_range(-16, 16))
		w._add_goblin_spawn({"type": kind, "position": pos, "sitting": camp, "look_at": center})


func _build_kobold_camp(rng: RandomNumberGenerator) -> void:
	var center := kobolds * TILE
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		var pos := center + Vector2.from_angle(angle) * Vector2(112, 80)
		var tent := _prop(TENT, pos, Vector2(40, 12))
		tent.flip_h = pos.x < center.x
		w._map_props[Vector2i(pos / TILE)] = MAP_TENT
	for i in 3:
		var spot := center + Vector2.from_angle(TAU * i / 3.0 + 1.0) * 46.0
		var fire: Node2D = CAMPFIRE.instantiate()
		fire.position = spot
		w.entities.add_child(fire)
		w._map_props[Vector2i(spot / TILE)] = w.MAP_FIRE
		_kobold_group(rng, spot / TILE, rng.randi_range(4, 5), true)
	for i in 4:
		_prop(TOTEM, center + Vector2.from_angle(TAU * i / 4.0) * Vector2(150, 104), Vector2(8, 4))
	for i in 6:
		var pos := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(60, 100)
		_prop(BOMB_CRATE if i % 2 == 0 else POWDER, pos, Vector2(16, 6))
	for i in 10:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 110), [7, 8, 11, 12, 15].pick_random())
	# zgraje w okolicznych łanach i na miedzach
	var spots: Array[Vector2] = []
	var area := Rect2(Vector2(10, 8), Vector2(w.map_size.x - 20, w.map_size.y * 0.5))
	var ok := func(tile: Vector2) -> bool:
		return tile.distance_to(kobolds) > 14.0 and tile.distance_to(gryf_hill) > 24.0 and not w._occupied.has(Vector2i(tile)) \
				and tile.distance_to(entry) > 50.0
	for i in KOBOLD_GROUPS:
		var tile: Vector2 = w._pick_spread(area, spots, ok)
		if not tile.is_finite():
			continue
		spots.append(tile)
		_kobold_group(rng, tile, rng.randi_range(3, 5), false)
	w._map_markers.append({"position": center, "color": Kobold.KOBOLD_COLOR, "size": 3.0})


func _build_bombardier_lair(rng: RandomNumberGenerator) -> void:
	var center := bombardier * TILE
	# barykada ze skrzyń bomb i beczek prochu łukiem od północy
	for i in 15:
		var angle := PI * 0.85 + PI * 1.3 * i / 14.0
		var pos := center + Vector2.from_angle(angle) * Vector2(140, 96)
		_prop(POWDER if i % 3 == 0 else BOMB_CRATE, pos, Vector2(18, 7))
	for i in 14:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 110), [7, 8, 8, 6].pick_random())
	_prop(TOTEM, center + Vector2(-30, -40), Vector2(8, 4))
	_prop(TOTEM, center + Vector2(30, -40), Vector2(8, 4))
	w._add_goblin_spawn({"type": "bombardier", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})


# ---------------------------------------------------------------- czerwie
func _build_worm_grounds(rng: RandomNumberGenerator) -> void:
	var placed := 0
	for attempt in 400:
		if placed >= WORMS:
			break
		var tile := worms + Vector2.from_angle(rng.randf() * TAU) * Vector2(34, 22) * sqrt(rng.randf())
		var cell := Vector2i(tile)
		if w._occupied.has(cell) or tile.distance_to(worm_lair) < 12.0 or not Rect2(Vector2(6, 6), Vector2(w.map_size) - Vector2(12, 12)).has_point(tile):
			continue
		placed += 1
		var pos := tile * TILE
		w._add_goblin_spawn({"type": "field_worm", "position": pos, "sitting": false, "look_at": pos})
		for k in 2:
			_decor(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(14, 30), [0, 1, 2, 14].pick_random())
	for i in 40:
		var tile := worms + Vector2.from_angle(rng.randf() * TAU) * Vector2(38, 25) * sqrt(rng.randf())
		_decor(rng, tile * TILE, [0, 0, 1, 2, 2, 14, 15].pick_random())
	w._map_markers.append({"position": worms * TILE, "color": Color(0.85, 0.6, 0.55), "size": 3.0})
	# krater Pożeracza: popękana ziemia, gruz i kości wokół
	var center := worm_lair * TILE
	for i in 14:
		var pos := center + Vector2.from_angle(TAU * i / 14.0 + rng.randf_range(-0.1, 0.1)) * Vector2(96, 70) * rng.randf_range(0.85, 1.1)
		_prop(RUBBLE if i % 3 == 0 else MOUND, pos)
	for i in 6:
		var crack := _floor_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 80), 2)
		crack.scale = Vector2.ONE * rng.randf_range(1.2, 2.0)
	for i in 6:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 90), [1, 15, 15].pick_random())
	w._add_goblin_spawn({"type": "giant_worm", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})


# ---------------------------------------------------------------- wzgórze Gryfa
## Najdalej od wejścia: skaliste wzgórze z gniazdem, kośćmi i szczątkami śmiałków. Gryf (poziom 42) krąży
## nad nim w powietrzu; zbyt słabi dostają ostrzeżenie (World._process_warnings).
func _build_gryf_hill(rng: RandomNumberGenerator) -> void:
	var center := gryf_hill * TILE
	_prop(AERIE, center + Vector2(0, -10), Vector2(60, 14))
	for i in 9:
		var pos := center + Vector2.from_angle(TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)) * rng.randf_range(90, 150)
		w._try_place(w.BOULDER, Vector2i(pos / TILE), 1)
	for i in 6:
		_prop(GRYF_BONES if i % 2 == 0 else CAIRN, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40, 120))
	for i in 8:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 140), [6, 11, 15].pick_random())
	w._add_goblin_spawn({"type": "gryf", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time,
			"level": 42, "warn": true})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 5.0})


# ---------------------------------------------------------------- pomocnicze
func _prop(texture: Texture2D, pos: Vector2, collision := Vector2.ZERO) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(texture, pos, collision)
	sprite.offset.y += PropSinks.of(texture)
	return sprite


func _decor(rng: RandomNumberGenerator, pos: Vector2, frame: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = DECOR
	sprite.hframes = DECOR_FRAMES
	sprite.frame = frame
	sprite.flip_h = rng.randf() < 0.5
	sprite.position = pos
	# płaskie drobiazgi (kopce, nory, pęknięcia, osmalenia) na podłodze, reszta sortuje się z postaciami
	if frame in [0, 1, 2, 7, 8, 11, 12]:
		w.floors.add_child(sprite)
	else:
		sprite.offset = Vector2(0, -12)
		w.entities.add_child(sprite)


func _floor_decor(rng: RandomNumberGenerator, pos: Vector2, frame: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = DECOR
	sprite.hframes = DECOR_FRAMES
	sprite.frame = frame
	sprite.flip_h = rng.randf() < 0.5
	sprite.position = pos
	w.floors.add_child(sprite)
	return sprite


## Gracz brnie przez łan wolniej.
func _process(_delta: float) -> void:
	if _player == null:
		return
	var feet: Vector2 = _player.global_position
	for rect in _grain_rects:
		if rect.has_point(feet):
			_player.apply_slow(GRAIN_SLOW, 0.2)
			return
