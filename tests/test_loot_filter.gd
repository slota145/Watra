extends SceneTree
## Filtr łupu (Loot.filter_quality, Loot.filter_tier, Loot.filtered_gold): odrzucone jakości i przedmioty ze słabą
## najlepszą premią zamieniają się w złoto za cenę skupu, a legendy, talizmany i kamienie zostają.

var _fails := 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _initialize() -> void:
	var loot = load("res://scripts/loot.gd")
	var common: String = loot.generate(loot.base_for("sword", 30), "common", 30)
	var magic: String = loot.generate(loot.base_for("sword", 30), "magic", 30)
	var rare: String = loot.generate(loot.base_for("sword", 30), "rare", 30)
	var legend: String = loot.legendary_at_level("legend_faun_horns", 30)
	loot.filter_quality = 0
	loot.filter_tier = 0
	check("bez filtra nic nie znika", loot.filtered_gold(common) < 0 and loot.filtered_gold(rare) < 0)
	loot.filter_quality = 2
	check("odrzucone zwykłe i magiczne", loot.filtered_gold(common) > 0 and loot.filtered_gold(magic) > 0)
	check("rzadkie zostają", loot.filtered_gold(rare) < 0)
	check("cena skupu", loot.filtered_gold(magic) == loot.sell_value("magic", 30))
	loot.filter_quality = 3
	check("legenda nigdy", loot.filtered_gold(legend) < 0)
	check("kamień nigdy", loot.filtered_gold("blessed_stone") < 0)
	loot.filter_quality = 0
	loot.filter_tier = 1
	check("filtr tieru odrzuca słabą premię", loot.filtered_gold(rare) > 0)
	loot.filter_tier = 45
	check("filtr tieru zostawia premię w progu", loot.filtered_gold(rare) < 0)
	loot.filter_tier = 0
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
