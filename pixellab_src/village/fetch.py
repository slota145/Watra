"""Pobiera grafiki osady z PixelLab do pixellab_src/village/ (identyfikatory w ids.json):
budynki (obiekty mapy) jako buildings/<nazwa>.png i mieszkańców (paczki postaci) do npcs/<nazwa>/.
Uruchom: python pixellab_src/village/fetch.py [buildings|npcs|animals|packs|props|objects]"""
import io
import json
import os
import sys
import urllib.error
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://api.pixellab.ai/mcp/"


def _get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})) as r:
        return r.read()


def buildings(ids):
    folder = os.path.join(HERE, "buildings")
    os.makedirs(folder, exist_ok=True)
    for name, ident in ids.items():
        try:
            data = _get(API + "map-objects/%s/download" % ident)
        except urllib.error.HTTPError as e:
            print("  %s: jeszcze nie gotowe (%d)" % (name, e.code))
            continue
        open(os.path.join(folder, name + ".png"), "wb").write(data)
        print("  %s: pobrano" % name)


def npcs(ids, root="npcs"):
    for name, ident in ids.items():
        try:
            data = _get(API + "characters/%s/download" % ident)
        except urllib.error.HTTPError as e:
            print("  %s: jeszcze nie gotowe (%d)" % (name, e.code))
            continue
        folder = os.path.join(HERE, root, name)
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for entry in z.namelist():
                if entry.endswith("/"):
                    continue
                parts = entry.split("/")
                if len(parts) > 1 and parts[0] in ("Idle", "base"):
                    parts = parts[1:]
                target = os.path.join(folder, *parts)
                os.makedirs(os.path.dirname(target), exist_ok=True)
                open(target, "wb").write(z.read(entry))
        print("  %s: pobrano" % name)


def obj(name, ident):
    """Obiekt 1-kierunkowy z animacją (np. wóz) do <nazwa>/."""
    data = _get(API + "objects/%s/download" % ident)
    folder = os.path.join(HERE, name)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for entry in z.namelist():
            if entry.endswith("/"):
                continue
            parts = entry.split("/")
            if len(parts) > 1 and parts[0] in ("Idle", "base"):
                parts = parts[1:]
            target = os.path.join(folder, *parts)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            open(target, "wb").write(z.read(entry))
    print("  %s: pobrano" % name)


def packs(ids):
    """Paczki kandydatów (obiekty 1-kierunkowe w przeglądzie): <paczka>/frame_<i>.png."""
    base = "https://backblaze.pixellab.ai/file/pixellab-characters/objects/0c12cf4e-835c-4af3-a6b6-56994b1301d9/"
    for name, ident in ids.get("_packs", {}).items():
        folder = os.path.join(HERE, name)
        os.makedirs(folder, exist_ok=True)
        for i in range(64):
            path = os.path.join(folder, "frame_%d.png" % i)
            if os.path.exists(path):
                continue
            try:
                data = _get(base + "%s/rotations/frame_%d.png" % (ident, i))
            except urllib.error.HTTPError:
                break
            open(path, "wb").write(data)
        print("  paczka %s: %d klatek" % (name, len(os.listdir(folder))))


def props(ids):
    """Duże rekwizyty (obiekty mapy) i pasy (obrazy) do props/<nazwa>.png."""
    folder = os.path.join(HERE, "props")
    os.makedirs(folder, exist_ok=True)
    for name, ident in ids.get("props", {}).items():
        try:
            open(os.path.join(folder, name + ".png"), "wb").write(_get(API + "map-objects/%s/download" % ident))
        except urllib.error.HTTPError as e:
            print("  %s: %d" % (name, e.code))
    for name, ident in ids.get("images", {}).items():
        try:
            open(os.path.join(folder, name + ".png"), "wb").write(_get(API + "images/%s/download" % ident))
        except urllib.error.HTTPError as e:
            print("  %s: %d" % (name, e.code))


if __name__ == "__main__":
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    what = sys.argv[1:] or ["buildings", "npcs", "wagon"]
    if "buildings" in what:
        buildings(ids["buildings"])
    if "npcs" in what:
        npcs(ids["npcs"])
    if "animals" in what:
        npcs(ids.get("animals", {}), "animals")
    if "packs" in what:
        packs(ids)
    if "props" in what:
        props(ids)
    if "objects" in what:
        for name, ident in ids.get("objects", {}).items():
            obj(name, ident)
    if "wagon" in what:
        obj("wagon", ids["wagon"])
        if "wagon_up" in ids:
            obj("wagon_up", ids["wagon_up"])
