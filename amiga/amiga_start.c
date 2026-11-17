/* Head over Heels on GFOS: version string and stack. The game finds its
 * data under PROGDIR:Data/headoverheels/ (DataDirFromConfigure in
 * build-amiga.sh), so it starts the same from a Shell or from its icon.
 * GPL-3.0, like the game. Copyright (c) 2026 AmiCradle Team. */
unsigned long __stack = 512 * 1024;
const char gfos_version[] = "$VER: HeadOverHeels 1.4dev (17.11.2026) GFOS 68040";
