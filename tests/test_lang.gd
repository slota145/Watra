extends SceneTree
## Tłumaczenia (Lang): polski jako język domyślny i zapasowy, angielskie tłumaczenie z translations/teksty.csv,
## odmiana liczebników po polsku i po angielsku, łączenie listy i zapis języka w ustawieniach.

var _fails := 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _initialize() -> void:
	var game: Node = root.get_node("Game")
	var before: String = game.language
	Lang.set_language("pl")
	check("polski bez zmian", Lang.t("Wróć") == "Wróć")
	check("brak tłumaczenia - polski tekst", Lang.t("Napis bez tłumaczenia 123") == "Napis bez tłumaczenia 123")
	var forms := ["%d ostrze", "%d ostrza", "%d ostrzy"]
	var picked := [1, 2, 4, 5, 12, 22, 25, 112, 0].map(func(n: int) -> String: return Lang.n(n, forms[0], forms[1], forms[2]) % n)
	check("odmiana po polsku", picked == ["1 ostrze", "2 ostrza", "4 ostrza", "5 ostrzy", "12 ostrzy", "22 ostrza", "25 ostrzy", "112 ostrzy", "0 ostrzy"], str(picked))
	check("lista po polsku", Lang.join(["a", "b", "c"]) == "a, b i c" and Lang.join(["a"]) == "a" and Lang.join([]) == "")
	Lang.set_language("en")
	check("angielskie tłumaczenie", Lang.t("Wróć") == "Back", Lang.t("Wróć"))
	check("angielski bez tłumaczenia - polski tekst", Lang.t("Napis bez tłumaczenia 123") == "Napis bez tłumaczenia 123")
	check("odmiana po angielsku", Lang.n(1, "a", "b", "c") == "a" and Lang.n(3, "a", "b", "c") == "c")
	check("nieznany język - polski", (func() -> bool:
		Lang.set_language("xx")
		return Lang.is_polish()).call())
	game.set_language("en")
	var config := ConfigFile.new()
	config.load(game.SETTINGS_PATH)
	check("język w ustawieniach", config.get_value("gameplay", "language", "") == "en" and Lang.current() == "en")
	game.set_language(before)
	print("WYNIK: %s" % ("OK" if _fails == 0 else "%d FAIL" % _fails))
	quit(_fails)
