class_name Travelers
extends Node
## Inni podróżnicy (świat jak w MMO, wszystko symulowane) - dziecko gracza, zapisywane. Spis 40 poszukiwaczy przygód
## z imionami, wyglądem (arkusze NPC), bronią, poziomem, sławą i ekwipunkiem; aktywnych jest tylu, ile pozwala ranga
## gildii (RANK_ACTIVE - przed zbudowaniem gildii tylko kilku samotnych wędrowców). Co TICK sekund każdy aktywny
## podróżnik żyje dalej: z Ostoi rusza na łowy do krainy pasującej do poziomu, poluje (zabójstwa, doświadczenie,
## awanse, czasem łup wystawiony na rynku), wraca albo ginie i po chwili wstaje w Ostoi.
## Widocznych w krainie i w Ostoi stawia świat (Traveler, World._sync_travelers); ich walki też trafiają do spisu.
## Drużyna gracza (party - stan "party"): 1-3 podróżników chodzi za graczem przez krainy i lochy, ich zabójstwa dają
## graczowi łup i doświadczenie z premią za każdego (party_xp_factor); odchodzą po party_ticks minutach, po powrocie
## do Ostoi albo po rozwiązaniu. Zaproszenia i prośby o pomoc (zadanie z drużyną) - World._process_party_offers.
## Łowcy przy okazji zbierają surowce (drzewa, głazy, ruda, zioła - Traveler, z limitem MAX_DEPLETED), a urobek wystawiają
## na rynku jako świeży towar (Market.supply; poza oczami gracza - GATHER w tick).

signal changed

const TICK := 60.0
const SIZE := 40
## Ilu podróżników jest aktywnych wg rangi gildii (0 - gildii nie ma) - z każdą rangą przybywa ich trochę mniej.
const RANK_ACTIVE: Array[int] = [4, 14, 21, 27, 32, 36, 40]
const MAX_RANK := 6
## Najwyższy poziom podróżników wg rangi gildii (wyższa ranga ściąga silniejszych).
const RANK_LEVEL_CAP: Array[int] = [12, 18, 24, 30, 36, 42, 45]
## Ulepszenia gildii (u pisarza gildii): potrzebna sława gildii (ze zleceń z tablicy - nie ubywa) oraz złoto i surowce.
const RANK_COSTS := [{}, {},
	{"fame": 60, "gold": 1000, "wood": 100, "stone": 100},
	{"fame": 180, "gold": 3000, "wood": 200, "stone": 200},
	{"fame": 400, "gold": 6000, "wood": 300, "stone": 300, "iron_ore": 30},
	{"fame": 800, "gold": 12000, "wood": 400, "stone": 400, "iron_ore": 60},
	{"fame": 1500, "gold": 20000, "wood": 500, "stone": 500, "iron_ore": 100},
]
const MALE := ["Bogumił", "Radomir", "Wojsław", "Ziemowit", "Lubomir", "Gniewko", "Mścisław", "Dobrosław", "Sobiesław",
		"Jaromir", "Czcibor", "Świętosław", "Wszemir", "Racibor", "Bożydar", "Stanimir", "Witosław", "Krzesimir", "Dalibor", "Unisław"]
const FEMALE := ["Dobrawa", "Milena", "Wiesława", "Ludmiła", "Bogna", "Jarosława", "Zlata", "Radosława", "Świętomira", "Wanda",
		"Dobromiła", "Grzymisława", "Bożena", "Sława", "Wojsława", "Zbysława", "Miłosława", "Czesława", "Jagna", "Rościsława"]
const NICKNAMES := ["Rudy", "z Gór", "Czarny", "Wilczy", "Bystry", "Cichy", "z Bagien", "Kruk", "Siwy", "Młody", "Mocny", "Łowca"]
const NICKNAMES_F := ["Ruda", "z Gór", "Czarna", "Wilcza", "Bystra", "Cicha", "z Bagien", "Krucza", "Siwa", "Młoda", "Mocna", "Łowczyni"]
## Wygląd (arkusz NPC) i broń: wojownicy, łucznicy, magowie.
const LOOKS := {
	"melee": ["soldier_a", "soldier_b", "soldier_c", "guard", "adventurer_a"],
	"bow": ["hunter", "hunter_b", "hunter_c", "hunter_d"],
	"spell": ["sage", "adventurer_b"],
}
const WEAPON_NAMES := {"melee": "miecz", "bow": "łuk", "spell": "księga"}
const ZONE_ORDER: Array[String] = ["forest", "fields", "swamp", "mountains", "ancient", "cemetery"]
const GEAR := ["zwykły", "magiczny", "rzadki", "legendarny"]
const PARTY_MAX := 3
const PARTY_XP_BONUS := 0.1
## Pozdrowienia napotkanych łowców i wskazówki o krainie (w dymkach, gdy gracz przechodzi obok).
const GREETINGS: Array[String] = ["Witaj, wędrowcze!", "Dobrych łowów!", "Niech Perun cię prowadzi.", "Hej! Uważaj na siebie.",
		"Ty też z Ostoi? Pozdrów Wszebora!", "Gorąco tu dziś, co?", "Ostrożnie, dużo ich tu."]
const HINTS := {
	"forest": ["Szarokieł wyje przed atakiem - wtedy zbiega się cała wataha.", "Goblińscy łucznicy trzymają się z tyłu - bij ich pierwszych.",
			"Osiłki goblinów są wolne, ale biją jak młotem.", "Zioła z iskierkami zerwiesz klawiszem F - zielarka zrobi z nich mikstury."],
	"fields": ["Uważaj na beczki bombiarzy - wybuchają po chwili.", "Czerwie polne wyskakują spod ziemi tuż pod nogami!",
			"Bombardier siedzi za barykadą na północy obozu.", "Gryf ze wzgórza jest dużo silniejszy, niż się wydaje."],
	"swamp": ["Uważaj na utopce - lubią wyskakiwać z wody tuż przed twarzą.", "Ogniki zwodzą na bagna. Nie idź za nimi!",
			"Hydra śpi na północnym skraju bagien. Nie budź jej za wcześnie.", "Plujące żabołaki trafiają z daleka - podchodź zygzakiem."],
	"mountains": ["Ptakoludzie skaczą z góry na wroga - patrz w niebo.", "Fletnia satyra miesza w głowie - sterowanie się odwraca!",
			"Gromoskrzydły ciska piorunami z gniazda nad wioską.", "W rudzie żelaza czasem błyszczy klejnot."],
	"ancient": ["Niszcz kokony, zanim wylęgną się pajączki.", "Pajęcze sieci spowalniają - nie stój w miejscu.",
			"Prastare drzewa smagają korzeniami z daleka.", "Leszy otacza się drzewcami - wytnij je najpierw."],
	"cemetery": ["Mortan wskrzesza szkielety - im dłużej walczysz, tym ich więcej.", "Ghul z trupowiska zieje smrodem i gniciem.",
			"Kruki zrywają się z krakaniem - mogą zwabić umarłych.", "Znicze przy grobach dają trochę światła w mroku."],
	"dungeon": ["Strażnik czeka w najdalszej komnacie.", "Kryształ Watry trzeba bronić do ostatniej fali!",
			"Płomienie powrotu są przy wejściu."],
}
## Surowce, które łowcy zbierają w krainie poza oczami gracza (tick) - trafiają na rynek jako świeży towar.
const GATHER := {
	"forest": [["wood", 3, 8], ["stone", 2, 6], ["herb_wort", 1, 3]],
	"fields": [["wood", 3, 8], ["stone", 2, 6], ["herb_chamomile", 1, 3]],
	"swamp": [["wood", 2, 6], ["herb_calamus", 1, 3], ["fish", 2, 5]],
	"mountains": [["iron_ore", 2, 6], ["stone", 3, 8], ["herb_arnica", 1, 3]],
	"ancient": [["wood", 4, 10], ["herb_fern", 1, 1], ["spider_silk", 2, 5]],
	"cemetery": [["stone", 3, 8], ["herb_datura", 1, 3], ["bone_dust", 2, 5]],
}
const GATHER_CHANCE := 0.3
## Co mówią łowcy przy zbieraniu (rodzaj surowca - Traveler.gather_kind).
const LINES_GATHER := {
	"tree": ["Dobry dąb, będzie na nowy łuk.", "Drewno na Watrę!", "Uwaga, drzewo leci!", "Jeszcze jedno i wracam do Ostoi.",
			"Cieśla w Ostoi dobrze płaci za belki."],
	"stone": ["Kamień na palisadę zawsze się przyda.", "Twardy ten głaz...", "Ładny kamień, sprzedam w gildii.",
			"Kilof by się przydał nowy."],
	"ore": ["Ruda! Kowal się ucieszy.", "Może tym razem błyśnie klejnot?", "Żelazo na nowe groty.", "Ciężka ta ruda, ale warta swego."],
	"herb": ["Zielarka za to dobrze zapłaci.", "Pachnie jak u babki w ogródku.", "Ostrożnie, żeby nie zgnieść kwiatu.",
			"Z tego będzie dobra mikstura."],
}
const LINES_TOWN: Array[String] = ["Ktoś na Hydrę? Szukam drużyny!", "Sprzedam pancerz, tanio!", "Watra dziś huczy jak nigdy.",
		"Byłeś już w lochach? Ja ledwo wyszedłem.", "Gromoskrzydły znów mnie ubił...", "Kupię kamienie miłosierdzia!",
		"W Prastarym Lesie pełno pająków.", "Kto widział Leszego, ten wie, co to strach.", "Jutro idę na Cmentarz.",
		"Pisarz gildii płaci za każde zlecenie.", "Wymienię esencję na esencję!", "Zielarka warzy najlepsze mikstury.",
		"Wystawiłem drewno na rynku - ledwo wystawiłem, a już poszło!", "Świeża ruda z Turni, tanio, pytajcie w gildii!",
		"Kto osłoni mnie przy rąbaniu? Wilki nie dają spokoju."]

## Spis: [{name, female, look, weapon, level, xp, zone, state ("town"/"hunt"/"dead"), wait, kills, deaths, gear, fame}]
var roster: Array[Dictionary] = []
## Ranga gildii (0 - brak gildii; 1 po zbudowaniu, dalej ulepszenia u pisarza gildii).
var guild_rank := 0
## Sława gildii - za zlecenia z tablicy ogłoszeń (Bounties); od niej zależą kolejne rangi.
var guild_fame := 0
## Drużyna gracza: imiona członków i ile jeszcze minut (tików) zostanie.
var party: Array[String] = []
var party_ticks := 0
## Tryb świata (WorldModes): nowa gra bierze go z menu (Game.world_mode), starsze zapisy - spokojny.
var world_mode := "calm"
## Rynek gracza (świeży towar od zbieraczy) - ustawia Player.
var market: Market


func _ready() -> void:
	world_mode = Game.world_mode
var _timer := TICK


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = TICK
		tick()


## Spis tworzy się raz (pierwsze wywołanie) - poziomy rozłożone od 1 do 45, z przewagą niskich.
func ensure_roster() -> void:
	if not roster.is_empty():
		return
	var used := {}
	# charaktery w stałych proporcjach (12% zbójów, 28% pojedynkowiczów), przetasowane
	var tempers: Array[String] = []
	for i in SIZE:
		tempers.append("bandit" if i < roundi(SIZE * 0.12) else "duelist" if i < roundi(SIZE * 0.4) else "friendly")
	tempers.shuffle()
	for i in SIZE:
		var female := randf() < 0.45
		var pool: Array = FEMALE if female else MALE
		var name: String = pool.pick_random()
		if used.has(name) or randf() < 0.35:
			name += " " + (NICKNAMES_F if female else NICKNAMES).pick_random()
		while used.has(name):
			name += " " + str(randi_range(2, 9))
		used[name] = true
		var weapon: String = ["melee", "melee", "bow", "spell"].pick_random()
		var level := clampi(roundi(pow(randf(), 1.6) * 44.0) + 1, 1, 45)
		roster.append({"name": name, "female": female, "look": LOOKS[weapon].pick_random(), "weapon": weapon, "temper": tempers[i],
				"level": level, "xp": 0, "zone": "forest", "state": "town", "wait": randi_range(0, 3),
				"kills": randi_range(0, 40) * level, "deaths": randi_range(0, level / 3), "gear": _gear_for(level), "fame": level * randi_range(5, 12)})
	# od najsłabszych - przed gildią i przy niskiej randze krążą tylko początkujący
	roster.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["level"]) < int(b["level"]))


## Charakter: 60% przyjaznych, 28% pojedynkowiczów, 12% zbójów.
static func _roll_temper() -> String:
	var roll := randf()
	return "friendly" if roll < 0.6 else "duelist" if roll < 0.88 else "bandit"


## Jak podróżnik zachowuje się wobec gracza w obecnym trybie świata: "friendly", "duelist" albo "bandit".
func behavior(traveler: Dictionary) -> String:
	var temper: String = traveler.get("temper", "friendly")
	match world_mode:
		"realistic":
			return "friendly" if temper == "friendly" else "duelist"
		"hardcore":
			return temper
	return "friendly"


func active_count() -> int:
	return RANK_ACTIVE[clampi(guild_rank, 0, MAX_RANK)]


## Aktywni podróżnicy (pierwsi z listy - przed gildią tylko kilku).
func active() -> Array[Dictionary]:
	ensure_roster()
	return roster.slice(0, active_count())


func level_cap() -> int:
	return RANK_LEVEL_CAP[clampi(guild_rank, 0, MAX_RANK)]


static func _gear_for(level: int) -> String:
	return GEAR[clampi(level / 12 + (1 if randf() < 0.3 else 0), 0, GEAR.size() - 1)]


## Kraina, w której poluje ktoś na tym poziomie.
static func zone_for(level: int) -> String:
	var best := "forest"
	for zone: String in ZONE_ORDER:
		if level >= Levels.ZONES[zone][0] - 1:
			best = zone
	return best


## Jedna chwila życia świata: wymarsze, łowy, awanse, powroty i śmierci.
func tick() -> void:
	if not party.is_empty():
		party_ticks -= 1
		if party_ticks <= 0:
			disband()
	for traveler: Dictionary in active():
		traveler["wait"] = maxi(int(traveler["wait"]) - 1, 0)
		match str(traveler["state"]):
			"party":
				add_kills(traveler, randi_range(1, 4))
			"dead":
				if traveler["wait"] == 0:
					traveler["state"] = "town"
					traveler["zone"] = "forest"
			"town":
				if traveler["wait"] == 0 and randf() < 0.45:
					traveler["state"] = "hunt"
					traveler["zone"] = zone_for(int(traveler["level"]))
					traveler["wait"] = randi_range(2, 5)
			"hunt":
				add_kills(traveler, randi_range(3, 15))
				if market != null and randf() < GATHER_CHANCE and GATHER.has(str(traveler["zone"])):
					var pick: Array = (GATHER[str(traveler["zone"])] as Array).pick_random()
					market.supply(pick[0], randi_range(pick[1], pick[2]), traveler["name"])
				if randf() < 0.025:
					die(traveler)
				elif traveler["wait"] == 0 and randf() < 0.35:
					traveler["state"] = "town"
					traveler["zone"] = "forest"
					traveler["wait"] = randi_range(1, 3)
	changed.emit()


## Zabójstwa (z symulacji albo z walki na oczach gracza): sława, doświadczenie i awanse do limitu rangi gildii.
func add_kills(traveler: Dictionary, count: int) -> void:
	traveler["kills"] = int(traveler["kills"]) + count
	traveler["fame"] = int(traveler["fame"]) + count
	traveler["xp"] = int(traveler["xp"]) + count
	var need := 20 + int(traveler["level"]) * 4
	if int(traveler["xp"]) >= need and int(traveler["level"]) < level_cap():
		traveler["xp"] = 0
		traveler["level"] = int(traveler["level"]) + 1
		if randf() < 0.15:
			traveler["gear"] = _gear_for(int(traveler["level"]))


func die(traveler: Dictionary) -> void:
	var in_party := party.has(traveler["name"])
	party.erase(traveler["name"])
	traveler["state"] = "dead"
	traveler["deaths"] = int(traveler["deaths"]) + 1
	traveler["wait"] = randi_range(2, 4)
	if in_party:
		# prośba drużyny przepada, gdy zginie proszący albo cała drużyna
		var player := get_parent() as Player
		var help := player.quests.active_help() if player != null else ""
		if party.is_empty() or (help != "" and Quests.get_data(help).get("poster", "") == traveler["name"]):
			_fail_party_help()
		if party.is_empty():
			party_ticks = 0
		changed.emit()


# ---------------------------------------------------------------- drużyna
## Dołączenie podróżników do drużyny gracza (najwyżej PARTY_MAX).
func join_party(members: Array) -> void:
	for traveler: Dictionary in members:
		if party.size() >= PARTY_MAX or party.has(traveler["name"]):
			continue
		party.append(traveler["name"])
		traveler["state"] = "party"
	party_ticks = maxi(party_ticks, randi_range(15, 30))
	changed.emit()


## Koniec wspólnych łowów: członkowie wracają do Ostoi.
func disband() -> void:
	for name in party:
		var traveler := find(name)
		if not traveler.is_empty() and traveler["state"] == "party":
			traveler["state"] = "town"
			traveler["zone"] = "forest"
			traveler["wait"] = randi_range(1, 3)
	party.clear()
	party_ticks = 0
	_fail_party_help()
	changed.emit()


## Drużyna odeszła (albo zginął proszący), zanim prośba o pomoc została wykonana - zadanie przepada i znika spod minimapy.
func _fail_party_help() -> void:
	var player := get_parent() as Player
	if player == null:
		return
	var help := player.quests.active_help()
	if help == "" or player.quests.state_of(help) != Quests.STATE_ACTIVE:
		return
	player.quests.abandon_bounty(help)
	if player.is_inside_tree():
		DamageNumber.spawn_text(player.get_parent(), player.body_center() + Vector2(0, -14),
				"Prośba drużyny nieudana", Color(1.0, 0.5, 0.45), 9)


func party_members() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for name in party:
		var traveler := find(name)
		if not traveler.is_empty():
			result.append(traveler)
	return result


## Premia do doświadczenia za drużynę: +10% za każdego członka.
func party_xp_factor() -> float:
	return 1.0 + PARTY_XP_BONUS * party.size()


func find(name: String) -> Dictionary:
	for traveler: Dictionary in roster:
		if traveler["name"] == name:
			return traveler
	return {}


## Kto teraz poluje w danej krainie / przebywa w Ostoi.
func in_zone(zone: String) -> Array[Dictionary]:
	return active().filter(func(t: Dictionary) -> bool: return t["state"] == "hunt" and t["zone"] == zone)


func in_town() -> Array[Dictionary]:
	return active().filter(func(t: Dictionary) -> bool: return t["state"] == "town")


## Gdzie jest (do listy podróżników).
static func place_text(traveler: Dictionary) -> String:
	match str(traveler["state"]):
		"town":
			return Lang.t("w Ostoi")
		"dead":
			return Lang.t("poległ, wraca do Ostoi") if not traveler["female"] else Lang.t("poległa, wraca do Ostoi")
	return Lang.t("poluje: %s") % Lang.t(Zones.DATA[traveler["zone"]]["name"])


## Ulepszenie gildii do następnej rangi (koszt RANK_COSTS) - "" albo powód odmowy.
func upgrade_rank(player: Player) -> String:
	if guild_rank >= MAX_RANK:
		return Lang.t("Gildia ma już najwyższą rangę.")
	if guild_rank == 0:
		return Lang.t("Najpierw trzeba zbudować gildię.")
	var cost: Dictionary = RANK_COSTS[guild_rank + 1]
	if guild_fame < int(cost.get("fame", 0)):
		return Lang.t("Za mało sławy gildii (%d/%d) - wykonuj zlecenia z tablicy.") % [guild_fame, cost["fame"]]
	for id: String in cost:
		if id == "fame":
			continue
		var have: int = player.stats.gold if id == "gold" else player.count_owned(id)
		if have < int(cost[id]):
			return Lang.t("Brakuje: %s") % (Lang.t("złota") if id == "gold" else Lang.t(Items.get_data(id)["name"]))
	for id: String in cost:
		if id == "fame":
			continue
		if id == "gold":
			player.stats.add_gold(-int(cost[id]))
		else:
			player.take_owned(id, int(cost[id]))
	guild_rank += 1
	changed.emit()
	return ""


func get_save_data() -> Dictionary:
	return {"roster": roster.duplicate(true), "rank": guild_rank, "fame": guild_fame, "party": party.duplicate(), "party_ticks": party_ticks,
			"mode": world_mode}


func load_save_data(data: Dictionary) -> void:
	roster.clear()
	for entry: Dictionary in data.get("roster", []):
		for key in ["level", "xp", "wait", "kills", "deaths", "fame"]:
			entry[key] = int(entry.get(key, 0))
		# starsze spisy nie znały charakterów
		if not entry.has("temper"):
			entry["temper"] = _roll_temper()
		roster.append(entry)
	guild_rank = int(data.get("rank", 0))
	guild_fame = int(data.get("fame", 0))
	party.clear()
	for name in data.get("party", []):
		if not find(str(name)).is_empty():
			party.append(str(name))
	party_ticks = int(data.get("party_ticks", 0))
	world_mode = str(data.get("mode", "calm"))
	if not WorldModes.MODES.has(world_mode):
		world_mode = "calm"
	changed.emit()
