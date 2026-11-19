MODULE CubN17;  (* CUBICUM N 17 (19 Nov 2026): the APPS header no longer disappears with many apps (OllGL6, Desk4), and
     the apps of the host load during the boot, the icons a little each frame (Gazda3). Same window: ecran-cubn16.dex.
       sh cp /sdcard/Download/OllGL6.Mod /sdcard/Download/Gazda3.Mod /sdcard/Download/Shell12.Mod /sdcard/Download/Desk4.Mod /sdcard/Download/Files3.Mod /sdcard/Download/Boot3.Mod /sdcard/Download/CubN17.Mod .
       sh echo "MODULE CubicumN; IMPORT CubN17; END CubicumN." > CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod OllGL6.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda3.Mod Shell12.Mod Desk4.Mod Files3.Mod Boot3.Mod CubN17.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 16 (19 Nov 2026): sharper icons of the host (32 x 32), BYZ7 that opens, a sweep over the synth
     at boot instead of the beeps. Pion: "the Android icons look like the 80s, Byz7 did not open, the beeps are short and shrill".
     Needs the window ecran-cubn16.dex (it sends the icons at 32 x 32):
       sh cp /sdcard/Download/ecran-cubn16.dex $EULA_UNELTE/ecran.dex
       sh cp /sdcard/Download/Gazda2.Mod /sdcard/Download/Shell11.Mod /sdcard/Download/Desk3.Mod /sdcard/Download/Files2.Mod /sdcard/Download/Boot2.Mod /sdcard/Download/CubN16.Mod .
       cp /sdcard/Download/CubicumN16.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod OllGL5.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda2.Mod Shell11.Mod Desk3.Mod Files2.Mod Boot2.Mod CubN16.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 15 (19 Nov 2026): a boot screen like Cubicum OS had (Boot1), FILES and SETTINGS (Files1, Desk2).
     Pion: "do what you said is still missing. The boot screen, the one of Cubicum OS was nice."
     Dock: SYNTH . PLAYER . SHELL . FILES . APPS; the status bar (or SETTINGS in APPS) opens the settings.
     Same window as 14 (ecran-cubn14.dex):
       sh cp /sdcard/Download/Desk2.Mod /sdcard/Download/Files1.Mod /sdcard/Download/Boot1.Mod /sdcard/Download/CubN15.Mod .
       cp /sdcard/Download/CubicumN15.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod OllGL5.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda1.Mod Shell10.Mod Desk2.Mod Files1.Mod Boot1.Mod CubN15.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 14 (19 Nov 2026): a desktop like a real operating system, and the apps of the system under it.
     Pion: "Cubicum N should see its own apps and those of the system it sits on: it can run bare metal and hosted.
     We already have Crisalida. And I want Cubicum N to look like a professional operating system (even if it is a game)."
     Home: the status bar (clock, host, battery), a big clock, the cube, a card (files, Tor7, synth) and the dock
     SYNTH . PLAYER . SHELL . APPS (Desk1). APPS: three tabs, CUBICUM N (its programs, INSTALL = Crisalida, BYZ7, the
     programs in the cube: tap one and it runs), JAHBALON and ANDROID (the host's apps, with their icons: tap = open).
     The host is Gazda1; with no host (bare metal) Cubicum N shows only its own apps. The shell has APPS and OPEN NAME.
     Needs the window ecran-gl4.dex (it lists and opens the phone's apps; everything else as ecran-gl3-sunet4.dex):
       sh cp /sdcard/Download/ecran-gl4.dex $EULA_UNELTE/ecran.dex
       cp /sdcard/Download/CubicumN14.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod OllGL5.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Gazda1.Mod Shell10.Mod Desk1.Mod CubN14.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 13 (19 Nov 2026): Z7 Arch inside (Pion: "put Z7 Arch in Cubicum N"):
     the shell has ARCH (Shell9 + Arch1, with Spatiu for images, sound and video). Same window as 12.
       cp /sdcard/Download/CubicumN13.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Spatiu.Mod Arch1.Mod Shell9.Mod CubN13.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 12 (11 Nov 2026): all three (Pion: "all three, one at a time, but all at once is fine too"):
     Oberon gets RECORD, CASE and Sound (Ob2, Scr2, Sal4), Cubicum FS gets its 7 dimensions (Fs2: name, type, day,
     folder, size, month, hour), and a first game written in Cubicum N itself (catch.mod). The window ecran-gl3-sunet4.dex
     gives the date (clock.txt) besides GL, sound and the clipboard.
       sh cp /sdcard/Download/ecran-gl3-sunet4.dex $EULA_UNELTE/ecran.dex
       cp /sdcard/Download/CubicumN12.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs2.Mod Clip2.Mod Edit4.Mod Tor11.Mod Ob2.Mod Scr2.Mod Sal4.Mod Shell8.Mod CubN12.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 11 (11 Nov 2026): copy and paste like on a phone: hold the finger on the command line of the shell
     or on the text of the editor, and a menu comes (Shell7, Edit3). The clipboard is the phone's and Cubicum N's own (Clip2).
       cp /sdcard/Download/CubicumN11.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Clip2.Mod Edit3.Mod Tor11.Mod Ob1.Mod Scr1.Mod Sal3.Mod Shell7.Mod CubN11.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 10 (11 Nov 2026): Oberon knows the touch screen (Pion: "it seems Oberon does not know the
     touch screen"). Screen and Touch live in the 11th dimension (Scr1); Ob1 compiles them, Salamandra 3 runs them, and the
     new scene CANVAS shows what the program draws (X in the corner goes back to the shell).
       cp /sdcard/Download/CubicumN10.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Clip1.Mod Edit2.Mod Tor11.Mod Ob1.Mod Scr1.Mod Sal3.Mod Shell6.Mod CubN10.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 9 (11 Nov 2026): copy and paste, in the shell and in the editor (Clip1, Shell5, Edit2), through
     the phone's clipboard. Needs the window ecran-gl3-sunet3.dex in unelte (GL, sound and the clipboard).
       sh cp /sdcard/Download/ecran-gl3-sunet3.dex $EULA_UNELTE/ecran.dex
       cp /sdcard/Download/CubicumN9.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Clip1.Mod Edit2.Mod Tor11.Mod Ob0.Mod Sal2.Mod Shell5.Mod CubN9.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 8 (11 Nov 2026): Oberon on Tor7. The shell compiles .mod files with Ob0 (Oberon-0 for Tor7)
     and Salamandra 2 runs them on the torus: RUN fib, ASM fib.mod. The same programs compile with OLL too.
       cp /sdcard/Download/CubicumN8.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Edit1.Mod Tor11.Mod Ob0.Mod Sal2.Mod Shell4.Mod CubN8.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 7 (11 Nov 2026): the Tor7 processor in 11 dimensions (Tor11 + Salamandra 1), run from the shell:
     RUN primes, PS, KILL, ASH, TOR. The processes run in every frame, wherever you are (letter TOR7).
     At home, the turns of the spiral that hold a running program are shown under the cube.
       cp /sdcard/Download/CubicumN7.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Edit1.Mod Tor11.Mod Sal2.Mod Shell4.Mod CubN7.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 6 (11 Nov 2026): files and Cubicum FS. The shell (Shell2) has LS, CAT, EDIT, RM, WHERE, CELL
     and a text editor (Edit1); every file lives in a cell of the cube (Fs1). At home, the cells that hold a file
     glow gold and are bigger.
       cp /sdcard/Download/CubicumN6.Mod CubicumN.Mod
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Text1.Mod Keys1.Mod Fs1.Mod Edit1.Mod Shell4.Mod CubN6.Mod CubicumN.Mod "Cubicum N"
   CUBICUM N 5 (11 Nov 2026): piece 3, the SHELL, and everything on screen in English
     (Pion: "let's move to the shell, but I want everything in English").
     Home: the Z7 cube (drag it to turn it) and three programs: SYNTH, PLAYER, SHELL.
     The sound flows in every frame, wherever you are.
     Built through CubicumN.Mod, which keeps the app name fixed so the saves stay between versions:
       ollapk Motor2.Mod OllGL4.Mod Synth9.Mod Shell4.Mod CubN5.Mod CubicumN.Mod "Cubicum N"
     Needs the window ecran-gl3-sunet2.dex (GL and streaming sound).
   Earlier: Cubicum N 4 (player), N 3 (no noise on the SOUND tab), N 2 (cube turns both ways), N 1 (cube + synth).
     Pion & Claude, 11.11.2026 *)

  IMPORT Math, Motor2, OllGL6, Grafica, Synth9, Shell12, Fs2, Sal4, Scr2, Gazda3, Desk4, Files3, Boot3;

  CONST
    HOME = 0; SYNTH = 1; PLAYER = 2; SHELL = 3; CANVAS = 4; APPS = 5; FILES = 6; SETTINGS = 7; BOOT = 8;   (* scenes = programs *)
    OPEN = 8;                                     (* event of the home buttons: val = the program's scene *)
    RANDURI = 20;                                 (* the bottom rows of the screen carry the sound *)

  VAR hold, bootFirst: BOOLEAN; lFiles, lSet, lBoot, lApps, lCanvas, lTor, lP1, lCore, lSynth, lPlayer, lShell, lP2, W, H, bw: INTEGER; started: BOOLEAN; angle, tilt: REAL;
    bg, gold, white, grey, green, panel: INTEGER;

  PROCEDURE Pump(ev, val: INTEGER);   (* the sound, at the start and at the end of every frame *)
  BEGIN IF started THEN Synth9.Sunet END
  END Pump;

  PROCEDURE Tor(ev, val: INTEGER);   (* the Tor7 processes and their lines, in every frame *)
  BEGIN
    IF started THEN
      IF Sal4.Busy() THEN Sal4.Run(20000) END;
      Shell12.Pull; Gazda3.Poll
    END
  END Tor;

  PROCEDURE Centre(cx, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
    VAR n: INTEGER;
  BEGIN
    n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
    OllGL6.Text2D(cx - n * 3 * m, y, s, m, c)
  END Centre;

  PROCEDURE Open(scene: INTEGER);
  BEGIN
    IF scene = PLAYER THEN Synth9.IntraPlayer ELSIF scene = SHELL THEN Shell12.Enter
    ELSIF (scene = APPS) OR (scene = HOME) OR (scene = SETTINGS) THEN Desk4.Enter ELSIF scene = CANVAS THEN hold := TRUE
    ELSIF scene = FILES THEN Files3.Enter ELSIF scene = BOOT THEN Boot3.Start(W, H)
    END;
    Motor2.SchimbaScena(scene)
  END Open;

  PROCEDURE Act(r: INTEGER);   (* the actions of the desk: -1 HOME, 1 SYNTH, 2 PLAYER, 3 SHELL, 4 APPS, 5 CANVAS,
                                   6 FILES, 7 SETTINGS, 8 BOOT *)
  BEGIN
    IF r = -1 THEN Open(HOME) ELSIF r = 4 THEN Open(APPS) ELSIF r = 5 THEN Open(CANVAS) ELSIF r = 6 THEN Open(FILES)
    ELSIF r = 7 THEN Open(SETTINGS) ELSIF r = 8 THEN Open(BOOT) ELSIF (r >= 1) & (r <= 3) THEN Open(r)
    END
  END Act;

  PROCEDURE Home;   (* the desktop: the cube under the clock, the card, the dock *)
    VAR x, y, z, l, r, cy: INTEGER; rr: REAL;
  BEGIN
    IF bootFirst THEN bootFirst := FALSE; IF Desk4.BootOn() THEN Open(BOOT) END END;
    OllGL6.Incepe(bg);
    IF ~Motor2.Jos() & Desk4.Spin() THEN angle := angle + Motor2.Pas() * 0.005 END;   (* turns by itself only when you do not hold it *)
    rr := 29.0 * Math.cos(tilt);
    OllGL6.Camera(rr * Math.cos(angle), 29.0 * Math.sin(tilt), rr * Math.sin(angle), 0.0, -0.6, 0.0, 50.0);
    OllGL6.Lumina(0.5);
    FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
      IF Fs2.At(x, y, z) >= 0 THEN OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.62, Desk4.Accent())   (* a file lives here *)
      ELSE OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.34, OllGL6.RGB(30 + x * 18, 30 + y * 18, 50 + z * 18))
      END
    END END END;
    r := Desk4.Home(Motor2.Jos(), Motor2.X(), Motor2.Y());
    cy := H - 268; Desk4.Card(cy, 88);   (* the card: what Cubicum N is doing *)
    OllGL6.Text2D(44, cy + 16, "CUBICUM N 17", 2, Desk4.Accent());
    IF Desk4.ShowFps() THEN OllGL6.Numar2D(W - 120, cy + 16, Motor2.Fps(), 2, grey); OllGL6.Text2D(W - 84, cy + 16, "FPS", 2, grey) END;
    l := Synth9.Locul();
    IF l > 0 THEN OllGL6.Text2D(44, cy + 54, "PLAYING SLOT", 2, green); OllGL6.Numar2D(44 + 13 * 12, cy + 54, l, 2, green)
    ELSIF Synth9.Canta() THEN OllGL6.Text2D(44, cy + 54, "THE SYNTH PLAYS", 2, green)
    ELSE OllGL6.Numar2D(44, cy + 54, Fs2.Count(), 2, white); OllGL6.Text2D(44 + 4 * 12, cy + 54, "FILES", 2, grey)
    END;
    OllGL6.Text2D(W - 270, cy + 54, "TOR7", 2, grey);
    FOR l := 0 TO 6 DO   (* the 7 turns of the spiral: gold = a program runs there *)
      IF Sal4.StateOf(l) # Sal4.Free THEN OllGL6.Rotund2D(W - 214 + l * 24, cy + 52, 18, 18, 4, Desk4.Accent())
      ELSE OllGL6.Rotund2D(W - 214 + l * 24, cy + 52, 18, 18, 4, panel)
      END
    END;
    OllGL6.Arata; Motor2.Arat;
    IF r # 0 THEN Act(r) END
  END Home;

  PROCEDURE Core(ev, val: INTEGER);
  BEGIN
    IF ev = Motor2.Scena THEN
      IF started THEN Fs2.Sync; Desk4.Enter END;   (* back home: the synth may have saved a song *)
      IF ~started THEN   (* first frame: now the window exists *)
        started := TRUE; W := Motor2.Latime(); H := Motor2.Inaltime() - RANDURI;
        OllGL6.Rezerva(RANDURI); Synth9.Porneste; Shell12.Start; Scr2.Size(W, H); bw := (W - 60) DIV 3;
        Desk4.Start(W, H); Files3.Start(W, H); bootFirst := TRUE
      END
    ELSIF ev = OPEN THEN Open(val)
    ELSIF ev = Motor2.Trage THEN
      angle := angle + FLT(Motor2.DX()) * 0.012; tilt := tilt + FLT(Motor2.DY()) * 0.008;
      IF tilt > 1.3 THEN tilt := 1.3 ELSIF tilt < -1.3 THEN tilt := -1.3 END
    ELSIF ev = Motor2.Tick THEN Home
    END
  END Core;

  PROCEDURE Apps(ev, val: INTEGER);   (* the drawer: own programs, the tools, the host's apps *)
    VAR r: INTEGER; nm: ARRAY 40 OF CHAR; cmd: ARRAY 48 OF CHAR; i, j: INTEGER;
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      r := Desk4.Drawer(Motor2.Jos(), Motor2.X(), Motor2.Y()); Motor2.Arat;
      IF (r # 0) & (r # 10) THEN Act(r)
      ELSIF r = 10 THEN   (* a program of the cube: RUN it in the shell, and the shell shows what it says *)
        Desk4.Chosen(nm); cmd := "run "; i := 4; j := 0;
        WHILE (nm[j] # 0X) & (i < LEN(cmd) - 1) DO cmd[i] := nm[j]; INC(i); INC(j) END; cmd[i] := 0X;
        r := Shell12.Do(cmd); Open(SHELL)
      END
    END
  END Apps;

  PROCEDURE FilesScene(ev, val: INTEGER);
    VAR r: INTEGER;
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      r := Files3.Frame(Motor2.Jos(), Motor2.X(), Motor2.Y()); Motor2.Arat;
      IF r = 3 THEN Open(SHELL) ELSIF r # 0 THEN Act(r) END
    END
  END FilesScene;

  PROCEDURE SetScene(ev, val: INTEGER);
    VAR r: INTEGER;
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      r := Desk4.Settings(Motor2.Jos(), Motor2.X(), Motor2.Y()); Motor2.Arat;
      IF r # 0 THEN Act(r) END
    END
  END SetScene;

  PROCEDURE BootScene(ev, val: INTEGER);
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      IF Boot3.Frame(Motor2.Jos()) THEN Motor2.Arat; Open(HOME) ELSE Motor2.Arat END
    END
  END BootScene;

  PROCEDURE Synth(ev, val: INTEGER);
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      IF Synth9.Cadru(Motor2.Jos(), Motor2.X(), Motor2.Y()) THEN Motor2.SchimbaScena(HOME) END
    END
  END Synth;

  PROCEDURE Player(ev, val: INTEGER);
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      IF Synth9.Player(Motor2.Jos(), Motor2.X(), Motor2.Y()) THEN Motor2.SchimbaScena(HOME) END
    END
  END Player;

  PROCEDURE Canvas(ev, val: INTEGER);   (* what the Tor7 programs draw; their finger *)
    VAR x, y: INTEGER; inX: BOOLEAN;
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      x := Motor2.X(); y := Motor2.Y(); inX := (x >= W - 64) & (y < 52);
      IF hold & ~Motor2.Jos() THEN hold := FALSE END;
      Scr2.Touch(Motor2.Jos() & ~inX & ~hold, x, y);
      Scr2.Draw(bg);
      Grafica.Dreptunghi(W - 58, 6, 52, 40, panel); Grafica.Text(W - 38, 18, "X", 2, Grafica.RGB(239, 68, 68));
      IF Motor2.Jos() & inX THEN Motor2.SchimbaScena(SHELL) END
    END
  END Canvas;

  PROCEDURE Shell(ev, val: INTEGER);
    VAR r: INTEGER;
  BEGIN
    IF (ev = Motor2.Tick) & started THEN
      r := Shell12.Frame(Motor2.Jos(), Motor2.X(), Motor2.Y());
      IF r = -1 THEN Open(HOME) ELSIF r = 1 THEN Open(SYNTH) ELSIF r = 2 THEN Open(PLAYER)
      ELSIF (r = 3) OR Scr2.Fresh() THEN hold := TRUE; Motor2.SchimbaScena(CANVAS)   (* the finger on ENTER is not a touch *)
      END
    END
  END Shell;

BEGIN
  hold := FALSE; bootFirst := FALSE; started := FALSE; angle := 0.6; tilt := 0.39; W := 1; H := 1; bw := 150;
  bg := OllGL6.RGB(14, 4, 28); gold := OllGL6.RGB(212, 160, 23); white := OllGL6.RGB(240, 235, 250);
  grey := OllGL6.RGB(140, 130, 160); green := OllGL6.RGB(74, 222, 128); panel := OllGL6.RGB(52, 22, 86);
  Motor2.AutoPauza(FALSE);
  lP1 := Motor2.Litera("SOUND1", Pump, {Motor2.Tick});
  lTor := Motor2.Litera("TOR7", Tor, {Motor2.Tick});
  lCore := Motor2.Litera("CORE", Core, {Motor2.Tick, Motor2.Scena, Motor2.Trage, OPEN});
  Motor2.InScene(lCore, {HOME});
  lSynth := Motor2.Litera("SYNTH", Synth, {Motor2.Tick}); Motor2.InScene(lSynth, {SYNTH});
  lPlayer := Motor2.Litera("PLAYER", Player, {Motor2.Tick}); Motor2.InScene(lPlayer, {PLAYER});
  lShell := Motor2.Litera("SHELL", Shell, {Motor2.Tick}); Motor2.InScene(lShell, {SHELL});
  lCanvas := Motor2.Litera("CANVAS", Canvas, {Motor2.Tick}); Motor2.InScene(lCanvas, {CANVAS});
  lApps := Motor2.Litera("APPS", Apps, {Motor2.Tick}); Motor2.InScene(lApps, {APPS});
  lFiles := Motor2.Litera("FILES", FilesScene, {Motor2.Tick}); Motor2.InScene(lFiles, {FILES});
  lSet := Motor2.Litera("SETTINGS", SetScene, {Motor2.Tick}); Motor2.InScene(lSet, {SETTINGS});
  lBoot := Motor2.Litera("BOOT", BootScene, {Motor2.Tick}); Motor2.InScene(lBoot, {BOOT});
  lP2 := Motor2.Litera("SOUND2", Pump, {Motor2.Tick});
  Motor2.Ruleaza
END CubN17.
