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
	# etap 3: żywioły lochu z modyfikatorów i bożków
	var dungeons = load("res://scripts/dungeons.gd")
	var idols = load("res://scripts/idols.gd")
	var config: Dictionary = dungeons.config("catacombs", 8, ["scorch", "curse"], 1, [idols.id_of("rime", "rare")])
	el.apply_dungeon(config)
	check("Pożoga dodaje ogień", is_equal_approx(float(el.added.get("fire", 0.0)), 0.3))
	check("Bożek Szronu dodaje lód", is_equal_approx(float(el.added.get("cold", 0.0)), 0.3))
	check("Klątwa żywiołów obniża odporność", is_equal_approx(el.curse, 0.25))
	stats.set_temp("t", {})
	check("klątwa w odporności gracza", is_equal_approx(stats.resistance("fire"), -0.25) and is_zero_approx(stats.resistance("nawia")))
	check("opis bożka żywiołu", idols.effect_lines(idols.id_of("blaze", "common")).size() >= 3)
	el.clear_dungeon()
	check("poza lochem bez żywiołów lochu", el.added.is_empty() and is_zero_approx(el.curse))
	# krok 3 dopieszczenia walki: premie formy i szanse na stany
	stats.set_temp("t", {"projectile_damage": 0.2, "dot_damage": 0.3, "ignite_chance": 0.9})
	check("obrażenia pocisków dla tagu pocisku", is_equal_approx(stats.kind_multiplier(["spell", "projectile"]) - stats.kind_multiplier(["spell"]), 0.2))
	check("obrażenia w czasie dla tagu dot", is_equal_approx(stats.kind_multiplier(["attack", "dot"]) - stats.kind_multiplier(["attack"]), 0.3))
	check("szansa na stan ma sufit", is_equal_approx(stats.ailment_chance("ignite"), 0.5) and is_zero_approx(stats.ailment_chance("shock")))
	check("każdy żywioł ma stan", el.AILMENTS.size() == 3)
	# maksymalna odporność (rzadkie węzły drzewka): sufit rośnie z premią, ale najwyżej do 85%
	stats.set_temp("t", {"fire_resistance": 1.0, "fire_max_resistance": 0.02, "cold_resistance": 1.0, "cold_max_resistance": 0.5})
	check("+2% maksymalnej odporności", is_equal_approx(stats.resistance("fire"), 0.77), "%.2f" % stats.resistance("fire"))
	check("sufit najwyżej 85%", is_equal_approx(stats.resistance("cold"), 0.85))
	check("inne żywioły bez zmian", is_equal_approx(stats.max_resistance("lightning"), 0.75))
	var tree = load("res://scripts/skill_tree.gd")
	check("węzły maksymalnej odporności w drzewku", ["fire_max", "cold_max", "lightning_max", "nawia_max"].all(
			func(id: String) -> bool: return tree.has_node(id) and not tree.is_soon(id)))
	var rings: Array = tree.nodes().keys().filter(func(id: String) -> bool: return id.begins_with("ring_"))
	check("autostrady w drzewku", rings.size() > 60, str(rings.size()))
	stats.free()
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
