class_name AncientForest
extends Node
## Prastary Las - kraina nad Goblińskim Lasem (wejście w jego prawym dolnym rogu, z prawego
## górnego rogu lasu goblinów). Pod gęstymi koronami ogromnych drzew panuje półmrok, przez
## który przebijają się smugi światła; między paprociami świecą grzyby (rozjarzają się, gdy
## gracz podejdzie), w powietrzu tańczą świetliki. Szlak prowadzi od wejścia przez rozstaje
## (kapliczka Starego Dębu) do trzech siedlisk:
## - na północy i północnym wschodzie: kamienny krąg oplątany pnączami z ołtarzem Leszego, wokół dwa pierścienie
##   prastarych drzew z twarzami (zaatakowane budzą drzewce), przy każdym gromadka drzewców, a w gęstwinie
##   na wschodzie wędrujące stada drzewców,
## - na północnym zachodzie: wielkie leże pająków - sieci na ziemi i między drzewami (spowalniają), dziesiątki
##   kokonów (rozbite wypuszczają pajęczaki), owinięte ofiary, jaja, gromady pająków i sieciarzy na całym
##   obszarze i Królowa Pająków przed ogromną pajęczyną; pojedyncze gniazda pająków także w gęstwinie,
## - na południowym zachodzie: siedlisko bestii - rozproszone, bardzo silne bestie (mini-bossowie), każda
##   w swoim rewirze pełnym śladów pazurów, złamanych drzew i krwi, z watahą wargów, a w głębi leże Biesa
##   otoczone czaszkami na palach.
## Poza siedliskami (gęstwina, _build_thicket i _build_wilds): gniazda pająków i stada drzewców, a dalej zasnute
## polany (pająki rozlane z leża: wielkie sieci, kokony, jaja, ofiary), kręgi drzewców na mchu (omszałe głazy,
## pnie, świecące grzyby) i legowiska wargów (kości, krew, ślady pazurów). Te ostatnie mają własne ziarno
## (_wild_rng), żeby reszta lasu wyglądała jak dawniej, i powstają na końcu (nowe numery miejsc potworów).

const TILE := 16
## Runo z PixelLab (tools/pixellab_sheets.py). Rzędy 7-10: luźne warianty ściółki, liści, mchu
## i korzeni; od rzędu 11 zestawy przejść Wang ściółka -> mech / liście / ścieżka, po 4 rzędy:
## kafelek o masce narożników mask (NW<<3 | NE<<2 | SW<<1 | SE, bit = górny teren) leży
## w kolumnie mask % 4 i rzędzie WANG_ROW + 4 * zestaw + mask / 4.
const SOIL_ROW := 7
const WANG_ROW := 11
enum Ground { SOIL, MOSS, LEAVES, PATH }
## Kolejność zestawów Wang w atlasie i pierwszeństwo przy spotkaniu dwóch terenów w jednej komórce.
const WANG_SET := {Ground.MOSS: 0, Ground.LEAVES: 1, Ground.PATH: 2}
const PRIORITY := [Ground.PATH, Ground.MOSS, Ground.LEAVES]
const MAP_FLOOR := Color("33291f")
const MAP_PATH := Color("6a5236")
const MAP_LEAVES := Color("5a3a20")
const MAP_MOSS := Color("3e6a2a")
const MAP_GIANT := Color("123018")
const MAP_WEB := Color("b8b8c8")
## Półmrok pod koronami - lżejszy niż na początku, żeby wrogowie byli czytelni (klimat dają smugi światła).
const SHADE := Color(0.02, 0.06, 0.03, 0.2)

## Olbrzymy (ok. 6 postaci wzrostu) i wysokie drzewa lasu (ok. 3,5 postaci) - korony robią się półprzezroczyste,
## gdy gracz wejdzie za nie (World/Occlusion); kolizję ma tylko pień.
const GIANT_TREES: Array[Texture2D] = [preload("res://assets/ancient/v2_colossal_0.png"), preload("res://assets/ancient/v2_colossal_1.png"),
		preload("res://assets/ancient/v2_colossal_2.png")]
const TALL_TREES: Array[Texture2D] = [preload("res://assets/ancient/v2_tall_0.png"), preload("res://assets/ancient/v2_tall_1.png"),
		preload("res://assets/ancient/v2_tall_2.png"), preload("res://assets/ancient/v2_tall_3.png")]
## Część drzew w głębi lasu to wysokie drzewa (reszta - zwykłe dęby i sosny, które można ścinać).
const TALL_CHANCE := 0.4
## Jak głęboko pod podstawą pnia sięgają korzenie na grafice (px).
const GIANT_ROOTS := 24.0
const TALL_ROOTS := 8.0
const FOREST_EXTRAS: Array[Texture2D] = [preload("res://assets/ancient/v2_boulder.png"), preload("res://assets/ancient/v2_mossy_rocks.png"),
		preload("res://assets/ancient/v2_roots.png"), preload("res://assets/ancient/v2_fallen_trunk.png"),
		preload("res://assets/ancient/v2_mushroom_ring.png"), preload("res://assets/ancient/v2_ferns.png"),
		preload("res://assets/ancient/v2_stump.png"), preload("res://assets/ancient/v2_hollow_log.png"),
		preload("res://assets/ancient/v2_tall_grass.png")]
const MENHIRS: Array[Texture2D] = [preload("res://assets/ancient/menhir_0.png"), preload("res://assets/ancient/menhir_1.png"),
		preload("res://assets/ancient/menhir_2.png")]
const ALTAR := preload("res://assets/ancient/altar_stump.png")
const LOG := preload("res://assets/ancient/fallen_log.png")
const DECOR := preload("res://assets/ancient/decor.png")
const DECOR_FRAMES := 25
## Drobiazgi runa mają płótno 32x32 ze stopą ok. 4 px nad dołem.
const DECOR_OFFSET := -12.0
const WEB_BIG := preload("res://assets/ancient/web_big.png")
const WEB_SMALL := preload("res://assets/ancient/web_small.png")
const WEB_HUGE := preload("res://assets/ancient/web_huge.png")
const VICTIM := preload("res://assets/ancient/wrapped_victim.png")
const EGG_SAC := preload("res://assets/ancient/egg_sac.png")
const CLAW_TREE := preload("res://assets/ancient/v2_claw_tree.png")
const CLAW_STUMP := preload("res://assets/ancient/v2_claw_stump.png")
const SCRATCHES := preload("res://assets/ancient/scratches.png")
const BLOOD := preload("res://assets/ancient/blood.png")
const SKULL_TOTEM := preload("res://assets/ancient/skull_totem.png")
const WEB_TANGLE := preload("res://assets/ancient/web_tangle.png")
const BONE_PILE := preload("res://assets/ancient/bone_pile.png")
const MOSSY_ROCK := preload("res://assets/ancient/mossy_rock.png")
const ROTTEN_STUMP := preload("res://assets/ancient/rotten_stump.png")
## Ślady poszukiwaczy przygód, którzy tu nie wrócili: czaszka, miecz, dzban, kości, latarnia, plecak.
const REMAINS := preload("res://assets/ancient/remains.png")
const REMAINS_FRAMES := 6
const OAK := preload("res://scenes/props/tree_ancient_oak.tscn")
const PINE := preload("res://scenes/props/tree_ancient_pine.tscn")
const THORN_BUSH := preload("res://scenes/props/thorn_bush.tscn")
const MAP_OAK := Color("1c3a22")
const MAP_PINE := Color("16302a")

const ANCIENT_TREES := 12
const SPIDER_GROUPS := 18
const COCOONS := 34
const BEASTS := 8
## Leże pająków: półosie (w kafelkach); gniazda pająków i stada drzewców w gęstwinie poza siedliskami.
const LAIR_RADII := Vector2(30, 21)
const SPIDER_NESTS := 7
const TREANT_HERDS := 8
const SHROOMS := 46
const LOGS := 14
const WEB_TRAPS := 20
## Dzikie ostępy poza siedliskami (_build_wilds): zasnute polany, kręgi drzewców i legowiska wargów.
const WEB_GLADES := 6
const TREANT_CIRCLES := 5
const WARG_DENS := 8

var w  # świat
var entry_x := 0.0
var leshy := Vector2.ZERO
var lair := Vector2.ZERO
var bies := Vector2.ZERO
var beast_area := Rect2()
var _cross := Vector2.ZERO
var _ancient_spots: Array[Vector2] = []
var _beast_spots: Array[Vector2] = []
var _webs: Array = []  # [środek w pikselach, promień]
var _lair_radii := LAIR_RADII
## Teren w wierzchołkach siatki kafelków (brak wpisu = ściółka).
var _corners := {}
## Miejsca (w kafelkach) z mchem pod ogromnymi drzewami, żeby ich podstawa wtapiała się w runo.
var _moss_spots: Array[Vector2] = []
var _moss_near := {}
var _player: Node2D
var _fireflies: Array[CPUParticles2D] = []
## Dzikie ostępy: [rodzaj ("glade" / "circle" / "den"), środek w kafelkach].
var _wilds: Array = []
var _wild_rng := RandomNumberGenerator.new()


func generate(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	_player = w.player
	Goblin.safe_zone = Rect2()
	entry_x = size.x - 18.0
	_cross = Vector2(size.x * 0.54, size.y * 0.64)
	leshy = Vector2(size.x * 0.62, size.y * 0.27)
	lair = Vector2(size.x * 0.19, size.y * 0.23)
	bies = Vector2(size.x * 0.17, size.y * 0.8)
	beast_area = Rect2(size * Vector2(0.06, 0.55), size * Vector2(0.38, 0.38))

	# szlak: od wejścia na rozstaje i dalej pod krąg Leszego; ścieżki do pająków i bestii
	w._road = Road.wiggle(Vector2(entry_x, size.y - 1), _cross, rng, 5.0, 11.0)
	w._road.append_array(Road.wiggle(_cross, leshy + Vector2(0, 14), rng, 5.0, 11.0))
	_mark_path(w._road, 1.3, 2.8)
	_mark_path(Road.wiggle(_cross, lair + Vector2(18, 14), rng, 5.0, 11.0), 0.9, 2.2)
	_mark_path(Road.wiggle(_cross, Vector2(beast_area.end.x - 6, beast_area.get_center().y), rng, 5.0, 11.0), 0.9, 2.2)
	# ścieżka na cmentarz losowana osobno - reszta lasu zostaje taka jak była
	var trail_rng := RandomNumberGenerator.new()
	trail_rng.seed = hash([w._seed, "cemetery_trail"])
	_mark_path(Road.wiggle(_cross, Vector2(size.x * 0.4, 0.0), trail_rng, 5.0, 10.0), 0.9, 2.2)

	var shrine_tile := _cross + Vector2(4.5, -4.0)
	w._reserve_area(shrine_tile, 3.0)
	w._reserve_area(leshy, 11.0)
	w._reserve_area(lair, 10.0)
	_lair_radii = LAIR_RADII
	w._reserve_area(bies, 7.0)
	_plan_ancient_trees(rng)
	_plan_beasts(rng)
	_plan_wilds()

	_place_forest(rng)
	_build_ground(rng)
	w._build_bounds()
	_build_leshy_grove(rng)
	_build_spider_lair(rng)
	_build_beast_habitat(rng)
	_build_thicket(rng)
	_build_atmosphere(rng)
	_build_wilds()

	var shrine: Node2D = w.SHRINE.instantiate()
	shrine.position = shrine_tile * TILE
	w.entities.add_child(shrine)
	w._register_shrine("old_oak", shrine.position)
	w._map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	w._spawn_point = shrine.position + Vector2(0, 20)
	w._add_exit(Rect2(entry_x - 4.5, size.y - 3.5, 9, 3.5), "forest", "from:ancient", Vector2(entry_x - 3.0, size.y - 5.0))
	# ścieżka od rozstajów na północ - do Leśnego Cmentarza
	var gate_x := size.x * 0.4
	w._add_exit(Rect2(gate_x - 4.5, 0, 9, 3.5), "cemetery", "from:ancient", Vector2(gate_x + 3.0, 5.0))
	w._arrivals["from:cemetery"] = Vector2(gate_x, 8.0) * TILE
	w._arrivals["from:forest"] = Vector2(entry_x, size.y - 7.0) * TILE


func _mark_path(points: PackedVector2Array, road: float, clear: float) -> void:
	for point in points:
		for cell in w._cells_in_radius(point, road):
			w._road_cells[cell] = true
		for cell in w._cells_in_radius(point, clear):
			w._road_clear[cell] = true


# ---------------------------------------------------------------- plan
func _plan_ancient_trees(rng: RandomNumberGenerator) -> void:
	var base := rng.randf() * TAU
	for i in ANCIENT_TREES:
		var outer := i % 2 == 1
		var angle := base + TAU * i / ANCIENT_TREES + rng.randf_range(-0.15, 0.15)
		var spot := leshy + Vector2.from_angle(angle) * (Vector2(46, 30) if outer else Vector2(28, 19)) * rng.randf_range(0.9, 1.05)
		spot = spot.clamp(Vector2(12, 12), Vector2(w.map_size) - Vector2(12, 12))
		_ancient_spots.append(spot)
		_moss_spots.append(spot)
		w._reserve_area(spot, 4.5)


func _plan_beasts(rng: RandomNumberGenerator) -> void:
	var ok := func(tile: Vector2) -> bool:
		return tile.distance_to(bies) > 20.0 and Road.distance_to(tile, w._road) > 6.0
	for i in BEASTS:
		var tile: Vector2 = w._pick_spread(beast_area, _beast_spots, ok)
		if not tile.is_finite():
			continue
		_beast_spots.append(tile)
		w._reserve_area(tile, 5.0)


## Dzikie ostępy: z dala od szlaku, rozstajów, wejścia, siedlisk i siebie nawzajem; najpierw kręgi drzewców
## (mech pod nimi kładzie się z runem), potem polany i legowiska. Rezerwacja bez drzew.
func _plan_wilds() -> void:
	_wild_rng.seed = hash([w._seed, "ancient_wilds"])
	var size := Vector2(w.map_size)
	var entry := Vector2(entry_x, size.y)
	var kinds: Array[String] = []
	for i in TREANT_CIRCLES:
		kinds.append("circle")
	for i in WEB_GLADES:
		kinds.append("glade")
	for i in WARG_DENS:
		kinds.append("den")
	var taken: Array[Vector2] = [leshy, lair, bies, _cross]
	taken.append_array(_beast_spots)
	taken.append_array(_ancient_spots)
	for kind in kinds:
		for attempt in 120:
			var tile := Vector2(_wild_rng.randf_range(14.0, size.x - 14.0), _wild_rng.randf_range(12.0, size.y - 12.0))
			if Road.distance_to(tile, w._road) < 8.0 or tile.distance_to(entry) < 30.0 or tile.distance_to(_cross) < 18.0:
				continue
			if tile.distance_to(leshy) < 50.0 or ((tile - lair) / _lair_radii).length() < 1.5 or tile.distance_to(bies) < 16.0:
				continue
			# legowiska wargów mogą stać przy bestiach (ich watahy), reszta poza siedliskiem bestii
			if kind != "den" and beast_area.grow(4.0).has_point(tile):
				continue
			if taken.any(func(other: Vector2) -> bool: return other.distance_to(tile) < 17.0):
				continue
			var room := 7.0 if kind == "circle" else 5.5
			if w._cells_in_radius(tile, room).any(func(cell: Vector2i) -> bool: return w._reserved.has(cell) or w._road_clear.has(cell)):
				continue
			taken.append(tile)
			_wilds.append([kind, tile])
			w._reserve_area(tile, room)
			if kind == "circle":
				_moss_spots.append(tile)
				for k in 8:
					_moss_spots.append(tile + Vector2.from_angle(TAU * k / 8.0) * 4.0)
			break


# ---------------------------------------------------------------- teren
## Runo: najpierw rodzaj terenu w każdym wierzchołku siatki (plamy mchu i liści z szumu, mech
## pod ogromnymi drzewami i w kręgu Leszego, ścieżki), potem każda komórka dostaje kafelek
## przejścia Wang pasujący do jej czterech narożników - granice terenów są miękkie i nieregularne.
func _build_ground(rng: RandomNumberGenerator) -> void:
	var patch := FastNoiseLite.new()
	patch.seed = rng.randi()
	patch.frequency = 0.08
	# odległość wierzchołków od najbliższego drzewa z mchem u stóp
	for spot in _moss_spots:
		for c in w._cells_in_radius(spot, 3.6):
			_moss_near[c] = minf(_moss_near.get(c, INF), Vector2(c).distance_to(spot))
	for y in w.map_size.y + 1:
		for x in w.map_size.x + 1:
			var corner := Vector2i(x, y)
			var kind := _corner_ground(corner, patch.get_noise_2d(x, y), rng)
			if kind != Ground.SOIL:
				_corners[corner] = kind
	# w jednej komórce może spotkać się ściółka z tylko jednym innym terenem
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var kinds := {}
			for c in _cell_corners(cell):
				kinds[_corners.get(c, Ground.SOIL)] = true
			kinds.erase(Ground.SOIL)
			if kinds.size() < 2:
				continue
			var keep: int = PRIORITY.filter(func(k: int) -> bool: return kinds.has(k))[0]
			for c in _cell_corners(cell):
				if _corners.get(c, Ground.SOIL) != keep:
					_corners.erase(c)
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			w.ground.set_cell(cell, 0, _cell_tile(cell, patch.get_noise_2d(x * 1.7, y * 1.7), rng))


func _corner_ground(corner: Vector2i, n: float, rng: RandomNumberGenerator) -> int:
	# ścieżka tam, gdzie co najmniej dwie z czterech sąsiednich komórek są drogą
	var road := 0
	var clear := 0
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		road += int(w._road_cells.has(corner + d))
		clear += int(w._road_clear.has(corner + d))
	if road >= 2:
		return Ground.PATH
	var point := Vector2(corner)
	if point.distance_to(leshy) < 9.0:
		return Ground.MOSS if n > -0.3 else Ground.SOIL
	if _moss_near.get(corner, INF) < 2.6 + n:
		return Ground.MOSS
	if clear >= 2 and rng.randf() < 0.3:
		return Ground.LEAVES
	if n > 0.32:
		return Ground.LEAVES
	if n < -0.32:
		return Ground.MOSS
	return Ground.SOIL


## Wierzchołki komórki w kolejności NW, NE, SW, SE.
func _cell_corners(cell: Vector2i) -> Array[Vector2i]:
	return [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]


func _cell_tile(cell: Vector2i, n: float, rng: RandomNumberGenerator) -> Vector2i:
	var kind := Ground.SOIL
	var mask := 0
	var bit := 8
	for c in _cell_corners(cell):
		var corner_kind: int = _corners.get(c, Ground.SOIL)
		if corner_kind != Ground.SOIL:
			kind = corner_kind
			mask |= bit
		bit >>= 1
	if kind == Ground.SOIL:
		# czysta ściółka: czasem wystające korzenie, poza tym jeden z trzech wariantów ziemi
		return Vector2i(0, WANG_ROW + 4 * (rng.randi() % WANG_SET.size()))
	var row := WANG_ROW + 4 * int(WANG_SET[kind]) + mask / 4
	return Vector2i(mask % 4, row)


## Kolor kafelka na mapie (dla World._build_map_texture).
static func map_color(atlas: Vector2i) -> Color:
	if atlas.y < WANG_ROW:
		return MAP_FLOOR
	var set_index := (atlas.y - WANG_ROW) / 4
	var mask := (atlas.y - WANG_ROW) % 4 * 4 + atlas.x
	var covered := 0
	for i in 4:
		covered += (mask >> i) & 1
	if covered < 2:
		return MAP_FLOOR
	return [MAP_MOSS, MAP_LEAVES, MAP_PATH][set_index]


## Las: brzegi i całe połacie gęstych drzew, ogromne drzewa, paprocie, powalone pnie.
func _place_forest(rng: RandomNumberGenerator) -> void:
	var dense := FastNoiseLite.new()
	dense.seed = rng.randi()
	dense.frequency = 0.05
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var edge_dist := mini(mini(x, y), mini(w.map_size.x - 1 - x, w.map_size.y - 1 - y))
			if w._road_clear.has(cell):
				if not w._road_cells.has(cell):
					_decor(rng, cell, 0.04)
				continue
			if w._reserved.has(cell):
				_decor(rng, cell, 0.035)
				continue
			if edge_dist < w.border_thickness + 1:
				if rng.randf() < 0.85 - edge_dist * 0.1:
					_plant(rng, cell, 0.5, 1)
				continue
			var d := dense.get_noise_2d(x, y)
			var r := rng.randf()
			if r < 0.016:
				_giant_tree(rng, cell)
			elif r < 0.02 and not w._occupied.has(cell) and _free_area(cell, 1, 1):
				# omszałe głazy, korzenie, powalone pnie, krąg grzybów, paprocie
				_mark(cell, 1, 1)
				var extra := FOREST_EXTRAS[rng.randi() % FOREST_EXTRAS.size()]
				var blocking := extra in [FOREST_EXTRAS[0], FOREST_EXTRAS[1], FOREST_EXTRAS[3], FOREST_EXTRAS[7]]
				_prop(extra, w._cell_to_world(cell), Vector2(22, 7) if blocking else Vector2.ZERO).flip_h = rng.randf() < 0.5
			elif d > 0.1 and r < 0.13:
				_plant(rng, cell, 0.65, 2)
			elif r < 0.032:
				_plant(rng, cell, 0.65, 2)
			elif r < 0.045:
				w._try_place(THORN_BUSH, cell, 1)
			elif r < 0.049 and _free_area(cell, 1, 1):
				_mark(cell, 1, 0)
				_prop(MOSSY_ROCK if rng.randf() < 0.5 else ROTTEN_STUMP, w._cell_to_world(cell), Vector2(28, 8)).flip_h = rng.randf() < 0.5
			else:
				_decor(rng, cell, 0.035)
	var placed := 0
	for attempt in 200:  # powalone, omszałe pnie
		if placed >= LOGS:
			break
		var cell := Vector2i(rng.randi_range(8, w.map_size.x - 8), rng.randi_range(8, w.map_size.y - 8))
		if _free_area(cell, 3, 1):
			_mark(cell, 3, 1)
			_prop(LOG, w._cell_to_world(cell), Vector2(50, 8)).flip_h = rng.randf() < 0.5
			placed += 1


## Zwykłe drzewo Prastarego Lasu (do ścięcia): liściaste albo iglaste. Drzewa są duże, więc
## w głębi lasu trzymają odstęp `spacing` kafelków (na brzegach mapy rosną ciaśniej).
func _plant(rng: RandomNumberGenerator, cell: Vector2i, oak_chance: float, spacing: int) -> void:
	var oak := rng.randf() < oak_chance
	if w._occupied.has(cell):
		return
	# w głębi lasu część drzew to wysokie drzewa (bez ścinania); na brzegach mapy zwykłe
	if spacing > 1 and rng.randf() < TALL_CHANCE:
		if not _free_area(cell, 1, 1):
			return
		_mark(cell, 1, 1)
		var tall := _prop(TALL_TREES[rng.randi() % TALL_TREES.size()], w._cell_to_world(cell), Vector2(14, 7))
		tall.flip_h = rng.randf() < 0.5
		_raise_sort(tall, TALL_ROOTS)
		_moss_spots.append(Vector2(cell) + Vector2(0.5, 0.5))
		w._map_props[cell] = MAP_OAK
		return
	w._try_place(OAK if oak else PINE, cell, spacing)
	if w._occupied.has(cell):
		w._map_props[cell] = MAP_OAK if oak else MAP_PINE


func _giant_tree(rng: RandomNumberGenerator, cell: Vector2i) -> void:
	if not _free_area(cell, 4, 3):
		return
	_mark(cell, 4, 3)
	_moss_spots.append(Vector2(cell) + Vector2(0.5, 0.5))
	var sprite: Sprite2D = _prop(GIANT_TREES[rng.randi() % GIANT_TREES.size()], w._cell_to_world(cell), Vector2(34, 12))
	sprite.flip_h = rng.randf() < 0.5
	_raise_sort(sprite, GIANT_ROOTS)
	for dy in range(-1, 1):
		for dx in range(-1, 2):
			w._map_props[cell + Vector2i(dx, dy)] = MAP_GIANT


## Korzenie drzewa rozchodzą się poniżej pnia - punkt sortowania (i kolizja) podniesione do podstawy pnia,
## żeby rzeczy stojące przed pniem (na korzeniach) rysowały się przed drzewem, a nie za nim.
func _raise_sort(sprite: Sprite2D, roots: float) -> void:
	var body := sprite.get_parent() as Node2D
	if body == null or not body is StaticBody2D:
		return
	body.position.y -= roots
	sprite.offset.y += roots


func _free_area(cell: Vector2i, rx: int, ry: int) -> bool:
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			var c := cell + Vector2i(dx, dy)
			if w._occupied.has(c) or w._reserved.has(c) or w._road_clear.has(c):
				return false
	return true


func _mark(cell: Vector2i, rx: int, ry: int) -> void:
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			w._occupied[cell + Vector2i(dx, dy)] = true


func _decor(rng: RandomNumberGenerator, cell: Vector2i, chance: float) -> void:
	if rng.randf() >= chance:
		return
	var sprite := Sprite2D.new()
	sprite.texture = DECOR
	sprite.hframes = DECOR_FRAMES
	sprite.frame = rng.randi() % DECOR_FRAMES
	sprite.flip_h = rng.randf() < 0.5
	# paprocie i grzyby mają wysokość - sortują się z drzewami, żeby nie chować się za tym, co dalej
	sprite.offset = Vector2(0, DECOR_OFFSET)
	sprite.position = w._cell_to_world(cell) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-6, 2))
	w.entities.add_child(sprite)


func _floor(texture: Texture2D, pos: Vector2, rotation := 0.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.rotation = rotation
	w.floors.add_child(sprite)
	return sprite


## Rekwizyt jak World._village_prop, ale grafika schodzi o PropSinks poniżej punktu
## sortowania - gra rysuje drzewo przed tym, co stoi za pniem, a nie za końcem korzeni.
func _prop(texture: Texture2D, pos: Vector2, collision := Vector2.ZERO, frames := 1) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(texture, pos, collision, frames)
	sprite.offset.y += PropSinks.of(texture)
	return sprite


## Szczątki poszukiwacza przygód (drobna grafika na ziemi).
func _remains(rng: RandomNumberGenerator, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = REMAINS
	sprite.hframes = REMAINS_FRAMES
	sprite.frame = rng.randi() % REMAINS_FRAMES
	sprite.flip_h = rng.randf() < 0.5
	sprite.offset = Vector2(0, DECOR_OFFSET)
	sprite.position = pos
	w.entities.add_child(sprite)


func _shroom(pos: Vector2) -> void:
	var shroom := GlowShroom.new()
	shroom.position = pos
	w.entities.add_child(shroom)


# ---------------------------------------------------------------- krąg Leszego i prastare drzewa
func _build_leshy_grove(rng: RandomNumberGenerator) -> void:
	var center := leshy * TILE
	# kamienny krąg oplątany pnączami; runy na kamieniach pulsują
	for i in 10:
		var angle := TAU * i / 10.0
		var spot := center + Vector2.from_angle(angle) * Vector2(128, 96)
		var stone: Sprite2D = _prop(MENHIRS[i % MENHIRS.size()], spot, Vector2(22, 8), 2)
		_pulse(stone, rng.randf_range(1.5, 3.0))
	_prop(ALTAR, center + Vector2(0, -40), Vector2(44, 10))
	for i in 8:  # pierścień świecących grzybów wewnątrz kręgu
		_shroom(center + Vector2.from_angle(TAU * i / 8.0 + 0.2) * Vector2(70, 52))
	w._add_goblin_spawn({"type": "leshy", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})
	# prastare drzewa z twarzami, przy każdym para wędrujących drzewców
	for spot in _ancient_spots:
		var pos := spot * TILE
		w._add_goblin_spawn({"type": "ancient_tree", "position": pos, "sitting": false, "look_at": pos})
		w._map_markers.append({"position": pos, "color": AncientTree.TREE_COLOR, "size": 3.0})
		for k in 4:
			var walker := pos + Vector2.from_angle(TAU * k / 4.0 + rng.randf_range(-0.4, 0.4)) * rng.randf_range(48.0, 70.0)
			w._add_goblin_spawn({"type": "treant", "position": walker, "sitting": false, "look_at": pos})
		for k in 2:
			_shroom(pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(44, 70))


## Powolne pulsowanie runy (dwie klatki).
func _pulse(sprite: Sprite2D, period: float) -> void:
	var timer := Timer.new()
	timer.wait_time = period
	timer.autostart = true
	timer.timeout.connect(func() -> void: sprite.frame = (sprite.frame + 1) % 2)
	sprite.add_child(timer)


# ---------------------------------------------------------------- leże pająków
func _build_spider_lair(rng: RandomNumberGenerator) -> void:
	var center := lair * TILE
	# Królowa przed ogromną pajęczyną rozpiętą między martwymi pniami
	_prop(WEB_HUGE, center + Vector2(0, -56), Vector2(110, 10))
	w._add_goblin_spawn({"type": "spider_queen", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})
	for i in 4:
		_prop(EGG_SAC, center + Vector2.from_angle(PI + i * 0.5) * Vector2(80, 50))
	# gromady pająków i sieciarzy
	var base := rng.randf() * TAU
	for i in SPIDER_GROUPS:
		var angle := base + TAU * i / SPIDER_GROUPS
		var spot := (lair + Vector2.from_angle(angle) * _lair_radii * (0.45 if i % 2 == 0 else 0.8) * rng.randf_range(0.85, 1.1)) * TILE
		for k in rng.randi_range(6, 8):
			var pos := spot + Vector2(rng.randf_range(-24, 24), rng.randf_range(-18, 18))
			w._add_goblin_spawn({"type": "web_spider" if k % 3 == 1 else "spider", "position": pos, "sitting": false, "look_at": spot})
	# kokony, owinięte ofiary, jaja i sieci na ziemi
	for i in COCOONS:
		var pos := (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * 0.9 * sqrt(rng.randf())) * TILE
		w._add_goblin_spawn({"type": "cocoon", "position": pos, "sitting": false, "look_at": pos, "respawn": 120.0})
	for i in 5:
		_remains(rng, (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * 0.85 * sqrt(rng.randf())) * TILE)
	for i in 7:
		_prop(VICTIM, (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * 0.85 * sqrt(rng.randf())) * TILE)
	for i in 6:
		_prop(EGG_SAC, (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * 0.85 * sqrt(rng.randf())) * TILE)
	for i in 70:
		var pos := (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * sqrt(rng.randf())) * TILE
		var roll := rng.randf()
		var web := _floor(WEB_SMALL if roll < 0.55 else (WEB_TANGLE if roll < 0.8 else WEB_BIG), pos, rng.randf() * TAU)
		web.modulate.a = 0.75
		if roll >= 0.55:
			web.scale = Vector2.ONE * 0.5
		w._map_props[Vector2i(pos / TILE)] = MAP_WEB
	# lepkie sieci-pułapki: kto w nie wejdzie, grzęźnie (spowolnienie)
	for i in WEB_TRAPS:
		var pos := (lair + Vector2.from_angle(rng.randf() * TAU) * _lair_radii * 0.9 * rng.randf_range(0.35, 1.0)) * TILE
		var web := _floor(WEB_BIG, pos, rng.randf() * TAU)
		web.scale = Vector2.ONE * 0.6
		_webs.append([pos, 30.0])


# ---------------------------------------------------------------- siedlisko bestii
func _build_beast_habitat(rng: RandomNumberGenerator) -> void:
	# leże Biesa: krąg czaszek na palach, krew i kości
	var center := bies * TILE
	for i in 8:
		var angle := TAU * i / 8.0
		_prop(SKULL_TOTEM, center + Vector2.from_angle(angle) * Vector2(92, 68), Vector2(6, 3))
	for i in 6:
		_floor(BLOOD, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 60), rng.randf() * TAU)
		_floor(SCRATCHES, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 70), rng.randf() * TAU)
	for i in 3:
		_prop(BONE_PILE, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 70))
	for i in 4:
		_remains(rng, center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 80))
	w._add_goblin_spawn({"type": "bies", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})
	# rozproszone bestie, każda w swoim rewirze pełnym śladów walki
	for i in _beast_spots.size():
		var pos := _beast_spots[i] * TILE
		w._add_goblin_spawn({"type": "beast_bear" if i % 2 == 0 else "beast_werewolf", "position": pos, "sitting": false,
				"look_at": pos, "respawn": 240.0})
		w._map_markers.append({"position": pos, "color": Color(0.85, 0.45, 0.3), "size": 3.0})
		for k in 2:
			_prop(CLAW_TREE, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(50, 72), Vector2(14, 6))
		_prop(CLAW_STUMP, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(50, 70), Vector2(14, 6))
		for k in 4:
			_floor(SCRATCHES, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 50), rng.randf() * TAU)
		for k in 2:
			_floor(BLOOD, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 45), rng.randf() * TAU)
		_prop(BONE_PILE, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25, 50))
		_remains(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(15, 45))
		# wataha wargów krążąca przy bestii
		var pack := pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(70.0, 100.0)
		for k in rng.randi_range(5, 7):
			w._add_goblin_spawn({"type": "warg", "position": pack + Vector2(rng.randf_range(-26, 26), rng.randf_range(-18, 18)),
					"sitting": false, "look_at": pos})


# ---------------------------------------------------------------- gęstwina
## Poza siedliskami (z dala od drogi): gniazda pająków (sieci, kokony, gromada pająków i sieciarzy) i stada
## wędrujących drzewców - wschodnia i środkowa część lasu też żyje.
func _build_thicket(rng: RandomNumberGenerator) -> void:
	var size := Vector2(w.map_size)
	var area := Rect2(Vector2(12, 10), size - Vector2(24, 22))
	var taken: Array[Vector2] = [leshy, lair, bies, _cross]
	taken.append_array(_beast_spots)
	var ok := func(tile: Vector2) -> bool:
		return Road.distance_to(tile, w._road) > 7.0 and tile.distance_to(leshy) > 52.0 \
				and ((tile - lair) / _lair_radii).length() > 1.4 and not beast_area.grow(4.0).has_point(tile) \
				and not w._reserved.has(Vector2i(tile))
	var spots: Array[Vector2] = []
	for i in SPIDER_NESTS + TREANT_HERDS:
		var tile: Vector2 = w._pick_spread(area, taken + spots, ok)
		if not tile.is_finite():
			continue
		spots.append(tile)
		var pos := tile * TILE
		if i < SPIDER_NESTS:
			for k in 6:
				var web := _floor(WEB_SMALL if k % 2 == 0 else WEB_TANGLE, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0, 60), rng.randf() * TAU)
				web.modulate.a = 0.7
				if k % 2 == 1:
					web.scale = Vector2.ONE * 0.5
			_prop(EGG_SAC, pos + Vector2(rng.randf_range(-30, 30), rng.randf_range(-20, 20)))
			for k in 3:
				var at := pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 60)
				w._add_goblin_spawn({"type": "cocoon", "position": at, "sitting": false, "look_at": at, "respawn": 120.0})
			for k in rng.randi_range(7, 9):
				var at := pos + Vector2(rng.randf_range(-36, 36), rng.randf_range(-26, 26))
				w._add_goblin_spawn({"type": "web_spider" if k % 3 == 1 else "spider", "position": at, "sitting": false, "look_at": pos})
		else:
			for k in rng.randi_range(5, 7):
				var at := pos + Vector2(rng.randf_range(-44, 44), rng.randf_range(-30, 30))
				w._add_goblin_spawn({"type": "treant", "position": at, "sitting": false, "look_at": pos})
			for k in 3:
				_shroom(pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 70))


## Dzikie ostępy zaplanowane w _plan_wilds.
func _build_wilds() -> void:
	var rng := _wild_rng
	for wild: Array in _wilds:
		var pos: Vector2 = wild[1] * TILE
		match str(wild[0]):
			"glade":
				_build_web_glade(rng, pos)
			"circle":
				_build_treant_circle(rng, pos)
			"den":
				_build_warg_den(rng, pos)


## Zasnuta polana: wielka sieć między pniami, sieci na ziemi, kokony, jaja, owinięta ofiara, szczątki
## i dwie gromady pająków z sieciarzami.
func _build_web_glade(rng: RandomNumberGenerator, pos: Vector2) -> void:
	_prop(WEB_BIG, pos + Vector2(0, -50), Vector2(60, 8))
	for k in 10:
		var web := _floor(WEB_SMALL if k % 3 != 2 else WEB_TANGLE, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0, 70), rng.randf() * TAU)
		web.modulate.a = 0.75
		if k % 3 == 2:
			web.scale = Vector2.ONE * 0.5
		w._map_props[Vector2i(web.position / TILE)] = MAP_WEB
	_prop(VICTIM, pos + Vector2(rng.randf_range(-50, 50), rng.randf_range(-30, 10)))
	for k in 2:
		_prop(EGG_SAC, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 60))
	_remains(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 60))
	for k in 4:
		var at := pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(24, 66)
		w._add_goblin_spawn({"type": "cocoon", "position": at, "sitting": false, "look_at": at, "respawn": 120.0})
	var web_trap := _floor(WEB_BIG, pos + Vector2(rng.randf_range(-30, 30), rng.randf_range(10, 40)), rng.randf() * TAU)
	web_trap.scale = Vector2.ONE * 0.6
	_webs.append([web_trap.position, 30.0])
	for side in [-1.0, 1.0]:
		var spot := pos + Vector2(side * 62.0, 22.0)
		for k in rng.randi_range(5, 6):
			var at := spot + Vector2(rng.randf_range(-26, 26), rng.randf_range(-20, 20))
			w._add_goblin_spawn({"type": "web_spider" if k % 3 == 1 else "spider", "position": at, "sitting": false, "look_at": pos})
	w._map_markers.append({"position": pos, "color": MAP_WEB, "size": 2.0})


## Krąg drzewców: drzewce stoją kręgiem zwrócone do środka (jakby radziły), między nimi omszałe głazy
## i spróchniałe pnie, w środku powalony pień i świecące grzyby; pod spodem mech.
func _build_treant_circle(rng: RandomNumberGenerator, pos: Vector2) -> void:
	var n := rng.randi_range(8, 10)
	var turn := rng.randf() * TAU
	for k in n:
		var angle := turn + TAU * k / n
		w._add_goblin_spawn({"type": "treant", "position": pos + Vector2.from_angle(angle) * Vector2(76, 54), "sitting": false, "look_at": pos})
		if k % 3 == 0:
			var between := angle + PI / n
			_prop(MOSSY_ROCK if k % 2 == 0 else ROTTEN_STUMP, pos + Vector2.from_angle(between) * Vector2(98, 70), Vector2(14, 6))
	_prop(LOG, pos + Vector2(0, 4), Vector2(40, 8)).flip_h = rng.randf() < 0.5
	for k in 5:
		_shroom(pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(16, 40))
	w._map_markers.append({"position": pos, "color": MAP_MOSS, "size": 2.0})


## Legowisko wargów: kości, krew, ślady pazurów, drapane drzewo, szczątki; część watahy leży, reszta stoi.
func _build_warg_den(rng: RandomNumberGenerator, pos: Vector2) -> void:
	_prop(BONE_PILE, pos + Vector2(rng.randf_range(-16, 16), -10))
	_prop(CLAW_STUMP, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(56, 70), Vector2(14, 6))
	for k in 3:
		_floor(SCRATCHES, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 50), rng.randf() * TAU)
	for k in 2:
		_floor(BLOOD, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 40), rng.randf() * TAU)
	_remains(rng, pos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 50))
	var n := rng.randi_range(6, 8)
	var turn := rng.randf() * TAU
	for k in n:
		var at := pos + Vector2.from_angle(turn + TAU * k / n + rng.randf_range(-0.2, 0.2)) * Vector2(rng.randf_range(48, 72), rng.randf_range(34, 50))
		var lying := k % 2 == 0
		var spawn := {"type": "warg", "position": at, "sitting": lying, "look_at": pos}
		if lying:
			spawn["pose"] = "lie"
		w._add_goblin_spawn(spawn)
	w._map_markers.append({"position": pos, "color": Color(0.85, 0.45, 0.3), "size": 2.0})


# ---------------------------------------------------------------- klimat: mrok, smugi światła, grzyby, świetliki
func _build_atmosphere(rng: RandomNumberGenerator) -> void:
	var size: Vector2i = w.map_size
	var shade := Sprite2D.new()
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			# w leżu pająków jeszcze ciemniej
			var extra := clampf(1.0 - Vector2(x, y).distance_to(lair) / 26.0, 0.0, 1.0) * 0.25
			image.set_pixel(x, y, Color(SHADE, SHADE.a + extra))
	shade.texture = ImageTexture.create_from_image(image)
	shade.centered = false
	shade.scale = Vector2(TILE, TILE)
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.z_index = 20
	add_child(shade)
	# smugi światła przebijające się przez korony: miękkie z obu stron i wygaszone na końcach,
	# rozszerzające się ku dołowi (gradient tylko w poprzek dawał ostry trapez)
	var beam_image := Image.create(48, 170, false, Image.FORMAT_RGBA8)
	for y in 170:
		var t := y / 169.0
		var along := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(0.65, 1.0, t))
		var half := lerpf(9.0, 22.0, t)
		for x in 48:
			var across := 1.0 - smoothstep(half * 0.35, half, absf(x - 23.5))
			beam_image.set_pixel(x, y, Color(1.0, 0.95, 0.7, 0.14 * along * across))
	var ray := ImageTexture.create_from_image(beam_image)
	for i in 16:
		var beam := Sprite2D.new()
		beam.texture = ray
		beam.position = Vector2(rng.randf_range(10, size.x - 10), rng.randf_range(10, size.y - 10)) * TILE
		beam.rotation = -0.35
		beam.z_index = 21
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		beam.material = additive
		add_child(beam)
	# świecące grzyby w całym lesie
	for i in SHROOMS:
		var cell := Vector2i(rng.randi_range(6, size.x - 6), rng.randi_range(6, size.y - 6))
		if not w._occupied.has(cell) and not w._road_cells.has(cell):
			_shroom(w._cell_to_world(cell))
	# świetliki w kilku miejscach
	for i in 10:
		var flies := CPUParticles2D.new()
		flies.position = Vector2(rng.randf_range(10, size.x - 10), rng.randf_range(10, size.y - 10)) * TILE
		flies.amount = 12
		flies.lifetime = 3.0
		flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		flies.emission_rect_extents = Vector2(70, 40)
		flies.gravity = Vector2.ZERO
		flies.initial_velocity_min = 4.0
		flies.initial_velocity_max = 10.0
		flies.spread = 180.0
		flies.scale_amount_max = 1.5
		var fade := Gradient.new()
		fade.colors = PackedColorArray([Color(0.9, 1.0, 0.5, 0.0), Color(0.9, 1.0, 0.5, 1.0), Color(0.9, 1.0, 0.5, 0.0)])
		flies.color_ramp = fade
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		flies.material = additive
		flies.z_index = 21
		add_child(flies)


## Sieci-pułapki spowalniają gracza, dopóki w nich stoi.
func _process(_delta: float) -> void:
	if _player == null or _webs.is_empty():
		return
	for web: Array in _webs:
		if _player.global_position.distance_to(web[0]) < web[1]:
			_player.apply_slow(0.45, 0.2)
			return
