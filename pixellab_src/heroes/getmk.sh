# użycie: getmk.sh <postać> <kierunek> <job_id> - pobiera klatki znacznika (obrót + 4 klatki chodu)
cd "$(dirname "$0")/$1" || exit 1
curl -sL --fail -o mk_idle_$2.png "https://api.pixellab.ai/mcp/images/$3/download?index=0" || { rm -f mk_idle_$2.png; echo "brak $1 $2"; exit 0; }
for k in 0 1 2 3; do curl -sL --fail -o mk_walk_$2_$k.png "https://api.pixellab.ai/mcp/images/$3/download?index=$((k+1))" || rm -f mk_walk_$2_$k.png; done
echo "ok $1 $2"
