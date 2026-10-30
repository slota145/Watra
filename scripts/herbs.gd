class_name Herbs
## Zielarstwo: dzikie zioła rosnące w krainach (każda kraina ma swoje) i mikstury wzmacniające, które warzy z nich
## zielarka w lecznicy Ostoi. Mikstura to przedmiot do wypicia (można ją położyć na pasku 1-0); daje premię z grupy
## "elixir" (Boons) - krótszą niż posiłek z karczmy (5 minut zamiast 15), ale mocniejszą. Działa jedna naraz.
## Grafiki z PixelLab: tools/herb_art.py (rośliny w świecie i ikony).

## zioło: nazwa, kraina, przedmiot (ziele), grafika rośliny w świecie, ile ziela z jednej rośliny,
## ile roślin w krainie, mikstura.
const KINDS := {
	"wort": {"name": "Dziurawiec", "zone": "forest", "item": "herb_wort", "amount": [1, 2], "count": 45,
			"elixir": "elixir_wort", "plant": preload("res://assets/herbs/wort.png")},
	"chamomile": {"name": "Rumianek", "zone": "fields", "item": "herb_chamomile", "amount": [1, 2], "count": 45,
			"elixir": "elixir_chamomile", "plant": preload("res://assets/herbs/chamomile.png")},
	"calamus": {"name": "Tatarak", "zone": "swamp", "item": "herb_calamus", "amount": [1, 2], "count": 45,
			"elixir": "elixir_calamus", "plant": preload("res://assets/herbs/calamus.png")},
	"arnica": {"name": "Arnika", "zone": "mountains", "item": "herb_arnica", "amount": [1, 2], "count": 40,
			"elixir": "elixir_arnica", "plant": preload("res://assets/herbs/arnica.png")},
	"fern": {"name": "Kwiat paproci", "zone": "ancient", "item": "herb_fern", "amount": [1, 1], "count": 18,
			"elixir": "elixir_fern", "plant": preload("res://assets/herbs/fern.png")},
	"datura": {"name": "Bieluń", "zone": "cemetery", "item": "herb_datura", "amount": [1, 2], "count": 40,
			"elixir": "elixir_datura", "plant": preload("res://assets/herbs/datura.png")},
}
const ORDER: Array[String] = ["wort", "chamomile", "calamus", "arnica", "fern", "datura"]
## Ile ziela i złota (rośnie z poziomem postaci) kosztuje jedna mikstura u zielarki.
const HERBS_PER_ELIXIR := 3
const BREW_GOLD := 15
const BREW_GOLD_PER_LEVEL := 2
## Zioła nie rosną bliżej niż tyle kafelków od siebie ani od brzegu mapy.
const SPACING := 5.0
const EDGE := 8


static func brew_gold(level: int) -> int:
	return BREW_GOLD + BREW_GOLD_PER_LEVEL * (level - 1)


## Zioło rosnące w danej krainie ("" - żadne).
static func kind_in_zone(zone: String) -> String:
	for kind: String in KINDS:
		if KINDS[kind]["zone"] == zone:
			return kind
	return ""
