# Cubicum N

A small operating system that lives in a 7 x 7 x 7 cube. It is written in Oberon-07 and
compiled to native ARM64 code on the phone itself (OLL + Byz7), and it runs on Android today.

**Page:** https://ion-pion.github.io/cubicum-n/

## What is here

| Folder | What |
|---|---|
| `src/` | the Oberon modules of Cubicum N 17 |
| `window/ecran-cubn16.dex` | the thin Java window under it (GL drawing, sound, clipboard, the host's apps) |
| `apk/CubicumN17.apk` | the app, ready to install on an ARM64 Android phone |
| `index.html` | the page |

## Build it on the phone (Byz7)

```
sh cp window/ecran-cubn16.dex $EULA_UNELTE/ecran.dex
ollapk Motor2.Mod OllGL4.Mod OllGL6.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda3.Mod Shell12.Mod Desk4.Mod Files3.Mod Boot3.Mod CubN17.Mod CubicumN.Mod "Cubicum N"
```

The main modules: `CubN17` (the system), `Desk4` (desktop, APPS, SETTINGS), `Files3` (FILES with the
Cubicum FS cube), `Boot3` (the boot screen), `Gazda3` (the host: Android, or nothing on bare metal),
`Shell12` (the shell), `Arch1` + `Spatiu` (Z7 Arch), `Synth9` (Synth Z7), `Tor11` + `Sal4` (Tor7 and Salamandra).

Ion Paraschiv (Pion) - Jahbalon Research, Iasi - with Claude - 2026. E pur si torque.
