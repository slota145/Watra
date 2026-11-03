class_name Dungeon
extends Node
## Loch w płomieniach Watry - generowany od nowa przy każdym wejściu (ziarno w ustawieniach wyprawy, Dungeons.config).
## Układ: komnaty połączone korytarzami na siatce wierzchołków co 64 px (40x30). Wierzchołek to podłoga albo skała;
## kafelek Wang 64x64 (PixelLab, ściany pełnej wysokości) dobiera się do czterech narożników komórki, a narożnik pod
## skałą jest "ścianą" (lico ściany wypełnia komórkę pod granicą). Narożniki, których zestaw nie ma, naprawia
## usunięcie drobnego występu skały (przejścia zostają drożne).
## Komnaty: wejściowa z płomieniami Watry (powrót do Ostoi), w pozostałych gromady potworów klimatu, w najdalszej
## strażnik (boss) przy zamkniętym skarbcu - po jego pokonaniu skarbiec się otwiera, a obok buchają płomienie powrotu.
## Mrok (CanvasModulate w kolorze klimatu), pochodnie / koksowniki / grzyby ze światłem i światło wokół gracza.
## Komnaty mają wcięte narożniki i wnęki; klimat z "decor" (wszystkie klimaty) urządza je scenkami (DungeonDecor),
## pozostałe - porozrzucanym wystrojem (_build_props).
## Loch na zewnątrz (klimat z "outdoor", np. Winnica satyrów): komnaty to polany o pofalowanym brzegu, połączone
## krętymi ścieżkami, a zamiast skały granicą jest teren - skalne półki (klify z kafelków Wang), ściana drzew albo
## staw (_plan_borders). Podłoże rysuje SoftGround z teksturami gór (łąka, ścieżka, kwiaty, woda), kafelki Wang
## stoją tylko przy klifach. Przejścia, kolizje i droga potworów działają tak samo jak w podziemiach.
## Klimat z "palisade_below" w "terrain" (Oblężony gród) ma granicą także palisadę: pale wzdłuż gładkiego obrysu
## terenu palisady (_build_palisade), za nią zagrody urządzane przez wystrój klimatu.

const CELL := 64
const GRID := Vector2i(40, 30)
const ROOMS := 11
## Kafelki arkusza (kolumna, wiersz) wg narożników NW, NE, SW, SE: l - podłoga, u - skała, t - lico ściany.
## Układ jak w pixellab_src/alpine/cliff.json (ten sam tryb generowania PixelLab).
const WANG := {"llll": Vector2i(2, 2), "lllu": Vector2i(3, 2), "lluu": Vector2i(1, 4), "llul": Vector2i(2, 4),
		"lulu": Vector2i(3, 4), "uuuu": Vector2i(0, 6), "ulul": Vector2i(1, 1), "uluu": Vector2i(0, 4), "luuu": Vector2i(3, 6),
		"uuut": Vector2i(1, 6), "uutt": Vector2i(3, 0), "ultl": Vector2i(1, 2), "utul": Vector2i(0, 3), "ttll": Vector2i(3, 1),
		"tlll": Vector2i(1, 3), "lult": Vector2i(2, 0), "uutu": Vector2i(0, 0), "ultu": Vector2i(2, 6), "ltll": Vector2i(2, 1),
		"tulu": Vector2i(2, 7), "luut": Vector2i(0, 2)}
## Lico ściany blokuje trochę niżej niż do połowy komórki - postać staje u jego stóp.
const FACE_DEPTH := 40.0
const PORTAL := preload("res://assets/village/watra.png")
const ALTAR := preload("res://assets/dungeons/veles_altar.png")
const NPC_SCENE := preload("res://scenes/npc.tscn")
const CHEST := preload("res://assets/village/chest.png")
const PORTAL_FPS := 7.0
## Ile potworów na wierzchołek podłogi komnaty i jak duże są gromady.
const DENSITY := 0.42
const PACK := Vector2i(4, 7)
const LEASH := 5000.0
## Pola winorośli lochu na zewnątrz: rzędy co tyle kafelków świata, krzewy co tyle pikseli (jak w Turniach).
const VINE_ROW := 3
const VINE_STEP := 40.0

var w
var config := {}
var climate := {}
var level := 1
## wierzchołek (Vector2i) -> true: podłoga
var floor_cells := {}
var rooms: Array[Rect2i] = []
var start_room := Rect2i()
var boss_room := Rect2i()
## Komnata Kryształu Watry (pusta do czasu zdarzenia) i jego wariant ("" - loch bez kryształu).
var event_room := Rect2i()
## Wariant Kryształu Watry ("crystal", "miners"; "" - loch bez Kryształu).
var event := ""
var crystal: WatraCrystal
## Wylosowane mechaniki lochu (Dungeons.MECHANICS) i ich obiekty.
var mechanics: Array[String] = []
var chests: Array[DungeonChest] = []
var shrines: Array[DungeonShrine] = []
var elites: Array[DungeonElite] = []
var uroczyska: Array[Uroczysko] = []
## Kręgi Żertwy (pnie ofiarne, mechanika "zertwa").
var zertwy: Array[Zertwa] = []
## Skarbnicy (mechanika "skarbnik").
var skarbniki: Array[Skarbnik] = []
## Ołtarz Welesa (Essences): ukryta komnata poza listą komnat - bez potworów i pochodni (pusta - brak ołtarza).
var altar_room := Rect2i()
## Rodzaj wystroju każdej komnaty (DungeonDecor): Rect2i -> nazwa (np. "crypt", "forge", "start").
var room_themes := {}
var altar: Npc
var _altar_sprite: Sprite2D
var _altar_glow: Sprite2D
var _corridors: Array[PackedVector2Array] = []
## Wierzchołki zajęte przez duże rekwizyty z kolizją (kolumny, sarkofagi) - potwory je omijają.
var solid := {}
## Migoczące światła: [Sprite2D, krycie, faza].
var flames: Array = []
var _rng := RandomNumberGenerator.new()
var _portals: Array[Dictionary] = []
var _boss: Goblin
var _chest: Sprite2D
var _vault_open := false
var _light: Sprite2D
var _time := 0.0
## Droga do gracza: wierzchołek podłogi -> liczba kroków do wierzchołka gracza (liczona od nowa, gdy gracz zmieni wierzchołek).
var _flow := {}
var _flow_from := Vector2i(-1, -1)
## Loch na zewnątrz (patrz opis skryptu): granica z terenu zamiast skały.
var outdoor := false
## Bóg areny (Pinnacles) albo "" - zwykły loch; stopień Pomroku areny (0 - zwykła).
var pinnacle := ""
var pomrok := 0
const ARENA_START := Rect2i(3, 11, 7, 6)
const ARENA := Rect2i(16, 6, 18, 16)
## Wierzchołki poza podłogą lochu na zewnątrz: klif (skalna półka) albo woda; reszta to ściana drzew.
var cliffs := {}
var waters := {}
## Pola winorośli na terenie niedostępnym (loch na zewnątrz z "vines" w "terrain") - równe rzędy krzewów.
var vines := {}
## Teren za palisadą (klimat z "palisade_below"): wierzchołki niedostępne otoczone palisadą.
var palisades := {}
## Wygładzone linie palisady (piksele) - po nich stoją pale; wystrój stawia przy nich wieże.
var palisade_lines: Array[PackedVector2Array] = []
## Komórki ścieżek (kafelki 16 px świata) - ubita ziemia pod krętymi ścieżkami między polanami.
var path_tiles := {}
## Gładkie linie krętych ścieżek (w wierzchołkach, przed zaokrągleniem) - po nich biegnie ubita ziemia.
var _trails: Array[PackedVector2Array] = []
## Kolor upiorów Nawii (Bożek Nawii).
const NAWIA_COLOR := Color(0.62, 0.55, 1.0)
const STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]


func generate(world, settings: Dictionary) -> void:
	w = world
	config = settings
	climate = Dungeons.CLIMATES[settings["climate"]]
	_rng.seed = int(settings["seed"])
	level = Dungeons.tier_level(int(settings["tier"]))
	# arena boga (Pinnacles): poziom boga, dwie komnaty, bez zwykłych potworów
	pinnacle = str(settings.get("pinnacle", ""))
	pomrok = 0
	if Pinnacles.GODS.has(pinnacle):
		pomrok = clampi(int(settings.get("pomrok", 0)), 0, Pinnacles.POMROK_MAX)
		level = Pinnacles.arena_level(pinnacle, pomrok)
	else:
		pinnacle = ""
	Levels.zone_default = level
	Goblin.safe_zone = Rect2()
	Goblin.dungeon_mods = {}
	for key in ["health", "damage", "xp", "gold", "loot", "gems", "legend"]:
		Goblin.dungeon_mods[key] = Dungeons.mult(settings, key)
	for key in ["item_level", "quality", "herbs", "res_wood", "res_stone", "res_ore", "gem_cut"]:
		Goblin.dungeon_mods[key] = Dungeons.added(settings, key)
	if pomrok > 0:
		Goblin.dungeon_mods["health"] *= Pinnacles.pomrok_mult("health", pomrok)
		Goblin.dungeon_mods["damage"] *= Pinnacles.pomrok_mult("damage", pomrok)
	outdoor = climate.get("outdoor", false)
	if pinnacle != "":
		_plan_arena()
	else:
		_plan_rooms()
	if outdoor:
		_shape_glades()
	else:
		_shape_rooms()
	_plan_altar()
	_connect_rooms()
	if outdoor:
		_plan_borders()
	else:
		_fix_corners()
	_pick_rooms()
	_pick_mechanics()
	_build_tiles()
	_build_collision()
	_build_map()
	w._build_bounds()
	if outdoor:
		_build_ground()
		_dress_borders()
		_vine_fields()
		_build_palisade()
	_build_atmosphere()
	if climate.has("decor"):
		DungeonDecor.create(self).build()
	else:
		_build_props()
	_build_entrance()
	if pinnacle == "":
		_populate(Dungeons.mult(settings, "count") * (1.0 + Dungeons.TIER_COUNT_BONUS * (Dungeons.config_tier(settings) - 1)))
	_build_vault()
	_apply_idols()
	_build_mechanics()
	_build_altar()
	Goblin.pathing = self


# ---------------------------------------------------------------- układ
## Prostokątne komnaty (w wierzchołkach) z odstępem co najmniej 2; pierwsza jest duża - nada się na komnatę strażnika.
## Arena boga (Pinnacles): mała komnata wejścia po lewej i wielka arena po prawej, połączone korytarzem.
func _plan_arena() -> void:
	for room in [ARENA_START, ARENA]:
		rooms.append(room)
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells[Vector2i(x, y)] = true


func _plan_rooms() -> void:
	var tries := 0
	while rooms.size() < ROOMS and tries < 3000:
		tries += 1
		var size := Vector2i(_rng.randi_range(7, 9), _rng.randi_range(6, 7)) if rooms.is_empty() \
				else Vector2i(_rng.randi_range(4, 8), _rng.randi_range(4, 7))
		var pos := Vector2i(_rng.randi_range(2, GRID.x - size.x - 3), _rng.randi_range(2, GRID.y - size.y - 3))
		var room := Rect2i(pos, size)
		if rooms.any(func(other: Rect2i) -> bool: return other.grow(2).intersects(room)):
			continue
		rooms.append(room)
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells[Vector2i(x, y)] = true


## Nieregularne komnaty: wcięte narożniki (blok skały) i wnęki wychodzące poza prostokąt. Środek komnaty i środki
## boków zostają wolne (płomienie Watry, strażnik, skarbiec, kryształ, wejścia korytarzy). Prostokąt w `rooms`
## zostaje jako obrys komnaty.
func _shape_rooms() -> void:
	for room in rooms:
		if room.size.x >= 6 and room.size.y >= 5:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				if _rng.randf() >= 0.45:
					continue
				var cut := Vector2i(_rng.randi_range(2, mini(3, room.size.x / 2 - 1)), 2)
				var origin := Vector2i(room.position.x if corner.x == 0 else room.end.x - cut.x,
						room.position.y if corner.y == 0 else room.end.y - cut.y)
				for x in range(origin.x, origin.x + cut.x):
					for y in range(origin.y, origin.y + cut.y):
						floor_cells.erase(Vector2i(x, y))
		# wnęka: pas 2-3 wierzchołków szeroki, 1-2 głęboki, na losowym boku (z dala od innych komnat)
		if _rng.randf() < 0.6:
			var side: Vector2i = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN][_rng.randi() % 4]
			var depth := _rng.randi_range(1, 2)
			var width := _rng.randi_range(2, 3)
			var along := room.size.x if side.y != 0 else room.size.y
			if along < width + 2:
				continue
			var offset := _rng.randi_range(1, along - width - 1)
			var nook := Rect2i()
			match side:
				Vector2i.UP: nook = Rect2i(room.position.x + offset, room.position.y - depth, width, depth)
				Vector2i.DOWN: nook = Rect2i(room.position.x + offset, room.end.y, width, depth)
				Vector2i.LEFT: nook = Rect2i(room.position.x - depth, room.position.y + offset, depth, width)
				_: nook = Rect2i(room.end.x, room.position.y + offset, depth, width)
			if nook.position.x < 2 or nook.position.y < 2 or nook.end.x > GRID.x - 2 or nook.end.y > GRID.y - 2:
				continue
			if rooms.any(func(other: Rect2i) -> bool: return other != room and other.grow(1).intersects(nook)):
				continue
			for x in range(nook.position.x, nook.end.x):
				for y in range(nook.position.y, nook.end.y):
					floor_cells[Vector2i(x, y)] = true


# ---------------------------------------------------------------- loch na zewnątrz
## Polany: owal wpisany w prostokąt komnaty z brzegiem pofalowanym szumem, wybrzuszony najwyżej o wierzchołek
## (z dala od innych polan). Środkowy rząd i kolumna zostają polaną (płomienie Watry, strażnik, skarbiec, ścieżki);
## prostokąt w `rooms` zostaje jako obrys polany.
func _shape_glades() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.3
	for room in rooms:
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells.erase(Vector2i(x, y))
	for room in rooms:
		var mid := Vector2(room.position) + Vector2(room.size - Vector2i.ONE) / 2.0
		# promień do skrajnych wierzchołków prostokąta z małym zapasem - narożniki prostokąta wypadają poza owal
		var radius := Vector2(room.size - Vector2i.ONE) / 2.0 + Vector2(0.3, 0.3)
		var area := room.grow(1)
		for x in range(area.position.x, area.end.x):
			for y in range(area.position.y, area.end.y):
				var v := Vector2i(x, y)
				if x < 2 or y < 2 or x > GRID.x - 3 or y > GRID.y - 3:
					continue
				var inside := room.has_point(v)
				if not inside and rooms.any(func(other: Rect2i) -> bool: return other != room and other.grow(2).has_point(v)):
					continue
				var q := pow((x - mid.x) / radius.x, 2) + pow((y - mid.y) / radius.y, 2)
				var core := inside and (x == room.position.x + room.size.x / 2 or y == room.position.y + room.size.y / 2)
				if core or q <= 1.0 + 0.35 * noise.get_noise_2d(x, y):
					floor_cells[v] = true


## Kręta ścieżka szerokości 2-3 wierzchołków: idzie ku celowi, łagodnie skręcając na boki (fala o losowej fazie,
## słabnąca przy celu). Skręt jest mniejszy niż kąt prosty, więc każdy krok zbliża do celu.
func _dig_path(from: Vector2i, to: Vector2i) -> void:
	var path := PackedVector2Array()
	var at := Vector2(from)
	var phase := _rng.randf() * TAU
	var wave := _rng.randf_range(0.18, 0.32)
	var swing := _rng.randf_range(0.55, 0.95)
	var last := Vector2i(-99, -99)
	var trail := PackedVector2Array([Vector2(from)])
	for i in 600:
		var left := Vector2(to) - at
		if left.length() < 1.0:
			break
		var bend := sin(i * wave + phase) * swing * clampf(left.length() / 5.0, 0.0, 1.0)
		at += left.normalized().rotated(bend) * 0.5
		trail.append(at)
		var cell := Vector2i(at.round()).clamp(Vector2i(2, 2), GRID - Vector2i(4, 4))
		if cell != last:
			_stamp_path(cell)
			path.append(Vector2(cell))
			last = cell
	_stamp_path(to)
	path.append(Vector2(to))
	trail.append(Vector2(to))
	_corridors.append(path)
	_trails.append(trail)


## Kawałek ścieżki: 2x2 wierzchołki, czasem poszerzony do 3x3 (brzeg ścieżki faluje).
func _stamp_path(cell: Vector2i) -> void:
	var wide := _rng.randf() < 0.12
	for dx in range(-1 if wide else 0, 2):
		for dy in range(-1 if wide else 0, 2):
			var v := cell + Vector2i(dx, dy)
			if v.x >= 1 and v.y >= 1 and v.x <= GRID.x - 2 and v.y <= GRID.y - 2:
				floor_cells[v] = true


## Granica polan: każdy wierzchołek poza podłogą to klif, woda, pole winorośli albo drzewa wg szumu o dużych plamach
## (progi w "terrain" klimatu). Klif, który nie pasuje do żadnego kafelka Wang, zamienia się w drzewa.
func _plan_borders() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.1
	var terrain: Dictionary = climate["terrain"]
	for x in range(-1, GRID.x + 1):
		for y in range(-1, GRID.y + 1):
			var v := Vector2i(x, y)
			if floor_cells.has(v):
				continue
			var n := noise.get_noise_2d(x, y)
			if n < terrain["cliff_below"]:
				cliffs[v] = true
			elif n < terrain.get("palisade_below", -2.0):
				palisades[v] = true
			elif n > terrain["water_above"] and x >= 1 and y >= 1 and x <= GRID.x - 2 and y <= GRID.y - 2:
				waters[v] = true
	# drobne kawałki terenu palisady (kółko z pali wokół kilku wierzchołków) zostają lasem
	var groups := {}
	for start: Vector2i in palisades.keys():
		if groups.has(start):
			continue
		var group: Array[Vector2i] = [start]
		groups[start] = true
		var i := 0
		while i < group.size():
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n := group[i] + step
				if palisades.has(n) and not groups.has(n):
					groups[n] = true
					group.append(n)
			i += 1
		if group.size() < 14:
			for v in group:
				palisades.erase(v)
	for _pass in 60:
		var bad := 0
		for x in range(-1, GRID.x):
			for y in range(-1, GRID.y):
				var cell := Vector2i(x, y)
				if WANG.has(_key(cell)):
					continue
				bad += 1
				for c: Vector2i in [cell, cell + Vector2i.RIGHT, cell + Vector2i.DOWN, cell + Vector2i.ONE]:
					cliffs.erase(c)
		if bad == 0:
			break
	# wokół klifu łąka, po której można chodzić: drzewa i krzewy zasłaniałyby lico albo wystawały za krawędź,
	# a goły zablokowany wierzchołek byłby niewidzialną ścianą (rząd niżej też - korony sięgają wysoko)
	for x in range(1, GRID.x - 1):
		for y in range(1, GRID.y - 1):
			var v := Vector2i(x, y)
			if not floor_cells.has(v) and not cliffs.has(v) and not waters.has(v) and not palisades.has(v) \
					and (near_cliff(v) or near_cliff(v + Vector2i.UP)):
				floor_cells[v] = true
	# pola winorośli: duże plamy drugiego szumu wśród drzew (skraj mapy zostaje lasem)
	if terrain.has("vines"):
		var field := FastNoiseLite.new()
		field.seed = _rng.randi()
		field.frequency = 0.09
		for x in range(1, GRID.x - 1):
			for y in range(1, GRID.y - 1):
				var v := Vector2i(x, y)
				if floor_cells.has(v) or cliffs.has(v) or waters.has(v) or palisades.has(v) or field.get_noise_2d(x, y) <= terrain["vines_above"]:
					continue
				# przy klifie (lico i przejścia kafelków Wang zachodzą na sąsiednie komórki, a wysokie krzewy sięgają
				# rząd wyżej) zostają drzewa
				if not near_cliff(v) and not near_cliff(v + Vector2i.UP):
					vines[v] = true
	# ubita ziemia ścieżek: kafelki świata (16 px) w pasie wzdłuż krętych ścieżek, tylko na podłodze
	var tile: int = w.TILE
	for trail in _trails:
		for i in trail.size() - 1:
			var a := (trail[i] + Vector2(0.5, 0.5)) * CELL
			var b := (trail[i + 1] + Vector2(0.5, 0.5)) * CELL
			var steps := maxi(1, int(a.distance_to(b) / 8.0))
			for s in steps + 1:
				var p := a.lerp(b, float(s) / steps)
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var t := Vector2i(p / tile) + Vector2i(dx, dy)
						var center := (Vector2(t) + Vector2(0.5, 0.5)) * tile
						var v := Vector2i((center / CELL).round())
						# ścieżka wtapia się w polanę kawałek za jej skrajem (owal mniejszy od polany)
						if center.distance_to(p) <= 15.0 and floor_cells.has(v) and not _in_glade(center / CELL, 0.55):
							path_tiles[t] = true


## Czy punkt (w wierzchołkach) leży w owalu polany pomniejszonym do `share` jej rozmiaru.
func _in_glade(at: Vector2, share: float) -> bool:
	for room in rooms:
		var mid := Vector2(room.position) + Vector2(room.size - Vector2i.ONE) / 2.0
		var radius := Vector2(room.size) / 2.0 * share
		if pow((at.x - mid.x) / radius.x, 2) + pow((at.y - mid.y) / radius.y, 2) <= 1.0:
			return true
	return false


## Podłoże lochu na zewnątrz (SoftGround z teksturami gór): łąka, pod ścianą drzew gęsta trawa, na polanach płaty
## kwiatów i gęstej trawy, ubita ścieżka, w stawach woda.
func _build_ground() -> void:
	var tile: int = w.TILE
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.05
	var shore := FastNoiseLite.new()
	shore.seed = _rng.randi()
	shore.frequency = 0.2
	# granice terenów (gęsta trawa pod drzewami, kwiaty) biegną po wierzchołkach lochu co 64 px - przesunięcie
	# punktu dwoma szumami wygina je, żeby nie były prostymi odcinkami
	var warp_x := FastNoiseLite.new()
	warp_x.seed = _rng.randi()
	warp_x.frequency = 0.08
	var warp_y := FastNoiseLite.new()
	warp_y.seed = _rng.randi()
	warp_y.frequency = 0.08
	var corners := {}
	for x in w.map_size.x + 1:
		for y in w.map_size.y + 1:
			var c := Vector2i(x, y)
			var px := Vector2(c) * tile
			var v := Vector2i((px / CELL).round())
			var bent := Vector2i(((px + Vector2(warp_x.get_noise_2d(x, y), warp_y.get_noise_2d(x, y)) * 26.0) / CELL).round())
			var kind := "meadow"
			if cliffs.has(bent) or near_cliff(bent):
				# przy klifie łąka w kolorze trawy kafelków klifu (inaczej brzeg półki odcina się prostą linią)
				kind = "meadow"
			elif waters.has(v):
				# woda kończy się przed brzegiem kolizji w odległości falującej z szumem (brzeg nie jest prostokątem;
				# trzciny zakrywają szparę): wszystkie punkty w kręgu wokół narożnika muszą leżeć nad wodą
				kind = "w_deep"
				var reach := 16.0 + 12.0 * shore.get_noise_2d(x, y)
				for i in 8:
					var probe := px + Vector2.from_angle(TAU * i / 8.0) * reach
					if not waters.has(Vector2i((probe / CELL).round())):
						kind = "m_dark"
						break
			elif palisades.has(bent):
				# za palisadą wydeptana trawa z płatami ubitej ziemi (inna niż ścieżki - tam się nie wchodzi)
				kind = "m_path" if noise.get_noise_2d(x, y) > 0.3 else "m_dark"
			elif floor_cells.has(bent):
				var near_path := false
				for t: Vector2i in [c, c - Vector2i(1, 0), c - Vector2i(0, 1), c - Vector2i(1, 1)]:
					if path_tiles.has(t):
						near_path = true
				var n := noise.get_noise_2d(x, y)
				if near_path:
					kind = "m_path"
				elif n > 0.3:
					kind = "m_flowers"
				elif n < -0.35:
					kind = "m_dark"
			elif not floor_cells.has(bent):
				kind = "m_dark"
			corners[c] = kind
	for x in w.map_size.x:
		for y in w.map_size.y:
			w.ground.set_cell(Vector2i(x, y), 0, Vector2i(0, w.ALPINE_WANG_ROW))
	w._soft_corners = corners
	w._soft_textures = {"w_deep": w.SWAMP_GROUND["w_deep"]}


## Czy wierzchołek sąsiaduje z klifem (także po skosie) - lico i krawędzie kafelków Wang zachodzą na jego komórki,
## więc nie stawiamy tam niczego wysokiego.
func near_cliff(v: Vector2i) -> bool:
	return STEPS.any(func(step: Vector2i) -> bool: return cliffs.has(v + step))


## Ściana drzew na wierzchołkach drzew (dwa drzewa na wierzchołek, korony zachodzą na siebie), krzewy i głazy
## w głębi skalnych półek, trzciny przy brzegu stawów i grążele na wodzie. Bez własnej kolizji - wierzchołek i tak
## jest zablokowany. Wokół klifów drzew nie ma - tam jest łąka (_plan_borders).
func _dress_borders() -> void:
	var terrain: Dictionary = climate["terrain"]
	var trees: Array = terrain["trees"].map(func(path: String) -> Texture2D: return load(path))
	var tops: Array = terrain["plateau"].map(func(path: String) -> Texture2D: return load(path))
	var reeds: Texture2D = load(terrain["reeds"])
	var lilies: Texture2D = load(terrain["lilies"])
	for x in GRID.x:
		for y in GRID.y:
			var v := Vector2i(x, y)
			if floor_cells.has(v) or vines.has(v) or palisades.has(v):
				continue
			var at := Vector2(v) * CELL
			if waters.has(v):
				var shore := false
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					shore = shore or not waters.has(v + d)
				if shore and not near_cliff(v) and _rng.randf() < 0.55:
					var reed: Sprite2D = w._village_prop(reeds, at + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-12, 20)))
					reed.hframes = 2
					reed.frame = _rng.randi() % 2
					reed.flip_h = _rng.randf() < 0.5
				elif not shore and _rng.randf() < 0.35:
					var lily := Sprite2D.new()
					lily.texture = lilies
					lily.hframes = 3
					lily.frame = _rng.randi() % 3
					lily.position = at + Vector2(_rng.randf_range(-16, 16), _rng.randf_range(-16, 16))
					w.floors.add_child(lily)
			elif cliffs.has(v):
				# w głębi półki (wszędzie wokół klif) krzewy i głazy - bez drzew, które wystawałyby za krawędź
				if not STEPS.all(func(step: Vector2i) -> bool: return cliffs.has(v + step)) or _rng.randf() >= 0.35:
					continue
				var top: Sprite2D = w._village_prop(tops.pick_random(), at + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(4, 16)))
				top.flip_h = _rng.randf() < 0.5
			else:
				for i in 2:
					var spot := at + Vector2(_rng.randf_range(-14, 14) + (i * 2 - 1) * 14, _rng.randf_range(-6, 6) + (24 if i == 0 else 4))
					var tree: Sprite2D = w._village_prop(trees.pick_random(), spot)
					tree.flip_h = _rng.randf() < 0.5
					var shade := _rng.randf_range(0.82, 1.0)
					tree.modulate = Color(shade, shade, shade)


## Palisada: obrys terenu palisady (marching squares po wierzchołkach - odcinki między środkami krawędzi, wierzchołki
## palisady stykające się tylko po skosie zostają osobno) łączony w linie i wygładzony (Chaikin), wzdłuż linii pale
## co kilka pikseli (w pionie gęściej - widać je jeden za drugim), w kilku miejscach pas złamanych pali, kolizja
## wzdłuż całej linii. Pale stoją tylko od strony polan, ścieżek i wody (zagroda przechodzi w las bez płotu).
func _build_palisade() -> void:
	if palisades.is_empty():
		return
	var terrain: Dictionary = climate["terrain"]
	var stakes: Texture2D = load(terrain["stakes"])
	var broken: Texture2D = load(terrain["stakes_broken"])
	# punkt obrysu to środek krawędzi między wierzchołkami a i b - kluczem jest a + b
	var links := {}
	for x in range(-1, GRID.x):
		for y in range(-1, GRID.y):
			var c := Vector2i(x, y)
			var corners: Array[Vector2i] = [c, c + Vector2i.RIGHT, c + Vector2i.ONE, c + Vector2i.DOWN]
			var cuts: Array[Vector2i] = []
			for i in 4:
				var a := corners[i]
				var b := corners[(i + 1) % 4]
				cuts.append(a + b if palisades.has(a) != palisades.has(b) else Vector2i(-99, -99))
			# pale tylko od strony polan, ścieżek i wody - zagroda przechodzi w las bez płotu
			var open := false
			for v in corners:
				open = open or (not palisades.has(v) and (floor_cells.has(v) or waters.has(v)))
			if not open:
				continue
			var real := cuts.filter(func(k: Vector2i) -> bool: return k.x != -99)
			if real.size() == 2:
				_link(links, real[0], real[1])
			elif real.size() == 4:
				# siodło: osobno obchodzimy każdy narożnik palisady
				var first := 3 if palisades.has(corners[0]) else 0
				_link(links, cuts[first], cuts[(first + 1) % 4])
				_link(links, cuts[(first + 2) % 4], cuts[(first + 3) % 4])
	# linie: najpierw od końców (obrys urwany na skraju mapy), potem pętle
	var seen := {}
	var starts: Array = links.keys().filter(func(k: Vector2i) -> bool: return links[k].size() == 1)
	starts.append_array(links.keys().filter(func(k: Vector2i) -> bool: return links[k].size() != 1))
	for start: Vector2i in starts:
		if seen.has(start):
			continue
		var line := PackedVector2Array()
		var at := start
		var last := start
		while true:
			seen[at] = true
			last = at
			line.append(Vector2(at) * CELL / 2.0)
			var next := Vector2i(-99, -99)
			for n: Vector2i in links[at]:
				if not seen.has(n):
					next = n
					break
			if next.x == -99:
				break
			at = next
		var closed: bool = line.size() > 2 and links[last].has(start)
		if closed:
			line.append(line[0])
		for _pass in 2:
			line = _chaikin(line, closed)
		if line.size() > 1:
			palisade_lines.append(line)
	var body := StaticBody2D.new()
	body.name = "Palisade"
	w.add_child(body)
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.006
	var area := Rect2(Vector2(-CELL / 2.0, -CELL / 2.0), Vector2(GRID) * CELL)
	for line in palisade_lines:
		var segments := PackedVector2Array()
		for i in line.size() - 1:
			segments.append_array([line[i], line[i + 1]])
		var shape := CollisionShape2D.new()
		var concave := ConcavePolygonShape2D.new()
		concave.segments = segments
		shape.shape = concave
		body.add_child(shape)
		# `t` - odległość od początku odcinka do następnego pala (reszta przechodzi na kolejny odcinek)
		var t := 0.0
		for i in line.size() - 1:
			var along := line[i + 1] - line[i]
			var length := along.length()
			var step := lerpf(6.0, 3.5, absf(along.normalized().y))
			while t < length:
				var at := line[i] + along * (t / length)
				if area.has_point(at):
					_palisade_stake(stakes, broken, at, noise.get_noise_2d(at.x, at.y) > 0.42)
				t += step
			t -= length


func _link(links: Dictionary, a: Vector2i, b: Vector2i) -> void:
	if not links.has(a):
		links[a] = []
	if not links.has(b):
		links[b] = []
	links[a].append(b)
	links[b].append(a)


## Wygładzenie łamanej (Chaikin): każdy odcinek zastępują punkty w 1/4 i 3/4; otwarta zachowuje końce.
func _chaikin(line: PackedVector2Array, closed: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	if not closed:
		out.append(line[0])
	for i in line.size() - 1:
		out.append(line[i].lerp(line[i + 1], 0.25))
		out.append(line[i].lerp(line[i + 1], 0.75))
	if closed:
		out.append(out[0])
	else:
		out.append(line[line.size() - 1])
	return out


## Jeden pal palisady (jak w Ostoi - Settlement._stake); złamany co trzeci w pasie złamanych.
func _palisade_stake(stakes: Texture2D, broken: Texture2D, at: Vector2, damaged: bool) -> void:
	var sprite := Sprite2D.new()
	if damaged and _rng.randf() < 0.45:
		sprite.texture = broken
		sprite.hframes = broken.get_width() / broken.get_height()
		sprite.frame = _rng.randi() % sprite.hframes
	else:
		sprite.texture = stakes
		sprite.hframes = Settlement.STAKE_WEIGHTS.size()
		sprite.frame = _rng.rand_weighted(PackedFloat32Array(Settlement.STAKE_WEIGHTS))
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1.0)
	sprite.position = (at + Vector2(_rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.6, 0.6))).round()
	sprite.flip_h = _rng.randf() < 0.5
	var shade := _rng.randf_range(0.82, 0.95) if not damaged else _rng.randf_range(0.6, 0.78)
	sprite.modulate = Color(shade, shade * 0.97, shade * 0.95)
	w.entities.add_child(sprite)


## Pola winorośli: rzędy co VINE_ROW kafelków świata, w rzędzie krzew co VINE_STEP px, co kilka krzewów przejście
## (jak winnice wioski satyrów w Turniach). Krzew stoi tylko tam, gdzie kafelek i kafelek nad nim leżą w polu -
## rząd kończy się równo na skraju pola.
func _vine_fields() -> void:
	if not climate["terrain"].has("vines"):
		return
	var tile: int = w.TILE
	var kinds: Array = climate["terrain"]["vines"].map(func(path: String) -> Texture2D: return load(path))
	var in_field := func(t: Vector2i) -> bool:
		return vines.has(Vector2i(((Vector2(t) + Vector2(0.5, 0.5)) * tile / CELL).round()))
	for y in range(1, w.map_size.y, VINE_ROW):
		var run := -1
		for x in w.map_size.x + 1:
			var on: bool = x < w.map_size.x and in_field.call(Vector2i(x, y)) and in_field.call(Vector2i(x, y - 1))
			if on and run < 0:
				run = x
			elif not on and run >= 0:
				vine_run(kinds[_rng.randi() % kinds.size()], run * tile, x * tile, y * tile + 14.0)
				run = -1


## Jeden rząd krzewów winorośli od `from` do `to` (px) na wysokości `y`: równe odstępy, przejście co 6-8 krzewów.
## Zwraca postawione krzewy.
func vine_run(texture: Texture2D, from: float, to: float, y: float, gaps := true) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var count := int((to - from + 8.0) / VINE_STEP)
	var left := from + (to - from - count * VINE_STEP) / 2.0 + VINE_STEP / 2.0
	var next_gap := _rng.randi_range(5, 7) if gaps else 1 << 20
	for k in count:
		if k == next_gap:
			next_gap += _rng.randi_range(6, 8)
			continue
		out.append(w._village_prop(texture, Vector2(left + k * VINE_STEP, y)))
	return out


## Ołtarz Welesa: rzadko (Essences.ALTAR_CHANCE, w trybie deweloperskim albo z "altar" w ustawieniach zawsze)
## mała komnata w wolnym miejscu mapy, połączona wąskim przejściem z najbliższą komnatą.
func _plan_altar() -> void:
	var wanted: bool = config.get("altar", Game.dev_mode or _rng.randf() < Essences.ALTAR_CHANCE)
	if not wanted:
		return
	for tries in 1200:
		var size := Vector2i(4, 4)
		var pos := Vector2i(_rng.randi_range(2, GRID.x - size.x - 3), _rng.randi_range(2, GRID.y - size.y - 3))
		var room := Rect2i(pos, size)
		# odstęp od komnat: najpierw 2 wierzchołki, przy ciasnym lochu - 1
		var gap := 2 if tries < 800 else 1
		if rooms.any(func(other: Rect2i) -> bool: return other.grow(gap).intersects(room)):
			continue
		altar_room = room
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				floor_cells[Vector2i(x, y)] = true
		var center := room.position + room.size / 2
		var nearest := rooms[0]
		for other in rooms:
			if Vector2(other.get_center() - center).length() < Vector2(nearest.get_center() - center).length():
				nearest = other
		_dig(center, nearest.position + nearest.size / 2)
		_corridors.pop_back()  # w przejściu do ołtarza nie stoją potwory
		if outdoor:
			_trails.pop_back()  # ukryta ścieżka - bez ubitej ziemi
		return


func _build_altar() -> void:
	if altar_room == Rect2i():
		return
	var pos := Vector2(altar_room.get_center()) * CELL + Vector2(0, CELL * 0.4)
	_altar_sprite = w._village_prop(ALTAR, pos, Vector2(70, 26))
	_altar_glow = _glow(pos + Vector2(0, -30), Color(0.35, 1.0, 0.45, 0.55), Vector2(220, 160))
	altar = NPC_SCENE.instantiate()
	altar.position = pos + Vector2(0, 26)
	altar.role = Npc.Role.IDLE
	altar.looks_around = false
	altar.display_name = "Ołtarz Welesa"
	altar.services.assign(["altar"])
	w.entities.add_child(altar)
	altar.get_node("Sprite").visible = false
	altar.get_node("Shadow").visible = false
	altar.prompt.text = Lang.t("[F] Ołtarz Welesa")
	w.hud.essence_window.altar_used.connect(_spend_altar)


## Ołtarz przyjął ofiarę: gaśnie i nie da się go już użyć.
func _spend_altar() -> void:
	if altar == null or not is_instance_valid(altar):
		return
	altar.services.assign([])
	altar.remove_from_group("interactables")
	altar.prompt.visible = false
	_altar_sprite.modulate = Color(0.55, 0.55, 0.6)
	_altar_glow.visible = false


## Korytarze szerokości 2 wierzchołków: drzewo rozpinające komnat (najkrótsze połączenia) i dwie dodatkowe pętle.
func _connect_rooms() -> void:
	var centers: Array[Vector2i] = []
	for room in rooms:
		centers.append(room.position + room.size / 2)
	var joined := {0: true}
	var edges: Array[Vector2i] = []
	while joined.size() < rooms.size():
		var best := Vector2i(-1, -1)
		var best_d := 1 << 30
		for a: int in joined:
			for b in rooms.size():
				if joined.has(b):
					continue
				var d := absi(centers[a].x - centers[b].x) + absi(centers[a].y - centers[b].y)
				if d < best_d:
					best_d = d
					best = Vector2i(a, b)
		edges.append(best)
		joined[best.y] = true
	for i in 2:
		edges.append(Vector2i(_rng.randi() % rooms.size(), _rng.randi() % rooms.size()))
	for edge in edges:
		if edge.x != edge.y:
			_dig(centers[edge.x], centers[edge.y])


func _dig(from: Vector2i, to: Vector2i) -> void:
	if outdoor:
		_dig_path(from, to)
		return
	var corner := Vector2i(to.x, from.y) if _rng.randf() < 0.5 else Vector2i(from.x, to.y)
	var path := PackedVector2Array()
	for leg in [[from, corner], [corner, to]]:
		var a: Vector2i = leg[0]
		var b: Vector2i = leg[1]
		var step := (b - a).sign()
		var at := a
		while true:
			path.append(Vector2(at))
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				floor_cells[at + d] = true
			if at == b:
				break
			at += step
	_corridors.append(path)


func _label(v: Vector2i) -> String:
	if not floor_cells.has(v):
		return "u"
	return "t" if _wall(v + Vector2i.UP) else "l"


## Czy wierzchołek rysuje się jako ściana (skała, a na zewnątrz - klif; drzewa i woda nie mają lica).
func _wall(v: Vector2i) -> bool:
	return cliffs.has(v) if outdoor else not floor_cells.has(v)


## Narożnik kafelka Wang: na zewnątrz "u" tylko pod klifem, a pod drzewami i wodą - łąka ("l").
func _tile_label(v: Vector2i) -> String:
	if not outdoor:
		return _label(v)
	if cliffs.has(v):
		return "u"
	return "t" if cliffs.has(v + Vector2i.UP) else "l"


func _key(cell: Vector2i) -> String:
	return _tile_label(cell) + _tile_label(cell + Vector2i.RIGHT) + _tile_label(cell + Vector2i.DOWN) \
			+ _tile_label(cell + Vector2i.ONE)


## Komórki bez pasującego kafelka: skała w środku mapy zamienia się w podłogę (znika drobny występ, przejście zostaje),
## przy brzegu mapy - podłoga w skałę.
func _fix_corners() -> void:
	for _pass in 80:
		var bad := 0
		for x in GRID.x - 1:
			for y in GRID.y - 1:
				var cell := Vector2i(x, y)
				if WANG.has(_key(cell)):
					continue
				bad += 1
				var corners: Array[Vector2i] = [cell, cell + Vector2i.RIGHT, cell + Vector2i.DOWN, cell + Vector2i.ONE]
				var inner := corners.all(func(v: Vector2i) -> bool:
					return v.x >= 2 and v.y >= 2 and v.x <= GRID.x - 3 and v.y <= GRID.y - 3)
				for v in corners:
					if inner:
						floor_cells[v] = true
					else:
						floor_cells.erase(v)
		if bad == 0:
			return


## Wejście w komnacie najbardziej na zachód, strażnik w największej z dalekich komnat (wg drogi przez loch).
func _pick_rooms() -> void:
	start_room = rooms[0]
	for room in rooms:
		if room.get_center().x < start_room.get_center().x:
			start_room = room
	var distance := _distances(start_room.position + start_room.size / 2)
	var best_score := -1.0
	for room in rooms:
		if room == start_room:
			continue
		var d: int = distance.get(room.position + room.size / 2, 0)
		var score := d * (1.5 if room.size.x >= 6 and room.size.y >= 5 else 1.0)
		if score > best_score:
			best_score = score
			boss_room = room


## Mechaniki lochu (Dungeons.MECHANICS): losowane z ziarna wyprawy; "mechanics" w ustawieniach wyprawy wymusza
## zestaw (testy), "event" - wariant Kryształu Watry; w trybie deweloperskim loch ma wszystkie mechaniki.
## Kryształ Watry zajmuje największą komnatę poza wejściową i komnatą strażnika.
func _pick_mechanics() -> void:
	if config.has("mechanics"):
		mechanics.assign(config["mechanics"])
	elif Game.dev_mode:
		mechanics.assign(Dungeons.MECHANICS.keys())
	else:
		mechanics = Dungeons.roll_mechanics(_rng, Dungeons.mechanic_bonus(config))
	event = str(config.get("event", ""))
	if event != "" and not mechanics.has("crystal"):
		mechanics.append("crystal")
	if not mechanics.has("crystal"):
		event = ""
		return
	if event == "":
		event = Dungeons.EVENTS[_rng.randi() % Dungeons.EVENTS.size()]
	var best := -1
	for room in rooms:
		if room == start_room or room == boss_room:
			continue
		if room.get_area() > best:
			best = room.get_area()
			event_room = room
	if best < 0:
		event = ""
		mechanics.erase("crystal")


# ---------------------------------------------------------------- bożki
## Działanie bożków na potwory lochu (po strażniku, przed mechanikami): dodatkowe gromady (z elitą), bossowie echa,
## same elity, wściekły strażnik i upiory Nawii.
func _apply_idols() -> void:
	var free_rooms: Array[Rect2i] = []
	for room in rooms:
		if room != start_room and room != boss_room and room != altar_room and not (event != "" and room == event_room):
			free_rooms.append(room)
	if free_rooms.is_empty():
		return
	var pack_elite := Dungeons.added(config, "pack_elites") > 0.0
	for i in int(Dungeons.added(config, "packs")):
		var room: Rect2i = free_rooms[_rng.randi() % free_rooms.size()]
		var center := _room_point(room, 28.0)
		var pack: Array[Dictionary] = []
		for j in _rng.randi_range(PACK.x, PACK.y):
			pack.append(_spawn(_pick(climate["monsters"]), center + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-22, 22)), center, level))
		if pack_elite:
			_promote_spawn(pack.pick_random())
	var echo_pool := Idols.boss_pool(climate["boss"])
	var echo_level := level + Dungeons.BOSS_BONUS + int(Dungeons.added(config, "echo_level"))
	for i in int(Dungeons.added(config, "echo")):
		var room: Rect2i = free_rooms[_rng.randi() % free_rooms.size()]
		var at := _room_point(room, 28.0)
		_spawn(echo_pool[_rng.randi() % echo_pool.size()], at, at + Vector2(0, 40), echo_level)
	if Dungeons.added(config, "all_elite") > 0.0:
		for spawn: Dictionary in w._goblin_spawns.duplicate():
			var goblin: Goblin = w._live_goblins.get(spawn.get("id", -1))
			if goblin != null and goblin.elite == null and not goblin is Boss and goblin.speed > 0.0:
				_promote_spawn(spawn)
	if _boss != null and Dungeons.mult(config, "boss_health") > 1.0:
		_boss.max_health = roundi(_boss.max_health * Dungeons.mult(config, "boss_health"))
		_boss.health = _boss.max_health
		var damage := Dungeons.mult(config, "boss_damage")
		for property in _boss.get_property_list():
			var key: String = property["name"]
			if key.ends_with("damage") and property["type"] == TYPE_INT and _boss.get(key) > 0 \
					and key != "traveler_damage" and key != "event_damage":
				_boss.set(key, maxi(1, roundi(_boss.get(key) * damage)))
		if _boss is Boss:
			_boss.enraged = true
	if Dungeons.added(config, "nawia") > 0.0 and not w.goblin_died.is_connected(_on_nawia_death):
		w.goblin_died.connect(_on_nawia_death)


## Elita z potwora z danego miejsca (cechy losowe).
func _promote_spawn(spawn: Dictionary) -> void:
	var target: Goblin = w._live_goblins.get(spawn.get("id", -1))
	if target == null or target.elite != null or target is Boss or target.speed <= 0.0:
		return
	elites.append(DungeonElite.promote(target, Dungeons.roll_elite_traits(_rng), self, spawn["type"]))


## Bożek Nawii: zabity wróg (nie upiór, nie boss) z szansą wstaje jako upiór w tym samym miejscu.
func _on_nawia_death(goblin: Goblin) -> void:
	if goblin is Boss or goblin.has_meta("nawia") or goblin.has_meta("ghost") or goblin.speed <= 0.0:
		return
	if _rng.randf() >= Dungeons.added(config, "nawia"):
		return
	_raise_nawia.call_deferred(goblin.global_position)


func _raise_nawia(at: Vector2) -> void:
	if not is_instance_valid(w) or w._dungeon != self:
		return
	var spawn := _spawn(_pick(climate["monsters"]), at, at, level)
	var ghost: Goblin = w._live_goblins.get(spawn.get("id", -1))
	if ghost == null:
		return
	ghost.set_meta("nawia", true)
	ghost.heart_drop_chance = 0.0
	ghost.map_color = NAWIA_COLOR
	var mat := ShaderMaterial.new()
	mat.shader = Uroczysko.SHADER
	mat.set_shader_parameter("ghost", NAWIA_COLOR)
	mat.set_shader_parameter("phase", _rng.randf() * TAU)
	ghost.sprite.material = mat
	ghost.sitting = false
	ghost.appear()
	ghost.aggro()
	MiscVfx.puff(ghost.get_parent(), at + Vector2(0, -6), NAWIA_COLOR, 0.8)


## Moc mechaniki z legendarnego bożka (Idols.MECHANIC_POWER) i drzewka Watry (WatraTree; 1 - zwykła mechanika).
func mechanic_power(id: String) -> float:
	return float(Dungeons.mechanic_bonus(config).get("power", {}).get(id, 1.0))


## Dodatkowe sztuki mechaniki przy wzmocnieniu (moc 1.5 -> `extra`, moc 1 -> 0).
func power_extra(id: String, extra: int) -> int:
	return roundi((mechanic_power(id) - 1.0) * 2.0 * extra)


## Buduje wylosowane mechaniki (po potworach - strażnicy skrzyń i fale Kryształu dochodzą później).
func _build_mechanics() -> void:
	if mechanics.has("crystal"):
		_build_crystal()
	if mechanics.has("uroczysko"):
		# największa z kilku wolnych komnat - krąg potrzebuje miejsca
		var best := Rect2i()
		for room in _mechanic_rooms(3):
			if room.get_area() > best.get_area():
				best = room
		if best.get_area() > 0:
			_add_uroczysko(best)
	if mechanics.has("zertwa"):
		# największa z kilku wolnych komnat (bez Uroczyska) - fale potrzebują miejsca wokół kręgu
		var taken: Array[Rect2i] = []
		for stone in uroczyska:
			taken.append(_room_of(stone.position))
		var best := Rect2i()
		for room in _mechanic_rooms(4):
			if not taken.has(room) and room.get_area() > best.get_area():
				best = room
		if best.get_area() > 0:
			_add_zertwa(best)
	if mechanics.has("skarbnik"):
		# komnaty bez Uroczyska i Kręgu Żertwy (fale potrzebują miejsca); więcej Skarbników - premie mechanik
		var taken: Array[Rect2i] = []
		for other: Node2D in uroczyska + zertwy:
			taken.append(_room_of(other.position))
		var count := int(config.get("mechanic_bonus", {}).get("skarbnik_count", Dungeons.SKA_COUNT)) + power_extra("skarbnik", 1)
		var spare := _mechanic_rooms(rooms.size()).filter(func(room: Rect2i) -> bool: return not taken.has(room))
		for room: Rect2i in spare.slice(0, count):
			_add_skarbnik(room)
	if mechanics.has("chests"):
		var kinds := {}
		for kind: String in Dungeons.CHEST_KINDS:
			kinds[kind] = Dungeons.CHEST_KINDS[kind]["weight"]
		for room in _mechanic_rooms(_rng.randi_range(Dungeons.CHESTS.x, Dungeons.CHESTS.y) + power_extra("chests", 2)):
			var traits: Array[String] = []
			for id: String in Dungeons.CHEST_TRAITS:
				if _rng.randf() < Dungeons.CHEST_TRAITS[id]["chance"]:
					traits.append(id)
			_add_chest(Dungeons.weighted(_rng, kinds), traits, room)
	if mechanics.has("shrine"):
		var gifts := Dungeons.SHRINES.duplicate()
		_shuffle(gifts)
		for room in _mechanic_rooms(mini(gifts.size(), _rng.randi_range(Dungeons.SHRINE_COUNT.x, Dungeons.SHRINE_COUNT.y) + power_extra("shrine", 1))):
			_add_shrine(gifts.pop_back(), room)
	if mechanics.has("elites"):
		for room in _mechanic_rooms(_rng.randi_range(Dungeons.ELITES.x, Dungeons.ELITES.y) + power_extra("elites", 2)):
			_add_elite(Dungeons.roll_elite_traits(_rng), room)


## Elita w komnacie: jeden z potworów gromady (nie strażnik, nie nieruchomy jak kokon) dostaje cechy
## (DungeonElite); w pustej komnacie elita staje sama.
func _add_elite(traits: Array[String], room: Rect2i) -> DungeonElite:
	var area := Rect2(Vector2(room.position) * CELL, Vector2(room.size) * CELL).grow(CELL / 2.0)
	var candidates: Array[Dictionary] = []
	for spawn: Dictionary in w._goblin_spawns:
		var goblin: Goblin = w._live_goblins.get(spawn.get("id", -1))
		if goblin != null and goblin.elite == null and not goblin is Boss and not goblin.fearless \
				and area.has_point(goblin.position):
			candidates.append(spawn)
	var spawn: Dictionary
	if candidates.is_empty():
		var spot := _mechanic_spot(room)
		spawn = _spawn(_pick(climate["monsters"]), spot, spot + Vector2(0, 20), level)
	else:
		spawn = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var target: Goblin = w._live_goblins.get(spawn["id"])
	if target == null:
		return null
	var elite := DungeonElite.promote(target, traits, self, spawn["type"])
	elites.append(elite)
	return elite


## Komnaty na skrzynie i kapliczki: zwykłe komnaty (bez wejściowej, strażnika, Kryształu i ołtarza), każda inna,
## póki starczy.
func _mechanic_rooms(count: int) -> Array[Rect2i]:
	var pool: Array[Rect2i] = []
	for room in rooms:
		if room != start_room and room != boss_room and room != altar_room and not (event != "" and room == event_room):
			pool.append(room)
	_shuffle(pool)
	var result: Array[Rect2i] = []
	while result.size() < count and not pool.is_empty():
		result.append(pool.pop_back())
	return result


func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


## Wolne miejsce na obiekt mechaniki w komnacie: z kilkunastu punktów ten, przy którym stoi najmniej wystroju
## (rekwizyty w w.entities, bez potworów), nie w ścianie i z dala od innych skrzyń i kapliczek.
func _mechanic_spot(room: Rect2i) -> Vector2:
	var props: Array[Vector2] = []
	var area := Rect2(Vector2(room.position) * CELL, Vector2(room.size) * CELL).grow(CELL)
	for node in w.entities.get_children():
		if node is Node2D and not node is Goblin and area.has_point(node.position):
			props.append(node.position)
	var best := _free_spot(Vector2(room.get_center()) * CELL + Vector2(0, CELL / 2.0), Vector2(room.get_center()) * CELL)
	var best_score := INF
	for attempt in 30:
		var spot := _room_point(room, 48.0)
		if _blocked(spot, 22.0):
			continue
		var score := 0.0
		for at in props:
			var d := at.distance_to(spot)
			if d < 70.0:
				score += 70.0 - d
		for other: Node2D in chests + shrines + uroczyska + zertwy + skarbniki:
			if other.position.distance_to(spot) < 120.0:
				score += 500.0
		if score < best_score:
			best_score = score
			best = spot
	return best


## Napisy nad obiektami w mroku lochu: rozjaśnienie, które znosi przyciemnienie świata (CanvasModulate).
func label_boost() -> Color:
	var tint: Color = climate["decor"]["tint"] if climate.has("decor") else climate["tint"]
	return Color(1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b)


func _add_chest(kind: String, traits: Array[String], room: Rect2i) -> DungeonChest:
	var chest := DungeonChest.create(self, kind, traits)
	chest.position = _mechanic_spot(room)
	chests.append(chest)
	w.entities.add_child(chest)
	_glow(chest.position + Vector2(0, -8), Dungeons.CHEST_KINDS[kind]["glow"], Vector2(110, 80))
	w._map_markers.append({"position": chest.position, "color": Color(1.0, 0.85, 0.35), "size": 2.0})
	return chest


## Uroczysko (menhir otwierający krąg upiorów) na środku komnaty.
func _add_uroczysko(room: Rect2i) -> Uroczysko:
	var stone := Uroczysko.create(self)
	var center := Vector2(room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	stone.position = _free_spot(center, Vector2(room.get_center()) * CELL)
	uroczyska.append(stone)
	w.entities.add_child(stone)
	stone.glow = _glow(stone.position + Vector2(0, -20), Color(Uroczysko.COLOR, 0.45), Vector2(140, 110))
	w._map_markers.append({"position": stone.position, "color": Uroczysko.COLOR, "size": 2.5})
	return stone


## Krąg Żertwy (pień ofiarny) na środku komnaty.
func _add_zertwa(room: Rect2i) -> Zertwa:
	var altar := Zertwa.create(self)
	var center := Vector2(room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	altar.position = _free_spot(center, Vector2(room.get_center()) * CELL)
	zertwy.append(altar)
	w.entities.add_child(altar)
	altar.glow = _glow(altar.position + Vector2(0, -16), Color(Zertwa.COLOR, 0.45), Vector2(140, 110))
	w._map_markers.append({"position": altar.position, "color": Zertwa.COLOR, "size": 2.5})
	return altar


## Skarbnik (duch górnika przy kupce skarbów) w komnacie.
func _add_skarbnik(room: Rect2i) -> Skarbnik:
	var spirit := Skarbnik.create(self)
	spirit.position = _mechanic_spot(room)
	skarbniki.append(spirit)
	w.entities.add_child(spirit)
	spirit.glow = _glow(spirit.position + Vector2(0, -16), Color(Skarbnik.COLOR, 0.45), Vector2(130, 100))
	w._map_markers.append({"position": spirit.position, "color": Skarbnik.COLOR, "size": 2.5})
	return spirit


## Komnata, w której leży punkt (pusty prostokąt - w korytarzu).
func _room_of(pos: Vector2) -> Rect2i:
	var cell := Vector2i((pos / CELL).round())
	for room in rooms:
		if room.grow(1).has_point(cell):
			return room
	return Rect2i()


func _add_shrine(gift: String, room: Rect2i) -> DungeonShrine:
	var shrine := DungeonShrine.create(self, gift)
	shrine.position = _mechanic_spot(room)
	shrines.append(shrine)
	w.entities.add_child(shrine)
	shrine.glow = _glow(shrine.position + Vector2(0, -14), Color(DungeonShrine.COLORS[gift], 0.5), Vector2(130, 100))
	w._map_markers.append({"position": shrine.position, "color": Color(0.55, 0.85, 1.0), "size": 2.0})
	return shrine


func _build_crystal() -> void:
	if event == "":
		return
	crystal = WatraCrystal.new()
	crystal.dungeon = self
	crystal.variant = event
	crystal.room = event_room
	crystal.level = level
	crystal.tier = Dungeons.config_tier(config)
	crystal.count_mult = Dungeons.mult(config, "count")
	crystal.position = Vector2(event_room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	w.entities.add_child(crystal)
	_glow(crystal.position + Vector2(0, -16), Color(1.0, 0.45, 0.2, 0.6), Vector2(200, 140))
	w._map_markers.append({"position": crystal.position, "color": Color(1.0, 0.45, 0.25), "size": 3.0})


## Odległość (w krokach po podłodze) od wierzchołka do wszystkich innych.
func _distances(from: Vector2i) -> Dictionary:
	var result := {from: 0}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var v: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = v + d
			if floor_cells.has(n) and not result.has(n):
				result[n] = result[v] + 1
				queue.append(n)
	return result


# ---------------------------------------------------------------- budowa
func _build_tiles() -> void:
	var source := TileSetAtlasSource.new()
	source.texture = climate["tiles"]
	source.texture_region_size = Vector2i(CELL, CELL)
	for coord: Vector2i in WANG.values():
		if not source.has_tile(coord):
			source.create_tile(coord)
	# pełne kafelki podłogi i skały w 4 odbiciach - powtarzający się wzór (np. rzędy grzybów) się rozmywa;
	# kafelek jest bezszwowy, więc odbity styka się z sąsiadami lustrzaną krawędzią
	for coord: Vector2i in [WANG["llll"], WANG["uuuu"]]:
		for flips in [[true, false], [false, true], [true, true]]:
			var alternative := source.create_alternative_tile(coord)
			source.get_tile_data(coord, alternative).flip_h = flips[0]
			source.get_tile_data(coord, alternative).flip_v = flips[1]
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(CELL, CELL)
	tiles.add_source(source, 0)
	var layer := TileMapLayer.new()
	layer.name = "DungeonTiles"
	layer.tile_set = tiles
	for x in GRID.x - 1:
		for y in GRID.y - 1:
			var key := _key(Vector2i(x, y))
			# na zewnątrz kafelki tylko przy klifach - resztę rysuje podłoże (SoftGround)
			if outdoor and key == "llll":
				continue
			var alternative := _rng.randi() % 4 if key == "llll" or key == "uuuu" else 0
			layer.set_cell(Vector2i(x, y), 0, WANG[key], alternative)
	w.ground.add_sibling(layer)


## Kolizje: kwadrat wokół każdego wierzchołka skały i lica ściany, łączone w poziome pasy.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "DungeonWalls"
	# ściany podziemi to granica (zryw i Mgnienie ich nie przeskakują); na zewnątrz teren to zwykłe przeszkody
	body.collision_layer = 1 if outdoor else 1 | w.BOUNDS_LAYER
	w.add_child(body)
	for y in GRID.y:
		var run_start := -1
		var run_kind := ""
		for x in GRID.x + 1:
			var kind := _label(Vector2i(x, y)) if x < GRID.x else "l"
			kind = "" if kind == "l" else kind
			if kind != run_kind:
				if run_kind != "":
					_wall_box(body, run_start, x - 1, y, run_kind)
				run_start = x
				run_kind = kind


func _wall_box(body: StaticBody2D, from_x: int, to_x: int, y: int, kind: String) -> void:
	var top := y * CELL - CELL / 2.0
	var bottom := y * CELL + (FACE_DEPTH if kind == "t" else CELL / 2.0)
	var rect := Rect2(from_x * CELL - CELL / 2.0, top, (to_x - from_x + 1) * CELL, bottom - top)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)


## Minimapa: każdy kafelek gry wg najbliższego wierzchołka (podłoga, lico, skała).
func _build_map() -> void:
	var tile: int = w.TILE
	for x in w.map_size.x:
		for y in w.map_size.y:
			var px := (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
			var v := Vector2i((px / CELL).round())
			var label := _label(v)
			var color: Color = climate["map_floor"] if label == "l" else climate["map_wall"]
			if label == "t":
				color = climate["map_wall"].lerp(climate["map_floor"], 0.35)
			elif outdoor and waters.has(v):
				color = climate["map_water"]
			elif outdoor and vines.has(v):
				color = climate["map_vines"]
			elif outdoor and palisades.has(v):
				color = climate["map_yard"]
			elif outdoor and label == "u" and not cliffs.has(v):
				color = climate["map_trees"]
			elif outdoor and path_tiles.has(Vector2i(x, y)):
				color = climate["map_path"]
			w._map_props[Vector2i(x, y)] = color


func _build_atmosphere() -> void:
	var dark := CanvasModulate.new()
	dark.color = climate["decor"]["tint"] if climate.has("decor") else climate["tint"]
	w.add_child(dark)
	if outdoor:
		# wieczór pod gołym niebem - gracz nie niesie światła, świecą latarnie i ogniska
		return
	_light = _glow(Vector2.ZERO, Color(1.0, 0.85, 0.65, 0.42 if climate.has("decor") else 0.35),
			Vector2(340, 250) if climate.has("decor") else Vector2(300, 220))


## Ciepła (albo zimna) plama światła na podłodze, pod postaciami.
func _glow(pos: Vector2, color: Color, glow_size: Vector2) -> Sprite2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, Color(color, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(glow_size.x)
	texture.height = int(glow_size.y)
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var glow := Sprite2D.new()
	glow.texture = texture
	glow.position = pos
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	w.floors.add_child(glow)
	return glow


## Bezpieczny punkt podłogi komnaty (z dala od ścian i od lica ściany na północy), w pikselach.
func _room_point(room: Rect2i, margin := 0.0) -> Vector2:
	var from := Vector2(room.position.x, room.position.y + 1) * CELL + Vector2(margin, margin)
	var to := Vector2(room.end.x - 1, room.end.y - 1) * CELL - Vector2(margin, margin)
	return Vector2(_rng.randf_range(from.x, maxf(from.x, to.x)), _rng.randf_range(from.y, maxf(from.y, to.y)))


## Pochodnie (koksowniki, świecące grzyby) pod północną ścianą komnat, wystrój pod ścianami i porozrzucany
## po komnatach i korytarzach (bez kolizji, tylko w wolnych miejscach).
func _build_props() -> void:
	var lamp: Texture2D = load(climate["lamp"])
	var frames: int = climate["lamp_frames"]
	var props: Array = climate["props"].map(func(path: String) -> Texture2D: return load(path))
	var wall_props: Array = climate["wall_props"].map(func(path: String) -> Texture2D: return load(path))
	for path in _corridors:
		for i in range(3, path.size() - 3, 5):
			if _rng.randf() < 0.6:
				var at := (path[i] + Vector2(0.5, 0.5)) * CELL + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(-14, 14))
				_scatter_prop(props.pick_random(), at)
	for room in rooms:
		var y := (room.position.y + 1) * CELL + 6.0
		var count := maxi(1, room.size.x / 3)
		for i in count:
			var x := lerpf(room.position.x * CELL + 24.0, (room.end.x - 1) * CELL - 24.0, (i + 0.5) / count)
			var sprite: Sprite2D = w._village_prop(lamp, Vector2(x, y), Vector2(8, 4), frames)
			if frames == 2:
				sprite.frame = _rng.randi() % 2
				w._flicker(sprite)
			_glow(Vector2(x, y - 6), climate["light"], Vector2(150, 100))
		# między pochodniami pod ścianą: skrzynie, świece, kokony...
		for i in count:
			if _rng.randf() < 0.7:
				var x := lerpf(room.position.x * CELL + 24.0, (room.end.x - 1) * CELL - 24.0, (i + 1.0) / count)
				_scatter_prop(wall_props.pick_random(), Vector2(x + _rng.randf_range(-10, 10), y + 4.0))
		if room == start_room:
			continue
		for i in maxi(3, room.size.x * room.size.y / 6):
			_scatter_prop(props.pick_random(), _room_point(room, 16.0))


## Rekwizyt bez kolizji w wolnym miejscu (punkt w ścianie przepada).
func _scatter_prop(tex: Texture2D, at: Vector2) -> void:
	if _blocked(at, 4.0):
		return
	var sprite: Sprite2D = w._village_prop(tex, at, Vector2.ZERO)
	sprite.flip_h = _rng.randf() < 0.5
	sprite.modulate = Color(0.9, 0.9, 0.9)


## Płomienie Watry w komnacie wejściowej: wejście w nie wraca do Ostoi (tak samo te po pokonaniu strażnika).
func _build_entrance() -> void:
	var center := Vector2(start_room.get_center()) * CELL
	var pos := Vector2(center.x, start_room.position.y * CELL + 84.0)
	_add_portal(pos, Lang.t("Płomienie Watry - powrót do Ostoi"))
	w._spawn_point = pos + Vector2(0, 56)
	w._arrivals["start"] = w._spawn_point


func _add_portal(pos: Vector2, text: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PORTAL
	sprite.hframes = 6
	sprite.offset = Vector2(0, -PORTAL.get_height() / 2.0 + 10.0)
	sprite.position = pos
	w.entities.add_child(sprite)
	_glow(pos + Vector2(0, -10), Color(1.0, 0.55, 0.2, 0.7), Vector2(240, 170))
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 10)
	label.position = pos + Vector2(-80, -92)
	label.z_index = 30
	w.add_child(label)
	_portals.append({"sprite": sprite, "rect": Rect2(pos + Vector2(-26, -18), Vector2(52, 26))})
	w._map_markers.append({"position": pos, "color": Color(1.0, 0.6, 0.25), "size": 3.0})


## Potwory: gromady w komnatach (im dalej od wejścia, tym o poziom wyżej), mniejsze grupki w długich korytarzach,
## strażnik ze świtą w komnacie skarbca.
func _populate(count_mult: float) -> void:
	var weights: Dictionary = climate["monsters"]
	var lords := Dungeons.added(config, "lords") > 0.0
	var lord_pool := Idols.boss_pool(climate["boss"])
	var distance := _distances(start_room.position + start_room.size / 2)
	var far := 1
	for d: int in distance.values():
		far = maxi(far, d)
	for room in rooms:
		if room == start_room or (event != "" and room == event_room):
			continue
		var depth: float = float(distance.get(room.position + room.size / 2, 0)) / far
		var lvl := level + (1 if depth > 0.6 else 0)
		var total := roundi(room.size.x * room.size.y * DENSITY * count_mult)
		if room == boss_room:
			total = roundi(6 * count_mult)
		elif lords:
			# Bożek Władców: zamiast gromady boss krainy
			var at := _room_point(room, 28.0)
			_spawn(lord_pool[_rng.randi() % lord_pool.size()], at, at + Vector2(0, 40), lvl + Dungeons.BOSS_BONUS)
			continue
		while total > 0:
			var n := mini(total, _rng.randi_range(PACK.x, PACK.y))
			total -= n
			var center := _room_point(room, 28.0)
			for i in n:
				var pos := center + Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-22, 22))
				_spawn(_pick(weights), pos, center, lvl)
	for path in _corridors:
		if path.size() < 9:
			continue
		var mid := (path[path.size() / 2] + Vector2(0.5, 0.5)) * CELL
		# korytarz przez komnatę Kryształu Watry - ta zostaje pusta do czasu zdarzenia
		if event != "" and Rect2(Vector2(event_room.position) * CELL, Vector2(event_room.size) * CELL).grow(CELL).has_point(mid):
			continue
		for i in roundi(_rng.randi_range(2, 4) * count_mult):
			_spawn(_pick(weights), mid + Vector2(_rng.randf_range(-16, 16), _rng.randf_range(-16, 16)), mid, level)


func _pick(weights: Dictionary) -> String:
	var total := 0.0
	for kind: String in weights:
		total += float(weights[kind])
	var roll := _rng.randf() * total
	for kind: String in weights:
		roll -= float(weights[kind])
		if roll <= 0.0:
			return kind
	return weights.keys()[0]


func _spawn(kind: String, pos: Vector2, look_at: Vector2, lvl: int) -> Dictionary:
	var spawn := {"type": kind, "position": _free_spot(pos, look_at), "sitting": false, "look_at": look_at, "level": lvl, "lurk": false}
	w._add_goblin_spawn(spawn)
	# w lochu potwory nie odpuszczają pogoni (droga i tak prowadzi wokół ścian); strażnik pilnuje skarbca
	var goblin: Goblin = w._live_goblins.get(spawn["id"])
	if goblin != null and not goblin is Boss:
		goblin.leash_radius = LEASH
	return spawn


## Czy punkt (z zapasem `margin` na ciało potwora) leży w kolizji skały albo lica ściany (patrz _wall_box).
func _blocked(pos: Vector2, margin := 10.0) -> bool:
	var center := Vector2i((pos / CELL).round())
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var v := center + Vector2i(dx, dy)
			var kind := _label(v)
			if solid.has(v) and Rect2(Vector2(v) * CELL + Vector2(-24, -22), Vector2(48, 30)).grow(margin).has_point(pos):
				return true
			if kind == "l":
				continue
			var top := v.y * CELL - CELL / 2.0
			var bottom := v.y * CELL + (FACE_DEPTH if kind == "t" else CELL / 2.0)
			var rect := Rect2(v.x * CELL - CELL / 2.0, top, CELL, bottom - top).grow(margin)
			if rect.has_point(pos):
				return true
	return false


## Wolne miejsce dla potwora: sam punkt, a gdy wypada w ścianie - pierwszy wolny punkt w stronę `toward`
## albo najbliższy wolny wierzchołek podłogi (inaczej potwór stałby w ścianie, nietrafialny).
func _free_spot(pos: Vector2, toward: Vector2) -> Vector2:
	if not _blocked(pos):
		return pos
	for i in range(1, 9):
		var spot := pos.lerp(toward, i / 8.0)
		if not _blocked(spot):
			return spot
	var best := toward
	var best_d := INF
	var center := Vector2i((pos / CELL).round())
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			var spot := Vector2(center + Vector2i(dx, dy)) * CELL
			if not _blocked(spot) and spot.distance_squared_to(pos) < best_d:
				best_d = spot.distance_squared_to(pos)
				best = spot
	return best


## Strażnik na środku najdalszej komnaty i zamknięta skrzynia skarbca pod jej północną ścianą.
func _build_vault() -> void:
	var center := Vector2(boss_room.get_center()) * CELL + Vector2(0, CELL / 2.0)
	var spawn := _spawn(Pinnacles.kind(pinnacle), center, center + Vector2(0, 40), level) if pinnacle != "" \
			else _spawn(climate["boss"], center, center + Vector2(0, 40), level + Dungeons.BOSS_BONUS)
	_boss = w._live_goblins.get(spawn["id"])
	if _boss != null:
		_boss.died.connect(_on_boss_died)
	_chest = Sprite2D.new()
	_chest.texture = CHEST
	_chest.scale = Vector2(1.6, 1.6)
	_chest.offset = Vector2(0, -CHEST.get_height() / 2.0)
	_chest.position = Vector2(center.x, (boss_room.position.y + 1) * CELL + 20.0)
	_chest.modulate = Color(0.75, 0.75, 0.8)
	w.entities.add_child(_chest)
	_glow(_chest.position, Color(1.0, 0.85, 0.4, 0.4), Vector2(120, 80))
	w._map_markers.append({"position": _chest.position, "color": Color(1.0, 0.85, 0.3), "size": 3.0})


## Strażnik pokonany: skarbiec wysypuje łup, obok buchają płomienie powrotu.
func _on_boss_died(_boss_node: Goblin = null) -> void:
	if _vault_open:
		return
	_vault_open = true
	w.player.quests.note_event("dungeon_clear")
	if pinnacle != "":
		_pinnacle_rewards()
		return
	var treasure := Dungeons.mult(config, "treasure")
	var loot_level := level + Dungeons.BOSS_BONUS
	var level_bonus := int(Dungeons.added(config, "item_level"))
	var quality := Dungeons.added(config, "quality")
	var at := _chest.position + Vector2(0, 16)
	_chest.modulate = Color.WHITE
	_drop(at, "gold", roundi(Levels.gold(loot_level) * 30.0 * treasure * Dungeons.mult(config, "gold")))
	for i in roundi(3 * treasure * Idols.multiplier(config.get("idols", []), "loot")):
		_drop(at, Loot.drop_at_level(loot_level, 0.3 + quality, Loot.MAGIC, level_bonus), 1)
	if treasure > 1.0:
		for i in 2:
			_drop(at, Loot.drop_at_level(loot_level, 0.5 + quality, Loot.RARE, level_bonus), 1)
	# kamieni zaklinających tu nie ma - jedynym źródłem w lochach jest Kryształ Watry
	_drop(at, "blessed_stone", roundi(_rng.randi_range(1, 3) * treasure))
	if Dungeons.config_tier(config) >= Essences.HEART_MIN_TIER and _rng.randf() < Essences.HEART_VAULT_CHANCE * treasure:
		_drop(at, Essences.HEART, 1)
	if _rng.randf() < ItemCraft.RUNE_VAULT_CHANCE * treasure:
		_drop(at, ItemCraft.roll_rune(Dungeons.config_tier(config), _rng), 1)
	# runy z Bożka Run
	for i in int(Dungeons.added(config, "vault_runes")):
		_drop(at, ItemCraft.roll_rune(Dungeons.config_tier(config), _rng), 1)
	if _rng.randf() < Gems.RADIUS_VAULT_CHANCE * treasure:
		_drop(at, Gems.roll_radius(Dungeons.config_tier(config)), 1)
	var bag := Bags.roll_vault(loot_level, treasure)
	if bag != "":
		_drop(at, bag, 1)
	if _rng.randf() < Dungeons.VAULT_LEGEND_CHANCE * treasure * Idols.multiplier(config.get("idols", []), "legend"):
		_drop(at, Loot.legendary_at_level(Dungeons.VAULT_LEGENDS.pick_random(), loot_level), 1)
	Sfx.play("quest_ready")
	_add_portal(Vector2(boss_room.get_center()) * CELL + Vector2(0, CELL * 1.2), Lang.t("Płomienie Watry - powrót do Ostoi"))
	_drop_fragment(at)
	# węzeł Mapy Nawii oczyszczony - odsłania sąsiednie i daje punkt Watry
	if config.has("nawia_node") and w.player.boons.clear_nawia_node(int(config["nawia_node"])):
		w.hud.show_banner(Lang.t("Węzeł Nawii oczyszczony! Zdobywasz punkt Watry\nPłomienie Watry zabiorą cię do Ostoi"),
				Color(0.75, 0.65, 1.0))
		return
	w.hud.show_banner(Lang.t("Strażnik pokonany! Skarbiec otwarty\nPłomienie Watry zabiorą cię do Ostoi"), Color(1.0, 0.8, 0.4))


## Strażnik węzła Nawii czasem zostawia fragment klucza boga swojego obszaru (Pinnacles.fragment_chance).
func _drop_fragment(at: Vector2) -> void:
	if not config.has("nawia_node"):
		return
	var nodes := NawiaMap.nodes(int(w._seed))
	var id := int(config["nawia_node"])
	if id < 0 or id >= nodes.size():
		return
	var god := Pinnacles.god_of_area(nodes[id]["area"])
	if god != "" and (Game.dev_mode or _rng.randf() < Pinnacles.fragment_chance(int(config.get("tier", 8)))):
		_drop(at + Vector2(0, 14), Pinnacles.fragment(god), 1)


## Bóg pokonany: skarbiec (Pinnacles.vault_rewards), punkty Watry za pierwsze zwycięstwo, płomienie powrotu.
func _pinnacle_rewards() -> void:
	var at := _chest.position + Vector2(0, 16)
	_chest.modulate = Color.WHITE
	_drop(at, "gold", roundi(Levels.gold(level) * 60.0 * Dungeons.mult(config, "gold")))
	var lord := Pinnacles.is_lord(pinnacle)
	for reward: Array in Pinnacles.vault_rewards(level, _rng, lord, pomrok):
		_drop(at, reward[0], reward[1])
	var unlocked: int = w.player.boons.pomrok_unlocked
	var first: bool = w.player.boons.defeat_pinnacle(pinnacle, pomrok)
	Sfx.play("quest_ready")
	_add_portal(Vector2(boss_room.get_center()) * CELL + Vector2(0, CELL * 1.2), Lang.t("Płomienie Watry - powrót do Ostoi"))
	var text := Lang.t("%s pokonany!") % Pinnacles.god_name(pinnacle)
	if first:
		text += "\n" + Lang.t("Pierwsze zwycięstwo: +%d punkty Watry") % (Pinnacles.LORD_POINTS if lord else Pinnacles.FIRST_KILL_POINTS)
	if lord and first:
		text += "\n" + Lang.t("Zdobywasz tytuł: Pogromca Hordy")
	if lord and w.player.boons.pomrok_unlocked > unlocked:
		text += "\n" + Lang.t("Odblokowano Pomrok %s") % Pinnacles.roman(w.player.boons.pomrok_unlocked)
	w.hud.show_banner(text, Pinnacles.GODS[pinnacle]["color"])


# ---------------------------------------------------------------- droga przez loch
## Czy po wierzchołku da się chodzić (podłoga, nie skała i nie lico ściany).
func _walkable(v: Vector2i) -> bool:
	return _label(v) == "l" and not solid.has(v)


## Krok po skosie tylko wtedy, gdy oba boczne wierzchołki są wolne - bez ścinania rogów ścian.
func _can_step(from: Vector2i, step: Vector2i) -> bool:
	if not _walkable(from + step):
		return false
	return step.x == 0 or step.y == 0 or (_walkable(from + Vector2i(step.x, 0)) and _walkable(from + Vector2i(0, step.y)))


## Odległości od wierzchołka gracza do całej podłogi lochu (przeszukiwanie wszerz).
func _update_flow(target: Vector2i) -> void:
	_flow_from = target
	_flow = {target: 0}
	var queue: Array[Vector2i] = [target]
	var head := 0
	while head < queue.size():
		var v := queue[head]
		head += 1
		for step in STEPS:
			var n := v + step
			if not _flow.has(n) and _can_step(v, step):
				_flow[n] = _flow[v] + 1
				queue.append(n)


## Kierunek, w którym potwór z punktu `from` ma iść do gracza: do sąsiedniego wierzchołka bliżej gracza.
## Zero, gdy gracz jest tuż obok (wtedy prosto) albo potwór stoi poza podłogą.
func steer(from: Vector2) -> Vector2:
	var v := Vector2i((from / CELL).round())
	var here: int = _flow.get(v, -1)
	if here >= 0 and here <= 1:
		return Vector2.ZERO
	var best := Vector2i(-1, -1)
	var best_d := here if here >= 0 else 1 << 30
	for step in STEPS:
		var n := v + step
		var d: int = _flow.get(n, -1)
		if d >= 0 and d < best_d and (here < 0 or _can_step(v, step)):
			best_d = d
			best = n
	if best.x < 0:
		return Vector2.ZERO
	return (Vector2(best) * CELL - from).normalized()


func _drop(at: Vector2, id: String, amount: int) -> void:
	if amount <= 0:
		return
	var pickup: Pickup = Goblin.pickup_scene().instantiate()
	pickup.item_id = id
	pickup.amount = amount
	pickup.position = at + Vector2(_rng.randf_range(-28, 28), _rng.randf_range(-6, 18))
	w.entities.add_child(pickup)


func _process(delta: float) -> void:
	if w == null:
		return
	_time += delta
	var frame := int(_time * PORTAL_FPS) % 6
	for portal: Dictionary in _portals:
		portal["sprite"].frame = frame
	if _light != null:
		_light.global_position = w.player.global_position + Vector2(0, -8)
	for flame: Array in flames:
		var phase: float = flame[2]
		flame[0].modulate.a = flame[1] * (0.86 + 0.08 * sin(_time * 9.0 + phase) + 0.06 * sin(_time * 23.0 + phase * 2.3))
	var player_vertex := Vector2i((w.player.global_position / CELL).round())
	if player_vertex != _flow_from:
		_update_flow(player_vertex)
	if w._traveling or w.player.is_dead:
		return
	for portal: Dictionary in _portals:
		if portal["rect"].has_point(w.player.global_position):
			Sfx.play("magic", 2.0, 0.7)
			w._travel("forest", "watra")
			return
