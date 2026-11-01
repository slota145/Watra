class_name SummonCircle
extends Node2D
## Magiczny krąg przyzwania bossa (efekt z kreatora efektów PixelLab - MiscVfx.summon): na ziemi rozbłyska
## krąg run z pentagramem, z kręgu bije słup fioletowego światła, wokół wznoszą się iskry, a na koniec
## błysk z falą - wtedy pojawia się boss (sygnał `summoned`). Krąg dogasa jeszcze chwilę po przyzwaniu.

signal summoned

const CHARGE_TIME := MiscVfx.SUMMON_FLASH
const FADE_TIME := 16.0 / MiscVfx.SUMMON_FPS - CHARGE_TIME
const COLOR := Color(0.72, 0.4, 1.0)
const SHINE := Color(0.95, 0.85, 1.0)

var radius := 34.0
var _t := 0.0
var _done := false


func _ready() -> void:
	z_index = 1
	MiscVfx.summon(self, global_position, radius / 36.0)


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= CHARGE_TIME:
		_done = true
		summoned.emit()
	if _t >= CHARGE_TIME + FADE_TIME:
		queue_free()
