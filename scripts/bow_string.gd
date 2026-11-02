class_name BowString
extends Node2D
## Cięciwa łuku w ręku rysowana w kodzie (grafiki łuków są bez cięciwy - tools/bow_strings.py). Węzeł jest dzieckiem
## sprite'a broni (Player.sword), więc obraca się i odbija razem z łukiem. Końce ramion z BowRig; środek cięciwy
## (siodełko) odciągamy o `pull` (0..1) w stronę łucznika, a przy naciągu na cięciwie leży strzała.
## Po puszczeniu cięciwa drga jeszcze przez chwilę (TWANG_TIME).

## Najdalszy naciąg (piksele grafiki łuku - w świecie połowa) i od jakiego naciągu widać strzałę.
const PULL_PX := 16.0
const ARROW_FROM := 0.15
## Strzała: długość i kolory (drzewce, grot, lotki), cięciwa.
const ARROW_LENGTH := 30.0
const SHAFT_COLOR := Color("8a5a2b")
const HEAD_COLOR := Color("c9ccd6")
const FLETCH_COLOR := Color("e8e0c8")
const STRING_COLOR := Color("e2d8bc")
## Grubość linii w pikselach grafiki (łuk jest rysowany w skali 0,5, więc 2 to jeden piksel świata).
const WIDTH := 2.0
## Drganie po puszczeniu: czas, największe wychylenie (piksele grafiki) i szybkość.
const TWANG_TIME := 0.22
const TWANG_PX := 5.0
const TWANG_SPEED := 70.0
## Drżenie przy pełnym naciągu (Grot Swaroga): wychylenie w pikselach grafiki.
const TREMBLE_PX := 1.0

var pull := 0.0:
	set = set_pull
## Pełny naciąg drży (napięte ramię).
var tremble := false
var _top := Vector2.ZERO
var _bottom := Vector2.ZERO
var _has_tips := false
var _twang := 0.0
var _time := 0.0


## Ustawia końce ramion dla grafiki łuku i jej położenia w sprite'cie (offset, odbicie w pionie).
func fit(sprite: Sprite2D) -> void:
	var tips := BowRig.tips(sprite.texture)
	_has_tips = tips.size() == 2
	visible = _has_tips
	if not _has_tips:
		return
	var size := sprite.texture.get_size()
	_top = _local(tips[0], size, sprite)
	_bottom = _local(tips[1], size, sprite)
	queue_redraw()


func _local(p: Vector2, size: Vector2, sprite: Sprite2D) -> Vector2:
	var x := sprite.offset.x - size.x / 2.0 + p.x
	var y := sprite.offset.y + size.y / 2.0 - p.y if sprite.flip_v else sprite.offset.y - size.y / 2.0 + p.y
	return Vector2(x, y)


func set_pull(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	# puszczona cięciwa (spory naciąg -> prawie zero) drga
	if pull > 0.4 and value < 0.1:
		_twang = TWANG_TIME
	pull = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _twang > 0.0:
		_twang = maxf(_twang - delta, 0.0)
		queue_redraw()
	elif tremble and pull > 0.9:
		queue_redraw()


func _draw() -> void:
	if not _has_tips:
		return
	var mid := (_top + _bottom) / 2.0
	# łucznik zawsze po lewej stronie łuku (cel w prawo)
	var nock := mid + Vector2(-PULL_PX * pull, 0.0)
	if _twang > 0.0:
		var fade := _twang / TWANG_TIME
		nock.x += sin(_time * TWANG_SPEED) * TWANG_PX * fade * fade
	elif tremble and pull > 0.9:
		nock.y += sin(_time * 55.0) * TREMBLE_PX
	draw_line(_top, nock, STRING_COLOR, WIDTH)
	draw_line(nock, _bottom, STRING_COLOR, WIDTH)
	if pull >= ARROW_FROM:
		var tip := nock + Vector2(ARROW_LENGTH, 0.0)
		draw_line(nock, tip - Vector2(4.0, 0.0), SHAFT_COLOR, WIDTH)
		draw_line(tip - Vector2(4.0, 0.0), tip, HEAD_COLOR, WIDTH + 1.0)
		draw_line(nock, nock + Vector2(4.0, 0.0), FLETCH_COLOR, WIDTH + 1.0)
