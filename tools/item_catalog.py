"""Katalog przedmiotów do założenia: linie (miecz, topór, kaptur...) w 5 poziomach (zakresy poziomu przedmiotu)
i 3 wyglądach rzadkości (zwykły, magiczny, rzadki). Jedno źródło dla promptów PixelLab (ikony 64x64),
nazw i statystyk - tools/pixellab_items.py generuje z niego scripts/item_bases.gd.

Statystyki bazowe są podane na poziom przedmiotu 1; w grze rosną z poziomem (Loot.base_multiplier),
więc poziom linii (t1-t5) decyduje o wyglądzie i nazwie, a liczby wynikają z poziomu przedmiotu.
Pierwszy poziom części linii to dawne przedmioty (iron_sword, leather_cap...) - zachowują id, nazwy
i ceny, żeby działały sklepy i stare zapisy.
"""

# zakresy poziomu przedmiotu dla poziomów linii
TIER_LEVELS = [(1, 19), (20, 39), (40, 59), (60, 79), (80, 100)]
RARITIES = ["common", "magic", "rare"]

ICON_STYLE = ("fantasy RPG inventory item icon, single item centered on transparent background, "
              "clean dark outline, rich shading, painterly pixel art")
RARITY_LOOK = {
    "common": "plain and simple, no decorations",
    "magic": "enchanted with softly glowing blue runes and a small sapphire",
    "rare": "ornate with golden filigree decorations and amber gems, faint golden glow",
}
DIAGONAL = "diagonal, with the tip pointing to the top-right corner and the handle at the bottom-left"
MATERIALS = {
    "metal": ["plain worn iron", "polished steel", "elegant elven mithril, pale silver-blue",
              "dark black steel engraved with glowing cyan runes", "dragonbone and red dragon scales with glowing embers"],
    "wood": ["simple wood", "reinforced yew wood with steel fittings", "elegant white elven wood with silver leaves",
             "dark ebony wood carved with glowing cyan runes", "dragonbone with red dragon scales and ember glow"],
    "book": ["a worn brown leather binding", "a sturdy blue cloth binding with brass corners",
             "a white elven binding with silver leaf ornaments", "a black leather binding with glowing cyan rune sigils",
             "a red dragon-scale binding with a glowing dragon eye on the cover"],
    "leather": ["worn brown leather", "hardened studded leather", "green elven leather with silver leaf embroidery",
                "black shadow leather with glowing cyan runes", "red dragonhide with dragon scales"],
    "cloth": ["plain linen", "blue wool", "white and green elven silk with silver embroidery",
              "dark purple shadow silk with glowing cyan runes", "crimson dragon silk with dragon scale trim"],
    "jewel": ["copper", "silver", "gold", "platinum with a glowing cyan runic crystal", "dragon gold with a blazing star gem"],
    "fang": ["wolf fang on a copper hoop", "bear fang on a silver hoop", "basilisk fang on a gold hoop",
             "demon fang with cyan runes on a platinum hoop", "glowing dragon fang on a dragon gold hoop"],
}

# id linii, miejsce, rodzaj materiału, opis przedmiotu (en, {m} - materiał), nazwy poziomów (pl),
# id poziomu 1 (dawny przedmiot albo None), statystyki bazowe, cena sprzedaży, chwyt (broń)
LINES = [
    # ---------------------------------------------------------------- broń
    {"id": "sword", "slot": "weapon", "material": "metal", "prompt": "sword, " + DIAGONAL,
     "names": ["Żelazny miecz", "Stalowy miecz", "Mithrilowy miecz", "Runiczne ostrze", "Smocze ostrze"],
     "t1": "iron_sword", "sell": 25, "held": {"length": 30, "grip": "guard"},
     "weapon": {"type": "melee", "damage": [14, 20], "speed": 1.0, "reach": 31.0, "arc": 160.0},
     "description": "Wyważone ostrze - dobre na każdą okazję."},
    {"id": "axe", "slot": "weapon", "material": "metal", "prompt": "battle axe, " + DIAGONAL.replace("tip", "axe head"),
     "names": ["Topór bojowy", "Stalowy topór", "Mithrilowy topór", "Runiczny topór", "Smoczy topór"],
     "t1": "war_axe", "sell": 45, "held": {"length": 30, "grip": 0.18},
     "weapon": {"type": "melee", "damage": [19, 27], "speed": 0.8, "reach": 33.0, "arc": 190.0},
     "description": "Wolniejszy, ale tnie szerzej i mocniej."},
    {"id": "mace", "slot": "weapon", "material": "metal", "prompt": "flanged mace, " + DIAGONAL.replace("tip", "mace head"),
     "names": ["Żelazna buława", "Stalowa buława", "Mithrilowa buława", "Runiczny młot", "Smoczy młot"],
     "t1": None, "sell": 35, "held": {"length": 28, "grip": 0.18},
     "weapon": {"type": "melee", "damage": [17, 24], "speed": 0.9, "reach": 30.0, "arc": 170.0},
     "description": "Miażdży pancerze i kości."},
    {"id": "dagger", "slot": "weapon", "material": "metal", "prompt": "dagger, " + DIAGONAL,
     "names": ["Żelazny sztylet", "Stalowy puginał", "Mithrilowy sztylet", "Runiczny sztylet", "Smoczy kieł"],
     "t1": None, "sell": 25, "held": {"length": 20, "grip": "guard"},
     "weapon": {"type": "melee", "damage": [8, 12], "speed": 1.4, "reach": 26.0, "arc": 130.0},
     "description": "Krótki zasięg, ale błyskawiczne cięcia."},
    {"id": "bow", "slot": "weapon", "material": "wood",
     "prompt": "bow, drawn diagonally from the bottom-left corner to the top-right corner, with its string",
     "names": ["Krótki łuk", "Łuk refleksyjny", "Elfi łuk", "Runiczny łuk", "Smoczy łuk"],
     "t1": "short_bow", "sell": 30, "held": {"length": 30, "grip": "bow"},
     "weapon": {"type": "bow", "damage": [9, 14], "speed": 1.0, "cooldown": 0.45,
                "projectile": {"texture": "arrow", "speed": 340.0, "range": 300.0, "pierce": 0, "magic": False}},
     "description": "Strzela w kierunku kursora. Strzała trafia pierwszego wroga na drodze."},
    {"id": "book", "slot": "weapon", "material": "book", "prompt": "closed spellbook seen from the front, upright",
     "names": ["Księga magicznych pocisków", "Księga zaklęć", "Elfi grimuar", "Runiczny grimuar", "Smocza księga"],
     "t1": "spellbook", "sell": 40, "held": {"length": 10, "grip": "book"},
     "weapon": {"type": "spell", "damage": [10, 15], "speed": 1.0, "cooldown": 0.5,
                "projectile": {"texture": "magic_missile", "speed": 230.0, "range": 250.0, "pierce": 2, "magic": True}},
     "description": "Wystrzeliwuje magiczny pocisk w kierunku kursora. Nie zużywa many. Pocisk przebija do 2 wrogów."},
    {"id": "staff", "slot": "weapon", "material": "wood", "prompt": "magic staff with a crystal at the top, " + DIAGONAL.replace("tip", "crystal top"),
     "names": ["Dębowy kostur", "Kostur adepta", "Elfi kostur", "Runiczny kostur", "Smoczy kostur"],
     "t1": None, "sell": 40, "held": {"length": 38, "grip": 0.3},
     "weapon": {"type": "spell", "damage": [14, 21], "speed": 1.0, "cooldown": 0.65,
                "projectile": {"texture": "magic_missile", "speed": 260.0, "range": 280.0, "pierce": 3, "magic": True}},
     "description": "Wolniej rzuca, ale pocisk leci dalej, mocniej uderza i przebija do 3 wrogów. Nie zużywa many."},
    # ---------------------------------------------------------------- zbroja
    {"id": "hood", "slot": "helmet", "material": "leather", "prompt": "hood, front view",
     "names": ["Skórzany kaptur", "Kaptur wędrowca", "Elfi kaptur", "Kaptur cienia", "Kaptur ze smoczej skóry"],
     "t1": "leather_cap", "sell": 10, "stats": {"armor": 2, "mana": 5},
     "description": "Lekki kaptur - nie krępuje ruchów ani myśli."},
    {"id": "helm", "slot": "helmet", "material": "metal", "prompt": "knight helmet, front view",
     "names": ["Żelazny hełm", "Stalowy hełm", "Mithrilowy hełm", "Runiczny hełm", "Smoczy hełm"],
     "t1": "iron_helmet", "sell": 30, "stats": {"armor": 5},
     "description": "Ciężki, ale głowa zostaje na karku."},
    {"id": "robe", "slot": "chest", "material": "cloth", "prompt": "mage robe, front view",
     "names": ["Lniana szata", "Szata adepta", "Elfia szata", "Szata cienia", "Smocza szata"],
     "t1": None, "sell": 20, "stats": {"armor": 3, "mana": 10},
     "description": "Szata maga - mało chroni, ale wzmacnia przepływ many."},
    {"id": "jerkin", "slot": "chest", "material": "leather", "prompt": "armored jerkin vest, front view",
     "names": ["Skórzana kurta", "Ćwiekowana kurta", "Elfi kaftan", "Kurta cienia", "Kurta ze smoczej skóry"],
     "t1": "leather_armor", "sell": 15, "stats": {"armor": 5, "health": 5},
     "description": "Utwardzana skóra - złoty środek między ochroną a swobodą."},
    {"id": "plate", "slot": "chest", "material": "metal", "prompt": "plate armor breastplate, front view",
     "t1_prompt": "chainmail hauberk shirt, front view",
     "names": ["Kolczuga", "Stalowy napierśnik", "Mithrilowy napierśnik", "Runiczna zbroja", "Smocza zbroja"],
     "t1": "chainmail", "sell": 50, "stats": {"armor": 9},
     "description": "Najlepsza ochrona, jaką da się wykuć."},
    {"id": "gloves", "slot": "gloves", "material": "leather", "prompt": "pair of gloves",
     "names": ["Skórzane rękawice", "Rękawice łucznika", "Elfie rękawice", "Rękawice cienia", "Rękawice ze smoczej skóry"],
     "t1": "leather_gloves", "sell": 10, "stats": {"armor": 1, "attack_speed": 0.03},
     "description": "Pewniejszy chwyt broni."},
    {"id": "gauntlets", "slot": "gloves", "material": "metal", "prompt": "pair of plate gauntlets",
     "names": ["Żelazne rękawice", "Stalowe rękawice", "Mithrilowe rękawice", "Runiczne rękawice", "Smocze rękawice"],
     "t1": None, "sell": 25, "stats": {"armor": 3},
     "description": "Okute rękawice - ciosy ześlizgują się po nich."},
    {"id": "boots", "slot": "boots", "material": "leather", "prompt": "pair of boots",
     "names": ["Skórzane buty", "Buty wędrowca", "Elfie buty", "Buty cienia", "Buty ze smoczej skóry"],
     "t1": "leather_boots", "sell": 10, "stats": {"armor": 1, "move_speed": 0.05},
     "description": "Wygodne na długie marsze przez las."},
    {"id": "greaves", "slot": "boots", "material": "metal", "prompt": "pair of plate armored boots",
     "names": ["Żelazne trzewiki", "Stalowe trzewiki", "Mithrilowe trzewiki", "Runiczne trzewiki", "Smocze trzewiki"],
     "t1": None, "sell": 25, "stats": {"armor": 3, "move_speed": 0.02},
     "description": "Ciężkie, okute buty."},
    # ---------------------------------------------------------------- biżuteria
    {"id": "band", "slot": "ring", "material": "jewel", "prompt": "ring with a gemstone",
     "names": ["Miedziany pierścień", "Srebrny pierścień", "Złoty pierścień", "Platynowy pierścień", "Gwiezdny pierścień"],
     "t1": "copper_ring", "sell": 15, "stats": {"health": 10},
     "description": "Prosty, ale dodaje otuchy."},
    {"id": "signet", "slot": "ring", "material": "jewel", "prompt": "heavy signet ring with a red stone",
     "names": ["Pierścień siły", "Srebrny sygnet", "Złoty sygnet", "Runiczny sygnet", "Smoczy sygnet"],
     "t1": "ring_of_strength", "sell": 20, "stats": {"damage": 1},
     "description": "Czerwony kamień ciepło pulsuje."},
    {"id": "stud", "slot": "earring", "material": "jewel", "prompt": "earring with a blue gem",
     "names": ["Srebrny kolczyk", "Kolczyk z szafirem", "Złoty kolczyk", "Runiczny kolczyk", "Gwiezdny kolczyk"],
     "t1": "silver_earring", "sell": 12, "stats": {"mana": 5},
     "description": "Niebieskie oczko szepcze o magii."},
    {"id": "fang", "slot": "earring", "material": "fang", "prompt": "earring: {m}",
     "names": ["Kolczyk z kłem", "Kolczyk z kłem niedźwiedzia", "Kolczyk z kłem bazyliszka", "Kolczyk z kłem demona",
               "Kolczyk ze smoczym kłem"],
     "t1": "fang_earring", "sell": 12, "stats": {"health": 5},
     "description": "Kieł bestii. Talizman myśliwych."},
    {"id": "amulet", "slot": "necklace", "material": "jewel", "prompt": "amulet necklace with an amber pendant",
     "names": ["Bursztynowy naszyjnik", "Srebrny amulet", "Złoty amulet", "Runiczny amulet", "Smoczy amulet"],
     "t1": "amber_necklace", "sell": 25, "stats": {"health": 5, "mana": 10},
     "description": "W bursztynie zastygł maleńki owad."},
    {"id": "talisman", "slot": "necklace", "material": "jewel", "prompt": "talisman necklace with a carved bone charm",
     "names": ["Kościany talizman", "Srebrny talizman", "Złoty talizman", "Runiczny talizman", "Gwiezdny talizman"],
     "t1": None, "sell": 25, "stats": {"damage": 1, "health": 3},
     "description": "Amulet wojownika - dodaje animuszu w walce."},
]

# pozostałe ikony przedmiotów (plik w assets/items -> opis): legendy, łupy, mikstury, kamienie, przyzwania
LEGENDARY_LOOK = "legendary artifact, glowing orange-gold aura, intricate and powerful"
MISC = [
    ("ring_gruzlog", "heavy massive gold signet ring of a goblin warlord with a cracked green stone, " + LEGENDARY_LOOK),
    ("ring_alpha", "silver ring set with a white wolf fang, faint howling moonlight glow, " + LEGENDARY_LOOK),
    ("ring_bulgor", "ring with a sea-green ocean stone swirling with water, coral and shells, " + LEGENDARY_LOOK),
    ("ring_storm", "steel ring with a crackling blue storm crystal and tiny lightning bolts, " + LEGENDARY_LOOK),
    ("ring_wodnik", "cold silver ring with an eye of swirling black water, dripping, " + LEGENDARY_LOOK),
    ("ring_leshy", "ring of twisted living root wood with tiny green leaves and moss, " + LEGENDARY_LOOK),
    ("ring_queen", "black ring with a red hourglass gem wrapped in spider silk, dripping green venom, " + LEGENDARY_LOOK),
    ("ring_bies", "ring of black demon horn with a glowing red eye, " + LEGENDARY_LOOK),
    ("earring_gruzlog", "huge goblin warlord fang earring in a golden setting, " + LEGENDARY_LOOK),
    ("earring_alpha", "earring of three wolf claws on a silver hoop, " + LEGENDARY_LOOK),
    ("earring_bulgor", "earring with a teardrop of glowing swamp water that never dries, " + LEGENDARY_LOOK),
    ("earring_storm", "earring made of a storm feather crackling with blue lightning, " + LEGENDARY_LOOK),
    ("earring_wodnik", "earring with a murky pearl holding a green ghostly flame, " + LEGENDARY_LOOK),
    ("earring_leshy", "earring of a golden acorn wrapped in thorny vines, " + LEGENDARY_LOOK),
    ("earring_queen", "earring with a tiny silk cocoon on a silver hoop, something moves inside, " + LEGENDARY_LOOK),
    ("earring_bies", "earring of a curved demon talon in gold setting, blood red glow, " + LEGENDARY_LOOK),
    ("rusty_sword", "old rusty chipped iron sword, " + DIAGONAL),
    ("goblin_heart", "green-red goblin heart, still warm and slightly glowing"),
    ("iron_ore", "chunk of rusty iron ore rock with metallic veins"),
    ("goat_hide", "fluffy white mountain goat hide, folded"),
    ("storm_feather", "grey-blue feather sparking with tiny blue lightning"),
    ("wood", "bundle of chopped wooden logs"),
    ("stone", "pile of grey quarried stone blocks"),
    ("wolf_pelt", "thick grey wolf pelt, folded"),
    ("deer_hide", "thick brown deer hide, folded"),
    ("roe_hide", "light tan spotted roe deer hide, folded"),
    ("boar_hide", "tough bristly dark boar hide, folded"),
    ("hare_pelt", "small fluffy brown hare pelt"),
    ("meat", "raw venison steak on the bone"),
    ("frog_tongue", "long sticky pink frog tongue, coiled"),
    ("summon_chief", "bloody goblin totem with a beating heart tied to it, summoning item"),
    ("summon_alpha", "hunting horn wrapped in grey wolf fur, summoning item"),
    ("summon_frog_chief", "large swamp conch shell lined with frog tongues, summoning item"),
    ("summon_storm_eagle", "bundle of storm feathers bound around a sparking blue crystal, summoning item"),
    ("drowned_algae", "slimy dark green algae from a drowned pond"),
    ("drowned_pearl", "murky pearl with a ghostly green glow inside"),
    ("ancient_bark", "thick piece of mossy ancient tree bark, faintly pulsing green"),
    ("spider_silk", "spool of shiny white spider silk"),
    ("spider_venom", "small glass vial of glowing green spider venom"),
    ("beast_fang", "huge curved beast fang trophy"),
    ("summon_leshy", "gnarled branch of ancient bark with a glowing green rune, summoning item"),
    ("summon_spider_queen", "large spider egg wrapped in silk dripping venom, summoning item"),
    ("summon_bies", "horned demon skull studded with beast fangs, summoning item"),
    ("summon_wodnik", "wet smoking pipe wrapped in seaweed, summoning item"),
    ("fish", "fresh silver river fish"),
    ("antlers", "majestic deer antlers trophy"),
    ("pouch", "small leather belt pouch with a buckle"),
    ("backpack", "large leather travel backpack with straps"),
    ("health_potion", "round glass potion bottle with glowing red health liquid, cork"),
    ("mana_potion", "round glass potion bottle with glowing blue mana liquid, cork"),
    ("weapon_stone", "red enchanting gemstone, faceted"),
    ("weapon_stone_perfect", "large radiant red enchanting crystal, brilliant glow"),
    ("armor_stone", "blue enchanting gemstone, faceted"),
    ("armor_stone_perfect", "large radiant blue enchanting crystal, brilliant glow"),
    ("jewelry_stone", "purple enchanting gemstone, faceted"),
    ("jewelry_stone_perfect", "large radiant purple enchanting crystal, brilliant glow"),
    ("blessed_stone", "small golden blessed stone, warm holy glow"),
    ("mercy_stone", "small azure orb of mercy, soft light"),
    ("coin", "single shiny gold coin"),
]

# poprawki nieudanych ikon (ta sama nazwa pliku - pobrane później nadpisują pierwszą wersję)
_BAND_MAGIC = ("solid {m} ring band seen from the front, with a bright glowing blue sapphire set on top, "
               "softly glowing blue runes engraved on the band")
MISC += [("copper_ring_magic", _BAND_MAGIC.format(m="copper")), ("band_t2_magic", _BAND_MAGIC.format(m="silver")),
         ("band_t3_magic", _BAND_MAGIC.format(m="gold")),
         ("band_t4_magic", _BAND_MAGIC.format(m="platinum with a glowing cyan runic crystal")),
         ("band_t5_magic", _BAND_MAGIC.format(m="dragon gold with a blazing star gem"))]

# ikony umiejętności (assets/skills) i interfejsu (assets/ui) - osobne paczki z własnym stylem
SKILL_STYLE = "fantasy RPG skill ability icon, square with a dark rounded frame, vivid magical effect, painterly pixel art"
SKILLS = [
    ("lunge", "warrior lunging forward with a sword, motion lines"),
    ("crescent", "crescent shaped golden sword slash arc"),
    ("whirlwind", "spinning whirlwind of sword blades"),
    ("seeker", "glowing homing arrow curving towards a target"),
    ("multishot", "three arrows flying in a fan"),
    ("rapid_volley", "rapid volley of many arrows"),
    ("fireball", "blazing fireball"),
    ("chain_lightning", "chain lightning jumping between points"),
    ("thunder_wave", "shockwave of thunder rings around a mage"),
    ("health_regen", "glowing red heart with green healing sparkles"),
    ("mana_regen", "glowing blue mana crystal with swirling energy"),
]
UI_STYLE = "fantasy RPG interface button icon, simple bold readable symbol, dark outline, pixel art"
UI_ICONS = [
    ("bag", "brown leather sack bag with a gold buckle"),
    ("character", "portrait bust of a young adventurer with brown hair and blue tunic"),
    ("skills", "open purple spellbook with a glowing magic star above"),
    ("map", "rolled out parchment map with a red X"),
    ("help", "blue circle with a white question mark"),
    ("journal", "quest journal: parchment scroll with a feather quill"),
    ("trash", "grey metal trash can with a lid"),
    ("sort", "three horizontal bars of decreasing length with a golden down arrow"),
    ("shrine_icon", "small glowing blue stone shrine"),
    ("track_on", "bright open eye with a golden iris"),
    ("track_off", "grey dim closed eye"),
]

# dawne ceny w sklepie (tylko poziom 1 dawnych przedmiotów)
SHOP_PRICES = {"iron_sword": 80, "war_axe": 140, "short_bow": 90, "spellbook": 120, "leather_cap": 30,
               "iron_helmet": 90, "leather_armor": 50, "chainmail": 160, "leather_gloves": 35, "leather_boots": 35,
               "copper_ring": 45, "ring_of_strength": 60, "silver_earring": 35, "fang_earring": 35,
               "amber_necklace": 70}


def base_id(line, tier):
    """Id przedmiotu bazowego: dawne id dla poziomu 1 albo <linia>_t<n>."""
    if tier == 0 and line.get("t1"):
        return line["t1"]
    return "%s_t%d" % (line["id"], tier + 1)


def icon_name(line, tier, rarity):
    """Nazwa pliku ikony (bez .png): zwykły - samo id, inne - z dopiskiem rzadkości."""
    return base_id(line, tier) + ("" if rarity == "common" else "_" + rarity)


def prompt(line, tier, rarity):
    material = MATERIALS[line["material"]][tier]
    text = line["t1_prompt"] if tier == 0 and "t1_prompt" in line else line["prompt"]
    if "{m}" in text:
        text = text.format(m=material)
    else:
        text += ", %s %s" % ("with" if line["material"] == "book" else "made of", material)
    return "%s, %s" % (text, RARITY_LOOK[rarity])


# linie wygenerowane w próbnej paczce (16. miejsce nie było przedmiotem z MISC)
PILOT_LINES = {"sword"}


def batches():
    """Paczki po 16 ikon do jednego wywołania create_1_direction_object: [(nazwa, styl, [(plik, prompt), ...])].
    Linie mają po 15 ikon - szesnaste miejsce dostaje kolejny przedmiot z MISC; resztę MISC dzielimy po 16."""
    misc = list(MISC)
    result = []
    for line in LINES:
        items = [(icon_name(line, t, r), prompt(line, t, r)) for t in range(5) for r in RARITIES]
        if misc and line["id"] not in PILOT_LINES:
            items.append(misc.pop(0))
        result.append((line["id"], ICON_STYLE, items))
    for i in range(0, len(misc), 16):
        result.append(("misc_%d" % (i // 16), ICON_STYLE, misc[i:i + 16]))
    result.append(("skills", SKILL_STYLE, SKILLS))
    result.append(("ui", UI_STYLE, UI_ICONS))
    return result


if __name__ == "__main__":
    import json
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    which = sys.argv[1] if len(sys.argv) > 1 else None
    for name, style, items in batches():
        if which and name != which:
            continue
        print(name, len(items), json.dumps([p for _, p in items], ensure_ascii=False))
