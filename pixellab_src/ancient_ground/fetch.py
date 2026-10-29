"""Pobiera zestawy Wang podłoża Prastarego Lasu (PixelLab, tryb pro, 64 px) do pixellab_src/ancient_ground/<nazwa>.png + .json.
Identyfikatory w ids.json. Uruchom: python pixellab_src/ancient_ground/fetch.py [nazwa ...]"""
import json
import os
import sys
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://api.pixellab.ai/mcp/tilesets/%s/%s"


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})) as r:
        return r.read()


def main(names):
    ids = json.load(open(os.path.join(HERE, "ids.json"), encoding="utf-8"))
    for name in names or list(ids):
        try:
            image = get(API % (ids[name], "image?inline=true"))
            meta = get(API % (ids[name], "metadata"))
        except urllib.error.HTTPError as e:
            print("  %s: jeszcze nie gotowe (%d)" % (name, e.code))
            continue
        open(os.path.join(HERE, name + ".png"), "wb").write(image)
        open(os.path.join(HERE, name + ".json"), "wb").write(meta)
        print("  %s: pobrano" % name)


if __name__ == "__main__":
    main(sys.argv[1:])
