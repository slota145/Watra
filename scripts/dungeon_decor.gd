class_name DungeonDecor
extends RefCounted
## Wystrój lochu klimatu z kluczem "decor" (Dungeons.CLIMATES, na razie Katakumby): kinkiety, nisze i chorągwie na
## licu ścian, nakładki na podłodze (pęknięcia, kałuże, gruz, płyty nagrobne, kratki) i komnaty urządzone scenkami:
## krypta (rzędy sarkofagów), sala kolumnowa, kostnica, kaplica (ołtarz, chodnik, ławy), zawalona sala (snop światła
## z dziury w sklepieniu, kurz). Komnata wejściowa dostaje koksowniki przy płomieniach Watry, komnata strażnika -
## krąg rytualny i posągi. Grafiki z tools/dungeon_props.py (assets/dungeons/<klimat>/).
## Duże rekwizyty (kolumny, sarkofagi, posągi) stoją na wierzchołkach z wolnym otoczeniem i zajmują je
## w Dungeon.solid - potwory je omijają, a przejścia zostają drożne.

const WARM := Color(1.0, 0.62, 0.3, 0.55)
const CANDLE := Color(1.0, 0.75, 0.42, 0.4)
const COLD := Color(0.6, 0.72, 1.0, 0.45)
const RITUAL := Color(0.62, 0.32, 1.0, 0.5)
## Nakładki na podłogę z wagami.
const FLOOR_DECALS := {"crack": 3.0, "rubble": 3.0, "puddle": 1.2, "slab": 0.5, "grate": 0.5, "blood": 0.8, "hole": 0.3}
const BONES: Array[String] = ["res://assets/forest/props/bones.png", "res://assets/wild/bones.png",
		"res://assets/forest/props/skull_bones.png", "res://assets/cemetery/skulls.png", "res://assets/forest/props/ribcage.png"]

var d: Dungeon
var w
var rng: RandomNumberGenerator
var dir := ""
var _decals: Node2D
var _cache := {}
## Cień u stóp ścian (półprzezroczysta czerń) - wspólna tekstura.
var _shade: GradientTexture2D


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
	var themes: Array = d.climate["decor"]["themes"].duplicate()
	var queue: Array = []
	for room in d.rooms:
		if room == d.start_room:
			_start_room(room)
		elif room == d.boss_room:
			_boss_room(room)
		elif d.event != "" and room == d.event_room:
			pass
		else:
			if queue.is_empty():
				queue = themes.duplicate()
				_shuffle(queue)
			call("_" + str(queue.pop_back()), room)
	_walls()
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
func _prop(name: String, pos: Vector2) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(_tex(name), pos, Vector2.ZERO)
	sprite.flip_h = rng.randf() < 0.5
	sprite.modulate = Color(0.92, 0.92, 0.92)
	return sprite


## Duży rekwizyt na wierzchołku `v`: kolizja u podstawy, wierzchołek zajęty (Dungeon.solid).
func _solid(name: String, v: Vector2i, collision := Vector2(34, 16), flip := true) -> Sprite2D:
	d.solid[v] = true
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
	if not _floor_at(v):
		return false
	for step in Dungeon.STEPS:
		if not _floor_at(v + step):
			return false
	return true


func _px(v: Vector2i) -> Vector2:
	return Vector2(v) * Dungeon.CELL


func _jitter(amount: float) -> Vector2:
	return Vector2(rng.randf_range(-amount, amount), rng.randf_range(-amount, amount))


## Wierzchołki podłogi komnaty przy ścianie (któryś sąsiad to skała albo lico), bez rzędu lica.
func _edge_cells(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(room.position.x - 2, room.end.x + 2):
		for y in range(room.position.y - 2, room.end.y + 2):
			var v := Vector2i(x, y)
			if not _floor_at(v):
				continue
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]:
				if d._label(v + step) != "l":
					result.append(v)
					break
	return result


func _add_shade(pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _shade
	sprite.position = pos
	_decals.add_child(sprite)


func _candles(pos: Vector2) -> void:
	_prop("candles", pos)
	_light(pos + Vector2(0, -10), CANDLE, Vector2(90, 66))


# ---------------------------------------------------------------- ściany i podłoga
## Lico ściany (wierzchołki "t" pod skałą): kinkiety co kilka wierzchołków, między nimi nisze z czaszkami,
## chorągwie i wykruszone cegły.
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
	var spacing := rng.randi_range(3, 4)
	var start := rng.randi() % spacing
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and i % spacing == start:
			var sconce := _decal("sconce", at + Vector2(0, -14), false)
			sconce.z_index = 1
			_light(at + Vector2(0, -30), WARM, Vector2(130, 110))
			_light(at + Vector2(0, 30), Color(WARM, 0.3), Vector2(190, 110))
		elif rng.randf() < 0.4:
			var overlay := _pick(["niche", "niche", "banner", "wall_crack"])
			var piece := _decal(overlay, at + Vector2(rng.randf_range(-6, 6), -8 if overlay != "wall_crack" else 2))
			if overlay == "niche" and rng.randf() < 0.5:
				_light(at + Vector2(0, -8), CANDLE, Vector2(70, 56))
			piece.modulate = Color(0.95, 0.95, 0.95)


## Nakładki na całej podłodze (gęściej przy ścianach), cień u stóp ścian i porozrzucane kości.
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
			if d.solid.has(v):
				continue
			if rng.randf() < 0.1 + walls * 0.07:
				_decal(d._pick(FLOOR_DECALS), _px(v) + _jitter(22) + Vector2(0, 12))
			if rng.randf() < 0.05:
				d._scatter_prop(_tex(_pick(BONES)), _px(v) + _jitter(24) + Vector2(0, 16))


# ---------------------------------------------------------------- komnaty
func _interior(room: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(room.position.x + 1, room.end.x - 1):
		for y in range(room.position.y + 1, room.end.y - 1):
			result.append(Vector2i(x, y))
	return result


## Krypta: rzędy sarkofagów i trumien co drugi wierzchołek, świece przy niektórych.
func _crypt(room: Rect2i) -> void:
	for v in _interior(room):
		if (v.x - room.position.x) % 2 != 1 or (v.y - room.position.y) % 2 != 0 or not _isolated(v):
			continue
		if rng.randf() < 0.15:
			continue
		var name := _pick(["sarcophagus_0", "sarcophagus_1", "sarcophagus_1", "coffin"])
		_solid(name, v, Vector2(48, 18), name != "sarcophagus_0")
		if rng.randf() < 0.3:
			_candles(_px(v) + Vector2(rng.randf_range(-30, 30), 34))


## Sala kolumnowa: dwa rzędy kolumn wzdłuż komnaty, koksowniki na osi.
func _pillars(room: Rect2i) -> void:
	var top := room.position.y + 2
	var bottom := room.end.y - 2
	var kind := _pick(["pillar_0", "pillar_1", "pillar_2"])
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in ([top, bottom] if bottom - top >= 2 else [top]):
			var v := Vector2i(x, y)
			if _isolated(v):
				_solid(kind if rng.randf() < 0.85 else _pick(["broken_0", "broken_1"]), v, Vector2(26, 14), false)
	var mid := room.position.y + room.size.y / 2
	for x in [room.position.x + 1, room.end.x - 2]:
		var v := Vector2i(x, mid)
		if _isolated(v):
			_solid("brazier", v, Vector2(26, 14), false)
			_light(_px(v) + Vector2(0, -36), WARM, Vector2(200, 160))


## Kostnica: stosy czaszek i kości, urny pod ścianami, świece, otwarte trumny.
func _ossuary(room: Rect2i) -> void:
	for v in _edge_cells(room):
		if rng.randf() < 0.45:
			var name := _pick(["skull_pile", "skull_pile", "urn", "res://assets/forest/props/bone_pile.png",
					"res://assets/cemetery/skulls.png", "res://assets/forest/props/skull_bones.png"])
			_prop(name, _px(v) + _jitter(12) + Vector2(0, 14))
		elif rng.randf() < 0.15:
			_candles(_px(v) + _jitter(10) + Vector2(0, 14))
	for v in _interior(room):
		if rng.randf() < 0.12 and _isolated(v):
			_solid(_pick(["coffin", "sarcophagus_1"]), v, Vector2(48, 18))
		elif rng.randf() < 0.12:
			_decal("coffin_lid" if rng.randf() < 0.3 else "rubble", _px(v) + _jitter(16))


## Kaplica: ołtarz pod północną ścianą, chodnik do wejścia, ławy po bokach, posągi i świeczniki.
func _chapel(room: Rect2i) -> void:
	var cx := room.position.x + room.size.x / 2
	var altar := Vector2i(cx, room.position.y + 1)
	if not _floor_at(altar):
		_crypt(room)
		return
	_solid("sarcophagus_0", altar, Vector2(48, 18), false)
	_light(_px(altar) + Vector2(0, -16), CANDLE, Vector2(160, 110))
	var runner := Sprite2D.new()
	runner.texture = _tex("runner")
	runner.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	runner.region_enabled = true
	var length := (room.end.y - 1 - altar.y) * Dungeon.CELL - 20
	runner.region_rect = Rect2(0, 0, 28, length)
	runner.centered = false
	runner.position = _px(altar) + Vector2(-14, 22)
	_decals.add_child(runner)
	for side in [-1, 1]:
		var statue := altar + Vector2i(side * 2, 0)
		if _isolated(statue):
			_solid(_pick(["statue_0", "statue_1", "statue_2"]), statue, Vector2(24, 14), false).flip_h = side > 0
		var stand := _px(altar) + Vector2(side * 44, 18)
		_prop("res://assets/village/candle_stand.png", stand)
		_light(stand + Vector2(0, -26), CANDLE, Vector2(80, 64))
		_candles(_px(altar) + Vector2(side * 84, 30))
		for y in range(altar.y + 2, room.end.y - 1, 1):
			for x in [52, 96]:
				var pos := Vector2(cx * Dungeon.CELL + side * x, y * Dungeon.CELL + 6)
				if not d._blocked(pos, 6.0):
					_prop("res://assets/village/deco_stone_bench.png", pos).flip_h = false


## Zawalona sala: złamane kolumny, gruz i dziury, snop zimnego światła z dziury w sklepieniu i wirujący kurz.
func _collapsed(room: Rect2i) -> void:
	var cells := _interior(room)
	_shuffle(cells)
	var broken := 0
	for v in cells:
		if broken < 4 and _isolated(v):
			_solid(_pick(["broken_0", "broken_1", "broken_2"]), v, Vector2(30, 14))
			broken += 1
		elif rng.randf() < 0.35:
			_decal(_pick(["rubble", "rubble", "hole", "crack", "coffin_lid"]), _px(v) + _jitter(20))
		elif rng.randf() < 0.1:
			d._scatter_prop(_tex("res://assets/cemetery/fallen_stone.png"), _px(v) + _jitter(16))
	var shaft := Vector2(room.get_center()) * Dungeon.CELL + _jitter(40) + Vector2(0, 40)
	_light(shaft, COLD, Vector2(220, 150), false)
	_light(shaft + Vector2(0, -90), Color(COLD, 0.18), Vector2(110, 260), false)
	_decal("rubble", shaft + Vector2(8, 6))
	_dust(shaft + Vector2(0, -60))


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


## Komnata wejściowa: koksowniki po bokach płomieni Watry, świece pod ścianami, porządek (bez gruzu).
func _start_room(room: Rect2i) -> void:
	var cx := room.position.x + room.size.x / 2
	for side in [-2, 2]:
		var v := Vector2i(cx + side, room.position.y + 2)
		if _isolated(v):
			_solid("brazier", v, Vector2(26, 14), false)
			_light(_px(v) + Vector2(0, -36), WARM, Vector2(200, 160))
	for v in _edge_cells(room):
		if v.y > room.position.y + 1 and rng.randf() < 0.12:
			_candles(_px(v) + _jitter(8) + Vector2(0, 14))


## Komnata strażnika: krąg rytualny pod strażnikiem, fioletowa poświata, posągi w narożnikach, czaszki pod ścianami.
func _boss_room(room: Rect2i) -> void:
	var center := Vector2(room.get_center()) * Dungeon.CELL + Vector2(0, Dungeon.CELL / 2.0)
	_decal("res://assets/cemetery/ritual.png", center + Vector2(0, 8), false).scale = Vector2(1.5, 1.5)
	_light(center, RITUAL, Vector2(300, 220))
	for corner: Vector2i in [Vector2i(1, 2), Vector2i(-2, 2), Vector2i(1, -2), Vector2i(-2, -2)]:
		var v := Vector2i(room.position.x if corner.x > 0 else room.end.x, room.position.y if corner.y > 0 else room.end.y) + corner
		if _isolated(v):
			_solid(_pick(["statue_0", "statue_2"]), v, Vector2(24, 14), false)
			_light(_px(v) + Vector2(0, -20), Color(RITUAL, 0.3), Vector2(110, 90))
	for v in _edge_cells(room):
		if v.y > room.position.y and rng.randf() < 0.3:
			_prop(_pick(["skull_pile", "res://assets/cemetery/skulls.png", "res://assets/cemetery/candle.png"]), _px(v) + _jitter(10) + Vector2(0, 14))
