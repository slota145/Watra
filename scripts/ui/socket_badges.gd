class_name SocketBadges
extends Control
## Kamienie szlachetne i esencja osadzone w przedmiocie - małe ikonki w dolnym rogu kratki (puste gniazdo to
## ciemne kółko). Znikają, gdy kursor jest nad kratką, żeby nie zasłaniać przedmiotu.
## Dodawane i zdejmowane przez UiStyle.set_item_frame().

const BADGE := 9.0
const EMPTY := Color(0.05, 0.05, 0.08, 0.85)
const RIM := Color(0.75, 0.68, 0.5)

## Ikony kamieni (null - puste gniazdo), na końcu esencja.
var icons: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var parent := get_parent() as Control
	visible = parent != null and not parent.get_global_rect().has_point(get_global_mouse_position())


func _draw() -> void:
	var step := minf(BADGE, (size.x - 2.0) / maxf(icons.size(), 1.0))
	for i in icons.size():
		var rect := Rect2(Vector2(1.0 + i * step, size.y - BADGE - 1.0), Vector2(BADGE, BADGE))
		var icon: Texture2D = icons[i]
		if icon == null:
			draw_circle(rect.get_center(), BADGE / 2.0 - 1.0, EMPTY)
			draw_arc(rect.get_center(), BADGE / 2.0 - 1.0, 0.0, TAU, 12, RIM, 1.0)
		else:
			draw_texture_rect(icon, rect, false)


## Ikony gniazd przedmiotu (pusta lista - przedmiot bez gniazd).
static func icons_of(id: String) -> Array:
	var result: Array = []
	if id == "":
		return result
	for gem: Dictionary in Gems.sockets_of(id):
		result.append(null if gem.is_empty() else Gems.icon_of(gem))
	var essence = Items.get_data(id).get("essence_socket")
	if essence is Dictionary:
		result.append(null if (essence as Dictionary).is_empty() else Essences.ICONS.get(essence.get("group", "jewelry")))
	return result
