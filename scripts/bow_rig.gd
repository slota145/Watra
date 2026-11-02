class_name BowRig
## Wygenerowane przez tools/bow_strings.py - nie edytować ręcznie.
## Końce ramion łuków w ręku (piksele grafiki assets/weapons/<łuk>.png, łuk pionowo, cel w prawo):
## tu gra przyczepia cięciwę (BowString).

const TIPS := {
	"bow_t2": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
	"bow_t2_magic": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
	"bow_t2_rare": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
	"bow_t3": [Vector2(1.5, 1.5), Vector2(1.5, 59.5)],
	"bow_t3_magic": [Vector2(1.5, 1.5), Vector2(1.5, 59.5)],
	"bow_t3_rare": [Vector2(1.5, 1.5), Vector2(1.5, 59.5)],
	"bow_t4": [Vector2(13.5, 1.5), Vector2(13.5, 59.5)],
	"bow_t4_magic": [Vector2(12.5, 2.5), Vector2(13.5, 59.5)],
	"bow_t4_rare": [Vector2(11.5, 2.5), Vector2(12.5, 59.5)],
	"bow_t5": [Vector2(1.5, 2.5), Vector2(2.5, 59.5)],
	"bow_t5_magic": [Vector2(0.5, 2.5), Vector2(1.5, 59.5)],
	"bow_t5_rare": [Vector2(0.5, 2.5), Vector2(1.5, 59.5)],
	"legend_devourer_bow": [Vector2(2.5, 2.5), Vector2(1.5, 59.5)],
	"legend_hydra_bow": [Vector2(3.5, 2.5), Vector2(3.5, 59.5)],
	"legend_storm_bow": [Vector2(6.5, 2.5), Vector2(6.5, 59.5)],
	"legend_swarog_bow": [Vector2(3.5, 2.5), Vector2(3.5, 59.5)],
	"short_bow": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
	"short_bow_magic": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
	"short_bow_rare": [Vector2(1.5, 2.5), Vector2(1.5, 59.5)],
}


## Końce ramion łuku z tej grafiki (pusta tablica - nie łuk).
static func tips(texture: Texture2D) -> Array:
	if texture == null:
		return []
	return TIPS.get(texture.resource_path.get_file().get_basename(), [])
