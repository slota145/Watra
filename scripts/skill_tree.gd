class_name SkillTree
## Wspólne drzewko umiejętności (docs/plan_drzewek.md, krok 2) - jedna sieć węzłów dla wszystkich broni, jak drzewko
## pasywne w Path of Exile. Dane węzłów generuje `python tools/shared_tree_draft.py` (SkillTreeData). Węzeł kupuje się
## za punkt umiejętności (z paska umiejętności - SkillBook.skill_xp, plus START_POINTS), ale tylko obok węzła już
## wybranego (start jest wybrany zawsze). Strony: siła (góra-lewo, miecz), zręczność (góra-prawo, łuk), inteligencja
## (dół, księga) i strefy pośrednie między nimi. Rodzaje węzłów (pole "kind"):
## - "skill": odblokowuje umiejętność (poziom 1; dalsze poziomy do 20 za punkty umiejętności - Skills.cost);
##   umiejętność działa tylko ze swoją bronią, ale węzeł można wybrać z każdą,
## - "passive": stałe premie (statystyki jak na przedmiotach albo premie do umiejętności - TREE_STATS); "notable" -
##   węzeł znaczący (większy), bez tego pola - drobny węzeł ścieżki,
## - "keystone": węzeł kluczowy - zmienia sposób gry (np. Oko Cyklonu),
## - "socket": gniazdo na kamień szlachetny (Gems) - kamień działa w drzewku o połowę mocniej (SkillBook.tree_bonus);
##   gniazdo "legendary" stoi za węzłem kluczowym i przyjmuje też esencję legendy, a kamień promienia wzmacnia
##   wybrane węzły pasywne w swoim promieniu.
## Węzeł z "soon" to puste miejsce na później (nowe umiejętności, aury, nowe węzły kluczowe): widać go, ale nie da się
## go wybrać, a drzewko można przez niego przejść za darmo (SkillBook.reachable). Węzeł z "aura" - aura (Auras).
## Premie z węzłów działają z każdą bronią - na umiejętności, które do nich pasują (tagi Skills.TAGS, np. +% obrażeń
## od ognia na umiejętności z ogniem); premie do konkretnej umiejętności działają tylko na nią.
## Wybrane węzły cofa się prawym przyciskiem (za złoto) albo całe drzewko u mędrca w Ostoi.

## Punkty umiejętności na start (dawniej 1 + 1 za 1. poziom postaci).
const START_POINTS := 2

## Premie z węzłów, które nie są statystykami postaci, tylko zmieniają umiejętności (czytane przez SkillBook.tree_bonus).
## Wartości to ułamki (+0.2 = +20%), poza combo_window (sekundy) i COUNT_STATS (sztuki).
const TREE_STATS := {
	"whirl_radius": "Zasięg Młynka", "whirl_damage": "Obrażenia Młynka", "flicker_mana": "Mana za skok Mgnienia",
	"flicker_damage": "Obrażenia Mgnienia", "smoke_charge": "Szybkość ładowania Dymnych Wybuchów",
	"smoke_damage": "Obrażenia Dymnych Wybuchów", "combo_window": "Dłuższe okno combo", "combo_damage": "Obrażenia ciosów combo",
	"bleed_damage": "Obrażenia krwawienia", "cry_power": "Premia Zewu Peruna", "slam_stun": "Ogłuszenie Rozłupania Ziemi",
	"lunge_cooldown": "Odnowienie Szarży", "riposte_damage": "Obrażenia kontry Riposty", "blade_count": "Widmowe ostrza",
	"multishot_arrows": "Strzały Salwy", "multishot_damage": "Obrażenia Salwy", "rain_damage": "Obrażenia Deszczu Strzał",
	"rain_area": "Krąg Deszczu Strzał", "seeker_hits": "Trafienia Strzały tropiącej", "falcon_damage": "Obrażenia Sokoła",
	"wind_damage": "Obrażenia Strzały Wichru", "power_charge": "Szybkość napinania Grotu Swaroga",
	"power_damage": "Obrażenia Grotu Swaroga", "arrow_pierce": "Strzały przebijają wrogów", "arrow_range": "Zasięg strzał",
	"ballista_damage": "Obrażenia Balisty", "ballista_time": "Czas Balisty", "snare_time": "Unieruchomienie Sideł",
	"venom_damage": "Obrażenia Jadowych Grotów", "vault_cooldown": "Odnowienie Odskoku",
	"fireball_charge": "Szybkość ładowania Kuli ognia", "fireball_damage": "Obrażenia Kuli ognia", "burn_damage": "Obrażenia podpalenia",
	"meteor_radius": "Wybuch Spadającej Gwiazdy", "shield_share": "Ciosy przyjmowane przez Tarczę Many",
	"blink_cooldown": "Odnowienie Kroku przez Mgłę", "rune_bonus": "Moc Kamienia Runicznego", "chain_targets": "Cele Łańcucha błyskawic",
	"storm_time": "Czas Burzy Peruna", "orb_damage": "Obrażenia Kuli Piorunów", "lance_damage": "Obrażenia Włóczni Marzanny",
	"chill_time": "Czas spowolnienia", "lance_pierce": "Włócznia przebija wrogów", "blizzard_damage": "Obrażenia Zamieci",
	"blizzard_time": "Czas Zamieci", "aura_reservation": "Rezerwacja many przez aury",
	"cry_radius": "Zasięg okrzyków", "cry_cooldown": "Odnowienie okrzyków",
	# premie z opisem w węźle (SkillTreeData "description"): Wciągający wir, Pełnia Sił, Gniew rannego, Wstrząs
	"whirl_pull": "Młynek przyciąga wrogów", "full_strength": "Obrażenia przy pełnym zdrowiu",
	"wounded_wrath": "Obrażenia przy niskim zdrowiu", "tremor_stun": "Ogłuszenie umiejętności obszarowych miecza",
	# strona zręczności (krok 5): Szereg, Ciche kroki, Oddech w biegu
	"row_shot": "Strzały umiejętności łuku lecące równolegle", "silent_steps": "Potwory zauważają cię z bliższa",
	"running_breath": "Regeneracja zdrowia w biegu",
}
const COUNT_STATS := ["blade_count", "multishot_arrows", "seeker_hits", "arrow_pierce", "chain_targets", "lance_pierce",
		"row_shot", "silent_steps"]

## Kolor obwódki umiejętności wg broni (w oknie drzewka).
const WEAPON_COLORS := {"melee": Color8(225, 85, 70), "bow": Color8(90, 200, 100), "spell": Color8(90, 140, 240),
		"melee/bow": Color8(220, 170, 60), "bow/spell": Color8(70, 200, 200), "melee/spell": Color8(180, 100, 220),
		"any": Color8(240, 240, 240)}

static var _neighbors := {}
static var _skill_nodes := {}


static func nodes() -> Dictionary:
	return SkillTreeData.NODES


static func node(id: String) -> Dictionary:
	return SkillTreeData.NODES.get(id, {})


static func has_node(id: String) -> bool:
	return SkillTreeData.NODES.has(id)


## Puste miejsce na później (nie da się go wybrać, ale można przez nie przejść).
static func is_soon(id: String) -> bool:
	return node(id).get("soon", false)


## Połączenia węzła w obie strony (w danych zapisane są tylko w jedną).
static func neighbors(id: String) -> Array:
	if _neighbors.is_empty():
		for other: String in SkillTreeData.NODES:
			_neighbors[other] = []
		for other: String in SkillTreeData.NODES:
			for link: String in SkillTreeData.NODES[other]["links"]:
				_neighbors[other].append(link)
				_neighbors[link].append(other)
	return _neighbors.get(id, [])


## Węzeł odblokowujący umiejętność ("" - umiejętność nie ma węzła).
static func node_for_skill(skill_id: String) -> String:
	if _skill_nodes.is_empty():
		for id: String in SkillTreeData.NODES:
			var skill: String = SkillTreeData.NODES[id].get("skill", "")
			if skill != "":
				_skill_nodes[skill] = id
	return _skill_nodes.get(skill_id, "")


## Broń umiejętności z węzła ("melee", "bow", "spell", mieszane "melee/bow", aura "any"; "" - węzeł bez umiejętności).
static func weapon_of(id: String) -> String:
	var data := node(id)
	if data.has("skill"):
		return str(Skills.get_data(data["skill"]).get("weapon", ""))
	return str(data.get("weapon", ""))


## Nazwa węzła w obecnym języku ("" - drobny węzeł bez nazwy).
static func node_name(id: String) -> String:
	var data := node(id)
	if data.has("skill"):
		return Skills.name_of(data["skill"])
	if data.has("name"):
		return Lang.t(data["name"])
	return stats_text(data.get("stats", {}))


## Opis węzła w obecnym języku ("" - węzeł bez opisu).
static func node_description(id: String) -> String:
	var data := node(id)
	if data.has("skill"):
		return Skills.description_of(data["skill"])
	return Lang.t(str(data.get("description", "")))


## Opis premii węzła ("+8% obrażeń fizycznych", "Zasięg Młynka +20%").
static func stats_text(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for stat: String in stats:
		var value: float = stats[stat]
		if TREE_STATS.has(stat):
			var seconds := "%+.1f s" % value
			var shown := (seconds.replace(".", ",") if Lang.is_polish() else seconds) if stat == "combo_window" \
					else "%+d" % roundi(value) if stat in COUNT_STATS else "%+d%%" % roundi(value * 100.0)
			parts.append(Lang.t("%s %s") % [Lang.t(TREE_STATS[stat]), shown])
		elif stat == "health_percent":
			parts.append(Lang.t("%+d%% maksymalnego zdrowia") % roundi(value * 100.0))
		elif stat == "mana_percent":
			parts.append(Lang.t("%+d%% maksymalnej many") % roundi(value * 100.0))
		elif stat == "armor_percent":
			parts.append(Lang.t("%+d%% pancerza") % roundi(value * 100.0))
		else:
			parts.append(Items._stat_text(stat, value))
	return ", ".join(parts)


## Najkrótsza droga od startu do węzła (bez startu i bez pustych miejsc) - testy i narzędzia dają nią postaci
## umiejętności bez wydawania punktów.
static func path_to(target: String) -> Array[String]:
	var previous := {"start": ""}
	var queue: Array[String] = ["start"]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == target:
			break
		for next: String in neighbors(id):
			if not previous.has(next):
				previous[next] = id
				queue.append(next)
	var path: Array[String] = []
	var at := target
	while previous.has(at) and at != "start":
		if not is_soon(at):
			path.push_front(at)
		at = previous[at]
	return path
