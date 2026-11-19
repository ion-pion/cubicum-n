MODULE Edit4;  (* EDIT 4 (11 Nov 2026): the files go into Cubicum FS 2 (7 dimensions).
   EDIT 3 (11 Nov 2026): hold the finger on the text and a little menu comes: PASTE (at that place),
     COPY LINE, COPY ALL. The clipboard is the phone's and Cubicum N's own (Clip2), so copying between the shell and the
     editor works even with the old window.
   EDIT 2 (11 Nov 2026): COPY puts the whole text on the phone's clipboard, PASTE puts the clipboard's text
     at the cursor (Pion: "the shell has no copy paste"). So a program written somewhere else can be pasted here.
     Needs the window ecran-gl3-sunet3.dex (module Clip1).
   EDIT 1 (11 Nov 2026): the text editor of Cubicum N. Opened from the shell with EDIT name.
     Touch the text to put the cursor there, drag up and down to scroll, << >> move the cursor.
     ENTER keeps the indentation of the line above (good for Oberon). SAVE writes the file and puts it in the cube
     (Cubicum FS); X closes (if there are unsaved changes, it asks you to press X again).
       Edit1.Open(name)                   loads the file (or starts an empty one)
       Edit1.Frame(down, x, y)            one frame; TRUE = closed
     Pion & Claude, 11.11.2026 *)

  IMPORT Ecran, Ceas, Grafica, Fisier, Text1, Keys1, Fs2, Clip2;

  CONST
    RANDURI = 20; NLN = 400; NCH = 100; LH = 22; CW = 12;

  VAR
    W, H, kbTop, txTop, txBot, rows, cols: INTEGER;
    buf: ARRAY NLN, NCH OF CHAR; len: ARRAY NLN OF INTEGER; nl, cr, cc, top, left: INTEGER;
    name: ARRAY 40 OF CHAR; dirty, warned: BOOLEAN; msg: ARRAY 48 OF CHAR; msgCol: INTEGER;
    down, wasDown, hit, dragged: BOOLEAN; mx, my, y0, acc: INTEGER;
    bg, panel, gold, white, grey, cyan, green, red, black, violet: INTEGER;
    clip: ARRAY 60000 OF CHAR; pasting: BOOLEAN;
    holding, menu: BOOLEAN; holdT, x0, menuY: INTEGER;

  PROCEDURE SetMsg(s: ARRAY OF CHAR; c: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(s)) & (i < LEN(msg) - 1) & (s[i] # 0X) DO msg[i] := s[i]; INC(i) END;
    msg[i] := 0X; msgCol := c
  END SetMsg;

  PROCEDURE Start;
  BEGIN
    W := Ecran.Latime(); H := Ecran.Inaltime() - RANDURI;
    kbTop := H - Keys1.Height; txTop := 64; txBot := kbTop - 30;
    rows := (txBot - txTop) DIV LH; cols := (W - 16) DIV CW;
    bg := Grafica.RGB(14, 4, 28); panel := Grafica.RGB(52, 22, 86); gold := Grafica.RGB(212, 160, 23);
    white := Grafica.RGB(240, 235, 250); grey := Grafica.RGB(140, 130, 160); cyan := Grafica.RGB(125, 211, 252);
    green := Grafica.RGB(74, 222, 128); red := Grafica.RGB(239, 68, 68); black := Grafica.RGB(10, 4, 20);
    violet := Grafica.RGB(191, 128, 255)
  END Start;

  PROCEDURE Open*(nm: ARRAY OF CHAR);
    VAR h, b, i: INTEGER;
  BEGIN
    Start;
    i := 0; WHILE (i < LEN(nm)) & (i < LEN(name) - 1) & (nm[i] # 0X) DO name[i] := nm[i]; INC(i) END; name[i] := 0X;
    nl := 1; len[0] := 0; buf[0, 0] := 0X;
    h := Fisier.Deschide(name);
    IF h >= 0 THEN
      b := Fisier.Citeste(h);
      WHILE b >= 0 DO
        IF b = 10 THEN
          IF nl < NLN THEN len[nl] := 0; buf[nl, 0] := 0X; INC(nl) ELSE b := -2 END
        ELSIF b # 13 THEN
          IF b = 9 THEN b := 32 END;
          IF (len[nl - 1] >= NCH - 1) & (nl < NLN) THEN len[nl] := 0; buf[nl, 0] := 0X; INC(nl) END;   (* too long: goes on below *)
          IF len[nl - 1] < NCH - 1 THEN buf[nl - 1, len[nl - 1]] := CHR(b); INC(len[nl - 1]); buf[nl - 1, len[nl - 1]] := 0X END
        END;
        IF b # -2 THEN b := Fisier.Citeste(h) END
      END;
      Fisier.Gata(h); SetMsg("", grey)
    ELSE SetMsg("NEW FILE", green)
    END;
    cr := 0; cc := 0; top := 0; left := 0; dirty := FALSE; warned := FALSE; pasting := FALSE; holding := FALSE; menu := FALSE;
    down := TRUE; wasDown := TRUE; Keys1.Reset
  END Open;

  PROCEDURE Save;
    VAR h, i, j: INTEGER;
  BEGIN
    h := Fisier.Creeaza(name);
    IF h < 0 THEN SetMsg("COULD NOT SAVE", red)
    ELSE
      FOR i := 0 TO nl - 1 DO
        FOR j := 0 TO len[i] - 1 DO Fisier.Scrie(h, ORD(buf[i, j])) END;
        IF i < nl - 1 THEN Fisier.Scrie(h, 10) END
      END;
      Fisier.Gata(h);
      IF Fs2.Add(name) >= 0 THEN SetMsg("SAVED", green) ELSE SetMsg("SAVED (THE CUBE IS FULL)", gold) END;
      dirty := FALSE; warned := FALSE
    END
  END Save;

  (* ---------- changing the text ---------- *)

  PROCEDURE Insert(ch: CHAR);
    VAR j: INTEGER;
  BEGIN
    IF len[cr] < NCH - 1 THEN
      FOR j := len[cr] TO cc + 1 BY -1 DO buf[cr, j] := buf[cr, j - 1] END;
      buf[cr, cc] := ch; INC(len[cr]); buf[cr, len[cr]] := 0X; INC(cc); dirty := TRUE
    ELSE SetMsg("THE LINE IS FULL", red)
    END
  END Insert;

  PROCEDURE NewLine(keep: BOOLEAN);   (* keep: the same indentation as the line above *)
    VAR i, j, ind: INTEGER;
  BEGIN
    IF nl < NLN THEN
      FOR i := nl TO cr + 2 BY -1 DO buf[i] := buf[i - 1]; len[i] := len[i - 1] END;
      ind := 0; IF keep THEN WHILE (ind < cc) & (buf[cr, ind] = " ") DO INC(ind) END END;
      j := 0;
      WHILE j < ind DO buf[cr + 1, j] := " "; INC(j) END;
      i := cc; WHILE i < len[cr] DO buf[cr + 1, j] := buf[cr, i]; INC(i); INC(j) END;
      buf[cr + 1, j] := 0X; len[cr + 1] := j;
      len[cr] := cc; buf[cr, cc] := 0X;
      INC(nl); INC(cr); cc := ind; dirty := TRUE
    ELSE SetMsg("THE FILE IS FULL", red)
    END
  END NewLine;

  PROCEDURE Delete;
    VAR i, j: INTEGER;
  BEGIN
    IF cc > 0 THEN
      FOR j := cc - 1 TO len[cr] - 1 DO buf[cr, j] := buf[cr, j + 1] END;
      DEC(len[cr]); DEC(cc); dirty := TRUE
    ELSIF cr > 0 THEN
      IF len[cr - 1] + len[cr] < NCH - 1 THEN
        cc := len[cr - 1];
        FOR j := 0 TO len[cr] DO buf[cr - 1, cc + j] := buf[cr, j] END;
        len[cr - 1] := cc + len[cr];
        FOR i := cr TO nl - 2 DO buf[i] := buf[i + 1]; len[i] := len[i + 1] END;
        DEC(nl); DEC(cr); dirty := TRUE
      ELSE SetMsg("THE LINES ARE TOO LONG TO JOIN", red)
      END
    END
  END Delete;

  PROCEDURE CopyAll;
    VAR i, j: INTEGER;
  BEGIN
    Clip2.Begin;
    FOR i := 0 TO nl - 1 DO
      FOR j := 0 TO len[i] - 1 DO Clip2.Put(ORD(buf[i, j])) END;
      IF i < nl - 1 THEN Clip2.Put(10) END
    END;
    Clip2.End; SetMsg("COPIED: THE WHOLE TEXT", green)
  END CopyAll;

  PROCEDURE CopyLine;
    VAR j: INTEGER;
  BEGIN
    Clip2.Begin; FOR j := 0 TO len[cr] - 1 DO Clip2.Put(ORD(buf[cr, j])) END; Clip2.End;
    SetMsg("COPIED: THE LINE", green)
  END CopyLine;

  PROCEDURE PasteIn;   (* the clipboard's text at the cursor *)
    VAR n, i: INTEGER;
  BEGIN
    n := Clip2.Take(clip); i := 0;
    WHILE i < n DO
      IF clip[i] = 0AX THEN NewLine(FALSE) ELSIF clip[i] >= " " THEN Insert(clip[i]) END;
      INC(i)
    END;
    pasting := FALSE; SetMsg("PASTED", green)
  END PasteIn;

  PROCEDURE Visible;   (* the cursor stays on the screen *)
  BEGIN
    IF cr < top THEN top := cr ELSIF cr >= top + rows THEN top := cr - rows + 1 END;
    IF cc < left THEN left := cc - 8 ELSIF cc >= left + cols - 4 THEN left := cc - cols + 8 END;
    IF left < 0 THEN left := 0 END
  END Visible;

  (* ---------- frame ---------- *)

  PROCEDURE In(x, y, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (mx >= x) & (mx < x + w) & (my >= y) & (my < y + h)
  END In;

  PROCEDURE Button(x, y, w: INTEGER; s: ARRAY OF CHAR; c: INTEGER): BOOLEAN;
  BEGIN
    Grafica.Dreptunghi(x, y, w, 44, panel); Text1.Centre(x + w DIV 2, y + 15, s, 2, c)
    RETURN hit & In(x, y, w, 44)
  END Button;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): BOOLEAN;
    VAR i, k, r, yy: INTEGER; closed: BOOLEAN; t: ARRAY 16 OF CHAR;
  BEGIN
    wasDown := down; down := isDown; mx := x; my := y; hit := down & ~wasDown; closed := FALSE;
    (* the little menu: a touch on it, or anywhere else closes it *)
    IF menu & hit THEN
      menu := FALSE;
      IF In(4, menuY, 170, 52) THEN Clip2.Ask; pasting := TRUE; SetMsg("PASTING ...", grey)
      ELSIF In(184, menuY, 170, 52) THEN CopyLine
      ELSIF In(364, menuY, 170, 52) THEN CopyAll
      END;
      hit := FALSE; y0 := -1; dragged := TRUE
    END;
    (* holding the finger on the text: the cursor goes there and the menu comes *)
    IF hit & (y >= txTop) & (y < txBot) THEN holding := TRUE; holdT := Ceas.Ms(); x0 := x
    ELSIF ~down OR dragged OR (ABS(x - x0) > 14) THEN holding := FALSE
    ELSIF holding & (Ceas.Ms() - holdT > 450) THEN
      holding := FALSE; menu := TRUE; dragged := TRUE;
      cr := top + (my - txTop) DIV LH; IF cr > nl - 1 THEN cr := nl - 1 END;
      cc := left + (mx - 8 + CW DIV 2) DIV CW; IF cc > len[cr] THEN cc := len[cr] END; IF cc < 0 THEN cc := 0 END;
      menuY := my - 80; IF menuY < txTop THEN menuY := my + 30 END
    END;
    (* scroll by dragging, or touch to put the cursor *)
    IF hit THEN y0 := y; acc := 0; dragged := FALSE
    ELSIF down & (y0 >= txTop) & (y0 < txBot) THEN
      acc := acc + y - y0; y0 := y;
      IF ABS(acc) > 14 THEN dragged := TRUE END;
      WHILE acc >= LH DO acc := acc - LH; DEC(top) END;
      WHILE acc <= -LH DO acc := acc + LH; INC(top) END;
      IF top > nl - 1 THEN top := nl - 1 END; IF top < 0 THEN top := 0 END
    ELSIF ~down & wasDown & ~dragged & (my >= txTop) & (my < txBot) THEN
      cr := top + (my - txTop) DIV LH; IF cr > nl - 1 THEN cr := nl - 1 END;
      cc := left + (mx - 8 + CW DIV 2) DIV CW; IF cc > len[cr] THEN cc := len[cr] END; IF cc < 0 THEN cc := 0 END
    END;
    Grafica.Dreptunghi(0, 0, W, kbTop, bg);
    Text1.Part(10, 8, name, 0, 12, 2, gold);
    IF dirty THEN Text1.Draw(10, 32, "CHANGED", 2, red) ELSE Text1.Draw(10, 32, "LINE", 2, grey);
      i := 0; k := cr + 1; t := "     ";
      WHILE (k > 0) & (i < 5) DO t[4 - i] := CHR(ORD("0") + k MOD 10); k := k DIV 10; INC(i) END;
      Text1.Draw(58, 32, t, 2, grey)
    END;
    IF Button(W - 384, 6, 104, "COPY", violet) THEN CopyAll END;
    IF Button(W - 276, 6, 104, "PASTE", violet) THEN
      Clip2.Ask; pasting := TRUE; SetMsg("PASTING ...", grey)
    END;
    IF pasting THEN
      IF Clip2.Ready() THEN PasteIn; Visible
      ELSIF Clip2.Late() THEN pasting := FALSE; SetMsg("THE CLIPBOARD DID NOT ANSWER", red)
      END
    END;
    IF Button(W - 168, 6, 94, "SAVE", cyan) THEN Save END;
    IF Button(W - 74, 6, 68, "X", red) THEN
      IF dirty & ~warned THEN warned := TRUE; SetMsg("NOT SAVED. X AGAIN TO CLOSE ANYWAY", red)
      ELSE closed := TRUE
      END
    END;
    (* the text *)
    FOR r := 0 TO rows - 1 DO
      i := top + r; yy := txTop + r * LH;
      IF i < nl THEN
        IF i = cr THEN Grafica.Dreptunghi(0, yy - 3, W, LH, Grafica.RGB(30, 12, 54)) END;
        Text1.Part(8, yy, buf[i], left, cols, 2, white);
        IF (i = cr) & (Ceas.Ms() DIV 450 MOD 2 = 0) & (cc >= left) & (cc - left < cols) THEN
          Grafica.Dreptunghi(8 + (cc - left) * CW - 2, yy - 2, 2, LH - 2, gold)
        END
      END
    END;
    IF left > 0 THEN Text1.Draw(W - 24, txTop, "<", 2, gold) END;
    Text1.Draw(10, txBot + 6, msg, 2, msgCol);
    IF menu THEN
      Grafica.Dreptunghi(0, menuY - 4, W, 60, black);
      Grafica.Dreptunghi(4, menuY, 170, 52, gold); Text1.Centre(89, menuY + 18, "PASTE", 2, black);
      Grafica.Dreptunghi(184, menuY, 170, 52, panel); Text1.Centre(269, menuY + 18, "COPY LINE", 2, white);
      Grafica.Dreptunghi(364, menuY, 170, 52, panel); Text1.Centre(449, menuY + 18, "COPY ALL", 2, white)
    END;
    k := Keys1.Draw(kbTop, down, hit, x, y);
    IF k = 13 THEN NewLine(TRUE)
    ELSIF k = 8 THEN Delete
    ELSIF k = Keys1.LEFT THEN
      IF cc > 0 THEN DEC(cc) ELSIF cr > 0 THEN DEC(cr); cc := len[cr] END
    ELSIF k = Keys1.RIGHT THEN
      IF cc < len[cr] THEN INC(cc) ELSIF cr < nl - 1 THEN INC(cr); cc := 0 END
    ELSIF k >= 32 THEN Insert(CHR(k))
    END;
    IF k # 0 THEN Visible END
    RETURN closed
  END Frame;

BEGIN
  nl := 1; len[0] := 0; buf[0, 0] := 0X; name[0] := 0X; msg[0] := 0X
END Edit4.
