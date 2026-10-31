extends SceneTree
## Zadania główne (MainQuests): dane łańcucha (postacie, potwory, kapliczki, nagrody), żerca Wszebor przy Watrze
## ze złotym "!", przyjęcie i oddanie kroku u innej postaci (rozmowa), warunki (inne zadanie, zdarzenie),
## nagrody (przedmioty, punkty umiejętności), blokada lochów do „Płomienia Watry”, zaliczanie kroków w starszych
## zapisach, zapis zdarzeń i punktów.

var _world: Node
var _frame := 0
var _fails := 0
const NPCS := ["Żerca Wszebor", "Sołtys Mirosław", "Myśliwy Radek", "Kupiec Bogdan", "Kowal Bronisław", "Jubiler Dobromir"]


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


func _npc(name: String):
	for npc in _world.get_tree().get_nodes_in_group("npcs"):
		if npc.display_name == name:
			return npc
	return null


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 8:
		return false
	var p = _world.player
	var Main = load("res://scripts/main_quests.gd")
	var Items = load("res://scripts/items.gd")
	var Codex = load("res://scripts/codex.gd")
	var Zones = load("res://scripts/zones.gd")
	# dane łańcucha
	var bad: Array = []
	for id: String in Main.CHAIN:
		var data: Dictionary = Main.DATA.get(id, {})
		if data.is_empty() or data["giver"] not in NPCS or Main.receiver_of(id) not in NPCS:
			bad.append(id)
			continue
		for item: String in data.get("reward_items", {}):
			if Items.get_data(item).is_empty():
				bad.append(id + ":" + item)
		var c: Array = data["check"]
		if c[0] == "boss" and not Codex.MONSTERS.has(c[1]):
			bad.append(id + ":" + c[1])
		if c[0] == "shrine" and not Zones.SHRINES.has(c[1]):
			bad.append(id + ":" + c[1])
	check("łańcuch: %d kroków, dane poprawne" % Main.CHAIN.size(), bad.is_empty() and Main.CHAIN.size() >= 20, str(bad))
	# żerca przy Watrze ze złotym "!"
	var zerca = _npc("Żerca Wszebor")
	check("żerca w Ostoi ze złotym !", zerca != null and zerca._quest_marker != null and zerca._quest_marker.visible
			and zerca._quest_marker.text == "!" and zerca._quest_marker.get_theme_color("font_color") == Main.COLOR)
	check("lochy zamknięte", not Main.dungeons_unlocked(p.quests))
	# przyjęcie u żercy, oddanie u sołtysa
	var dialog = _world.find_child("HUD", true, false).npc_dialog
	dialog.open(zerca)
	check("rozmowa: zadanie główne", dialog._shown_quest == "main_ember")
	dialog._accept()
	check("rozmowa z sołtysem od razu wykonana", p.quests.state_of("main_ember") == "ready")
	var soltys = _npc("Sołtys Mirosław")
	zerca._update_quest_marker(0.0)
	soltys._update_quest_marker(0.0)
	check("złoty ? nad sołtysem", soltys._quest_marker.visible and soltys._quest_marker.text == "?"
			and soltys._quest_marker.get_theme_color("font_color") == Main.COLOR)
	dialog.close()
	var gold: int = p.stats.gold
	dialog.open(soltys)
	dialog._turn_in()
	check("nagroda u sołtysa", p.quests.state_of("main_ember") == "done" and p.stats.gold == gold + 50)
	check("następny krok u sołtysa", Main.current(p.quests) == "main_village" and dialog._shown_quest == "main_village")
	dialog._accept()
	check("krok przyjmuje zadanie poboczne", p.quests.state_of("village_help") == "active")
	check("postęp kroku: surowce", Main.progress_text(p, "main_village").contains("0/30"), Main.progress_text(p, "main_village"))
	p.inventory.add_item("wood", 30)
	p.inventory.add_item("stone", 20)
	p._update_gather_quests()
	p.quests.update_main(p)
	check("postęp kroku po zebraniu", p.quests.state_of("village_help") == "ready"
			and p.quests.state_of("main_village") == "active" and dialog._shown_quest == "village_help", dialog._shown_quest)
	soltys._update_quest_marker(0.0)
	check("jasny złoty ? przy surowcach do oddania", soltys._quest_marker.text == "?"
			and soltys._quest_marker.get_theme_color("font_color") == Main.COLOR)
	dialog._turn_in()
	p.quests.update_main(p)
	check("warunek: inne zadanie", p.quests.state_of("village_help") == "done" and p.quests.state_of("main_village") == "ready"
			and dialog._shown_quest == "main_village" and p.inventory.count_of("wood") == 0)
	var potions: int = p.inventory.count_of("health_potion")
	dialog._turn_in()
	check("nagroda: przedmioty", p.inventory.count_of("health_potion") == potions + 5)
	# punkty umiejętności
	var points: int = p.skills.points_total() - p.skills.character_level
	p.quests.states["main_build"] = "ready"
	p.quests.turn_in("main_build", p.stats)
	check("nagroda: punkt umiejętności", p.skills.points_total() - p.skills.character_level == points + 1 and p.skills.bonus_points == 1)
	# zdarzenie: encyklopedia
	p.quests.states["main_herbs"] = "done"
	p.quests.states["main_tree"] = "done"
	p.quests.accept("main_codex")
	p.quests.update_main(p)
	check("przed otwarciem encyklopedii w toku", p.quests.state_of("main_codex") == "active")
	_world.find_child("HUD", true, false).codex_window.toggle()
	p.quests.update_main(p)
	check("zdarzenie: encyklopedia", p.quests.state_of("main_codex") == "ready" and p.quests.is_tracked("main_codex"))
	# zapis
	var saved: Dictionary = JSON.parse_string(JSON.stringify(p.quests.get_save_data()))
	var log = load("res://scripts/quest_log.gd").new()
	log.load_save_data(saved)
	var book_saved: Dictionary = JSON.parse_string(JSON.stringify(p.skills.get_save_data()))
	var book = load("res://scripts/skill_book.gd").new()
	book.load_save_data(book_saved)
	check("zapis zdarzeń i punktów", log.events.get("codex", 0) >= 1 and log.state_of("main_village") == "done" and book.bonus_points == 1)
	# starszy zapis: kroki zaliczają się same aż do ostatniego spełnionego (Watra na 2. poziomie -> lochy otwarte)
	log.states.clear()
	p.boons.ember = 1000
	log.catch_up_main(p)
	check("starszy zapis: lochy otwarte", Main.dungeons_unlocked(log) and log.state_of("main_watra") == "done"
			and Main.current(log) == "main_dungeon", Main.current(log))
	log.free()
	book.free()
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
