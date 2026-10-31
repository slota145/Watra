class_name ActionBars
extends VBoxContainer
## Paski szybkiego wyboru na dole ekranu (dane w Player.hotbar): górny (LPM, PPM, Q, E, R, Z, X) - układ zależy od
## założonej broni, dolny (1-0) - wspólny. Każdy slot przyjmuje umiejętność albo przedmiot do użycia:
## - umiejętność: odnowienie (wskazówka zegara i sekundy), brak many (niebieskawy slot), umiejętność innej broni
##   (na pasku 1-0) i nieodblokowana - przygaszona; w czasie okna combo świecą sloty umiejętności, które zadziałają
##   inaczej (atak - dodatkowy cios, Dymne Wybuchy - od razu 9 wybuchów; kurczący się pierścień pokazuje, ile okna
##   zostało), Mgnienie świeci w trakcie Młynka,
## - przedmiot: liczba sztuk w plecaku; gdy się skończą, slot zostaje przygaszony z zerem; LPM na slocie go używa.
## Umiejętności przeciąga się z okna umiejętności (K), przedmioty z plecaka; między slotami (także między paskami) -
## zamiana miejscami. PPM na slocie albo przeciągnięcie poza pasek opróżnia slot.

const SKILL_SIZE := 22.0
const ITEM_SIZE := 20.0
const EMPTY := Color(1, 1, 1, 0.35)
const NO_MANA := Color(0.55, 0.65, 1.0)
const LOCKED := Color(0.3, 0.3, 0.35)

var _player: Player
## Wszystkie sloty we wspólnej numeracji (Hotbar.SLOT_KEYS): 7 górnych, potem 10 dolnych.
var _slots: Array[HotbarSlot] = []
var _skill_slots: Array[HotbarSlot] = []
var _item_slots: Array[HotbarSlot] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)
	var rows: Array[HBoxContainer] = []
	for r in 2:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 2)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		rows.append(row)
	for i in Hotbar.slot_count():
		var top := i < Hotbar.SKILL_KEYS.size()
		var slot := HotbarSlot.new(SKILL_SIZE if top else ITEM_SIZE, Hotbar.SLOT_KEYS[i])
		slot.drag_data = func() -> Variant: return _drag(i)
		slot.can_drop = func(data: Variant) -> bool: return _can_drop(i, data)
		slot.drop = func(data: Variant) -> void: _drop(i, data)
		slot.dragged_away = func() -> void: _clear(i)
		slot.cleared = func() -> void: _clear(i)
		slot.clicked = func() -> void: _click(i)
		rows[0 if top else 1].add_child(slot)
		_slots.append(slot)
		(_skill_slots if top else _item_slots).append(slot)


func setup(player: Player) -> void:
	_player = player
	player.hotbar.changed.connect(refresh)
	player.inventory.changed.connect(refresh)
	player.skills.changed.connect(refresh)
	player.equipment.changed.connect(refresh)
	refresh()


func _entry(index: int) -> String:
	return _player.hotbar.entry(_player.stats.weapon_type(), index)


func refresh() -> void:
	if _player == null:
		return
	var weapon_type := _player.stats.weapon_type()
	for i in _slots.size():
		var slot := _slots[i]
		var id := _entry(i)
		var key := Hotbar.SLOT_KEYS[i]
		slot.count_label.text = ""
		slot.modulate = Color.WHITE
		if id == "":
			slot.icon.texture = null
			slot.tooltip_text = "Pusty slot [%s]\nPrzeciągnij tu umiejętność z okna umiejętności (K) albo przedmiot z plecaka (I)." % key
		elif Hotbar.is_item(id):
			var count := _player.inventory.count_of(id)
			slot.icon.texture = Items.get_data(id)["icon"]
			slot.count_label.text = str(count)
			slot.modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.45)
			slot.tooltip_text = "%s [%s]\n%s" % [Items.get_data(id)["name"], key, Items.strip_icon(Items.describe(id))]
		else:
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
	if data["weapon"] != weapon_type:
		return "%s [%s] - działa z bronią: %s" % [data["name"], key, Skills.WEAPON_NAMES[data["weapon"]].to_lower()]
	if _player.skills.level_of(id) <= 0:
		return "%s [%s] - nieodblokowana (K)" % [data["name"], key]
	return "%s [%s]  •  %s\n%s" % [data["name"], key, Skills.mana_cost_text(id), data["description"]]


func _process(_delta: float) -> void:
	if _player == null:
		return
	var weapon_type := _player.stats.weapon_type()
	var combo := _player.combo_ready()
	for i in _slots.size():
		var slot := _slots[i]
		var id := _entry(i)
		if id == "" or id == Hotbar.ATTACK or Hotbar.is_item(id):
			slot.set_cooldown(0.0, 0.0)
			slot.set_highlight(combo and id == Hotbar.ATTACK)
			slot.icon.modulate = Color.WHITE
			continue
		if Skills.get_data(id)["weapon"] != weapon_type:
			slot.set_cooldown(0.0, 0.0)
			slot.set_highlight(false)
			slot.icon.modulate = LOCKED
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
## Dane przeciągania: {"skill": id} - z okna umiejętności, {"bar_slot": i} - z paska (wspólna numeracja),
## {"inventory": Inventory, "index": i} - z plecaka (jak w oknie ekwipunku).
func _drag(index: int) -> Variant:
	if _player == null or _entry(index) == "":
		return null
	Sfx.play("ui_click")
	return {"bar_slot": index}


## Wpis, który niesie przeciągnięcie ("" - nic do położenia).
func _dragged_entry(data: Variant) -> String:
	if not data is Dictionary:
		return ""
	if data.has("bar_slot"):
		return _entry(data["bar_slot"])
	if data.has("skill"):
		return data["skill"]
	if data.has("inventory"):
		var slot: Dictionary = data["inventory"].slots[data["index"]]
		return slot["id"] if not slot.is_empty() and Hotbar.is_item(slot["id"]) else ""
	return ""


func _can_drop(index: int, data: Variant) -> bool:
	if _player == null:
		return false
	var id := _dragged_entry(data)
	return id != "" and Hotbar.fits(id, index, _player.stats.weapon_type())


func _drop(index: int, data: Variant) -> void:
	var weapon_type := _player.stats.weapon_type()
	if data.has("bar_slot"):
		_player.hotbar.move(weapon_type, data["bar_slot"], index)
	else:
		_player.hotbar.put(weapon_type, index, _dragged_entry(data))
	Sfx.play("pickup")


func _clear(index: int) -> void:
	if _player == null:
		return
	_player.hotbar.put(_player.stats.weapon_type(), index, "")
	Sfx.play("ui_close")


## LPM na slocie z przedmiotem go używa.
func _click(index: int) -> void:
	if _player != null and Hotbar.is_item(_entry(index)):
		_player.use_item(_entry(index))
