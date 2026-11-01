class_name SkillTree
## Drzewka umiejętności broni - sieć węzłów jak drzewko pasywne w Path of Exile, tylko mniejsza. Węzeł kupuje się za
## punkt umiejętności (1 za każdy poziom postaci, plus START_POINTS), ale tylko obok węzła już wybranego (start jest
## wybrany zawsze). Rodzaje węzłów:
## - "skill": odblokowuje umiejętność (poziom 1; dalsze poziomy 2-5 za złoto jak dotąd),
## - "passive": stałe premie (statystyki jak na przedmiotach albo premie do umiejętności - TREE_STATS),
## - "keystone": węzeł kluczowy - zmienia sposób gry (np. Nieustający Wir),
## - "socket": gniazdo na kamień szlachetny (Gems) - kamień działa w drzewku o połowę mocniej (SkillBook.tree_bonus);
##   gniazdo "legendary" stoi za węzłem kluczowym (później przyjmie też esencję legendy), a kamień promienia wzmacnia
##   wybrane węzły pasywne w swoim promieniu.
## Premie działają tylko z założoną bronią swojego rodzaju. Wybrane węzły cofa za złoto mędrzec w Ostoi.
## Drzewka mają wszystkie rodzaje broni: miecz (broń biała), łuk i księga magii.

const START_POINTS := 1
## Ile złota kosztuje zapomnienie drzewka u mędrca (za każdy poziom postaci).
const RESPEC_GOLD_PER_LEVEL := 25

## Premie z węzłów, które nie są statystykami postaci, tylko zmieniają umiejętności (czytane przez SkillBook.tree_bonus).
## Wartości to ułamki (+0.2 = +20%), poza combo_window (sekundy) i COUNT_STATS (sztuki).
const TREE_STATS := {
	"whirl_radius": "Zasięg Młynka", "whirl_damage": "Obrażenia Młynka", "flicker_mana": "Mana za skok Mgnienia",
	"flicker_damage": "Obrażenia Mgnienia", "smoke_charge": "Szybkość ładowania Dymnych Wybuchów",
	"smoke_damage": "Obrażenia Dymnych Wybuchów", "combo_window": "Dłuższe okno combo", "combo_damage": "Obrażenia ciosów combo",
	"bleed_damage": "Obrażenia krwawienia", "cry_power": "Premia Zewu Peruna", "slam_stun": "Ogłuszenie Rozłupania Ziemi",
	"lunge_cooldown": "Odnowienie Szarży", "riposte_damage": "Obrażenia kontry Riposty", "blade_count": "Widmowe ostrza",
	"multishot_arrows": "Strzały Salwy", "multishot_damage": "Obrażenia Salwy", "rain_damage": "Obrażenia Deszczu Strzał",
	"rain_area": "Krąg Deszczu Strzał", "seeker_hits": "Trafienia Strzały tropiącej", "falcon_damage": "Obrażenia Sokoła",
	"wind_damage": "Obrażenia Strzały Wichru", "power_charge": "Szybkość napinania Grotu Swaroga",
	"power_damage": "Obrażenia Grotu Swaroga", "arrow_pierce": "Strzały przebijają wrogów", "arrow_range": "Zasięg strzał",
	"ballista_damage": "Obrażenia Balisty", "ballista_time": "Czas Balisty", "snare_time": "Unieruchomienie Sideł",
	"venom_damage": "Obrażenia Jadowych Grotów", "vault_cooldown": "Odnowienie Odskoku",
	"fireball_charge": "Szybkość ładowania Kuli ognia", "fireball_damage": "Obrażenia Kuli ognia", "burn_damage": "Obrażenia podpalenia",
	"meteor_radius": "Wybuch Spadającej Gwiazdy", "shield_share": "Ciosy przyjmowane przez Tarczę Many",
	"blink_cooldown": "Odnowienie Kroku przez Mgłę", "rune_bonus": "Moc Kamienia Runicznego", "chain_targets": "Cele Łańcucha błyskawic",
	"storm_time": "Czas Burzy Peruna", "orb_damage": "Obrażenia Kuli Piorunów", "lance_damage": "Obrażenia Włóczni Marzanny",
	"chill_time": "Czas spowolnienia", "lance_pierce": "Włócznia przebija wrogów", "blizzard_damage": "Obrażenia Zamieci",
	"blizzard_time": "Czas Zamieci",
}
const COUNT_STATS := ["blade_count", "multishot_arrows", "seeker_hits", "arrow_pierce", "chain_targets", "lance_pierce"]

## Węzły: pozycja w siatce drzewka (jednostki - SkillTreeView), połączenia, rodzaj, nazwa / umiejętność, premie, opis.
## Gałęzie miecza: zachód - Wir (Młynek, Mgnienie, Nieustający Wir), północny zachód - Krew i okrzyk (Zew Peruna,
## Krwawy Szał przez Rozpłatanie), północny wschód - Ostrze (Szarża, Półksiężyc, Rozłupanie Ziemi, Riposta, Taniec Ostrzy),
## południowy wschód - Dym (Dymne Wybuchy, Widmowe Ostrza, czary, Dym i Cień), południowy zachód - obrona.
const TREES := {
	"melee": {
		"start": {"pos": Vector2(0, 0), "kind": "start", "name": "Ścieżka miecza", "links": ["whirlwind", "lunge", "smoke_burst", "warrior_blood", "battle_focus"],
				"description": "Początek drzewka miecza (zwykły atak). Wybieraj węzły połączone z już wybranymi."},
		"warrior_blood": {"pos": Vector2(-1.1, -1.6), "kind": "skill", "skill": "warrior_blood", "links": ["hp_1"]},
		"socket_1": {"pos": Vector2(-3.0, -1.5), "kind": "socket", "name": "Gniazdo", "links": ["hp_1", "whirl_reach"]},
		"socket_2": {"pos": Vector2(3.5, 0.0), "kind": "socket", "name": "Gniazdo", "links": ["crit_1", "smoke_dmg"]},
		"socket_legend": {"pos": Vector2(-8.0, 0.0), "kind": "socket", "legendary": true, "name": "Gniazdo legendarne", "links": ["endless_whirl"]},
		"battle_focus": {"pos": Vector2(-1.1, 1.6), "kind": "skill", "skill": "battle_focus", "links": ["rend", "armor_1"]},
		# ---- Wir
		"whirlwind": {"pos": Vector2(-1.6, 0), "kind": "skill", "skill": "whirlwind", "links": ["phys_1"]},
		"phys_1": {"pos": Vector2(-3.0, 0), "kind": "passive", "name": "Ostra stal", "stats": {"physical_damage": 0.08}, "links": ["whirl_reach", "flicker"]},
		"whirl_reach": {"pos": Vector2(-4.3, -1.0), "kind": "passive", "name": "Szeroki zamach", "stats": {"whirl_radius": 0.2}, "links": ["whirl_dmg"]},
		"flicker": {"pos": Vector2(-4.3, 1.0), "kind": "skill", "skill": "flicker", "links": ["flicker_focus", "rend"]},
		"whirl_dmg": {"pos": Vector2(-5.6, -1.6), "kind": "passive", "name": "Wirujące ostrze", "stats": {"whirl_damage": 0.2}, "links": ["endless_whirl", "phys_2"]},
		"flicker_focus": {"pos": Vector2(-5.6, 1.6), "kind": "passive", "name": "Lekki krok", "stats": {"flicker_mana": -0.25}, "links": ["endless_whirl", "flicker_dmg"]},
		"endless_whirl": {"pos": Vector2(-6.6, 0), "kind": "keystone", "name": "Nieustający Wir", "links": [],
				"description": "Mgnienie w trakcie Młynka nie ma odnowienia - skaczesz, dopóki trzymasz klawisz. Młynek zużywa dwa razy więcej many."},
		"phys_2": {"pos": Vector2(-7.0, -2.6), "kind": "passive", "name": "Hartowana stal", "stats": {"physical_damage": 0.1}, "links": ["life_hit"]},
		"flicker_dmg": {"pos": Vector2(-7.0, 2.6), "kind": "passive", "name": "Cięcie z cienia", "stats": {"flicker_damage": 0.2}, "links": ["move_1"]},
		"life_hit": {"pos": Vector2(-8.4, -1.4), "kind": "passive", "name": "Krew za krew", "stats": {"life_on_hit": 3.0}, "links": []},
		"move_1": {"pos": Vector2(-8.4, 1.4), "kind": "passive", "name": "Wiatr w nogach", "stats": {"move_speed": 0.05}, "links": []},
		# ---- Krew i okrzyk
		"hp_1": {"pos": Vector2(-2.4, -2.7), "kind": "passive", "name": "Twarda skóra", "stats": {"health_percent": 0.05}, "links": ["war_cry", "regen_1"]},
		"war_cry": {"pos": Vector2(-3.8, -2.9), "kind": "skill", "skill": "war_cry", "links": ["cry_power"]},
		"regen_1": {"pos": Vector2(-1.4, -3.8), "kind": "passive", "name": "Szybkie gojenie", "stats": {"health_regen": 1.5}, "links": ["hp_2"]},
		"cry_power": {"pos": Vector2(-4.6, -4.1), "kind": "passive", "name": "Głos burzy", "stats": {"cry_power": 0.1}, "links": ["hp_2"]},
		"hp_2": {"pos": Vector2(-3.0, -4.6), "kind": "passive", "name": "Niezłomny", "stats": {"health": 40.0}, "links": []},
		"rend": {"pos": Vector2(-2.8, 2.7), "kind": "skill", "skill": "rend", "links": ["bleed_1"]},
		"bleed_1": {"pos": Vector2(-4.2, 3.6), "kind": "passive", "name": "Głębokie rany", "stats": {"bleed_damage": 0.25}, "links": ["blood_frenzy"]},
		"blood_frenzy": {"pos": Vector2(-5.7, 3.9), "kind": "keystone", "name": "Krwawy Szał", "links": [],
				"description": "Krwawienie wrogów cię leczy: wracasz do zdrowia o 30% zadanych nim obrażeń."},
		# ---- Ostrze
		"lunge": {"pos": Vector2(1.1, -1.4), "kind": "skill", "skill": "lunge", "links": ["crescent", "speed_1"]},
		"crescent": {"pos": Vector2(2.6, -1.4), "kind": "skill", "skill": "crescent", "links": ["combo_1", "crit_1"]},
		"speed_1": {"pos": Vector2(1.1, -2.8), "kind": "passive", "name": "Szybkie ręce", "stats": {"attack_speed": 0.06}, "links": ["combo_1", "speed_2"]},
		"combo_1": {"pos": Vector2(2.6, -2.8), "kind": "passive", "name": "Płynne przejścia", "stats": {"combo_window": 0.4}, "links": ["ground_slam", "lunge_cd"]},
		"crit_1": {"pos": Vector2(4.0, -1.4), "kind": "passive", "name": "Oko kata", "stats": {"crit_chance": 0.04}, "links": ["ground_slam", "crit_2"]},
		"ground_slam": {"pos": Vector2(4.0, -2.8), "kind": "skill", "skill": "ground_slam", "links": ["slam_stun"]},
		"slam_stun": {"pos": Vector2(5.4, -3.6), "kind": "passive", "name": "Drżąca ziemia", "stats": {"slam_stun": 0.5}, "links": ["blade_dance", "combo_2"]},
		"speed_2": {"pos": Vector2(1.1, -4.2), "kind": "passive", "name": "Błyskawiczne ręce", "stats": {"attack_speed": 0.06}, "links": ["lunge_cd"]},
		"lunge_cd": {"pos": Vector2(2.6, -4.2), "kind": "passive", "name": "Szybki wypad", "stats": {"lunge_cooldown": -0.25}, "links": ["blade_dance"]},
		"blade_dance": {"pos": Vector2(4.0, -4.5), "kind": "keystone", "name": "Taniec Ostrzy", "links": [],
				"description": "Każde combo daje +5% szybkości ataku na 4 s (do 5 razy naraz)."},
		"combo_2": {"pos": Vector2(6.8, -3.8), "kind": "passive", "name": "Mistrz przejść", "stats": {"combo_damage": 0.15}, "links": []},
		"crit_2": {"pos": Vector2(5.4, -1.4), "kind": "passive", "name": "Cios w serce", "stats": {"crit_damage": 0.3}, "links": ["riposte", "cdr_1"]},
		"riposte": {"pos": Vector2(6.8, -2.0), "kind": "skill", "skill": "riposte", "links": ["riposte_power", "armor_2"]},
		"riposte_power": {"pos": Vector2(8.2, -2.6), "kind": "passive", "name": "Mistrz szermierki", "stats": {"riposte_damage": 0.5}, "links": []},
		"armor_2": {"pos": Vector2(8.2, -1.0), "kind": "passive", "name": "Pancerna postawa", "stats": {"armor": 10.0}, "links": []},
		"cdr_1": {"pos": Vector2(6.8, -0.5), "kind": "passive", "name": "Rytm walki", "stats": {"cooldown_reduction": 0.05}, "links": []},
		# ---- Dym
		"smoke_burst": {"pos": Vector2(1.1, 1.4), "kind": "skill", "skill": "smoke_burst", "links": ["smoke_charge", "spell_1"]},
		"smoke_charge": {"pos": Vector2(2.6, 1.4), "kind": "passive", "name": "Gęsty dym", "stats": {"smoke_charge": 0.25}, "links": ["cast_1", "smoke_dmg"]},
		"spell_1": {"pos": Vector2(1.1, 2.8), "kind": "passive", "name": "Szept run", "stats": {"spell_damage": 0.08}, "links": ["cast_1", "spell_2"]},
		"cast_1": {"pos": Vector2(2.6, 2.8), "kind": "passive", "name": "Bystry umysł", "stats": {"cast_speed": 0.08}, "links": ["spectral_blades", "cast_2"]},
		"smoke_dmg": {"pos": Vector2(4.0, 1.4), "kind": "passive", "name": "Duszący dym", "stats": {"smoke_damage": 0.2}, "links": ["smoke_shadow", "spectral_blades"]},
		"smoke_shadow": {"pos": Vector2(5.5, 0.7), "kind": "keystone", "name": "Dym i Cień", "links": [],
				"description": "Po Dymnych Wybuchach zostaje chmura dymu na 5 s: w niej masz +30% szansy na unik, a Mgnienie nie zużywa many."},
		"spectral_blades": {"pos": Vector2(4.0, 2.8), "kind": "skill", "skill": "spectral_blades", "links": ["blades_count"]},
		"blades_count": {"pos": Vector2(5.4, 3.6), "kind": "passive", "name": "Czwarte ostrze", "stats": {"blade_count": 1.0}, "links": ["mana_regen"]},
		"spell_2": {"pos": Vector2(1.1, 4.2), "kind": "passive", "name": "Pieśń run", "stats": {"spell_damage": 0.1}, "links": ["cast_2"]},
		"cast_2": {"pos": Vector2(2.6, 4.2), "kind": "passive", "name": "Szybkie słowa", "stats": {"cast_speed": 0.08}, "links": ["mana_regen"]},
		"mana_regen": {"pos": Vector2(4.0, 4.5), "kind": "passive", "name": "Źródło mocy", "stats": {"mana_regen": 1.5}, "links": []},
		# ---- Obrona
		"armor_1": {"pos": Vector2(-1.3, 3.5), "kind": "passive", "name": "Kolczuga pod skórą", "stats": {"armor": 8.0}, "links": ["dodge_1", "mana_1"]},
		"dodge_1": {"pos": Vector2(-2.7, 4.4), "kind": "passive", "name": "Unik szermierza", "stats": {"dodge_chance": 0.03}, "links": []},
		"mana_1": {"pos": Vector2(-0.1, 4.6), "kind": "passive", "name": "Głęboki oddech", "stats": {"mana": 20.0}, "links": []},
	},
	## Gałęzie łuku: zachód - Grad (Salwa, Deszcz Strzał, Grad), północny zachód - Sidła i zdrowie, południowy zachód -
	## Jad i cień (Jadowe Groty, Odskok, Myśliwy z Cienia), północny wschód - Tropiciel (Strzała tropiąca, Sokół,
	## Strzała Wichru, Oko Sokoła), południowy wschód - Myśliwy (Grot Swaroga, Balista, Strzelanie w biegu).
	"bow": {
		"start": {"pos": Vector2(0, 0), "kind": "start", "name": "Ścieżka łuku", "links": ["multishot", "seeker", "power_shot", "hunter_breath", "hunter_patience"],
				"description": "Początek drzewka łuku (zwykły strzał). Wybieraj węzły połączone z już wybranymi."},
		"hunter_breath": {"pos": Vector2(-1.1, -1.6), "kind": "skill", "skill": "hunter_breath", "links": ["hp_b1"]},
		"socket_1": {"pos": Vector2(-3.0, -1.5), "kind": "socket", "name": "Gniazdo", "links": ["hp_b1", "multi_arrows"]},
		"socket_2": {"pos": Vector2(3.5, 0.0), "kind": "socket", "name": "Gniazdo", "links": ["crit_b1", "power_dmg"]},
		"socket_legend": {"pos": Vector2(-8.0, 0.0), "kind": "socket", "legendary": true, "name": "Gniazdo legendarne", "links": ["hail"]},
		"hunter_patience": {"pos": Vector2(-1.1, 1.6), "kind": "skill", "skill": "hunter_patience", "links": ["venom_arrows", "mana_b1"]},
		# ---- Grad
		"multishot": {"pos": Vector2(-1.6, 0), "kind": "skill", "skill": "multishot", "links": ["phys_b1"]},
		"phys_b1": {"pos": Vector2(-3.0, 0), "kind": "passive", "name": "Ostre groty", "stats": {"physical_damage": 0.08}, "links": ["multi_arrows", "arrow_rain"]},
		"multi_arrows": {"pos": Vector2(-4.3, -1.0), "kind": "passive", "name": "Pełny kołczan", "stats": {"multishot_arrows": 1.0}, "links": ["multi_dmg"]},
		"arrow_rain": {"pos": Vector2(-4.3, 1.0), "kind": "skill", "skill": "arrow_rain", "links": ["rain_dmg"]},
		"multi_dmg": {"pos": Vector2(-5.6, -1.6), "kind": "passive", "name": "Zgrana cięciwa", "stats": {"multishot_damage": 0.2}, "links": ["hail", "aspd_b1"]},
		"rain_dmg": {"pos": Vector2(-5.6, 1.6), "kind": "passive", "name": "Stalowa ulewa", "stats": {"rain_damage": 0.2}, "links": ["hail", "rain_area"]},
		"hail": {"pos": Vector2(-6.6, 0), "kind": "keystone", "name": "Grad", "links": [],
				"description": "Salwa wypuszcza 2 strzały więcej, a Deszcz Strzał pada o połowę gęściej, ale każda strzała zadaje 20% mniej obrażeń."},
		"aspd_b1": {"pos": Vector2(-7.0, -2.6), "kind": "passive", "name": "Szybka cięciwa", "stats": {"attack_speed": 0.06}, "links": ["crit_b0"]},
		"rain_area": {"pos": Vector2(-7.0, 2.6), "kind": "passive", "name": "Szeroka ulewa", "stats": {"rain_area": 0.25}, "links": ["crit_dmg_b"]},
		"crit_b0": {"pos": Vector2(-8.4, -1.4), "kind": "passive", "name": "Celne oko", "stats": {"crit_chance": 0.04}, "links": []},
		"crit_dmg_b": {"pos": Vector2(-8.4, 1.4), "kind": "passive", "name": "Grot w serce", "stats": {"crit_damage": 0.3}, "links": []},
		# ---- Sidła i zdrowie
		"hp_b1": {"pos": Vector2(-2.4, -2.7), "kind": "passive", "name": "Twardy myśliwy", "stats": {"health_percent": 0.05}, "links": ["snare", "regen_b1"]},
		"snare": {"pos": Vector2(-3.8, -2.9), "kind": "skill", "skill": "snare", "links": ["snare_time"]},
		"regen_b1": {"pos": Vector2(-1.4, -3.8), "kind": "passive", "name": "Leśne zioła", "stats": {"health_regen": 1.5}, "links": ["hp_b2"]},
		"snare_time": {"pos": Vector2(-4.6, -4.1), "kind": "passive", "name": "Mocne sprężyny", "stats": {"snare_time": 0.3}, "links": ["hp_b2"]},
		"hp_b2": {"pos": Vector2(-3.0, -4.6), "kind": "passive", "name": "Wytrwały", "stats": {"health": 40.0}, "links": []},
		# ---- Jad i cień
		"venom_arrows": {"pos": Vector2(-2.8, 2.7), "kind": "skill", "skill": "venom_arrows", "links": ["venom_dmg"]},
		"venom_dmg": {"pos": Vector2(-4.2, 3.6), "kind": "passive", "name": "Jad żmii", "stats": {"venom_damage": 0.3}, "links": ["shadow_hunter"]},
		"shadow_hunter": {"pos": Vector2(-5.7, 3.9), "kind": "keystone", "name": "Myśliwy z Cienia", "links": [],
				"description": "Po Odskoku wrogowie na 2 s tracą cię z oczu, a pierwsze trafienie zadaje podwójne obrażenia."},
		"mana_b1": {"pos": Vector2(-1.3, 3.5), "kind": "passive", "name": "Spokojny oddech", "stats": {"mana": 20.0}, "links": ["vault", "dodge_b1"]},
		"vault": {"pos": Vector2(-2.7, 4.4), "kind": "skill", "skill": "vault", "links": ["vault_cd"]},
		"vault_cd": {"pos": Vector2(-4.0, 4.9), "kind": "passive", "name": "Lekkie nogi", "stats": {"vault_cooldown": -0.25}, "links": ["shadow_hunter"]},
		"dodge_b1": {"pos": Vector2(-0.1, 4.6), "kind": "passive", "name": "Zwinność rysia", "stats": {"dodge_chance": 0.03}, "links": []},
		# ---- Tropiciel
		"seeker": {"pos": Vector2(1.1, -1.4), "kind": "skill", "skill": "seeker", "links": ["rapid_volley", "speed_b1"]},
		"rapid_volley": {"pos": Vector2(2.6, -1.4), "kind": "skill", "skill": "rapid_volley", "links": ["combo_b1", "crit_b1"]},
		"speed_b1": {"pos": Vector2(1.1, -2.8), "kind": "passive", "name": "Szybkie palce", "stats": {"attack_speed": 0.06}, "links": ["combo_b1", "speed_b2"]},
		"combo_b1": {"pos": Vector2(2.6, -2.8), "kind": "passive", "name": "Łowiecki rytm", "stats": {"combo_window": 0.4}, "links": ["falcon", "seeker_hits"]},
		"crit_b1": {"pos": Vector2(4.0, -1.4), "kind": "passive", "name": "Oko tropiciela", "stats": {"crit_chance": 0.04}, "links": ["falcon", "crit_b2"]},
		"falcon": {"pos": Vector2(4.0, -2.8), "kind": "skill", "skill": "falcon", "links": ["falcon_power"]},
		"falcon_power": {"pos": Vector2(5.4, -3.6), "kind": "passive", "name": "Ostre szpony", "stats": {"falcon_damage": 0.3}, "links": ["falcon_eye", "combo_b2"]},
		"speed_b2": {"pos": Vector2(1.1, -4.2), "kind": "passive", "name": "Błyskawiczna cięciwa", "stats": {"attack_speed": 0.06}, "links": ["seeker_hits"]},
		"seeker_hits": {"pos": Vector2(2.6, -4.2), "kind": "passive", "name": "Uparta strzała", "stats": {"seeker_hits": 2.0}, "links": ["falcon_eye"]},
		"falcon_eye": {"pos": Vector2(4.0, -4.5), "kind": "keystone", "name": "Oko Sokoła", "links": [],
				"description": "Trafienia wrogów daleko od ciebie (ponad 150) są zawsze krytyczne, ale bliskie (do 70) zadają 30% mniej obrażeń."},
		"combo_b2": {"pos": Vector2(6.8, -3.8), "kind": "passive", "name": "Mistrz łowów", "stats": {"combo_damage": 0.15}, "links": []},
		"crit_b2": {"pos": Vector2(5.4, -1.4), "kind": "passive", "name": "Śmiertelny grot", "stats": {"crit_damage": 0.3}, "links": ["wind_arrow", "cdr_b"]},
		"wind_arrow": {"pos": Vector2(6.8, -2.0), "kind": "skill", "skill": "wind_arrow", "links": ["wind_power", "spell_b1"]},
		"wind_power": {"pos": Vector2(8.2, -2.6), "kind": "passive", "name": "Wicher Strzyboga", "stats": {"wind_damage": 0.3}, "links": []},
		"spell_b1": {"pos": Vector2(8.2, -1.0), "kind": "passive", "name": "Szept wiatru", "stats": {"spell_damage": 0.1}, "links": []},
		"cdr_b": {"pos": Vector2(6.8, -0.5), "kind": "passive", "name": "Rytm łowów", "stats": {"cooldown_reduction": 0.05}, "links": []},
		# ---- Myśliwy
		"power_shot": {"pos": Vector2(1.1, 1.4), "kind": "skill", "skill": "power_shot", "links": ["power_charge", "pierce_1"]},
		"power_charge": {"pos": Vector2(2.6, 1.4), "kind": "passive", "name": "Silne ramię", "stats": {"power_charge": 0.25}, "links": ["range_1", "power_dmg"]},
		"pierce_1": {"pos": Vector2(1.1, 2.8), "kind": "passive", "name": "Przeszywające groty", "stats": {"arrow_pierce": 1.0}, "links": ["range_1", "phys_b2"]},
		"range_1": {"pos": Vector2(2.6, 2.8), "kind": "passive", "name": "Daleki strzał", "stats": {"arrow_range": 0.25}, "links": ["ballista", "phys_b3"]},
		"power_dmg": {"pos": Vector2(4.0, 1.4), "kind": "passive", "name": "Gniew Swaroga", "stats": {"power_damage": 0.25}, "links": ["running_fire", "ballista"]},
		"running_fire": {"pos": Vector2(5.5, 0.7), "kind": "keystone", "name": "Strzelanie w biegu", "links": [],
				"description": "Strzelanie nie spowalnia ruchu, a gdy biegniesz, masz +15% szybkości ataku."},
		"ballista": {"pos": Vector2(4.0, 2.8), "kind": "skill", "skill": "ballista", "links": ["ballista_power"]},
		"ballista_power": {"pos": Vector2(5.4, 3.6), "kind": "passive", "name": "Napięte liny", "stats": {"ballista_damage": 0.3}, "links": ["ballista_time"]},
		"phys_b2": {"pos": Vector2(1.1, 4.2), "kind": "passive", "name": "Hartowane groty", "stats": {"physical_damage": 0.1}, "links": ["phys_b3"]},
		"phys_b3": {"pos": Vector2(2.6, 4.2), "kind": "passive", "name": "Ciężkie strzały", "stats": {"physical_damage": 0.1}, "links": ["ballista_time"]},
		"ballista_time": {"pos": Vector2(4.0, 4.5), "kind": "passive", "name": "Solidna rama", "stats": {"ballista_time": 0.4}, "links": []},
	},
	## Gałęzie księgi magii: zachód - Ogień (Kula ognia, Spadająca Gwiazda, Pełnia Mocy), północny zachód - Tarcza Many
	## i zdrowie, południowy zachód - Mgła i runy (Krok przez Mgłę, Kamień Runiczny, Ofiara Krwi), północny wschód -
	## Piorun (Łańcuch błyskawic, Burza Peruna, Kula Piorunów, Echo Run), południowy wschód - Lód (Włócznia Marzanny,
	## Zamieć, Harmonia Żywiołów).
	"spell": {
		"start": {"pos": Vector2(0, 0), "kind": "start", "name": "Ścieżka księgi", "links": ["fireball", "chain_lightning", "frost_lance", "mystic_renewal", "mana_stream"],
				"description": "Początek drzewka księgi magii (magiczny pocisk). Wybieraj węzły połączone z już wybranymi."},
		"mystic_renewal": {"pos": Vector2(-1.1, -1.6), "kind": "skill", "skill": "mystic_renewal", "links": ["hp_s1"]},
		"socket_1": {"pos": Vector2(-3.0, -1.5), "kind": "socket", "name": "Gniazdo", "links": ["hp_s1", "fire_charge"]},
		"socket_2": {"pos": Vector2(3.5, 0.0), "kind": "socket", "name": "Gniazdo", "links": ["crit_s1", "ice_dmg"]},
		"socket_legend": {"pos": Vector2(-8.0, 0.0), "kind": "socket", "legendary": true, "name": "Gniazdo legendarne", "links": ["full_power"]},
		"mana_stream": {"pos": Vector2(-1.1, 1.6), "kind": "skill", "skill": "mana_stream", "links": ["blink", "mana_s1"]},
		# ---- Ogień
		"fireball": {"pos": Vector2(-1.6, 0), "kind": "skill", "skill": "fireball", "links": ["fire_b1"]},
		"fire_b1": {"pos": Vector2(-3.0, 0), "kind": "passive", "name": "Żar w żyłach", "stats": {"spell_damage": 0.08}, "links": ["fire_charge", "meteor"]},
		"fire_charge": {"pos": Vector2(-4.3, -1.0), "kind": "passive", "name": "Szybki płomień", "stats": {"fireball_charge": 0.3}, "links": ["fire_dmg"]},
		"meteor": {"pos": Vector2(-4.3, 1.0), "kind": "skill", "skill": "meteor", "links": ["burn_dmg"]},
		"fire_dmg": {"pos": Vector2(-5.6, -1.6), "kind": "passive", "name": "Ogień Swaroga", "stats": {"fireball_damage": 0.2}, "links": ["full_power", "cast_s1"]},
		"burn_dmg": {"pos": Vector2(-5.6, 1.6), "kind": "passive", "name": "Pożoga", "stats": {"burn_damage": 0.3}, "links": ["full_power", "meteor_area"]},
		"full_power": {"pos": Vector2(-6.6, 0), "kind": "keystone", "name": "Pełnia Mocy", "links": [],
				"description": "Gdy masz ponad 90% many, czary zadają 40% więcej obrażeń, ale wszystkie umiejętności kosztują 20% więcej many."},
		"cast_s1": {"pos": Vector2(-7.0, -2.6), "kind": "passive", "name": "Bystre słowa", "stats": {"cast_speed": 0.08}, "links": ["crit_s0"]},
		"meteor_area": {"pos": Vector2(-7.0, 2.6), "kind": "passive", "name": "Wielka gwiazda", "stats": {"meteor_radius": 0.25}, "links": ["crit_dmg_s"]},
		"crit_s0": {"pos": Vector2(-8.4, -1.4), "kind": "passive", "name": "Oko wiedźmy", "stats": {"crit_chance": 0.04}, "links": []},
		"crit_dmg_s": {"pos": Vector2(-8.4, 1.4), "kind": "passive", "name": "Klątwa", "stats": {"crit_damage": 0.3}, "links": []},
		# ---- Tarcza i zdrowie
		"hp_s1": {"pos": Vector2(-2.4, -2.7), "kind": "passive", "name": "Hart ducha", "stats": {"health_percent": 0.05}, "links": ["mana_shield", "regen_s1"]},
		"mana_shield": {"pos": Vector2(-3.8, -2.9), "kind": "skill", "skill": "mana_shield", "links": ["shield_power"]},
		"regen_s1": {"pos": Vector2(-1.4, -3.8), "kind": "passive", "name": "Ziołowy napar", "stats": {"health_regen": 1.5}, "links": ["hp_s2"]},
		"shield_power": {"pos": Vector2(-4.6, -4.1), "kind": "passive", "name": "Twarda tarcza", "stats": {"shield_share": 0.15}, "links": ["hp_s2"]},
		"hp_s2": {"pos": Vector2(-3.0, -4.6), "kind": "passive", "name": "Długowieczność", "stats": {"health": 40.0}, "links": []},
		# ---- Mgła i runy
		"blink": {"pos": Vector2(-2.8, 2.7), "kind": "skill", "skill": "blink", "links": ["blink_cd"]},
		"blink_cd": {"pos": Vector2(-4.2, 3.6), "kind": "passive", "name": "Wędrowiec mgieł", "stats": {"blink_cooldown": -0.25}, "links": ["blood_sacrifice"]},
		"blood_sacrifice": {"pos": Vector2(-5.7, 3.9), "kind": "keystone", "name": "Ofiara Krwi", "stats": {"health_percent": 0.25}, "links": [],
				"description": "Z księgą w ręku umiejętności kosztują zdrowie zamiast many (nie mogą cię zabić), a maksymalne zdrowie rośnie o 25%."},
		"mana_s1": {"pos": Vector2(-1.3, 3.5), "kind": "passive", "name": "Głęboka studnia", "stats": {"mana": 25.0}, "links": ["rune_stone", "dodge_s1"]},
		"rune_stone": {"pos": Vector2(-2.7, 4.4), "kind": "skill", "skill": "rune_stone", "links": ["rune_power"]},
		"rune_power": {"pos": Vector2(-4.0, 4.9), "kind": "passive", "name": "Głębokie runy", "stats": {"rune_bonus": 0.3}, "links": ["blood_sacrifice"]},
		"dodge_s1": {"pos": Vector2(-0.1, 4.6), "kind": "passive", "name": "Mglista postać", "stats": {"dodge_chance": 0.03}, "links": []},
		# ---- Piorun
		"chain_lightning": {"pos": Vector2(1.1, -1.4), "kind": "skill", "skill": "chain_lightning", "links": ["thunder_wave", "cast_s2"]},
		"thunder_wave": {"pos": Vector2(2.6, -1.4), "kind": "skill", "skill": "thunder_wave", "links": ["combo_s1", "crit_s1"]},
		"cast_s2": {"pos": Vector2(1.1, -2.8), "kind": "passive", "name": "Szybki szept", "stats": {"cast_speed": 0.08}, "links": ["combo_s1", "cast_s3"]},
		"combo_s1": {"pos": Vector2(2.6, -2.8), "kind": "passive", "name": "Splecione zaklęcia", "stats": {"combo_window": 0.4}, "links": ["storm_call", "chain_more"]},
		"crit_s1": {"pos": Vector2(4.0, -1.4), "kind": "passive", "name": "Iskra", "stats": {"crit_chance": 0.04}, "links": ["storm_call", "crit_s2"]},
		"storm_call": {"pos": Vector2(4.0, -2.8), "kind": "skill", "skill": "storm_call", "links": ["storm_time"]},
		"storm_time": {"pos": Vector2(5.4, -3.6), "kind": "passive", "name": "Długa nawałnica", "stats": {"storm_time": 0.3}, "links": ["echo_runes", "combo_s2"]},
		"cast_s3": {"pos": Vector2(1.1, -4.2), "kind": "passive", "name": "Błyskawiczne słowa", "stats": {"cast_speed": 0.08}, "links": ["chain_more"]},
		"chain_more": {"pos": Vector2(2.6, -4.2), "kind": "passive", "name": "Rozgałęziony piorun", "stats": {"chain_targets": 2.0}, "links": ["echo_runes"]},
		"echo_runes": {"pos": Vector2(4.0, -4.5), "kind": "keystone", "name": "Echo Run", "stats": {"cast_speed": -0.1}, "links": [],
				"description": "Nowe czary drzewka (Włócznia Marzanny, Zamieć, Burza Peruna, Kula Piorunów, Spadająca Gwiazda) w 30% przypadków wybrzmiewają drugi raz za darmo, ale rzucasz o 10% wolniej."},
		"combo_s2": {"pos": Vector2(6.8, -3.8), "kind": "passive", "name": "Mistrz zaklęć", "stats": {"combo_damage": 0.15}, "links": []},
		"crit_s2": {"pos": Vector2(5.4, -1.4), "kind": "passive", "name": "Gniew Peruna", "stats": {"crit_damage": 0.3}, "links": ["ball_lightning", "cdr_s"]},
		"ball_lightning": {"pos": Vector2(6.8, -2.0), "kind": "skill", "skill": "ball_lightning", "links": ["orb_dmg", "spell_s1"]},
		"orb_dmg": {"pos": Vector2(8.2, -2.6), "kind": "passive", "name": "Żywy piorun", "stats": {"orb_damage": 0.3}, "links": []},
		"spell_s1": {"pos": Vector2(8.2, -1.0), "kind": "passive", "name": "Moc burzy", "stats": {"spell_damage": 0.1}, "links": []},
		"cdr_s": {"pos": Vector2(6.8, -0.5), "kind": "passive", "name": "Rytm zaklęć", "stats": {"cooldown_reduction": 0.05}, "links": []},
		# ---- Lód
		"frost_lance": {"pos": Vector2(1.1, 1.4), "kind": "skill", "skill": "frost_lance", "links": ["lance_dmg", "chill_1"]},
		"lance_dmg": {"pos": Vector2(2.6, 1.4), "kind": "passive", "name": "Ostry lód", "stats": {"lance_damage": 0.25}, "links": ["lance_pierce", "ice_dmg"]},
		"chill_1": {"pos": Vector2(1.1, 2.8), "kind": "passive", "name": "Mróz w kościach", "stats": {"chill_time": 0.4}, "links": ["lance_pierce", "spell_s2"]},
		"lance_pierce": {"pos": Vector2(2.6, 2.8), "kind": "passive", "name": "Przeszywający lód", "stats": {"lance_pierce": 2.0}, "links": ["blizzard", "spell_s3"]},
		"ice_dmg": {"pos": Vector2(4.0, 1.4), "kind": "passive", "name": "Oddech Marzanny", "stats": {"blizzard_damage": 0.25}, "links": ["harmony", "blizzard"]},
		"harmony": {"pos": Vector2(5.5, 0.7), "kind": "keystone", "name": "Harmonia Żywiołów", "links": [],
				"description": "Czar innego żywiołu (ogień, lód, piorun) niż poprzedni daje na 4 s +30% obrażeń magicznych."},
		"blizzard": {"pos": Vector2(4.0, 2.8), "kind": "skill", "skill": "blizzard", "links": ["blizzard_time"]},
		"blizzard_time": {"pos": Vector2(5.4, 3.6), "kind": "passive", "name": "Długa zima", "stats": {"blizzard_time": 0.4}, "links": ["mana_regen_s"]},
		"spell_s2": {"pos": Vector2(1.1, 4.2), "kind": "passive", "name": "Pieśń zimy", "stats": {"spell_damage": 0.1}, "links": ["spell_s3"]},
		"spell_s3": {"pos": Vector2(2.6, 4.2), "kind": "passive", "name": "Szron na runach", "stats": {"spell_damage": 0.1}, "links": ["mana_regen_s"]},
		"mana_regen_s": {"pos": Vector2(4.0, 4.5), "kind": "passive", "name": "Źródło Marzanny", "stats": {"mana_regen": 2.0}, "links": []},
	},
}


static func has_tree(weapon_type: String) -> bool:
	return TREES.has(weapon_type)


static func nodes(weapon_type: String) -> Dictionary:
	return TREES.get(weapon_type, {})


## Połączenia węzła w obie strony (w danych zapisane są tylko w jedną).
static func neighbors(weapon_type: String, id: String) -> Array[String]:
	var tree := nodes(weapon_type)
	var result: Array[String] = []
	for link: String in tree[id]["links"]:
		result.append(link)
	for other: String in tree:
		if id in tree[other]["links"] and not other in result:
			result.append(other)
	return result


## Węzeł odblokowujący umiejętność ("" - umiejętność nie ma węzła; wtedy odblokowuje się ją za złoto).
static func node_for_skill(skill_id: String) -> String:
	var weapon: String = Skills.get_data(skill_id).get("weapon", "")
	for id: String in nodes(weapon):
		if nodes(weapon)[id].get("skill", "") == skill_id:
			return id
	return ""


## Nazwa węzła w obecnym języku.
static func node_name(weapon_type: String, id: String) -> String:
	var node: Dictionary = nodes(weapon_type)[id]
	if node["kind"] == "skill":
		return Skills.name_of(node["skill"])
	return Lang.t(node["name"])


## Opis węzła w obecnym języku ("" - węzeł bez opisu).
static func node_description(weapon_type: String, id: String) -> String:
	var node: Dictionary = nodes(weapon_type)[id]
	if node["kind"] == "skill":
		return Skills.description_of(node["skill"])
	return Lang.t(str(node.get("description", "")))


## Opis premii węzła ("+8% obrażeń fizycznych", "Zasięg Młynka +20%").
static func stats_text(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for stat: String in stats:
		var value: float = stats[stat]
		if TREE_STATS.has(stat):
			var seconds := "%+.1f s" % value
			var shown := (seconds.replace(".", ",") if Lang.is_polish() else seconds) if stat == "combo_window" \
					else "%+d" % roundi(value) if stat in COUNT_STATS else "%+d%%" % roundi(value * 100.0)
			parts.append(Lang.t("%s %s") % [Lang.t(TREE_STATS[stat]), shown])
		elif stat == "health_percent":
			parts.append(Lang.t("%+d%% maksymalnego zdrowia") % roundi(value * 100.0))
		else:
			parts.append(Items._stat_text(stat, value))
	return ", ".join(parts)


## Najkrótsza droga od startu do węzła (bez startu) - do przeniesienia umiejętności ze starszych zapisów.
static func path_to(weapon_type: String, target: String) -> Array[String]:
	var previous := {"start": ""}
	var queue: Array[String] = ["start"]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == target:
			break
		for next in neighbors(weapon_type, id):
			if not previous.has(next):
				previous[next] = id
				queue.append(next)
	var path: Array[String] = []
	var at := target
	while previous.has(at) and at != "start":
		path.push_front(at)
		at = previous[at]
	return path
