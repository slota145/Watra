extends SceneTree
## Symulacja siły tierów premii: postać na 40. poziomie (wojownik z mieczem, 20 siły i 19 witalności)
## w ekwipunku z typowymi premiami z poziomu 40, z najlepszymi możliwymi dziś (najwyższy tier pasma szczęścia)
## i z samymi T1. Wypisuje tabelę wartości premii na tierach i wyniki postaci (zdrowie, obrażenia, przeżywalność).

const LEVEL := 40
const ITEM_LEVEL := 40
const STR := 20
const VIT := 19
const BASES := {"weapon": "sword", "helmet": "helm", "chest": "plate", "gloves": "gauntlets", "boots": "greaves",
		"earring_1": "stud", "earring_2": "stud", "ring_1": "signet", "ring_2": "signet", "necklace": "amulet", "belt": "girdle"}
## Wartości T1 do porównania (nadpisują Loot.TIER_VALUES z argumentem "propozycja"; obecne wartości to propozycja z listopada 2026).
const PROPOSAL := {"health": [5.0, 120.0], "crit_chance": [0.01, 0.07], "move_speed": [0.02, 0.20], "crit_damage": [0.05, 0.45]}
const PRIORITY := ["damage", "physical_damage", "damage_percent", "crit_chance", "crit_damage", "attack_speed",
		"health", "move_speed", "strength", "armor", "vitality", "life_on_hit", "area", "dodge_chance",
		"cooldown_reduction", "health_regen", "mana", "dexterity", "intelligence", "mana_regen", "gold_find", "xp_gain",
		"potion_power", "spell_damage", "cast_speed"]


var values := Loot.TIER_VALUES.duplicate()


func _init() -> void:
	if "propozycja" in OS.get_cmdline_user_args():
		values.merge(PROPOSAL, true)
		print("PROPOZYCJA: ", PROPOSAL)
	var tiers := [40, 33, 26, 13, 1]
	print("WARTOSCI premii (srodek zakresu) na tierach ", tiers)
	for stat: String in values:
		var row := []
		for t: int in tiers:
			var r := _range(stat, t)
			row.append(snappedf((float(r[0]) + float(r[1])) / 2.0, 0.001))
		print("  %-20s %s" % [stat, str(row)])
	print("okno ilvl 40: best ", Loot.best_tier(40), " worst ", Loot.worst_tier(40), " top(szczescie) ", Loot.top_tier(40),
			" | ilvl 43: best ", Loot.best_tier(43), " top ", Loot.top_tier(43))
	_report("Typowy rzadki (5 premii, losowe tiery ilvl 40, srednia 300 prob)", -1, 5, 300)
	_report("Najlepszy dzis (6 premii, tier %d)" % Loot.top_tier(43), Loot.top_tier(43), 6, 1)
	_report("Sufit Skarbnika (6 premii, tier %d)" % SkarbnikOffer.ceiling_tier(43), SkarbnikOffer.ceiling_tier(43), 6, 1)
	_report("Pelne T1 (6 premii)", 1, 6, 1)
	_report("Pelne T1 (8 premii, legendy)", 1, 8, 1)
	quit()


func _report(title: String, tier: int, count: int, samples: int) -> void:
	var acc := {}
	for i in samples:
		var r := _simulate(tier, count)
		for k: String in r:
			acc[k] = float(acc.get(k, 0.0)) + r[k] / samples
	var parts := []
	for k: String in acc:
		parts.append("%s=%s" % [k, str(snappedf(acc[k], 0.01))])
	print("WYNIK ", title, ": ", ", ".join(parts))


func _simulate(tier: int, count: int) -> Dictionary:
	var total := {}
	var weapon := {}
	for slot: String in BASES:
		var base := Loot.base_for(BASES[slot], ITEM_LEVEL)
		var pool: Array = Loot.POOLS[Items.get_data(base)["slot"]]
		var chosen := []
		for stat: String in PRIORITY:
			if stat in pool and chosen.size() < count:
				chosen.append(stat)
		var affixes := {}
		for stat: String in chosen:
			var t := tier if tier > 0 else Loot.roll_tier(ITEM_LEVEL, Loot.RARE)
			var r := _range(stat, t)
			var v := (float(r[0]) + float(r[1])) / 2.0
			affixes[stat] = v if Loot._step(stat) > 0.0 else roundi(v)
		var id := Loot.register({"base": base, "quality": Loot.RARE, "level": ITEM_LEVEL, "affixes": affixes, "tiers": {}})
		var data := Items.get_data(id)
		if slot == "weapon":
			weapon = data["weapon"]
		for stat: String in data["stats"]:
			total[stat] = float(total.get(stat, 0.0)) + float(data["stats"][stat])
	var strength := STR + float(total.get("strength", 0))
	var vit := VIT + float(total.get("vitality", 0))
	var hp := 100.0 + (LEVEL - 1) * 8 + vit * 5 + float(total.get("health", 0))
	var armor := float(total.get("armor", 0))
	var dr := 1.0 - (50.0 / (50.0 + armor)) * (1.0 - minf(strength * 0.005, 0.25))
	var dodge := minf(float(total.get("dodge_chance", 0)), 0.5)
	var crit := minf(float(total.get("crit_chance", 0)), 0.75)
	var crit_mult := 1.5 + float(total.get("crit_damage", 0))
	var aspd := 1.0 + float(total.get("attack_speed", 0))
	var hit: float = (weapon["damage"][0] + weapon["damage"][1]) / 2.0 + strength + float(total.get("damage", 0))
	var dps: float = hit * (1.0 + float(total.get("damage_percent", 0))) * (1.0 + float(total.get("physical_damage", 0))) \
			* aspd * weapon["speed"] * (1.0 + crit * (crit_mult - 1.0))
	return {"zdrowie": hp, "pancerz": armor, "redukcja": dr, "unik": dodge, "kryt": crit, "mn_kryt": crit_mult,
			"szyb_ataku": aspd, "ruch": 1.0 + float(total.get("move_speed", 0)), "cios": hit, "dps": dps,
			"ehp": hp / (1.0 - dr) / (1.0 - dodge)}


## Jak Loot.tier_range, ale z wartościami z `values` (bez zaokrągleń).
func _range(stat: String, tier: int) -> Array:
	var ends: Array = values[stat]
	var x := float(Loot.TIERS - clampi(tier, 1, Loot.TIERS)) / Loot.TIERS
	return [ends[0] * pow(ends[1] / ends[0], x), ends[0] * pow(ends[1] / ends[0], x + 1.0 / Loot.TIERS)]
