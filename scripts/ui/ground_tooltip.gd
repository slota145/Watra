class_name GroundTooltip
extends PanelContainer
## Dymek łupu leżącego na ziemi: po najechaniu kursorem na przedmiot pokazuje ten sam opis co w plecaku,
## razem z porównaniem z założonym przedmiotem (Items.tooltip). Ukryty nad oknami interfejsu i nad złotem.

## Jak blisko środka ikony musi być kursor (piksele świata; ikona ma 16 px).
const HOVER_RADIUS := 9.0
## Środek ikony względem punktu łupu (Pickup.Sprite).
const ICON_OFFSET := Vector2(0, -3)

var _player: Player
var _shown: Pickup
## Buduje zawartość dymka jak dymki interfejsu (kolory BBCode, dwa panele przy porównaniu).
var _builder := RichTooltip.new()


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", theme.get_stylebox("panel", "TooltipPanel"))
	add_child(_builder)
	_builder.visible = false


func setup(player: Player) -> void:
	_player = player


func _process(_delta: float) -> void:
	var pickup := _hovered()
	if pickup == null:
		_hide()
		return
	if pickup != _shown:
		_show(pickup)
	var viewport := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	position = (mouse + Vector2(10, 10)).clamp(Vector2.ZERO, viewport - size).floor()


## Przedmiot na ziemi pod kursorem (bez złota), gdy kursor nie jest nad oknem interfejsu.
func _hovered() -> Pickup:
	if _player == null or not is_instance_valid(_player) or get_viewport().gui_get_hovered_control() != null:
		return null
	var mouse := _player.get_global_mouse_position()
	var best: Pickup = null
	var best_distance := HOVER_RADIUS
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup == null or pickup.item_id == "gold":
			continue
		var distance := (pickup.global_position + ICON_OFFSET).distance_to(mouse)
		if distance <= best_distance:
			best = pickup
			best_distance = distance
	return best


func _show(pickup: Pickup) -> void:
	_hide()
	_shown = pickup
	var extra := "\n" + Lang.t("Ilość: %d") % pickup.amount if pickup.amount > 1 else ""
	var content: Control = _builder._make_custom_tooltip(Items.tooltip(pickup.item_id, 0, extra))
	add_child(content)
	# dymek nie łapie myszy - inaczej sam byłby "oknem pod kursorem" i znikał
	for node in [content] + content.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_size()
	visible = true


func _hide() -> void:
	_shown = null
	visible = false
	for child in get_children():
		if child != _builder:
			remove_child(child)
			child.queue_free()
