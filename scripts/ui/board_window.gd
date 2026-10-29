class_name BoardWindow
extends PanelContainer
## Tablica ogłoszeń przed gildią: gdy nie mamy zlecenia - dwa do wyboru (wilki albo gobliny),
## gdy mamy - jego postęp, odbiór nagrody i możliwość porzucenia. Po odebraniu nagrody
## od razu wiszą kolejne, lepiej płatne zlecenia.

const CARD_WIDTH := 172.0
const PAPER := Color(0.93, 0.88, 0.76)
const INK := Color(0.22, 0.17, 0.12)
const INK_DIM := Color(0.42, 0.34, 0.26)
const REWARD := Color(0.55, 0.32, 0.05)

var _player: Player
var _box: VBoxContainer
var _cards: HBoxContainer
var _done_label: Label
var _status: Label
## Porzucenie wymaga drugiego kliknięcia.
var _confirm_abandon := false


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(0.36, 0.25, 0.15, 0.98), Color(0.2, 0.13, 0.07), 6))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	_box.add_child(UiStyle.title("Tablica ogłoszeń"))
	_done_label = UiStyle.label("", 7, Color(0.95, 0.85, 0.65))
	_done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_done_label)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 6)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(_cards)
	var bottom := HBoxContainer.new()
	_status = UiStyle.label("", 8, Color(0.95, 0.85, 0.65))
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_status)
	var close_button := _button("Zamknij", func() -> void:
		visible = false
		Sfx.play("ui_close"))
	bottom.add_child(close_button)
	_box.add_child(bottom)


func setup(player: Player) -> void:
	_player = player
	player.quests.changed.connect(func() -> void:
		if visible:
			_refresh())


func open() -> void:
	visible = true
	_status.text = ""
	_confirm_abandon = false
	_refresh()
	Sfx.play("ui_book")


func toggle() -> void:
	if visible:
		visible = false
	else:
		open()


func _process(_delta: float) -> void:
	# tablica zamyka się, gdy gracz odejdzie
	var board := get_tree().get_first_node_in_group("notice_board") as Node2D
	if visible and (board == null or _player.is_dead or _player.global_position.distance_to(board.global_position) > 70.0):
		visible = false


func _refresh() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var quest_log := _player.quests
	_done_label.text = "Wykonane zlecenia: %d  •  każde kolejne płaci więcej" % quest_log.bounties_done
	var active := quest_log.active_bounty()
	if active != "":
		_cards.add_child(_active_card(active))
	else:
		for offer in Bounties.offers(quest_log.bounties_done):
			_cards.add_child(_offer_card(offer))
	reset_size()
	position = ((get_viewport_rect().size - size) / 2.0).floor()


## Kartka papieru przypięta do tablicy.
func _paper(width: float) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(PAPER, Color(0.55, 0.45, 0.3), 5))
	card.custom_minimum_size.x = width
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	card.add_child(content)
	var pin := UiStyle.label("●", 8, Color(0.75, 0.15, 0.12))
	pin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin.add_theme_constant_override("outline_size", 0)
	content.add_child(pin)
	return content


func _ink(text: String, size := 7, color := INK, wrap_width := 0.0) -> Label:
	var label := UiStyle.label(text, size, color)
	label.add_theme_constant_override("outline_size", 0)
	if wrap_width > 0.0:
		label.custom_minimum_size.x = wrap_width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _quest_text(content: VBoxContainer, quest: Dictionary, progress: int, show_progress: bool) -> void:
	var title := _ink(quest["title"], 9, Color(0.5, 0.12, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(_ink(quest["description"], 7, INK, CARD_WIDTH - 10.0))
	var goal := "Cel: %s %d/%d" % [quest["target_name"], progress, quest["count"]] if show_progress \
			else "Cel: pokonaj %d (%s)" % [quest["count"], quest["target_name"].to_lower()]
	content.add_child(_ink(goal, 7, INK))
	content.add_child(_ink("Gdzie: " + quest["area_name"], 7, INK_DIM, CARD_WIDTH - 10.0))
	content.add_child(_ink("Nagroda:", 7, REWARD))
	var rewards := HFlowContainer.new()
	rewards.custom_minimum_size.x = CARD_WIDTH - 10.0
	rewards.add_theme_constant_override("h_separation", 6)
	rewards.add_child(_ink("%d zł" % quest["gold"], 7, REWARD))
	rewards.add_child(_ink("%d exp" % quest["xp"], 7, REWARD))
	var items: Dictionary = quest["reward_items"]
	for id: String in items:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 1)
		var icon := TextureRect.new()
		icon.texture = Items.get_data(id)["icon"]
		UiStyle.fit_icon(icon)
		icon.tooltip_text = Items.get_data(id)["name"]
		pair.add_child(icon)
		pair.add_child(_ink("x%d" % items[id], 7, REWARD))
		rewards.add_child(pair)
	content.add_child(rewards)


func _offer_card(offer: Dictionary) -> Control:
	var content := _paper(CARD_WIDTH)
	_quest_text(content, offer, 0, false)
	var take := _button("Przyjmij zlecenie", _take.bind(offer))
	take.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(take)
	return content.get_parent()


func _active_card(id: String) -> Control:
	var quest_log := _player.quests
	var quest := Quests.get_data(id)
	var content := _paper(CARD_WIDTH * 1.4)
	_quest_text(content, quest, quest_log.progress_of(id), true)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 6)
	if quest_log.state_of(id) == Quests.STATE_READY:
		buttons.add_child(_button("Odbierz nagrodę", _finish.bind(id)))
	else:
		buttons.add_child(_button("Na pewno porzucić?" if _confirm_abandon else "Porzuć zlecenie", _abandon.bind(id)))
	content.add_child(buttons)
	return content.get_parent()


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(on_pressed)
	return button


func _take(offer: Dictionary) -> void:
	if _player.quests.take_bounty(offer) == "":
		return
	Sfx.play("ui_confirm")
	_status.text = "Przyjęto: %s" % offer["title"]
	_refresh()


func _finish(id: String) -> void:
	var quest := Quests.get_data(id).duplicate()
	if not _player.quests.finish_bounty(id, _player):
		return
	Sfx.play("quest_done")
	Sfx.play("coins")
	DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -14),
			"+%d zł  +%d exp" % [quest["gold"], quest["xp"]], Color(1.0, 0.85, 0.3), 10)
	for item: String in quest["reward_items"]:
		_player.item_picked.emit(item, int(quest["reward_items"][item]))
	_status.text = "Nagroda odebrana! Na tablicy wiszą nowe zlecenia."
	_refresh()


func _abandon(id: String) -> void:
	if not _confirm_abandon:
		_confirm_abandon = true
		_refresh()
		return
	_confirm_abandon = false
	_player.quests.abandon_bounty(id)
	Sfx.play("ui_close")
	_status.text = "Zlecenie porzucone."
	_refresh()
