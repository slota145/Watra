extends SceneTree
## Paski szybkiego wyboru i efekty: domyślne mikstury pod 1 i 2, mikstury na start nowej postaci, klawisze 1-0,
## układ umiejętności zależny od broni (LPM, PPM, Q...), uderzenie i atak ze slotów, combo, odnowienie,
## zapis paska, starsze zapisy bez paska, interakcja pod F, tryb deweloperski na F1-F4 i lista efektów.

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


func check(name: String, ok: bool, info := "") -> void:
	print("%s %s %s" % ["OK  " if ok else "FAIL", name, info])
	if not ok:
		_fails += 1


func _action(name: String, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	return event


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var p = _world.player
	var hud = _world.hud
	if _frame == 5:
		var bar = p.hotbar
		check("domyślne mikstury na pasku", bar.items[0] == "health_potion" and bar.items[1] == "mana_potion" and bar.items[2] == "")
		check("domyślne umiejętności miecza", bar.skill_bar("melee") == (["attack", "whirlwind", "lunge", "", "", "", ""] as Array[String]),
				str(bar.skill_bar("melee")))
		check("osobny układ łuku", bar.skill_bar("bow")[1] == "multishot" and bar.skill_bar("bow")[2] == "seeker")
		p.give_starting_items()
		check("mikstury na start", p.inventory.count_of("health_potion") == 5 and p.inventory.count_of("mana_potion") == 5)
		hud.action_bars.refresh()  # zmiany plecaka pasek przelicza raz na klatkę (ActionBars._queue_refresh)
		check("pasek pokazuje liczbę", hud.action_bars._item_slots[0].count_label.text == "5", hud.action_bars._item_slots[0].count_label.text)
		check("7 slotów umiejętności i 10 przedmiotów", hud.action_bars._skill_slots.size() == 7 and hud.action_bars._item_slots.size() == 10)
		# klawisz 1 - mikstura życia (przy pełnym zdrowiu nie zużywa)
		p.health = 10
		p._unhandled_input(_action("item_1", true))
		check("klawisz 1 pije miksturę", p.inventory.count_of("health_potion") == 4 and p.health > 10)
		# przedmiot na slot 5 i zamiana miejscami
		p.inventory.add_item("guard_horn", 1)
		bar.set_item(4, "guard_horn")
		bar.swap_items(4, 0)
		check("zamiana slotów przedmiotów", bar.items[0] == "guard_horn" and bar.items[4] == "health_potion")
		bar.swap_items(4, 0)
		# umiejętności: uderzenie ze slotu Q, atak z LPM, combo po uderzeniu
		# umiejętności miecza odblokowują węzły drzewka (punkty z poziomów)
		p.skills.character_level = 5
		for node in ["lunge", "crescent", "whirlwind"]:
			p.skills.take("melee", node)
		p.mana = 100.0
		p._unhandled_input(_action("skill_q", true))
		p._input(_action("skill_q", false))
		check("Q - uderzenie", p._strike_request)
		p._strike_request = false
		p._unhandled_input(_action("attack", true))
		check("LPM trzyma atak", p._attack_held)
		p._input(_action("attack", false))
		check("puszczenie LPM", not p._attack_held)
		# atak przełożony na E, a uderzenie na LPM
		bar.set_skill("melee", 3, "attack")
		check("przełożenie ataku na E", bar.skill_bar("melee")[3] == "attack" and bar.skill_bar("melee")[0] == "")
		bar.set_skill("melee", 0, "lunge")
		check("uderzenie na LPM (zamiana z Q)", bar.skill_bar("melee")[0] == "lunge" and bar.skill_bar("melee")[2] == "")
		p._unhandled_input(_action("skill_e", true))
		check("E trzyma atak", p._attack_held)
		p._input(_action("skill_e", false))
		p._combo_window = 1.0
		p._unhandled_input(_action("skill_e", true))
		p._input(_action("skill_e", false))
		check("atak w oknie combo to dodatkowy cios", p._combo_request and not p._attack_held)
		p._combo_request = false
		p._combo_window = 0.0
		# odnowienie uderzenia widać na slocie
		p._strike_cooldown = 1.5
		p._strike_cooldown_total = 2.5
		var cd: Vector2 = p.cooldown_of("lunge")
		check("odnowienie uderzenia", is_equal_approx(cd.x, 1.5) and is_equal_approx(cd.y, 2.5))
		# zapis i wczytanie paska
		var saved: Dictionary = p.hotbar.get_save_data()
		var copy = load("res://scripts/hotbar.gd").new()
		copy.load_save_data(JSON.parse_string(JSON.stringify(saved)))
		check("zapis paska", copy.items == bar.items and copy.skill_bar("melee") == bar.skill_bar("melee"))
		copy.load_save_data({"items": ["iron_ore", "health_potion"], "skills": {"melee": ["multishot", "attack"]}})
		check("zapis odrzuca złe wpisy", copy.items[0] == "" and copy.items[1] == "health_potion" \
				and copy.skill_bar("melee")[0] == "" and copy.skill_bar("melee")[1] == "attack")
		check("starszy zapis bez paska", load("res://scripts/hotbar.gd").new().items[1] == "mana_potion")
		# wszystko wszędzie: mikstura pod R, uderzenie pod 3, umiejętność innej broni czeka na pasku 1-0
		var Hb = load("res://scripts/hotbar.gd")
		bar.put("melee", 4, "health_potion")
		check("mikstura na pasku umiejętności (przeniesiona z 1)", bar.skill_bar("melee")[4] == "health_potion" and bar.items[0] == "")
		p.health = 10
		var potions: int = p.inventory.count_of("health_potion")
		p._unhandled_input(_action("skill_r", true))
		p._input(_action("skill_r", false))
		check("R pije miksturę", p.inventory.count_of("health_potion") == potions - 1)
		bar.put("melee", 9, "lunge")
		check("uderzenie pod 3 (przeniesione z LPM)", bar.items[2] == "lunge" and bar.skill_bar("melee")[0] == "")
		p._strike_cooldown = 0.0
		p._unhandled_input(_action("item_3", true))
		p._input(_action("item_3", false))
		check("3 - uderzenie", p._strike_request)
		p._strike_request = false
		check("na pasek 1-0 pasuje umiejętność innej broni", Hb.fits("multishot", 10, "melee") and not Hb.fits("multishot", 2, "melee"))
		bar.put("melee", 10, "multishot")
		p._skill_held = false
		p._unhandled_input(_action("item_4", true))
		p._input(_action("item_4", false))
		check("umiejętność innej broni czeka", not p._skill_held and not p._attack_held)
		check("przygaszona na pasku", hud.action_bars._item_slots[3].tooltip_text.contains("działa z bronią"))
		bar.move("melee", 4, 7)
		check("zamiana między paskami", bar.items[0] == "health_potion" and bar.skill_bar("melee")[4] == "")
		bar.move("melee", 10, 2)
		check("umiejętność innej broni nie wejdzie na górny pasek", bar.skill_bar("melee")[2] == "" and bar.items[3] == "multishot")
		var mixed = Hb.new()
		mixed.load_save_data(JSON.parse_string(JSON.stringify(bar.get_save_data())))
		check("zapis mieszanych pasków", mixed.items == bar.items and mixed.skill_bar("melee") == bar.skill_bar("melee"))
		# interakcja pod F
		var interact: InputEventKey = InputMap.action_get_events("interact")[0]
		check("interakcja pod F", interact.physical_keycode == KEY_F)
		# tryb deweloperski na klawiszach F
		hud.set_dev_mode(true)
		var gold: int = p.stats.gold
		var f1 := InputEventKey.new()
		f1.physical_keycode = KEY_F1
		f1.pressed = true
		hud._handle_dev_keys(f1)
		check("F1 daje złoto", p.stats.gold == gold + hud.DEV_GOLD)
		var zero := InputEventKey.new()
		zero.physical_keycode = KEY_0
		zero.pressed = true
		check("0 nie jest już skrótem deweloperskim", not hud._handle_dev_keys(zero))
		hud.set_dev_mode(false)
		# efekty: premia, osłabienie, poziom Watry
		p.boons.grant("stew")
		p.apply_poison(3.0, 4.0)
		p.boons.ember = 400
		var SE = load("res://scripts/status_effects.gd")
		var effects: Array = SE.list(p)
		var names := effects.map(func(e: Dictionary) -> String: return e["name"])
		check("efekty: posiłek, trucizna, Watra", "Gulasz myśliwski" in names and "Trucizna" in names and "Watra - poziom 2" in names, str(names))
		check("trucizna jako osłabienie", effects[names.find("Trucizna")]["kind"] == "bad")
		check("czas pod ikoną", SE.time_text(900.0) == "15m" and SE.time_text(4.2) == "5s" and SE.time_text(-1.0) == "")
	if _frame == 20:
		var row = hud.status_row
		var shown := 0
		for cell: Control in row._cells:
			if cell.visible:
				shown += 1
		check("ikony efektów pod paskami", shown >= 3, "%d" % shown)
		print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
		quit()
	return false
