class_name NawiaMap
## Mapa Nawii - końcówka gry jak atlas w Path of Exile. Zaświaty wylane na świat przez Hordę: koło z Watrą w środku,
## podzielone na 6 obszarów (po jednym na krainę świata), a w każdym obszarze 10 pierścieni węzłów - lochów o stopniach
## 8-17 (Dungeons.TIER_LEVELS, potwory 45-90), od środka na zewnątrz. Węzeł ma stały klimat (w obszarze przeważają
## klimaty pasujące do krainy) i połączenia z sąsiadami. Na początku widać tylko pierwszy pierścień; pokonanie
## strażnika lochu z węzła (Dungeon._on_boss_died) oczyszcza węzeł i odsłania sąsiednie. Każdy nowy oczyszczony węzeł
## daje POINTS_PER_NODE punkty Watry (do drzewka Watry). Układ losuje się z ziarna zapisu (ta sama mapa w jednym zapisie),
## postęp (oczyszczone węzły) trzyma Boons.nawia_cleared. Okno: scripts/ui/nawia_window.gd.
## Błogosławieństwo Watry: oczyszczone węzły obszaru pozwalają przy kapliczce krainy podnieść jej potwory do poziomu
## najtrudniejszego oczyszczonego węzła (blessing_*), z premią do łupu i doświadczenia rosnącą z liczbą węzłów.

## Obszary mapy (krainy świata) w kolejności wokół koła, od góry zgodnie ze wskazówkami zegara.
const AREAS: Array[String] = ["cemetery", "ancient", "mountains", "swamp", "fields", "forest"]
## Klimaty lochów pasujące do krainy (przeważają w jej obszarze) i szansa, że węzeł ma któryś z nich.
const AREA_CLIMATES := {
	"forest": ["mine", "stronghold"], "fields": ["stronghold", "mine"], "swamp": ["flooded"],
	"mountains": ["vineyard"], "ancient": ["roots"], "cemetery": ["catacombs"],
}
const OWN_CLIMATE := 0.75
## Kolory obszarów na mapie.
const AREA_COLORS := {
	"forest": Color(0.35, 0.6, 0.3), "fields": Color(0.8, 0.7, 0.3), "swamp": Color(0.3, 0.55, 0.55),
	"mountains": Color(0.6, 0.6, 0.7), "ancient": Color(0.25, 0.45, 0.25), "cemetery": Color(0.55, 0.45, 0.65),
}
## Liczba węzłów na kolejnych pierścieniach jednego obszaru (pierścień = stopień 8, 9, ...): 15 na obszar, 90 razem.
const RING_NODES: Array[int] = [1, 1, 1, 2, 2, 2, 2, 2, 1, 1]
## Połączenia: druga droga do wewnętrznego pierścienia, droga do sąsiada w pierścieniu, przejście do sąsiedniego obszaru.
const LINK_SECOND := 0.35
const LINK_RING := 0.5
const LINK_CROSS := 0.3
## Mapa otwiera się od tego poziomu postaci (po Leśnym Cmentarzu).
const UNLOCK_LEVEL := 40
## Punkty Watry za każdy nowy oczyszczony węzeł (90 węzłów - 180 punktów; z bogami i Władcą ok. 205 na ~500 węzłów
## drzewka Watry, czyli ok. 40% drzewka).
const POINTS_PER_NODE := 2
## Błogosławieństwo Watry: premia do łupu i doświadczenia za każdy oczyszczony węzeł obszaru (15 węzłów - +30%)
## i rozrzut poziomów krainy wokół poziomu węzła: [przy wejściu, w najdalszym zakątku, bossowie].
const BLESS_BONUS_PER_NODE := 0.02
const BLESS_SPREAD: Array[int] = [-4, 0, 2]

static var _cache_seed := 0
static var _cache: Array[Dictionary] = []


static func first_tier() -> int:
	return Dungeons.BASE_TIERS + 1


static func ring_count() -> int:
	return RING_NODES.size()


## Odległość pierścienia od środka (koło o promieniu 1) - pierwszy z dala od Watry, ostatni przy krawędzi.
static func ring_radius(ring: float) -> float:
	return (ring + 1.6) / (ring_count() + 0.9)


static func node_count() -> int:
	var per_area := 0
	for n in RING_NODES:
		per_area += n
	return per_area * AREAS.size()


## Węzły mapy dla ziarna zapisu: [{"id", "area", "ring", "tier", "climate", "pos" (koło o promieniu 1, środek 0,0),
## "links": Array[int]}]. Wynik jest zapamiętywany - nie zmieniaj zwróconej tablicy.
static func nodes(world_seed: int) -> Array[Dictionary]:
	if _cache_seed == world_seed and not _cache.is_empty():
		return _cache
	_cache = generate(world_seed)
	_cache_seed = world_seed
	return _cache


static func generate(world_seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world_seed, "nawia_map"])
	var result: Array[Dictionary] = []
	## [obszar][pierścień] -> identyfikatory węzłów w kolejności kąta
	var grid: Array = []
	var sector := TAU / AREAS.size()
	var rings := ring_count()
	for a in AREAS.size():
		var area := AREAS[a]
		var start := -PI / 2.0 + (a - 0.5) * sector
		var per_ring: Array = []
		for ring in rings:
			var ids: Array[int] = []
			var count := RING_NODES[ring]
			for k in count:
				var slot := sector / count
				var angle := start + (k + 0.5) * slot + rng.randf_range(-0.22, 0.22) * slot
				var radius := ring_radius(ring + rng.randf_range(-0.2, 0.2))
				var own: Array = AREA_CLIMATES[area]
				var climate: String = own[rng.randi_range(0, own.size() - 1)] if rng.randf() < OWN_CLIMATE \
						else Dungeons.CLIMATE_ORDER[rng.randi_range(0, Dungeons.CLIMATE_ORDER.size() - 1)]
				var id := result.size()
				result.append({"id": id, "area": area, "ring": ring, "tier": first_tier() + ring, "climate": climate,
						"pos": Vector2.from_angle(angle) * radius, "links": [] as Array[int]})
				ids.append(id)
			per_ring.append(ids)
		grid.append(per_ring)
	for a in AREAS.size():
		for ring in rings:
			var ids: Array[int] = grid[a][ring]
			# droga do środka: do najbliższego węzła poprzedniego pierścienia, czasem też do drugiego
			if ring > 0:
				var inner: Array[int] = grid[a][ring - 1]
				for id in ids:
					var by_distance := inner.duplicate()
					by_distance.sort_custom(func(p: int, q: int) -> bool:
						return result[p]["pos"].distance_to(result[id]["pos"]) < result[q]["pos"].distance_to(result[id]["pos"]))
					_link(result, id, by_distance[0])
					if by_distance.size() > 1 and rng.randf() < LINK_SECOND:
						_link(result, id, by_distance[1])
				# każdy węzeł wewnętrzny prowadzi dalej (bez ślepych zaułków poza ostatnim pierścieniem)
				for inner_id in inner:
					if not (result[inner_id]["links"] as Array).any(func(other: int) -> bool: return result[other]["ring"] == ring):
						var nearest := ids[0]
						for id in ids:
							if result[id]["pos"].distance_to(result[inner_id]["pos"]) < result[nearest]["pos"].distance_to(result[inner_id]["pos"]):
								nearest = id
						_link(result, inner_id, nearest)
			for k in ids.size() - 1:
				if rng.randf() < LINK_RING:
					_link(result, ids[k], ids[k + 1])
			# przejście do sąsiedniego obszaru (ostatni węzeł pierścienia z pierwszym w następnym obszarze) - tylko na
			# pierścieniach z kilkoma węzłami, bo pojedyncze stoją na środku obszaru i droga byłaby za długa
			var next: Array[int] = grid[(a + 1) % AREAS.size()][ring]
			if ring >= 1 and ids.size() > 1 and next.size() > 1 and rng.randf() < LINK_CROSS:
				_link(result, ids[ids.size() - 1], next[0])
	return result


static func _link(list: Array[Dictionary], a: int, b: int) -> void:
	if a == b or (list[a]["links"] as Array).has(b):
		return
	(list[a]["links"] as Array).append(b)
	(list[b]["links"] as Array).append(a)


## Odsłonięte węzły (id -> true): pierwszy pierścień, oczyszczone i ich sąsiedzi.
static func revealed(list: Array[Dictionary], cleared: Array) -> Dictionary:
	var result := {}
	for node in list:
		if int(node["ring"]) == 0:
			result[node["id"]] = true
	for id in cleared:
		if id < 0 or id >= list.size():
			continue
		result[id] = true
		for other: int in list[id]["links"]:
			result[other] = true
	return result


## Czy do węzła można wejść (odsłonięty).
static func is_open(list: Array[Dictionary], cleared: Array, id: int) -> bool:
	return revealed(list, cleared).has(id)


## Punkty Watry z mapy (do drzewka Watry).
static func points(cleared: Array) -> int:
	return cleared.size() * POINTS_PER_NODE


## [oczyszczone, wszystkie] węzły obszaru.
static func area_progress(list: Array[Dictionary], cleared: Array, area: String) -> Vector2i:
	var done := 0
	var total := 0
	for node in list:
		if node["area"] == area:
			total += 1
			if cleared.has(node["id"]):
				done += 1
	return Vector2i(done, total)


static func area_cleared(list: Array[Dictionary], cleared: Array, area: String) -> bool:
	var progress := area_progress(list, cleared, area)
	return progress.x >= progress.y


## Czy gracz może już korzystać z mapy (poziom postaci).
static func unlocked(player_level: int) -> bool:
	return player_level >= UNLOCK_LEVEL


## Poziom Błogosławieństwa Watry krainy: poziom najtrudniejszego oczyszczonego węzła jej obszaru (0 - brak).
static func blessing_level(list: Array[Dictionary], cleared: Array, area: String) -> int:
	var best := 0
	for node in list:
		if node["area"] == area and cleared.has(node["id"]):
			best = maxi(best, Dungeons.tier_level(int(node["tier"])))
	return best


## Premia błogosławieństwa do łupu i doświadczenia (ułamek, np. 0.1 = +10%).
static func blessing_bonus(list: Array[Dictionary], cleared: Array, area: String) -> float:
	return area_progress(list, cleared, area).x * BLESS_BONUS_PER_NODE


## Poziomy krainy z błogosławieństwem: [przy wejściu, w najdalszym zakątku, bossowie] (jak Levels.ZONES).
static func blessing_range(level: int) -> Array:
	return [level + BLESS_SPREAD[0], level + BLESS_SPREAD[1], level + BLESS_SPREAD[2]]
