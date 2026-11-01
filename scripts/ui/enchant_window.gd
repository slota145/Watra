class_name EnchantWindow
extends PanelContainer
## Okno zaklinania. Środkowy rząd: kamień, zaklinany przedmiot (duża kratka) i wynik.
## Nad przedmiotem kratka na kamienie miłosierdzia (chronią poziom przy porażce),
## pod nim kratka na uświęcone kamienie (pewne wbicie III-V; używane w pierwszej kolejności).
## PPM na kamieniu albo przedmiocie - w plecaku lub założonym - wkłada go do okna,
## PPM na kratce w oknie ją opróżnia. Pasek u góry pokazuje założone przedmioty - kliknięcie wkłada przedmiot
## do okna (okno może zasłaniać sylwetkę w plecaku).
## Zaklinanie trwa kilka sekund (pasek + złote iskry), potem złoty puls przy sukcesie
## albo czerwony błysk przy porażce. Opcje: pominięcie ładowania i automat do +15.

const CHARGE_TIME := 3.0
## Narastające magiczne trzaskanie podczas ładowania (tools/sfx_synth.py, trwa tyle co ładowanie).
const CHARGE_SOUND := "res://assets/sfx/enchant_charge.ogg"
## Odstęp między kolejnymi próbami automatu (z animacją i bez niej).
const AUTO_DELAY := 0.35
const AUTO_DELAY_FAST := 0.45
const GOLD := Color(1.0, 0.82, 0.3)
const MERCY_BLUE := Color(0.45, 0.85, 1.0)
const FAIL_RED := Color(1.0, 0.3, 0.25)
const GOOD_GREEN := Color(0.55, 1.0, 0.5)
const SMALL_SLOT := Vector2(24, 24)
const BIG_SLOT := Vector2(38, 38)
const AID_SLOT := Vector2(20, 20)
const WORN_SLOT := Vector2(22, 22)
## Jak często z kratki uświęconych kamieni wylatuje iskra (s).
const SPARK_INTERVAL := 0.04

var _player: Player
var _stone_id := ""
## Zaklinany przedmiot: {"bag": indeks, "id": id} albo {"equip": miejsce, "id": id}.
var _item_ref := {}
## Czy w kratkach leżą uświęcone kamienie / kamienie miłosierdzia (biorą się z plecaka).
var _blessed_on := false
var _mercy_on := false
var _busy := false
var _auto_running := false
var _blessed_flow := false
var _spark_timer := 0.0

var _stone_slot: Panel
var _stone_icon: TextureRect
var _stone_count: Label
var _item_slot: Panel
var _item_icon: TextureRect
var _item_level: Label
var _result_icon: TextureRect
var _result_level: Label
var _blessed_slot: Panel
var _blessed_icon: TextureRect
var _blessed_label: Label
var _mercy_slot: Panel
var _mercy_icon: TextureRect
var _mercy_label: Label
var _chance_label: Label
var _current_stats: Label
var _next_stats: RichTextLabel
var _progress: ProgressBar
var _button: Button
var _skip_box: CheckBox
var _auto_box: CheckBox
var _status: Label
var _warning: Label
var _charge_fx: AnimatedSprite2D
var _fx: Control
var _pulse_radius := 0.0
var _pulse_alpha := 0.0
var _charge_sound: AudioStreamPlayer
## Pasek założonych przedmiotów: miejsce -> [kratka, ikona].
var _worn_slots := {}


func _ready() -> void:
	visible = false
	_charge_sound = AudioStreamPlayer.new()
	_charge_sound.stream = load(CHARGE_SOUND)
	_charge_sound.bus = "SFX"
	_charge_sound.volume_db = -3.0
	add_child(_charge_sound)
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	add_child(box)
	box.add_child(UiStyle.title("Zaklinanie"))
	var hint := UiStyle.label("PPM na kamieniu lub przedmiocie (w plecaku albo założonym) wkłada go tutaj.", 7, UiStyle.DIM_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var worn_row := HBoxContainer.new()
	worn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	worn_row.add_theme_constant_override("separation", 2)
	box.add_child(worn_row)
	for slot_name: String in Equipment.SLOTS:
		var parts := _make_slot(worn_row, WORN_SLOT, "")
		parts[0].gui_input.connect(_on_worn_input.bind(slot_name))
		_worn_slots[slot_name] = parts

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 6)
	box.add_child(main)

	# lewa kolumna - obecne statystyki
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 104
	main.add_child(left)
	left.add_child(UiStyle.label("Teraz", 8, UiStyle.TITLE_COLOR))
	_current_stats = UiStyle.label("", 7, UiStyle.TEXT_COLOR)
	_current_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_current_stats.custom_minimum_size.x = 104
	left.add_child(_current_stats)

	main.add_child(VSeparator.new())

	# środek - kratki
	var center := VBoxContainer.new()
	center.custom_minimum_size.x = 150
	center.add_theme_constant_override("separation", 2)
	main.add_child(center)
	_chance_label = UiStyle.label("", 10, GOLD)
	_chance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_chance_label)

	var mercy_parts := _make_aid_row(center, "Kamienie miłosierdzia - chronią poziom przy porażce")
	_mercy_slot = mercy_parts[0]
	_mercy_icon = mercy_parts[1]
	_mercy_label = mercy_parts[2]
	_mercy_slot.gui_input.connect(_on_slot_input.bind("mercy"))

	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 6)
	center.add_child(slots)
	var stone_parts := _make_slot(slots, SMALL_SLOT, "Kamień zaklinający")
	_stone_slot = stone_parts[0]
	_stone_icon = stone_parts[1]
	_stone_count = stone_parts[2]
	_stone_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stone_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_stone_slot.gui_input.connect(_on_slot_input.bind("stone"))
	slots.add_child(_arrow())
	var item_parts := _make_slot(slots, BIG_SLOT, "Przedmiot do zaklęcia")
	_item_slot = item_parts[0]
	_item_icon = item_parts[1]
	_item_level = item_parts[2]
	_item_slot.gui_input.connect(_on_slot_input.bind("item"))
	slots.add_child(_arrow())
	var result_parts := _make_slot(slots, SMALL_SLOT, "Wynik")
	_result_icon = result_parts[1]
	_result_level = result_parts[2]

	var blessed_parts := _make_aid_row(center, "Uświęcone kamienie - pewne zaklęcie (III-V)")
	_blessed_slot = blessed_parts[0]
	_blessed_icon = blessed_parts[1]
	_blessed_label = blessed_parts[2]
	_blessed_slot.gui_input.connect(_on_slot_input.bind("blessed"))

	_warning = UiStyle.label("", 7, UiStyle.DIM_COLOR)
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.custom_minimum_size.x = 150
	center.add_child(_warning)

	main.add_child(VSeparator.new())

	# prawa kolumna - statystyki po udanym zaklęciu
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 104
	main.add_child(right)
	right.add_child(UiStyle.label("Po zaklęciu", 8, UiStyle.TITLE_COLOR))
	_next_stats = RichTextLabel.new()
	_next_stats.bbcode_enabled = true
	_next_stats.fit_content = true
	_next_stats.scroll_active = false
	_next_stats.custom_minimum_size.x = 104
	_next_stats.add_theme_font_size_override("normal_font_size", 7)
	_next_stats.add_theme_color_override("default_color", UiStyle.TEXT_COLOR)
	_next_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_next_stats)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 7
	_progress.show_percentage = false
	_progress.max_value = 100.0
	_progress.add_theme_stylebox_override("background", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.SLOT_BORDER, 0))
	_progress.add_theme_stylebox_override("fill", UiStyle.panel(GOLD, Color(0.6, 0.45, 0.1), 0))
	box.add_child(_progress)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	_button = Button.new()
	_button.text = "Zaklnij"
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size = Vector2(70, 16)
	_button.add_theme_font_size_override("font_size", 9)
	_button.pressed.connect(_on_enchant_pressed)
	bottom.add_child(_button)
	_skip_box = _check_box("Pomiń animację", "Od razu pokazuje wynik zaklęcia")
	bottom.add_child(_skip_box)
	_auto_box = _check_box("Auto do +15", "Zaklina raz za razem zwykłymi kamieniami, aż przedmiot osiągnie +15 albo skończą się kamienie")
	bottom.add_child(_auto_box)
	box.add_child(bottom)
	_status = UiStyle.label("", 8, UiStyle.DIM_COLOR)
	box.add_child(_status)

	# efekty na środkowej kratce: iskry przy ładowaniu i puls/błysk na koniec
	_charge_fx = WorldVfx.enchant_charge()
	_charge_fx.position = BIG_SLOT / 2.0 + Vector2(0, 4)
	_charge_fx.visible = false
	_item_slot.add_child(_charge_fx)
	# pierścień pulsu leży poza kratką, żeby nie przejmował jej rozjaśnienia
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.top_level = true
	_fx.draw.connect(_draw_pulse)
	add_child(_fx)


func setup(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh)
	player.inventory.rearranged.connect(_follow_bag_item)
	player.equipment.changed.connect(_refresh)


## Przedmiot z plecaka przeniesiony na inne miejsce (przeciąganie, sortowanie) - okno nadal go trzyma.
func _follow_bag_item(old_to_new: Dictionary) -> void:
	if _item_ref.has("bag") and old_to_new.has(_item_ref["bag"]):
		_item_ref["bag"] = old_to_new[_item_ref["bag"]]


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()


func is_busy() -> bool:
	return _busy or _auto_running


func _process(delta: float) -> void:
	# zamknięcie okna przerywa automat (bieżąca próba i tak się dokończy)
	if not visible and _auto_running:
		_auto_running = false
	if _blessed_flow:
		_spark_timer -= delta
		while _spark_timer <= 0.0:
			_spark_timer += SPARK_INTERVAL
			_spawn_flow_spark()


## PPM na przedmiocie w plecaku przy otwartym oknie.
func offer_bag_item(index: int) -> void:
	if is_busy():
		return
	var data: Dictionary = _player.inventory.slots[index]
	if data.is_empty():
		return
	var id: String = data["id"]
	var item := Items.get_data(id)
	if item.has("stone"):
		_stone_id = id
	elif item.get("enchant_aid", "") == "blessed":
		_blessed_on = true
	elif item.get("enchant_aid", "") == "mercy":
		_mercy_on = true
	elif Enchanting.category(id) != "":
		_item_ref = {"bag": index, "id": id}
	else:
		_set_status("Tego nie da się zaklinać", UiStyle.DIM_COLOR)
	_refresh()


## PPM na założonym przedmiocie przy otwartym oknie.
func offer_equipped(slot: String) -> void:
	if is_busy() or _player.equipment.get_item(slot) == "":
		return
	_item_ref = {"equip": slot, "id": _player.equipment.get_item(slot)}
	_refresh()


# ---------------------------------------------------------------- stan
## Zaklinany przedmiot jako {"id", "enchant"} albo {}, jeśli w międzyczasie zniknął z miejsca.
func _item() -> Dictionary:
	if _item_ref.has("bag"):
		var data: Dictionary = _player.inventory.slots[_item_ref["bag"]]
		if data.get("id", "") == _item_ref["id"]:
			return {"id": data["id"], "enchant": data.get("enchant", 0)}
	elif _item_ref.has("equip"):
		if _player.equipment.get_item(_item_ref["equip"]) == _item_ref["id"]:
			return {"id": _item_ref["id"], "enchant": _player.equipment.get_enchant(_item_ref["equip"])}
	_item_ref = {}
	return {}


func _set_item_level(level: int) -> void:
	if _item_ref.has("bag"):
		_player.inventory.set_enchant(_item_ref["bag"], level)
	else:
		_player.equipment.set_enchant(_item_ref["equip"], level)


func _count(id: String) -> int:
	return _player.inventory.count_of(id)


## Co się stanie po kliknięciu "Zaklnij":
## {"problem": String ("" = można), "blessed": bool, "chance": int, "level": int}.
func _plan() -> Dictionary:
	var item := _item()
	var id: String = item.get("id", "")
	var level: int = item.get("enchant", 0)
	var plan := {"problem": "", "blessed": false, "chance": 0, "level": level, "id": id}
	var blessed_cost := Enchanting.blessed_cost(level)
	# uświęcone kamienie mają pierwszeństwo, jeśli jest ich dość
	if id != "" and _blessed_on and blessed_cost > 0 and _count("blessed_stone") >= blessed_cost:
		plan["blessed"] = true
		plan["chance"] = 100
		return plan
	plan["problem"] = Enchanting.check(_stone_id, id, level)
	if id != "" and level < Enchanting.MAX_LEVEL:
		plan["chance"] = Enchanting.chance(level)
	return plan


func _refresh() -> void:
	if _player == null:
		return
	if _stone_id != "" and _count(_stone_id) == 0:
		_stone_id = ""
	_blessed_on = _blessed_on and _count("blessed_stone") > 0
	_mercy_on = _mercy_on and _count("mercy_stone") > 0
	var plan := _plan()
	var id: String = plan["id"]
	var level: int = plan["level"]
	var can_upgrade := id != "" and level < Enchanting.MAX_LEVEL

	_stone_icon.texture = Items.get_data(_stone_id)["icon"] if _stone_id != "" else null
	_stone_count.text = str(_count(_stone_id)) if _stone_id != "" else ""
	_stone_slot.tooltip_text = Items.describe(_stone_id) if _stone_id != "" else "Kamień zaklinający"
	_item_icon.texture = Items.get_data(id)["icon"] if id != "" else null
	_item_level.text = Enchanting.level_name(level)
	_item_slot.tooltip_text = Items.describe(id, level) if id != "" else "Przedmiot do zaklęcia"
	_result_icon.texture = _item_icon.texture if can_upgrade else null
	UiStyle.set_item_frame(_item_icon.get_parent(), id)
	UiStyle.set_item_frame(_result_icon.get_parent(), id if can_upgrade else "")
	_result_level.text = Enchanting.level_name(level + 1) if can_upgrade else ""

	# kratki kamieni wspierających: ile mamy / ile potrzeba na ten poziom
	var blessed_cost := Enchanting.blessed_cost(level) if can_upgrade else 0
	var mercy_cost := Enchanting.mercy_cost(level) if can_upgrade else 0
	_update_aid(_blessed_icon, _blessed_label, "blessed_stone", _blessed_on, blessed_cost, GOLD)
	_update_aid(_mercy_icon, _mercy_label, "mercy_stone", _mercy_on, mercy_cost, MERCY_BLUE)

	if plan["blessed"]:
		_chance_label.text = "Szansa: 100% (uświęcone)"
		_chance_label.add_theme_color_override("font_color", GOLD)
	elif can_upgrade:
		_chance_label.text = "Szansa: %d%%" % plan["chance"]
		_chance_label.add_theme_color_override("font_color", FAIL_RED.lerp(GOOD_GREEN, plan["chance"] / 100.0))
	else:
		_chance_label.text = "Maksymalny poziom" if id != "" else ""

	var mercy_ready := _mercy_on and mercy_cost > 0 and _count("mercy_stone") >= mercy_cost
	if plan["blessed"]:
		_set_warning("Uświęcone kamienie: pewne zaklęcie (zużyje %d szt.)" % blessed_cost, GOLD)
	elif plan["problem"] != "":
		_set_warning(plan["problem"], UiStyle.DIM_COLOR)
	elif Enchanting.failure_drops_level(level) and mercy_ready:
		_set_warning("Kamienie miłosierdzia ochronią poziom (zużyje %d szt. przy porażce)" % mercy_cost, MERCY_BLUE)
	elif Enchanting.failure_drops_level(level):
		_set_warning("Uwaga: porażka obniży poziom o 1!", FAIL_RED)
	else:
		_set_warning("Porażka zabierze tylko kamień.", UiStyle.DIM_COLOR)

	_refresh_worn()
	_current_stats.text = _stats_text(id, level) if id != "" else "-"
	_next_stats.text = _diff_text(id, level) if can_upgrade else "-"
	_update_button(plan)


## Pasek założonych przedmiotów: puste miejsca znikają, zaklinany przedmiot jest podświetlony.
func _refresh_worn() -> void:
	for slot_name: String in _worn_slots:
		var parts: Array = _worn_slots[slot_name]
		var id := _player.equipment.get_item(slot_name)
		parts[0].visible = id != ""
		if id == "":
			continue
		var level := _player.equipment.get_enchant(slot_name)
		parts[1].texture = Items.get_data(id)["icon"]
		parts[2].text = Enchanting.level_name(level)
		parts[0].tooltip_text = Items.describe(id, level) + "\nKliknij - do zaklęcia"
		UiStyle.set_item_frame(parts[0], id)
		parts[0].modulate = Color(1.35, 1.25, 0.8) if _item_ref.get("equip", "") == slot_name else Color.WHITE


func _on_worn_input(event: InputEvent, slot_name: String) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		offer_equipped(slot_name)
		accept_event()


func _update_aid(icon: TextureRect, label: Label, id: String, active: bool, cost: int, color: Color) -> void:
	icon.texture = Items.get_data(id)["icon"] if active else null
	var count := _count(id) if active else 0
	if cost > 0:
		label.text = "%d / %d" % [count, cost]
		label.add_theme_color_override("font_color", color if count >= cost else UiStyle.DIM_COLOR)
	else:
		label.text = str(count) if active else ""
		label.add_theme_color_override("font_color", UiStyle.DIM_COLOR)


func _update_button(plan: Dictionary) -> void:
	if _auto_running:
		_button.text = "Zatrzymaj"
		_button.disabled = false
	else:
		_button.text = "Zaklnij"
		_button.disabled = _busy or plan["problem"] != ""


func _stats_text(id: String, level: int) -> String:
	var lines: Array[String] = [Items.display_name(id, level)]
	for line: Array in Items.stat_lines(id, level):
		lines.append("%s: %s" % [line[0], line[1]])
	return "\n".join(lines)


## Statystyki po zaklęciu z zielonym przyrostem.
func _diff_text(id: String, level: int) -> String:
	var before := Items.stat_lines(id, level)
	var after := Items.stat_lines(id, level + 1)
	var lines: Array[String] = ["[color=#%s]%s[/color]" % [GOLD.to_html(false), Items.display_name(id, level + 1)]]
	for i in after.size():
		var gain: float = after[i][2] - before[i][2]
		var gain_text := " [color=#%s](+%d)[/color]" % [GOOD_GREEN.to_html(false), gain] if gain >= 1.0 else ""
		lines.append("%s: %s%s" % [after[i][0], after[i][1], gain_text])
	return "\n".join(lines)


# ---------------------------------------------------------------- zaklinanie
func _on_enchant_pressed() -> void:
	if _auto_running:
		_auto_running = false
		_set_status("Automat zatrzymany", UiStyle.DIM_COLOR)
		_refresh()
		return
	if _busy:
		return
	var plan := _plan()
	if plan["problem"] != "":
		return
	# automat działa tylko na zwykłych kamieniach, do +15
	_auto_running = _auto_box.button_pressed and not plan["blessed"] and plan["level"] < Enchanting.MAX_NORMAL
	_start_attempt()


func _start_attempt() -> void:
	var plan := _plan()
	if plan["problem"] != "":
		_auto_running = false
		_refresh()
		return
	_busy = true
	_update_button(plan)
	var success: bool = plan["blessed"] or randi_range(1, 100) <= plan["chance"]
	if _skip_box.button_pressed:
		_finish(success, plan["blessed"])
		return

	_set_status("Zaklinanie...", GOLD)
	_charge_sound.play()
	_charge_fx.visible = true
	_blessed_flow = plan["blessed"]
	_spark_timer = 0.0
	_progress.value = 0.0
	var tween := create_tween()
	tween.tween_property(_progress, "value", 100.0, CHARGE_TIME)
	tween.parallel().tween_method(_charge_glow, 0.0, 1.0, CHARGE_TIME)
	tween.tween_callback(_finish.bind(success, plan["blessed"]))


## Kratka pulsuje złotem coraz szybciej (t: 0..1).
func _charge_glow(t: float) -> void:
	_item_slot.modulate = Color.WHITE.lerp(GOLD * 1.4, 0.5 + 0.5 * sin(t * t * 30.0))


func _finish(success: bool, blessed: bool) -> void:
	_charge_sound.stop()
	_busy = false
	_blessed_flow = false
	_charge_fx.visible = false
	_progress.value = 0.0
	_item_slot.modulate = Color.WHITE

	var item := _item()
	var level: int = item.get("enchant", 0)
	var blessed_cost := Enchanting.blessed_cost(level)
	var paid := false
	if not item.is_empty():
		if blessed:
			paid = _count("blessed_stone") >= blessed_cost and _player.inventory.remove_item("blessed_stone", blessed_cost)
		else:
			paid = _count(_stone_id) > 0 and _player.inventory.remove_item(_stone_id, 1)
	if not paid:
		_auto_running = false
		_set_status("Zaklinanie przerwane", UiStyle.DIM_COLOR)
		_refresh()
		return

	var new_level := level
	if success:
		new_level = level + 1
		_set_status("Sukces! %s" % Items.display_name(item["id"], new_level), GOOD_GREEN)
		_play_success()
		# wbicie poziomu - potężne uderzenie w kowadło, a przy najwyższych poziomach także fanfary
		Sfx.play("enchant_success")
		if new_level >= Enchanting.MAX_NORMAL:
			Sfx.play("enchant_fanfare")
	elif Enchanting.failure_drops_level(level):
		var mercy_cost := Enchanting.mercy_cost(level)
		if _mercy_on and _count("mercy_stone") >= mercy_cost:
			_player.inventory.remove_item("mercy_stone", mercy_cost)
			_set_status("Porażka, ale kamienie miłosierdzia ochroniły poziom (-%d szt.)" % mercy_cost, MERCY_BLUE)
		else:
			new_level = level - 1
			_set_status("Porażka! Poziom spadł do %s" % Enchanting.level_name(new_level), FAIL_RED)
			Sfx.play("enchant_drop")
		_play_failure()
		Sfx.play("enchant_fail")
	else:
		_set_status("Porażka... kamień przepadł", FAIL_RED)
		_play_failure()
		Sfx.play("enchant_fail")
	if new_level != level:
		_set_item_level(new_level)
	_refresh()

	if _auto_running:
		if new_level >= Enchanting.MAX_NORMAL or _plan()["problem"] != "":
			_auto_running = false
			_status.text += "  •  automat zakończony"
			_refresh()
		else:
			var delay := AUTO_DELAY_FAST if _skip_box.button_pressed else AUTO_DELAY
			get_tree().create_timer(delay).timeout.connect(_auto_next)


func _auto_next() -> void:
	if _auto_running and not _busy:
		_start_attempt()


func _play_success() -> void:
	WorldVfx.enchant_result(self, _slot_center(), true)
	var tween := create_tween()
	tween.tween_method(_pulse_step, 0.0, 1.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_item_slot.modulate = GOLD * 1.6
	create_tween().tween_property(_item_slot, "modulate", Color.WHITE, 0.6)


func _play_failure() -> void:
	WorldVfx.enchant_result(self, _slot_center(), false)
	var tween := create_tween()
	for i in 2:
		tween.tween_property(_item_slot, "modulate", FAIL_RED * 1.5, 0.12)
		tween.tween_property(_item_slot, "modulate", Color.WHITE, 0.18)


## Złoty pierścień rozchodzący się od kratki (t: 0..1).
func _pulse_step(t: float) -> void:
	_fx.global_position = _item_slot.global_position + BIG_SLOT / 2.0
	_pulse_radius = lerpf(10.0, 90.0, t)
	_pulse_alpha = 1.0 - t
	_fx.queue_redraw()


func _draw_pulse() -> void:
	if _pulse_alpha <= 0.0:
		return
	_fx.draw_arc(Vector2.ZERO, _pulse_radius, 0.0, TAU, 48, Color(GOLD, _pulse_alpha), 3.0)
	_fx.draw_arc(Vector2.ZERO, _pulse_radius * 0.7, 0.0, TAU, 40, Color(1, 1, 0.8, _pulse_alpha * 0.6), 1.5)


## Złota iskra lecąca łukiem z kratki uświęconych kamieni do przedmiotu.
func _spawn_flow_spark() -> void:
	var spark := ColorRect.new()
	spark.size = Vector2(3, 3)
	spark.color = GOLD if randf() < 0.7 else Color(1, 0.95, 0.7)
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.top_level = true
	add_child(spark)
	var from := _blessed_slot.global_position + AID_SLOT / 2.0 + Vector2(randf_range(-6, 6), randf_range(-4, 4))
	var to := _item_slot.global_position + BIG_SLOT / 2.0 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var bend := Vector2(randf_range(-30, 30), 0)
	spark.global_position = from
	var tween := spark.create_tween()
	tween.tween_method(_move_spark.bind(spark, from, to, bend), 0.0, 1.0, randf_range(0.55, 0.8))
	tween.tween_property(spark, "modulate:a", 0.0, 0.1)
	tween.tween_callback(spark.queue_free)


func _move_spark(t: float, spark: Control, from: Vector2, to: Vector2, bend: Vector2) -> void:
	spark.global_position = from.lerp(to, t) + bend * sin(t * PI)


# ---------------------------------------------------------------- pomocnicze
func _on_slot_input(event: InputEvent, which: String) -> void:
	var mouse := event as InputEventMouseButton
	if is_busy() or mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_RIGHT:
		return
	match which:
		"stone":
			_stone_id = ""
		"item":
			_item_ref = {}
		"blessed":
			_blessed_on = false
		"mercy":
			_mercy_on = false
	_refresh()


func _make_slot(parent: Node, slot_size: Vector2, tooltip: String) -> Array:
	var slot := Panel.new()
	UiStyle.rich_tooltip(slot)
	slot.custom_minimum_size = slot_size
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, UiStyle.BORDER, 0))
	slot.tooltip_text = tooltip
	parent.add_child(slot)
	var icon := TextureRect.new()
	UiStyle.center_icon(icon)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var label := UiStyle.label("", 7, GOLD)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 2
	label.offset_top = -2
	label.offset_right = -1
	label.offset_bottom = 2
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	return [slot, icon, label]


## Mała kratka kamieni wspierających z licznikiem "mamy / potrzeba" obok.
func _make_aid_row(parent: Node, tooltip: String) -> Array:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var spacer := Control.new()  # równoważy licznik po prawej, żeby kratka była pod przedmiotem
	spacer.custom_minimum_size.x = 36
	row.add_child(spacer)
	var parts := _make_slot(row, AID_SLOT, tooltip)
	var count := UiStyle.label("", 7, UiStyle.DIM_COLOR)
	count.custom_minimum_size.x = 36
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(count)
	return [parts[0], parts[1], count]


func _arrow() -> Label:
	var arrow := UiStyle.label("»", 10, UiStyle.DIM_COLOR)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return arrow


func _check_box(text: String, tooltip: String) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.tooltip_text = tooltip
	box.focus_mode = Control.FOCUS_NONE
	box.add_theme_font_size_override("font_size", 8)
	return box


## Środek dużej kratki przedmiotu na płótnie okna - tu wybucha efekt wyniku zaklinania (z kreatora efektów PixelLab).
func _slot_center() -> Vector2:
	return _item_slot.get_global_transform() * (BIG_SLOT / 2.0)


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _set_warning(text: String, color: Color) -> void:
	_warning.text = text
	_warning.add_theme_color_override("font_color", color)
