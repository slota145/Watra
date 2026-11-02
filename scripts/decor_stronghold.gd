class_name StrongholdDecor
extends DungeonDecor
## Wystrój Oblężonego grodu - drugiego lochu na zewnątrz (Dungeon.outdoor): gród zdobyty i spalony przez hordę
## koboldów. Granicą polan jest palisada (Dungeon._build_palisade), a za nią zagrody: spalone i ocalałe chaty,
## stodoły, wozy, siano i drewno na podwórzach (_yards), nad zgliszczami dym i tlący się żar. Na palisadzie
## wieże strażnicze, przy ścieżkach pochodnie (nic nie stoi na samych ścieżkach).
## Polany: brama i wyłom (łuk bramy z ocalałym kawałkiem palisady i wieżami, z drugiej strony wyłom ze złamanymi
## palami, rusztowaniem, lejami po bombach i taranem z belek), spalone zagrody (zgliszcza chat, połamane płoty,
## przewrócone wozy, żar i dym), obóz koboldów (namioty ze skór wokół ogniska, skrzynie bomb, beczki prochu, łupy,
## totemy i czaszki na palach) i plac - majdan (studnia, rozbite kramy, manekiny, stojaki z bronią, chorągwie).
## Wejście: ostatni obóz obrońców przy płomieniach Watry; polana strażnika: spalony dwór, a przed nim barykada
## z prochu Bombardiera Kaszlaka.
## Grafiki: Ostoja (assets/village/), Kopalnia goblinów (assets/dungeons/mine/) i Pola Zbożowe (assets/fields/).

const M := "res://assets/dungeons/mine/"
const F := "res://assets/fields/"
const TORCH := Color(1.0, 0.6, 0.3, 0.5)
const FIRE := Color(1.0, 0.5, 0.18, 0.55)
const EMBER := Color(1.0, 0.55, 0.2)
## Zgliszcza: osmalone drewno.
const BURNT := Color(0.62, 0.54, 0.5)
const BONFIRE := preload("res://scenes/props/mountains/satyr/bonfire.tscn")
## Chaty za palisadą: [grafika, szerokość w wierzchołkach (1 albo 3), kolizja nieistotna - teren i tak niedostępny].
const HOUSES := [["cottage_0", 1], ["cottage_1", 1], ["smokehouse", 1], ["pig_shelter", 1], ["lean_to", 1],
		[F + "farmhouse", 3], [F + "barn", 3], ["stable", 3], ["infirmary", 3], ["bathhouse", 3], ["jeweler_hut", 3],
		["forge_shed", 3], ["chapel", 3]]
## Ogródki przy chatach i drobiazgi na podwórzach.
const GARDENS := ["garden", "tilled_plot", "tilled_bed", "herb_garden"]
const YARD_CLUTTER := ["hay", "hay_pile", "firewood", "cart", "handcart", "crate", "barrel", "trough", "grain_sacks",
		"chop_block", "deco_wheelbarrow", "sack", "water_trough", "clothesline", "deco_wood_shelter", "deco_beehive",
		"deco_kennel", "deco_chickens", "deco_washing_line", "deco_fence", "pen_fence_h"]
## Najwięcej dymów w lochu (cząsteczki kosztują).
const MAX_SMOKE := 18
const LINES := {
	"burned": {"s": ["", M + "broken_beams", "", "", "hay", ""], "w": ["", "firewood", ""], "e": ["", F + "sacks", ""]},
	"camp": {"s": ["", M + "bomb_crate", "", M + "powder_barrels", "", ""], "w": [M + "skull_stick", "", ""],
			"e": ["", "", M + "skull_stick"]},
	"gate": {"s": ["", "stake_pile", "", "", "stake_fallen", ""], "w": ["", "stake_fallen", ""], "e": ["stake_pile", "", ""]},
	"square": {"s": ["", "barrel", "", "crate", "", ""], "w": ["", "banner", ""], "e": ["", "", "banner"]},
	"start": {"s": ["", "refugee_tent_0", "", "", "crate", ""], "w": ["", "sack"], "e": ["barrel", ""]},
	"boss": {"s": ["", M + "powder_stack", "", M + "bomb_crate", ""], "w": [M + "totem", "", ""], "e": ["", "", M + "totem"]},
	"event": {"w": ["", M + "banner_pole"], "e": [M + "banner_pole", ""]},
}

var _smokes := 0


func lines() -> Dictionary:
	return LINES


func low_props() -> Array:
	return ["stake_pile", "stake_fallen", "hay", "firewood", "barrel", "crate", "sack", F + "sacks", M + "bomb_crate"]


func event_pillars() -> Array:
	return [M + "pillar"]


func build() -> void:
	# na ścieżkach nic nie stoi: wierzchołki, przez których środek biegnie ubita ziemia, są zajęte od początku
	for v: Vector2i in d.floor_cells:
		if d.path_tiles.has(Vector2i(_px(v) / w.TILE)):
			_used[v] = true
	super.build()
	_yards()
	_towers()
	_trail_torches()


# ---------------------------------------------------------------- pomocnicy
## Rekwizyt z klatkami (wieża, pochodnia): losowa klatka, a pochodnia migocze.
func _framed(name: String, pos: Vector2, frames: int, collision := Vector2.ZERO) -> Sprite2D:
	var sprite: Sprite2D = w._village_prop(_tex(name), pos.round(), collision, frames)
	sprite.frame = rng.randi() % frames
	return sprite


## Pochodnia na stojaku (2 klatki, migocze) ze światłem.
func _torch(pos: Vector2) -> void:
	var torch := _framed("torch_stand", pos, 2)
	w._flicker(torch)
	_light(pos - Vector2(0, 30), TORCH, Vector2(150, 110))


## Spalony rekwizyt: osmalony kolor.
func _burnt(sprite: Sprite2D) -> void:
	if sprite != null:
		sprite.modulate = BURNT


## Dym unoszący się nad zgliszczami (najwyżej MAX_SMOKE w lochu).
func _smoke(at: Vector2) -> void:
	if _smokes >= MAX_SMOKE:
		return
	_smokes += 1
	var smoke := CPUParticles2D.new()
	smoke.position = at
	smoke.amount = 10
	smoke.lifetime = 5.0
	smoke.preprocess = 5.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(14, 4)
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 18.0
	smoke.gravity = Vector2(4, -2)
	smoke.initial_velocity_min = 8.0
	smoke.initial_velocity_max = 14.0
	smoke.scale_amount_min = 5.0
	smoke.scale_amount_max = 9.0
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.5, 0.48, 0.46, 0.0), Color(0.52, 0.5, 0.48, 0.5), Color(0.6, 0.58, 0.56, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	smoke.color_ramp = fade
	smoke.z_index = 20
	w.add_child(smoke)


## Tlący się żar na ziemi: mały pierścień płomieni z migoczącym światłem.
func _embers(at: Vector2, radius := 12.0) -> void:
	var fire := WorldVfx.burning("fire", radius)
	fire.position = at.round()
	w.entities.add_child(fire)
	_light(at, FIRE, Vector2(radius * 9.0, radius * 6.5))


## Krąg rzeczy wokół `at` (elipsa o promieniach `radius`) na wolnej podłodze polany, z dala od ścieżki.
func _ring(at: Vector2, radius: Vector2, count: int, names: Array, decals := false) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	for i in count:
		var angle := TAU * i / count + 0.3
		var spot := at + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		var v := Vector2i((spot / Dungeon.CELL).round())
		if not _floor_at(v) or _used.has(v) or d._blocked(spot, 8.0) or not _clear_of_path(spot, 20.0):
			continue
		out.append(_decal(_pick(names), spot) if decals else _prop(_pick(names), spot))
	return out


## Czy pas szerokości 2 * `half` px wokół punktu omija ubitą ziemię ścieżki.
func _clear_of_path(pos: Vector2, half: float) -> bool:
	for dx in range(-int(half), int(half) + 1, 8):
		for dy in [-8, 0, 8]:
			if d.path_tiles.has(Vector2i((pos + Vector2(dx, dy)) / w.TILE)):
				return false
	return true


## Rekwizyt z kolizją, gdy wierzchołek ma wolne otoczenie (zwraca null, gdy nie ma miejsca).
func _maybe_solid(name: String, v: Vector2i, collision: Vector2) -> Sprite2D:
	if _isolated(v) and _clear_of_path(_px(v) + Vector2(0, 10), 30.0):
		return _solid(name, v, collision)
	return null


## Czy wierzchołek leży głęboko za palisadą: teren palisady, a wokół żadnej polany, ścieżki ani wody (las może być).
func _deep(v: Vector2i) -> bool:
	return d.palisades.has(v) and Dungeon.STEPS.all(func(step: Vector2i) -> bool:
			return not d.floor_cells.has(v + step) and not d.waters.has(v + step))


# ---------------------------------------------------------------- za palisadą
## Zagrody za palisadą: gęsta zabudowa - chaty w siatce co około 88 px (rzędy na przemian przesunięte, z drgnięciem)
## na terenie głęboko za palisadą, bez polany dwa rzędy wyżej (wysoki dach nie zachodzi na polanę); duże (dwór,
## stodoła, stajnia, kuźnia...) tam, gdzie zmieszczą się trzy wierzchołki. Część spalona - osmalona, z dymem i żarem.
## Pod małymi chatami ogródki, w wolnych miejscach co 40 px siano, wozy, drewno, płotki, skrzynie i zwęglone drzewa.
## Teren jest niedostępny, więc nic nie ma kolizji.
func _yards() -> void:
	var houses: Array[Rect2] = []
	var free := func(rect: Rect2) -> bool:
		return not houses.any(func(other: Rect2) -> bool: return other.intersects(rect))
	var row := 0
	for py in range(-Dungeon.CELL / 2, Dungeon.GRID.y * Dungeon.CELL, 84):
		row += 1
		for px in range(-Dungeon.CELL / 2 + (row % 2) * 44, Dungeon.GRID.x * Dungeon.CELL, 88):
			var at := Vector2(px, py) + _jitter(10)
			var v := Vector2i((at / Dungeon.CELL).round())
			if not _deep(v) or d.floor_cells.has(v + Vector2i.UP * 2) or rng.randf() > 0.9:
				continue
			var big := _deep(v + Vector2i.LEFT) and _deep(v + Vector2i.RIGHT) and rng.randf() < 0.35
			var options := HOUSES.filter(func(h: Array) -> bool: return (h[1] == 3) == big)
			var house: Array = options[rng.randi() % options.size()]
			var size := Vector2(_tex(house[0]).get_size())
			var rect := Rect2(at - Vector2(size.x / 2.0 + 4.0, size.y * 0.55), Vector2(size.x + 8.0, size.y * 0.6))
			if not free.call(rect):
				continue
			houses.append(rect)
			var sprite := _prop(house[0], at)
			if rng.randf() < 0.6:
				_burnt(sprite)
				_smoke(at - Vector2(0, size.y * 0.6))
				if rng.randf() < 0.4:
					_embers(at + Vector2(rng.randf_range(-size.x / 3.0, size.x / 3.0), 10), 9.0)
			else:
				sprite.modulate = Color(0.82, 0.8, 0.78)
			# ogródek pod małą chatą
			var plot := Rect2(at + Vector2(-28, 6), Vector2(56, 40))
			if not big and d.palisades.has(Vector2i(((at + Vector2(0, 40)) / Dungeon.CELL).round())) and free.call(plot) \
					and rng.randf() < 0.5:
				houses.append(plot)
				_prop(_pick(GARDENS), at + Vector2(rng.randf_range(-6, 6), 44)).modulate = Color(0.8, 0.76, 0.72)
	for py in range(-Dungeon.CELL / 2, Dungeon.GRID.y * Dungeon.CELL, 40):
		for px in range(-Dungeon.CELL / 2, Dungeon.GRID.x * Dungeon.CELL, 40):
			var at := Vector2(px, py) + _jitter(12)
			var v := Vector2i((at / Dungeon.CELL).round())
			if not d.palisades.has(v) or not free.call(Rect2(at - Vector2(14, 20), Vector2(28, 22))):
				continue
			# przy samych palach (sąsiad - polana) tylko niskie rzeczy, a i tak rzadziej
			var edge := not _deep(v)
			var roll := rng.randf()
			if roll < (0.25 if edge else 0.42):
				var thing := _prop(_pick(YARD_CLUTTER), at)
				thing.modulate = Color(0.78, 0.74, 0.7) if rng.randf() < 0.5 else BURNT.lightened(0.25)
			elif not edge and roll < 0.47:
				var tree := _prop(_pick(["res://assets/forest/trees/oak_2.png", "res://assets/forest/trees/oak_5.png"]), at)
				tree.modulate = Color(0.32, 0.28, 0.26)
				houses.append(Rect2(at - Vector2(20, 30), Vector2(40, 32)))


## Wieże strażnicze na palisadzie: co kawałek linii, tam gdzie biegnie poziomo, a za nią (na północy) jest
## teren palisady - wieża stoi tuż za palami i nie zasłania polany.
func _towers() -> void:
	for line: PackedVector2Array in d.palisade_lines:
		var walked := 200.0 + rng.randf() * 300.0
		for i in line.size() - 1:
			var along := line[i + 1] - line[i]
			walked -= along.length()
			if walked > 0.0 or absf(along.normalized().y) > 0.3:
				continue
			var at := line[i]
			var behind := Vector2i(((at - Vector2(0, 40)) / Dungeon.CELL).round())
			if not d.palisades.has(behind) or not d.palisades.has(behind + Vector2i.UP) \
					or not d.palisades.has(behind + Vector2i.LEFT) or not d.palisades.has(behind + Vector2i.RIGHT):
				continue
			walked = rng.randf_range(520.0, 760.0)
			var tower := _framed("palisade_tower", at - Vector2(0, 6), 2)
			tower.flip_h = rng.randf() < 0.5
			tower.modulate = Color(0.85, 0.82, 0.8) if rng.randf() < 0.6 else BURNT.lightened(0.15)
			_light(at - Vector2(0, 60), Color(TORCH, 0.35), Vector2(130, 100))


## Pochodnie przy krętych ścieżkach: co kilka kroków, na przemian po obu stronach, na skraju pierwszego
## niedostępnego wierzchołka obok ścieżki (przy palisadzie albo pod drzewami) - nigdy na samej ścieżce.
func _trail_torches() -> void:
	for trail: PackedVector2Array in d._trails:
		var side := 1.0
		for i in range(6, trail.size() - 6, 11):
			var at := trail[i] + Vector2(0.5, 0.5)
			var across := (trail[i + 1] - trail[i - 1]).normalized().orthogonal() * side
			side = -side
			for k in range(1, 4):
				var v := Vector2i((at + across * k).round())
				if d.floor_cells.has(v):
					continue
				if not d.waters.has(v) and not _sconces.has(v):
					_sconces[v] = true
					var spot := _px(v) - across * 30.0 + Vector2(0, 16)
					if _clear_of_path(spot, 10.0):
						_torch(spot)
				break


# ---------------------------------------------------------------- scenki
## Wejście: ostatni obóz obrońców przy płomieniach Watry - pochodnie, rusztowanie i stos pali do naprawy palisady.
func _start(room: Rect2i) -> void:
	var mid := _center(room)
	for dx in [-2, 2]:
		var v := Vector2i(mid.x + dx, room.position.y + 1)
		if _floor_at(v) and not _used.has(v):
			_used[v] = true
			_torch(_px(v) + Vector2(0, 14))
	for corner: Vector2i in _corners(room).slice(2):
		if _floor_at(corner) and not _used.has(corner):
			_used[corner] = true
			_prop(_pick(["palisade_scaffold", "stake_pile", "refugee_tent_1"]), _px(corner) + Vector2(0, 16))


## Polana strażnika: spalony dwór pod północnym brzegiem (dym, żar), przed nim skarbiec i Bombardier Kaszlak,
## po bokach totemy i chorągwie z czaszką, wokół półkolem barykada z beczek prochu i skrzyń bomb.
func _boss(room: Rect2i) -> void:
	var mid := _center(room)
	var top := Vector2i(mid.x, room.position.y)
	_used[top] = true
	_burnt(_prop(F + "farmhouse", _px(top) + Vector2(0, -8), false))
	_smoke(_px(top) + Vector2(-20, -90))
	_smoke(_px(top) + Vector2(26, -80))
	for dx in [-2, 2]:
		var v := Vector2i(mid.x + dx, room.position.y + 1)
		if _floor_at(v) and not _used.has(v):
			_used[v] = true
			_prop(M + "banner_pole", _px(v) + Vector2(0, 10), false)
			_embers(_px(v) + Vector2(dx * 12, 44), 10.0)
	# barykada: łuk od zachodu przez południe na wschód (wejście od północy zostaje wolne)
	for i in 11:
		var angle := PI * 0.05 + PI * 0.9 * i / 10.0
		var spot := _px(mid) + Vector2(0, 30) + Vector2(cos(angle) * room.size.x * 25.0, sin(angle) * room.size.y * 20.0)
		var v := Vector2i((spot / Dungeon.CELL).round())
		if _floor_at(v) and not d._blocked(spot, 8.0) and _clear_of_path(spot, 22.0):
			_prop(_pick([M + "powder_barrels", M + "bomb_crate", M + "powder_stack", F + "powder_barrel", F + "bomb_crate"]), spot)
	_ring(_px(mid) + Vector2(0, 30), Vector2(90, 60), 6, [F + "hole", M + "rubble", F + "rubble"], true)
	_light(_px(mid) + Vector2(0, 20), Color(FIRE, 0.3), Vector2(420, 300), false)


## Brama i wyłom: łuk bramy grodu na środku, z jednej strony ocalały kawałek palisady z wieżą, z drugiej wyłom
## (złamane pale, rusztowanie, stos pali), przed bramą taran z belek, leje po bombach, gruz i żar.
func _gate(room: Rect2i) -> void:
	var mid := _center(room)
	if not _isolated(mid):
		_ring(_px(mid) + Vector2(0, 30), Vector2(90, 60), 6, ["stake_fallen", "stake_pile", M + "rubble"])
		return
	_used[mid] = true
	var arch := _prop("gate_arch", _px(mid) + Vector2(0, 14), false)
	arch.modulate = Color(0.8, 0.76, 0.72)
	var half := _tex("gate_arch").get_width() / 2.0 - 12.0
	for side in [-1, 1]:
		_post(_px(mid) + Vector2(side * half, 16), Vector2(12, 6))
		d.solid[mid + Vector2i(side, 0)] = true
		_used[mid + Vector2i(side, 0)] = true
	var breach := -1 if rng.randf() < 0.5 else 1
	for side in [-1, 1]:
		var broken: bool = side == breach
		for k in range(2, 4):
			var v := mid + Vector2i(side * k, 0)
			if not _floor_at(v) or _used.has(v) or not _clear_of_path(_px(v) + Vector2(0, 14), 34.0):
				break
			_used[v] = true
			d.solid[v] = true
			_stake_run(_px(v) + Vector2(-32, 14), _px(v) + Vector2(32, 14), broken)
		var end := mid + Vector2i(side * 4, 0)
		if broken:
			_maybe_solid("palisade_scaffold", end, Vector2(30, 8))
		elif _isolated(end) and _clear_of_path(_px(end) + Vector2(0, 10), 30.0):
			d.solid[end] = true
			_used[end] = true
			_framed("palisade_tower", _px(end) + Vector2(0, 12), 2, Vector2(44, 10))
	# przed bramą (na południu) taran, wóz i ślady szturmu
	var ram := mid + Vector2i(0, 2)
	_maybe_solid(M + "lumber", ram, Vector2(40, 10))
	_ring(_px(mid) + Vector2(0, 110), Vector2(120, 40), 6, [F + "hole", M + "rubble", F + "rubble", "stake_fallen"], true)
	_ring(_px(mid) + Vector2(0, 90), Vector2(170, 60), 5, [M + "bomb_crate", M + "cart_tipped", "stake_pile", M + "banner"])
	_embers(_px(mid) + Vector2(breach * 150, 40), 12.0)
	_smoke(_px(mid) + Vector2(breach * 150, 10))


## Sama kolizja (słup bramy narysowany w łuku) u podstawy w `pos`.
func _post(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector2(0, -size.y / 2.0)
	body.add_child(shape)
	w.entities.add_child(body)


## Pas pali z kolizją od `from` do `to` (na jednej wysokości); złamany - co drugi pal złamany, część brakuje.
func _stake_run(from: Vector2, to: Vector2, broken: bool) -> void:
	var stakes := _tex("palisade_stake")
	var snapped := _tex("palisade_stake_broken")
	var x := from.x
	while x <= to.x:
		if not broken or rng.randf() < 0.7:
			var sprite := Sprite2D.new()
			var damaged := broken and rng.randf() < 0.6
			sprite.texture = snapped if damaged else stakes
			sprite.hframes = snapped.get_width() / snapped.get_height() if damaged else Settlement.STAKE_WEIGHTS.size()
			sprite.frame = rng.randi() % sprite.hframes if damaged else rng.rand_weighted(PackedFloat32Array(Settlement.STAKE_WEIGHTS))
			sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1.0)
			sprite.position = Vector2(x, from.y + rng.randf_range(-0.6, 0.6)).round()
			sprite.flip_h = rng.randf() < 0.5
			sprite.modulate = Color(0.85, 0.83, 0.8) if not broken else Color(0.62, 0.58, 0.55)
			w.entities.add_child(sprite)
		x += 6.0
	var body := StaticBody2D.new()
	body.position = Vector2((from.x + to.x) / 2.0, from.y - 4.0)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(to.x - from.x, 10.0)
	shape.shape = box
	body.add_child(shape)
	w.entities.add_child(body)
	if broken:
		_prop("stake_fallen", Vector2(rng.randf_range(from.x, to.x), from.y + rng.randf_range(14, 26)))


## Spalone zagrody: zgliszcza chat w narożnikach polany (dym, żar), na środku zwalone belki albo przewrócony wóz,
## wokół połamane płoty, rozsypane siano, gruz i tlący się żar.
func _burned(room: Rect2i) -> void:
	var mid := _center(room)
	for corner in _corners(room):
		if rng.randf() < 0.75:
			var hut := _maybe_solid(_pick(["cottage_0", "cottage_1", "smokehouse", "pig_shelter", "lean_to"]), corner, Vector2(40, 12))
			if hut != null:
				_burnt(hut)
				_smoke(_px(corner) - Vector2(0, 40))
				if rng.randf() < 0.6:
					_embers(_px(corner) + Vector2(rng.randf_range(-24, 24), 34), 9.0)
	var middle := _maybe_solid(_pick([M + "broken_beams", M + "cart_tipped", "covered_wagon"]), mid, Vector2(40, 10))
	_burnt(middle)
	for sprite in _ring(_px(mid) + Vector2(0, 30), Vector2(room.size.x * 22.0, room.size.y * 18.0), 7,
			["deco_fence", "pen_fence_h", "hay", "deco_fence", "handcart"]):
		sprite.modulate = BURNT.lightened(0.2)
	_ring(_px(mid) + Vector2(0, 30), Vector2(80, 56), 6, [M + "rubble", F + "rubble", M + "rubble"], true)
	_embers(_px(mid) + Vector2(rng.randf_range(-60, 60), 50), 11.0)
	_motes(_px(mid) + Vector2(0, -10), Vector2(room.size.x * 22.0, room.size.y * 16.0), 10, EMBER)


## Obóz koboldów: wielkie ognisko na środku, wokół namioty ze skór, w środku kręgu posłania, skrzynie bomb,
## beczki prochu i zrabowane łupy, na skraju totemy i czaszki na palach.
func _camp(room: Rect2i) -> void:
	var mid := _center(room)
	if _isolated(mid):
		d.solid[mid] = true
		_used[mid] = true
		var fire: Node2D = BONFIRE.instantiate()
		fire.position = _px(mid) + Vector2(0, 14)
		w.entities.add_child(fire)
		_light(_px(mid), FIRE, Vector2(320, 230))
	for i in 5:
		var angle := TAU * i / 5.0 - PI / 2.0
		var v := mid + Vector2i(roundi(cos(angle) * 2.6), roundi(sin(angle) * 2.0))
		_maybe_solid(F + "kobold_tent", v, Vector2(40, 10))
	_ring(_px(mid) + Vector2(0, 20), Vector2(84, 56), 6, [M + "bedroll", M + "bomb_crate", M + "treasure", M + "ore_sacks",
			F + "powder_barrel"])
	for corner in _corners(room):
		if _floor_at(corner) and not _used.has(corner) and _clear_of_path(_px(corner) + Vector2(0, 14), 20.0):
			_used[corner] = true
			_prop(_pick([F + "totem", M + "totem", M + "skull_stick"]), _px(corner) + Vector2(0, 14))


## Plac - majdan: studnia na środku, wokół rozbite kramy i porzucone towary, przy brzegu manekiny, tarcze
## i stojaki z bronią, tablica ogłoszeń, chorągwie; koboldy zostawiły skrzynie bomb.
func _square(room: Rect2i) -> void:
	var mid := _center(room)
	if _isolated(mid):
		_solid("well", mid, Vector2(28, 10), false)
	for i in 4:
		var angle := TAU * i / 4.0 + PI / 4.0
		var v := mid + Vector2i(roundi(cos(angle) * 2.2), roundi(sin(angle) * 1.6))
		var stall := _maybe_solid(_pick(["deco_market_stall", "stall_bread", "stall_goods", "stall_veg"]), v, Vector2(40, 10))
		if stall != null and rng.randf() < 0.5:
			_burnt(stall)
	_ring(_px(mid) + Vector2(0, 30), Vector2(room.size.x * 26.0, room.size.y * 22.0), 8,
			["dummy", "archery_target", "weapon_rack", "notice_board", "banner", "arms_bundle"])
	_ring(_px(mid) + Vector2(0, 30), Vector2(70, 46), 5, ["crate", "barrel", "sack", M + "bomb_crate", "grain_sacks"])
	_light(_px(mid), Color(TORCH, 0.3), Vector2(300, 220), false)
