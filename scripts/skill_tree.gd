class_name SkillTree
## Drzewka umiejętności broni - sieć węzłów jak drzewko pasywne w Path of Exile, tylko mniejsza. Węzeł kupuje się za
## punkt umiejętności (1 za każdy poziom postaci, plus START_POINTS), ale tylko obok węzła już wybranego (start jest
## wybrany zawsze). Rodzaje węzłów:
## - "skill": odblokowuje umiejętność (poziom 1; dalsze poziomy 2-5 za złoto jak dotąd),
## - "passive": stałe premie (statystyki jak na przedmiotach albo premie do umiejętności - TREE_STATS),
## - "keystone": węzeł kluczowy - zmienia sposób gry (np. Nieustający Wir).
## Premie działają tylko z założoną bronią swojego rodzaju. Wybrane węzły cofa za złoto mędrzec w Ostoi.
## Na razie drzewko ma miecz (broń biała); łuk i księga magii korzystają jeszcze z kart umiejętności za złoto.

const START_POINTS := 1
## Ile złota kosztuje zapomnienie drzewka u mędrca (za każdy poziom postaci).
const RESPEC_GOLD_PER_LEVEL := 25

## Premie z węzłów, które nie są statystykami postaci, tylko zmieniają umiejętności (czytane przez SkillBook.tree_bonus).
const TREE_STATS := {
	"whirl_radius": "Zasięg Młynka", "flicker_mana": "Mana za skok Mgnienia", "smoke_charge": "Szybkość ładowania Dymnych Wybuchów",
	"combo_window": "Dłuższe okno combo (s)",
}

## węzeł: pozycja w siatce drzewka, połączenia, rodzaj, nazwa / umiejętność, premie, opis
const TREES := {
	"melee": {
		"start": {"pos": Vector2(0, 0), "kind": "start", "name": "Ścieżka miecza", "links": ["whirlwind", "lunge", "smoke_burst", "warrior_blood", "battle_focus"],
				"description": "Początek drzewka miecza. Wybieraj węzły połączone z już wybranymi."},
		"warrior_blood": {"pos": Vector2(-1.3, -1.5), "kind": "skill", "skill": "warrior_blood", "links": []},
		"battle_focus": {"pos": Vector2(-1.3, 1.5), "kind": "skill", "skill": "battle_focus", "links": []},
		# ---- Wir: Młynek, Mgnienie i Nieustający Wir
		"whirlwind": {"pos": Vector2(-1.6, 0), "kind": "skill", "skill": "whirlwind", "links": ["phys_1"]},
		"phys_1": {"pos": Vector2(-3.0, 0), "kind": "passive", "name": "Ostra stal", "stats": {"physical_damage": 0.08},
				"links": ["whirl_reach", "flicker"]},
		"whirl_reach": {"pos": Vector2(-4.2, -1.2), "kind": "passive", "name": "Szeroki zamach", "stats": {"whirl_radius": 0.2},
				"links": ["endless_whirl"]},
		"flicker": {"pos": Vector2(-4.2, 1.2), "kind": "skill", "skill": "flicker", "links": ["flicker_focus"]},
		"flicker_focus": {"pos": Vector2(-5.6, 1.6), "kind": "passive", "name": "Lekki krok", "stats": {"flicker_mana": -0.25},
				"links": ["endless_whirl"]},
		"endless_whirl": {"pos": Vector2(-6.0, -0.2), "kind": "keystone", "name": "Nieustający Wir", "links": [],
				"description": "Mgnienie w trakcie Młynka nie ma odnowienia - skaczesz, dopóki trzymasz klawisz. Młynek zużywa dwa razy więcej many."},
		# ---- Ostrze: Szarża, Półksiężyc, szybkość i combo
		"lunge": {"pos": Vector2(1.1, -1.4), "kind": "skill", "skill": "lunge", "links": ["crescent", "speed_1"]},
		"crescent": {"pos": Vector2(2.6, -1.4), "kind": "skill", "skill": "crescent", "links": ["combo_1", "crit_1"]},
		"speed_1": {"pos": Vector2(1.1, -2.8), "kind": "passive", "name": "Szybkie ręce", "stats": {"attack_speed": 0.06},
				"links": ["combo_1"]},
		"combo_1": {"pos": Vector2(2.6, -2.8), "kind": "passive", "name": "Płynne przejścia", "stats": {"combo_window": 0.4},
				"links": []},
		"crit_1": {"pos": Vector2(4.0, -1.4), "kind": "passive", "name": "Oko kata", "stats": {"crit_chance": 0.04}, "links": []},
		# ---- Dym: Dymne Wybuchy i czary
		"smoke_burst": {"pos": Vector2(1.1, 1.4), "kind": "skill", "skill": "smoke_burst", "links": ["smoke_charge", "spell_1"]},
		"smoke_charge": {"pos": Vector2(2.6, 1.4), "kind": "passive", "name": "Gęsty dym", "stats": {"smoke_charge": 0.25},
				"links": ["cast_1"]},
		"spell_1": {"pos": Vector2(1.1, 2.8), "kind": "passive", "name": "Szept run", "stats": {"spell_damage": 0.08}, "links": ["cast_1"]},
		"cast_1": {"pos": Vector2(2.6, 2.8), "kind": "passive", "name": "Bystry umysł", "stats": {"cast_speed": 0.08}, "links": []},
	},
}


static func has_tree(weapon_type: String) -> bool:
	return TREES.has(weapon_type)


static func nodes(weapon_type: String) -> Dictionary:
	return TREES.get(weapon_type, {})


## Połączenia węzła w obie strony (w danych zapisane są tylko w jedną).
static func neighbors(weapon_type: String, id: String) -> Array[String]:
	var tree := nodes(weapon_type)
	var result: Array[String] = []
	for link: String in tree[id]["links"]:
		result.append(link)
	for other: String in tree:
		if id in tree[other]["links"] and not other in result:
			result.append(other)
	return result


## Węzeł odblokowujący umiejętność ("" - umiejętność nie ma węzła; wtedy odblokowuje się ją za złoto).
static func node_for_skill(skill_id: String) -> String:
	var weapon: String = Skills.get_data(skill_id).get("weapon", "")
	for id: String in nodes(weapon):
		if nodes(weapon)[id].get("skill", "") == skill_id:
			return id
	return ""


static func node_name(weapon_type: String, id: String) -> String:
	var node: Dictionary = nodes(weapon_type)[id]
	if node["kind"] == "skill":
		return Skills.get_data(node["skill"])["name"]
	return node["name"]


## Opis premii węzła ("+8% obrażeń fizycznych", "Zasięg Młynka +20%").
static func stats_text(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for stat: String in stats:
		var value: float = stats[stat]
		if TREE_STATS.has(stat):
			var shown := ("%+.1f s" % value).replace(".", ",") if stat == "combo_window" else "%+d%%" % roundi(value * 100.0)
			parts.append("%s %s" % [TREE_STATS[stat], shown])
		else:
			parts.append(Items._stat_text(stat, value))
	return ", ".join(parts)


## Najkrótsza droga od startu do węzła (bez startu) - do przeniesienia umiejętności ze starszych zapisów.
static func path_to(weapon_type: String, target: String) -> Array[String]:
	var previous := {"start": ""}
	var queue: Array[String] = ["start"]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == target:
			break
		for next in neighbors(weapon_type, id):
			if not previous.has(next):
				previous[next] = id
				queue.append(next)
	var path: Array[String] = []
	var at := target
	while previous.has(at) and at != "start":
		path.push_front(at)
		at = previous[at]
	return path
