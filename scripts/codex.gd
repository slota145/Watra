class_name Codex
extends Node
## Encyklopedia (okno L, CodexWindow): legendy, bossowie, potwory, zioła i mikstury oraz zwykłe przedmioty.
## Wpisy są zakryte ("???"), dopóki gracz nie zdobędzie przedmiotu (choćby wylosowanego na jego bazie - plecak,
## postać, magazyn) albo nie pokona potwora; w trybie deweloperskim widać wszystko.
## Dziecko gracza - pamięta odkryte przedmioty i liczbę pokonanych potworów każdego rodzaju (zapis gry).
## Dane potworów: nazwa, kraina i krótki opis (MONSTERS); grafikę, bossa i jego legendy czyta ze sceny potwora.

signal changed

## Potwory wg nazwy sceny: nazwa (u bossów - boss_name ze sceny), kraina, opis. Kolejność - jak w encyklopedii.
const MONSTERS := {
	"goblin": {"name": "Goblin", "zone": "forest", "note": "Siedzi przy ognisku z kompanami i rzuca się na każdego, kto podejdzie."},
	"goblin_archer": {"name": "Goblin łucznik", "zone": "forest", "note": "Trzyma się z tyłu i strzela z łuku."},
	"goblin_brute": {"name": "Goblin osiłek", "zone": "forest", "note": "Wielki goblin z maczugą - wolny, ale bije bardzo mocno."},
	"wolf": {"name": "Wilk", "zone": "forest", "note": "Poluje w watahach; leżące wilki zrywają się, gdy ktoś podejdzie."},
	"warg": {"name": "Warg", "zone": "forest", "note": "Ogromny wilk, przewodnik watahy."},
	"goblin_chief": {"zone": "forest", "note": "Wódz goblinów w sercu obozu, otoczony strażą."},
	"alpha_wolf": {"zone": "forest", "note": "Przewodnik wilczego siedliska. Jego wycie zwołuje watahę."},
	"kobold": {"name": "Kobold", "zone": "fields", "note": "Mały i zwinny - koboldy napadają całymi zgrajami."},
	"kobold_slinger": {"name": "Kobold procarz", "zone": "fields", "note": "Ciska kamieniami z procy z bezpiecznej odległości."},
	"kobold_bomber": {"name": "Kobold bombiarz", "zone": "fields", "note": "Rzuca beczułkami prochu, które wybuchają po chwili."},
	"field_worm": {"name": "Czerw polny", "zone": "fields", "note": "Kopie pod łanami i wyskakuje spod ziemi tuż pod nogami."},
	"kobold_bombardier": {"zone": "fields", "note": "Szalony bombardier z barykady w obozie koboldów."},
	"giant_worm": {"zone": "fields", "note": "Olbrzymi czerw, który pożera całe pola."},
	"gryf": {"zone": "fields", "note": "Gryf strzegący wzgórza nad polami."},
	"frogman": {"name": "Żabołak", "zone": "swamp", "note": "Mieszkaniec rozlewisk z włócznią."},
	"frog_spitter": {"name": "Żabołak plujący", "zone": "swamp", "note": "Pluje żrącym śluzem z daleka."},
	"drowner": {"name": "Utopiec", "zone": "swamp", "note": "Czai się pod wodą sadzawek i wynurza, gdy ktoś podejdzie."},
	"wisp": {"name": "Ognik", "zone": "swamp", "note": "Błędny ognik unoszący się nad bagnem."},
	"rusalka": {"name": "Topielica", "zone": "swamp", "note": "Blada panna z sadzawek Topielczego Uroczyska."},
	"wodnik": {"name": "Wodnik", "zone": "swamp", "note": "Pan topielców z najgłębszej sadzawki. Strzeże też zatopionych lochów."},
	"frog_chief": {"zone": "swamp", "note": "Wódz żabołaków z wioski na rozlewiskach."},
	"hydra": {"zone": "swamp", "note": "Wielogłowa bestia z bagna na północnym skraju rozlewisk."},
	"birdman": {"name": "Ptakoczłek", "zone": "mountains", "note": "Wojownik z wioski ptakoludzi - potrafi skoczyć z góry na wroga."},
	"birdman_thrower": {"name": "Ptakoczłek oszczepnik", "zone": "mountains", "note": "Miota oszczepami z wysoka."},
	"birdman_shaman": {"name": "Ptakoczłek szaman", "zone": "mountains", "note": "Wzywa wichry i wspiera współplemieńców."},
	"satyr": {"name": "Satyr", "zone": "mountains", "note": "Rozbrykany mieszkaniec polany satyrów."},
	"satyr_piper": {"name": "Satyr fletnista", "zone": "mountains", "note": "Jego melodia oszałamia - sterowanie odwraca się na chwilę."},
	"satyr_brute": {"name": "Satyr osiłek", "zone": "mountains", "note": "Rogaty siłacz, szarżuje z opuszczonym łbem."},
	"storm_eagle": {"zone": "mountains", "note": "Elektryczny orzeł z gniazda nad wioską ptakoludzi."},
	"satyr_king": {"zone": "mountains", "note": "Władca satyrów z wielkiej polany."},
	"spider": {"name": "Pająk", "zone": "ancient", "note": "Wielki leśny pająk z leża w Prastarym Lesie."},
	"web_spider": {"name": "Pająk sieciarz", "zone": "ancient", "note": "Strzela lepką siecią, która spowalnia."},
	"spiderling": {"name": "Pajączek", "zone": "ancient", "note": "Wylęga się z kokonów całymi gromadami."},
	"cocoon": {"name": "Kokon", "zone": "ancient", "note": "Pajęczy kokon - jeśli go nie zniszczysz, wylęgną się pajączki."},
	"treant": {"name": "Drzewiec", "zone": "ancient", "note": "Ożywione drzewo, wolne, ale wytrzymałe."},
	"ancient_tree": {"name": "Prastare drzewo", "zone": "ancient", "note": "Stoi w pierścieniach wokół Leszego i smaga korzeniami."},
	"beast_bear": {"zone": "ancient", "note": "Bestia ze świty Biesa."},
	"beast_werewolf": {"zone": "ancient", "note": "Bestia ze świty Biesa."},
	"leshy": {"zone": "ancient", "note": "Duch puszczy w sercu Prastarego Lasu."},
	"spider_queen": {"zone": "ancient", "note": "Matka wszystkich pająków z wielkiego leża."},
	"bies": {"zone": "ancient", "note": "Demon dziczy, władca bestii."},
	"skeleton": {"name": "Szkielet", "zone": "cemetery", "note": "Wstaje z grobów w kwaterach cmentarza."},
	"skeleton_archer": {"name": "Szkielet łucznik", "zone": "cemetery", "note": "Strzela z kościanego łuku."},
	"skeleton_knight": {"name": "Szkielet rycerz", "zone": "cemetery", "note": "Dawny rycerz w zardzewiałej zbroi."},
	"ghoul": {"name": "Trupojad", "zone": "cemetery", "note": "Żeruje na trupowisku, szybki i zachłanny."},
	"zombie": {"name": "Zombie", "zone": "cemetery", "note": "Powolny, ale nie czuje bólu."},
	"necromancer": {"zone": "cemetery", "note": "Nekromanta z mauzoleum, który wskrzesza umarłych."},
	"colossal_ghoul": {"zone": "cemetery", "note": "Kolosalny ghul z trupowiska."},
	"deer": {"name": "Jeleń", "zone": "", "note": "Zwierzyna - ucieka przed myśliwym. Daje mięso i skóry."},
	"roe": {"name": "Sarna", "zone": "", "note": "Płochliwa zwierzyna leśnych polan."},
	"boar": {"name": "Dzik", "zone": "", "note": "Zwierzyna, która broni się szarżą."},
	"hare": {"name": "Zając", "zone": "", "note": "Szybka, drobna zwierzyna."},
	"goat": {"name": "Kozica", "zone": "", "note": "Górska zwierzyna chodząca stadami."},
}
const VAULT_SOURCE := "Skarbiec strażnika w lochach Watry"

## przedmiot (baza) -> true
var discovered := {}
## potwór (nazwa sceny) -> liczba pokonanych
var kills := {}
static var _monster_cache := {}
static var _legend_sources := {}


# ---------------------------------------------------------------- odkrywanie
## Przedmiot zdobyty (w plecaku, na postaci albo w magazynie) - liczy się jego baza.
func note_item(id: String) -> void:
	var key := base_of(id)
	if key == "" or discovered.has(key):
		return
	discovered[key] = true
	changed.emit()


## Wszystkie przedmioty gracza (np. po wczytaniu starszego zapisu albo po zmianie w plecaku).
func note_owned(player: Player) -> void:
	var before := discovered.size()
	for id: String in player._owned_ids():
		var key := base_of(id)
		if key != "":
			discovered[key] = true
	if discovered.size() != before:
		changed.emit()


func note_kill(enemy: Node) -> void:
	var id := monster_id(enemy)
	if not MONSTERS.has(id):
		return
	kills[id] = int(kills.get(id, 0)) + 1
	changed.emit()


func is_item_known(id: String) -> bool:
	return discovered.has(id)


func kills_of(id: String) -> int:
	return int(kills.get(id, 0))


## Baza przedmiotu (wylosowane przedmioty liczą się jako ich baza, np. legenda albo broń danego tieru).
static func base_of(id: String) -> String:
	if id == "" or id == "gold" or Items.get_data(id).has("gem"):
		return ""
	return str(Items.get_data(id).get("base", id))


static func monster_id(enemy: Node) -> String:
	return enemy.scene_file_path.get_file().get_basename() if enemy != null else ""


# ---------------------------------------------------------------- listy wpisów
## Wszystkie legendy: najpierw wg bossów (krainami), potem skarbiec lochów, na końcu pozostałe.
static func legends() -> Array[String]:
	var result: Array[String] = []
	for monster: String in MONSTERS:
		for id: String in monster_info(monster).get("legends", []):
			if not id in result:
				result.append(id)
	for id: String in Dungeons.VAULT_LEGENDS:
		if not id in result:
			result.append(id)
	for id: String in Items.DATA:
		# Legendarny tobół to torba (Bags), nie legenda z efektem
		if Items.DATA[id].get("rarity", "") == "legendary" and not id in result and not Items.DATA[id].has("bag"):
			result.append(id)
	for id: String in Legends.DATA:
		if not id in result:
			result.append(id)
	return result


## Skąd pochodzi legenda (boss albo skarbiec lochów).
static func legend_source(id: String) -> String:
	if _legend_sources.is_empty():
		for monster: String in MONSTERS:
			for legend: String in monster_info(monster).get("legends", []):
				_legend_sources[legend] = monster_name(monster)
	if _legend_sources.has(id):
		return _legend_sources[id]
	return VAULT_SOURCE if id in Dungeons.VAULT_LEGENDS else "nieznane"


static func bosses() -> Array[String]:
	var result: Array[String] = []
	for id: String in MONSTERS:
		if monster_info(id).get("boss", false):
			result.append(id)
	return result


static func monsters() -> Array[String]:
	var result: Array[String] = []
	for id: String in MONSTERS:
		if not monster_info(id).get("boss", false):
			result.append(id)
	return result


## Zioła i mikstury zielarki.
static func herbs() -> Array[String]:
	var result: Array[String] = []
	for kind in Herbs.ORDER:
		result.append(Herbs.KINDS[kind]["item"])
	for kind in Herbs.ORDER:
		result.append(Herbs.KINDS[kind]["elixir"])
	return result


## Zwykłe przedmioty: każda linia (miecze, łuki, hełmy...) od najniższego tieru.
static func items() -> Array[String]:
	var result: Array[String] = []
	for line: String in ItemBases.LINES:
		for id: String in ItemBases.LINES[line]:
			result.append(id)
	return result


# ---------------------------------------------------------------- potwory
static func monster_name(id: String) -> String:
	var info := monster_info(id)
	return info.get("boss_name", MONSTERS.get(id, {}).get("name", id))


## Dane potwora ze sceny (raz, potem z pamięci): grafika (pierwsza klatka), boss, jego nazwa i legendy,
## gatunek w bestiariuszu mędrca.
static func monster_info(id: String) -> Dictionary:
	if _monster_cache.has(id):
		return _monster_cache[id]
	var info := {}
	var path := "res://scenes/%s.tscn" % id
	if ResourceLoader.exists(path):
		var enemy: Node = load(path).instantiate()
		var sprite := enemy.get_node_or_null("Sprite") as Sprite2D
		if sprite != null and sprite.texture != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite.texture
			var cell := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
			atlas.region = Rect2(Vector2.ZERO, cell) if not sprite.region_enabled else sprite.region_rect
			info["texture"] = atlas
		if enemy is Boss:
			info["boss"] = true
			info["boss_name"] = enemy.boss_name
			info["legends"] = Array(enemy.legendary_drops)
		info["kind"] = Boons.kind_of(enemy)
		enemy.free()
	_monster_cache[id] = info
	return info


## Poziomy potwora w jego krainie ("poz. 1-7", u bossów "poz. 9").
static func level_text(id: String) -> String:
	var zone: String = MONSTERS.get(id, {}).get("zone", "")
	if not Levels.ZONES.has(zone):
		return ""
	if monster_info(id).get("boss", false):
		return "poz. %d" % Levels.boss_level(zone)
	return "poz. %d-%d" % [Levels.ZONES[zone][0], Levels.ZONES[zone][1]]


# ---------------------------------------------------------------- zapis
func get_save_data() -> Dictionary:
	return {"items": discovered.keys(), "kills": kills.duplicate()}


func load_save_data(data: Dictionary) -> void:
	discovered.clear()
	kills.clear()
	for id in data.get("items", []):
		discovered[str(id)] = true
	var saved: Dictionary = data.get("kills", {})
	for id: String in saved:
		kills[id] = int(saved[id])
	changed.emit()
