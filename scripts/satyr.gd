class_name Satyr
extends Goblin
## Satyr z wioski satyrów w Wietrznych Turniach: kozionogi, rogaty, wiecznie rozbawiony. Przy ognisku
## tańczy (klatki 4-5), a gdy zobaczy gracza, rusza całą gromadą z maczugą. Silniejszy od ptakoludzi -
## wioska satyrów to najtrudniejsze miejsce w górach poza gniazdem Gromoskrzydłego.

const SATYR_COLOR := Color(0.78, 0.42, 0.85)


func _ready() -> void:
	super()
	equipment_drop_chance = 0.1
	hurt_radius = 8.0
	heart_drop_chance = 0.0
	map_color = SATYR_COLOR
	quest_kind = "satyr"
