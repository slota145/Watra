class_name Crafting
## Receptury rzemiosła (okno Rzemiosła w plecaku, zakładki wg "group"): przedmioty przyzwania bossów - każdy robi się
## z łupu zdobywanego tam, gdzie mieszka dany boss - i torby (Bags) szyte ze skór i surowców kolejnych krain.
## Składniki bierzemy z plecaka.

const RECIPES: Array[Dictionary] = [
	{"result": "summon_chief", "amount": 1, "ingredients": {"goblin_heart": 20}},
	{"result": "summon_alpha", "amount": 1, "ingredients": {"wolf_pelt": 12}},
	{"result": "summon_frog_chief", "amount": 1, "ingredients": {"frog_tongue": 15}},
	{"result": "summon_storm_eagle", "amount": 1, "ingredients": {"storm_feather": 15}},
	{"result": "summon_wodnik", "amount": 1, "ingredients": {"drowned_algae": 15, "drowned_pearl": 3}},
	{"result": "summon_leshy", "amount": 1, "ingredients": {"ancient_bark": 20}},
	{"result": "summon_spider_queen", "amount": 1, "ingredients": {"spider_silk": 15, "spider_venom": 4}},
	{"result": "summon_bies", "amount": 1, "ingredients": {"beast_fang": 8}},
	{"result": "summon_bombardier", "amount": 1, "ingredients": {"kobold_fuse": 15}},
	{"result": "summon_giant_worm", "amount": 1, "ingredients": {"worm_tooth": 15}},
	{"result": "summon_necromancer", "amount": 1, "ingredients": {"bone_dust": 20}},
	{"result": "summon_colossal_ghoul", "amount": 1, "ingredients": {"ghoul_claw": 15}},
	{"result": "summon_hydra", "amount": 1, "ingredients": {"hydra_scale": 5}},
	{"result": "summon_satyr_king", "amount": 1, "ingredients": {"satyr_horn": 15}},
	{"result": "summon_gryf", "amount": 1, "ingredients": {"gryf_feather": 5}},
	{"result": "bag_purse", "amount": 1, "group": "bags", "ingredients": {"deer_hide": 3, "wolf_pelt": 2}},
	{"result": "bag_satchel", "amount": 1, "group": "bags", "ingredients": {"boar_hide": 5, "wolf_pelt": 5}},
	{"result": "bag_wanderer", "amount": 1, "group": "bags", "ingredients": {"goat_hide": 6, "boar_hide": 6, "frog_tongue": 6}},
	{"result": "bag_hunter", "amount": 1, "group": "bags", "ingredients": {"goat_hide": 12, "spider_silk": 12, "satyr_horn": 6}},
	{"result": "bag_expedition", "amount": 1, "group": "bags", "ingredients": {"spider_silk": 25, "goat_hide": 15, "bone_dust": 20}},
	{"result": "bag_legendary", "amount": 1, "group": "bags",
			"ingredients": {"hydra_scale": 10, "gryf_feather": 10, "storm_feather": 15, "crystal_heart": 2}},
]
## Zakładki okna Rzemiosła.
const GROUPS := {"summon": "Przyzwania bossów", "bags": "Torby"}


static func can_craft(recipe: Dictionary, inventory: Inventory) -> bool:
	for id: String in recipe["ingredients"]:
		if inventory.count_of(id) < int(recipe["ingredients"][id]):
			return false
	return true


## Zabiera składniki i daje wynik. Zwraca false, gdy czegoś brakuje albo plecak jest pełny.
static func craft(recipe: Dictionary, inventory: Inventory) -> bool:
	if not can_craft(recipe, inventory):
		return false
	for id: String in recipe["ingredients"]:
		inventory.remove_item(id, int(recipe["ingredients"][id]))
	var left := inventory.add_item(recipe["result"], int(recipe["amount"]))
	if left > 0:
		# brak miejsca - oddajemy składniki
		inventory.remove_item(recipe["result"], int(recipe["amount"]) - left)
		for id: String in recipe["ingredients"]:
			inventory.add_item(id, int(recipe["ingredients"][id]))
		return false
	return true
