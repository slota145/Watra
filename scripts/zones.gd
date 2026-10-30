class_name Zones
## Krainy świata i kapliczki odrodzenia. Każda kraina generuje się z tego samego ziarna
## co cały świat, a przejścia między nimi są na krańcach dróg.
## Wszystkie krainy mają ten sam rozmiar i na mapie świata układają się w mozaikę krawędź
## w krawędź (map_offset w kafelkach mapy) - droga z lasu przechodzi prosto w drogę rozlewisk.

const DATA := {
	"forest": {"name": "Gobliński Las", "size": Vector2i(200, 150), "map_offset": Vector2i(0, 0)},
	"swamp": {"name": "Rozlewiska", "size": Vector2i(200, 150), "map_offset": Vector2i(200, 0)},
	"mountains": {"name": "Wietrzne Turnie", "size": Vector2i(200, 150), "map_offset": Vector2i(400, 0)},
	"ancient": {"name": "Prastary Las", "size": Vector2i(200, 150), "map_offset": Vector2i(0, -150)},
	"fields": {"name": "Pola Zbożowe", "size": Vector2i(200, 150), "map_offset": Vector2i(-200, 0)},
}

## Kapliczki odrodzenia - po odkryciu można się do nich teleportować z dużej mapy (M).
const SHRINES := {
	"ostoja": {"zone": "forest", "name": "Ostoja"},
	"swamp_ford": {"zone": "swamp", "name": "Bagienny Bród"},
	"eagle_pass": {"zone": "mountains", "name": "Orla Przełęcz"},
	"old_oak": {"zone": "ancient", "name": "Stary Dąb"},
	"old_mill": {"zone": "fields", "name": "Stary Młyn"},
}


static func zone_name(zone: String) -> String:
	return DATA.get(zone, {}).get("name", zone)


static func size_of(zone: String) -> Vector2i:
	return DATA[zone]["size"]


static func map_offset(zone: String) -> Vector2i:
	return DATA[zone]["map_offset"]


## Zapamiętany obrazek mapy krainy (1 piksel = 1 kafelek) - zapisywany po wygenerowaniu krainy,
## żeby na dużej mapie było widać także krainy, w których akurat nas nie ma.
static func map_cache_path(world_seed: int, zone: String) -> String:
	return "user://map_cache/%d_%s.png" % [world_seed, zone]


static func save_map_cache(world_seed: int, zone: String, image: Image) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://map_cache"))
	image.save_png(map_cache_path(world_seed, zone))


static func load_map_cache(world_seed: int, zone: String) -> Texture2D:
	var path := map_cache_path(world_seed, zone)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	# mapa z innej wersji krainy (inny rozmiar) - nieaktualna
	if image == null or Vector2i(image.get_size()) != size_of(zone):
		return null
	return ImageTexture.create_from_image(image)
