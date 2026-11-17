#!/bin/sh
# hoh.lock pins full commits and the tinyxml2 sum; $VER carries the locked
# version; amiga/sources.txt is exactly the Allegro 5 sources of the game's
# source/Makefile.am (HOH_SRC=<checkout>), and patches/ still apply.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/hoh.lock"
for c in "$HOH_COMMIT" "$ALLEGRO_COMMIT"; do echo "$c" | grep -Eqx '[0-9a-f]{40}' || { echo "FAIL commit $c"; exit 1; }; done
echo "$TINYXML2_SHA256" | grep -Eqx '[0-9a-f]{64}' || { echo "FAIL tinyxml2 sum"; exit 1; }
grep -q "HeadOverHeels $HOH_VERSION " "$HERE/amiga/amiga_start.c" || { echo "FAIL \$VER"; exit 1; }
grep -q "HeadOverHeels \$HOH_VERSION (17.11.2026) GFOS" "$HERE/build-amiga.sh" || { echo "FAIL \$VER check"; exit 1; }
n=$(wc -l < "$HERE/amiga/sources.txt")
[ "$n" -ge 100 ] || { echo "FAIL sources.txt has $n lines"; exit 1; }
[ "$(sort "$HERE/amiga/sources.txt" | uniq -d)" = "" ] || { echo "FAIL duplicate sources"; exit 1; }
if grep -Eq 'loadpng|alogg|/algif/' "$HERE/amiga/sources.txt"; then echo "FAIL Allegro 4 sources"; exit 1; fi
if [ -n "${HOH_SRC:-}" ]; then
    M="$HOH_SRC/source/Makefile.am"
    up=$({ sed -n '/^headoverheels_SOURCES = /,/^$/p' "$M"; sed -n '/^if USE_ALLEGRO5/,/^else/p' "$M"; } \
        | grep -oE '[A-Za-z0-9_/]+\.(cpp|c)\b' | sort)
    [ "$(sort "$HERE/amiga/sources.txt")" = "$up" ] || { echo "FAIL sources differ from Makefile.am"; exit 1; }
    while read -r f; do [ -f "$HOH_SRC/source/$f" ] || { echo "FAIL missing $f"; exit 1; }; done < "$HERE/amiga/sources.txt"
    echo "$TINYXML2_SHA256  $HOH_SRC/external/tinyxml2/tinyxml2-11.0.0.tar.gz" | sha256sum -c - >/dev/null || { echo "FAIL tinyxml2 tarball"; exit 1; }
    for p in "$HERE"/patches/*.patch; do [ -f "$p" ] || continue; (patch -s --batch --forward --dry-run -d "$HOH_SRC" -p1 < "$p" 2>/dev/null || patch -s --batch -R --dry-run -d "$HOH_SRC" -p1 < "$p" 2>/dev/null) || { echo "FAIL $p"; exit 1; }; done
fi
echo "test_lock: pass"
