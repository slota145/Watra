extends SceneTree
## Drzewko Watry (scripts/watra_tree.gd): układ (12 tematów po 4 skupiska porozrzucane po drzewku, ścieżki neutralnych
## węzłów, wszystkie węzły osiągalne, węzły się nie nakładają),
## wybieranie tylko obok wybranych i za wolne punkty, cofanie tylko węzłów z końca ścieżki, 3 zakładki z osobnymi pulami,
## premie (wagi, wymuszone mechaniki, „tylko ta mechanika”, podwójne mechaniki, moc razem z bożkami, mnożniki lochów,
## bożki, Błogosławieństwo), zapis zakładek i zwrot punktów ze starego układu;
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
	var themes: int = _T.SECTORS.size()
	var kinds := {}
	for id: String in nodes:
		kinds[nodes[id]["kind"]] = int(kinds.get(nodes[id]["kind"], 0)) + 1
		if _T.node_name(id) == "" or (id != _T.START and _T.node_lines(id).is_empty()):
			check("węzeł %s ma nazwę i opis" % id, false)
	check("4 skupiska na temat (6 małych i znaczący), kluczowy na temat",
			kinds["notable"] == 4 * themes and kinds["keystone"] == themes, str(kinds))
	check("ponad 450 węzłów - ponad 4 razy więcej niż punktów z całej mapy", nodes.size() > 450
			and nodes.size() - 1 > 4 * load("res://scripts/nawia_map.gd").node_count(), str(nodes.size()))
	var all: Array = nodes.keys()
	all.erase(_T.START)
	check("wszystkie węzły połączone z Watrą", _T.connected(all).size() == all.size())
	var closest := INF
	for a: String in nodes:
		for b: String in nodes:
			if a < b:
				closest = minf(closest, (nodes[a]["pos"] as Vector2).distance_to(nodes[b]["pos"]))
	check("węzły się nie nakładają", closest > 0.7, str(closest))
	check("nazwa węzła z mechaniką", _T.node_name("uroczysko_a_1") == "Uroczysko - częściej", _T.node_name("uroczysko_a_1"))
	check("węzeł kluczowy za skupiskiem d", nodes["zertwa_k"]["links"].has("zertwa_d_1"))
	# skupiska jednego tematu porozrzucane: każde w innej ćwiartce drzewka
	for theme: String in _T.SECTORS:
		var angles: Array = []
		for group: String in _T.CLUSTER_GROUPS:
			angles.append((nodes["%s_%s_n" % [theme, group]]["pos"] as Vector2).angle())
		var spread := INF
		for i in angles.size():
			for j in range(i + 1, angles.size()):
				spread = minf(spread, absf(angle_difference(angles[i], angles[j])))
		if spread < deg_to_rad(60.0):
			check("%s: skupiska porozrzucane" % theme, false, str(rad_to_deg(spread)))
	# droga do dalekiego skupiska prowadzi przez cudze skupiska
	var route := _route("uroczysko_d_n")
	var foreign := route.filter(func(id: String) -> bool: return nodes[id]["branch"] != "uroczysko" and nodes[id]["branch"] != _T.NEUTRAL)
	check("droga do skupiska przez cudze skupiska", not foreign.is_empty() and route.size() > 12, "%d węzłów" % route.size())
	for mechanic: String in _D.MECHANICS:
		var keystone: Dictionary = nodes[mechanic + "_k"]["effects"]
		check("%s: kluczowy wymusza i wyłącza inne" % mechanic, keystone.has("forced:" + mechanic) and keystone.has("only:" + mechanic))
		var changes := 0
		for group in ["b", "c", "d"]:
			for key: String in nodes["%s_%s_n" % [mechanic, group]]["effects"]:
				if not key.contains(":"):
					changes += 1
					break
		check("%s: 3 węzły zmieniające mechanikę" % mechanic, changes == 3, str(changes))


func _check_rules() -> void:
	var chosen: Array = []
	check("Iskra przy Watrze do wybrania", _T.can_allocate(chosen, "inner_0") and _T.can_allocate(chosen, "inner_6"))
	var route := _route("chests_a_1")
	check("dalszy węzeł nie od razu", not _T.can_allocate(chosen, route[1]))
	chosen = route.slice(0, 2)
	check("dalszy węzeł po ścieżce", _T.can_allocate(chosen, route[2]) and not _T.can_allocate(chosen, route[1]))
	check("cofnięcie końca ścieżki", _T.can_refund(chosen, route[1]))
	check("bez cofania węzła, od którego coś zależy", not _T.can_refund(chosen, route[0]))
	# kółko skupiska: dwie drogi, więc węzeł w kółku da się cofnąć, gdy reszta kółka trzyma się innej strony
	chosen = route.duplicate()
	for k in 6:
		if not chosen.has("chests_a_%d" % (k + 1)):
			chosen.append("chests_a_%d" % (k + 1))
	var ring := chosen.filter(func(id: String) -> bool: return id.begins_with("chests_a_") and id != route.back())
	check("kółko skupiska: cofnięcie przy drugiej drodze", ring.any(func(id: String) -> bool: return _T.can_refund(chosen, id)))
	check("koszt cofania rośnie z poziomem", _T.refund_cost(60) > _T.refund_cost(40) and _T.reset_cost(60, 10) < _T.refund_cost(60) * 10)


## Najkrótsza droga od Watry do węzła (bez startu) - węzły w kolejności wybierania.
func _route(target: String) -> Array:
	var nodes: Dictionary = _T.nodes()
	var before := {_T.START: ""}
	var queue: Array = [_T.START]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == target:
			break
		for other: String in nodes[id]["links"]:
			if not before.has(other):
				before[other] = id
				queue.append(other)
	var route: Array = []
	var at := target
	while at != _T.START:
		route.push_front(at)
		at = before[at]
	return route


## Całe skupisko (6 małych i znaczący).
func _cluster(id: String) -> Array:
	var result: Array = []
	for k in 6:
		result.append("%s_%d" % [id, k + 1])
	result.append(id + "_n")
	return result


func _check_effects() -> void:
	var tree: Dictionary = _T.effects(_cluster("uroczysko_a") + _cluster("uroczysko_c") + ["uroczysko_k"]
			+ _cluster("zertwa_b") + ["inner_4", "loot_d_1"])
	check("wagi się mnożą", is_equal_approx(tree["weight:uroczysko"], pow(_T.MECH_WEIGHT_A, 6)), str(tree["weight:uroczysko"]))
	check("moc się sumuje", is_equal_approx(tree["power:zertwa"], 7 * _T.MECH_POWER), str(tree["power:zertwa"]))
	check("węzły zmieniające mechanikę", _T.has_flag(tree, "uro_hold") and is_equal_approx(_T.value(tree, "zer_offer"), 1.0)
			and is_equal_approx(tree["dup:uroczysko"], _T.MECH_DUP))
	var config: Dictionary = _D.config("catacombs", 5, [], 1, ["idol_zertwa_legendary"])
	config["tree"] = tree
	var bonus: Dictionary = _D.mechanic_bonus(config)
	check("Uroczysko wymuszone, bez innych", bonus["forced"].has("uroczysko") and bonus["only"], str(bonus["forced"]))
	check("moc drzewka i bożka się dodaje", is_equal_approx(bonus["power"]["zertwa"],
			1.0 + 7 * _T.MECH_POWER + _I.MECHANIC_POWER - 1.0), str(bonus["power"]))
	check("bez Splotu bez szansy na drugą mechanikę z drzewka", is_equal_approx(float(bonus["extra"][0]), 0.0))
	check("podwójna mechanika w premiach", is_equal_approx(float(bonus["dup"]["uroczysko"]), _T.MECH_DUP))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var only := true
	for i in 200:
		if _D.roll_mechanics(rng, bonus) != bonus["forced"]:
			only = false
	check("węzeł kluczowy: tylko wymuszone mechaniki (Uroczysko i Żertwa z bożka)", only and bonus["forced"].size() == 2, str(bonus["forced"]))
	# bez węzła kluczowego: zwykłe losowanie, czwarta mechanika z Poczwórnego Węzła
	var splot: Dictionary = _T.effects(_cluster("general_a") + ["general_k"])
	var counts := [0, 0, 0, 0, 0]
	var split_bonus: Dictionary = _D.mechanic_bonus({"tree": splot})
	for i in 400:
		counts[_D.roll_mechanics(rng, split_bonus).size()] += 1
	check("Wielki Splot: zawsze co najmniej 2 mechaniki", counts[1] == 0 and counts[2] > 0, str(counts))
	check("Wielki Splot: słabsze mechaniki", float(split_bonus["power"]["chests"]) < 1.0, str(split_bonus["power"]))
	var four: Dictionary = _D.mechanic_bonus({"tree": {"extra2": 1.0, "extra3": 1.0, "extra4": 1.0}})
	check("czwarta mechanika", _D.roll_mechanics(rng, four).size() == 4)
	check("mnożnik łupu lochu", is_equal_approx(_D.mult(config, "loot"), 1.02) and is_equal_approx(_D.mult(config, "treasure"), 1.0),
			str(_D.mult(config, "loot")))
	check("premia dodawana lochu", is_equal_approx(_D.added(config, "quality"), 0.03))
	check("więcej potworów z Iskry", is_equal_approx(_D.mult({"tree": _T.effects(["inner_1"])}, "count"), 1.02))
	check("bez drzewka bez zmian", is_equal_approx(_D.mult(_D.config("catacombs", 5, [], 1), "loot"), 1.0))
	var idols: Dictionary = _T.effects(_cluster("idols_a"))
	check("slot na bożka z drzewka", _T.idol_slots(idols) == 1 and _I.slot_count(1, _T.idol_slots(idols)) == 3)
	check("bożki częściej", _I.drop_chance(false, 1.0 + idols["idol_drop"]) > _I.drop_chance(false) * 1.4)
	var rare := [0, 0]
	for bonus_value: float in [0.0, 2.0]:
		rng.seed = 9
		for i in 3000:
			if _I.parse(_I.roll(rng, bonus_value))[1] != "common":
				rare[0 if bonus_value == 0.0 else 1] += 1
	check("rzadsze bożki z premią", rare[1] > rare[0] * 1.5, str(rare))
	var bless: Dictionary = _T.effects(["bless_a_1", "bless_a_2", "bless_a_n"])
	check("Błogosławieństwo: premia za węzły obszaru", is_equal_approx(_T.blessing_bonus(bless, 10), 0.06 + 0.005 * 10),
			str(_T.blessing_bonus(bless, 10)))
	check("cena węzła kluczowego w opisie", _T.node_lines("loot_k").any(func(line: String) -> bool: return line.begins_with("-20%")),
			str(_T.node_lines("loot_k")))


func _check_boons() -> void:
	var boons = load("res://scripts/boons.gd").new()
	for i in 5:
		boons.nawia_cleared.append(i)
	check("5 punktów w każdej zakładce", boons.tree_free(0) == 5 and boons.tree_free(2) == 5)
	var near := _route("crystal_a_n")
	check("wybór obok Watry", boons.tree_allocate(near[0]) and boons.tree_allocate(near[1]))
	check("bez wyboru za daleko", not boons.tree_allocate(near[3]))
	boons.set_tree_tab(1)
	check("druga zakładka ma pełną pulę", boons.tree_free() == 5 and boons.tree_nodes().is_empty())
	for id in _route("idols_a_n").slice(0, 5):
		boons.tree_allocate(id)
	check("brak punktów blokuje wybór", boons.tree_free() == 0 and not boons.tree_allocate("inner_0"))
	boons.watra_tab_names[1] = "Bożki"
	var data: Dictionary = boons.get_save_data()
	var copy = load("res://scripts/boons.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(data)))
	check("zapis zakładek", copy.watra_tab == 1 and copy.tree_nodes(0) == near.slice(0, 2)
			and copy.tree_nodes(1).size() == 5 and copy.tree_tab_name(1) == "Bożki" and copy.tree_tab_name(2) == "Zakładka 3"
			and not copy.tree_refunded)
	check("premie z zapisu (działająca zakładka)", _T.effects_from_save(data) == _T.effects(copy.tree_nodes(1))
			and not _T.effects_from_save(data).is_empty())
	data["watra_tabs"][0] = [near[1], "nieznany"]
	copy.load_save_data(data)
	check("odcięte i nieznane węzły wracają jako punkty", copy.tree_nodes(0).is_empty())
	# stary układ drzewka (bez "watra_tree"): wszystko wraca do rozdania, okno o tym mówi
	var old := {"nawia": [1, 2, 3], "watra_tabs": [["chests_root", "chests_a1"], [], ["idols_root"]], "watra_tab": 2}
	copy.load_save_data(old)
	check("zwrot punktów ze starego drzewka", copy.tree_refunded and copy.tree_nodes(0).is_empty() and copy.tree_nodes(2).is_empty()
			and copy.tree_free(0) == 3 and copy.watra_tab == 2)
	check("stary zapis bez premii drzewka", _T.effects_from_save(old).is_empty())
	copy.load_save_data({})
	check("nowa gra bez komunikatu o zwrocie", not copy.tree_refunded)
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
		var route := _route("idols_a_n")
		for id in route:
			window.select(id)
			window._on_allocate()
		check("wybrano drogę do Nowego Ołtarza", boons.tree_nodes().size() == route.size() and boons.tree_free() == 10 - route.size(),
				str(route))
		var visible_pickers: int = hud.dungeon_window._idol_pickers.filter(func(p: Control) -> bool: return p.visible).size()
		hud.dungeon_window.open()
		var after: int = hud.dungeon_window._idol_pickers.filter(func(p: Control) -> bool: return p.visible).size()
		check("dodatkowy slot na bożka w oknie lochów", after == _I.SLOT_LEVELS.size() + 1, "%d -> %d" % [visible_pickers, after])
		player.stats.add_gold(-player.stats.gold)
		window.select("idols_a_n")
		window._refresh()
		check("bez złota nie da się cofnąć", window._refund.disabled)
		player.stats.add_gold(100000)
		window._on_refund()
		check("cofnięcie za złoto", not boons.tree_nodes().has("idols_a_n")
				and player.stats.gold == 100000 - _T.refund_cost(player.stats.level))
		window.select(route[0])
		window._on_refund()
		check("początku drogi nie cofa", boons.tree_nodes().has(route[0]))
		window._on_tab(2)
		check("zmiana zakładki poza lochem", boons.watra_tab == 2 and boons.tree_free() == 10)
		window._on_tab(0)
		var gold: int = player.stats.gold
		window._on_reset()
		var spent: int = boons.tree_nodes().size()
		check("czyszczenie prosi o potwierdzenie", spent == route.size() - 1)
		window._on_reset()
		check("czyszczenie zakładki za złoto", boons.tree_nodes().is_empty() and player.stats.gold == gold - _T.reset_cost(player.stats.level, spent))
		window.visible = false
	if _frame == 8:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
