extends SceneTree
## Władca Hordy - ostateczny boss Mapy Nawii (scripts/horde_lord.gd, Pinnacles.LORD): dane, wejście za serca bogów,
## Pomrok (poziom, zdrowie, odblokowanie, zapis), tytuł; potem arena Władcy na Pomroku II: walka z graczem, fazy
## z cieniami bogów i osłoną, fale Hordy w ostatniej fazie, śmierć (serce, skarbiec, Pomrok III, sprzątanie Hordy);
## na koniec łańcuch Pasa Zimowego Oddechu i wpis Władcy w oknie Mapy Nawii.

const POMROK := 2
## Goblin.State.DEAD (bez odwołania do klasy - test kompiluje się przed autoloadami).
const DEAD := 4

var _world: Node
var _frame := 0
var _fails := 0
var _P
var _I
var _Loot
var _E
var _L
var _attacks := {}
var _shades := {}
var _health_mark := 0
var _frost: Array = []


func _initialize() -> void:
	TranslationServer.set_locale("pl")
	root.get_node("Game").save_path = "user://test_savegame.json"
	var config := {"climate": "mine", "tier": 17, "mods": [], "seed": 555, "idols": [], "pinnacle": "horde",
			"pomrok": POMROK, "mechanics": [], "altar": false, "tree": {}}
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": config, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _check_data() -> void:
	var lord: String = _P.LORD
	check("Władca w danych, nie wśród bogów", _P.GODS.has(lord) and not lord in _P.ORDER)
	check("scena Władcy", load("res://scenes/pinnacle_horde.tscn") != null)
	check("serce Władcy", _I.get_data(_P.heart(lord)).has("icon"))
	for id: String in _P.GODS[lord]["legends"] + ["legend_marzanna_belt"]:
		var data: Dictionary = _I.get_data(_Loot.legendary_at_level(id, 98))
		check("legenda %s" % id, data.get("rarity", "") == "legendary" and data.has("effect")
				and ResourceLoader.exists("res://assets/items/legends/%s.png" % id))
	check("pas Marzanny bez esencji", not _E.is_legend(_Loot.legendary_at_level("legend_marzanna_belt", 93)))
	check("poziom areny rośnie z Pomrokiem", _P.arena_level(lord, 3) == _P.GODS[lord]["level"] + 3 * _P.POMROK_LEVEL)
	check("Pomrok daje więcej łupu", _P.vault_rewards(98, RandomNumberGenerator.new(), true, 2).size()
			> _P.vault_rewards(98, RandomNumberGenerator.new(), false, 0).size())
	check("tytuł w opisie zapisu", root.get_node("Game").describe_save({"title": "horde", "pomrok": 2}).contains("Pogromca Hordy II"))


func _check_boons() -> void:
	var boons = load("res://scripts/boons.gd").new()
	var base: int = boons.watra_points()
	check("bez Władcy brak Pomroku i tytułu", boons.pomrok_unlocked == 0 and boons.title() == "")
	boons.set_pomrok(3)
	check("Pomrok zablokowany", boons.pomrok == 0)
	check("pierwsze zwycięstwo nad Władcą", boons.defeat_pinnacle("horde", 0))
	check("punkty Watry za Władcę", boons.watra_points() == base + _P.LORD_POINTS)
	check("odblokowany Pomrok I i tytuł", boons.pomrok_unlocked == 1 and boons.title() == "Pogromca Hordy")
	boons.defeat_pinnacle("weles", 1)
	check("bóg nie odblokowuje Pomroku", boons.pomrok_unlocked == 1)
	boons.defeat_pinnacle("horde", 0)
	check("niższy stopień nie odblokowuje", boons.pomrok_unlocked == 1)
	boons.defeat_pinnacle("horde", 1)
	boons.set_pomrok(5)
	check("Pomrok II i wybór w granicach", boons.pomrok_unlocked == 2 and boons.pomrok == 2)
	var copy = load("res://scripts/boons.gd").new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(boons.get_save_data())))
	check("zapis Pomroku", copy.pomrok_unlocked == 2 and copy.pomrok == 2 and int(copy.pinnacle_kills.get("horde", 0)) == 3)
	boons.free()
	copy.free()


func _lord():
	return _world._dungeon._boss


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_P = load("res://scripts/pinnacles.gd")
		_I = load("res://scripts/items.gd")
		_Loot = load("res://scripts/loot.gd")
		_E = load("res://scripts/essences.gd")
		_L = load("res://scripts/levels.gd")
		_check_data()
		_check_boons()
	if _frame == 6:
		var dungeon = _world._dungeon
		var lord = _lord()
		check("arena Władcy", dungeon != null and dungeon.pinnacle == "horde" and dungeon.pomrok == POMROK and lord.get_script().resource_path.ends_with("horde_lord.gd"))
		check("Władca na poziomie Pomroku", lord.level == _P.arena_level("horde", POMROK), str(lord.level))
		check("Władca ma więcej zdrowia niż bóg", lord.max_health > _L.health(lord.level) * _L.BOSS_HEALTH.y * 6.0, str(lord.max_health))
		check("tytuł areny z Pomrokiem", load("res://scripts/dungeons.gd").title(dungeon.config).contains("Pomrok II"))
		var player = _world.player
		player.global_position = lord.global_position + Vector2(0, 100)
		player.stats.level = 90
		lord._special_cooldown = 0.0
		lord.aggro()
	if _frame > 6 and _frame < 1500:
		_world.player.health = _world.player.stats.max_health()
		_world.player._invulnerable_timer = 1.0
		var lord = _lord()
		if _frame % 90 == 0 and is_instance_valid(lord) and lord.state != DEAD:
			_world.player.global_position = lord.global_position + Vector2.from_angle(_frame * 0.7) * (60.0 + (_frame % 270))
		for boss in root.get_tree().get_nodes_in_group("pinnacle_bosses"):
			if boss._attack != "":
				_attacks[boss.kind + ":" + boss._attack] = true
	# każdy atak Władcy choć raz: Zew Hordy (z dala) i Rozpłatanie (z bliska)
	if _frame == 150 or _frame == 340:
		var lord = _lord()
		var wanted := "call" if _frame == 150 else "lord_cleave"
		_world.player.global_position = lord.global_position + Vector2(0, 80)
		for i in 60:
			lord._cancel_attack()
			lord._call_cooldown = 0.0 if wanted == "call" else 99.0
			lord._choose_attack(_world.player.global_position - lord.global_position)
			if lord._attack == wanted:
				break
		check("wymuszony atak %s" % wanted, lord._attack == wanted)
	if _frame == 330:
		check("Zew Hordy przyzywa potwory", _lord().minion_count() > 0, str(_lord().minion_count()))
	# fazy: 75% - cień Welesa i osłona
	if _frame == 400:
		var lord = _lord()
		lord.take_damage(lord.health - roundi(lord.max_health * 0.74), lord.global_position)
		check("faza 2", lord.phase == 2, str(lord.phase))
	if _frame == 402:
		var lord = _lord()
		check("cień Welesa", lord.shade_alive() and lord._shade.kind == "weles" and lord._shade.shade)
		_shades["weles"] = lord._shade.max_health
		var before: int = lord.health
		lord.take_damage(1000, lord.global_position)
		check("osłona cienia", before - lord.health == roundi(1000 * lord.SHADE_SHIELD), str(before - lord.health))
		lord._shade.take_damage(lord._shade.health + 1, lord.global_position)
	if _frame == 404:
		var lord = _lord()
		check("cień pokonany - bez osłony", not lord.shade_alive())
		var before: int = lord.health
		lord.take_damage(1000, lord.global_position)
		check("pełne obrażenia bez cienia", before - lord.health == 1000)
		lord.take_damage(lord.health - roundi(lord.max_health * 0.49), lord.global_position)
	if _frame == 406:
		var lord = _lord()
		check("cień Marzanny", lord.phase == 3 and lord.shade_alive() and lord._shade.kind == "marzanna")
		lord._shade.take_damage(lord._shade.health + 1, lord.global_position)
	if _frame == 408:
		var lord = _lord()
		lord.take_damage(lord.health - roundi(lord.max_health * 0.24), lord.global_position)
	if _frame == 410:
		var lord = _lord()
		check("faza 4: cień Czarnoboga i wściekłość", lord.phase == 4 and lord.shade_alive() and lord._shade.kind == "czarnobog"
				and lord.enraged)
	if _frame == 900:
		var lord = _lord()
		check("fale Hordy", lord.minion_count() >= 3 and lord.minion_count() <= lord.MAX_MINIONS, str(lord.minion_count()))
	if _frame == 1500:
		var gods := {}
		for key: String in _attacks:
			gods[key.split(":")[0]] = true
		check("Władca i cienie atakują", gods.has("horde") and gods.size() >= 2, str(_attacks.keys()))
		check("różne ataki Władcy", _attacks.keys().filter(func(k: String) -> bool: return k.begins_with("horde:")).size() >= 2, str(_attacks.keys()))
		var lord = _lord()
		if lord.shade_alive():
			lord._shade.take_damage(lord._shade.health + 1, lord.global_position)
		lord.take_damage(lord.health + 10, lord.global_position)
		var boons = _world.player.boons
		check("pokonany Władca: Pomrok III i tytuł", boons.pomrok_unlocked == POMROK + 1 and boons.title() != "",
				"%d %s" % [boons.pomrok_unlocked, boons.title()])
	if _frame == 1520:
		var lord = _lord()
		check("Horda i cień znikają ze Władcą", lord.minion_count() == 0 and not lord.shade_alive())
		var hearts := 0
		var items := 0
		for pickup in root.get_tree().get_nodes_in_group("pickups"):
			if pickup.item_id == _P.heart("horde"):
				hearts += 1
			items += 1
		check("serce Władcy i skarbiec", hearts == 1 and items > 30, "%d serc, %d łupów" % [hearts, items])
		# Pas Zimowego Oddechu: łańcuch lodu przez gromadę słabych wrogów
		var dungeon = _world._dungeon
		var at: Vector2 = _world.player.global_position + Vector2(120, 0)
		for i in 5:
			var spawn: Dictionary = dungeon._spawn("goblin", at + Vector2(i * 40.0, 0), at, 1)
			var goblin = _world._live_goblins.get(spawn["id"])
			goblin.health = 1
			_frost.append(goblin)
		_world.player.legendary._winter_breath(_frost[0].hurt_center())
	if _frame == 1580:
		var dead := _frost.filter(func(g) -> bool: return not is_instance_valid(g) or g.state == DEAD).size()
		check("łańcuch Zimowego Oddechu", dead == _frost.size(), "%d / %d" % [dead, _frost.size()])
		# okno Mapy Nawii: Władca za serca bogów
		var player = _world.player
		var window = _world.hud.nawia_window
		window.open()
		var entry: Dictionary = window._gods["horde"]
		for god: String in _P.ORDER:
			while player.inventory.count_of(_P.heart(god)) > 0:
				player.inventory.remove_item(_P.heart(god), 1)
		window._refresh_gods()
		check("Władca bez serc zablokowany", entry["fight"].disabled)
		check("wybór Pomroku widoczny", window._pomrok_row.visible)
		for god: String in _P.ORDER:
			player.inventory.add_item(_P.heart(god), 1)
		window._refresh_gods()
		check("serca bogów otwierają Władcę", not entry["fight"].disabled)
		check("zapłata serc", _P.pay_lord(player.inventory) and _P.ORDER.all(func(god: String) -> bool:
				return player.inventory.count_of(_P.heart(god)) == 0))
	if _frame == 1584:
		print("WYNIK: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
		quit(1 if _fails > 0 else 0)
	return false
