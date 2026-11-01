class_name PropSinks
## Wygenerowane przez tools/pixellab_sheets.py - nie edytować ręcznie.
## Ile pikseli od dołu grafiki leży podstawa obiektu (pień, a nie koniec korzeni). O tyle
## grafika schodzi poniżej punktu, według którego gra ustala, co jest bliżej kamery.

const SINKS := {
	"altar_stump": 7,
	"ancient_stump": 7,
	"ancient_tree": 29,
	"bone_pile": 4,
	"broken_tree": 3,
	"claw_tree": 5,
	"egg_sac": 6,
	"fallen_log": 4,
	"giant_tree_0": 19,
	"giant_tree_1": 24,
	"giant_tree_2": 19,
	"menhir_0": 7,
	"menhir_1": 6,
	"menhir_2": 7,
	"mossy_rock": 5,
	"rotten_stump": 6,
	"skull_totem": 7,
	"tree": 8,
	"web_huge": 17,
	"wrapped_victim": 2,
}


static func of(texture: Texture2D) -> int:
	return SINKS.get(texture.resource_path.get_file().get_basename(), 0)
