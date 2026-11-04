# Watra - lista zadań i pomysłów

Co jest do poprawienia po graniu autora („Do poprawy”) i co czeka na zrobienie („Pomysły i rzeczy do zrobienia”).
Zrobione punkty ze szczegółami są w `docs/historia.md`, wizja gry w `docs/GDD.md`, zasady grafiki w `docs/ART_SPEC.md`.
Plik jest długi - szukaj w nim grepem albo czytaj tylko potrzebną sekcję.

## Do poprawy

Konkretne poprawki istniejących krain i postaci, zgłoszone przez autora po graniu.

### Zasada ogólna: dużo potworów

- [ ] Domyślnie każde siedlisko potworów ma mieć **dziesiątki, a nawet setki potworów**, jak w miejscach farmienia w Black Desert albo w Path of Exile.
  Wyjątek: siedliska, których projekt wymaga inaczej (np. arena bossa).
  Przy zwiększaniu liczebności sprawdź wydajność (`tests/bench_combat.gd`, `tests/playtest_bot.gd`).
  Potwory w spoczynku, które się nie ruszają, pomijają `move_and_slide` (`scripts/goblin.gd`), żeby setki stojących potworów mało kosztowały.
  Plan uzgodniony z autorem: kraina po krainie (osobny PR), cel 600-800 wrogów na krainę, nowe siedliska z obecnych
  potworów na pustych terenach (z własnym wystrojem i sensem) i gęściej w istniejących. Liczy je `tests/bench_combat.gd`
  („spawns”); koszt rośnie z liczbą wrogów atakujących naraz (największa gromada), nie z liczbą w krainie.
  Zrobione (pomiar z listopada 2026): Gobliński Las 672, Pola Zbożowe 626, Rozlewiska 617, Wietrzne Turnie 637,
  Prastary Las 579, Leśny Cmentarz 682 - wszystkie krainy zrobione, punkt do zamknięcia po ograniu przez autora. Nowe siedliska losuj osobnym ziarnem (jak `FrogPonds`)
  i buduj na końcu, żeby w starych zapisach reszta krainy się nie zmieniła. Przy przebudowie całej krainy podbij
  jej wersję układu (`World.ZONE_LAYOUTS`) - postać ze starego zapisu wróci do kapliczki.
  Walka w największej gromadzie każdej krainy kosztuje średnio 7-8,5 ms na klatkę.
  Walkę z rysowaniem i umiejętnościami mierzy `tests/bench_village.gd` (z oknem, scena na uruchomienie:
  stoi / miecz / ksiega / mgnienie) - wypisuje najwolniejsze klatki z liczbą zabitych i zmianą liczby węzłów.
  Szukając, co kosztuje, mierz kawałki kodu stoperem (`Time.get_ticks_usec`) - profiler Godota działa tylko w edytorze.

### Zgłoszenia z listopada 2026

- [ ] **Gra za łatwa w końcówce** (autor, 3.11.2026): poprawione, czeka na ocenę autora (szczegóły w `docs/historia.md`,
  szukaj „Końcówka gry trudniejsza”): krótsza nietykalność, limit kradzieży życia, odporność potworów na przerwanie
  zamachu i odrzut, słabszy pancerz, dużo mocniejsze potwory ponad 41. poziomem i do 4x więcej potworów w lochach
  najwyższych stopni (etap 2). Pomiar siły postaci z zapisu:
  `godot --headless --path . -s res://tests/endgame_probe.gd -- <zapis.json> <stopień> <sekundy> [full|whirl|flicker|bow|spell|idle|uro] [poziom] [poziom ekwipunku]`. Do ustalenia po ograniu: liczby (`Levels.ENDGAME_*`,
  `LEECH_CAP`), czy umiejętności łuku i księgi też trzeba sprawdzić tym pomiarem.
- [ ] **Za mała gęstość potworów w Uroczyskach** i ogólnie za mało potworów (autor, 3.11.2026): poprawione, czeka na
  ocenę autora - lochy do 4x więcej potworów w najwyższych stopniach, Uroczysko ok. 3x więcej upiorów naraz, gromadami
  (szczegóły w `docs/historia.md`, szukaj „Gęstsze Uroczyska”).


## Pomysły i rzeczy do zrobienia

Aktualizuj tę listę, gdy autor rzuci nowy pomysł. Zrobiony punkt przenieś (ze szczegółami) do `docs/historia.md`,
a w `CLAUDE.md` zostaw najwyżej linię w „Systemy w grze”.
Przed rozpoczęciem większego punktu dopytaj autora o szczegóły, bo to luźne pomysły, a nie gotowe projekty.

### Postać i przedmioty

- [ ] **Dopieszczenie i usystematyzowanie walki** (plan z autorem, listopad 2026; każdy krok osobny PR):
  1. prędkość ataku - zrobione (szukaj „Malejące zyski szybkości” w `docs/historia.md`): malejące zyski i sufit
     +150% (`CharacterStats.speed_gain`), 1% za punkt zręczności / inteligencji, Salwa i Mgnienie z najkrótszym
     odstępem (umiejętności liczą tylko szybkość postaci, bez szybkości broni - do przemyślenia przy statystykach);
  2. tagi umiejętności - zrobione razem z 2b (szukaj „Tagi umiejętności i atrybuty” w `docs/historia.md`):
     `Skills.TAGS` w 4 grupach (rodzaj, forma, obrażenia z „tajemnymi”, atrybut), ikonki z `tools/tag_icons.py`
     w oknie K i na paskach;
  3. nowe premie na tagach - zrobione (szukaj „Krok 3 dopieszczenia walki” i „Żywioły, etap 2” w `docs/historia.md`):
     obrażenia żywiołów, pocisków / ciosów / obszarowe, w czasie, szanse na podpalenie / zamrożenie / porażenie,
     przebicie odporności. Czeka na ocenę autora;
  2b. statystyki jak w Last Epoch - zrobione: +1% obrażeń za punkt atrybutu z tagu (zamiast płaskiego +1), siła -
     redukcja, zręczność - unik 0,4% za punkt (malejące zyski, do 35%), inteligencja - mana, witalność - zdrowie;
     szybkość tylko z broni, przedmiotów i drzewek, umiejętności liczą prędkość broni; darmowy reset w starych zapisach.
     Czeka na ocenę autora;
  4. **gniazda i kamienie wsparcia** (jak w PoE) - etapy 1 i 2 zrobione, czekają na ocenę autora (szukaj „Kamienie wsparcia,
     etap” w `docs/historia.md`): `scripts/supports.gd`, 17 kamieni z poziomami 1-20 (rosną z doświadczeniem postaci
     w gnieździe, 3 takie same łączą się w 1 o 2 poziomy wyższy), gniazda w `SkillBook.supports` (1-4 Krzesiwem Nawii
     za 1/2/4/8, 5. Wielkim Krzesiwem), bez zwykłego ataku, bez rynku; okno K, tryb deweloperski F6.
     Etap 2: **Mgła Nawii** (`scripts/nawia_mist.gd`, stałe `MIST_*` w `Dungeons`) - mechanika lochów, jedyne źródło
     kamieni i krzesiw (Wielkie Krzesiwo od gęstości 8 i ze skarbców bogów); zwykła gałąź mechaniki w drzewku Watry
     już jest. Etap 3 zrobiony (szukaj „Kamienie wsparcia, etap 3”): własne węzły Mgły w drzewku Watry
     (`WatraTree.EXTENSIONS`, `Dungeons.mist_rules`) i Bożek Mgły. Liczby Mgły autor po ograniu zostawił bez zmian.
     Czeka na ocenę autora.
- [ ] Nowe bronie: kosa, kostur (nekromanta), młoty, chainblade'y, sztylety, włócznie, rapier, hydrosfera.
  Każda broń to nowy rodzaj z własnym drzewkiem, a nie tylko nowy przedmiot, więc wymaga szczegółów od autora.
  Ustalenia z rozmowy z autorem (pomysły, nie decyzje):
  - nowa broń to koszt całego drzewka (około 12 umiejętności, 35 pasywnych, 4 kluczowe), broni w ręku 4 postaci,
    linii przedmiotów (5 poziomów x 3 rzadkości), legend i efektów - dodawać po jednej i taką, która gra inaczej
    niż miecz, łuk i księga;
  - **kostur nekromanty** - najmocniejszy kandydat: przywołańcy (upiory, strzygi walczące za gracza), czego gra nie ma;
  - **hydrosfera** - kontrola pola wodą: fale odpychające, wiry ściągające, kałuże spowalniające, lód z księgą
    (Wodnik, rusałki);
  - **chainblade'y** (dwa miecze na łańcuchach) - efektowne, ale bliskie mieczowi; potrzebują własnego pomysłu
    (przyciąganie łańcuchem, ataki na średni dystans). Próbka efektu „dwa szybkie obroty z czerwoną poświatą”
    w kreatorze PixelLab: efekt `70533e5e-74fc-4e0c-bcf5-842dde7d4d03`;
  - **kosa** (w stylu Sorceress z BDO) i **włócznia** - raczej jako odnogi (specjalizacje) istniejących drzewek
    z kilkoma własnymi umiejętnościami, jak wniebowstąpienia w PoE, niż osobne bronie;
  - **przełączania broni NIE będzie** - autor chce, żeby gracz przywiązał się do jednego stylu gry.
- [ ] **Wspólne drzewko umiejętności, aury, combo i przebudzenia** (burza mózgów z autorem, listopad 2026) - pełny
  plan w `docs/plan_drzewek.md`. Ustalone: jedno wspólne drzewko 200-250 węzłów (strony siła / zręczność /
  inteligencja, strefy pośrednie, skupiska tematyczne, wyróżnione umiejętności aktywne), umiejętności nadal wymagają
  swojej broni, klas nie ma - gracz wybiera konkretne przebudzenie (pomysły: magia cieni z kosą, chainblade'y,
  bojowy mag z glewią / runicznym rapierem; przebudzenie przez zadanie u żercy Wszebora, jedna ulepszana broń
  przebudzenia, broń w ręku zmienia się sama), nekromancja jako gałąź magii, nowe combo, drzewko lochów od nowa.
  Krok 2 zrobiony, czeka na ocenę autora (szukaj „Wspólne drzewko umiejętności, krok 2” w `docs/historia.md`): drzewko
  w grze z obecnymi umiejętnościami, nowe umiejętności i nowe węzły kluczowe to puste miejsca; stare zapisy -
  zwrot wszystkich punktów, dodatkowo 1 punkt umiejętności co 2 poziomy postaci. Krok 3 (aury i rezerwacja many) zrobiony,
  czeka na ocenę autora (szukaj „Aury rezerwujące manę - krok 3”). Krok 4 (nowe combo; Półksiężyc, Szybka salwa
  i Fala piorunów jako zwykłe umiejętności) zrobiony, czeka na ocenę autora (szukaj „Nowe combo - krok 4”).
  Krok 5 (nowe węzły kluczowe i nowe umiejętności) idzie strona po stronie: strony siły, zręczności i inteligencji
  oraz strefy pośrednie zrobione, czekają na ocenę autora (szukaj „Krok 5 wspólnego drzewka, strona siły”, „…, strona
  zręczności”, „…, strona inteligencji” i „…, strefy pośrednie”) - Wilczy Kieł, Ryk Tura, Skok Niedźwiedzia, Ostatni
  Bastion, Strzała Żmija, Rozszczepiona Strzała, Kolczatka, Łowca w Cieniu, Szał Bitewny, Ściana Ognia, Lodowy Pancerz,
  Mistrz Żywiołów, umiejętności z dwiema broniami (Ciśnięte Noże, Strzała Gromu, Zaklęte Ostrze - `scripts/zone_skills.gd`),
  Żelazna Wola i węzły znaczące; ikony z PixelLab (`tools/tree_step5_icons.py`). Przywołania (Wataha, Błędne Ogniki,
  Wierny tropiciel, Przewodnik stada, Wierne ogniki) też zrobione, czekają na ocenę autora (szukaj „…, przywołania”) -
  krok 5 skończony, w drzewku nie ma już pustych miejsc. Krok 6 (nowe drzewko lochów) zrobiony, czeka na ocenę autora
  (szukaj „Nowe drzewko lochów” w `docs/historia.md`). Dalej krok 7 (przebudzenia).
- [ ] **Modyfikacja premii tylko runami** (decyzja autora, listopad 2026): wszystkie sposoby zmiany premii
  (afiksów) przedmiotów mają działać przez runy - przedmioty-waluty jak orby w Path of Exile. Zrobione razem
  z Uroczyskiem (szukaj „Mechaniki w lochach, etap 3”): każde działanie warsztatu kowala zużywa swoją runę
  (`ItemCraft.ACTIONS`, `ItemCraft.RUNES`), trofea już tam nie idą. Do ustalenia: kolejne runy (np. jak orby
  wyższego poziomu), czy runy mają wypadać też poza lochami, ewentualne grafiki run z PixelLab zamiast przebarwień.
- [ ] **Animacje postaci z bronią** (listopad 2026): broń nie leży stabilnie w dłoni, za mało animacji ataków.
  Ustalenia z autorem: porządnie animowany tylko **Wojciech** (reszta może zostać NPC), styl **zamaszysty jak w BDO**,
  nowe pozy ciała (etap 4) na później. Etap 1 zrobiony (szczegóły w `docs/historia.md`, szukaj „Etap 1 animacji”):
  ataki Wojciecha po 8 klatek z ruchów szkieletowych PixelLab, broń w dłoni w każdej klatce ataku. Etap 2 zrobiony
  (szukaj „Etap 2 animacji”): seria 3 cięć w zwykłych atakach i własne ruchy Rozpłatania, Rozłupania Ziemi, Szarży,
  Półksiężyca i Młynka; zrzuty klatek ataków w grze robi `tools/anim_shots.gd`. Etap 3 zrobiony (szukaj „Etap 3 animacji”):
  cięciwa łuku rysowana w kodzie (`BowString`, `tools/bow_strings.py`) i własne ruchy umiejętności łuku i księgi
  (`Player.SKILL_MOVES`, chwyt ze znaczników stanu „Znacznik” w PixelLab). Etap 4 zrobiony (szukaj „Etap 4 animacji”):
  oddech w spoczynku, chód po 8 klatek, zryw i upadek przy śmierci. Punkt do zamknięcia po ograniu przez autora.
- [ ] **Aury rezerwujące manę**: zrobione, czekają na ocenę autora (szukaj „Aury rezerwujące manę - krok 3”
  w `docs/historia.md`). Do ustalenia po ograniu: liczby (`scripts/aura_data.gd`), gniazda na kamienie wsparcia
  dla aur, animacje ataków aur żywiołów z kreatora efektów PixelLab.
- [ ] **Bogatsze strefy pośrednie, autostrady i odporności we wspólnym drzewku** (pomysł autora, listopad 2026): zrobione,
  czeka na ocenę autora (szukaj „Bogatsze strefy pośrednie” w `docs/historia.md`): po 2 nowe skupiska w każdej strefie,
  skupiska odporności, autostrada wewnętrzna i zewnętrzna (`RINGS` w `tools/shared_tree_draft.py`), maksymalna odporność
  z węzłów (+2%, limit 85% - `CharacterStats.max_resistance`). Do zrobienia później: więcej umiejętności łączonych
  w strefach, maksymalna odporność także z legend albo talizmanów.
- [ ] **Przebudowa rozwoju postaci**: zastąpiona planem wspólnego drzewka (`docs/plan_drzewek.md`). Osobne punkty
  statystyk (2 za awans) i umiejętności (pasek) już są - punkt niżej.
- [ ] **Punkty umiejętności z osobnego paska doświadczenia** (pomysł autora, listopad 2026; jak w BDO): zrobione,
  czeka na ocenę autora (szukaj „Pasek umiejętności” w `docs/historia.md`): pasek `SkillBook.skill_xp` z progami
  `Skills.SKILL_XP_BANDS`, poziomy umiejętności 1-20 za punkty (`Skills.LEVEL_POINTS` 1/2/3/5, wzory przez
  `Skills.power` i `Skills.count`), 2 punkty statystyk za awans, cofanie za złoto (`Skills.REFUND_GOLD_PER_LEVEL`),
  stare zapisy przelicza `SkillBook.migrate_old` (zwrot złota i punktów). Do ustalenia po ograniu: progi paska,
  cena cofania, siła poziomów 6-20, punkty na start.

### Watra i Ostoja

- [ ] **Kryształ Watry** (autor, listopad 2026): na razie zostaje obrona przed falami (etap 6 - fale rosną ze stopniem
  lochu); nowy sposób działania do ustalenia z autorem później.
- [ ] Pomysły do Kryształu Watry: komnata z kowadłem w lochu (jednorazowo wyższa szansa zaklinania), kolejne
  warianty zdarzenia.
- [ ] **Mechaniki w lochach - powód, żeby robić lochy** (plan z autorem, listopad 2026; najpierw mechaniki, potem
  atlas, nowe klimaty lochów odłożone). W każdym lochu co najmniej 1 mechanika, z małą szansą druga i trzecia; proste
  częściej, duże rzadziej; drzewko rozwoju Watry podnosi szanse (aż do 100% na wybraną mechanikę) i wzmacnia
  mechaniki. Każda większa mechanika ma własny, unikalny łup:
  - **Skrzynki** (jak strongboxy) - zwykły łup, czasem z cechami (pułapka, więcej przedmiotów);
  - **Kapliczki** - buff na czas lochu;
  - **Elitarne potwory** z cechami (wzmacniają wrogów wokół) - więcej i lepszego łupu;
  - **Uroczysko** - dotknięty kamień otwiera rosnący krąg innego świata pełen upiorów, na czas - łup: **runy**
    (patrz „Modyfikacja premii tylko runami”);
  - **Krąg Żertwy** (nie „Ołtarz Welesa” - ta nazwa jest już zajęta przez esencje) - zabici wrogowie w kręgu dają
    daninę, za nią wybór nagrody - łup: **talizmany**;
  - **Skarbnik** - nagroda z ryzykiem (jak Ultimatum w PoE): zrobiony (etap 5), szczegóły w `docs/historia.md`;
  - **Kryształ Watry** - jedyne źródło **kamieni zaklinania** w lochach (etap 6; skarbiec daje już tylko kamienie
    uświęcone), rynek i nagroda zadania głównego zostają jako drogie wyjście awaryjne; Kryształ wypada często;
  - **Mgła Nawii** - loch coraz trudniejszy i hojniejszy z każdą minutą - łup: **kamienie wsparcia i krzesiwa**
    (etap 7, szukaj „Kamienie wsparcia, etap 2” w `docs/historia.md`);
  - pomysły na później: **Kurhan** (wysadzanie kurhanów prochem, artefakty wymieniane u handlarza w Ostoi), **Łowy** (chwytanie
    rzadkich bestii do zagrody w Ostoi - składniki rzemiosła).
  Odrzucone przez autora: zbłąkany wędrowiec, Noc Kupały, Zakład z biesem, Licho, Dziady.
  Etap 1 zrobiony, czeka na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Mechaniki w lochach, etap 1”):
  losowanie mechanik (`Dungeons.MECHANICS`, `roll_mechanics` z miejscem na premie drzewka Watry), skrzynie
  (`dungeon_chest.gd`), kapliczki (`dungeon_shrine.gd`), Kryształ w puli, mniej kamieni zaklinania ze skarbca.
  Etap 2 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 2”): elitarne potwory z cechami
  (`dungeon_elite.gd`, `Dungeons.ELITE_TRAITS` - aury, obrona, żywioły, przywołanie).
  Etap 3 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 3”): Uroczysko (`uroczysko.gd`, stałe
  `URO_*` w `Dungeons`) - krąg upiorów rosnący z zabójstwami, nagroda - runy.
  Etap 4 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 4”): Krąg Żertwy (`zertwa.gd`, stałe
  `ZER_*` w `Dungeons`) - danina za wrogów zabitych w kręgu, nagroda - wybór 1 z 3 talizmanów.
  Etap 5 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 5”): Skarbnik (`skarbnik.gd`,
  `skarbnik_offer.gd`, stałe `SKA_*` w `Dungeons`) - oferta, Wzmocnij / Przelosuj z falami, księga ofert przeciw
  wczytywaniu zapisu, sufit tierów; przy okazji przegląd tierów T1 (`tests/tier_sim.gd`, nowe `Loot.TIER_VALUES`).
  Do ustalenia po ograniu: liczby fal i wrogów, szansa na Kości, czy Skarbnik ma mieć własną grafikę.
  Etap 6 zrobiony, czeka na ocenę autora (szukaj „Mechaniki w lochach, etap 6”): obrona Kryształu zostaje, fale rosną
  ze stopniem lochu (`WatraCrystal.wave_count`), skarbiec strażnika bez kamieni zaklinających.
  Etap 7 zrobiony, czeka na ocenę autora: Mgła Nawii (`nawia_mist.gd`) - Mglisty Słup, gęstość co minutę do 10,
  Skrzynia Mgły; Kryształ Watry dostał wagę 7,8 (był 7), żeby po dojściu Mgły trafiał się tak samo często.
- [ ] **Bożki** (jak skaraby w PoE): zrobione, czekają na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Bożki”):
  `scripts/idols.gd`, 33 rodzaje (3 rzadkości, 2 prastare), sloty w oknie lochów (2, więcej z poziomem Watry), zużywają
  się przy wejściu, bożki potworów i łupu mogą być w kilku slotach. Węzły bożków w drzewku Watry zrobione (gałąź „Bożki”).
  Do ustalenia po ograniu: szansa wypadania, siła rodzajów,
  czy ikony mają być z PixelLab (paczka 16 obiektów - 10 generacji).
- [ ] **Talizmany** (jak idole w Last Epoch): zrobione razem z Kręgiem Żertwy (szukaj „Mechaniki w lochach, etap 4”) -
  siatka 4x3, kształty 1x1, 1x2, 2x1, 2x2, magiczne z premiami, rzadkie z efektem legendy. Do ustalenia: rosnąca
  siatka (poziom, drzewko Watry), własne efekty talizmanów zamiast efektów legend (np. ognista tarcza przy niskim
  zdrowiu), grafiki z PixelLab zamiast rysowanych w kodzie, rzemiosło talizmanów runami.
- [ ] **Mapa Nawii - endgame jak atlas w PoE** (ustalenia z autorem, listopad 2026; przed drzewkiem Watry albo razem
  z nim). Z PoE bierzemy szkielet (mapa węzłów-lochów, przejście odsłania sąsiednie, rosnące stopnie, punkty do
  drzewka, bossowie szczytowi), wygląd i nazwy własne, słowiańskie:
  - osobna **Mapa Nawii** (zaświaty wylane na świat przez Hordę) w oknie Watry; węzły to lochy z klimatem i stopniem;
  - **wpływ na świat**: oczyszczone obszary mapy zdejmują spaczenie z prawdziwych krain (premie, obozy - łączy się
    z punktem „Budowa i rozbudowa obozów” w „Świat”);
  - **wejście bez kosztów** (ograniczeniem jest tylko trudność); bożki nadal wkładane przed wejściem;
  - **dzisiejsze lochy zostają do ~40. poziomu** (nauka mechanik, rozwój postaci); po 40. poziomie / Cmentarzu
    otwiera się mapa z wyższymi stopniami;
  - **bossowie szczytowi**: słowiańscy bogowie (np. Weles, Marzanna, Czarnobóg), obce bogi (grecki, nordycki,
    egipski - patrz „Obce mitologie”) i Władca Hordy jako ostateczny boss;
  - **ustalone (listopad 2026)**: mapa **duża, 80+ węzłów** jak pełny atlas PoE, 6 obszarów (po jednym na krainę
    świata), węzeł przejdziony po pokonaniu strażnika, wtedy odsłania sąsiednie (mgła); **10 nowych stopni 8-17,
    poziomy potworów 45-90 co 5** (bossowie szczytowi ~92-95, pełny zakres łupu); oczyszczony obszar daje w swojej
    krainie **premię** (łup, doświadczenie, kraina bez spaczenia na mapie świata), **miejsce na obóz** i **wariant
    endgame krainy** (potwory na poziomie mapy - stare krainy znów do farmienia); **1 punkt drzewka Watry za każdy
    nowy węzeł** (bossowie szczytowi więcej; punkty zbierane, zanim drzewko powstanie);
  - kolejność: 1) okno mapy, węzły, odsłanianie, stopnie 8-17 z balansem (`tests/balance_sim.gd`), 2) oczyszczanie
    krain (Błogosławieństwo Watry), 3) drzewko Watry (razem z węzłami bożków), 4) bossowie szczytowi po jednym;
  - etap 1 zrobiony, czeka na ocenę autora (szczegóły w `docs/historia.md`, szukaj „Mapa Nawii, etap 1”): mapa
    losowana z ziarna zapisu (`scripts/nawia_map.gd`, 90 węzłów), okno `ui/nawia_window.gd` (przycisk „Nawia” w oknie
    Watry, rysowane w kodzie - ładna mapa z PixelLab później), stopnie 8-17 (`Dungeons.TIER_LEVELS`, `BASE_TIERS`,
    `power_tier`), balans końcówki `Levels.ENDGAME_*`, postęp i punkty Watry w `Boons.nawia_cleared`;
  - etap 2 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 2”): zamiast spaczenia **Błogosławieństwo Watry**
    - F przy kapliczce krainy (od 1. oczyszczonego węzła jej obszaru) podnosi potwory do poziomu najtrudniejszego
    oczyszczonego węzła, łup i doświadczenie +2% za węzeł (`NawiaMap.blessing_*`, `Boons.nawia_blessed`,
    `ui/blessing_window.gd`, `Levels.zone_range`); miejsce na obóz odłożone do punktu o obozach;
  - etap 3 zrobiony (szukaj „Mapa Nawii, etap 3”): **drzewko Watry** (`scripts/watra_tree.gd`, okno
    `ui/watra_tree_window.gd`), 3 zakładki z osobnymi pulami punktów, cofanie za złoto; premie idą do lochu
    w `config["tree"]`;
  - etap 4 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 4”): **bossowie szczytowi** Weles, Marzanna,
    Czarnobóg (`scripts/pinnacles.gd`, `scripts/pinnacle_boss.gd`) - areny za 4 fragmenty kluczy z węzłów, serca
    na legendy, pasy w stylu Mageblooda i Headhuntera (Pas Wiecznych Ziół, Pas Łowcy Dusz, 10 serc);
  - etap 5 zrobiony, czeka na ocenę autora (szukaj „Mapa Nawii, etap 5”): **Władca Hordy** (`scripts/horde_lord.gd`) -
    wejście za serce każdego boga, 4 fazy z cieniami bogów i falami Hordy, legendy Władcy, Pas Zimowego Oddechu
    (Marzanna), tytuł „Pogromca Hordy”, posąg w Ostoi i stopnie **Pomroku** I-X dla wszystkich aren;
  - **drzewko Watry od nowa** zrobione, czeka na ocenę autora (szukaj „Nowe drzewko lochów” w `docs/historia.md`):
    ok. 500 węzłów, 4 skupiska każdej mechaniki porozrzucane po drzewku, ścieżki neutralnych węzłów, węzły zmieniające
    mechaniki (`Dungeon.tree_value`), podwójne mechaniki, węzły kluczowe z ceną, zwrot punktów Watry;
  - do zrobienia: obce bogi; do ustalenia po ograniu: siła bogów i Władcy, szanse na fragmenty i pasy, liczby
    Pomroku, liczby w drzewku Watry, ewentualne ikony węzłów z PixelLab. Punkty Watry podniesione (szukaj „Więcej punktów
    Watry” w `docs/historia.md`): 2 za węzeł, 5 za boga, 10 za Władcę - ok. 205 na ~500 węzłów drzewka.
- [ ] **Obce mitologie jako odległe królestwa** (luźny pomysł autora): świat zostaje słowiański, a królestwa grecki,
  nordycki, egipski tylko w końcówce gry (np. wrota w atlasie, najeźdźcy przez płomienie Watry), każde jako mały
  obszar z bossem szczytowym - obcym bogiem; tłumaczy hydrę i satyry. Na pinnacle nadają się też słowiańscy bogowie.
- [ ] Pomysły na rozwój lochów: kolejne klimaty (lodowe jaskinie, wulkaniczna kuźnia, krasnoludzkie ruiny), kilka pięter
  w dół z coraz lepszym łupem, elitarne potwory z własnymi cechami, pułapki i zagadki, własni strażnicy lochów
  zamiast bossów z krain, sekretne komnaty, zlecenia gildii na lochy.
- [ ] **Lochy ładne i bogate w środku** (listopad 2026): dokładniej przyjrzeć się wystrojowi lochów.
  Ustalenia z autorem po zrzutach (2026-11-02): razi wszystko - mało rodzajów lochów, monotonne ściany, jednolite
  podłogi, komnaty jako gołe prostokąty, ozdoby sypane losowo zamiast scenek, płaskie światło. Grafiki: PixelLab
  (duże ozdoby, płytki) + kod (nakładki, światło, rozmieszczenie); gdzie pasuje, używać gotowych grafik z krain.
  Kolejność: najpierw odnowić **Katakumby** na próbę, potem resztę podziemnych klimatów, potem nowe lochy
  **na zewnątrz** (granicą woda, drzewa, skarpy, palisada, góry; polany połączone ścieżkami o organicznych
  kształtach): Winnica satyrów (półki skalne i drzewa; grafiki `assets/forest/props/satyr_*`), Oblężony gród
  (palisada, chaty), Wyspy na bagnie (kępy, kładki, brody), Przesmyk w Turniach (wąwozy, półki), Święty gaj / uręba
  (ściana drzew, kręgi kamieni). Każdy klimat może mieć też wariant **otwarty** (połać terenu) z innym bossem niż
  wersja zamknięta.
  Krok 1 (Katakumby) i krok 2 (Kopalnia goblinów: tory, skład prochu, kuźnia, obóz, szyb z windą, zawał, żyła
  kruszcu, tron wodza) i krok 3 (Zatopione podziemia - zalana świątynia bogów wody: świątynia, kładki, wraki,
  gniazdo topielców, grota z ognikami, obóz żabołaków, sala rusałek, źródło, tron wodnika) i krok 4 (Pajęcze
  korzenie - dzikie jaskinie: wylęgarnia, spiżarnia, korzenie, grzybnia, sieciowa sala, kryjówka drzewców, obóz
  łowców, pajęczy ołtarz, gniazdo królowej) zrobione, czekają na ocenę autora - szczegóły w `docs/historia.md`
  (szukaj „Wystrój lochów”). Wszystkie podziemne klimaty mają wystrój. Krok 5 (Winnica satyrów - pierwszy loch na
  zewnątrz: polany, kręte ścieżki, granicą klify, ściana drzew i stawy - `Dungeon.outdoor`, `decor_vineyard.gd`) zrobiony,
  czeka na ocenę autora. Krok 6 (Oblężony gród - granicą palisada po gładkim obrysie, `Dungeon._build_palisade`, za nią
  spalone zagrody; `decor_stronghold.gd`) zrobiony, czeka na ocenę autora; dalej Wyspy na bagnie, Przesmyk w Turniach,
  Święty gaj.
  Kolejny klimat: "decor" w `Dungeons.CLIMATES`, skrypt `scripts/decor_<klimat>.gd` (dziedziczy po `DungeonDecor`),
  paczki PixelLab w `pixellab_src/dungeons/` i wpis w `tools/dungeon_props.py`; zrzuty sal: `tools/dungeon_shots.gd`.
- [ ] **Podział lochów na zwykłe i endgame'owe** (listopad 2026): zwykłe jak dziś; endgame'owe z przedmiotami w Watrze
  (skaraby), drzewkami lochów i mechanik, losowymi mechanikami i bossami szczytowymi (pinnacle), plus system jak
  atlas w PoE dający namacalny postęp. Wymaga projektu z autorem przed pracą.

### Zielarstwo

- [ ] Pomysły na rozwój zielarstwa: rzadsze odmiany ziół i mocniejsze mikstury na wyższe poziomy, mikstury łączące dwa zioła,
  zioła w lochach, ogródek ziołowy w Ostoi.

### Gildia i świat jak w MMO

Oba systemy zależą od gildii poszukiwaczy przygód w Ostoi (budowla `guild` w `scripts/settlement.gd`, tablica ogłoszeń w `scripts/bounties.gd` i `scripts/ui/board_window.gd`).

- [ ] **Druga Watra** (pomysł autora, późna gra): odnaleziona druga Watra i wielki system budowy nowego schronienia
  wokół niej - duże ujście surowców.

### Tłumaczenie na angielski

- [ ] Poprawki tłumaczenia przez autora (kolumna „en” w `translations/teksty.csv`, nazwy w `translations/slowniczek.md`).

### Świat

- [ ] Budowa i rozbudowa obozów w innych krainach, które pasywnie dają surowce albo inne korzyści. Decyzja autora
  (4.11.2026): drewna i kamienia gracz nie musi już zbierać ręcznie - mają je zbierać robotnicy w obozach (jak w BDO),
  a ich ujściem będą np. rangi gildii i Druga Watra.
- [ ] Wydarzenia w świecie - dalsze pomysły: kolejni world bossi (np. Baba Jaga w chacie na kurzych nogach), kolejni
  bossowie polowań, zawody na święcie (strzelanie do tarcz, manekiny na czas).
- [ ] Uzupełnienie siatki mapy świata (dziś krainy stoją w kształcie krzyża) o 6 krain:
  - 2 nad Polami Zbożowymi (`map_offset` (-200,-150) i (-200,-300)),
  - 2 nad Rozlewiskami ((200,-150) i (200,-300)),
  - 2 nad Wietrznymi Turniami ((400,-150) i (400,-300)).
  Po tym mapa jest pełnym prostokątem 4x3.
- [ ] Duża mapa świata ma wyglądać jak prawdziwa, ładna mapa, a nie jak siatka kafelków (`scripts/ui/world_map_view.gd`, `scripts/ui/big_map.gd`).

### Nowe krainy

- [ ] **Wysokie góry**:
  - harpie, bardzo liczne, z Królową Harpii jako bossem,
  - kryształowe pająki z Kamienną Królową jako bossem,
  - górskie wiwerny,
  - kamienne golemy,
  - górskie gryfy.
- [ ] **Lodowe góry**: żywiołaki lodu, lodowe bestie.
- [ ] **Drugie Rozlewiska**: pijawki, owady bagienne, utopieni mieszkańcy wioski, mięsożerne rośliny.
- [ ] Ruiny miasta.
- [ ] Las grzybów.
- [ ] Spaczone równiny.
- [ ] Piaszczysta pustynia.
- [ ] Skalista pustynia.
- [ ] Wulkaniczne pola.
- [ ] Stare krasnoludzkie podziemne miasto.

