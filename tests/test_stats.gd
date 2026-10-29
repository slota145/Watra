extends SceneTree
## Test nowych statystyk: tiery, pule, opis, działanie w CharacterStats.

func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_savegame.json"
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)


func _run() -> void:
	var loot: GDScript = load("res://scripts/loot.gd")
	var items: GDScript = load("res://scripts/items.gd")
	for stat in items.STAT_NAMES:
		_check(loot.TIER_VALUES.has(stat) and loot.SUFFIXES.has(stat), "%s: tiery i dopisek" % stat)
		print("    T45 ", loot.tier_range(stat, 45), "  T1 ", loot.tier_range(stat, 1))
	for slot in loot.POOLS:
		_check(loot.POOLS[slot].size() >= 8, "%s: pula %d premii" % [slot, loot.POOLS[slot].size()])
	# losowanie z nowymi statystykami i zapis/odczyt wartości ułamkowych
	var seen := {}
	for i in 300:
		var id: String = loot.generate(loot.base_for(load("res://scripts/item_bases.gd").LINES.keys().pick_random(), 80), "rare", 80)
		for stat in items.get_data(id)["affixes"]:
			seen[stat] = true
	_check(seen.size() == items.STAT_NAMES.size(), "wylosowano wszystkie %d statystyki (%d)" % [items.STAT_NAMES.size(), seen.size()])
	var regen := ""
	for i in 500:
		var id: String = loot.generate("leather_cap", "rare", 70)
		if items.get_data(id)["affixes"].has("health_regen"):
			regen = id
			break
	var before: float = items.get_data(regen)["stats"]["health_regen"]
	var saved: Dictionary = JSON.parse_string(JSON.stringify(loot.export_used([regen])))
	items.generated.erase(regen)
	loot.import(saved)
	_check(is_equal_approx(items.get_data(regen)["stats"]["health_regen"], before), "regeneracja %.1f po zapisie i odczycie" % before)
	print(items.describe(regen))
	# działanie w statystykach postaci
	var eq: Node = load("res://scripts/equipment.gd").new()
	root.add_child(eq)
	var stats: Node = load("res://scripts/character_stats.gd").new()
	root.add_child(stats)
	stats.equipment = eq
	items.generated["gen_t1"] = {"name": "Test", "slot": "ring", "rarity": "rare", "icon": null, "description": "",
		"stats": {"crit_chance": 0.9, "crit_damage": 0.3, "dodge_chance": 0.7, "cooldown_reduction": 0.2, "gold_find": 0.25,
			"xp_gain": 0.1, "damage_percent": 0.15, "life_on_hit": 4, "health_regen": 1.5, "mana_regen": 0.5}}
	eq.equip("gen_t1")
	_check(stats.crit_chance() == 0.75, "limit szansy na krytyk 75%")
	_check(is_equal_approx(stats.crit_multiplier(), 1.8), "krytyk 150% + 30%")
	_check(stats.dodge_chance() == 0.5, "limit uniku 50%")
	_check(is_equal_approx(stats.cooldown_multiplier(), 0.8), "skrócenie odnowienia 20%")
	_check(is_equal_approx(stats.gold_multiplier(), 1.25) and is_equal_approx(stats.xp_multiplier(), 1.1), "złoto i exp")
	_check(is_equal_approx(stats.damage_multiplier(), 1.15) and stats.life_on_hit() == 4, "obrażenia % i zdrowie za trafienie")
	_check(is_equal_approx(stats.health_regen(), 1.5) and is_equal_approx(stats.mana_regen(), 0.5), "regeneracja")
	quit()
