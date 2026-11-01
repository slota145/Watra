class_name Bounties
## Zlecenia z tablicy ogłoszeń przed gildią. Wystawiają je inni podróżnicy (Travelers) i mieszkańcy Ostoi; na tablicy
## wisi kilka ofert naraz (więcej przy wyższej randze gildii - offer_count), odświeżanych co REFRESH sekund, a gracz
## może mieć MAX_ACTIVE przyjętych. Rodzaje:
## - "kill": pokonaj N potworów danego rodzaju (Goblin.quest_kind) w jednej z odkrytych krain,
## - "boss": pokonaj bossa krainy (cel "boss:<nazwa sceny>" - World._on_goblin_died),
## - "gather": przynieś surowce i trofea krainy (liczy się plecak i magazyn, oddaje się je przy odbiorze nagrody).
## Krainy: odkryte kapliczki (World.shrines) i Gobliński Las, najwyżej trochę powyżej poziomu gracza. Nagroda rośnie
## z poziomem krainy: złoto, doświadczenie, przedmioty (mikstury, kamienie szlachetne, czasem Serce Kryształu)
## i sława gildii (Travelers.guild_fame - od niej zależą rangi gildii). Każde wykonane zlecenie płaci odrobinę więcej.

const GIVER := "Tablica ogłoszeń"
const MAX_ACTIVE := 3
const REFRESH := 600
## Przyrost nagród z każdym wykonanym zleceniem (do limitu).
const TIER_STEP := 0.03
const TIER_MAX := 1.0

## Potwory do zleceń w krainach: [quest_kind, nazwa w celu, ile (min, max), gdzie].
const HUNTS := {
	"forest": [["goblin", "Gobliny", 40, 120, "obozy goblinów (północny zachód Goblińskiego Lasu)"],
			["wolf", "Wilki", 40, 120, "siedlisko wilków (południowy wschód Goblińskiego Lasu)"]],
	"fields": [["kobold", "Koboldy", 40, 120, "obóz koboldów i łany Pól Zbożowych"],
			["worm", "Czerwie polne", 20, 60, "łany Pól Zbożowych"]],
	"swamp": [["frogman", "Żabołaki", 40, 100, "wioska żabołaków na Rozlewiskach"],
			["drowner", "Utopce", 30, 90, "Topielcze Uroczysko (pod drogą, na zachód od rzeki)"],
			["wisp", "Ogniki", 20, 60, "Topielcze Uroczysko"], ["rusalka", "Topielice", 15, 40, "sadzawki Topielczego Uroczyska"]],
	"mountains": [["birdman", "Ptakoludzie", 40, 120, "wioska ptakoludzi w Wietrznych Turniach"],
			["satyr", "Satyry", 40, 100, "polana satyrów w Wietrznych Turniach"]],
	"ancient": [["spider", "Pająki", 40, 120, "leże pająków w Prastarym Lesie"], ["treant", "Drzewce", 20, 60, "gęstwina Prastarego Lasu"]],
	"cemetery": [["skeleton", "Szkielety", 60, 160, "kwatery Leśnego Cmentarza"], ["ghoul", "Ghule", 20, 60, "trupowisko Leśnego Cmentarza"]],
}
## Bossowie krain (nazwy scen - Codex).
const BOSSES := {
	"forest": ["goblin_chief", "alpha_wolf"], "fields": ["kobold_bombardier", "giant_worm", "gryf"],
	"swamp": ["frog_chief", "hydra"], "mountains": ["storm_eagle", "satyr_king"],
	"ancient": ["leshy", "spider_queen", "bies"], "cemetery": ["necromancer", "colossal_ghoul"],
}
## Surowce i trofea krain: [id przedmiotu, ile (min, max)].
const GATHER := {
	"forest": [["wood", 30, 80], ["stone", 20, 60], ["wolf_pelt", 5, 15], ["goblin_heart", 5, 15], ["herb_wort", 6, 15], ["meat", 10, 30]],
	"fields": [["herb_chamomile", 6, 15], ["kobold_fuse", 5, 15], ["worm_tooth", 4, 10]],
	"swamp": [["herb_calamus", 6, 15], ["frog_tongue", 5, 15], ["drowned_algae", 5, 15]],
	"mountains": [["iron_ore", 15, 40], ["herb_arnica", 6, 15], ["goat_hide", 5, 15], ["satyr_horn", 4, 12]],
	"ancient": [["ancient_bark", 8, 20], ["spider_silk", 8, 20], ["herb_fern", 1, 3], ["beast_fang", 3, 8]],
	"cemetery": [["bone_dust", 10, 25], ["herb_datura", 5, 12], ["ghoul_claw", 4, 10]],
}
const SHRINE_ZONES := {"old_mill": "fields", "swamp_ford": "swamp", "eagle_pass": "mountains", "old_oak": "ancient", "grave_chapel": "cemetery"}
const RESIDENTS := ["Sołtys Mirosław", "Myśliwy Radek", "Kupiec Bogdan", "Karczmarz Wacław", "Kowal Bronisław"]
const KILL_LINES := ["%s nie dają nam żyć. Przetrzebisz je?", "Ktoś musi wreszcie zrobić porządek z tymi bestiami: %s.",
		"Szukam śmiałka, który pomoże z plagą: %s.", "Płacę uczciwie za każdą ubitą sztukę. Cel: %s."]
const BOSS_LINES := ["Ten potwór zabił mi towarzysza. Pomścij go - %s musi zginąć.", "%s wciąż żyje. Gildia wyznaczyła nagrodę.",
		"Słyszałem, że %s strzeże skarbu. Nagroda dla tego, kto go pokona."]
const GATHER_LINES := ["Potrzebuję tego do roboty: %s. Zapłacę dobrze.", "Skupuję %s - przynieś, a nie pożałujesz.",
		"Moja drużyna wyrusza w drogę i brakuje nam zapasów: %s."]


static func is_bounty(id: String) -> bool:
	return id.begins_with("bounty_")


## Ile ofert wisi naraz (ranga gildii 1-6 -> 4-8).
static func offer_count(rank: int) -> int:
	return clampi(3 + rank, 4, 8)


## Krainy dla zleceń: odkryte kapliczki i Gobliński Las, poziomem niewiele powyżej gracza.
static func zones_for(player: Player) -> Array[String]:
	var result: Array[String] = ["forest"]
	var world := player.get_tree().get_first_node_in_group("world") if player.is_inside_tree() else null
	for shrine: String in SHRINE_ZONES:
		var zone: String = SHRINE_ZONES[shrine]
		if world != null and world.shrines.has(shrine) and Levels.ZONES[zone][0] <= player.stats.level + 4:
			result.append(zone)
	return result


## Nowe oferty na tablicy.
static func generate(player: Player, count: int, tier: int) -> Array[Dictionary]:
	var zones := zones_for(player)
	var names: Array = player.travelers.active().map(func(t: Dictionary) -> String: return t["name"])
	names.append_array(RESIDENTS)
	var result: Array[Dictionary] = []
	for i in count:
		var zone: String = zones.pick_random()
		var roll := randf()
		var kind := "kill" if roll < 0.55 else "gather" if roll < 0.85 else "boss"
		result.append(make(kind, zone, tier, names.pick_random()))
	return result


## Jedno zlecenie danego rodzaju w krainie; `tier` - liczba wykonanych zleceń (nagrody rosną).
## Teksty to wzory z danymi (Quests.resolve) - składane i tłumaczone przy pokazywaniu, nie w zapisie gry.
static func make(kind: String, zone: String, tier: int, poster: String) -> Dictionary:
	var level: int = Levels.ZONES[zone][1]
	var scale := (1.0 + minf(TIER_STEP * tier, TIER_MAX)) * randf_range(0.9, 1.1)
	var zone_name: String = Zones.DATA[zone]["name"]
	var quest := {"giver": GIVER, "poster": poster, "bounty": true, "zone": zone, "area": "", "kind": kind,
			"progress_text": "Zlecenie wciąż wisi na tablicy. Wróć, gdy je wykonasz.",
			"complete_text": ["Zlecenie wykonane! %s dziękuje i wypłaca nagrodę.", poster], "done_text": "Zlecenie wykonane."}
	var units := 1.0
	match kind:
		"kill":
			var hunt: Array = HUNTS[zone].pick_random()
			var count := roundi(randi_range(hunt[2], hunt[3]) / 10.0) * 10
			quest.merge({"title": ["%s: %s", zone_name, hunt[1]], "target": hunt[0], "target_name": hunt[1], "count": count,
					"area_name": hunt[4], "description": [KILL_LINES.pick_random(), {"t": hunt[1], "lower": true}]})
			units = count
		"boss":
			var boss: String = BOSSES[zone].pick_random()
			var boss_name: String = Codex.monster_info(boss).get("boss_name", boss)
			quest.merge({"title": ["Nagroda za głowę: %s", {"t": boss_name, "slice": true}], "target": "boss:" + boss,
					"target_name": boss_name, "count": 1, "area_name": zone_name,
					"description": [BOSS_LINES.pick_random(), {"t": boss_name, "slice": true}]})
			units = 60.0
		"gather":
			var wanted: Array = GATHER[zone].pick_random()
			var count := randi_range(wanted[1], wanted[2])
			var item_name: String = Items.get_data(wanted[0])["name"]
			quest.merge({"title": ["Zamówienie: %s", item_name], "type": "gather", "item": wanted[0], "target_name": item_name,
					"count": count, "area_name": ["%s - liczy się plecak i magazyn, oddajesz przy odbiorze", zone_name],
					"description": [GATHER_LINES.pick_random(), {"t": item_name, "lower": true}]})
			units = 25.0 + count * maxf(1.0, Market.COMMODITIES.get(wanted[0], 8) / 8.0)
	quest["gold"] = roundi(Levels.gold(level) * units * 1.6 * scale)
	quest["xp"] = roundi(Levels.xp(level) * units * 0.5 * scale)
	quest["fame"] = {"kill": 10, "gather": 8, "boss": 30}[kind] + roundi(level / 4.0)
	quest["reward_items"] = _rewards(kind, level)
	return quest


static func _rewards(kind: String, level: int) -> Dictionary:
	var items := {}
	items["greater_health_potion" if level >= 12 else "health_potion"] = 2 + level / 10
	if randf() < 0.5:
		items["greater_mana_potion" if level >= 12 else "mana_potion"] = 1 + level / 12
	if kind == "boss" and level >= 20 and randf() < 0.35:
		items["crystal_heart"] = 1
	if kind == "boss" and randf() < 0.5:
		items["mercy_stone"] = 1
	return items


## Kamień szlachetny w nagrodzie (po zadaniu jubilera) - wylosowany przy odbiorze, więc tylko w opisie.
static func gem_bonus(quest: Dictionary) -> bool:
	return Gems.unlocked and quest.get("kind", "") in ["boss", "kill"] and int(quest.get("count", 0)) >= 1
