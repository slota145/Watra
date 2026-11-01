class_name TrainingDummy
extends Goblin
## Kukła treningowa przy placu ćwiczeń koszar - nieśmiertelna, do ćwiczeń i testów.
## Dla broni, umiejętności i efektów legendarnych jest zwykłym wrogiem (da się ją ogłuszyć,
## odepchnąć się nie da), ale nie atakuje, nie alarmuje innych, nie ginie i nie daje łupu.
## Nad nią licznik: obrażenia na sekundę z ostatnich sekund, suma i liczba trafień.
## Po kilku sekundach bez trafień licznik się zeruje.

const DPS_WINDOW := 5.0
const RESET_AFTER := 4.0
const DUMMY_COLOR := Color(0.85, 0.75, 0.5)

## [czas, obrażenia] trafień z ostatnich sekund
var _hits: Array = []
var _total := 0
var _count := 0
var _since_hit := INF
var _clock := 0.0
var _label: Label


func _ready() -> void:
	super()
	quest_kind = "dummy"
	map_color = DUMMY_COLOR
	hurt_radius = 8.0
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(120, 30)
	_label.position = Vector2(-60, -64)
	_label.z_index = 30
	add_child(_label)
	_update_label()


func hurt_center() -> Vector2:
	return global_position + Vector2(0, -14)


## Kukła nikogo nie goni i nikogo nie alarmuje.
func aggro() -> void:
	pass


func take_damage(amount: int, _from_position: Vector2, _knockback := 0.0) -> void:
	Sfx.play_at("dummy", global_position)
	DamageNumber.spawn(get_parent(), hurt_center(), amount)
	_flash()
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "rotation", 0.18 * (1.0 if randf() < 0.5 else -1.0), 0.06)
	tween.tween_property(sprite, "rotation", 0.0, 0.18)
	_hits.append([_clock, amount])
	_total += amount
	_count += 1
	_since_hit = 0.0
	_update_label()


func _physics_process(delta: float) -> void:
	_clock += delta
	_since_hit += delta
	_process_stun(delta)
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	if _since_hit > RESET_AFTER and _count > 0:
		_hits.clear()
		_total = 0
		_count = 0
		_update_label()
	elif _count > 0 and Engine.get_physics_frames() % 15 == 0:
		_update_label()


func _update_label() -> void:
	if _count == 0:
		_label.text = Lang.t("Kukła treningowa")
		return
	while not _hits.is_empty() and _clock - float(_hits[0][0]) > DPS_WINDOW:
		_hits.pop_front()
	var recent := 0
	for hit: Array in _hits:
		recent += int(hit[1])
	var span := clampf(_clock - float(_hits[0][0]) if not _hits.is_empty() else DPS_WINDOW, 1.0, DPS_WINDOW)
	_label.text = Lang.t("DPS: %d\nSuma: %d  •  trafień: %d") % [roundi(recent / span), _total, _count]
