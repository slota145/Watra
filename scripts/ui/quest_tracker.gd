class_name QuestTracker
extends VBoxContainer
## Śledzone zadania pod minimapą: tytuł i postęp. Kliknięcie w zadanie pokazuje
## jego obszar na mapie (sygnał area_requested).

signal area_requested(quest_id: String)

const ACTIVE_COLOR := Color(1.0, 0.72, 0.38)
const READY_COLOR := Color(0.6, 1.0, 0.5)

var _player: Player


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(player: Player) -> void:
	_player = player
	player.quests.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in get_children():
		child.get_parent().remove_child(child)  # od razu znika z układu
		child.queue_free()
	if _player.quests.tracked.is_empty():
		return
	var header := UiStyle.label("Zadania", 8, UiStyle.TITLE_COLOR)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(header)
	for id in _player.quests.tracked:
		add_child(_entry(id))


func _entry(id: String) -> Button:
	var quest := Quests.get_data(id)
	var is_ready := _player.quests.state_of(id) == Quests.STATE_READY
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Kliknij, aby zobaczyć obszar zadania na mapie"
	button.custom_minimum_size = Vector2(0, 24)
	var empty := StyleBoxEmpty.new()
	var hover := UiStyle.panel(Color(0.1, 0.11, 0.17, 0.6), Color(1, 1, 1, 0.0), 0)
	for state in ["normal", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	button.add_theme_stylebox_override("hover", hover)
	button.theme = UiStyle.make_theme()

	var lines := VBoxContainer.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.add_theme_constant_override("separation", -2)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(lines)
	var main := MainQuests.is_main(id)
	var title := UiStyle.label(quest["title"], 8, MainQuests.COLOR if main else READY_COLOR if is_ready else ACTIVE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(title)
	var status := "Wróć do: %s" % Quests.receiver(id) if is_ready \
			else "%s: %d/%d" % [quest["target_name"], _player.quests.progress_of(id), quest.get("count", 1)]
	if main and not is_ready:
		var have: Array = MainQuests.progress(_player, id)
		status = "%s: %d/%d" % [quest["target_name"], have[0], have[1]] if have[1] > 1 else quest["target_name"]
	var detail := UiStyle.label(status, 7, UiStyle.TEXT_COLOR)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(detail)
	button.pressed.connect(area_requested.emit.bind(id))
	return button
