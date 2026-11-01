class_name GoblinPosts
extends Node
## Gobliński Las poza dawnymi siedliskami - gobliny odcinają Ostoję od świata, a wilki łowią coraz bliżej:
## - posterunki przy drogach (dalej od Ostoi, z dala od wyjść z krainy): rząd pali od strony drogi z przejściem,
##   dwa namioty, ognisko z siedzącą zgrają, łucznicy pilnujący drogi, osiłek, sztandar i stojak z bronią,
## - psiarnie między obozami goblinów a siedliskiem wilków: zagroda z pali z oswajanymi wilkami, klatka i kości,
##   przy bramie poskramiacze, osiłek i wargi,
## - zgraje zwiadowców na wolnych pasach wokół Ostoi (z dala od łowisk ze zwierzyną),
## - wilcze łowy: watahy przy upolowanych jeleniach na skraju siedliska wilków.
## Losowane osobnym ziarnem, żeby reszta lasu wyglądała jak dawniej. Planowane przed ułożeniem podłoża
## (udeptana ziemia, rezerwacje), budowane na końcu (nowe miejsca potworów dostają kolejne numery - numery
## dawnych miejsc w zapisach się nie zmieniają).
const TILE := 16
const ROAD_POSTS := 4
const KENNELS := 3
const SCOUTS := 18
const WOLF_HUNTS := 8
## Najmniejsza odległość od palisady Ostoi (w kafelkach) - okolica osady zostaje spokojna.
const SETTLEMENT_CLEARANCE := 10.0
## Posterunki stoją dalej od Ostoi - pierwsze kroki za bramą mają być spokojne.
const POST_CLEARANCE := 20.0
const KENNEL_RADIUS := 4.3

var w  # świat
## Posterunki: [miejsce, kierunek do drogi].
var _posts: Array = []
var _kennels: Array[Vector2] = []
var _scouts: Array[Vector2] = []
var _hunts: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()
var _palisade := Rect2()


func plan(world) -> void:
	w = world
	_rng.seed = hash([w._seed, "goblin_posts"])
	_palisade = Rect2(Vector2(w._settlement_area.position + Vector2i.ONE * w.settlement_margin), Vector2(Settlement.SIZE))
	_plan_posts()
	_plan_kennels()
	_plan_scouts()
	_plan_hunts()


func _plan_posts() -> void:
	var road: PackedVector2Array = w._road
	var spots: Array[Vector2] = []
	for attempt in 800:
		if _posts.size() >= ROAD_POSTS:
			break
		var i := _rng.randi_range(1, road.size() - 2)
		var along: Vector2 = (road[i + 1] - road[i - 1]).normalized()
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var spot: Vector2 = road[i] + along.orthogonal() * side * 9.0
		if not _free(spot, 4.0, 8.0, 4.0) or not _far(spot, spots, 24.0) or w._distance_to_rect(spot, _palisade) < POST_CLEARANCE:
			continue
		spots.append(spot)
		_posts.append([spot, (road[i] - spot).normalized()])
		_claim(spot, 5.0)


func _plan_kennels() -> void:
	var size := Vector2(w.map_size)
	for attempt in 300:
		if _kennels.size() >= KENNELS:
			break
		var spot := Vector2(_rng.randf_range(size.x * 0.08, size.x * 0.6), _rng.randf_range(size.y * 0.55, size.y * 0.92))
		if not _free(spot, KENNEL_RADIUS + 3.0, 14.0) or not _far(spot, _kennels, 26.0) or Road.distance_to(spot, w._road) < 9.0:
			continue
		_kennels.append(spot)
		_claim(spot, KENNEL_RADIUS + 3.0)


func _plan_scouts() -> void:
	var size := Vector2(w.map_size)
	for attempt in 400:
		if _scouts.size() >= SCOUTS:
			break
		var spot := Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y))
		if not _free(spot, 2.0, 9.0) or not _far(spot, _scouts + _kennels, 12.0) or Road.distance_to(spot, w._road) < 5.0:
			continue
		_scouts.append(spot)
		w._reserve_area(spot, 2.0)


## Wilcze łowy na pasie przy siedlisku wilków (na zachód i na północ od niego), poza samym siedliskiem.
func _plan_hunts() -> void:
	var rect: Rect2 = w._wolf_rect.grow(22.0)
	for attempt in 400:
		if _hunts.size() >= WOLF_HUNTS:
			break
		var spot := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
		if w._wolf_strength(Vector2i(spot)) > 0.05 or not _free(spot, 2.5, 10.0) or not _far(spot, _hunts, 12.0):
			continue
		if Road.distance_to(spot, w._road) < 5.0:
			continue
		_hunts.append(spot)
		w._reserve_area(spot, 2.5)


## Czy miejsce jest wolne: daleko od Ostoi, wyjść z krainy (krawędzi), dawnych siedlisk, leży, łowisk i rezerwacji.
func _free(spot: Vector2, radius: float, gap: float, herd_gap := 8.0) -> bool:
	var size := Vector2(w.map_size)
	var edge := minf(minf(spot.x, spot.y), minf(size.x - spot.x, size.y - spot.y))
	if edge < w.border_thickness + radius + 3.0 or w._distance_to_rect(spot, _palisade) < SETTLEMENT_CLEARANCE:
		return false
	if spot.distance_to(w._chief_lair) < w.lair_radius + gap or spot.distance_to(w._alpha_lair) < w.lair_radius + gap:
		return false
	var taken: Array[Vector2] = w._camp_tiles + w._group_tiles + w._den_tiles + w._carcass_tiles
	if not _far(spot, taken, gap):
		return false
	for herd: Array in w._herds:
		if spot.distance_to(herd[1]) < herd_gap:
			return false
	for cell in w._cells_in_radius(spot, radius):
		if w._reserved.has(cell) or w._road_clear.has(cell):
			return false
	return true


func _far(spot: Vector2, others: Array, min_distance: float) -> bool:
	for other: Vector2 in others:
		if spot.distance_to(other) < min_distance:
			return false
	return true


## Udeptany placyk obozowiska bez drzew (z zapasem na korony) i drobiazgów runa.
func _claim(spot: Vector2, radius: float) -> void:
	w._reserve_area(spot, radius + 3.0)
	w._trample_patch(spot, radius)
	for cell in w._cells_in_radius(spot, radius + 1.0):
		w._goblin_camp_cells[cell] = true


func build() -> void:
	for post: Array in _posts:
		_build_post(post[0] * TILE, post[1])
	for spot in _kennels:
		_build_kennel(spot * TILE)
	for spot in _scouts:
		_build_scouts(spot * TILE)
	for spot in _hunts:
		_build_hunt(spot * TILE)


## Posterunek: rząd pali od strony drogi (z przejściem pośrodku), za nim ognisko z siedzącą zgrają, dwa namioty
## z tyłu, łucznicy przy przejściu patrzący na drogę, osiłek, sztandar i stojak z bronią.
func _build_post(center: Vector2, to_road: Vector2) -> void:
	var across := to_road.orthogonal()
	var front := center + to_road * 62.0
	for k in range(-3, 4):
		if absi(k) <= 0:
			continue  # przejście
		w._spawn_palisade(front + across * k * 30.0, across)
	for side in [-1.0, 1.0]:
		var tent: Vector2 = center - to_road * 42.0 + across * side * 50.0
		w._spawn(w.FOREST_PROPS["tent" if side < 0 else "hide_tent"], tent)
		w._map_markers.append({"position": tent, "color": w.MAP_TENT, "size": 2.0})
		w._add_goblin_spawn({"type": "archer", "position": front - to_road * 20.0 + across * side * 24.0, "sitting": false,
				"look_at": front + to_road * 80.0})
	w._spawn(w.FOREST_PROPS["banner"], front - to_road * 16.0 + across * 74.0)
	w._spawn(w.FOREST_PROPS["weapon_rack"], front - to_road * 18.0 - across * 76.0)
	w._spawn(w.CAMPFIRE, center)
	w._map_markers.append({"position": center, "color": w.MAP_FIRE, "size": 2.0})
	var n := _rng.randi_range(6, 8)
	var offset := _rng.randf() * TAU
	for k in n:
		var pos := center + Vector2.from_angle(offset + TAU * k / n + _rng.randf_range(-0.15, 0.15)) * Vector2(34, 25)
		w._add_goblin_spawn({"position": pos, "sitting": true, "look_at": center})
	w._add_goblin_spawn({"type": "brute", "position": front - to_road * 30.0, "sitting": false, "look_at": front + to_road * 80.0})
	for k in 3:
		var pos := center + across * _rng.randf_range(-40, 40) - to_road * _rng.randf_range(10, 30)
		w._add_goblin_spawn({"position": pos, "sitting": false, "look_at": front})


## Psiarnia: zagroda z pali (brama od południa) z oswajanymi wilkami, w środku klatka i kości; przed bramą
## poskramiacze, osiłek i wargi, z boku suszące się skóry.
func _build_kennel(center: Vector2) -> void:
	var r := KENNEL_RADIUS * TILE
	var stakes := 13
	for k in stakes:
		var angle := TAU * k / stakes
		if absf(angle_difference(angle, PI / 2.0)) < 0.4:
			continue  # brama
		w._spawn_palisade(center + Vector2.from_angle(angle) * Vector2(r, r * 0.75), Vector2(-sin(angle) * r, cos(angle) * r * 0.75))
	w._spawn(w.FOREST_PROPS["cage"], center + Vector2(-18, -14))
	w._spawn(w.FOREST_PROPS["bone_pile"], center + Vector2(20, -8))
	w._map_markers.append({"position": center, "color": w.MAP_DEN, "size": 2.5})
	for k in _rng.randi_range(6, 8):
		var pos := center + Vector2.from_angle(_rng.randf() * TAU) * Vector2(r, r * 0.75) * _rng.randf_range(0.25, 0.6)
		w._add_goblin_spawn({"type": "wolf", "pose": "lie", "position": pos, "sitting": true, "look_at": center})
	var gate := center + Vector2(0, r * 0.75 + 30.0)
	for side in [-1.0, 1.0]:
		w._add_goblin_spawn({"type": "warg", "position": gate + Vector2(side * 30.0, 6), "sitting": false, "look_at": gate + Vector2(0, 80)})
	w._add_goblin_spawn({"type": "brute", "position": gate + Vector2(0, 14), "sitting": false, "look_at": center})
	for k in _rng.randi_range(4, 5):
		var pos := gate + Vector2(_rng.randf_range(-60, 60), _rng.randf_range(16, 40))
		w._add_goblin_spawn({"position": pos, "sitting": false, "look_at": center})
	w._spawn(w.FOREST_PROPS["hide_rack"], center + Vector2(r + 30.0, 20))


## Zgraja zwiadowców: przywódca (łucznik albo osiłek) i kilka goblinów.
func _build_scouts(center: Vector2) -> void:
	var n := _rng.randi_range(5, 7)
	var leader := "archer" if _rng.randf() < 0.55 else "brute"
	for k in n:
		var pos := center + Vector2(_rng.randf_range(-18, 18), _rng.randf_range(-14, 14))
		var spawn := {"position": pos, "sitting": false, "look_at": center}
		if k == 0:
			spawn["type"] = leader
		w._add_goblin_spawn(spawn)


## Wilcze łowy: upolowany jeleń i ucztująca wataha (czasem z wargiem).
func _build_hunt(center: Vector2) -> void:
	w._spawn_carcass(center)
	var n := _rng.randi_range(4, 6)
	for k in n:
		var angle := TAU * k / n + _rng.randf_range(-0.3, 0.3)
		var warg := k == 0 and _rng.randf() < 0.3
		w._add_goblin_spawn({"type": "warg" if warg else "wolf", "pose": "lie" if warg else "eat",
				"position": center + Vector2.from_angle(angle) * Vector2(30, 18), "sitting": true, "look_at": center})
