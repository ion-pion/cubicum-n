MODULE Quince1;  (* QUINCE 1 (21 Nov 2026, Pixipogo 30): the notebook. In A Midsummer Night's Dream Peter Quince is the
     one who writes the play; here he keeps the notes of the cube: every .txt file, with its first line under its name.
     + NEW NOTE starts nota-YYYYMMDD-HHMM.txt; a tap opens a note in the editor of the shell (Edit4: the keyboard,
     SAVE puts it in the cube, X comes back here). Pion: "a notebook" (1 2 3: search, notebook, recorder).
   Pion & Claude, 21.11.2026 *)

  IMPORT Ecran, Fisier, OllGL6, Fs2, Desk6, Keys1, Edit4;

  CONST NL = 300; RH = 76; TOP = 196;

  VAR W, H, x0, y0, scroll, scroll0, n: INTEGER;
    down, moved, editing: BOOLEAN;
    list: ARRAY NL OF INTEGER;
    first: ARRAY NL, 44 OF CHAR;   (* the first line of each note *)

  PROCEDURE Len(s: ARRAY OF CHAR): INTEGER;
    VAR k: INTEGER;
  BEGIN k := 0; WHILE (k < LEN(s)) & (s[k] # 0X) DO INC(k) END
    RETURN k
  END Len;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := Len(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END Add;

  PROCEDURE AddN(VAR s: ARRAY OF CHAR; v, digits: INTEGER);   (* v with at least digits digits *)
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF v < 0 THEN v := 0 END;
    REPEAT d[k] := CHR(ORD("0") + v MOD 10); v := v DIV 10; INC(k) UNTIL (v = 0) & (k >= digits);
    j := Len(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END AddN;

  PROCEDURE Short(VAR s: ARRAY OF CHAR; k: INTEGER);
  BEGIN IF Len(s) > k THEN s[k - 1] := "."; s[k] := 0X END
  END Short;

  PROCEDURE IsNote*(VAR nm: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN Desk6.KindOf(nm) = 21
  END IsNote;

  PROCEDURE FirstLine(VAR nm: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);   (* the first line that is not empty *)
    VAR h, c, k: INTEGER;
  BEGIN
    k := 0; h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      c := Fisier.Citeste(h);
      WHILE (c = 10) OR (c = 13) OR (c = 32) DO c := Fisier.Citeste(h) END;
      WHILE (c >= 0) & (c # 10) & (c # 13) & (k < LEN(s) - 1) DO
        IF (c >= 32) & (c < 127) THEN s[k] := CHR(c); INC(k) END;
        c := Fisier.Citeste(h)
      END;
      Fisier.Gata(h)
    END;
    s[k] := 0X;
    IF (k = 0) & (LEN(s) > 2) THEN s[0] := "-"; s[1] := 0X END
  END FirstLine;

  PROCEDURE Build;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    n := 0; Fs2.Sync;
    FOR i := Fs2.Count() - 1 TO 0 BY -1 DO   (* the newest first *)
      Fs2.Name(i, nm);
      IF IsNote(nm) & (n < NL) THEN list[n] := i; FirstLine(nm, first[n]); INC(n) END
    END
  END Build;

  PROCEDURE NewName(VAR s: ARRAY OF CHAR);   (* nota-YYYYMMDD-HHMM.txt, or nota-YYYYMMDD-HHMM-2.txt ... *)
    VAR b: ARRAY 40 OF CHAR; k: INTEGER;
  BEGIN
    b := "nota-";
    IF Fs2.ReadClock() THEN
      AddN(b, Fs2.Now(0), 4); AddN(b, Fs2.Now(1), 2); AddN(b, Fs2.Now(2), 2); Add(b, "-"); AddN(b, Fs2.Now(3), 2); AddN(b, Fs2.Now(4), 2)
    ELSE AddN(b, n + 1, 1)
    END;
    s[0] := 0X; Add(s, b); Add(s, ".txt"); k := 2;
    WHILE Fs2.Exists(s) DO s[0] := 0X; Add(s, b); Add(s, "-"); AddN(s, k, 1); Add(s, ".txt"); INC(k) END
  END NewName;

  PROCEDURE Open*(nm: ARRAY OF CHAR);   (* a note in the editor *)
  BEGIN Keys1.Reset; Edit4.Open(nm); editing := TRUE
  END Open;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, lim: INTEGER; s, nm: ARRAY 64 OF CHAR;
  BEGIN
    r := 0;
    IF editing THEN
      IF Edit4.Frame(isDown, x, y) THEN editing := FALSE; down := TRUE; moved := TRUE; Build END;
      Ecran.Arata   (* the editor draws pixels, not triangles: its frame goes to the screen here *)
    ELSE
      lim := H - 90 - TOP - n * RH; IF lim > 0 THEN lim := 0 END;
      IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll
      ELSIF isDown THEN
        IF ABS(y - y0) > 14 THEN moved := TRUE END;
        IF moved & (y0 >= TOP) THEN scroll := scroll0 + y - y0 END
      ELSIF down THEN
        down := FALSE;
        IF ~moved THEN
          IF Desk6.IsHome(y0) THEN r := -1
          ELSIF (y0 >= 112) & (y0 < 172) THEN NewName(nm); Open(nm)
          ELSIF y0 >= TOP THEN
            i := (y0 - TOP - scroll) DIV RH;
            IF (i >= 0) & (i < n) THEN Fs2.Name(list[i], nm); Open(nm) END
          END
        END
      END;
      IF scroll > 0 THEN scroll := 0 ELSIF scroll < lim THEN scroll := lim END;
      IF ~editing THEN
        OllGL6.Incepe(Desk6.bg);
        FOR i := 0 TO n - 1 DO
          yy := TOP + scroll + i * RH;
          IF (yy > TOP - RH) & (yy < H - 80) THEN
            OllGL6.Rotund2D(16, yy, W - 32, RH - 8, 16, Desk6.surface);
            Desk6.Glyph(21, 26, yy + 10, 48);
            Fs2.Name(list[i], nm); Short(nm, 30); OllGL6.Text2D(90, yy + 14, nm, 2, Desk6.text);
            s[0] := 0X; Add(s, first[i]); Short(s, (W - 110) DIV 12); OllGL6.Text2D(90, yy + 42, s, 2, Desk6.muted)
          END
        END;
        IF n = 0 THEN
          Desk6.Centre(W DIV 2, TOP + 60, "NO NOTES YET", 2, Desk6.muted);
          Desk6.Centre(W DIV 2, TOP + 100, "+ NEW NOTE STARTS ONE", 2, Desk6.muted)
        END;
        OllGL6.Dreptunghi2D(0, 0, W, TOP - 8, Desk6.bg);
        OllGL6.Rotund2D(16, 112, W - 32, 60, 30, Desk6.Accent()); Desk6.Centre(W DIV 2, 132, "+ NEW NOTE", 3, Desk6.dark);
        s[0] := 0X; AddN(s, n, 1); Add(s, " NOTES . NOTES"); Desk6.Header("QUINCE", s);
        Desk6.Bottom; Desk6.Toast(H - 200);
        OllGL6.Arata
      END
    END
    RETURN r
  END Frame;

  PROCEDURE Enter*;
  BEGIN down := TRUE; moved := TRUE; IF ~editing THEN Build END
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h
  END Start;

BEGIN
  W := 1; H := 1; down := FALSE; moved := FALSE; editing := FALSE; scroll := 0; n := 0
END Quince1.
