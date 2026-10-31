class_name WatraWindow
extends PanelContainer
## Okno Watry - wielkiego ognia na placu Ostoi. Gracz składa w niej ofiary: złoto albo przedmioty z plecaka
## (spalone - przepadają). Ofiary dokładają żaru (Boons.ember); od żaru zależy poziom Watry, a od poziomu stałe
## premie postaci i rozwój Ostoi (większy podatek, szybsze budowy). Za złoto można też przyjąć jeden z darów Watry
## (czasowe błogosławieństwo); zapłata za dar także dokłada żaru. Przycisk "Lochy" otwiera wybór lochu
## w płomieniach Watry (DungeonWindow).

signal offered(ember: int, level_up: bool)
signal dungeon_requested
signal essence_requested

const WIDTH := 300.0
const LIST_HEIGHT := 44.0
const FIRE := Color(1.0, 0.6, 0.25)
const GOLD_OFFERINGS: Array[int] = [100, 500, 2000]
const GIFTS: Array[String] = ["watra_fire", "watra_warmth", "watra_glow"]

var _player: Player
var _level_label: Label
var _bar: ProgressBar
var _perks: Label
var _gifts: VBoxContainer
var _gold_row: HBoxContainer
var _items: VBoxContainer
var _gold_label: Label
var _status: Label
## Przycisk lochów - zablokowany do zadania głównego „Płomień Watry” (MainQuests.DUNGEON_STEP).
var _dungeons: Button


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.16, 0.08, 0.05, 0.98), Color(0.85, 0.45, 0.18), 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title("Watra"))
	box.add_child(_wrapped("Dopóki płonie ogień, Ostoja trwa. Złóż ofiarę, a żar Watry urośnie.", 7, UiStyle.DIM_COLOR))
	_level_label = UiStyle.label("", 8, FIRE)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_level_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(WIDTH, 8)
	_bar.show_percentage = false
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := StyleBoxFlat.new()
	fill.bg_color = FIRE
	_bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.04, 0.03)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)
	_perks = _wrapped("", 7, UiStyle.TEXT_COLOR)
	box.add_child(_perks)

	box.add_child(HSeparator.new())
	box.add_child(_header("Dary Watry (20 minut, jeden naraz)"))
	_gifts = VBoxContainer.new()
	_gifts.add_theme_constant_override("separation", 2)
	box.add_child(_gifts)

	var gold_box := HBoxContainer.new()
	gold_box.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_box.add_theme_constant_override("separation", 6)
	gold_box.add_child(_header("Ofiara ze złota:"))
	_gold_row = HBoxContainer.new()
	_gold_row.add_theme_constant_override("separation", 6)
	gold_box.add_child(_gold_row)
	box.add_child(gold_box)

	box.add_child(HSeparator.new())
	box.add_child(_header("Spal przedmioty z plecaka"))
	_items = VBoxContainer.new()
	_items.add_theme_constant_override("separation", 2)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(WIDTH + 14.0, LIST_HEIGHT)
	scroll.add_child(_items)
	box.add_child(scroll)

	var bottom := HBoxContainer.new()
	var coin := TextureRect.new()
	coin.texture = Items.GOLD_ICON
	UiStyle.fit_icon(coin, 10)
	bottom.add_child(coin)
	_gold_label = UiStyle.label("", 8, Color(1.0, 0.85, 0.3))
	bottom.add_child(_gold_label)
	_status = UiStyle.label("", 8, FIRE)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(_status)
	bottom.add_child(_button("Esencje", func() -> void:
		visible = false
		essence_requested.emit()))
	_dungeons = _button("Lochy", func() -> void:
		visible = false
		dungeon_requested.emit())
	bottom.add_child(_dungeons)
	bottom.add_child(_button("Zamknij", func() -> void:
		visible = false
		Sfx.play("ui_close")))
	box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh_if_open)
	player.boons.changed.connect(_refresh_if_open)
	player.stats.gold_changed.connect(func(_gold: int) -> void: _refresh_if_open())


func open() -> void:
	visible = true
	_status.text = ""
	_refresh()
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor().max(Vector2.ZERO)
	Sfx.play("ui_open")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


func _refresh_if_open() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if _player == null:
		return
	var unlocked := MainQuests.dungeons_unlocked(_player.quests)
	_dungeons.disabled = not unlocked
	_dungeons.tooltip_text = "" if unlocked else "Żerca Wszebor otworzy lochy, gdy Watra urośnie (zadanie główne „Płomień Watry”)"
	var boons := _player.boons
	var level := boons.watra_level()
	var next := boons.watra_next()
	var from: int = Boons.WATRA_LEVELS[level - 1]
	_level_label.text = "Poziom Watry: %d   żar: %d%s" % [level, boons.ember, (" / %d" % next) if next > 0 else " (najwyższy)"]
	_bar.min_value = from
	_bar.max_value = maxi(next, from + 1)
	_bar.value = boons.ember if next > 0 else _bar.max_value
	_perks.text = _perks_text(level)
	_gold_label.text = "%d" % _player.stats.gold

	for child in _gifts.get_children() + _gold_row.get_children() + _items.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var active_gift := ""
	if boons.has_group("watra"):
		active_gift = boons.active["watra"]["id"]
	for id in GIFTS:
		var data: Dictionary = Boons.DEFS[id]
		var price := Boons.gold_cost(id, _player.stats.level)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var text := UiStyle.label("%s: %s" % [data["name"], data["description"]], 7, FIRE if id == active_gift else UiStyle.TEXT_COLOR)
		text.custom_minimum_size.x = WIDTH - 70.0
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var take := _button("%d zł" % price, _take_gift.bind(id, price))
		take.disabled = _player.stats.gold < price
		row.add_child(take)
		_gifts.add_child(row)
	for amount in GOLD_OFFERINGS:
		var offer := _button("%d zł" % amount, _offer_gold.bind(amount))
		offer.disabled = _player.stats.gold < amount
		offer.tooltip_text = "+%d żaru" % roundi(amount * Boons.EMBER_PER_GOLD)
		_gold_row.add_child(offer)

	var any := false
	for i in _player.inventory.slots.size():
		var slot: Dictionary = _player.inventory.slots[i]
		if slot.is_empty() or not Items.get_data(slot["id"]).has("sell_price"):
			continue
		any = true
		var enchant: int = slot.get("enchant", 0)
		var count: int = slot.get("count", 1)
		var ember := _item_ember(slot["id"], enchant)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		UiStyle.rich_tooltip(row)
		row.tooltip_text = Items.tooltip(slot["id"], enchant)
		var icon := TextureRect.new()
		icon.texture = Items.get_data(slot["id"])["icon"]
		UiStyle.fit_icon(icon)
		icon.custom_minimum_size = Vector2(16, 16)
		row.add_child(icon)
		UiStyle.set_item_frame(icon, slot["id"])
		var name := Items.display_name(slot["id"], enchant) + (" x%d" % count if count > 1 else "")
		var label := UiStyle.label("%s (+%d żaru/szt.)" % [name, ember], 7, Items.rarity_color(slot["id"]))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.custom_minimum_size.x = WIDTH - 110.0
		row.add_child(label)
		row.add_child(_button("Spal", _burn.bind(i, 1)))
		if count > 1:
			row.add_child(_button("Wszystkie", _burn.bind(i, count)))
		_items.add_child(row)
	if not any:
		_items.add_child(UiStyle.label("Nie masz w plecaku nic, co można spalić.", 7, UiStyle.DIM_COLOR))


func _perks_text(level: int) -> String:
	var steps := level - 1
	var lines: Array[String] = []
	lines.append("Każdy kolejny poziom: +%d%% złota, +%d%% doświadczenia, +%.1f zdrowia/s; podatek osadników +%d%%, budowy szybsze o %d%%." % [
			roundi(Boons.WATRA_PERKS["gold_find"] * 100.0), roundi(Boons.WATRA_PERKS["xp_gain"] * 100.0),
			Boons.WATRA_PERKS["health_regen"], roundi(Boons.WATRA_TAX * 100.0), roundi(Boons.WATRA_BUILD_SPEED * 100.0)])
	if steps > 0:
		lines.append("Teraz: +%d%% złota, +%d%% doświadczenia, +%.1f zdrowia/s, podatek +%d%%, budowy +%d%%." % [
				roundi(Boons.WATRA_PERKS["gold_find"] * steps * 100.0), roundi(Boons.WATRA_PERKS["xp_gain"] * steps * 100.0),
				Boons.WATRA_PERKS["health_regen"] * steps, roundi(Boons.WATRA_TAX * steps * 100.0),
				roundi(Boons.WATRA_BUILD_SPEED * steps * 100.0)])
	return "\n".join(lines)


static func _item_ember(id: String, enchant: int) -> int:
	var value: int = Items.get_data(id)["sell_price"] + Enchanting.bonus(enchant) * 3
	return maxi(1, roundi(value * Boons.EMBER_PER_ITEM_VALUE))


func _take_gift(id: String, price: int) -> void:
	if _player.stats.gold < price:
		return
	_player.stats.add_gold(-price)
	_player.boons.grant(id)
	_add(roundi(price * Boons.EMBER_PER_GOLD), "Watra przyjęła ofiarę: %s" % Boons.DEFS[id]["name"])


func _offer_gold(amount: int) -> void:
	if _player.stats.gold < amount:
		return
	_player.stats.add_gold(-amount)
	_add(roundi(amount * Boons.EMBER_PER_GOLD), "Złoto topnieje w płomieniach")


func _burn(index: int, count: int) -> void:
	# cały stos naraz - pojedyncze zdejmowanie przebudowywało okna setki razy i gra stawała
	var taken := _player.inventory.take(index, count)
	if taken.is_empty():
		return
	var ember := _item_ember(taken["id"], int(taken["enchant"])) * int(taken["count"])
	if ember > 0:
		_add(ember, "Ogień pochłania ofiarę")


func _add(ember: int, text: String) -> void:
	var level_up := _player.boons.add_ember(ember)
	_status.text = "%s (+%d żaru)" % [text, ember]
	if level_up:
		_status.text = "Watra rozgorzała! Poziom %d" % _player.boons.watra_level()
	Sfx.play("fireball_launch" if level_up else "ui_confirm")
	offered.emit(ember, level_up)
	_refresh()


func _header(text: String) -> Label:
	var label := UiStyle.label(text, 8, FIRE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _wrapped(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(text, font_size, color)
	label.custom_minimum_size.x = WIDTH
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.custom_minimum_size = Vector2(18, 14)
	button.pressed.connect(on_pressed)
	return button
