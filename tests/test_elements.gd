extends SceneTree
## Żywioły (scripts/elements.gd): odporności gracza (sufit, kara Mapy Nawii), obrażenia po obronie wg rodzaju,
## premie do obrażeń umiejętności z tagiem żywiołu i odporności / wrażliwości potworów z przebiciem.

var _fails := 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _initialize() -> void:
	var el = load("res://scripts/elements.gd")
	var stats = load("res://scripts/character_stats.gd").new()
	el.penalty = 0.0
	check("bez premii odporność 0", is_zero_approx(stats.resistance("fire")))
	stats.set_temp("t", {"fire_resistance": 0.5, "all_resistances": 0.5, "nawia_resistance": 0.3})
	check("sufit 75%", is_equal_approx(stats.resistance("fire"), 0.75))
	check("na żywioły podnosi lód", is_equal_approx(stats.resistance("cold"), 0.5))
	check("na żywioły nie działa na Nawię", is_equal_approx(stats.resistance("nawia"), 0.3))
	el.penalty = el.penalty_for_tier(17)
	check("kara stopnia 17 to 60%", is_equal_approx(el.penalty, 0.6))
	check("kara stopnia 8 to 20%", is_equal_approx(el.penalty_for_tier(8), 0.2) and is_zero_approx(el.penalty_for_tier(7)))
	check("kara obniża odporność", is_equal_approx(stats.resistance("cold"), -0.1) and is_equal_approx(stats.resistance("nawia"), -0.3))
	check("ujemna odporność zwiększa obrażenia", stats.taken_multiplier("nawia") > 1.0)
	el.penalty = 0.0
	stats.set_temp("t", {"fire_damage": 0.3, "elemental_damage": 0.2})
	var fire: float = stats.kind_multiplier(["spell", "fire"]) - stats.kind_multiplier(["spell"])
	check("obrażenia od ognia dla tagu ognia", is_equal_approx(fire, 0.5), "%.2f" % fire)
	check("bez tagu żywiołu bez premii", is_equal_approx(stats.kind_multiplier(["spell", "lightning"]) - stats.kind_multiplier(["spell"]), 0.2))
	check("wrażliwość potwora zwiększa obrażenia", is_equal_approx(el.hit_multiplier(-0.25, 0.0), 1.25))
	check("przebicie zmniejsza odporność", is_equal_approx(el.hit_multiplier(0.4, 0.15), 0.75))
	check("szkielety wrażliwe na ogień", float(el.monster_resistances("skeleton").get("fire", 0.0)) < 0.0)
	stats.free()
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
