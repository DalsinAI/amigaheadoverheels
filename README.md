# Head over Heels for GFOS

Head over Heels, Douglas Mencken's free remake of the 1987 isometric
adventure (https://github.com/dougmencken/HeadOverHeels, 1.4dev), built for
GFOS (AmigaOS 3.2.3 with GFOpenUp, 68040) on amigaallegro: Allegro 5 over
SDL2.module, GL.module and OpenGPU, with Ogg Vorbis for the music.

## Build

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

The game, amigaallegro, ogg and vorbis are fetched at the commits in
`hoh.lock`; nothing third-party is kept in this repository. tinyxml2 11.0.0
comes from the game's own `external/` tarball, checked against the sum in
`hoh.lock`. Allegro and the game's objects are kept between runs, so a run
that ends out of time says so and the next run goes on.

The part is `out/Parts/HeadOverHeels`:

    GFOpenUpTool INSTALL Parts/HeadOverHeels

installs `SYS:Games/HeadOverHeels/` with the game data under
`Data/headoverheels/`. The game finds its data through `PROGDIR:`, so it
starts the same from its icon or from a Shell.

## Tests

    sh tests/test_host.sh
    HOH_SRC=<checkout of the game> sh tests/test_lock.sh

`test_lock.sh` checks the pins, the `$VER` string and that
`amiga/sources.txt` is exactly the Allegro 5 source list of the game's
`source/Makefile.am`. `test-part.sh` checks the GFOpenUp Part writer.

## Rights

The game code is GPL-3.0 (LICENSE). The game data (graphics, music, sounds,
maps) comes from the remake's repository; its rights need a review before
this part ships in a release.

## Licence

The Amiga build files here are GPL-3.0, like the game.
Copyright (c) 2026 AmiCradle Team.
Designed, tested and delivered by The AmiCradle Team.
