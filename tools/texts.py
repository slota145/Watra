"""Zbiera napisy do tłumaczenia ze skryptów (scripts/**/*.gd) i scen (scenes/**/*.tscn) do pliku
translations/teksty.csv (kolumny: keys - polski tekst, en - tłumaczenie angielskie, _gdzie - pliki, w których
napis występuje; kolumny z "_" Godot pomija). Gotowe tłumaczenia zostają. Napisy, których nie ma już w grze,
a mają tłumaczenie, zostają na końcu z dopiskiem "(nieużywany)"; bez tłumaczenia - znikają.

Napis trafia do pliku, gdy:
- stoi w Lang.t(...), Lang.n(...) albo tr(...),
- ma polską literę albo kilka słów (po usunięciu znaczników BBCode i %s / %d),
- jest kluczem albo wartością w słowniku i zaczyna się wielką literą ("boss": "Wodnik"), stoi pod kluczem "name"
  ("name": "przyjazny") albo w słowniku stałej o nazwie kończącej się na _NAMES (WEAPON_NAMES),
- jest elementem listy w stałej (const) i zaczyna się wielką literą ([["goblin", "Gobliny", 40]]),
- w scenie jest tekstem kontrolki (text, tooltip_text, placeholder_text, title) albo nazwą bossa (boss_name).
Pomija: komunikaty print/push_error/assert, ścieżki plików, napisy z translations/pomijane.txt (jeden na linię).

Uruchom: python tools/texts.py           - odświeża plik
         python tools/texts.py --check   - tylko wypisuje, ile napisów nie ma tłumaczenia (nic nie zapisuje)"""
import csv
import glob
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(ROOT, "translations", "teksty.csv")
SKIP_PATH = os.path.join(ROOT, "translations", "pomijane.txt")
POLISH = re.compile(r"[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]")
CALL = re.compile(r"(?:\bLang\.t|\bLang\.n|(?<![\w.])tr|\.tr)\(\s*$")
DICT_VALUE = re.compile(r"[\"'\w]\s*:\s*$")
NAME_VALUE = re.compile(r"[\"']name[\"']\s*:\s*$")
NAMES_CONST = re.compile(r"^const \w*_NAMES\b")
LOG_CALL = re.compile(r"\b(print|prints|printerr|print_rich|push_error|push_warning|assert)\(|@export_group|@export_category|@export_subgroup")
SCENE_PROP = re.compile(r"^(text|tooltip_text|placeholder_text|title) = \"")
ESCAPES = {"n": "\n", "t": "\t", "\"": "\"", "'": "'", "\\": "\\", "r": "\r"}


def unescape(raw):
    out, i = [], 0
    while i < len(raw):
        c = raw[i]
        if c == "\\" and i + 1 < len(raw):
            out.append(ESCAPES.get(raw[i + 1], raw[i + 1]))
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def literals(line):
    """Napisy z linii kodu: (tekst, kod przed napisem, kod po napisie). Pomija komentarze, &"…" i ^"…"."""
    found, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c == "#":
            break
        if c in "\"'":
            j, raw = i + 1, []
            while j < n and line[j] != c:
                if line[j] == "\\" and j + 1 < n:
                    raw.append(line[j:j + 2])
                    j += 2
                    continue
                raw.append(line[j])
                j += 1
            prefix = line[i - 1] if i > 0 else ""
            if prefix not in "&^":
                found.append((unescape("".join(raw)), line[:i], line[j + 1:]))
            i = j + 1
            continue
        i += 1
    return found


def wordy(text):
    bare = re.sub(r"\[/?[a-z_]+(=[^\]]*)?\]", " ", text)
    bare = re.sub(r"%[-+0-9.]*[sdfix%]", " ", bare)
    words = re.findall(r"[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]{2,}", bare)
    return words


def wanted(text, before):
    if not text.strip() or "://" in text or re.search(r"\.(png|tscn|gd|ogg|wav|json|cfg|tres)$", text):
        return False
    words = wordy(text)
    if not words:
        return False
    if CALL.search(before):
        return True
    if POLISH.search(text):
        return True
    if " " in text.strip() and len(words) >= 2:
        return True
    if NAME_VALUE.search(before) or NAMES_CONST.search(before.lstrip()) and DICT_VALUE.search(before):
        return True
    return bool(DICT_VALUE.search(before)) and text[:1].isupper()


def scan_script(path, found):
    with open(path, encoding="utf-8-sig") as f:
        lines = f.read().split("\n")
    # napis może ciągnąć się przez kilka linii - łączy je, póki cudzysłów nie jest zamknięty
    logical, buffer = [], ""
    for line in lines:
        buffer = buffer + "\n" + line if buffer else line
        if not _open_quote(buffer):
            logical.append(buffer)
            buffer = ""
    if buffer:
        logical.append(buffer)
    in_const = False
    depth = 0
    for line in logical:
        if line.startswith("const "):
            in_const, depth = True, 0
        elif depth <= 0:
            in_const = False
        if line.strip().startswith("#") or LOG_CALL.search(line):
            continue
        for text, before, after in literals(line):
            last = before.split("\n")[-1]
            # klucz słownika z wielkiej litery ("Surowce": [...]) - nazwa kategorii pokazywana graczowi
            key = after.lstrip().startswith(":") and text[:1].isupper() and bool(wordy(text)) and "://" not in text
            # element listy w stałej, z wielkiej litery ([["goblin", "Gobliny", ...]], ["all", "Wszystko"])
            listed = in_const and text[:1].isupper() and bool(wordy(text)) and re.search(r"[\[,]\s*$", last) is not None
            if key or listed or wanted(text, last):
                found.setdefault(text, set()).add(os.path.basename(path))
        depth += _brackets(line)


def _brackets(line):
    """Bilans nawiasów [ ] { } ( ) w linii kodu (bez napisów i komentarzy)."""
    total, quote, i = 0, "", 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = ""
        elif c == "#":
            break
        elif c in "\"'":
            quote = c
        elif c in "[{(":
            total += 1
        elif c in "]})":
            total -= 1
        i += 1
    return total


def _open_quote(line):
    quote, i = "", 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = ""
        elif c == "#":
            return False
        elif c in "\"'":
            quote = c
        i += 1
    return quote != ""


def scan_scene(path, found):
    with open(path, encoding="utf-8-sig") as f:
        data = f.read()
    for match in re.finditer(r"^(?:text|tooltip_text|placeholder_text|title|boss_name) = \"((?:[^\"\\]|\\.)*)\"", data, re.M):
        text = unescape(match.group(1))
        if wordy(text):
            found.setdefault(text, set()).add(os.path.basename(path))


def main():
    found = {}
    for path in sorted(glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)):
        scan_script(path, found)
    for path in sorted(glob.glob(os.path.join(ROOT, "scenes", "**", "*.tscn"), recursive=True)):
        scan_scene(path, found)
    skip = set()
    if os.path.exists(SKIP_PATH):
        with open(SKIP_PATH, encoding="utf-8") as f:
            skip = {unescape(line.rstrip("\n")) for line in f if line.strip()}
    for text in skip:
        found.pop(text, None)
    old = {}
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                old[row["keys"]] = row.get("en", "")
    missing = sum(1 for text in found if not old.get(text))
    if "--check" in sys.argv:
        print("napisów: %d, bez tłumaczenia: %d" % (len(found), missing))
        return
    rows = [(text, old.get(text, ""), ", ".join(sorted(files)[:4])) for text, files in found.items()]
    rows.sort(key=lambda r: (r[2], r[0]))
    rows += [(text, en, "(nieużywany)") for text, en in old.items() if en and text not in found]
    os.makedirs(os.path.dirname(CSV_PATH), exist_ok=True)
    buffer = io.StringIO()
    writer = csv.writer(buffer, quoting=csv.QUOTE_ALL, lineterminator="\n")
    writer.writerow(["keys", "en", "_gdzie"])
    writer.writerows(rows)
    with open(CSV_PATH, "w", encoding="utf-8", newline="") as f:
        f.write(buffer.getvalue())
    print("napisów: %d, bez tłumaczenia: %d -> %s" % (len(found), missing, os.path.relpath(CSV_PATH, ROOT)))


if __name__ == "__main__":
    main()
