class_name DamageNumber
extends Node2D
## Wyskakujący tekst (obrażenia, zebrane złoto, exp...), który unosi się i znika.
## Rysowany wprost (draw_string z obwódką), a nie jako Label - czar trafiający dziesiątki wrogów tworzy
## dziesiątki napisów w jednej klatce, a element interfejsu (motyw, układ) kosztuje kilka razy więcej.

const CRIT_COLOR := Color(1.0, 0.82, 0.25)
const OUTLINE_COLOR := Color(0.1, 0.11, 0.17)
const OUTLINE_SIZE := 4
## Wysokość dawnej etykiety - napis stoi tak jak przedtem (górą 12 px nad punktem).
const LINE_HEIGHT := 12.0

## Ustawiane przez gracza na czas zadania ciosu krytycznego (Player.hit_enemy) - liczba wroga
## jest wtedy większa, złota i z wykrzyknikiem, bez zmiany take_damage we wszystkich wrogach.
static var critical := false

var text := ""
var color := Color.WHITE
var font_size := 10


static func spawn(parent: Node, pos: Vector2, amount: int, color := Color.WHITE) -> void:
	if critical:
		spawn_text(parent, pos, "%d!" % amount, CRIT_COLOR, 13)
		return
	spawn_text(parent, pos, str(amount), color)


static func spawn_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE, font_size := 10) -> void:
	var label := DamageNumber.new()
	label.text = text
	label.color = color
	label.font_size = font_size
	label.z_index = 50
	label.position = pos + Vector2(randf_range(-4, 4), 0)
	parent.add_child(label)

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 14, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(-width / 2.0, -LINE_HEIGHT + font.get_ascent(font_size))
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_SIZE, OUTLINE_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
