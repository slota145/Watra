# Wspólne drzewko umiejętności - układ i węzły (szkic do akceptacji)

Krok 1 z `docs/plan_drzewek.md`. Na razie tylko dane: gra się nie zmienia. Po akceptacji autora krok 2 przebuduje
`scripts/skill_tree.gd`.

- Rysunek: `docs/drzewko_wspolne.png`
- Pełna lista węzłów z premiami: `docs/drzewko_wspolne_wezly.md`
- Dane, z których powstają oba pliki: `tools/shared_tree_draft.py` (po zmianie uruchom `python tools/shared_tree_draft.py`)

## Ustalenia z autorem (4.11.2026)

- **Umiejętności:** wszystkie obecne i do tego **5 nowych na każdą stronę**.
- **Węzły kluczowe:** **5 na każdą stronę + 1 w każdej strefie pośredniej**, razem 18.
- **Wszystkie 7 propozycji węzłów kluczowych wchodzi.** „Krew za Manę” to dawna Ofiara Krwi z księgi, teraz z każdą
  bronią, więc nowych jest 6.
- **Regeneracje:** 6 dzisiejszych umiejętności regeneracji (po 2 na broń) znika. Na ich miejsce wchodzą:
  - **skupiska premii** po każdej stronie, każde z innym podejściem, żeby gracz mógł mocno podbić te statystyki:
    - Siła, „Krzepa”: zdrowie, regeneracja zdrowia, aura +% zdrowia,
    - Zręczność, „Szał”: regeneracja w biegu, szybkość,
    - Inteligencja, „Mana” i „Wola”: mana, regeneracja many, część obrażeń zabiera manę, mniejsza rezerwacja aur;
  - **2 aury**, które działają z każdą bronią: Źródło Życia i Źródło Many (strefa siła / inteligencja).
  Moja opinia: to dobry pomysł. Dziś regeneracje są nudnymi przyciskami, a w skupiskach to wybór, czy budować postać
  na wytrzymałość, czy na obrażenia.

## Układ

```
                       Strefa S/Z
               (krwawienie, ciosy, szarże)
     SIŁA (miecz)        Krwawy Szał         ZRĘCZNOŚĆ (łuk)
   góra-lewo                                 góra-prawo
                 Młynek ── START ── Salwa
   Strefa S/I              │                 Strefa Z/I
 (ogień, aury,          Kula ognia      (pioruny, uniki,
  zaklęte ostrza)          │             pociski czarów)
  Żelazna Wola                           Myśliwy z Cienia
                     INTELIGENCJA (księga)
                           dół
```

- **Start** w środku. Obok niego 3 **bramy**: zwykła umiejętność każdej broni (Młynek, Salwa, Kula ognia).
  Bramy łączy pierścień 6 drobnych węzłów (zdrowie, odporności), więc do strefy pośredniej można dojść od razu.
- Każda strona ma 7-8 **skupisk** po 4-8 węzłów, ułożonych w 3 pierścienie: blisko startu skupiska podstawowe,
  dalej specjalizacje, na końcu węzły kluczowe i gniazda legendarne.
- **Skupisko** to pierścień: wejście od strony startu, dwa łuki węzłów, a węzeł kluczowy to ślepy koniec (trzeba go
  wybrać celowo, nie wpada się w niego po drodze).
- Skupiska łączą ścieżki 1-2 drobnych węzłów (+8 atrybutu, +4% zdrowia / many, +3% szybkości ataku).
  W strefach pośrednich drobne węzły dają po trochu obu atrybutów.
- **Umiejętności wymagają swojej broni** (wariant A). Wyjątki:
  - 3 nowe **umiejętności mieszane** w strefach działają z jedną z dwóch broni: Ciśnięte Noże (miecz albo łuk),
    Strzała Gromu (łuk albo księga), Zaklęte Ostrze (miecz albo księga);
  - **aury** działają z każdą bronią.
- **Premie z węzłów pasywnych działają z każdą bronią.** Premie do konkretnej umiejętności i tak działają tylko
  z nią, więc gracz z łukiem nie ma po co brać węzłów Młynka.

## Liczby

| | Siła | Zręczność | Inteligencja | Strefy (3) | Razem |
|---|---|---|---|---|---|
| umiejętności i aury | 14 | 15 | 16 | 10 | 55 |
| w tym nowe | 5 | 5 | 5 | 8 | 23 |
| węzły kluczowe | 5 | 5 | 5 | 3 | 18 |
| wszystkie węzły (ze ścieżkami) | 65 | 53 | 60 | 50 | **235** (ze startem i pierścieniem) |

Rodzaje: 45 umiejętności, 10 aur, 18 kluczowych, 81 znaczących, 68 drobnych, 9 gniazd, 3 gniazda legendarne.
Dziś są 3 drzewka po ok. 55 węzłów (167). Ile punktów ma gracz w końcówce i jaką część drzewka wybierze,
policzymy w kroku 2 (może trzeba będzie dodać punkty, bo węzłów jest więcej).

## Strony i skupiska (skrót, szczegóły w liście węzłów)

**Siła (miecz):** Wir (Mgnienie, Oko Cyklonu) · Ostrze i combo (Szarża, Półksiężyc, Rozłupanie Ziemi, Taniec Ostrzy) ·
Szermierz (Riposta, **Wilczy Kieł**) · Okrzyki (Zew Peruna, **Ryk Tura**, aura **Postrach**) · Krzepa (aura **Krzepa**,
zdrowie, Krew za Manę) · Bastion (pancerz, **Ostatni Bastion**) · Ziemia (**Skok Niedźwiedzia**) · Dym (Dymne Wybuchy,
Widmowe Ostrza, Dym i Cień).

**Zręczność (łuk):** Grad (Deszcz Strzał, Wachlarz i Szereg - więcej pocisków, Grad) · Tropiciel (Strzała tropiąca,
Szybka salwa, **Strzała Żmija**, Wierny tropiciel - tropiąca jako przywołanie z rezerwacją many, Oko Sokoła) ·
Myśliwy (Grot Swaroga, **Rozszczepiona Strzała**, Strzelanie w biegu) · Wataha (Sokół, Balista, **Wataha**) ·
Pułapki i jad (Sidła, Jadowe Groty, **Kolczatka**) · Cień (Odskok, **Łowca w Cieniu**) · Szał (aura **Wiatr Strzyboga**,
**Szał Bitewny**).

**Inteligencja (księga):** Ogień (Spadająca Gwiazda, **Ściana Ognia**) · Lód (Włócznia Marzanny, Zamieć,
**Lodowy Pancerz**, aura **Mroźny Oddech**) · Piorun (Łańcuch błyskawic, Fala piorunów, Burza Peruna, Kula Piorunów,
aura **Gniew Peruna**) · Runy (Kamień Runiczny, Echo Run) · Mana (Tarcza Many, obrażenia od % many, Pełnia Mocy) ·
Mgła (Krok przez Mgłę, **Błędne Ogniki** - zalążek nekromancji) · Żywioły (Harmonia Żywiołów, **Mistrz Żywiołów**) ·
Wola (mniejsza rezerwacja, **Krwawa Ofiara**).

**Strefa siła / zręczność:** Krwawienie (Rozpłatanie, krwawienie z każdą bronią, Krwawy Szał) · Ciosy i szarże
(**Ciśnięte Noże**, premia po umiejętności ruchu).

**Strefa zręczność / inteligencja:** Burza i pociski (Strzała Wichru, **Strzała Gromu**, porażenie) · Uniki
(Myśliwy z Cienia - teraz po każdej umiejętności ruchu).

**Strefa siła / inteligencja:** Aury (Źródło Życia, Źródło Many, aury żywiołów **Żar Swaroga**, **Szron Marzanny**,
**Iskry Peruna**) · Zaklęte ostrza (**Zaklęte Ostrze**, odporność na ogień, **Żelazna Wola**).

Pogrubione - nowe. Pomysły autora z planu są w drzewku: obrażenia od % zdrowia (Pełnia Sił, Gniew rannego) i od % many
(Pełnia umysłu), więcej pocisków wachlarzem i równolegle, Strzała tropiąca jako przywołanie, mniejsza rezerwacja,
% zdrowia i many, obrażenia w manę (Przelana moc), odporność i obrażenia konkretnych żywiołów.

## Co się dzieje z dzisiejszymi węzłami

- Wszystkie umiejętności zostają. Półksiężyc, Szybka salwa i Fala piorunów stają się zwykłymi umiejętnościami,
  combo daje im tylko premię (krok 4).
- Węzły kluczowe zostają, część zmienia miejsce albo zasięg:
  - Krwawy Szał przechodzi do strefy siła / zręczność (działa z każdą bronią),
  - Myśliwy z Cienia przechodzi do strefy zręczność / inteligencja (po każdej umiejętności ruchu),
  - Ofiara Krwi zmienia się w Krew za Manę po stronie siły (z każdą bronią).
- 6 umiejętności regeneracji zastępują skupiska i 2 aury (patrz wyżej).
- Gniazda: 9 zwykłych (dziś 6) i 3 legendarne (jak dziś), każde legendarne za węzłem kluczowym
  (Oko Cyklonu, Grad, Echo Run).
- Stare zapisy: wszystkie punkty wracają do rozdania (krok 2).

## Do decyzji autora

1. Czy taki układ (rysunek) jest dobry: strony, strefy, pierścień przy starcie?
2. Nowe umiejętności i aury: które zostają, które wymienić (pełne opisy w liście węzłów)?
3. Czy umiejętności mieszane w strefach (z jedną z dwóch broni) wchodzą, czy zostajemy przy samym wariancie A?
4. Czy aury mają działać z każdą bronią?
5. Czy premie z węzłów pasywnych mają działać z każdą bronią (dziś tylko z bronią swojego drzewka)?
6. Liczby w premiach to propozycje. Ustalimy je w kroku 2 symulacją (`tests/endgame_probe.gd`, `tests/balance_sim.gd`).
