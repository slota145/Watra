"""Pobiera grafiki Leśnego Cmentarza z PixelLab do pixellab_src/cemetery/ - tymi samymi funkcjami co
pixellab_src/regions/fetch.py (postacie i obiekty z ZIP, paczki kandydatów, zestawy Wang).
Uruchom: python pixellab_src/cemetery/fetch.py [nazwa ...]"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("regions_fetch", os.path.join(HERE, "..", "regions", "fetch.py"))
regions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(regions)
regions.HERE = HERE

if __name__ == "__main__":
    names = sys.argv[1:]
    if not names or "packs" in names:
        regions.packs()
    if not names or "tilesets" in names:
        regions.tilesets()
    rest = [n for n in names if n not in ("packs", "tilesets")]
    if rest or not names:
        for name in rest or [n for n in regions.json.load(open(os.path.join(HERE, "ids.json"))) if not n.startswith("_")]:
            try:
                regions.main([name])
            except Exception as e:  # obiekt jeszcze nie gotowy (zwraca stronę zamiast ZIP)
                print("  %s: %s" % (name, e))
