extends Node
## Globalny stan gry (autoload "Game"): przełączanie scen oraz zapis i odczyt gry.
## Zapisów może być dowolnie wiele (user://saves/<id>.json): każdy to plik JSON z ziarnem mapy
## (świat generuje się z niego identycznie), krainą, w której jest gracz, stanem gracza i stanem
## każdej odwiedzonej krainy. Obok leży mały plik z opisem (nazwa, data, poziom - do listy
## zapisów bez wczytywania całości) i miniaturka ekranu z chwili zapisu.
## Przejście do innej krainy działa jak szybkie wczytanie z pamięci - z wygaszeniem ekranu.

## Dawny pojedynczy zapis - przy pierwszym uruchomieniu kopiowany do listy zapisów (oryginał zostaje).
const SAVE_PATH := "user://savegame.json"
const SAVES_DIR := "user://saves"
## Testy zapisują osobno - nigdy w folderze zapisów gracza.
const TEST_SAVES_DIR := "user://test_saves"
const LEGACY_SLOT := "stary_zapis"
const THUMB_SIZE := Vector2i(160, 90)
const SAVE_VERSION := 1
const WORLD_SCENE := "res://scenes/world.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

## Plik zapisu - testy podmieniają go na osobny, żeby nie ruszać zapisu gracza
## (wtedy także lista zapisów trafia do osobnego folderu testowego).
var save_path := SAVE_PATH:
	set(value):
		save_path = value
		saves_dir = SAVES_DIR if value == SAVE_PATH else TEST_SAVES_DIR
var saves_dir := SAVES_DIR
## Zapis, z którego gramy (wczytany albo ostatnio zapisany) - podpowiadany przy zapisie.
var current_slot := ""
## Dane zapisu czekające na wczytanie przez świat po zmianie sceny.
var _pending_load: Dictionary = {}
var _fade: ColorRect
var _traveling := false
## Postać wybrana do nowej gry (zapis pamięta ją w danych gracza).
var hero := "wojciech"


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # wygaszanie ekranu (tween) w _process
	_migrate_legacy_save()


func new_game(hero_id := "") -> void:
	if hero_id != "":
		hero = hero_id
	current_slot = ""
	_pending_load = {}
	_change_scene(WORLD_SCENE)


## Wczytuje zapis o danym id (domyślnie najnowszy).
func load_game(slot := "") -> bool:
	if slot == "":
		slot = latest_slot()
	var data := read_save(slot)
	if data.is_empty():
		return false
	current_slot = slot
	_pending_load = data
	_change_scene(WORLD_SCENE)
	return true


## "Kontynuuj" w menu głównym - najnowszy zapis.
func continue_game() -> bool:
	return load_game(latest_slot())


## Przejście do innej krainy (albo teleport): `data` to bieżący stan gry z ustawionym
## "zone" i "arrive" (gdzie postać się pojawi).
func travel(data: Dictionary) -> void:
	if _traveling:
		return
	_traveling = true
	_pending_load = data
	var tween := _fade_rect().create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.3)
	tween.tween_callback(_change_scene.bind(WORLD_SCENE))


## Wołane przez świat po zbudowaniu krainy - ekran się rozjaśnia.
func end_transition() -> void:
	_traveling = false
	if _fade == null or _fade.color.a <= 0.0:
		return
	_fade.create_tween().tween_property(_fade, "color:a", 0.0, 0.4)


func _fade_rect() -> ColorRect:
	if _fade == null:
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		_fade = ColorRect.new()
		_fade.color = Color(0.02, 0.02, 0.04, 0.0)
		_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fade)
	return _fade


func go_to_menu() -> void:
	_change_scene(MENU_SCENE)


func quit_game() -> void:
	get_tree().quit()


## Zwraca (i zużywa) dane do wczytania - pusty słownik oznacza nową grę.
func take_pending_load() -> Dictionary:
	var data := _pending_load
	_pending_load = {}
	return data


func has_save() -> bool:
	return latest_slot() != ""


## Zapisuje grę: `slot` = id istniejącego zapisu (nadpisanie) albo "" (nowy zapis).
## Zwraca id zapisu albo "", gdy się nie udało.
func save_game(data: Dictionary, save_name := "", slot := "", thumbnail: Image = null) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(saves_dir))
	if slot == "":
		slot = "zapis_%d" % int(Time.get_unix_time_from_system() * 1000.0)
	var path := _slot_path(slot, "json")
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	# poprzednia wersja tego zapisu zostaje jako kopia zapasowa (.bak)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(_slot_path(slot, "bak")))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Nie udało się zapisać gry: %s" % error_string(FileAccess.get_open_error()))
		return ""
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var player: Dictionary = data.get("player", {})
	var meta := {
		"name": save_name if save_name != "" else default_save_name(data),
		"saved_at": data["saved_at"],
		"saved_unix": Time.get_unix_time_from_system(),
		"level": int(player.get("stats", {}).get("level", 1)),
		"zone": str(data.get("zone", "forest")),
		"hero": str(player.get("hero", hero)),
	}
	var meta_file := FileAccess.open(_slot_path(slot, "meta.json"), FileAccess.WRITE)
	if meta_file != null:
		meta_file.store_string(JSON.stringify(meta))
	if thumbnail != null:
		var image := thumbnail.duplicate() as Image
		image.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_BILINEAR)
		image.save_png(_slot_path(slot, "png"))
	current_slot = slot
	return slot


func read_save(slot := "") -> Dictionary:
	if slot == "":
		slot = latest_slot()
	var path := _slot_path(slot, "json")
	if slot == "" or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Plik zapisu jest uszkodzony: %s" % path)
		return {}
	return parsed


## Wszystkie zapisy od najnowszego: [{"id", "name", "saved_at", "level", "zone", "hero"}].
func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	var dir := DirAccess.open(saves_dir)
	if dir == null:
		return saves
	for file in dir.get_files():
		if not file.ends_with(".meta.json"):
			continue
		var slot := file.trim_suffix(".meta.json")
		if not FileAccess.file_exists(_slot_path(slot, "json")):
			continue
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(_slot_path(slot, "meta.json")))
		if meta is Dictionary:
			meta["id"] = slot
			saves.append(meta)
	saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _save_time(a) > _save_time(b))
	return saves


## Czas zapisu do sortowania (starsze opisy mają tylko datę z dokładnością do sekundy).
func _save_time(meta: Dictionary) -> float:
	if meta.has("saved_unix"):
		return float(meta["saved_unix"])
	return Time.get_unix_time_from_datetime_string(str(meta.get("saved_at", "")))


func latest_slot() -> String:
	var saves := list_saves()
	return saves[0]["id"] if not saves.is_empty() else ""


## Miniaturka ekranu z chwili zapisu (null, jeśli jej nie ma).
func save_thumbnail(slot: String) -> Texture2D:
	var path := _slot_path(slot, "png")
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null else null


func delete_save(slot: String) -> void:
	for ext in ["json", "meta.json", "png", "bak"]:
		var path := _slot_path(slot, ext)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if current_slot == slot:
		current_slot = ""


## Podpowiadana nazwa nowego zapisu, np. "Mira - Prastary Las, poz. 7".
func default_save_name(data: Dictionary) -> String:
	var player: Dictionary = data.get("player", {})
	var hero_id := str(player.get("hero", hero))
	var level := int(player.get("stats", {}).get("level", 1))
	return "%s - %s, poz. %d" % [HeroRig.NAMES.get(hero_id, hero_id.capitalize()), Zones.zone_name(str(data.get("zone", "forest"))), level]


## Krótki opis zapisu, np. "Poziom 3  •  Gobliński Las  •  2026-10-25 20:15".
func describe_save(meta: Dictionary) -> String:
	var date := str(meta.get("saved_at", "")).substr(0, 16)
	return "Poziom %d  •  %s  •  %s" % [int(meta.get("level", 1)), Zones.zone_name(str(meta.get("zone", "forest"))), date]


func _slot_path(slot: String, ext: String) -> String:
	return "%s/%s.%s" % [saves_dir, slot, ext]


## Dawny jedyny zapis (user://savegame.json) trafia na listę jako "Stary zapis" - kopia,
## oryginał zostaje nietknięty.
func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists("%s/%s.json" % [SAVES_DIR, LEGACY_SLOT]):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return
	var previous_dir := saves_dir
	saves_dir = SAVES_DIR
	var data: Dictionary = parsed
	var saved_at := str(data.get("saved_at", ""))
	save_game(data, "Stary zapis", LEGACY_SLOT)
	# zachowujemy pierwotną datę zapisu
	var meta_path := _slot_path(LEGACY_SLOT, "meta.json")
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if meta is Dictionary and saved_at != "":
		meta["saved_at"] = saved_at
		meta["saved_unix"] = Time.get_unix_time_from_datetime_string(saved_at)
		var file := FileAccess.open(meta_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(meta))
	saves_dir = previous_dir
	current_slot = ""


func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)
