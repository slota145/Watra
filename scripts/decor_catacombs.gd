class_name CatacombsDecor
extends DungeonDecor
## Wystrój Katakumb: kinkiety w równych odstępach na licu ścian (między nimi nisze, chorągwie, wykruszenia),
## pod ścianami rzędy mebli (półki z czaszkami, stojące trumny, kandelabry...), a środek komnaty urządza scenka:
## krypta (siatka sarkofagów), sala kolumnowa, kostnica (kopiec czaszek w kręgu świec), kaplica (ołtarz, chodnik,
## rzędy ław), zawalona sala (złamana kolumnada, gruz wokół snopu światła z dziury w sklepieniu) i kaźnia
## (klatki, łańcuchy, koksownik). Komnata wejściowa dostaje koksowniki przy płomieniach Watry, komnata
## strażnika - krąg rytualny i posągi.

const FLOOR_DECALS := {"crack": 3.0, "rubble": 3.0, "puddle": 1.2, "grate": 0.5, "blood": 0.6, "hole": 0.3}
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


func lines() -> Dictionary:
	return LINES


func floor_decals() -> Dictionary:
	return FLOOR_DECALS


func low_props() -> Array:
	return ["skull_pile", "urn", "font"]


func line_lights() -> Dictionary:
	return {"candelabra": [CANDLE, Vector2(110, 90), Vector2(0, -40)]}


func event_pillars() -> Array:
	return ["pillar_0", "pillar_2"]


## Kinkiety co 3 wierzchołki, między nimi nisze z czaszkami, chorągwie (parami po bokach kinkietu) i wykruszone cegły.
func _dress_wall(run: Array[Vector2i]) -> void:
	var start := _light_start(run)
	var banners := rng.randf() < 0.5
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and (i - start) % 3 == 0 and i >= start:
			_wall_light("sconce", v)
		elif banners and run.size() >= 4:
			_decal("banner", at + Vector2(0, -8), false)
		elif rng.randf() < 0.35:
			_decal(_pick(["niche", "niche", "wall_crack"]), at + Vector2(0, -8))


func _candles(pos: Vector2) -> void:
	_prop("candles", pos)
	_light(pos + Vector2(0, -10), CANDLE, Vector2(90, 66))


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
	for v in _corners(room):
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
	_light_shaft(mid, ["res://assets/cemetery/fallen_stone.png"])


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
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["statue_0", "statue_2"]), v, Vector2(24, 14), false)
			_light(_px(v) + Vector2(0, -20), Color(RITUAL, 0.3), Vector2(110, 90))
