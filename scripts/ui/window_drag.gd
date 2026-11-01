class_name WindowDrag
extends Node
## Przesuwanie i skalowanie okna interfejsu przez gracza: przeciągnij okno za tło albo tytuł (lewy przycisk),
## Ctrl + kółko myszy nad oknem zmienia jego wielkość. Ustawienie zapamiętuje Game.window_layouts (user://settings.cfg),
## więc okno wraca w to samo miejsce przy każdym otwarciu - także po zmianie krainy i w kolejnej grze.
## Podpina się jako dziecko okna (WindowDrag.attach) i słucha jego gui_input, więc kliknięcia w przyciski
## i kratki okna działają jak dotąd - przesuwa tylko to, co trafi w samo okno.

const SCALE_RANGE := Vector2(0.6, 2.0)
const SCALE_STEP := 0.1
## O ile pikseli trzeba ruszyć myszą, żeby kliknięcie stało się przeciąganiem.
const DRAG_THRESHOLD := 3.0
## Ile okna musi zostać na ekranie po przesunięciu.
const KEEP_VISIBLE := 24.0

var _window: Control
var _pressed := false
var _dragging := false
var _press_at := Vector2.ZERO
var _grab := Vector2.ZERO


## Robi okno przesuwalnym i skalowalnym; jego ustawienie zapisuje się pod nazwą węzła.
static func attach(window: Control) -> WindowDrag:
	var drag := WindowDrag.new()
	drag.name = "WindowDrag"
	drag._window = window
	window.add_child(drag)
	window.gui_input.connect(drag._on_gui_input)
	window.visibility_changed.connect(drag._restore)
	return drag


## Okno samo ustawia się przy otwieraniu (środek ekranu, obok ekwipunku) - ustawienie gracza wygrywa,
## więc nakładamy je po tym, jak okno skończy się otwierać.
func _restore() -> void:
	if _window.visible and Game.window_layouts.has(_window.name):
		_apply.call_deferred()


func _apply() -> void:
	var layout: Array = Game.window_layouts.get(_window.name, [])
	if layout.size() < 3:
		return
	_window.scale = Vector2.ONE * clampf(float(layout[2]), SCALE_RANGE.x, SCALE_RANGE.y)
	_window.position = _clamped(Vector2(float(layout[0]), float(layout[1])))


func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null:
		if click.button_index == MOUSE_BUTTON_LEFT:
			_pressed = click.pressed
			_press_at = click.global_position
			_grab = _window.position - click.global_position
			if not click.pressed and _dragging:
				_dragging = false
				_save()
		elif click.pressed and click.ctrl_pressed and click.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step := SCALE_STEP if click.button_index == MOUSE_BUTTON_WHEEL_UP else -SCALE_STEP
			_rescale(_window.scale.x + step, click.global_position)
			_window.accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion == null or not _pressed:
		return
	if not _dragging and motion.global_position.distance_to(_press_at) < DRAG_THRESHOLD:
		return
	_dragging = true
	_window.position = _clamped(motion.global_position + _grab)
	_window.accept_event()


## Zmienia skalę okna tak, żeby punkt pod kursorem został w miejscu.
func _rescale(value: float, anchor: Vector2) -> void:
	var before := _window.scale.x
	var after := clampf(snappedf(value, 0.05), SCALE_RANGE.x, SCALE_RANGE.y)
	if is_equal_approx(before, after):
		return
	_window.position = _clamped(anchor - (anchor - _window.position) * (after / before))
	_window.scale = Vector2.ONE * after
	_save()


## Okno nie ucieka całkiem za krawędź ekranu.
func _clamped(at: Vector2) -> Vector2:
	var screen := _window.get_viewport_rect().size
	var shown := _window.size * _window.scale
	return Vector2(clampf(at.x, KEEP_VISIBLE - shown.x, screen.x - KEEP_VISIBLE),
			clampf(at.y, 0.0, screen.y - KEEP_VISIBLE)).floor()


func _save() -> void:
	Game.set_window_layout(_window.name, [_window.position.x, _window.position.y, _window.scale.x])
