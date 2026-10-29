"""Pobiera paczki kandydatów PixelLab przeróbki Rozlewisk (most, kładki, brzegi) do pixellab_src/swamp_v2/<paczka>/frame_<i>.png.
Identyfikatory w ids.json. Uruchom: python pixellab_src/swamp_v2/fetch.py"""
import json
import os
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = "https://backblaze.pixellab.ai/file/pixellab-characters/objects/0c12cf4e-835c-4af3-a6b6-56994b1301d9/"


def main():
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    for name, ident in ids.items():
        folder = os.path.join(HERE, name)
        os.makedirs(folder, exist_ok=True)
        for i in range(64):
            path = os.path.join(folder, "frame_%d.png" % i)
            if os.path.exists(path):
                continue
            try:
                req = urllib.request.Request(BASE + "%s/rotations/frame_%d.png" % (ident, i), headers={"User-Agent": "curl/8.0"})
                data = urllib.request.urlopen(req).read()
            except urllib.error.HTTPError:
                break
            open(path, "wb").write(data)
        print("  paczka %s: %d klatek" % (name, len(os.listdir(folder))))


if __name__ == "__main__":
    main()
