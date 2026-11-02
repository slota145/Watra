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
## Na licu klifów zwisa winorośl, na poboczu ścieżek stoją latarnie; na samych ścieżkach nic nie stoi.
## Pola winorośli rosną też na terenie niedostępnym (Dungeon._vine_fields).
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
## Nakładki na trawę tylko drobne i naturalne - ślady święta (wino, winogrona) leżą wyłącznie w scenkach.
const FLOOR_DECALS := {"flowers": 1.0}
const LINES := {
	"vines": {"n": ["", "", "raisin_rack", "", "", ""], "s": ["", "", "grape_crate", "", ""]},
	"press": {"n": ["barrel_rack", "", "tapped_barrel", "barrel_tower", ""], "w": ["grape_crate", "", S + "keg"],
			"e": [S + "barrel_pile", "", "amphora_stand"], "s": ["", "tapped_barrel", "", S + "keg"]},
	"feast": {"n": ["lantern_post", "", "table", "", "wineskins", ""], "w": ["bench", "", ""], "e": ["", "", "bench"],
			"s": ["", "jug", "", "goblets"]},
	"dance": {"n": ["ribbon_pole", "", "lantern_post", ""], "w": ["", "", "ribbon_pole"], "e": ["ribbon_pole", "", ""],
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
	# nic nie staje na ścieżce ani przy klifie: wierzchołki, przez których środek biegnie ubita ziemia, sąsiedzi
	# klifów (lico i krawędź półki zachodzą na ich komórki) i rząd pod nimi są zajęte od początku
	for v: Vector2i in d.floor_cells:
		if d.path_tiles.has(Vector2i(_px(v) / w.TILE)) or d.near_cliff(v) or d.near_cliff(v + Vector2i.UP):
			_used[v] = true
	super.build()
	_trail_lights()
	_lone_trees()
	# szerokie miejsca przy ścieżkach poza polanami też obsadzone winoroślą
	_vine_strips(Rect2i(Vector2i.ZERO, Dungeon.GRID), S + "vine_row", 2, func(v: Vector2i) -> bool:
			return not d.rooms.any(func(r: Rect2i) -> bool: return r.grow(1).has_point(v)) and not d.altar_room.grow(1).has_point(v))


## Rekwizyt stojący; wysoki (ponad 40 px) nie staje tuż pod klifem ani dwa rzędy niżej - wystawałby na lico
## albo na szczyt półki (zwraca wtedy null).
func _prop(name: String, pos: Vector2, flip := true) -> Sprite2D:
	if _tex(name).get_height() > 40:
		var v := Vector2i((pos / Dungeon.CELL).round())
		for k in 3:
			if d.cliffs.has(v + Vector2i.UP * k) or d.near_cliff(v + Vector2i.UP * k):
				return null
	return super._prop(name, pos, flip)


## Pojedyncze drzewa na wolnej łące (poza polanami ze scenkami): wierzchołek z wolnym otoczeniem, z dala od ścieżki.
func _lone_trees() -> void:
	var trees := ["res://assets/forest/trees/oak_1.png", "res://assets/forest/trees/oak_4.png", "birch", "poplar",
			S + "apple_tree", S + "pear_tree"]
	for x in Dungeon.GRID.x:
		for y in Dungeon.GRID.y:
			var v := Vector2i(x, y)
			if rng.randf() < 0.07 and _isolated(v) and _clear_of_path(_px(v) + Vector2(0, 16), 40.0) \
					and not d.near_cliff(v + Vector2i.UP) and not d.near_cliff(v + Vector2i.UP * 2) \
					and not d.rooms.any(func(r: Rect2i) -> bool: return r.grow(-1).has_point(v)):
				_solid(_pick(trees), v, Vector2(12, 8))


## Czy pas szerokości 2 * `half` px wokół punktu (na wysokości podstawy rekwizytu) omija ubitą ziemię ścieżki.
func _clear_of_path(pos: Vector2, half: float) -> bool:
	for dx in range(-int(half), int(half) + 1, 8):
		for dy in [-8, 0, 8]:
			if d.path_tiles.has(Vector2i((pos + Vector2(dx, dy)) / w.TILE)):
				return false
	return true


## Czy wierzchołek i jego czterej sąsiedzi są wolną podłogą (drzewo sadu nie zamknie przejścia).
func _open_cross(v: Vector2i) -> bool:
	for step: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _floor_at(v + step) or _used.has(v + step):
			return false
	return true


## Lico klifu: zwisająca winorośl.
func _dress_wall(run: Array[Vector2i]) -> void:
	for v in run:
		if rng.randf() < 0.35:
			_decal(P + "vines", _px(v) + Vector2(0, -12)).z_index = 1


## Latarnie na poboczu krętych ścieżek: co kilka kroków, na przemian po obu stronach, na skraju pierwszego
## niedostępnego wierzchołka obok ścieżki (drzewa albo pole winorośli) - nigdy na samej ścieżce.
func _trail_lights() -> void:
	for trail: PackedVector2Array in d._trails:
		var side := 1.0
		for i in range(5, trail.size() - 5, 8):
			var at := trail[i] + Vector2(0.5, 0.5)
			var across := (trail[i + 1] - trail[i - 1]).normalized().orthogonal() * side
			side = -side
			for k in range(1, 4):
				var v := Vector2i((at + across * k).round())
				if d.floor_cells.has(v):
					continue
				if not d.waters.has(v) and not d.cliffs.has(v) and not d.near_cliff(v) and not _sconces.has(v):
					_sconces[v] = true
					var spot := _px(v) - across * 26.0 + Vector2(0, 18)
					_prop("lantern_post", spot, false)
					_light(spot - Vector2(0, 40), LAMP, Vector2(150, 110))
				break


## Duży rekwizyt na środku polany; gdy środek nie jest wolny - bez kolizji.
func _centerpiece(name: String, mid: Vector2i, collision: Vector2) -> void:
	if _isolated(mid):
		_solid(name, mid, collision, false)
	elif not d.near_cliff(mid):
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
		if not _floor_at(v) or d._blocked(spot, 8.0) or not _clear_of_path(spot, 20.0) or d.near_cliff(v):
			continue
		if decals:
			_decal(_pick(names), spot)
		else:
			_prop(_pick(names), spot)


## Drobiazg w przejściu między rzędami siatki.
func _litter(v: Vector2i, props: Array, chance := 0.25) -> void:
	if rng.randf() < chance and _clear_of_path(_px(v) + Vector2(0, 20), 20.0):
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
	_ring(_px(mid) + Vector2(0, 40), Vector2(110, 60), 6, ["flowers", "leaves", "flowers"], true)


## Polana strażnika: tron Króla Satyrów za skarbcem, po bokach totemy z kozią czaszką i poduchy, krąg latarni
## i tyczek ze wstążkami.
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
	_light(_px(mid) + Vector2(0, 30), Color(LAMP, 0.3), Vector2(420, 300), false)


## Winnica: polanę wypełniają długie, równe pasy winorośli (co drugi rząd wierzchołków po dwa rzędy krzewów, krzew
## co 40 px), pas kończy się na skraju polany i przy ścieżce, co kilka wierzchołków poprzeczne przejście.
## W przejściach między pasami kosze i skrzynki z zebranymi winogronami, na skraju strach na wróble.
func _vines(room: Rect2i) -> void:
	_vine_strips(room.grow(1), S + ("vine_row" if rng.randf() < 0.5 else "vine_row_2"), rng.randi_range(0, 4))
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			var v := Vector2i(x, y)
			if posmod(y, 2) == 0 and _floor_at(v) and not _used.has(v) and rng.randf() < 0.08:
				_used[v] = true
				_prop(_pick([S + "grape_basket", "grape_crate", S + "ladder_basket"]), _px(v) + Vector2(rng.randf_range(-14, 14), 18))
	var corner: Vector2i = _corners(room)[rng.randi() % 4]
	if _floor_at(corner) and not _used.has(corner):
		_used[corner] = true
		_prop("scarecrow", _px(corner) + Vector2(0, 16))


## Pasy winorośli w obszarze `area`: co drugi rząd wierzchołków (nieparzyste y) przez wolną podłogę z podłogą nad
## i pod pasem, co pięć wierzchołków poprzeczne przejście (od `cross`), pas kończy się na skraju i przy ścieżce,
## z dala od klifów (krzewy są wysokie - pas tuż pod klifem zachodziłby na lico).
## `allow` (wierzchołek -> bool) zawęża, gdzie pas może biec.
func _vine_strips(area: Rect2i, kind: String, cross: int, allow := Callable()) -> void:
	for y in range(area.position.y, area.end.y):
		if posmod(y, 2) == 0:
			continue
		var run: Array[Vector2i] = []
		for x in range(area.position.x, area.end.x + 1):
			var v := Vector2i(x, y)
			var on: bool = x < area.end.x and _floor_at(v) and not _used.has(v) and posmod(x - cross, 5) != 0 \
					and _floor_at(v + Vector2i.UP) and _floor_at(v + Vector2i.DOWN) and not d.near_cliff(v + Vector2i.UP) \
					and (not allow.is_valid() or allow.call(v))
			if on:
				run.append(v)
			elif not run.is_empty():
				_vine_row(kind, run)
				run = []


## Pas winorośli przez kolejne wierzchołki `run`: dwa rzędy krzewów w równych odstępach (gęsto jak na polach
## za skrajem polany), jedna kolizja na cały pas, wierzchołki zajęte (potwory obchodzą pas przejściami).
func _vine_row(kind: String, run: Array[Vector2i]) -> void:
	if run.size() < 2:
		return
	var from := _px(run[0]).x - 30.0
	var to := _px(run[-1]).x + 30.0
	var y := _px(run[0]).y
	for row_y in [y - 10.0, y + 30.0]:
		d.vine_run(_tex(kind), from, to, row_y, false)
	for v in run:
		d.solid[v] = true
		_used[v] = true
	var body := StaticBody2D.new()
	body.position = Vector2((from + to) / 2.0, y + 6.0)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(to - from - 8.0, 44.0)
	shape.shape = box
	body.add_child(shape)
	w.entities.add_child(body)


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
	_ring(_px(mid) + Vector2(0, 40), Vector2(80, 50), 5, ["wine_spill", "grape_skins"], true)


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
			["bench", "jug", S + "amphora", S + "keg"])
	_ring(_px(mid) + Vector2(0, 30), Vector2(100, 70), 4, ["wine_spill", "goblets"], true)


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


## Zagroda kóz: płot wokół wolnego od ścieżek miejsca polany (z furtką na południu), w środku koryto i paśnik
## z sianem, kozy.
func _goats(room: Rect2i) -> void:
	var mid := _pen_spot(room)
	if mid.x < 0:
		return
	for dx in range(-2, 3):
		for dy in [-1, 2]:
			var v := mid + Vector2i(dx, dy)
			if dy == 2 and dx == 0:
				continue
			if _floor_at(v) and not _used.has(v) and _clear_of_path(_px(v) + Vector2(0, 10), 26.0):
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


## Środek zagrody: wierzchołek polany (najbliżej środka), wokół którego cały prostokąt płotu leży na wolnej podłodze
## z dala od ścieżki i klifów; (-1, -1), gdy takiego miejsca nie ma (polana zostaje bez zagrody).
func _pen_spot(room: Rect2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			var mid := Vector2i(x, y)
			var ok := true
			for dx in range(-2, 3):
				for dy in range(-1, 3):
					var v := mid + Vector2i(dx, dy)
					if not _floor_at(v) or _used.has(v):
						ok = false
			ok = ok and _clear_of_path(_px(mid) + Vector2(0, 10), 170.0) and _clear_of_path(_px(mid) + Vector2(0, 74), 170.0) \
					and _clear_of_path(_px(mid) + Vector2(0, 138), 170.0) and _clear_of_path(_px(mid) - Vector2(0, 54), 170.0)
			var dist := (mid - _center(room)).length_squared()
			if ok and dist < best_d:
				best_d = dist
				best = mid
	return best


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
