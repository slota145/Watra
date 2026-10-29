class_name MapView
extends Control
## Rysuje mapę świata ze znacznikami: gracz, gobliny, ogniska, namioty, kapliczka.
## W trybie minimapy podąża za graczem, w trybie dużej mapy pokazuje cały świat.

## true = minimapa (wycinek wokół gracza), false = cała mapa.
@export var follow_player := true
## Ile pikseli ekranu zajmuje jeden kafelek świata.
@export var pixels_per_tile := 2.0
@export var goblin_dot_size := 1.0

const PLAYER_COLOR := Color(1, 1, 1)
const GOBLIN_COLOR := Color(0.95, 0.25, 0.2)
const OUTLINE := Color(0.1, 0.11, 0.17)
const BORDER := Color(0.62, 0.5, 0.32)

var _texture: Texture2D
var _map_size := Vector2i.ONE
var _tile_size := 16.0
var _player: Player
## Każdy znacznik: {"position": Vector2 (świat), "color": Color, "size": float}.
var _markers: Array[Dictionary] = []
## Lewy górny róg widocznego fragmentu (w kafelkach).
var _origin := Vector2.ZERO
## Podświetlony obszar (w kafelkach), np. miejsce zadania; pusty = brak.
var highlight := Rect2()
var highlight_label := ""
var _time := 0.0


func setup(texture: Texture2D, map_size: Vector2i, tile_size: float, player: Player, markers: Array[Dictionary]) -> void:
	_texture = texture
	_map_size = map_size
	_tile_size = tile_size
	_player = player
	_markers = markers
	if not follow_player:
		custom_minimum_size = Vector2(map_size) * pixels_per_tile
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if _texture == null or _player == null:
		return
	var view_tiles := size / pixels_per_tile
	_origin = Vector2.ZERO
	if follow_player:
		_origin = _player.global_position / _tile_size - view_tiles / 2.0
		_origin = _origin.clamp(Vector2.ZERO, (Vector2(_map_size) - view_tiles).max(Vector2.ZERO))

	draw_rect(Rect2(Vector2.ZERO, size), OUTLINE)
	draw_texture_rect_region(_texture, Rect2(Vector2.ZERO, size), Rect2(_origin, view_tiles))

	if highlight.has_area():
		_draw_highlight()
	for marker in _markers:
		_draw_dot(marker["position"], marker["color"], marker["size"])
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		_draw_dot(enemy.global_position, enemy.map_color, goblin_dot_size, false)
	_draw_dot(_player.global_position, PLAYER_COLOR, 2.0)

	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 1.0)


## Pulsujący złoty prostokąt nad obszarem zadania.
func _draw_highlight() -> void:
	var rect := Rect2((highlight.position - _origin) * pixels_per_tile, highlight.size * pixels_per_tile)
	rect = rect.intersection(Rect2(Vector2.ZERO, size))
	if not rect.has_area():
		return
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_rect(rect, Color(1.0, 0.82, 0.3, 0.12 + 0.12 * pulse))
	draw_rect(rect, Color(1.0, 0.85, 0.35, 0.6 + 0.4 * pulse), false, 2.0)
	if highlight_label != "":
		var font := get_theme_default_font()
		var at := rect.position + Vector2(4, 12)
		draw_string_outline(font, at, highlight_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0.1, 0.11, 0.17))
		draw_string(font, at, highlight_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.85, 0.35))


func _draw_dot(world_pos: Vector2, color: Color, dot_size: float, outlined := true) -> void:
	var pos := (world_pos / _tile_size - _origin) * pixels_per_tile
	if not Rect2(Vector2.ZERO, size).grow(-1.0).has_point(pos):
		return
	var half := Vector2.ONE * dot_size
	if outlined:
		draw_rect(Rect2(pos - half - Vector2.ONE, half * 2.0 + Vector2.ONE * 2.0), OUTLINE)
	draw_rect(Rect2(pos - half, half * 2.0), color)
