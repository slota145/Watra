class_name ActionBars
extends VBoxContainer
## Paski szybkiego wyboru na dole ekranu (dane w Player.hotbar):
## - umiejętności (LPM, PPM, Q, E, R, Z, X) - układ zależy od założonej broni; na slotach widać odnowienie
##   (wskazówka zegara i sekundy), brak many (niebieskawy slot), a w czasie okna combo świecą sloty umiejętności,
##   które zadziałają inaczej (atak - dodatkowy cios, Dymne Wybuchy - od razu 9 wybuchów; kurczący się pierścień
##   pokazuje, ile okna zostało), Mgnienie świeci w trakcie Młynka,
## - przedmioty (1-0) z liczbą sztuk w plecaku; gdy się skończą, slot zostaje przygaszony z zerem.
## Umiejętności przeciąga się z okna umiejętności (K), przedmioty z plecaka; między slotami - zamiana miejscami.
## PPM na slocie albo przeciągnięcie poza pasek opróżnia slot, LPM na przedmiocie go używa.

const SKILL_SIZE := 22.0
const ITEM_SIZE := 20.0
const EMPTY := Color(1, 1, 1, 0.35)
const NO_MANA := Color(0.55, 0.65, 1.0)
const LOCKED := Color(0.3, 0.3, 0.35)

var _player: Player
var _skill_slots: Array[HotbarSlot] = []
var _item_slots: Array[HotbarSlot] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)
	var skill_row := HBoxContainer.new()
	skill_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skill_row.add_theme_constant_override("separation", 2)
	skill_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skill_row)
	for i in Hotbar.SKILL_KEYS.size():
		var slot := HotbarSlot.new(SKILL_SIZE, Hotbar.SKILL_KEYS[i])
		slot.drag_data = func() -> Variant: return _drag_skill(i)
		slot.can_drop = func(data: Variant) -> bool: return _can_drop_skill(data)
		slot.drop = func(data: Variant) -> void: _drop_skill(i, data)
		slot.dragged_away = func() -> void: _set_skill(i, "")
		slot.cleared = func() -> void: _set_skill(i, "")
		skill_row.add_child(slot)
		_skill_slots.append(slot)
	var item_row := HBoxContainer.new()
	item_row.alignment = BoxContainer.ALIGNMENT_CENTER
	item_row.add_theme_constant_override("separation", 2)
	item_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item_row)
	for i in Hotbar.ITEM_SLOTS:
		var slot := HotbarSlot.new(ITEM_SIZE, Hotbar.ITEM_KEYS[i])
		slot.drag_data = func() -> Variant: return _drag_item(i)
		slot.can_drop = func(data: Variant) -> bool: return _can_drop_item(data)
		slot.drop = func(data: Variant) -> void: _drop_item(i, data)
		slot.dragged_away = func() -> void: _set_item(i, "")
		slot.cleared = func() -> void: _set_item(i, "")
		slot.clicked = func() -> void:
			if _player != null:
				_player.use_hotbar_item(i)
		item_row.add_child(slot)
		_item_slots.append(slot)


func setup(player: Player) -> void:
	_player = player
	player.hotbar.changed.connect(refresh)
	player.inventory.changed.connect(_refresh_items)
	player.skills.changed.connect(_refresh_skills)
	player.equipment.changed.connect(_refresh_skills)
	refresh()


func refresh() -> void:
	_refresh_skills()
	_refresh_items()


func _refresh_skills() -> void:
	if _player == null:
		return
	var weapon_type := _player.stats.weapon_type()
	var bar := _player.hotbar.skill_bar(weapon_type)
	for i in _skill_slots.size():
		var slot := _skill_slots[i]
		var id := bar[i]
		var key := Hotbar.SKILL_KEYS[i]
		if id == "":
			slot.icon.texture = null
			slot.tooltip_text = "Pusty slot [%s]\nPrzeciągnij tu umiejętność z okna umiejętności (K)." % key
			continue
		slot.icon.texture = _attack_icon() if id == Hotbar.ATTACK else Hotbar.skill_icon(id)
		slot.tooltip_text = _skill_tooltip(id, key, weapon_type)


## Zwykły atak pokazuje ikonę założonej broni.
func _attack_icon() -> Texture2D:
	var weapon := _player.equipment.get_item("weapon")
	return Items.get_data(weapon)["icon"] if weapon != "" else Hotbar.ATTACK_ICON


func _skill_tooltip(id: String, key: String, weapon_type: String) -> String:
	if id == Hotbar.ATTACK:
		var combo := _player.skills.combo_for(weapon_type)
		var text := "%s [%s]\nZwykły atak założoną bronią w stronę kursora." % [Hotbar.ATTACK_NAME, key]
		if combo != "":
			text += "\nZaraz po uderzeniu: %s (%s)" % [Skills.get_data(combo)["name"], Skills.mana_cost_text(combo)]
		return text
	var data := Skills.get_data(id)
	if _player.skills.level_of(id) <= 0:
		return "%s [%s] - nieodblokowana (K)" % [data["name"], key]
	return "%s [%s]  •  %s\n%s" % [data["name"], key, Skills.mana_cost_text(id), data["description"]]


func _refresh_items() -> void:
	if _player == null:
		return
	for i in _item_slots.size():
		var slot := _item_slots[i]
		var id := _player.hotbar.items[i]
		if id == "":
			slot.icon.texture = null
			slot.count_label.text = ""
			slot.modulate = Color.WHITE
			slot.tooltip_text = "Pusty slot [%s]\nPrzeciągnij tu przedmiot z plecaka (I)." % Hotbar.ITEM_KEYS[i]
			continue
		var count := _player.inventory.count_of(id)
		slot.icon.texture = Items.get_data(id)["icon"]
		slot.count_label.text = str(count)
		slot.modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.45)
		slot.tooltip_text = "%s [%s]\n%s" % [Items.get_data(id)["name"], Hotbar.ITEM_KEYS[i], Items.describe(id)]


func _process(_delta: float) -> void:
	if _player == null:
		return
	var weapon_type := _player.stats.weapon_type()
	var bar := _player.hotbar.skill_bar(weapon_type)
	var combo := _player.combo_ready()
	for i in _skill_slots.size():
		var slot := _skill_slots[i]
		var id := bar[i]
		if id == "" or id == Hotbar.ATTACK:
			slot.set_cooldown(0.0, 0.0)
			slot.set_highlight(combo and id == Hotbar.ATTACK)
			slot.icon.modulate = Color.WHITE
			continue
		var cooldown := _player.cooldown_of(id)
		slot.set_cooldown(cooldown.x, cooldown.y)
		# umiejętność, która teraz zadziała jako combo (np. Dymne Wybuchy zaraz po innej umiejętności)
		var chained := _player.combo_with(id) or (id == "flicker" and _player.is_whirling() and cooldown.x <= 0.0)
		slot.set_highlight(chained)
		slot.combo_fraction = _player.combo_fraction() if _player.combo_with(id) else 0.0
		if _player.skills.level_of(id) <= 0:
			slot.icon.modulate = LOCKED
		elif _player.mana < Skills.mana_cost(id):
			slot.icon.modulate = NO_MANA
		else:
			slot.icon.modulate = Color.WHITE


# ---------------------------------------------------------------- przeciąganie
## Dane przeciągania: {"skill": id} - z okna umiejętności, {"skill_slot": i} - z paska,
## {"hotbar_item": i} - przedmiot z paska, {"inventory": Inventory, "index": i} - z plecaka (jak w oknie ekwipunku).
func _drag_skill(index: int) -> Variant:
	if _player == null or _player.hotbar.skill_bar(_player.stats.weapon_type())[index] == "":
		return null
	Sfx.play("ui_click")
	return {"skill_slot": index}


func _can_drop_skill(data: Variant) -> bool:
	if _player == null or not data is Dictionary:
		return false
	if data.has("skill_slot"):
		return true
	if not data.has("skill"):
		return false
	var id: String = data["skill"]
	return id == Hotbar.ATTACK or Skills.get_data(id).get("weapon", "") == _player.stats.weapon_type()


func _drop_skill(index: int, data: Variant) -> void:
	var weapon_type := _player.stats.weapon_type()
	if data.has("skill_slot"):
		var bar := _player.hotbar.skill_bar(weapon_type)
		_player.hotbar.set_skill(weapon_type, index, bar[data["skill_slot"]])
	else:
		_player.hotbar.set_skill(weapon_type, index, data["skill"])
	Sfx.play("pickup")


func _set_skill(index: int, id: String) -> void:
	if _player == null:
		return
	_player.hotbar.set_skill(_player.stats.weapon_type(), index, id)
	Sfx.play("ui_close")


func _drag_item(index: int) -> Variant:
	if _player == null or _player.hotbar.items[index] == "":
		return null
	Sfx.play("ui_click")
	return {"hotbar_item": index}


func _can_drop_item(data: Variant) -> bool:
	if _player == null or not data is Dictionary:
		return false
	if data.has("hotbar_item"):
		return true
	if not data.has("inventory"):
		return false
	var slot: Dictionary = data["inventory"].slots[data["index"]]
	return not slot.is_empty() and Items.is_usable(slot["id"])


func _drop_item(index: int, data: Variant) -> void:
	if data.has("hotbar_item"):
		_player.hotbar.swap_items(data["hotbar_item"], index)
	else:
		_player.hotbar.set_item(index, data["inventory"].slots[data["index"]]["id"])
	Sfx.play("pickup")


func _set_item(index: int, id: String) -> void:
	if _player == null:
		return
	_player.hotbar.set_item(index, id)
	Sfx.play("ui_close")
