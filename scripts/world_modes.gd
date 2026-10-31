class_name WorldModes
## Tryby symulacji świata MMO (wybór przy nowej grze, zmiana u żercy Wszebora w Ostoi - Travelers.world_mode):
## jak zachowują się inni podróżnicy wobec gracza. Charakter podróżnika (Travelers - "temper": przyjazny, pojedynkowicz,
## zbój) działa tylko tam, gdzie pozwala tryb (Travelers.behavior), a kolor imienia ostrzega, kogo się wystrzegać.

const ORDER: Array[String] = ["calm", "realistic", "hardcore"]
const MODES := {
	"calm": {"name": "Spokojny", "color": Color(0.55, 1.0, 0.6),
		"short": "Wszyscy są życzliwi.",
		"description": "Inni podróżnicy są życzliwi: zapraszają do drużyny, proszą o pomoc, pozdrawiają i dają wskazówki. Nikt cię nie zaczepi ani nie zaatakuje. Dla tych, którzy chcą spokojnie grać i odkrywać świat."},
	"realistic": {"name": "Realistyczny", "color": Color(1.0, 0.85, 0.35),
		"short": "Pojedynki do 10% zdrowia.",
		"description": "Jak w prawdziwym MMO. Część podróżników (żółte imię) lubi się bić i wyzywa cię na pojedynek. Walka trwa, aż ktoś spadnie do 10% zdrowia - nikt nie ginie. Wygrana daje złoto i sławę gildii, a odmowa nic nie kosztuje (najwyżej usłyszysz „Tchórz!”). Nikt nie atakuje bez pytania."},
	"hardcore": {"name": "Hardcorowy", "color": Color(1.0, 0.45, 0.4),
		"short": "Pojedynki i zbóje (PK).",
		"description": "Świat bez litości. Oprócz pojedynków grasują zbóje (czerwone imię), którzy rzucają się na ciebie bez ostrzeżenia - to tzw. PK. Gdy cię pokonają, zabierają 10% złota z sakiewki. Zbój pokonany przez ciebie oddaje więcej: złoto, doświadczenie i czasem przedmiot. Uważaj na czerwone imiona!"},
}
## Charakter podróżnika: kolor imienia i podpis na liście.
const TEMPERS := {
	"friendly": {"name": "przyjazny", "color": Color(0.55, 1.0, 0.6)},
	"duelist": {"name": "pojedynkowicz", "color": Color(1.0, 0.85, 0.35)},
	"bandit": {"name": "zbój", "color": Color(1.0, 0.45, 0.4)},
}
## Złoto zabierane przez zbója, gdy pokona gracza (tryb hardcorowy).
const PK_STEAL := 0.1
