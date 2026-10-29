class_name Bounties
## Zlecenia z tablicy ogłoszeń przed gildią: do wyboru zawsze jedno na wilki i jedno na gobliny
## (po 200 sztuk). Po odebraniu nagrody od razu wiszą następne - każde kolejne zlecenie
## (stopień = liczba wykonanych) płaci więcej. Zlecenia to zwykłe zadania zabijania
## (widać je w dzienniku i pod minimapą), tworzone w locie i zapisywane w QuestLog.

const COUNT := 200
const GIVER := "Tablica ogłoszeń"
## Przyrost nagród z każdym wykonanym zleceniem.
const TIER_STEP := 0.15

const KINDS := {
	"wolf": {
		"title": "Wilcza nagonka", "target_name": "Wilki", "area": "wolves",
		"area_name": "siedlisko wilków (południowy wschód)", "gold": 1100, "xp": 6000,
		"description": "Myśliwi z okolicznych azylów płacą za każdego wilka. Watahy z południowego wschodu znów się rozrosły - ubij 200 wilków, a gildia wypłaci nagrodę.",
	},
	"goblin": {
		"title": "Goblińska obława", "target_name": "Gobliny", "area": "goblins",
		"area_name": "obozy goblinów (północny zachód)", "gold": 1000, "xp": 5400,
		"description": "Kupcy skarżą się na napady na szlaku. Gildia wyznaczyła nagrodę: pokonaj 200 goblinów z obozów na północnym zachodzie.",
	},
}


## Zlecenie danego rodzaju na dany stopień (liczbę wykonanych dotąd zleceń).
static func make(kind: String, tier: int) -> Dictionary:
	var base: Dictionary = KINDS[kind]
	var scale := 1.0 + TIER_STEP * tier
	var rewards := {"blessed_stone": 10 + 2 * tier, "mercy_stone": 3 + tier,
			Enchanting.stone_id(["weapon", "armor", "jewelry"][tier % 3], false): 2 + tier / 3}
	# co trzecie zlecenie dorzuca doskonały kamień
	if tier % 3 == 2:
		rewards[Enchanting.stone_id(["weapon", "armor", "jewelry"][(tier / 3) % 3], true)] = 1
	return {
		"title": "%s (zlecenie %d)" % [base["title"], tier + 1],
		"giver": GIVER,
		"target": kind,
		"target_name": base["target_name"],
		"count": COUNT,
		"area": base["area"],
		"area_name": base["area_name"],
		"gold": roundi(base["gold"] * scale),
		"xp": roundi(base["xp"] * scale),
		"reward_items": rewards,
		"bounty": true,
		"description": base["description"],
		"progress_text": "Zlecenie wciąż wisi na tablicy. Wróć, gdy pokonasz wszystkich.",
		"complete_text": "Zlecenie wykonane! Gildia wypłaca nagrodę.",
		"done_text": "Zlecenie wykonane.",
	}


## Dwa zlecenia do wyboru na dany stopień.
static func offers(tier: int) -> Array[Dictionary]:
	return [make("wolf", tier), make("goblin", tier)]


static func is_bounty(id: String) -> bool:
	return id.begins_with("bounty_")
