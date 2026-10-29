extends SceneTree
## Zapis i odczyt wylosowanych przedmiotów (200 przepisów): statystyki muszą wrócić identyczne.
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	var loot = load("res://scripts/loot.gd")
	var items = load("res://scripts/items.gd")
	for i in 200:
		var id: String = loot.generate("chainmail", "rare", 40)
		var before: Dictionary = items.get_data(id).duplicate(true)
		var saved: Dictionary = JSON.parse_string(JSON.stringify(loot.export_used([id])))
		items.generated.erase(id)
		loot.import(saved)
		var after: Dictionary = items.get_data(id)
		if after["stats"] != before["stats"]:
			for k in before["stats"]:
				if before["stats"][k] != after["stats"].get(k):
					print("FAIL zapis ", k, " ", var_to_str(before["stats"][k]), " -> ", var_to_str(after["stats"].get(k)))
			quit()
			return
	print("OK   zapis i odczyt 200 przedmiotów")
	quit()
