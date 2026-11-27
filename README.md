# Pixipogo (Cubicum N)

A small operating system that lives in a 7 x 7 x 7 cube. It is written in Oberon-07 and
compiled to native ARM64 code on the phone itself (OLL + Byz7), and it runs on Android today.
Cubicum N was its first name; since version 44 it is called Pixipogo.

**Page:** https://ion-pion.github.io/cubicum-n/

## What is here

| Folder | What |
|---|---|
| `src/` | the Oberon modules of Pixipogo 52 |
| `window/ecran-cubn49.dex` | the thin Java window under it (GL drawing, sound, clipboard, the host's apps) |
| `cartridges/` | games and programs for Pixipogo's own Oberon (Tor7), run from the Shell or THE COURT |
| `index.html` | the page |

## Build it on the phone (Byz7)

```
sh cp -f window/ecran-cubn49.dex $EULA_UNELTE/ecran.dex
OLL2.Apk Motor2.Mod OllGL4.Mod OllGL7.Mod OllGL6t.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda4.Mod Shell13.Mod Desk6.Mod Zane4.Mod Juno1.Mod Quince1.Mod Ceres1.Mod Files14.Mod Boot5.Mod Pic6.Mod Filme1.Mod Nora18.Mod Herne1.Mod CubN52.Mod CubicumN.Mod "Pixipogo"
```

The main modules: `CubN52` (the system), `Desk6` (desktop, APPS, SETTINGS), `Files14` (Cobweb, the file cube),
`Boot5` (the boot screen), `Gazda4` (the host: Android, or nothing on bare metal), `Shell13` (the shell),
`Nora18` (Nora, the web fairy), `Arch1` + `Spatiu` (Z7 Arch), `Synth9` (Synth Z7), `Pic6` and `Filme1` (pictures, films),
`Zane4`, `Juno1`, `Quince1`, `Ceres1` (the helpers), `Herne1` (a game in THE COURT),
`Tor11` + `Sal4` (Tor7, the processor of the cube, and Salamandra, its kernel), `Ob2` (Oberon for Tor7),
`Scr2` (the canvas of the cartridges: 2D, tilt, music, 3D). `CubN51` is kept beside `CubN52` to go back one version.

## Cartridges: games without updating Pixipogo

A cartridge is a plain `.mod` file in Oberon. Put it in Download, import it in Cobweb (IMPORT), then
tap it in THE COURT or type `run name` in the Shell. Pixipogo compiles it for Tor7 on the spot.
It can use `Screen`, `Touch`, `Sound`, `Tor`, `Out` and, since 52, `Space` (3D on the graphics card),
the tilt of the phone (`Touch.TiltX`, `Touch.TiltY`, `Touch.Level`) and music that Pixipogo plays by itself
(`Sound.Seq`, `Sound.Tempo`, `Sound.Loop`). The kernel says the room on RUN, for example
`herne3.mod ON TURN 1, 15532 INSTRUCTIONS OF 23483`: since Pixipogo 51 a cartridge has room for about
27000 instructions (before, 8000). `END` in a game quits it; the X of the canvas only hides it (`screen` brings it back,
`ps` and `kill N` show and stop the 7 turns).

| Cartridge | What |
|---|---|
| `tubul2.mod` | the tube in 3D: tilt to steer, red gates with a hole, gems that are notes, music (Pixipogo 52) |
| `herne3.mod` | Herne, the boar hunt, turn by turn: a river, dogs that follow your tracks, bowmen that hear you (Pixipogo 51) |
| `herne2.mod` | the smaller Herne (runs on Pixipogo 50 too) |
| `tubul1.mod` | the tube in 2D, whole numbers only (Pixipogo 51) |
| `catch.mod`, `bounce.mod`, `touch.mod` | the examples of the Shell |

## Versions

- **52** (25 Nov 2026): the hardware for the cartridges, through Pixipogo itself: the tilt, a music sequencer of
  2 tracks, and `Space`: camera, fog, light, cubes, balls, triangles and a path of 512 points that Pixipogo bends into
  tubes, rings and walls on the graphics card, with a camera that rides it and turns with the player.
- **51** (25 Nov 2026): room for big cartridges. The globals of a program sit right after its code; two new
  instructions of the kernel (`GLOB`, `DEV`) make Screen/Touch/Sound and the globals 3 times cheaper; a program too long
  gets a clear message instead of falling; cartridges get up to 8 ms of every frame when they want it.
- **50**: Herne in THE COURT. **44**: Cubicum N becomes Pixipogo. **17**: the first version on GitHub.

Ion Paraschiv (Pion) - Jahbalon Research, Iasi - with Claude - 2026. E pur si torque.
