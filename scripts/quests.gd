class_name Quests
## Baza zadań. Każde zadanie daje NPC (giver) i nagradza złotem i expem. Rodzaje:
## - kill (domyślny): pokonaj `count` potworów rodzaju `target` (Goblin.quest_kind) w obszarze `area`,
## - gather: zbierz `count` sztuk przedmiotu `item` albo kilka surowców naraz (`items`: id -> ilość,
##   `count` to wtedy ich suma); liczy się plecak i magazyn, a przy odbiorze nagrody surowce są zabierane.
##
## Stany zadania: available (do przyjęcia), active (w toku), ready (do odebrania nagrody), done.

const STATE_AVAILABLE := "available"
const STATE_ACTIVE := "active"
const STATE_READY := "ready"
const STATE_DONE := "done"

## Ile zadań naraz może być śledzonych pod minimapą.
const MAX_TRACKED := 3

const DATA := {
	"village_help": {
		"title": "Ostoja prosi o pomoc",
		"giver": "Sołtys Mirosław",
		"type": "gather",
		"items": {"wood": 30, "stone": 20},
		"target_name": "Drewno i kamień",
		"count": 50,
		"area": "village",
		"area_name": "las wokół Ostoi - liczy się to, co masz w plecaku i w magazynie",
		"gold": 150,
		"xp": 400,
		"description": "Wędrowcze, Ostoja ledwo się trzyma. Palisada się sypie, a ludzi przybywa z każdym dniem. Cieśle są gotowi do pracy, ale nie mają z czego budować. Pomóż nam - zetnij w lesie drzewa i rozbij kilofem kilka głazów. Przynieś 30 drewna i 20 kamienia, a ruszymy z budową osady.",
		"progress_text": "Trzydzieści kłód i dwadzieścia kamieni - tyle, żeby cieśle mogli zacząć. Możesz je też złożyć w magazynie u Zenona.",
		"complete_text": "Jest drewno, jest kamień! Teraz możemy budować. Przychodź do mnie, gdy zechcesz postawić coś nowego - pokażę ci plany.",
		"done_text": "Dzięki tobie Ostoja znów rośnie! Gdy uzbierasz surowce, zajrzyj do planów budowy.",
	},
	"wolf_hunt": {
		"title": "Wilcza plaga",
		"giver": "Myśliwy Radek",
		"target": "wolf",
		"target_name": "Wilki",
		"count": 50,
		"area": "wolves",
		"area_name": "siedlisko wilków (południowy wschód)",
		"gold": 300,
		"xp": 1500,
		"description": "Wataha z ciemnego lasu na południowym wschodzie rozszarpuje każdego, kto zapuści się za daleko. Przetrzeb ją - zabij 50 wilków.",
		"progress_text": "Wilki wciąż wyją po nocach. Wróć, gdy ubijesz pięćdziesiąt.",
		"complete_text": "W lesie zrobiło się ciszej. Dobra robota, łowco - oto twoja zapłata.",
		"done_text": "Dzięki tobie znów mogę polować bez oglądania się za siebie.",
	},
	"goblin_purge": {
		"title": "Goblińska zaraza",
		"giver": "Kupiec Bogdan",
		"target": "goblin",
		"target_name": "Gobliny",
		"count": 50,
		"area": "goblins",
		"area_name": "obozy goblinów (północny zachód)",
		"gold": 250,
		"xp": 1100,
		"description": "Gobliny z obozów na północnym zachodzie napadają na moje wozy. Pokaż im, gdzie ich miejsce - pokonaj 50 goblinów.",
		"progress_text": "Moje wozy dalej giną w lesie. Wróć, gdy pokonasz pięćdziesiąt goblinów.",
		"complete_text": "Wozy znów dojeżdżają całe! Należy ci się sowita zapłata.",
		"done_text": "Interesy idą lepiej, odkąd gobliny siedzą cicho.",
	},
	"jeweler_gem": {
		"title": "Pierwszy klejnot",
		"giver": "Jubiler Dobromir",
		"type": "gather",
		"item": "rough_gem",
		"target_name": "Surowy klejnot",
		"count": 1,
		"area": "",
		"area_name": "złoża rudy żelaza w Wietrznych Turniach",
		"gold": 300,
		"xp": 2500,
		"description": "Te góry kryją więcej niż żelazo, młody. W złożach rudy rodzą się klejnoty - rubiny, szafiry, szmaragdy. Rozbij kilofem złoże rudy żelaza tu, w Turniach, i przynieś mi surowy klejnot. Pokażę ci, co potrafi szlachetny kamień osadzony w orężu.",
		"progress_text": "Złoża rudy żelaza - rdzawe skały na płaskowyżach. Rozbij jedno kilofem, a klejnot sam wyskoczy.",
		"complete_text": "Oto i on! Patrz uważnie: oszlifuję go i wydrążę gniazdo w twoim przedmiocie - pierwsze za darmo. Odtąd kamienie szlachetne będą ci wypadać z potworów, a niektóre przedmioty znajdziesz już z gniazdem. Przychodź do mnie osadzać, wyjmować i łączyć kamienie - trzy jednego szlifu dadzą jeden lepszy.",
		"done_text": "Kamień w gnieździe to jak drugi przedmiot w jednym. Przynieś, co znajdziesz - osadzę, wyjmę albo połączę.",
	},
}


## Zadania tworzone w locie (zlecenia z tablicy ogłoszeń) - rejestruje je QuestLog.
static var dynamic := {}


static func get_data(id: String) -> Dictionary:
	if DATA.has(id):
		return DATA[id]
	if MainQuests.DATA.has(id):
		return MainQuests.DATA[id]
	return dynamic.get(id, {})


## Komu oddać wykonane zadanie (zadania główne mogą wskazać inną postać niż zleceniodawca).
static func receiver(id: String) -> String:
	var quest := get_data(id)
	return quest.get("receiver", quest.get("giver", ""))


## Co trzeba zebrać: id przedmiotu -> ilość.
static func requirements(id: String) -> Dictionary:
	var quest := get_data(id)
	if quest.has("items"):
		return quest["items"]
	if quest.has("item"):
		return {quest["item"]: quest["count"]}
	return {}


static func is_gather(id: String) -> bool:
	return get_data(id).get("type", "kill") == "gather"


static func reward_text(id: String) -> String:
	var quest := get_data(id)
	var parts: Array[String] = [Lang.t("%d złota") % quest["gold"], Lang.t("%d exp") % quest["xp"]]
	var items: Dictionary = quest.get("reward_items", {})
	for item: String in items:
		parts.append("%s x%d" % [Lang.t(Items.get_data(item)["name"]), items[item]])
	if int(quest.get("skill_points", 0)) > 0:
		parts.append(Lang.t("+%d pkt umiejętności") % int(quest["skill_points"]))
	return ", ".join(parts)


## Tekst zadania do pokazania (tytuł, opis, cel, miejsce, wypowiedzi), przetłumaczony. `quest` - id albo dane.
## Zadania stałe trzymają polski tekst, a zlecenia z tablicy i prośby drużyny - wzór z danymi (resolve), żeby
## zapis gry nie przechowywał gotowego zdania (starsze zapisy mają zwykły tekst - też działa).
static func text(quest: Variant, key: String, fallback := "") -> String:
	var data: Dictionary = quest if quest is Dictionary else get_data(str(quest))
	return resolve(data.get(key, fallback))


## Nazwa postaci-zleceniodawcy do pokazania ("Kupiec Bogdan" -> tłumaczenie; imiona podróżników bez zmian).
static func person(name: String) -> String:
	return Lang.t(name)


## Składa tekst z wzoru: napis - tłumaczenie; tablica [wzór, dane...] - przetłumaczony wzór z wstawionymi danymi
## (napisy w danych też tłumaczone, liczby bez zmian, zagnieżdżone tablice rozwijane tak samo); słownik
## {"t": napis, "lower": true, "slice": true} - tłumaczenie małą literą / do pierwszego przecinka
## ("Gruzłog, Wódz Goblinów" -> "Gruzłog"). Wynik tablicy zaczyna się wielką literą.
static func resolve(spec: Variant) -> String:
	if spec is Array:
		var parts: Array = spec
		if parts.is_empty():
			return ""
		var args: Array = parts.slice(1).map(func(arg: Variant) -> Variant: return arg if arg is int or arg is float else resolve(arg))
		var result: String = Lang.t(str(parts[0])) % args if not args.is_empty() else Lang.t(str(parts[0]))
		return result.left(1).to_upper() + result.substr(1)
	if spec is Dictionary:
		var result := resolve(spec.get("t", ""))
		if spec.get("slice", false):
			result = result.get_slice(",", 0)
		if spec.get("lower", false):
			result = result.to_lower()
		return result
	return Lang.t(str(spec))
