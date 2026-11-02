"""Pobiera paczki kandydatów rekwizytów lochów (klucz "_packs" w ids.json) do pixellab_src/dungeons/<paczka>/ -
tą samą funkcją co pixellab_src/regions/fetch.py. Zestawy Wang klimatów pobiera się osobno (patrz tools/dungeon_tiles.py).
Uruchom: python pixellab_src/dungeons/fetch.py"""
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("regions_fetch", os.path.join(HERE, "..", "regions", "fetch.py"))
regions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(regions)
regions.HERE = HERE

if __name__ == "__main__":
    regions.packs()
