extends SceneTree
## Odrodzenie po śmierci w lochu: postać znów widoczna (zanikanie po śmierci nie trwa dalej po odrodzeniu).
var _world: Node
var _frame := 0
func _initialize() -> void:
	Engine.max_fps = 60
	root.get_node("Game").save_path = "user://test_savegame.json"
	root.get_node("Game")._pending_load = {"seed": 12345, "zone": "dungeon", "dungeon": {"climate": "catacombs", "tier": 3, "mods": [], "seed": 5, "mechanics": []}, "arrive": "start", "player": {}}
	_world = load("res://scenes/world.tscn").instantiate()
	root.add_child(_world)
func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 10:
		_world.player.health = 1
		_world.player.take_damage(9999, _world.player.global_position + Vector2(5, 0))
	if _frame == 10 + 60 * 4:
		var ok: bool = not _world.player.is_dead and is_equal_approx(_world.player.sprite.modulate.a, 1.0)
		print(("OK  " if ok else "FAIL") + " po odrodzeniu postać widoczna (alfa %.2f)" % _world.player.sprite.modulate.a)
		print("WYNIK: ", "OK" if ok else "1 bledow")
		quit()
	return false
