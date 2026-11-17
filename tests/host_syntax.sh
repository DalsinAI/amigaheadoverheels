#!/bin/sh
# Compiles every source of amiga/sources.txt with the host compiler
# (-fsyntax-only, the language, define and include flags build-amiga.sh
# uses) against host Allegro 5 headers and the game's tinyxml2 tarball.
# Skips without host Allegro 5.
#   HOH_SRC=<checkout of the game> sh tests/host_syntax.sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
[ -n "${HOH_SRC:-}" ] || { echo "host_syntax: skip (no HOH_SRC)"; exit 0; }
[ -f /usr/include/allegro5/allegro.h ] || { echo "host_syntax: skip (no host Allegro 5)"; exit 0; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
tar xzf "$HOH_SRC/external/tinyxml2/tinyxml2-11.0.0.tar.gz" -C "$T" --strip-components 1
S="$HOH_SRC/source"
INC="-I$S -I$S/activities -I$S/behaviors -I$S/gui -I$S/guiactions -I$T"
printf '#define USE_ALLEGRO5 1\n#define PACKAGE_VERSION "1.4dev"\n#define BinDirFromConfigure "PROGDIR:"\n#define DataDirFromConfigure "PROGDIR:Data"\n' > "$T/defs.h"
DEFS="-include $T/defs.h"
fails=0
while read -r f; do
    case "$f" in
        *.c) gcc -std=gnu17 -fsyntax-only $DEFS $INC "$S/$f" ;;
        *) g++ -std=gnu++17 -fsyntax-only $DEFS $INC "$S/$f" ;;
    esac 2> "$T/err" || { fails=$((fails + 1)); echo "FAIL $f"; grep -m3 error "$T/err"; }
done < "$HERE/amiga/sources.txt"
g++ -std=gnu++17 -fsyntax-only "$T/tinyxml2.cpp" || fails=$((fails + 1))
[ $fails -eq 0 ] || { echo "host_syntax: $fails failed"; exit 1; }
echo "host_syntax: pass ($(( $(wc -l < "$HERE/amiga/sources.txt") + 1 )) sources)"
