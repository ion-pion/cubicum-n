MODULE Scr2;  (* SCREEN 2b (25 Nov 2026, Pixipogo 52, file Scr2b.Mod): the cartridges get the hardware that Pixipogo has.
     Pion: "can the games like the tube have the hardware when they need it?" - yes, through Pixipogo itself, so the same
     .mod runs wherever Pixipogo runs (phone, Linux, Windows, the stick, one day the bare metal).
     TILT   words 7, 8: Touch.TiltX(), Touch.TiltY() in thousandths of m/s2 (about -9810 .. 9810): right and forward
            are plus; command 9 Touch.Level: the way the phone is held now becomes zero.
     MUSIC  a sequencer of 2 tracks x 64 steps that Pixipogo plays by itself, on time, while the program runs:
            24 Sound.Seq(track, step, note)  25 Sound.Tempo(ms a step)  26 Sound.Loop(steps; 0 = silence).
            A note: 1 .. 21 = the degrees of Do major from Do3 (1 Do3, 8 Do4, 15 Do5); 0 = rest. Track 1 sounds an octave lower.
     SPACE  3D drawn by the graphics card (OllGL6), the numbers in thousandths (1000 = one unit). The parameters of the
            3D commands live in the words 40 .. 53. A frame with a camera is a 3D frame; Screen.* draws over it.
            30 Camera(ex, ey, ez, tx, ty, tz)  31 Fov(degrees)  32 Fog(near, far)  33 Light(thousandths)
            34 Lamp(x, y, z, r, power, c)  35 Cube(x, y, z, size, c)  36 Ball(x, y, z, r, c)  37 Tri(9 numbers, c)
            THE PATH (for tubes, roads, rivers): 512 points that the program sets and Pixipogo bends into geometry:
            38 Point(i, x, y, z)  39 Tube(from, to, r, sides, c1, c2)  40 Arc(i, a0, a1, r, thick, c) a ring piece around
            point i (angles in 64ths of a turn, 0 = right, 16 = up)
            41 At(p, a, r, size, c) a ball near the wall: p = the place on the path in thousandths of a point (smooth),
               a = the angle in 1024ths of a turn, r = how far from the middle
            42 Follow(p, ahead, a, lift, look) the camera rides the path at p, lifted towards angle a, looking ahead points.
            43 Roll(a) the picture turns around the line of sight by a (1024ths): what is at angle 768 - a comes down.
   SCREEN 2 (11 Nov 2026): the sound too, in the same device: commands 20 Note(x, y, z, ms) a node of the Z7
     cube, 21 Hz(f, ms), 22 Play(slot), 23 Stop (they go to Synth9).
   SCREEN 1 (11 Nov 2026): the screen and the touch of the Tor7 programs. Pion: "it seems Oberon does not know the touch screen".
     They live in the torus, in the 11th dimension: the cells whose 11th coordinate is 6 (from IO = 6 * 7^10) are not memory
     but the device. A program reads and writes words there (LDW, STW); Ob0 does it for Screen.* and Touch.*:
       word 0 down (0/1)   1 x   2 y   3 tap (1 once for every new touch)   4 width   5 height   6 frames shown
       words 10..15 the parameters, word 16 the command:
         1 Clear(c)  2 Rect(x, y, w, h, c)  3 Char(x, y, ch, size, c)  4 Int(x, y, n, size, c)  5 Show
         6 Circle(x, y, r, c)  7 Start text at (x, y, size, c)  8 one more letter of that text
     What is drawn goes into a list (Clear empties it); Show makes the list the picture (the canvas draws it every frame).
     Pion & Claude, 11.11.2026 *)

  IMPORT Grafica, Text1, Synth9, Motor2, OllGL6, Math;

  CONST IO* = 1694851494; NI = 6000; N3 = 3000; NP = 512; PI2 = 6.28318530717959;

  VAR
    kind, ax, ay, aw, ah, ac: ARRAY NI OF INTEGER;   (* the list being drawn *)
    ni: INTEGER;
    skind, sx, sy, sw, sh, sc: ARRAY NI OF INTEGER;  (* the list shown *)
    ns: INTEGER;
    par: ARRAY 6 OF INTEGER; tx, ty, tsize, tcol: INTEGER;
    down, wasDown, tapped: BOOLEAN; x, y, W, H, frames: INTEGER;
    used*: BOOLEAN;   (* a program has drawn: the canvas should be seen *)
    told: BOOLEAN;
    (* tilt *)
    tx0, ty0: INTEGER;
    (* music *)
    seq: ARRAY 2, 64 OF INTEGER; tempo, loopN, step, nextT: INTEGER; semi: ARRAY 7 OF INTEGER;
    (* space: the list being drawn and the list shown *)
    par2: ARRAY 14 OF INTEGER;
    k3, sk3: ARRAY N3 OF INTEGER; p3, sp3: ARRAY N3, 10 OF INTEGER; n3, sn3: INTEGER;
    cam, scam: ARRAY 12 OF INTEGER; is3, sis3: BOOLEAN;   (* eye, target, fov, fog near/far, light, lamp x y z r power c *)
    bgc, sbgc: INTEGER;   (* the colour of Clear *)
    ppx, ppy, ppz: ARRAY NP OF INTEGER;   (* the path *)
    cs, sn: ARRAY 65 OF REAL;   (* the sine of the 64ths *)
    rollOn: BOOLEAN; rkx, rky, rkz, rc, rs, rex, rey, rez: REAL;   (* the world turns around the line of sight (Roll) *)

  PROCEDURE Is*(a: INTEGER): BOOLEAN;   (* is address a in the device? *)
  BEGIN RETURN a >= IO
  END Is;

  PROCEDURE Col(c: INTEGER): INTEGER;   (* 0RRGGBB from the program -> an opaque colour *)
  BEGIN RETURN c MOD 16777216 - 16777216
  END Col;

  PROCEDURE Item(k, a, b, c, d, e: INTEGER);
  BEGIN
    IF ni < NI THEN kind[ni] := k; ax[ni] := a; ay[ni] := b; aw[ni] := c; ah[ni] := d; ac[ni] := e; INC(ni) END
  END Item;

  PROCEDURE Show;
    VAR i, j: INTEGER;
  BEGIN
    FOR i := 0 TO ni - 1 DO skind[i] := kind[i]; sx[i] := ax[i]; sy[i] := ay[i]; sw[i] := aw[i]; sh[i] := ah[i]; sc[i] := ac[i] END;
    ns := ni; INC(frames); used := TRUE;   (* the list stays: the picture is all that was drawn since Clear *)
    FOR i := 0 TO n3 - 1 DO sk3[i] := k3[i]; FOR j := 0 TO 9 DO sp3[i, j] := p3[i, j] END END;
    FOR j := 0 TO 11 DO scam[j] := cam[j] END;
    sn3 := n3; sis3 := is3; sbgc := bgc
  END Show;

  PROCEDURE Item3(k, n: INTEGER);   (* a 3D thing with n parameters from par2 *)
    VAR i: INTEGER;
  BEGIN
    IF n3 < N3 THEN k3[n3] := k; FOR i := 0 TO n - 1 DO p3[n3, i] := par2[i] END; INC(n3) END
  END Item3;

  PROCEDURE MusicOff;
  BEGIN loopN := 0; step := 0
  END MusicOff;

  PROCEDURE Read*(a: INTEGER): INTEGER;
    VAR k, v: INTEGER;
  BEGIN
    k := (a - IO) DIV 12; v := 0;
    IF k = 0 THEN IF down THEN v := 1 END
    ELSIF k = 1 THEN v := x
    ELSIF k = 2 THEN v := y
    ELSIF k = 3 THEN IF tapped THEN v := 1; tapped := FALSE END
    ELSIF k = 4 THEN v := W
    ELSIF k = 5 THEN v := H
    ELSIF k = 6 THEN v := frames
    ELSIF k = 7 THEN v := -(Motor2.Ix() - tx0)
    ELSIF k = 8 THEN v := Motor2.Iy() - ty0
    ELSIF (k >= 10) & (k <= 15) THEN v := par[k - 10]
    ELSIF (k >= 40) & (k <= 53) THEN v := par2[k - 40]
    END
    RETURN v
  END Read;

  PROCEDURE Write*(a, v: INTEGER): BOOLEAN;   (* TRUE = Show: the program should wait for the next frame *)
    VAR k: INTEGER; sh: BOOLEAN;
  BEGIN
    k := (a - IO) DIV 12; sh := FALSE;
    IF (k >= 10) & (k <= 15) THEN par[k - 10] := v
    ELSIF (k >= 40) & (k <= 53) THEN par2[k - 40] := v
    ELSIF k = 16 THEN
      IF v = 1 THEN ni := 0; Item(2, 0, 0, W, H, Col(par[0])); n3 := 0; is3 := FALSE; bgc := Col(par[0]); cam[11] := 0
      ELSIF v = 2 THEN Item(2, par[0], par[1], par[2], par[3], Col(par[4]))
      ELSIF v = 3 THEN Item(3, par[0], par[1], par[2], par[3], Col(par[4]))
      ELSIF v = 4 THEN Item(4, par[0], par[1], par[2], par[3], Col(par[4]))
      ELSIF v = 5 THEN Show; sh := TRUE
      ELSIF v = 6 THEN Item(6, par[0], par[1], par[2], 0, Col(par[3]))
      ELSIF v = 7 THEN tx := par[0]; ty := par[1]; tsize := par[2]; tcol := Col(par[3])
      ELSIF v = 8 THEN Item(3, tx, ty, par[0], tsize, tcol); tx := tx + 6 * tsize
      ELSIF v = 20 THEN Synth9.Note(par[0], par[1], par[2], par[3])
      ELSIF v = 21 THEN Synth9.NoteHz(FLT(par[0]), par[1])
      ELSIF v = 22 THEN IF Synth9.PlaySlot(par[0]) THEN END
      ELSIF v = 23 THEN Synth9.Stop
      ELSIF v = 9 THEN tx0 := Motor2.Ix(); ty0 := Motor2.Iy()
      ELSIF v = 24 THEN IF (par[0] >= 0) & (par[0] < 2) & (par[1] >= 0) & (par[1] < 64) THEN seq[par[0], par[1]] := par[2] END
      ELSIF v = 25 THEN tempo := par[0]; IF tempo < 40 THEN tempo := 40 END
      ELSIF v = 26 THEN loopN := par[0]; IF loopN > 64 THEN loopN := 64 END; IF loopN < 0 THEN loopN := 0 END; step := 0
      ELSIF v = 30 THEN FOR k := 0 TO 5 DO cam[k] := par2[k] END; is3 := TRUE
      ELSIF v = 31 THEN cam[6] := par[0]
      ELSIF v = 32 THEN cam[7] := par[0]; cam[8] := par[1]
      ELSIF v = 33 THEN cam[9] := par[0]
      ELSIF v = 34 THEN Item3(34, 6)
      ELSIF v = 35 THEN Item3(35, 5)
      ELSIF v = 36 THEN Item3(36, 5)
      ELSIF v = 37 THEN Item3(37, 10)
      ELSIF v = 38 THEN k := par2[0] MOD NP; ppx[k] := par2[1]; ppy[k] := par2[2]; ppz[k] := par2[3]
      ELSIF v = 39 THEN Item3(39, 6)
      ELSIF v = 40 THEN Item3(40, 6)
      ELSIF v = 41 THEN Item3(41, 5)
      ELSIF v = 42 THEN Item3(42, 5); is3 := TRUE
      ELSIF v = 43 THEN cam[10] := par[0]; cam[11] := 1
      END
    END
    RETURN sh
  END Write;

  PROCEDURE Ended*;   (* a program ended: what it drew without Show is shown too; the music stops *)
  BEGIN IF ni # ns THEN Show END; MusicOff
  END Ended;

  (* ---------- music ---------- *)

  PROCEDURE Hz(note, track: INTEGER): REAL;   (* 1 = Do3 (130.81 Hz), the degrees of Do major *)
    VAR f: REAL; k: INTEGER;
  BEGIN
    DEC(note); f := 130.81; FOR k := 1 TO note DIV 7 DO f := f * 2.0 END;
    FOR k := 1 TO semi[note MOD 7] DO f := f * 1.0594631 END;
    IF track = 1 THEN f := f * 0.5 END
    RETURN f
  END Hz;

  PROCEDURE Tick*(now: INTEGER);   (* every frame: the sequencer plays the step that is due *)
    VAR t: INTEGER;
  BEGIN
    IF loopN > 0 THEN
      IF (now - nextT > 1000) OR (nextT - now > 10000) THEN nextT := now END;
      IF now >= nextT THEN
        FOR t := 0 TO 1 DO
          IF seq[t, step] > 0 THEN Synth9.NoteHz(Hz(seq[t, step], t), tempo * 2) END
        END;
        step := (step + 1) MOD loopN; nextT := nextT + tempo
      END
    END
  END Tick;

  PROCEDURE Size*(w, h: INTEGER);
  BEGIN W := w; H := h
  END Size;

  PROCEDURE Draw*(bg: INTEGER);   (* the canvas: the list shown, every frame of Cubicum N *)
    VAR i, m: INTEGER; s: ARRAY 2 OF CHAR;
  BEGIN
    Grafica.Dreptunghi(0, 0, W, H, bg); s[1] := 0X;
    FOR i := 0 TO ns - 1 DO
      m := sh[i]; IF m < 1 THEN m := 1 ELSIF m > 20 THEN m := 20 END;
      IF skind[i] = 2 THEN
        IF (sw[i] > 0) & (sh[i] > 0) THEN Grafica.Dreptunghi(sx[i], sy[i], sw[i], sh[i], sc[i]) END
      ELSIF skind[i] = 3 THEN
        IF (sw[i] > 32) & (sw[i] < 127) THEN s[0] := CHR(sw[i]); Text1.Draw(sx[i], sy[i], s, m, sc[i]) END
      ELSIF skind[i] = 4 THEN Grafica.Numar(sx[i], sy[i], sw[i], m, sc[i])
      ELSIF skind[i] = 6 THEN IF (sw[i] > 0) & (sw[i] < 2000) THEN Grafica.Cerc(sx[i], sy[i], sw[i], sc[i]) END
      END
    END
  END Draw;

  (* ---------- space ---------- *)

  PROCEDURE Is3D*(): BOOLEAN;   (* the picture shown has a camera: draw it with Draw3D *)
  BEGIN RETURN sis3
  END Is3D;

  PROCEDURE M(v: INTEGER): REAL;   (* thousandths -> units *)
  BEGIN RETURN FLT(v) / 1000.0
  END M;

  PROCEDURE Basis(i: INTEGER; VAR ux, uy, uz, vx, vy, vz: REAL);   (* across the path at point i: u to the right, v up *)
    VAR a, b: INTEGER; tx, ty, tz, l: REAL;
  BEGIN
    a := (i + NP - 1) MOD NP; b := (i + 1) MOD NP;
    tx := FLT(ppx[b] - ppx[a]); ty := FLT(ppy[b] - ppy[a]); tz := FLT(ppz[b] - ppz[a]);
    l := Math.sqrt(tx * tx + ty * ty + tz * tz); IF l < 0.001 THEN tx := 0.0; ty := 0.0; tz := 1.0; l := 1.0 END;
    tx := tx / l; ty := ty / l; tz := tz / l;
    ux := -tz; uy := 0.0; uz := tx;   (* to the right on the screen when you look along the path *)
    l := Math.sqrt(ux * ux + uz * uz); IF l < 0.001 THEN ux := 1.0; uz := 0.0; l := 1.0 END;
    ux := ux / l; uz := uz / l;
    vx := uy * tz - uz * ty; vy := uz * tx - ux * tz; vz := ux * ty - uy * tx   (* u x t *)
  END Basis;

  PROCEDURE OnWall(p, a, r: INTEGER; VAR x, y, z: REAL);   (* p: the place on the path in thousandths of a point;
                                                             a: the angle in 1024ths of a turn; r: thousandths *)
    VAR i, j: INTEGER; f, ux, uy, uz, vx, vy, vz, ux2, uy2, uz2, vx2, vy2, vz2, c, s, rr, cx, cy, cz: REAL;
  BEGIN
    i := (p DIV 1000) MOD NP; j := (i + 1) MOD NP; f := FLT(p MOD 1000) / 1000.0;
    Basis(i, ux, uy, uz, vx, vy, vz); Basis(j, ux2, uy2, uz2, vx2, vy2, vz2);
    ux := ux + (ux2 - ux) * f; uy := uy + (uy2 - uy) * f; uz := uz + (uz2 - uz) * f;
    vx := vx + (vx2 - vx) * f; vy := vy + (vy2 - vy) * f; vz := vz + (vz2 - vz) * f;
    cx := M(ppx[i]) + (M(ppx[j]) - M(ppx[i])) * f; cy := M(ppy[i]) + (M(ppy[j]) - M(ppy[i])) * f; cz := M(ppz[i]) + (M(ppz[j]) - M(ppz[i])) * f;
    c := Math.cos(PI2 * FLT(a MOD 1024) / 1024.0); s := Math.sin(PI2 * FLT(a MOD 1024) / 1024.0); rr := M(r);
    x := cx + rr * (c * ux + s * vx); y := cy + rr * (c * uy + s * vy); z := cz + rr * (c * uz + s * vz)
  END OnWall;

  PROCEDURE Turn(VAR x, y, z: REAL);   (* the roll: around the line of sight through the eye *)
    VAR vx, vy, vz, cx, cy, cz, d: REAL;
  BEGIN
    IF rollOn THEN
      vx := x - rex; vy := y - rey; vz := z - rez;
      cx := rky * vz - rkz * vy; cy := rkz * vx - rkx * vz; cz := rkx * vy - rky * vx;
      d := (rkx * vx + rky * vy + rkz * vz) * (1.0 - rc);
      x := rex + vx * rc + cx * rs + rkx * d; y := rey + vy * rc + cy * rs + rky * d; z := rez + vz * rc + cz * rs + rkz * d
    END
  END Turn;

  PROCEDURE Quad(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3: REAL; c: INTEGER);
  BEGIN
    Turn(x0, y0, z0); Turn(x1, y1, z1); Turn(x2, y2, z2); Turn(x3, y3, z3);
    OllGL6.Patrat(x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3, c)
  END Quad;

  PROCEDURE SetRoll(ex, ey, ez, tx, ty, tz: REAL);   (* the eye and where it looks: the axis of the roll *)
    VAR l, a: REAL;
  BEGIN
    rollOn := scam[11] = 1;
    IF rollOn THEN
      rkx := tx - ex; rky := ty - ey; rkz := tz - ez; l := Math.sqrt(rkx * rkx + rky * rky + rkz * rkz);
      IF l < 0.0001 THEN rollOn := FALSE
      ELSE
        rkx := rkx / l; rky := rky / l; rkz := rkz / l; rex := ex; rey := ey; rez := ez;
        a := -PI2 * FLT(scam[10]) / 1024.0; rc := Math.cos(a); rs := Math.sin(a)
      END
    END
  END SetRoll;

  PROCEDURE Ball(x, y, z, r: REAL; c: INTEGER);   (* a small sphere: 8 slices, 5 bands *)
    VAR i, j: INTEGER; a0, a1, b0, b1: REAL;
  BEGIN
    Turn(x, y, z);
    FOR j := 0 TO 4 DO
      b0 := 3.14159265 * (FLT(j) / 5.0 - 0.5); b1 := 3.14159265 * (FLT(j + 1) / 5.0 - 0.5);
      FOR i := 0 TO 7 DO
        a0 := PI2 * FLT(i) / 8.0; a1 := PI2 * FLT(i + 1) / 8.0;
        OllGL6.Patrat(x + r * Math.cos(b0) * Math.cos(a0), y + r * Math.sin(b0), z + r * Math.cos(b0) * Math.sin(a0),
          x + r * Math.cos(b0) * Math.cos(a1), y + r * Math.sin(b0), z + r * Math.cos(b0) * Math.sin(a1),
          x + r * Math.cos(b1) * Math.cos(a1), y + r * Math.sin(b1), z + r * Math.cos(b1) * Math.sin(a1),
          x + r * Math.cos(b1) * Math.cos(a0), y + r * Math.sin(b1), z + r * Math.cos(b1) * Math.sin(a0), c)
      END
    END
  END Ball;

  PROCEDURE Tube(from, to, r, sides, c1, c2: INTEGER);
    VAR i, k, s, c: INTEGER; ux, uy, uz, vx, vy, vz, rr, a: REAL;
      x0, y0, z0, x1, y1, z1: ARRAY 49 OF REAL;
  BEGIN
    IF sides < 3 THEN sides := 3 ELSIF sides > 48 THEN sides := 48 END;
    IF to - from > 200 THEN to := from + 200 END;
    rr := M(r);
    FOR i := from TO to DO
      k := (i + NP) MOD NP; Basis(k, ux, uy, uz, vx, vy, vz);
      FOR s := 0 TO sides DO
        a := PI2 * FLT(s) / FLT(sides);
        x1[s] := M(ppx[k]) + rr * (Math.cos(a) * ux + Math.sin(a) * vx);
        y1[s] := M(ppy[k]) + rr * (Math.cos(a) * uy + Math.sin(a) * vy);
        z1[s] := M(ppz[k]) + rr * (Math.cos(a) * uz + Math.sin(a) * vz)
      END;
      IF i > from THEN
        FOR s := 0 TO sides - 1 DO
          IF ODD(i + s) THEN c := c1 ELSE c := c2 END;
          Quad(x0[s], y0[s], z0[s], x0[s + 1], y0[s + 1], z0[s + 1], x1[s + 1], y1[s + 1], z1[s + 1], x1[s], y1[s], z1[s], c)
        END
      END;
      FOR s := 0 TO sides DO x0[s] := x1[s]; y0[s] := y1[s]; z0[s] := z1[s] END
    END
  END Tube;

  PROCEDURE Arc(i, a0, a1, r, th, c: INTEGER);   (* a piece of ring around point i: the face towards you and the inner face *)
    VAR a, k: INTEGER; ux, uy, uz, vx, vy, vz, tx, ty, tz, l, px, py, pz, ri, ro, d, c0, s0, c1, s1: REAL;
  BEGIN
    i := i MOD NP; Basis(i, ux, uy, uz, vx, vy, vz);
    k := (i + NP - 1) MOD NP;
    tx := FLT(ppx[i] - ppx[k]); ty := FLT(ppy[i] - ppy[k]); tz := FLT(ppz[i] - ppz[k]);
    l := Math.sqrt(tx * tx + ty * ty + tz * tz); IF l < 0.001 THEN l := 1.0; tz := 1.0 END;
    d := M(th) * 0.5; tx := tx / l * d; ty := ty / l * d; tz := tz / l * d;
    px := M(ppx[i]) - tx; py := M(ppy[i]) - ty; pz := M(ppz[i]) - tz;   (* the face towards the camera *)
    ro := M(r); ri := M(r - th); IF ri < 0.0 THEN ri := 0.0 END;
    IF a1 < a0 THEN a1 := a1 + 64 END;
    FOR a := a0 TO a1 - 1 DO
      c0 := cs[a MOD 64]; s0 := sn[a MOD 64]; c1 := cs[(a + 1) MOD 64]; s1 := sn[(a + 1) MOD 64];
      Quad(px + ri * (c0 * ux + s0 * vx), py + ri * (c0 * uy + s0 * vy), pz + ri * (c0 * uz + s0 * vz),
        px + ro * (c0 * ux + s0 * vx), py + ro * (c0 * uy + s0 * vy), pz + ro * (c0 * uz + s0 * vz),
        px + ro * (c1 * ux + s1 * vx), py + ro * (c1 * uy + s1 * vy), pz + ro * (c1 * uz + s1 * vz),
        px + ri * (c1 * ux + s1 * vx), py + ri * (c1 * uy + s1 * vy), pz + ri * (c1 * uz + s1 * vz), c);
      Quad(px + ri * (c0 * ux + s0 * vx), py + ri * (c0 * uy + s0 * vy), pz + ri * (c0 * uz + s0 * vz),
        px + ri * (c1 * ux + s1 * vx), py + ri * (c1 * uy + s1 * vy), pz + ri * (c1 * uz + s1 * vz),
        px + 2.0 * tx + ri * (c1 * ux + s1 * vx), py + 2.0 * ty + ri * (c1 * uy + s1 * vy), pz + 2.0 * tz + ri * (c1 * uz + s1 * vz),
        px + 2.0 * tx + ri * (c0 * ux + s0 * vx), py + 2.0 * ty + ri * (c0 * uy + s0 * vy), pz + 2.0 * tz + ri * (c0 * uz + s0 * vz), c)
    END
  END Arc;

  PROCEDURE Follow(p, ahead, a, lift, look: INTEGER);   (* the camera rides the path at p (thousandths of a point), lifted
                                                         towards angle a (1024ths), looking ahead points, at height look *)
    VAR ex, ey, ez, gx, gy, gz, f: REAL;
  BEGIN
    OnWall(p, a, lift, ex, ey, ez); OnWall(p + ahead * 1000, a, look, gx, gy, gz);
    IF scam[6] > 0 THEN f := FLT(scam[6]) ELSE f := 60.0 END;
    OllGL6.Camera(ex, ey, ez, gx, gy, gz, f); SetRoll(ex, ey, ez, gx, gy, gz)
  END Follow;

  PROCEDURE Draw3D*;   (* the canvas of a 3D program: the space, then what Screen drew over it *)
    VAR i, j, m, c: INTEGER; x, y, z: REAL; p: ARRAY 10 OF INTEGER;
  BEGIN
    OllGL6.Incepe(sbgc);
    IF scam[6] > 0 THEN m := scam[6] ELSE m := 60 END;
    OllGL6.Camera(M(scam[0]), M(scam[1]), M(scam[2]), M(scam[3]), M(scam[4]), M(scam[5]), FLT(m));
    SetRoll(M(scam[0]), M(scam[1]), M(scam[2]), M(scam[3]), M(scam[4]), M(scam[5]));
    FOR i := 0 TO sn3 - 1 DO   (* the camera that rides the path comes first: the roll needs it *)
      IF sk3[i] = 42 THEN Follow(sp3[i, 0], sp3[i, 1], sp3[i, 2], sp3[i, 3], sp3[i, 4]) END
    END;
    IF scam[8] > scam[7] THEN OllGL6.Ceata(M(scam[7]), M(scam[8])) ELSE OllGL6.Ceata(0.0, 0.0) END;
    IF scam[9] > 0 THEN OllGL6.Lumina(M(scam[9])) ELSE OllGL6.Lumina(0.55) END;
    FOR i := 0 TO sn3 - 1 DO
      FOR j := 0 TO 9 DO p[j] := sp3[i, j] END;
      IF sk3[i] = 34 THEN x := M(p[0]); y := M(p[1]); z := M(p[2]); Turn(x, y, z); OllGL6.LuminaPunct(x, y, z, M(p[3]), M(p[4]), Col(p[5]))
      ELSIF sk3[i] = 35 THEN x := M(p[0]); y := M(p[1]); z := M(p[2]); Turn(x, y, z); OllGL6.Cub(x, y, z, M(p[3]), Col(p[4]))
      ELSIF sk3[i] = 36 THEN Ball(M(p[0]), M(p[1]), M(p[2]), M(p[3]), Col(p[4]))
      ELSIF sk3[i] = 37 THEN Quad(M(p[0]), M(p[1]), M(p[2]), M(p[3]), M(p[4]), M(p[5]), M(p[6]), M(p[7]), M(p[8]), M(p[6]), M(p[7]), M(p[8]), Col(p[9]))
      ELSIF sk3[i] = 39 THEN Tube(p[0], p[1], p[2], p[3], Col(p[4]), Col(p[5]))
      ELSIF sk3[i] = 40 THEN Arc(p[0], p[1], p[2], p[3], p[4], Col(p[5]))
      ELSIF sk3[i] = 41 THEN OnWall(p[0], p[1], p[2], x, y, z); Ball(x, y, z, M(p[3]), Col(p[4]))
      END
    END;
    FOR i := 1 TO ns - 1 DO   (* item 0 is the Clear: the space is under the words *)
      m := sh[i]; IF m < 1 THEN m := 1 ELSIF m > 20 THEN m := 20 END; c := sc[i];
      IF skind[i] = 2 THEN
        IF (sw[i] > 0) & (sh[i] > 0) THEN OllGL6.Dreptunghi2D(sx[i], sy[i], sw[i], sh[i], c) END
      ELSIF skind[i] = 3 THEN
        IF (sw[i] > 32) & (sw[i] < 127) THEN OllGL6.Litera2D(sx[i], sy[i], CHR(sw[i]), m, c) END
      ELSIF skind[i] = 4 THEN OllGL6.Numar2D(sx[i], sy[i], sw[i], m, c)
      ELSIF skind[i] = 6 THEN IF (sw[i] > 0) & (sw[i] < 2000) THEN OllGL6.Cerc2D(sx[i], sy[i], sw[i], c) END
      END
    END
  END Draw3D;

  PROCEDURE Touch*(d: BOOLEAN; px, py: INTEGER);   (* the finger, every frame the canvas is seen *)
  BEGIN
    wasDown := down; down := d;
    IF d THEN x := px; y := py; IF ~wasDown THEN tapped := TRUE END END
  END Touch;

  PROCEDURE Reset*;   (* a new program starts drawing on a clean canvas *)
  BEGIN ni := 0; ns := 0; tapped := FALSE; used := FALSE; told := FALSE;
    n3 := 0; sn3 := 0; is3 := FALSE; sis3 := FALSE; MusicOff; tempo := 150
  END Reset;

  PROCEDURE Fresh*(): BOOLEAN;   (* TRUE once, when a program has just shown its first picture *)
    VAR r: BOOLEAN;
  BEGIN r := used & ~told; IF r THEN told := TRUE END
    RETURN r
  END Fresh;

  PROCEDURE Init3;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 64 DO cs[i] := Math.cos(PI2 * FLT(i) / 64.0); sn[i] := Math.sin(PI2 * FLT(i) / 64.0) END;
    FOR i := 0 TO 11 DO cam[i] := 0; scam[i] := 0 END;
    FOR i := 0 TO NP - 1 DO ppx[i] := 0; ppy[i] := 0; ppz[i] := i * 1000 END;
    FOR i := 0 TO 63 DO seq[0, i] := 0; seq[1, i] := 0 END;
    semi[0] := 0; semi[1] := 2; semi[2] := 4; semi[3] := 5; semi[4] := 7; semi[5] := 9; semi[6] := 11;
    n3 := 0; sn3 := 0; is3 := FALSE; sis3 := FALSE; rollOn := FALSE; tx0 := 0; ty0 := 0; tempo := 150; loopN := 0; step := 0; nextT := 0;
    bgc := Col(0); sbgc := bgc
  END Init3;

BEGIN
  Init3;
  ni := 0; ns := 0; down := FALSE; wasDown := FALSE; tapped := FALSE; x := 0; y := 0; W := 540; H := 1000; frames := 0; used := FALSE; told := FALSE
END Scr2.
