class_name QuestJournal
extends PanelContainer
## Dziennik zadań (klawisz J): zadania w toku (pomarańczowe), do odebrania nagrody
## (zielone) i ukończone (szare). Oko przy zadaniu włącza/wyłącza jego śledzenie
## pod minimapą, a kliknięcie tytułu pokazuje obszar zadania na mapie.

signal area_requested(quest_id: String)

const ACTIVE_COLOR := QuestTracker.ACTIVE_COLOR
const READY_COLOR := QuestTracker.READY_COLOR
const DONE_COLOR := Color(0.55, 0.57, 0.62)
const TRACK_ON := preload("res://assets/ui/track_on.png")
const TRACK_OFF := preload("res://assets/ui/track_off.png")
const SECTIONS := [
	[Quests.STATE_READY, "Do odebrania nagrody", READY_COLOR],
	[Quests.STATE_ACTIVE, "W toku", ACTIVE_COLOR],
	[Quests.STATE_DONE, "Ukończone", DONE_COLOR],
]

var _player: Player
var _list: VBoxContainer


func _ready() -> void:
	visible = false
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel(Color(UiStyle.BG, 1.0)))
	custom_minimum_size = Vector2(250, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(UiStyle.title(tr("Dziennik zadań")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 190
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	var hint := UiStyle.label(tr("Oko - śledzenie pod minimapą (maks. %d)   •   tytuł - pokaż na mapie") % Quests.MAX_TRACKED, 7, UiStyle.DIM_COLOR)
	box.add_child(hint)


func setup(player: Player) -> void:
	_player = player
	player.quests.changed.connect(_refresh)
	_refresh()


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()
		reset_size()
		position = ((get_viewport_rect().size - size) / 2.0).floor()


func _refresh() -> void:
	if _player == null:
		return
	for child in _list.get_children():
		child.get_parent().remove_child(child)  # od razu znika z układu
		child.queue_free()
	var any := false
	for section: Array in SECTIONS:
		var ids: Array[String] = []
		for id: String in _player.quests.states:
			if _player.quests.state_of(id) == section[0]:
				ids.append(id)
		if ids.is_empty():
			continue
		any = true
		_list.add_child(UiStyle.label(tr(section[1]), 8, section[2]))
		for id in ids:
			_list.add_child(_entry(id, section[0], section[2]))
	if not any:
		var empty := UiStyle.label(tr("Nie masz jeszcze żadnych zadań.\nPoszukaj w osadzie postaci ze złotym \"!\" nad głową."), 8, UiStyle.DIM_COLOR)
		_list.add_child(empty)


func _entry(id: String, state: String, color: Color) -> PanelContainer:
	var quest := Quests.get_data(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.SLOT_BG, Color(color, 0.7), 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	card.add_child(row)

	if state != Quests.STATE_DONE:
		var track := Button.new()
		var tracked := _player.quests.is_tracked(id)
		track.icon = TRACK_ON if tracked else TRACK_OFF
		UiStyle.fit_button_icon(track, 12)
		track.flat = true
		track.focus_mode = Control.FOCUS_NONE
		track.tooltip_text = tr("Przestań śledzić") if tracked else tr("Śledź pod minimapą")
		track.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		track.pressed.connect(_toggle_track.bind(id))
		row.add_child(track)

	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lines)
	var title := Button.new()
	title.text = Quests.text(quest, "title")
	title.flat = true
	title.focus_mode = Control.FOCUS_NONE
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", MainQuests.COLOR if MainQuests.is_main(id) and state != Quests.STATE_DONE else color)
	if MainQuests.is_main(id):
		title.text = "★ " + Quests.text(quest, "title")
	title.add_theme_color_override("font_hover_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 9)
	title.tooltip_text = tr("Pokaż obszar zadania na mapie")
	title.pressed.connect(area_requested.emit.bind(id))
	lines.add_child(title)
	var details := [
		tr("Zleceniodawca: %s") % Quests.person(quest["giver"]),
		tr("Postęp: %s") % (MainQuests.progress_text(_player, id) if MainQuests.is_main(id)
				else "%s %d/%d" % [Quests.text(quest, "target_name"), _player.quests.progress_of(id), quest.get("count", 1)]),
		tr("Nagroda: %s") % Quests.reward_text(id),
	]
	if state == Quests.STATE_READY:
		details[1] = tr("Wykonane! Wróć do: %s") % Quests.person(Quests.receiver(id))
	elif state == Quests.STATE_DONE:
		details.remove_at(1)
	for line: String in details:
		lines.add_child(UiStyle.label(line, 7, UiStyle.DIM_COLOR if state == Quests.STATE_DONE else UiStyle.TEXT_COLOR))
	return card


func _toggle_track(id: String) -> void:
	if not _player.quests.toggle_track(id):
		DamageNumber.spawn_text(_player.get_parent(), _player.body_center() + Vector2(0, -10),
				tr("Można śledzić najwyżej %d zadania") % Quests.MAX_TRACKED, Color(1, 0.5, 0.4), 8)
