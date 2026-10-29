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
## mask % 4 i rzędzie row + mask / 4 zestawu).

const TILE := 16
## Zestawy Wang w atlasie tiles.png: pierwszy rząd, dolny teren, górny teren.
const SETS := [
	[11, "soil", "moss"], [15, "soil", "leaves"], [19, "soil", "path"],
	[23, "grass", "dark"], [27, "grass", "road"], [31, "grass", "flowers"],
	[35, "grass", "mud"], [39, "mud", "shallow"], [43, "shallow", "deep"],
	[47, "alpine", "rock"], [51, "alpine", "gravel"], [55, "grass", "cobble"],
]
## Kolejność rysowania (wyżej = na wierzchu); przy sprzecznych narożnikach wygrywa wyższy teren.
const ORDER := ["soil", "grass", "alpine", "flowers", "leaves", "moss", "dark", "mud", "shallow", "deep",
		"gravel", "rock", "road", "path", "cobble"]
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
}
const SHADER := preload("res://shaders/soft_ground.gdshader")
const CORNER_OFFSETS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

var _ground: TileMapLayer
var _noise: Texture2D
var _set_of_row := {}
var _full_tiles := {}


## Podpina miękkie podłoże pod warstwę Ground (i ją ukrywa) - woła świat po wygenerowaniu krainy.
static func attach(ground: TileMapLayer) -> SoftGround:
	var soft := SoftGround.new()
	soft._ground = ground
	ground.add_child(soft)
	ground.self_modulate = Color(1, 1, 1, 0)
	soft.rebuild()
	return soft


func _init() -> void:
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


## Przebudowuje warstwy z bieżących kafelków Ground (np. po budowie w osadzie).
func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var used := _ground.get_used_rect()
	var size := used.end
	# teren narożników
	var corners := {}
	var wang := {}
	for cell in _ground.get_used_cells():
		var atlas := _ground.get_cell_atlas_coords(cell)
		var s: Array = _set_of_row.get(atlas.y, [])
		if s.is_empty() or atlas.x > 3:
			continue
		var mask: int = (atlas.y - int(s[0])) * 4 + atlas.x
		wang[cell] = true
		for i in 4:
			var kind: String = s[2] if mask & (8 >> i) else s[1]
			var corner: Vector2i = cell + CORNER_OFFSETS[i]
			var old: String = corners.get(corner, "")
			if old == "" or ORDER.find(kind) > ORDER.find(old):
				corners[corner] = kind

	var base := _new_layer()
	var overlays := {}
	for cell in _ground.get_used_cells():
		if not wang.has(cell):
			base.set_cell(cell, 0, _ground.get_cell_atlas_coords(cell), _ground.get_cell_alternative_tile(cell))
			continue
		var kinds := {}
		var lowest := ""
		for offset in CORNER_OFFSETS:
			var kind: String = corners[cell + offset]
			kinds[kind] = true
			if lowest == "" or ORDER.find(kind) < ORDER.find(lowest):
				lowest = kind
		base.set_cell(cell, 0, _full_tile(lowest, cell))
		for kind: String in kinds:
			if kind != lowest:
				overlays.get_or_add(kind, {})[cell] = true
	add_child(base)

	var kinds_sorted: Array = overlays.keys()
	kinds_sorted.sort_custom(func(a: String, b: String) -> bool: return ORDER.find(a) < ORDER.find(b))
	for kind: String in kinds_sorted:
		var covers: Array = COVERS.get(kind, [kind])
		var field := Image.create(size.x + 1, size.y + 1, false, Image.FORMAT_L8)
		for corner: Vector2i in corners:
			if corner.x <= size.x and corner.y <= size.y and corners[corner] in covers:
				field.set_pixel(corner.x, corner.y, Color.WHITE)
		# gładkie pole: powiększenie z interpolacją dwusześcienną zaokrągla schodki narożników
		field.resize((size.x + 1) * 4, (size.y + 1) * 4, Image.INTERPOLATE_CUBIC)
		var layer := _new_layer()
		var cells: Dictionary = overlays[kind]
		# warstwa o komórkę szersza - zaokrąglony brzeg może wyjść nieco poza komórki z narożnikami
		var grown := {}
		for cell: Vector2i in cells:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					grown[cell + Vector2i(dx, dy)] = true
		for cell: Vector2i in grown:
			if cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y:
				layer.set_cell(cell, 0, _full_tile(kind, cell))
		var style: Dictionary = STYLES.get(kind, {})
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("field", ImageTexture.create_from_image(field))
		material.set_shader_parameter("noise_tex", _noise)
		material.set_shader_parameter("corner_count", Vector2(size + Vector2i.ONE))
		material.set_shader_parameter("edge_noise", style.get("noise", 0.4))
		material.set_shader_parameter("rim_color", style.get("rim", Color(0, 0, 0, 0)))
		material.set_shader_parameter("rim_width", style.get("rim_width", 0.0))
		material.set_shader_parameter("dither_width", style.get("dither", 0.0))
		material.set_shader_parameter("shadow_color", style.get("shadow", Color(0, 0, 0, 0)))
		material.set_shader_parameter("shadow_width", style.get("shadow_width", 0.0))
		layer.material = material
		add_child(layer)


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
