MODULE Files3;  (* FILES 3 (19 Nov 2026, Cubicum N 17): Files 2 with OllGL6, Desk4, Shell12.
   FILES 2 (19 Nov 2026, Cubicum N 16): Files 1 with Desk3 and Shell11.
   FILES 1 (19 Nov 2026, Cubicum N 15): the files of Cubicum N with their cube.
     Above: the Cubicum FS cube; the cells that hold a file are lit, the chosen file is red and big.
     Below: the list (name, size, the 7 digits of its address). Tap a file, then:
       OPEN    the editor of the shell          RUN     a .mod or .z7 program
       PACK    a Z7 Arch cube NAME.z7c          UNPACK  every file out of a .z7c
       DELETE  (tap twice: SURE?)
     The work is done by the shell (Shell11.Do), so the shell shows what happened.
   Pion & Claude, 19.11.2026 *)

  IMPORT Math, OllGL6, Fs2, Desk4, Shell12;

  CONST BAR = 40; RH = 66;   (* list rows *)

  VAR W, H, sel, scroll, scroll0, x0, y0, lTop, lBot, aY, sure: INTEGER;
    down, moved: BOOLEAN; angle: REAL;

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

  PROCEDURE Size(n: INTEGER; VAR s: ARRAY OF CHAR);   (* 812 B, 3.4 KB, 1.2 MB *)
  BEGIN
    s[0] := 0X;
    IF n < 1024 THEN AddN(s, n); Add(s, " B")
    ELSIF n < 1048576 THEN AddN(s, n DIV 1024); Add(s, "."); AddN(s, n MOD 1024 * 10 DIV 1024); Add(s, " KB")
    ELSE AddN(s, n DIV 1048576); Add(s, "."); AddN(s, n MOD 1048576 * 10 DIV 1048576); Add(s, " MB")
    END
  END Size;

  PROCEDURE Ends(VAR s: ARRAY OF CHAR; e: ARRAY OF CHAR): BOOLEAN;
    VAR n, m, i: INTEGER; ok: BOOLEAN;
  BEGIN
    n := Len(s); m := Len(e); ok := n > m; i := 0;
    WHILE ok & (i < m) DO IF s[n - m + i] # e[i] THEN ok := FALSE END; INC(i) END
    RETURN ok
  END Ends;

  PROCEDURE Base(VAR nm, b: ARRAY OF CHAR);   (* the name without its ending *)
    VAR k: INTEGER;
  BEGIN
    k := 0; WHILE (nm[k] # 0X) & (k < LEN(b) - 1) DO b[k] := nm[k]; INC(k) END; b[k] := 0X;
    WHILE (k > 0) & (b[k] # ".") DO DEC(k) END; IF k > 0 THEN b[k] := 0X END
  END Base;

  PROCEDURE Addr(k: INTEGER; VAR s: ARRAY OF CHAR);   (* the 7 digits 1..7 of file k *)
    VAR d: INTEGER;
  BEGIN
    s[0] := 0X;
    FOR d := 0 TO 6 DO AddN(s, Fs2.Digit(k, d) + 1); IF d < 6 THEN Add(s, " ") END END
  END Addr;

  (* the buttons of the chosen file: 0 OPEN, 1 RUN, 2 PACK, 3 UNPACK, 4 DELETE *)

  PROCEDURE Has(b: INTEGER; VAR nm: ARRAY OF CHAR): BOOLEAN;
    VAR ok: BOOLEAN;
  BEGIN
    IF b = 0 THEN ok := ~Ends(nm, ".z7c")
    ELSIF b = 1 THEN ok := Ends(nm, ".mod") OR Ends(nm, ".z7")
    ELSIF b = 2 THEN ok := ~Ends(nm, ".z7c")
    ELSIF b = 3 THEN ok := Ends(nm, ".z7c")
    ELSE ok := TRUE
    END
    RETURN ok
  END Has;

  PROCEDURE Put(t: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  BEGIN s[0] := 0X; Add(s, t)
  END Put;

  PROCEDURE Label(b: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    IF b = 0 THEN Put("OPEN", s) ELSIF b = 1 THEN Put("RUN", s) ELSIF b = 2 THEN Put("PACK", s) ELSIF b = 3 THEN Put("UNPACK", s)
    ELSIF sure > 0 THEN Put("SURE?", s) ELSE Put("DELETE", s) END
  END Label;

  PROCEDURE Do(b: INTEGER): INTEGER;   (* button b on the chosen file; 3 = go to the shell *)
    VAR nm, bs: ARRAY 40 OF CHAR; cmd: ARRAY 48 OF CHAR; r, k: INTEGER;
  BEGIN
    r := 0; Fs2.Name(sel, nm); Base(nm, bs);
    IF b = 0 THEN cmd := "edit "; Add(cmd, nm); k := Shell12.Do(cmd); r := 3
    ELSIF b = 1 THEN cmd := "run "; Add(cmd, bs); k := Shell12.Do(cmd); r := 3
    ELSIF b = 2 THEN cmd := "arch pack "; Add(cmd, bs); Add(cmd, " "); Add(cmd, nm); k := Shell12.Do(cmd); r := 3
    ELSIF b = 3 THEN cmd := "arch all "; Add(cmd, bs); k := Shell12.Do(cmd); r := 3
    ELSIF sure = 0 THEN sure := 120   (* the first tap only asks *)
    ELSE
      cmd := "rm "; Add(cmd, nm); k := Shell12.Do(cmd); k := Shell12.Do(cmd);   (* the shell deletes on the second RM *)
      Fs2.Sync; sure := 0; sel := -1; cmd := "DELETED "; Add(cmd, nm); Desk4.Say(cmd)
    END
    RETURN r
  END Do;

  PROCEDURE Cube;   (* the Cubicum FS cube, turning slowly *)
    VAR x, y, z, k, c: INTEGER; r: REAL; sx, sy, sz: INTEGER;
  BEGIN
    IF ~down THEN angle := angle + 0.006 END;
    r := 42.0 * 0.92;
    OllGL6.Camera(r * Math.cos(angle), 13.0, r * Math.sin(angle), 0.0, -11.0, 0.0, 50.0);
    OllGL6.Lumina(0.5);
    sx := -9; sy := -9; sz := -9;
    IF sel >= 0 THEN sx := Fs2.X(sel); sy := Fs2.Y(sel); sz := Fs2.Z(sel) END;
    FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
      k := Fs2.At(x, y, z);
      IF (x = sx) & (y = sy) & (z = sz) THEN OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.9, Desk4.red)
      ELSIF k >= 0 THEN OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.6, Desk4.Accent())
      ELSE
        c := OllGL6.RGB(30 + x * 12, 24 + y * 10, 50 + z * 14);
        OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.22, c)
      END
    END END END
  END Cube;


  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME, 3 SHELL *)
    VAR r, i, n, yy, b, bw, lim, k: INTEGER; nm, s: ARRAY 40 OF CHAR;
  BEGIN
    r := 0; n := Fs2.Count(); IF sel >= n THEN sel := -1 END;
    IF sure > 0 THEN DEC(sure) END;
    lim := lBot - lTop - n * RH; IF lim > 0 THEN lim := 0 END;
    bw := (W - 40) DIV 5;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll
    ELSIF isDown THEN
      IF ABS(y - y0) > 14 THEN moved := TRUE END;
      IF moved & (y0 >= lTop) & (y0 < lBot) THEN scroll := scroll0 + y - y0 END
    ELSIF down THEN
      down := FALSE;
      IF ~moved THEN
        IF (y0 >= lTop) & (y0 < lBot) THEN
          i := (y0 - lTop - scroll) DIV RH;
          IF (i >= 0) & (i < n) THEN sel := i; sure := 0 END
        ELSIF (y0 >= aY) & (y0 < aY + 56) & (sel >= 0) THEN
          b := (x0 - 20) DIV bw; Fs2.Name(sel, nm);
          IF (b >= 0) & (b <= 4) & Has(b, nm) THEN r := Do(b) END
        ELSIF y0 >= H - 76 THEN r := -1
        END
      END
    END;
    IF scroll > 0 THEN scroll := 0 ELSIF scroll < lim THEN scroll := lim END;
    OllGL6.Incepe(Desk4.bg);
    Cube;
    FOR i := 0 TO n - 1 DO   (* the list *)
      yy := lTop + scroll + i * RH;
      IF (yy > lTop - RH) & (yy < lBot) THEN
        Fs2.Name(i, nm);
        IF i = sel THEN OllGL6.Rotund2D(12, yy + 2, W - 24, RH - 4, 14, Desk4.surface2) END;
        Desk4.Glyph(Desk4.KindOf(nm), 22, yy + 9, 48);
        OllGL6.Text2D(84, yy + 12, nm, 2, Desk4.text);
        Addr(i, s); OllGL6.Text2D(84, yy + 40, s, 1, Desk4.muted);
        Size(Fs2.SizeOf(nm), s); k := Len(s) * 12 - 2; OllGL6.Text2D(W - 24 - k, yy + 12, s, 2, Desk4.muted)
      END
    END;
    IF n = 0 THEN Desk4.Centre(W DIV 2, lTop + 40, "NO FILES YET", 2, Desk4.muted) END;
    (* the header and the chosen file, over the list *)
    OllGL6.Dreptunghi2D(0, BAR, W, 50, Desk4.bg);
    Desk4.Status;
    OllGL6.Text2D(24, BAR + 14, "FILES", 4, Desk4.text);
    s[0] := 0X; AddN(s, n); Add(s, " IN THE CUBE"); k := Len(s) * 12 - 2; OllGL6.Text2D(W - 24 - k, BAR + 24, s, 2, Desk4.muted);
    OllGL6.Dreptunghi2D(0, lTop - 74, W, 74, Desk4.bg);
    IF sel >= 0 THEN
      Fs2.Name(sel, nm); Desk4.Centre(W DIV 2, lTop - 66, nm, 3, Desk4.Accent());
      s := "CELL "; Addr(sel, nm); Add(s, nm); Add(s, "   ("); AddN(s, Fs2.X(sel)); Add(s, ","); AddN(s, Fs2.Y(sel)); Add(s, ",");
      AddN(s, Fs2.Z(sel)); Add(s, ")"); Desk4.Centre(W DIV 2, lTop - 32, s, 2, Desk4.muted)
    ELSE Desk4.Centre(W DIV 2, lTop - 50, "TAP A FILE: ITS CELL LIGHTS UP", 2, Desk4.muted)
    END;
    OllGL6.Dreptunghi2D(0, lTop - 2, W, 1, Desk4.edge);
    (* the buttons of the chosen file *)
    OllGL6.Dreptunghi2D(0, lBot, W, H - lBot + 80, Desk4.dark);
    IF sel >= 0 THEN
      Fs2.Name(sel, nm);
      FOR b := 0 TO 4 DO
        IF Has(b, nm) THEN
          IF (b = 4) & (sure > 0) THEN OllGL6.Rotund2D(20 + b * bw + 3, aY, bw - 6, 52, 18, Desk4.red)
          ELSE OllGL6.Rotund2D(20 + b * bw + 3, aY, bw - 6, 52, 18, Desk4.surface2)
          END;
          Label(b, s); Desk4.Centre(20 + b * bw + bw DIV 2, aY + 20, s, 2, Desk4.text)
        END
      END
    END;
    OllGL6.Rotund2D(W DIV 2 - 70, H - 62, 140, 44, 22, Desk4.surface2); Desk4.Centre(W DIV 2, H - 46, "HOME", 2, Desk4.text);
    OllGL6.Arata
    RETURN r
  END Frame;

  PROCEDURE Enter*;
  BEGIN down := TRUE; moved := TRUE; Fs2.Sync; sure := 0
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h; lTop := 470; aY := H - 146; lBot := aY - 12
  END Start;

BEGIN
  W := 1; H := 1; sel := -1; scroll := 0; down := FALSE; moved := FALSE; angle := 0.4; sure := 0; lTop := 470; lBot := 900; aY := 900
END Files3.
