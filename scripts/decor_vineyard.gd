class_name VineyardDecor
extends DungeonDecor
## Wystrój Winnicy satyrów - lochu na zewnątrz (Dungeon.outdoor): dzika winnica na skalnych tarasach, w której
## satyrowie upili się winem z płomieni Watry i świętują bez końca. Wieczór, ciepłe światło latarni i ognisk.
## Polany: winnica (rzędy winorośli na kratach z przejściami, kosze, suszarnie, strach na wróble), tłocznia (wielka
## prasa, kadzie, beczki z kranem, rozlane wino), biesiada (wielki stół przy ognisku, stoliki, poduchy, rożen),
## tany (słup majowy w kręgu tyczek ze wstążkami, altana z muzykami, lira i fletnia), sad (siatka jabłoni, grusz
## i bzu), zagroda kóz (płot wokół koryta i paśnika, kozy), obóz (namioty i szałasy wokół rożna) i źródło wina
## (fontanna z satyrem w kręgu pałek i brzóz, świetliki). Wejście: łuk z winorośli i latarnie przy płomieniach
## Watry; polana strażnika: tron Króla Satyrów za skarbcem, totemy z kozią czaszką, bożek, krąg latarni i wstążek.
## Na licu klifów zwisa winorośl, wzdłuż ścieżek stoją latarnie, a przy rozstajach drogowskazy.
## Grafiki: assets/dungeons/vineyard/ (tools/dungeon_props.py) i wioska satyrów z Turni
## (assets/mountains/satyr/, assets/forest/props/satyr_*).

const S := "res://assets/mountains/satyr/"
const P := "res://assets/forest/props/satyr_"
## Wieczorne, ciepłe światło latarni i ognisk.
const LAMP := Color(1.0, 0.72, 0.38, 0.5)
const FIRE := Color(1.0, 0.55, 0.2, 0.55)
## Świetliki nad sadem i źródłem.
const FIREFLY := Color(0.85, 1.0, 0.5)
const BONFIRE := preload("res://scenes/props/mountains/satyr/bonfire.tscn")
const FLOOR_DECALS := {"grapes": 1.2, "wine_spill": 0.8, "leaves": 1.6, "flowers": 2.0, "grape_skins": 0.8,
		"hoofprints": 1.0, "stones": 1.0, "shards": 0.5}
const LINES := {
	"vines": {"n": ["trellis", "", "raisin_rack", "trellis", ""], "w": ["grape_crate", ""], "e": ["", "basket_tipped"],
			"s": ["", "grape_crate", "", "trellis"]},
	"press": {"n": ["barrel_rack", "", "tapped_barrel", "barrel_tower", ""], "w": ["grape_crate", "", S + "keg"],
			"e": [S + "barrel_pile", "", "amphora_stand"], "s": ["", "tapped_barrel", "", S + "keg"]},
	"feast": {"n": ["lantern_post", "", "table", "", "wineskins", ""], "w": ["cushions", "", "bench"], "e": ["bench", "", "cushions"],
			"s": ["", "jug", "", "goblets"]},
	"dance": {"n": ["ribbon_pole", "", "lantern_post", ""], "w": ["cushions", "", "ribbon_pole"], "e": ["ribbon_pole", "", "cushions"],
			"s": ["", "lantern_post", ""]},
	"orchard": {"n": ["elder", "", S + "ladder_basket", ""], "w": ["", "mushrooms"], "e": ["mushrooms", ""], "s": ["", "basket_tipped", ""]},
	"goats": {"n": ["hay_rack", "", P + "hay", ""], "w": [S + "fence", ""], "e": [S + "fence", ""], "s": ["", P + "hay", ""]},
	"camp": {"n": ["firewood", "", "wineskins", ""], "w": ["bench", ""], "e": ["", "firewood"], "s": ["", P + "drums", ""]},
	"pond": {"n": ["birch", "", "cattails", ""], "w": ["cattails", "", "birch"], "e": ["birch", "", "cattails"], "s": ["", "cattails", ""]},
	"start": {"n": ["", "", "barrel_cart", ""], "w": [S + "barrel_pile", ""], "e": ["", "amphora_stand"], "s": []},
	"boss": {"n": ["ribbon_pole", "", "lantern_post", ""], "w": ["idol", "", "lantern_post"], "e": ["idol", "", "lantern_post"],
			"s": ["", "ribbon_pole", ""]},
	"event": {"n": ["lantern_post", "", ""], "w": ["", "ribbon_pole"], "e": ["", "ribbon_pole"], "s": []},
}


func lines() -> Dictionary:
	return LINES


func floor_decals() -> Dictionary:
	return FLOOR_DECALS


func low_props() -> Array:
	return ["grape_crate", "basket_tipped", "cushions", "bench", "jug", "goblets", "mushrooms", "firewood", "tapped_barrel",
			"hay_rack", S + "keg", S + "barrel_pile", S + "ladder_basket", P + "hay", P + "drums", S + "fence"]


func line_lights() -> Dictionary:
	return {"lantern_post": [LAMP, Vector2(160, 120), Vector2(0, -38)]}


func event_pillars() -> Array:
	return ["ivy_pillar", "pergola_post"]


func build() -> void:
	super.build()
	_trail_lights()
	_scatter()


## Czy wierzchołek i jego czterej sąsiedzi są wolną podłogą (drzewo sadu nie zamknie przejścia).
func _open_cross(v: Vector2i) -> bool:
	for step: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _floor_at(v + step) or _used.has(v + step):
			return false
	return true


## Ślady wiecznego święta na wolnej trawie polan: nakładki (winogrona, liście, kwiaty, rozlane wino) i porzucone
## drobiazgi (dzbany, kielichy, bukłaki, kosze).
func _scatter() -> void:
	var small := ["jug", "goblets", "wine_skin", "basket_tipped", "mushrooms", "grape_crate", "wreath", S + "amphora"]
	for room in d.rooms:
		if room == d.start_room:
			continue
		for x in range(room.position.x - 1, room.end.x + 1):
			for y in range(room.position.y - 1, room.end.y + 1):
				var v := Vector2i(x, y)
				if not _floor_at(v) or _used.has(v):
					continue
				var roll := rng.randf()
				if roll < 0.1:
					_decal(d._pick(FLOOR_DECALS), _px(v) + _jitter(20) + Vector2(0, 10))
				elif roll < 0.14:
					_used[v] = true
					_prop(_pick(small), _px(v) + _jitter(16) + Vector2(0, 16))


## Lico klifu: zwisająca winorośl.
func _dress_wall(run: Array[Vector2i]) -> void:
	for v in run:
		if rng.randf() < 0.35:
			_decal(P + "vines", _px(v) + Vector2(0, -12)).z_index = 1


## Latarnie wzdłuż krętych ścieżek (co kilka kroków, na przemian po obu stronach) i drogowskazy na ich końcach.
func _trail_lights() -> void:
	for trail: PackedVector2Array in d._trails:
		var side := 1.0
		for i in range(4, trail.size() - 4, 9):
			var dir := (trail[i + 1] - trail[i - 1]).normalized()
			var spot := (trail[i] + Vector2(0.5, 0.5) + dir.orthogonal() * side * 1.05) * Dungeon.CELL
			side = -side
			var v := Vector2i((spot / Dungeon.CELL).round())
			if d._label(v) != "l" or d.solid.has(v) or _used.has(v) or d.rooms.any(func(r: Rect2i) -> bool: return r.grow(1).has_point(v)):
				continue
			_used[v] = true
			_prop("lantern_post", spot + Vector2(0, 14), false)
			_light(spot - Vector2(0, 22), LAMP, Vector2(150, 110))
		if trail.size() > 12 and rng.randf() < 0.5:
			var spot := (trail[3] + Vector2(1.3, 0.2)) * Dungeon.CELL
			if not d._blocked(spot, 6.0):
				_prop("signpost", spot)


## Duży rekwizyt na środku polany; gdy środek nie jest wolny - bez kolizji.
func _centerpiece(name: String, mid: Vector2i, collision: Vector2) -> void:
	if _isolated(mid):
		_solid(name, mid, collision, false)
	else:
		_used[mid] = true
		_prop(name, _px(mid) + Vector2(0, 20), false)


## Wielkie ognisko (animowane, z kolizją) na wierzchołku `v`.
func _bonfire(v: Vector2i) -> void:
	d.solid[v] = true
	_used[v] = true
	var fire: Node2D = BONFIRE.instantiate()
	fire.position = _px(v) + Vector2(0, 14)
	w.entities.add_child(fire)
	_light(_px(v), FIRE, Vector2(320, 230))


## Krąg rzeczy wokół `at` (elipsa o promieniach `radius`) na wolnej podłodze polany.
func _ring(at: Vector2, radius: Vector2, count: int, names: Array, decals := false) -> void:
	for i in count:
		var angle := TAU * i / count + 0.3
		var spot := at + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var v := Vector2i((spot / Dungeon.CELL).round())
		if not _floor_at(v) or d._blocked(spot, 8.0):
			continue
		if decals:
			_decal(_pick(names), spot)
		else:
			_prop(_pick(names), spot)


## Drobiazg w przejściu między rzędami siatki.
func _litter(v: Vector2i, props: Array, chance := 0.25) -> void:
	if rng.randf() < chance:
		_used[v] = true
		_prop(_pick(props), _px(v) + _jitter(10) + Vector2(0, 20))


## Rekwizyt z kolizją, gdy wierzchołek ma wolne otoczenie.
func _maybe_solid(name: String, v: Vector2i, collision: Vector2) -> void:
	if _isolated(v):
		_solid(name, v, collision)


# ---------------------------------------------------------------- scenki
## Wejście: łuk z winorośli pod płomieniami Watry, po bokach latarnie, beczki i wózek.
func _start(room: Rect2i) -> void:
	var mid := _center(room)
	var gate := Vector2i(mid.x, room.position.y + 3)
	if _floor_at(gate):
		_used[gate] = true
		_prop(P + "arch", _px(gate) + Vector2(0, 16), false)
	for dx in [-2, 2]:
		var v := Vector2i(mid.x + dx, room.position.y + 1)
		if _floor_at(v):
			_used[v] = true
			_prop("lantern_post", _px(v) + Vector2(0, 14), false)
			_light(_px(v) - Vector2(0, 24), LAMP, Vector2(160, 120))
	_ring(_px(mid) + Vector2(0, 40), Vector2(110, 60), 6, ["flowers", "leaves", "grapes"], true)


## Polana strażnika: tron Króla Satyrów za skarbcem, po bokach totemy z kozią czaszką, poduchy, rozlane wino,
## krąg latarni i tyczek ze wstążkami.
func _boss(room: Rect2i) -> void:
	var mid := _center(room)
	var top := Vector2i(mid.x, room.position.y)
	_used[top] = true
	_prop(S + "throne", _px(top) + Vector2(0, 2), false)
	for dx in [-2, 2]:
		var v := Vector2i(mid.x + dx, room.position.y + 1)
		if _floor_at(v):
			_used[v] = true
			_prop("goat_totem", _px(v) + Vector2(0, 10), false)
			_prop("cushions", _px(v) + Vector2(-dx * 14, 34))
	_ring(_px(mid) + Vector2(0, 30), Vector2(room.size.x * 26.0, room.size.y * 22.0), 8, ["lantern_post", "ribbon_pole"])
	_ring(_px(mid) + Vector2(0, 30), Vector2(90, 60), 5, ["wine_spill", "grape_skins", "grapes"], true)
	_light(_px(mid) + Vector2(0, 30), Color(LAMP, 0.3), Vector2(420, 300), false)


## Winnica: poziome rzędy winorośli co dwa wierzchołki z przejściem co cztery krzewy; w przejściach kosze,
## skrzynki winogron i wózek, na skraju strach na wróble.
func _vines(room: Rect2i) -> void:
	for y in range(room.position.y + 1, room.end.y - 1, 2):
		var n := 0
		for x in range(room.position.x, room.end.x):
			var v := Vector2i(x, y)
			n += 1
			if n % 4 == 0 or not _floor_at(v) or _used.has(v):
				continue
			if not _floor_at(v + Vector2i.UP) or not _floor_at(v + Vector2i.DOWN):
				continue
			_solid(S + ("vine_row" if rng.randf() < 0.5 else "vine_row_2"), v, Vector2(42, 8))
		for x in range(room.position.x, room.end.x):
			var v := Vector2i(x, y + 1)
			if _floor_at(v) and not _used.has(v):
				_litter(v, [S + "grape_basket", "basket_tipped", "grape_crate", S + "grape_cart", "grapes"], 0.2)
	var corner: Vector2i = _corners(room)[rng.randi() % 4]
	if _floor_at(corner) and not _used.has(corner):
		_used[corner] = true
		_prop("scarecrow", _px(corner) + Vector2(0, 16))


## Tłocznia: wielka prasa albo kadź na środku, po bokach kadzie z winogronami i do deptania, beczki z kranem, rozlane wino
## i wytłoczyny.
func _press(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece(_pick(["wine_press", "giant_vat"]), mid, Vector2(70, 22))
	_light(_px(mid), Color(LAMP, 0.35), Vector2(280, 200), false)
	var pieces := {Vector2i(-2, 0): S + "stomp_tub", Vector2i(2, 0): "grape_vat", Vector2i(-2, 2): "tapped_barrel",
			Vector2i(2, 2): "press_small", Vector2i(0, 2): S + "stomp_tub"}
	for step: Vector2i in pieces:
		_maybe_solid(pieces[step], mid + step, Vector2(28, 8))
	_ring(_px(mid) + Vector2(0, 40), Vector2(80, 50), 7, ["wine_spill", "grape_skins", "grapes"], true)


## Biesiada: wielki stół z jadłem przy ognisku, wokół stoliki, poduchy, rożen, dzbany i kielichy.
func _feast(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece(S + "banquet", mid, Vector2(76, 20))
	var fire := mid + Vector2i(0, 2) if room.size.y >= 6 else mid + Vector2i(-3, 0)
	if _isolated(fire):
		_bonfire(fire)
	for step: Vector2i in [Vector2i(-3, 1), Vector2i(3, 1)]:
		_maybe_solid(_pick(["table", "roast_spit"]), mid + step, Vector2(34, 8))
	_ring(_px(mid) + Vector2(0, 30), Vector2(room.size.x * 26.0, room.size.y * 24.0), 8,
			["cushions", "jug", "goblets", S + "amphora", "wine_skin"])
	_ring(_px(mid) + Vector2(0, 30), Vector2(100, 70), 5, ["wine_spill", "grapes"], true)


## Tany: słup majowy na środku w kręgu tyczek ze wstążkami, pod północnym brzegiem altana z muzykami (lira,
## fletnia, bębny).
func _dance(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece(P + "maypole", mid, Vector2(10, 6))
	_ring(_px(mid) + Vector2(0, 16), Vector2(110, 80), 6, ["ribbon_pole", S + "wreath_pole"])
	var stage := Vector2i(mid.x, room.position.y + 1)
	if _floor_at(stage) and not _used.has(stage):
		_used[stage] = true
		_prop("gazebo", _px(stage) + Vector2(0, 30), false)
		_prop("lyre", _px(stage) + Vector2(-60, 40))
		_prop(P + "drums", _px(stage) + Vector2(56, 40))
	_ring(_px(mid) + Vector2(0, 20), Vector2(70, 50), 5, ["hoofprints", "flowers", "wreath", "pan_flute"], true)
	_light(_px(mid), Color(LAMP, 0.35), Vector2(300, 220), false)
	_motes(_px(mid) + Vector2(0, -20), Vector2(90, 50), 10, Color(1.0, 0.85, 0.5))


## Sad: drzewa co drugi wierzchołek w obu kierunkach (jabłonie, grusze, bez - przejścia między nimi zostają),
## w przejściach kosze, drabiny i grzyby, świetliki.
func _orchard(room: Rect2i) -> void:
	var i := 0
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y + 1, room.end.y):
			var v := Vector2i(x, y)
			if not _floor_at(v) or _used.has(v):
				continue
			if (x - room.position.x) % 2 == 1 and (y - room.position.y) % 2 == 0 and _open_cross(v):
				_solid(S + "apple_tree" if i % 3 != 2 else S + "pear_tree" if i % 2 == 0 else "elder", v, Vector2(12, 8))
				i += 1
			else:
				_litter(v, [S + "grape_basket", S + "ladder_basket", "mushrooms", "basket_tipped"], 0.12)
	_motes(_px(_center(room)), Vector2(room.size.x * 24.0, room.size.y * 20.0), 12, FIREFLY)


## Zagroda kóz: płot wokół środka polany (z furtką na południu), w środku koryto i paśnik z sianem, kozy.
func _goats(room: Rect2i) -> void:
	var mid := _center(room)
	for dx in range(-2, 3):
		for dy in [-1, 2]:
			var v := mid + Vector2i(dx, dy)
			if dy == 2 and dx == 0:
				continue
			if _floor_at(v) and not _used.has(v):
				_solid(S + "fence", v, Vector2(44, 6), false)
	_centerpiece(S + "trough", mid, Vector2(30, 6))
	var rack := mid + Vector2i(1, 1)
	if _floor_at(rack) and not _used.has(rack):
		_used[rack] = true
		_prop("hay_rack", _px(rack) + Vector2(0, 12))
	_ring(_px(mid) + Vector2(0, 40), Vector2(120, 50), 6, ["hoofprints", "hoofprints", "stones"], true)
	for i in rng.randi_range(3, 5):
		var spot := _px(mid) + Vector2(rng.randf_range(-90, 90), rng.randf_range(10, 60))
		w._add_goblin_spawn({"type": "goat", "position": d._free_spot(spot, _px(mid)), "sitting": false, "look_at": _px(mid), "level": d.level})


## Obóz: namioty i szałasy wokół rożna, ławy, drewno na opał, bębny.
func _camp(room: Rect2i) -> void:
	var mid := _center(room)
	_used[mid] = true
	_prop("roast_spit", _px(mid) + Vector2(0, 20), false)
	_light(_px(mid) + Vector2(0, 4), FIRE, Vector2(260, 190))
	for i in 5:
		var angle := TAU * i / 5.0 - PI / 2.0
		var v := mid + Vector2i(roundi(cos(angle) * 2.4), roundi(sin(angle) * 2.0))
		_maybe_solid(P + ("tent" if i % 2 == 0 else "hut"), v, Vector2(32, 8))
	_ring(_px(mid) + Vector2(0, 16), Vector2(70, 50), 5, ["bench", "firewood", P + "drums", "wine_skin"])


## Źródło wina: fontanna z satyrem na środku, wokół pałki, brzozy, kamienie i rozlane wino, świetliki.
func _pond(room: Rect2i) -> void:
	var mid := _center(room)
	_centerpiece("fountain", mid, Vector2(80, 26))
	_light(_px(mid) + Vector2(0, -10), Color(1.0, 0.4, 0.5, 0.35), Vector2(240, 170), false)
	_ring(_px(mid) + Vector2(0, 30), Vector2(130, 80), 8, ["cattails", "birch", "offering_altar", "cattails"])
	_ring(_px(mid) + Vector2(0, 30), Vector2(80, 54), 6, ["wine_spill", "stones", "flowers"], true)
	_motes(_px(mid), Vector2(110, 70), 14, FIREFLY)
