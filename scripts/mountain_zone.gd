class_name MountainZone
extends Node
## Wietrzne Turnie - górska kraina na wschód od rozlewisk (wejście z lewego dolnego rogu,
## na przedłużeniu drogi z rozlewisk). Nad halami wznoszą się płaskowyże o łagodnych kształtach,
## duże z wyższą półką w środku. Od południa opada z nich skalna ściana: dwa kafelki pod
## krawędzią, rysowana pod postaciami i cała z kolizją, więc nie da się za nią wejść. Z boków
## i od tyłu biegnie skalna krawędź (też z kolizją). Na górę prowadzą wyłącznie żwirowe rampy
## wycięte w ścianie. Płaskowyżów nie ma przy drodze, w wiosce ani na pastwiskach, a przy ich
## krawędziach nic nie rośnie.
## Na halach rosną świerki i martwe drzewa (żerdzie orłów), leżą głazy i złoża rudy żelaza
## (najwięcej u stóp ścian). Kozy górskie pasą się na halach, a nad turniami krążą orły.
## Na północnym wschodzie, na wielkim płaskowyżu (dwie rampy od drogi), leży wioska ptakoludzi:
## chaty na palach z ogniskami, skalne iglice z gniazdami, żerdzie z piórami, totemy, a pośrodku
## wielkie gniazdo Gromoskrzydłego, otoczone piorunochronami z kryształami burzy. Od wschodu,
## północy i zachodu wioskę zamyka niedostępna grań o dwa poziomy wyżej - opada ku wiosce
## wysoką ścianą i jest najeżona ośnieżonymi szczytami; od południa jest wejście.
##
## Na południowym wschodzie, na kwietnej polanie wśród hal, leży wioska satyrów: wielkie ognisko
## w kręgu kamieni, wokół którego tańczą satyrowie i grają grajkowie, namioty i szałasy z winem,
## winoroślą i amforami, gaik z majem i totemy z kozich czaszek. Od ścieżki z przełęczy pilnują jej
## satyrowie osiłki, którzy szarżują z rogami.
##
## Węzeł żyje w świecie (orły potrzebują _process); generuje teren przez metody świata.

const TILE := 16
const ALPINE_TILES: Array[Vector2i] = [Vector2i(0, 5), Vector2i(1, 5), Vector2i(3, 6)]
const ROCK_TILES: Array[Vector2i] = [Vector2i(2, 5), Vector2i(3, 5)]
const GRAVEL_TILES: Array[Vector2i] = [Vector2i(0, 6), Vector2i(1, 6)]
const HIGH_ROCK_TILES: Array[Vector2i] = [Vector2i(2, 6)]
const MAP_ALPINE := Color("6f8a48")
const MAP_PLATEAU := Color("a09a58")
const MAP_HIGH := Color("8a8f7a")
const MAP_GRAVEL := Color("948a78")
const MAP_CLIFF := Color("3a3a44")
const MAP_ORE := Color("b0602a")

## Skalna ściana jako pas z powtarzającym się wzorem (PixelLab, tools/region_props.py): kolumnę wycinamy
## wg pozycji x, więc sąsiednie odcinki ściany pasują do siebie. Krawędzie płaskowyżów - tak samo.
const CLIFF_STRIP := preload("res://assets/mountains/cliff_strip.png")
## Przejścia klifów do otoczenia (nakładane na ściany i trawę): piarg u podstawy ściany, gzyms z trawą
## na górnej krawędzi (obrócony - na bokach płaskowyżu) i zaokrąglone skały na końcach ścian.
const CLIFF_FOOT := preload("res://assets/mountains/cliff_foot.png")
## Rodzaj podłoża komórki; narożnik dostaje rodzaj, który ma co najmniej połowa stykających się
## komórek (wg pierwszeństwa), a kafelek przejścia Wang dobiera się do czterech narożników.
## Drogi w górach to żwirowe ścieżki (przejście hala -> żwir).
enum Floor { GRASS, ROCK, GRAVEL }
const FLOOR_PRIORITY := [Floor.ROCK, Floor.GRAVEL]
## Pierwszeństwo terenów widocznego podłoża w narożnikach (_plan_soft_ground).
const SOFT_PRIORITY := ["m_path", "m_snow", "m_rock", "m_scree", "m_dark", "m_flowers"]


## Nawis krawędzi płaskowyżu: pas przyczepiony u góry (na ścianie, a odbity w pionie - z tyłu płaskowyżu),
## pas boczny przyczepiony z prawej (boki płaskowyżu i schodki ściany) i zaokrąglony róg przyczepiony
## w prawym dolnym rogu (wypukłe rogi z tyłu). Trawa nad ścianą i z tyłu ma malowany pas z PixelLab; pozostałe
## nawisy to maski wypełniane teksturą podłoża płaskowyżu (shaders/cliff_lip.gdshader).
enum Lip { DOWN, SIDE, CORNER }
const GRASS_LIP := preload("res://assets/mountains/cliff_lip_grass.png")
const LIP_MASKS: Array[Texture2D] = [preload("res://assets/mountains/cliff_lip_mask.png"),
		preload("res://assets/mountains/cliff_lip_mask_side.png"), preload("res://assets/mountains/cliff_lip_mask_corner.png")]
const LIP_SHADER := preload("res://shaders/cliff_lip.gdshader")
## Skośny nawis w wcięciach schodków krawędzi - zamiast prostokątnych zębów skos pod 45°.
const FILLET_SHADER := preload("res://shaders/cliff_fillet.gdshader")
## Pas przy krawędzi płaskowyżu (w kafelkach) z jednolitym podłożem, pasującym do nawisu: na halach łąka,
## na wyższej półce skała, na grani śnieg (tereny SoftGround).
const RIM := 2
const RIM_KINDS := {1: "meadow", 2: "m_rock", RING_LEVEL: "m_snow"}
const CLIFF_END := preload("res://assets/mountains/cliff_end.png")
const CLIFF_END_FRAMES := 4
const RAMP := preload("res://assets/mountains/ramp.png")
const PEAKS: Array[Texture2D] = [preload("res://assets/mountains/peak_0.png"), preload("res://assets/mountains/peak_1.png"),
		preload("res://assets/mountains/peak_2.png")]
## Płaskowyż wioski (półosie w kafelkach), szerokość grani wokół niej i jej wysokość.
const VILLAGE_RADII := Vector2(32.0, 24.0)
const RING_WIDTH := 12.0
const RING_LEVEL := 3
const MAP_SNOW := Color("e8eef4")
const DEAD_TREES: Array[Texture2D] = [preload("res://assets/mountains/dead_tree_0.png"), preload("res://assets/mountains/dead_tree_1.png")]
const DECOR := preload("res://assets/mountains/decor.png")
const IRON_ORE := preload("res://scenes/props/iron_ore.tscn")
const STILT_HUTS: Array[Texture2D] = [preload("res://assets/mountains/stilt_hut_0.png"), preload("res://assets/mountains/stilt_hut_1.png")]
const PILLAR_NESTS: Array[Texture2D] = [preload("res://assets/mountains/pillar_nest_0.png"), preload("res://assets/mountains/pillar_nest_1.png")]
const PERCH_POLE := preload("res://assets/mountains/perch_pole.png")
const EAGLE_TOTEM := preload("res://assets/mountains/eagle_totem.png")
const EGG_NEST := preload("res://assets/mountains/egg_nest.png")
const BONE_PILE := preload("res://assets/mountains/bone_pile.png")
const CAIRN := preload("res://assets/mountains/cairn.png")
const WIND_CHIME := preload("res://assets/mountains/wind_chime.png")
const STORM_ROD := preload("res://assets/mountains/storm_rod.png")
const AERIE := preload("res://assets/mountains/aerie.png")

const HUTS := 7
## Wioska satyrów: promień polany (w kafelkach), liczba namiotów i tancerzy przy ognisku.
const SATYR_RADIUS := 12.0
const SATYR_TENTS := 5
const SATYR_DANCERS := 8
const SATYR_PROPS := {
	"tent": preload("res://scenes/props/forest/satyr_tent.tscn"), "hut": preload("res://scenes/props/forest/satyr_hut.tscn"),
	"barrels": preload("res://scenes/props/forest/satyr_barrels.tscn"), "amphoras": preload("res://scenes/props/forest/satyr_amphoras.tscn"),
	"vines": preload("res://scenes/props/forest/satyr_vines.tscn"), "press": preload("res://scenes/props/forest/satyr_press.tscn"),
	"maypole": preload("res://scenes/props/forest/satyr_maypole.tscn"), "totem": preload("res://scenes/props/forest/satyr_totem.tscn"),
	"stone": preload("res://scenes/props/forest/satyr_stone.tscn"), "arch": preload("res://scenes/props/forest/satyr_arch.tscn"),
	"bench": preload("res://scenes/props/forest/satyr_bench.tscn"), "drums": preload("res://scenes/props/forest/satyr_drums.tscn"),
	"feast": preload("res://scenes/props/forest/satyr_feast.tscn"), "statue": preload("res://scenes/props/forest/satyr_statue.tscn"),
	"hay": preload("res://scenes/props/forest/satyr_hay.tscn"),
}
const SATYR_CLUTTER := ["barrels", "amphoras", "vines", "feast", "hay", "drums"]
const PILLARS := 6
const PATROLS := 6
const EAGLES := 7
const GOAT_HERDS := 9
const PLATEAUS := 20
## Odstęp płaskowyżu od drogi, wioski, pastwisk i innych płaskowyżów (w kafelkach).
const PLATEAU_MARGIN := 3

var w  # świat (World) - korzystamy z jego pomocniczych metod generowania
var lair := Vector2.ZERO
var _shape := FastNoiseLite.new()
var _patch := FastNoiseLite.new()
## Drobniejszy szum do mieszania rodzajów podłoża w zwarte płaty (zamiast szachownicy).
var _mix := FastNoiseLite.new()
## Komórki u stóp ścian - piarg (osypisko).
var _scree := {}
## Wysokość komórki: 0 - hala, 1 - płaskowyż, 2 - wyższa półka (brak wpisu = 0).
var _levels := {}
var _no_cliff := {}
## Ściany i krawędzie płaskowyżów - przy nich nic nie stawiamy.
var _cliff_cells := {}
## Górne komórki krawędzi, pod którymi zamiast ściany jest rampa.
var _ramps := {}
## Komórki płaskowyżów przy krawędzi (do RIM kafelków od niższego terenu) - jednolite podłoże.
var _rim := {}
## Materiał nawisów z maski dla każdego terenu krawędzi (wspólny - nawisy rysują się jedną partią).
var _lip_materials := {}
## Wcięcia schodków: niższa komórka -> lista [płaskowyż obok (LEFT / RIGHT), płaskowyż nad (UP) albo pod (DOWN)].
var _fillets := {}
var _fillet_materials := {}
var _perches: Array = []
var _village_cells := {}
var _ring := {}
var _huts: Array[Vector2] = []
## Warstwa przejść klifów i nawisy do położenia po ułożeniu podłoża:
## [komórka płaskowyżu, pozycja, Lip, odbicie poziome, odbicie pionowe, (teren SoftGround - nad schodami)].
var _blend: Node2D
var _lips: Array = []
## Środek polany satyrów (w kafelkach) i punkt, z którego dochodzi do niej ścieżka.
var satyr_glade := Vector2.ZERO
var _satyr_gate := Vector2.ZERO


func generate(world) -> void:
	w = world
	var rng: RandomNumberGenerator = w._rng
	var size := Vector2(w.map_size)
	_shape.seed = rng.randi()
	_shape.frequency = 0.07
	_shape.fractal_octaves = 2
	_patch.seed = rng.randi()
	_patch.frequency = 0.045
	_mix.seed = rng.randi()
	_mix.frequency = 0.13
	Goblin.safe_zone = Rect2()

	lair = Vector2(size.x * 0.74, size.y * 0.3)
	var pass_point := Vector2(size.x * 0.36, size.y * 0.66)
	var foot := _plan_village_plateau(rng)
	# droga: od wejścia (lewy dolny róg) przez przełęcz pod rampę wioski
	w._road = Road.wiggle(Vector2(1, size.y - 4), pass_point, rng, 6.0, 12.0)
	w._road.append_array(Road.wiggle(pass_point, foot + Vector2(0, 8), rng, 6.0, 12.0))
	w._road.append_array(Road.straight(foot + Vector2(0, 8), foot))
	for point: Vector2 in w._road:
		for cell in w._cells_in_radius(point, 1.3):
			w._road_cells[cell] = true
		for cell in w._cells_in_radius(point, 2.8):
			w._road_clear[cell] = true
			_no_cliff[cell] = true
	var shrine_tile: Vector2 = pass_point + Vector2(3.5, -4.5)
	w._reserve_area(shrine_tile, 3.0)
	_plan_village(rng)
	_plan_satyr_glade(rng, pass_point)
	_plan_goats(rng)
	for cell: Vector2i in w._reserved:
		_no_cliff[cell] = true
	# inne płaskowyże z dala od wioski i grani (także od wysokich ścian grani)
	_no_cliff.merge(_dilate(_ring, 7))
	_no_cliff.merge(_dilate(_village_cells, 3))

	_plan_plateaus(rng)
	_plan_rim()
	_plan_fillets()
	_build_cliffs(rng)
	_build_level_shade()
	_build_ground(rng)
	_place_lips()
	_place_props(rng)
	w._build_bounds()
	for herd: Array in w._herds:
		w._build_herd(herd[0], herd[1] * TILE)
	_build_village(rng)
	_build_satyr_village(rng)
	_place_peaks(rng)
	_spawn_eagles(size)

	var shrine: Node2D = w.SHRINE.instantiate()
	shrine.position = shrine_tile * TILE
	w.entities.add_child(shrine)
	w._register_shrine("eagle_pass", shrine.position)
	w._map_markers.append({"position": shrine.position, "color": Color("5fd3ff"), "size": 3.0})
	w._spawn_point = shrine.position + Vector2(0, 20)
	w._add_exit(Rect2(0, size.y - 9, 3.5, 9), "swamp", "from:mountains", w._road_point_from_edge(true, 5.0) / TILE + Vector2(1.5, -2.0))
	w._arrivals["from:swamp"] = w._road_point_from_edge(true, 9.0)


# ---------------------------------------------------------------- plan
func level_of(cell: Vector2i) -> int:
	return _levels.get(cell, 0)


func _plan_village(rng: RandomNumberGenerator) -> void:
	w._reserve_area(lair, 9.0)
	var base := rng.randf() * TAU
	for i in HUTS:
		var angle := base + TAU * i / HUTS + rng.randf_range(-0.15, 0.15)
		var hut := lair + Vector2.from_angle(angle) * Vector2(17.0, 13.0) * rng.randf_range(0.95, 1.1)
		_huts.append(hut)
		w._reserve_area(hut + Vector2(0, 2), 4.5)


## Polana satyrów na południowym wschodzie, z dala od drogi i wioski ptakoludzi; ścieżka
## prowadzi do niej od przełęczy (tylko wydeptany pas, bez karawan).
func _plan_satyr_glade(rng: RandomNumberGenerator, pass_point: Vector2) -> void:
	var size := Vector2(w.map_size)
	satyr_glade = Vector2(size.x * rng.randf_range(0.74, 0.8), size.y * rng.randf_range(0.74, 0.78))
	w._reserve_area(satyr_glade, SATYR_RADIUS)
	w._mark_camp_area(satyr_glade, SATYR_RADIUS - 2.0)
	var trail := Road.wiggle(pass_point + Vector2(4, 2), satyr_glade, rng, 5.0, 12.0)
	for point: Vector2 in trail:
		if point.distance_to(satyr_glade) < SATYR_RADIUS - 3.0:
			break
		_satyr_gate = point
		for cell in w._cells_in_radius(point, 1.0):
			w._road_cells[cell] = true
		for cell in w._cells_in_radius(point, 2.5):
			w._road_clear[cell] = true
			_no_cliff[cell] = true


## Płaskowyż wioski z dwiema rampami od południa i grań wokół (bez południowego wejścia).
## Zwraca kafelek u stóp zachodniej rampy - tam kończy się droga.
func _plan_village_plateau(rng: RandomNumberGenerator) -> Vector2:
	var village := _blob(lair, VILLAGE_RADII, 0.12)
	var ramps := _try_level(village, 1, rng, [lair + Vector2(-12, VILLAGE_RADII.y), lair + Vector2(14, VILLAGE_RADII.y)])
	_village_cells = village
	var outer := VILLAGE_RADII + Vector2(RING_WIDTH, RING_WIDTH)
	var size: Vector2i = w.map_size
	for y in range(floori(lair.y - outer.y - 4), ceili(lair.y + outer.y + 4)):
		for x in range(floori(lair.x - outer.x - 4), ceili(lair.x + outer.x + 4)):
			var cell := Vector2i(x, y)
			if village.has(cell) or x < 1 or y < 1 or x > size.x - 2 or y > size.y - 2:
				continue
			var p := Vector2(x, y) + Vector2(0.5, 0.5) - lair
			var angle := rad_to_deg(atan2(p.y, p.x))
			if angle > 28.0 and angle < 152.0:  # od południa wejście do wioski
				continue
			if (p / (outer + Vector2.ONE * _shape.get_noise_2d(x * 0.6, y * 0.6) * 5.0)).length() < 1.0:
				_levels[cell] = RING_LEVEL
				_ring[cell] = true
	if ramps.is_empty():
		return lair + Vector2(0, VILLAGE_RADII.y + 3)
	return Vector2(ramps[0]) + Vector2(0.5, 3.5)


func _plan_goats(rng: RandomNumberGenerator) -> void:
	var size := Vector2(w.map_size)
	var area := Rect2(size * Vector2(0.06, 0.06), size * Vector2(0.55, 0.88))
	# pastwiska z dala od drogi, wioski i grani (z zapasem na wysokie ściany grani)
	var walls := _dilate(_ring, 9)
	walls.merge(_dilate(_village_cells, 4))
	var ok := func(tile: Vector2) -> bool:
		return Road.distance_to(tile, w._road) > 5.0 and not walls.has(Vector2i(tile)) and not w._reserved.has(Vector2i(tile))
	var placed: Array[Vector2] = []
	for i in GOAT_HERDS:
		var tile: Vector2 = w._pick_spread(area, placed, ok)
		if not tile.is_finite():
			continue
		placed.append(tile)
		w._herds.append(["goat", tile])
		w._reserve_area(tile, 4.0)


## Płaskowyże: kształt to elipsa poszarpana szumem i wygładzona; duże dostają wyższą półkę
## w środku. Każdy poziom musi mieć co najmniej jedną rampę - inaczej płaskowyżu nie ma.
func _plan_plateaus(rng: RandomNumberGenerator) -> void:
	var size := Vector2(w.map_size)
	var blocked := _dilate(_no_cliff, PLATEAU_MARGIN)
	var placed := 0
	for attempt in 320:
		if placed >= PLATEAUS:
			break
		var radii := Vector2(rng.randf_range(7.0, 17.0), rng.randf_range(6.0, 12.0))
		var margin: float = w.border_thickness + 5.0
		var center := Vector2(rng.randf_range(radii.x + margin, size.x - radii.x - margin),
				rng.randf_range(radii.y + margin, size.y - radii.y - margin - 3.0))
		var cells := _blob(center, radii, 0.3)
		if cells.size() < 45 or cells.keys().any(func(c: Vector2i) -> bool: return blocked.has(c)):
			continue
		if _try_level(cells, 1, rng).is_empty():
			continue
		placed += 1
		blocked.merge(_dilate(cells, PLATEAU_MARGIN + 2))
		# wyższa półka w środku dużego płaskowyżu (z dala od jego krawędzi)
		if radii.x > 12.0 and rng.randf() < 0.65:
			var inner := _blob(center + Vector2(rng.randf_range(-2, 2), rng.randf_range(-1, 1)), radii * 0.52, 0.3)
			var core := {}
			for cell: Vector2i in inner:
				if _inside_by(cell, cells, 4):
					core[cell] = true
			if core.size() >= 24:
				_try_level(core, 2, rng)


## Komórki poszarpanej, wygładzonej elipsy (bez wąskich wypustek i dziur).
func _blob(center: Vector2, radii: Vector2, roughness: float) -> Dictionary:
	var cells := {}
	var from := Vector2i(floori(center.x - radii.x - 3), floori(center.y - radii.y - 3))
	var to := Vector2i(ceili(center.x + radii.x + 3), ceili(center.y + radii.y + 3))
	for y in range(from.y, to.y):
		for x in range(from.x, to.x):
			var d := ((Vector2(x, y) + Vector2(0.5, 0.5) - center) / radii).length() + _shape.get_noise_2d(x, y) * roughness
			if d < 1.0:
				cells[Vector2i(x, y)] = true
	for i in 2:
		var next := {}
		for y in range(from.y, to.y):
			for x in range(from.x, to.x):
				var cell := Vector2i(x, y)
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if (dx != 0 or dy != 0) and cells.has(cell + Vector2i(dx, dy)):
							n += 1
				if n >= 5 or (cells.has(cell) and n >= 4):
					next[cell] = true
		cells = next
	return cells


## Pas przy krawędzi każdego płaskowyżu: komórki, od których do niższego terenu jest najwyżej RIM kafelków.
func _plan_rim() -> void:
	for cell: Vector2i in _levels:
		var level := level_of(cell)
		if level <= 0:
			continue
		for dy in range(-RIM, RIM + 1):
			for dx in range(-RIM, RIM + 1):
				if level_of(cell + Vector2i(dx, dy)) < level:
					_rim[cell] = true
					break
			if _rim.has(cell):
				break


## Wcięcia schodków krawędzi: niższa komórka, którą płaskowyż obejmuje z boku i z góry (ściana) albo z dołu
## (tył płaskowyżu), razem z komórką na skos. Pomijamy samą rampę (komórka pod nią to schody).
func _plan_fillets() -> void:
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var low := level_of(cell)
			for vertical: Vector2i in [Vector2i.UP, Vector2i.DOWN]:
				var level := level_of(cell + vertical)
				if level <= low or _ramps.has(cell + vertical):
					continue
				for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
					if level_of(cell + side) == level and level_of(cell + side + vertical) >= level:
						_fillets.get_or_add(cell, []).append([side, vertical])


## Teren SoftGround pasa przy krawędzi płaskowyżu na danej wysokości.
func _rim_kind(level: int) -> String:
	return RIM_KINDS.get(level, "m_rock")


func _inside_by(cell: Vector2i, cells: Dictionary, distance: int) -> bool:
	for dy in range(-distance, distance + 1):
		for dx in range(-distance, distance + 1):
			if not cells.has(cell + Vector2i(dx, dy)):
				return false
	return true


func _dilate(cells: Dictionary, distance: int) -> Dictionary:
	var result := {}
	for cell: Vector2i in cells:
		for dy in range(-distance, distance + 1):
			for dx in range(-distance, distance + 1):
				result[cell + Vector2i(dx, dy)] = true
	return result


## Nadaje komórkom poziom i wybiera 1-2 rampy w południowej ścianie (trzy kolumny prostej
## krawędzi, pod którymi jest płasko) - losowo albo najbliżej podanych punktów (`prefer`).
## Zwraca wybrane rampy; bez miejsca na rampę nic nie robi i zwraca pustą listę.
func _try_level(cells: Dictionary, level: int, rng: RandomNumberGenerator, prefer: Array = []) -> Array[Vector2i]:
	var edge: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if cells.has(cell + Vector2i.DOWN):
			continue
		var straight := true
		for dx in [-1, 1]:
			var side: Vector2i = cell + Vector2i(dx, 0)
			if not cells.has(side) or cells.has(side + Vector2i.DOWN):
				straight = false
		for dy in range(1, 4):
			for dx in range(-1, 2):
				var below: Vector2i = cell + Vector2i(dx, dy)
				if cells.has(below) or level_of(below) != level - 1:
					straight = false
		if straight:
			edge.append(cell)
	var chosen: Array[Vector2i] = []
	if edge.is_empty():
		return chosen
	if prefer.is_empty():
		edge.shuffle()
		chosen.append(edge[0])
		for cell in edge:
			if chosen.size() >= 2:
				break
			if cell.distance_to(chosen[0]) > 10.0:
				chosen.append(cell)
	else:
		for point: Vector2 in prefer:
			var best := edge[0]
			for cell in edge:
				if Vector2(cell).distance_to(point) < Vector2(best).distance_to(point):
					best = cell
			if chosen.is_empty() or best.distance_to(chosen[0]) > 10.0:
				chosen.append(best)
	for cell: Vector2i in cells:
		_levels[cell] = level
	for cell in chosen:
		for dx in range(-1, 2):
			_ramps[cell + Vector2i(dx, 0)] = true
	return chosen


# ---------------------------------------------------------------- skarpy
## Ściany i krawędzie płaskowyżów (na warstwie podłóg, pod postaciami) z kolizją i rampy.
func _build_cliffs(rng: RandomNumberGenerator) -> void:
	var body := StaticBody2D.new()
	w.add_child(body)
	# przejścia rysujemy na osobnej warstwie nad wszystkimi ścianami (dodanej po nich)
	var blend := Node2D.new()
	_blend = blend
	# schody ramp nad ścianami (kolumny rampy mają pod spodem zwykły pas ściany), pod przejściami
	var stairs := Node2D.new()
	for cell: Vector2i in _levels:
		var level := level_of(cell)
		var x := cell.x
		var y := cell.y
		# od południa: ściana w dół - po dwa kafelki na każdy poziom różnicy (albo rampa)
		var below := level_of(cell + Vector2i.DOWN)
		if below < level:
			var depth := 2 * (level - below)
			_cliff_cells[cell] = true
			for k in depth:
				_cliff_cells[cell + Vector2i.DOWN * (k + 1)] = true
				w._map_props[cell + Vector2i.DOWN * (k + 1)] = MAP_CLIFF
			_scree[cell + Vector2i.DOWN * (depth + 1)] = true
			if rng.randf() < 0.6:
				_scree[cell + Vector2i.DOWN * (depth + 2)] = true
			var strip_x := posmod(x * TILE, CLIFF_STRIP.get_width())
			if _ramps.has(cell):
				for k in range(0, depth, 2):
					_floor_sprite(CLIFF_STRIP, Vector2(x * TILE, (y + 1 + k) * TILE), Rect2(posmod(x * TILE + k * 40, CLIFF_STRIP.get_width()), 0, TILE, 32))
				if not _ramps.has(cell + Vector2i.LEFT):  # schody rysowane raz, od lewej kolumny
					_floor_sprite(RAMP, Vector2(x * TILE, (y + 1) * TILE), Rect2(), stairs)
				# po bokach schodów głazy z końców ściany (bez jej płyty) zachodzą na brzeg stopni
				for side in [-1, 1]:
					if _ramps.has(cell + Vector2i(side, 0)):
						continue
					for k in range(0, depth, 2):
						var cheek := _floor_sprite(CLIFF_END, Vector2(x * TILE + (2 if side > 0 else -2), (y + 1 + k) * TILE),
								Rect2(rng.randi() % CLIFF_END_FRAMES * 24 + 8, 0, 16, CLIFF_END.get_height()), blend)
						cheek.flip_h = side > 0
				# u góry schodów nawis podłoża (ścieżka albo pas krawędzi), bez malowanego pasa trawy
				var terrain := "m_path" if w._road_cells.has(cell) else _rim_kind(level)
				_lips.append([cell, Vector2(x * TILE, (y + 1) * TILE - 1), Lip.DOWN, false, false, terrain])
				continue
			for k in range(0, depth, 2):
				_floor_sprite(CLIFF_STRIP, Vector2(x * TILE, (y + 1 + k) * TILE), Rect2(posmod(x * TILE + k * 40, CLIFF_STRIP.get_width()), 0, TILE, 32))
				for side in [-1, 1]:  # na rogu płaskowyżu ściana kończy się osypiskiem zaokrąglonych skał
					var n := cell + Vector2i(side, 0)
					if level_of(n) < level and not _ramps.has(n):
						var cap := _floor_sprite(CLIFF_END, Vector2(x * TILE + (TILE - 8 if side > 0 else -16), (y + 1 + k) * TILE + 1),
								Rect2(rng.randi() % CLIFF_END_FRAMES * 24, 0, 24, CLIFF_END.get_height()), blend)
						cap.flip_h = side < 0
					# schodek: płaskowyż obok sięga niżej - jego podłoże zwiesza się bokiem na tę ścianę
					if level_of(n) >= level and k == 0:
						for r in range(1, depth + 1):
							if level_of(n + Vector2i(0, r)) >= level:
								_lips.append([n + Vector2i(0, r), Vector2(x * TILE, (y + r) * TILE), Lip.SIDE, side < 0, false])
			# nawis podłoża płaskowyżu na górnej krawędzi ściany (kładziony po podłożu) i piarg u jej podstawy
			_lips.append([cell, Vector2(x * TILE, (y + 1) * TILE - 1), Lip.DOWN, false, false])
			_floor_sprite(CLIFF_FOOT, Vector2(x * TILE, (y + 1 + depth) * TILE - 8), Rect2(strip_x, 0, TILE, 16), blend)
			_box(body, Vector2(x * TILE + 8, (y + 1) * TILE + depth * 8), Vector2(16, depth * 16))
			if rng.randf() < 0.1:  # orzeł może przysiąść na krawędzi
				_perches.append([Vector2(x * TILE + 8, y * TILE + 10), 2.0])
		# z boków i od tyłu: krawędź z kolizją, a na niej nawis podłoża płaskowyżu nad niższym terenem obok
		var behind := level_of(cell + Vector2i.UP) < level
		for side in [-1, 1]:
			if level_of(cell + Vector2i(side, 0)) < level:
				_lips.append([cell, Vector2(x * TILE + side * TILE, y * TILE), Lip.SIDE, side > 0, false])
				_box(body, Vector2(x * TILE + (TILE - 2 if side > 0 else 2), y * TILE + 8), Vector2(4, 16))
				_cliff_cells[cell] = true
				if behind:  # wypukły róg z tyłu - zaokrąglony
					_lips.append([cell, Vector2(x * TILE + side * TILE, (y - 1) * TILE), Lip.CORNER, side > 0, false])
		if behind:
			_lips.append([cell, Vector2(x * TILE, (y - 1) * TILE), Lip.DOWN, false, true])
			_box(body, Vector2(x * TILE + 8, y * TILE + 2), Vector2(16, 4))
			_cliff_cells[cell] = true
	w.floors.add_child(stairs)
	w.floors.add_child(blend)


## Łagodny cień na niższym terenie przy płaskowyżach (shaders/level_shade.gdshader), pod ścianami
## i nawisami - boki i tył płaskowyżu wyglądały jak cienkie pęknięcie w płaskiej trawie.
func _build_level_shade() -> void:
	var size: Vector2i = w.map_size
	var levels := _level_image()
	var reach := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var near := {}
	for cell: Vector2i in _levels:
		var level := level_of(cell)
		if level <= 0:
			continue
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var n := cell + Vector2i(dx, dy)
				# cień jak przy jednym poziomie różnicy - przy wysokiej grani był za szeroki
				var value := mini(level, level_of(n) + 1) - 0.32 * Vector2(dx, dy).length()
				if value > near.get(n, 0.0):
					near[n] = value
	for cell: Vector2i in near:
		if Rect2i(Vector2i.ZERO, size).has_point(cell):
			reach.set_pixel(cell.x, cell.y, Color(maxf(near[cell], level_of(cell)) / 8.0, 0, 0))
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/level_shade.gdshader")
	material.set_shader_parameter("levels", ImageTexture.create_from_image(levels))
	material.set_shader_parameter("reach", ImageTexture.create_from_image(reach))
	material.set_shader_parameter("cells", Vector2(size))
	var shade := Sprite2D.new()
	shade.texture = ImageTexture.create_from_image(reach)
	shade.centered = false
	shade.scale = Vector2(TILE, TILE)
	shade.material = material
	w.floors.add_child(shade)
	w.floors.move_child(shade, 0)


## Nawisy mają podłoże pasu przy krawędzi płaskowyżu (łąka / skała / śnieg) - to samo co płaskowyż nad nimi.
func _place_lips() -> void:
	for lip: Array in _lips:
		var pos: Vector2 = lip[1]
		var kind: Lip = lip[2]
		if _replaced_by_fillet(lip):
			continue
		var terrain: String = lip[5] if lip.size() > 5 else _rim_kind(level_of(lip[0]))
		# malowany pas trawy tylko nad ścianą i z tyłu (obrócony na bok wyglądał jak wklejony), nie nad schodami
		var grass := terrain == "meadow" and kind == Lip.DOWN and lip.size() == 5
		var texture: Texture2D = GRASS_LIP if grass else LIP_MASKS[kind]
		var region := Rect2(0, 0, 16, 16)
		if kind == Lip.DOWN:
			region.position.x = posmod(int(pos.x), texture.get_width())
		elif kind == Lip.SIDE:
			region.position.y = posmod(int(pos.y), texture.get_height())
		var sprite := _floor_sprite(texture, pos, region, _blend)
		sprite.flip_h = lip[3]
		sprite.flip_v = lip[4]
		if not grass:
			sprite.material = _lip_material(terrain)
	_place_fillets()


## Nawis prosty, który w wcięciu schodka zastępuje skos: z płaskowyżu nad / pod komórką wcięcia
## albo z boku, od strony płaskowyżu tworzącego wcięcie.
func _replaced_by_fillet(lip: Array) -> bool:
	var owner: Vector2i = lip[0]
	var kind: Lip = lip[2]
	if kind == Lip.CORNER:
		return false
	var target := owner + (Vector2i.UP if lip[4] else Vector2i.DOWN)
	if kind == Lip.SIDE:
		target = Vector2i(((lip[1] as Vector2) + Vector2(8, 8)) / TILE)
	for fillet: Array in _fillets.get(target, []):
		if kind == Lip.DOWN and target - owner == -fillet[1] or kind == Lip.SIDE and owner - target == fillet[0]:
			return true
	return false


## Skośne nawisy w wcięciach schodków: duszek 16 x 33 px zaczyna się 1 px nad komórką wcięcia (ściana)
## albo kafelek wyżej (tył płaskowyżu, odbity w pionie); odbity w poziomie, gdy płaskowyż jest po lewej.
func _place_fillets() -> void:
	var image := Image.create(16, 33, false, Image.FORMAT_L8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	for cell: Vector2i in _fillets:
		for fillet: Array in _fillets[cell]:
			var side: Vector2i = fillet[0]
			var vertical: Vector2i = fillet[1]
			var top := cell.y * TILE - 1 if vertical == Vector2i.UP else cell.y * TILE - 17
			var sprite := _floor_sprite(texture, Vector2(cell.x * TILE, top), Rect2(), _blend)
			sprite.flip_h = side == Vector2i.LEFT
			sprite.flip_v = vertical == Vector2i.DOWN
			sprite.material = _fillet_material(_rim_kind(level_of(cell + vertical)))


func _fillet_material(terrain: String) -> ShaderMaterial:
	if not _fillet_materials.has(terrain):
		var material := ShaderMaterial.new()
		material.shader = FILLET_SHADER
		var grass := terrain == "meadow"
		material.set_shader_parameter("lip_tex", GRASS_LIP if grass else LIP_MASKS[Lip.DOWN])
		material.set_shader_parameter("is_mask", not grass)
		material.set_shader_parameter("terrain_tex", SoftGround.TEXTURES[terrain])
		_fillet_materials[terrain] = material
	return _fillet_materials[terrain]


func _lip_material(terrain: String) -> ShaderMaterial:
	if not _lip_materials.has(terrain):
		var material := ShaderMaterial.new()
		material.shader = LIP_SHADER
		material.set_shader_parameter("terrain_tex", SoftGround.TEXTURES[terrain])
		_lip_materials[terrain] = material
	return _lip_materials[terrain]


## `region` - wycinek tekstury (pasy ścian i krawędzi); pusty = cała tekstura. `parent` - warstwa
## (domyślnie podłogi świata).
func _floor_sprite(texture: Texture2D, top_left: Vector2, region := Rect2(), parent: Node2D = null) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	if region.has_area():
		sprite.region_enabled = true
		sprite.region_rect = region
	sprite.centered = false
	sprite.position = top_left
	(parent if parent != null else w.floors).add_child(sprite)
	return sprite


func _box(body: StaticBody2D, center: Vector2, box_size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = box_size
	shape.shape = box
	shape.position = center
	body.add_child(shape)


# ---------------------------------------------------------------- teren
func _build_ground(rng: RandomNumberGenerator) -> void:
	var kinds := {}
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var kind := _floor_of(cell, rng)
			if kind != Floor.GRASS:
				kinds[cell] = kind
	var corners := {}
	for y in w.map_size.y + 1:
		for x in w.map_size.x + 1:
			var corner := Vector2i(x, y)
			var counts := {}
			for cell in [corner - Vector2i(1, 1), corner - Vector2i(0, 1), corner - Vector2i(1, 0), corner]:
				var kind: int = kinds.get(cell, Floor.GRASS)
				counts[kind] = counts.get(kind, 0) + 1
			for kind: int in FLOOR_PRIORITY:
				if counts.get(kind, 0) >= 2:
					corners[corner] = kind
					break
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var cell_corners: Array[int] = []
			for c in [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]:
				cell_corners.append(corners.get(c, Floor.GRASS))
			var kind := Floor.GRASS
			for candidate: int in FLOOR_PRIORITY:
				if candidate in cell_corners:
					kind = candidate
					break
			var tile := Vector2i(0, w.ALPINE_WANG_ROW + 4 * (rng.randi() % 2))
			if kind != Floor.GRASS:
				var mask: int = w._corner_mask(cell_corners, kind)
				var row: int = w.ALPINE_WANG_ROW + (0 if kind == Floor.ROCK else 4)
				tile = Vector2i(mask % 4, row + mask / 4)
			w.ground.set_cell(cell, 0, tile)
	_plan_soft_ground(kinds)


## Tereny widocznego podłoża (SoftGround, tekstury 64 px z PixelLab): ścieżki i ubita ziemia wioski,
## piarg, skała, śnieg na grani, a na halach płaty gęstej trawy i kwietne łąki (polana satyrów cała
## w kwiatach). Narożnik dostaje teren, który ma co najmniej połowa stykających się komórek
## (wg pierwszeństwa), jak przy kafelkach Wang.
func _plan_soft_ground(kinds: Dictionary) -> void:
	var cell_kind := {}
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var kind: int = kinds.get(cell, Floor.GRASS)
			var name := "meadow"
			if w._road_cells.has(cell) or kind == Floor.GRAVEL and _village_cells.has(cell):
				name = "m_path"
			elif _rim.has(cell):
				name = _rim_kind(level_of(cell))
			elif kind == Floor.GRAVEL:
				name = "m_scree"
			elif kind == Floor.ROCK:
				name = "m_snow" if level_of(cell) >= RING_LEVEL and _mix.get_noise_2d(x, y) > -0.25 else "m_rock"
			elif Vector2(cell).distance_to(satyr_glade) < SATYR_RADIUS + _mix.get_noise_2d(x, y) * 3.0:
				name = "m_flowers"
			else:
				var patch: float = w._noise.get_noise_2d(x * 0.8 + 300.0, y * 0.8)
				if patch > 0.32:
					name = "m_dark"
				elif patch < -0.42:
					name = "m_flowers"
			if name != "meadow":
				cell_kind[cell] = name
	# na granicy poziomów teren narożnika liczymy osobno z każdej strony: od góry decyduje płaskowyż (teren
	# spod ściany nie wchodzi na niego), od dołu niższy teren (płaskowyż nie wylewa się obok nawisu);
	# SoftGround wybiera wariant wg wysokości komórki
	for y in w.map_size.y + 1:
		for x in w.map_size.x + 1:
			var corner := Vector2i(x, y)
			var cells := [corner - Vector2i(1, 1), corner - Vector2i(0, 1), corner - Vector2i(1, 0), corner]
			var top := 0
			var bottom := 99
			for cell: Vector2i in cells:
				top = maxi(top, level_of(cell))
				bottom = mini(bottom, level_of(cell))
			w._soft_corners[corner] = _corner_kind(cells, cell_kind, top)
			if bottom != top:
				w._soft_low_corners[corner] = _corner_kind(cells, cell_kind, bottom)
	w._soft_levels = _level_image()


## Teren narożnika z komórek na danej wysokości: ten, który ma co najmniej połowa z nich (wg pierwszeństwa).
func _corner_kind(cells: Array, cell_kind: Dictionary, level: int) -> String:
	var counts := {}
	var n := 0
	for cell: Vector2i in cells:
		if level_of(cell) == level:
			var name: String = cell_kind.get(cell, "meadow")
			counts[name] = counts.get(name, 0) + 1
			n += 1
	for name: String in SOFT_PRIORITY:
		if counts.get(name, 0) >= (n + 1) / 2:
			return name
	return "meadow"


## Wysokości komórek jako obraz (R = poziom / 8) - dla cienia u stóp płaskowyżów i SoftGround.
func _level_image() -> Image:
	var size: Vector2i = w.map_size
	var image := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	for cell: Vector2i in _levels:
		var level := level_of(cell)
		if level > 0 and Rect2i(Vector2i.ZERO, size).has_point(cell):
			image.set_pixel(cell.x, cell.y, Color(level / 8.0, 0, 0))
	return image


func _floor_of(cell: Vector2i, rng: RandomNumberGenerator) -> Floor:
	var level := level_of(cell)
	var rocky := _patch.get_noise_2d(cell.x, cell.y)
	var m := _mix.get_noise_2d(cell.x, cell.y)
	if w._road_cells.has(cell):
		return Floor.GRAVEL
	if w._road_clear.has(cell) and rng.randf() < 0.3:
		return Floor.GRAVEL
	# pas przy krawędzi płaskowyżu: jednolite podłoże jak nawis nad ścianą
	if _rim.has(cell):
		return Floor.GRASS if _rim_kind(level) == "meadow" else Floor.ROCK
	# polana satyrów: sama trawa
	if Vector2(cell).distance_to(satyr_glade) < SATYR_RADIUS:
		return Floor.GRASS
	if _ring.has(cell):
		return Floor.ROCK
	if _village_cells.has(cell):
		# płaskowyż wioski: ubita ziemia, płaty żwiru i gołej skały
		return Floor.GRAVEL if m > 0.2 else Floor.ROCK if m < -0.4 else Floor.GRASS
	if _scree.has(cell) and m > -0.3:
		return Floor.GRAVEL
	if level == 0 and (rocky > 0.5 or rocky < -0.55):
		return Floor.ROCK if rocky > 0 else Floor.GRAVEL
	# płaskowyże mają inny teren - im wyżej, tym więcej skały
	match level:
		0:
			return Floor.GRASS
		1:
			return Floor.GRAVEL if m < -0.45 else Floor.GRASS
	return Floor.ROCK if m > -0.2 else Floor.GRAVEL


func _place_props(rng: RandomNumberGenerator) -> void:
	for y in w.map_size.y:
		for x in w.map_size.x:
			var cell := Vector2i(x, y)
			var edge_dist := mini(mini(x, y), mini(w.map_size.x - 1 - x, w.map_size.y - 1 - y))
			var r := rng.randf()
			if w._road_clear.has(cell):
				if not w._road_cells.has(cell):
					_decor(rng, cell, 0.05)
				continue
			if w._reserved.has(cell) or _near_edge(cell) or _ring.has(cell):
				continue
			if edge_dist < w.border_thickness:
				if rng.randf() < 0.6 - edge_dist * 0.08:
					w._try_place(w.PINE if rng.randf() < 0.75 else w.BOULDER, cell, 1)
				continue
			if _village_cells.has(cell):
				if r < 0.012:
					w._try_place(w.BOULDER, cell, 1)
				else:
					_decor(rng, cell, 0.05)
				continue
			var density: float = w._noise.get_noise_2d(x, y)
			if density > 0.3 and r < 0.28:
				w._try_place(w.PINE, cell, 2)
			elif _scree.has(cell) and r < 0.12:  # złoża najczęściej u stóp ścian
				_ore(cell)
			elif r < 0.004:
				_ore(cell)
			elif r < 0.012:
				w._try_place(w.PINE, cell, 2)
			elif r < 0.016:
				_dead_tree(rng, cell)
			elif r < 0.026:
				w._try_place(w.BOULDER, cell, 1)
			else:
				_decor(rng, cell, 0.08)


## Ściana albo krawędź płaskowyżu tuż obok - tu nic nie stawiamy.
func _near_edge(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if _cliff_cells.has(cell + Vector2i(dx, dy)):
				return true
	return false


func _ore(cell: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if w._occupied.has(cell + Vector2i(dx, dy)):
				return
	w._occupied[cell] = true
	w._spawn(IRON_ORE, w._cell_to_world(cell))
	w._map_props[cell] = MAP_ORE


func _dead_tree(rng: RandomNumberGenerator, cell: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if w._occupied.has(cell + Vector2i(dx, dy)):
				return
	w._occupied[cell] = true
	var pos: Vector2 = w._cell_to_world(cell)
	var sprite: Sprite2D = w._village_prop(DEAD_TREES[rng.randi() % DEAD_TREES.size()], pos, Vector2(8, 5))
	sprite.flip_h = rng.randf() < 0.5
	w._map_props[cell] = w.MAP_STUMP
	_perches.append([pos + Vector2(-9.0 if sprite.flip_h else 9.0, 0), 34.0])


func _decor(rng: RandomNumberGenerator, cell: Vector2i, chance: float) -> void:
	var clump: Vector2 = w.decor_clump(w._seed, cell)
	if rng.randf() >= chance * clump.x:
		return
	var sprite := Sprite2D.new()
	sprite.texture = DECOR
	sprite.hframes = 8
	sprite.frame = (int(clump.y * 8) + rng.randi() % 3) % 8
	sprite.flip_h = rng.randf() < 0.5
	sprite.position = w._cell_to_world(cell) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-6, 2))
	w.decor.add_child(sprite)


# ---------------------------------------------------------------- wioska ptakoludzi
func _build_village(rng: RandomNumberGenerator) -> void:
	var center := lair * TILE
	# wielkie gniazdo wodza i piorunochrony z kryształami burzy dookoła
	var nest := Sprite2D.new()
	nest.texture = AERIE
	nest.position = center + Vector2(0, -4)
	w.floors.add_child(nest)
	for i in 6:
		var angle := TAU * i / 6.0 + 0.3
		var spot := center + Vector2.from_angle(angle) * Vector2(112, 84)
		var rod: Sprite2D = w._village_prop(STORM_ROD, spot, Vector2(10, 4), 2)
		w._flicker(rod)
		w._glow_at(spot + Vector2(0, -36), Color(0.45, 0.75, 1.0, 0.35))
	for i in 4:
		var angle := TAU * i / 4.0 + PI / 4.0
		w._village_prop(EAGLE_TOTEM, center + Vector2.from_angle(angle) * Vector2(150, 116), Vector2(8, 4))
	w._add_goblin_spawn({"type": "storm_eagle", "position": center, "sitting": false, "look_at": center, "respawn": w.boss_respawn_time})
	w._map_markers.append({"position": center, "color": w.MAP_BOSS, "size": 4.0})
	for k in 6:
		var pos := center + Vector2.from_angle(TAU * k / 6.0) * Vector2(80, 60)
		var kind: String = ["birdman", "birdman_thrower", "birdman_shaman"][k % 3]
		w._add_goblin_spawn({"type": kind, "position": pos, "sitting": false, "look_at": center})

	# chaty na palach z ogniskami, przy każdej gromada ptakoludzi i ozdoby
	for hut_tile in _huts:
		var hut := hut_tile * TILE
		w._village_prop(STILT_HUTS[rng.randi() % STILT_HUTS.size()], hut, Vector2(40, 8))
		w._map_markers.append({"position": hut, "color": w.MAP_TENT, "size": 2.5})
		var fire := hut + Vector2(rng.randf_range(-8, 8), 44)
		w._spawn(w.CAMPFIRE, fire)
		w._map_markers.append({"position": fire, "color": w.MAP_FIRE, "size": 2.0})
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var chime: Sprite2D = w._village_prop(WIND_CHIME, hut + Vector2(40 * side, 18), Vector2(4, 3), 2)
		w._flicker(chime)
		w._village_prop(EGG_NEST, hut + Vector2(-34 * side, 30))
		w._village_prop(BONE_PILE if rng.randf() < 0.5 else CAIRN, hut + Vector2(30 * side, 64))
		var pole: Sprite2D = w._village_prop(PERCH_POLE, hut + Vector2(-44 * side, 58), Vector2(4, 3), 2)
		w._flicker(pole)
		_perches.append([hut + Vector2(-44 * side, 58), 36.0])
		var count := rng.randi_range(5, 6)
		var offset := rng.randf() * TAU
		for k in count:
			var angle := offset + TAU * k / count + rng.randf_range(-0.15, 0.15)
			var pos := fire + Vector2.from_angle(angle) * Vector2(26, 20)
			var kind: String = "birdman_thrower" if k % 3 == 1 else "birdman_shaman" if k == 2 else "birdman"
			w._add_goblin_spawn({"type": kind, "position": pos, "sitting": true, "look_at": fire})

	# skalne iglice z gniazdami na obrzeżach wioski
	var base := rng.randf() * TAU
	for i in PILLARS:
		var angle := base + TAU * i / PILLARS
		var spot := center + Vector2.from_angle(angle) * Vector2(23, 15) * TILE
		w._village_prop(PILLAR_NESTS[i % PILLAR_NESTS.size()], spot, Vector2(26, 10))
		_perches.append([spot + Vector2(0, -2), 64.0])
		w._map_props[Vector2i(spot / TILE)] = MAP_CLIFF

	# patrole na obrzeżach wioski
	for i in PATROLS:
		var angle := base + TAU * (i + 0.5) / PATROLS
		var spot := center + Vector2.from_angle(angle) * Vector2(24, 15) * TILE
		for k in rng.randi_range(4, 5):
			var pos := spot + Vector2(rng.randf_range(-20, 20), rng.randf_range(-16, 16))
			var kind: String = "birdman_thrower" if k % 3 == 1 else "birdman_shaman" if k == 3 else "birdman"
			w._add_goblin_spawn({"type": kind, "position": pos, "sitting": false, "look_at": spot})


# ---------------------------------------------------------------- wioska satyrów
func _build_satyr_village(rng: RandomNumberGenerator) -> void:
	var center := satyr_glade * TILE
	# wielkie ognisko w kręgu kamieni i tańczący wokół satyrowie (co trzeci gra na fletni)
	w._spawn(w.CAMPFIRE, center)
	w._map_markers.append({"position": center, "color": w.MAP_FIRE, "size": 3.0})
	for i in 8:
		var angle := TAU * i / 8.0 + 0.2
		w._spawn(SATYR_PROPS["stone"], center + Vector2.from_angle(angle) * Vector2(88, 66))
	for k in SATYR_DANCERS:
		var angle := TAU * k / SATYR_DANCERS + rng.randf_range(-0.12, 0.12)
		var pos := center + Vector2.from_angle(angle) * Vector2(50, 38)
		w._add_goblin_spawn({"type": "satyr_piper" if k % 3 == 1 else "satyr", "position": pos, "sitting": true, "look_at": center})
	# maj z wstążkami, posąg rogatego boga i uczta na trawie
	w._spawn(SATYR_PROPS["maypole"], center + Vector2(0, -108))
	w._spawn(SATYR_PROPS["statue"], center + Vector2(-52, -112))
	w._spawn(SATYR_PROPS["feast"], center + Vector2(54, -100))

	# namioty i szałasy na obrzeżu, przy każdym wino, winorośl albo amfory i gromadka satyrów
	var gate_angle := (_satyr_gate * TILE - center).angle() if _satyr_gate != Vector2.ZERO else PI / 2.0
	for i in SATYR_TENTS:
		var angle := gate_angle + TAU * (i + 0.5) / SATYR_TENTS
		var tent := center + Vector2.from_angle(angle) * Vector2(138, 104)
		w._spawn(SATYR_PROPS["tent" if i % 2 == 0 else "hut"], tent)
		w._map_markers.append({"position": tent, "color": w.MAP_TENT, "size": 2.0})
		var side := Vector2.from_angle(angle + PI / 2.0)
		w._spawn(SATYR_PROPS[SATYR_CLUTTER[rng.randi() % SATYR_CLUTTER.size()]], tent + side * 36.0 + Vector2(0, 8))
		w._spawn(SATYR_PROPS[SATYR_CLUTTER[rng.randi() % SATYR_CLUTTER.size()]], tent - side * 36.0 + Vector2(0, 8))
		var front := tent + Vector2.from_angle(angle + PI) * 34.0
		w._spawn(SATYR_PROPS["bench"], tent + side * 30.0 - Vector2(0, 14))
		for k in rng.randi_range(2, 3):
			var pos := front + Vector2(rng.randf_range(-18, 18), rng.randf_range(-12, 12))
			w._add_goblin_spawn({"type": "satyr_piper" if k == 2 else "satyr", "position": pos, "sitting": false, "look_at": center})
	# tłocznia wina między namiotami i pilnujący jej osiłek
	var press := center + Vector2.from_angle(gate_angle + PI) * Vector2(96, 72)
	w._spawn(SATYR_PROPS["press"], press)
	w._add_goblin_spawn({"type": "satyr_brute", "position": press + Vector2(26, 14), "sitting": false, "look_at": center})
	# totemy z kozich czaszek na skraju polany
	for i in 4:
		var angle := gate_angle + TAU * (i + 0.25) / 4.0
		w._spawn(SATYR_PROPS["totem"], center + Vector2.from_angle(angle) * Vector2(184, 140))

	# brama z kwiecistego łuku na ścieżce i osiłki na straży
	if _satyr_gate != Vector2.ZERO:
		var gate := _satyr_gate * TILE
		var across := Vector2.from_angle(gate_angle + PI / 2.0)
		w._spawn(SATYR_PROPS["arch"], gate)
		for side in [-1.0, 1.0]:
			w._add_goblin_spawn({"type": "satyr_brute", "position": gate + across * 30.0 * side + (center - gate).normalized() * 16.0,
					"sitting": false, "look_at": gate * 2.0 - center})
	w._map_markers.append({"position": center + Vector2(0, -24), "color": Color("c86ad8"), "size": 3.0})


## Ośnieżone szczyty gęsto na grani wokół wioski (na rzadkiej, poszarpanej siatce).
func _place_peaks(rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector2i] = []
	for cell: Vector2i in _ring:
		if posmod(cell.x, 4) != 0 or posmod(cell.y, 4) != 0:
			continue
		var spot := cell + Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		if _inside_by(spot, _ring, 1):
			spots.append(spot)
	spots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
	for spot in spots:
		var pos := Vector2(spot * TILE) + Vector2(8, 12)
		var peak: Sprite2D = w._village_prop(PEAKS[rng.randi() % PEAKS.size()], pos)
		peak.flip_h = rng.randf() < 0.5
		w._map_props[spot] = MAP_SNOW
		if rng.randf() < 0.25:  # orły siadają na szczytach
			_perches.append([pos, float(peak.texture.get_height()) - 12.0])


# ---------------------------------------------------------------- orły
func _spawn_eagles(size: Vector2) -> void:
	var bounds := Rect2(Vector2(12, 12) * TILE, (size - Vector2(24, 24)) * TILE)
	for i in EAGLES:
		var eagle := Eagle.new()
		w.entities.add_child(eagle)
		eagle.setup(bounds, _perches, w.player)
