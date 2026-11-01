class_name Lang
## Tłumaczenia gry (wbudowany mechanizm Godota). Kluczem jest polski tekst, a angielskie tłumaczenia leżą
## w translations/teksty.csv (kolumna "en"; puste pole - zostaje polski tekst). Plik z tekstami odświeża
## `python tools/texts.py` (zbiera napisy ze skryptów i scen, zachowuje gotowe tłumaczenia).
##
## Zasady dla nowych napisów:
## - napis pokazywany graczowi przechodzi przez Lang.t("…") (w funkcjach statycznych) albo tr("…") (w węzłach);
##   Label.text i Button.text z gotowym napisem tłumaczą się same, ale napisy składane z kawałków - nie,
## - zdanie z liczbą lub imieniem: najpierw tłumaczenie wzoru, potem wstawienie - Lang.t("Poziom %d") % level,
##   nigdy "Poziom " + str(level); cały wzór w jednym kawałku, żeby tłumacz mógł zmienić szyk zdania,
## - odmiana liczebników: Lang.n(liczba, "%d ostrze", "%d ostrza", "%d ostrzy") % liczba,
## - w stałych (const) polski tekst zostaje, a tłumaczy się go przy pokazywaniu (Lang.t(NAMES[id])),
## - zapis gry nie przechowuje nazw ani opisów jako tekstu (tylko identyfikatory), bo po zmianie języka
##   zostałyby po polsku.

## Języki do wyboru w Ustawieniach (kod - nazwa w tym języku, celowo bez tłumaczenia).
const LANGUAGES := {"pl": "Polski", "en": "English"}
const DEFAULT := "pl"


## Tłumaczy napis (polski tekst jako klucz). Bez tłumaczenia zwraca polski tekst.
static func t(text: String) -> String:
	if text.is_empty():
		return text
	return String(TranslationServer.translate(text))


## Odmiana przez liczbę: po polsku "1 ostrze", "3 ostrza", "5 ostrzy"; po angielsku tłumaczenie formy
## pierwszej przy 1, a trzeciej przy innej liczbie ("1 blade", "5 blades"). Zwraca wzór (bez wstawionej liczby).
static func n(count: int, one: String, few: String, many: String) -> String:
	if is_polish():
		return t(one if count == 1 else (few if _polish_few(count) else many))
	return t(one if count == 1 else many)


## Spójnik listy: "a, b i c" (w obecnym języku).
static func join(parts: Array) -> String:
	if parts.size() <= 1:
		return "" if parts.is_empty() else str(parts[0])
	var head := ", ".join(parts.slice(0, parts.size() - 1).map(func(p: Variant) -> String: return str(p)))
	return t("%s i %s") % [head, str(parts[-1])]


static func current() -> String:
	return TranslationServer.get_locale().substr(0, 2)


static func is_polish() -> bool:
	return current() == "pl"


static func set_language(code: String) -> void:
	TranslationServer.set_locale(code if LANGUAGES.has(code) else DEFAULT)


static func _polish_few(count: int) -> bool:
	var last := absi(count) % 10
	var tens := absi(count) % 100
	return last >= 2 and last <= 4 and (tens < 12 or tens > 14)
