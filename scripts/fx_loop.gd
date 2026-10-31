class_name FxLoop
extends Sprite2D
## Zapętlony efekt z kreatora efektów PixelLab (tools/vfx_art.py): jeden rząd klatek odtwarzany w kółko.
## Punkt zaczepienia `anchor` (piksel klatki) stoi w pozycji węzła - obrót i skala działają wokół niego.

var fps := 12.0
var _time := 0.0


## Nowy efekt: `frames` klatek w rzędzie, `fps` klatek na sekundę.
static func make(sheet: Texture2D, frames: int, frames_per_second: float, anchor: Vector2) -> FxLoop:
	var fx := FxLoop.new()
	fx.texture = sheet
	fx.hframes = frames
	fx.fps = frames_per_second
	fx.centered = false
	fx.offset = -anchor
	return fx


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * fps) % hframes
