class_name WorldEvents
extends Node
## Losowe wydarzenia w świecie - dziecko gracza, zapisywane. Co INTERVAL sekund w losowej odkrytej krainie (kapliczka)
## zaczyna się wydarzenie (TYPES): najazd na kapliczkę, wędrowny czempion, deszcz meteorytów albo polowanie na bossa.
## Etap 2: world boss (WorldBoss - Żmij Gorynycz w wyższych krainach, Wij w niższych; ogłaszany WORLD_BOSS_WARNING s
## wcześniej, rzadki - WEIGHTS), karawana do eskortowania (wóz na drodze krainy, po dojechaniu - tańsze sklepy) i święto
## w Ostoi (tylko Gobliński Las: ozdoby, tańce, premia „Święto” - Boons; bez rankingu).
## Gracz dostaje komunikat (także w innej krainie), na mapach widać znacznik, a w krainie wydarzenia stawia je świat
## (EventSite): potwory, meteoryty i gromadę podróżników, którzy walczą razem z graczem i rywalizują o wkład.
## Bez gracza wydarzenie rozstrzyga się samo (poza oczami gracza - podróżnicy). Poziom wydarzenia: górny poziom krainy,
## a w starszej krainie - poziom gracza. Na koniec ranking wkładu (punkty: obrażenia zadane potworom wydarzenia,
## rozbite meteoryty) i nagrody wg miejsca: skrzynia z łupem (EventSite), sława gildii i Znaki Zwycięstwa
## (MARK - wymiana u pisarza gildii, VillageServices "marks"). Przegrany najazd gasi kapliczkę na SHRINE_DOWN_TIME s.

signal started(event: Dictionary)
signal finished(result: Dictionary)
signal changed

const TYPES := {
	"raid": {"name": "Najazd na kapliczkę", "duration": 240.0, "color": Color(1.0, 0.5, 0.35),
			"text": "Potwory idą na kapliczkę %s! Obroń ją, zanim zgaśnie."},
	"champion": {"name": "Wędrowny czempion", "duration": 300.0, "color": Color(1.0, 0.75, 0.3),
			"text": "Po krainie %s krąży czempion: %s. Pokonaj go, zanim odejdzie."},
	"meteors": {"name": "Deszcz meteorytów", "duration": 150.0, "color": Color(0.6, 0.8, 1.0),
			"text": "Nad krainą %s spadają meteoryty! Rozbijaj je i bij potwory z kraterów - uważaj na głowę."},
	"hunt": {"name": "Polowanie na bossa", "duration": 360.0, "color": Color(0.85, 0.5, 1.0),
			"text": "Ogłoszono polowanie: %s w krainie %s! Gromada podróżników już rusza."},
	"world_boss": {"name": "World boss", "duration": 780.0, "color": Color(1.0, 0.35, 0.3),
			"text": "Ziemia drży... %s pojawi się w krainie %s za minutę! Zbierają się wszyscy podróżnicy."},
	"caravan": {"name": "Karawana kupiecka", "duration": 420.0, "color": Color(1.0, 0.85, 0.45),
			"text": "Karawana kupiecka rusza drogą przez krainę %s. Eskortuj wóz do końca - kupcy w Ostoi się odwdzięczą."},
	"festival": {"name": "Święto w Ostoi", "duration": 600.0, "color": Color(1.0, 0.6, 0.85),
			"text": "W Ostoi zaczyna się święto! Tańce przy Watrze, więcej doświadczenia i złota, a kupcy sprzedają taniej."},
}
## Waga losowania rodzaju (pozostałe - 1): world boss rzadko (mniej więcej co 4-5 wydarzeń w danej krainie), święto czasem.
const WEIGHTS := {"world_boss": 0.3, "festival": 0.5}
## World boss: kto w której krainie i za ile sekund się pojawia po ogłoszeniu.
const WORLD_BOSSES := {"zmij": ["mountains", "ancient", "cemetery"], "wij": ["forest", "fields", "swamp"]}
const WORLD_BOSS_NAMES := {"zmij": "Żmij Gorynycz", "wij": "Wij"}
const WORLD_BOSS_WARNING := 60.0
## Ile sekund między wydarzeniami (i do pierwszego po wczytaniu gry).
const INTERVAL := Vector2(600.0, 900.0)
const FIRST_DELAY := Vector2(240.0, 420.0)
## Bossowie polowań i ich krainy (w przyszłości kolejni silni bossowie).
const HUNT_BOSSES := {"hydra": "swamp", "gryf": "fields"}
## Cechy czempionów: nazwa, kolor (modulate) i zachowanie (EventSite / ChampionAura).
const TRAITS := {
	"fiery": {"name": "Płomienny", "color": Color(1.6, 0.85, 0.55), "text": "zostawia płonący ślad"},
	"vampiric": {"name": "Wampiryczny", "color": Color(1.4, 0.55, 0.6), "text": "leczy się w walce"},
	"swift": {"name": "Rączy", "color": Color(0.8, 1.3, 1.5), "text": "bardzo szybki"},
	"stone": {"name": "Kamienny", "color": Color(0.85, 0.85, 0.8), "text": "ogromna wytrzymałość, ale wolny"},
	"summoner": {"name": "Przywoływacz", "color": Color(1.2, 0.8, 1.6), "text": "przyzywa pomocników"},
}
const SHRINE_DOWN_TIME := 600.0
const MARK := "victory_mark"
## Znaki Zwycięstwa wg miejsca w rankingu (indeks 0 - pierwsze miejsce, ostatni - pozostali) i za udział w porażce.
const MARKS := [5, 3, 3, 2]
const MARKS_FAIL := 1
const FAME := 3
const FAME_FIRST := 5
## Szansa sukcesu wydarzenia rozstrzyganego bez gracza.
const OFFSCREEN_SUCCESS := 0.7
const PLAYER := "Ty"

## Trwające wydarzenie: {type, zone, title, level, left, duration, trait, boss, shrine, contrib {imię: punkty}} albo {}.
var active := {}
var next_in := 0.0
## Zgaszone kapliczki: id -> sekundy do ponownego rozpalenia.
var shrine_down := {}
## Krainy, w których może zacząć się wydarzenie (odkryte kapliczki) - ustawia świat.
var known_zones: Array = []
var last_result := {}
var _player: Player


func setup(player: Player) -> void:
	_player = player
	next_in = randf_range(FIRST_DELAY.x, FIRST_DELAY.y)


func _process(delta: float) -> void:
	for id: String in shrine_down.keys():
		shrine_down[id] = float(shrine_down[id]) - delta
		if shrine_down[id] <= 0.0:
			shrine_down.erase(id)
	if active.is_empty():
		next_in -= delta
		if next_in <= 0.0:
			next_in = randf_range(INTERVAL.x, INTERVAL.y)
			start_random()
		return
	active["left"] = float(active["left"]) - delta
	if float(active.get("warn", 0.0)) > 0.0:
		active["warn"] = float(active["warn"]) - delta
	# poza krainą gracza (albo zanim świat je postawi) wydarzenie rozstrzyga się samo; święto po prostu się kończy
	if active["left"] <= 0.0 and not active.get("built", false):
		finish(active["type"] == "festival" or randf() < OFFSCREEN_SUCCESS)


## Wydarzenia możliwe w krainie.
static func types_for(zone: String) -> Array[String]:
	var result: Array[String] = ["champion", "meteors", "caravan", "world_boss"]
	if zone != "forest":
		result.append("raid")
	else:
		result.append("festival")
	if zone in HUNT_BOSSES.values():
		result.append("hunt")
	return result


## Losowy rodzaj z wagami (WEIGHTS).
static func pick_type(types: Array[String]) -> String:
	var total := 0.0
	for type: String in types:
		total += float(WEIGHTS.get(type, 1.0))
	var roll := randf() * total
	for type: String in types:
		roll -= float(WEIGHTS.get(type, 1.0))
		if roll <= 0.0:
			return type
	return types[-1]


static func world_boss_for(zone: String) -> String:
	for boss: String in WORLD_BOSSES:
		if zone in WORLD_BOSSES[boss]:
			return boss
	return "wij"


func start_random() -> bool:
	var zones := known_zones.filter(func(z: String) -> bool: return Levels.ZONES.has(z))
	if zones.is_empty():
		return false
	var zone: String = zones.pick_random()
	return start(pick_type(types_for(zone)), zone)


## Początek wydarzenia (także z trybu deweloperskiego i testów).
func start(type: String, zone: String) -> bool:
	if not active.is_empty() or not TYPES.has(type) or not Levels.ZONES.has(zone) or not type in types_for(zone):
		return false
	var level: int = Levels.ZONES[zone][1]
	if _player != null:
		level = maxi(level, _player.stats.level)
	active = {"type": type, "zone": zone, "level": level, "left": TYPES[type]["duration"], "duration": TYPES[type]["duration"],
			"contrib": {}, "trait": "", "boss": "", "shrine": ""}
	match type:
		"raid":
			for id: String in Zones.SHRINES:
				if Zones.SHRINES[id]["zone"] == zone:
					active["shrine"] = id
		"champion":
			active["trait"] = TRAITS.keys().pick_random()
		"hunt":
			for boss: String in HUNT_BOSSES:
				if HUNT_BOSSES[boss] == zone:
					active["boss"] = boss
		"world_boss":
			active["boss"] = world_boss_for(zone)
			active["warn"] = WORLD_BOSS_WARNING
			active["level"] = level + 3
		"festival":
			# premia działa w całym świecie
			if _player != null:
				_player.boons.grant("festival")
	active["title"] = title_of(active)
	started.emit(active)
	changed.emit()
	return true


static func title_of(event: Dictionary) -> String:
	var info: Dictionary = TYPES[event["type"]]
	match event["type"]:
		"raid":
			return "Najazd na %s" % Zones.SHRINES.get(event["shrine"], {}).get("name", "kapliczkę")
		"champion":
			return "Czempion: %s" % TRAITS[event["trait"]]["name"]
		"hunt":
			return "Polowanie: %s" % boss_title(event["boss"])
		"world_boss":
			return "World boss: %s" % WORLD_BOSS_NAMES.get(event["boss"], "?")
	return info["name"]


static func boss_title(boss: String) -> String:
	return {"hydra": "Rozwścieczona Hydra", "gryf": "Rozjuszony Gryf"}.get(boss, "Wściekły boss")


## Opis wydarzenia do komunikatu.
static func announcement(event: Dictionary) -> String:
	var zone_name := Zones.zone_name(event["zone"])
	var text: String = TYPES[event["type"]]["text"]
	match event["type"]:
		"raid":
			return text % Zones.SHRINES.get(event["shrine"], {}).get("name", "")
		"champion":
			var data: Dictionary = TRAITS[event["trait"]]
			return text % [zone_name, "%s (%s)" % [data["name"], data["text"]]]
		"hunt":
			return text % [boss_title(event["boss"]), zone_name]
		"world_boss":
			return text % [WORLD_BOSS_NAMES.get(event["boss"], "?"), zone_name]
		"festival":
			return text
	return text % zone_name


func is_active_in(zone: String) -> bool:
	return not active.is_empty() and active["zone"] == zone


## Punkty wkładu (obrażenia potworom wydarzenia, rozbite meteoryty).
func add_points(who: String, points: float) -> void:
	if active.is_empty() or points <= 0.0:
		return
	var contrib: Dictionary = active["contrib"]
	contrib[who] = float(contrib.get(who, 0.0)) + points


## Ranking: [[imię, punkty]...] od największego wkładu.
func ranking(event := active) -> Array:
	var list: Array = []
	var contrib: Dictionary = event.get("contrib", {})
	for who: String in contrib:
		list.append([who, roundi(float(contrib[who]))])
	list.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return list


## Miejsce gracza w rankingu (1 - pierwsze, 0 - bez udziału).
func player_place(event := active) -> int:
	var list := ranking(event)
	for i in list.size():
		if list[i][0] == PLAYER:
			return i + 1 if list[i][1] > 0 else 0
	return 0


## Wydarzenie bez gracza: podróżnicy rozdzielają wkład między siebie.
func _simulate_contrib() -> void:
	if _player == null:
		return
	var names: Array = _player.travelers.active().filter(func(t: Dictionary) -> bool: return t["state"] != "party").map(
			func(t: Dictionary) -> String: return t["name"])
	names.shuffle()
	for name: String in names.slice(0, randi_range(3, 8)):
		add_points(name, randf_range(0.5, 3.0) * Levels.health(int(active["level"])))


## Koniec wydarzenia: ranking, nagrody gracza (znaki, sława), sława zwycięzcy-podróżnika, zgaszona kapliczka.
## Zwraca wynik ({type, zone, title, success, ranking, place, marks, fame, level}); skrzynię stawia EventSite.
func finish(success: bool) -> Dictionary:
	if active.is_empty():
		return {}
	var event := active
	active = {}
	if not event.get("built", false) and event["contrib"].is_empty() and event["type"] != "festival":
		_simulate_contrib_into(event)
	var place := player_place(event)
	var result := {"type": event["type"], "zone": event["zone"], "title": event["title"], "success": success,
			"ranking": ranking(event), "place": place, "marks": 0, "fame": 0, "level": event["level"],
			"here": event.get("built", false)}
	if place > 0 and _player != null:
		var marks: int = MARKS[mini(place, MARKS.size()) - 1] if success else MARKS_FAIL
		# world boss - podwójne znaki
		if event["type"] == "world_boss":
			marks *= 2
		result["marks"] = marks
		if _player.inventory.add_item(MARK, marks) > 0:
			_player.storage.add_item(MARK, marks)
		if success:
			result["fame"] = FAME + (FAME_FIRST if place == 1 else 0)
			_player.travelers.guild_fame += int(result["fame"])
	# zwycięzca-podróżnik zyskuje sławę
	var top: Array = result["ranking"][0] if not result["ranking"].is_empty() else []
	if success and not top.is_empty() and top[0] != PLAYER and _player != null:
		var winner: Dictionary = _player.travelers.find(top[0])
		if not winner.is_empty():
			winner["fame"] = int(winner["fame"]) + 10
	if not success and event["type"] == "raid" and event["shrine"] != "":
		shrine_down[event["shrine"]] = SHRINE_DOWN_TIME
	last_result = result
	finished.emit(result)
	changed.emit()
	return result


func _simulate_contrib_into(event: Dictionary) -> void:
	var keep := active
	active = event
	_simulate_contrib()
	active = keep


func is_shrine_down(id: String) -> bool:
	return shrine_down.has(id)


func get_save_data() -> Dictionary:
	var event := active.duplicate(true)
	event.erase("built")
	return {"active": event, "next_in": next_in, "shrine_down": shrine_down.duplicate()}


func load_save_data(data: Dictionary) -> void:
	active = data.get("active", {})
	if not active.is_empty():
		for key in ["left", "duration"]:
			active[key] = float(active[key])
		active["level"] = int(active["level"])
		if not TYPES.has(str(active.get("type", ""))):
			active = {}
	next_in = float(data.get("next_in", next_in))
	shrine_down = {}
	var down: Dictionary = data.get("shrine_down", {})
	for id: String in down:
		shrine_down[id] = float(down[id])
	changed.emit()
