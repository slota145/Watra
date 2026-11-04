extends SceneTree
## Drzewko Watry (scripts/watra_tree.gd): układ (13 gałęzi, wszystkie węzły osiągalne, węzły się nie nakładają),
## wybieranie tylko obok wybranych i za wolne punkty, cofanie tylko węzłów z końca ścieżki, 3 zakładki z osobnymi pulami,
## premie (wagi, wymuszone mechaniki, moc razem z bożkami, mnożniki lochów, bożki, Błogosławieństwo), zapis zakładek;
## potem okno drzewka w HUD: wybieranie, cofanie za złoto, czyszczenie zakładki, zmiana zakładki i dodatkowe sloty
## na bożki w oknie lochów.

var _world: Node
var _frame := 0
var _fails := 0
var _T
var _D
var _I


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	_T = load("res://scripts/watra_tree.gd")
	_D = load("res://scripts/dungeons.gd")
	_I = load("res://scripts/idols.gd")
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_layout() -> void:
	var nodes: Dictionary = _T.nodes()
	check("13 gałęzi po 11 węzłów i start", nodes.size() == 13 * 11 + 1, str(nodes.size()))
	check("więcej węzłów niż punktów z całej mapy", nodes.size() - 1 > load("res://scripts/nawia_map.gd").node_count())
	var all: Array = nodes.keys()
	all.erase(_T.START)
	check("wszystkie węzły połączone z Watrą", _T.connected(all).size() == all.size())
	var closest := INF
	for a: String in nodes:
		for b: String in nodes:
			if a < b:
				closest = minf(closest, (nodes[a]["pos"] as Vector2).distance_to(nodes[b]["pos"]))
	check("węzły się nie nakładają", closest > 0.75, str(closest))
	var keystones := 0
	for id: String in nodes:
		if nodes[id]["kind"] == "keystone":
			keystones += 1
		if _T.node_name(id) == "" or (id != _T.START and _T.node_lines(id).is_empty()):
			check("węzeł %s ma nazwę i opis" % id, false)
	check("węzeł kluczowy dla każdej mechaniki", keystones == _D.MECHANICS.size(), str(keystones))
	check("nazwa ścieżki z mechaniką", _T.node_name("uroczysko_a1") == "Uroczysko - częściej", _T.node_name("uroczysko_a1"))


func _check_rules() -> void:
	var chosen: Array = []
	check("korzeń obok Watry do wybrania", _T.can_allocate(chosen, "chests_root"))
	check("dalszy węzeł nie od razu", not _T.can_allocate(chosen, "chests_a1"))
	chosen = ["chests_root", "chests_a1", "chests_a2"]
	check("dalszy węzeł po ścieżce", _T.can_allocate(chosen, "chests_a3") and not _T.can_allocate(chosen, "chests_a2"))
	check("cofnięcie końca ścieżki", _T.can_refund(chosen, "chests_a2"))
	check("bez cofania węzła, od którego coś zależy", not _T.can_refund(chosen, "chests_root") and not _T.can_refund(chosen, "chests_a1"))
	check("koszt cofania rośnie z poziomem", _T.refund_cost(60) > _T.refund_cost(40) and _T.reset_cost(60, 10) < _T.refund_cost(60) * 10)


func _check_effects() -> void:
	var tree: Dictionary = _T.effects(["uroczysko_root", "uroczysko_a1", "uroczysko_a2", "uroczysko_a3", "uroczysko_a4",
			"uroczysko_a_end", "zertwa_root", "zertwa_b1", "zertwa_b2", "zertwa_b3", "zertwa_b4", "zertwa_b_end",
			"loot_root", "vault_root", "vault_a1", "general_root"])
	check("wagi się mnożą", is_equal_approx(tree["weight:uroczysko"], pow(_T.MECH_WEIGHT, 5)), str(tree["weight:uroczysko"]))
	check("moc się sumuje", is_equal_approx(tree["power:zertwa"], 4 * _T.MECH_POWER + _T.MECH_POWER_NOTABLE))
	var config: Dictionary = _D.config("catacombs", 5, [], 1, ["idol_zertwa_legendary"])
	config["tree"] = tree
	var bonus: Dictionary = _D.mechanic_bonus(config)
	check("Uroczysko wymuszone z drzewka", bonus["forced"].has("uroczysko") and bonus["forced"].has("zertwa"), str(bonus["forced"]))
	check("moc drzewka i bożka się dodaje", is_equal_approx(bonus["power"]["zertwa"],
			1.0 + 4 * _T.MECH_POWER + _T.MECH_POWER_NOTABLE + _I.MECHANIC_POWER - 1.0), str(bonus["power"]))
	check("szansa na drugą mechanikę", is_equal_approx(float(bonus["extra"][0]), 0.03))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var always := true
	for i in 200:
		if not _D.roll_mechanics(rng, bonus).has("uroczysko"):
			always = false
	check("wymuszona mechanika w każdym lochu", always)
	check("mnożnik łupu lochu", is_equal_approx(_D.mult(config, "loot"), 1.04) and is_equal_approx(_D.mult(config, "treasure"), 1.05))
	check("premia dodawana lochu", is_equal_approx(_D.added(config, "quality"), 0.03))
	check("bez drzewka bez zmian", is_equal_approx(_D.mult(_D.config("catacombs", 5, [], 1), "loot"), 1.0))
	var idols: Dictionary = _T.effects(["idols_root", "idols_a1", "idols_a2", "idols_a3", "idols_a4", "idols_a_end"])
	check("slot na bożka z drzewka", _T.idol_slots(idols) == 1 and _I.slot_count(1, _T.idol_slots(idols)) == 3)
	check("bożki częściej", _I.drop_chance(false, 1.0 + idols["idol_drop"]) > _I.drop_chance(false) * 1.4)
	var rare := [0, 0]
	for bonus_value: float in [0.0, 2.0]:
		rng.seed = 9
		for i in 3000:
			if _I.parse(_I.roll(rng, bonus_value))[1] != "common":
				rare[0 if bonus_value == 0.0 else 1] += 1
	check("rzadsze bożki z premią", rare[1] > rare[0] * 1.5, str(rare))
	var bless: Dictionary = _T.effects(["bless_root", "bless_a1", "bless_a2"])
	check("Błogosławieństwo: premia za węzły obszaru", is_equal_approx(_T.blessing_bonus(bless, 10), 0.02 + 0.005 * 10))


func _check_boons() -> void:
	var boons = load("res://scripts/boons.gd").new()
	for i in 5:
		boons.nawia_cleared.append(i)
	check("5 punktów w każdej zakładce", boons.tree_free(0) == 5 and boons.tree_free(2) == 5)
	check("wybór obok Watry", boons.tree_allocate("crystal_root") and boons.tree_allocate("crystal_b1"))
	check("bez wyboru za daleko", not boons.tree_allocate("crystal_b3"))
	boons.set_tree_tab(1)
	check("druga zakładka ma pełną pulę", boons.tree_free() == 5 and boons.tree_nodes().is_empty())
	for id in ["idols_root", "idols_a1", "idols_a2", "idols_a3", "idols_a4"]:
		boons.tree_allocate(id)
	check("brak punktów blokuje wybór", boons.tree_free() == 0 and not boons.tree_allocate("loot_root"))
	boons.watra_tab_names[1] = "Bożki"
	var data: Dictionary = boons.get_save_data()
	var copy = load("res://scripts/boons.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(data)))
	check("zapis zakładek", copy.watra_tab == 1 and copy.tree_nodes(0) == ["crystal_root", "crystal_b1"]
			and copy.tree_nodes(1).size() == 5 and copy.tree_tab_name(1) == "Bożki" and copy.tree_tab_name(2) == "Zakładka 3")
	check("premie z zapisu (działająca zakładka)", is_equal_approx(float(_T.effects_from_save(data).get("idol_drop", 0.0)), 0.5))
	data["watra_tabs"][0] = ["crystal_b1", "nieznany"]
	copy.load_save_data(data)
	check("odcięte i nieznane węzły wracają jako punkty", copy.tree_nodes(0).is_empty())
	boons.free()
	copy.free()


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_check_layout()
		_check_rules()
		_check_effects()
		_check_boons()
	if _frame == 6:
		var hud = _world.hud
		var player = _world.player
		var boons = player.boons
		for i in 10:
			boons.nawia_cleared.append(i)
		var window = hud.watra_tree_window
		check("okno drzewka w HUD", window != null)
		window.open()
		check("okno otwarte, 10 wolnych punktów", window.visible and boons.tree_free() == 10)
		window.select("idols_root")
		window._on_allocate()
		for id in ["idols_a1", "idols_a2", "idols_a3", "idols_a4", "idols_a_end"]:
			window.select(id)
			window._on_allocate()
		check("wybrano ścieżkę bożków", boons.tree_nodes().size() == 6 and boons.tree_free() == 4)
		var visible_pickers: int = hud.dungeon_window._idol_pickers.filter(func(p: Control) -> bool: return p.visible).size()
		hud.dungeon_window.open()
		var after: int = hud.dungeon_window._idol_pickers.filter(func(p: Control) -> bool: return p.visible).size()
		check("dodatkowy slot na bożka w oknie lochów", after == _I.SLOT_LEVELS.size() + 1, "%d -> %d" % [visible_pickers, after])
		player.stats.add_gold(-player.stats.gold)
		window.select("idols_a_end")
		window._refresh()
		check("bez złota nie da się cofnąć", window._refund.disabled)
		player.stats.add_gold(100000)
		window._on_refund()
		check("cofnięcie za złoto", not boons.tree_nodes().has("idols_a_end")
				and player.stats.gold == 100000 - _T.refund_cost(player.stats.level))
		window.select("idols_root")
		window._on_refund()
		check("korzenia z wybraną ścieżką nie cofa", boons.tree_nodes().has("idols_root"))
		window._on_tab(2)
		check("zmiana zakładki poza lochem", boons.watra_tab == 2 and boons.tree_free() == 10)
		window._on_tab(0)
		var gold: int = player.stats.gold
		window._on_reset()
		check("czyszczenie prosi o potwierdzenie", boons.tree_nodes().size() == 5)
		window._on_reset()
		check("czyszczenie zakładki za złoto", boons.tree_nodes().is_empty() and player.stats.gold == gold - _T.reset_cost(player.stats.level, 5))
		window.visible = false
	if _frame == 8:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
