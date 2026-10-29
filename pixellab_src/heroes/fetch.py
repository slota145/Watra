"""Pobiera klatki postaci z PixelLab do pixellab_src/heroes/<postać>/ (adresy z get_character).
Uruchom: python pixellab_src/heroes/fetch.py <postać>"""
import os
import sys
import urllib.request

BASE = "https://backblaze.pixellab.ai/file/pixellab-characters/0c12cf4e-835c-4af3-a6b6-56994b1301d9/"
HERE = os.path.dirname(os.path.abspath(__file__))

# postać -> (id postaci, id znacznika, {animacja: {kierunek: id animacji}})
HEROES = {
    "wojciech": ("2943ee0b-be1f-43ce-84d5-e476021df5e9", "e19cc73c-1650-498a-aa8a-9735c3b09adf", {
        "walk": {"south": "e5a222a1-91c1-4feb-992d-20d3c39d4979", "south-east": "16e4279f-020c-4d3a-be4a-6277b51fafa2",
                 "east": "0d1f1429-36b3-4ce9-81bc-994b537b5e8c", "north-east": "7e7ba86e-fd12-4a52-b74f-b7026752dc12",
                 "north": "94f39220-99f6-4cd8-a3b4-f2fd89693462"},
        "slash": {"south": "49c04504-f055-4039-a0af-b28c9a966686", "south-east": "9510242f-78ea-4136-8473-a0ae96d67d0b",
                  "east": "4d35aa8f-42bc-43fe-8208-22af405e0e02", "north-east": "4585c103-e0c5-4333-b3e9-2dc8c567fa66",
                  "north": "c17daa3d-4480-405c-9145-0d5f0f5b6420"},
        "cast": {"south": "7788c44f-76c1-41e2-8264-84f4d246841d", "south-east": "e49ebd66-99f7-4e4e-aff0-afeae576afe3",
                 "east": "daca3b9d-058f-4ea2-a952-dd565b8db2f1", "north-east": "a99e3669-9635-4bcb-b30f-9f5660abb139",
                 "north": "f9763fb1-c636-4ff5-8b69-27dfe8fd0ffa"},
        "shoot": {"south": "34387720-5e08-4ee3-a496-e2812486fb4b", "south-east": "fb547b09-93ad-4bc8-adb9-855605f796b7",
                  "east": "963e5806-5770-43f9-bfb9-67532f536b03", "north-east": "5f17f5d7-f25e-4400-9407-33cfd615040d",
                  "north": "4d7ebcbf-3074-4f00-b5bd-7dc098f0c61c"},
    }),
    "bogdan": ("1ba8364f-0339-4ef4-8f18-b58da320ef49", "f6fa136e-cbb9-45da-8a15-f7ca07005c49", {
        "walk": {"south": "402a349c-c3ca-4be1-a6fa-2cc1d5f24823", "south-east": "94ddc46a-c5a9-460d-b017-9dfb7d02f3da",
                 "east": "3808e1c6-7f52-41a2-8c50-f0bdfd0ac184", "north-east": "630b2517-761e-4608-83a1-544a1b032389",
                 "north": "26781fca-e112-4a51-9f4b-18a41ee5cb83"},
        "slash": {"south": "f06a7978-4a41-41b7-88ac-4ecd21f309d3", "south-east": "14fa66ce-efe2-42dd-9245-46b49bf9523e",
                  "east": "0f844e0c-a792-4707-a09c-92f9b1e2f45e", "north-east": "9df9f2d3-95d7-4631-9356-38aa9d3d6460",
                  "north": "e05bf34a-9d1f-4b26-baff-27bc6fab1e98"},
        "cast": {"south": "c297963a-881c-4aea-94ad-a25cee9361d6", "south-east": "204ef77b-fccc-4b6a-8e5b-05f6cc7a0b88",
                 "east": "bd59f462-2f94-452d-aad1-10f609984221", "north-east": "de687990-8b01-4766-85f4-f7e4c1dd8faa",
                 "north": "4d7c8f30-6cfd-4669-b813-7ba22a2752f7"},
        "shoot": {"south": "f2822f83-a075-4774-a431-7b70a670e121", "south-east": "21d8a15c-9537-44a0-8dad-809d6f433f4b",
                  "east": "ed1cc686-d577-478d-a1e1-70f84c7fffcc", "north-east": "557f11ba-821e-497e-95a1-641af05e270f",
                  "north": "6373bfa8-2ce1-4133-a708-18444b1285c1"},
    }),
    "mira": ("2686c7d3-330c-4af4-afa1-be28d1e352b7", "931f652c-6703-42dd-896d-97d0a538fdb0", {
        "walk": {"south": "239a89d0-764c-42ad-a737-7743cd4dc17d", "south-east": "3c5c704d-3ea8-4c13-808e-54325550adce",
                 "east": "f68aca89-1e12-4f6f-a44d-0ef88dd07905", "north-east": "46102b27-fe86-4084-9daa-efdbc4d31c0a",
                 "north": "b42b73bc-ea89-4b58-90ce-62475f8a1ee0"},
        "slash": {"south": "b4b63e28-9603-4bab-98de-fd10751ae2ac", "south-east": "98ee5e5a-89de-4e63-9a8e-b028095a537f",
                  "east": "15bd1d9f-eb97-406b-973b-c9a219ec4e90", "north-east": "9df264cd-fb48-45f0-b688-a89c38503cc9",
                  "north": "eb9f1063-8af5-4827-89be-9f7c84ee7d2b"},
        "cast": {"south": "9ac7466b-9e3e-43c2-a770-93ebdeb81a17", "south-east": "ed6e3f85-c4f2-4969-b29f-169e9ca8e292",
                 "east": "6b6452ec-a737-4437-98f1-0a836da5772f", "north-east": "e4abd8d3-4976-4f1e-af5d-b053783b1eb1",
                 "north": "aafd5a9e-6fa6-4663-8e11-ff20e8648d07"},
        "shoot": {"south": "8de21c32-d34a-476b-b67d-2c4305c3805e", "south-east": "ca426208-a867-42af-8954-2b19003284cf",
                  "east": "657edfc7-cc14-40fe-9491-c212e1e079ae", "north-east": "a4bdb8e4-efe7-453c-9711-58bfd44116ec",
                  "north": "809e5ced-c6ac-4917-bfd8-8a284d7e9cc7"},
    }),
    "jaga": ("5dc5526c-34c8-4481-a41e-beed3cd3c797", "ec092049-2758-4251-b53c-5a7a022365b0", {
        "walk": {"south": "e7e29963-02f5-48ef-9ff9-fbf0d99e5a85", "south-east": "60b53820-39ad-45a8-9eb8-4c6dba928fc6",
                 "east": "7cd7fd1f-a031-485a-8df7-b3ce340fcf02", "north-east": "27acfa61-91b1-4f5a-babb-cf53ecedf96e",
                 "north": "42d42a7f-dad5-402d-ba2e-1acc1bb79feb"},
        "slash": {"south": "cf046829-ad0f-49b6-8931-013accca8dd3", "south-east": "03014f78-de3f-4d7f-96a3-96477f3dcf89",
                  "east": "59682342-bb26-4dc4-8618-a2287d42740e", "north-east": "0a54cf80-c37f-41e6-9f1a-8db2141767f8",
                  "north": "d27da28a-a5d8-4b3e-b4ff-bc3ee8de8607"},
        "cast": {"south": "5fce03cf-4752-4bd9-bf84-723fdb9aaec1", "south-east": "963ed8b6-e32d-42bc-8e61-101ad4337bd4",
                 "north-east": "614a4468-6664-4f58-834a-3cf54742cbd1", "north": "ddbaa505-43c3-4437-ad42-6d8a40c11421",
                 "east": "7ad9fff4-2279-4c90-b82a-5e9fa8adb006"},
        "shoot": {"south": "470718a0-7cc1-402c-9a12-9b386f62134f", "south-east": "b5a5674f-38be-49f2-8b8c-e896a173b27c",
                  "east": "b0472863-c02c-4b0d-9bc8-8820ddca792a", "north-east": "4d3421b4-55a4-42b5-9531-4868cd779159",
                  "north": "11ae1823-d7d4-452f-b650-cbb3a0b24a87"},
    }),
}
DIRS = ["south", "south-east", "east", "north-east", "north"]


def get(url, path):
    if os.path.exists(path):
        return
    request = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(request) as r, open(path, "wb") as f:
        f.write(r.read())


def fetch(hero):
    char_id, _marker, anims = HEROES[hero]
    folder = os.path.join(HERE, hero)
    os.makedirs(folder, exist_ok=True)
    for d in DIRS:
        get(BASE + "%s/rotations/%s.png" % (char_id, d), os.path.join(folder, "rot_%s.png" % d))
    for anim, dirs in anims.items():
        for d, anim_id in dirs.items():
            for i in range(4):
                get(BASE + "%s/animations/%s/%s/%d.png" % (char_id, anim_id, d, i),
                    os.path.join(folder, "%s_%s_%d.png" % (anim, d, i)))
    print("Pobrano", hero)


def urls(hero, anim="walk"):
    """Adresy klatek (do transfer_outfit): obroty, potem chód we wszystkich kierunkach."""
    char_id, _marker, anims = HEROES[hero]
    out = [BASE + "%s/rotations/%s.png" % (char_id, d) for d in DIRS]
    for d in DIRS:
        out += [BASE + "%s/animations/%s/%s/%d.png" % (char_id, anims[anim][d], d, i) for i in range(4)]
    return out


if __name__ == "__main__":
    fetch(sys.argv[1])
