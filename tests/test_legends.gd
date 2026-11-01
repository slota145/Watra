extends SceneTree
## Legendy bossów: każdy przedmiot z legendary_drops w scenach bossów istnieje, ma miejsce na postaci,
## efekt z opisem (Items.EFFECT_TEXTS, dymek Items.describe się składa) i daje się wylosować z poziomem (Loot.legendary_at_level).

var _fails := 0


func _check(what: String, ok: bool) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		_fails += 1


func _initialize() -> void:
	var items = load("res://scripts/items.gd")
	var loot = load("res://scripts/loot.gd")
	var ids := []
	var dir := DirAccess.open("res://scenes")
	for file in dir.get_files():
		if not file.ends_with(".tscn"):
			continue
		var text := FileAccess.get_file_as_string("res://scenes/" + file)
		var found := RegEx.create_from_string('legendary_drops = PackedStringArray\\(([^)]*)\\)').search(text)
		if found == null:
			continue
		for part in found.get_string(1).split(","):
			var id := part.strip_edges().trim_prefix('"').trim_suffix('"')
			if id != "":
				ids.append(id)
	_check("legendy w scenach bossów (%d)" % ids.size(), ids.size() >= 20)
	for id: String in ids:
		var data: Dictionary = items.get_data(id)
		var effect: String = data.get("effect", {}).get("kind", "")
		var ok: bool = not data.is_empty() and data.get("slot", "") != "" and data.get("rarity", "") == "legendary" \
				and items.EFFECT_TEXTS.has(effect) and data.get("icon") != null
		var rolled: String = loot.legendary_at_level(id, 20)
		ok = ok and rolled != "" and items.get_data(rolled).get("rarity", "") == "legendary"
		# dymek z opisem (błąd formatowania - np. "%" bez "%%" w EFFECT_TEXTS - daje pusty tekst)
		# (napis w języku gry - na komputerze z angielskim systemem gra startuje po angielsku)
		var label: String = Lang.t("Efekt: %s").get_slice("%", 0)
		ok = ok and items.describe(id).contains(label) and items.describe(rolled).contains(label)
		_check("%s (%s, %s)" % [id, data.get("slot", "?"), effect], ok)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
