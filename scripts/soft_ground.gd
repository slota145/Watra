class_name SoftGround
extends Node2D
## Miękkie przejścia terenu dla wszystkich krain. Kafelki przejść Wang z PixelLab mają kanciaste,
## ośmiokątne cięcia, przez co plamy ciemnej trawy, drogi, błoto, woda czy żwir układały się
## w schodki z kafelków. Warstwa Ground zostaje bez zmian (z niej czytają mapa, przejścia osady
## i krawędzie klifów), ale jest niewidoczna - zamiast niej rysujemy:
## - warstwę bazową: w każdej komórce pełny kafelek najniższego terenu z jej narożników,
## - po jednej warstwie na każdy wyższy teren: pełne kafelki tego terenu, przycięte shaderem
##   (shaders/soft_ground.gdshader) do gładkiego pola narożników z szumem.
## Teren narożników odczytujemy z kafelków Wang (maska NW<<3 | NE<<2 | SW<<1 | SE w kolumnie
## mask % 4 i rzędzie row + mask / 4 zestawu) albo dostajemy wprost od krainy (corners w attach) -
## tak robią góry, których tereny (z dużymi teksturami 64 px) nie mają kafelków w atlasie.

const TILE := 16
## Zestawy Wang w atlasie tiles.png: pierwszy rząd, dolny teren, górny teren.
const SETS := [
	[11, "soil", "moss"], [15, "soil", "leaves"], [19, "soil", "path"],
	[23, "grass", "dark"], [27, "grass", "road"], [31, "grass", "flowers"],
	[35, "grass", "mud"], [39, "mud", "shallow"], [43, "shallow", "deep"],
	[47, "alpine", "rock"], [51, "alpine", "gravel"], [55, "grass", "cobble"],
]
## Kolejność rysowania (wyżej = na wierzchu); przy sprzecznych narożnikach wygrywa wyższy teren.
const ORDER := ["w_deep", "w_shallow", "w_mud", "soil", "grass", "alpine", "flowers", "leaves", "moss", "dark", "mud", "shallow", "deep",
		"gravel", "rock", "road", "path", "cobble",
		"meadow", "m_flowers", "m_dark", "m_scree", "m_rock", "m_snow", "m_path"]
## Tereny rysowane bezszwową teksturą w przestrzeni świata (zamiast kafelków 16 px z atlasu) - góry
## z zestawów PixelLab 64 px (tools/alpine_tiles.py).
const TEXTURES := {
	"meadow": preload("res://assets/mountains/ground/meadow.png"),
	"m_flowers": preload("res://assets/mountains/ground/flowers.png"),
	"m_dark": preload("res://assets/mountains/ground/dark.png"),
	"m_scree": preload("res://assets/mountains/ground/scree.png"),
	"m_rock": preload("res://assets/mountains/ground/rock.png"),
	"m_snow": preload("res://assets/mountains/ground/snow.png"),
	"m_path": preload("res://assets/mountains/ground/path.png"),
}
## Warianty terenów, które są tylko dolne (maska 0 zestawów) - jak dotąd losowane w krainach.
const BASE_ROWS := {"soil": [11, 15, 19], "grass": [23, 27, 31], "alpine": [47, 51]}
## Tereny zagnieżdżone: płycizna i głębia leżą zawsze w błocie, głębia w płyciźnie.
const COVERS := {"mud": ["mud", "shallow", "deep"], "shallow": ["shallow", "deep"]}
## Wygląd brzegu: obwódka (kolor z kryciem w alfie, szerokość), dithering, cień na niższym terenie.
const STYLES := {
	"dark": {"dither": 0.07, "noise": 0.55},
	"flowers": {"dither": 0.09, "noise": 0.6},
	"moss": {"dither": 0.07, "noise": 0.5, "shadow": Color(0.05, 0.03, 0.02, 0.25), "shadow_width": 0.05},
	"leaves": {"dither": 0.08, "noise": 0.55},
	"road": {"rim": Color(0.22, 0.13, 0.07, 0.45), "rim_width": 0.05, "dither": 0.04, "noise": 0.32},
	"path": {"rim": Color(0.12, 0.08, 0.05, 0.4), "rim_width": 0.05, "dither": 0.04, "noise": 0.32},
	"cobble": {"rim": Color(0.1, 0.1, 0.12, 0.55), "rim_width": 0.06, "noise": 0.22,
			"shadow": Color(0.05, 0.08, 0.03, 0.3), "shadow_width": 0.05},
	"mud": {"rim": Color(0.12, 0.07, 0.04, 0.35), "rim_width": 0.05, "dither": 0.05, "noise": 0.4},
	"shallow": {"rim": Color(0.72, 0.84, 0.78, 0.35), "rim_width": 0.045, "noise": 0.32,
			"shadow": Color(0.08, 0.05, 0.03, 0.45), "shadow_width": 0.05},
	"deep": {"rim": Color(0.1, 0.24, 0.22, 0.5), "rim_width": 0.06, "noise": 0.3},
	"rock": {"rim": Color(0.18, 0.18, 0.2, 0.45), "rim_width": 0.05, "noise": 0.4,
			"shadow": Color(0.12, 0.16, 0.05, 0.3), "shadow_width": 0.05},
	"gravel": {"rim": Color(0.3, 0.28, 0.25, 0.35), "rim_width": 0.04, "dither": 0.05, "noise": 0.4},
	# góry: brzeg trawy nad ścieżką i skałą jak w ręcznie malowanych zestawach - poszarpane kępki
	# (drobny szum) z ciemnozielonym obrysem po stronie trawy
	"m_path": {"rim": Color(0.36, 0.22, 0.1, 0.35), "rim_width": 0.035, "noise": 0.35, "fine": 0.22,
			"shadow": Color(0.11, 0.27, 0.08, 1.0), "shadow_width": 0.035},
	"m_rock": {"rim": Color(0.2, 0.2, 0.22, 0.45), "rim_width": 0.04, "noise": 0.4, "fine": 0.12,
			"shadow": Color(0.11, 0.27, 0.08, 1.0), "shadow_width": 0.035},
	"m_scree": {"dither": 0.06, "noise": 0.45, "fine": 0.28},
	"m_dark": {"dither": 0.06, "noise": 0.6, "fine": 0.2},
	"m_flowers": {"dither": 0.08, "noise": 0.6, "fine": 0.15},
	"m_snow": {"rim": Color(0.75, 0.84, 0.95, 0.6), "rim_width": 0.04, "noise": 0.4, "fine": 0.12,
			"shadow": Color(0.25, 0.27, 0.3, 0.6), "shadow_width": 0.035},
	# rozlewiska: woda jest najniższym terenem, a trawa nawisa nad nią skarpą - poszarpany brzeg z ciemnym
	# obrysem i szeroki cień pod skarpą na wodzie; woda faluje i błyska (animate)
	"grass": {"rim": Color(0.07, 0.18, 0.06, 1.0), "rim_width": 0.05, "noise": 0.26, "fine": 0.12,
			"shadow": Color(0.02, 0.07, 0.12, 0.55), "shadow_width": 0.08, "face": 8.0},
	"w_mud": {"rim": Color(0.14, 0.08, 0.04, 0.7), "rim_width": 0.035, "noise": 0.42, "fine": 0.15,
			"shadow": Color(0.02, 0.07, 0.07, 0.45), "shadow_width": 0.07},
	"w_shallow": {"dither": 0.05, "noise": 0.5, "animate": true},
	"w_deep": {"animate": true},
}
const SHADER := preload("res://shaders/soft_ground.gdshader")
## Kafelek-nośnik komórek warstw z teksturą (shader i tak rysuje teksturę terenu).
const FILLER_TILE := Vector2i(0, 47)
const CORNER_OFFSETS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

var _ground: TileMapLayer
## Teren narożników podany przez krainę (Vector2i -> nazwa z ORDER); pusty = odczyt z kafelków Wang.
var _corners := {}
## Góry: teren narożników na granicy poziomów od strony niższego terenu (Vector2i -> nazwa) i wysokości
## komórek. Shader komórki przy wyższej sąsiedniej bierze pole z tych narożników, więc teren płaskowyżu
## nie wylewa się na niższy teren obok krawędzi (i odwrotnie).
var _low_corners := {}
var _levels: Texture2D
## Tekstury terenów podane przez krainę (nazwa z ORDER -> tekstura 64 px): las podmienia nimi kafelki
## atlasu (trawa, ścieżka, ciemna trawa, kwiaty, bruk) - rozmieszczenie terenów się nie zmienia.
var _textures := {}
var _noise: Texture2D
var _set_of_row := {}
var _full_tiles := {}
## Pozycja terenu w ORDER (szybciej niż ORDER.find w pętlach po całej mapie).
var _rank := {}
## Przebudowa zlecona na koniec klatki - kilka zmian naraz (np. wczytanie osady) przebudowuje raz.
var _rebuild_queued := false


## Podpina miękkie podłoże pod warstwę Ground (i ją ukrywa) - woła świat po wygenerowaniu krainy.
static func attach(ground: TileMapLayer, corners := {}, low_corners := {}, levels: Image = null,
		textures := {}) -> SoftGround:
	var soft := SoftGround.new()
	soft._ground = ground
	soft._corners = corners
	soft._low_corners = low_corners
	soft._textures = textures
	if levels != null:
		soft._levels = ImageTexture.create_from_image(levels)
	ground.add_child(soft)
	ground.self_modulate = Color(1, 1, 1, 0)
	soft.rebuild()
	return soft


func _init() -> void:
	for i in ORDER.size():
		_rank[ORDER[i]] = i
	for s: Array in SETS:
		for r in 4:
			_set_of_row[s[0] + r] = s
		_full_tiles.get_or_add(s[2], []).append(Vector2i(3, s[0] + 3))
	for kind: String in BASE_ROWS:
		for row: int in BASE_ROWS[kind]:
			_full_tiles.get_or_add(kind, []).append(Vector2i(0, row))
	var noise := FastNoiseLite.new()
	noise.seed = 1337
	noise.frequency = 0.04
	noise.fractal_octaves = 2
	var image := noise.get_seamless_image(128, 128)
	_noise = ImageTexture.create_from_image(image)


## Zleca przebudowę na koniec klatki - kolejne prośby w tej samej klatce łączą się w jedną.
func queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	rebuild.call_deferred()


## Przebudowuje warstwy z bieżących kafelków Ground (np. po budowie w osadzie).
## Teren narożników i komórek trzymamy w płaskich tablicach (indeks y * szerokość + x) zamiast
## słowników z kluczami Vector2i - przebudowa całej krainy jest przez to kilka razy szybsza.
func rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		child.queue_free()
	var size := _ground.get_used_rect().end
	var w := maxi(size.x, 0)
	var h := maxi(size.y, 0)
	var cw := w + 1
	# teren narożników: pozycja w ORDER (-1 = brak), przy sprzecznych narożnikach wygrywa wyższy teren
	var corner_rank := PackedInt32Array()
	corner_rank.resize(cw * (h + 1))
	corner_rank.fill(-1)
	var wang := PackedByteArray()
	wang.resize(w * h)
	var cells := _ground.get_used_cells()
	if not _corners.is_empty():
		wang.fill(1)
		for corner: Vector2i in _corners:
			if corner.x >= 0 and corner.y >= 0 and corner.x <= w and corner.y <= h:
				corner_rank[corner.y * cw + corner.x] = _rank[_corners[corner]]
	for cell in cells:
		if cell.x < 0 or cell.y < 0 or not _corners.is_empty():
			continue
		var atlas := _ground.get_cell_atlas_coords(cell)
		var s: Array = _set_of_row.get(atlas.y, [])
		if s.is_empty() or atlas.x > 3:
			continue
		var mask: int = (atlas.y - int(s[0])) * 4 + atlas.x
		var low: int = _rank[s[1]]
		var high: int = _rank[s[2]]
		wang[cell.y * w + cell.x] = 1
		var top := cell.y * cw + cell.x
		var idx := PackedInt32Array([top, top + 1, top + cw, top + cw + 1])
		for i in 4:
			var r := high if mask & (8 >> i) else low
			if r > corner_rank[idx[i]]:
				corner_rank[idx[i]] = r
	# narożniki od strony niższego terenu - różnią się tylko na granicach poziomów
	var low_rank := corner_rank.duplicate()
	for corner: Vector2i in _low_corners:
		if corner.x >= 0 and corner.y >= 0 and corner.x <= w and corner.y <= h:
			low_rank[corner.y * cw + corner.x] = _rank[_low_corners[corner]]

	var base := _new_layer()
	# komórki każdej nakładki (wg pozycji terenu w ORDER) i komórki bazowe terenów z teksturą
	var overlays := {}
	var textured_base := {}
	for cell in cells:
		if cell.x < 0 or cell.y < 0 or wang[cell.y * w + cell.x] == 0:
			base.set_cell(cell, 0, _ground.get_cell_atlas_coords(cell), _ground.get_cell_alternative_tile(cell))
			continue
		var top := cell.y * cw + cell.x
		var ranks := [corner_rank[top], corner_rank[top + 1], corner_rank[top + cw], corner_rank[top + cw + 1]]
		if not _low_corners.is_empty():
			ranks.append_array([low_rank[top], low_rank[top + 1], low_rank[top + cw], low_rank[top + cw + 1]])
		var lowest: int = ranks.min()
		if _texture(ORDER[lowest]) != null:
			textured_base.get_or_add(lowest, []).append(cell)
		else:
			base.set_cell(cell, 0, _full_tile(ORDER[lowest], cell))
		for r: int in ranks:
			if r != lowest:
				var list: Array = overlays.get_or_add(r, [])
				if list.is_empty() or list[-1] != cell:
					list.append(cell)
	add_child(base)
	# tereny z teksturą: warstwa bazowa każdego z nich bez przycinania
	for r: int in textured_base:
		var layer := _new_layer()
		for cell: Vector2i in textured_base[r]:
			layer.set_cell(cell, 0, FILLER_TILE)
		layer.material = _material(ORDER[r], null, Vector2i.ONE, true)
		add_child(layer)

	var ranks_sorted: Array = overlays.keys()
	ranks_sorted.sort()
	# pola narożników wszystkich nakładek w jednym przejściu (teren narożnika -> nakładki, które go obejmują);
	# wygładza je dopiero shader (interpolacja Catmulla-Roma), więc obraz zostaje w rozmiarze narożników
	var split := not _low_corners.is_empty() and _levels != null
	var fields := {}
	var low_fields := {}
	var covered_by := {}
	for r: int in ranks_sorted:
		fields[r] = Image.create(cw, h + 1, false, Image.FORMAT_L8)
		if split:
			low_fields[r] = Image.create(cw, h + 1, false, Image.FORMAT_L8)
		for covered: String in COVERS.get(ORDER[r], [ORDER[r]]):
			covered_by.get_or_add(_rank[covered], []).append(r)
	for i in corner_rank.size():
		var r := corner_rank[i]
		if r >= 0 and covered_by.has(r):
			for target: int in covered_by[r]:
				(fields[target] as Image).set_pixel(i % cw, i / cw, Color.WHITE)
		r = low_rank[i]
		if split and r >= 0 and covered_by.has(r):
			for target: int in covered_by[r]:
				(low_fields[target] as Image).set_pixel(i % cw, i / cw, Color.WHITE)
	for r: int in ranks_sorted:
		var kind: String = ORDER[r]
		var field: Image = fields[r]
		var layer := _new_layer()
		# warstwa o komórkę szersza - zaokrąglony brzeg może wyjść nieco poza komórki z narożnikami
		var grown := PackedByteArray()
		grown.resize(w * h)
		for cell: Vector2i in overlays[r]:
			for dy in range(-1, 2):
				var y := cell.y + dy
				if y < 0 or y >= h:
					continue
				for dx in range(-1, 2):
					var x := cell.x + dx
					if x < 0 or x >= w or grown[y * w + x] == 1:
						continue
					grown[y * w + x] = 1
					var spot := Vector2i(x, y)
					layer.set_cell(spot, 0, FILLER_TILE if _texture(kind) != null else _full_tile(kind, spot))
		layer.material = _material(kind, field, Vector2i(cw, h + 1), false, low_fields.get(r))
		add_child(layer)


## Materiał warstwy terenu: `field` - pole narożników przycinające nakładkę, `full` - warstwa bazowa bez
## przycinania (tylko tereny z teksturą), `low_field` - pole dla komórek przy wyższym terenie (góry).
func _material(kind: String, field: Image, corner_count: Vector2i, full: bool, low_field: Image = null) -> ShaderMaterial:
	var style: Dictionary = STYLES.get(kind, {})
	var material := ShaderMaterial.new()
	material.shader = SHADER
	if field != null:
		material.set_shader_parameter("field", ImageTexture.create_from_image(field))
	if low_field != null:
		material.set_shader_parameter("low_field", ImageTexture.create_from_image(low_field))
		material.set_shader_parameter("levels", _levels)
		material.set_shader_parameter("split_levels", true)
	material.set_shader_parameter("noise_tex", _noise)
	material.set_shader_parameter("corner_count", Vector2(corner_count))
	material.set_shader_parameter("full", full)
	if _texture(kind) != null:
		material.set_shader_parameter("use_texture", true)
		material.set_shader_parameter("terrain_tex", _texture(kind))
	material.set_shader_parameter("edge_noise", style.get("noise", 0.4))
	material.set_shader_parameter("fine_noise", style.get("fine", 0.0))
	material.set_shader_parameter("rim_color", style.get("rim", Color(0, 0, 0, 0)))
	material.set_shader_parameter("rim_width", style.get("rim_width", 0.0))
	material.set_shader_parameter("dither_width", style.get("dither", 0.0))
	material.set_shader_parameter("shadow_color", style.get("shadow", Color(0, 0, 0, 0)))
	material.set_shader_parameter("shadow_width", style.get("shadow_width", 0.0))
	material.set_shader_parameter("animate", style.get("animate", false))
	material.set_shader_parameter("face_height", style.get("face", 0.0))
	return material


## Tekstura terenu w przestrzeni świata (podana przez krainę albo z TEXTURES) - null: kafelki z atlasu.
func _texture(kind: String) -> Texture2D:
	return _textures.get(kind, TEXTURES.get(kind))


func _new_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _ground.tile_set
	layer.collision_enabled = false
	layer.navigation_enabled = false
	layer.occlusion_enabled = false
	return layer


## Pełny kafelek terenu - wariant wybierany stale wg położenia komórki.
func _full_tile(kind: String, cell: Vector2i) -> Vector2i:
	var options: Array = _full_tiles[kind]
	return options[absi(hash(cell)) % options.size()]
