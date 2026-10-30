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
## Wartości to ułamki (+0.2 = +20%), poza combo_window (sekundy) i blade_count (sztuki).
const TREE_STATS := {
	"whirl_radius": "Zasięg Młynka", "whirl_damage": "Obrażenia Młynka", "flicker_mana": "Mana za skok Mgnienia",
	"flicker_damage": "Obrażenia Mgnienia", "smoke_charge": "Szybkość ładowania Dymnych Wybuchów",
	"smoke_damage": "Obrażenia Dymnych Wybuchów", "combo_window": "Dłuższe okno combo", "combo_damage": "Obrażenia ciosów combo",
	"bleed_damage": "Obrażenia krwawienia", "cry_power": "Premia Zewu Peruna", "slam_stun": "Ogłuszenie Rozłupania Ziemi",
	"lunge_cooldown": "Odnowienie Szarży", "riposte_damage": "Obrażenia kontry Riposty", "blade_count": "Widmowe ostrza",
}

## Węzły: pozycja w siatce drzewka (jednostki - SkillTreeView), połączenia, rodzaj, nazwa / umiejętność, premie, opis.
## Gałęzie miecza: zachód - Wir (Młynek, Mgnienie, Nieustający Wir), północny zachód - Krew i okrzyk (Zew Peruna,
## Krwawy Szał przez Rozpłatanie), północny wschód - Ostrze (Szarża, Półksiężyc, Rozłupanie Ziemi, Riposta, Taniec Ostrzy),
## południowy wschód - Dym (Dymne Wybuchy, Widmowe Ostrza, czary, Dym i Cień), południowy zachód - obrona.
const TREES := {
	"melee": {
		"start": {"pos": Vector2(0, 0), "kind": "start", "name": "Ścieżka miecza", "links": ["whirlwind", "lunge", "smoke_burst", "warrior_blood", "battle_focus"],
				"description": "Początek drzewka miecza (zwykły atak). Wybieraj węzły połączone z już wybranymi."},
		"warrior_blood": {"pos": Vector2(-1.1, -1.6), "kind": "skill", "skill": "warrior_blood", "links": ["hp_1"]},
		"battle_focus": {"pos": Vector2(-1.1, 1.6), "kind": "skill", "skill": "battle_focus", "links": ["rend", "armor_1"]},
		# ---- Wir
		"whirlwind": {"pos": Vector2(-1.6, 0), "kind": "skill", "skill": "whirlwind", "links": ["phys_1"]},
		"phys_1": {"pos": Vector2(-3.0, 0), "kind": "passive", "name": "Ostra stal", "stats": {"physical_damage": 0.08}, "links": ["whirl_reach", "flicker"]},
		"whirl_reach": {"pos": Vector2(-4.3, -1.0), "kind": "passive", "name": "Szeroki zamach", "stats": {"whirl_radius": 0.2}, "links": ["whirl_dmg"]},
		"flicker": {"pos": Vector2(-4.3, 1.0), "kind": "skill", "skill": "flicker", "links": ["flicker_focus", "rend"]},
		"whirl_dmg": {"pos": Vector2(-5.6, -1.6), "kind": "passive", "name": "Wirujące ostrze", "stats": {"whirl_damage": 0.2}, "links": ["endless_whirl", "phys_2"]},
		"flicker_focus": {"pos": Vector2(-5.6, 1.6), "kind": "passive", "name": "Lekki krok", "stats": {"flicker_mana": -0.25}, "links": ["endless_whirl", "flicker_dmg"]},
		"endless_whirl": {"pos": Vector2(-6.6, 0), "kind": "keystone", "name": "Nieustający Wir", "links": [],
				"description": "Mgnienie w trakcie Młynka nie ma odnowienia - skaczesz, dopóki trzymasz klawisz. Młynek zużywa dwa razy więcej many."},
		"phys_2": {"pos": Vector2(-7.0, -2.6), "kind": "passive", "name": "Hartowana stal", "stats": {"physical_damage": 0.1}, "links": ["life_hit"]},
		"flicker_dmg": {"pos": Vector2(-7.0, 2.6), "kind": "passive", "name": "Cięcie z cienia", "stats": {"flicker_damage": 0.2}, "links": ["move_1"]},
		"life_hit": {"pos": Vector2(-8.4, -1.4), "kind": "passive", "name": "Krew za krew", "stats": {"life_on_hit": 3.0}, "links": []},
		"move_1": {"pos": Vector2(-8.4, 1.4), "kind": "passive", "name": "Wiatr w nogach", "stats": {"move_speed": 0.05}, "links": []},
		# ---- Krew i okrzyk
		"hp_1": {"pos": Vector2(-2.4, -2.7), "kind": "passive", "name": "Twarda skóra", "stats": {"health_percent": 0.05}, "links": ["war_cry", "regen_1"]},
		"war_cry": {"pos": Vector2(-3.8, -2.9), "kind": "skill", "skill": "war_cry", "links": ["cry_power"]},
		"regen_1": {"pos": Vector2(-1.4, -3.8), "kind": "passive", "name": "Szybkie gojenie", "stats": {"health_regen": 1.5}, "links": ["hp_2"]},
		"cry_power": {"pos": Vector2(-4.6, -4.1), "kind": "passive", "name": "Głos burzy", "stats": {"cry_power": 0.1}, "links": ["hp_2"]},
		"hp_2": {"pos": Vector2(-3.0, -4.6), "kind": "passive", "name": "Niezłomny", "stats": {"health": 40.0}, "links": []},
		"rend": {"pos": Vector2(-2.8, 2.7), "kind": "skill", "skill": "rend", "links": ["bleed_1"]},
		"bleed_1": {"pos": Vector2(-4.2, 3.6), "kind": "passive", "name": "Głębokie rany", "stats": {"bleed_damage": 0.25}, "links": ["blood_frenzy"]},
		"blood_frenzy": {"pos": Vector2(-5.7, 3.9), "kind": "keystone", "name": "Krwawy Szał", "links": [],
				"description": "Krwawienie wrogów cię leczy: wracasz do zdrowia o 30% zadanych nim obrażeń."},
		# ---- Ostrze
		"lunge": {"pos": Vector2(1.1, -1.4), "kind": "skill", "skill": "lunge", "links": ["crescent", "speed_1"]},
		"crescent": {"pos": Vector2(2.6, -1.4), "kind": "skill", "skill": "crescent", "links": ["combo_1", "crit_1"]},
		"speed_1": {"pos": Vector2(1.1, -2.8), "kind": "passive", "name": "Szybkie ręce", "stats": {"attack_speed": 0.06}, "links": ["combo_1", "speed_2"]},
		"combo_1": {"pos": Vector2(2.6, -2.8), "kind": "passive", "name": "Płynne przejścia", "stats": {"combo_window": 0.4}, "links": ["ground_slam", "lunge_cd"]},
		"crit_1": {"pos": Vector2(4.0, -1.4), "kind": "passive", "name": "Oko kata", "stats": {"crit_chance": 0.04}, "links": ["ground_slam", "crit_2"]},
		"ground_slam": {"pos": Vector2(4.0, -2.8), "kind": "skill", "skill": "ground_slam", "links": ["slam_stun"]},
		"slam_stun": {"pos": Vector2(5.4, -3.6), "kind": "passive", "name": "Drżąca ziemia", "stats": {"slam_stun": 0.5}, "links": ["blade_dance", "combo_2"]},
		"speed_2": {"pos": Vector2(1.1, -4.2), "kind": "passive", "name": "Błyskawiczne ręce", "stats": {"attack_speed": 0.06}, "links": ["lunge_cd"]},
		"lunge_cd": {"pos": Vector2(2.6, -4.2), "kind": "passive", "name": "Szybki wypad", "stats": {"lunge_cooldown": -0.25}, "links": ["blade_dance"]},
		"blade_dance": {"pos": Vector2(4.0, -4.5), "kind": "keystone", "name": "Taniec Ostrzy", "links": [],
				"description": "Każde combo daje +5% szybkości ataku na 4 s (do 5 razy naraz)."},
		"combo_2": {"pos": Vector2(6.8, -3.8), "kind": "passive", "name": "Mistrz przejść", "stats": {"combo_damage": 0.15}, "links": []},
		"crit_2": {"pos": Vector2(5.4, -1.4), "kind": "passive", "name": "Cios w serce", "stats": {"crit_damage": 0.3}, "links": ["riposte", "cdr_1"]},
		"riposte": {"pos": Vector2(6.8, -2.0), "kind": "skill", "skill": "riposte", "links": ["riposte_power", "armor_2"]},
		"riposte_power": {"pos": Vector2(8.2, -2.6), "kind": "passive", "name": "Mistrz szermierki", "stats": {"riposte_damage": 0.5}, "links": []},
		"armor_2": {"pos": Vector2(8.2, -1.0), "kind": "passive", "name": "Pancerna postawa", "stats": {"armor": 10.0}, "links": []},
		"cdr_1": {"pos": Vector2(6.8, -0.5), "kind": "passive", "name": "Rytm walki", "stats": {"cooldown_reduction": 0.05}, "links": []},
		# ---- Dym
		"smoke_burst": {"pos": Vector2(1.1, 1.4), "kind": "skill", "skill": "smoke_burst", "links": ["smoke_charge", "spell_1"]},
		"smoke_charge": {"pos": Vector2(2.6, 1.4), "kind": "passive", "name": "Gęsty dym", "stats": {"smoke_charge": 0.25}, "links": ["cast_1", "smoke_dmg"]},
		"spell_1": {"pos": Vector2(1.1, 2.8), "kind": "passive", "name": "Szept run", "stats": {"spell_damage": 0.08}, "links": ["cast_1", "spell_2"]},
		"cast_1": {"pos": Vector2(2.6, 2.8), "kind": "passive", "name": "Bystry umysł", "stats": {"cast_speed": 0.08}, "links": ["spectral_blades", "cast_2"]},
		"smoke_dmg": {"pos": Vector2(4.0, 1.4), "kind": "passive", "name": "Duszący dym", "stats": {"smoke_damage": 0.2}, "links": ["smoke_shadow", "spectral_blades"]},
		"smoke_shadow": {"pos": Vector2(5.5, 0.7), "kind": "keystone", "name": "Dym i Cień", "links": [],
				"description": "Po Dymnych Wybuchach zostaje chmura dymu na 5 s: w niej masz +30% szansy na unik, a Mgnienie nie zużywa many."},
		"spectral_blades": {"pos": Vector2(4.0, 2.8), "kind": "skill", "skill": "spectral_blades", "links": ["blades_count"]},
		"blades_count": {"pos": Vector2(5.4, 3.6), "kind": "passive", "name": "Czwarte ostrze", "stats": {"blade_count": 1.0}, "links": ["mana_regen"]},
		"spell_2": {"pos": Vector2(1.1, 4.2), "kind": "passive", "name": "Pieśń run", "stats": {"spell_damage": 0.1}, "links": ["cast_2"]},
		"cast_2": {"pos": Vector2(2.6, 4.2), "kind": "passive", "name": "Szybkie słowa", "stats": {"cast_speed": 0.08}, "links": ["mana_regen"]},
		"mana_regen": {"pos": Vector2(4.0, 4.5), "kind": "passive", "name": "Źródło mocy", "stats": {"mana_regen": 1.5}, "links": []},
		# ---- Obrona
		"armor_1": {"pos": Vector2(-1.3, 3.5), "kind": "passive", "name": "Kolczuga pod skórą", "stats": {"armor": 8.0}, "links": ["dodge_1", "mana_1"]},
		"dodge_1": {"pos": Vector2(-2.7, 4.4), "kind": "passive", "name": "Unik szermierza", "stats": {"dodge_chance": 0.03}, "links": []},
		"mana_1": {"pos": Vector2(-0.1, 4.6), "kind": "passive", "name": "Głęboki oddech", "stats": {"mana": 20.0}, "links": []},
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
			var shown := ("%+.1f s" % value).replace(".", ",") if stat == "combo_window" \
					else "%+d" % roundi(value) if stat == "blade_count" else "%+d%%" % roundi(value * 100.0)
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
