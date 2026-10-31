extends SceneTree
## Encyklopedia: dane (legendy z bossów i skarbca lochów, bossowie, potwory z grafiką i krainą, zioła, przedmioty),
## odkrywanie (przedmiot w plecaku - także wylosowany na bazie legendy; pokonany potwór), zapis, okno (zakładki,
## zakryte wpisy "???", licznik, szczegóły) i tryb deweloperski (wszystko widać, kliknięcie daje przedmiot).

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


func _process(_d: float) -> bool:
	if _world == null:
		return false
	_frame += 1
	if _frame != 5:
		return false
	var p = _world.player
	var Codex = load("res://scripts/codex.gd")
	_check_data(Codex)
	# odkrywanie przedmiotów: wylosowana legenda liczy się jako jej baza
	var legend: String = load("res://scripts/loot.gd").legendary_at_level("ring_gruzlog", 5)
	check("legenda nieznana", not p.codex.is_item_known("ring_gruzlog"))
	p.inventory.add_item(legend, 1)
	check("legenda odkryta po zdobyciu", p.codex.is_item_known("ring_gruzlog"))
	p.inventory.add_item("herb_wort", 1)
	check("zioło odkryte", p.codex.is_item_known("herb_wort"))
	# pokonany potwór
	var enemy = null
	for e in _world.get_tree().get_nodes_in_group("enemies"):
		if e.scene_file_path.ends_with("goblin.tscn"):
			enemy = e
			break
	enemy.take_damage(99999, enemy.global_position + Vector2(10, 0))
	check("potwór odkryty po pokonaniu", p.codex.kills_of("goblin") == 1)
	# zapis
	var copy = Codex.new()
	copy.load_save_data(JSON.parse_string(JSON.stringify(p.codex.get_save_data())))
	check("zapis encyklopedii", copy.is_item_known("ring_gruzlog") and copy.kills_of("goblin") == 1)
	copy.free()
	_check_window(p)
	print("WYNIK: ", "OK" if _fails == 0 else "%d bledow" % _fails)
	quit()
	return false


func _check_data(Codex) -> void:
	var legends: Array = Codex.legends()
	check("legendy: bossowie i skarbiec", legends.has("ring_gruzlog") and legends.has("legend_hydra_bow")
			and legends.has("legend_perun_crown") and legends.size() >= 50, "%d" % legends.size())
	var no_icon := legends.filter(func(id: String) -> bool: return load("res://scripts/items.gd").get_data(id).get("icon") == null)
	check("legendy mają ikony", no_icon.is_empty(), str(no_icon))
	check("źródła legend", Codex.legend_source("ring_gruzlog") == "Gruzłog, Wódz Goblinów"
			and Codex.legend_source("legend_endless_amulet") == Codex.VAULT_SOURCE)
	var unknown_source := legends.filter(func(id: String) -> bool: return Codex.legend_source(id) == "nieznane")
	check("każda legenda ma źródło", unknown_source.is_empty(), str(unknown_source))
	var bosses: Array = Codex.bosses()
	check("bossowie", bosses.has("goblin_chief") and bosses.has("hydra") and bosses.has("necromancer") and not bosses.has("goblin"), str(bosses.size()))
	var monsters: Array = Codex.monsters()
	var broken := (bosses + monsters).filter(func(id: String) -> bool: return Codex.monster_info(id).get("texture") == null)
	check("potwory mają grafikę", broken.is_empty(), str(broken))
	var missing := []
	for scene: String in load("res://scripts/levels.gd").HOME:
		if not Codex.MONSTERS.has(scene):
			missing.append(scene)
	check("wszystkie potwory w encyklopedii", missing.is_empty(), str(missing))
	check("zioła i mikstury", Codex.herbs().size() == 12)
	check("przedmioty", Codex.items().size() >= 100 and Codex.items().has("short_bow"))


func _check_window(p) -> void:
	var hud = _world.find_child("HUD", true, false)
	var window = hud.codex_window
	window.toggle()
	check("okno otwarte", window.visible)
	window._show_tab("legends")
	check("licznik", window._counter.text.begins_with("Odkryto: 1 /"), window._counter.text)
	window._show_details("ring_alpha")
	check("zakryta legenda", window._name.text == "???" and window._body.text.contains("Źródło"))
	window._show_details("ring_gruzlog")
	check("odkryta legenda: opis i źródło", window._name.text != "???" and window._body.text.contains("Gruzłog"))
	window._show_tab("monsters")
	window._show_details("goblin")
	check("potwór: kraina i pokonani", window._body.text.contains("Gobliński Las") and window._body.text.contains("Pokonano:[/color] 1"))
	window._show_tab("bosses")
	window._show_details("goblin_chief")
	check("zakryty boss", window._name.text == "???")
	# tryb deweloperski: wszystko widać, kliknięcie daje przedmiot
	hud.dev_mode = true
	window._show_tab("bosses")
	window._show_details("hydra")
	check("tryb deweloperski: boss widoczny", window._name.text == "Hydra z Bagien" and window._body.text.contains("Legendy"))
	window._show_tab("legends")
	var before: int = p.inventory.count_of("ring_alpha")
	var given: String = window.give("legend_hydra_bow")
	check("tryb deweloperski: legenda do plecaka", load("res://scripts/items.gd").get_data(given).get("base", "") == "legend_hydra_bow"
			and p.inventory.count_of(given) == 1 and before == 0)
	check("tryb deweloperski: licznik pełny", window._counter.text.begins_with("Odkryto: %d / %d" % [window.entries().size(), window.entries().size()]))
	hud.dev_mode = false
	window.toggle()
