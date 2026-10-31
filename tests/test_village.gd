extends SceneTree
## Funkcje osady: budowle z menu, premie (posiłek, błogosławieństwo, łaźnia), bestiariusz, przekuwanie,
## róg straży, łucznicy na wieżach, podatek, wędrowny kupiec. Na koniec zrzuty budowli.

var _world: Node
var _frame := 0
var _out := ""
var _fails := 0
var _cam: Camera2D
var _shots := []
var VS
var LOOT
var BASES

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else ""
	root.get_node("Game").save_path = "user://test_savegame.json"
	_setup.call_deferred()


func _setup() -> void:
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "forest", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)


func check(name: String, ok: bool, info := "") -> void:
	print("%s: %s %s" % [name, "OK" if ok else "BLAD", info])
	if not ok:
		_fails += 1


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	var s = _world._settlement
	var p = _world.player
	if _frame == 4:
		VS = load("res://scripts/village_services.gd")
		LOOT = load("res://scripts/loot.gd")
		BASES = load("res://scripts/item_bases.gd")
	if _frame == 5:
		for project in ["barracks", "infirmary", "chapel", "houses", "market", "bathhouse", "armory"]:
			s.set_project(project, "built")
		check("budowle", s.project_state("chapel") == "built" and s.project_state("armory") == "built")
		# premie
		var hp0: int = p.stats.max_health()
		p.boons.grant("stew")
		check("gulasz +10% HP", p.stats.max_health() == roundi(hp0 * 1.1), "%d -> %d" % [hp0, p.stats.max_health()])
		p.boons.grant("roast")
		check("jeden posiłek naraz", p.boons.active["meal"]["id"] == "roast" and p.stats.max_health() == hp0)
		p.boons.grant("bless_might")
		check("błogosławieństwo", absf(p.stats.damage_multiplier() - 1.05) < 0.001, str(p.stats.damage_multiplier()))
		s.on_rest()
		check("łaźnia -> wypoczęty", p.boons.has_group("rest"))
		var saved: Dictionary = p.boons.get_save_data()
		p.boons.load_save_data(saved)
		check("zapis premii", p.boons.active.size() == 3)
		# lecznica
		var inside: float = s.regen_bonus(s._px(Vector2(33, 20)))
		var outside: float = s.regen_bonus(s._px(Vector2(33, 50)))
		check("lecznica regeneracja", inside > 0.0 and outside == 0.0, "%s/%s" % [inside, outside])
		# bestiariusz
		p.storage.add_item("goblin_heart", 10)
		var rows: Array = VS.offers("bestiary", p, s._smith)["rows"]
		var msg: String = rows[0]["action"].call()
		check("bestiariusz", p.boons.rank("goblin") == 1 and p.count_owned("goblin_heart") == 0, msg)
		var goblin = null
		for e in root.get_tree().get_nodes_in_group("enemies"):
			if e.get_script().resource_path.ends_with("goblin.gd"):
				goblin = e
				break
		check("bestiariusz mnożnik", goblin != null and absf(p.boons.damage_multiplier(goblin) - 1.03) < 0.001)
		# posiłek przez okno ofert
		p.stats.add_gold(1000)
		p.storage.add_item("meat", 5)
		var meal: Array = VS.offers("meals", p, s._smith)["rows"]
		meal[0]["action"].call()
		check("zakup gulaszu", p.boons.active["meal"]["id"] == "stew" and p.count_owned("meat") == 3)
		# przekuwanie
		var item: String = LOOT.generate(LOOT.base_for(BASES.LINES.keys()[0], 10), "rare", 10)
		p.inventory.add_item(item, 1)
		p.storage.add_item("iron_ore", 3)
		var forge: Array = VS.offers("reforge", p, s._smith)["rows"]
		check("przekuwanie lista", forge.size() >= 1)
		if forge.size() >= 1:
			var r: String = forge[0]["action"].call()
			check("przekuwanie", p.inventory.count_of(item) == 0 and p.count_owned("iron_ore") == 0, r)
		# róg straży
		p.inventory.add_item("guard_horn", 1)
		p.use_item("guard_horn")
		var allies := 0
		for n in p.get_parent().get_children():
			if n.get_script() == load("res://scripts/soldier_ally.gd"):
				allies += 1
		check("róg straży", allies == 2)
		# łucznicy na wieżach
		var archers := 0
		for t in s._tower_sprites:
			for c in t.get_children():
				if c.get_script() == load("res://scripts/tower_archer.gd"):
					archers += 1
		check("łucznicy na wieżach", archers == 4)
		# podatek i kupiec
		var gold0: int = p.stats.gold
		s._collect_tax()
		check("podatek", p.stats.gold > gold0)
		check("kupiec ma towar", s._traveler != null and s._traveler.shop_sells.size() == mini(s.MERCHANT_STOCK, s.MERCHANT_POOL.size()),
				str(s._traveler.shop_sells if s._traveler != null else "brak kupca"))
		check("kowal przekuwa", "reforge" in s._smith.services)
		var shooters := 0
		for t in s._tower_sprites:
			for c in t.get_children():
				if c.get_script() == load("res://scripts/tower_archer.gd") and c.can_shoot:
					shooters += 1
		check("łucznicy strzelają", shooters == 4)
		s.celebrate()
		check("święto", s._celebration.size() == 4)
		# Watra: ofiary ze złota i przedmiotów podnoszą poziom, dar Watry, podatek rośnie z poziomem, zapis żaru
		var watra = _world.hud.watra_window
		check("watra stoi", s._watra != null and s._watra_glow != null)
		watra.open()
		check("okno watry", watra.visible and p.boons.watra_level() == 1)
		p.stats.add_gold(5000)
		watra._offer_gold(2000)
		watra._offer_gold(2000)
		check("watra poziom 2", p.boons.ember == 400 and p.boons.watra_level() == 2, "żar %d" % p.boons.ember)
		var junk: String = LOOT.generate(LOOT.base_for(BASES.LINES.keys()[0], 10), "magic", 10)
		p.inventory.add_item(junk, 1)
		var ember0: int = p.boons.ember
		for i in p.inventory.slots.size():
			if not p.inventory.slots[i].is_empty() and p.inventory.slots[i]["id"] == junk:
				watra._burn(i, 1)
		check("spalenie przedmiotu", p.inventory.count_of(junk) == 0 and p.boons.ember > ember0)
		watra._take_gift("watra_fire", p.boons.gold_cost("watra_fire", p.stats.level))
		check("dar watry", p.boons.has_group("watra"))
		var gold1: int = p.stats.gold
		s._collect_tax()
		var taxed: int = p.stats.gold - gold1
		check("podatek z watrą", taxed > s.TAX_GOLD + s.TAX_PER_LEVEL * (p.stats.level - 1), "%d zł" % taxed)
		var ember1: int = p.boons.ember
		p.boons.load_save_data(p.boons.get_save_data())
		check("zapis żaru", p.boons.ember == ember1 and p.boons.watra_level() == 2)
		var carriers := 0
		for n in s._entities.get_children():
			if "carried_texture" in n and n.carried_texture == s._tex("firewood"):
				carriers += 1
		check("noszący drewno", carriers == 2, "%d" % carriers)
		watra.visible = false
		_cam = Camera2D.new()
		_world.add_child(_cam)
		_cam.make_current()
		_shots = [Vector2(32, 19), Vector2(3.5, 30.5), Vector2(8.5, 47.5), Vector2(61.5, 32.5), Vector2(42.5, 36.5), Vector2(50, 27), Vector2(25, 28.5)]
	if _frame > 10 and not _shots.is_empty():
		var i := (_frame - 10) / 20
		if i >= _shots.size():
			print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
			quit()
			return false
		if (_frame - 10) % 20 == 1:
			_cam.global_position = s._px(_shots[i])
			_cam.zoom = Vector2(2, 2)
		if (_frame - 10) % 20 == 18 and _out != "":
			root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [_out, i])
	return false
