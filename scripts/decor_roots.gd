class_name RootsDecor
extends DungeonDecor
## Wystrój Pajęczych korzeni - dzikich jaskiń pod Prastarym Lasem, bez śladów dawnych mieszkańców: strop przebijają
## korzenie wielkich drzew, w wilgoci rośnie świecąca grzybnia, a całe podziemia zajęły pająki. Zapuszczają się
## tu tylko łowcy, a drzewce schodzą bronić korzeni.
## Na licu ścian świecące huby (niebieskie światło) w równych odstępach, między nimi zwisające korzenie, sieci
## i jaja przyklejone do skały. Na podłodze płaty sieci, świecący mech, muł, liście i kości.
## Rodzaje sal: wylęgarnia (siatka kopców jaj, skorupki w przejściach), spiżarnia (siatka kokonów z ofiarami,
## kości i porzucony ekwipunek), korzenie (snop światła z dziury w stropie, krąg kolumn z korzeni), grzybnia (siatka
## wielkich świecących grzybów, unoszące się zarodniki), sieciowa sala (pajęczy most przez salę między rzędami
## oplecionych siecią stalagmitów), kryjówka drzewców (wydrążony pień w kręgu omszałych głazów i pniaków, żywica
## kapiąca z korzeni), obóz łowców (zgasłe ognisko z trójnogiem, szałas, posłania, nad nim kokony - łowcy
## nie wrócili) i pajęczy ołtarz (stos czaszek i poroży owinięty siecią, krąg trofeów). Komnata wejściowa:
## zejście po korzeniach od płomieni Watry, komnata strażnika: gniazdo królowej z sieci i kości za skarbcem,
## aleja oplecionych stalagmitów, krąg kokonów i kopce jaj w narożnikach.

## Blade, zimne światło hub i grzybów.
const GLOW := Color(0.45, 0.8, 1.0, 0.5)
## Bursztynowa żywica korzeni.
const SAP := Color(1.0, 0.7, 0.3, 0.45)
## Trupi, zielonkawy blask jaj i ołtarza.
const EGG := Color(0.7, 1.0, 0.55, 0.4)
## Wielka pajęczyna z Prastarego Lasu (przezroczysta) - pod ścianami i między stalagmitami.
const WEB := "res://assets/ancient/web_big.png"
const FLOOR_DECALS := {"crack": 1.2, "silk_patch": 2.0, "glow_moss": 1.2, "mud": 1.4, "leaves": 1.6, "bones": 0.6,
		"shells": 0.15}
const LINES := {
	"hatchery": {"n": ["eggs", "", "web_sheet", ""], "w": ["eggs", "", WEB], "e": ["eggs", "", WEB],
			"s": ["", "eggs", "", WEB]},
	"larder": {"n": ["cocoons", "", "bone_heap", "cocoons", ""], "w": ["cocoons", "", "bone_heap"], "e": ["cocoons", "", "bone_heap"],
			"s": ["", "cocoons", "", WEB]},
	"roots": {"n": ["root_wall", "", "sap_root", "root_wall", ""], "w": ["moss", "", "log"], "e": ["moss", "", "log"],
			"s": ["", "moss", "", "log"]},
	"mycelium": {"n": ["shelf_fungi", "", "moss", ""], "w": ["shelf_fungi", "", "moss"], "e": ["shelf_fungi", "", "moss"],
			"s": ["", "shelf_fungi", "", "log"]},
	"webhall": {"n": ["web_sheet", WEB, "", "web_sheet"], "w": [WEB, "", WEB],
			"e": [WEB, "", WEB], "s": ["", WEB, "", WEB]},
	"treants": {"n": ["dead_treant", "", "sap_root", "moss", ""], "w": ["log", "", "moss"], "e": ["log", "", "moss"],
			"s": ["", "dead_treant", "", "moss"]},
	"camp": {"n": ["spear_rack", "supplies", "", "bedroll", ""], "w": ["bedroll", "", "supplies"], "e": ["bedroll", "", "lantern_post"],
			"s": ["", "supplies", "", "cocoons"]},
	"altar": {"n": ["antlers", "", "bone_heap", ""], "w": ["antlers", "", WEB], "e": ["antlers", "", WEB],
			"s": ["", "bone_heap", "", "antlers"]},
	"start": {"n": ["root_wall", "", "sap_root", ""], "w": ["moss", ""], "e": ["moss", ""], "s": []},
	"boss": {"n": ["eggs", "web_sheet"], "w": ["cocoons", WEB, ""], "e": ["cocoons", WEB, ""], "s": [WEB, ""]},
	"event": {"n": ["root_wall", "", "shelf_fungi", ""], "w": ["", "moss"], "e": ["", "moss"], "s": []},
}


func lines() -> Dictionary:
	return LINES


func floor_decals() -> Dictionary:
	return FLOOR_DECALS


func low_props() -> Array:
	return ["eggs", "bone_heap", "moss", "bedroll", "supplies", "log", "antlers", "skull", "egg", "shrooms", "backpack"]


func line_lights() -> Dictionary:
	return {"shelf_fungi": [Color(GLOW, 0.35), Vector2(120, 100), Vector2(0, -24)],
			"sap_root": [Color(SAP, 0.3), Vector2(100, 90), Vector2(0, -16)],
			"lantern_post": [Color(WARM, 0.4), Vector2(130, 110), Vector2(0, -40)]}


func event_pillars() -> Array:
	return ["root_column", "root_twist"]


## Świecące huby co 3 wierzchołki, między nimi zwisające korzenie, sieci i jaja.
func _dress_wall(run: Array[Vector2i]) -> void:
	var start := _light_start(run)
	for i in run.size():
		var v := run[i]
		var at := _px(v)
		if run.size() >= 2 and (i - start) % 3 == 0 and i >= start:
			_wall_light("fungus_lamp", v, GLOW)
		elif rng.randf() < 0.6:
			_decal(_pick(["root_drape", "root_drape", "wall_web", "wall_eggs"]), at + Vector2(0, -10))


## Drobiazg albo nakładka w przejściu między rzędami siatki.
func _litter(v: Vector2i, decals: Array, props: Array, chance := 0.3) -> void:
	var roll := rng.randf()
	if roll < chance:
		_decal(_pick(decals), _px(v) + _jitter(12) + Vector2(0, 10))
	elif roll < chance + 0.1 and not props.is_empty():
		_used[v] = true
		_prop(_pick(props), _px(v) + _jitter(10) + Vector2(0, 20))


## Krąg rzeczy wokół `at` (elipsa o promieniach `radius`): co druga to rekwizyt z `props`, reszta - nakładki.
func _ring(at: Vector2, radius: Vector2, count: int, props: Array, decals: Array) -> void:
	for i in count:
		var angle := TAU * i / count
		var spot := at + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) != "l":
			continue
		if i % 2 == 0 and not props.is_empty():
			_prop(_pick(props), spot)
		else:
			_decal(_pick(decals), spot)


## Duży rekwizyt na środku sali; gdy środek nie jest wolny - bez kolizji.
func _centerpiece(name: String, mid: Vector2i, collision: Vector2) -> void:
	if _isolated(mid):
		_solid(name, mid, collision, false)
	else:
		_used[mid] = true
		_prop(name, _px(mid) + Vector2(0, 20), false)


# ---------------------------------------------------------------- scenki
## Wylęgarnia: siatka kopców jaj (część już pęknięta - rozdarte kokony), w przejściach skorupki, płaty sieci
## i pojedyncze jaja, trupi blask nad salą.
func _hatchery(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			_solid("egg_mound" if i % 4 != 3 else "cocoon_torn", v, Vector2(40, 16))
			if i % 2 == 0:
				_light(_px(v) + Vector2(0, -8), Color(EGG, 0.3), Vector2(130, 100)),
		func(v: Vector2i) -> void:
			_litter(v, ["shells", "silk_patch", "silk_patch"], ["egg", "husk"]))
	_light(_px(_center(room)) + Vector2(0, 10), Color(EGG, 0.22), Vector2(300, 220), false)


## Spiżarnia: siatka kokonów z ofiarami i oplecionych siecią stalagmitów, w przejściach kości, czaszki
## i porzucone plecaki.
func _larder(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			_solid("cocoon" if i % 3 != 2 else "silk_spire", v, Vector2(28, 14)),
		func(v: Vector2i) -> void:
			_litter(v, ["bones", "silk_patch", "mud"], ["skull", "backpack", "res://assets/ancient/wrapped_victim.png"]))
	_light(_px(_center(room)) + Vector2(0, 10), Color(GLOW, 0.2), Vector2(280, 200), false)


## Korzenie: na środku snop światła z dziury w stropie, wokół krąg kolumn z korzeni przebijających strop,
## w narożnikach omszałe głazy.
func _roots(room: Rect2i) -> void:
	var mid := _center(room)
	_light_shaft(mid, ["root_stump", "shrooms", "res://assets/ancient/v2_mossy_rocks.png"], "leaves", "mud")
	for step: Vector2i in [Vector2i(-2, -1), Vector2i(2, -1), Vector2i(-2, 2), Vector2i(2, 2), Vector2i(0, -2)]:
		var v := mid + step
		if _isolated(v):
			_solid(_pick(["root_column", "root_twist"]), v, Vector2(26, 14))
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["root_boulder", "root_stump"]), v, Vector2(36, 16))


## Grzybnia: siatka wielkich świecących grzybów (każdy z własnym światłem i zarodnikami), w przejściach
## świecący mech i małe grzyby, nad salą unoszą się zarodniki.
func _mycelium(room: Rect2i) -> void:
	_grid(room, func(v: Vector2i, i: int) -> void:
			_solid("giant_shroom" if i % 3 != 1 else "shroom_cluster", v, Vector2(30, 14))
			_light(_px(v) + Vector2(0, -16), GLOW, Vector2(170, 130))
			_motes(_px(v) + Vector2(0, -30), Vector2(20, 14), 3, Color(0.6, 0.9, 1.0)),
		func(v: Vector2i) -> void:
			_litter(v, ["glow_moss", "glow_moss", "leaves"], ["shrooms"], 0.4))
	var mid := _center(room)
	_motes(_px(mid), Vector2(room.size.x * 24.0, room.size.y * 20.0), 18, Color(0.6, 0.9, 1.0))


## Sieciowa sala: przez salę od ściany do ściany pajęczy most z nici, wzdłuż niego dwa rzędy oplecionych
## siecią stalagmitów, między nimi wielkie pajęczyny.
func _webhall(room: Rect2i) -> void:
	var mid := _center(room)
	var x0 := room.position.x
	var x1 := room.end.x - 1
	while x0 > room.position.x - 3 and _floor_at(Vector2i(x0 - 1, mid.y)):
		x0 -= 1
	while x1 < room.end.x + 2 and _floor_at(Vector2i(x1 + 1, mid.y)):
		x1 += 1
	var bridge := _runner(_px(Vector2i(x0, mid.y)) + Vector2(-28, 14), (x1 - x0) * Dungeon.CELL + 56, true, "silk")
	bridge.z_index = 1
	for x in range(x0, x1 + 1):
		_used[Vector2i(x, mid.y)] = true
	for x in range(room.position.x + 1, room.end.x - 1, 2):
		for y in [mid.y - 2, mid.y + 2]:
			var v := Vector2i(x, y)
			if not _isolated(v):
				continue
			_solid("silk_spire", v, Vector2(26, 14), false)
			var gap := Vector2i(x + 1, y)
			if _floor_at(gap) and not _used.has(gap) and rng.randf() < 0.5:
				_used[gap] = true
				_prop(_pick([WEB, "res://assets/ancient/web_small.png"]), _px(gap) + Vector2(0, 16))
	_light(_px(mid) + Vector2(0, 10), Color(GLOW, 0.25), Vector2(320, 200), false)


## Kryjówka drzewców: wydrążony pień na środku, wokół krąg omszałych głazów i pniaków, liście i mech,
## bursztynowe światło żywicy.
func _treants(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece("hollow_stump", mid, Vector2(44, 18))
	_light(_px(mid) + Vector2(0, -10), SAP, Vector2(220, 160))
	for step: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(2, 2), Vector2i(-2, -2)]:
		var v := mid + step
		if _isolated(v):
			_solid(_pick(["root_boulder", "root_stump", "root_boulder"]), v, Vector2(36, 16))
	_ring(_px(mid) + Vector2(0, 20), Vector2(150, 100), 10, ["shrooms", "res://assets/ancient/v2_roots.png"], ["leaves", "glow_moss"])


## Obóz łowców: zgasłe ognisko z trójnogiem, obok szałas i plecaki, nad obozem kokony - łowcy nie wrócili;
## w narożnikach rozdarte kokony i kości.
func _camp(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece("campfire", mid, Vector2(36, 16))
	_light(_px(mid) + Vector2(0, 0), Color(WARM, 0.28), Vector2(200, 150))
	var tent := mid + Vector2i(-2, -1)
	if _isolated(tent):
		_solid("tent", tent, Vector2(44, 18))
	for step: Vector2i in [Vector2i(2, -1), Vector2i(2, 1), Vector2i(-1, 2)]:
		var v := mid + step
		if _isolated(v):
			_solid("cocoon", v, Vector2(28, 14))
	_ring(_px(mid) + Vector2(0, 20), Vector2(110, 74), 6, ["backpack", "skull"], ["bones", "silk_patch"])
	for v in _corners(room):
		if _isolated(v):
			_solid(_pick(["cocoon_torn", "silk_spire"]), v, Vector2(30, 14))


## Pajęczy ołtarz: stos czaszek i poroży owinięty siecią pod północną ścianą, przed nim krąg czaszek i kości,
## od ołtarza w głąb sali dwa rzędy kokonów, trupi blask.
func _altar(room: Rect2i) -> void:
	var mid := _center(room)
	var top := Vector2i(mid.x, room.position.y + 2)
	if not _isolated(top):
		top = mid
	_centerpiece("altar", top, Vector2(40, 16))
	_light(_px(top) + Vector2(0, -20), EGG, Vector2(220, 170))
	_motes(_px(top) + Vector2(0, -30), Vector2(30, 20), 5, Color(0.75, 1.0, 0.6))
	_ring(_px(top) + Vector2(0, 40), Vector2(100, 56), 8, ["skull", "egg"], ["bones", "silk_patch"])
	for y in range(top.y + 3, room.end.y - 1, 2):
		for side in [-2, 2]:
			var v := Vector2i(mid.x + side, y)
			if _isolated(v):
				_solid("cocoon" if rng.randf() < 0.7 else "silk_spire", v, Vector2(28, 14))


## Komnata wejściowa: zejście po korzeniach od płomieni Watry w głąb sali, po bokach kolumny z korzeni.
func _start(room: Rect2i) -> void:
	var cx := _center(room).x
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, room.position.y + 1)] = true
	var length := (room.end.y - room.position.y - 2) * Dungeon.CELL - 40
	var path := _runner(_px(Vector2i(cx, room.position.y + 1)) + Vector2(0, 46), length, false, "root_path")
	path.z_index = 1
	for side in [-2, 2]:
		var v := Vector2i(cx + side, room.position.y + 2)
		if _isolated(v):
			_solid(_pick(["root_column", "root_twist"]), v, Vector2(26, 14), false)


## Komnata strażnika: gniazdo królowej z sieci, kości i korzeni za skarbcem, skarby i kopce jaj po bokach,
## aleja oplecionych stalagmitów od gniazda w głąb sali, krąg kokonów i płatów sieci wokół miejsca walki,
## kopce jaj w narożnikach.
func _boss(room: Rect2i) -> void:
	var cx := _center(room).x
	var top := room.position.y + 1
	for x in range(cx - 1, cx + 2):
		_used[Vector2i(x, top)] = true
		_used[Vector2i(x, top - 1)] = true
	# gniazdo za skrzynią skarbca (Dungeon._build_vault stawia ją w wierzchołku (cx, top))
	_prop("throne", _px(Vector2i(cx, top)) + Vector2(0, -6), false)
	_light(_px(Vector2i(cx, top)), Color(EGG, 0.45), Vector2(240, 170))
	for side in [-1, 1]:
		for step in [2, 3]:
			var v := Vector2i(cx + side * step, top)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				var heap := _prop("treasure" if step == 2 else "egg_mound", _px(v) + Vector2(0, -8), false)
				heap.flip_h = side > 0
		for y in range(top + 2, room.end.y - 1, 2):
			var v := Vector2i(cx + side * 3, y)
			if _floor_at(v) and not _used.has(v):
				_used[v] = true
				_prop("silk_spire" if (y - top) % 4 == 2 else "cocoon", _px(v) + Vector2(0, 12), false)
	var arena := Vector2(room.get_center()) * Dungeon.CELL + Vector2(0, Dungeon.CELL / 2.0)
	_decal("silk_patch", arena)
	for i in 10:
		var angle := TAU * i / 10.0
		var spot := arena + Vector2(cos(angle) * 160, sin(angle) * 100)
		if d._label(Vector2i((spot / Dungeon.CELL).round())) == "l" and spot.y > _px(Vector2i(cx, top)).y + 70:
			_decal(_pick(["silk_patch", "silk_patch", "bones"]), spot)
	for v in _corners(room):
		if v.y > top + 1 and _isolated(v):
			_solid("egg_mound", v, Vector2(40, 16), false)
			_light(_px(v) + Vector2(0, -8), Color(EGG, 0.3), Vector2(150, 110))
