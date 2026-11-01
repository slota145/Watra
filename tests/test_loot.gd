extends SceneTree
## Test systemu przedmiotów: tiery, liczba premii, skłonność jakości, zapis/odczyt, opis z porównaniem.

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var items: GDScript = load("res://scripts/items.gd")
	_check(loot.best_tier(1) == 45 and loot.worst_tier(1) == 45, "poziom 1: tylko tier 45")
	_check(loot.best_tier(100) == 1 and loot.worst_tier(100) == 10, "poziom 100: tiery 1-10")
	print("  okna: ", [1, 10, 25, 50, 75, 100].map(func(l): return [l, loot.best_tier(l), loot.worst_tier(l)]))
	for stat in ["health", "armor", "attack_speed"]:
		print("  ", stat, " T45 ", loot.tier_range(stat, 45), " T20 ", loot.tier_range(stat, 20), " T1 ", loot.tier_range(stat, 1))
	# jakość: liczba premii i średni tier na poziomie 60
	for quality in ["common", "magic", "rare", "legendary"]:
		var counts := {}
		var tier_sum := 0.0
		var n := 0
		var bad_tier := false
		for i in 400:
			var id: String = loot.generate("iron_helmet" if quality != "legendary" else "ring_gruzlog", quality, 60)
			var item: Dictionary = items.get_data(id)
			counts[item["affixes"].size()] = counts.get(item["affixes"].size(), 0) + 1
			for stat in item["tiers"]:
				var t: int = item["tiers"][stat]
				tier_sum += t
				n += 1
				if t < loot.best_tier(60) or t > loot.worst_tier(60):
					bad_tier = true
		var span: Array = loot.AFFIX_COUNTS[quality]
		var keys := counts.keys()
		_check(keys.min() >= span[0] and keys.max() <= span[1], "%s: liczba premii %s w %s" % [quality, str(counts), str(span)])
		_check(not bad_tier, "%s: tiery w oknie poziomu 60" % quality)
		print("  %s: średni tier %.2f" % [quality, tier_sum / maxf(n, 1)])
	# baza rośnie z poziomem
	var low: String = loot.generate("iron_sword", "common", 1)
	var high: String = loot.generate("iron_sword", "common", 100)
	print("  miecz poz. 1: ", items.weapon_damage(low), "  poz. 100: ", items.weapon_damage(high))
	_check(items.weapon_damage(low) == [14, 20], "poziom 1 = statystyki z bazy")
	# zapis i odczyt
	var id: String = loot.generate("chainmail", "rare", 40)
	var before: Dictionary = items.get_data(id).duplicate(true)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(loot.export_used([id])))
	items.generated.erase(id)
	loot.import(saved)
	var after: Dictionary = items.get_data(id)
	_check(after["stats"] == before["stats"] and after["tiers"] == before["tiers"] and after["item_level"] == 40, "zapis i odczyt przepisu")
	# dawny przepis (bez poziomu i tierów)
	loot.import({"gen_9001": {"base": "iron_helmet", "quality": "magic", "affixes": {"health": 12.0}, "name": "Stary hełm Dębu"}})
	var old: Dictionary = items.get_data("gen_9001")
	_check(old["item_level"] == 1 and old["stats"].get("health") == 12 and old["stats"]["armor"] == 5, "dawny przepis -> poziom 1")
	# enchant biżuterii liczy się od przeskalowanej bazy
	var ring: String = loot.generate("copper_ring", "common", 50)
	var base_health: int = items.base_stats(ring)["health"]
	_check(items.stats_of(ring, 3)["health"] == items.get_data(ring)["stats"]["health"] + 3, "zaklęcie biżuterii +3 (baza %d)" % base_health)
	var world_legend: String = loot.world_legend(20)
	_check(items.get_data(world_legend)["rarity"] == "legendary", "legenda ze zwykłego potwora")
	_check(loot.WORLD_LEGEND_CHANCE * 700.0 < 0.1, "legenda z potwora bardzo rzadka (cała kraina < 10%)")
	print("\n--- opis z porównaniem ---")
	print(items.describe(high, 0, {"id": low, "enchant": 5}))
	quit()
