"""Arkusze postaci gracza z PixelLab (pixellab_src/heroes/<postać>/) i dane chwytu broni.

Każda postać ma 5 kierunków (south, south-east, east, north-east, north - pozostałe gra
odbija w poziomie) i animacje: idle (obrót postaci), walk, slash (zamach), cast (czar),
shoot (łuk), a u Wojciecha też ruchy miecza chop, sweep, stab, rising_cut i spin - po 4 klatki, a ataki postaci animowanej porządnie (Wojciech) po 8 klatek
(szkieletowe ruchy PixelLab: cięcie, strzał z łuku, czar - broń w prawej ręce).
Arkusz: kolumny = klatki (8), wiersze = animacja * 5 + kierunek.

Chwyt broni: PixelLab przerysował klatki z postacią trzymającą znacznik - pręt z różowym
(#FF00FF) końcem w dłoni i błękitnym (#00FFFF) czubkiem (pliki mk_*.png, w atakach przez
edit_image na klatkach animacji). Z położenia obu kolorów liczymy punkt chwytu i kąt broni dla
każdej klatki - w grze broń z ekwipunku jest wtedy trzymana w dłoni i porusza się razem z ręką
(w cięciu pręt pokazuje tor miecza). Przerysowana klatka bywa przesunięta o kilka pikseli -
przesunięcie znajduje dopasowanie sylwetek (_align).

Pięść: po zmniejszeniu arkusza chwyt przesuwa się ze skraju sylwetki (tam kończy się pręt) w głąb dłoni
(_fist_center), a piksele pięści trafiają do osobnego arkusza assets/heroes/<postać>_fist.png - gra rysuje go
nad bronią, więc rękojeść chowa się w zaciśniętej dłoni (Player._update_fist).

Wynik: assets/heroes/<postać>.png, <postać>_fist.png i scripts/hero_rig.gd (stałe dla gry).
Uruchom: python tools/hero_sheets.py"""
import colorsys
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "pixellab_src", "heroes")
OUT = os.path.join(ROOT, "assets", "heroes")

HEROES = [("wojciech", "Wojciech"), ("bogdan", "Bogdan"), ("mira", "Mira"), ("jaga", "Jaga")]
DIRS = ["south", "south-east", "east", "north-east", "north"]
ANIMS = ["idle", "walk", "slash", "cast", "shoot", "chop", "sweep", "stab", "rising_cut", "spin",
         "bow_power", "bow_sky", "bow_hop", "cast_push", "cast_self", "cast_down", "cast_up", "dash", "death"]
## Ruchy miecza z etapu 2: tu znacznik czytamy po całym pręcie (_rod_ends), bo bywa w ciemniejszym błękicie.
## Obrót (spin) nie ma znaczników: w Młynku miecz krąży wokół postaci w kodzie (Player).
SWORD_MOVES = ("chop", "sweep", "stab", "rising_cut", "spin")
## Ruchy łuku i księgi z etapu 3. Znaczniki (mk_<ruch>_<kierunek>_<i>.png) to ten sam ruch szkieletowy puszczony
## na stanie postaci „Znacznik” w PixelLab (Wojciech z prętem w prawej dłoni) - pręt pokazuje dłoń w każdej klatce.
## Łuk w grze celuje w cel, a księga stoi grzbietem w górę, więc liczy się tylko położenie dłoni.
STAGE3_MOVES = ("bow_power", "bow_sky", "bow_hop", "cast_push", "cast_self", "cast_down", "cast_up")
## Etap 4 (tylko postać grywalna, FIST_HEROES): spoczynek z oddechem i chód po 8 klatek oraz zryw (dash) - chwyt
## z tych samych znaczników co w etapie 3 (mk_<ruch>_<kierunek>_<i>.png). Gdy widać tylko różowy koniec pręta, kąt
## broni bierzemy z sąsiedniej klatki (albo ze starego znacznika spoczynku mk_idle_<kierunek>.png). Upadek przy
## śmierci (death) nie ma chwytu - martwa postać nie trzyma broni.
STAGE4_MOVES = ("idle", "walk", "dash")


def _marker_state(hero, anim):
    """Czy chwyt tego ruchu pochodzi ze znaczników stanu „Znacznik” (etapy 3 i 4)."""
    return anim in STAGE3_MOVES or (anim in STAGE4_MOVES and hero in FIST_HEROES)
FRAMES = 8  # kolumny arkusza; chód i spoczynek mają 4 klatki, ataki do 8
CELL = 72
FEET_Y = 62  # stopy w komórce (od góry), przed zmniejszeniem
## Postać z PixelLab jest za duża przy reszcie świata - zmniejszamy ją do ok. 30 px wzrostu
## (trochę więcej niż dawna, 24-pikselowa postać). Wynikowa komórka i stopy:
SCALE = 0.75
## Znaczniki, którym nie da się ufać: Mira trzyma znacznik za plecami i w chodzie bokiem przekłada go przez ciało.
## STEADY_WALK - w chodzie broń zostaje w dłoni z pozy spoczynku (kołysze się z sylwetką); IDLE_GRIP_FROM - spoczynek
## w danym kierunku bierze chwyt z innego kierunku.
STEADY_WALK = {"mira": ("east", "south-east")}
IDLE_GRIP_FROM = {"mira": {"south-east": "east"}}
## Poprawki klatek, w które PixelLab wtopił przedmiot (łuk) mimo pustych dłoni: "erase" - kolory
## (hex) do wymazania w prostokącie [x0, y0, x1, y1] płótna klatki, "copy" - klatka zastąpiona inną klatką
## tej samej animacji i kierunku.
GREY_BOW = ["7a8084", "625d55", "5e6475"]
FRAME_FIX = {
    "wojciech": {
        ("shoot", "south", 1): {"erase": [50, 30, 60, 41], "colors": GREY_BOW},
        ("shoot", "south", 4): {"erase": [50, 30, 60, 41], "colors": GREY_BOW},
        ("shoot", "south", 5): {"copy": 4},
        ("shoot", "south", 6): {"copy": 4},
        ("shoot", "east", 4): {"copy": 3},
        # upadek: ostatnia klatka leży inaczej niż poprzednia - postać zostaje w pozie z przedostatniej
        ("death", "north-east", 7): {"copy": 6}, ("death", "north", 7): {"copy": 6},
    },
}
## Ręczny kąt broni (stopnie) w klatkach ruchów miecza, w których pręt ze znacznika przecina ciało.
ANGLE_FIX = {
    "wojciech": {
        ("stab", "south", 4): 100, ("stab", "south", 5): 100, ("stab", "south", 7): 110,
        ("sweep", "north", 1): -35, ("sweep", "south-east", 4): -15,
    },
}
## Najdalej (w pikselach), o ile chwyt ataku może zostać przyciągnięty do sylwetki (_snap).
SNAP_MAX = 7
## Jak daleko (w pikselach) szukać dłoni na przedłużeniu pręta w ruchach miecza (_to_fist).
ROD_REACH = 22
## Pręt różni się od czystej klatki o więcej niż tyle (odległość kolorów RGB); ile pikseli za końcem pręta leży
## środek pięści (_rod_contact).
ROD_DIFF = 70
ROD_INTO_FIST = 1.5
## Pięść w zmniejszonym arkuszu: o ile (piksele) cofnąć chwyt od miejsca, gdzie pręt dotyka sylwetki, w głąb dłoni,
## promień, z którego liczymy środek pięści, i promień pikseli kopiowanych do arkusza pięści. Pięść nie sięga
## dalej niż FIST_FRONT pikseli w stronę ostrza (jelec i ostrze zostają widoczne).
## Tylko postać grywalna (Wojciech) dostaje arkusz pięści i poprawiony chwyt.
FIST_HEROES = ("wojciech",)
FIST_INSET = 0.5
FIST_FIND_RADIUS = 1.6
FIST_RADIUS = 1.9
FIST_FRONT = 0.6
## Dłonie Wojciecha mają kolor skóry (strój, włosy i buty nie), więc środek pięści przyciągamy do plamy skóry:
## w spoczynku i chodzie - do dłoni poniżej głowy (klatki ze znacznikiem bywają tam w innej pozie niż czyste klatki),
## w atakach - do plamy skóry najdalej SKIN_SNAP pikseli od chwytu ze znacznika. Dłoń z mieczem (prawa) w spoczynku
## i chodzie: SKIN_SIDE - -1 ta bardziej z lewej na ekranie, 1 - z prawej, 0 - bliższa chwytowi ze znacznika.
SKIN_SNAP = 3.5
## W atakach tylko w widokach od przodu (od tyłu skóra na karku udaje dłoń).
SKIN_ATTACK_DIRS = ("south", "south-east", "east")
## Ręczne poprawki środka pięści w zmniejszonej komórce ([x, y] od stóp, jak w HeroRig) dla klatek, w których
## ani znacznik, ani kolor skóry nie trafiają w dłoń (sprawdzone na powiększonych klatkach).
FIST_FIX = {
    "wojciech": {
        ("sweep", "south", 3): [-5.5, -15.0],
        ("bow_hop", "east", 3): [4.0, -16.0], ("bow_hop", "north-east", 3): [6.0, -18.0],
    },
}
## Większa plama skóry to twarz, nie dłoń.
HAND_MAX_PIXELS = 9
SKIN_SIDE = {"south": -1, "south-east": -1, "east": 0, "north-east": 1, "north": 1}
## Pas wysokości (piksele nad stopami w zmniejszonej komórce), w którym szukamy dłoni w spoczynku i chodzie.
HAND_ROWS = (3, 17)
## Pojedynczy kąt ataku, który odskakuje od obu sąsiednich klatek o więcej niż tyle stopni (a sąsiednie są
## zgodne), zastępujemy średnią sąsiadów - pręt ze znacznika bywa w jednej klatce przekręcony.
ANGLE_JUMP = 100
## Broń za postacią: w kierunkach "od kamery" zawsze, a w pozostałych, gdy ostrze celuje w górę i przechodzi przez
## głowę (zamach nad głową) - przez co najmniej HEAD_HITS próbek wzdłuż ostrza. Głowa to górne HEAD_ROWS wierszy
## sylwetki. Chwyt dostaje wtedy czwartą liczbę: 1 - za postacią, 0 - przed nią.
BEHIND_DIRS = ("north-east", "north")
HEAD_ROWS = 11
HEAD_HITS = 2
## Długość broni w dłoni w zmniejszonym arkuszu (piksele) - do sprawdzania, przez co przechodzi ostrze.
BLADE_LENGTH = 20
OUT_CELL = round(CELL * SCALE)
OUT_FEET_Y = round(FEET_Y * SCALE)


def _open(path):
    return Image.open(path).convert("RGBA")


def _bottom(img):
    return img.getbbox()[3]


def _frames(hero, anim, direction):
    folder = os.path.join(SRC, hero)
    if anim == "idle" and not os.path.exists(os.path.join(folder, "idle_%s_0.png" % direction)):
        path = os.path.join(folder, "rot_%s.png" % direction)
        return [path] * 4 if os.path.exists(path) else []
    paths = []
    while len(paths) < FRAMES and os.path.exists(os.path.join(folder, "%s_%s_%d.png" % (anim, direction, len(paths)))):
        paths.append(os.path.join(folder, "%s_%s_%d.png" % (anim, direction, len(paths))))
    return paths if len(paths) >= 4 else []


def _clean(hero, anim, direction, f, img):
    """Wymazuje kolory wtopionego przedmiotu (FRAME_FIX - "erase") z klatki."""
    fix = FRAME_FIX.get(hero, {}).get((anim, direction, f), {})
    if "erase" not in fix:
        return img
    x0, y0, x1, y1 = fix["erase"]
    colors = {tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) for c in fix["colors"]}
    px = img.load()
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[x, y][3] and px[x, y][:3] in colors:
                px[x, y] = (0, 0, 0, 0)
    return img


def _drop_specks(img):
    """Usuwa z klatki ruchu miecza małe, oderwane od postaci plamki (do 12 pikseli), które dorysował PixelLab."""
    px = img.load()
    body = set(_largest_group(_opaque(img)))
    left = _opaque(img) - body
    while left:
        stack = [left.pop()]
        group = list(stack)
        while stack:
            x, y = stack.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in left:
                        left.remove(n)
                        group.append(n)
                        stack.append(n)
        if len(group) <= 12:
            for p in group:
                px[p] = (0, 0, 0, 0)
    return img


def _paste(sheet, img, x, y):
    """Wkleja klatkę także przy ujemnym położeniu (płótno ataku jest większe od komórki)."""
    left, top = max(0, -x), max(0, -y)
    sheet.alpha_composite(img.crop((left, top, img.width, img.height)), (x + left, y + top))


def _opaque(img, skip_marker=False):
    px = img.load()
    out = set()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128 or (skip_marker and _is_rod(r, g, b)):
                continue
            out.add((x, y))
    return out


def _align(mk, img, rod):
    """Przesunięcie (dx, dy) przerysowanej klatki ze znacznikiem względem czystej - to, przy którym
    sylwetki pokrywają się najlepiej (bez pikseli pręta: rod = (x, y) chwytu i czubka). Bez przesunięcia,
    gdy (0, 0) pasuje równie dobrze."""
    ox = (mk.width - img.width) // 2
    oy = (mk.height - img.height) // 2
    mx, my, cx, cy = rod
    length = max(1e-6, math.hypot(cx - mx, cy - my))

    def near_rod(x, y):
        t = max(0.0, min(1.0, ((x - mx) * (cx - mx) + (y - my) * (cy - my)) / length ** 2))
        return math.hypot(x - (mx + t * (cx - mx)), y - (my + t * (cy - my))) < 2.5

    a = {p for p in _opaque(mk, True) if not near_rod(*p)}
    b = _opaque(img)

    def score(dx, dy):
        moved = {(x + dx - ox, y + dy - oy) for x, y in a}
        return len(moved & b) / max(1, len(moved | b))

    base = score(0, 0)
    best = max(((score(dx, dy), dx, dy) for dx in range(-16, 17) for dy in range(-16, 17)))
    return (0, 0) if best[0] <= base + 0.02 else (best[1], best[2])


def _snap(img, hand):
    """Chwyt w ataku przyciągnięty do sylwetki czystej klatki: przerysowana klatka bywa trochę inna,
    więc pręt potrafi wisieć kilka pikseli obok dłoni. Dalej niż SNAP_MAX - znacznik nie do użycia (None)."""
    hx, hy = hand
    best = None
    for x, y in _opaque(img):
        d = (x - hx) ** 2 + (y - hy) ** 2
        if best is None or d < best[0]:
            best = (d, x, y)
    if best is None or best[0] > SNAP_MAX ** 2:
        return None
    return hand if best[0] <= 1 else (best[1], best[2])


def _hsv(r, g, b):
    h, sat, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    return h * 360.0, sat, v


def _is_magenta(r, g, b):
    h, sat, v = _hsv(r, g, b)
    return 280.0 <= h <= 335.0 and sat > 0.3 and v > 0.35


def _is_cyan(r, g, b):
    # błękitny czubek bywa bardzo blady - wystarczy wyraźnie błękitny odcień
    h, sat, v = _hsv(r, g, b)
    return 170.0 <= h <= 196.0 and sat > 0.15 and v > 0.72


def _is_rod(r, g, b):
    return min(r, g, b) > 165 or _is_magenta(r, g, b) or _is_cyan(r, g, b)


def _largest_group(points):
    """Największa zwarta grupa pikseli (odrzuca pojedyncze błyski w kolorze znacznika na stroju)."""
    left = set(points)
    best = []
    while left:
        start = left.pop()
        group, stack = [start], [start]
        while stack:
            x, y = stack.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in left:
                        left.remove(n)
                        group.append(n)
                        stack.append(n)
        if len(group) > len(best):
            best = group
    return best


def _marker(img):
    """(x, y chwytu, x, y czubka) znacznika albo None. Czubek to środek błękitnych pikseli;
    chwyt - środek różowych, a gdy różowy koniec schował się w pięści, najdalszy od czubka
    punkt pręta (idziemy od czubka po jasnych pikselach pręta)."""
    px = img.load()
    mag, cyan = [], []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            if _is_magenta(r, g, b):
                mag.append((x, y))
            elif _is_cyan(r, g, b):
                cyan.append((x, y))
    cyan = _largest_group(cyan)
    mag = _largest_group(mag)
    if len(cyan) < 2:
        return None
    cx = sum(p[0] for p in cyan) / len(cyan)
    cy = sum(p[1] for p in cyan) / len(cyan)
    if len(mag) >= 2:
        return sum(p[0] for p in mag) / len(mag), sum(p[1] for p in mag) / len(mag), cx, cy
    seen = set(cyan)
    stack = list(cyan)
    while stack:
        x, y = stack.pop()
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                n = (x + dx, y + dy)
                if n in seen or not (0 <= n[0] < img.width and 0 <= n[1] < img.height):
                    continue
                r, g, b, a = px[n]
                if a >= 128 and _is_rod(r, g, b):
                    seen.add(n)
                    stack.append(n)
    far = max(seen, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
    if (far[0] - cx) ** 2 + (far[1] - cy) ** 2 < 16:
        return None
    return far[0], far[1], cx, cy


def _rod_ends(img, sword=True):
    """(x, y chwytu, x, y czubka) z pręta w ruchach miecza (sword) i etapu 3 (bez sword: szerszy odcień błękitu
    i sam różowy koniec wystarczy). Czubek to najdalszy od chwytu punkt błękitnej części
    (także ciemnego błękitu). Chwyt to środek różowej części, a bez niej - koniec błękitu bliższy środka
    sylwetki. None, gdy pręta nie ma."""
    px = img.load()
    cyan, mag, body = [], [], []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            h, sat, v = _hsv(r, g, b)
            if _is_magenta(r, g, b):
                mag.append((x, y))
            elif (170.0 if sword else 155.0) <= h <= 200.0 and sat > 0.4 and v > 0.3:
                cyan.append((x, y))
            else:
                body.append((x, y))
    cyan = _largest_group(cyan)
    mag = _largest_group(mag)
    if not sword and len(mag) >= 2 and len(cyan) < 2:
        # ruchy łuku i księgi: kąt nie jest potrzebny, wystarczy różowy koniec w pięści (pręt bywa schowany)
        hx = sum(p[0] for p in mag) / len(mag)
        hy = sum(p[1] for p in mag) / len(mag)
        return hx, hy, hx + 4.0, hy
    if len(cyan) < 2 or not body:
        return None
    if len(mag) >= 2:
        hx = sum(p[0] for p in mag) / len(mag)
        hy = sum(p[1] for p in mag) / len(mag)
    else:
        bx = sum(p[0] for p in body) / len(body)
        by = sum(p[1] for p in body) / len(body)
        hx, hy = min(cyan, key=lambda p: (p[0] - bx) ** 2 + (p[1] - by) ** 2)
    tip = max(cyan, key=lambda p: (p[0] - hx) ** 2 + (p[1] - hy) ** 2)
    if (tip[0] - hx) ** 2 + (tip[1] - hy) ** 2 < 16:
        return None
    return hx, hy, tip[0], tip[1]


def _to_fist(img, rod):
    """Chwyt ruchu miecza, gdy koniec pręta wisi przed dłonią: cofamy się po linii pręta (od czubka przez
    chwyt) do pierwszego piksela sylwetki, najdalej ROD_REACH pikseli. None, gdy linia nie trafia w postać."""
    mx, my, cx, cy = rod
    length = max(1e-6, math.hypot(cx - mx, cy - my))
    ux, uy = (mx - cx) / length, (my - cy) / length
    px = img.load()
    for step in range(ROD_REACH + 1):
        x, y = round(mx + ux * step), round(my + uy * step)
        if 0 <= x < img.width and 0 <= y < img.height and px[x, y][3] >= 128:
            return x, y
    return None


def _rod_contact(mk, img, rod, shift):
    """Miejsce, w którym pręt znika w pięści (współrzędne czystej klatki), dla cięć mieczem. PixelLab rysuje między
    pięścią a różowym końcem jeszcze ciemny odcinek pręta, więc idziemy od różowego końca dalej wzdłuż pręta
    (od czubka w stronę dłoni), dopóki klatka ze znacznikiem różni się od czystej (to piksele pręta). Potem jeszcze
    ROD_INTO_FIST pikseli w głąb dłoni. None, gdy nie da się tego ustalić."""
    mx, my, cx, cy = rod
    sx, sy = shift
    length = math.hypot(mx - cx, my - cy)
    if length < 1e-6:
        return None
    ux, uy = (mx - cx) / length, (my - cy) / length
    mpx, ipx = mk.load(), img.load()

    def rodish(x, y):
        X, Y = int(round(x)), int(round(y))
        if not (0 <= X < mk.width and 0 <= Y < mk.height) or mpx[X, Y][3] < 128:
            return False
        ix, iy = X + sx, Y + sy
        if not (0 <= ix < img.width and 0 <= iy < img.height) or ipx[ix, iy][3] < 128:
            return True
        a, b = mpx[X, Y], ipx[ix, iy]
        return sum((a[i] - b[i]) ** 2 for i in range(3)) > ROD_DIFF ** 2

    last, step = 0.0, 0.0
    while step <= ROD_REACH:
        if rodish(mx + ux * step, my + uy * step):
            last = step
        elif step - last > 1.5:
            break
        step += 0.5
    depth = last + ROD_INTO_FIST
    hand = (mx + ux * depth + sx, my + uy * depth + sy)
    return _snap(img, hand)


def build(hero):
    folder = os.path.join(SRC, hero)
    sheet = Image.new("RGBA", (CELL * FRAMES, CELL * len(ANIMS) * len(DIRS)))
    grips = {}
    counts = {}  # liczba klatek animacji (najwięcej spośród kierunków)
    tops = {}  # (animacja, kierunek, klatka) -> czubek głowy względem stóp (kołysanie przy chodzie)
    for a, anim in enumerate(ANIMS):
        grips[anim] = []
        for d, direction in enumerate(DIRS):
            rot = _open(os.path.join(folder, "rot_%s.png" % direction))
            dir_grips = []
            paths = _frames(hero, anim, direction)
            counts[anim] = max(counts.get(anim, 0), len(paths))
            marked = _marker_state(hero, anim)
            if marked and anim in ("idle", "walk") and _rod_count(folder, anim, direction, len(paths)) < MIN_RODS:
                marked = False  # pręt prawie cały czas za plecami - chwyt ze starego znacznika spoczynku
            for f, path in enumerate(paths):
                # klatka z wtopionym przedmiotem zastąpiona inną klatką tej animacji (razem ze znacznikiem)
                src_f = FRAME_FIX.get(hero, {}).get((anim, direction, f), {}).get("copy", f)
                img = _clean(hero, anim, direction, src_f, _open(paths[src_f]))
                if anim in SWORD_MOVES or _marker_state(hero, anim):
                    img = _drop_specks(img)
                # płótna PixelLab są wyśrodkowane na postaci: stopy z obrotu, przesunięte o różnicę płócien
                feet = _bottom(rot) + (img.height - rot.height) / 2.0
                x0 = CELL / 2.0 - img.width / 2.0
                y0 = FEET_Y - feet
                _paste(sheet, img, int(f * CELL + x0), int((a * len(DIRS) + d) * CELL + y0))
                tops[(anim, d, f)] = img.getbbox()[1] + y0 - FEET_Y
                # znacznik chwytu (tylko spoczynek i chód)
                # stary znacznik spoczynku: spoczynek bez nowych znaczników i chód Wojciecha z prętem za plecami
                old_idle = not marked and (anim == "idle" or (anim == "walk" and _marker_state(hero, anim)))
                mk_name = "mk_idle_%s.png" % direction if old_idle else "mk_%s_%s_%d.png" % (anim, direction, src_f)
                mk_path = os.path.join(folder, mk_name)
                grip = None
                if os.path.exists(mk_path):
                    mk = _open(mk_path)
                    found = _rod_ends(mk, anim in SWORD_MOVES) if anim in SWORD_MOVES or marked else _marker(mk)
                    if found:
                        found_raw = found
                        mx, my, cx, cy = found
                        # przesunięcie tylko w atakach (znaczniki chodu i spoczynku są na miejscu)
                        dx, dy = (0, 0) if anim in ("idle", "walk") and not marked else _align(mk, img, found)
                        mx, my, cx, cy = mx + dx, my + dy, cx + dx, cy + dy
                        # znacznik może mieć inne płótno niż czysta klatka - też wyśrodkowane
                        ox = (mk.width - img.width) / 2.0
                        oy = (mk.height - img.height) / 2.0
                        angle = math.atan2(cy - my, cx - mx)
                        if marked and anim in STAGE4_MOVES and _tipless(found):
                            angle = None  # sam różowy koniec: kąt z sąsiednich klatek
                        fixed = ANGLE_FIX.get(hero, {}).get((anim, direction, f))
                        if fixed is not None:
                            angle = math.radians(fixed)
                        hand = (mx - ox, my - oy)
                        if anim in SWORD_MOVES or anim == "slash":
                            contact = _rod_contact(mk, img, found_raw, (int(dx - ox), int(dy - oy)))
                        else:
                            contact = None
                        if contact is not None:
                            hand = contact
                        elif anim not in ("idle", "walk") or marked:
                            snapped = _snap(img, hand)
                            if snapped is None and anim in SWORD_MOVES:
                                snapped = _to_fist(img, (hand[0], hand[1], cx - ox, cy - oy))
                            hand = snapped
                        if hand is None:
                            dir_grips.append(None)
                            continue
                        gx = hand[0] + x0 - CELL / 2.0
                        gy = hand[1] + y0 - FEET_Y
                        # bokiem broń ma celować przed postać - PixelLab bywa, że rysuje znacznik
                        # trzymany za plecami (Mira); odbijamy wtedy kąt i dłoń w poziomie względem
                        # środka sylwetki, żeby rękojeść była w przedniej dłoni
                        if anim in ("idle", "walk") and not marked and direction in ("east", "south-east") and math.cos(angle) < 0:
                            angle = math.atan2(math.sin(angle), -math.cos(angle))
                            box = img.getbbox()
                            body_x = (box[0] + box[2]) / 2.0 + x0 - CELL / 2.0
                            gx = 2.0 * body_x - gx
                        grip = [round(gx * SCALE, 1), round(gy * SCALE, 1), None if angle is None else round(angle, 3)]
                dir_grips.append(grip)
            # brakujące klatki biorą chwyt z poprzedniej (albo z najbliższej znalezionej)
            known = [g for g in dir_grips if g]
            if marked and dir_grips:
                if anim in STAGE4_MOVES:
                    _fill_angles(dir_grips, _rest_angle(folder, direction))
                rest = grips["idle"][d][0] if anim != "idle" and grips["idle"][d] else None
                _fill_between(dir_grips, rest)
            for i, g in enumerate(dir_grips):
                if g is None and known:
                    dir_grips[i] = dir_grips[i - 1] if i > 0 and dir_grips[i - 1] else known[0]
            # pojedyncza klatka z bronią obróconą w drugą stronę (np. Bogdan idący na północ) - kąt jak w pozostałych
            if len(known) >= 3 and anim in ("idle", "walk") and not marked:
                for i, g in enumerate(dir_grips):
                    others = [o[2] for j, o in enumerate(dir_grips) if j != i]
                    near = [a for a in others if abs(math.remainder(a - g[2], math.tau)) < math.pi / 3]
                    if not near:
                        dir_grips[i] = [g[0], g[1], sorted(others)[len(others) // 2]]
            grips[anim].append(dir_grips if known else [])
    # spoczynek bez znacznika bierze chwyt z pierwszej klatki chodu (i odwrotnie)
    for d in range(len(DIRS)):
        if not grips["idle"][d] and grips["walk"][d]:
            grips["idle"][d] = [grips["walk"][d][0]] * 4
        elif not grips["walk"][d] and grips["idle"][d]:
            grips["walk"][d] = list(grips["idle"][d])
    # kierunek ataku bez żadnego znacznika (np. strzał na północ - dłoń schowana) - chwyt spoczynku
    for anim in ("slash", "cast", "shoot"):
        for d in range(len(DIRS)):
            if not grips[anim][d] and grips["idle"][d] and counts.get(anim, 0) > 4:
                grips[anim][d] = [grips["idle"][d][0]] * counts[anim]
    for d, direction in enumerate(DIRS):
        source = IDLE_GRIP_FROM.get(hero, {}).get(direction)
        if source:
            grips["idle"][d] = list(grips["idle"][DIRS.index(source)])
        if direction in STEADY_WALK.get(hero, ()) and grips["idle"][d]:
            # chwyt spoczynku, który unosi się i opada razem z sylwetką
            hold = grips["idle"][d][0]
            grips["walk"][d] = [[hold[0], round(hold[1] + (tops[("walk", d, f)] - tops[("idle", d, 0)]) * SCALE, 1), hold[2]]
                                for f in range(counts["walk"])]
    os.makedirs(OUT, exist_ok=True)
    small = _shrink(sheet)
    small.save(os.path.join(OUT, hero + ".png"))
    if hero in FIST_HEROES:
        _smooth_angles(grips)
        _fist_sheet(small, grips, hero).save(os.path.join(OUT, hero + "_fist.png"))
    return grips, counts


## Spoczynek i chód z mniej niż tyloma klatkami z prętem biorą chwyt ze starego znacznika spoczynku (mk_idle_<kierunek>.png).
MIN_RODS = 3


def _rod_count(folder, anim, direction, count):
    """W ilu klatkach znacznika ruchu widać pręt."""
    found = 0
    for i in range(count):
        path = os.path.join(folder, "mk_%s_%s_%d.png" % (anim, direction, i))
        if os.path.exists(path) and _rod_ends(_open(path), False):
            found += 1
    return found


def _tipless(found):
    """Czy _rod_ends znalazł tylko różowy koniec pręta (czubek wstawiony umownie 4 piksele w prawo)."""
    return abs(found[2] - found[0] - 4.0) < 1e-6 and found[3] == found[1]


def _rest_angle(folder, direction):
    """Kąt broni ze starego znacznika spoczynku (jedna klatka) albo 90 stopni (w dół), gdy go nie ma."""
    path = os.path.join(folder, "mk_idle_%s.png" % direction)
    found = _marker(_open(path)) if os.path.exists(path) else None
    return round(math.atan2(found[3] - found[1], found[2] - found[0]), 3) if found else round(math.pi / 2, 3)


def _fill_angles(dir_grips, fallback):
    """Klatki z chwytem bez kąta (None) biorą kąt z najbliższej klatki z kątem (albo fallback)."""
    known = [i for i, g in enumerate(dir_grips) if g and g[2] is not None]
    for i, g in enumerate(dir_grips):
        if g and g[2] is None:
            g[2] = dir_grips[min(known, key=lambda k: abs(k - i))][2] if known else fallback


def _fill_between(dir_grips, rest):
    """Klatki bez znacznika między dwiema klatkami ze znacznikiem: chwyt w pół drogi (liniowo). Ruch zaczyna się
    i kończy w spoczynku, więc pierwsza i ostatnia klatka bez znacznika dostają chwyt spoczynku (rest)."""
    if rest:
        for i in (0, len(dir_grips) - 1):
            if dir_grips[i] is None:
                dir_grips[i] = list(rest[:3])
    found = [i for i, g in enumerate(dir_grips) if g]
    for a, b in zip(found, found[1:]):
        for i in range(a + 1, b):
            t = (i - a) / float(b - a)
            ga, gb = dir_grips[a], dir_grips[b]
            dir_grips[i] = [round(ga[0] + (gb[0] - ga[0]) * t, 1), round(ga[1] + (gb[1] - ga[1]) * t, 1), ga[2]]


def _smooth_angles(grips):
    """Poprawia w atakach pojedyncze kąty broni, które odskakują od obu sąsiednich klatek (ANGLE_JUMP)."""
    limit = math.radians(ANGLE_JUMP)
    for anim, per_dir in grips.items():
        if anim in ("idle", "walk"):
            continue
        for dir_grips in per_dir:
            for i in range(1, len(dir_grips) - 1):
                prev, cur, nxt = dir_grips[i - 1], dir_grips[i], dir_grips[i + 1]
                if not (prev and cur and nxt):
                    continue
                gap = math.remainder(nxt[2] - prev[2], math.tau)
                if abs(gap) > math.radians(45):
                    continue
                if abs(math.remainder(cur[2] - prev[2], math.tau)) > limit and abs(math.remainder(cur[2] - nxt[2], math.tau)) > limit:
                    dir_grips[i] = [cur[0], cur[1], round(math.remainder(prev[2] + gap / 2.0, math.tau), 3)]


def _fist_center(px, cx, cy, angle):
    """Środek pięści w komórce zmniejszonego arkusza: od punktu (cx, cy), w którym pręt dotyka sylwetki, cofamy się
    o FIST_INSET w stronę przeciwną do ostrza i bierzemy środek nieprzezroczystych pikseli w promieniu
    FIST_FIND_RADIUS. None, gdy w pobliżu nie ma sylwetki."""
    ux, uy = math.cos(angle), math.sin(angle)
    x, y = cx - ux * FIST_INSET, cy - uy * FIST_INSET
    near = []
    reach = int(math.ceil(FIST_FIND_RADIUS)) + 1
    for qy in range(int(y) - reach, int(y) + reach + 1):
        for qx in range(int(x) - reach, int(x) + reach + 1):
            if 0 <= qx < OUT_CELL and 0 <= qy < OUT_CELL and px[qx, qy][3] >= 128 \
                    and math.hypot(qx + 0.5 - x, qy + 0.5 - y) <= FIST_FIND_RADIUS:
                near.append((qx + 0.5, qy + 0.5))
    if len(near) < 2:
        return None
    return sum(p[0] for p in near) / len(near), sum(p[1] for p in near) / len(near)


def _over_head(px, fx, fy, ux, uy):
    """Czy ostrze z pięści (fx, fy) w kierunku (ux, uy) celuje w górę i przechodzi przez głowę (HEAD_ROWS, HEAD_HITS)
    albo pięść jest na wysokości głowy."""
    if uy > -0.2:
        return False
    top = next((y for y in range(OUT_CELL) if any(px[x, y][3] >= 128 for x in range(OUT_CELL))), OUT_CELL)
    if fy < top + HEAD_ROWS:
        return True  # pięść na wysokości głowy i ostrze w górę: zamach zza głowy
    hits = 0
    for step in range(3, BLADE_LENGTH):
        x, y = int(fx + ux * step), int(fy + uy * step)
        if 0 <= x < OUT_CELL and top <= y < top + HEAD_ROWS and px[x, y][3] >= 128:
            hits += 1
    return hits >= HEAD_HITS


def _is_skin(r, g, b):
    return r >= 190 and 0.48 <= g / r <= 0.85 and b / r >= 0.38


def _skin_groups(px):
    """Zwarte plamy skóry w komórce: lista (środek x, środek y, liczba pikseli)."""
    left = {(x, y) for y in range(OUT_CELL) for x in range(OUT_CELL) if px[x, y][3] >= 128 and _is_skin(*px[x, y][:3])}
    groups = []
    while left:
        stack = [left.pop()]
        group = list(stack)
        while stack:
            x, y = stack.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in left:
                        left.remove(n)
                        group.append(n)
                        stack.append(n)
        groups.append((sum(p[0] for p in group) / len(group) + 0.5, sum(p[1] for p in group) / len(group) + 0.5, len(group)))
    return groups


def _skin_hand(px, anim, direction, guess):
    """Środek dłoni z mieczem z plamy skóry (SKIN_*, HAND_ROWS) albo None. guess - chwyt ze znacznika."""
    groups = [g for g in _skin_groups(px) if g[2] <= HAND_MAX_PIXELS]
    gx, gy = guess
    if anim in ("idle", "walk"):
        low, high = OUT_FEET_Y - HAND_ROWS[1], OUT_FEET_Y - HAND_ROWS[0]
        hands = [g for g in groups if low <= g[1] <= high]
        if not hands:
            return None
        side = SKIN_SIDE.get(direction, 0)
        if side:
            # tylko dłoń po właściwej stronie sylwetki (druga to dłoń bez miecza; schowana - zostaje znacznik)
            hands = [g for g in hands if (g[0] - OUT_CELL / 2.0) * side > 0]
            if not hands:
                return None
            best = min(hands, key=lambda g: g[0] * side * -1)
        else:
            best = min(hands, key=lambda g: (g[0] - gx) ** 2 + (g[1] - gy) ** 2)
        return best[0], best[1]
    if direction not in SKIN_ATTACK_DIRS:
        return None
    near = [g for g in groups if math.hypot(g[0] - gx, g[1] - gy) <= SKIN_SNAP]
    if not near:
        return None
    best = min(near, key=lambda g: math.hypot(g[0] - gx, g[1] - gy))
    return best[0], best[1]


## Jak daleko (piksele zmniejszonej komórki) szukać sylwetki dla chwytu, który wisi obok postaci (ruchy etapu 3).
NEAR_REACH = 5.0


def _nearest_opaque(px, x, y, reach):
    """Środek najbliższego nieprzezroczystego piksela komórki w promieniu reach albo None."""
    best = None
    r = int(math.ceil(reach))
    for qy in range(int(y) - r, int(y) + r + 1):
        for qx in range(int(x) - r, int(x) + r + 1):
            if 0 <= qx < OUT_CELL and 0 <= qy < OUT_CELL and px[qx, qy][3] >= 128:
                dist = math.hypot(qx + 0.5 - x, qy + 0.5 - y)
                if dist <= reach and (best is None or dist < best[0]):
                    best = (dist, qx + 0.5, qy + 0.5)
    return (best[1], best[2]) if best else None


def _fist_sheet(small, grips, hero="wojciech"):
    """Arkusz pięści (taki sam układ jak arkusz postaci): w każdej klatce z chwytem piksele dłoni wokół środka pięści.
    Przy okazji przesuwa chwyt (grips, w miejscu) do środka pięści - tam gra kładzie rękojeść broni."""
    fist = Image.new("RGBA", small.size)
    out = fist.load()
    for a, anim in enumerate(ANIMS):
        if anim == "spin":
            continue
        for d, dir_grips in enumerate(grips.get(anim, [])):
            for f, grip in enumerate(dir_grips):
                if not grip:
                    continue
                ox, oy = f * OUT_CELL, (a * len(DIRS) + d) * OUT_CELL
                cell = small.crop((ox, oy, ox + OUT_CELL, oy + OUT_CELL))
                px = cell.load()
                cx, cy = OUT_CELL / 2.0 + grip[0], OUT_FEET_Y + grip[1]
                fix = FIST_FIX.get(hero, {}).get((anim, DIRS[d], f))
                if fix:
                    center = (OUT_CELL / 2.0 + fix[0], OUT_FEET_Y + fix[1])
                else:
                    center = _skin_hand(px, anim, DIRS[d], (cx, cy)) or _fist_center(px, cx, cy, grip[2])
                    if center is None and _marker_state(hero, anim):
                        # chwyt wyliczony w pół drogi między znacznikami bywa obok ręki: najbliższy piksel sylwetki
                        near = _nearest_opaque(px, cx, cy, NEAR_REACH)
                        if near:
                            center = _fist_center(px, near[0], near[1], grip[2]) or near
                if center is None:
                    continue
                fx, fy = center
                dir_grips[f] = [round(fx - OUT_CELL / 2.0, 1), round(fy - OUT_FEET_Y, 1), grip[2]]
                ux, uy = math.cos(grip[2]), math.sin(grip[2])
                dir_grips[f].append(1 if DIRS[d] in BEHIND_DIRS or _over_head(px, fx, fy, ux, uy) else 0)
                for qy in range(OUT_CELL):
                    for qx in range(OUT_CELL):
                        dx, dy = qx + 0.5 - fx, qy + 0.5 - fy
                        if px[qx, qy][3] >= 128 and math.hypot(dx, dy) <= FIST_RADIUS and dx * ux + dy * uy <= FIST_FRONT:
                            out[ox + qx, oy + qy] = px[qx, qy]
    return fist


def _shrink(sheet):
    """Zmniejsza arkusz komórka po komórce tak, żeby został pixel artem: skalowanie z mieszaniem
    na kanale alfa (bez ciemnych obwódek), twardy próg przezroczystości i powrót do oryginalnej
    palety kolorów komórki - piksele zostają ostre, bez rozmytych półtonów."""
    cols, rows = sheet.width // CELL, sheet.height // CELL
    out = Image.new("RGBA", (OUT_CELL * cols, OUT_CELL * rows))
    for r in range(rows):
        for c in range(cols):
            cell = sheet.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
            if cell.getbbox() is None:
                continue
            small = shrink_image(cell, OUT_CELL, OUT_CELL)
            out.alpha_composite(small, (c * OUT_CELL, r * OUT_CELL))
    return out


def shrink_image(cell, out_w, out_h):
    """Zmniejsza jeden obrazek pixel artu do out_w x out_h: skalowanie z mieszaniem na kanale
    alfa, twardy próg przezroczystości i powrót do oryginalnej palety kolorów."""
    cell_px = cell.load()
    palette = list({cell_px[x, y][:3] for y in range(cell.height) for x in range(cell.width) if cell_px[x, y][3] >= 128})
    small = cell.convert("RGBa").resize((out_w, out_h), Image.LANCZOS).convert("RGBA")
    px = small.load()
    cache = {}
    for y in range(out_h):
        for x in range(out_w):
            red, green, blue, alpha = px[x, y]
            if alpha < 110 or not palette:
                px[x, y] = (0, 0, 0, 0)
                continue
            key = (red, green, blue)
            if key not in cache:
                cache[key] = min(palette, key=lambda p: (p[0] - red) ** 2 + (p[1] - green) ** 2 + (p[2] - blue) ** 2)
            px[x, y] = cache[key] + (255,)
    return small


def _gd(value):
    if value is None:
        return "[]"
    if isinstance(value, list):
        return "[" + ", ".join(_gd(v) for v in value) + "]"
    if isinstance(value, dict):
        return "{" + ", ".join('"%s": %s' % (k, _gd(v)) for k, v in value.items()) + "}"
    return repr(value)


def main():
    grips = {}
    counts = {}
    heroes = [(h, n) for h, n in HEROES if os.path.exists(os.path.join(SRC, h, "rot_south.png"))]
    for hero, _name in heroes:
        grips[hero], counts[hero] = build(hero)
        print("Zapisano", hero)
    lines = [
        "class_name HeroRig",
        "## Wygenerowane przez tools/hero_sheets.py - nie edytować ręcznie.",
        "## Postacie gracza z PixelLab: arkusz assets/heroes/<postać>.png (kolumny = klatki,",
        "## wiersze = animacja * DIRS + kierunek; COUNTS - liczba klatek animacji, FRAMES - kolumn)",
        "## i chwyt broni w dłoni dla każdej klatki:",
        "## [x, y, kąt] w pikselach od stóp postaci (kierunki zachodnie = odbicie lustrzane), u Wojciecha też czwarta",
        "## liczba: 1 - broń za postacią, 0 - przed nią.",
        "",
        "const HEROES := %s" % _gd([h for h, _n in heroes]),
        "const NAMES := %s" % _gd({h: n for h, n in heroes}),
        "const DIRS := %d" % len(DIRS),
        "const ANIMS := %s" % _gd(ANIMS),
        "const FRAMES := %d" % FRAMES,
        "const CELL := %d" % OUT_CELL,
        "const FEET_Y := %d" % OUT_FEET_Y,
        "const COUNTS := %s" % _gd(counts),
        "const GRIPS := {",
    ]
    for hero, data in grips.items():
        lines.append('\t"%s": %s,' % (hero, _gd(data)))
    lines += [
        "}",
        "",
        "",
        "static func sheet(hero: String) -> Texture2D:",
        '\treturn load("res://assets/heroes/%s.png" % hero)',
        "",
        "",
        "## Arkusz pięści (ten sam układ co arkusz postaci): rysowany nad bronią, żeby rękojeść chowała się w dłoni.",
        "static func fist_sheet(hero: String) -> Texture2D:",
        '\treturn load("res://assets/heroes/%s_fist.png" % hero)',
        "",
        "",
        "## Liczba klatek animacji postaci (4 albo 8).",
        "static func frames(hero: String, anim: String) -> int:",
        "\treturn COUNTS.get(hero, {}).get(anim, 4)",
        "",
        "",
        "static func frame_index(anim: String, dir: int, frame: int) -> int:",
        "\treturn (ANIMS.find(anim) * DIRS + dir) * FRAMES + frame",
        "",
        "",
        "## Chwyt [x, y, kąt] dla klatki (pusta tablica - brak danych).",
        "static func grip(hero: String, anim: String, dir: int, frame: int) -> Array:",
        "\tvar per_dir: Array = GRIPS.get(hero, {}).get(anim, [])",
        "\tif dir >= per_dir.size() or per_dir[dir].is_empty():",
        "\t\treturn []",
        "\treturn per_dir[dir][mini(frame, per_dir[dir].size() - 1)]",
        "",
    ]
    with open(os.path.join(ROOT, "scripts", "hero_rig.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("Zapisano scripts/hero_rig.gd")


if __name__ == "__main__":
    main()
