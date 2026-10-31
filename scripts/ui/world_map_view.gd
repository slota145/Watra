class_name WorldMapView
extends Control
## Duża mapa w dwóch trybach:
## - "zone" - bieżąca kraina w dużej skali,
## - "world" - mozaika wszystkich krain ułożonych krawędź w krawędź (patrz Zones), otoczona
##   nieodkrytym terenem, żeby całość wyglądała jak jeden kontynent. Kraina, w której jeszcze
##   nas nie było, jest zakryta.
## Odkryte kapliczki odrodzenia są ikonami - kliknięcie teleportuje do kapliczki.
## Gracz, wrogowie i znaczniki są rysowane w bieżącej krainie.

signal teleport_requested(shrine_id: String)

const SHRINE_ICON := preload("res://assets/ui/shrine_icon.png")
const ICON_HIT := 8.0
const OUTLINE := Color(0.1, 0.11, 0.17)
const BORDER := Color(0.62, 0.5, 0.32)
## Ile kafelków nieodkrytego terenu otacza krainy na mapie świata.
const WORLD_MARGIN := 40

var mode := "zone"
var pixels_per_tile := 1.0
var tile_size := 16.0
## Podświetlony obszar w kafelkach lasu (miejsce zadania); pusty = brak.
var highlight := Rect2()
var highlight_label := ""

var _seed := 0
var _zone := "forest"
var _textures := {}
var _player: Player
var _markers: Array[Dictionary] = []
## Odkryte kapliczki (id -> [x, y] w kafelkach swojej krainy) - wspólny słownik ze światem.
var _shrines := {}
var _hovered := ""
## Trwające wydarzenie (BigMap.set_event): kraina, miejsce w niej w pikselach świata (INF - środek), tytuł i kolor.
var event_zone := ""
var event_point := Vector2.INF
var event_title := ""
var event_color := Color.WHITE
var _time := 0.0
var _wilds: ImageTexture


func setup(world_seed: int, zone: String, texture: Texture2D, player: Player, markers: Array[Dictionary], shrines: Dictionary) -> void:
	_seed = world_seed
	_zone = zone
	_player = player
	_markers = markers
	_shrines = shrines
	_textures.clear()
	for other: String in Zones.DATA:
		_textures[other] = texture if other == zone else Zones.load_map_cache(world_seed, other)
	custom_minimum_size = view_tiles() * pixels_per_tile
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


## Ile kafelków mapy widać w bieżącym trybie.
func view_tiles() -> Vector2:
	return Vector2(Zones.size_of(_zone)) if mode == "zone" else world_bounds().size


## Prostokąt (w kafelkach) obejmujący wszystkie krainy z marginesem nieodkrytego terenu.
static func world_bounds() -> Rect2:
	var bounds := Rect2()
	for zone: String in Zones.DATA:
		var rect := Rect2(Vector2(Zones.map_offset(zone)), Vector2(Zones.size_of(zone)))
		bounds = rect if not bounds.has_area() else bounds.merge(rect)
	return bounds.grow(WORLD_MARGIN)


## Lewy górny róg krainy w kafelkach widoku.
func _zone_origin(zone: String) -> Vector2:
	if mode == "zone":
		return Vector2.ZERO
	return Vector2(Zones.map_offset(zone)) - world_bounds().position


func _visible_zones() -> Array:
	return [_zone] if mode == "zone" else Zones.DATA.keys()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if _player == null:
		return
	var font := get_theme_default_font()
	if mode == "world":
		draw_texture_rect(_wilds_texture(), Rect2(Vector2.ZERO, view_tiles() * pixels_per_tile), false)
	for zone: String in _visible_zones():
		var rect := Rect2(_zone_origin(zone) * pixels_per_tile, Vector2(Zones.size_of(zone)) * pixels_per_tile)
		var texture: Texture2D = _textures.get(zone)
		if texture != null:
			draw_texture_rect(texture, rect, false)
		else:
			# kraina jeszcze nieodkryta - zamglona, ze znakiem zapytania
			draw_rect(rect, Color(0.1, 0.12, 0.13, 0.75))
			_text(font, rect.get_center() + Vector2(-4, 6), "?", 16, Color(0.6, 0.62, 0.68))
		if mode == "world":
			draw_rect(rect, Color(BORDER, 0.9 if zone == _zone else 0.45), false, 1.0)

	if highlight.has_area() and "forest" in _visible_zones():
		_draw_highlight(font)
	var origin := _zone_origin(_zone)
	for marker in _markers:
		_dot(marker["position"] / tile_size + origin, marker["color"], marker["size"])
	for enemy: Goblin in get_tree().get_nodes_in_group("enemies"):
		_dot(enemy.global_position / tile_size + origin, enemy.map_color, 1.0, false)
	_dot(_player.global_position / tile_size + origin, Color.WHITE, 2.0)

	for id: String in _shrines:
		if not Zones.SHRINES[id]["zone"] in _visible_zones():
			continue
		var pos := _shrine_screen_pos(id)
		var bright := id == _hovered
		var icon_size := Vector2(14, 14) * (1.25 if bright else 1.0)  # ikona ma 64 px
		draw_texture_rect(SHRINE_ICON, Rect2(pos - icon_size / 2.0, icon_size), false,
				Color(1.3, 1.3, 1.3) if bright else Color.WHITE)
	# nazwy krain na środku górnej krawędzi, nad znacznikami
	if mode == "world":
		for zone: String in Zones.DATA:
			var rect := Rect2(_zone_origin(zone) * pixels_per_tile, Vector2(Zones.size_of(zone)) * pixels_per_tile)
			var zone_name := Zones.zone_name(zone)
			var width := font.get_string_size(zone_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			_text(font, Vector2(rect.get_center().x - width / 2.0, rect.position.y + 11), zone_name, 8, Color(1.0, 0.9, 0.6))
	if event_zone != "" and event_zone in _visible_zones():
		var local := event_point / tile_size if event_point != Vector2.INF else Vector2(Zones.size_of(event_zone)) / 2.0
		var at := (local + _zone_origin(event_zone)) * pixels_per_tile
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		draw_arc(at, 6.0 + 4.0 * pulse, 0.0, TAU, 20, event_color, 2.0)
		draw_circle(at, 3.0, event_color)
		_text(font, at + Vector2(10, 4), event_title, 8, event_color)
	if _hovered != "":
		var pos := _shrine_screen_pos(_hovered)
		_text(font, pos + Vector2(10, -6), "Teleport: " + Zones.SHRINES[_hovered]["name"], 8, Color(0.6, 0.9, 1.0))


## Nieodkryty teren wokół krain: ciemny, zamglony las (rysowany raz).
func _wilds_texture() -> ImageTexture:
	if _wilds != null:
		return _wilds
	var tiles := Vector2i(world_bounds().size)
	var noise := FastNoiseLite.new()
	noise.seed = 1234
	noise.frequency = 0.06
	var image := Image.create(tiles.x, tiles.y, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for y in tiles.y:
		for x in tiles.x:
			var n := noise.get_noise_2d(x, y)
			var color := Color("24402a").lerp(Color("355a36"), clampf(n + 0.5, 0.0, 1.0))
			if rng.randf() < 0.18:
				color = color.darkened(0.25)
			image.set_pixel(x, y, color.lerp(Color(0.16, 0.18, 0.2), 0.45))
	_wilds = ImageTexture.create_from_image(image)
	return _wilds


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hovered = _shrine_at(event.position)
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var id := _shrine_at(click.position)
		if id != "":
			teleport_requested.emit(id)
			accept_event()


func _shrine_at(pos: Vector2) -> String:
	for id: String in _shrines:
		if Zones.SHRINES[id]["zone"] in _visible_zones() and _shrine_screen_pos(id).distance_to(pos) <= ICON_HIT:
			return id
	return ""


func _shrine_screen_pos(id: String) -> Vector2:
	var tile: Array = _shrines[id]
	return (Vector2(tile[0], tile[1]) + _zone_origin(Zones.SHRINES[id]["zone"])) * pixels_per_tile


## Pulsujący złoty prostokąt nad obszarem zadania (zadania są w lesie).
func _draw_highlight(font: Font) -> void:
	var rect := Rect2((highlight.position + _zone_origin("forest")) * pixels_per_tile, highlight.size * pixels_per_tile)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_rect(rect, Color(1.0, 0.82, 0.3, 0.12 + 0.12 * pulse))
	draw_rect(rect, Color(1.0, 0.85, 0.35, 0.6 + 0.4 * pulse), false, 2.0)
	if highlight_label != "":
		_text(font, rect.position + Vector2(4, 12), highlight_label, 8, Color(1.0, 0.85, 0.35))


func _dot(tile: Vector2, color: Color, dot_size: float, outlined := true) -> void:
	var pos := tile * pixels_per_tile
	var half := Vector2.ONE * dot_size
	if outlined:
		draw_rect(Rect2(pos - half - Vector2.ONE, half * 2.0 + Vector2.ONE * 2.0), OUTLINE)
	draw_rect(Rect2(pos - half, half * 2.0), color)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, OUTLINE)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
