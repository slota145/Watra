extends SceneTree
## Lochy w płomieniach Watry: każdy klimat (kafelki dla wszystkich komórek, komnaty połączone, gracz na podłodze,
## potwory klimatu na poziomie stopnia, strażnik, co najmniej jedna mechanika), mechaniki (losowanie, skrzynie,
## kapliczki, elity, Uroczysko), modyfikatory, otwarcie skarbca po pokonaniu strażnika,
## zapis gry z lochu (wraca do Ostoi), żar do wydania, a na koniec pełna droga: okno lochów przy Watrze ->
## wejście w płomienie (żar wydany, modyfikatory działają) -> płomienie w lochu -> powrót przed Watrę.

const CLIMATES := ["catacombs", "mine", "flooded", "roots", "vineyard", "stronghold"]

var _world: Node
var _frame := 0
var _fails := 0
var _index := 0
var _Dungeons
## Etap pełnej drogi: 0 - jeszcze nie, 1 - las z oknem, 2 - w lochu, 3 - z powrotem w lesie.
var _flow := 0
var _flow_frame := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_Dungeons = load("res://scripts/dungeons.gd")
	_load_next.call_deferred()


func _load_next() -> void:
	var mods: Array = ["horde", "fury"] if _index == 0 else []
	var config: Dictionary = _Dungeons.config(CLIMATES[_index], 2 + _index, mods, 1000 + _index * 77)
	if _index == 0:
		config["mechanics"] = ["chests", "shrine", "crystal", "elites", "uroczysko"]
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	_frame = 0


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _flow > 0:
		_process_flow()
		return false
	if _world == null:
		return false
	_frame += 1
	if _frame == 5:
		_check_dungeon()
	if _frame == 6 and _index == 0:
		_check_mechanics()
	if _frame == 8 and _index == 0:
		_check_vault_and_save()
	if _frame == 20:
		_world.queue_free()
		_world = null
		_index += 1
		if _index >= CLIMATES.size():
			_check_window()
			_start_flow.call_deferred()
		else:
			_load_next.call_deferred()
	return false


func _check_dungeon() -> void:
	var climate: String = CLIMATES[_index]
	var d = _world._dungeon
	check("%s: kraina lochu" % climate, _world.zone == "dungeon" and d != null)
	var layer: TileMapLayer = _world.get_node("DungeonTiles")
	if d.outdoor:
		# loch na zewnątrz: kafelki tylko przy klifach, granicą są też drzewa i stawy, pod spodem podłoże z teksturami
		if d.climate["terrain"].has("palisade_below"):
			# granicą palisada (pale wzdłuż wygładzonych linii z kolizją), drzewa i stawy - bez klifów
			check("%s: palisada, drzewa i woda" % climate, d.palisades.size() > 50 and d.palisade_lines.size() > 0
					and _world.get_node_or_null("Palisade") != null and d.waters.size() > 0 and _world._soft_corners.size() > 0,
					"%d za palisadą, %d linii, %d wody" % [d.palisades.size(), d.palisade_lines.size(), d.waters.size()])
		else:
			check("%s: klify, drzewa i woda" % climate, layer.get_used_cells().size() > 0 and d.cliffs.size() > 0 and d.waters.size() > 0
					and _world._soft_corners.size() > 0, "%d klifów, %d wody" % [d.cliffs.size(), d.waters.size()])
		check("%s: kręte ścieżki z ubitej ziemi" % climate, d._trails.size() >= d.rooms.size() - 1 and d.path_tiles.size() > 100)
	else:
		check("%s: kafelek w każdej komórce" % climate, layer.get_used_cells().size() == (d.GRID.x - 1) * (d.GRID.y - 1))
	var distance: Dictionary = d._distances(d.start_room.position + d.start_room.size / 2)
	var connected := true
	for room: Rect2i in d.rooms:
		if not distance.has(room.position + room.size / 2):
			connected = false
	check("%s: wszystkie komnaty połączone" % climate, connected, "%d komnat" % d.rooms.size())
	var player = _world.player
	var vertex := Vector2i((player.global_position / d.CELL).round())
	check("%s: gracz na podłodze przy wejściu" % climate, d._label(vertex) == "l" and d.start_room.grow(1).has_point(vertex))
	# droga przez loch: z komnaty strażnika krok po kroku coraz bliżej gracza
	d._update_flow(vertex)
	var from: Vector2i = d.boss_room.position + d.boss_room.size / 2
	var at: Vector2 = Vector2(from) * d.CELL
	var closer: bool = d._flow.has(from)
	for i in 400:
		var here: int = d._flow.get(Vector2i((at / d.CELL).round()), -1)
		if here <= 1:
			break
		var step: Vector2 = d.steer(at)
		at += step * 16.0
		closer = closer and step != Vector2.ZERO
	check("%s: droga do gracza omija ściany" % climate, closer and d._flow.get(Vector2i((at / d.CELL).round()), 99) <= 1)
	var kinds := {}
	var levels := {}
	var count := 0
	for enemy in _world.get_tree().get_nodes_in_group("enemies"):
		count += 1
		kinds[enemy.scene_file_path.get_file().get_basename()] = true
		levels[enemy.level] = true
	var tier_level: int = _Dungeons.tier_level(2 + _index)
	check("%s: dużo potworów" % climate, count >= 60, "%d" % count)
	check("%s: poziomy wg stopnia" % climate, levels.has(tier_level) and levels.keys().all(func(l: int) -> bool: return l >= tier_level and l <= tier_level + 2), str(levels.keys()))
	var boss = d._boss
	check("%s: strażnik" % climate, boss != null and boss.is_in_group("bosses") and boss.level == tier_level + 2,
			boss.scene_file_path.get_file() if boss != null else "brak")
	check("%s: potwory klimatu" % climate, kinds.size() >= 3, str(kinds.keys()))
	check("%s: co najmniej jedna mechanika" % climate, d.mechanics.size() >= 1 and (d.mechanics.size() <= 3 or d.config.has("mechanics")), str(d.mechanics))
	if _index == 0:
		check("modyfikatory: wściekłość", is_equal_approx(_mods()["health"], 1.25) and is_equal_approx(_mods()["xp"], 1.5))
	else:
		check("%s: bez modyfikatorów" % climate, is_equal_approx(_mods()["health"], 1.0))


## Mechaniki lochu: losowanie (zawsze co najmniej jedna, proste częściej), skrzynie (zwykła, strzeżona) i kapliczka.
func _check_mechanics() -> void:
	var d = _world._dungeon
	check("mechaniki z ustawień wyprawy", d.mechanics.size() == 5 and d.uroczyska.size() == 1 and d.crystal != null and d.chests.size() >= 2 and d.shrines.size() >= 1,
			"%s, %d skrzyń, %d kapliczek" % [d.mechanics, d.chests.size(), d.shrines.size()])
	var in_rooms := true
	for node: Node2D in d.chests + d.shrines:
		var vertex := Vector2i((node.position / d.CELL).round())
		if d._blocked(node.position, 4.0) or d.boss_room.has_point(vertex) or d.start_room.has_point(vertex):
			in_rooms = false
	check("skrzynie i kapliczki w wolnych miejscach zwykłych komnat", in_rooms)
	# losowanie
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var counts := {}
	var sizes := 0
	var never_empty := true
	for i in 3000:
		var rolled: Array[String] = _Dungeons.roll_mechanics(rng)
		never_empty = never_empty and rolled.size() >= 1
		sizes += rolled.size()
		for id in rolled:
			counts[id] = counts.get(id, 0) + 1
	var average := sizes / 3000.0
	check("losowanie: zawsze mechanika, czasem druga i trzecia", never_empty and average > 1.15 and average < 1.5, "średnio %.2f" % average)
	check("losowanie: proste częściej niż duże", counts.get("chests", 0) > counts.get("shrine", 0) and counts.get("shrine", 0) > counts.get("crystal", 0),
			str(counts))
	var crystal: float = _Dungeons.mechanic_chance("crystal")
	check("Kryształ Watry mniej więcej w co czwartym lochu", crystal > 0.18 and crystal < 0.35, "%.2f" % crystal)
	var forced: Array[String] = _Dungeons.roll_mechanics(rng, {"forced": ["crystal"], "weights": {"chests": 0.0, "shrine": 0.0}})
	check("premie z drzewka Watry: wymuszona mechanika i wagi", forced[0] == "crystal" and not forced.has("chests"), str(forced))
	# zawartość każdego rodzaju skrzyni
	var Chest = load("res://scripts/dungeon_chest.gd")
	var all_filled := true
	for kind in _Dungeons.CHEST_KINDS:
		all_filled = all_filled and not Chest.roll_contents(kind, [], d.level).is_empty()
	check("każdy rodzaj skrzyni ma łup", all_filled)
	var rich := 0
	var plain := 0
	for i in 40:
		rich += Chest.roll_contents("common", ["rich"], d.level).size()
		plain += Chest.roll_contents("common", [], d.level).size()
	check("obfita skrzynia ma więcej łupu", rich > plain, "%d > %d" % [rich, plain])
	# zwykła skrzynia: otwiera się od razu
	var chest = d.chests[0]
	chest.traits.assign([])
	var before := _pickups()
	chest.harvest(chest.global_position)
	check("skrzynia wysypuje łup", chest.state == "open" and _pickups() > before and not chest.can_harvest(), "%d łupów" % (_pickups() - before))
	# strzeżona: najpierw strażnicy, po ich pokonaniu łup
	var guarded = d.chests[1]
	guarded.traits.assign(["guarded"])
	var enemies := _world.get_tree().get_nodes_in_group("enemies").size()
	guarded.harvest(guarded.global_position)
	check("strzeżona skrzynia wypuszcza strażników", guarded.state == "guarded" and guarded._guards.size() >= 5
			and _world.get_tree().get_nodes_in_group("enemies").size() > enemies)
	for goblin in guarded._guards:
		goblin.take_damage(999999, goblin.global_position)
	before = _pickups()
	guarded._process(0.1)
	check("po strażnikach skrzynia się otwiera", guarded.state == "open" and _pickups() > before)
	# kapliczka: dar na 60 s
	var shrine = d.shrines[0]
	shrine.gift = "shrine_fortune"
	var player = _world.player
	shrine.harvest(shrine.global_position)
	check("kapliczka daje dar", player.boons.has_group("shrine") and is_equal_approx(player.stats.item_find_multiplier(), 2.0)
			and not shrine.can_harvest(), str(player.boons.active))
	var icons: Array = load("res://scripts/status_effects.gd").list(player).filter(func(e: Dictionary) -> bool: return e["left"] > 0.0 and e["total"] == 60.0)
	check("ikona daru kapliczki pod paskami", icons.size() == 1)
	_check_uroczysko(d)
	_check_elites(d)


## Uroczysko: dotknięcie otwiera krąg, upiory rodzą się w kręgu i nie wychodzą poza niego, zabójstwa poszerzają
## krąg, a po jego zgaśnięciu upiory znikają i kamień sypie runy.
func _check_uroczysko(d) -> void:
	var stone = d.uroczyska[0]
	check("Uroczysko czeka na dotknięcie", stone.can_harvest() and stone.state == "idle")
	stone.harvest(stone.global_position)
	check("dotknięcie otwiera krąg", stone.state == "open" and not stone.can_harvest() and is_equal_approx(stone.radius, _Dungeons.URO_START))
	var enemies := _world.get_tree().get_nodes_in_group("enemies").size()
	for i in 60:
		stone._spawn_timer = 0.0
		stone._process(0.0)
	var inside := true
	for entry: Array in stone.ghosts:
		inside = inside and entry[0].global_position.distance_to(stone.global_position) <= stone.radius + 1.0 \
				and entry[0].sprite.material.shader == load("res://shaders/ghost.gdshader")
	check("upiory w kręgu (zjawy)", stone.ghosts.size() == stone.wanted_ghosts() and inside
			and _world.get_tree().get_nodes_in_group("enemies").size() == enemies + stone.ghosts.size(), "%d upiorów" % stone.ghosts.size())
	# upiór wypchnięty poza brzeg wraca do kręgu
	var ghost = stone.ghosts[0][0]
	ghost.global_position = stone.global_position + Vector2(stone.radius + 200.0, 0)
	stone._keep_inside()
	check("upiory nie wychodzą poza krąg", ghost.global_position.distance_to(stone.global_position) <= stone.radius)
	var before: float = stone.radius
	for i in 5:
		stone.ghosts[0][0].take_damage(99999999, stone.global_position)
	check("zabójstwa poszerzają krąg", stone.kills == 5 and stone.radius > before, "%.0f -> %.0f" % [before, stone.radius])
	# krąg się kurczy (po chwili spokoju)
	stone._elapsed = _Dungeons.URO_GRACE + 1.0
	before = stone.radius
	stone._process(1.0)
	check("krąg się kurczy", stone.radius < before)
	check("runy za upiory: więcej zabitych - więcej run", stone.reward_runes(0) == 0 and stone.reward_runes(5) == 1
			and stone.reward_runes(60) > stone.reward_runes(20) and stone.reward_runes(9999) == _Dungeons.URO_RUNES_MAX)
	var alive: Array = stone.ghosts.map(func(e: Array): return e[0])
	stone.kills = 30
	stone.radius = _Dungeons.URO_END - 1.0
	stone._process(0.1)
	var runes: Array = _world.entities.get_children().filter(func(n: Node) -> bool:
			return n.get_script() == load("res://scripts/pickup.gd") and str(n.item_id).begins_with("rune_") \
				and n.position.distance_to(stone.position) < 80.0)
	check("krąg gaśnie: upiory znikają, kamień sypie runy", stone.state == "closed" and stone.ghosts.is_empty()
			and alive.all(func(g) -> bool: return not g.is_in_group("enemies")) and runes.size() >= stone.reward_runes(30),
			"%d run" % runes.size())
	var R = load("res://scripts/item_craft.gd")
	var rolled := {}
	for i in 2000:
		var id: String = R.roll_rune(1)
		rolled[id] = rolled.get(id, 0) + 1
	check("runy: proste częściej, Pieczęć dopiero od 4. stopnia", rolled.get("rune_polish", 0) > rolled.get("rune_chaos", 0)
			and not rolled.has("rune_seal") and not rolled.has("rune_ascend") and R.roll_rune(9) != "", str(rolled))
	# siatka „kto jest blisko” (Goblin.near) jest liczona raz na klatkę - test elit dodaje potwory w tej samej klatce
	load("res://scripts/goblin.gd")._near_frame = -1


## Elitarne potwory: liczba, cechy z różnych grup, aura, tarcza, rozszczepienie i łup.
func _check_elites(d) -> void:
	var traits_ok := true
	for elite in d.elites:
		var groups := {}
		for id: String in elite.traits:
			groups[_Dungeons.ELITE_TRAITS[id]["group"]] = true
		traits_ok = traits_ok and elite.traits.size() >= 1 and elite.traits.size() <= 3 and groups.size() == elite.traits.size() \
				and elite.goblin.elite == elite and elite.goblin.scale.x > 1.0 and elite.label_text() != ""
	check("elity w lochu (3-5, cechy z różnych grup, większe, z napisem)", d.elites.size() >= 3 and d.elites.size() <= 5 and traits_ok,
			str(d.elites.map(func(e) -> Array: return e.traits)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var counts := [0, 0, 0, 0]
	for i in 2000:
		counts[_Dungeons.roll_elite_traits(rng).size()] += 1
	check("liczba cech elity: najczęściej 1, rzadko 3", counts[1] > counts[2] and counts[2] > counts[3] and counts[3] > 0 and counts[0] == 0, str(counts))
	var elite = d.elites[0]
	var boss = elite.goblin
	# aura Dowódczego: sąsiad zadaje więcej obrażeń, po wygaśnięciu wraca do normy
	var spawn: Dictionary = d._spawn("skeleton", boss.global_position + Vector2(20, 0), boss.global_position, d.level)
	var ally = _world._live_goblins.get(spawn["id"])
	var base_damage: int = ally.damage
	elite._trait_tick("commander", Time.get_ticks_msec())
	check("aura elity wzmacnia sąsiadów", ally.has_aura("commander") and ally.damage == roundi(base_damage * 1.4), "%d -> %d" % [base_damage, ally.damage])
	ally._auras["commander"][1] = 0
	ally._refresh_auras()
	check("po wyjściu z aury statystyki wracają", ally.damage == base_damage and ally._aura_base.is_empty())
	elite._trait_tick("warding", Time.get_ticks_msec())
	var hp: int = ally.health
	ally.take_damage(100, ally.global_position)
	check("aura Osłaniającego zmniejsza obrażenia", hp - ally.health == 65, "%d" % (hp - ally.health))
	# tarcza (bez aury Osłaniającego, którą elita nałożyła też na siebie)
	boss._auras.clear()
	boss._refresh_auras()
	elite.max_shield = 100
	elite.shield = 100
	hp = boss.health
	boss.take_damage(60, boss.global_position)
	check("tarcza elity przyjmuje obrażenia", boss.health == hp and elite.shield == 40, "tarcza %d" % elite.shield)
	boss.take_damage(70, boss.global_position)
	check("po tarczy obrażenia idą w zdrowie", elite.shield == 0 and boss.health == hp - 30, "%d" % (hp - boss.health))
	# łup elity
	var loot: Array = load("res://scripts/dungeon_elite.gd").roll_loot(d.level, 2)
	check("łup elity: 1 + liczba cech przedmiotów", loot.size() >= 3)
	# rozszczepienie
	var enemies := _world.get_tree().get_nodes_in_group("enemies").size()
	elite.traits.assign(["splitting"])
	elite._split(boss.global_position)
	check("Rozszczepialny dzieli się na mniejsze", _world.get_tree().get_nodes_in_group("enemies").size() == enemies + 3)
	# śmierć elity: zwykły łup i dodatkowy (przedmioty leżące przy elicie)
	var at: Vector2 = boss.global_position
	elite.traits.assign(["volatile"])
	boss.take_damage(99999999, boss.global_position)
	for i in 2:
		await _world.get_tree().process_frame
	var items: Array = _world.entities.get_children().filter(func(n: Node) -> bool:
			return n.get_script() == load("res://scripts/pickup.gd") and n.item_id != "gold" and n.position.distance_to(at) < 60.0)
	check("pokonana elita sypie dodatkowe przedmioty", items.size() >= 2, str(items.map(func(n) -> String: return n.item_id)))


func _mods() -> Dictionary:
	return load("res://scripts/goblin.gd").dungeon_mods


func _pickups() -> int:
	var script = load("res://scripts/pickup.gd")
	return _world.entities.get_children().filter(func(n: Node) -> bool: return n.get_script() == script).size()


func _check_vault_and_save() -> void:
	var d = _world._dungeon
	var before := _pickups()
	d._boss.take_damage(999999, d._boss.global_position)
	var after := _pickups()
	check("skarbiec po strażniku", d._vault_open and after - before >= 5, "%d łupów" % (after - before))
	check("płomienie powrotu w komnacie strażnika", d._portals.size() == 2)
	var save: Dictionary = _world.get_save_data()
	check("zapis z lochu wraca do Ostoi", save["zone"] == "forest" and save["arrive"] == "watra" and not save["zones"].has("dungeon"))
	check("potwory w lochu się nie odradzają", _world._respawn_queue.is_empty())


func _start_flow() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	var world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	_flow = 1
	_flow_frame = 0


func _process_flow() -> void:
	_flow_frame += 1
	var w = root.get_tree().get_first_node_in_group("world")
	if w == null:
		return
	if _flow == 1 and _flow_frame == 10:
		w.player.boons.ember = 2400
		w.hud.watra_window.open()
		w.hud.watra_window.dungeon_requested.emit()
		var win = w.hud.dungeon_window
		check("okno lochów z okna Watry", win.visible)
		win._choose_climate("flooded")
		win._change_tier(5)
		check("stopień najwyżej poziom Watry", win._tier == 4, "%d" % win._tier)
		win._mod_boxes["fury"].button_pressed = true
		win._on_enter()
		check("wydany żar", w.player.boons.ember_spent == 50 and w.player.boons.watra_level() == 4)
		_flow = 2
		_flow_frame = 0
	elif _flow == 2 and _flow_frame == 60:
		check("w lochu po wejściu w płomienie", w.zone == "dungeon" and w._dungeon_config["climate"] == "flooded" and w._dungeon_config["tier"] == 4)
		check("modyfikator działa", is_equal_approx(_mods()["damage"], 1.25))
		w.player.global_position = w._dungeon._portals[0]["rect"].get_center()
		_flow = 3
		_flow_frame = 0
	elif _flow == 3 and _flow_frame == 60:
		check("powrót przed Watrę", w.zone == "forest" and w.player.global_position.distance_to(w._settlement.watra_arrival()) < 8.0)
		check("poza lochem bez modyfikatorów", _mods().is_empty())
		print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
		quit()


func _check_window() -> void:
	var Boons = load("res://scripts/boons.gd")
	var boons = Boons.new()
	boons.ember = 1000
	check("żar do wydania", boons.available_ember() == 1000 and boons.watra_level() == 3)
	check("wydanie żaru", boons.spend_ember(150) and boons.available_ember() == 850 and boons.watra_level() == 3)
	check("za mało żaru", not boons.spend_ember(5000))
	var copy = Boons.new()
	copy.load_save_data(boons.get_save_data())
	check("zapis wydanego żaru", copy.ember_spent == 150)
	boons.free()
	copy.free()
	check("koszt modyfikatorów", _Dungeons.mods_cost(["horde", "wealth"]) == 100)
	check("stopnie", _Dungeons.tier_level(1) == 5 and _Dungeons.tier_level(7) == 41)
