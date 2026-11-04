# Watra - zasady grafiki

Jak robić nowe grafiki, żeby pasowały do reszty gry. Spisane z tego, jak gra jest dziś zrobiona. Koszty generacji
PixelLab i obejście blokady pobierania są w `CLAUDE.md` („PixelLab w chmurze”).

## Ekran i piksele

- Obraz gry ma 640x360 pikseli (okno 1280x720, skalowanie `canvas_items`), więc jeden piksel grafiki to zwykle
  2x2 piksele ekranu. Skalowanie interfejsu w ustawieniach (`Game.ui_scale`) powiększa całość.
- Domyślny filtr tekstur to **najbliższy sąsiad** (bez rozmycia), a położenia są przyciągane do pełnych pikseli
  (`project.godot`). Wyjątek: ikony 64 px pokazywane w polu 16 px pomniejsza filtr liniowy (`UiStyle.fit_icon`), żeby
  nie gubić co drugiego piksela.
- **Kafelek świata ma 16x16 px** (`TILE`). Krainy mają 200x150 kafelków, lochy 156x116.

## Perspektywa

- Postacie, potwory, obiekty, budynki: widok **„low top-down”** (lekko z góry, widać przód i górę) - tak ustawiona
  jest większość generacji PixelLab.
- Podłoża (trawa, błoto, ścieżki): widok **„high top-down”** (prawie z góry).
- Światło pada z góry, cień pod obiektem (`assets/shadow.png`), budynki mają osobny dach, który robi się
  przezroczysty, gdy gracz wchodzi do środka.

## Styl

- Ciepły, przytulny pixel-art fantasy z mrocznym tłem; w opisach do PixelLab sprawdza się dopisek
  „cozy fantasy RPG style”.
- Słowiańskie detale: drewno, strzechy, palisady, rzeźbione słupy i kamienie z runami (np. krąg wokół Watry).
- Ogień i złoto to akcenty Ostoi i Watry (interfejs ma złote tytuły i obwódki - `UiStyle`).
- *Propozycje do potwierdzenia przez autora:* unikać wyglądu typowo zachodniego średniowiecza (ceglane zamki,
  płytowe zbroje rycerskie); Nawię i Hordę trzymać w chłodniejszych, mroczniejszych barwach jako przeciwwagę dla
  ciepła Ostoi.
- Do ustalenia z autorem: stała paleta kolorów i jednolity kontur (dziś każda paczka PixelLab ma ustawienia
  „domyślne”, a spójność trzyma podobny opis i przebarwienia w narzędziach).

## Rozmiary

| Co | Rozmiar | Uwagi |
|---|---|---|
| Postać gracza | komórka 54x54 px w grze | z PixelLab 72 px, zmniejszone x0,75 (`tools/hero_sheets.py`) |
| Ikony przedmiotów, umiejętności, interfejsu | 64x64 px | w grze pole 16 px (`UiStyle.fit_icon`) |
| Obiekty (drzewa, skały, ozdoby) | paczki 64 px albo 128 px | `create_1_direction_object` / paczka 4 obiektów 128 px |
| Podłoże | zestaw Wang 64 px (tryb pro) | z zestawu bierzemy pełny kafelek jako bezszwową teksturę, przejścia rysuje shader (`scripts/soft_ground.gd`) |
| Ikona gry | 256 px i `.ico` 16-256 | `tools/game_icon.py` z klatki Watry |

## Animacje

- Postać gracza: 5 kierunków (południe, płd.-wschód, wschód, płn.-wschód, północ; pozostałe odbija gra), arkusz
  8 kolumn = klatki, wiersze = animacja x kierunek. Ataki Wojciecha po 8 klatek, inne ruchy po 4.
- Broń w dłoni: PixelLab przerysowuje klatki z postacią trzymającą znacznik (pręt z różowym `#FF00FF` końcem
  w dłoni i błękitnym `#00FFFF` czubkiem); narzędzie liczy z niego chwyt i kąt broni w każdej klatce.
- Obiekty: animacja 8 klatek (`animate_object`, 2 generacje).
- Efekty (cięcia, błyski, czary): kreator efektów PixelLab `vfx_workbench` (darmowy), jeden rząd klatek,
  `pixellab_src/vfx/` -> `python tools/vfx_art.py` -> `assets/effects/`.

## Co rysuje kod, a nie PixelLab

Talizmany, Mapa Nawii, cięciwa łuku (`BowString`), światło i poświaty, część efektów (`SkillEffects`, `FxLoop`),
przebarwienia wariantów (np. runy, wersje magiczne i rzadkie przedmiotów). Jeśli coś da się dobrze narysować
w kodzie albo przebarwić gotową grafikę, nie wydajemy generacji.

## Droga grafiki do gry

1. Najpierw sprawdź, co już jest: `assets/` (także grafiki z innych krain), niewykorzystane paczki na PixelLabie,
   saldo generacji - i pokaż autorowi koszt.
2. Surowe pliki z PixelLab trafiają do `pixellab_src/<temat>/` (z identyfikatorami w `ids.json`).
3. Narzędzie z `tools/` tnie, skaluje i składa arkusze do `assets/`. Pliki, które zmieniły się tylko kodowaniem PNG,
   przywróć.
4. Sprawdź wygląd zrzutem ekranu (`tools/screenshot.sh`, `tools/overview.gd`, `tools/dungeon_shots.gd`).
