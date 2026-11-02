class_name DungeonDecor
extends RefCounted
## Wspólna część wystroju lochu klimatu z kluczem "decor" (Dungeons.CLIMATES). Każdy klimat ma własny skrypt
## scripts/decor_<klimat>.gd (CatacombsDecor, MineDecor), który dziedziczy po tym i dopisuje: rzędy mebli pod
## ścianami (lines), nakładki na podłogę (floor_decals), wystrój lica ścian (_dress_wall) i scenki komnat
## (funkcje _<rodzaj>(room) dla rodzajów z "themes" oraz _start, _boss i _event).
## Wszystko stoi w porządku, a nie porozrzucane: na licu ścian światła w równych odstępach, pod ścianami komnat
## rzędy mebli według wzoru rodzaju komnaty, środek komnaty urządza scenka. Na podłodze nakładki głównie przy
## ścianach i cień u stóp ścian. Grafiki z tools/dungeon_props.py (assets/dungeons/<klimat>/).
## Duże rekwizyty stoją na wierzchołkach z wolnym otoczeniem i zajmują je w Dungeon.solid - potwory je omijają,
## a przejścia zostają drożne.

const WARM := Color(1.0, 0.62, 0.3, 0.55)
const CANDLE := Color(1.0, 0.75, 0.42, 0.4)
const COLD := Color(0.6, 0.72, 1.0, 0.45)
const RITUAL := Color(0.62, 0.32, 1.0, 0.5)
## Gdzie stoi rekwizyt pod ścianą danej strony względem wierzchołka podłogi.
const SIDE_OFFSET := {"n": Vector2(0, -18), "s": Vector2(0, 26), "w": Vector2(-14, 10), "e": Vector2(14, 10)}

var d: Dungeon
var w
var rng: RandomNumberGenerator
var dir := ""
var _decals: Node2D
var _cache := {}
## Cień u stóp ścian (półprzezroczysta czerń) - wspólna tekstura.
var _shade: GradientTexture2D
## Wierzchołki zajęte wystrojem (meble pod ścianą, scenki) i wierzchołki pod światłami na ścianie (tam nic wysokiego).
var _used := {}
var _sconces := {}


## Wystrój dla klimatu lochu: skrypt scripts/decor_<klimat>.gd.
static func create(dungeon: Dungeon) -> DungeonDecor:
	var script: GDScript = load("res://scripts/decor_%s.gd" % dungeon.config["climate"])
	return script.new(dungeon)


func _init(dungeon: Dungeon) -> void:
	d = dungeon
	w = dungeon.w
	rng = dungeon._rng
	dir = dungeon.climate["decor"]["dir"]


# ---------------------------------------------------------------- do nadpisania w klimacie
## Rzędy mebli pod ścianami: rodzaj komnaty -> strona ("n" pod licem, "s", "w", "e" - boki) -> wzór powtarzany
## wzdłuż ściany ("" - wolne miejsce, ścieżka z "res://" - grafika spoza klimatu).
func lines() -> Dictionary:
	return {}


## Nakładki na podłogę z wagami.
func floor_decals() -> Dictionary:
	return {}


## Niskie rekwizyty, które mogą stać pod światłem na ścianie.
func low_props() -> Array:
	return []


## Rekwizyty z rzędów, które świecą: nazwa -> [kolor, rozmiar plamy, przesunięcie od podstawy].
func line_lights() -> Dictionary:
	return {}


## Lico ściany: odcinek kolejnych wierzchołków "t" w jednym rzędzie.
func _dress_wall(_run: Array[Vector2i]) -> void:
	pass


## Kolumny wokół komnaty Kryształu Watry.
func event_pillars() -> Array:
	return []


func build() -> void:
	# nakładki pod wszystkim innym na warstwie podłogi (plamy światła rysują się na nich)
	_decals = Node2D.new()
	_decals.name = "DungeonDecals"
	w.floors.add_child(_decals)
	w.floors.move_child(_decals, 0)
	_walls()
	var themes: Array = d.climate["decor"]["themes"].duplicate()
	var patterns := lines()
	var queue: Array = []
	for room in d.rooms:
		var theme := ""
		if room == d.start_room:
			theme = "start"
		elif room == d.boss_room:
			theme = "boss"
		elif d.event != "" and room == d.event_room:
			theme = "event"
		else:
			if queue.is_empty():
				queue = themes.duplicate()
				_shuffle(queue)
			theme = str(queue.pop_back())
		d.room_themes[room] = theme
		# najpierw scenka (duże rekwizyty na środku), potem rzędy pod ścianami w wolnych miejscach
		call("_" + theme, room)
		_line(room, patterns.get(theme, {}))
	_floor()


# ---------------------------------------------------------------- pomocnicy
func _tex(name: String) -> Texture2D:
	var path := name if name.begins_with("res://") else dir + name + ".png"
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


func _pick(names: Array) -> String:
	return names[rng.randi() % names.size()]


## Rekwizyt stojący (sortowany z postaciami), bez kolizji.
func _prop(name: String, pos: Vector2, flip := true) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(_tex(name), pos.round(), Vector2.ZERO)
	sprite.flip_h = flip and rng.randf() < 0.5
	sprite.modulate = Color(0.92, 0.92, 0.92)
	return sprite


## Duży rekwizyt na wierzchołku `v`: kolizja u podstawy, wierzchołek zajęty (Dungeon.solid).
func _solid(name: String, v: Vector2i, collision := Vector2(34, 16), flip := true) -> Sprite2D:
	d.solid[v] = true
	_used[v] = true
	var sprite: Sprite2D = w._village_prop(_tex(name), Vector2(v) * Dungeon.CELL + Vector2(0, 10), collision)
	sprite.flip_h = flip and rng.randf() < 0.5
	return sprite


## Płaska nakładka na podłodze albo na licu ściany (pod postaciami).
func _decal(name: String, pos: Vector2, flip := true) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _tex(name)
	sprite.position = pos.round()
	sprite.flip_h = flip and rng.randf() < 0.5
	_decals.add_child(sprite)
	return sprite


## Plama światła; migocząca (płomień) dostaje drgające krycie w Dungeon._process.
func _light(pos: Vector2, color: Color, size: Vector2, flicker := true) -> void:
	var glow := d._glow(pos, color, size)
	if flicker:
		d.flames.append([glow, 1.0, rng.randf() * TAU])


func _floor_at(v: Vector2i) -> bool:
	return d._label(v) == "l" and not d.solid.has(v)


## Wierzchołek na duży rekwizyt: podłoga, a wokół (8 sąsiadów) podłoga bez innych dużych rekwizytów -
## pojedyncza przeszkoda z wolnym pierścieniem nie przecina żadnego przejścia.
func _isolated(v: Vector2i) -> bool:
	if not _floor_at(v) or _used.has(v):
		return false
	for step in Dungeon.STEPS:
		if not _floor_at(v + step):
			return false
	return true


func _px(v: Vector2i) -> Vector2:
	return Vector2(v) * Dungeon.CELL


func _center(room: Rect2i) -> Vector2i:
	return room.position + room.size / 2


func _jitter(amount: float) -> Vector2:
	return Vector2(rng.randf_range(-amount, amount), rng.randf_range(-amount, amount))


## Pas powtarzany wzdłuż komnaty (chodnik, kładka, tory) od punktu `from` w dół (albo w prawo) na długość
## `length` px; tekstura `texture` jest bezszwowa w pionie.
func _runner(from: Vector2, length: float, horizontal: bool, texture := "runner") -> Sprite2D:
	var runner := Sprite2D.new()
	runner.texture = _tex(texture)
	var width := runner.texture.get_width()
	runner.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	runner.region_enabled = true
	runner.region_rect = Rect2(0, 0, width, length)
	runner.centered = false
	runner.offset = Vector2(-width / 2.0, 0)
	runner.position = from.round()
	if horizontal:
		runner.rotation = -PI / 2.0
	_decals.add_child(runner)
	return runner


func _add_shade(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _shade
	sprite.position = pos
	_decals.add_child(sprite)


# ---------------------------------------------------------------- ściany i podłoga
## Lico ściany (wierzchołki "t" pod skałą) - odcinki w rzędach urządza _dress_wall klimatu.
func _walls() -> void:
	for y in Dungeon.GRID.y:
		var run: Array[Vector2i] = []
		for x in Dungeon.GRID.x + 1:
			var v := Vector2i(x, y)
			if x < Dungeon.GRID.x and d._label(v) == "t":
				run.append(v)
				continue
			if not run.is_empty():
				_dress_wall(run)
				run = []


## Indeks pierwszego światła na odcinku ściany: światła co 3 wierzchołki, wyśrodkowane na odcinku.
func _light_start(run: Array[Vector2i]) -> int:
	return (run.size() - 1) % 3 / 2 + (1 if run.size() >= 5 else 0)


## Światło na licu ściany w wierzchołku `v` (grafika `name`); pod nim nic wysokiego.
func _wall_light(name: String, v: Vector2i, color := WARM) -> void:
	var at := _px(v)
	var sconce := _decal(name, at + Vector2(0, -14), false)
	sconce.z_index = 1
	_light(at + Vector2(0, -30), color, Vector2(130, 110))
	_light(at + Vector2(0, 30), Color(color, 0.3), Vector2(190, 110))
	_sconces[v + Vector2i.DOWN] = true


## Nakładki na podłodze (głównie przy ścianach) i cień u stóp ścian.
func _floor() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.02, 0.02, 0.05, 0.3), Color(0.02, 0.02, 0.05, 0.0)])
	_shade = GradientTexture2D.new()
	_shade.gradient = gradient
	_shade.width = 150
	_shade.height = 150
	_shade.fill = GradientTexture2D.FILL_RADIAL
	_shade.fill_from = Vector2(0.5, 0.5)
	_shade.fill_to = Vector2(1.0, 0.5)
	var decals := floor_decals()
	for x in Dungeon.GRID.x:
		for y in Dungeon.GRID.y:
			var v := Vector2i(x, y)
			if d._label(v) != "l":
				continue
			var walls := 0
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]:
				if d._label(v + step) != "l":
					walls += 1
					_add_shade(_px(v) + Vector2(step) * Vector2(30, 24) + (Vector2(0, 8) if step == Vector2i.UP else Vector2.ZERO))
			if d.solid.has(v) or _used.has(v) or decals.is_empty():
				continue
			if rng.randf() < (0.13 if walls > 0 else 0.025):
				_decal(d._pick(decals), _px(v) + _jitter(18) + Vector2(0, 12))


# ---------------------------------------------------------------- rzędy pod ścianami
## Miejsca pod ścianami komnaty (z wnękami): strona -> wierzchołki w kolejności wzdłuż ściany.
func _wall_slots(room: Rect2i) -> Dictionary:
	var slots := {"n": [], "s": [], "w": [], "e": []}
	var area := room.grow(2)
	for x in range(area.position.x, area.end.x):
		for y in range(area.position.y, area.end.y):
			var v := Vector2i(x, y)
			if d._label(v) != "l":
				continue
			if d._label(v + Vector2i.UP) == "t":
				slots["n"].append(v)
			elif d._label(v + Vector2i.DOWN) == "u":
				slots["s"].append(v)
			elif d._label(v + Vector2i.LEFT) == "u":
				slots["w"].append(v)
			elif d._label(v + Vector2i.RIGHT) == "u":
				slots["e"].append(v)
	# wzdłuż ściany: północ i południe po x, boki po y
	for side in ["n", "s"]:
		slots[side].sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for side in ["w", "e"]:
		slots[side].sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return slots


## Rząd mebli pod każdą ścianą według wzoru (kolejne miejsca biorą kolejne pozycje wzoru).
func _line(room: Rect2i, pattern: Dictionary) -> void:
	var slots := _wall_slots(room)
	var low := low_props()
	var lights := line_lights()
	for side: String in slots:
		var names: Array = pattern.get(side, [])
		if names.is_empty():
			continue
		var i := 0
		for v: Vector2i in slots[side]:
			var name: String = names[i % names.size()]
			i += 1
			if name == "" or _used.has(v) or d.solid.has(v):
				continue
			# pod światłem na ścianie nic wysokiego
			if side == "n" and _sconces.has(v) and name not in low:
				continue
			_used[v] = true
			_prop(name, _px(v) + SIDE_OFFSET[side], side == "s")
			if lights.has(name):
				var spec: Array = lights[name]
				_light(_px(v) + SIDE_OFFSET[side] + spec[2], spec[0], spec[1])


# ---------------------------------------------------------------- scenki wspólne
## Komnata Kryształu Watry: kolumnada wzdłuż ścian, środek (kryształ i walka wokół niego) wolny.
func _event(room: Rect2i) -> void:
	var names := event_pillars()
	if names.is_empty():
		return
	var mid := _center(room)
	var kind := _pick(names)
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [room.position.y + 2, room.end.y - 2]:
			var v := Vector2i(x, y)
			if absi(v.x - mid.x) > 1 or absi(v.y - mid.y) > 1:
				if _isolated(v):
					_solid(kind, v, Vector2(26, 14), false)


## Snop zimnego światła z dziury w sklepieniu nad `mid`: dziura w podłodze, krąg gruzu i odłamków
## (`stones` - grafiki większych odłamków, `rubble` - nakładka gruzu) i wirujący kurz.
func _light_shaft(mid: Vector2i, stones: Array, rubble := "rubble", hole := "hole") -> void:
	var shaft := _px(mid) + Vector2(0, 40)
	_used[mid] = true
	_light(shaft, COLD, Vector2(240, 160), false)
	_light(shaft + Vector2(0, -90), Color(COLD, 0.18), Vector2(110, 260), false)
	_decal(hole, shaft + Vector2(0, 4), false)
	for i in 9:
		var angle := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var spot := shaft + Vector2(cos(angle), sin(angle) * 0.7) * rng.randf_range(50, 80)
		if i % 3 == 0:
			_prop(_pick(stones), spot)
		else:
			_decal(rubble, spot)
	_dust(shaft + Vector2(0, -60))


## Narożniki komnaty (o krok od ścian): wierzchołki do postawienia czegoś dużego.
func _corners(room: Rect2i, inset := Vector2i(1, 2)) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for corner: Vector2i in [Vector2i(inset.x, inset.y), Vector2i(-inset.x - 1, inset.y), Vector2i(inset.x, -inset.y),
			Vector2i(-inset.x - 1, -inset.y)]:
		out.append(Vector2i(room.position.x if corner.x > 0 else room.end.x, room.position.y if corner.y > 0 else room.end.y) + corner)
	return out


func _dust(at: Vector2) -> void:
	var dust := CPUParticles2D.new()
	dust.position = at
	dust.amount = 16
	dust.lifetime = 5.0
	dust.preprocess = 5.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(36, 70)
	dust.direction = Vector2(0, 1)
	dust.spread = 40.0
	dust.gravity = Vector2(0, 2)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 6.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.0
	dust.color = Color(0.85, 0.9, 1.0, 0.5)
	dust.z_index = 20
	w.add_child(dust)
