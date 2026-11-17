#!/bin/sh
# Unit test for scripts/write-part.sh on a fake part drawer.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D="$T/Games/HeadOverHeels"; mkdir -p "$D/Data/headoverheels/map" "$D/Data/headoverheels/music"
for f in HeadOverHeels HeadOverHeels.info ReadMe Data/headoverheels/items.xml \
         Data/headoverheels/map/blacktooth1.xml Data/headoverheels/music/begin.ogg; do : > "$D/$f"; done
: > "$T/Games/HeadOverHeels.info"
sh "$HERE/scripts/write-part.sh" "$T" 1.4dev
fail() { echo "FAIL: $*"; cat "$T/Part"; exit 1; }
[ "$(sed -n 1p "$T/Part")" = "part HeadOverHeels 1.4dev" ] || fail header
grep -qx 'needs 68040' "$T/Part" || fail needs
grep -qx 'copy "Games/HeadOverHeels/HeadOverHeels" "SYS:Games/HeadOverHeels/HeadOverHeels"' "$T/Part" || fail program
grep -qx 'default "Games/HeadOverHeels/HeadOverHeels.info" "SYS:Games/HeadOverHeels/HeadOverHeels.info"' "$T/Part" || fail icon
grep -qx 'default "Games/HeadOverHeels.info" "SYS:Games/HeadOverHeels.info"' "$T/Part" || fail drawer
grep -qx 'copy "Games/HeadOverHeels/Data/headoverheels/map/blacktooth1.xml" "SYS:Games/HeadOverHeels/Data/headoverheels/map/blacktooth1.xml"' "$T/Part" || fail map
[ "$(grep -c '^copy\|^default' "$T/Part")" = 7 ] || fail count
echo "test-part: pass"
