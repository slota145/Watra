#!/usr/bin/env bash
# Zrzut ekranu sceny na Linuksie bez monitora: Godot rysuje na wirtualnym ekranie (Xvfb)
# programowym OpenGL (Mesa). Renderer zgodności zamiast Forward+ - 2D wygląda tak samo,
# niektóre shadery i światła mogą się nieco różnić.
#
# Użycie: tools/screenshot.sh <plik.png> [scena] [sekundy] [rozdzielczość]
#   tools/screenshot.sh /tmp/menu.png
#   tools/screenshot.sh /tmp/wioska.png res://scenes/main.tscn 3 1920x1080
# Dowolny inny skrypt z oknem (np. testy ze zrzutami):
#   SCRIPT=tests/test_ui.gd tools/screenshot.sh <argumenty skryptu...>
# Ścieżkę do Godota można podać w zmiennej GODOT (domyślnie godot z PATH).
set -euo pipefail

project="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-godot}"
resolution="${RESOLUTION:-1280x720}"

if [[ -n "${SCRIPT:-}" ]]; then
    args=("$@")
else
    if [[ $# -lt 1 ]]; then
        sed -n '2,12p' "$0"
        exit 2
    fi
    out="$(realpath -m "$1")"
    args=("$out" "${2:-}" "${3:-1}")
    resolution="${4:-$resolution}"
    SCRIPT=tools/screenshot.gd
fi

# import zasobów: w świeżym klonie (brak .godot/) skrypty bez niego nie widzą klas globalnych,
# a po zmianie grafiki gra używałaby starej wersji; gdy nic się nie zmieniło, trwa kilka sekund
"$godot" --headless --path "$project" --import >/dev/null 2>&1 || true

exec xvfb-run -a -s "-screen 0 3840x2160x24" \
    "$godot" --path "$project" --rendering-driver opengl3 --resolution "$resolution" \
    -s "res://$SCRIPT" -- "${args[@]}"
