extends SceneTree
## Zlecenia z tablicy ogłoszeń (Bounties): oferty od podróżników i mieszkańców w odkrytych krainach (potwory, bossowie,
## surowce), liczba ofert wg rangi gildii, najwyżej 3 przyjęte, postęp i odbiór (surowce oddane, sława gildii,
## przedmioty), zapis tablicy, rangi gildii zależne od sławy (6 poziomów, na końcu 40 podróżników), okno tablicy.

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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 6:
		return false
	var p = _world.player
	var B = load("res://scripts/bounties.gd")
	var T = load("res://scripts/travelers.gd")
	var log = p.quests
	p.quests.states["village_help"] = "done"
	_world._settlement.set_project("guild", "built")
	_world._sync_travelers()
	p.stats.level = 12
	_world.shrines["old_mill"] = [0, 0]
	check("krainy zleceń: odkryte", B.zones_for(p) == ["forest", "fields"], str(B.zones_for(p)))
	var kinds := {}
	var ok := true
	for offer: Dictionary in B.generate(p, 80, 0):
		kinds[offer["kind"]] = true
		if offer["zone"] not in ["forest", "fields"] or offer["gold"] <= 0 or offer["fame"] <= 0 or offer["poster"] == "":
			ok = false
		if offer["kind"] == "boss" and not str(offer["target"]).begins_with("boss:"):
			ok = false
	check("oferty: potwory, bossowie, surowce", ok and kinds.size() == 3, str(kinds.keys()))
	log.refresh_board(p, true)
	check("liczba ofert wg rangi", log.board_offers.size() == B.offer_count(1))
	# przyjęcie: najwyżej 3
	var kill: Dictionary = B.make("kill", "forest", 0, "Dobrawa")
	var gather: Dictionary = B.make("gather", "forest", 0, "Radomir")
	var boss: Dictionary = B.make("boss", "forest", 0, "Zlata")
	var ids := []
	for offer in [kill, gather, boss]:
		ids.append(log.take_bounty(offer))
	check("trzy przyjęte, czwarte nie", log.active_bounties().size() == 3 and log.take_bounty(B.make("kill", "forest", 0, "X")) == "")
	# potwory
	for i in kill["count"]:
		log.on_enemy_killed(kill["target"])
	var gold: int = p.stats.gold
	check("zlecenie na potwory wykonane", log.state_of(ids[0]) == "ready")
	check("odbiór: złoto i sława", log.finish_bounty(ids[0], p) and p.stats.gold >= gold + kill["gold"] and p.travelers.guild_fame == kill["fame"])
	# surowce - oddane przy odbiorze
	var owned_before: int = p.count_owned(gather["item"])
	p.storage.add_item(gather["item"], gather["count"])
	p._update_gather_quests()
	check("zamówienie surowców gotowe", log.state_of(ids[1]) == "ready")
	check("surowce oddane", log.finish_bounty(ids[1], p) and p.count_owned(gather["item"]) == owned_before, "%s %d" % [gather["item"], p.count_owned(gather["item"])])
	# boss
	log.on_enemy_killed(boss["target"])
	check("nagroda za bossa", log.state_of(ids[2]) == "ready" and log.finish_bounty(ids[2], p) and log.bounties_done == 3)
	# zapis tablicy
	log.refresh_board(p, true)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(log.get_save_data()))
	var copy = load("res://scripts/quest_log.gd").new()
	copy.load_save_data(saved)
	check("zapis tablicy", copy.board_offers.size() == log.board_offers.size() and copy.bounties_done == log.bounties_done, "%d %d %d" % [copy.board_offers.size(), log.board_offers.size(), copy.bounties_done])
	copy.free()
	# rangi gildii: 6 poziomów, coraz mniejszy przyrost, na końcu 40
	var steps := []
	for r in range(1, T.RANK_ACTIVE.size()):
		steps.append(T.RANK_ACTIVE[r] - T.RANK_ACTIVE[r - 1])
	check("6 rang, mniejszy przyrost, 40 na końcu", T.MAX_RANK == 6 and T.RANK_ACTIVE[1] == 14 and T.RANK_ACTIVE[-1] == 40
			and steps.slice(1) == steps.slice(1).duplicate().map(func(x): return x) and steps[2] >= steps[-1], str(T.RANK_ACTIVE))
	# okno tablicy
	var board = _world.find_child("HUD", true, false).board_window
	board.open()
	check("okno tablicy", board.visible and board._offers.get_child_count() == log.board_offers.size())
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
