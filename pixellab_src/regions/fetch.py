"""Pobiera postacie i obiekty z PixelLab (paczki ZIP) do pixellab_src/regions/<nazwa>/.
Identyfikatory w ids.json (nazwa -> id postaci; "obj:<id>" dla obiektów 1-kierunkowych).
Uruchom: python pixellab_src/regions/fetch.py [nazwa ...]  (bez nazw - wszystkie)"""
import io
import json
import os
import sys
import urllib.error
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))


def fetch(name, ident):
    kind, ident = ("objects", ident[4:]) if ident.startswith("obj:") else ("characters", ident)
    url = "https://api.pixellab.ai/mcp/%s/%s/download" % (kind, ident)
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})) as r:
            data = r.read()
    except urllib.error.HTTPError as e:
        print("  %s: jeszcze nie gotowe (%d)" % (name, e.code))
        return False
    folder = os.path.join(HERE, name)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for entry in z.namelist():
            if entry.endswith("/"):
                continue
            # pierwszy stan postaci (np. "Idle/") spłaszczamy, pozostałe stany zostają w podfolderach
            parts = entry.split("/")
            if len(parts) > 1 and parts[0] in ("Idle", "base"):
                parts = parts[1:]
            target = os.path.join(folder, *parts)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as f:
                f.write(z.read(entry))
    print("  %s: pobrano" % name)
    return True


def main(names):
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    for name in names or [n for n in ids if not n.startswith("_")]:
        fetch(name, ids[name])


def packs():
    """Paczki kandydatów (obiekty 1-kierunkowe w przeglądzie): frame_<i>.png do pixellab_src/forest/<paczka>/."""
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    base = "https://backblaze.pixellab.ai/file/pixellab-characters/objects/0c12cf4e-835c-4af3-a6b6-56994b1301d9/"
    for name, ident in ids.get("_packs", {}).items():
        folder = os.path.join(HERE, name)
        os.makedirs(folder, exist_ok=True)
        for i in range(64):
            path = os.path.join(folder, "frame_%d.png" % i)
            if os.path.exists(path):
                continue
            try:
                req = urllib.request.Request(base + "%s/rotations/frame_%d.png" % (ident, i), headers={"User-Agent": "curl/8.0"})
                with urllib.request.urlopen(req) as r, open(path, "wb") as f:
                    f.write(r.read())
            except urllib.error.HTTPError:
                break
        print("  paczka %s: %d klatek" % (name, len(os.listdir(folder))))


def tilesets():
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    folder = os.path.join(HERE, "wang")
    os.makedirs(folder, exist_ok=True)
    for name, ident in ids.get("_tilesets", {}).items():
        for suffix, url in (("png", "image?inline=true"), ("json", "metadata")):
            req = urllib.request.Request("https://api.pixellab.ai/mcp/tilesets/%s/%s" % (ident, url), headers={"User-Agent": "curl/8.0"})
            try:
                with urllib.request.urlopen(req) as r, open(os.path.join(folder, "%s.%s" % (name, suffix)), "wb") as f:
                    f.write(r.read())
            except urllib.error.HTTPError as e:
                print("  zestaw %s: %d" % (name, e.code))


if __name__ == "__main__":
    if sys.argv[1:2] == ["packs"]:
        packs()
    elif sys.argv[1:2] == ["tiles"]:
        tilesets()
    else:
        main(sys.argv[1:])
