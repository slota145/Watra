extends SceneTree
## Inni podróżnicy i rynek gildii: spis (aktywni wg rangi gildii), życie w czasie, spacerowicze w Ostoi i łowcy
## w krainie, walka podróżnika (potwór odpowiada, zabity przez podróżnika nie daje graczowi łupu ani doświadczenia),
## pisarz gildii (rynek, lista), rynek towarów (kupno i sprzedaż od razu, zamówienia realizowane z czasem, wycofanie),
## oferty przedmiotów (kupno, wystawienie i sprzedaż), ulepszenie gildii, zapis, okna.

var _world: Node
var _frame := 0
var _fails := 0
var _hunter = null
var _enemy = null
var _xp := 0


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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	match _frame:
		6:
			_roster_and_town(p)
		7:
			_start_fight(p)
		90:
			check("walka: potwór odpowiada", _enemy == null or not is_instance_valid(_enemy) or _enemy.objective == _hunter or _enemy.state == 4)
			_market(p)
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
	return false


func _roster_and_town(p) -> void:
	var t = p.travelers
	t.ensure_roster()
	check("spis 40 podróżników", t.roster.size() == 40 and t.roster.all(func(r: Dictionary) -> bool: return r["name"] != ""))
	check("bez gildii kilku wędrowców", t.active().size() == 4)
	p.quests.states["village_help"] = "done"
	_world._settlement.set_project("guild", "built")
	var clerk = null
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == "Pisarz gildii Gniewko":
			clerk = npc
	check("pisarz gildii: rynek i lista", clerk != null and "market" in clerk.services and "travelers" in clerk.services)
	_world._sync_travelers()
	check("gildia: ranga 1, 14 aktywnych", t.guild_rank == 1 and t.active().size() == 14)
	var town: Array = _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "town")
	check("spacerowicze w Ostoi", town.size() > 0 and town.size() <= 10 and town.size() == mini(t.in_town().size(), 10), "%d" % town.size())
	# łowy w krainie
	for r: Dictionary in t.active().slice(0, 3):
		r["state"] = "hunt"
		r["zone"] = "forest"
	_world._sync_travelers()
	var hunters: Array = _world.get_tree().get_nodes_in_group("travelers").filter(func(n) -> bool: return n.mode == "hunt")
	check("łowcy w krainie", hunters.size() == 3)
	_hunter = hunters[0] if not hunters.is_empty() else null
	# czas: spis żyje dalej
	var kills_before := 0
	for r: Dictionary in t.active():
		kills_before += int(r["kills"])
	for i in 5:
		t.tick()
	var kills_after := 0
	for r: Dictionary in t.active():
		kills_after += int(r["kills"])
	check("spis żyje w czasie", kills_after > kills_before)


func _start_fight(p) -> void:
	if _hunter == null:
		check("łowca do walki", false)
		return
	# zwykły potwór blisko łowcy, gracz daleko
	for e in _world.get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("bosses") and e.quest_kind != "animal" and not e.scene_file_path.contains("dummy"):
			_enemy = e
			break
	_hunter.global_position = _enemy.global_position + Vector2(15, 0)
	_hunter.data["level"] = 40
	_hunter._target = _enemy
	_xp = p.stats.xp
	var hits := 0
	while is_instance_valid(_enemy) and _enemy.state != 4 and hits < 40:
		_hunter._attack("melee")
		hits += 1
	check("podróżnik pokonał potwora", _enemy.state == 4, "%d ciosów" % hits)
	check("bez łupu i doświadczenia dla gracza", _enemy.slain_by_travelers() and p.stats.xp == _xp)
	check("zabójstwo w spisie", int(_hunter.data["kills"]) > 0)
	# drugi potwór - walka w czasie (odpowiada na ciosy)
	_enemy = null
	for e in _world.get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("bosses") and e.quest_kind != "animal" and not e.scene_file_path.contains("dummy") and e.global_position.distance_to(p.global_position) > 300:
			_enemy = e
			break
	if _enemy != null:
		_hunter.global_position = _enemy.global_position + Vector2(18, 0)
		_hunter.data["level"] = 1
		_hunter._target = _enemy
		_hunter._attack("melee")


func _market(p) -> void:
	var m = p.market
	m.ensure()
	var gold := 100000
	p.stats.add_gold(gold)
	var price: int = m.price_of("wood")
	check("ceny towarów", price > 0 and m.book("wood")["sell"].size() >= 5 and m.book("wood")["buy"][0][0] < m.book("wood")["sell"][0][0])
	var wood: int = p.inventory.count_of("wood")
	var cost: int = m.quote_buy("wood", 20)
	var before: int = p.stats.gold
	check("kupno od razu", m.buy_now("wood", 20) == "" and p.inventory.count_of("wood") == wood + 20 and p.stats.gold == before - cost)
	before = p.stats.gold
	var gain: int = m.quote_sell("wood", 10)
	check("sprzedaż od razu (podatek)", m.sell_now("wood", 10) == "" and p.stats.gold == before + gain and gain < 10 * m.book("wood")["buy"][0][0] + 1)
	# zamówienia: sprzedaż taniej i kupno drożej od rynku realizują się szybko
	p.inventory.add_item("stone", 50)
	check("wystawienie sprzedaży", m.place_sell("stone", 50, maxi(1, m.price_of("stone") / 2)) == "" and p.inventory.count_of("stone") == 0)
	check("zamówienie kupna", m.place_buy("iron_ore", 10, m.price_of("iron_ore") * 2) == "")
	var gold_mid: int = p.stats.gold
	for i in 30:
		m.tick()
	check("zamówienia zrealizowane", m.orders.is_empty() and p.inventory.count_of("iron_ore") >= 10 and p.stats.gold > gold_mid, str(m.orders))
	p.inventory.add_item("meat", 5)
	m.place_sell("meat", 5, 99999)
	m.cancel(m.orders.size() - 1)
	check("wycofanie zamówienia", p.inventory.count_of("meat") == 5 and m.orders.is_empty())
	# przedmioty
	m.refresh_listings(true)
	check("oferty przedmiotów", m.listings.size() >= 20)
	var listing: Dictionary = m.listings[0]
	var id: String = listing["id"]
	check("kupno przedmiotu", m.buy_listing(0) == "" and p.inventory.count_of(id) == 1)
	var index := -1
	for i in p.inventory.slots.size():
		if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == id:
			index = i
	check("wystawienie przedmiotu", m.list_item(index, 1) == "" and m.listings.any(func(l: Dictionary) -> bool: return l["id"] == id and l["mine"]))
	before = p.stats.gold
	for i in 20:
		m.tick()
	check("przedmiot sprzedany", not m.listings.any(func(l: Dictionary) -> bool: return l.get("mine", false)) and p.stats.gold >= before)
	# zapis
	var saved_m: Dictionary = JSON.parse_string(JSON.stringify(m.get_save_data()))
	var saved_t: Dictionary = JSON.parse_string(JSON.stringify(p.travelers.get_save_data()))
	var copy = load("res://scripts/market.gd").new()
	copy.load_save_data(saved_m)
	var t2 = load("res://scripts/travelers.gd").new()
	t2.load_save_data(saved_t)
	check("zapis rynku i podróżników", copy.listings.size() == m.listings.size() and is_equal_approx(copy.prices["wood"], m.prices["wood"])
			and t2.roster.size() == 40 and t2.guild_rank == 1)
	copy.free()
	t2.free()
	# ulepszenie gildii
	for item in ["wood", "stone"]:
		p.inventory.add_item(item, 300)
	check("ulepszenie wymaga sławy", p.travelers.upgrade_rank(p) != "" and p.travelers.guild_rank == 1)
	p.travelers.guild_fame = 60
	check("ulepszenie gildii", p.travelers.upgrade_rank(p) == "" and p.travelers.guild_rank == 2 and p.travelers.active().size() == 21)
	# okna
	var hud = _world.find_child("HUD", true, false)
	hud.market_window.open()
	for tab in ["goods", "items", "mine"]:
		hud.market_window._show(tab)
	hud.travelers_window.open()
	check("okna rynku i podróżników", hud.market_window.visible and hud.travelers_window._list.get_child_count() > 8 * 10)
