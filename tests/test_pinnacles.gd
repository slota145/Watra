extends SceneTree
## Bossowie szczytowi Mapy Nawii (scripts/pinnacles.gd, scripts/pinnacle_boss.gd): dane bogów, przedmioty, legendy
## i pasy (Pas Wiecznych Ziół, Pas Łowcy Dusz w Boons), punkty Watry za pierwsze zwycięstwo i zapis; potem arena
## Welesa: dwie komnaty, sam bóg na swoim poziomie, wszyscy trzej bogowie walczą chwilę z graczem (bez błędów),
## pokonany bóg daje serce, skarbiec i punkty Watry; na koniec kolumna bogów w oknie Mapy Nawii (wyzwanie, wymiana serc).

var _world: Node
var _frame := 0
var _fails := 0
var _P
var _I
var _Loot
var _E
var _N
var _L
var _health_start := 0
## Ataki wykonane przez bogów w czasie próby ("bóg:atak").
var _attacks := {}


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	var config := {"climate": "roots", "tier": 17, "mods": [], "seed": 777, "idols": [], "pinnacle": "weles",
			"mechanics": [], "altar": false, "tree": {}}
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_data() -> void:
	check("3 bogów", _P.ORDER.size() == 3)
	for god: String in _P.ORDER:
		check("scena %s" % god, load("res://scenes/pinnacle_%s.tscn" % god) != null)
		check("fragment i serce %s" % god, _I.get_data(_P.fragment(god)).has("icon") and _I.get_data(_P.heart(god)).has("icon"))
		for id: String in _P.GODS[god]["legends"] + ([_P.GODS[god]["belt"]] if _P.GODS[god].has("belt") else []):
			var data: Dictionary = _I.get_data(_Loot.legendary_at_level(id, 92))
			check("legenda %s" % id, data.get("rarity", "") == "legendary" and data.has("effect")
					and ResourceLoader.exists("res://assets/items/legends/%s.png" % id))
	for area: String in _N.AREAS:
		check("obszar %s ma boga" % area, _P.god_of_area(area) != "")
	check("szansa na fragment rośnie ze stopniem", _P.fragment_chance(17) > _P.fragment_chance(8) and _P.fragment_chance(8) > 0.0)
	check("pasy bez esencji", not _E.is_legend(_Loot.legendary_at_level("legend_weles_belt", 92))
			and _E.is_legend(_Loot.legendary_at_level("legend_weles_staff", 92)))


func _check_boons() -> void:
	var boons = load("res://scripts/boons.gd").new()
	var base: int = boons.watra_points()
	check("pierwsze zwycięstwo", boons.defeat_pinnacle("weles") and not boons.defeat_pinnacle("weles"))
	check("punkty Watry za boga", boons.watra_points() == base + _P.FIRST_KILL_POINTS)
	# Pas Wiecznych Ziół
	boons.eternal_herbs = 4
	for id in ["elixir_wort", "elixir_chamomile", "elixir_calamus", "elixir_arnica", "elixir_fern"]:
		boons.grant(id)
	check("wieczne zioła: 4 naraz, najstarsza wypada", boons.eternal.size() == 4 and not boons.eternal.has("elixir_wort")
			and not boons.active.has("elixir"))
	check("wieczne zioła działają", is_equal_approx(boons.bonus("damage_percent"), 0.15) and is_equal_approx(boons.bonus("move_speed"), 0.08))
	boons._process(10000.0)
	check("wieczne zioła nie wygasają", boons.eternal.size() == 4)
	boons.eternal_herbs = 0
	check("bez pasa nie działają", is_zero_approx(boons.bonus("damage_percent")))
	boons.grant("elixir_arnica")
	check("bez pasa zwykła mikstura", boons.active.has("elixir"))
	# Pas Łowcy Dusz
	boons.add_soul("commander")
	check("dusza elity daje cechę", is_equal_approx(boons.bonus("damage_percent"), 0.15 + 0.4))
	boons._process(boons.SOUL_TIME + 1.0)
	check("dusza wygasa", boons.souls.is_empty())
	var copy = load("res://scripts/boons.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(boons.get_save_data())))
	check("zapis zwycięstw i ziół", int(copy.pinnacle_kills.get("weles", 0)) == 2 and copy.eternal.size() == 4)
	boons.free()
	copy.free()


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_P = load("res://scripts/pinnacles.gd")
		_I = load("res://scripts/items.gd")
		_Loot = load("res://scripts/loot.gd")
		_E = load("res://scripts/essences.gd")
		_N = load("res://scripts/nawia_map.gd")
		_L = load("res://scripts/levels.gd")
		_check_data()
		_check_boons()
	if _frame == 6:
		var dungeon = _world._dungeon
		check("arena: dwie komnaty", dungeon != null and dungeon.rooms.size() == 2 and dungeon.pinnacle == "weles")
		var enemies := root.get_tree().get_nodes_in_group("enemies")
		var boss = dungeon._boss
		check("na arenie tylko bóg", enemies.size() == 1 and boss.is_in_group("pinnacle_bosses"), str(enemies.size()))
		check("bóg na swoim poziomie", boss.level == 92 and boss.boss_name == _P.god_name("weles"), str(boss.level))
		check("bóg ma ogromne zdrowie", boss.max_health > _L.health(92) * _L.BOSS_HEALTH.y * 3.0, str(boss.max_health))
		# pozostali bogowie obok - wszyscy walczą chwilę z graczem
		for god in ["marzanna", "czarnobog"]:
			var other = load("res://scenes/pinnacle_%s.tscn" % god).instantiate()
			other.level = 90
			other.position = boss.position + Vector2(140 if god == "marzanna" else -140, 0)
			boss.get_parent().add_child(other)
		var player = _world.player
		player.global_position = boss.global_position + Vector2(0, 90)
		player.stats.level = 90
		_health_start = player.health
		for other in root.get_tree().get_nodes_in_group("pinnacle_bosses"):
			other._special_cooldown = 0.0
			other.aggro()
	if _frame > 6 and _frame < 1200:
		# gracz nie ginie w czasie próby - bogowie mają czas wykonać kilka ataków
		_world.player.health = _world.player.stats.max_health()
		# nietykalny, żeby bogowie zdążyli wykonać wiele ataków (zapowiedzi i trafienia i tak są liczone)
		_world.player._invulnerable_timer = 1.0
		# gracz co chwilę staje gdzie indziej - bogowie dobierają ataki do odległości
		if _frame % 90 == 0:
			var boss = _world._dungeon._boss
			_world.player.global_position = boss.global_position + Vector2.from_angle(_frame * 0.7) * (60.0 + (_frame % 270))
		for other in root.get_tree().get_nodes_in_group("pinnacle_bosses"):
			if other._attack != "":
				_attacks[other.kind + ":" + other._attack] = true
	if _frame == 1200:
		var gods := {}
		for key: String in _attacks:
			gods[key.split(":")[0]] = true
		check("każdy bóg atakuje", gods.size() == 3, str(_attacks.keys()))
		check("różne ataki", _attacks.size() >= 4, str(_attacks.size()))
		var boss = _world._dungeon._boss
		var boons = _world.player.boons
		var points: int = boons.watra_points()
		boss.take_damage(boss.health + 10, boss.global_position)
		check("pokonany bóg: zwycięstwo i punkty Watry", int(boons.pinnacle_kills.get("weles", 0)) == 1
				and boons.watra_points() == points + _P.FIRST_KILL_POINTS)
	if _frame == 1220:
		var hearts := 0
		var items := 0
		for pickup in root.get_tree().get_nodes_in_group("pickups"):
			if pickup.item_id == _P.heart("weles"):
				hearts += 1
			items += 1
		check("serce boga i skarbiec", hearts == 1 and items > 15, "%d serc, %d łupów" % [hearts, items])
		var hud = _world.hud
		var player = _world.player
		player.inventory.add_item(_P.fragment("czarnobog"), _P.FRAGMENTS - 1)
		player.inventory.add_item(_P.heart("czarnobog"), _P.BELT_COST)
		hud.nawia_window.open()
		var entry: Dictionary = hud.nawia_window._gods["czarnobog"]
		check("za mało fragmentów", entry["fight"].disabled)
		player.inventory.add_item(_P.fragment("czarnobog"), 1)
		hud.nawia_window._refresh_gods()
		check("4 fragmenty otwierają arenę", not entry["fight"].disabled)
		hud.nawia_window._exchange("czarnobog", "belt")
		check("10 serc - pas", player.inventory.count_of(_P.heart("czarnobog")) == 0
				and player.inventory.slots.any(func(slot: Dictionary) -> bool:
					return not slot.is_empty() and _I.get_data(slot["id"]).get("effect", {}).get("kind", "") == "soul_hunter"))
		check("wymiana bez serc zablokowana", entry["legend"].disabled and entry["belt"].disabled)
	if _frame == 1224:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
