extends StaticBody2D
## Przeszkoda na mapie (drzewo, kamień, krzak...). Losuje jedną z podanych tekstur.

@export var textures: Array[Texture2D] = []


func _ready() -> void:
	if not textures.is_empty():
		$Sprite.texture = textures.pick_random()
