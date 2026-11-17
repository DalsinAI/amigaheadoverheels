#!/bin/sh
# Builds Head over Heels (dougmencken's remake, 1.4dev) for GFOS (AmigaOS
# 3.2.3 with GFOpenUp) with a stove, on amigaallegro (Allegro 5 over
# SDL2.module, GL.module and OpenGPU), with Ogg Vorbis for its music:
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# The game and amigaallegro are fetched at what hoh.lock gives; nothing
# third-party is kept here. tinyxml2 comes from the game's own external/
# tarball, checked against hoh.lock. Allegro is built once and kept; a run
# that ends out of time says so, and the next run goes on (objects too).
# OUT gets Parts/HeadOverHeels, a GFOpenUp part:
#   GFOpenUpTool INSTALL Parts/HeadOverHeels  -> SYS:Games/HeadOverHeels/
# GPL-3.0, like the game. Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/hoh.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
WORK="${WORK:-$HOME/.cache/amigaheadoverheels/build}"; OUT="${OUT:-$WORK/out}"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 4)}; export JOBS
BUDGET_TOTAL=${BUDGET_TOTAL:-840}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)
left() { echo $(( BUDGET_TOTAL - ( $(date +%s) - t0 ) )); }
m68k-amigaos-gcc --version | head -n 1

# --- amigaallegro with Ogg Vorbis (kept between runs) ------------------------------
set +e
ALLEGRO_BUDGET=$(( BUDGET_TOTAL - 60 )) sh "$HERE/scripts/build-allegro.sh" "$STOVE" "$WORK" "$ALLEGRO_GIT" "$ALLEGRO_COMMIT" > "$WORK/allegro.out"
rc=$?
set -e
[ $rc -eq 3 ] && { echo "out of time in allegro, run again to go on"; exit 0; }
[ $rc -eq 0 ] || { tail -20 "$WORK/allegro.out"; exit $rc; }
PFX=$(tail -n 1 "$WORK/allegro.out"); VP="$WORK/vorbis-prefix"
echo "allegro: $PFX ($(( $(date +%s) - t0 )) s)"

# --- the game at its pinned commit, with patches/ -------------------------------------
SRC="$WORK/headoverheels"
PSUM=$(cat "$HERE"/patches/*.patch 2>/dev/null | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$HOH_COMMIT-$PSUM" ]; then
    rm -rf "$SRC" "$WORK/obj"; mkdir -p "$SRC"; git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$HOH_GIT" "$HOH_COMMIT"; git -C "$SRC" checkout -q FETCH_HEAD
    for p in "$HERE"/patches/*.patch; do
        [ -f "$p" ] || continue
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$HOH_COMMIT-$PSUM" > "$SRC/.patched"
fi
TX="$WORK/tinyxml2"
if [ ! -f "$TX/tinyxml2.cpp" ]; then
    T="$SRC/external/tinyxml2/tinyxml2-11.0.0.tar.gz"
    echo "$TINYXML2_SHA256  $T" | sha256sum -c - >/dev/null || { echo "tinyxml2 tarball sum"; exit 1; }
    rm -rf "$TX"; mkdir -p "$TX"; tar xzf "$T" -C "$TX" --strip-components 1
fi

# --- compile (objects kept, so a run out of time goes on) and link ---------------------
SYSROOT="$TC/m68k-amigaos"; DEPS="$SYSROOT/port-deps"
ARCH="-mcrt=nix20 -m68040 -m68881 -pthread"
DEFS="-DUSE_ALLEGRO5=1 -DALLEGRO_STATICLINK=1 -D__AMIGAOS3__=1 -DPACKAGE_VERSION=\"$HOH_VERSION\" \
 -DBinDirFromConfigure=\"PROGDIR:\" -DDataDirFromConfigure=\"PROGDIR:Data\""
INC="-I$SRC/source -I$SRC/source/activities -I$SRC/source/behaviors -I$SRC/source/gui -I$SRC/source/guiactions \
 -I$TX -I$PFX/include -I$VP/include -I$SYSROOT/include"
CXXF="$ARCH -std=gnu++17 -O2 -fomit-frame-pointer $DEFS $INC"
CF="$ARCH -std=gnu17 -O2 -fomit-frame-pointer $DEFS $INC"
O="$WORK/obj"; mkdir -p "$O"; export CF CXXF
{ sed "s|^|$SRC/source/|" "$HERE/amiga/sources.txt"; echo "$TX/tinyxml2.cpp"; echo "$HERE/amiga/amiga_start.c"; } > "$WORK/files.txt"
set +e
timeout "$(left)" sh -c '
    while read -r f; do
        o="'"$O"'/$(echo "$f" | sed "s|.*/source/||; s|/|_|g; s|\.[^.]*$|.o|")"
        echo "$f $o"
    done < "'"$WORK"'/files.txt" | xargs -P "$JOBS" -n 2 sh -c '"'"'
        CF="$0"; CXXF="$1"; s="$2"; o="$3"
        [ -f "$o" ] && [ "$o" -nt "$s" ] && exit 0
        case "$s" in
            *.c) m68k-amigaos-gcc $CF -c "$s" -o "$o.tmp" 2> "$o.log" ;;
            *) m68k-amigaos-g++ $CXXF -c "$s" -o "$o.tmp" 2> "$o.log" ;;
        esac || { cat "$o.log"; rm -f "$o.tmp"; exit 1; }
        mv "$o.tmp" "$o"
    '"'"' "$CF" "$CXXF"
'
rc=$?
set -e
[ $rc -eq 124 ] && { echo "out of time compiling ($(ls "$O"/*.o | wc -l) objects kept), run again to go on"; exit 0; }
[ $rc -eq 0 ] || { echo "compile failed"; exit 1; }
n=$(ls "$O"/*.o | wc -l); want=$(wc -l < "$WORK/files.txt")
[ "$n" -eq "$want" ] || { echo "objects $n of $want"; exit 1; }
m68k-amigaos-g++ $ARCH -o "$WORK/HeadOverHeels.debug" "$O"/*.o \
    "$PFX/lib/liballegro_monolith-static.a" "$VP/lib/libvorbisfile.a" "$VP/lib/libvorbis.a" "$VP/lib/libogg.a" \
    "$SYSROOT/lib/libSDL2.a" "$SYSROOT/lib/libGL.a" "$DEPS/lib/libpng.a" "$DEPS/lib/libz.a" -lm -lpthread

# --- the GFOpenUp part: Parts/HeadOverHeels --------------------------------------------------
P="$OUT/Parts/HeadOverHeels"; D="$P/Games/HeadOverHeels"; rm -rf "$P"; mkdir -p "$D/Data"
m68k-amigaos-strip -o "$D/HeadOverHeels" "$WORK/HeadOverHeels.debug"
cp -R "$SRC/gamedata" "$D/Data/headoverheels"
find "$D/Data" \( -name 'Makefile*' -o -name '*.sh' -o -name '*.xpm' \) -exec rm -f {} +
cp "$SRC/LICENSE" "$D/License.txt"; cp "$TX/LICENSE.txt" "$D/License-tinyxml2.txt"; cp "$HERE/README.md" "$D/ReadMe"
cp "$HERE/amiga/icons/HeadOverHeels.info" "$HERE/amiga/icons/ReadMe.info" "$D/"
cp "$HERE/amiga/icons/HeadOverHeels-drawer.info" "$P/Games/HeadOverHeels.info"
sh "$HERE/scripts/write-part.sh" "$P" "$HOH_VERSION"
ls -l "$D/HeadOverHeels"
strings "$D/HeadOverHeels" | grep -q "HeadOverHeels $HOH_VERSION (17.11.2026) GFOS" || { echo "no \$VER"; exit 1; }
echo "part: $(grep -c '^copy\|^default' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
