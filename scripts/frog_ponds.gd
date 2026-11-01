class_name FrogPonds
extends Node
## Żabie stawy - wschodnia część Rozlewisk (za rzeką), dokąd żaboludzie rozlali się ze swojej wioski:
## - stawy (płycizna z liliami i pałkami, błotnisty pas, brzeg) z gromadami żaboludzi i plujek na błocie
##   i kilkoma brodzącymi w wodzie; płycizna stawów jest bagnem, po którym da się brodzić (World._in_marsh),
## - przy największych stawach osady: chata w namorzynie z ogniskiem, suszarnią ryb, siecią, garnkami, totemem
##   i dłubanką, wokół ogniska siedząca gromada,
## - łowiska nad rzeką: gromady żaboludzi z sieciami na brzegach nurtu (za mostem i pod nim),
## - dodatkowe gromady na brzegach wokół wioski żaboludzi.
## Losowane osobnym ziarnem, żeby reszta rozlewisk wyglądała jak dawniej. Planowane przed ułożeniem kafelków
## (woda, rezerwacje), budowane po Bagnie Hydry (nowe miejsca potworów dostają kolejne numery - numery dawnych
## miejsc w zapisach się nie zmieniają).
const TILE := 16
const PONDS := 14
## Promień stawu (w kafelkach): najmniejszy i największy.
const POND_RADIUS := Vector2(4.5, 8.0)
## Przy tylu największych stawach stoi chata z ogniskiem.
const HUT_PONDS := 3
const RIVER_PARTIES := 12
const VILLAGE_GROUPS := 6

var w  # świat
## Stawy: [środek, promień] w kafelkach.
var _ponds: Array = []
var _huts: Array[Vector2] = []
## Łowiska nad rzeką: [miejsce gromady, punkt nurtu, na który patrzą].
var _parties: Array = []
var _village_spots: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func plan(world) -> void:
	w = world
	_rng.seed = hash([w._seed, "frog_ponds"])
	_plan_ponds()
	_plan_river_parties()
	_plan_village_groups()


func _plan_ponds() -> void:
	var size := Vector2(w.map_size)
	for attempt in 800:
		if _ponds.size() >= PONDS:
			break
		var r := _rng.randf_range(POND_RADIUS.x, POND_RADIUS.y)
		var spot := Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y))
		if not _east_of_river(spot) or _room(spot) < r + 4.0 or _village_distance(spot) < 1.55 + r / w._swamp_radii.x:
			continue
		if _ponds.any(func(pond: Array) -> bool: return spot.distance_to(pond[0]) < r + pond[1] + 5.0):
			continue
		if w._cells_in_radius(spot, r + 2.0).any(func(cell: Vector2i) -> bool: return w._reserved.has(cell) or w._water.has(cell)):
			continue
		_make_pond(spot, r)
	# osady przy największych stawach - chata na północnym brzegu (za nią nic nie zasłania stawu)
	var by_size := _ponds.duplicate()
	by_size.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	for pond: Array in by_size.slice(0, HUT_PONDS):
		var hut: Vector2 = pond[0] + Vector2(0, -(pond[1] + 3.0))
		_huts.append(hut)
		w._reserve_area(hut, 2.5)


## Staw: płycizna, błotnisty pas (dwa kafelki) i brzeg; brzeg postrzępiony szumem.
func _make_pond(at: Vector2, radius: float) -> void:
	for cell in w._cells_in_radius(at, radius + 2.0):
		var d: float = Vector2(cell).distance_to(at) + w._noise.get_noise_2d(cell.x * 2.5 + 900.0, cell.y * 2.5) * 2.0
		if d < radius - 2.0:
			w._water[cell] = "shallow"
		elif d < radius:
			w._water[cell] = "mud"
		elif d < radius + 1.2 and not w._water.has(cell):
			w._water[cell] = "bank"
	_ponds.append([at, radius])


## Łowiska na brzegach rzeki (na lądzie przy nurcie), z dala od drogi, mostu, wioski, uroczyska i bagna Hydry.
func _plan_river_parties() -> void:
	var river: PackedVector2Array = w._river
	var spots: Array[Vector2] = []
	for attempt in 400:
		if _parties.size() >= RIVER_PARTIES:
			break
		var i := _rng.randi_range(1, river.size() - 2)
		var along: Vector2 = (river[i + 1] - river[i - 1]).normalized()
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var spot: Vector2 = river[i] + along.orthogonal() * side * (w.SWAMP_RIVER_BANK + 1.5)
		var cell := Vector2i(spot)
		if w._water.get(cell, "") in ["deep", "shallow"] or w._reserved.has(cell) or _edge_room(spot) < 2.0:
			continue
		if Road.distance_to(spot, w._road) < 7.0 or _village_distance(spot) < 1.4 or not _far_from(spot, spots, 11.0):
			continue
		if w._grove.contains(cell) or w._hydra_bog.contains(cell):
			continue
		spots.append(spot)
		_parties.append([spot, river[i]])
		w._reserve_area(spot, 2.0)


## Gromady na brzegach dookoła wioski - w lukach między dawnymi (World._plan_frog_village).
func _plan_village_groups() -> void:
	for attempt in 200:
		if _village_spots.size() >= VILLAGE_GROUPS:
			break
		var spot: Vector2 = w._swamp_center + Vector2.from_angle(_rng.randf() * TAU) * w._swamp_radii * _rng.randf_range(1.3, 1.7)
		var cell := Vector2i(spot)
		if _edge_room(spot) < 2.0 or w._water.has(cell) or w._reserved.has(cell) or Road.distance_to(spot, w._river) < 6.0:
			continue
		if not _far_from(spot, w._frog_groups, 9.0) or not _far_from(spot, _village_spots, 9.0):
			continue
		_village_spots.append(spot)
		w._reserve_area(spot, 2.0)


## Ile miejsca jest wokół punktu: odległość do drogi, rzeki i krawędzi mapy (z pasem lasu przy granicy).
func _room(p: Vector2) -> float:
	var room := minf(_edge_room(p), Road.distance_to(p, w._road) - 4.0)
	return minf(room, Road.distance_to(p, w._river) - 5.0)


## Czy punkt leży na wschód od rzeki (po stronie wioski żaboludzi).
func _east_of_river(p: Vector2) -> bool:
	for point: Vector2 in w._river:
		if absf(point.y - p.y) < 1.0 and point.x < p.x:
			return true
	return false


## Odległość od krawędzi mapy (z pasem lasu przy granicy).
func _edge_room(p: Vector2) -> float:
	var size := Vector2(w.map_size)
	return minf(minf(p.x, p.y), minf(size.x - p.x, size.y - p.y)) - (w.border_thickness + 3.0)


func _village_distance(p: Vector2) -> float:
	return ((p - w._swamp_center) / w._swamp_radii).length()


func _far_from(p: Vector2, others: Array, min_distance: float) -> bool:
	for other: Vector2 in others:
		if p.distance_to(other) < min_distance:
			return false
	return true


## Czy komórka leży w płyciźnie stawu - po stawach da się brodzić (World._in_marsh).
func contains(cell: Vector2i) -> bool:
	for pond: Array in _ponds:
		if Vector2(cell).distance_to(pond[0]) < pond[1]:
			return true
	return false


func build() -> void:
	for pond: Array in _ponds:
		_build_pond(pond[0], pond[1])
	for hut in _huts:
		_build_hut(hut)
	for party: Array in _parties:
		var center: Vector2 = party[0] * TILE
		var river: Vector2 = party[1] * TILE
		if _rng.randf() < 0.6:
			w._village_prop(w.FISH_NET, center + (center - river).normalized() * 30.0, Vector2(30, 4))
		_group(center, river, _rng.randi_range(4, 6), Vector2(18, 14))
	for spot in _village_spots:
		_group(spot * TILE, w._swamp_center * TILE, _rng.randi_range(5, 7), Vector2(18, 14))


## Gromady na błotnistym brzegu stawu (zwrócone do wody) i brodzący w płyciźnie; totem albo garnki na brzegu.
func _build_pond(at: Vector2, radius: float) -> void:
	var c := at * TILE
	var groups := 3 if radius > 6.5 else 2
	var turn := _rng.randf() * TAU
	for g in groups:
		var dir := Vector2.from_angle(turn + TAU * g / groups + _rng.randf_range(-0.3, 0.3))
		_group(c + dir * (radius - 1.0) * TILE, c, _rng.randi_range(6, 8), Vector2(16, 12))
	for k in _rng.randi_range(3, 4):
		var pos := c + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, radius - 3.0) * TILE
		w._add_goblin_spawn({"type": "frogman", "position": pos, "sitting": false, "look_at": c})
	var prop: Texture2D = w.FROG_TOTEM if _rng.randf() < 0.5 else w.CLAY_POTS
	w._village_prop(prop, c + Vector2.from_angle(turn + PI / groups) * (radius + 1.5) * TILE, Vector2(8, 4))
	w._map_markers.append({"position": c, "color": Color("6fbf5a"), "size": 2.0})


## Osada nad stawem: chata w namorzynie, przed nią (od strony stawu) ognisko z siedzącą gromadą, suszarnia ryb,
## sieć, garnki i totem, dłubanka na wodzie.
func _build_hut(tile: Vector2) -> void:
	var hut := tile * TILE
	w._village_prop(w.HUT_TREES[_rng.randi() % w.HUT_TREES.size()], hut + Vector2(0, -10), Vector2(24, 10))
	var fire := hut + Vector2(_rng.randf_range(-8, 8), 40)
	w._spawn(w.CAMPFIRE, fire)
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	w._village_prop(w.FISH_RACK, hut + Vector2(-50 * side, 18), Vector2(28, 4))
	w._village_prop(w.FISH_NET, hut + Vector2(48 * side, 14), Vector2(30, 4))
	w._village_prop(w.CLAY_POTS, hut + Vector2(-30 * side, 46))
	w._village_prop(w.FROG_TOTEM, hut + Vector2(36 * side, 44), Vector2(8, 4))
	for k in 16:
		var spot := hut + Vector2(0, 40) + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(3.0, 5.0) * TILE
		if w.water_at(spot) == "shallow":
			w._village_prop(w.CANOE, spot)
			break
	var count := _rng.randi_range(5, 7)
	var offset := _rng.randf() * TAU
	for k in count:
		var pos := fire + Vector2.from_angle(offset + TAU * k / count + _rng.randf_range(-0.15, 0.15)) * Vector2(24, 18)
		w._add_goblin_spawn({"type": "frog_spitter" if k % 3 == 0 else "frogman", "position": pos, "sitting": true, "look_at": fire})
	w._map_markers.append({"position": fire, "color": w.MAP_FIRE, "size": 2.0})
	w._map_markers.append({"position": hut, "color": w.MAP_TENT, "size": 2.5})


## Gromada żaboludzi (co trzecia to plujka) wokół punktu, zwrócona w stronę `look`.
func _group(center: Vector2, look: Vector2, n: int, spread: Vector2) -> void:
	for k in n:
		var pos := center + Vector2(_rng.randf_range(-spread.x, spread.x), _rng.randf_range(-spread.y, spread.y))
		w._add_goblin_spawn({"type": "frog_spitter" if k % 3 == 0 else "frogman", "position": pos, "sitting": false, "look_at": look})
