MODULE Boot5;  (* BOOT 5c (21 Nov 2026, Pixipogo 30): it says PIXIPOGO 30 under the name.
  BOOT 5b (20 Nov 2026, Cubicum N 27): the system is called PIXIPOGO (Pion: "and we have pi, 3.14, in the title"): PI in gold.
  BOOT 5 (20 Nov 2026, Cubicum N 19): the court of Oberon wakes up.
   BOOT 4 (20 Nov 2026, Cubicum N 18): Boot 3 with Desk5 and Gazda4.
   BOOT 3 (19 Nov 2026, Cubicum N 17): Boot 2 with OllGL6, Desk4, Gazda3 (which asks the host for its
     apps while the boot runs).
   BOOT 2 (19 Nov 2026, Cubicum N 16): instead of the short high notes, a sweep over the keys of the synth:
     from the lowest note of the cube up two octaves (1 9/8 5/4 3/2 5/3 2 ...), one note as each part of the cube
     lights up, long and soft, and a low chord at READY (Pion: "the two beeps are short and shrill").
   BOOT 1 (19 Nov 2026, Cubicum N 15): the boot screen, like the one of Cubicum OS (March 2026):
     the void -> the egg -> the Salamandra comes out of it -> the cube lights up from its centre, shell by shell,
     with a note for each shell; the boot log on the left, the 5 clocks (/1 /2 /3 /5 /7) beating, a bar,
     then CUBICUM N 15 . READY. About 4.5 seconds; a tap skips it. SETTINGS can turn it off or show it again.
   Pion & Claude, 19.11.2026 *)

  IMPORT Math, Ceas, OllGL6, Desk6, Gazda4, Fs2, Synth9;

  CONST VOID = 700; EGG = 1500; CUBE = 3700; END0 = 4600; STEP = 360;

  VAR W, H, t0, played, cx, cy, nn: INTEGER; wasDown: BOOLEAN;
    nx, ny, nz: ARRAY 12 OF INTEGER;   (* the sweep: nodes of the cube, low to high *)

  PROCEDURE Len(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END Len;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := Len(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END Add;

  PROCEDURE AddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := Len(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END AddN;

  PROCEDURE Line(k: INTEGER; VAR s: ARRAY OF CHAR);   (* line k of the boot log *)
    VAR h: ARRAY 24 OF CHAR;
  BEGIN
    s[0] := 0X;
    IF k = 0 THEN Add(s, "PIXIPOGO 30 . BUILD Z7")
    ELSIF k = 1 THEN Add(s, ". INITIALIZING Z7 . 343 NODES")
    ELSIF k = 2 THEN Add(s, ". LOADING SALAMANDRA FROM THE EGG")
    ELSIF k = 3 THEN Add(s, ". IGNITING 5 CLOCKS /1 /2 /3 /5 /7")
    ELSIF k = 4 THEN Add(s, ". MOUNTING CUBICUM FS . "); AddN(s, Fs2.Count()); Add(s, " FILES")
    ELSIF k = 5 THEN
      IF Gazda4.Hosted() THEN Add(s, ". HOST FOUND . "); Gazda4.System(h); Add(s, h)
      ELSE Add(s, ". NO HOST . BARE METAL")
      END
    ELSIF k = 6 THEN Add(s, ". WAKING THE FAIRIES . ARIEL . PUCK . ROBIN")
    ELSE Add(s, "READY . PION (JAHBALON) . 2026")
    END
  END Line;

  PROCEDURE Egg(r, c: INTEGER);   (* an egg at the centre, r = its half width *)
    VAR k, x0, y0, x1, y1: INTEGER; u, sy: REAL;
  BEGIN
    x0 := cx + r; y0 := cy;
    FOR k := 1 TO 24 DO
      u := 6.28318530718 * FLT(k) / 24.0;
      IF Math.sin(u) < 0.0 THEN sy := 1.42 ELSE sy := 1.12 END;   (* narrower and higher at the top *)
      x1 := cx + FLOOR(Math.cos(u) * FLT(r) * (1.0 - 0.12 * Math.sin(u)) + 0.5); y1 := cy + FLOOR(Math.sin(u) * FLT(r) * sy + 0.5);
      OllGL6.Triunghi2D(cx, cy, x0, y0, x1, y1, c); x0 := x1; y0 := y1
    END
  END Egg;

  PROCEDURE Salamandra(t: INTEGER);   (* she swims around the cube: a chain of circles, the head first *)
    VAR i, x, y, rad, tt, c: INTEGER; a, rr: REAL;
  BEGIN
    FOR i := 11 TO 0 BY -1 DO
      tt := t - i * 55;
      IF tt > 0 THEN
        rr := FLT(tt) / 700.0; IF rr > 1.0 THEN rr := 1.0 END;
        a := FLT(tt) / 520.0;
        x := cx + FLOOR(Math.cos(a) * 190.0 * rr + Math.sin(a * 5.0) * 10.0 * rr);
        y := cy + FLOOR(Math.sin(a) * 150.0 * rr + Math.cos(a * 5.0) * 10.0 * rr);
        rad := 13 - i; IF rad < 3 THEN rad := 3 END;
        c := OllGL6.RGB(250 - i * 6, 120 - i * 8, 30 + i * 4);
        OllGL6.Cerc2D(x, y, rad, c);
        IF i = 0 THEN OllGL6.Cerc2D(x + 4, y - 3, 2, OllGL6.RGB(20, 0, 0)) END
      END
    END
  END Salamandra;

  PROCEDURE Cube(t: INTEGER);   (* the cells light up shell by shell from the centre *)
    VAR x, y, z, d, e, ad: INTEGER; s, ang: REAL;
  BEGIN
    ang := FLT(t) / 1400.0;
    OllGL6.Camera(29.0 * 0.92 * Math.cos(ang), 11.0, 29.0 * 0.92 * Math.sin(ang), 0.0, -0.6, 0.0, 50.0);
    OllGL6.Lumina(0.5);
    FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
      d := ABS(x - 3); IF ABS(y - 3) > d THEN d := ABS(y - 3) END; IF ABS(z - 3) > d THEN d := ABS(z - 3) END;
      e := t - d * 450;
      IF e > 0 THEN
        s := FLT(e) / 300.0; IF s > 1.0 THEN s := 1.0 END;
        IF d = 0 THEN OllGL6.Cub(0.0, 0.0, 0.0, 0.62 * s, Desk6.Accent())
        ELSE
          ad := x + y + z;
          OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.34 * s, OllGL6.RGB(30 + x * 18, 30 + y * 18, 50 + z * 18 + ad MOD 2 * 6))
        END
      END
    END END END
  END Cube;

  PROCEDURE Clocks(t: INTEGER);   (* the 5 clocks: each flashes on its own beat *)
    VAR k, d, x, beat: INTEGER; s: ARRAY 4 OF CHAR;
  BEGIN
    beat := t DIV 240;
    FOR k := 0 TO 4 DO
      IF k = 0 THEN d := 1 ELSIF k = 1 THEN d := 2 ELSIF k = 2 THEN d := 3 ELSIF k = 3 THEN d := 5 ELSE d := 7 END;
      x := W DIV 2 - 160 + k * 80;
      IF (beat MOD d = 0) & (t MOD 240 < 120) THEN OllGL6.Cerc2D(x, 110, 20, Desk6.Accent())
      ELSE OllGL6.Inel2D(x, 110, 20, 2, Desk6.edge)
      END;
      s[0] := "/"; s[1] := CHR(ORD("0") + d); s[2] := 0X; Desk6.Centre(x, 140, s, 1, Desk6.muted)
    END
  END Clocks;

  PROCEDURE Note(x, y, z, ms: INTEGER);
  BEGIN Synth9.Note(x, y, z, ms)
  END Note;

  PROCEDURE Frame*(isDown: BOOLEAN): BOOLEAN;   (* TRUE = the boot is over *)
    VAR t, k, n, r, w: INTEGER; s: ARRAY 48 OF CHAR; done: BOOLEAN;
  BEGIN
    Gazda4.Poll;
    t := Ceas.Ms() - t0; done := t >= END0;
    IF isDown & ~wasDown & (t > 400) THEN done := TRUE END;
    wasDown := isDown;
    OllGL6.Incepe(OllGL6.RGB(4, 0, 10));
    IF t >= EGG THEN Cube(t - EGG) END;
    (* the sweep: one note every 190 ms while the cube lights up, then a low chord *)
    k := (t - EGG + 100) DIV 190;
    IF (t >= EGG - 100) & (k < nn) & (played <= k) THEN played := k + 1; Note(nx[k], ny[k], nz[k], 1600) END;
    IF (t >= CUBE) & (played < 100) & (nn > 0) THEN
      played := 100; Note(nx[0], ny[0], nz[0], 2600);
      IF nn > 3 THEN Note(nx[3], ny[3], nz[3], 2600) END; IF nn > 5 THEN Note(nx[5], ny[5], nz[5], 2600) END
    END;
    IF t < VOID THEN   (* the void: a point that grows *)
      r := 2 + t DIV 70; OllGL6.Cerc2D(cx, cy, r, Desk6.Accent());
      OllGL6.Inel2D(cx, cy, 10 + t DIV 6, 1, Desk6.edge)
    ELSIF t < EGG THEN   (* the egg, breathing *)
      r := 34 + FLOOR(Math.sin(FLT(t) / 90.0) * 3.0);
      OllGL6.Inel2D(cx, cy, r * 2 + (t - VOID) DIV 20, 2, Desk6.edge);
      Egg(r + 4, Desk6.surface2); Egg(r, Desk6.Accent());
      IF t > EGG - 260 THEN OllGL6.Linie2D(cx - 14, cy - 10, cx + 4, cy + 6, 2, Desk6.dark); OllGL6.Linie2D(cx + 4, cy + 6, cx + 16, cy - 4, 2, Desk6.dark) END
    ELSE Salamandra(t - EGG)
    END;
    IF t >= EGG - 200 THEN Clocks(t) END;
    (* the log *)
    n := (t - 300) DIV STEP + 1; IF n > 8 THEN n := 8 END;
    FOR k := 0 TO n - 1 DO
      Line(k, s);
      IF k = 7 THEN OllGL6.Text2D(24, H - 330 + k * 26, s, 2, Desk6.Accent()) ELSE OllGL6.Text2D(24, H - 330 + k * 26, s, 2, Desk6.muted) END
    END;
    w := (W - 48) * t DIV END0; IF w > W - 48 THEN w := W - 48 END;
    OllGL6.Rotund2D(24, H - 98, W - 48, 10, 5, Desk6.surface); IF w > 10 THEN OllGL6.Rotund2D(24, H - 98, w, 10, 5, Desk6.Accent()) END;
    IF t >= CUBE THEN
      OllGL6.Text2D(W DIV 2 - 144, 190, "PI", 6, Desk6.Accent()); OllGL6.Text2D(W DIV 2 - 144 + 72, 190, "XIPOGO", 6, Desk6.text);
      Desk6.Centre(W DIV 2, 250, "READY", 3, Desk6.Accent()); Desk6.Centre(W DIV 2, 290, "PIXIPOGO 30 . CUBICUM N", 2, Desk6.muted)
    END;
    Desk6.Centre(W DIV 2, H - 60, "TAP TO SKIP", 1, Desk6.edge);
    OllGL6.Arata
    RETURN done
  END Frame;

  PROCEDURE Sweep;   (* the nodes nearest to base * 1, 9/8, 5/4, 3/2, 5/3, 2, 9/4, 5/2, 3, 10/3, 4 *)
    VAR x, y, z, k, bx, by, bz: INTEGER; f, base, top, want, d, bd: REAL;
  BEGIN
    base := 100000.0; top := 0.0;
    FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
      f := Synth9.Freq(x, y, z);
      IF (f >= 110.0) & (f < base) THEN base := f END; IF f > top THEN top := f END
    END END END;
    nn := 0;
    IF base < 100000.0 THEN
      FOR k := 0 TO 10 DO
        IF k = 0 THEN want := 1.0 ELSIF k = 1 THEN want := 1.125 ELSIF k = 2 THEN want := 1.25 ELSIF k = 3 THEN want := 1.5
        ELSIF k = 4 THEN want := 1.6667 ELSIF k = 5 THEN want := 2.0 ELSIF k = 6 THEN want := 2.25 ELSIF k = 7 THEN want := 2.5
        ELSIF k = 8 THEN want := 3.0 ELSIF k = 9 THEN want := 3.3333 ELSE want := 4.0 END;
        want := want * base;
        IF want <= top * 1.03 THEN
          bd := 1.0E9; bx := 0; by := 0; bz := 0;
          FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
            f := Synth9.Freq(x, y, z); d := ABS(f - want) / want;
            IF d < bd THEN bd := d; bx := x; by := y; bz := z END
          END END END;
          nx[nn] := bx; ny[nn] := by; nz[nn] := bz; INC(nn)
        END
      END
    END
  END Sweep;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h; cx := W DIV 2; cy := H DIV 2 - 40; t0 := Ceas.Ms(); played := 0; wasDown := TRUE; Sweep
  END Start;

BEGIN W := 1; H := 1; t0 := 0; played := 0; wasDown := FALSE; cx := 0; cy := 0; nn := 0
END Boot5.
