class_name Bags
## Torby z łupu (miejsca na torby - Player.bags): 6 rodzajów o stałej pojemności, od Mieszka po Legendarny tobół.
## Wypadają z potworów (ORDER - rodzaj wg poziomu potwora, MONSTER_CHANCE), częściej z bossów (BOSS_CHANCE),
## ze skarbca lochów i skrzyń wydarzeń w świecie; Legendarny tobół tylko z bossów, skarbców i najlepszych skrzyń.
## Wszystkie można też uszyć w oknie Rzemiosła (Crafting) ze skór i innych surowców. Dawne Sakwa i Plecak
## ze sklepu nie są już sprzedawane, ale działają w starszych zapisach.

## Rodzaje od najmniejszej: id, pojemność i poziom potworów, od którego wypada.
const ORDER: Array[String] = ["bag_purse", "bag_satchel", "bag_wanderer", "bag_hunter", "bag_expedition", "bag_legendary"]
const LEVELS := {"bag_purse": 1, "bag_satchel": 8, "bag_wanderer": 16, "bag_hunter": 24, "bag_expedition": 32, "bag_legendary": 30}
## Szansa na torbę ze zwykłego potwora i z bossa; szansa, że boss / skarbiec da Legendarny tobół.
const MONSTER_CHANCE := 0.004
const BOSS_CHANCE := 0.15
const BOSS_LEGENDARY_CHANCE := 0.02
const VAULT_CHANCE := 0.3
const VAULT_LEGENDARY_CHANCE := 0.05
const LEGENDARY := "bag_legendary"


## Zwykła torba dla poziomu potwora: najlepszy dostępny rodzaj (40% - o jeden mniejszy).
static func for_level(level: int) -> String:
	var best := 0
	for i in ORDER.size() - 1:
		if level >= int(LEVELS[ORDER[i]]):
			best = i
	if best > 0 and randf() < 0.4:
		best -= 1
	return ORDER[best]


## Łup z potwora: "" albo torba. `boss` - częściej i z szansą na Legendarny tobół.
static func roll_drop(level: int, boss := false) -> String:
	if boss:
		if level >= int(LEVELS[LEGENDARY]) and randf() < BOSS_LEGENDARY_CHANCE:
			return LEGENDARY
		return for_level(level) if randf() < BOSS_CHANCE else ""
	return for_level(level) if randf() < MONSTER_CHANCE else ""


## Skarbiec lochu i najlepsza skrzynia wydarzenia: torba na poziomie, czasem Legendarny tobół.
static func roll_vault(level: int, factor := 1.0) -> String:
	if randf() < VAULT_LEGENDARY_CHANCE * factor:
		return LEGENDARY
	return for_level(level) if randf() < VAULT_CHANCE * factor else ""
