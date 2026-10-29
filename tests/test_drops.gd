extends SceneTree
## Łup: poziomy linii wg poziomu przedmiotu, wygląd wg rzadkości, legendy bossów, koszt w kuźni.

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var items: GDScript = load("res://scripts/items.gd")
	var bases: GDScript = load("res://scripts/item_bases.gd")
	var bad := 0
	var tiers := {}
	for i in 400:
		var id: String = loot.random_drop(randi_range(1, 3), 0.2, "", 5 if i % 4 == 0 else 0)
		var item: Dictionary = items.get_data(id)
		var base: Dictionary = items.get_data(item["base"])
		var tier: int = base["tier"]
		tiers[tier] = tiers.get(tier, 0) + 1
		if loot.tier_of(item["item_level"]) + 1 != tier or item["icon"] == null:
			bad += 1
		if item["rarity"] != "common" and base["looks"].has(item["rarity"]) and item["icon"] != base["looks"][item["rarity"]]["icon"]:
			bad += 1
	_check(bad == 0, "400 łupów: poziom linii zgodny z poziomem przedmiotu, ikona wg rzadkości (poziomy: %s)" % str(tiers))
	_check(loot.base_for("sword", 1) == "iron_sword" and loot.base_for("sword", 100) == "sword_t5" and loot.base_for("plate", 45) == "plate_t3", "base_for")
	var leg: String = loot.legendary("ring_storm", 3)
	_check(items.get_data(leg)["rarity"] == "legendary" and items.get_data(leg)["icon"] == items.get_data("ring_storm")["icon"] and items.get_data(leg)["affixes"].size() >= 6, "legenda bossa z własną ikoną i premiami")
	var rare_bow: String = loot.generate("bow_t4", "rare", 70)
	var w: Dictionary = items.get_data(rare_bow)["weapon"]
	_check(w["held"] == bases.DATA["bow_t4"]["looks"]["rare"]["weapon"]["held"] and w["hold"] == "bow" and w["damage"][0] > 9, "rzadki łuk: broń w ręku wersji rzadkiej, obrażenia z poziomem")
	_check(load("res://scripts/ui/forge_window.gd").cost("mace_t1", "rare").has("gold"), "kuźnia: koszt dla nowej linii bez ceny sklepowej")
	for id in ["iron_sword", "leather_cap", "chainmail", "rusty_sword", "amber_necklace", "copper_ring"]:
		if items.get_data(id).is_empty():
			print("FAIL brak dawnego przedmiotu ", id)
	_check(items.get_data("iron_sword").get("price", 0) == 80, "dawne przedmioty ze sklepu zachowują ceny")
	quit()
