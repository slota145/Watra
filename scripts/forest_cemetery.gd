class_name ForestCemetery
extends Node
## Leśny Cmentarz - najgroźniejsza kraina (poziomy 32-40), na północ od Prastarego Lasu (wejście ścieżką od
## jego rozstajów). Zamglony cmentarz w martwym lesie, podzielony siecią żwirowych alejek na prawie prostokątne
## kwatery. Większość kwater otacza kuty płot z kamiennymi słupkami i furtkami (autotile z tools/cemetery_art.py),
## stare kwatery - żywopłot z ciemnych cisów; w środku gęste rzędy grobów (nagrobki, krzyże, kopczyki, otwarte
## groby) z płonącymi zniczami, w większych pomnik. Między kwaterami zagajniki martwych drzew i świerków na
## opadłych liściach, kurhany, mauzolea i krypty, latarnie z zielonym ogniem. Droga prowadzi od wejścia do
## zrujnowanej kaplicy (kapliczka odrodzenia). Siedliska:
## - wielkie gromady szkieletów w kwaterach - im bliżej mauzoleum nekromanty (północny zachód), tym większe; podczas
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
## Nad mauzoleum, trupowiskiem, kurhanami i zagajnikami krążą stada kruków, przy grobach siedzą i dziobią grupki
## kruków (zrywają się, gdy gracz podejdzie), a w pobliżu gracza co jakiś czas przepływa i rozwiewa się zjawa
## (CemeteryLife). Droga do mauzoleum nekromanty biegnie aleją krypt z latarniami, przy kaplicy stoi chata
## grabarza, a wśród świerków rosną rdzawe modrzewie.
## Mrok nad cmentarzem (chłodny, sinawy): lekki, gęsty dopiero przy nekromancie i w trupowisku; ciepłe światło zniczy
## przebija się przez niego.
const SHADE := Color(0.03, 0.03, 0.09, 0.16)
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
## Kuty płot jako autotile (tools/cemetery_art.py): 16 kafelków 16x32 wg maski sąsiadów N=1, E=2, S=4, W=8.
const IRON_FENCE := preload("res://assets/cemetery/iron_fence.png")
## Znicz (2 klatki migotania) i jego ciepła poświata.
const CANDLE := preload("res://assets/cemetery/candle.png")
const CANDLE_GLOW := Color(1.0, 0.45, 0.2, 0.55)
## Cisy żywopłotów starych kwater: krzaki z lasu w ciemnej, chłodnej zieleni.
const YEWS: Array[Texture2D] = [preload("res://assets/forest/trees/bush_0.png"),
		preload("res://assets/forest/trees/bush_1.png"), preload("res://assets/forest/trees/bush_2.png")]
const YEW_TINT := Color(0.42, 0.55, 0.5)
## Chata grabarza (dawna chałupa z Pól, przyciemniona) i rdzawe modrzewie (shader jesieni na części świerków).
const HUT := preload("res://assets/fields/farmhouse.png")
const AUTUMN_SHADER := preload("res://shaders/autumn.gdshader")
const LARCH_TINTS: Array[Color] = [Color(0.85, 0.45, 0.18), Color(0.72, 0.36, 0.16), Color(0.9, 0.62, 0.24)]
const LARCH_SHARE := 0.22
## Aleja krypt: odcinek drogi do mauzoleum (ułamki długości drogi od kaplicy) i odstęp między kryptami (kafelki).
const ALLEY_FROM := 0.5
const ALLEY_TO := 0.88
const ALLEY_STEP := 7.0
const CROW_FLOCKS := 6
const CROW_GROUPS := 16
const HEADSTONES: Array[Texture2D] = [GRAVESTONE, GRAVESTONE, CELTIC_CROSS, WOOD_CROSS, WOOD_CROSS, GRAVE_MOUND, FALLEN_STONE]

## Kwatery: środki na lekko poszarpanej siatce co PARCEL kafelków, granice wg odległości w normie L4 (prawie prostokąty);
## alejka tam, gdzie dwa najbliższe środki są prawie tak samo daleko (ALLEY). Kwatera mocno przycięta przez drogę albo
## siedlisko staje się zagajnikiem; zagajnikiem zostaje też część pozostałych, część ma żywopłot z cisów zamiast płotu.
const PARCEL := Vector2(19.0, 13.0)
const ALLEY := 1.6
const PARCEL_KEEP := 0.6
const YEW_SHARE := 0.25
const GROVE_SHARE := 0.12
const CANDLE_SHARE := 0.3
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
## Kwatery: [Rect2i w kafelkach, Array[Vector2] grobów w pikselach, pozostały czas odnowienia, komórki, rodzaj]
var plots: Array = []
var _alley_cells := {}
var _grove_cells := {}
var _candle_glow: GradientTexture2D
var _larch: Array[ShaderMaterial] = []
var _crypt_alley: Array[Vector2] = []
var _hut := Vector2.ZERO
var _candle_material: CanvasItemMaterial
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
	_plan_crypt_alley()
	_hut = chapel + Vector2(12.0, -1.0)
	w._reserve_area(_hut, 6.0)
	_plan_plots(rng)

	_build_ground(rng)
	_place_nature(rng)
	w._build_bounds()
	_setup_candles()
	for plot: Array in plots:
		_build_plot(rng, plot)
	for barrow in _barrows:
		_build_barrow(rng, barrow)
	_build_chapel(rng)
	_build_crypt_alley(rng)
	_build_hut(rng)
	_build_necromancer_lair(rng)
	_build_ghoul_pit(rng)
	_build_atmosphere(rng)
	_build_life(rng)

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


## Kwatery grobów: komórki Woronoja z odległością w normie L4 (zaokrąglone prostokąty) na lekko poszarpanej siatce, poza
## drogami, siedliskami i pasem lasu przy granicy; między nimi alejki. Kwatera, z której droga albo siedlisko zabrały
## sporą część, zostaje zagajnikiem (jej brzeg byłby poszarpany). Rodzaj: "iron" (kuty płot), "yew" (żywopłot z cisów).
func _plan_plots(rng: RandomNumberGenerator) -> void:
	var grid := Vector2i((Vector2(w.map_size) / PARCEL).ceil()) + Vector2i(2, 2)
	var seeds := {}
	for gy in grid.y:
		for gx in grid.x:
			seeds[Vector2i(gx, gy)] = (Vector2(gx - 1, gy - 1) + Vector2(rng.randf_range(0.35, 0.65), rng.randf_range(0.35, 0.65))) * PARCEL
	var margin: int = w.border_thickness + 2
	var cells_of := {}
	var total := {}
	for y in range(margin, w.map_size.y - margin):
		for x in range(margin, w.map_size.x - margin):
			var cell := Vector2i(x, y)
			var p := Vector2(x, y) + Vector2(0.5, 0.5)
			var home := Vector2i((p / PARCEL).floor()) + Vector2i.ONE
			var best := INF
			var second := INF
			var owner := home
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var g := home + Vector2i(dx, dy)
					var seed_at: Vector2 = seeds[g]
					var q := Vector2(absf(p.x - seed_at.x) / PARCEL.x, absf(p.y - seed_at.y) / PARCEL.y)
					var d := pow(pow(q.x, 4.0) + pow(q.y, 4.0), 0.25) * PARCEL.y
					if d < best:
						second = best
						best = d
						owner = g
					elif d < second:
						second = d
			if second - best < ALLEY:
				if not (w._reserved.has(cell) or w._road_clear.has(cell)):
					_alley_cells[cell] = true
				continue
			total[owner] = total.get(owner, 0) + 1
			if w._reserved.has(cell) or w._road_clear.has(cell):
				continue
			if not cells_of.has(owner):
				cells_of[owner] = {}
			cells_of[owner][cell] = true
	for owner: Vector2i in cells_of:
		var cells: Dictionary = cells_of[owner]
		# z kwatery zostało za mało (droga, siedlisko, brzeg mapy) - zagajnik zamiast grobów
		if cells.size() < total[owner] * PARCEL_KEEP or cells.size() < 40 or rng.randf() < GROVE_SHARE:
			_grove_cells.merge(cells)
			continue
		var lo := Vector2i(9999, 9999)
		var hi := Vector2i(-1, -1)
		for cell: Vector2i in cells:
			lo = lo.min(cell)
			hi = hi.max(cell)
		var kind := "yew" if rng.randf() < YEW_SHARE else "iron"
		plots.append([Rect2i(lo, hi - lo + Vector2i.ONE), [], 0.0, cells, kind])
		_plot_cells.merge(cells)


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
			if _touches(corner, w._road_cells) >= 2 or _touches(corner, _alley_cells) >= 2:
				kind = "c_path"
			elif _touches(corner, soil) >= 2 and n > -0.35:
				kind = "c_soil"
			elif _touches(corner, _plot_cells) >= 2:
				kind = "c_soil"
			elif _touches(corner, _grove_cells) >= 2 and n > -0.3:
				kind = "c_leaves"
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
			elif _alley_cells.has(cell):
				w._map_props[cell] = MAP_PATH
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
			if w._road_clear.has(cell) or _alley_cells.has(cell):
				continue
			if edge_dist < w.border_thickness + 1:
				if rng.randf() < 0.85 - edge_dist * 0.12:
					_tree(rng, cell, 1)
				continue
			if w._reserved.has(cell) or _plot_cells.has(cell):
				continue
			var r := rng.randf()
			if _grove_cells.has(cell) and r < 0.16:  # zagajnik między kwaterami
				_tree(rng, cell, 1)
			elif groves.get_noise_2d(x, y) > 0.4 and r < 0.14:
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
	if w._occupied.has(cell):
		return
	w._try_place(PINE, cell, spacing)
	if w._occupied.has(cell):
		w._map_props[cell] = w.MAP_PINE
		if rng.randf() < LARCH_SHARE:  # rdzawy modrzew
			if _larch.is_empty():
				for tint in LARCH_TINTS:
					var material := ShaderMaterial.new()
					material.shader = AUTUMN_SHADER
					material.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
					_larch.append(material)
			var tree: Node2D = w.entities.get_child(w.entities.get_child_count() - 1)
			(tree.get_node("Sprite") as Sprite2D).material = _larch[rng.randi() % _larch.size()]


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
## Kwatera: obramowanie (kuty płot albo żywopłot z cisów) z furtkami, w środku rzędy grobów co 2 kafelki (co drugi
## kafelek w rzędzie, sąsiednie rzędy przesunięte), przy części grobów znicze, w większych kwaterach pomnik na środku; wielkie gromady szkieletów.
func _build_plot(rng: RandomNumberGenerator, plot: Array) -> void:
	var rect: Rect2i = plot[0]
	var cells: Dictionary = plot[3]
	var graves: Array = plot[1]
	# obramowanie: komórki kwatery, których któryś z 8 sąsiadów jest poza nią - linia zawsze styka się bokami
	var ring := {}
	for cell: Vector2i in cells:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not cells.has(cell + Vector2i(dx, dy)):
					ring[cell] = true
	var border := ring.duplicate()
	_cut_gates(rng, ring, cells, rect)
	if plot[4] == "iron":
		_build_iron_fence(ring)
	else:
		_build_yews(rng, ring)
	# groby w rzędach (z dala od obramowania), znicze przy części z nich
	var center := Vector2(rect.get_center()) * TILE
	var monument := rect.size.x >= 12 and rect.size.y >= 9 and rng.randf() < 0.7
	for cell: Vector2i in cells:
		var row := cell.y - rect.position.y
		if row % 2 != 0 or (cell.x - rect.position.x + (row / 2) % 2) % 2 != 1:
			continue
		if border.has(cell) or border.has(cell + Vector2i.DOWN) or rng.randf() < 0.08:
			continue
		var pos := Vector2(cell * TILE) + Vector2(8, 14) + Vector2(rng.randf_range(-1.5, 1.5), 0)
		if monument and pos.distance_to(center) < 40.0:
			continue
		var tex: Texture2D = OPEN_GRAVE if rng.randf() < 0.08 else HEADSTONES[rng.randi() % HEADSTONES.size()]
		var sprite := _prop(tex, pos, Vector2(14, 5) if tex != OPEN_GRAVE and tex != GRAVE_MOUND else Vector2.ZERO)
		sprite.flip_h = rng.randf() < 0.5
		graves.append(pos + Vector2(0, 10))
		w._map_props[cell] = MAP_GRAVE
		if tex != OPEN_GRAVE and rng.randf() < CANDLE_SHARE:
			_candle(rng, pos + Vector2(rng.randf_range(-7, 7), 5))
	if monument:
		_prop([ANGEL, OBELISK, SARCOPHAGUS, ANGEL].pick_random(), center + Vector2(0, 8), Vector2(22, 8))
		for i in 2:
			_candle(rng, center + Vector2(-14 + i * 28, 14))
	# szkielety: wielkie gromady, im bliżej nekromanty, tym liczniejsze
	var near := clampf(1.0 - Vector2(rect.get_center()).distance_to(necromancer) / 110.0, 0.0, 1.0)
	# gromada w co drugiej kwaterze daleko od nekromanty, w każdej bliżej niego (druga przy samym mauzoleum)
	var groups := int(near > 0.45) + (1 if near > 0.2 or rng.randf() < 0.5 else 0)
	for g in groups:
		var spot := (Vector2(rect.position) + Vector2(rng.randf_range(0.3, 0.7) * rect.size.x, rng.randf_range(0.3, 0.7) * rect.size.y)) * TILE
		_skeleton_group(rng, spot, rng.randi_range(3, 6) + roundi(near * 7.0), near)


## Czy komórka sąsiaduje (także po skosie) z którąś ze zbioru.
func _near(cell: Vector2i, cells: Dictionary) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if cells.has(cell + Vector2i(dx, dy)):
				return true
	return false


## Furtki: na środku dolnego boku kwatery i na środku jednego z pozostałych (losowo) - wycięcie 3 komórek
## obramowania (płot kończy się po obu stronach kamiennym słupkiem).
func _cut_gates(rng: RandomNumberGenerator, ring: Dictionary, cells: Dictionary, rect: Rect2i) -> void:
	var sides: Array[Vector2i] = [Vector2i.DOWN, [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT].pick_random()]
	var mid := Vector2(rect.get_center())
	for side in sides:
		var along := Vector2i(1, 0) if side.y != 0 else Vector2i(0, 1)
		var best := Vector2i(-1, -1)
		var best_score := INF
		for cell: Vector2i in ring:
			# komórka na tym boku: na zewnątrz kwatery w tę stronę, a wzdłuż boku z obu stron dalej obramowanie
			if cells.has(cell + side) or not ring.has(cell + along) or not ring.has(cell - along):
				continue
			var score := absf(Vector2(cell).x - mid.x) if side.y != 0 else absf(Vector2(cell).y - mid.y)
			if score < best_score:
				best_score = score
				best = cell
		if best.x < 0:
			continue
		for k in range(-1, 2):
			ring.erase(best + along * k)


## Kuty płot z kafelków: każda komórka obramowania dostaje kafelek wg sąsiadów; kolizje w jednym ciele.
func _build_iron_fence(ring: Dictionary) -> void:
	var body := StaticBody2D.new()
	w.add_child(body)
	for cell: Vector2i in ring:
		var mask := int(ring.has(cell + Vector2i.UP)) | int(ring.has(cell + Vector2i.RIGHT)) * 2 \
				| int(ring.has(cell + Vector2i.DOWN)) * 4 | int(ring.has(cell + Vector2i.LEFT)) * 8
		var sprite := Sprite2D.new()
		sprite.texture = IRON_FENCE
		sprite.hframes = 16
		sprite.frame = mask
		sprite.centered = false
		sprite.offset = Vector2(0, -IRON_FENCE.get_height())
		sprite.position = Vector2(cell.x * TILE, (cell.y + 1) * TILE)
		w.entities.add_child(sprite)
		_box(body, Vector2(cell * TILE) + Vector2(8, 8), Vector2(12, 8))
		w._map_props[cell] = MAP_FENCE
		w._occupied[cell] = true


## Żywopłot z cisów: ciemne krzaki gęsto jeden przy drugim (w komórce i w pół drogi do sąsiada), jak na Polach.
func _build_yews(rng: RandomNumberGenerator, ring: Dictionary) -> void:
	var body := StaticBody2D.new()
	w.add_child(body)
	for cell: Vector2i in ring:
		var center := Vector2(cell * TILE) + Vector2(8, 10)
		var points: Array[Vector2] = [center]
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			if ring.has(cell + d):
				points.append(center + Vector2(d * TILE) * 0.5)
		for point in points:
			var yew := Sprite2D.new()
			yew.texture = YEWS[rng.randi() % YEWS.size()]
			yew.offset = Vector2(0, -13)
			yew.position = (point + Vector2(rng.randf_range(-2, 2), rng.randf_range(-1, 1))).round()
			yew.flip_h = rng.randf() < 0.5
			yew.scale = Vector2.ONE * rng.randf_range(0.9, 1.1)
			var shade := rng.randf_range(0.85, 1.0)
			yew.modulate = Color(YEW_TINT.r * shade, YEW_TINT.g * shade, YEW_TINT.b * shade)
			w.entities.add_child(yew)
		_box(body, center, Vector2(14, 10))
		w._map_props[cell] = Color("1f3328")
		w._occupied[cell] = true


func _box(body: StaticBody2D, center: Vector2, box_size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = box_size
	shape.shape = rect
	shape.position = center
	body.add_child(shape)


## Wspólna poświata zniczy (ciepłe, małe koło nad mrokiem).
func _setup_candles() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([CANDLE_GLOW, Color(CANDLE_GLOW, 0.0)])
	_candle_glow = GradientTexture2D.new()
	_candle_glow.gradient = gradient
	_candle_glow.width = 40
	_candle_glow.height = 28
	_candle_glow.fill = GradientTexture2D.FILL_RADIAL
	_candle_glow.fill_from = Vector2(0.5, 0.5)
	_candle_glow.fill_to = Vector2(1.0, 0.5)
	_candle_material = CanvasItemMaterial.new()
	_candle_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


## Znicz z migoczącym płomykiem i poświatą rysowaną ponad mrokiem cmentarza.
func _candle(rng: RandomNumberGenerator, pos: Vector2) -> void:
	var candle := Sprite2D.new()
	candle.texture = CANDLE
	candle.hframes = 2
	candle.frame = rng.randi() % 2
	candle.offset = Vector2(0, -5)
	candle.position = pos.round()
	w.entities.add_child(candle)
	w._flicker(candle)
	var glow := Sprite2D.new()
	glow.texture = _candle_glow
	glow.material = _candle_material
	glow.position = pos + Vector2(0, -6)
	glow.z_index = 21
	glow.scale = Vector2.ONE * rng.randf_range(0.85, 1.15)
	add_child(glow)


func _skeleton_group(rng: RandomNumberGenerator, center: Vector2, n: int, near: float) -> void:
	for k in n:
		var roll := rng.randf()
		var kind := "skeleton_knight" if roll < 0.08 + near * 0.1 else "skeleton_archer" if roll < 0.35 else "skeleton"
		var spread := 20.0 + n * 3.0
		var pos := center + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread) * 0.75)
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


# ---------------------------------------------------------------- aleja krypt i chata grabarza
## Miejsca krypt po obu stronach drogi z kaplicy do mauzoleum (na zmianę), rezerwowane przed planem kwater.
func _plan_crypt_alley() -> void:
	var road: PackedVector2Array = w._road
	var start := 0
	for i in road.size():  # droga zaczyna się przy wejściu - aleja liczy się od kaplicy
		if road[i].distance_to(chapel) < road[start].distance_to(chapel):
			start = i
	var walked := 0.0
	var total := 0.0
	for i in range(start + 1, road.size()):
		total += road[i].distance_to(road[i - 1])
	var next := total * ALLEY_FROM
	var side := 1.0
	for i in range(start + 1, road.size()):
		walked += road[i].distance_to(road[i - 1])
		if walked < next or walked > total * ALLEY_TO:
			continue
		next = walked + ALLEY_STEP
		var dir := (road[i] - road[i - 1]).normalized()
		var spot := road[i] + dir.orthogonal() * 4.5 * side
		side = -side
		_crypt_alley.append(spot)
		w._reserve_area(spot, 3.5)


func _build_crypt_alley(rng: RandomNumberGenerator) -> void:
	for i in _crypt_alley.size():
		var pos := _crypt_alley[i] * TILE + Vector2(0, 14)
		var crypt := _prop(CRYPT, pos, Vector2(60, 16))
		crypt.flip_h = rng.randf() < 0.5
		for dy in range(-3, 1):
			for dx in range(-2, 3):
				w._map_props[Vector2i(_crypt_alley[i]) + Vector2i(dx, dy)] = MAP_CRYPT
		if i % 2 == 0:
			_lantern(pos + Vector2(46 if rng.randf() < 0.5 else -46, 4))
		for k in 2:
			_candle(rng, pos + Vector2(-10 + k * 20, 10))


## Chata grabarza obok kaplicy: przyciemniona chałupa, przy niej świeżo wykopane groby, stos krzyży i latarnia.
func _build_hut(rng: RandomNumberGenerator) -> void:
	var pos := _hut * TILE
	var hut := _prop(HUT, pos, Vector2(80, 22))
	hut.modulate = Color(0.62, 0.6, 0.66)
	hut.flip_h = true
	for dy in range(-5, 1):
		for dx in range(-3, 4):
			w._map_props[Vector2i(_hut) + Vector2i(dx, dy)] = MAP_CRYPT
	_prop(OPEN_GRAVE, pos + Vector2(-52, 40))
	_prop(OPEN_GRAVE, pos + Vector2(-16, 46))
	_prop(GRAVE_MOUND, pos + Vector2(20, 44))
	for k in 3:
		_prop(WOOD_CROSS, pos + Vector2(56 + k * 6, 30 + k * 3)).flip_h = k % 2 == 0
	_lantern(pos + Vector2(48, 6))


# ---------------------------------------------------------------- kruki i zjawy
## Stada nad mauzoleum, trupowiskiem, leżem Gnilca, kurhanami i zagajnikami; grupki na ziemi przy losowych grobach;
## zjawy pojawiają się nad grobami.
func _build_life(rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2] = [necromancer * TILE, pit * TILE, ghoul_lair * TILE]
	for barrow in _barrows:
		spots.append(barrow * TILE)
	var graves: Array[Vector2] = []
	for plot: Array in plots:
		for grave: Vector2 in plot[1]:
			graves.append(grave)
	var ground: Array[Vector2] = []
	for i in CROW_GROUPS:
		if not graves.is_empty():
			ground.append(graves[rng.randi() % graves.size()] + Vector2(rng.randf_range(-10, 10), 4))
	var life := CemeteryLife.new()
	add_child(life)
	var bounds := Rect2(Vector2(10, 10) * TILE, (Vector2(w.map_size) - Vector2(20, 20)) * TILE)
	life.setup(_player, w.entities, bounds, spots, ground, graves, CROW_FLOCKS, rng)


# ---------------------------------------------------------------- klimat
func _build_atmosphere(rng: RandomNumberGenerator) -> void:
	var size: Vector2i = w.map_size
	var shade := Sprite2D.new()
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var p := Vector2(x, y)
			var extra := clampf(1.0 - p.distance_to(necromancer) / 34.0, 0.0, 1.0) * 0.26 \
					+ clampf(1.0 - p.distance_to(pit) / 26.0, 0.0, 1.0) * 0.14
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
