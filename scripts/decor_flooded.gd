class_name FloodedDecor
extends DungeonDecor
## Wystrój Zatopionych podziemi - podziemnej świątyni dawnych bogów wody, zalanej, gdy podniosła się woda.
## Wodnik zajął ją na swoje królestwo, w zakamarkach gnieżdżą się topielce, żabołaki i rusałki.
## Na licu ścian kinkiety z zielonym płomieniem w równych odstępach, między nimi płaskorzeźby fal, zwisający mech
## i sieci. Na podłodze płytkie rozlewiska, kałuże, glony i muł - wszędzie da się przejść.
## Rodzaje sal: świątynia (posąg boga wody z ołtarzem, nawa z dwóch rzędów kolumn), kładki (mokre deski przez
## rozlewisko, kikuty kolumn w wodzie), wraki (siatka wraków i łodzi), gniazdo topielców (krąg gniazd wokół
## utopionych skarbów), grota z ognikami (siatka świecących grzybów, unoszące się ogniki), obóz żabołaków (totem
## w kręgu suszarni ryb), sala rusałek (lustro wody w kręgu wianków, brzozowe gałązki ze wstążkami) i źródło
## (woda spada ze stropu do skalnego zbiornika w snopie światła). Komnata wejściowa: kładka do płomieni Watry,
## komnata strażnika: tron wodnika z wyrzuconego drewna za skarbcem, aleja posągów.

const FLAME := Color(0.45, 1.0, 0.62, 0.5)
const WISP := Color(0.42, 0.95, 1.0, 0.55)
const WATER := Color(0.45, 0.85, 0.95, 0.4)
const FLOOR_DECALS := {"crack": 1.5, "puddle": 2.5, "lilies": 0.6, "algae": 2.0, "mud": 1.2, "fish_bones": 0.4,
		"mosaic": 1.0, "grate": 0.2}
const LINES := {
	"temple": {"n": ["shrine", "amphorae", "", "bench"], "w": ["bench", "", "amphorae", ""], "e": ["bench", "", "amphorae", ""],
			"s": ["", "candles", "", "amphorae"]},
	"boardwalk": {"n": ["reeds", "", "oars", ""], "w": ["reeds", "stakes", ""], "e": ["reeds", "stakes", ""],
			"s": ["stakes", "", "reeds"]},
	"wrecks": {"n": ["oars", "anchor", "", "barrels", "crates", ""], "w": ["oars", "", "driftwood"], "e": ["oars", "", "driftwood"],
			"s": ["", "driftwood", "", "barrels"]},
	"nest": {"n": ["driftwood", "", "roots"], "w": ["roots", "", "driftwood"], "e": ["roots", "", "driftwood"],
			"s": ["", "driftwood", "", "shells"]},
	"wisps": {"n": ["wisp_post", "roots", "", "roots"], "w": ["roots", "", "wisp_post", ""], "e": ["roots", "", "wisp_post", ""],
			"s": ["", "roots"]},
	"frogs": {"n": ["fish_baskets", "amphorae", "", "shelf"], "w": ["fish_baskets", "", "stakes"], "e": ["fish_baskets", "", "stakes"],
			"s": ["", "fish_baskets", "", "reeds"]},
	"rusalka": {"n": ["birch", "", "reeds", "birch"], "w": ["birch", "", "reeds"], "e": ["birch", "", "reeds"],
			"s": ["", "birch", "", "reeds"]},
	"spring": {"n": ["reeds", "", "roots", ""], "w": ["reeds", "", "bench"], "e": ["reeds", "", "bench"], "s": ["", "reeds"]},
	"start": {"n": ["wisp_post", "", "shelf", ""], "w": ["barrels", ""], "e": ["barrels", ""], "s": []},
	"boss": {"n": ["shrine", "amphorae"], "w": ["wisp_post", "roots", ""], "e": ["wisp_post", "roots", ""], "s": ["reeds", ""]},
	"event": {"n": ["amphorae", "", "shelf", ""], "w": ["", "barrels"], "e": ["", "barrels"], "s": []},
}


func lines() -> Dictionary:
	return LINES


func floor_decals() -> Dictionary:
	return FLOOR_DECALS


func low_props() -> Array:
	return ["candles", "shells", "jug", "wreath", "fish_baskets", "amphorae", "bench", "driftwood", "anchor", "barrels"]


func line_lights() -> Dictionary:
	return {"wisp_post": [Color(WISP, 0.35), Vector2(120, 100), Vector2(0, -40)], "shrine": [CANDLE, Vector2(120, 90), Vector2(0, -20)]}


func event_pillars() -> Array:
	return ["pillar"]


## Kinkiety co 3 wierzchołki, między nimi płaskorzeźby fal, zwisający mech albo sieci.
func _dress_wall(run: Array[Vector2i]) -> void:
	var start := _light_start(run)
	var reliefs := rng.randf() < 0.4
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and (i - start) % 3 == 0 and i >= start:
			_wall_light("sconce", v, FLAME)
		elif reliefs and run.size() >= 4 and (i - start) % 3 != 0:
			_decal("wave_plaque", at + Vector2(0, -12), false)
		elif rng.randf() < 0.45:
			_decal(_pick(["moss_drape", "moss_drape", "net"]), at + Vector2(0, -10))


## Płytkie rozlewisko na podłodze (nakładka, da się przejść), z liliami i odblaskiem.
func _pool(at: Vector2, small := false) -> void:
	_decal("pool_small" if small else "pool", at)
	_light(at, Color(WATER, 0.18), Vector2(200, 120) if not small else Vector2(130, 80), false)
	if rng.randf() < 0.6:
		_decal("lilies", at + _jitter(24 if not small else 12))


## Krople spadające ze stropu (źródło).
func _drips(at: Vector2) -> void:
	var drops := CPUParticles2D.new()
	drops.position = at
	drops.amount = 14
	drops.lifetime = 0.9
	drops.preprocess = 1.0
	drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drops.emission_rect_extents = Vector2(10, 2)
	drops.direction = Vector2(0, 1)
	drops.spread = 4.0
	drops.gravity = Vector2(0, 260)
	drops.initial_velocity_min = 40.0
	drops.initial_velocity_max = 70.0
	drops.scale_amount_min = 1.0
	drops.scale_amount_max = 2.0
	drops.color = Color(0.7, 0.95, 1.0, 0.75)
	drops.z_index = 20
	w.add_child(drops)


# ---------------------------------------------------------------- scenki
## Świątynia: posąg boga wody pod północną ścianą, przed nim ołtarz ze świecami i muszlami, od ołtarza w głąb
## sali nawa z dwóch rzędów kolumn (część przewrócona), między nimi rozlewisko.
func _temple(room: Rect2i) -> void:
	var mid := _center(room)
	var top := Vector2i(mid.x, room.position.y + 2)
	if _isolated(top):
		_solid("statue", top, Vector2(30, 14), false)
		_light(_px(top) + Vector2(0, -30), Color(WISP, 0.4), Vector2(200, 160))
	var altar := top + Vector2i(0, 2)
	if _isolated(altar):
		_solid("altar", altar, Vector2(40, 16), false)
		_light(_px(altar) + Vector2(0, -6), CANDLE, Vector2(160, 110))
		_prop("candles", _px(altar) + Vector2(-44, 26))
		_prop("shells", _px(altar) + Vector2(42, 28))
	var fallen := false
	for y in range(room.position.y + 2, room.end.y - 1, 2):
		for side in [-2, 2]:
			var v := Vector2i(mid.x + side, y)
			if not _isolated(v):
				continue
			if not fallen and rng.randf() < 0.2:
				_solid("pillar_fallen", v, Vector2(44, 16))
				fallen = true
			else:
				_solid("pillar" if rng.randf() < 0.8 else "pillar_stump", v, Vector2(26, 14), false)
	if room.end.y - 2 - altar.y >= 2:
		_pool(_px(Vector2i(mid.x, altar.y + 2)) + Vector2(0, 30))


## Kładki: rozlewisko przez całą salę, przez nie od ściany do ściany kładka z mokrych desek, w wodzie kikuty
## kolumn i lilie.
func _boardwalk(room: Rect2i) -> void:
	var mid := _center(room)
	# rozlewisko wzdłuż kładki i pojedyncze plamy wody obok
	for x in range(room.position.x, room.end.x, 2):
		_pool(_px(Vector2i(x, mid.y)) + Vector2(32, 16) + _jitter(8))
		for y in [mid.y - 2, mid.y + 2]:
			if rng.randf() < 0.4 and _floor_at(Vector2i(x, y)):
				_pool(_px(Vector2i(x, y)) + Vector2(0, 20), true)
	var x0 := room.position.x
	var x1 := room.end.x - 1
	while x0 > room.position.x - 3 and _floor_at(Vector2i(x0 - 1, mid.y)):
		x0 -= 1
	while x1 < room.end.x + 2 and _floor_at(Vector2i(x1 + 1, mid.y)):
		x1 += 1
	var walk := _runner(_px(Vector2i(x0, mid.y)) + Vector2(-28, 14), (x1 - x0) * Dungeon.CELL + 56, true, "planks")
	walk.z_index = 1
	for x in range(x0, x1 + 1):
		_used[Vector2i(x, mid.y)] = true
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [mid.y - 2, mid.y + 2]:
			var v := Vector2i(x, y)
			if _isolated(v) and rng.randf() < 0.6:
				_solid("pillar_stump", v, Vector2(26, 14))


## Wraki: siatka wraków, przewróconych łodzi i połamanych masztów, każdy w kałuży; w przejściach sieci,
## ości i drewno.
func _wrecks(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			_decal("pool_small", _px(v) + Vector2(0, 16))
			_solid(["wreck", "rowboat", "mast"][i % 3] if rng.randf() < 0.85 else "anchor", v, Vector2(40, 16)),
		func(v: Vector2i) -> void:
			var roll := rng.randf()
			if roll < 0.25:
				_decal(_pick(["fish_bones", "mud", "puddle"]), _px(v) + _jitter(12) + Vector2(0, 10))
			elif roll < 0.35:
				_used[v] = true
				_prop(_pick(["jug", "shells"]), _px(v) + _jitter(10) + Vector2(0, 20)))
	var mid := _center(room)
	_light(_px(mid) + Vector2(0, 10), Color(FLAME, 0.25), Vector2(280, 200))


## Gniazdo topielców: utopione skarby na środku, wokół krąg gniazd z mułu, trzciny i kości, na podłodze muł.
func _nest(room: Rect2i) -> void:
	var mid := _center(room)
	var at := _px(mid) + Vector2(0, 20)
	if _isolated(mid):
		_solid("treasure", mid, Vector2(34, 14), false)
	else:
		_used[mid] = true
		_prop("treasure", at, false)
	_light(at + Vector2(0, -10), Color(1.0, 0.85, 0.45, 0.35), Vector2(160, 110))
	for step: Vector2i in [Vector2i(-2, -1), Vector2i(2, -1), Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, -2), Vector2i(0, 2)]:
		var v := mid + step
		if _isolated(v):
			_solid("nest", v, Vector2(40, 16))
	for i in 10:
		var angle := TAU * i / 10.0
		var spot := at + Vector2(cos(angle) * 170, sin(angle) * 110)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) == "l":
			_decal(_pick(["mud", "mud", "fish_bones"]), spot)
	_prop("res://assets/forest/props/bones.png", at + Vector2(-60, 40))


## Grota z ognikami: siatka świecących grzybów (każdy z własnym światłem i ognikami), w przejściach glony
## i lilie, nad salą unoszą się ogniki.
func _wisps(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			if i % 3 == 2:
				_pool(_px(v) + Vector2(0, 20), true)
				_used[v] = true
				return
			_solid("mushrooms", v, Vector2(30, 14))
			_light(_px(v) + Vector2(0, -16), WISP, Vector2(170, 130))
			_motes(_px(v) + Vector2(0, -30), Vector2(20, 14), 3),
		func(v: Vector2i) -> void:
			if rng.randf() < 0.3:
				_decal(_pick(["algae", "lilies", "puddle"]), _px(v) + _jitter(12) + Vector2(0, 10)))
	var mid := _center(room)
	_motes(_px(mid), Vector2(room.size.x * 24.0, room.size.y * 20.0), 18)


## Obóz żabołaków: totem z żabimi czaszkami na środku, wokół suszarnie ryb, kosze i dzbany, kałuże.
func _frogs(room: Rect2i) -> void:
	var mid := _center(room)
	if _isolated(mid):
		_solid("totem", mid, Vector2(24, 12), false)
	else:
		_used[mid] = true
		_prop("totem", _px(mid) + Vector2(0, 20), false)
	_light(_px(mid) + Vector2(0, -20), Color(FLAME, 0.4), Vector2(220, 170))
	for step: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(-2, 2), Vector2i(2, 2)]:
		var v := mid + step
		if _isolated(v):
			_solid("drying_rack", v, Vector2(40, 14))
	var at := _px(mid) + Vector2(0, 20)
	for i in 6:
		var angle := TAU * i / 6.0 + PI / 6.0
		var spot := at + Vector2(cos(angle) * 110, sin(angle) * 74)
		if i % 2 == 0:
			_decal("puddle", spot)
		else:
			_prop(_pick(["jug", "res://assets/frogs/clay_pots.png"]), spot)
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["drying_rack", "res://assets/frogs/fish_net.png"]), v, Vector2(34, 14))


## Sala rusałek: lustro wody na środku w kręgu wianków i lilii, z góry pada blade światło, wokół krąg
## kolumn i brzozowe gałązki ze wstążkami pod ścianami.
func _rusalka(room: Rect2i) -> void:
	var mid := _center(room)
	var at := _px(mid) + Vector2(0, 20)
	_pool(at + Vector2(0, 10))
	if _isolated(mid):
		_solid("mirror_pool", mid, Vector2(44, 18), false)
	else:
		_used[mid] = true
	_light(at, Color(COLD, 0.35), Vector2(220, 150), false)
	_light(at + Vector2(0, -90), Color(COLD, 0.16), Vector2(110, 240), false)
	_motes(at + Vector2(0, -20), Vector2(50, 30), 6)
	for i in 8:
		var angle := TAU * i / 8.0
		var spot := at + Vector2(cos(angle) * 120, sin(angle) * 80)
		if i % 2 == 0:
			_prop("wreath", spot)
		else:
			_decal("lilies", spot)
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["pillar", "pillar_stump"]), v, Vector2(26, 14), false)


## Źródło: woda spada ze stropu do skalnego zbiornika w snopie zimnego światła, wokół rozlewiska, trzciny
## i omszałe kamienie.
func _spring(room: Rect2i) -> void:
	var mid := _center(room)
	var at := _px(mid) + Vector2(0, 20)
	for offset in [Vector2(-70, 40), Vector2(70, 50), Vector2(0, 80)]:
		_pool(at + offset, true)
	if _isolated(mid):
		_solid("spring", mid, Vector2(40, 16), false)
	else:
		_used[mid] = true
		_prop("spring", at, false)
	_light(at, COLD, Vector2(240, 160), false)
	_light(at + Vector2(0, -90), Color(COLD, 0.18), Vector2(110, 260), false)
	_drips(at + Vector2(0, -140))
	_dust(at + Vector2(0, -60))
	for i in 8:
		var angle := TAU * i / 8.0 + rng.randf_range(-0.2, 0.2)
		var spot := at + Vector2(cos(angle), sin(angle) * 0.7) * rng.randf_range(110, 140)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) != "l":
			continue
		if i % 2 == 0:
			_prop(_pick(["res://assets/swamp/v2_reeds.png", "res://assets/ancient/v2_mossy_rocks.png"]), spot)
		else:
			_decal(_pick(["algae", "lilies"]), spot)
	for v in _corners(room):
		if _isolated(v):
			_solid("basin", v, Vector2(36, 16), false)


## Komnata wejściowa: kładka z mokrych desek od płomieni Watry przez rozlewisko, po bokach kolumny.
func _start(room: Rect2i) -> void:
	var cx := _center(room).x
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, room.position.y + 1)] = true
	var length := (room.end.y - room.position.y - 2) * Dungeon.CELL - 40
	_pool(_px(Vector2i(cx, room.position.y + 1)) + Vector2(0, 46 + length * 0.6))
	var walk := _runner(_px(Vector2i(cx, room.position.y + 1)) + Vector2(0, 46), length, false, "planks")
	walk.z_index = 1
	for side in [-2, 2]:
		var v := Vector2i(cx + side, room.position.y + 2)
		if _isolated(v):
			_solid("pillar", v, Vector2(26, 14), false)


## Komnata strażnika: tron wodnika z wyrzuconego drewna i muszli za skarbcem, utopione skarby po bokach,
## aleja posągów i kolumn od tronu w głąb sali, krąg rozlewisk i lilii wokół miejsca walki, misy z wodą
## w narożnikach.
func _boss(room: Rect2i) -> void:
	var cx := _center(room).x
	var top := room.position.y + 1
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, top)] = true
		_used[Vector2i(x, top - 1)] = true
	# tron za skrzynią skarbca (Dungeon._build_vault stawia ją w wierzchołku (cx, top))
	_prop("throne", _px(Vector2i(cx, top)) + Vector2(0, -6), false)
	_light(_px(Vector2i(cx, top)), Color(WISP, 0.45), Vector2(240, 170))
	for side in [-1, 1]:
		for step in [2, 3]:
			var v := Vector2i(cx + side * step, top)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				var heap := _prop("treasure" if step == 2 else "shells", _px(v) + Vector2(0, -8), false)
				heap.flip_h = side > 0
		for y in range(top + 2, room.end.y - 1, 2):
			var v := Vector2i(cx + side * 3, y)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				_prop("statue" if (y - top) % 4 == 2 else "pillar", _px(v) + Vector2(0, 12), false)
	var arena := Vector2(room.get_center()) * Dungeon.CELL + Vector2(0, Dungeon.CELL / 2.0)
	_pool(arena)
	for i in 10:
		var angle := TAU * i / 10.0
		var spot := arena + Vector2(cos(angle) * 160, sin(angle) * 100)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) == "l" and spot.y > _px(Vector2i(cx, top)).y + 70:
			if i % 2 == 0:
				_decal("pool_small", spot)
			else:
				_decal("lilies", spot)
	for v in _corners(room):
		if v.y > top + 1 and _isolated(v):
			_solid("basin", v, Vector2(36, 16), false)
			_light(_px(v) + Vector2(0, -16), WISP, Vector2(170, 130))
