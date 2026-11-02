class_name DungeonDecor
extends RefCounted
## Wystrój lochu klimatu z kluczem "decor" (Dungeons.CLIMATES, na razie Katakumby). Wszystko stoi w porządku,
## a nie porozrzucane: kinkiety w równych odstępach na licu ścian (między nimi nisze, chorągwie, wykruszenia),
## pod ścianami komnat rzędy mebli według wzoru rodzaju komnaty (półki z czaszkami, stojące trumny, kandelabry...),
## a środek komnaty urządza scenka: krypta (siatka sarkofagów), sala kolumnowa, kostnica (kopiec czaszek w kręgu
## świec), kaplica (ołtarz, chodnik, rzędy ław), zawalona sala (złamana kolumnada, gruz wokół snopu światła z dziury
## w sklepieniu) i kaźnia (klatki, łańcuchy, koksownik). Komnata wejściowa dostaje koksowniki przy płomieniach Watry,
## komnata strażnika - krąg rytualny i posągi. Na podłodze nakładki (pęknięcia, gruz, kałuże) głównie przy ścianach
## i cień u stóp ścian. Grafiki z tools/dungeon_props.py (assets/dungeons/<klimat>/).
## Duże rekwizyty (kolumny, sarkofagi, posągi) stoją na wierzchołkach z wolnym otoczeniem i zajmują je
## w Dungeon.solid - potwory je omijają, a przejścia zostają drożne.

const WARM := Color(1.0, 0.62, 0.3, 0.55)
const CANDLE := Color(1.0, 0.75, 0.42, 0.4)
const COLD := Color(0.6, 0.72, 1.0, 0.45)
const RITUAL := Color(0.62, 0.32, 1.0, 0.5)
## Nakładki na podłogę z wagami.
const FLOOR_DECALS := {"crack": 3.0, "rubble": 3.0, "puddle": 1.2, "grate": 0.5, "blood": 0.6, "hole": 0.3}
## Rzędy mebli pod ścianami: rodzaj komnaty -> strona ("n" pod licem, "s", "w", "e" - boki) -> wzór powtarzany
## wzdłuż ściany ("" - wolne miejsce, ścieżka z "res://" - grafika spoza klimatu).
const LINES := {
	"crypt": {"n": ["upright_sarc", "shelf", "upright_sarc", "coffins_upright"], "w": ["shrouds", "", "coffins_upright", ""],
			"e": ["shrouds", "", "coffins_upright", ""], "s": ["", "urn", "", "runestone"]},
	"pillars": {"n": ["candelabra", "runestone", "shelf", "runestone"], "w": ["urn", "", "candelabra", ""],
			"e": ["urn", "", "candelabra", ""], "s": ["", "runestone"]},
	"ossuary": {"n": ["ossuary_shelf"], "w": ["skull_pile", "res://assets/forest/props/bone_pile.png", "urn"],
			"e": ["skull_pile", "res://assets/forest/props/bone_pile.png", "urn"], "s": ["skull_pile", "", "urn", ""]},
	"chapel": {"n": ["runestone", "candelabra"], "w": ["candelabra", "", "shelf", ""], "e": ["candelabra", "", "shelf", ""],
			"s": ["", "candelabra", ""]},
	"collapsed": {"n": ["crates", "", "cart", "", "web", ""], "w": ["web", "", "crates", ""], "e": ["web", "", "crates", ""],
			"s": ["", "web", ""]},
	"prison": {"n": ["cage", "chains", "weapon_rack", "cage", "table"], "w": ["chains", "", "cage", ""],
			"e": ["chains", "", "cage", ""], "s": ["", "crates", ""]},
	"start": {"n": ["candelabra", "", "runestone", ""], "w": ["candelabra", ""], "e": ["candelabra", ""], "s": []},
	"boss": {"n": ["ossuary_shelf", "candelabra"], "w": ["skull_pile", "candelabra", ""], "e": ["skull_pile", "candelabra", ""],
			"s": ["skull_pile", ""]},
	"event": {"n": ["shelf", "", "candelabra", ""], "w": ["", "urn"], "e": ["", "urn"], "s": []},
}
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
## Wierzchołki zajęte wystrojem (meble pod ścianą, scenki) i wierzchołki pod kinkietami (tam nic wysokiego).
var _used := {}
var _sconces := {}


func _init(dungeon: Dungeon) -> void:
	d = dungeon
	w = dungeon.w
	rng = dungeon._rng
	dir = dungeon.climate["decor"]["dir"]


func build() -> void:
	# nakładki pod wszystkim innym na warstwie podłogi (plamy światła rysują się na nich)
	_decals = Node2D.new()
	_decals.name = "DungeonDecals"
	w.floors.add_child(_decals)
	w.floors.move_child(_decals, 0)
	_walls()
	var themes: Array = d.climate["decor"]["themes"].duplicate()
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
		# najpierw scenka (duże rekwizyty na środku), potem rzędy pod ścianami w wolnych miejscach
		call("_" + theme, room)
		_line(room, LINES[theme])
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


## Chodnik od punktu `from` w dół (albo w prawo) na długość `length` px.
func _runner(from: Vector2, length: float, horizontal: bool) -> void:
	var runner := Sprite2D.new()
	runner.texture = _tex("runner")
	runner.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	runner.region_enabled = true
	runner.region_rect = Rect2(0, 0, 28, length)
	runner.centered = false
	runner.offset = Vector2(-14, 0)
	runner.position = from.round()
	if horizontal:
		runner.rotation = -PI / 2.0
	_decals.add_child(runner)


func _candles(pos: Vector2) -> void:
	_prop("candles", pos)
	_light(pos + Vector2(0, -10), CANDLE, Vector2(90, 66))


func _add_shade(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _shade
	sprite.position = pos
	_decals.add_child(sprite)


# ---------------------------------------------------------------- ściany i podłoga
## Lico ściany (wierzchołki "t" pod skałą): kinkiety co 3 wierzchołki, między nimi nisze z czaszkami,
## chorągwie (parami po bokach kinkietu) i wykruszone cegły.
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


func _dress_wall(run: Array[Vector2i]) -> void:
	# kinkiety symetrycznie: co 3 wierzchołki, wyśrodkowane na odcinku ściany
	var start := (run.size() - 1) % 3 / 2 + (1 if run.size() >= 5 else 0)
	var banners := rng.randf() < 0.5
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and (i - start) % 3 == 0 and i >= start:
			var sconce := _decal("sconce", at + Vector2(0, -14), false)
			sconce.z_index = 1
			_light(at + Vector2(0, -30), WARM, Vector2(130, 110))
			_light(at + Vector2(0, 30), Color(WARM, 0.3), Vector2(190, 110))
			_sconces[v + Vector2i.DOWN] = true
		elif banners and run.size() >= 4:
			_decal("banner", at + Vector2(0, -8), false)
		elif rng.randf() < 0.35:
			_decal(_pick(["niche", "niche", "wall_crack"]), at + Vector2(0, -8))


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
			if d.solid.has(v) or _used.has(v):
				continue
			if rng.randf() < (0.13 if walls > 0 else 0.025):
				_decal(d._pick(FLOOR_DECALS), _px(v) + _jitter(18) + Vector2(0, 12))


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
			# pod kinkietem nic wysokiego - zostaje światło na ścianie
			if side == "n" and _sconces.has(v) and name not in ["skull_pile", "urn", "font"]:
				continue
			_used[v] = true
			_prop(name, _px(v) + SIDE_OFFSET[side], side == "s")
			if name == "candelabra":
				_light(_px(v) + SIDE_OFFSET[side] + Vector2(0, -40), CANDLE, Vector2(110, 90))


# ---------------------------------------------------------------- scenki
## Krypta: siatka sarkofagów co drugi wierzchołek, płyty nagrobne w przejściach między rzędami.
func _crypt(room: Rect2i) -> void:
	var kind := _pick(["sarcophagus_1", "sarcophagus_0"])
	for x in range(room.position.x + 1, room.end.x - 1):
		for y in range(room.position.y + 2, room.end.y - 1):
			var v := Vector2i(x, y)
			var col := (x - room.position.x) % 2 == 1
			var row := (y - room.position.y) % 2 == 0
			if col and row and _isolated(v):
				_solid(kind if rng.randf() < 0.8 else "coffin", v, Vector2(48, 18), false)
			elif col and not row and _floor_at(v) and not _used.has(v):
				_decal("slab", _px(v) + Vector2(0, 8), false)
				_used[v] = true


## Sala kolumnowa: dwa rzędy kolumn wzdłuż komnaty, koksowniki na końcach osi, chrzcielnica na środku.
func _pillars(room: Rect2i) -> void:
	var top := room.position.y + 2
	var bottom := room.end.y - 2
	var kind := _pick(["pillar_0", "pillar_1", "pillar_2"])
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in ([top, bottom] if bottom - top >= 2 else [top]):
			var v := Vector2i(x, y)
			if _isolated(v):
				_solid(kind, v, Vector2(26, 14), false)
	var mid := _center(room)
	var braziers := 0
	for x in [room.position.x + 1, room.end.x - 2]:
		var v := Vector2i(x, mid.y)
		if _isolated(v):
			_solid("brazier", v, Vector2(26, 14), false)
			_light(_px(v) + Vector2(0, -36), WARM, Vector2(200, 160))
			braziers += 1
	# chodnik wzdłuż osi między koksownikami
	if braziers == 2:
		_runner(_px(Vector2i(room.position.x + 1, mid.y)) + Vector2(26, 16), (room.size.x - 3) * Dungeon.CELL - 52, true)
	if _isolated(mid):
		_solid("font", mid, Vector2(26, 14), false)


## Kostnica: kopiec czaszek na środku w kręgu kości i świec, otwarte trumny w narożnikach.
func _ossuary(room: Rect2i) -> void:
	var mid := _center(room)
	var at := _px(mid) + Vector2(0, 20)
	_used[mid] = true
	_prop("skull_pile", at, false)
	for i in 8:
		var angle := TAU * i / 8.0
		var spot := at + Vector2(cos(angle) * 54, sin(angle) * 36)
		if i % 2 == 0:
			_candles(spot)
		else:
			_prop("res://assets/cemetery/skulls.png", spot)
	for corner: Vector2i in [Vector2i(1, 2), Vector2i(-2, 2), Vector2i(1, -2), Vector2i(-2, -2)]:
		var v := Vector2i(room.position.x if corner.x > 0 else room.end.x, room.position.y if corner.y > 0 else room.end.y) + corner
		if _isolated(v):
			_solid("coffin", v, Vector2(48, 18))


## Kaplica: ołtarz-grobowiec pod północną ścianą, chodnik do wejścia, rzędy ław po bokach, posągi i świeczniki.
func _chapel(room: Rect2i) -> void:
	var cx := _center(room).x
	var altar := Vector2i(cx, room.position.y + 1)
	if not _floor_at(altar):
		_crypt(room)
		return
	_solid("sarcophagus_0", altar, Vector2(48, 18), false)
	_light(_px(altar) + Vector2(0, -16), CANDLE, Vector2(160, 110))
	_runner(_px(altar) + Vector2(0, 22), (room.end.y - 1 - altar.y) * Dungeon.CELL - 20, false)
	for y in range(altar.y, room.end.y):
		_used[Vector2i(cx, y)] = true
	for side in [-1, 1]:
		var statue := altar + Vector2i(side * 2, 0)
		if _isolated(statue):
			_solid(_pick(["statue_0", "statue_2"]), statue, Vector2(24, 14), false).flip_h = side > 0
		var stand := _px(altar) + Vector2(side * 44, 18)
		_prop("res://assets/village/candle_stand.png", stand, false)
		_light(stand + Vector2(0, -26), CANDLE, Vector2(80, 64))
		_candles(_px(altar) + Vector2(side * 84, 30))
		# ławy: rzędy co wierzchołek, po dwie z każdej strony chodnika
		for y in range(altar.y + 2, room.end.y - 1):
			for x in [cx + side, cx + side * 2]:
				var v := Vector2i(x, y)
				if _floor_at(v) and not _used.has(v) and d._label(v + Vector2i.RIGHT * side) == "l":
					_prop("bench", _px(v) + Vector2(-side * 8, 8), false)
					_used[v] = true


## Zawalona sala: złamana kolumnada (część kolumn leży w gruzie), gruz w kręgu wokół snopu zimnego światła
## z dziury w sklepieniu i wirujący kurz.
func _collapsed(room: Rect2i) -> void:
	var mid := _center(room)
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [room.position.y + 2, room.end.y - 2]:
			var v := Vector2i(x, y)
			if not _isolated(v) or absi(v.x - mid.x) <= 1 and absi(v.y - mid.y) <= 1:
				continue
			var roll := rng.randf()
			if roll < 0.35:
				_solid(_pick(["pillar_0", "pillar_2"]), v, Vector2(26, 14), false)
			elif roll < 0.8:
				_solid(_pick(["broken_0", "broken_1", "broken_2"]), v, Vector2(30, 14))
			else:
				_decal("rubble", _px(v) + Vector2(0, 10))
				_used[v] = true
	var shaft := _px(mid) + Vector2(0, 40)
	_used[mid] = true
	_light(shaft, COLD, Vector2(240, 160), false)
	_light(shaft + Vector2(0, -90), Color(COLD, 0.18), Vector2(110, 260), false)
	_decal("hole", shaft + Vector2(0, 4), false)
	for i in 9:
		var angle := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var spot := shaft + Vector2(cos(angle), sin(angle) * 0.7) * rng.randf_range(50, 80)
		if i % 3 == 0:
			_prop("res://assets/cemetery/fallen_stone.png", spot)
		else:
			_decal("rubble", spot)
	_dust(shaft + Vector2(0, -60))


## Kaźnia: rząd słupów z łańcuchami na osi komnaty, koksownik z węglami i stół na środku.
func _prison(room: Rect2i) -> void:
	var mid := _center(room)
	if _isolated(mid):
		_solid("brazier_iron", mid, Vector2(26, 14), false)
		_light(_px(mid) + Vector2(0, -20), WARM, Vector2(220, 170))
	var table := mid + Vector2i(0, 2)
	if _isolated(table):
		_solid("table", table, Vector2(40, 14), false)
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		var v := Vector2i(x, mid.y)
		if absi(x - mid.x) >= 2 and _isolated(v):
			_solid(_pick(["chains", "cage"]), v, Vector2(26, 14), false)


## Komnata Kryształu Watry: kolumnada wzdłuż ścian, środek (kryształ i walka wokół niego) wolny.
func _event(room: Rect2i) -> void:
	var mid := _center(room)
	var kind := _pick(["pillar_0", "pillar_2"])
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [room.position.y + 2, room.end.y - 2]:
			var v := Vector2i(x, y)
			if absi(v.x - mid.x) > 1 or absi(v.y - mid.y) > 1:
				if _isolated(v):
					_solid(kind, v, Vector2(26, 14), false)


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


## Komnata wejściowa: koksowniki po bokach płomieni Watry, pod nimi środek wolny (miejsce pojawienia się).
func _start(room: Rect2i) -> void:
	var cx := _center(room).x
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, room.position.y + 1)] = true
	_runner(_px(Vector2i(cx, room.position.y + 1)) + Vector2(0, 46), (room.end.y - room.position.y - 2) * Dungeon.CELL - 40, false)
	for side in [-2, 2]:
		var v := Vector2i(cx + side, room.position.y + 2)
		if _isolated(v):
			_solid("brazier", v, Vector2(26, 14), false)
			_light(_px(v) + Vector2(0, -36), WARM, Vector2(200, 160))


## Komnata strażnika: krąg rytualny pod strażnikiem, fioletowa poświata, posągi w narożnikach.
func _boss(room: Rect2i) -> void:
	var center := Vector2(room.get_center()) * Dungeon.CELL + Vector2(0, Dungeon.CELL / 2.0)
	_decal("res://assets/cemetery/ritual.png", center + Vector2(0, 8), false).scale = Vector2(1.5, 1.5)
	_light(center, RITUAL, Vector2(300, 220))
	# skarbiec pod północną ścianą (Dungeon._build_vault)
	var cx := _center(room).x
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, room.position.y + 1)] = true
	for corner: Vector2i in [Vector2i(1, 2), Vector2i(-2, 2), Vector2i(1, -2), Vector2i(-2, -2)]:
		var v := Vector2i(room.position.x if corner.x > 0 else room.end.x, room.position.y if corner.y > 0 else room.end.y) + corner
		if _isolated(v):
			_solid(_pick(["statue_0", "statue_2"]), v, Vector2(24, 14), false)
			_light(_px(v) + Vector2(0, -20), Color(RITUAL, 0.3), Vector2(110, 90))
