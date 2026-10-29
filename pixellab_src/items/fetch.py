"""Pobiera paczki ikon przedmiotów (PixelLab, create_1_direction_object, 16 kandydatów 64x64) do
pixellab_src/items/raw/<plik>.png - nazwy plików według kolejności w tools/item_catalog.batches().
Identyfikatory paczek w ids.json; pojedyncze ikony wybrane z innych paczek (poprawki) w overrides.json
(plik -> [id paczki, numer kandydata]) - pobierane na końcu, więc nadpisują wersję z paczki. Uruchom: python pixellab_src/items/fetch.py [paczka ...]"""
import json
import os
import sys
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
import item_catalog  # noqa: E402

FRAME = "https://backblaze.pixellab.ai/file/pixellab-characters/objects/0c12cf4e-835c-4af3-a6b6-56994b1301d9/%s/rotations/frame_%d.png"


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})) as r:
        return r.read()


def main(names):
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    out = os.path.join(HERE, "raw")
    os.makedirs(out, exist_ok=True)
    batches = {name: items for name, _style, items in item_catalog.batches()}
    for name in names or list(ids):
        if name not in batches:
            continue
        done = 0
        for i, (file, _prompt) in enumerate(batches[name]):
            path = os.path.join(out, file + ".png")
            try:
                data = get(FRAME % (ids[name], i))
            except urllib.error.HTTPError as e:
                print("  %s/%s: brak (%d)" % (name, file, e.code))
                continue
            open(path, "wb").write(data)
            done += 1
        print("  %s: pobrano %d/%d" % (name, done, len(batches[name])))
    overrides = os.path.join(HERE, "overrides.json")
    if os.path.exists(overrides):
        for file, (object_id, index) in json.load(open(overrides, encoding="utf-8")).items():
            open(os.path.join(out, file + ".png"), "wb").write(get(FRAME % (object_id, index)))
            print("  poprawka: %s" % file)


if __name__ == "__main__":
    main(sys.argv[1:])
