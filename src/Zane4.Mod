MODULE Zane4;  (* THE FAIRIES 4b (20 Nov 2026, Cubicum N 27): ROBIN's manual says PIXIPOGO.
  THE FAIRIES 4 (20 Nov 2026, Cubicum N 26): the fairies remember. PHILOMEL keeps the song and where it was,
     PEASEBLOSSOM the page of the last 20 books, in zane.cfg; after a restart PLAY goes on from the same second and a book
     opens at the same page.
   THE FAIRIES 3 (20 Nov 2026, Cubicum N 25): Zane1 and Zane2 in one module. With 24 modules the command
     of ollapk passed 4096 letters again and the link broke ("cannot open .../cache/tmp/o"). PUCK, MUSTARDSEED, MOTH, IRIS,
     ROBIN (Pk, Ms, Mo, Ir, Rb) as in Zane1; PHILOMEL (Ph) and PEASEBLOSSOM (Pb) as in Zane2, their helpers start with Zn.
     The next fairies come in here too, so the number of modules stays 23.
   Pion & Claude, 20.11.2026 *)

  IMPORT Math, Ceas, OllGL6, Desk6, Sal4, Tor11, Gazda4, Synth9, Fisier, Fs2;


  CONST
  (* PUCK (tasks) *) PkTOP = 112; PkLT = 446; PkRH = 62;
  (* MUSTARDSEED (calc) *) MsBIG = 2147483647;
  (* IRIS (images) *) IrMX = 160; IrNL = 300;
  (* ROBIN (help) *) RbNL = 220; RbTOP = 110; RbLH = 26;
  (* PHILOMEL, PEASEBLOSSOM *) ZnNL = 300; ZnRH = 64; ZnNB = 20;

  VAR
  (* PUCK (tasks) *)
    PkW, PkH, Pkx0, Pky0, PktSpeed: INTEGER; Pkdown, Pkmoved: BOOLEAN;
    Pklast, Pkspeed: ARRAY 8 OF INTEGER;
  (* MUSTARDSEED (calc) *)
    MsW, MsH, Msx0, Msy0, MskTop, MskH, MskW: INTEGER; Msdown, Msmoved: BOOLEAN;
    Msacc, Mscur, Msop, Msrest, MsopAt: INTEGER;   (* the number before the operation, the one being written, + - * / M, the rest of / *)
    Msfresh, Msz7, Mserr, MshasAcc, Msshown: BOOLEAN;   (* fresh: the next digit starts a new number *)
    Msline: ARRAY 64 OF CHAR;   (* what was done: 12 + 7 = *)
  (* MOTH (clock) *)
    MoW, MoH, Mox0, Moy0, Motab: INTEGER; Modown, Momoved: BOOLEAN;
    MotSet, MotLeft, MotEnd, Moring, MotRing: INTEGER; MotRun: BOOLEAN;   (* the timer, in ms *)
    Mosw0, MoswAcc, MonLap: INTEGER; MoswRun: BOOLEAN; Molap: ARRAY 8 OF INTEGER;   (* the stopwatch *)
  (* IRIS (images) *)
    IrW, IrH, Irx0, Iry0, Irscroll, Irscroll0: INTEGER; Irdown, Irmoved, Irviewing: BOOLEAN;
    Irpix: ARRAY IrMX * IrMX OF INTEGER; Irpw, Irph, Irfw, Irfh: INTEGER;   (* the points kept; the size in the file *)
    Irname, Irerr: ARRAY 40 OF CHAR;
    Irlist: ARRAY IrNL OF INTEGER; Irnl: INTEGER;   (* the files of the cube that are pictures *)
    Irhd: ARRAY 1100 OF INTEGER; Irh, Irpos: INTEGER;   (* the file while it is read *)
  (* ROBIN (help) *)
    RbW, RbH, Rbx0, Rby0, Rbscroll, Rbscroll0, Rbn, Rbnh: INTEGER; Rbdown, Rbmoved: BOOLEAN;
    Rbtxt: ARRAY RbNL OF ARRAY 44 OF CHAR; Rbkind: ARRAY RbNL OF INTEGER;   (* 0 text, 1 title, 2 command, 3 note *)
    Rbhead: ARRAY 16 OF INTEGER;   (* the lines of the titles *)


  (* PHILOMEL, PEASEBLOSSOM *)
    ZnW, ZnH: INTEGER;
    (* PHILOMEL *)
    ZnphDown, ZnphMoved: BOOLEAN; ZnphX0, ZnphY0, ZnphScroll, ZnphScroll0: INTEGER;
    ZnphList: ARRAY ZnNL OF INTEGER; ZnphN: INTEGER;
    Znsong: ARRAY 40 OF CHAR;   (* the song that plays or waits *)
    Znst, Znpos, Zndur: INTEGER;   (* what the phone said: 0 stopped, 1 plays, 2 paused, 3 it ended *)
    ZntPoll, ZntSent: INTEGER;
    ZnsavedPos, ZnseekTo, ZntSave: INTEGER;   (* where the song was before a restart; a jump still to send; the last save *)
    ZnbkName: ARRAY ZnNB OF ARRAY 40 OF CHAR; ZnbkPage: ARRAY ZnNB OF INTEGER; ZnbkN: INTEGER;   (* the pages of the books *)
    (* PEASEBLOSSOM *)
    ZnpbDown, ZnpbMoved, Znreading, Znwaiting, Znshown: BOOLEAN; ZnpbX0, ZnpbY0, ZnpbScroll, ZnpbScroll0: INTEGER;
    ZnpbList: ARRAY ZnNL OF INTEGER; ZnpbN: INTEGER;
    Znbook: ARRAY 40 OF CHAR; ZnpbErr: ARRAY 64 OF CHAR; Znpage, Znpages, Znzoom, ZntAsk: INTEGER;

  (* ---------- small helpers ---------- *)


  (* ================= PUCK (tasks): Procs2 ================= *)
  PROCEDURE PkLen(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END PkLen;

  PROCEDURE PkAdd(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := PkLen(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END PkAdd;

  PROCEDURE PkAddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := PkLen(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END PkAddN;

  PROCEDURE PkColour(st: INTEGER): INTEGER;
    VAR c: INTEGER;
  BEGIN
    IF st = Sal4.Free THEN c := Desk6.edge ELSIF st = Sal4.Active THEN c := Desk6.green
    ELSIF st = Sal4.Sleeps THEN c := OllGL6.RGB(125, 211, 252) ELSIF st = Sal4.Senses THEN c := Desk6.gold
    ELSE c := OllGL6.RGB(167, 139, 250)
    END
    RETURN c
  END PkColour;

  PROCEDURE PkStateName(st: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    s[0] := 0X;
    IF st = Sal4.Free THEN PkAdd(s, "FREE") ELSIF st = Sal4.Active THEN PkAdd(s, "RUNS") ELSIF st = Sal4.Sleeps THEN PkAdd(s, "SLEEPS")
    ELSIF st = Sal4.Senses THEN PkAdd(s, "WAITS") ELSE PkAdd(s, "RECEIVES") END
  END PkStateName;

  PROCEDURE PkWhere(k: INTEGER; VAR x, y: INTEGER);   (* turn k on the spiral *)
    VAR a, r: REAL;
  BEGIN
    a := -1.5708 + FLT(k) * 2.2; r := 34.0 + FLT(k) * 21.0;
    x := PkW DIV 2 + FLOOR(Math.cos(a) * r); y := PkTOP + 160 + FLOOR(Math.sin(a) * r * 0.86)
  END PkWhere;

  PROCEDURE PkSpiral(t: INTEGER);
    VAR k, j, x, y, st: INTEGER; a, r: REAL; s: ARRAY 4 OF CHAR;
  BEGIN
    FOR j := 0 TO 140 DO   (* the path of the spiral, as dots *)
      a := -1.5708 + FLT(j) * 6.0 * 2.2 / 140.0; r := 34.0 + FLT(j) * 6.0 * 21.0 / 140.0;
      OllGL6.Cerc2D(PkW DIV 2 + FLOOR(Math.cos(a) * r), PkTOP + 160 + FLOOR(Math.sin(a) * r * 0.86), 2, Desk6.edge)
    END;
    OllGL6.Cerc2D(PkW DIV 2, PkTOP + 160, 8, Desk6.Accent());   (* the centre, (4,4,4) *)
    FOR k := 0 TO Sal4.NP - 1 DO
      PkWhere(k, x, y); st := Sal4.StateOf(k);
      IF st = Sal4.Active THEN OllGL6.Inel2D(x, y, 20 + (t DIV 60 + k * 3) MOD 10, 2, Desk6.green) END;
      OllGL6.Cerc2D(x, y, 16, PkColour(st)); OllGL6.Cerc2D(x, y, 11, Desk6.bg);
      s[0] := CHR(ORD("1") + k); s[1] := 0X; Desk6.Centre(x, y - 6, s, 2, Desk6.text)
    END
  END PkSpiral;

  PROCEDURE PkFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, k, yy, st, n, now: INTEGER; s, nm: ARRAY 48 OF CHAR;
  BEGIN
    r := 0; now := Ceas.Ms();
    IF now - PktSpeed >= 1000 THEN   (* steps per second *)
      FOR k := 0 TO Sal4.NP - 1 DO
        IF Sal4.StateOf(k) = Sal4.Free THEN Pkspeed[k] := 0 ELSE Pkspeed[k] := (Sal4.StepsOf(k) - Pklast[k]) * 1000 DIV (now - PktSpeed) END;
        Pklast[k] := Sal4.StepsOf(k)
      END;
      PktSpeed := now
    END;
    IF isDown & ~Pkdown THEN Pkdown := TRUE; Pkmoved := FALSE; Pkx0 := x; Pky0 := y
    ELSIF isDown THEN IF (ABS(x - Pkx0) > 14) OR (ABS(y - Pky0) > 14) THEN Pkmoved := TRUE END
    ELSIF Pkdown THEN
      Pkdown := FALSE;
      IF ~Pkmoved THEN
        IF Desk6.IsHome(Pky0) THEN r := -1
        ELSIF (Pky0 >= PkLT) & (Pky0 < PkLT + Sal4.NP * PkRH) & (Pkx0 > PkW - 140) THEN
          k := (Pky0 - PkLT) DIV PkRH;
          IF Sal4.StateOf(k) # Sal4.Free THEN
            Sal4.NameOf(k, nm); Sal4.Kill(k); s := "STOPPED "; PkAdd(s, nm); Desk6.Say(s)
          END
        END
      END
    END;
    OllGL6.Incepe(Desk6.bg);
    PkSpiral(now);
    n := 0;
    FOR k := 0 TO Sal4.NP - 1 DO
      yy := PkLT + k * PkRH; st := Sal4.StateOf(k);
      IF st # Sal4.Free THEN INC(n) END;
      IF ODD(k) THEN OllGL6.Rotund2D(12, yy + 2, PkW - 24, PkRH - 4, 14, Desk6.surface) END;
      OllGL6.Cerc2D(36, yy + PkRH DIV 2, 9, PkColour(st));
      s := "TURN "; PkAddN(s, k + 1); OllGL6.Text2D(56, yy + 10, s, 2, Desk6.muted);
      IF st = Sal4.Free THEN OllGL6.Text2D(56, yy + 34, "FREE", 2, Desk6.edge)
      ELSE
        Sal4.NameOf(k, nm); OllGL6.Text2D(56, yy + 34, nm, 2, Desk6.text);
        PkStateName(st, s); OllGL6.Text2D(170, yy + 10, s, 2, PkColour(st));
        s[0] := 0X; PkAddN(s, Sal4.StepsOf(k)); PkAdd(s, " STEPS  "); PkAddN(s, Pkspeed[k]); PkAdd(s, "/S");
        OllGL6.Text2D(PkW - 380, yy + 34, s, 1, Desk6.muted);
        OllGL6.Rotund2D(PkW - 128, yy + 12, 104, 38, 19, Desk6.red); Desk6.Centre(PkW - 76, yy + 24, "STOP", 2, Desk6.text)
      END
    END;
    yy := PkLT + Sal4.NP * PkRH + 14;   (* Tor11 *)
    s := "FIELD "; PkAddN(s, Tor11.Field()); PkAdd(s, "   WRITES "); PkAddN(s, Tor11.Writes()); OllGL6.Text2D(24, yy, s, 2, Desk6.muted);
    s := "OPAL CYCLE "; PkAddN(s, Tor11.Cycle()); PkAdd(s, "   BEAT "); PkAddN(s, Tor11.BeatInHour()); PkAdd(s, "/1155");
    OllGL6.Text2D(24, yy + 26, s, 2, Desk6.muted);
    s := "BURNS "; PkAddN(s, Tor11.Burns()); PkAdd(s, "   ASH "); PkAddN(s, Sal4.AshLines()); PkAdd(s, " LINES"); OllGL6.Text2D(24, yy + 52, s, 2, Desk6.muted);
    s[0] := 0X; PkAddN(s, n); PkAdd(s, " OF 7 RUNNING");
    PkAdd(s, " . TASKS"); Desk6.Header("PUCK", s);
    Desk6.Bottom; Desk6.Toast(PkH - 136);
    OllGL6.Arata
    RETURN r
  END PkFrame;

  PROCEDURE PkEnter*;
  BEGIN Pkdown := TRUE; Pkmoved := TRUE
  END PkEnter;

  PROCEDURE PkStart*(w, h: INTEGER);
    VAR k: INTEGER;
  BEGIN PkW := w; PkH := h; PktSpeed := Ceas.Ms(); FOR k := 0 TO 7 DO Pklast[k] := 0; Pkspeed[k] := 0 END
  END PkStart;

  (* ================= MUSTARDSEED (calc): Calc2 ================= *)

  PROCEDURE MsLen(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END MsLen;

  PROCEDURE MsAdd(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := MsLen(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END MsAdd;

  PROCEDURE MsAddC(VAR s: ARRAY OF CHAR; c: CHAR);
    VAR k: INTEGER;
  BEGIN k := MsLen(s); IF k < LEN(s) - 1 THEN s[k] := c; s[k + 1] := 0X END
  END MsAddC;

  PROCEDURE MsDec(n: INTEGER; VAR s: ARRAY OF CHAR);   (* base 10 *)
    VAR d: ARRAY 12 OF CHAR; k: INTEGER; neg: BOOLEAN;
  BEGIN
    s[0] := 0X; neg := n < 0; IF neg THEN n := -n; MsAddC(s, "-") END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE k > 0 DO DEC(k); MsAddC(s, d[k]) END
  END MsDec;

  PROCEDURE MsZ7(n: INTEGER; VAR s: ARRAY OF CHAR);   (* base 7 without zero: 1..7; 0 has no digits *)
    VAR d: ARRAY 16 OF CHAR; k, q: INTEGER;
  BEGIN
    s[0] := 0X;
    IF n = 0 THEN MsAdd(s, "(EMPTY)")
    ELSE
      IF n < 0 THEN n := -n; MsAddC(s, "-") END;
      k := 0;
      WHILE n > 0 DO q := (n - 1) MOD 7 + 1; d[k] := CHR(ORD("0") + q); INC(k); n := (n - q) DIV 7 END;
      WHILE k > 0 DO DEC(k); MsAddC(s, d[k]) END
    END
  END MsZ7;

  PROCEDURE MsShow(n: INTEGER; VAR s: ARRAY OF CHAR);   (* in the base of the keys *)
  BEGIN IF Msz7 THEN MsZ7(n, s) ELSE MsDec(n, s) END
  END MsShow;

  PROCEDURE MsOpChar(o: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    IF o = ORD("+") THEN MsAdd(s, " + ") ELSIF o = ORD("-") THEN MsAdd(s, " - ") ELSIF o = ORD("*") THEN MsAdd(s, " X ")
    ELSIF o = ORD("/") THEN MsAdd(s, " / ") ELSE MsAdd(s, " MOD ") END
  END MsOpChar;

  PROCEDURE MsFits(r: REAL): BOOLEAN;
  BEGIN RETURN (r <= FLT(MsBIG)) & (r >= -FLT(MsBIG))
  END MsFits;

  PROCEDURE MsApply;   (* acc := acc op cur *)
    VAR r: INTEGER;
  BEGIN
    Msrest := -1;
    IF Msop = ORD("+") THEN IF MsFits(FLT(Msacc) + FLT(Mscur)) THEN r := Msacc + Mscur ELSE Mserr := TRUE END
    ELSIF Msop = ORD("-") THEN IF MsFits(FLT(Msacc) - FLT(Mscur)) THEN r := Msacc - Mscur ELSE Mserr := TRUE END
    ELSIF Msop = ORD("*") THEN IF MsFits(FLT(Msacc) * FLT(Mscur)) THEN r := Msacc * Mscur ELSE Mserr := TRUE END
    ELSIF (Msop = ORD("/")) OR (Msop = ORD("M")) THEN
      IF Mscur = 0 THEN Mserr := TRUE
      ELSIF Mscur > 0 THEN
        IF Msop = ORD("/") THEN r := Msacc DIV Mscur; Msrest := Msacc MOD Mscur ELSE r := Msacc MOD Mscur END
      ELSE   (* by a negative number: as by its opposite, and the sign *)
        IF Msop = ORD("/") THEN r := -(Msacc DIV (-Mscur)); Msrest := Msacc MOD (-Mscur) ELSE r := Msacc MOD (-Mscur) END
      END
    ELSE r := Mscur
    END;
    IF ~Mserr THEN Msacc := r; Mscur := r END
  END MsApply;

  PROCEDURE MsKey(k: INTEGER);   (* key k: row * 4 + column *)
    VAR d: INTEGER; s: ARRAY 24 OF CHAR;
  BEGIN
    d := -1;
    IF k = 4 THEN d := 7 ELSIF k = 5 THEN d := 8 ELSIF k = 6 THEN d := 9 ELSIF k = 8 THEN d := 4 ELSIF k = 9 THEN d := 5
    ELSIF k = 10 THEN d := 6 ELSIF k = 12 THEN d := 1 ELSIF k = 13 THEN d := 2 ELSIF k = 14 THEN d := 3 ELSIF k = 17 THEN d := 0
    END;
    IF Mserr & (k # 0) THEN   (* after an error only C *)
    ELSIF d >= 0 THEN
      IF Msz7 & ((d = 0) OR (d > 7)) THEN Desk6.Say("IN Z7 THE DIGITS ARE 1..7")
      ELSE
        IF Msfresh THEN Mscur := 0; Msfresh := FALSE; IF ~MshasAcc THEN Msline[0] := 0X END END;
        IF Msz7 THEN
          IF MsFits(FLT(Mscur) * 7.0 + FLT(d)) THEN Mscur := Mscur * 7 + d ELSE Desk6.Say("TOO BIG") END
        ELSIF MsFits(FLT(Mscur) * 10.0 + FLT(d)) THEN Mscur := Mscur * 10 + d ELSE Desk6.Say("TOO BIG")
        END;
        Msshown := FALSE
      END
    ELSIF k = 0 THEN Msacc := 0; Mscur := 0; Msop := 0; Mserr := FALSE; Msfresh := TRUE; MshasAcc := FALSE; Msline[0] := 0X; Msrest := -1; Msshown := FALSE
    ELSIF k = 1 THEN IF ~Msfresh THEN IF Msz7 THEN Mscur := (Mscur - ((Mscur - 1) MOD 7 + 1)) DIV 7 ELSE Mscur := Mscur DIV 10 END END
    ELSIF k = 16 THEN Mscur := -Mscur
    ELSIF k = 18 THEN Msz7 := ~Msz7
    ELSE   (* + - X / MOD = *)
      IF k = 2 THEN d := ORD("M") ELSIF k = 3 THEN d := ORD("/") ELSIF k = 7 THEN d := ORD("*") ELSIF k = 11 THEN d := ORD("-")
      ELSIF k = 15 THEN d := ORD("+") ELSE d := ORD("=") END;
      IF MshasAcc & ~Msfresh THEN
        MsShow(Mscur, s); MsAdd(Msline, s); MsApply;
        IF Mserr THEN MsAdd(Msline, " = ?") END
      ELSIF ~MshasAcc THEN Msacc := Mscur; Msline[0] := 0X; MsShow(Mscur, s); MsAdd(Msline, s)
      END;
      IF d = ORD("=") THEN
        IF MshasAcc & ~Mserr THEN MsAdd(Msline, " =") END;
        MshasAcc := FALSE; Msop := 0; Msshown := TRUE
      ELSIF ~Mserr THEN
        IF MshasAcc & Msfresh THEN Msline[MsopAt] := 0X END;   (* another operation instead of the last one *)
        Msop := d; MshasAcc := TRUE; MsopAt := MsLen(Msline); MsOpChar(Msop, Msline); Msrest := -1
      END;
      Msfresh := TRUE
    END
  END MsKey;

  PROCEDURE MsLabel(k: INTEGER; VAR s: ARRAY OF CHAR);
  BEGIN
    s[0] := 0X;
    IF k = 0 THEN MsAdd(s, "C") ELSIF k = 1 THEN MsAdd(s, "DEL") ELSIF k = 2 THEN MsAdd(s, "MOD") ELSIF k = 3 THEN MsAdd(s, "/")
    ELSIF k = 7 THEN MsAdd(s, "X") ELSIF k = 11 THEN MsAdd(s, "-") ELSIF k = 15 THEN MsAdd(s, "+") ELSIF k = 16 THEN MsAdd(s, "+/-")
    ELSIF k = 18 THEN IF Msz7 THEN MsAdd(s, "Z7") ELSE MsAdd(s, "10") END
    ELSIF k = 19 THEN MsAdd(s, "=")
    ELSIF k = 4 THEN MsAdd(s, "7") ELSIF k = 5 THEN MsAdd(s, "8") ELSIF k = 6 THEN MsAdd(s, "9") ELSIF k = 8 THEN MsAdd(s, "4")
    ELSIF k = 9 THEN MsAdd(s, "5") ELSIF k = 10 THEN MsAdd(s, "6") ELSIF k = 12 THEN MsAdd(s, "1") ELSIF k = 13 THEN MsAdd(s, "2")
    ELSIF k = 14 THEN MsAdd(s, "3") ELSIF k = 17 THEN MsAdd(s, "0")
    END
  END MsLabel;

  PROCEDURE MsFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, k, kx, ky, c, n, m, cx, cy, cz: INTEGER; s, t: ARRAY 48 OF CHAR; dead: BOOLEAN;
  BEGIN
    r := 0;
    IF isDown & ~Msdown THEN Msdown := TRUE; Msmoved := FALSE; Msx0 := x; Msy0 := y
    ELSIF isDown THEN IF (ABS(x - Msx0) > 20) OR (ABS(y - Msy0) > 20) THEN Msmoved := TRUE END
    ELSIF Msdown THEN
      Msdown := FALSE;
      IF ~Msmoved THEN
        IF Desk6.IsHome(Msy0) THEN r := -1
        ELSIF (Msy0 >= MskTop) & (Msy0 < MskTop + 5 * MskH) THEN MsKey((Msy0 - MskTop) DIV MskH * 4 + (Msx0 - 12) DIV MskW)
        END
      END
    END;
    OllGL6.Incepe(Desk6.bg);
    (* the display *)
    OllGL6.Rotund2D(16, 108, MsW - 32, MskTop - 124, 22, Desk6.surface);
    Desk6.Right(MsW - 40, 126, Msline, 2, Desk6.muted);
    n := Mscur;
    IF Mserr THEN s := "ERROR" ELSE MsShow(n, s) END;
    m := 8; WHILE (m > 3) & (MsLen(s) * 6 * m > MsW - 72) DO DEC(m) END;
    Desk6.Right(MsW - 40, 158, s, m, Desk6.text);
    IF ~Mserr THEN
      IF Msz7 THEN t := "BASE 10  "; MsDec(n, s) ELSE t := "BASE 7  "; MsZ7(n, s) END;
      MsAdd(t, s); OllGL6.Text2D(40, MskTop - 92, t, 2, Desk6.Accent());
      t := "MOD 7  "; MsDec((n MOD 7 + 7) MOD 7, s); MsAdd(t, s);
      IF Msrest >= 0 THEN MsAdd(t, "    REST "); MsShow(Msrest, s); MsAdd(t, s) END;
      OllGL6.Text2D(40, MskTop - 64, t, 2, Desk6.muted);
      m := (n MOD 343 + 343) MOD 343; cx := m MOD 7 + 1; cy := m DIV 7 MOD 7 + 1; cz := m DIV 49 + 1;
      t := "CELL ("; MsDec(cx, s); MsAdd(t, s); MsAddC(t, ","); MsDec(cy, s); MsAdd(t, s); MsAddC(t, ","); MsDec(cz, s); MsAdd(t, s); MsAddC(t, ")");
      Desk6.Right(MsW - 40, MskTop - 64, t, 2, Desk6.muted)
    END;
    (* the keys *)
    FOR k := 0 TO 19 DO
      kx := 12 + (k MOD 4) * MskW; ky := MskTop + (k DIV 4) * MskH;
      dead := Msz7 & ((k = 5) OR (k = 6) OR (k = 17));
      IF k = 19 THEN c := Desk6.Accent() ELSIF (k MOD 4 = 3) OR (k = 2) OR (k = 15) THEN c := Desk6.surface2
      ELSIF (k = 0) OR (k = 1) OR (k = 16) OR (k = 18) THEN c := Desk6.edge ELSE c := Desk6.surface END;
      IF Msdown & ~Msmoved & (Msx0 >= kx) & (Msx0 < kx + MskW) & (Msy0 >= ky) & (Msy0 < ky + MskH) THEN c := Desk6.Accent() END;
      OllGL6.Rotund2D(kx + 5, ky + 5, MskW - 10, MskH - 10, 22, c);
      MsLabel(k, s);
      IF dead THEN Desk6.Centre(kx + MskW DIV 2, ky + MskH DIV 2 - 14, s, 4, Desk6.edge)
      ELSIF k = 19 THEN Desk6.Centre(kx + MskW DIV 2, ky + MskH DIV 2 - 14, s, 4, Desk6.dark)
      ELSE Desk6.Centre(kx + MskW DIV 2, ky + MskH DIV 2 - 14, s, 4, Desk6.text)
      END
    END;
    IF Msz7 THEN Desk6.Header("MUSTARDSEED", "CALC . BASE 7") ELSE Desk6.Header("MUSTARDSEED", "CALC . BASE 10") END;
    Desk6.Bottom; Desk6.Toast(MskTop - 52);
    OllGL6.Arata
    RETURN r
  END MsFrame;

  PROCEDURE MsEnter*;
  BEGIN Msdown := TRUE; Msmoved := TRUE
  END MsEnter;

  PROCEDURE MsStart*(w, h: INTEGER);
  BEGIN MsW := w; MsH := h; MskW := (MsW - 24) DIV 4; MskTop := 400; MskH := (MsH - 90 - MskTop) DIV 5
  END MsStart;

  (* ================= MOTH (clock): Ceas2 ================= *)

  PROCEDURE MoLen(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END MoLen;

  PROCEDURE MoAdd(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := MoLen(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END MoAdd;

  PROCEDURE MoTwo(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR k: INTEGER;
  BEGIN k := MoLen(s); IF k < LEN(s) - 2 THEN s[k] := CHR(ORD("0") + n DIV 10 MOD 10); s[k + 1] := CHR(ORD("0") + n MOD 10); s[k + 2] := 0X END
  END MoTwo;

  PROCEDURE MoAddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := MoLen(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END MoAddN;

  PROCEDURE MoMinSec(ms: INTEGER; VAR s: ARRAY OF CHAR; cents: BOOLEAN);   (* MM:SS or MM:SS.CC (H:MM:SS past an hour) *)
    VAR t: INTEGER;
  BEGIN
    s[0] := 0X; IF ms < 0 THEN ms := 0 END; t := ms DIV 1000;
    IF t >= 3600 THEN MoAddN(s, t DIV 3600); MoAdd(s, ":") END;
    MoTwo(s, t DIV 60 MOD 60); MoAdd(s, ":"); MoTwo(s, t MOD 60);
    IF cents THEN MoAdd(s, "."); MoTwo(s, ms DIV 10 MOD 100) END
  END MoMinSec;

  PROCEDURE MoButton(x, y, w, h: INTEGER; s: ARRAY OF CHAR; c, tc: INTEGER);
  BEGIN OllGL6.Rotund2D(x, y, w, h, h DIV 2, c); Desk6.Centre(x + w DIV 2, y + h DIV 2 - 7, s, 2, tc)
  END MoButton;

  PROCEDURE MoIn(x, y, w, h: INTEGER): BOOLEAN;   (* was the tap in this box? *)
  BEGIN RETURN (Mox0 >= x) & (Mox0 < x + w) & (Moy0 >= y) & (Moy0 < y + h)
  END MoIn;

  PROCEDURE MoHand(cx, cy, len, gros: INTEGER; a: REAL; c: INTEGER);   (* a: 0 = up, clockwise, in turns *)
    VAR u: REAL;
  BEGIN
    u := a * 6.28318530718 - 1.5707963268;
    OllGL6.Linie2D(cx, cy, cx + FLOOR(Math.cos(u) * FLT(len)), cy + FLOOR(Math.sin(u) * FLT(len)), gros, c)
  END MoHand;

  PROCEDURE MoRing;   (* the sound of the timer *)
  BEGIN Synth9.Note(3, 3, 3, 500); Synth9.Note(5, 3, 1, 500); Synth9.Note(3, 6, 3, 500)
  END MoRing;

  PROCEDURE MoTick*;   (* every frame, on every screen: the timer goes on *)
    VAR now: INTEGER;
  BEGIN
    now := Ceas.Ms();
    IF MotRun THEN
      MotLeft := MotEnd - now;
      IF MotLeft <= 0 THEN MotLeft := 0; MotRun := FALSE; Moring := 8; MotRing := now - 1000; Desk6.Say("THE TIMER IS DONE") END
    END;
    IF (Moring > 0) & (now - MotRing >= 700) THEN MoRing; DEC(Moring); MotRing := now END
  END MoTick;

  PROCEDURE MoClockTab(cx, cy: INTEGER);
    VAR k, h, m, sec, r: INTEGER; s, t: ARRAY 40 OF CHAR; u: REAL;
  BEGIN
    r := 170;
    OllGL6.Cerc2D(cx, cy, r + 8, Desk6.surface2); OllGL6.Cerc2D(cx, cy, r, Desk6.surface);
    FOR k := 0 TO 59 DO
      u := FLT(k) / 60.0 * 6.28318530718 - 1.5707963268;
      IF k MOD 5 = 0 THEN
        OllGL6.Cerc2D(cx + FLOOR(Math.cos(u) * FLT(r - 18)), cy + FLOOR(Math.sin(u) * FLT(r - 18)), 5, Desk6.text)
      ELSE OllGL6.Cerc2D(cx + FLOOR(Math.cos(u) * FLT(r - 18)), cy + FLOOR(Math.sin(u) * FLT(r - 18)), 2, Desk6.muted)
      END
    END;
    h := Gazda4.Clock(3); m := Gazda4.Clock(4); sec := Gazda4.Clock(5);
    MoHand(cx, cy, 92, 9, (FLT(h MOD 12) + FLT(m) / 60.0) / 12.0, Desk6.text);
    MoHand(cx, cy, 138, 6, (FLT(m) + FLT(sec) / 60.0) / 60.0, Desk6.text);
    MoHand(cx, cy, 150, 2, FLT(sec) / 60.0, Desk6.Accent());
    OllGL6.Cerc2D(cx, cy, 9, Desk6.Accent());
    s[0] := 0X; MoTwo(s, h); MoAdd(s, ":"); MoTwo(s, m); MoAdd(s, ":"); MoTwo(s, sec);
    IF ~Gazda4.HasClock() THEN s := "--:--:--" END;
    Desk6.Centre(cx, cy + r + 40, s, 6, Desk6.text);
    IF Gazda4.HasClock() THEN
      s[0] := 0X; MoAddN(s, Gazda4.Clock(2)); MoAdd(s, " . "); MoAddN(s, Gazda4.Clock(1)); MoAdd(s, " . "); MoAddN(s, Gazda4.Clock(0));
      Desk6.Centre(cx, cy + r + 106, s, 2, Desk6.muted)
    END;
    Gazda4.System(t); Desk6.Centre(cx, cy + r + 136, t, 2, Desk6.edge)
  END MoClockTab;

  PROCEDURE MoTimerTab(cx, cy: INTEGER);
    VAR k, n, bw, by: INTEGER; s: ARRAY 24 OF CHAR; u: REAL;
  BEGIN
    OllGL6.Inel2D(cx, cy, 150, 6, Desk6.surface2);
    IF MotSet > 0 THEN   (* what is left, as an arc *)
      n := 120 * MotLeft DIV MotSet;
      FOR k := 0 TO n - 1 DO
        u := FLT(k) / 120.0 * 6.28318530718 - 1.5707963268;
        OllGL6.Cerc2D(cx + FLOOR(Math.cos(u) * 150.0), cy + FLOOR(Math.sin(u) * 150.0), 5, Desk6.Accent())
      END
    END;
    MoMinSec(MotLeft, s, FALSE); Desk6.Centre(cx, cy - 28, s, 8, Desk6.text);
    IF MotRun THEN Desk6.Centre(cx, cy + 50, "RUNS", 2, Desk6.green) ELSIF Moring > 0 THEN Desk6.Centre(cx, cy + 50, "DONE", 2, Desk6.gold)
    ELSIF MotLeft > 0 THEN Desk6.Centre(cx, cy + 50, "READY", 2, Desk6.muted) END;
    bw := (MoW - 48) DIV 4; by := cy + 190;
    MoButton(24, by, bw - 8, 56, "-1 MIN", Desk6.surface, Desk6.text); MoButton(24 + bw, by, bw - 8, 56, "+10 S", Desk6.surface, Desk6.text);
    MoButton(24 + 2 * bw, by, bw - 8, 56, "+1 MIN", Desk6.surface, Desk6.text); MoButton(24 + 3 * bw, by, bw - 8, 56, "+5 MIN", Desk6.surface, Desk6.text);
    IF MotRun THEN MoButton(24, by + 76, (MoW - 48) DIV 2 - 8, 64, "PAUSE", Desk6.Accent(), Desk6.dark)
    ELSE MoButton(24, by + 76, (MoW - 48) DIV 2 - 8, 64, "START", Desk6.Accent(), Desk6.dark) END;
    MoButton(24 + (MoW - 48) DIV 2, by + 76, (MoW - 48) DIV 2 - 8, 64, "RESET", Desk6.surface2, Desk6.text)
  END MoTimerTab;

  PROCEDURE MoTimerTap(cy: INTEGER);
    VAR bw, by, now, d: INTEGER;
  BEGIN
    bw := (MoW - 48) DIV 4; by := cy + 190; now := Ceas.Ms(); d := 0;
    IF MoIn(24, by, bw, 56) THEN d := -60000 ELSIF MoIn(24 + bw, by, bw, 56) THEN d := 10000
    ELSIF MoIn(24 + 2 * bw, by, bw, 56) THEN d := 60000 ELSIF MoIn(24 + 3 * bw, by, bw, 56) THEN d := 300000
    ELSIF MoIn(24, by + 76, (MoW - 48) DIV 2, 64) THEN
      IF MotRun THEN MotRun := FALSE ELSIF MotLeft > 0 THEN MotRun := TRUE; MotEnd := now + MotLeft; Moring := 0 END
    ELSIF MoIn(24 + (MoW - 48) DIV 2, by + 76, (MoW - 48) DIV 2, 64) THEN MotRun := FALSE; MotLeft := 0; MotSet := 0; Moring := 0
    END;
    IF d # 0 THEN
      MotLeft := MotLeft + d; IF MotLeft < 0 THEN MotLeft := 0 END; IF MotLeft > 359999000 THEN MotLeft := 359999000 END;
      MotSet := MotLeft; IF MotRun THEN MotEnd := now + MotLeft END; Moring := 0
    END
  END MoTimerTap;

  PROCEDURE MoSwTime(): INTEGER;
    VAR t: INTEGER;
  BEGIN t := MoswAcc; IF MoswRun THEN t := t + Ceas.Ms() - Mosw0 END
    RETURN t
  END MoSwTime;

  PROCEDURE MoSwTab(cx, cy: INTEGER);
    VAR k: INTEGER; s, t: ARRAY 24 OF CHAR;
  BEGIN
    MoMinSec(MoSwTime(), s, TRUE); Desk6.Centre(cx, cy - 120, s, 7, Desk6.text);
    IF MoswRun THEN MoButton(24, cy - 20, (MoW - 48) DIV 2 - 8, 64, "STOP", Desk6.red, Desk6.text)
    ELSE MoButton(24, cy - 20, (MoW - 48) DIV 2 - 8, 64, "START", Desk6.Accent(), Desk6.dark) END;
    IF MoswRun THEN MoButton(24 + (MoW - 48) DIV 2, cy - 20, (MoW - 48) DIV 2 - 8, 64, "LAP", Desk6.surface2, Desk6.text)
    ELSE MoButton(24 + (MoW - 48) DIV 2, cy - 20, (MoW - 48) DIV 2 - 8, 64, "RESET", Desk6.surface2, Desk6.text) END;
    FOR k := 0 TO MonLap - 1 DO
      s := "LAP "; MoAddN(s, MonLap - k); OllGL6.Text2D(60, cy + 80 + k * 40, s, 2, Desk6.muted);
      MoMinSec(Molap[k], t, TRUE); Desk6.Right(MoW - 60, cy + 80 + k * 40, t, 2, Desk6.text)
    END
  END MoSwTab;

  PROCEDURE MoSwTap(cy: INTEGER);
    VAR k: INTEGER;
  BEGIN
    IF MoIn(24, cy - 20, (MoW - 48) DIV 2, 64) THEN
      IF MoswRun THEN MoswAcc := MoSwTime(); MoswRun := FALSE ELSE Mosw0 := Ceas.Ms(); MoswRun := TRUE END
    ELSIF MoIn(24 + (MoW - 48) DIV 2, cy - 20, (MoW - 48) DIV 2, 64) THEN
      IF MoswRun THEN   (* a lap, the newest on top *)
        FOR k := 7 TO 1 BY -1 DO Molap[k] := Molap[k - 1] END; Molap[0] := MoSwTime(); IF MonLap < 8 THEN INC(MonLap) END
      ELSE MoswAcc := 0; MonLap := 0
      END
    END
  END MoSwTap;

  PROCEDURE MoFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, cy, tw: INTEGER;
  BEGIN
    r := 0; Gazda4.Poll; cy := 420; tw := (MoW - 40) DIV 3;
    IF isDown & ~Modown THEN Modown := TRUE; Momoved := FALSE; Mox0 := x; Moy0 := y
    ELSIF isDown THEN IF (ABS(x - Mox0) > 20) OR (ABS(y - Moy0) > 20) THEN Momoved := TRUE END
    ELSIF Modown THEN
      Modown := FALSE;
      IF ~Momoved THEN
        IF Desk6.IsHome(Moy0) THEN r := -1
        ELSIF (Moy0 >= 108) & (Moy0 < 164) THEN Motab := (Mox0 - 20) DIV tw; IF Motab < 0 THEN Motab := 0 ELSIF Motab > 2 THEN Motab := 2 END
        ELSIF Motab = 1 THEN MoTimerTap(cy)
        ELSIF Motab = 2 THEN MoSwTap(cy)
        END
      END
    END;
    OllGL6.Incepe(Desk6.bg);
    IF Motab = 0 THEN MoClockTab(MoW DIV 2, cy) ELSIF Motab = 1 THEN MoTimerTab(MoW DIV 2, cy) ELSE MoSwTab(MoW DIV 2, cy) END;
    Desk6.Header("MOTH", "CLOCK");
    OllGL6.Rotund2D(16, 112, MoW - 32, 48, 24, Desk6.surface);
    IF Motab = 0 THEN OllGL6.Rotund2D(20, 116, tw, 40, 20, Desk6.Accent()); Desk6.Centre(20 + tw DIV 2, 130, "CLOCK", 2, Desk6.dark)
    ELSE Desk6.Centre(20 + tw DIV 2, 130, "CLOCK", 2, Desk6.muted) END;
    IF Motab = 1 THEN OllGL6.Rotund2D(20 + tw, 116, tw, 40, 20, Desk6.Accent()); Desk6.Centre(20 + tw + tw DIV 2, 130, "TIMER", 2, Desk6.dark)
    ELSE Desk6.Centre(20 + tw + tw DIV 2, 130, "TIMER", 2, Desk6.muted) END;
    IF Motab = 2 THEN OllGL6.Rotund2D(20 + 2 * tw, 116, tw, 40, 20, Desk6.Accent()); Desk6.Centre(20 + 2 * tw + tw DIV 2, 130, "STOPWATCH", 2, Desk6.dark)
    ELSE Desk6.Centre(20 + 2 * tw + tw DIV 2, 130, "STOPWATCH", 2, Desk6.muted) END;
    Desk6.Bottom; Desk6.Toast(MoH - 136);
    OllGL6.Arata
    RETURN r
  END MoFrame;

  PROCEDURE MoRunning*(): BOOLEAN;   (* the timer counts (for the home card) *)
  BEGIN RETURN MotRun
  END MoRunning;

  PROCEDURE MoLeft*(VAR s: ARRAY OF CHAR);   (* what is left of the timer, MM:SS *)
  BEGIN MoMinSec(MotLeft, s, FALSE)
  END MoLeft;

  PROCEDURE MoEnter*;
  BEGIN Modown := TRUE; Momoved := TRUE
  END MoEnter;

  PROCEDURE MoStart*(w, h: INTEGER);
  BEGIN MoW := w; MoH := h
  END MoStart;

  (* ================= IRIS (images): Img2 ================= *)

  PROCEDURE IrLen(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END IrLen;

  PROCEDURE IrCopy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(d) - 1) DO d[i] := s[i]; INC(i) END; d[i] := 0X
  END IrCopy;

  PROCEDURE IrAdd(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := IrLen(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END IrAdd;

  PROCEDURE IrAddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := IrLen(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END IrAddN;

  PROCEDURE IrEnds(VAR s: ARRAY OF CHAR; e: ARRAY OF CHAR): BOOLEAN;
    VAR n, m, i: INTEGER; ok: BOOLEAN;
  BEGIN
    n := IrLen(s); m := IrLen(e); ok := n > m; i := 0;
    WHILE ok & (i < m) DO IF s[n - m + i] # e[i] THEN ok := FALSE END; INC(i) END
    RETURN ok
  END IrEnds;

  PROCEDURE IrIsPicture*(VAR nm: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN IrEnds(nm, ".bmp") OR IrEnds(nm, ".ppm") OR IrEnds(nm, ".pgm")
  END IrIsPicture;

  PROCEDURE IrRGB(r, g, b: INTEGER): INTEGER;   (* 32 shades a colour: near points become one rectangle *)
  BEGIN RETURN OllGL6.RGB(r DIV 8 * 8 + 4, g DIV 8 * 8 + 4, b DIV 8 * 8 + 4)
  END IrRGB;

  PROCEDURE IrB(): INTEGER;   (* the next byte, -1 at the end *)
    VAR c: INTEGER;
  BEGIN c := Fisier.Citeste(Irh); IF c >= 0 THEN INC(Irpos) END
    RETURN c
  END IrB;

  PROCEDURE IrSize(w, ht: INTEGER; VAR st: INTEGER);   (* every st-th point, so that it fits in MX x MX *)
  BEGIN
    st := 1; WHILE (w + st - 1) DIV st > IrMX DO INC(st) END; WHILE (ht + st - 1) DIV st > IrMX DO INC(st) END;
    Irfw := w; Irfh := ht; Irpw := (w + st - 1) DIV st; Irph := (ht + st - 1) DIV st
  END IrSize;

  PROCEDURE IrPut(x, y, st, c: INTEGER);
  BEGIN IF (x MOD st = 0) & (y MOD st = 0) & (x DIV st < Irpw) & (y DIV st < Irph) THEN Irpix[(y DIV st) * IrMX + x DIV st] := c END
  END IrPut;

  (* ---------- PPM / PGM ---------- *)

  PROCEDURE IrNum(VAR c: INTEGER): INTEGER;   (* a number of the text part; c is the next byte after it *)
    VAR n: INTEGER;
  BEGIN
    n := 0;
    WHILE (c = 35) OR (c >= 0) & ((c < ORD("0")) OR (c > ORD("9"))) DO   (* spaces and # comments *)
      IF c = 35 THEN WHILE (c >= 0) & (c # 10) DO c := IrB() END END;
      c := IrB()
    END;
    WHILE (c >= ORD("0")) & (c <= ORD("9")) DO n := n * 10 + c - ORD("0"); c := IrB() END
    RETURN n
  END IrNum;

  PROCEDURE IrPnm(kind: INTEGER): BOOLEAN;   (* kind 2, 3, 5, 6 *)
    VAR c, w, ht, mx, st, x, y, r, g, b: INTEGER; ok: BOOLEAN;
  BEGIN
    c := IrB(); w := IrNum(c); ht := IrNum(c); mx := IrNum(c); ok := (w > 0) & (ht > 0) & (mx > 0) & (mx < 256);
    IF ok THEN
      IrSize(w, ht, st);
      FOR y := 0 TO ht - 1 DO
        FOR x := 0 TO w - 1 DO
          IF kind = 6 THEN r := IrB(); g := IrB(); b := IrB()
          ELSIF kind = 5 THEN r := IrB(); g := r; b := r
          ELSIF kind = 3 THEN r := IrNum(c); g := IrNum(c); b := IrNum(c)
          ELSE r := IrNum(c); g := r; b := r
          END;
          IF mx # 255 THEN r := r * 255 DIV mx; g := g * 255 DIV mx; b := b * 255 DIV mx END;
          IF r >= 0 THEN IrPut(x, y, st, IrRGB(r, g, b)) END
        END
      END
    ELSE Irerr := "NOT A PPM / PGM I KNOW"
    END
    RETURN ok
  END IrPnm;

  (* ---------- BMP ---------- *)

  PROCEDURE IrLe(p, n: INTEGER): INTEGER;   (* n bytes, little end first, from the header *)
    VAR v, k: INTEGER;
  BEGIN v := 0; FOR k := n - 1 TO 0 BY -1 DO v := v * 256 + Irhd[p + k] END
    RETURN v
  END IrLe;

  PROCEDURE IrBmp(): BOOLEAN;
    VAR k, off, w, ht, bpp, comp, hs, row, pad, st, x, y, r, g, b, i, c: INTEGER; up, ok: BOOLEAN;
  BEGIN
    Irhd[0] := 66; Irhd[1] := 77; k := 2;
    WHILE k < 54 DO c := IrB(); Irhd[k] := c; INC(k) END;
    off := IrLe(10, 4); hs := IrLe(14, 4); w := IrLe(18, 4); ht := IrLe(22, 4); bpp := IrLe(28, 2); comp := IrLe(30, 4);
    up := FALSE;
    IF Irhd[25] >= 128 THEN   (* a height under zero: the rows go from the top down *)
      up := TRUE; ht := (255 - Irhd[22]) + (255 - Irhd[23]) * 256 + (255 - Irhd[24]) * 65536 + 1
    ELSE ht := IrLe(22, 3)
    END;
    IF Irhd[21] >= 128 THEN w := 0 ELSE w := IrLe(18, 3) END;
    ok := (w > 0) & (w < 20000) & (ht > 0) & (ht < 20000) & ((bpp = 8) OR (bpp = 24) OR (bpp = 32)) & ((comp = 0) OR (comp = 3))
      & (off < 1100);
    IF ok THEN
      WHILE Irpos < off DO k := Irpos; c := IrB(); Irhd[k] := c END;   (* the palette of 8 bits is in here *)
      IrSize(w, ht, st);
      row := w * bpp DIV 8; pad := (4 - row MOD 4) MOD 4;
      FOR k := 0 TO ht - 1 DO
        IF up THEN y := k ELSE y := ht - 1 - k END;
        FOR x := 0 TO w - 1 DO
          IF bpp = 8 THEN c := IrB(); i := 14 + hs + c * 4; IF (c >= 0) & (i + 2 < 1100) THEN b := Irhd[i]; g := Irhd[i + 1]; r := Irhd[i + 2] ELSE r := 0; g := 0; b := 0 END
          ELSE b := IrB(); g := IrB(); r := IrB(); IF bpp = 32 THEN c := IrB() END
          END;
          IF r >= 0 THEN IrPut(x, y, st, IrRGB(r, g, b)) END
        END;
        FOR i := 1 TO pad DO c := IrB() END
      END
    ELSE Irerr := "A BMP I CANNOT READ (PACKED?)"
    END
    RETURN ok
  END IrBmp;

  PROCEDURE IrShow*(nm: ARRAY OF CHAR);   (* opens the picture nm *)
    VAR i, a, b: INTEGER; ok: BOOLEAN;
  BEGIN
    IrCopy(nm, Irname); Irerr[0] := 0X; Irpw := 0; Irph := 0; Irviewing := TRUE; ok := FALSE;
    FOR i := 0 TO IrMX * IrMX - 1 DO Irpix[i] := 0 END;
    Irh := Fisier.Deschide(nm); Irpos := 0;
    IF Irh < 0 THEN Irerr := "NO SUCH FILE"
    ELSE
      a := IrB(); b := IrB();
      IF (a = 66) & (b = 77) THEN ok := IrBmp()
      ELSIF (a = 80) & (b >= ORD("2")) & (b <= ORD("6")) & (b # ORD("4")) THEN ok := IrPnm(b - ORD("0"))
      ELSE Irerr := "NOT A PICTURE I KNOW"
      END;
      Fisier.Gata(Irh)
    END;
    IF ~ok THEN Irpw := 0; Irph := 0 END
  END IrShow;

  PROCEDURE IrNear(a, b: INTEGER): BOOLEAN;
    VAR d: INTEGER;
  BEGIN
    a := a + 16777216; b := b + 16777216;
    d := ABS(a MOD 256 - b MOD 256) + ABS(a DIV 256 MOD 256 - b DIV 256 MOD 256) + ABS(a DIV 65536 MOD 256 - b DIV 65536 MOD 256)
    RETURN d <= 24
  END IrNear;

  PROCEDURE IrDraw(x, y, p: INTEGER);   (* the picture at x, y; p units a point; runs of near colours *)
    VAR r, b, i0, c, st: INTEGER;
  BEGIN
    st := 1; IF Irpw * Irph > 9000 THEN IF OllGL6.Liber2D() < 30000 THEN st := 2 END END;
    r := 0;
    WHILE r < Irph DO
      b := 0;
      WHILE b < Irpw DO
        c := Irpix[r * IrMX + b];
        IF c # 0 THEN
          i0 := b; b := b + st;
          WHILE (b < Irpw) & (Irpix[r * IrMX + b] # 0) & IrNear(Irpix[r * IrMX + b], c) DO b := b + st END;
          OllGL6.Dreptunghi2D(x + i0 * p, y + r * p, (b - i0) * p, p * st, c)
        ELSE b := b + st
        END
      END;
      r := r + st
    END
  END IrDraw;

  PROCEDURE IrBuild;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    Irnl := 0; Fs2.Sync;
    FOR i := 0 TO Fs2.Count() - 1 DO Fs2.Name(i, nm); IF IrIsPicture(nm) & (Irnl < IrNL) THEN Irlist[Irnl] := i; INC(Irnl) END END
  END IrBuild;

  PROCEDURE IrSame(VAR a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN a[i] = b[i]
  END IrSame;

  PROCEDURE IrStep(d: INTEGER);   (* the previous or the next picture *)
    VAR i, k: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    k := -1; FOR i := 0 TO Irnl - 1 DO Fs2.Name(Irlist[i], nm); IF IrSame(nm, Irname) THEN k := i END END;
    IF Irnl > 0 THEN k := (k + d + Irnl) MOD Irnl; Fs2.Name(Irlist[k], nm); IrShow(nm) END
  END IrStep;

  PROCEDURE IrFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, p, ix, iy, bw, lim: INTEGER; s, nm: ARRAY 48 OF CHAR;
  BEGIN
    r := 0; bw := (IrW - 48) DIV 3;
    lim := IrH - 90 - 110 - Irnl * 64; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~Irdown THEN Irdown := TRUE; Irmoved := FALSE; Irx0 := x; Iry0 := y; Irscroll0 := Irscroll
    ELSIF isDown THEN
      IF ABS(y - Iry0) > 14 THEN Irmoved := TRUE END;
      IF Irmoved & ~Irviewing THEN Irscroll := Irscroll0 + y - Iry0 END
    ELSIF Irdown THEN
      Irdown := FALSE;
      IF ~Irmoved THEN
        IF Desk6.IsHome(Iry0) THEN r := -1
        ELSIF Irviewing & (Iry0 >= IrH - 150) & (Iry0 < IrH - 84) THEN
          i := (Irx0 - 24) DIV bw;
          IF i = 0 THEN IrStep(-1) ELSIF i = 1 THEN Irviewing := FALSE; IrBuild ELSE IrStep(1) END
        ELSIF ~Irviewing & (Iry0 >= 110) THEN
          i := (Iry0 - 110 - Irscroll) DIV 64;
          IF (i >= 0) & (i < Irnl) THEN Fs2.Name(Irlist[i], nm); IrShow(nm) END
        END
      END
    END;
    IF Irscroll > 0 THEN Irscroll := 0 ELSIF Irscroll < lim THEN Irscroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    IF Irviewing THEN
      IF (Irpw > 0) & (Irph > 0) THEN
        p := (IrW - 32) DIV Irpw; IF (IrH - 300) DIV Irph < p THEN p := (IrH - 300) DIV Irph END; IF p < 1 THEN p := 1 END;
        ix := (IrW - Irpw * p) DIV 2; iy := 120 + (IrH - 300 - Irph * p) DIV 2;
        OllGL6.Dreptunghi2D(ix - 4, iy - 4, Irpw * p + 8, Irph * p + 8, Desk6.surface);
        IrDraw(ix, iy, p);
        s[0] := 0X; IrAddN(s, Irfw); IrAdd(s, " X "); IrAddN(s, Irfh); IF Irfw > Irpw THEN IrAdd(s, "  (SHOWN "); IrAddN(s, Irpw); IrAdd(s, " X "); IrAddN(s, Irph); IrAdd(s, ")") END;
        Desk6.Centre(IrW DIV 2, IrH - 186, s, 2, Desk6.muted)
      ELSE Desk6.Centre(IrW DIV 2, IrH DIV 2 - 40, Irerr, 2, Desk6.red)
      END;
      OllGL6.Rotund2D(24, IrH - 150, bw - 8, 56, 28, Desk6.surface2); Desk6.Centre(24 + bw DIV 2 - 4, IrH - 130, "PREV", 2, Desk6.text);
      OllGL6.Rotund2D(24 + bw, IrH - 150, bw - 8, 56, 28, Desk6.surface2); Desk6.Centre(24 + bw + bw DIV 2 - 4, IrH - 130, "LIST", 2, Desk6.text);
      OllGL6.Rotund2D(24 + 2 * bw, IrH - 150, bw - 8, 56, 28, Desk6.surface2); Desk6.Centre(24 + 2 * bw + bw DIV 2 - 4, IrH - 130, "NEXT", 2, Desk6.text);
      Desk6.Header("IRIS", Irname)
    ELSE
      FOR i := 0 TO Irnl - 1 DO
        yy := 110 + Irscroll + i * 64;
        IF (yy > 50) & (yy < IrH - 80) THEN
          Fs2.Name(Irlist[i], nm);
          Desk6.Glyph(16, 24, yy + 8, 48); OllGL6.Text2D(88, yy + 22, nm, 2, Desk6.text)
        END
      END;
      IF Irnl = 0 THEN
        Desk6.Centre(IrW DIV 2, 300, "NO PICTURES IN THE CUBE YET", 2, Desk6.muted);
        Desk6.Centre(IrW DIV 2, 340, "FILES . IMPORT BRINGS ONE FROM THE PHONE", 2, Desk6.muted)
      END;
      s[0] := 0X; IrAddN(s, Irnl); IrAdd(s, " PICTURES");
      IrAdd(s, " . IMAGES"); Desk6.Header("IRIS", s)
    END;
    Desk6.Bottom; Desk6.Toast(IrH - 200);
    OllGL6.Arata
    RETURN r
  END IrFrame;

  PROCEDURE IrEnter*;
  BEGIN Irdown := TRUE; Irmoved := TRUE; IrBuild
  END IrEnter;

  PROCEDURE IrStart*(w, ht: INTEGER);
  BEGIN IrW := w; IrH := ht
  END IrStart;

  (* ================= ROBIN (help): Help2 ================= *)

  PROCEDURE RbL(k: INTEGER; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF Rbn < RbNL THEN
      i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < 43) DO Rbtxt[Rbn][i] := s[i]; INC(i) END; Rbtxt[Rbn][i] := 0X;
      Rbkind[Rbn] := k; IF (k = 1) & (Rbnh < 16) THEN Rbhead[Rbnh] := Rbn; INC(Rbnh) END; INC(Rbn)
    END
  END RbL;

  PROCEDURE RbT(s: ARRAY OF CHAR); BEGIN RbL(0, s) END RbT;
  PROCEDURE RbC(s: ARRAY OF CHAR); BEGIN RbL(2, s) END RbC;

  PROCEDURE RbFill;
  BEGIN
    Rbn := 0; Rbnh := 0;
    RbL(3, "PIXIPOGO . THE MANUAL"); RbT("");
    RbL(1, "1 THE DESK"); RbL(1, "2 THE COURT"); RbL(1, "3 COBWEB . FILES"); RbL(1, "4 PUCK . TASKS"); RbL(1, "5 MUSTARDSEED . MOTH . IRIS");
    RbL(1, "6 OBERON . THE SHELL"); RbL(1, "7 THE CUBE AND ITS ADDRESSES"); RbL(1, "8 HOSTED OR BARE METAL"); RbT("");
    Rbnh := 0;   (* the real titles start here; the lines above are the contents *)
    RbL(1, "1 THE DESK");
    RbT("THE BAR AT THE TOP: THE TIME, THE HOST,");
    RbT("THE BATTERY. TAP IT FOR SETTINGS.");
    RbT("THE CUBE: GOLD CELLS HOLD FILES.");
    RbT("DRAG IT TO TURN IT.");
    RbT("THE DOCK: ARIEL (SYNTH), ECHO (PLAYER),");
    RbT("OBERON (SHELL), COBWEB (FILES) AND THE");
    RbT("COURT (APPS). THE CARD SAYS WHAT RUNS.");
    RbT("");
    RbL(1, "2 THE COURT");
    RbT("THE FAIRIES OF OBERON, EACH WITH ITS JOB:");
    RbL(2, "ARIEL        SYNTH");
    RbL(2, "ECHO         PLAYER");
    RbL(2, "OBERON       SHELL");
    RbL(2, "MAB          CANVAS");
    RbL(2, "COBWEB       FILES");
    RbL(2, "TITANIA      SETTINGS");
    RbL(2, "PUCK         TASKS");
    RbL(2, "MUSTARDSEED  CALC");
    RbL(2, "MOTH         CLOCK");
    RbL(2, "IRIS         IMAGES");
    RbL(2, "ROBIN        HELP");
    RbT("THEN THE TOOLS");
    RbT("ON THE HOST (INSTALL = CRISALIDA, BYZ7)");
    RbT("AND THE PROGRAMS IN THE CUBE: A TAP");
    RbT("RUNS ONE IN THE SHELL.");
    RbT("JAHBALON, ANDROID: THE APPS OF THE");
    RbT("PHONE. A TAP OPENS ONE. REFRESH ASKS");
    RbT("THE PHONE AGAIN.");
    RbT("");
    RbL(1, "3 COBWEB . FILES");
    RbT("THE CUBE ABOVE, THE LIST BELOW. TAP A");
    RbT("FILE: ITS CELL TURNS RED. THEN:");
    RbC("OPEN     THE EDITOR (A PICTURE: IRIS)");
    RbC("RUN      A .MOD OR .Z7 PROGRAM");
    RbC("PACK     INTO A Z7 ARCH CUBE .Z7C");
    RbC("UNPACK   EVERY FILE OUT OF A .Z7C");
    RbC("EXPORT   TO DOWNLOAD/CUBICUMN");
    RbC("DELETE   TAP TWICE (SURE?)");
    RbT("IMPORT AT THE TOP BRINGS A FILE FROM");
    RbT("THE PHONE. A PHOTO ALSO COMES AS .PPM,");
    RbT("SMALL, FOR IRIS.");
    RbT("");
    RbL(1, "4 PUCK . TASKS");
    RbT("THE SEVEN TURNS OF TOR7, AS A SPIRAL.");
    RbT("GREEN RUNS, BLUE SLEEPS, GOLD WAITS,");
    RbT("VIOLET RECEIVES, DARK IS FREE.");
    RbT("STOP ENDS A PROGRAM. BELOW: THE FIELD,");
    RbT("OPAL'S BEAT, THE BURNS AND THE ASH.");
    RbT("");
    RbL(1, "5 MUSTARDSEED . MOTH . IRIS");
    RbT("MUSTARDSEED: WHOLE NUMBERS IN BASE 10 OR");
    RbT("IN BASE 7 WITHOUT ZERO (KEY 10 / Z7).");
    RbT("UNDER THE NUMBER: THE OTHER BASE, MOD 7");
    RbT("AND ITS CELL IN THE CUBE.");
    RbT("MOTH: A DIAL, A TIMER THAT RINGS ON ANY");
    RbT("SCREEN, A STOPWATCH WITH LAPS.");
    RbT("IRIS: BMP, PPM, PGM IN THE CUBE.");
    RbT("");
    RbL(1, "6 OBERON . THE SHELL");
    RbC("HELP          ALL THE COMMANDS");
    RbC("LS            THE FILES AND THEIR CELLS");
    RbC("EDIT NAME     WRITE A FILE");
    RbC("RUN NAME      A PROGRAM ON A TURN");
    RbC("PS, KILL N    THE TURNS; END ONE");
    RbC("NOTE X Y Z MS ONE NOTE OF THE CUBE");
    RbC("ARCH          Z7 ARCH (ARCH: HOW)");
    RbC("APPS          THE APPS OF THE HOST");
    RbC("OPEN NAME     START ONE OF THEM");
    RbC("HOME          BACK TO THE DESK");
    RbT("");
    RbL(1, "7 THE CUBE AND ITS ADDRESSES");
    RbT("7 X 7 X 7 = 343 CELLS. THE CENTRE IS");
    RbT("(4,4,4). EVERY FILE HAS AN ADDRESS OF");
    RbT("7 DIGITS FROM 1 TO 7 (NO ZERO):");
    RbT("NAME TYPE DAY FOLDER SIZE MONTH HOUR,");
    RbT("AND A CELL OF THE CUBE.");
    RbT("");
    RbL(1, "8 HOSTED OR BARE METAL");
    RbT("ON A PHONE, PIXIPOGO SEES ITS HOST:");
    RbT("THE APPS, THE BATTERY, THE CLOCK, THE");
    RbT("FILES OF THE PHONE. WITH NO HOST IT");
    RbT("RUNS ALONE, WITH ITS OWN PROGRAMS: THE");
    RbT("BAR SAYS BARE METAL.");
    RbT("");
    RbL(3, "OBERON-07 . OLL . BYZ7");
    RbL(3, "PION AND CLAUDE . JAHBALON . 2026");
    RbL(3, "E PUR SI TORQUE")
  END RbFill;

  PROCEDURE RbFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, lim, c, k: INTEGER;
  BEGIN
    r := 0; lim := RbH - 90 - RbTOP - Rbn * RbLH; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~Rbdown THEN Rbdown := TRUE; Rbmoved := FALSE; Rbx0 := x; Rby0 := y; Rbscroll0 := Rbscroll
    ELSIF isDown THEN
      IF ABS(y - Rby0) > 14 THEN Rbmoved := TRUE END;
      IF Rbmoved THEN Rbscroll := Rbscroll0 + y - Rby0 END
    ELSIF Rbdown THEN
      Rbdown := FALSE;
      IF ~Rbmoved THEN
        IF Desk6.IsHome(Rby0) THEN r := -1
        ELSE   (* a title in the contents: go there *)
          i := (Rby0 - RbTOP - Rbscroll) DIV RbLH;
          IF (i >= 2) & (i < 10) & (Rbkind[i] = 1) THEN k := i - 2; IF k < Rbnh THEN Rbscroll := -(Rbhead[k] * RbLH) + 10 END END
        END
      END
    END;
    IF Rbscroll > 0 THEN Rbscroll := 0 ELSIF Rbscroll < lim THEN Rbscroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    FOR i := 0 TO Rbn - 1 DO
      yy := RbTOP + Rbscroll + i * RbLH;
      IF (yy > 60) & (yy < RbH - 80) THEN
        k := Rbkind[i];
        IF k = 1 THEN c := Desk6.Accent() ELSIF k = 2 THEN c := OllGL6.RGB(125, 211, 252) ELSIF k = 3 THEN c := Desk6.muted ELSE c := Desk6.text END;
        IF k = 3 THEN Desk6.Centre(RbW DIV 2, yy, Rbtxt[i], 2, c) ELSE OllGL6.Text2D(24, yy, Rbtxt[i], 2, c) END
      END
    END;
    Desk6.Header("ROBIN", "HELP . DRAG TO READ");
    Desk6.Bottom;
    OllGL6.Arata
    RETURN r
  END RbFrame;

  PROCEDURE RbEnter*;
  BEGIN Rbdown := TRUE; Rbmoved := TRUE
  END RbEnter;

  PROCEDURE RbStart*(w, h: INTEGER);
  BEGIN RbW := w; RbH := h
  END RbStart;


  (* ================= PHILOMEL and PEASEBLOSSOM: Zane2 ================= *)

  PROCEDURE ZnLen(s: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END
    RETURN n
  END ZnLen;

  PROCEDURE ZnCopy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(d) - 1) DO d[i] := s[i]; INC(i) END; d[i] := 0X
  END ZnCopy;

  PROCEDURE ZnAdd(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := ZnLen(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END ZnAdd;

  PROCEDURE ZnAddN(VAR s: ARRAY OF CHAR; n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF n < 0 THEN n := 0 END;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    j := ZnLen(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END ZnAddN;

  PROCEDURE ZnAddTime(VAR s: ARRAY OF CHAR; ms: INTEGER);   (* m:ss *)
    VAR sec: INTEGER;
  BEGIN
    sec := ms DIV 1000; ZnAddN(s, sec DIV 60); ZnAdd(s, ":"); IF sec MOD 60 < 10 THEN ZnAdd(s, "0") END; ZnAddN(s, sec MOD 60)
  END ZnAddTime;

  PROCEDURE ZnSame(a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN a[i] = b[i]
  END ZnSame;

  PROCEDURE ZnPut(h: INTEGER; s: ARRAY OF CHAR);   (* the letters of s into file h *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Fisier.Scrie(h, ORD(s[i])); INC(i) END
  END ZnPut;

  PROCEDURE ZnGo(nm: ARRAY OF CHAR);   (* the little file that tells the window to look *)
    VAR h: INTEGER;
  BEGIN h := Fisier.Creeaza(nm); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END
  END ZnGo;

  PROCEDURE ZnReadNums(nm: ARRAY OF CHAR; VAR v: ARRAY OF INTEGER): INTEGER;   (* the numbers of the first line; how many *)
    VAR h, c, n: INTEGER; inNum: BOOLEAN;
  BEGIN
    n := 0; h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      inNum := FALSE; c := Fisier.Citeste(h);
      WHILE (c >= 0) & (c # 10) & (n < LEN(v)) DO
        IF (c >= ORD("0")) & (c <= ORD("9")) THEN
          IF ~inNum THEN v[n] := 0; inNum := TRUE END;
          v[n] := v[n] * 10 + c - ORD("0")
        ELSIF inNum THEN inNum := FALSE; INC(n)
        END;
        c := Fisier.Citeste(h)
      END;
      IF inNum & (n < LEN(v)) THEN INC(n) END;
      Fisier.Gata(h)
    END
    RETURN n
  END ZnReadNums;

  PROCEDURE ZnButton(x, y, w: INTEGER; s: ARRAY OF CHAR; on: BOOLEAN);
  BEGIN
    IF on THEN OllGL6.Rotund2D(x, y, w, 56, 28, Desk6.Accent()); Desk6.Centre(x + w DIV 2, y + 20, s, 2, Desk6.dark)
    ELSE OllGL6.Rotund2D(x, y, w, 56, 28, Desk6.surface2); Desk6.Centre(x + w DIV 2, y + 20, s, 2, Desk6.text)
    END
  END ZnButton;

  PROCEDURE ZnShort(VAR s: ARRAY OF CHAR; n: INTEGER);   (* at most n letters *)
  BEGIN IF ZnLen(s) > n THEN s[n - 1] := "."; s[n] := 0X END
  END ZnShort;

  (* ---------- PHILOMEL ---------- *)

  PROCEDURE ZnSave;   (* zane.cfg: "S pos song" and "B page book" lines *)
    VAR h, i: INTEGER; s: ARRAY 64 OF CHAR;
  BEGIN
    h := Fisier.Creeaza("zane.cfg");
    IF h >= 0 THEN
      IF Znsong[0] # 0X THEN s := "S "; ZnAddN(s, Znpos); ZnAdd(s, " "); ZnAdd(s, Znsong); ZnPut(h, s); Fisier.Scrie(h, 10) END;
      FOR i := 0 TO ZnbkN - 1 DO s := "B "; ZnAddN(s, ZnbkPage[i]); ZnAdd(s, " "); ZnAdd(s, ZnbkName[i]); ZnPut(h, s); Fisier.Scrie(h, 10) END;
      Fisier.Gata(h)
    END;
    ZntSave := Ceas.Ms()
  END ZnSave;

  PROCEDURE ZnLoad;
    VAR h, c, k, n, i: INTEGER; kind: CHAR; nm: ARRAY 40 OF CHAR;
  BEGIN
    h := Fisier.Deschide("zane.cfg");
    IF h >= 0 THEN
      c := Fisier.Citeste(h);
      WHILE c >= 0 DO
        kind := CHR(c); n := 0; c := Fisier.Citeste(h);
        WHILE c = 32 DO c := Fisier.Citeste(h) END;
        WHILE (c >= ORD("0")) & (c <= ORD("9")) DO n := n * 10 + c - ORD("0"); c := Fisier.Citeste(h) END;
        WHILE c = 32 DO c := Fisier.Citeste(h) END;
        k := 0; WHILE (c > 32) & (k < 39) DO nm[k] := CHR(c); INC(k); c := Fisier.Citeste(h) END; nm[k] := 0X;
        WHILE (c >= 0) & (c # 10) DO c := Fisier.Citeste(h) END;
        IF c = 10 THEN c := Fisier.Citeste(h) END;
        IF k > 0 THEN
          IF kind = "S" THEN ZnCopy(nm, Znsong); ZnsavedPos := n; Znpos := n
          ELSIF (kind = "B") & (ZnbkN < ZnNB) THEN ZnCopy(nm, ZnbkName[ZnbkN]); ZnbkPage[ZnbkN] := n; INC(ZnbkN)
          END
        END
      END;
      Fisier.Gata(h)
    END;
    i := 0
  END ZnLoad;

  PROCEDURE ZnRemember(nm: ARRAY OF CHAR; page: INTEGER);   (* the book goes first in the list, with its page *)
    VAR i, k: INTEGER;
  BEGIN
    k := 0; WHILE (k < ZnbkN) & ~ZnSame(ZnbkName[k], nm) DO INC(k) END;
    IF k = ZnbkN THEN IF ZnbkN < ZnNB THEN INC(ZnbkN) END; k := ZnbkN - 1 END;
    FOR i := k TO 1 BY -1 DO ZnbkName[i] := ZnbkName[i - 1]; ZnbkPage[i] := ZnbkPage[i - 1] END;
    ZnCopy(nm, ZnbkName[0]); ZnbkPage[0] := page;
    ZnSave
  END ZnRemember;

  PROCEDURE ZnPageOf(nm: ARRAY OF CHAR): INTEGER;
    VAR k, p: INTEGER;
  BEGIN
    p := 0; FOR k := 0 TO ZnbkN - 1 DO IF ZnSame(ZnbkName[k], nm) THEN p := ZnbkPage[k] END END
    RETURN p
  END ZnPageOf;

  PROCEDURE PhIsSong*(VAR nm: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN Desk6.KindOf(nm) = 18
  END PhIsSong;

  PROCEDURE ZnPhBuild;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    ZnphN := 0; Fs2.Sync;
    FOR i := 0 TO Fs2.Count() - 1 DO Fs2.Name(i, nm); IF PhIsSong(nm) & (ZnphN < ZnNL) THEN ZnphList[ZnphN] := i; INC(ZnphN) END END
  END ZnPhBuild;

  PROCEDURE ZnSend(cmd: ARRAY OF CHAR);   (* one command for the phone's player *)
    VAR h: INTEGER;
  BEGIN
    h := Fisier.Creeaza("aud.txt");
    IF h >= 0 THEN ZnPut(h, cmd); Fisier.Scrie(h, 10); Fisier.Gata(h); ZnGo("aud-go"); ZntSent := Ceas.Ms() END
  END ZnSend;

  PROCEDURE PhPlay*(nm: ARRAY OF CHAR);   (* plays song nm *)
    VAR c: ARRAY 64 OF CHAR;
  BEGIN
    ZnCopy(nm, Znsong);
    IF ~Gazda4.Hosted() THEN Desk6.Say("NO HOST: NOBODY TO PLAY IT")
    ELSE c := "play "; ZnAdd(c, nm); ZnSend(c); Znst := 1; Znpos := 0; Zndur := 0; ZnsavedPos := 0; ZnSave
    END
  END PhPlay;

  PROCEDURE ZnStep(d: INTEGER);   (* the previous or the next song *)
    VAR i, k: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    ZnPhBuild; k := -1;
    FOR i := 0 TO ZnphN - 1 DO Fs2.Name(ZnphList[i], nm); IF ZnSame(nm, Znsong) THEN k := i END END;
    IF ZnphN > 0 THEN
      IF k < 0 THEN k := 0 ELSE k := (k + d + ZnphN) MOD ZnphN END;
      Fs2.Name(ZnphList[k], nm); PhPlay(nm)
    END
  END ZnStep;

  PROCEDURE PhTick*;   (* every frame, in every screen: what the phone says; the next song when one ends *)
    VAR v: ARRAY 4 OF INTEGER; t: INTEGER; c: ARRAY 24 OF CHAR;
  BEGIN
    t := Ceas.Ms();
    IF (Znsong[0] # 0X) & (t - ZntPoll > 300) & (t - ZntSent > 700) THEN
      ZntPoll := t;
      IF ZnReadNums("aud-st.txt", v) >= 3 THEN
        Znst := v[0]; Znpos := v[1]; Zndur := v[2];
        IF Znst = 3 THEN Znst := 0; ZnStep(1)
        ELSIF (Znst = 1) & (ZnseekTo > 0) THEN c := "seek "; ZnAddN(c, ZnseekTo); ZnSend(c); Znpos := ZnseekTo; ZnseekTo := 0
        ELSIF (Znst = 0) & (ZnsavedPos > 0) THEN Znpos := ZnsavedPos   (* still where it was before the restart *)
        ELSIF (Znst = 1) & (t - ZntSave > 5000) THEN ZnSave
        END
      END
    END
  END PhTick;

  PROCEDURE PhPlaying*(VAR s: ARRAY OF CHAR): BOOLEAN;   (* for the card of HOME *)
  BEGIN
    IF (Znsong[0] # 0X) & ((Znst = 1) OR (Znst = 2)) THEN ZnCopy(Znsong, s); ZnShort(s, 16) ELSE s[0] := 0X END
    RETURN s[0] # 0X
  END PhPlaying;

  PROCEDURE ZnBars(x, y, w, h: INTEGER);   (* the nightingale sings: bars that move with the song *)
    VAR k, bw, bh, t: INTEGER; a: REAL;
  BEGIN
    bw := w DIV 16; t := Ceas.Ms();
    FOR k := 0 TO 15 DO
      IF Znst = 1 THEN
        a := Math.sin(FLT(t) * 0.004 * (1.0 + FLT(k) * 0.23) + FLT(k) * 1.7);
        IF a < 0.0 THEN a := -a END;
        bh := 8 + FLOOR(FLT(h - 8) * a * (0.5 + 0.5 * Math.sin(FLT(t) * 0.0013 + FLT(k))))
      ELSE bh := 8
      END;
      IF bh < 8 THEN bh := 8 END;
      IF k MOD 3 = 0 THEN OllGL6.Rotund2D(x + k * bw + 3, y + h - bh, bw - 6, bh, 4, Desk6.Accent())
      ELSE OllGL6.Rotund2D(x + k * bw + 3, y + h - bh, bw - 6, bh, 4, OllGL6.RGB(170, 40, 110))
      END
    END
  END ZnBars;

  PROCEDURE PhFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, top, lim, bw, px, d, n: INTEGER; s, nm: ARRAY 64 OF CHAR;
  BEGIN
    r := 0; top := 520; bw := (ZnW - 48) DIV 3;
    lim := ZnH - 90 - top - ZnphN * ZnRH; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~ZnphDown THEN ZnphDown := TRUE; ZnphMoved := FALSE; ZnphX0 := x; ZnphY0 := y; ZnphScroll0 := ZnphScroll
    ELSIF isDown THEN
      IF ABS(y - ZnphY0) > 14 THEN ZnphMoved := TRUE END;
      IF ZnphMoved & (ZnphY0 >= top) THEN ZnphScroll := ZnphScroll0 + y - ZnphY0 END
    ELSIF ZnphDown THEN
      ZnphDown := FALSE;
      IF ~ZnphMoved THEN
        IF Desk6.IsHome(ZnphY0) THEN r := -1
        ELSIF (ZnphY0 >= 340) & (ZnphY0 < 380) & (Zndur > 0) THEN   (* the bar of the time: jump there *)
          d := (ZnphX0 - 24) * (Zndur DIV 100) DIV (ZnW - 48) * 100; IF d < 0 THEN d := 0 END;
          s := "seek "; ZnAddN(s, d); ZnSend(s); Znpos := d
        ELSIF (ZnphY0 >= 410) & (ZnphY0 < 466) THEN
          i := (ZnphX0 - 24) DIV bw;
          IF i = 0 THEN ZnStep(-1)
          ELSIF i = 1 THEN
            IF Znsong[0] = 0X THEN ZnStep(1)
            ELSIF Znst = 1 THEN ZnSend("pause"); Znst := 2; ZnSave
            ELSIF Znst = 2 THEN ZnSend("resume"); Znst := 1
            ELSE n := ZnsavedPos; PhPlay(Znsong); ZnseekTo := n   (* after a restart: from the same second *)
            END
          ELSE ZnStep(1)
          END
        ELSIF ZnphY0 >= top THEN
          i := (ZnphY0 - top - ZnphScroll) DIV ZnRH;
          IF (i >= 0) & (i < ZnphN) THEN Fs2.Name(ZnphList[i], nm); PhPlay(nm) END
        END
      END
    END;
    IF ZnphScroll > 0 THEN ZnphScroll := 0 ELSIF ZnphScroll < lim THEN ZnphScroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    (* the list, under the player *)
    FOR i := 0 TO ZnphN - 1 DO
      yy := top + ZnphScroll + i * ZnRH;
      IF (yy > top - ZnRH) & (yy < ZnH - 80) THEN
        Fs2.Name(ZnphList[i], nm);
        IF ZnSame(nm, Znsong) THEN OllGL6.Rotund2D(16, yy, ZnW - 32, ZnRH - 6, 14, Desk6.surface2) END;
        Desk6.Glyph(18, 24, yy + 6, 46); ZnShort(nm, 30); OllGL6.Text2D(88, yy + 20, nm, 2, Desk6.text)
      END
    END;
    IF ZnphN = 0 THEN
      Desk6.Centre(ZnW DIV 2, top + 40, "NO SONGS IN THE CUBE YET", 2, Desk6.muted);
      Desk6.Centre(ZnW DIV 2, top + 80, "FILES . IMPORT BRINGS ONE FROM THE PHONE", 2, Desk6.muted)
    END;
    (* the player, over the list *)
    OllGL6.Dreptunghi2D(0, 0, ZnW, top - 4, Desk6.bg);
    OllGL6.Rotund2D(16, 112, ZnW - 32, top - 124, 22, Desk6.surface);
    ZnBars(40, 132, ZnW - 80, 120);
    IF Znsong[0] # 0X THEN ZnCopy(Znsong, s); ZnShort(s, 34) ELSE s := "CHOOSE A SONG" END;
    Desk6.Centre(ZnW DIV 2, 276, s, 3, Desk6.text);
    s[0] := 0X; ZnAddTime(s, Znpos); IF Zndur > 0 THEN ZnAdd(s, " / "); ZnAddTime(s, Zndur) END;
    IF Znst = 2 THEN ZnAdd(s, "  PAUSED") END;
    Desk6.Centre(ZnW DIV 2, 316, s, 2, Desk6.muted);
    OllGL6.Rotund2D(24, 352, ZnW - 48, 14, 7, Desk6.surface2);
    IF Zndur > 0 THEN
      px := (ZnW - 48) * (Znpos DIV 100) DIV (Zndur DIV 100 + 1); IF px > ZnW - 48 THEN px := ZnW - 48 END;
      OllGL6.Rotund2D(24, 352, px + 14, 14, 7, Desk6.Accent()); OllGL6.Cerc2D(24 + px + 7, 359, 13, Desk6.text)
    END;
    ZnButton(24, 410, bw - 8, "PREV", FALSE);
    IF Znst = 1 THEN ZnButton(24 + bw, 410, bw - 8, "PAUSE", TRUE) ELSE ZnButton(24 + bw, 410, bw - 8, "PLAY", TRUE) END;
    ZnButton(24 + 2 * bw, 410, bw - 8, "NEXT", FALSE);
    s[0] := 0X; ZnAddN(s, ZnphN); ZnAdd(s, " SONGS . MUSIC"); Desk6.Header("PHILOMEL", s);
    Desk6.Bottom; Desk6.Toast(ZnH - 200);
    OllGL6.Arata
    RETURN r
  END PhFrame;

  PROCEDURE PhEnter*;
  BEGIN ZnphDown := TRUE; ZnphMoved := TRUE; ZnPhBuild
  END PhEnter;

  (* ---------- PEASEBLOSSOM ---------- *)

  PROCEDURE PbIsBook*(VAR nm: ARRAY OF CHAR): BOOLEAN;
  BEGIN RETURN Desk6.KindOf(nm) = 19
  END PbIsBook;

  PROCEDURE ZnPbBuild;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    ZnpbN := 0; Fs2.Sync;
    FOR i := 0 TO Fs2.Count() - 1 DO Fs2.Name(i, nm); IF PbIsBook(nm) & (ZnpbN < ZnNL) THEN ZnpbList[ZnpbN] := i; INC(ZnpbN) END END
  END ZnPbBuild;

  PROCEDURE ZnAsk;   (* page of book, drawn by the phone in the window of the reader *)
    VAR h: INTEGER; s: ARRAY 96 OF CHAR;
  BEGIN
    IF ~Gazda4.Hosted() THEN ZnpbErr := "NO HOST: THE PHONE DRAWS THE PAGES"
    ELSE
      Fisier.Sterge("pdf-ok.txt"); h := Fisier.Creeaza("pdf.txt");
      IF h >= 0 THEN
        ZnCopy(Znbook, s); ZnAdd(s, " "); ZnAddN(s, Znpage); ZnAdd(s, " "); ZnAddN(s, Znzoom); ZnAdd(s, " 20 174 "); ZnAddN(s, ZnW - 40);
        ZnAdd(s, " "); ZnAddN(s, ZnH - 174 - 172); ZnAdd(s, " "); ZnAddN(s, ZnW); ZnAdd(s, " "); ZnAddN(s, ZnH);
        ZnPut(h, s); Fisier.Scrie(h, 10); Fisier.Gata(h); ZnGo("pdf-go");
        Znwaiting := TRUE; ZntAsk := Ceas.Ms(); ZnpbErr[0] := 0X
      END
    END
  END ZnAsk;

  PROCEDURE PbHide*;   (* the page leaves the screen with the reader *)
    VAR h: INTEGER;
  BEGIN
    IF Znshown OR Znwaiting THEN
      h := Fisier.Creeaza("pdf.txt"); IF h >= 0 THEN ZnPut(h, "hide"); Fisier.Scrie(h, 10); Fisier.Gata(h); ZnGo("pdf-go") END;
      Znshown := FALSE; Znwaiting := FALSE
    END
  END PbHide;

  PROCEDURE PbShow*(nm: ARRAY OF CHAR);   (* opens book nm; the same book opens where it was left *)
  BEGIN
    IF ~ZnSame(nm, Znbook) THEN ZnCopy(nm, Znbook); Znpage := ZnPageOf(nm); Znpages := 0; Znzoom := 1 END;
    Znreading := TRUE; ZnAsk
  END PbShow;

  PROCEDURE ZnAnswer;   (* what the phone said: "1 page pages w h" or "0 why" *)
    VAR v: ARRAY 6 OF INTEGER; n, h: INTEGER;
  BEGIN
    IF Znwaiting & (Ceas.Ms() - ZntAsk > 150) THEN
      h := -1; n := ZnReadNums("pdf-ok.txt", v);
      IF n >= 3 THEN Znpage := v[1]; Znpages := v[2]; Znwaiting := FALSE; Znshown := TRUE; Fisier.Sterge("pdf-ok.txt");
        ZnRemember(Znbook, Znpage)
      ELSE h := Fisier.Deschide("pdf-ok.txt"); IF h >= 0 THEN Fisier.Gata(h) END END;
      IF ~Znwaiting OR (n >= 3) THEN
      ELSIF h >= 0 THEN   (* "0 why": a file the phone cannot read *)
        ZnpbErr := "THE PHONE CANNOT READ THIS PDF"; Znwaiting := FALSE; Fisier.Sterge("pdf-ok.txt")
      ELSIF Ceas.Ms() - ZntAsk > 15000 THEN ZnpbErr := "NO ANSWER. THE WINDOW NEEDS ECRAN-CUBN24.DEX"; Znwaiting := FALSE
      END
    END
  END ZnAnswer;

  PROCEDURE ZnTurn(d: INTEGER);
  BEGIN
    IF ~Znwaiting & (Znpage + d >= 0) & ((Znpages = 0) OR (Znpage + d < Znpages)) THEN Znpage := Znpage + d; ZnAsk END
  END ZnTurn;

  PROCEDURE PbFrame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, top, lim, bw: INTEGER; s, nm: ARRAY 64 OF CHAR;
  BEGIN
    r := 0; top := 110; bw := (ZnW - 48) DIV 4;
    IF Znreading THEN ZnAnswer END;
    lim := ZnH - 90 - top - ZnpbN * ZnRH; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~ZnpbDown THEN ZnpbDown := TRUE; ZnpbMoved := FALSE; ZnpbX0 := x; ZnpbY0 := y; ZnpbScroll0 := ZnpbScroll
    ELSIF isDown THEN
      IF ABS(y - ZnpbY0) > 14 THEN ZnpbMoved := TRUE END;
      IF ZnpbMoved & ~Znreading THEN ZnpbScroll := ZnpbScroll0 + y - ZnpbY0 END
    ELSIF ZnpbDown THEN
      ZnpbDown := FALSE;
      IF ~ZnpbMoved THEN
        IF Desk6.IsHome(ZnpbY0) THEN PbHide; r := -1
        ELSIF Znreading & (ZnpbY0 >= ZnH - 150) & (ZnpbY0 < ZnH - 84) THEN
          i := (ZnpbX0 - 24) DIV bw;
          IF i = 0 THEN ZnTurn(-1)
          ELSIF i = 1 THEN PbHide; Znreading := FALSE; ZnPbBuild
          ELSIF i = 2 THEN IF ~Znwaiting THEN Znzoom := 3 - Znzoom; ZnAsk END
          ELSE ZnTurn(1)
          END
        ELSIF ~Znreading & (ZnpbY0 >= top) THEN
          i := (ZnpbY0 - top - ZnpbScroll) DIV ZnRH;
          IF (i >= 0) & (i < ZnpbN) THEN Fs2.Name(ZnpbList[i], nm); PbShow(nm) END
        END
      END
    END;
    IF ZnpbScroll > 0 THEN ZnpbScroll := 0 ELSIF ZnpbScroll < lim THEN ZnpbScroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    IF Znreading THEN
      OllGL6.Rotund2D(12, 166, ZnW - 24, ZnH - 174 - 172 + 16, 12, Desk6.surface);   (* the frame of the page *)
      IF ZnpbErr[0] # 0X THEN Desk6.Centre(ZnW DIV 2, ZnH DIV 2 - 40, ZnpbErr, 2, Desk6.red)
      ELSIF ~Znshown THEN Desk6.Centre(ZnW DIV 2, ZnH DIV 2 - 40, "THE PHONE DRAWS THE PAGE ...", 2, Desk6.muted)
      END;
      ZnButton(24, ZnH - 150, bw - 8, "PREV", FALSE); ZnButton(24 + bw, ZnH - 150, bw - 8, "LIST", FALSE);
      IF Znzoom = 2 THEN ZnButton(24 + 2 * bw, ZnH - 150, bw - 8, "FIT", TRUE) ELSE ZnButton(24 + 2 * bw, ZnH - 150, bw - 8, "ZOOM", FALSE) END;
      ZnButton(24 + 3 * bw, ZnH - 150, bw - 8, "NEXT", FALSE);
      s := "PAGE "; ZnAddN(s, Znpage + 1); IF Znpages > 0 THEN ZnAdd(s, " / "); ZnAddN(s, Znpages) END;
      IF Znwaiting THEN ZnAdd(s, " ...") END;
      Desk6.Header("PEASEBLOSSOM", s)
    ELSE
      FOR i := 0 TO ZnpbN - 1 DO
        yy := top + ZnpbScroll + i * ZnRH;
        IF (yy > 50) & (yy < ZnH - 80) THEN
          Fs2.Name(ZnpbList[i], nm);
          Desk6.Glyph(19, 24, yy + 6, 46); ZnShort(nm, 30); OllGL6.Text2D(88, yy + 20, nm, 2, Desk6.text)
        END
      END;
      IF ZnpbN = 0 THEN
        Desk6.Centre(ZnW DIV 2, 300, "NO BOOKS IN THE CUBE YET", 2, Desk6.muted);
        Desk6.Centre(ZnW DIV 2, 340, "FILES . IMPORT BRINGS A PDF FROM THE PHONE", 2, Desk6.muted)
      END;
      s[0] := 0X; ZnAddN(s, ZnpbN); ZnAdd(s, " BOOKS . BOOKS"); Desk6.Header("PEASEBLOSSOM", s)
    END;
    Desk6.Bottom; Desk6.Toast(ZnH - 200);
    OllGL6.Arata
    RETURN r
  END PbFrame;

  PROCEDURE PbEnter*;
  BEGIN ZnpbDown := TRUE; ZnpbMoved := TRUE; ZnPbBuild; IF Znreading & ~Znwaiting THEN ZnAsk END
  END PbEnter;

  PROCEDURE ZnStart*(w, h: INTEGER);
  BEGIN ZnW := w; ZnH := h; ZnLoad
  END ZnStart;

BEGIN
PkW := 1; PkH := 1; Pkdown := FALSE; Pkmoved := FALSE; PktSpeed := 0;
  MsW := 1; MsH := 1; Msacc := 0; Mscur := 0; Msop := 0; Msrest := -1; MsopAt := 0; Msfresh := TRUE; Msz7 := FALSE; Mserr := FALSE; MshasAcc := FALSE;
  Msshown := FALSE; Msline[0] := 0X; Msdown := FALSE; Msmoved := FALSE; MskTop := 400; MskH := 120; MskW := 120;
  MoW := 1; MoH := 1; Motab := 0; Modown := FALSE; Momoved := FALSE; MotSet := 0; MotLeft := 0; MotEnd := 0; MotRun := FALSE; Moring := 0; MotRing := 0;
  Mosw0 := 0; MoswAcc := 0; MoswRun := FALSE; MonLap := 0;
  IrW := 1; IrH := 1; Irdown := FALSE; Irmoved := FALSE; Irviewing := FALSE; Irpw := 0; Irph := 0; Irnl := 0; Irscroll := 0; Irname[0] := 0X; Irerr[0] := 0X;
  RbW := 1; RbH := 1; Rbdown := FALSE; Rbmoved := FALSE; Rbscroll := 0; RbFill;
ZnW := 1; ZnH := 1; ZnphDown := FALSE; ZnphMoved := FALSE; ZnphScroll := 0; ZnphN := 0; Znsong[0] := 0X; Znst := 0; Znpos := 0; Zndur := 0;
  ZntPoll := 0; ZntSent := 0; ZnsavedPos := 0; ZnseekTo := 0; ZntSave := 0; ZnbkN := 0;
  ZnpbDown := FALSE; ZnpbMoved := FALSE; Znreading := FALSE; Znwaiting := FALSE; Znshown := FALSE; ZnpbScroll := 0; ZnpbN := 0;
  Znbook[0] := 0X; ZnpbErr[0] := 0X; Znpage := 0; Znpages := 0; Znzoom := 1; ZntAsk := 0
END Zane4.
