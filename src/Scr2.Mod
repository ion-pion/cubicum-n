MODULE Scr2;  (* SCREEN 2 (11 Nov 2026): the sound too, in the same device: commands 20 Note(x, y, z, ms) a node of the Z7
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

  IMPORT Grafica, Text1, Synth9;

  CONST IO* = 1694851494; NI = 6000;

  VAR
    kind, ax, ay, aw, ah, ac: ARRAY NI OF INTEGER;   (* the list being drawn *)
    ni: INTEGER;
    skind, sx, sy, sw, sh, sc: ARRAY NI OF INTEGER;  (* the list shown *)
    ns: INTEGER;
    par: ARRAY 6 OF INTEGER; tx, ty, tsize, tcol: INTEGER;
    down, wasDown, tapped: BOOLEAN; x, y, W, H, frames: INTEGER;
    used*: BOOLEAN;   (* a program has drawn: the canvas should be seen *)
    told: BOOLEAN;

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
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO ni - 1 DO skind[i] := kind[i]; sx[i] := ax[i]; sy[i] := ay[i]; sw[i] := aw[i]; sh[i] := ah[i]; sc[i] := ac[i] END;
    ns := ni; INC(frames); used := TRUE   (* the list stays: the picture is all that was drawn since Clear *)
  END Show;

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
    ELSIF (k >= 10) & (k <= 15) THEN v := par[k - 10]
    END
    RETURN v
  END Read;

  PROCEDURE Write*(a, v: INTEGER): BOOLEAN;   (* TRUE = Show: the program should wait for the next frame *)
    VAR k: INTEGER; sh: BOOLEAN;
  BEGIN
    k := (a - IO) DIV 12; sh := FALSE;
    IF (k >= 10) & (k <= 15) THEN par[k - 10] := v
    ELSIF k = 16 THEN
      IF v = 1 THEN ni := 0; Item(2, 0, 0, W, H, Col(par[0]))
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
      END
    END
    RETURN sh
  END Write;

  PROCEDURE Ended*;   (* a program ended: what it drew without Show is shown too *)
  BEGIN IF ni # ns THEN Show END
  END Ended;

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

  PROCEDURE Touch*(d: BOOLEAN; px, py: INTEGER);   (* the finger, every frame the canvas is seen *)
  BEGIN
    wasDown := down; down := d;
    IF d THEN x := px; y := py; IF ~wasDown THEN tapped := TRUE END END
  END Touch;

  PROCEDURE Reset*;   (* a new program starts drawing on a clean canvas *)
  BEGIN ni := 0; ns := 0; tapped := FALSE; used := FALSE; told := FALSE
  END Reset;

  PROCEDURE Fresh*(): BOOLEAN;   (* TRUE once, when a program has just shown its first picture *)
    VAR r: BOOLEAN;
  BEGIN r := used & ~told; IF r THEN told := TRUE END
    RETURN r
  END Fresh;

BEGIN
  ni := 0; ns := 0; down := FALSE; wasDown := FALSE; tapped := FALSE; x := 0; y := 0; W := 540; H := 1000; frames := 0; used := FALSE; told := FALSE
END Scr2.
