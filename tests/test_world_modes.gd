extends SceneTree
## Tryby świata (WorldModes): charaktery podróżników i ich zachowanie w trybach (spokojny - wszyscy przyjaźni,
## realistyczny - pojedynki, hardcorowy - także zbóje), kolor imienia, pojedynek do 10% zdrowia (wygrana: złoto
## i sława, przegrana: bez śmierci), napad zbója (pokonany - sława i śmierć w spisie; wygrany - kradzież 10% złota),
## zmiana trybu u żercy, starsze zapisy - tryb spokojny.

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


var _used := {}


func _hunter(t, temper: String):
	var data: Dictionary = {}
	for r: Dictionary in t.active():
		if r["state"] != "party" and not _used.has(r["name"]):
			data = r
			_used[r["name"]] = true
			break
	data["temper"] = temper
	data["state"] = "hunt"
	data["zone"] = "forest"
	data["level"] = 10
	_world._sync_travelers()
	for node in _world.get_tree().get_nodes_in_group("travelers"):
		if node.data == data and node.is_alive():
			return node
	return null


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 6:
		return false
	var p = _world.player
	var t = p.travelers
	var WM = load("res://scripts/world_modes.gd")
	p.quests.states["village_help"] = "done"
	_world._settlement.set_project("guild", "built")
	_world._sync_travelers()
	var tempers := {}
	for r: Dictionary in t.roster:
		tempers[r["temper"]] = true
	check("charaktery w spisie", tempers.size() == 3, str(tempers.keys()))
	check("starsze zapisy - tryb spokojny", t.world_mode == "calm")
	var bandit := {"temper": "bandit"}
	var duelist := {"temper": "duelist"}
	check("spokojny: wszyscy przyjaźni", t.behavior(bandit) == "friendly" and t.behavior(duelist) == "friendly")
	t.world_mode = "realistic"
	check("realistyczny: pojedynki, bez zbójów", t.behavior(bandit) == "duelist" and t.behavior(duelist) == "duelist")
	t.world_mode = "hardcore"
	check("hardcorowy: zbóje", t.behavior(bandit) == "bandit")
	# kolor imienia
	var node = _hunter(t, "bandit")
	check("czerwone imię zbója", node != null and node._label.get_theme_color("font_color") == WM.TEMPERS["bandit"]["color"])
	# pojedynek: wygrana
	t.world_mode = "realistic"
	var duel_node = _hunter(t, "duelist")
	p.stats.level = 20
	p.global_position = duel_node.global_position + Vector2(40, 0)
	var gold: int = p.stats.gold
	var fame: int = t.guild_fame
	_world._start_fight(duel_node, "duel")
	var rival = _world._rival
	check("rywal w walce", rival != null and rival.is_in_group("enemies") and not duel_node.visible)
	rival.take_damage(rival.max_health, p.global_position)
	check("wygrany pojedynek: bez śmierci, złoto i sława", rival._ended and rival.health > 0 and p.stats.gold > gold and t.guild_fame == fame + 5)
	check("podróżnik wraca", duel_node.visible and duel_node.is_alive())
	# pojedynek: przegrana bez śmierci
	_world._rival = null
	_world._start_fight(duel_node, "duel")
	rival = _world._rival
	p.health = roundi(p.stats.max_health() * 0.12)
	var health: int = p.health
	rival.global_position = p.global_position + Vector2(10, 0)
	rival._attack_timer = 0.0
	rival._process_attack(0.1)
	check("przegrany pojedynek: gracz żyje", rival._ended and not p.is_dead and p.health == health)
	# napad zbója - gracz wygrywa
	t.world_mode = "hardcore"
	_world._rival = null
	var bandit_node = _hunter(t, "bandit")
	_world._start_fight(bandit_node, "pk")
	rival = _world._rival
	fame = t.guild_fame
	rival.take_damage(rival.max_health * 2, p.global_position)
	check("pokonany zbój: sława i śmierć w spisie", t.guild_fame == fame + 10 and bandit_node.data["state"] == "dead")
	# napad zbója - gracz pada: kradzież złota
	_world._rival = null
	var bandit2 = _hunter(t, "bandit")
	_world._start_fight(bandit2, "pk")
	p.stats.gold = 1000
	_world._on_player_died_pk()
	check("zbój zabiera 10% złota", p.stats.gold == 900 and _world._rival._ended)
	# spotkanie: zbój napada bez okienka
	_world._rival = null
	var bandit3 = _hunter(t, "bandit")
	p.global_position = bandit3.global_position + Vector2(30, 0)
	_world._party_cooldown = 0.0
	_world._party_check = 0.0
	_world._process_party_offers(0.1)
	check("zbój napada bez ostrzeżenia", _world._rival != null and _world._rival.kind == "pk"
			and not _world.find_child("HUD", true, false).party_offer.is_open())
	# zmiana trybu u żercy i zapis
	var hud = _world.find_child("HUD", true, false)
	hud.open_world_modes()
	var window = hud.get_node("WorldModeWindow")
	var picker = window.get_child(0).get_child(0)
	picker.chosen.emit("calm")
	check("zmiana trybu u żercy", t.world_mode == "calm")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(t.get_save_data()))
	var t2 = load("res://scripts/travelers.gd").new()
	t2.load_save_data(saved)
	check("zapis trybu i charakterów", t2.world_mode == "calm" and t2.roster[0].has("temper"))
	t2.free()
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false
