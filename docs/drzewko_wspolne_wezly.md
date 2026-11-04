# Wspólne drzewko - pełna lista węzłów (szkic)

Plik generuje `python tools/shared_tree_draft.py` (razem z rysunkiem `docs/drzewko_wspolne.png`).
Opis układu i decyzje: `docs/drzewko_wspolne.md`. Liczby w premiach to propozycje do balansu.

Legenda: **[U]** umiejętność, **[A]** aura, **[K]** węzeł kluczowy, **[Z]** węzeł znaczący, [d] drobny, [G] gniazdo; ✦ - nowe, ⌛ - na razie puste miejsce w grze (przyjdzie w kolejnych krokach).

## Siła (miecz) (65 węzłów ze ścieżkami)

### Brama Siły (1)

- **[U]** Młynek (miecz; atak, obszar, fizyczne) - zwykła umiejętność miecza (PPM)

### Wir (8)

- **[U]** Mgnienie (miecz) - skoki od wroga do wroga; combo po Młynku
- **[Z]** Szeroki zamach - +20% zasięgu Młynka
- **[Z]** Wirujące ostrze - +20% obrażeń Młynka
- [d] +6% obrażeń fizycznych
- **[Z]** Cięcie z cienia - +20% obrażeń Mgnienia, -25% many za skok
- **[Z]** Wciągający wir ✦ - Młynek lekko przyciąga wrogów z bliska
- **[K]** Oko Cyklonu - Młynek wciąga wrogów i rozkręca się do +100% obrażeń, zużywa 2x więcej many
- [G] Gniazdo legendarne - kamień szlachetny albo esencja legendy

### Ostrze i combo (8)

- **[U]** Szarża (miecz) - wypad z cięciem; Półksiężyc po niej
- **[U]** Półksiężyc (miecz) - szerokie cięcie - teraz zwykła umiejętność, po Szarży mocniejsze (combo)
- **[Z]** Płynne przejścia - +0,4 s okna combo
- **[Z]** Szybki wypad - -25% odnowienia Szarży
- **[U]** Rozłupanie Ziemi (miecz) - kolce z ziemi; combo po Półksiężycu
- **[Z]** Drżąca ziemia - +50% ogłuszenia Rozłupania Ziemi
- **[Z]** Mistrz przejść - +15% obrażeń ciosów combo
- **[K]** Taniec Ostrzy - każde combo daje +5% szybkości ataku na 4 s (do 5 razy)

### Szermierz (6)

- **[U]** Riposta (miecz) - zasłona i kontra wszystkich wokół; po niej Szarża za darmo
- **[Z]** Oko kata - +4% szansy na cios krytyczny
- **[Z]** Mistrz szermierki - +50% obrażeń kontry Riposty
- **[U]** Wilczy Kieł ✦ (miecz; atak, cios, fizyczne) - seria 4 szybkich pchnięć w jednego wroga (na bossów); ostatnie rozdziera i ogłusza
- **[Z]** Cios w serce - +30% obrażeń krytycznych
- [d] +8 siły

### Okrzyki (6)

- **[U]** Zew Peruna (miecz) - okrzyk: strach i pewne krytyki
- **[Z]** Głos burzy - +10% premii Zewu Peruna
- **[U]** Ryk Tura ✦ (miecz; okrzyk, obszar) - okrzyk: wrogowie wokół rzucają się na ciebie, +30% pancerza na 6 s
- **[Z]** Donośny głos ✦ - +40% zasięgu okrzyków, -20% ich odnowienia
- **[A]** Postrach ✦ (każda broń; aura) - aura: wrogowie wokół zadają 10% mniej obrażeń i wolniej atakują
- [d] +8 siły

### Krzepa (zdrowie) (6)

- **[Z]** Twarda skóra - +8% zdrowia
- **[Z]** Szybkie gojenie - +2 regeneracji zdrowia/s
- **[A]** Krzepa ✦ (każda broń; aura) - aura: +12% maksymalnego zdrowia
- **[Z]** Niezłomny - +60 zdrowia
- **[Z]** Pełnia Sił ✦ - +1% obrażeń za każde 5% zdrowia ponad połowę (najwyżej +10%)
- **[K]** Krew za Manę - umiejętności kosztują zdrowie zamiast many (nie mogą zabić), +25% zdrowia - dawna Ofiara Krwi z księgi, teraz z każdą bronią

### Bastion (6)

- **[Z]** Kolczuga pod skórą - +10 pancerza
- **[Z]** Pancerna postawa - +12% pancerza
- **[Z]** Hart ducha ✦ - +15% odporności na Nawię
- **[Z]** Gniew rannego ✦ - +1% obrażeń za każde 5% brakującego zdrowia
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)
- **[K]** Ostatni Bastion ✦ - poniżej 30% zdrowia +50% obrażeń i +50% redukcji obrażeń

### Ziemia (5)

- **[U]** Skok Niedźwiedzia ✦ (miecz; atak, obszar, ruch, fizyczne) - skok na wskazane miejsce, lądowanie rani i odrzuca wrogów wokół
- **[Z]** Ciężka ręka - +12% obrażeń obszarowych
- **[Z]** Wstrząs ✦ - umiejętności obszarowe miecza ogłuszają na 0,3 s
- [d] +8 siły
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)

### Dym (6)

- **[U]** Dymne Wybuchy (miecz) - ładowane wybuchy dymu (siła i inteligencja)
- **[Z]** Gęsty dym - +25% szybkości ładowania Dymnych Wybuchów
- **[U]** Widmowe Ostrza (miecz) - krążące ostrza (siła i inteligencja)
- **[Z]** Duszący dym - +20% obrażeń Dymnych Wybuchów
- **[Z]** Czwarte ostrze - +1 Widmowe Ostrze
- **[K]** Dym i Cień - po Dymnych Wybuchach chmura na 5 s: +30% uniku, Mgnienie bez many

Ścieżki: 13 drobnych węzłów (+4% zdrowia, +8 siły).

## Zręczność (łuk) (53 węzłów ze ścieżkami)

### Brama Zręczności (1)

- **[U]** Salwa (łuk; atak, pocisk, fizyczne) - zwykła umiejętność łuku (PPM)

### Grad (7)

- **[U]** Deszcz Strzał (łuk) - deszcz strzał na obszar; combo po Salwie
- **[Z]** Wachlarz - +1 strzała Salwy, strzały lecą wachlarzem
- **[Z]** Szereg ✦ - +1 pocisk umiejętności łuku, dodatkowe lecą równolegle obok siebie
- **[Z]** Gęsty grad - +25% kręgu Deszczu Strzał
- **[Z]** Ostre groty - +20% obrażeń Salwy i Deszczu Strzał
- **[K]** Grad - Salwa +2 strzały, Deszcz o połowę gęstszy, każda strzała -20% obrażeń
- [G] Gniazdo legendarne - kamień szlachetny albo esencja legendy

### Tropiciel (6)

- **[U]** Strzała tropiąca (łuk) - strzała sama szuka wrogów
- **[U]** Szybka salwa (łuk) - seria strzał - teraz zwykła umiejętność, po Strzale tropiącej mocniejsza (combo)
- **[Z]** Wierny tropiciel ✦ ⌛ - Strzała tropiąca krąży przy tobie jak przywołanie i sama strzela, ale rezerwuje 15% many
- **[U]** Strzała Żmija ✦ (łuk; atak, pocisk, fizyczne, trucizna) - jadowa strzała przeskakuje między 4 wrogami, każdy skok +10% obrażeń, trafieni zatruci
- **[Z]** Ostrzejszy trop - +1 trafienie Strzały tropiącej
- **[K]** Oko Sokoła - trafienia z daleka (ponad 150) zawsze krytyczne, z bliska (do 70) -30% obrażeń

### Myśliwy (6)

- **[U]** Grot Swaroga (łuk) - napinany strzał z wybuchem
- **[Z]** Napięta cięciwa - +25% szybkości napinania Grotu Swaroga
- **[U]** Rozszczepiona Strzała ✦ (łuk; atak, pocisk, fizyczne) - strzała po trafieniu rozpada się na 3 mniejsze lecące dalej
- **[Z]** Grot przebijający - strzały przebijają 1 wroga
- **[Z]** Daleki strzał - +20% zasięgu strzał, +15% obrażeń Grotu Swaroga
- **[K]** Strzelanie w biegu - strzelanie nie spowalnia, w biegu +15% szybkości ataku

### Wataha (przywołania) (6)

- **[U]** Sokół (łuk) - sokół atakuje wrogów
- **[Z]** Szpony - +20% obrażeń Sokoła
- **[U]** Balista (łuk) - stawiana balista
- **[Z]** Mocna balista - +25% czasu i +15% obrażeń Balisty
- **[U]** Wataha ✦ ⌛ (łuk; przywołanie, fizyczne) - przywołuje 2 wilki na 15 s; wilki gryzą i powalają wrogów
- **[Z]** Przewodnik stada ✦ ⌛ - +1 wilk, +15% obrażeń przywołań

### Pułapki i jad (6)

- **[U]** Sidła (łuk) - pułapki unieruchamiające
- **[Z]** Mocne sidła - +50% unieruchomienia Sideł
- **[U]** Jadowe Groty (łuk) - trujące strzały; combo po Sidłach
- **[Z]** Żmijowy jad - +25% obrażeń Jadowych Grotów
- **[U]** Kolczatka ✦ (łuk; atak, obszar, fizyczne, w czasie) - rozsypane kolce spowalniają i ranią (krwawienie) wrogów na nich
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)

### Cień (5)

- **[U]** Odskok (łuk) - odskok z rozrzutem strzał
- **[Z]** Lekki krok - -25% odnowienia Odskoku
- **[Z]** Unik łowcy - +4% uniku
- **[Z]** Ciche kroki ✦ - potwory w spoczynku zauważają cię z połowy odległości
- **[K]** Łowca w Cieniu ✦ - wrogowie, którzy cię jeszcze nie zauważyli, dostają +60% obrażeń i pierwsze trafienie zawsze krytyczne; wrogowie w walce z tobą -10%

### Szał (szybkość) (6)

- **[Z]** Szybkie ręce - +6% szybkości ataku
- **[Z]** Wiatr w nogach - +5% szybkości ruchu
- **[A]** Wiatr Strzyboga ✦ (każda broń; aura) - aura: +8% szybkości ruchu, ataku i rzucania
- **[Z]** Oddech w biegu ✦ - +3 regeneracji zdrowia/s, gdy biegniesz
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)
- **[K]** Szał Bitewny ✦ - zabójstwo daje ładunek +4% szybkości ataku i +2% ruchu (do 10), ładunki znikają po 3 s bez zabójstwa

Ścieżki: 10 drobnych węzłów (+8 zręczności).

## Inteligencja (księga) (60 węzłów ze ścieżkami)

### Brama Inteligencji (1)

- **[U]** Kula ognia (księga; czar, pocisk, obszar, ogień) - zwykła umiejętność księgi (PPM)

### Ogień (6)

- **[U]** Spadająca Gwiazda (księga) - meteoryt z podpaleniem
- **[Z]** Żar - +20% obrażeń Kuli ognia
- **[Z]** Tlący się ogień - +25% obrażeń podpalenia
- **[U]** Ściana Ognia ✦ (księga; czar, obszar, ogień, w czasie) - ściana płomieni w poprzek drogi pod kursorem pali wrogów; pociski przez nią lecące dostają obrażenia od ognia
- **[Z]** Wielki wybuch - +25% wybuchu Spadającej Gwiazdy
- **[Z]** Szybkie słowa - +25% szybkości ładowania Kuli ognia

### Lód (8)

- **[U]** Włócznia Marzanny (księga) - lodowa włócznia
- **[Z]** Przeszywający lód - Włócznia przebija 1 wroga
- **[U]** Zamieć (księga) - śnieżyca na obszar
- **[Z]** Długa zima - +25% czasu Zamieci i spowolnienia
- **[U]** Lodowy Pancerz ✦ (księga; czar, obszar, lód) - na 8 s tarcza z lodu przyjmuje ciosy; gdy pęknie, wybucha i zamraża wrogów wokół
- **[Z]** Zimna krew ✦ - +15% odporności na lód
- **[A]** Mroźny Oddech ✦ (każda broń; aura) - aura (jak Righteous Fire): lodowy wir rani co sekundę wrogów wokół i ciebie; więcej obrażeń lodu
- **[Z]** Mroźne serce - +15% obrażeń od lodu

### Piorun (7)

- **[U]** Łańcuch błyskawic (księga) - piorun skacze między wrogami
- **[U]** Fala piorunów (księga) - fala - teraz zwykła umiejętność, po Łańcuchu mocniejsza (combo)
- **[Z]** Rozgałęzienie - +1 cel Łańcucha błyskawic
- **[U]** Burza Peruna (księga) - burza bijąca piorunami
- **[Z]** Długa burza - +25% czasu Burzy Peruna
- **[U]** Kula Piorunów (księga) - wolna kula rażąca wrogów
- **[A]** Gniew Peruna ✦ (każda broń; aura) - aura: co 3 s piorun bije losowego wroga w pobliżu

### Runy (6)

- **[U]** Kamień Runiczny (księga) - kamień wzmacniający czary obok
- **[Z]** Moc run - +25% mocy Kamienia Runicznego
- **[Z]** Pieśń run - +10% obrażeń czarów
- [d] +8 inteligencji
- **[K]** Echo Run - czary drzewka w 30% wybrzmiewają drugi raz za darmo, ale rzucasz 10% wolniej
- [G] Gniazdo legendarne - kamień szlachetny albo esencja legendy

### Mana (6)

- **[U]** Tarcza Many (księga) - część ciosów przyjmuje mana
- **[Z]** Głęboki oddech - +10% many
- **[Z]** Źródło mocy - +2 regeneracji many/s
- **[Z]** Przelana moc ✦ - 8% otrzymanych obrażeń zabiera manę zamiast zdrowia
- **[Z]** Pełnia umysłu ✦ - +1% obrażeń za każde 5% many ponad połowę (najwyżej +10%)
- **[K]** Pełnia Mocy - ponad 90% many czary +40% obrażeń, wszystkie umiejętności +20% many

### Mgła (5)

- **[U]** Krok przez Mgłę (księga) - teleport
- **[Z]** Szybki krok - -25% odnowienia Kroku przez Mgłę
- **[U]** Błędne Ogniki ✦ ⌛ (księga; czar, przywołanie, ogień) - przywołuje 3 ogniki krążące przy tobie i strzelające do wrogów (zalążek nekromancji)
- **[Z]** Wierne ogniki ✦ ⌛ - +1 ognik, +15% obrażeń przywołań
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)

### Żywioły (5)

- **[Z]** Żywiołowa moc - +12% obrażeń od żywiołów
- **[K]** Harmonia Żywiołów - czar innego żywiołu niż poprzedni daje na 4 s +30% obrażeń magicznych
- **[Z]** Przebicie - +8% przebicia odporności
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)
- **[K]** Mistrz Żywiołów ✦ - zadajesz tylko żywioł, który ostatnio cię trafił (zmienia go w ten żywioł), ale +40% obrażeń

### Wola (rezerwacja) (4)

- **[Z]** Skupiona wola ✦ - aury rezerwują 10% many mniej
- [d] +5% many
- **[Z]** Żelazny umysł - +10% many, +1 regeneracji many/s
- **[K]** Krwawa Ofiara ✦ - aury rezerwują zdrowie zamiast many

Ścieżki: 12 drobnych węzłów (+4% many, +8 inteligencji).

## Strefa siła / zręczność (16 węzłów ze ścieżkami)

### Krwawienie (5)

- **[U]** Rozpłatanie (miecz) - cięcie z krwawieniem; combo po Mgnieniu
- **[Z]** Głębokie rany - +25% obrażeń krwawienia
- **[Z]** Otwarte rany ✦ - trafienia ciosami i pociskami mają 10% szansy na krwawienie (z każdą bronią)
- [d] +4 siły, +4 zręczności
- **[K]** Krwawy Szał - krwawienie wrogów leczy cię o 30% zadanych nim obrażeń - teraz z każdą bronią

### Ciosy i szarże (5)

- **[U]** Ciśnięte Noże ✦ (miecz albo łuk; atak, pocisk, fizyczne, w czasie) - rzut 3 nożami wachlarzem z krwawieniem; z mieczem noże wracają do ręki, z łukiem lecą dalej
- **[Z]** Celny cios - +12% obrażeń ciosów
- **[Z]** Impet ✦ - po umiejętności ruchu następne trafienie +30% obrażeń
- **[Z]** Krew za krew - +3 zdrowia za trafienie
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)

Ścieżki: 6 drobnych węzłów (+4 siły, +4 zręczności, +4% obrażeń ciosów).

## Strefa zręczność / inteligencja (17 węzłów ze ścieżkami)

### Burza i pociski (5)

- **[U]** Strzała Wichru (łuk) - podmuch odpychający (zręczność i inteligencja)
- **[Z]** Gromowładny - +15% obrażeń od piorunów
- **[U]** Strzała Gromu ✦ (łuk albo księga; atak, czar, pocisk, obszar, piorun) - piorunowy pocisk; z łuku przeskakuje na 2 wrogów, z księgi piorun z nieba uderza w obszar
- **[Z]** Porażenie - +8% szansy na porażenie
- **[Z]** Uziemienie ✦ - +15% odporności na pioruny

### Uniki (5)

- **[Z]** Unik tancerza - +4% uniku
- **[Z]** Zwiewność ✦ - po uniku +10% szybkości ruchu, ataku i rzucania na 2 s
- [d] +4 zręczności, +4 inteligencji
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)
- **[K]** Myśliwy z Cienia - po umiejętności ruchu (każdej, nie tylko Odskoku) wrogowie tracą cię z oczu na 2 s, pierwsze trafienie podwójne

Ścieżki: 7 drobnych węzłów (+4 zręczności, +4 inteligencji, +4% obrażeń pocisków).

## Strefa siła / inteligencja (17 węzłów ze ścieżkami)

### Aury (6)

- **[A]** Źródło Życia ✦ (każda broń; aura) - aura: +regeneracja zdrowia (zastępuje Krew wojownika, Oddech łowcy, Mistyczną odnowę)
- **[A]** Żar Swaroga ✦ (każda broń; aura) - aura: ataki i czary dostają obrażenia od ognia i szansę na podpalenie
- **[A]** Szron Marzanny ✦ (każda broń; aura) - aura: obrażenia od lodu i szansa na zamrożenie
- **[Z]** Oszczędne aury ✦ - aury rezerwują 8% many mniej
- **[A]** Iskry Peruna ✦ (każda broń; aura) - aura: obrażenia od piorunów i szansa na porażenie
- **[A]** Źródło Many ✦ (każda broń; aura) - aura: +regeneracja many (zastępuje Skupienie bitewne, Cierpliwość łowcy, Strumień many)

### Zaklęte ostrza (5)

- **[U]** Zaklęte Ostrze ✦ (miecz albo księga; atak, czar, cios, obszar, ogień) - z mieczem cięcie i krótka płonąca fala, z księgą dłuższa i szersza fala ognia
- **[Z]** Płonąca stal - +12% obrażeń od ognia
- **[Z]** Ognioodporny ✦ - +15% odporności na ogień
- [G] Gniazdo - kamień szlachetny (działa o połowę mocniej)
- **[K]** Żelazna Wola ✦ - obrażenia czarów rosną z siły zamiast z inteligencji

Ścieżki: 6 drobnych węzłów (+4 siły, +4 inteligencji, +4% obrażeń od ognia).

## Pierścień wokół startu

6 drobnych węzłów między bramami (+4% zdrowia, +6% odporności na żywioły) - pozwalają przejść do sąsiedniej strony bez okrążania.

## Liczby

| Rodzaj | Ile |
|---|---|
| start | 1 |
| umiejętność | 45 |
| aura | 10 |
| węzeł kluczowy | 18 |
| węzeł znaczący | 81 |
| drobny | 68 |
| gniazdo | 9 |
| gniazdo legendarne | 3 |
| **razem** | **235** |
