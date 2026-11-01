extends SceneTree
## Nazwy wylosowanych przedmiotów a tłumaczenia: nazwa składana z przepisu (baza + dopiski premii), starsze zapisy
## z gotową polską nazwą, zapis bez nazwy, zmiana języka (przedmioty z łupu, kamienie, esencje, niezidentyfikowane).

var _fails := 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _initialize() -> void:
	# skrypty wczytywane w trakcie (bez nazw klas), żeby nie kompilować przed autoloadami całego łańcucha zależności
	var Items: Variant = load("res://scripts/items.gd")
	var Loot: Variant = load("res://scripts/loot.gd")
	var Gems: Variant = load("res://scripts/gems.gd")
	var Essences: Variant = load("res://scripts/essences.gd")
	var Unidentified: Variant = load("res://scripts/unidentified.gd")
	Lang.set_language("pl")
	# nowy przedmiot z dwiema premiami - nazwa z dopiskami pierwszych dwóch
	var id: String = Loot.register({"base": "sword_t2", "quality": "rare", "level": 10, "affixes": {"dexterity": 5, "intelligence": 4, "health": 20},
			"tiers": {}, "name_stats": ["dexterity", "intelligence"]})
	check("nazwa z dopiskami", Items.get_data(id)["name"] == "Stalowy miecz Rysia i Sowy", Items.get_data(id)["name"])
	check("zapis bez nazwy", not Loot.export_used([id])[id].has("name"))
	# starszy zapis: gotowa polska nazwa (dopiski w kolejności losowania, nie alfabetycznej)
	var old: String = Loot.register({"base": "sword_t2", "quality": "magic", "level": 5, "affixes": {"dexterity": 5, "intelligence": 4},
			"tiers": {}, "name": "Stalowy miecz Sowy i Rysia"})
	check("starszy zapis - ta sama nazwa", Items.get_data(old)["name"] == "Stalowy miecz Sowy i Rysia", Items.get_data(old)["name"])
	check("starszy zapis - dopiski z nazwy", Loot.export_used([old])[old].get("name_stats", []) == ["intelligence", "dexterity"])
	var legend: String = Loot.legendary_at_level("legend_swarog_bow", 20)
	var generated: String = Loot.generate("sword_t2", "magic", 8)
	var gem: String = Gems.roll("ruby", 1)
	var unid: String = Unidentified.id_for("weapon", "rare", 12)
	var pl_names := [Items.get_data(generated)["name"], Items.get_data(gem)["name"], Items.get_data(unid)["name"]]
	check("legenda - nazwa legendy", Items.get_data(legend)["name"] == "Łuk Swaroga", Items.get_data(legend)["name"])
	check("kamień po polsku", Items.get_data(gem)["name"] == "Rubin (odłamek)", Items.get_data(gem)["name"])
	check("niezidentyfikowany po polsku", Items.get_data(unid)["name"] == "Niezidentyfikowana broń (rzadka, poz. 12)", Items.get_data(unid)["name"])

	# zmiana języka - nazwy powstają od nowa z przepisu
	var english := Translation.new()
	english.locale = "en"
	for pair: Array in [["Stalowy miecz", "Steel Sword"], ["Rysia", "of the Lynx"], ["Sowy", "of the Owl"], ["%s i %s", "%s and %s"],
			["Rubin", "Ruby"], ["Odłamek", "Shard"], ["Łuk Swaroga", "Swaróg's Bow"], ["Niezidentyfikowana broń", "Unidentified Weapon"],
			["rzadka", "rare"], ["%s (%s, poz. %d)", "%s (%s, Lv. %d)"], ["Esencja: %s", "Essence: %s"]]:
		english.add_message(pair[0], pair[1])
	TranslationServer.add_translation(english)
	Lang.set_language("en")
	check("angielska nazwa z dopiskami", Items.get_data(id)["name"] == "Steel Sword of the Lynx and of the Owl", Items.get_data(id)["name"])
	check("angielska nazwa starszego zapisu", Items.display_name(old) == "Steel Sword of the Owl and of the Lynx", Items.display_name(old))
	check("angielska legenda", Items.display_name(legend) == "Swaróg's Bow", Items.display_name(legend))
	check("angielski kamień", Items.display_name(gem) == "Ruby (shard)", Items.display_name(gem))
	check("angielski niezidentyfikowany", Items.display_name(unid) == "Unidentified Weapon (rare, Lv. 12)", Items.display_name(unid))
	var essence: String = Essences.extract(legend)
	check("angielska esencja", Items.display_name(essence) == "Essence: Swaróg's Bow", Items.display_name(essence))
	check("opis po angielsku bez błędów", Items.describe(id) != "" and Items.describe(essence) != "")
	Lang.set_language("pl")
	check("powrót do polskiego", [Items.get_data(generated)["name"], Items.get_data(gem)["name"], Items.get_data(unid)["name"]] == pl_names)
	check("esencja po polsku", Items.display_name(essence) == "Esencja: Łuk Swaroga", Items.display_name(essence))
	TranslationServer.remove_translation(english)
	print("WYNIK: %s" % ("OK" if _fails == 0 else "%d FAIL" % _fails))
	quit(_fails)
