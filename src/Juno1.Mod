MODULE Juno1;  (* JUNO 1 (20 Nov 2026, Pixipogo / Cubicum N 28): the films of the cube. In The Tempest the spirits of
     Prospero play a masque for the lovers, and Juno comes on the stage; here she plays the films.
     The phone plays the film in a place over the screen (window ecran-cubn28.dex: vid.txt + vid-go, it answers in
     vid-st.txt "state pos dur"); the buttons, the bar of the time and the list are drawn here. FULL gives the film the
     whole screen, and a tap anywhere brings the buttons back. A film stops PHILOMEL's song while it plays.
     Pion: "something like vlc to play video".
   Pion & Claude, 20.11.2026 *)

  IMPORT Fisier, Ceas, OllGL6, Fs2, Gazda4, Desk6;

  CONST NL = 300; RH = 64;

  VAR W, H, x0, y0, scroll, scroll0, n, st, pos, dur, tPoll, tSent: INTEGER;
    down, moved, shown, full: BOOLEAN;
    list: ARRAY NL OF INTEGER;
    film: ARRAY 40 OF CHAR;

  PROCEDURE Len(s: ARRAY OF CHAR): INTEGER;
    VAR k: INTEGER;
  BEGIN k := 0; WHILE (k < LEN(s)) & (s[k] # 0X) DO INC(k) END
    RETURN k
  END Len;

  PROCEDURE Copy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(d) - 1) DO d[i] := s[i]; INC(i) END; d[i] := 0X
  END Copy;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := Len(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END Add;

  PROCEDURE AddN(VAR s: ARRAY OF CHAR; v: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF v < 0 THEN v := 0 END;
    REPEAT d[k] := CHR(ORD("0") + v MOD 10); v := v DIV 10; INC(k) UNTIL v = 0;
    j := Len(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END AddN;

  PROCEDURE AddTime(VAR s: ARRAY OF CHAR; ms: INTEGER);   (* m:ss, or h:mm:ss for a long film *)
    VAR sec: INTEGER;
  BEGIN
    sec := ms DIV 1000;
    IF sec >= 3600 THEN AddN(s, sec DIV 3600); Add(s, ":"); IF sec DIV 60 MOD 60 < 10 THEN Add(s, "0") END END;
    AddN(s, sec DIV 60 MOD 60); Add(s, ":"); IF sec MOD 60 < 10 THEN Add(s, "0") END; AddN(s, sec MOD 60)
  END AddTime;

  PROCEDURE Same(a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN a[i] = b[i]
  END Same;

  PROCEDURE Short(VAR s: ARRAY OF CHAR; k: INTEGER);
  BEGIN IF Len(s) > k THEN s[k - 1] := "."; s[k] := 0X END
  END Short;

  PROCEDURE Put(h: INTEGER; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Fisier.Scrie(h, ORD(s[i])); INC(i) END
  END Put;

  PROCEDURE Tell(file, go: ARRAY OF CHAR; cmd: ARRAY OF CHAR);   (* one command for the window *)
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Creeaza(file);
    IF h >= 0 THEN
      Put(h, cmd); Fisier.Scrie(h, 10); Fisier.Gata(h);
      h := Fisier.Creeaza(go); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END
    END;
    tSent := Ceas.Ms()
  END Tell;

  PROCEDURE ReadNums(nm: ARRAY OF CHAR; VAR v: ARRAY OF INTEGER): INTEGER;
    VAR h, c, k: INTEGER; inNum: BOOLEAN;
  BEGIN
    k := 0; h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      inNum := FALSE; c := Fisier.Citeste(h);
      WHILE (c >= 0) & (c # 10) & (k < LEN(v)) DO
        IF (c >= ORD("0")) & (c <= ORD("9")) THEN
          IF ~inNum THEN v[k] := 0; inNum := TRUE END;
          v[k] := v[k] * 10 + c - ORD("0")
        ELSIF inNum THEN inNum := FALSE; INC(k)
        END;
        c := Fisier.Citeste(h)
      END;
      IF inNum & (k < LEN(v)) THEN INC(k) END;
      Fisier.Gata(h)
    END
    RETURN k
  END ReadNums;

  PROCEDURE Button(x, y, w: INTEGER; s: ARRAY OF CHAR; on: BOOLEAN);
  BEGIN
    IF on THEN OllGL6.Rotund2D(x, y, w, 56, 28, Desk6.Accent()); Desk6.Centre(x + w DIV 2, y + 20, s, 2, Desk6.dark)
    ELSE OllGL6.Rotund2D(x, y, w, 56, 28, Desk6.surface2); Desk6.Centre(x + w DIV 2, y + 20, s, 2, Desk6.text)
    END
  END Button;

  (* ---------- the place of the film ---------- *)

  PROCEDURE VH(): INTEGER;   (* the height of the film's place: 16 x 9 *)
  BEGIN RETURN (W - 32) * 9 DIV 16
  END VH;

  PROCEDURE Place(VAR s: ARRAY OF CHAR);   (* " x y w h W H" *)
  BEGIN
    IF full THEN Add(s, " 0 0 "); AddN(s, W); Add(s, " "); AddN(s, H)
    ELSE Add(s, " 16 120 "); AddN(s, W - 32); Add(s, " "); AddN(s, VH())
    END;
    Add(s, " "); AddN(s, W); Add(s, " "); AddN(s, H)
  END Place;

  PROCEDURE Move;   (* the film goes to its place: small or the whole screen *)
    VAR s: ARRAY 64 OF CHAR;
  BEGIN IF shown THEN s := "place"; Place(s); Tell("vid.txt", "vid-go", s) END
  END Move;

  PROCEDURE IsFilm*(VAR nm: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN Desk6.KindOf(nm) = 20
  END IsFilm;

  PROCEDURE Build;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    n := 0; Fs2.Sync;
    FOR i := 0 TO Fs2.Count() - 1 DO Fs2.Name(i, nm); IF IsFilm(nm) & (n < NL) THEN list[n] := i; INC(n) END END
  END Build;

  PROCEDURE Show*(nm: ARRAY OF CHAR);   (* plays film nm *)
    VAR s: ARRAY 96 OF CHAR; v: ARRAY 4 OF INTEGER;
  BEGIN
    Copy(nm, film); full := FALSE;
    IF ~Gazda4.Hosted() THEN Desk6.Say("NO HOST: NOBODY TO PLAY IT")
    ELSE
      IF (ReadNums("aud-st.txt", v) >= 1) & (v[0] = 1) THEN Tell("aud.txt", "aud-go", "pause") END;   (* PHILOMEL waits *)
      s := "play "; Add(s, nm); Place(s); Tell("vid.txt", "vid-go", s);
      shown := TRUE; st := 1; pos := 0; dur := 0
    END
  END Show;

  PROCEDURE Hide*;   (* the film stops when its screen is left *)
  BEGIN
    IF shown THEN Tell("vid.txt", "vid-go", "hide"); shown := FALSE; full := FALSE; st := 0 END
  END Hide;

  PROCEDURE Step(d: INTEGER);
    VAR i, k: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    Build; k := -1;
    FOR i := 0 TO n - 1 DO Fs2.Name(list[i], nm); IF Same(nm, film) THEN k := i END END;
    IF n > 0 THEN
      IF k < 0 THEN k := 0 ELSE k := (k + d + n) MOD n END;
      Fs2.Name(list[k], nm); Show(nm)
    END
  END Step;

  PROCEDURE Poll;
    VAR v: ARRAY 4 OF INTEGER; t: INTEGER;
  BEGIN
    t := Ceas.Ms();
    IF shown & (t - tPoll > 300) & (t - tSent > 700) THEN
      tPoll := t;
      IF ReadNums("vid-st.txt", v) >= 3 THEN st := v[0]; pos := v[1]; dur := v[2] END
    END
  END Poll;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, top, lim, bw, px, d, vy, by: INTEGER; s, nm: ARRAY 64 OF CHAR;
  BEGIN
    r := 0; Poll;
    vy := 120 + VH(); by := vy + 92; top := by + 76; bw := (W - 48) DIV 4;
    IF ~shown THEN top := 120 END;
    lim := H - 90 - top - n * RH; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll
    ELSIF isDown THEN
      IF ABS(y - y0) > 14 THEN moved := TRUE END;
      IF moved & (y0 >= top) & ~full THEN scroll := scroll0 + y - y0 END
    ELSIF down THEN
      down := FALSE;
      IF full THEN full := FALSE; Move   (* a tap on the whole-screen film: the buttons come back *)
      ELSIF ~moved THEN
        IF Desk6.IsHome(y0) THEN Hide; r := -1
        ELSIF shown & (y0 >= vy + 40) & (y0 < vy + 80) & (dur > 0) THEN   (* the bar of the time *)
          d := (x0 - 24) * (dur DIV 100) DIV (W - 48) * 100; IF d < 0 THEN d := 0 END;
          s := "seek "; AddN(s, d); Tell("vid.txt", "vid-go", s); pos := d
        ELSIF shown & (y0 >= by) & (y0 < by + 56) THEN
          i := (x0 - 24) DIV bw;
          IF i = 0 THEN Step(-1)
          ELSIF i = 1 THEN
            IF st = 1 THEN Tell("vid.txt", "vid-go", "pause"); st := 2
            ELSIF st = 2 THEN Tell("vid.txt", "vid-go", "resume"); st := 1
            ELSE Show(film)
            END
          ELSIF i = 2 THEN Step(1)
          ELSE full := TRUE; Move
          END
        ELSIF y0 >= top THEN
          i := (y0 - top - scroll) DIV RH;
          IF (i >= 0) & (i < n) THEN Fs2.Name(list[i], nm); Show(nm) END
        END
      END
    END;
    IF scroll > 0 THEN scroll := 0 ELSIF scroll < lim THEN scroll := lim END;
    IF full THEN OllGL6.Incepe(OllGL6.RGB(0, 0, 0))
    ELSE
      OllGL6.Incepe(Desk6.bg);
      FOR i := 0 TO n - 1 DO   (* the list *)
        yy := top + scroll + i * RH;
        IF (yy > top - RH) & (yy < H - 80) THEN
          Fs2.Name(list[i], nm);
          IF Same(nm, film) & shown THEN OllGL6.Rotund2D(16, yy, W - 32, RH - 6, 14, Desk6.surface2) END;
          Desk6.Glyph(20, 24, yy + 6, 46); Short(nm, 30); OllGL6.Text2D(88, yy + 20, nm, 2, Desk6.text)
        END
      END;
      IF n = 0 THEN
        Desk6.Centre(W DIV 2, top + 80, "NO FILMS IN THE CUBE YET", 2, Desk6.muted);
        Desk6.Centre(W DIV 2, top + 120, "FILES . IMPORT BRINGS ONE FROM THE PHONE", 2, Desk6.muted)
      END;
      IF shown THEN   (* the stage, over the list *)
        OllGL6.Dreptunghi2D(0, 0, W, top - 4, Desk6.bg);
        OllGL6.Rotund2D(10, 114, W - 20, VH() + 12, 10, OllGL6.RGB(0, 0, 0));
        IF st = 4 THEN Desk6.Centre(W DIV 2, 120 + VH() DIV 2, "THE PHONE CANNOT PLAY THIS FILM", 2, Desk6.red) END;
        Copy(film, s); Short(s, 22);
        nm[0] := 0X; AddTime(nm, pos); IF dur > 0 THEN Add(nm, " / "); AddTime(nm, dur) END;
        IF st = 2 THEN Add(nm, "  PAUSED") ELSIF st = 3 THEN Add(nm, "  END") END;
        OllGL6.Text2D(24, vy + 14, s, 2, Desk6.text); Desk6.Right(W - 24, vy + 14, nm, 2, Desk6.muted);
        OllGL6.Rotund2D(24, vy + 54, W - 48, 14, 7, Desk6.surface2);
        IF dur > 0 THEN
          px := (W - 48) * (pos DIV 100) DIV (dur DIV 100 + 1); IF px > W - 48 THEN px := W - 48 END;
          OllGL6.Rotund2D(24, vy + 54, px + 14, 14, 7, Desk6.Accent()); OllGL6.Cerc2D(24 + px + 7, vy + 61, 13, Desk6.text)
        END;
        Button(24, by, bw - 8, "PREV", FALSE);
        IF st = 1 THEN Button(24 + bw, by, bw - 8, "PAUSE", TRUE) ELSE Button(24 + bw, by, bw - 8, "PLAY", TRUE) END;
        Button(24 + 2 * bw, by, bw - 8, "NEXT", FALSE); Button(24 + 3 * bw, by, bw - 8, "FULL", FALSE)
      END;
      s[0] := 0X; AddN(s, n); Add(s, " FILMS . VIDEO"); Desk6.Header("JUNO", s);
      Desk6.Bottom; Desk6.Toast(H - 200)
    END;
    OllGL6.Arata
    RETURN r
  END Frame;

  PROCEDURE Enter*;
  BEGIN down := TRUE; moved := TRUE; Build
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h
  END Start;

BEGIN
  W := 1; H := 1; down := FALSE; moved := FALSE; shown := FALSE; full := FALSE; scroll := 0; n := 0;
  st := 0; pos := 0; dur := 0; tPoll := 0; tSent := 0; film[0] := 0X
END Juno1.
