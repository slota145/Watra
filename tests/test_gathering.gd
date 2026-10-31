extends SceneTree
## Łowcy zbierający surowce: wybór surowca przy siedlisku (daleko od gracza, poza Ostoją, limit zebranych w krainie),
## praca i ślad po zebraniu, urobek na rynku jako świeża, tańsza oferta (kupno zabiera ją pierwszą, inni wykupują,
## zapis), rynek w spisie podróżników, prośba o osłonę i osłona zbieracza (fale potworów, nagroda, porażka).

var _world: Node
var _frame := 0
var _fails := 0


func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
	current_scene = _world


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _hunters() -> Array:
	return _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "hunt" and n.is_alive())


func _reset_quota() -> void:
	load("res://scripts/traveler.gd").set("_quota_at", -100000)


## Gracz daleko od łowcy (poza Ostoją).
func _away(p, from: Vector2) -> void:
	for offset in [Vector2(900, 0), Vector2(-900, 0), Vector2(0, 900), Vector2(0, -900)]:
		var spot: Vector2 = from + offset
		if not _world._settlement.is_inside_palisade(Vector2i((spot / 16.0).floor())):
			p.global_position = spot
			break
	p.reset_physics_interpolation()


## Praca łowcy aż do końca (bez czekania na klatki).
func _work(h, steps := 60) -> void:
	h.global_position = h.gather_target.global_position + Vector2(0, 8)
	for i in steps:
		if h.gather_target == null:
			return
		h._process_gather(0.25)


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var hud = _world.find_child("HUD", true, false)
	if _frame != 6:
		return false
	p.quests.states["village_help"] = "done"
	_world._settlement.set_project("guild", "built")
	_world._sync_travelers()
	for r: Dictionary in p.travelers.active().slice(0, 3):
		r["state"] = "hunt"
		r["zone"] = "forest"
		r["level"] = 30
	_world._sync_travelers()
	var hunters := _hunters()
	check("łowcy na spocie", hunters.size() >= 2)
	var h = hunters[0]
	check("rynek w spisie podróżników", p.travelers.market == p.market)
	_away(p, h.global_position)
	_reset_quota()
	var t = h.find_gather_target()
	check("łowca znajduje surowiec przy siedlisku", t != null and t.global_position.distance_to(h.home) < 260.0
			and not load("res://scripts/goblin.gd").safe_zone.has_point(t.global_position))
	if t == null:
		_finish()
		return false
	# surowiec blisko gracza zostaje dla gracza
	var keep: Vector2 = p.global_position
	p.global_position = t.global_position
	check("nie zbiera blisko gracza", h.find_gather_target() != t)
	p.global_position = keep
	# praca i urobek na rynku
	var market = p.market
	market.fresh.clear()
	h._start_gather(t)
	check("zajęty surowiec", t.get_meta("gatherer", null) == h and hunters[1].find_gather_target() != t)
	check("rodzaj surowca", h.gather_kind() in ["tree", "stone", "ore", "herb"])
	_work(h)
	check("surowiec zebrany - ślad", t.is_depleted and h.gather_target == null)
	var fresh_id := ""
	for id: String in market.fresh:
		if str(market.fresh[id][0][1]) == h.data["name"]:
			fresh_id = id
	check("urobek na rynku jako świeży towar", fresh_id != "", str(market.fresh))
	if fresh_id != "":
		var book: Dictionary = market.book(fresh_id)
		var fresh_levels: Array = book["sell"].filter(func(l: Array) -> bool: return l.size() > 3)
		var normal: Array = book["sell"].filter(func(l: Array) -> bool: return l.size() == 3)
		check("świeża oferta najtańsza, ale droższa od kupna", not fresh_levels.is_empty() and book["sell"][0].size() > 3
				and int(fresh_levels[0][0]) < int(normal[0][0]) and int(fresh_levels[0][0]) > int(book["buy"][0][0]),
				"%s / %s" % [book["sell"].slice(0, 3), book["buy"][0]])
		# zapis świeżego towaru
		var saved: Dictionary = JSON.parse_string(JSON.stringify(market.get_save_data()))
		var m2 = load("res://scripts/market.gd").new()
		m2.load_save_data(saved)
		check("zapis świeżego towaru", m2.fresh.get(fresh_id, []) == market.fresh[fresh_id])
		m2.free()
		# kupno zabiera świeże oferty pierwsze
		var qty := 0
		for e: Array in market.fresh[fresh_id]:
			qty += int(e[0])
		p.stats.add_gold(100000)
		var message: String = market.buy_now(fresh_id, qty)
		check("kupno zabiera świeży towar", message == "" and not market.fresh.has(fresh_id), message)
	# inni podróżnicy wykupują świeże oferty
	market.supply("wood", 5, "Test")
	for i in 30:
		market.tick()
	check("świeże oferty znikają z czasem", not market.fresh.has("wood"))
	# limit: zebrane 20% surowców w krainie - łowcy czekają
	var all: Array = _world.get_tree().get_nodes_in_group("harvestables")
	var forced: Array = []
	for node in all:
		if forced.size() >= ceili(all.size() * 0.21):
			break
		if not node.is_depleted:
			node.deplete(500.0)
			forced.append(node)
	_reset_quota()
	check("limit zebranych surowców", h.find_gather_target() == null)
	for node in forced:
		node.regrow()
	_reset_quota()
	# napadnięty przy pracy - przerywa
	var t2 = h.find_gather_target()
	h._start_gather(t2)
	h.take_hit(1.0)
	check("napad przerywa zbieranie", h.gather_target == null and not t2.has_meta("gatherer"))
	# prośba o osłonę przy zbierającym łowcy
	h._start_gather(t2)
	h.global_position = t2.global_position + Vector2(0, 8)
	var asked := false
	for i in 20:
		p.global_position = h.global_position + Vector2(40, 0)
		_world._party_cooldown = 0.0
		_world._party_check = 0.0
		_world._process_party_offers(0.1)
		if hud.party_offer.is_open():
			asked = hud.party_offer._text.text.contains("Osłonisz")
			hud.party_offer._answer(false)
			if asked:
				break
	check("prośba o osłonę", asked)
	# osłona: fala potworów na zbieracza, ciosy nie przerywają pracy, nagroda
	_world.start_guard(h)
	check("osłona trwa", not _world._guard.is_empty() and h.guard_time > 0.0)
	var enemy = null
	for e in _world.get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("bosses") and e.quest_kind != "animal" and e.state != 4:
			enemy = e
			break
	enemy.global_position = h.global_position + Vector2(60, 0)
	enemy.home = enemy.global_position
	_world._guard_wave(h)
	var pulled: Array = _world.get_tree().get_nodes_in_group("enemies").filter(func(e) -> bool: return e.objective == h)
	check("fala potworów idzie na zbieracza", pulled.size() >= 1 and pulled.all(func(e) -> bool: return e.state == 1),
			"%d %s %s %.0f" % [pulled.size(), enemy.objective, enemy.state, enemy.leash_radius])
	h.take_hit(1.0)
	check("ciosy nie przerywają osłanianej pracy", h.is_gathering())
	var gold: int = p.stats.gold
	var xp: int = p.stats.xp
	_world._guard["left"] = 0.01
	_world._process_guard(0.1)
	check("nagroda za osłonę", _world._guard.is_empty() and p.stats.gold > gold and enemy.objective == null)
	# porażka: zbieracz pada
	var h2 = hunters[1]
	_away(p, h2.global_position)
	_reset_quota()
	var t3 = h2.find_gather_target()
	if t3 != null:
		h2._start_gather(t3)
		h2.global_position = t3.global_position + Vector2(0, 8)
		_world.start_guard(h2)
		gold = p.stats.gold
		h2.health = 0.1
		h2.take_hit(1000.0)
		_world._process_guard(0.1)
		check("porażka osłony bez nagrody", _world._guard.is_empty() and p.stats.gold == gold and not t3.has_meta("gatherer"))
	else:
		check("drugi łowca znajduje surowiec", false)
	_finish()
	return false


func _finish() -> void:
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
