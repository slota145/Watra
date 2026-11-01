class_name GrainFields
extends Node
## Pola Zbożowe - kraina na zachód od Goblińskiego Lasu (wejście na końcu leśnej drogi, w prawym dolnym rogu).
## Dawny spichlerz okolicy: pola zajmują prawie całą krainę - organiczne, faliste kształty (z szumu) na brązowej
## glebie, rozdzielone wąskimi miedzami z żywopłotami (z przejściami między polami), płotami z żerdzi, kamieniami i kwiatami.
## Przeważają wysokie, złote łany (rząd zboża to kołyszący się pas - postacie chowają się w nim do pasa; zboże nie
## spowalnia), część pól jest już zebrana (ściernisko z rzędami snopków), część świeżo zaorana. Między polami kępy
## jesiennych drzew, a na polanach opuszczone gospodarstwa (chałupy, stodoły, studnie) z dróżkami do drogi. Droga prowadzi od wejścia do rozstajów przy ruinie wiatraka (kapliczka Starego Młyna). Siedliska:
## - na północy: wielki obóz koboldów (namioty ze skór, ogniska, skrzynie bomb, totemy), a w jego północnej
##   części barykada Bombardiera; zgraje koboldów także w łanach w całej krainie,
## - czaty koboldów (OUTPOSTS) na dawnych pustkowiach: wianuszek namiotów wokół ogniska, łupy z gospodarstw
##   (wóz, worki), skrzynie bomb i totemy, dróżka do drogi - po około 30 koboldów,
## - opuszczone gospodarstwa: na północy plądrują je koboldy, na południu podwórka rozryły czerwie,
## - na południowym zachodzie: ryjowisko czerwi polnych (gromadki czerwi wokół nor, kopce, popękana ziemia)
##   z kraterem Pożeracza Pól (ryjowisko to ścierniska i zaorane zagony, nie łany); gniazda czerwi także
##   w zaoranych zagonach w całej krainie,
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
## Żywopłoty na miedzach: krzaki ustawione gęsto jeden przy drugim (jak pale palisady), tworzą ciągłe linie
## na granicach działek. Żywopłot tam, gdzie szum stylu miedz jest ponad HEDGE_STYLE, płot z żerdzi w paśmie
## pod nim, niżej miedza otwarta. Przejścia między polami co najwyżej co HEDGE_GAP_EVERY kafelków.
const HEDGE_BUSHES: Array[Texture2D] = [preload("res://assets/forest/trees/bush_0.png"),
		preload("res://assets/forest/trees/bush_1.png"), preload("res://assets/forest/trees/bush_2.png")]
const HEDGE_STYLE := -0.2
const FENCE_STYLE := -0.5
const HEDGE_GAP_EVERY := 11.0
const HEDGE_GAP_RADIUS := 1.6
const MAP_HEDGE := Color("3f6a2a")
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

const FARMS := 10
## Zgraje koboldów w łanach i na miedzach (cała kraina poza ryjowiskiem i okolicą wejścia).
const KOBOLD_GROUPS := 34
const WORMS := 80
## Czaty koboldów: mniejsze obozowiska z łupami z gospodarstw - ile, promień polany (w kafelkach), namioty.
const OUTPOSTS := 4
const OUTPOST_RADIUS := 8.0
const OUTPOST_TENTS := 5
## Gniazda czerwi w zaoranych zagonach poza ryjowiskiem (po kilka czerwi).
const SOIL_NESTS := 14
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
var _outposts: Array[Vector2] = []
## Rodzaj pola w komórce: "grain" / "stubble" / "soil" (brak wpisu - łąka, droga, siedlisko).
var _field_kind := {}
var _farms: Array[Vector2] = []
## Teren narożników (Vector2i -> nazwa terenu SoftGround); brak wpisu = trawa.
var _corners := {}
var _yard_cells := {}
var _field_cells := {}
## Działka, do której należy komórka (także miedza między działkami), i komórki miedz.
var _owner := {}
var _balk_cells := {}
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
	_plan_outposts(rng)
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
	for outpost in _outposts:
		_build_outpost(rng, outpost)
	_build_worm_grounds(rng)
	_build_soil_nests(rng)
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
		return _free(Vector2i(tile), 8) and Road.distance_to(tile, w._road) > 4.0 and Road.distance_to(tile, w._road) < 26.0
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


## Czaty koboldów z dala od obozu, ryjowiska, wzgórza gryfa, rozstajów i wejścia - tam, gdzie dziś są puste łany
## (środek i wschód krainy). Dróżka do najbliższej drogi.
func _plan_outposts(rng: RandomNumberGenerator) -> void:
	var area := Rect2(Vector2(30, 24), Vector2(w.map_size) - Vector2(60, 48))
	var ok := func(tile: Vector2) -> bool:
		return _far_from_all(tile, _outposts, 44.0) and ((tile - kobolds) / CAMP_RADII).length() > 1.9 and ((tile - worms) / Vector2(40, 28)).length() > 1.0 \
				and tile.distance_to(gryf_hill) > 30.0 and tile.distance_to(cross) > 22.0 and tile.distance_to(entry) > 40.0 \
				and Road.distance_to(tile, w._road) > OUTPOST_RADIUS + 3.0 and _free(Vector2i(tile), int(OUTPOST_RADIUS))
	var taken: Array[Vector2] = _farms.duplicate()
	taken.append_array([kobolds, worms, gryf_hill, cross])
	for i in OUTPOSTS:
		var tile: Vector2 = w._pick_spread(area, taken, ok, 200)
		if not tile.is_finite():
			continue
		_outposts.append(tile)
		taken.append(tile)
		w._reserve_area(tile, OUTPOST_RADIUS + 1.0)
		var nearest: Vector2 = w._road[0]
		for point: Vector2 in w._road:
			if point.distance_squared_to(tile) < nearest.distance_squared_to(tile):
				nearest = point
		_mark_path(Road.wiggle(tile + Vector2(0, OUTPOST_RADIUS * 0.6), nearest, rng, 3.0, 8.0), 0.7, 1.8)


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
			_owner[cell] = owner
			if second - best < BALK:
				_balk_cells[cell] = true
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
	for outpost in _outposts:
		for cell in _ellipse(outpost, Vector2(OUTPOST_RADIUS, OUTPOST_RADIUS * 0.75)):
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
				continue  # miedze urządza _build_balks (żywopłoty, płoty, drobiazgi)
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


## Miedze: na granicach działek żywopłoty (ciągłe linie krzaków z przejściami między polami), w innych płatach
## krainy płoty z żerdzi pod dolnym skrajem pól, część miedz zostaje otwarta. Na miedzach kamienie, kwiaty,
## pojedyncze krzaki i drzewa.
func _build_balks(rng: RandomNumberGenerator) -> void:
	var style := FastNoiseLite.new()
	style.seed = rng.randi()
	style.frequency = 0.04
	# żywopłoty: komórki na granicy działek (sąsiad z prawej albo z dołu należy do innej działki - schodkowa
	# linia zawsze styka się bokami), z przejściami rozstawionymi wzdłuż linii
	var line: Array[Vector2i] = []
	for cell: Vector2i in _balk_cells:
		if style.get_noise_2d(cell.x, cell.y) <= HEDGE_STYLE or not _hedge_allowed(cell):
			continue
		var right: Variant = _owner.get(cell + Vector2i.RIGHT)
		var down: Variant = _owner.get(cell + Vector2i.DOWN)
		if (right != null and right != _owner[cell]) or (down != null and down != _owner[cell]):
			line.append(cell)
	line.sort()
	var gaps: Array[Vector2] = []
	for cell in line:
		if not gaps.any(func(g: Vector2) -> bool: return g.distance_to(Vector2(cell)) < HEDGE_GAP_EVERY):
			gaps.append(Vector2(cell) + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2)))
	var hedge := {}
	for cell in line:
		if not gaps.any(func(g: Vector2) -> bool: return g.distance_to(Vector2(cell)) < HEDGE_GAP_RADIUS):
			hedge[cell] = true
	_build_hedges(rng, hedge)
	# płoty z żerdzi tuż pod dolnym skrajem pól w drugim paśmie stylu (płoty są tylko poziome)
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var n := style.get_noise_2d(x, y)
			if n > HEDGE_STYLE or n <= FENCE_STYLE or not _balk_edge(cell) or hedge.has(cell + Vector2i.DOWN):
				continue
			if x % 2 == 0 and x % 10 != 0 and rng.randf() < 0.85:
				var pos := Vector2((x + 0.5) * TILE, (y + 1) * TILE + 4.0)
				_prop(FENCE, pos, Vector2(FENCE.get_width() - 8, 4)).flip_h = rng.randf() < 0.5
				w._map_props[cell] = MAP_WALL
	# drobiazgi na miedzach: krzaki, kamienie, kwiaty, czasem drzewo
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			if _field_kind.has(cell) or not _near_field(cell) or w._road_clear.has(cell) or w._reserved.has(cell) \
					or w._map_props.get(cell) in [MAP_WALL, MAP_HEDGE]:
				continue
			var r := rng.randf()
			if r < 0.015:
				_tree(rng, cell, 2)
			elif r < 0.3:
				_decor(rng, w._cell_to_world(cell) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-4, 4)), [3, 4, 5, 6, 13, 13, 14].pick_random())


## Czy na komórce miedzy może rosnąć żywopłot: nie na drodze, siedlisku, podwórku ani przy pasie lasu na granicy.
func _hedge_allowed(cell: Vector2i) -> bool:
	var edge := mini(mini(cell.x, cell.y), mini(w.map_size.x - 1 - cell.x, w.map_size.y - 1 - cell.y))
	return edge >= w.border_thickness + 4 and not (w._road_clear.has(cell) or w._reserved.has(cell) \
			or _yard_cells.has(cell) or w._occupied.has(cell))


## Żywopłot: w każdej komórce linii krzak (losowy z trzech, różnej wielkości i odcienia, przesunięty o kilka
## pikseli), a między sąsiednimi komórkami jeszcze jeden w pół drogi - krzaki zachodzą na siebie i schodki linii
## się zacierają. U stóp tu i ówdzie kwiaty, drzewa rosną obok na miedzy. Kolizje w jednym ciele.
func _build_hedges(rng: RandomNumberGenerator, hedge: Dictionary) -> void:
	var body := StaticBody2D.new()
	w.add_child(body)
	var points: Array[Vector2] = []
	for cell: Vector2i in hedge:
		var center := Vector2(cell * TILE) + Vector2(8, 10)
		points.append(center)
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			if hedge.has(cell + d):
				points.append(center + Vector2(d * TILE) * 0.5)
		w._map_props[cell] = MAP_HEDGE
		w._occupied[cell] = true
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		shape.position = center
		body.add_child(shape)
	for point in points:
		var pos := point + Vector2(rng.randf_range(-3, 3), rng.randf_range(-2, 2))
		var bush := Sprite2D.new()
		bush.texture = HEDGE_BUSHES[rng.randi() % HEDGE_BUSHES.size()]
		bush.offset = Vector2(0, -13)
		bush.position = pos.round()
		bush.flip_h = rng.randf() < 0.5
		bush.scale = Vector2.ONE * rng.randf_range(0.85, 1.1)
		var shade := rng.randf_range(0.82, 1.0)
		bush.modulate = Color(shade, shade * rng.randf_range(0.98, 1.04), shade * 0.95)
		w.entities.add_child(bush)
		if rng.randf() < 0.12:
			_decor(rng, pos + Vector2(rng.randf_range(-8, 8), 6), [3, 4, 5].pick_random())


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
	# opuszczone gospodarstwo plądrują koboldy (północ: zgraja przy wyniesionych workach i rozbitych beczkach)
	# albo rozryły czerwie (południe: kopce i nory na podwórku)
	var tile := center + Vector2(0, 2.5)
	if center.y < w.map_size.y * 0.5:
		for i in 3:
			_prop(SACKS if i < 2 else BOMB_CRATE, c + Vector2(rng.randf_range(-60, 60), rng.randf_range(-4, 14)))
		_kobold_group(rng, tile, rng.randi_range(5, 7), false)
		_kobold_group(rng, tile + Vector2(-4.0 * side, 1.5), rng.randi_range(3, 5), false)
	else:
		for i in rng.randi_range(4, 6):
			var pos := (tile + Vector2(rng.randf_range(-5, 5), rng.randf_range(-2, 3))) * TILE
			w._add_goblin_spawn({"type": "field_worm", "position": pos, "sitting": false, "look_at": pos})
			_molehill(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(14, 26))


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
	var area := Rect2(Vector2(10, 8), Vector2(w.map_size) - Vector2(20, 16))
	var ok := func(tile: Vector2) -> bool:
		return ((tile - kobolds) / CAMP_RADII).length() > 1.3 and ((tile - worms) / Vector2(40, 28)).length() > 1.0 \
				and tile.distance_to(gryf_hill) > 24.0 and tile.distance_to(worm_lair) > 16.0 and tile.distance_to(cross) > 10.0 \
				and not w._occupied.has(Vector2i(tile)) and tile.distance_to(entry) > 40.0 \
				and _far_from_all(tile, _outposts, OUTPOST_RADIUS + 6.0) and _far_from_all(tile, _farms, 12.0)
	for i in KOBOLD_GROUPS:
		var tile: Vector2 = w._pick_spread(area, spots, ok)
		if not tile.is_finite():
			continue
		spots.append(tile)
		_kobold_group(rng, tile, rng.randi_range(5, 8), false)
	w._map_markers.append({"position": center, "color": Kobold.KOBOLD_COLOR, "size": 3.0})


## Czata koboldów: wianuszek namiotów wokół ogniska z siedzącą zgrają, stos łupów z gospodarstw (worki, wóz, bele),
## skrzynie bomb, totemy na skraju i zgraje stojące między namiotami - razem około 30 koboldów.
func _build_outpost(rng: RandomNumberGenerator, tile: Vector2) -> void:
	var center := tile * TILE
	var radii := Vector2(OUTPOST_RADIUS, OUTPOST_RADIUS * 0.75) * TILE
	var fire: Node2D = CAMPFIRE.instantiate()
	fire.position = center
	w.entities.add_child(fire)
	w._map_props[Vector2i(tile)] = w.MAP_FIRE
	_kobold_group(rng, tile, rng.randi_range(7, 9), true)
	var turn := rng.randf() * TAU
	for i in OUTPOST_TENTS:
		var pos := center + Vector2.from_angle(turn + TAU * i / OUTPOST_TENTS) * radii * rng.randf_range(0.7, 0.8)
		var tent := _prop(TENT, pos, Vector2(40, 12))
		tent.flip_h = pos.x < center.x
		w._map_props[Vector2i(pos / TILE)] = MAP_TENT
	# luki między namiotami: w tej od strony dróżki (południe) stos łupów, w pozostałych stojące zgraje i skrzynie bomb
	var loot_gap := 0
	for i in OUTPOST_TENTS:
		var angle := turn + TAU * (i + 0.5) / OUTPOST_TENTS
		if absf(angle_difference(angle, PI / 2.0)) < absf(angle_difference(turn + TAU * (loot_gap + 0.5) / OUTPOST_TENTS, PI / 2.0)):
			loot_gap = i
	for i in OUTPOST_TENTS:
		var dir := Vector2.from_angle(turn + TAU * (i + 0.5) / OUTPOST_TENTS)
		if i == loot_gap:
			var loot := center + dir * radii * 0.72
			_prop(CART, loot + Vector2(-22, 0), Vector2(26, 8)).flip_h = rng.randf() < 0.5
			for k in 3:
				_prop(SACKS if k != 1 else HAY_BALE, loot + Vector2(10 + k * 13, rng.randf_range(-6, 6)))
			continue
		_kobold_group(rng, tile + dir * OUTPOST_RADIUS * Vector2(0.62, 0.62 * 0.75), rng.randi_range(4, 6), false)
		if i % 2 == 0:
			_prop(BOMB_CRATE if i % 4 == 0 else POWDER, center + dir * radii * 0.95, Vector2(16, 6))
	for k in 4:
		_prop(TOTEM, center + Vector2.from_angle(turn + TAU * (k + 0.25) / 4.0) * radii * 1.05, Vector2(8, 4))
	for i in 14:
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * radii * rng.randf_range(0.2, 0.95), [7, 8, 11, 12, 15].pick_random())
	w._map_markers.append({"position": center, "color": Kobold.KOBOLD_COLOR, "size": 2.0})


func _far_from_all(tile: Vector2, others: Array[Vector2], min_distance: float) -> bool:
	for other in others:
		if tile.distance_to(other) < min_distance:
			return false
	return true


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
	for attempt in 1000:
		if placed >= WORMS:
			break
		var tile := worms + Vector2.from_angle(rng.randf() * TAU) * Vector2(34, 22) * sqrt(rng.randf())
		var cell := Vector2i(tile)
		if w._occupied.has(cell) or tile.distance_to(worm_lair) < 12.0 or not Rect2(Vector2(6, 6), Vector2(w.map_size) - Vector2(12, 12)).has_point(tile):
			continue
		# czerwie ryją gromadkami (2-4) wokół jednej nory
		_molehill(rng, tile * TILE, true)
		for k in rng.randi_range(2, 4):
			placed += 1
			var pos := (tile + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 3.0)) * TILE
			w._add_goblin_spawn({"type": "field_worm", "position": pos, "sitting": false, "look_at": pos})
			_molehill(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(14, 30))
	for i in 40:
		var tile := worms + Vector2.from_angle(rng.randf() * TAU) * Vector2(38, 25) * sqrt(rng.randf())
		if rng.randf() < 0.55:
			_molehill(rng, tile * TILE)
		else:
			_decor(rng, tile * TILE, [0, 2, 2, 14, 15].pick_random())
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
		_decor(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 90), [0, 14, 15, 15].pick_random())
	w._add_goblin_spawn({"type": "giant_worm", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})


## Gniazda czerwi w zaoranych zagonach w całej krainie (czerwie lubią świeżo zruszoną ziemię): po 3-5 czerwi
## wokół nor i kopców.
func _build_soil_nests(rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2] = []
	var area := Rect2(Vector2(10, 8), Vector2(w.map_size) - Vector2(20, 16))
	var ok := func(tile: Vector2) -> bool:
		return _field_kind.get(Vector2i(tile), "") == "soil" and ((tile - worms) / Vector2(40, 28)).length() > 1.0 \
				and ((tile - kobolds) / CAMP_RADII).length() > 1.2 and tile.distance_to(entry) > 40.0 \
				and tile.distance_to(cross) > 10.0 and not w._occupied.has(Vector2i(tile))
	for i in SOIL_NESTS:
		var tile: Vector2 = w._pick_spread(area, spots, ok, 300)
		if not tile.is_finite():
			continue
		spots.append(tile)
		_molehill(rng, tile * TILE, true)
		for k in rng.randi_range(3, 5):
			var pos := (tile + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.5, 3.5)) * TILE
			w._add_goblin_spawn({"type": "field_worm", "position": pos, "sitting": false, "look_at": pos})
			_molehill(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(12, 24))


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


## Kopczyk świeżej ziemi jak po krecie (tools/fields_art.py) - czasem z wylotem nory czerwia.
func _molehill(rng: RandomNumberGenerator, pos: Vector2, hole := false) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = HOLE if hole or rng.randf() < 0.35 else MOUND
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 3.0)
	sprite.flip_h = rng.randf() < 0.5
	sprite.position = pos.round()
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
