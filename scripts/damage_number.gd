class_name DamageNumber
extends Label
## Wyskakujący tekst (obrażenia, zebrane złoto, exp...), który unosi się i znika.

const CRIT_COLOR := Color(1.0, 0.82, 0.25)

## Ustawiane przez gracza na czas zadania ciosu krytycznego (Player.hit_enemy) - liczba wroga
## jest wtedy większa, złota i z wykrzyknikiem, bez zmiany take_damage we wszystkich wrogach.
static var critical := false


static func spawn(parent: Node, pos: Vector2, amount: int, color := Color.WHITE) -> void:
	if critical:
		spawn_text(parent, pos, "%d!" % amount, CRIT_COLOR, 13)
		return
	spawn_text(parent, pos, str(amount), color)


static func spawn_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE, font_size := 10) -> void:
	var label := DamageNumber.new()
	label.text = text
	label.z_index = 50
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.11, 0.17))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 12)
	label.position = pos - Vector2(80, 12) + Vector2(randf_range(-4, 4), 0)
	parent.add_child(label)

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 14, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)
