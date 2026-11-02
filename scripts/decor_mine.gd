class_name MineDecor
extends DungeonDecor
## Wystrój Kopalni goblinów - czynnej kopalni, w której gobliny kopią rudę (koboldy robią za niewolników).
## Na licu ścian latarnie w równych odstępach, między nimi żyły kruszcu, plemienne chorągwie i bazgroły goblinów.
## Rodzaje sal: chodnik z torami (tory przez salę, wózki z rudą, rzędy podpór), skład prochu (siatka stosów beczek,
## znaki ostrzegawcze), kuźnia (palenisko z iskrami, kowadła, koryto), obóz (ognisko w kręgu legowisk), szyb z windą
## (platforma, kołowrót, słupy z kajdanami), zawał (połamane podpory, głazy wokół snopu światła z dziury w stropie)
## i żyła kruszcu (świecące kryształy w rzędach, kopce rudy). Komnata wejściowa: kładka z desek do płomieni Watry,
## komnata strażnika: tron wodza z łupów za skarbcem, góry skarbów po bokach.

const LANTERN := Color(1.0, 0.66, 0.32, 0.55)
const FORGE := Color(1.0, 0.5, 0.2, 0.6)
const CRYSTAL := Color(0.4, 0.75, 1.0, 0.5)
const FLOOR_DECALS := {"crack": 2.0, "rubble": 3.0, "puddle": 0.8, "powder": 0.6, "ore_bits": 1.5, "pick": 0.3,
		"hatch": 0.15}
const LINES := {
	"tracks": {"n": ["tool_rack", "ore_sacks", "", "lumber", "bucket", ""], "w": ["ore_sacks", "bucket", ""],
			"e": ["ore_sacks", "bucket", ""], "s": ["lumber", "", "picks", "ore_sacks"]},
	"powder": {"n": ["powder_barrels", "warning_sign", "powder_barrels", "bomb_crate"], "w": ["bomb_crate", "", "powder_barrels", ""],
			"e": ["bomb_crate", "", "powder_barrels", ""], "s": ["", "bomb_crate", "", "warning_sign"]},
	"forge": {"n": ["ingot_shelf", "weapon_rack", "tool_rack", "weapon_rack"], "w": ["weapon_rack", "", "ore_sacks", ""],
			"e": ["weapon_rack", "", "ore_sacks", ""], "s": ["", "lumber", "", "bucket"]},
	"camp": {"n": ["totem", "bedroll", "banner_pole", "bedroll"], "w": ["bedroll", "", "skull_stick", ""],
			"e": ["bedroll", "", "skull_stick", ""], "s": ["", "nuggets", "", "bedroll"]},
	"shaft": {"n": ["ladder", "rope", "chain_post", ""], "w": ["chain_post", "ore_sacks", ""], "e": ["chain_post", "ore_sacks", ""],
			"s": ["rope", "", "bucket", "ore_sacks"]},
	"cavein": {"n": ["lumber", "", "tool_rack", "picks"], "w": ["rope", "", "picks", "lumber"], "e": ["rope", "", "picks", "lumber"],
			"s": ["", "picks", "ore_sacks"]},
	"vein": {"n": ["tool_rack", "ore_sacks", "", "bucket"], "w": ["picks", "", "bucket", "ore_sacks"],
			"e": ["picks", "", "bucket", "ore_sacks"], "s": ["", "ore_sacks", "picks"]},
	"start": {"n": ["banner_pole", "", "tool_rack", ""], "w": ["ore_sacks", ""], "e": ["ore_sacks", ""], "s": []},
	"boss": {"n": ["banner_pole", "totem"], "w": ["totem", "banner_pole", ""], "e": ["totem", "banner_pole", ""], "s": ["skull_stick", ""]},
	"event": {"n": ["tool_rack", "", "ore_sacks", ""], "w": ["", "bucket"], "e": ["", "bucket"], "s": []},
}


func lines() -> Dictionary:
	return LINES


func floor_decals() -> Dictionary:
	return FLOOR_DECALS


func low_props() -> Array:
	return ["bucket", "picks", "nuggets", "ore_sacks", "bedroll", "rope", "skull_stick"]


func event_pillars() -> Array:
	return ["support"]


## Latarnie co 3 wierzchołki, między nimi pary chorągwi albo żyły kruszcu i bazgroły goblinów.
func _dress_wall(run: Array[Vector2i]) -> void:
	var start := _light_start(run)
	var banners := rng.randf() < 0.4
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and (i - start) % 3 == 0 and i >= start:
			_wall_light("lantern", v, LANTERN)
		elif banners and run.size() >= 4 and (i - start) % 3 != 0:
			_decal("banner", at + Vector2(0, -8), false)
		elif rng.randf() < 0.4:
			_decal(_pick(["vein", "vein", "scrawl"]), at + Vector2(0, -8))


## Podpora stropu z wiszącą latarnią (co druga świeci).
func _support(v: Vector2i, lit: bool) -> void:
	_solid("support", v, Vector2(26, 14), false)
	if lit:
		_light(_px(v) + Vector2(0, -30), LANTERN, Vector2(170, 130))


## Iskry nad paleniskiem.
func _sparks(at: Vector2) -> void:
	var sparks := CPUParticles2D.new()
	sparks.position = at
	sparks.amount = 10
	sparks.lifetime = 1.2
	sparks.preprocess = 1.2
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(10, 4)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 25.0
	sparks.gravity = Vector2(0, 20)
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 45.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.5
	sparks.color = Color(1.0, 0.7, 0.3, 0.9)
	sparks.z_index = 20
	w.add_child(sparks)


# ---------------------------------------------------------------- scenki
## Chodnik z torami: tory przez środek sali od ściany do ściany, na nich wózki z rudą (jeden wywrócony obok),
## kopce rudy przy końcach, wzdłuż sali dwa rzędy podpór z latarniami.
func _tracks(room: Rect2i) -> void:
	var mid := _center(room)
	var x0 := room.position.x
	var x1 := room.end.x - 1
	while x0 > room.position.x - 3 and _floor_at(Vector2i(x0 - 1, mid.y)):
		x0 -= 1
	while x1 < room.end.x + 2 and _floor_at(Vector2i(x1 + 1, mid.y)):
		x1 += 1
	_runner(_px(Vector2i(x0, mid.y)) + Vector2(-28, 12), (x1 - x0) * Dungeon.CELL + 56, true, "rails")
	var carts := 0
	for x in range(x0 + 1, x1):
		var v := Vector2i(x, mid.y)
		if carts < 2 and absi(x - mid.x) >= 1 and (x - x0) % 3 == 1 and _isolated(v):
			_solid("cart", v, Vector2(36, 16), false)
			carts += 1
		_used[v] = true
	# wzdłuż torów: podpory dwa wierzchołki dalej, a przy samych torach rząd worków, wiader i kilofów
	var lit := false
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [mid.y - 2, mid.y + 2]:
			var v := Vector2i(x, y)
			if _isolated(v):
				_support(v, lit)
				lit = not lit
	var i := 0
	for x in range(x0 + 1, x1):
		for y in [mid.y - 1, mid.y + 1]:
			var v := Vector2i(x, y)
			i += 1
			if i % 2 == 0 and _floor_at(v) and not _used.has(v):
				_used[v] = true
				_prop(["ore_sacks", "bucket", "lumber", "picks"][i / 2 % 4], _px(v) + Vector2(0, 16 if y < mid.y else 30))
	var tipped := Vector2i(x1 - 1, mid.y + 1)
	if _isolated(tipped):
		_solid("cart_tipped", tipped, Vector2(36, 16))
	for x in [room.position.x, room.end.x - 1]:
		var v := Vector2i(x, mid.y - 1)
		if _isolated(v):
			_solid("ore_heap", v, Vector2(34, 14))


## Siatka dużych rekwizytów co drugi wierzchołek (jak regały w magazynie); `place` stawia jeden na wierzchołku
## (z numerem kolejnym), `aisle` - coś w przejściu między rzędami (albo nic).
func _grid(room: Rect2i, place: Callable, aisle: Callable) -> void:
	var i := 0
	for x in range(room.position.x + 1, room.end.x - 1):
		for y in range(room.position.y + 2, room.end.y - 1):
			var v := Vector2i(x, y)
			var col := (x - room.position.x) % 2 == 1
			var row := (y - room.position.y) % 2 == 0
			if col and row and _isolated(v):
				place.call(v, i)
				i += 1
			elif _floor_at(v) and not _used.has(v):
				aisle.call(v)


## Skład prochu: siatka stosów beczek, rozsypany proch w przejściach, słabe światło.
func _powder(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, _i: int) -> void:
			_solid("powder_stack" if rng.randf() < 0.75 else "bomb_crate", v, Vector2(40, 16)),
		func(v: Vector2i) -> void:
			if rng.randf() < 0.4:
				_decal("powder", _px(v) + _jitter(10) + Vector2(0, 10)))
	var mid := _center(room)
	_light(_px(mid) + Vector2(0, 10), Color(LANTERN, 0.3), Vector2(260, 180))


## Kuźnia: palenisko na środku (żar, iskry), po bokach kowadła, przed nim koryto z wodą, wokół kopce rudy.
func _forge(room: Rect2i) -> void:
	var mid := _center(room)
	if not _isolated(mid):
		_tracks(room)
		return
	_solid("forge", mid, Vector2(44, 18), false)
	_light(_px(mid) + Vector2(0, -10), FORGE, Vector2(260, 200))
	_sparks(_px(mid) + Vector2(0, -34))
	_prop("bellows", _px(mid) + Vector2(-40, 14))
	for side in [-2, 2]:
		var anvil := mid + Vector2i(side, 1)
		if _isolated(anvil):
			_solid("anvil", anvil, Vector2(30, 14))
	var trough := mid + Vector2i(0, 2)
	if _isolated(trough):
		_solid("trough", trough, Vector2(40, 14), false)
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["ore_heap", "ore_sacks"]), v, Vector2(34, 14))


## Obóz goblinów: ognisko z rożnem na środku, krąg legowisk wokół, tyczki z czaszkami między nimi.
func _camp(room: Rect2i) -> void:
	var mid := _center(room)
	var at := _px(mid) + Vector2(0, 20)
	if _isolated(mid):
		_solid("campfire", mid, Vector2(30, 14), false)
	else:
		_used[mid] = true
		_prop("campfire", at, false)
	_light(at + Vector2(0, -16), FORGE, Vector2(240, 180))
	_sparks(at + Vector2(0, -20))
	for i in 8:
		var angle := TAU * i / 8.0 + PI / 8.0
		var spot := at + Vector2(cos(angle) * 96, sin(angle) * 64)
		if i % 2 == 0:
			var bed := _prop("bedroll", spot)
			bed.scale = Vector2(0.7, 0.7)
			bed.modulate = Color(0.78, 0.74, 0.7)
		else:
			_prop("skull_stick", spot)
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["nuggets", "ore_sacks", "lumber"]), v, Vector2(34, 14))


## Szyb z windą: platforma na środku, obok kołowrót i wózek, słupy z kajdanami w rzędzie pod spodem,
## ze stropu pada słabe zimne światło.
func _shaft(room: Rect2i) -> void:
	var mid := _center(room)
	if not _isolated(mid):
		_cavein(room)
		return
	_solid("lift", mid, Vector2(52, 24), false)
	_light(_px(mid) + Vector2(0, -40), Color(COLD, 0.3), Vector2(120, 240), false)
	_dust(_px(mid) + Vector2(0, -80))
	var winch := mid + Vector2i(2, 0)
	if _isolated(winch):
		_solid("windlass", winch, Vector2(34, 14), false)
	var cart := mid + Vector2i(-2, 0)
	if _isolated(cart):
		_solid("cart", cart, Vector2(36, 16), false)
	for offset in [Vector2(-40, 52), Vector2(44, 50), Vector2(-60, -6)]:
		_prop(_pick(["ore_sacks", "bucket", "rope"]), _px(mid) + offset)
	var y := room.end.y - 2
	if y - mid.y >= 2:
		for x in range(room.position.x + 1, room.end.x - 1, 2):
			var v := Vector2i(x, y)
			if _isolated(v):
				_solid("chain_post", v, Vector2(20, 12), false)


## Zawał: połamane podpory i głazy w dwóch rzędach, gruz i odłamki wokół snopu światła z dziury w stropie.
func _cavein(room: Rect2i) -> void:
	var mid := _center(room)
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [room.position.y + 2, room.end.y - 2]:
			var v := Vector2i(x, y)
			if not _isolated(v) or absi(v.x - mid.x) <= 1 and absi(v.y - mid.y) <= 1:
				continue
			var roll := rng.randf()
			if roll < 0.3:
				_solid("support", v, Vector2(26, 14), false)
			elif roll < 0.65:
				_solid("broken_beams", v, Vector2(40, 14))
			elif roll < 0.9:
				_solid("boulders", v, Vector2(40, 16))
			else:
				_decal("rubble", _px(v) + Vector2(0, 10))
				_used[v] = true
	_light_shaft(mid, ["res://assets/fields/rubble.png", "res://assets/forest/props/boulders.png", "pick"],
			"rubble", "res://assets/dungeons/catacombs/hole.png")


## Żyła kruszcu: siatka świecących kryształów i kopców rudy na przemian, w przejściach okruchy rudy,
## wiadra i kilofy.
func _vein(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			if i % 2 == 0:
				_solid("crystal", v, Vector2(30, 14))
				_light(_px(v) + Vector2(0, -20), CRYSTAL, Vector2(160, 130))
			else:
				_solid("ore_heap", v, Vector2(34, 14)),
		func(v: Vector2i) -> void:
			var roll := rng.randf()
			if roll < 0.3:
				_decal("ore_bits", _px(v) + _jitter(12) + Vector2(0, 10))
			elif roll < 0.5:
				_used[v] = true
				_prop(_pick(["bucket", "picks", "nuggets"]), _px(v) + _jitter(10) + Vector2(0, 20)))


## Komnata wejściowa: kładka z desek od płomieni Watry, po bokach podpory z latarniami.
func _start(room: Rect2i) -> void:
	var cx := _center(room).x
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, room.position.y + 1)] = true
	_runner(_px(Vector2i(cx, room.position.y + 1)) + Vector2(0, 46), (room.end.y - room.position.y - 2) * Dungeon.CELL - 40, false,
			"walkway")
	for side in [-2, 2]:
		var v := Vector2i(cx + side, room.position.y + 2)
		if _isolated(v):
			_support(v, true)


## Komnata strażnika: tron wodza z łupów za skarbcem, góry skarbów po bokach, aleja chorągwi i totemów od tronu
## w głąb sali, krąg tyczek z czaszkami wokół miejsca walki (środek wolny), koksowniki w narożnikach.
func _boss(room: Rect2i) -> void:
	var cx := _center(room).x
	var top := room.position.y + 1
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, top)] = true
		_used[Vector2i(x, top - 1)] = true
	# tron za skrzynią skarbca (Dungeon._build_vault stawia ją w wierzchołku (cx, top))
	_prop("throne", _px(Vector2i(cx, top)) + Vector2(0, -6), false)
	_light(_px(Vector2i(cx, top)), Color(1.0, 0.8, 0.4, 0.45), Vector2(220, 160))
	for side in [-1, 1]:
		for step in [2, 3]:
			var v := Vector2i(cx + side * step, top)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				var heap := _prop("treasure" if step == 2 else "nuggets", _px(v) + Vector2(0, -8), false)
				heap.flip_h = side > 0
		for y in range(top + 2, room.end.y - 1, 2):
			var v := Vector2i(cx + side * 3, y)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				_prop("banner_pole" if (y - top) % 4 == 2 else "totem", _px(v) + Vector2(0, 12), false)
	# krąg tyczek z czaszkami i kości wokół miejsca walki (środek komnaty, tu stoi wódz)
	var arena := Vector2(room.get_center()) * Dungeon.CELL + Vector2(0, Dungeon.CELL / 2.0)
	for i in 12:
		var angle := TAU * i / 12.0
		var spot := arena + Vector2(cos(angle) * 150, sin(angle) * 96)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) == "l" and spot.y > _px(Vector2i(cx, top)).y + 70:
			if i % 2 == 0:
				_prop("skull_stick", spot)
			else:
				_prop("res://assets/forest/props/bones.png", spot)
	for v in _corners(room):
		if v.y > top + 1 and _isolated(v):
			_solid("res://assets/dungeons/catacombs/brazier_iron.png", v, Vector2(26, 14), false)
			_light(_px(v) + Vector2(0, -24), FORGE, Vector2(180, 140))
