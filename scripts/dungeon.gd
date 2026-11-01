class_name Dungeon
extends Node
## Loch w płomieniach Watry - generowany od nowa przy każdym wejściu (ziarno w ustawieniach wyprawy, Dungeons.config).
## Układ: komnaty połączone korytarzami na siatce wierzchołków co 64 px (40x30). Wierzchołek to podłoga albo skała;
## kafelek Wang 64x64 (PixelLab, ściany pełnej wysokości) dobiera się do czterech narożników komórki, a narożnik pod
## skałą jest "ścianą" (lico ściany wypełnia komórkę pod granicą). Narożniki, których zestaw nie ma, naprawia
## usunięcie drobnego występu skały (przejścia zostają drożne).
## Komnaty: wejściowa z płomieniami Watry (powrót do Ostoi), w pozostałych gromady potworów klimatu, w najdalszej
## strażnik (boss) przy zamkniętym skarbcu - po jego pokonaniu skarbiec się otwiera, a obok buchają płomienie powrotu.
## Mrok (CanvasModulate w kolorze klimatu), pochodnie / koksowniki / grzyby ze światłem i światło wokół gracza.

const CELL := 64
const GRID := Vector2i(40, 30)
const ROOMS := 11
## Kafelki arkusza (kolumna, wiersz) wg narożników NW, NE, SW, SE: l - podłoga, u - skała, t - lico ściany.
## Układ jak w pixellab_src/alpine/cliff.json (ten sam tryb generowania PixelLab).
const WANG := {"llll": Vector2i(2, 2), "lllu": Vector2i(3, 2), "lluu": Vector2i(1, 4), "llul": Vector2i(2, 4),
		"lulu": Vector2i(3, 4), "uuuu": Vector2i(0, 6), "ulul": Vector2i(1, 1), "uluu": Vector2i(0, 4), "luuu": Vector2i(3, 6),
		"uuut": Vector2i(1, 6), "uutt": Vector2i(3, 0), "ultl": Vector2i(1, 2), "utul": Vector2i(0, 3), "ttll": Vector2i(3, 1),
		"tlll": Vector2i(1, 3), "lult": Vector2i(2, 0), "uutu": Vector2i(0, 0), "ultu": Vector2i(2, 6), "ltll": Vector2i(2, 1),
		"tulu": Vector2i(2, 7), "luut": Vector2i(0, 2)}
## Lico ściany blokuje trochę niżej niż do połowy komórki - postać staje u jego stóp.
const FACE_DEPTH := 40.0
const PORTAL := preload("res://assets/village/watra.png")
const ALTAR := preload("res://assets/dungeons/veles_altar.png")
const NPC_SCENE := preload("res://scenes/npc.tscn")
const CHEST := preload("res://assets/village/chest.png")
const PORTAL_FPS := 7.0
## Ile potworów na wierzchołek podłogi komnaty i jak duże są gromady.
const DENSITY := 0.42
const PACK := Vector2i(4, 7)
const LEASH := 5000.0

var w
var config := {}
var climate := {}
var level := 1
## wierzchołek (Vector2i) -> true: podłoga
var floor_cells := {}
var rooms: Array[Rect2i] = []
var start_room := Rect2i()
var boss_room := Rect2i()
## Komnata Kryształu Watry (pusta do czasu zdarzenia) i jego wariant ("" - loch bez kryształu).
var event_room := Rect2i()
var event := ""
var crystal: WatraCrystal
## Ołtarz Welesa (Essences): ukryta komnata poza listą komnat - bez potworów i pochodni (pusta - brak ołtarza).
var altar_room := Rect2i()
var altar: Npc
var _altar_sprite: Sprite2D
var _altar_glow: Sprite2D
var _corridors: Array[PackedVector2Array] = []
var _rng := RandomNumberGenerator.new()
var _portals: Array[Dictionary] = []
var _boss: Goblin
var _chest: Sprite2D
var _vault_open := false
var _light: Sprite2D
var _time := 0.0
## Droga do gracza: wierzchołek podłogi -> liczba kroków do wierzchołka gracza (liczona od nowa, gdy gracz zmieni wierzchołek).
var _flow := {}
var _flow_from := Vector2i(-1, -1)
const STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]


func generate(world, settings: Dictionary) -> void:
	w = world
	config = settings
	climate = Dungeons.CLIMATES[settings["climate"]]
	_rng.seed = int(settings["seed"])
	level = Dungeons.tier_level(int(settings["tier"]))
	Levels.zone_default = level
	Goblin.safe_zone = Rect2()
	var mods: Array = settings.get("mods", [])
	Goblin.dungeon_mods = {}
	for key in ["health", "damage", "xp", "gold", "loot"]:
		Goblin.dungeon_mods[key] = Dungeons.multiplier(mods, key)
	_plan_rooms()
	_plan_altar()
	_connect_rooms()
	_fix_corners()
	_pick_rooms()
	_pick_event()
	_build_tiles()
	_build_collision()
	_build_map()
	w._build_bounds()
	_build_atmosphere()
	_build_props()
	_build_entrance()
	_populate(Dungeons.multiplier(mods, "count") * (1.0 + Dungeons.TIER_COUNT_BONUS * (int(settings["tier"]) - 1)))
	_build_vault()
	_build_event()
	_build_altar()
	Goblin.pathing = self


# ---------------------------------------------------------------- układ
## Prostokątne komnaty (w wierzchołkach) z odstępem co najmniej 2; pierwsza jest duża - nada się na komnatę strażnika.
func _plan_rooms() -> void:
	var tries := 0
	while rooms.size() < ROOMS and tries < 3000:
		tries += 1
		var size := Vector2i(_rng.randi_range(7, 9), _rng.randi_range(6, 7)) if rooms.is_empty() \
				else Vector2i(_rng.randi_range(4, 8), _rng.randi_range(4, 7))
		var pos := Vector2i(_rng.randi_range(2, GRID.x - size.x - 3), _rng.randi_range(2, GRID.y - size.y - 3))
		var room := Rect2i(pos, size)
		if rooms.any(func(other: Rect2i) -> bool: return other.grow(2).intersects(room)):
			continue
		rooms.append(room)
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells[Vector2i(x, y)] = true


## Ołtarz Welesa: rzadko (Essences.ALTAR_CHANCE, w trybie deweloperskim albo z "altar" w ustawieniach zawsze)
## mała komnata w wolnym miejscu mapy, połączona wąskim przejściem z najbliższą komnatą.
func _plan_altar() -> void:
	var wanted: bool = config.get("altar", Game.dev_mode or _rng.randf() < Essences.ALTAR_CHANCE)
	if not wanted:
		return
	for tries in 1200:
		var size := Vector2i(4, 4)
		var pos := Vector2i(_rng.randi_range(2, GRID.x - size.x - 3), _rng.randi_range(2, GRID.y - size.y - 3))
		var room := Rect2i(pos, size)
		# odstęp od komnat: najpierw 2 wierzchołki, przy ciasnym lochu - 1
		var gap := 2 if tries < 800 else 1
		if rooms.any(func(other: Rect2i) -> bool: return other.grow(gap).intersects(room)):
			continue
		altar_room = room
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells[Vector2i(x, y)] = true
		var center := room.position + room.size / 2
		var nearest := rooms[0]
		for other in rooms:
			if Vector2(other.get_center() - center).length() < Vector2(nearest.get_center() - center).length():
				nearest = other
		_dig(center, nearest.position + nearest.size / 2)
		_corridors.pop_back()  # w przejściu do ołtarza nie stoją potwory
		return


func _build_altar() -> void:
	if altar_room == Rect2i():
		return
	var pos := Vector2(altar_room.get_center()) * CELL + Vector2(0, CELL * 0.4)
	_altar_sprite = w._village_prop(ALTAR, pos, Vector2(70, 26))
	_altar_glow = _glow(pos + Vector2(0, -30), Color(0.35, 1.0, 0.45, 0.55), Vector2(220, 160))
	altar = NPC_SCENE.instantiate()
	altar.position = pos + Vector2(0, 26)
	altar.role = Npc.Role.IDLE
	altar.looks_around = false
	altar.display_name = "Ołtarz Welesa"
	altar.services.assign(["altar"])
	w.entities.add_child(altar)
	altar.get_node("Sprite").visible = false
	altar.get_node("Shadow").visible = false
	altar.prompt.text = Lang.t("[F] Ołtarz Welesa")
	w.hud.essence_window.altar_used.connect(_spend_altar)


## Ołtarz przyjął ofiarę: gaśnie i nie da się go już użyć.
func _spend_altar() -> void:
	if altar == null or not is_instance_valid(altar):
		return
	altar.services.assign([])
	altar.remove_from_group("interactables")
	altar.prompt.visible = false
	_altar_sprite.modulate = Color(0.55, 0.55, 0.6)
	_altar_glow.visible = false


## Korytarze szerokości 2 wierzchołków: drzewo rozpinające komnat (najkrótsze połączenia) i dwie dodatkowe pętle.
func _connect_rooms() -> void:
	var centers: Array[Vector2i] = []
	for room in rooms:
		centers.append(room.position + room.size / 2)
	var joined := {0: true}
	var edges: Array[Vector2i] = []
	while joined.size() < rooms.size():
		var best := Vector2i(-1, -1)
		var best_d := 1 << 30
		for a: int in joined:
			for b in rooms.size():
				if joined.has(b):
					continue
				var d := absi(centers[a].x - centers[b].x) + absi(centers[a].y - centers[b].y)
				if d < best_d:
					best_d = d
					best = Vector2i(a, b)
		edges.append(best)
		joined[best.y] = true
	for i in 2:
		edges.append(Vector2i(_rng.randi() % rooms.size(), _rng.randi() % rooms.size()))
	for edge in edges:
		if edge.x != edge.y:
			_dig(centers[edge.x], centers[edge.y])


func _dig(from: Vector2i, to: Vector2i) -> void:
	var corner := Vector2i(to.x, from.y) if _rng.randf() < 0.5 else Vector2i(from.x, to.y)
	var path := PackedVector2Array()
	for leg in [[from, corner], [corner, to]]:
		var a: Vector2i = leg[0]
		var b: Vector2i = leg[1]
		var step := (b - a).sign()
		var at := a
		while true:
			path.append(Vector2(at))
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				floor_cells[at + d] = true
			if at == b:
				break
			at += step
	_corridors.append(path)


func _label(v: Vector2i) -> String:
	if not floor_cells.has(v):
		return "u"
	return "t" if not floor_cells.has(v + Vector2i.UP) else "l"


func _key(cell: Vector2i) -> String:
	return _label(cell) + _label(cell + Vector2i.RIGHT) + _label(cell + Vector2i.DOWN) + _label(cell + Vector2i.ONE)


## Komórki bez pasującego kafelka: skała w środku mapy zamienia się w podłogę (znika drobny występ, przejście zostaje),
## przy brzegu mapy - podłoga w skałę.
func _fix_corners() -> void:
	for _pass in 80:
		var bad := 0
		for x in GRID.x - 1:
			for y in GRID.y - 1:
				var cell := Vector2i(x, y)
				if WANG.has(_key(cell)):
					continue
				bad += 1
				var corners: Array[Vector2i] = [cell, cell + Vector2i.RIGHT, cell + Vector2i.DOWN, cell + Vector2i.ONE]
				var inner := corners.all(func(v: Vector2i) -> bool:
					return v.x >= 2 and v.y >= 2 and v.x <= GRID.x - 3 and v.y <= GRID.y - 3)
				for v in corners:
					if inner:
						floor_cells[v] = true
					else:
						floor_cells.erase(v)
		if bad == 0:
			return


## Wejście w komnacie najbardziej na zachód, strażnik w największej z dalekich komnat (wg drogi przez loch).
func _pick_rooms() -> void:
	start_room = rooms[0]
	for room in rooms:
		if room.get_center().x < start_room.get_center().x:
			start_room = room
	var distance := _distances(start_room.position + start_room.size / 2)
	var best_score := -1.0
	for room in rooms:
		if room == start_room:
			continue
		var d: int = distance.get(room.position + room.size / 2, 0)
		var score := d * (1.5 if room.size.x >= 6 and room.size.y >= 5 else 1.0)
		if score > best_score:
			best_score = score
			boss_room = room


## Kryształ Watry: losowo (zawsze w trybie deweloperskim albo gdy wyprawa ma "event") w największej komnacie
## poza wejściową i komnatą strażnika.
func _pick_event() -> void:
	event = str(config.get("event", ""))
	if event == "":
		if not Game.dev_mode and _rng.randf() >= Dungeons.EVENT_CHANCE:
			return
		event = Dungeons.EVENTS[_rng.randi() % Dungeons.EVENTS.size()]
	var best := -1
	for room in rooms:
		if room == start_room or room == boss_room:
			continue
		if room.get_area() > best:
			best = room.get_area()
			event_room = room
	if best < 0:
		event = ""


func _build_event() -> void:
	if event == "":
		return
	crystal = WatraCrystal.new()
	crystal.dungeon = self
	crystal.variant = event
	crystal.room = event_room
	crystal.level = level
	crystal.tier = int(config.get("tier", 1))
	crystal.count_mult = Dungeons.multiplier(config.get("mods", []), "count")
	crystal.position = Vector2(event_room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	w.entities.add_child(crystal)
	_glow(crystal.position + Vector2(0, -16), Color(1.0, 0.45, 0.2, 0.6), Vector2(200, 140))
	w._map_markers.append({"position": crystal.position, "color": Color(1.0, 0.45, 0.25), "size": 3.0})


## Odległość (w krokach po podłodze) od wierzchołka do wszystkich innych.
func _distances(from: Vector2i) -> Dictionary:
	var result := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var v: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = v + d
			if floor_cells.has(n) and not result.has(n):
				result[n] = result[v] + 1
				queue.append(n)
	return result


# ---------------------------------------------------------------- budowa
func _build_tiles() -> void:
	var source := TileSetAtlasSource.new()
	source.texture = climate["tiles"]
	source.texture_region_size = Vector2i(CELL, CELL)
	for coord: Vector2i in WANG.values():
		if not source.has_tile(coord):
			source.create_tile(coord)
	# pełne kafelki podłogi i skały w 4 odbiciach - powtarzający się wzór (np. rzędy grzybów) się rozmywa;
	# kafelek jest bezszwowy, więc odbity styka się z sąsiadami lustrzaną krawędzią
	for coord: Vector2i in [WANG["llll"], WANG["uuuu"]]:
		for flips in [[true, false], [false, true], [true, true]]:
			var alternative := source.create_alternative_tile(coord)
			source.get_tile_data(coord, alternative).flip_h = flips[0]
			source.get_tile_data(coord, alternative).flip_v = flips[1]
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(CELL, CELL)
	tiles.add_source(source, 0)
	var layer := TileMapLayer.new()
	layer.name = "DungeonTiles"
	layer.tile_set = tiles
	for x in GRID.x - 1:
		for y in GRID.y - 1:
			var key := _key(Vector2i(x, y))
			var alternative := _rng.randi() % 4 if key == "llll" or key == "uuuu" else 0
			layer.set_cell(Vector2i(x, y), 0, WANG[key], alternative)
	w.ground.add_sibling(layer)


## Kolizje: kwadrat wokół każdego wierzchołka skały i lica ściany, łączone w poziome pasy.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "DungeonWalls"
	w.add_child(body)
	for y in GRID.y:
		var run_start := -1
		var run_kind := ""
		for x in GRID.x + 1:
			var kind := _label(Vector2i(x, y)) if x < GRID.x else "l"
			kind = "" if kind == "l" else kind
			if kind != run_kind:
				if run_kind != "":
					_wall_box(body, run_start, x - 1, y, run_kind)
				run_start = x
				run_kind = kind


func _wall_box(body: StaticBody2D, from_x: int, to_x: int, y: int, kind: String) -> void:
	var top := y * CELL - CELL / 2.0
	var bottom := y * CELL + (FACE_DEPTH if kind == "t" else CELL / 2.0)
	var rect := Rect2(from_x * CELL - CELL / 2.0, top, (to_x - from_x + 1) * CELL, bottom - top)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)


## Minimapa: każdy kafelek gry wg najbliższego wierzchołka (podłoga, lico, skała).
func _build_map() -> void:
	var tile: int = w.TILE
	for x in w.map_size.x:
		for y in w.map_size.y:
			var px := (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
			var label := _label(Vector2i((px / CELL).round()))
			var color: Color = climate["map_floor"] if label == "l" else climate["map_wall"]
			if label == "t":
				color = climate["map_wall"].lerp(climate["map_floor"], 0.35)
			w._map_props[Vector2i(x, y)] = color


func _build_atmosphere() -> void:
	var dark := CanvasModulate.new()
	dark.color = climate["tint"]
	w.add_child(dark)
	_light = _glow(Vector2.ZERO, Color(1.0, 0.85, 0.65, 0.35), Vector2(300, 220))


## Ciepła (albo zimna) plama światła na podłodze, pod postaciami.
func _glow(pos: Vector2, color: Color, glow_size: Vector2) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(glow_size.x)
	texture.height = int(glow_size.y)
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = pos
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	w.floors.add_child(glow)
	return glow


## Bezpieczny punkt podłogi komnaty (z dala od ścian i od lica ściany na północy), w pikselach.
func _room_point(room: Rect2i, margin := 0.0) -> Vector2:
	var from := Vector2(room.position.x, room.position.y + 1) * CELL + Vector2(margin, margin)
	var to := Vector2(room.end.x - 1, room.end.y - 1) * CELL - Vector2(margin, margin)
	return Vector2(_rng.randf_range(from.x, maxf(from.x, to.x)), _rng.randf_range(from.y, maxf(from.y, to.y)))


## Pochodnie (koksowniki, świecące grzyby) pod północną ścianą komnat, wystrój pod ścianami i porozrzucany
## po komnatach i korytarzach (bez kolizji, tylko w wolnych miejscach).
func _build_props() -> void:
	var lamp: Texture2D = load(climate["lamp"])
	var frames: int = climate["lamp_frames"]
	var props: Array = climate["props"].map(func(path: String) -> Texture2D: return load(path))
	var wall_props: Array = climate["wall_props"].map(func(path: String) -> Texture2D: return load(path))
	for path in _corridors:
		for i in range(3, path.size() - 3, 5):
			if _rng.randf() < 0.6:
				var at := (path[i] + Vector2(0.5, 0.5)) * CELL + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-14, 14))
				_scatter_prop(props.pick_random(), at)
	for room in rooms:
		var y := (room.position.y + 1) * CELL + 6.0
		var count := maxi(1, room.size.x / 3)
		for i in count:
			var x := lerpf(room.position.x * CELL + 24.0, (room.end.x - 1) * CELL - 24.0, (i + 0.5) / count)
			var sprite: Sprite2D = w._village_prop(lamp, Vector2(x, y), Vector2(8, 4), frames)
			if frames == 2:
				sprite.frame = _rng.randi() % 2
				w._flicker(sprite)
			_glow(Vector2(x, y - 6), climate["light"], Vector2(150, 100))
		# między pochodniami pod ścianą: skrzynie, świece, kokony...
		for i in count:
			if _rng.randf() < 0.7:
				var x := lerpf(room.position.x * CELL + 24.0, (room.end.x - 1) * CELL - 24.0, (i + 1.0) / count)
				_scatter_prop(wall_props.pick_random(), Vector2(x + _rng.randf_range(-10, 10), y + 4.0))
		if room == start_room:
			continue
		for i in maxi(3, room.size.x * room.size.y / 6):
			_scatter_prop(props.pick_random(), _room_point(room, 16.0))


## Rekwizyt bez kolizji w wolnym miejscu (punkt w ścianie przepada).
func _scatter_prop(tex: Texture2D, at: Vector2) -> void:
	if _blocked(at, 4.0):
		return
	var sprite: Sprite2D = w._village_prop(tex, at, Vector2.ZERO)
	sprite.flip_h = _rng.randf() < 0.5
	sprite.modulate = Color(0.9, 0.9, 0.9)


## Płomienie Watry w komnacie wejściowej: wejście w nie wraca do Ostoi (tak samo te po pokonaniu strażnika).
func _build_entrance() -> void:
	var center := Vector2(start_room.get_center()) * CELL
	var pos := Vector2(center.x, start_room.position.y * CELL + 84.0)
	_add_portal(pos, Lang.t("Płomienie Watry - powrót do Ostoi"))
	w._spawn_point = pos + Vector2(0, 56)
	w._arrivals["start"] = w._spawn_point


func _add_portal(pos: Vector2, text: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PORTAL
	sprite.hframes = 6
	sprite.offset = Vector2(0, -PORTAL.get_height() / 2.0 + 10.0)
	sprite.position = pos
	w.entities.add_child(sprite)
	_glow(pos + Vector2(0, -10), Color(1.0, 0.55, 0.2, 0.7), Vector2(240, 170))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 10)
	label.position = pos + Vector2(-80, -92)
	label.z_index = 30
	w.add_child(label)
	_portals.append({"sprite": sprite, "rect": Rect2(pos + Vector2(-26, -18), Vector2(52, 26))})
	w._map_markers.append({"position": pos, "color": Color(1.0, 0.6, 0.25), "size": 3.0})


## Potwory: gromady w komnatach (im dalej od wejścia, tym o poziom wyżej), mniejsze grupki w długich korytarzach,
## strażnik ze świtą w komnacie skarbca.
func _populate(count_mult: float) -> void:
	var weights: Dictionary = climate["monsters"]
	var distance := _distances(start_room.position + start_room.size / 2)
	var far := 1
	for d: int in distance.values():
		far = maxi(far, d)
	for room in rooms:
		if room == start_room or (event != "" and room == event_room):
			continue
		var depth: float = float(distance.get(room.position + room.size / 2, 0)) / far
		var lvl := level + (1 if depth > 0.6 else 0)
		var total := roundi(room.size.x * room.size.y * DENSITY * count_mult)
		if room == boss_room:
			total = roundi(6 * count_mult)
		while total > 0:
			var n := mini(total, _rng.randi_range(PACK.x, PACK.y))
			total -= n
			var center := _room_point(room, 28.0)
			for i in n:
				var pos := center + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-22, 22))
				_spawn(_pick(weights), pos, center, lvl)
	for path in _corridors:
		if path.size() < 9:
			continue
		var mid := (path[path.size() / 2] + Vector2(0.5, 0.5)) * CELL
		# korytarz przez komnatę Kryształu Watry - ta zostaje pusta do czasu zdarzenia
		if event != "" and Rect2(Vector2(event_room.position) * CELL, Vector2(event_room.size) * CELL).grow(CELL).has_point(mid):
			continue
		for i in roundi(_rng.randi_range(2, 4) * count_mult):
			_spawn(_pick(weights), mid + Vector2(_rng.randf_range(-16, 16), _rng.randf_range(-16, 16)), mid, level)


func _pick(weights: Dictionary) -> String:
	var total := 0.0
	for kind: String in weights:
		total += float(weights[kind])
	var roll := _rng.randf() * total
	for kind: String in weights:
		roll -= float(weights[kind])
		if roll <= 0.0:
			return kind
	return weights.keys()[0]


func _spawn(kind: String, pos: Vector2, look_at: Vector2, lvl: int) -> Dictionary:
	var spawn := {"type": kind, "position": _free_spot(pos, look_at), "sitting": false, "look_at": look_at, "level": lvl, "lurk": false}
	w._add_goblin_spawn(spawn)
	# w lochu potwory nie odpuszczają pogoni (droga i tak prowadzi wokół ścian); strażnik pilnuje skarbca
	var goblin: Goblin = w._live_goblins.get(spawn["id"])
	if goblin != null and not goblin is Boss:
		goblin.leash_radius = LEASH
	return spawn


## Czy punkt (z zapasem `margin` na ciało potwora) leży w kolizji skały albo lica ściany (patrz _wall_box).
func _blocked(pos: Vector2, margin := 10.0) -> bool:
	var center := Vector2i((pos / CELL).round())
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var v := center + Vector2i(dx, dy)
			var kind := _label(v)
			if kind == "l":
				continue
			var top := v.y * CELL - CELL / 2.0
			var bottom := v.y * CELL + (FACE_DEPTH if kind == "t" else CELL / 2.0)
			var rect := Rect2(v.x * CELL - CELL / 2.0, top, CELL, bottom - top).grow(margin)
			if rect.has_point(pos):
				return true
	return false


## Wolne miejsce dla potwora: sam punkt, a gdy wypada w ścianie - pierwszy wolny punkt w stronę `toward`
## albo najbliższy wolny wierzchołek podłogi (inaczej potwór stałby w ścianie, nietrafialny).
func _free_spot(pos: Vector2, toward: Vector2) -> Vector2:
	if not _blocked(pos):
		return pos
	for i in range(1, 9):
		var spot := pos.lerp(toward, i / 8.0)
		if not _blocked(spot):
			return spot
	var best := toward
	var best_d := INF
	var center := Vector2i((pos / CELL).round())
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			var spot := Vector2(center + Vector2i(dx, dy)) * CELL
			if not _blocked(spot) and spot.distance_squared_to(pos) < best_d:
				best_d = spot.distance_squared_to(pos)
				best = spot
	return best


## Strażnik na środku najdalszej komnaty i zamknięta skrzynia skarbca pod jej północną ścianą.
func _build_vault() -> void:
	var center := Vector2(boss_room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	var spawn := _spawn(climate["boss"], center, center + Vector2(0, 40), level + Dungeons.BOSS_BONUS)
	_boss = w._live_goblins.get(spawn["id"])
	if _boss != null:
		_boss.died.connect(_on_boss_died)
	_chest = Sprite2D.new()
	_chest.texture = CHEST
	_chest.scale = Vector2(1.6, 1.6)
	_chest.offset = Vector2(0, -CHEST.get_height() / 2.0)
	_chest.position = Vector2(center.x, (boss_room.position.y + 1) * CELL + 20.0)
	_chest.modulate = Color(0.75, 0.75, 0.8)
	w.entities.add_child(_chest)
	_glow(_chest.position, Color(1.0, 0.85, 0.4, 0.4), Vector2(120, 80))
	w._map_markers.append({"position": _chest.position, "color": Color(1.0, 0.85, 0.3), "size": 3.0})


## Strażnik pokonany: skarbiec wysypuje łup, obok buchają płomienie powrotu.
func _on_boss_died(_boss_node: Goblin = null) -> void:
	if _vault_open:
		return
	_vault_open = true
	w.player.quests.note_event("dungeon_clear")
	var mods: Array = config.get("mods", [])
	var treasure := Dungeons.multiplier(mods, "treasure")
	var loot_level := level + Dungeons.BOSS_BONUS
	var at := _chest.position + Vector2(0, 16)
	_chest.modulate = Color.WHITE
	_drop(at, "gold", roundi(Levels.gold(loot_level) * 30.0 * treasure * Dungeons.multiplier(mods, "gold")))
	for i in roundi(3 * treasure):
		_drop(at, Loot.drop_at_level(loot_level, 0.3, Loot.MAGIC), 1)
	if treasure > 1.0:
		for i in 2:
			_drop(at, Loot.drop_at_level(loot_level, 0.5, Loot.RARE), 1)
	var chances := Levels.stone_chances(loot_level)
	for category in ["weapon", "armor", "jewelry"]:
		if _rng.randf() < 0.5 + chances[1] * 4.0:
			_drop(at, Enchanting.stone_id(category, _rng.randf() < chances[1] * 6.0), roundi(_rng.randi_range(1, 2) * treasure))
	_drop(at, "blessed_stone", roundi(_rng.randi_range(1, 3) * treasure))
	if int(config.get("tier", 1)) >= Essences.HEART_MIN_TIER and _rng.randf() < Essences.HEART_VAULT_CHANCE * treasure:
		_drop(at, Essences.HEART, 1)
	if _rng.randf() < ItemCraft.RUNE_VAULT_CHANCE * treasure:
		_drop(at, "rune_seal" if int(config.get("tier", 1)) >= 4 and _rng.randf() < 0.35 else "rune_chaos", 1)
	if _rng.randf() < Gems.RADIUS_VAULT_CHANCE * treasure:
		_drop(at, Gems.roll_radius(int(config.get("tier", 1))), 1)
	var bag := Bags.roll_vault(loot_level, treasure)
	if bag != "":
		_drop(at, bag, 1)
	if _rng.randf() < Dungeons.VAULT_LEGEND_CHANCE * treasure:
		_drop(at, Loot.legendary_at_level(Dungeons.VAULT_LEGENDS.pick_random(), loot_level), 1)
	Sfx.play("quest_ready")
	_add_portal(Vector2(boss_room.get_center()) * CELL + Vector2(0, CELL * 1.2), Lang.t("Płomienie Watry - powrót do Ostoi"))
	w.hud.show_banner(Lang.t("Strażnik pokonany! Skarbiec otwarty\nPłomienie Watry zabiorą cię do Ostoi"), Color(1.0, 0.8, 0.4))


# ---------------------------------------------------------------- droga przez loch
## Czy po wierzchołku da się chodzić (podłoga, nie skała i nie lico ściany).
func _walkable(v: Vector2i) -> bool:
	return _label(v) == "l"


## Krok po skosie tylko wtedy, gdy oba boczne wierzchołki są wolne - bez ścinania rogów ścian.
func _can_step(from: Vector2i, step: Vector2i) -> bool:
	if not _walkable(from + step):
		return false
	return step.x == 0 or step.y == 0 or (_walkable(from + Vector2i(step.x, 0)) and _walkable(from + Vector2i(0, step.y)))


## Odległości od wierzchołka gracza do całej podłogi lochu (przeszukiwanie wszerz).
func _update_flow(target: Vector2i) -> void:
	_flow_from = target
	_flow = {target: 0}
	var queue: Array[Vector2i] = [target]
	var head := 0
	while head < queue.size():
		var v := queue[head]
		head += 1
		for step in STEPS:
			var n := v + step
			if not _flow.has(n) and _can_step(v, step):
				_flow[n] = _flow[v] + 1
				queue.append(n)


## Kierunek, w którym potwór z punktu `from` ma iść do gracza: do sąsiedniego wierzchołka bliżej gracza.
## Zero, gdy gracz jest tuż obok (wtedy prosto) albo potwór stoi poza podłogą.
func steer(from: Vector2) -> Vector2:
	var v := Vector2i((from / CELL).round())
	var here: int = _flow.get(v, -1)
	if here >= 0 and here <= 1:
		return Vector2.ZERO
	var best := Vector2i(-1, -1)
	var best_d := here if here >= 0 else 1 << 30
	for step in STEPS:
		var n := v + step
		var d: int = _flow.get(n, -1)
		if d >= 0 and d < best_d and (here < 0 or _can_step(v, step)):
			best_d = d
			best = n
	if best.x < 0:
		return Vector2.ZERO
	return (Vector2(best) * CELL - from).normalized()


func _drop(at: Vector2, id: String, amount: int) -> void:
	if amount <= 0:
		return
	var pickup: Pickup = load(Goblin.PICKUP_PATH).instantiate()
	pickup.item_id = id
	pickup.amount = amount
	pickup.position = at + Vector2(_rng.randf_range(-28, 28), _rng.randf_range(-6, 18))
	w.entities.add_child(pickup)


func _process(delta: float) -> void:
	if w == null:
		return
	_time += delta
	var frame := int(_time * PORTAL_FPS) % 6
	for portal: Dictionary in _portals:
		portal["sprite"].frame = frame
	if _light != null:
		_light.global_position = w.player.global_position + Vector2(0, -8)
	var player_vertex := Vector2i((w.player.global_position / CELL).round())
	if player_vertex != _flow_from:
		_update_flow(player_vertex)
	if w._traveling or w.player.is_dead:
		return
	for portal: Dictionary in _portals:
		if portal["rect"].has_point(w.player.global_position):
			Sfx.play("magic", 2.0, 0.7)
			w._travel("forest", "watra")
			return
