class_name GrainFields
extends Node
## Pola Zbożowe - kraina na zachód od Goblińskiego Lasu (wejście na końcu leśnej drogi, w prawym dolnym rogu).
## Dawny spichlerz okolicy: pola zajmują prawie całą krainę - organiczne, faliste kształty (z szumu) na brązowej
## glebie, rozdzielone wąskimi miedzami z płotami, murkami z polnych kamieni, krzakami, kamieniami i kwiatami.
## Przeważają wysokie, złote łany (rząd zboża to kołyszący się pas - postacie chowają się w nim do pasa; zboże nie
## spowalnia), część pól jest już zebrana (ściernisko z rzędami snopków), część świeżo zaorana. Między polami kępy
## jesiennych drzew, a na polanach opuszczone gospodarstwa (chałupy, stodoły, studnie) z dróżkami do drogi. Droga prowadzi od wejścia do rozstajów przy ruinie wiatraka (kapliczka Starego Młyna). Siedliska:
## - na północy: wielki obóz koboldów (namioty ze skór, ogniska, skrzynie bomb, totemy), a w jego północnej
##   części barykada Bombardiera; zgraje koboldów także w okolicznych łanach,
## - na południowym zachodzie: ryjowisko czerwi polnych (kopce, nory, popękana ziemia) z kraterem
##   Pożeracza Pól (ryjowisko to ścierniska i zaorane zagony, nie łany),
## - w lewym górnym rogu, najdalej od wejścia: wzgórze, nad którym krąży gryf.

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

const FARMS := 7
const KOBOLD_GROUPS := 14
const WORMS := 26
## Obóz koboldów: półosie (w kafelkach), namioty, ogniska i stojące zgraje w obozie.
const CAMP_RADII := Vector2(24.0, 15.0)
const CAMP_TENTS := 12
const CAMP_FIRES := 6
const CAMP_PACKS := 8
## Pola to działki: środki na poszarpanej siatce co PARCEL kafelków (szersze niż wyższe), granice wygięte szumem.
## Miedza tam, gdzie dwa najbliższe środki są prawie tak samo daleko (BALK); łąki tylko tam, gdzie szum łąk
## spada poniżej MEADOW_LEVEL. Udział rodzajów działek: łany, ścierniska (reszta - zaorane zagony).
const PARCEL := Vector2(17.0, 12.0)
const BALK := 1.5
const MEADOW_LEVEL := -0.45
const GRAIN_SHARE := 0.64
const STUBBLE_SHARE := 0.18
## Polana wokół gospodarstwa (bez pól, w kafelkach).
const FARM_CLEARING := 11.0
## Jesienne barwy liści dębów (shader podmienia zieleń) - część dębów zostaje zielona.
const AUTUMN_SHADER := preload("res://shaders/autumn.gdshader")
const AUTUMN: Array[Color] = [Color(1.0, 0.74, 0.26), Color(1.0, 0.55, 0.2), Color(1.0, 0.88, 0.34), Color(0.92, 0.42, 0.18)]
const AUTUMN_SHARE := 0.7

var w  # świat
var entry := Vector2.ZERO
var cross := Vector2.ZERO
var kobolds := Vector2.ZERO
var bombardier := Vector2.ZERO
var worms := Vector2.ZERO
var worm_lair := Vector2.ZERO
var gryf_hill := Vector2.ZERO
## Rodzaj pola w komórce: "grain" / "stubble" / "soil" (brak wpisu - łąka, droga, siedlisko).
var _field_kind := {}
var _farms: Array[Vector2] = []
## Teren narożników (Vector2i -> nazwa terenu SoftGround); brak wpisu = trawa.
var _corners := {}
var _yard_cells := {}
var _field_cells := {}
var _sway: ShaderMaterial
var _autumn: Array[ShaderMaterial] = []


func generate(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	Goblin.safe_zone = Rect2()
	entry = Vector2(size.x - 1.0, size.y - 3.0)
	cross = Vector2(size.x * 0.58, size.y * 0.6)
	kobolds = Vector2(size.x * 0.5, size.y * 0.25)
	bombardier = kobolds + Vector2(0, -CAMP_RADII.y + 3.0)
	worms = Vector2(size.x * 0.3, size.y * 0.72)
	worm_lair = Vector2(size.x * 0.1, size.y * 0.83)
	gryf_hill = Vector2(size.x * 0.12, size.y * 0.26)
	_sway = ShaderMaterial.new()
	_sway.shader = SWAY
	for tint in AUTUMN:
		var material := ShaderMaterial.new()
		material.shader = AUTUMN_SHADER
		material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
		_autumn.append(material)

	# droga od wejścia do rozstajów i dalej do bramy obozu koboldów; ścieżki do czerwi i na wzgórze gryfa,
	# a między nimi dróżka zachodem (drugie rozstaje)
	w._road = Road.wiggle(entry, cross, rng, 5.0, 11.0)
	w._road.append_array(Road.wiggle(cross, kobolds + Vector2(0, CAMP_RADII.y + 3.0), rng, 5.0, 11.0))
	_mark_path(w._road, 1.3, 2.8)
	var to_worms := Road.wiggle(cross, worms + Vector2(14, -4), rng, 5.0, 11.0)
	var to_gryf := Road.wiggle(cross, gryf_hill + Vector2(16, 6), rng, 5.0, 11.0)
	_mark_path(to_worms, 0.9, 2.2)
	_mark_path(to_gryf, 0.9, 2.2)
	_mark_path(Road.wiggle(to_worms[to_worms.size() * 2 / 3], to_gryf[to_gryf.size() * 2 / 3], rng, 4.0, 9.0), 0.8, 2.0)

	var shrine_tile := cross + Vector2(4.5, -4.0)
	w._reserve_area(shrine_tile, 3.0)
	w._reserve_area(cross + Vector2(-6.0, -6.0), 4.0)  # wiatrak
	for cell in _ellipse(kobolds, CAMP_RADII):
		w._reserved[cell] = true
	w._reserve_area(worm_lair, 9.0)
	w._reserve_area(gryf_hill, 14.0)
	_plan_farms(rng)
	_plan_fields(rng)

	_build_ground(rng)
	_place_nature(rng)
	w._build_bounds()
	for farm in _farms:
		_build_farm(rng, farm)
	_build_fields(rng)
	_build_balks(rng)
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
	# dróżki od podwórek do najbliższej drogi
	for farm in _farms:
		var nearest: Vector2 = w._road[0]
		for point: Vector2 in w._road:
			if point.distance_squared_to(farm) < nearest.distance_squared_to(farm):
				nearest = point
		_mark_path(Road.wiggle(farm + Vector2(0, 4), nearest, rng, 2.0, 6.0), 0.7, 1.8)


## Pola: działki o organicznych granicach (komórki Woronoja z wygiętymi szumem odległościami) na całej krainie poza
## drogami, siedliskami, podwórkami i pasem lasu przy granicy; między działkami miedze, a gdzieniegdzie łąka.
## Każda działka ma jeden rodzaj: łan (najczęściej), ściernisko albo zaorany zagon; na ryjowisku czerwi łanów nie ma.
func _plan_fields(rng: RandomNumberGenerator) -> void:
	var meadows := FastNoiseLite.new()
	meadows.seed = rng.randi()
	meadows.frequency = 0.03
	var warp := FastNoiseLite.new()
	warp.seed = rng.randi()
	warp.frequency = 0.06
	# środki działek na poszarpanej siatce i ich rodzaje
	var grid := Vector2i((Vector2(w.map_size) / PARCEL).ceil()) + Vector2i(2, 2)
	var seeds := {}
	var kinds := {}
	for gy in grid.y:
		for gx in grid.x:
			var g := Vector2i(gx, gy)
			seeds[g] = (Vector2(gx - 1, gy - 1) + Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.15, 0.85))) * PARCEL
			var roll := rng.randf()
			kinds[g] = "grain" if roll < GRAIN_SHARE else "stubble" if roll < GRAIN_SHARE + STUBBLE_SHARE else "soil"
	var margin: int = w.border_thickness + 2
	for y in range(margin, w.map_size.y - margin):
		for x in range(margin, w.map_size.x - margin):
			var cell := Vector2i(x, y)
			if w._reserved.has(cell) or w._road_clear.has(cell) or _yard_cells.has(cell):
				continue
			if meadows.get_noise_2d(x, y) < MEADOW_LEVEL:
				continue
			if _farms.any(func(farm: Vector2) -> bool: return farm.distance_to(Vector2(cell)) < FARM_CLEARING):
				continue
			var p := Vector2(x, y) + Vector2(warp.get_noise_2d(x, y), warp.get_noise_2d(x + 500.0, y)) * 4.0
			var home := Vector2i((p / PARCEL).floor()) + Vector2i.ONE
			var best := INF
			var second := INF
			var owner := home
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var g := home + Vector2i(dx, dy)
					if not seeds.has(g):
						continue
					var seed_at: Vector2 = seeds[g]
					var d := ((p - seed_at) / PARCEL).length() * PARCEL.y
					if d < best:
						second = best
						best = d
						owner = g
					elif d < second:
						second = d
			if second - best < BALK:
				continue
			var kind: String = kinds[owner]
			if kind == "grain" and ((Vector2(cell) - worms) / Vector2(34, 22)).length() < 1.0:
				kind = "stubble" if (owner.x + owner.y) % 2 == 0 else "soil"
			_field_kind[cell] = kind
			_field_cells[cell] = true


## Komórki elipsy (w kafelkach).
func _ellipse(center: Vector2, radii: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(floori(center.y - radii.y), ceili(center.y + radii.y) + 1):
		for x in range(floori(center.x - radii.x), ceili(center.x + radii.x) + 1):
			if ((Vector2(x, y) + Vector2(0.5, 0.5) - center) / radii).length() < 1.0:
				cells.append(Vector2i(x, y))
	return cells


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
	for cell: Vector2i in _field_kind:
		if _field_kind[cell] == "stubble":
			stubble[cell] = true
		else:  # pod łanem brązowa gleba - prześwituje między rzędami i na skraju pola
			soil[cell] = true
	var dirt := {}
	for cell in w._road_cells:
		dirt[cell] = true
	for cell in _yard_cells:
		dirt[cell] = true
	for cell in _ellipse(kobolds, CAMP_RADII * 0.9):
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
			if w._reserved.has(cell) or _field_cells.has(cell) or _yard_cells.has(cell) or _near_field(cell):
				continue  # miedze urządza _build_balks (płoty, murki, krzaki)
			var r := rng.randf()
			# kępy drzew na łąkach między polami i pojedyncze drzewa na miedzach
			if groves.get_noise_2d(x, y) > 0.22 and r < 0.34:
				_tree(rng, cell, 1)
			elif r < 0.006:
				_tree(rng, cell, 2)
			elif r < 0.012:
				w._try_place(BUSH, cell, 1)
			elif r < 0.045:
				_decor(rng, w._cell_to_world(cell), [3, 4, 6, 13, 13, 14].pick_random())


## Drzewo; dęby mają jesienne barwy (złote, rude), jak na pogórzu pełnym pól.
func _tree(rng: RandomNumberGenerator, cell: Vector2i, spacing: int) -> void:
	var oak := rng.randf() < 0.8
	if w._occupied.has(cell):
		return
	w._try_place(OAK if oak else PINE, cell, spacing)
	if w._occupied.has(cell):
		w._map_props[cell] = w.MAP_TREE if oak else w.MAP_PINE
		if oak and rng.randf() < AUTUMN_SHARE:
			var tree: Node2D = w.entities.get_child(w.entities.get_child_count() - 1)
			(tree.get_node("Sprite") as Sprite2D).material = _autumn[rng.randi() % _autumn.size()]


# ---------------------------------------------------------------- pola
## Łany: w każdym rzędzie kafelków ciągłe odcinki zboża stają się jednym kołyszącym się pasem (końce lekko
## postrzępione); odmiana zboża zmienia się łagodnie po krainie. Na łanach strachy na wróble, na skraju maki.
## Ścierniska dostają snopki, bele i czasem stóg, zagony - porzucone pługi.
func _build_fields(rng: RandomNumberGenerator) -> void:
	var variants := FastNoiseLite.new()
	variants.seed = rng.randi()
	variants.frequency = 0.02
	# odmiana w komórce: dwie złote (dojrzałe łany), zielonkawa tylko w rzadkich płatach; pas dzielimy tam,
	# gdzie zmienia się odmiana - granice płatów biegną wtedy po konturze szumu, a nie w poprzek rzędów
	var variant_of := func(x: int, y: int) -> int:
		var n := variants.get_noise_2d(x, y)
		return 2 if n < -0.5 else 0 if n < 0.1 else 1
	for y in w.map_size.y:
		var x := 0
		while x < w.map_size.x:
			if _field_kind.get(Vector2i(x, y), "") != "grain":
				x += 1
				continue
			var start := x
			var variant: int = variant_of.call(x, y)
			while _field_kind.get(Vector2i(x, y), "") == "grain" and variant_of.call(x, y) == variant:
				x += 1
			var left := start * TILE - (rng.randf_range(0.0, 6.0) if not _field_kind.has(Vector2i(start - 1, y)) else 0.0)
			var right := x * TILE + (rng.randf_range(0.0, 6.0) if _field_kind.get(Vector2i(x, y), "") != "grain" else 0.0)
			_grain_row(rng, Vector2(left, (y + 1) * TILE + 2), right - left, variant)
	for cell: Vector2i in _field_kind:
		var kind: String = _field_kind[cell]
		var pos := Vector2(cell * TILE) + Vector2(8, 8)
		match kind:
			"grain":
				w._map_props[cell] = MAP_GRAIN
				if rng.randf() < 0.0025:
					_prop(SCARECROW, pos)
				elif not _field_kind.has(cell + Vector2i.DOWN) and rng.randf() < 0.2:
					_decor(rng, pos + Vector2(rng.randf_range(-6, 6), 14), [3, 4, 5].pick_random())
			"stubble":
				w._map_props[cell] = MAP_STUBBLE
				# snopki w równych rzędach (co dwa kafelki w poziomie, co trzy w pionie), tu i ówdzie bela
				if cell.x % 2 == 0 and cell.y % 3 == 1 and rng.randf() < 0.85:
					var jitter := Vector2(rng.randf_range(-2, 2), rng.randf_range(-1, 1))
					_prop(STOOK if rng.randf() < 0.88 else HAY_BALE, pos + jitter)  # snopki nie zagradzają drogi
				elif rng.randf() < 0.004:
					_prop(HAYSTACK, pos, Vector2(30, 10))
			_:
				w._map_props[cell] = MAP_SOIL
				if rng.randf() < 0.004:
					_prop(PLOUGH, pos)
				elif rng.randf() < 0.02:
					_decor(rng, pos, [6, 14].pick_random())


## Miedze i skraje pól: wzdłuż poziomych granic pól (komórka poza polem, pole tuż nad nią albo pod nią) płoty
## z żerdzi albo murki z polnych kamieni - rodzaj zmienia się płatami po krainie, część granic zostaje otwarta;
## w ogrodzeniach co jakiś czas przerwa na przejście. Na miedzach krzaki, kamienie, kwiaty i pojedyncze drzewa.
func _build_balks(rng: RandomNumberGenerator) -> void:
	var style := FastNoiseLite.new()
	style.seed = rng.randi()
	style.frequency = 0.04
	# przęsła stawiamy co kilka kafelków dolnego skraju pola (skraj bywa schodkowy - ogrodzenie idzie za nim);
	# co jakiś czas przerwa na przejście, w murkach także wyłomy z gruzem
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			if not _balk_edge(cell):
				continue
			var n := style.get_noise_2d(x, y)
			var pos := Vector2((x + 0.5) * TILE, (y + 1) * TILE + 4.0)
			if n > 0.15 and x % 3 == 0:
				if rng.randf() < 0.2:
					_prop(RUBBLE, pos)
				elif rng.randf() < 0.9:
					var piece := _prop(WALL if rng.randf() < 0.8 else WALL_END, pos, Vector2(WALL.get_width() - 4, 8))
					piece.flip_h = rng.randf() < 0.5
					w._map_props[cell] = MAP_WALL
			elif n <= 0.15 and n > -0.35 and x % 2 == 0 and x % 10 != 0 and rng.randf() < 0.85:
				_prop(FENCE, pos, Vector2(FENCE.get_width() - 8, 4)).flip_h = rng.randf() < 0.5
				w._map_props[cell] = MAP_WALL
	# drobiazgi na miedzach: krzaki, kamienie, kwiaty, czasem drzewo
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			if _field_kind.has(cell) or not _near_field(cell) or w._road_clear.has(cell) or w._reserved.has(cell):
				continue
			var r := rng.randf()
			if r < 0.035:
				w._try_place(BUSH, cell, 1)
			elif r < 0.05:
				_tree(rng, cell, 2)
			elif r < 0.3:
				_decor(rng, w._cell_to_world(cell) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-4, 4)), [3, 4, 5, 6, 13, 13, 14].pick_random())


## Dolny skraj pola (pod nim miedza), wzdłuż którego można postawić płot albo murek: ogrodzenie stoi tuż pod
## ostatnim rzędem łanu, więc rysuje się przed nim, a łan z pola niżej zaczyna się dopiero za miedzą.
func _balk_edge(cell: Vector2i) -> bool:
	var below := cell + Vector2i.DOWN
	if not _field_kind.has(cell) or _field_kind.has(below):
		return false
	# przy pasie lasu na granicy krainy bez ogrodzeń - nie zamykają przejść między polem a drzewami
	var edge := mini(mini(cell.x, cell.y), mini(w.map_size.x - 1 - cell.x, w.map_size.y - 1 - cell.y))
	if edge < w.border_thickness + 5:
		return false
	return not (w._road_clear.has(below) or w._reserved.has(below) or _yard_cells.has(below) or w._occupied.has(below))


func _near_field(cell: Vector2i) -> bool:
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _field_kind.has(cell + d):
			return true
	return false


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


## Wielki obóz koboldów na udeptanej ziemi: wianuszek namiotów ze skór, kilka ognisk z siedzącymi zgrajami,
## stojące zgraje między namiotami, skrzynie bomb i beczki prochu, totemy na skraju i straż przy bramie od
## drogi (południe). W północnej części obozu barykada Bombardiera. Dookoła, w łanach, kolejne zgraje.
func _build_kobold_camp(rng: RandomNumberGenerator) -> void:
	var center := kobolds * TILE
	var radii := CAMP_RADII * TILE
	var gate := center + Vector2(0, radii.y)
	for i in CAMP_TENTS:
		var angle := TAU * i / CAMP_TENTS + 0.15
		var pos := center + Vector2.from_angle(angle) * radii * rng.randf_range(0.72, 0.84)
		if pos.distance_to(gate) < 70.0 or pos.distance_to(bombardier * TILE) < 150.0:
			continue
		var tent := _prop(TENT, pos, Vector2(40, 12))
		tent.flip_h = pos.x < center.x
		w._map_props[Vector2i(pos / TILE)] = MAP_TENT
	for i in CAMP_FIRES:
		var angle := TAU * i / CAMP_FIRES + 0.5
		var spot := center + Vector2(0, radii.y * 0.15) + Vector2.from_angle(angle) * radii * 0.48
		var fire: Node2D = CAMPFIRE.instantiate()
		fire.position = spot
		w.entities.add_child(fire)
		w._map_props[Vector2i(spot / TILE)] = w.MAP_FIRE
		_kobold_group(rng, spot / TILE, rng.randi_range(6, 8), true)
	for i in CAMP_PACKS:
		var angle := TAU * (i + 0.5) / CAMP_PACKS + rng.randf_range(-0.2, 0.2)
		var spot := center + Vector2(0, radii.y * 0.15) + Vector2.from_angle(angle) * radii * rng.randf_range(0.25, 0.62)
		_kobold_group(rng, spot / TILE, rng.randi_range(5, 7), false)
	# straż bramy od drogi
	_kobold_group(rng, gate / TILE + Vector2(-3, -1), 4, false)
	_kobold_group(rng, gate / TILE + Vector2(3, -1), 4, false)
	for side in [-1.0, 1.0]:
		_prop(TOTEM, gate + Vector2(side * 40.0, -6), Vector2(8, 4))
	for i in 8:
		var angle := TAU * i / 8.0 + 0.4
		var pos := center + Vector2.from_angle(angle) * radii * 0.97
		if pos.distance_to(gate) > 60.0:
			_prop(TOTEM, pos, Vector2(8, 4))
	for i in 16:
		var pos := center + Vector2.from_angle(rng.randf() * TAU) * radii * rng.randf_range(0.2, 0.7)
		if pos.distance_to(bombardier * TILE) > 120.0:
			_prop(BOMB_CRATE if i % 2 == 0 else POWDER, pos, Vector2(16, 6))
	for i in 30:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * radii * rng.randf_range(0.1, 0.9), [7, 8, 11, 12, 15].pick_random())
	# zgraje w okolicznych łanach i na miedzach
	var spots: Array[Vector2] = []
	var area := Rect2(Vector2(10, 8), Vector2(w.map_size.x - 20, w.map_size.y * 0.55))
	var ok := func(tile: Vector2) -> bool:
		return ((tile - kobolds) / CAMP_RADII).length() > 1.3 and tile.distance_to(gryf_hill) > 24.0 \
				and not w._occupied.has(Vector2i(tile)) and tile.distance_to(entry) > 50.0
	for i in KOBOLD_GROUPS:
		var tile: Vector2 = w._pick_spread(area, spots, ok)
		if not tile.is_finite():
			continue
		spots.append(tile)
		_kobold_group(rng, tile, rng.randi_range(5, 7), false)
	w._map_markers.append({"position": center, "color": Kobold.KOBOLD_COLOR, "size": 3.0})


## Barykada Bombardiera w północnej części obozu: łuk ze skrzyń bomb i beczek prochu, totemy, osmalona ziemia
## i przyboczni saperzy przed wejściem.
func _build_bombardier_lair(rng: RandomNumberGenerator) -> void:
	var center := bombardier * TILE
	# barykada łukiem od północy (wejście od strony obozu)
	for i in 15:
		var angle := PI * 0.85 + PI * 1.3 * i / 14.0
		var pos := center + Vector2.from_angle(angle) * Vector2(140, 96)
		_prop(POWDER if i % 3 == 0 else BOMB_CRATE, pos, Vector2(18, 7))
	for i in 14:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 110), [7, 8, 8, 6].pick_random())
	_prop(TOTEM, center + Vector2(-30, -40), Vector2(8, 4))
	_prop(TOTEM, center + Vector2(30, -40), Vector2(8, 4))
	for k in 6:
		var pos := center + Vector2(-75 + k * 30, 70 + (k % 2) * 10)
		w._add_goblin_spawn({"type": "kobold_bomber" if k % 2 == 0 else "kobold", "position": pos, "sitting": false, "look_at": center})
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
