MODULE Files14;  (* COBWEB 14 (21 Nov 2026, Pixipogo 30): FIND. A few letters (the small keyboard, or a real one) and
     the list keeps only the files whose names have them; FIND again closes it and shows all. OPEN on a .txt opens it
     in QUINCE, the notebook (19).
   COBWEB 13 (20 Nov 2026, Cubicum N 28): OPEN on a film plays it in JUNO (18).
   COBWEB 12 (20 Nov 2026, Cubicum N 26): the same, with the fairies from Zane4.
   COBWEB 11 (20 Nov 2026, Cubicum N 25): the same as 10, with the fairies from Zane3.
   COBWEB 10 (20 Nov 2026, Cubicum N 24): OPEN on a song plays it in PHILOMEL (16), on a .pdf it
     opens the book in PEASEBLOSSOM (17); everything else as in 9.
   COBWEB 9 (20 Nov 2026, Cubicum N 23): a PDF looked like text (its first 512 bytes are letters), so it still
     opened in the editor. Now the ending decides first: pdf, photos, music, video, documents, archives go to the phone;
     the bytes decide only for an ending it does not know. Pion: "it opens the same".
   COBWEB 8 (20 Nov 2026, Cubicum N 22): OPEN on a file that is not text (a PDF, a photo, a document ...)
     gives it to the phone: it goes to Download/CubicumN and the phone opens it with its own app (window ecran-cubn22.dex:
     view.txt + view-go -> view-ok.txt). Text still opens in the editor, pictures of the cube in IRIS.
     Pion: "it imports it, but when I open it the code shows".
   COBWEB 7 (20 Nov 2026, Cubicum N 21): a file that came with IMPORT is put into the cube (Fs2.Add; before it
     stayed outside, and the cube still had 18 files), and what IMPORT and EXPORT say stays on the screen for 8 seconds,
     with where the file went. Pion: "it writes something but too fast to read".
   COBWEB 6 (20 Nov 2026, Cubicum N 20): Files 5 with IRIS from Zane1.
   COBWEB (20 Nov 2026, Cubicum N 19): FILES 4 with a fairy name; the web keeps what it caught. IRIS opens pictures.
   FILES 4 (20 Nov 2026, Cubicum N 18): IMPORT (a file from the phone, by its file picker) and EXPORT
     (to Download/CubicumN on the phone), through Gazda4; OPEN on a picture shows it in IMAGES.
   FILES 3 (19 Nov 2026, Cubicum N 17): Files 2 with OllGL6, Desk4, Shell13.
   FILES 2 (19 Nov 2026, Cubicum N 16): Files 1 with Desk3 and Shell11.
   FILES 1 (19 Nov 2026, Cubicum N 15): the files of Cubicum N with their cube.
     Above: the Cubicum FS cube; the cells that hold a file are lit, the chosen file is red and big.
     Below: the list (name, size, the 7 digits of its address). Tap a file, then:
       OPEN    the editor of the shell          RUN     a .mod or .z7 program
       PACK    a Z7 Arch cube NAME.z7c          UNPACK  every file out of a .z7c
       DELETE  (tap twice: SURE?)
     The work is done by the shell (Shell11.Do), so the shell shows what happened.
   Pion & Claude, 19.11.2026 *)

  IMPORT Math, Ecran, Fisier, Ceas, OllGL6, Fs2, Desk6, Shell13, Gazda4, Zane4, Juno1, Quince1;

  CONST BAR = 40; RH = 66; NB = 6; NF = 600; KR = 52;   (* list rows; buttons; the files found; a row of keys *)

  VAR note: ARRAY 80 OF CHAR; tNote, viewSt, tView: INTEGER;   (* viewSt: 1 = the phone is opening a file *)   (* the message of IMPORT / EXPORT, and how many frames it stays *)
    W, H, sel, scroll, scroll0, x0, y0, lTop, lBot, aY, sure: INTEGER;
    down, moved: BOOLEAN; angle: REAL;
    finding: BOOLEAN; q: ARRAY 24 OF CHAR; nq, hw, nf, kTop: INTEGER; found: ARRAY NF OF INTEGER;   (* FIND *)

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

  (* the buttons of the chosen file: 0 OPEN, 1 RUN, 2 PACK, 3 UNPACK, 4 EXPORT, 5 DELETE *)

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
    ELSIF b = 4 THEN Put("EXPORT", s) ELSIF sure > 0 THEN Put("SURE?", s) ELSE Put("DELETE", s) END
  END Label;

  PROCEDURE Note(t: ARRAY OF CHAR);
  BEGIN note[0] := 0X; Add(note, t); tNote := 480
  END Note;

  PROCEDURE ForPhone(VAR nm: ARRAY OF CHAR): BOOLEAN;   (* an ending that only the phone can show *)
  BEGIN
    RETURN Ends(nm, ".pdf") OR Ends(nm, ".jpg") OR Ends(nm, ".jpeg") OR Ends(nm, ".png") OR Ends(nm, ".gif") OR Ends(nm, ".webp")
      OR Ends(nm, ".heic") OR Ends(nm, ".mp3") OR Ends(nm, ".m4a") OR Ends(nm, ".ogg") OR Ends(nm, ".wav") OR Ends(nm, ".flac")
      OR Ends(nm, ".mp4") OR Ends(nm, ".mkv") OR Ends(nm, ".webm") OR Ends(nm, ".avi") OR Ends(nm, ".3gp") OR Ends(nm, ".doc")
      OR Ends(nm, ".docx") OR Ends(nm, ".xls") OR Ends(nm, ".xlsx") OR Ends(nm, ".ppt") OR Ends(nm, ".pptx") OR Ends(nm, ".odt")
      OR Ends(nm, ".epub") OR Ends(nm, ".zip") OR Ends(nm, ".apk") OR Ends(nm, ".rar") OR Ends(nm, ".7z")
  END ForPhone;

  PROCEDURE IsText(VAR nm: ARRAY OF CHAR): BOOLEAN;   (* its first 512 bytes are letters, not a binary file *)
    VAR h, b, n, bad: INTEGER;
  BEGIN
    n := 0; bad := 0; h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      b := Fisier.Citeste(h);
      WHILE (b >= 0) & (n < 512) DO
        IF (b < 9) OR (b > 13) & (b < 32) OR (b = 127) THEN INC(bad) END;
        INC(n); b := Fisier.Citeste(h)
      END;
      Fisier.Gata(h)
    END
    RETURN bad * 20 <= n
  END IsText;

  PROCEDURE ViewOnPhone(VAR nm: ARRAY OF CHAR);   (* the phone opens it with its own app *)
    VAR h, i: INTEGER;
  BEGIN
    IF ~Gazda4.Hosted() THEN Note("NO HOST: THIS FILE IS NOT TEXT")
    ELSE
      Fisier.Sterge("view-ok.txt"); h := Fisier.Creeaza("view.txt");
      IF h >= 0 THEN
        i := 0; WHILE nm[i] # 0X DO Fisier.Scrie(h, ORD(nm[i])); INC(i) END; Fisier.Scrie(h, 10); Fisier.Gata(h);
        h := Fisier.Creeaza("view-go"); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END;
        viewSt := 1; tView := Ceas.Ms(); Note("OPENING IT ON THE PHONE ...")
      END
    END
  END ViewOnPhone;

  PROCEDURE ViewResult;   (* what the phone said *)
    VAR h, b, n: INTEGER; s: ARRAY 64 OF CHAR;
  BEGIN
    IF (viewSt = 1) & (Ceas.Ms() - tView > 300) THEN
      tView := Ceas.Ms(); h := Fisier.Deschide("view-ok.txt");
      IF h >= 0 THEN
        b := Fisier.Citeste(h); n := 0;
        IF b = ORD("1") THEN
          b := Fisier.Citeste(h); b := Fisier.Citeste(h);
          WHILE (b >= 32) & (n < LEN(s) - 1) DO s[n] := CHR(b); INC(n); b := Fisier.Citeste(h) END; s[n] := 0X;
          note := "THE PHONE OPENED IT. A COPY IS IN "; Add(note, s); tNote := 480
        ELSE Note("THE PHONE HAS NO APP FOR THIS FILE")
        END;
        Fisier.Gata(h); Fisier.Sterge("view-ok.txt"); viewSt := 0
      ELSIF Ceas.Ms() - tView > 15000 THEN viewSt := 0
      END
    END
  END ViewResult;

  PROCEDURE Do(b: INTEGER): INTEGER;   (* button b on the chosen file; 3 = go to the shell *)
    VAR nm, bs: ARRAY 40 OF CHAR; cmd: ARRAY 48 OF CHAR; r, k: INTEGER;
  BEGIN
    r := 0; Fs2.Name(sel, nm); Base(nm, bs);
    IF (b = 0) & Zane4.IrIsPicture(nm) THEN Zane4.IrShow(nm); r := 14
    ELSIF (b = 0) & Juno1.IsFilm(nm) THEN Juno1.Show(nm); r := 18
    ELSIF (b = 0) & Quince1.IsNote(nm) THEN Quince1.Open(nm); r := 19
    ELSIF (b = 0) & Zane4.PhIsSong(nm) THEN Zane4.PhPlay(nm); r := 16
    ELSIF (b = 0) & Zane4.PbIsBook(nm) THEN Zane4.PbShow(nm); r := 17
    ELSIF (b = 0) & (ForPhone(nm) OR ~IsText(nm)) THEN ViewOnPhone(nm)
    ELSIF b = 0 THEN cmd := "edit "; Add(cmd, nm); k := Shell13.Do(cmd); r := 3
    ELSIF b = 1 THEN cmd := "run "; Add(cmd, bs); k := Shell13.Do(cmd); r := 3
    ELSIF b = 2 THEN cmd := "arch pack "; Add(cmd, bs); Add(cmd, " "); Add(cmd, nm); k := Shell13.Do(cmd); r := 3
    ELSIF b = 3 THEN cmd := "arch all "; Add(cmd, bs); k := Shell13.Do(cmd); r := 3
    ELSIF b = 4 THEN
      IF Gazda4.Hosted() THEN Gazda4.Export(nm); Note("SAVING ON THE PHONE ...") ELSE Note("NO HOST: NOWHERE TO EXPORT") END
    ELSIF sure = 0 THEN sure := 120   (* the first tap only asks *)
    ELSE
      cmd := "rm "; Add(cmd, nm); k := Shell13.Do(cmd); k := Shell13.Do(cmd);   (* the shell deletes on the second RM *)
      Fs2.Sync; sure := 0; sel := -1; cmd := "DELETED "; Add(cmd, nm); Desk6.Say(cmd)
    END
    RETURN r
  END Do;

  PROCEDURE Results;   (* what the phone answered to IMPORT and EXPORT *)
    VAR nm, p: ARRAY 64 OF CHAR; s: ARRAY 80 OF CHAR; k: INTEGER;
  BEGIN
    k := Gazda4.ImportState();
    IF k = 2 THEN
      Gazda4.ImportDone; Gazda4.ImportName(nm); Gazda4.ImportPpm(p);
      k := Fs2.Add(nm); IF p[0] # 0X THEN k := Fs2.Add(p) END;   (* into the cube *)
      Fs2.Sync; sel := Fs2.Find(nm); scroll := 0;
      s := "IMPORTED "; Add(s, nm); IF p[0] # 0X THEN Add(s, " + "); Add(s, p) END; Note(s)
    ELSIF k = 3 THEN Gazda4.ImportDone; Note("NOTHING CAME IN")
    END;
    k := Gazda4.ExportState();
    IF k = 2 THEN Gazda4.ExportDone; Gazda4.ExportPath(p); s := "SAVED ON THE PHONE: "; Add(s, p); Note(s)
    ELSIF k = 3 THEN Gazda4.ExportDone; Note("COULD NOT SAVE IT ON THE PHONE")
    END
  END Results;

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
      IF (x = sx) & (y = sy) & (z = sz) THEN OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.9, Desk6.red)
      ELSIF k >= 0 THEN OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.6, Desk6.Accent())
      ELSE
        c := OllGL6.RGB(30 + x * 12, 24 + y * 10, 50 + z * 14);
        OllGL6.Cub(FLT(x - 3), FLT(y - 3), FLT(z - 3), 0.22, c)
      END
    END END END
  END Cube;


  (* ---------- FIND ---------- *)

  PROCEDURE Low(c: CHAR): CHAR;
  BEGIN IF (c >= "A") & (c <= "Z") THEN c := CHR(ORD(c) + 32) END
    RETURN c
  END Low;

  PROCEDURE Matches(VAR nm: ARRAY OF CHAR): BOOLEAN;   (* q is somewhere in nm *)
    VAR i, j: INTEGER; ok: BOOLEAN;
  BEGIN
    IF nq = 0 THEN ok := TRUE
    ELSE
      ok := FALSE; i := 0;
      WHILE ~ok & (nm[i] # 0X) DO
        j := 0; WHILE (j < nq) & (nm[i + j] # 0X) & (Low(nm[i + j]) = q[j]) DO INC(j) END;
        ok := j = nq; INC(i)
      END
    END
    RETURN ok
  END Matches;

  PROCEDURE Filter;   (* found[]: the files to show *)
    VAR i, n: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    n := Fs2.Count(); nf := 0;
    FOR i := 0 TO n - 1 DO Fs2.Name(i, nm); IF (~finding OR Matches(nm)) & (nf < NF) THEN found[nf] := i; INC(nf) END END
  END Filter;

  PROCEDURE Type(c: INTEGER);   (* a letter more, 8 = one less *)
  BEGIN
    IF c = 8 THEN IF nq > 0 THEN DEC(nq); q[nq] := 0X END
    ELSIF (c > 32) & (c < 127) & (nq < LEN(q) - 1) THEN q[nq] := Low(CHR(c)); INC(nq); q[nq] := 0X
    END;
    scroll := 0
  END Type;

  PROCEDURE KeyRow(s: ARRAY OF CHAR; y: INTEGER);
    VAR i, kw: INTEGER; l: ARRAY 2 OF CHAR;
  BEGIN
    kw := (W - 24) DIV 10; l[1] := 0X; i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO
      l[0] := s[i]; OllGL6.Rotund2D(12 + i * kw + 2, y + 3, kw - 4, KR - 6, 10, Desk6.surface2);
      IF s[i] = "_" THEN OllGL6.Dreptunghi2D(12 + i * kw + kw DIV 2 - 8, y + 30, 16, 3, Desk6.text)   (* the font has no _ *)
      ELSE Desk6.Centre(12 + i * kw + kw DIV 2, y + 16, l, 2, Desk6.text)
      END;
      INC(i)
    END
  END KeyRow;

  PROCEDURE KeyAt(x, y: INTEGER): INTEGER;   (* what key is at x, y: a character, 8 delete, 1 done, 0 none *)
    VAR row, col, kw, k: INTEGER; s: ARRAY 12 OF CHAR;
  BEGIN
    k := 0; kw := (W - 24) DIV 10; row := (y - kTop) DIV KR; col := (x - 12) DIV kw;
    IF (y >= kTop) & (row >= 0) & (row < 4) & (col >= 0) & (col < 10) THEN
      IF row = 0 THEN s := "1234567890" ELSIF row = 1 THEN s := "qwertyuiop" ELSIF row = 2 THEN s := "asdfghjkl-" ELSE s := "zxcvbnm._ " END;
      k := ORD(s[col]); IF k = 32 THEN k := 8 END
    ELSIF row = 4 THEN IF x < W DIV 2 THEN k := 8 ELSE k := 1 END
    END
    RETURN k
  END KeyAt;

  PROCEDURE Keyboard;
  BEGIN
    OllGL6.Dreptunghi2D(0, kTop - 6, W, H - kTop + 80, Desk6.dark);
    KeyRow("1234567890", kTop); KeyRow("qwertyuiop", kTop + KR); KeyRow("asdfghjkl-", kTop + 2 * KR); KeyRow("zxcvbnm._", kTop + 3 * KR);
    OllGL6.Rotund2D(12 + 9 * ((W - 24) DIV 10) + 2, kTop + 3 * KR + 3, (W - 24) DIV 10 - 4, KR - 6, 10, Desk6.surface2);
    Desk6.Centre(12 + 9 * ((W - 24) DIV 10) + (W - 24) DIV 20, kTop + 3 * KR + 16, "<", 2, Desk6.red);
    OllGL6.Rotund2D(14, kTop + 4 * KR + 3, W DIV 2 - 20, KR - 6, 14, Desk6.surface2); Desk6.Centre(W DIV 4, kTop + 4 * KR + 16, "DEL", 2, Desk6.text);
    OllGL6.Rotund2D(W DIV 2 + 6, kTop + 4 * KR + 3, W DIV 2 - 20, KR - 6, 14, Desk6.Accent()); Desk6.Centre(3 * W DIV 4, kTop + 4 * KR + 16, "DONE", 2, Desk6.dark)
  END Keyboard;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME, 3 SHELL, 14 IMAGES, 16 MUSIC, 17 BOOKS *)
    VAR r, i, n, yy, b, bw, lim, k: INTEGER; nm: ARRAY 40 OF CHAR; s: ARRAY 80 OF CHAR;
  BEGIN
    r := 0; n := Fs2.Count(); IF sel >= n THEN sel := -1 END;
    IF finding THEN   (* a real keyboard types too *)
      k := Ecran.Citeste(16); IF k # hw THEN hw := k; k := Ecran.Citeste(15); IF k = 1067 THEN Type(8) ELSIF k = 10 THEN finding := FALSE ELSE Type(k) END END
    END;
    Filter; n := nf; IF finding THEN lBot := kTop - 10 ELSE lBot := aY - 12 END;
    IF sure > 0 THEN DEC(sure) END;
    lim := lBot - lTop - n * RH; IF lim > 0 THEN lim := 0 END;
    bw := (W - 40) DIV NB;
    Results; ViewResult;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll
    ELSIF isDown THEN
      IF ABS(y - y0) > 14 THEN moved := TRUE END;
      IF moved & (y0 >= lTop) & (y0 < lBot) THEN scroll := scroll0 + y - y0 END
    ELSIF down THEN
      down := FALSE;
      IF ~moved THEN
        IF (y0 >= lTop) & (y0 < lBot) THEN
          i := (y0 - lTop - scroll) DIV RH;
          IF (i >= 0) & (i < n) THEN sel := found[i]; sure := 0 END
        ELSIF finding & (y0 >= kTop) THEN
          k := KeyAt(x0, y0); IF k = 1 THEN finding := FALSE ELSIF k # 0 THEN Type(k) END
        ELSIF (y0 >= aY) & (y0 < aY + 56) & (sel >= 0) THEN
          b := (x0 - 20) DIV bw; Fs2.Name(sel, nm);
          IF (b >= 0) & (b < NB) & Has(b, nm) THEN r := Do(b) END
        ELSIF (y0 >= BAR + 4) & (y0 < BAR + 56) & (x0 > W - 296) & (x0 <= W - 176) THEN   (* FIND *)
          finding := ~finding; q[0] := 0X; nq := 0; hw := Ecran.Citeste(16); scroll := 0
        ELSIF (y0 >= BAR + 4) & (y0 < BAR + 56) & (x0 > W - 170) THEN
          IF ~Gazda4.Hosted() THEN Desk6.Say("NO HOST: NO PHONE TO IMPORT FROM")
          ELSIF Gazda4.ImportState() # 1 THEN Gazda4.Import
          END
        ELSIF y0 >= H - 76 THEN r := -1
        END
      END
    END;
    IF scroll > 0 THEN scroll := 0 ELSIF scroll < lim THEN scroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    Cube;
    FOR i := 0 TO n - 1 DO   (* the list *)
      yy := lTop + scroll + i * RH;
      IF (yy > lTop - RH) & (yy < lBot) THEN
        Fs2.Name(found[i], nm);
        IF found[i] = sel THEN OllGL6.Rotund2D(12, yy + 2, W - 24, RH - 4, 14, Desk6.surface2) END;
        Desk6.Glyph(Desk6.KindOf(nm), 22, yy + 9, 48);
        OllGL6.Text2D(84, yy + 12, nm, 2, Desk6.text);
        Addr(found[i], s); OllGL6.Text2D(84, yy + 40, s, 1, Desk6.muted);
        Size(Fs2.SizeOf(nm), s); k := Len(s) * 12 - 2; OllGL6.Text2D(W - 24 - k, yy + 12, s, 2, Desk6.muted)
      END
    END;
    IF (n = 0) & finding THEN Desk6.Centre(W DIV 2, lTop + 40, "NOTHING WITH THESE LETTERS", 2, Desk6.muted)
    ELSIF n = 0 THEN Desk6.Centre(W DIV 2, lTop + 40, "NO FILES YET", 2, Desk6.muted)
    END;
    (* the header and the chosen file, over the list *)
    OllGL6.Dreptunghi2D(0, BAR, W, 50, Desk6.bg);
    Desk6.Status;
    OllGL6.Text2D(24, BAR + 14, "COBWEB", 4, Desk6.text);
    IF Gazda4.ImportState() = 1 THEN OllGL6.Rotund2D(W - 166, BAR + 6, 142, 46, 23, Desk6.edge); Desk6.Centre(W - 95, BAR + 21, "...", 2, Desk6.text)
    ELSE OllGL6.Rotund2D(W - 166, BAR + 6, 142, 46, 23, Desk6.Accent()); Desk6.Centre(W - 95, BAR + 21, "IMPORT", 2, Desk6.dark)
    END;
    IF finding THEN OllGL6.Rotund2D(W - 292, BAR + 6, 116, 46, 23, Desk6.Accent()); Desk6.Centre(W - 234, BAR + 21, "FIND", 2, Desk6.dark)
    ELSE OllGL6.Rotund2D(W - 292, BAR + 6, 116, 46, 23, Desk6.surface2); Desk6.Centre(W - 234, BAR + 21, "FIND", 2, Desk6.text)
    END;
    OllGL6.Dreptunghi2D(0, lTop - 74, W, 74, Desk6.bg);
    IF finding THEN   (* the letters searched for *)
      OllGL6.Rotund2D(24, lTop - 66, W - 48, 52, 26, Desk6.surface);
      s := "FIND: "; Add(s, q); IF (Ceas.Ms() DIV 500) MOD 2 = 0 THEN Add(s, "_") END;
      OllGL6.Text2D(44, lTop - 50, s, 2, Desk6.text);
      s[0] := 0X; AddN(s, n); Add(s, " FOUND"); k := Len(s) * 12; OllGL6.Text2D(W - 44 - k, lTop - 50, s, 2, Desk6.muted)
    ELSIF sel >= 0 THEN
      Fs2.Name(sel, nm); Desk6.Centre(W DIV 2, lTop - 66, nm, 3, Desk6.Accent());
      s := "CELL "; Addr(sel, nm); Add(s, nm); Add(s, "   ("); AddN(s, Fs2.X(sel)); Add(s, ","); AddN(s, Fs2.Y(sel)); Add(s, ",");
      AddN(s, Fs2.Z(sel)); Add(s, ")"); Desk6.Centre(W DIV 2, lTop - 32, s, 2, Desk6.muted)
    ELSE s[0] := 0X; AddN(s, n); Add(s, " FILES . TAP ONE: ITS CELL LIGHTS UP"); Desk6.Centre(W DIV 2, lTop - 50, s, 2, Desk6.muted)
    END;
    OllGL6.Dreptunghi2D(0, lTop - 2, W, 1, Desk6.edge);
    (* the buttons of the chosen file *)
    OllGL6.Dreptunghi2D(0, lBot, W, H - lBot + 80, Desk6.dark);
    IF sel >= 0 THEN
      Fs2.Name(sel, nm);
      FOR b := 0 TO NB - 1 DO
        IF Has(b, nm) THEN
          IF (b = 5) & (sure > 0) THEN OllGL6.Rotund2D(20 + b * bw + 3, aY, bw - 6, 52, 18, Desk6.red)
          ELSE OllGL6.Rotund2D(20 + b * bw + 3, aY, bw - 6, 52, 18, Desk6.surface2)
          END;
          Label(b, s); Desk6.Centre(20 + b * bw + bw DIV 2, aY + 20, s, 2, Desk6.text)
        END
      END
    END;
    IF finding THEN Keyboard END;
    OllGL6.Rotund2D(W DIV 2 - 70, H - 62, 140, 44, 22, Desk6.surface2); Desk6.Centre(W DIV 2, H - 46, "HOME", 2, Desk6.text);
    IF tNote > 0 THEN   (* the message, long enough to read; it may need two rows *)
      DEC(tNote); OllGL6.Rotund2D(16, lBot - 84, W - 32, 76, 20, Desk6.surface2);
      IF Len(note) * 12 <= W - 56 THEN Desk6.Centre(W DIV 2, lBot - 54, note, 2, Desk6.Accent())
      ELSE
        k := 0; i := (W - 56) DIV 12; WHILE (i > 0) & (note[i] # " ") DO DEC(i) END; IF i = 0 THEN i := (W - 56) DIV 12 END;
        FOR k := 0 TO i - 1 DO s[k] := note[k] END; s[i] := 0X; Desk6.Centre(W DIV 2, lBot - 70, s, 2, Desk6.Accent());
        k := 0; WHILE (note[i + 1 + k] # 0X) & (k < LEN(s) - 1) DO s[k] := note[i + 1 + k]; INC(k) END; s[k] := 0X;
        Desk6.Centre(W DIV 2, lBot - 40, s, 2, Desk6.Accent())
      END
    ELSE Desk6.Toast(lBot - 56)
    END;
    OllGL6.Arata
    RETURN r
  END Frame;

  PROCEDURE Enter*;
  BEGIN down := TRUE; moved := TRUE; Fs2.Sync; sure := 0; hw := Ecran.Citeste(16)
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h; lTop := 470; aY := H - 146; lBot := aY - 12; kTop := H - 80 - 5 * KR
  END Start;

BEGIN
  note[0] := 0X; tNote := 0; viewSt := 0; tView := 0; W := 1; H := 1; sel := -1; scroll := 0; down := FALSE; moved := FALSE; angle := 0.4; sure := 0; lTop := 470; lBot := 900; aY := 900;
  finding := FALSE; q[0] := 0X; nq := 0; hw := 0; nf := 0; kTop := 600
END Files14.
