MODULE Shell12;  (* SHELL 12 (19 Nov 2026, Cubicum N 17): Shell 11 with Gazda3.
   SHELL 11 (19 Nov 2026, Cubicum N 16): Shell 10 with Gazda2 (the host with 32 x 32 icons).
   SHELL 10 (19 Nov 2026, Cubicum N 14): Shell 9 plus the host: APPS lists the apps of the system under
     Cubicum N, OPEN NAME starts one (Gazda1); Do runs a command for the APPS drawer (a program tapped there).
   SHELL 9 (19 Nov 2026): Z7 Arch inside Cubicum N (Pion: "put Z7 Arch in Cubicum N").
     ARCH packs the files of Cubicum N into .z7c cubes and takes them out again, one or all, searches inside them
     and checks them (module Arch1, the same engine and cubes as the app Z7 Arch 8). ARCH alone tells the commands.
   SHELL 8 (11 Nov 2026): Cubicum FS in 7 dimensions (Fs2) and the new compiler (Ob2: RECORD, CASE, Sound).
     LS shows the 7 digits of every address (1..7: name type day folder size month hour); WHERE explains them;
     CELL x y z (the home cube) or CELL with 7 digits; FOLDER n chooses the folder of the new files; DATE.
     New examples: rec.mod (records and CASE) and catch.mod (a game: catch the falling notes, with sound).
   SHELL 7 (11 Nov 2026): hold the finger on the command line (like on any phone) and a little menu comes:
     PASTE, COPY, CLEAR (Pion: "I am used to copy paste"). The clipboard is the phone's and Cubicum N's own (Clip2).
   SHELL 6 (11 Nov 2026): programs with a screen. When a program shows its first picture (Screen.Show),
     Cubicum N opens its canvas; X on the canvas comes back here, SCREEN goes there again. Frame returns 3 = the canvas.
     New examples: touch.mod (draw with the finger) and bounce.mod (a ball, tap to change its colour).
   SHELL 5 (11 Nov 2026): copy and paste (Pion: "the shell has no copy paste").
     COPY puts all the lines of the shell on the phone's clipboard (to send them on); PASTE puts the clipboard's first line
     in the command line. Touch a line that starts with > and the command comes back to be run again.
     The editor (Edit2) has COPY and PASTE too. Needs the window ecran-gl3-sunet3.dex (module Clip1).
   SHELL 4 (11 Nov 2026): Oberon on Tor7. RUN fib (or fib.mod) compiles the Oberon file with Ob0 and runs it;
     ASM fib.mod writes the Tor7 code the compiler made into fib.asm (CAT fib.asm to read it).
     New examples in Oberon: fib.mod, sieve.mod, towers.mod, walk11.mod, scale.mod (EDIT them, RUN them).
   SHELL 3 (11 Nov 2026): the Tor7 processor (Pion: "we go with Tor7 with the 11th dimension").
     New commands: RUN name (a .z7 program on a free turn), PS, KILL N, ASH, TOR, EXAMPLES.
     The programs' lines (PRINT, PRINTC, ...) come into the shell (Shell3.Pull, every frame, wherever you are).
     The first time, the example programs are written: hello.z7, primes.z7, dim11.z7, song.z7, salamandra.z7.
   SHELL 2 (11 Nov 2026): files. Pion: "yes, and bring Cubicum FS after".
     New commands: LS, CAT name, EDIT name, RM name (twice, to be sure), WHERE name, CELL x y z.
     Every file lives in a cell of the cube (module Fs1, Cubicum FS); EDIT opens the editor (module Edit1).
     The keyboard (Keys1) now has small and capital letters and the signs of Oberon (SYM); the text font is Text1.
       Shell2.Frame returns 0 = stay, -1 = cube, 1 = synth, 2 = player
   SHELL 1 (11 Nov 2026): the command line of Cubicum N (piece 3). Pion: "let's move to the shell,
     but I want everything in English".
     It has its own keyboard on the screen (a hardware keyboard works too). Type HELP for the commands.
       Shell1.Start                       once, after the window exists
       Shell1.Frame(down, x, y)           one frame while the shell has the screen; returns
                                            0 = stay, -1 = back to the cube, 1 = open the synth, 2 = open the player
     Commands: HELP, PROGRAMS, SYNTH, PLAYER, HOME, SLOTS, PLAY N, STOP, LOOP [ON|OFF], ORDER [ON|OFF],
               NOTE X Y Z [MS], FREQ X Y Z, STATUS, TIME, ECHO ..., CLEAR, VER
     Pion & Claude, 11.11.2026 *)

  IMPORT Ecran, Ceas, Grafica, Fisier, Synth9, Text1, Keys1, Fs2, Edit4, Tor11, Sal4, Clip2, Arch1, Gazda3;

  CONST
    RANDURI = 20;                    (* the bottom rows of the screen carry the sound *)
    NL = 120; NC = 44;               (* lines kept, characters per line *)
    LH = 20;                         (* line height *)
    NW = 6; WL = 24;                 (* words in a command, letters in a word *)

  VAR
    W, H, kbTop, inY, outTop, outBot, vis: INTEGER;
    lines: ARRAY NL, NC OF CHAR; lcol: ARRAY NL OF INTEGER; nLines, scroll: INTEGER;
    inp: ARRAY NC OF CHAR; nInp: INTEGER;
    words: ARRAY NW, WL OF CHAR; nWords: INTEGER;
    t: ARRAY 64 OF CHAR; tn: INTEGER;
    down, wasDown, hit: BOOLEAN; mx, my, lastY, dragAcc, keyDown: INTEGER; fname: ARRAY 40 OF CHAR;
    result, t0, eh: INTEGER; started, editing: BOOLEAN; rmName: ARRAY 40 OF CHAR;
    clip: ARRAY 2000 OF CHAR; pasting, moved: BOOLEAN; startY: INTEGER;
    holding, menu: BOOLEAN; holdT, startX: INTEGER;
    bg, panel, gold, white, grey, cyan, green, red, violet, black: INTEGER;

  (* ---------- text ---------- *)

  PROCEDURE Clr; BEGIN tn := 0; t[0] := 0X END Clr;

  PROCEDURE Add(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (tn < 62) DO t[tn] := s[i]; INC(tn); INC(i) END;
    t[tn] := 0X
  END Add;

  PROCEDURE AddN(n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN Add("-"); n := -n END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE (k > 0) & (tn < 62) DO DEC(k); t[tn] := d[k]; INC(tn) END;
    t[tn] := 0X
  END AddN;

  PROCEDURE AddDec(n, unit: INTEGER);   (* n / unit with one decimal *)
  BEGIN AddN(n DIV unit); Add("."); AddN(n MOD unit * 10 DIV unit)
  END AddDec;

  PROCEDURE Put(c: INTEGER);   (* the text gathered in t becomes output line(s) *)
    VAR i, k, j: INTEGER;
  BEGIN
    i := 0;
    REPEAT
      IF nLines = NL THEN   (* drop the oldest line *)
        FOR k := 1 TO NL - 1 DO lines[k - 1] := lines[k]; lcol[k - 1] := lcol[k] END;
        DEC(nLines)
      END;
      j := 0;
      WHILE (i < tn) & (j < NC - 1) DO lines[nLines, j] := t[i]; INC(i); INC(j) END;
      lines[nLines, j] := 0X; lcol[nLines] := c; INC(nLines)
    UNTIL i >= tn;
    scroll := 0
  END Put;

  PROCEDURE Say(s: ARRAY OF CHAR; c: INTEGER);
  BEGIN Clr; Add(s); Put(c)
  END Say;

  (* ---------- words ---------- *)

  PROCEDURE Lower(ch: CHAR): CHAR;
  BEGIN IF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch) + 32) END
    RETURN ch
  END Lower;

  PROCEDURE Split;
    VAR i, j: INTEGER;
  BEGIN
    nWords := 0; i := 0;
    WHILE (i < nInp) & (nWords < NW) DO
      WHILE (i < nInp) & (inp[i] = " ") DO INC(i) END;
      IF i < nInp THEN
        j := 0;
        WHILE (i < nInp) & (inp[i] # " ") DO
          IF j < WL - 1 THEN words[nWords, j] := Lower(inp[i]); INC(j) END;
          INC(i)
        END;
        words[nWords, j] := 0X; INC(nWords)
      END
    END
  END Split;

  PROCEDURE Is(k: INTEGER; s: ARRAY OF CHAR): BOOLEAN;   (* word k is s *)
    VAR i: INTEGER; same: BOOLEAN;
  BEGIN
    same := k < nWords; i := 0;
    WHILE same & (i < LEN(s)) & (s[i] # 0X) DO
      IF words[k, i] # s[i] THEN same := FALSE END; INC(i)
    END
    RETURN same & (words[k, i] = 0X)
  END Is;

  PROCEDURE Num(k: INTEGER; VAR v: INTEGER): BOOLEAN;   (* word k as a whole number *)
    VAR i: INTEGER; neg, ok: BOOLEAN;
  BEGIN
    ok := k < nWords; v := 0; i := 0; neg := FALSE;
    IF ok & (words[k, 0] = "-") THEN neg := TRUE; i := 1 END;
    IF ok & (words[k, i] = 0X) THEN ok := FALSE END;
    WHILE ok & (words[k, i] # 0X) DO
      IF (words[k, i] >= "0") & (words[k, i] <= "9") THEN v := v * 10 + ORD(words[k, i]) - ORD("0")
      ELSE ok := FALSE
      END;
      INC(i)
    END;
    IF neg THEN v := -v END
    RETURN ok
  END Num;

  PROCEDURE OnOff(k: INTEGER; now: BOOLEAN): BOOLEAN;   (* ON, OFF, or nothing = switch *)
  BEGIN
    IF Is(k, "on") THEN now := TRUE ELSIF Is(k, "off") THEN now := FALSE ELSE now := ~now END
    RETURN now
  END OnOff;

  (* ---------- commands ---------- *)

  PROCEDURE Help;
  BEGIN
    Say("PROGRAMS        WHAT YOU CAN OPEN", cyan);
    Say("SYNTH, PLAYER   OPEN A PROGRAM", cyan);
    Say("HOME            BACK TO THE CUBE", cyan);
    Say("SLOTS           THE 7 SAVED SLOTS", cyan);
    Say("PLAY N          PLAY SLOT N (1..7)", cyan);
    Say("STOP            SILENCE", cyan);
    Say("LOOP ON/OFF     REPEAT THE SLOT", cyan);
    Say("ORDER ON/OFF    GO ON TO THE NEXT SLOT", cyan);
    Say("NOTE X Y Z MS   PLAY ONE NODE (0..6)", cyan);
    Say("FREQ X Y Z      FREQUENCY OF A NODE", cyan);
    Say("LS              THE FILES AND THEIR CELLS", cyan);
    Say("CAT NAME        SHOW A FILE", cyan);
    Say("EDIT NAME       EDIT (OR MAKE) A FILE", cyan);
    Say("RM NAME         DELETE A FILE (TWICE)", cyan);
    Say("WHERE NAME      THE CELL OF A FILE", cyan);
    Say("CELL X Y Z      A CELL OF THE HOME CUBE (0..6)", cyan);
    Say("CELL 7 DIGITS   A 7D ADDRESS (DIGITS 1..7)", cyan);
    Say("FOLDER N, DATE  THE FOLDER OF NEW FILES; THE DATE", cyan);
    Say("RUN NAME        RUN A PROGRAM (.MOD OBERON, .Z7)", cyan);
    Say("ASM NAME.MOD    THE TOR7 CODE OF AN OBERON FILE", cyan);
    Say("PS, KILL N      THE 7 TURNS; STOP TURN N", cyan);
    Say("ASH, TOR        THE ASH; THE STATE OF THE TORUS", cyan);
    Say("SCREEN          THE CANVAS OF THE PROGRAMS", cyan);
    Say("EXAMPLES        WRITE THE EXAMPLE PROGRAMS", cyan);
    Say("ARCH            Z7 ARCH CUBES (ARCH: HOW)", cyan);
    Say("APPS, OPEN NAME THE APPS OF THE HOST; START ONE", cyan);
    Say("STATUS, TIME, VER, ECHO, CLEAR", cyan);
    Say("HOLD THE COMMAND LINE: PASTE, COPY, CLEAR.", cyan);
    Say("COPY ABOVE: ALL THE LINES. TOUCH A > LINE:", cyan);
    Say("THE COMMAND COMES BACK.", cyan)
  END Help;

  PROCEDURE Slots;
    VAR n, k: INTEGER;
  BEGIN
    Synth9.Rescan;
    FOR n := 1 TO 7 DO
      Clr; Add("SLOT "); AddN(n); Add("   ");
      k := Synth9.Slot(n);
      IF k < 0 THEN Add("EMPTY"); Put(grey)
      ELSE AddDec(Synth9.SlotMs(n), 1000); Add(" S   "); AddN(k); Add(" NOTES"); Put(white)
      END
    END
  END Slots;

  PROCEDURE Status;
    VAR n: INTEGER;
  BEGIN
    Clr; Add("SOUND RATE "); AddN(Synth9.Rate()); Add(" HZ   LATENCY "); AddN(Synth9.Latency()); Add(" MS"); Put(white);
    Clr; Add("UNDERRUNS "); AddN(Ecran.Citeste(24)); Put(white);
    n := Synth9.Locul();
    Clr;
    IF n > 0 THEN Add("PLAYING SLOT "); AddN(n) ELSIF Synth9.Canta() THEN Add("THE SYNTH IS PLAYING") ELSE Add("QUIET") END;
    Put(green);
    Clr; Add("LOOP ");
    IF Synth9.Looping() THEN Add("ON") ELSE Add("OFF") END;
    Add("   ORDER "); IF Synth9.InOrder() THEN Add("ON") ELSE Add("OFF") END;
    Put(white);
    Clr; Add("SCREEN "); AddN(W); Add(" X "); AddN(H); Put(white)
  END Status;

  PROCEDURE AddAddr(k: INTEGER);   (* the 7 digits of file k, 1..7 *)
    VAR d: INTEGER;
  BEGIN FOR d := 0 TO 6 DO AddN(Fs2.Digit(k, d) + 1) END
  END AddAddr;

  PROCEDURE AddCell(k: INTEGER);   (* (x,y,z) of file k *)
  BEGIN Add("("); AddN(Fs2.X(k)); Add(","); AddN(Fs2.Y(k)); Add(","); AddN(Fs2.Z(k)); Add(")")
  END AddCell;

  PROCEDURE Word1(VAR s: ARRAY OF CHAR): BOOLEAN;   (* the second word as typed (with its capitals): a file name *)
    VAR i, j: INTEGER; ok: BOOLEAN;
  BEGIN
    i := 0; WHILE (i < nInp) & (inp[i] = " ") DO INC(i) END;
    WHILE (i < nInp) & (inp[i] # " ") DO INC(i) END;
    WHILE (i < nInp) & (inp[i] = " ") DO INC(i) END;
    j := 0; ok := TRUE;
    WHILE (i < nInp) & (inp[i] # " ") DO
      IF ~(((inp[i] >= "a") & (inp[i] <= "z")) OR ((inp[i] >= "A") & (inp[i] <= "Z")) OR ((inp[i] >= "0") & (inp[i] <= "9"))
         OR (inp[i] = ".") OR (inp[i] = "-") OR (inp[i] = "_")) THEN ok := FALSE END;
      IF j < LEN(s) - 1 THEN s[j] := inp[i]; INC(j) ELSE ok := FALSE END;
      INC(i)
    END;
    s[j] := 0X
    RETURN ok & (j > 0)
  END Word1;

  PROCEDURE Ls;
    VAR k, sz: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    Fs2.Sync;
    IF Fs2.Count() = 0 THEN Say("NO FILES YET. MAKE ONE: EDIT NOTES.TXT", grey)
    ELSE
      FOR k := 0 TO Fs2.Count() - 1 DO
        Fs2.Name(k, nm); sz := Fs2.SizeOf(nm);
        Clr; AddAddr(k); Add("  "); Add(nm); Add("  "); AddN(sz); Add(" B"); Put(white)
      END;
      Clr; AddN(Fs2.Count()); Add(" FILE(S) . THE 7 DIGITS: NAME TYPE DAY"); Put(grey);
      Say("FOLDER SIZE MONTH HOUR (WHERE NAME TELLS)", grey)
    END
  END Ls;

  PROCEDURE Cat;
    VAR h, b, lines: INTEGER;
  BEGIN
    h := Fisier.Deschide(fname);
    IF h < 0 THEN Clr; Add("NO FILE "); Add(fname); Put(red)
    ELSE
      Clr; lines := 0; b := Fisier.Citeste(h);
      WHILE (b >= 0) & (lines < 100) DO
        IF b = 10 THEN Put(white); Clr; INC(lines)
        ELSIF (b >= 32) & (b < 127) THEN
          IF tn >= NC - 1 THEN Put(white); Clr; INC(lines) END;
          t[tn] := CHR(b); INC(tn); t[tn] := 0X
        END;
        b := Fisier.Citeste(h)
      END;
      IF tn > 0 THEN Put(white) END;
      IF b >= 0 THEN Say("... (ONLY THE FIRST 100 LINES)", grey) END;
      Fisier.Gata(h)
    END
  END Cat;

  PROCEDURE L(s: ARRAY OF CHAR);   (* one line of the example being written (OLL strings are at most 255 letters) *)
    VAR i: INTEGER;
  BEGIN
    IF eh >= 0 THEN
      i := 0;
      WHILE (i < LEN(s)) & (s[i] # 0X) DO   (* ' becomes the double quote (it cannot sit in a string here) *)
        IF s[i] = "'" THEN Fisier.Scrie(eh, 22H) ELSE Fisier.Scrie(eh, ORD(s[i])) END; INC(i)
      END;
      Fisier.Scrie(eh, 10)
    END
  END L;

  PROCEDURE Open(name: ARRAY OF CHAR);
  BEGIN eh := Fisier.Creeaza(name)
  END Open;

  PROCEDURE Close(name: ARRAY OF CHAR);
  BEGIN IF eh >= 0 THEN Fisier.Gata(eh); IF Fs2.Add(name) >= 0 THEN END END
  END Close;

  PROCEDURE Examples;
  BEGIN
    Open("hello.z7");
    L("# HELLO: letters with PRINTC, then 7^7, the cells of the dense torus");
    L("SET R0, 72");
    L("PRINTC R0");
    L("SET R0, 69");
    L("PRINTC R0");
    L("SET R0, 76");
    L("PRINTC R0");
    L("PRINTC R0");
    L("SET R0, 79");
    L("PRINTC R0");
    L("SET R0, 32");
    L("PRINTC R0");
    L("SET R0, 84");
    L("PRINTC R0");
    L("SET R0, 79");
    L("PRINTC R0");
    L("SET R0, 82");
    L("PRINTC R0");
    L("SET R0, 55");
    L("PRINTC R0");
    L("SET R0, 10");
    L("PRINTC R0");
    L("SET R1, 823543");
    L("PRINT R1");
    L("STOP");
    Close("hello.z7");
    Open("primes.z7");
    L("# PRIMES: the prime numbers under 100 (R6 is for the labels)");
    L("        SET R1, 2");
    L("next:   SET R2, 2");
    L("try:    MOV R3, R2");
    L("        MUL R3, R2");
    L("        MOV R4, R1");
    L("        LT R4, R3");
    L("        JNZ R4, prime");
    L("        MOV R5, R1");
    L("        MOD R5, R2");
    L("        JZ R5, skip");
    L("        INC R2");
    L("        JMP try");
    L("prime:  PRINTN R1");
    L("        SET R0, 32");
    L("        PRINTC R0");
    L("skip:   INC R1");
    L("        SET R0, 100");
    L("        MOV R4, R1");
    L("        LT R4, R0");
    L("        JNZ R4, next");
    L("        SET R0, 10");
    L("        PRINTC R0");
    L("        STOP");
    Close("primes.z7");
    Open("dim11.z7");
    L("# DIM11: from its own turn (+50000), one step on each of the 11 dimensions;");
    L("# a digit is written in every cell it reaches (dims 8..11 are sparse pages)");
    L("        BASE R1");
    L("        SET R0, 50000");
    L("        ADD R1, R0");
    L("        SET R2, 0");
    L("loop:   STEP R1, R2");
    L("        ST R2, R1");
    L("        PRINTN R2");
    L("        SET R0, 58");
    L("        PRINTC R0");
    L("        PRINTN R1");
    L("        SET R0, 10");
    L("        PRINTC R0");
    L("        INC R2");
    L("        SET R0, 11");
    L("        MOV R3, R2");
    L("        LT R3, R0");
    L("        JNZ R3, loop");
    L("        SET R2, 10");
    L("        COORD R1, R2");
    L("        PRINT R1");
    L("        STOP");
    Close("dim11.z7");
    Open("song.z7");
    L("# SONG: the 7 notes of Z7 going up, then down");
    L("        SET R0, 0");
    L("        SET R1, 1");
    L("        SET R2, 200");
    L("up:     NOTE R0, R1");
    L("        SLEEP R2");
    L("        INC R0");
    L("        SET R3, 7");
    L("        MOV R4, R0");
    L("        LT R4, R3");
    L("        JNZ R4, up");
    L("down:   DEC R0");
    L("        NOTE R0, R1");
    L("        SLEEP R2");
    L("        JNZ R0, down");
    L("        STOP");
    Close("song.z7");
    Open("salamandra.z7");
    L("# SALAMANDRA: the first time it falls on purpose (DIV by 0).");
    L("# The turn burns, it starts again from the Egg, reads its Ash (ASH) and goes another way.");
    L("        ASH R1");
    L("        JNZ R1, again");
    L("        SET R0, 70");
    L("        PRINTC R0");
    L("        SET R2, 0");
    L("        SET R3, 5");
    L("        DIV R3, R2");
    L("again:  SET R0, 65");
    L("        PRINTC R0");
    L("        SET R0, 83");
    L("        PRINTC R0");
    L("        SET R0, 72");
    L("        PRINTC R0");
    L("        SET R0, 32");
    L("        PRINTC R0");
    L("        PRINTN R1");
    L("        SET R0, 10");
    L("        PRINTC R0");
    L("        STOP");
    Close("salamandra.z7");
    Say("EXAMPLES: HELLO PRIMES DIM11 SONG SALAMANDRA (.Z7)", green)
  END Examples;

  PROCEDURE ExamplesOb;
  BEGIN
    Open("fib.mod");
    L("MODULE Fib;  (* recursion: a function that calls itself *)");
    L("  IMPORT Out;");
    L("  VAR i: INTEGER;");
    L("");
    L("  PROCEDURE F(n: INTEGER): INTEGER;");
    L("    VAR r: INTEGER;");
    L("  BEGIN");
    L("    IF n < 2 THEN r := n ELSE r := F(n - 1) + F(n - 2) END");
    L("    RETURN r");
    L("  END F;");
    L("");
    L("BEGIN");
    L("  FOR i := 0 TO 15 DO Out.Int(F(i), 0); Out.Char(' ') END;");
    L("  Out.Ln");
    L("END Fib.");
    Close("fib.mod");
    Open("sieve.mod");
    L("MODULE Sieve;  (* arrays: the sieve of Eratosthenes *)");
    L("  IMPORT Out;");
    L("  CONST N = 200;");
    L("  VAR p: ARRAY N OF BOOLEAN; i, k, c: INTEGER;");
    L("BEGIN");
    L("  FOR i := 2 TO N - 1 DO p[i] := TRUE END;");
    L("  i := 2;");
    L("  WHILE i * i < N DO");
    L("    IF p[i] THEN k := i * i; WHILE k < N DO p[k] := FALSE; k := k + i END END;");
    L("    INC(i)");
    L("  END;");
    L("  c := 0;");
    L("  FOR i := 2 TO N - 1 DO IF p[i] THEN INC(c) END END;");
    L("  Out.String('PRIMES UNDER 200: '); Out.Int(c, 0); Out.Ln");
    L("END Sieve.");
    Close("sieve.mod");
    Open("towers.mod");
    L("MODULE Towers;  (* VAR parameters: the towers of Hanoi *)");
    L("  IMPORT Out;");
    L("  VAR moves: INTEGER;");
    L("");
    L("  PROCEDURE Move(n, from, to, via: INTEGER; VAR count: INTEGER);");
    L("  BEGIN");
    L("    IF n > 0 THEN");
    L("      Move(n - 1, from, via, to, count);");
    L("      INC(count);");
    L("      Move(n - 1, via, to, from, count)");
    L("    END");
    L("  END Move;");
    L("");
    L("BEGIN");
    L("  moves := 0; Move(10, 1, 3, 2, moves);");
    L("  Out.String('HANOI 10: '); Out.Int(moves, 0); Out.String(' MOVES'); Out.Ln");
    L("END Towers.");
    Close("towers.mod");
    Open("walk11.mod");
    L("MODULE Walk11;  (* the torus: one step on each of the 11 dimensions *)");
    L("  IMPORT Out, Tor;");
    L("  VAR a, d: INTEGER;");
    L("BEGIN");
    L("  a := Tor.Base() + 60000;");
    L("  FOR d := 0 TO 10 DO");
    L("    a := Tor.Step(a, d); Tor.Write(a, d + 1);");
    L("    Out.Int(d + 1, 0); Out.Char(':'); Out.Int(Tor.Coord(a, d), 0); Out.Char(' ')");
    L("  END;");
    L("  Out.Ln; Out.String('FIELD '); Out.Int(Tor.Field(), 0); Out.Ln");
    L("END Walk11.");
    Close("walk11.mod");
    Open("scale.mod");
    L("MODULE Scale;  (* sound: the 7 notes of Z7 up, then down an octave higher *)");
    L("  IMPORT Tor;");
    L("  VAR n: INTEGER;");
    L("BEGIN");
    L("  FOR n := 0 TO 6 DO Tor.Note(n, 1); Tor.Sleep(180) END;");
    L("  FOR n := 6 TO 0 BY -1 DO Tor.Note(n, 2); Tor.Sleep(180) END");
    L("END Scale.");
    Close("scale.mod");
    Say("OBERON EXAMPLES: FIB SIEVE TOWERS WALK11 SCALE (.MOD)", green)
  END ExamplesOb;

  PROCEDURE ExamplesScreen;
  BEGIN
    Open("touch.mod");
    L("MODULE Touch1;  (* draw with the finger; the colour follows the height *)");
    L("  IMPORT Screen, Touch;");
    L("  VAR x, y, n: INTEGER;");
    L("BEGIN");
    L("  Screen.Clear(Screen.RGB(14, 4, 28));");
    L("  Screen.String(20, 30, 'DRAW WITH YOUR FINGER', 3, Screen.RGB(212, 160, 23));");
    L("  Screen.Show;");
    L("  n := 0;");
    L("  WHILE n < 100000 DO");
    L("    IF Touch.Down() THEN");
    L("      x := Touch.X(); y := Touch.Y();");
    L("      Screen.Circle(x, y, 12, Screen.RGB(255 - y DIV 4, 120, y DIV 4))");
    L("    END;");
    L("    Screen.Show; INC(n)");
    L("  END");
    L("END Touch1.");
    Close("touch.mod");
    Open("bounce.mod");
    L("MODULE Bounce;  (* a ball; tap the screen and it changes colour *)");
    L("  IMPORT Screen, Touch;");
    L("  VAR x, y, dx, dy, w, h, c, k: INTEGER;");
    L("BEGIN");
    L("  w := Screen.Width(); h := Screen.Height();");
    L("  x := w DIV 2; y := h DIV 3; dx := 7; dy := 5; c := Screen.RGB(74, 222, 128); k := 0;");
    L("  REPEAT");
    L("    x := x + dx; y := y + dy;");
    L("    IF (x < 30) OR (x > w - 30) THEN dx := -dx END;");
    L("    IF (y < 30) OR (y > h - 30) THEN dy := -dy END;");
    L("    IF Touch.Tap() THEN c := Screen.RGB(Touch.X() MOD 256, 160, Touch.Y() MOD 256); INC(k) END;");
    L("    Screen.Clear(Screen.RGB(14, 4, 28));");
    L("    Screen.Circle(x, y, 28, c);");
    L("    Screen.String(20, 30, 'TAPS ', 3, Screen.RGB(212, 160, 23)); Screen.Int(110, 30, k, 3, Screen.RGB(212, 160, 23));");
    L("    Screen.Show");
    L("  UNTIL k = 20");
    L("END Bounce.");
    Close("bounce.mod");
    Say("SCREEN EXAMPLES: TOUCH, BOUNCE (.MOD)", green)
  END ExamplesScreen;

  PROCEDURE ExamplesGame;
  BEGIN
    Open("rec.mod");
    L("MODULE Rec;  (* records, a whole record copied, CASE *)");
    L("  IMPORT Out;");
    L("  TYPE P = RECORD x, y: INTEGER; c: CHAR END;");
    L("  VAR a, b: P; i: INTEGER;");
    L("");
    L("  PROCEDURE Move(VAR p: P; dx: INTEGER);");
    L("  BEGIN p.x := p.x + dx; p.y := p.y * 2");
    L("  END Move;");
    L("");
    L("  PROCEDURE Name(k: INTEGER);");
    L("  BEGIN");
    L("    CASE k OF");
    L("      0: Out.String('ZERO')");
    L("    | 1, 2: Out.String('SMALL')");
    L("    | 3..9: Out.String('DIGIT')");
    L("    | 65: Out.String('LETTER A')");
    L("    ELSE Out.String('BIG')");
    L("    END;");
    L("    Out.Char(' ')");
    L("  END Name;");
    L("");
    L("BEGIN");
    L("  a.x := 3; a.y := 4; a.c := 'Q';");
    L("  b := a; Move(b, 10);");
    L("  Out.Int(a.x, 0); Out.Char(' '); Out.Int(b.x, 0); Out.Char(' '); Out.Int(b.y, 0); Out.Char(' '); Out.Char(b.c); Out.Ln;");
    L("  FOR i := 0 TO 5 DO Name(i * 3) END; Name(ORD('A')); Out.Ln");
    L("END Rec.");
    Close("rec.mod");
    Open("catch.mod");
    L("MODULE Catch;  (* catch the falling notes: touch them before they reach the floor *)");
    L("  IMPORT Screen, Touch, Sound;");
    L("  CONST N = 5;");
    L("  TYPE Note = RECORD x, y, v, z: INTEGER END;");
    L("  VAR n: ARRAY N OF Note; i, w, h, score, miss, seed, tx, ty: INTEGER;");
    L("");
    L("  PROCEDURE Rand(m: INTEGER): INTEGER;");
    L("  BEGIN seed := (seed * 1103 + 12345) MOD 65536");
    L("    RETURN seed MOD m");
    L("  END Rand;");
    L("");
    L("  PROCEDURE Start(VAR a: Note);");
    L("  BEGIN a.x := 40 + Rand(w - 80); a.y := -Rand(400); a.v := 3 + Rand(4); a.z := Rand(7)");
    L("  END Start;");
    L("");
    L("  PROCEDURE Colour(z: INTEGER): INTEGER;");
    L("    VAR c: INTEGER;");
    L("  BEGIN");
    L("    CASE z OF");
    L("      0: c := Screen.RGB(239, 68, 68)");
    L("    | 1: c := Screen.RGB(251, 146, 60)");
    L("    | 2: c := Screen.RGB(250, 204, 21)");
    L("    | 3: c := Screen.RGB(74, 222, 128)");
    L("    | 4: c := Screen.RGB(56, 189, 248)");
    L("    | 5: c := Screen.RGB(129, 140, 248)");
    L("    ELSE c := Screen.RGB(232, 121, 249)");
    L("    END");
    L("    RETURN c");
    L("  END Colour;");
    L("");
    L("BEGIN");
    L("  w := Screen.Width(); h := Screen.Height(); seed := 7; score := 0; miss := 0;");
    L("  FOR i := 0 TO N - 1 DO Start(n[i]) END;");
    L("  WHILE miss < 10 DO");
    L("    Screen.Clear(Screen.RGB(14, 4, 28));");
    L("    IF Touch.Tap() THEN");
    L("      tx := Touch.X(); ty := Touch.Y();");
    L("      FOR i := 0 TO N - 1 DO");
    L("        IF (ABS(tx - n[i].x) < 50) & (ABS(ty - n[i].y) < 50) THEN");
    L("          Sound.Note(n[i].z, 1, 2, 300); INC(score); Start(n[i])");
    L("        END");
    L("      END");
    L("    END;");
    L("    FOR i := 0 TO N - 1 DO");
    L("      n[i].y := n[i].y + n[i].v;");
    L("      IF n[i].y > h THEN INC(miss); Start(n[i]) END;");
    L("      Screen.Circle(n[i].x, n[i].y, 30, Colour(n[i].z))");
    L("    END;");
    L("    Screen.String(20, 30, 'SCORE', 3, Screen.RGB(212, 160, 23)); Screen.Int(140, 30, score, 3, Screen.RGB(212, 160, 23));");
    L("    Screen.String(300, 30, 'MISS', 3, Screen.RGB(239, 68, 68)); Screen.Int(400, 30, miss, 3, Screen.RGB(239, 68, 68));");
    L("    Screen.Show");
    L("  END;");
    L("  Screen.String(120, h DIV 2, 'GAME OVER', 5, Screen.RGB(212, 160, 23)); Screen.Show");
    L("END Catch.");
    Close("catch.mod");
    Say("NEW EXAMPLES: REC (RECORDS, CASE), CATCH (A GAME)", green)
  END ExamplesGame;

  PROCEDURE Ps;
    VAR s, st: INTEGER; nm: ARRAY 32 OF CHAR;
  BEGIN
    FOR s := 0 TO Sal4.NP - 1 DO
      st := Sal4.StateOf(s); Clr; Add("TURN "); AddN(s + 1); Add("  ");
      IF st = Sal4.Free THEN Add("FREE"); Put(grey)
      ELSE
        Sal4.NameOf(s, nm); Add(nm); Add("  ");
        IF st = Sal4.Active THEN Add("RUNS") ELSIF st = Sal4.Sleeps THEN Add("SLEEPS") ELSIF st = Sal4.Senses THEN Add("WAITS")
        ELSE Add("RECEIVES") END;
        Add("  "); AddN(Sal4.StepsOf(s)); Add(" STEPS"); Put(white)
      END
    END
  END Ps;

  PROCEDURE TorState;
  BEGIN
    Clr; Add("FIELD "); AddN(Tor11.Field()); Add("   WRITES "); AddN(Tor11.Writes()); Put(white);
    Clr; Add("OPAL: CYCLE "); AddN(Tor11.Cycle()); Add("   BEAT "); AddN(Tor11.BeatInHour()); Add(" / 1155"); Put(white);
    Clr; Add("BURNS "); AddN(Tor11.Burns()); Add("   ASH "); AddN(Sal4.AshLines()); Add(" LINES"); Put(white);
    Clr; Add("DIMENSIONS 8..11: "); AddN(Tor11.Pages()); Add(" OF 4096 PAGES"); Put(white);
    Say("11 DIMENSIONS: 7^11 = 1977326743 CELLS", grey)
  END TorState;

  PROCEDURE Pull*;   (* the lines of the programs come into the shell *)
    VAR k, c: INTEGER; ln: ARRAY 64 OF CHAR;
  BEGIN
    IF Sal4.Lines() > 0 THEN
      FOR k := 0 TO Sal4.Lines() - 1 DO
        Sal4.Line(k, ln, c); Clr; Add(ln);
        IF c = 1 THEN Put(green) ELSIF c = 2 THEN Put(red) ELSE Put(white) END
      END;
      Sal4.Taken
    END
  END Pull;

  PROCEDURE HostApps;   (* the apps of the system under Cubicum N *)
    VAR i: INTEGER; nm: ARRAY 44 OF CHAR;
  BEGIN
    IF ~Gazda3.Hosted() THEN Say("NO HOST UNDER CUBICUM N: BARE METAL", grey)
    ELSIF ~Gazda3.Loaded() THEN Gazda3.Ask; Say("ASKING THE HOST. TYPE APPS AGAIN IN A MOMENT", grey)
    ELSE
      Gazda3.System(nm); Clr; Add(nm); Add(": "); AddN(Gazda3.Count()); Add(" APPS"); Put(gold);
      FOR i := 0 TO Gazda3.Count() - 1 DO
        Gazda3.Label(i, nm); Clr; Add("  "); Add(nm); IF Gazda3.Mine(i) THEN Put(violet) ELSE Put(white) END
      END;
      Say("OPEN NAME STARTS ONE (THE FIRST LETTERS ARE ENOUGH)", grey)
    END
  END HostApps;

  PROCEDURE HostOpen;   (* OPEN NAME: the first app whose name starts with NAME *)
    VAR i, j, r: INTEGER; nm: ARRAY 44 OF CHAR; ok: BOOLEAN;
  BEGIN
    IF nWords < 2 THEN Say("OPEN WHICH APP? LIKE: OPEN CRISALIDA (APPS LISTS THEM)", red)
    ELSIF ~Gazda3.Hosted() THEN Say("NO HOST UNDER CUBICUM N: BARE METAL", red)
    ELSIF ~Gazda3.Loaded() THEN Gazda3.Ask; Say("ASKING THE HOST. TRY AGAIN IN A MOMENT", grey)
    ELSE
      r := -1; i := 0;
      WHILE (r < 0) & (i < Gazda3.Count()) DO
        Gazda3.Label(i, nm); ok := TRUE; j := 0;
        WHILE ok & (words[1, j] # 0X) DO IF Lower(nm[j]) # words[1, j] THEN ok := FALSE END; INC(j) END;
        IF ok THEN r := i END; INC(i)
      END;
      IF r < 0 THEN Say("NO SUCH APP ON THE HOST (APPS LISTS THEM)", red)
      ELSIF Gazda3.Launch(r) THEN Gazda3.Label(r, nm); Clr; Add("OPENING "); Add(nm); Put(green)
      ELSE Say("THE HOST DID NOT TAKE IT", red)
      END
    END
  END HostOpen;

  PROCEDURE Run;   (* the line in inp *)
    VAR x, y, z, ms, n: INTEGER; f: REAL; s: ARRAY 8 OF CHAR; nm: ARRAY 40 OF CHAR;
  BEGIN
    Clr; Add("> "); Add(inp); Put(gold);
    Split;
    IF ~Is(0, "rm") THEN rmName[0] := 0X END;
    IF nWords = 0 THEN
    ELSIF Is(0, "help") OR Is(0, "?") THEN Help
    ELSIF Is(0, "programs") THEN
      Say("SYNTH    SYNTH Z7: KEYS, SOUND, SEQ, REC", white);
      Say("PLAYER   PLAYS THE SAVED SLOTS", white);
      Say("SHELL    THIS COMMAND LINE", white)
    ELSIF Is(0, "synth") OR (Is(0, "run") & Is(1, "synth")) THEN result := 1
    ELSIF Is(0, "player") OR (Is(0, "run") & Is(1, "player")) THEN result := 2
    ELSIF Is(0, "home") OR Is(0, "exit") OR Is(0, "cube") THEN result := -1
    ELSIF Is(0, "slots") THEN Slots
    ELSIF Is(0, "play") THEN
      IF ~Num(1, n) OR (n < 1) OR (n > 7) THEN Say("PLAY WHICH SLOT? PLAY 1 .. PLAY 7", red)
      ELSIF Synth9.PlaySlot(n) THEN Clr; Add("PLAYING SLOT "); AddN(n); Put(green)
      ELSE Clr; Add("SLOT "); AddN(n); Add(" IS EMPTY"); Put(red)
      END
    ELSIF Is(0, "stop") THEN Synth9.Stop; Say("STOPPED", green)
    ELSIF Is(0, "loop") THEN
      Synth9.SetLoop(OnOff(1, Synth9.Looping()));
      IF Synth9.Looping() THEN Say("LOOP ON", green) ELSE Say("LOOP OFF", green) END
    ELSIF Is(0, "order") THEN
      Synth9.SetInOrder(OnOff(1, Synth9.InOrder()));
      IF Synth9.InOrder() THEN Say("ORDER ON", green) ELSE Say("ORDER OFF", green) END
    ELSIF Is(0, "note") OR Is(0, "freq") THEN
      IF Num(1, x) & Num(2, y) & Num(3, z) & (x >= 0) & (x <= 6) & (y >= 0) & (y <= 6) & (z >= 0) & (z <= 6) THEN
        f := Synth9.Freq(x, y, z); Synth9.NoteName(f, s);
        Clr; Add("("); AddN(x); Add(","); AddN(y); Add(","); AddN(z); Add(")  ");
        n := FLOOR(f * 10.0 + 0.5); AddDec(n, 10); Add(" HZ  "); Add(s);
        IF Is(0, "note") THEN
          IF ~Num(4, ms) THEN ms := 600 END;
          Synth9.Note(x, y, z, ms); Add("  "); AddN(ms); Add(" MS")
        END;
        Put(green)
      ELSE Say("THREE NUMBERS 0..6, LIKE: NOTE 3 0 2", red)
      END
    ELSIF Is(0, "ls") OR Is(0, "dir") OR Is(0, "files") THEN Ls
    ELSIF Is(0, "cat") OR Is(0, "edit") OR Is(0, "rm") OR Is(0, "where") THEN
      IF ~Word1(fname) THEN Say("A FILE NAME: LETTERS, DIGITS, . - _", red)
      ELSIF Is(0, "cat") THEN Cat
      ELSIF Is(0, "edit") THEN Edit4.Open(fname); editing := TRUE
      ELSIF Is(0, "where") THEN
        n := Fs2.Find(fname);
        IF n < 0 THEN Clr; Add(fname); Add(" IS NOT IN THE CUBE"); Put(red)
        ELSE
          Clr; Fs2.Name(n, nm); Add(nm); Add("  LIVES AT "); AddAddr(n); Put(green);
          Clr; Add("NAME "); AddN(Fs2.Digit(n, 0) + 1); Add(" TYPE "); AddN(Fs2.Digit(n, 1) + 1);
          Add(" DAY "); AddN(Fs2.Digit(n, 2) + 1); Add(" FOLDER "); AddN(Fs2.Digit(n, 3) + 1); Put(white);
          Clr; Add("SIZE "); AddN(Fs2.Digit(n, 4) + 1); Add(" MONTH "); AddN(Fs2.Digit(n, 5) + 1);
          Add(" HOUR "); AddN(Fs2.Digit(n, 6) + 1); Add("   CUBE "); AddCell(n); Put(white)
        END
      ELSE   (* rm *)
        n := Fs2.Find(fname);
        IF (n < 0) & Fs2.Exists(fname) THEN n := Fs2.Add(fname) END;
        IF n < 0 THEN Clr; Add("NO FILE "); Add(fname); Put(red); rmName[0] := 0X
        ELSIF ~Fs2.Same(rmName, fname) THEN
          Clr; Add("DELETE "); Add(fname); Add("? TYPE THE SAME RM AGAIN"); Put(gold);
          x := 0; WHILE fname[x] # 0X DO rmName[x] := fname[x]; INC(x) END; rmName[x] := 0X
        ELSE Fs2.Remove(n); Clr; Add("DELETED "); Add(fname); Put(green); rmName[0] := 0X
        END
      END
    ELSIF Is(0, "cell") & (nWords = 8) THEN   (* 7 digits 1..7 *)
      ms := 0; x := 7;
      WHILE x >= 1 DO
        IF Num(x, y) & (y >= 1) & (y <= 7) THEN ms := ms * 7 + y - 1 ELSE ms := -1; x := 0 END;
        DEC(x)
      END;
      IF ms < 0 THEN Say("7 DIGITS 1..7, LIKE: CELL 3 2 5 1 4 6 2", red)
      ELSE
        n := Fs2.AtAddress(ms); Clr; Add("CELL ");
        FOR x := 1 TO 7 DO IF Num(x, y) THEN AddN(y) END END;
        Add("  ");
        IF n < 0 THEN Add("EMPTY"); Put(grey) ELSE Fs2.Name(n, nm); Add(nm); Put(green) END
      END
    ELSIF Is(0, "folder") THEN
      IF Num(1, x) & (x >= 1) & (x <= 7) THEN Fs2.SetFolder(x - 1) END;
      Clr; Add("NEW FILES GO INTO FOLDER "); AddN(Fs2.Folder() + 1); Add(" (FOLDER 1..7)"); Put(green)
    ELSIF Is(0, "date") THEN
      IF Fs2.ReadClock() THEN
        Clr; AddN(Fs2.Now(2)); Add("."); AddN(Fs2.Now(1)); Add("."); AddN(Fs2.Now(0)); Add("  ");
        AddN(Fs2.Now(3)); Add(":"); IF Fs2.Now(4) < 10 THEN Add("0") END; AddN(Fs2.Now(4));
        Add("  DAY "); AddN(Fs2.Now(6) + 1); Add(" OF THE WEEK"); Put(green)
      ELSE Say("NO CLOCK: NEEDS THE WINDOW ECRAN-GL3-SUNET4.DEX", red)
      END
    ELSIF Is(0, "cell") THEN
      IF Num(1, x) & Num(2, y) & Num(3, z) & (x >= 0) & (x <= 6) & (y >= 0) & (y <= 6) & (z >= 0) & (z <= 6) THEN
        n := Fs2.At(x, y, z);
        Clr; Add("("); AddN(x); Add(","); AddN(y); Add(","); AddN(z); Add(")  ");
        IF n < 0 THEN Add("EMPTY"); Put(grey) ELSE Fs2.Name(n, nm); Add(nm); Put(green) END
      ELSE Say("THREE NUMBERS 0..6, LIKE: CELL 0 3 2", red)
      END
    ELSIF Is(0, "run") & ~Is(1, "synth") & ~Is(1, "player") THEN
      IF ~Word1(fname) THEN Say("RUN WHICH PROGRAM? LIKE: RUN PRIMES", red)
      ELSIF Sal4.Start(fname) >= 0 THEN
      END
    ELSIF Is(0, "ps") THEN Ps
    ELSIF Is(0, "kill") THEN
      IF Num(1, n) & (n >= 1) & (n <= 7) THEN
        IF Sal4.StateOf(n - 1) = Sal4.Free THEN Say("THAT TURN IS FREE", grey) ELSE Sal4.Kill(n - 1) END
      ELSE Say("KILL WHICH TURN? 1..7 (SEE PS)", red)
      END
    ELSIF Is(0, "ash") THEN
      IF Sal4.AshLines() = 0 THEN Say("THE ASH IS EMPTY: NO ERRORS YET", grey)
      ELSE FOR n := 0 TO Sal4.AshLines() - 1 DO Clr; Sal4.AshLine(n, nm); Add(nm); Put(gold) END
      END
    ELSIF Is(0, "tor") THEN TorState
    ELSIF Is(0, "screen") THEN result := 3
    ELSIF Is(0, "examples") THEN Examples; ExamplesOb; ExamplesScreen; ExamplesGame
    ELSIF Is(0, "asm") THEN
      IF ~Word1(fname) THEN Say("ASM WHICH FILE? LIKE: ASM FIB.MOD", red)
      ELSE
        x := 0; WHILE (fname[x] # 0X) & (fname[x] # ".") DO nm[x] := fname[x]; INC(x) END;
        nm[x] := "."; nm[x + 1] := "a"; nm[x + 2] := "s"; nm[x + 3] := "m"; nm[x + 4] := 0X;
        IF Sal4.Translate(fname, nm) THEN Clr; Add("THE TOR7 CODE IS IN "); Add(nm); Add(" (CAT IT)"); Put(green) END
      END
    ELSIF Is(0, "arch") THEN   (* Z7 Arch: cubes of files (Arch1); it gets the list of the files first *)
      Fs2.Sync;
      FOR n := 0 TO Fs2.Count() - 1 DO Fs2.Name(n, nm); Arch1.Known(nm) END;
      Arch1.Command(inp);
      FOR n := 0 TO Arch1.Lines() - 1 DO
        x := Arch1.Line(n, t); tn := 0; WHILE t[tn] # 0X DO INC(tn) END;
        IF x = 1 THEN Put(green) ELSIF x = 2 THEN Put(red) ELSIF x = 3 THEN Put(gold) ELSE Put(white) END
      END;
      Fs2.Sync
    ELSIF Is(0, "apps") THEN HostApps
    ELSIF Is(0, "open") THEN HostOpen
    ELSIF Is(0, "status") THEN Status
    ELSIF Is(0, "time") THEN Clr; Add("UP "); AddN((Ceas.Ms() - t0) DIV 1000); Add(" S"); Put(white)
    ELSIF Is(0, "echo") THEN
      Clr; n := 0;
      WHILE (n < nInp) & (inp[n] = " ") DO INC(n) END;
      WHILE (n < nInp) & (inp[n] # " ") DO INC(n) END;
      WHILE (n < nInp) & (inp[n] = " ") DO INC(n) END;
      WHILE n < nInp DO t[tn] := inp[n]; INC(tn); INC(n) END; t[tn] := 0X;
      Put(white)
    ELSIF Is(0, "clear") OR Is(0, "cls") THEN nLines := 0; scroll := 0
    ELSIF Is(0, "ver") OR Is(0, "version") THEN Say("CUBICUM N 17 . SHELL 12 . DESK 4 . GAZDA 3 . ARCH 1", gold)
    ELSE Clr; Add("UNKNOWN: "); Add(words[0]); Add(". TRY HELP"); Put(red)
    END;
    nInp := 0; inp[0] := 0X
  END Run;

  (* ---------- keys ---------- *)

  PROCEDURE Type(ch: CHAR);
  BEGIN
    IF nInp < NC - 3 THEN inp[nInp] := ch; INC(nInp); inp[nInp] := 0X END
  END Type;

  PROCEDURE Back;
  BEGIN IF nInp > 0 THEN DEC(nInp); inp[nInp] := 0X END
  END Back;

  PROCEDURE In(x, y, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (mx >= x) & (mx < x + w) & (my >= y) & (my < y + h)
  END In;

  (* ---------- frame ---------- *)

  PROCEDURE Start*;
  BEGIN
    W := Ecran.Latime(); H := Ecran.Inaltime() - RANDURI;
    kbTop := H - Keys1.Height; inY := kbTop - 50; outTop := 62; outBot := inY - 6;
    vis := (outBot - outTop) DIV LH;
    bg := Grafica.RGB(14, 4, 28); panel := Grafica.RGB(52, 22, 86); gold := Grafica.RGB(212, 160, 23);
    white := Grafica.RGB(240, 235, 250); grey := Grafica.RGB(140, 130, 160); cyan := Grafica.RGB(125, 211, 252);
    green := Grafica.RGB(74, 222, 128); red := Grafica.RGB(239, 68, 68); violet := Grafica.RGB(191, 128, 255);
    black := Grafica.RGB(10, 4, 20);
    t0 := Ceas.Ms(); Fs2.Load; Sal4.Init;
    IF ~Fs2.Exists("hello.z7") THEN Examples END;
    IF ~Fs2.Exists("fib.mod") THEN ExamplesOb END;
    IF ~Fs2.Exists("bounce.mod") THEN ExamplesScreen END;
    IF ~Fs2.Exists("catch.mod") THEN ExamplesGame END;
    IF ~started THEN
      started := TRUE;
      Say("CUBICUM N SHELL 12 . OBERON ON TOR7", gold);
      Say("HOLD THE COMMAND LINE TO PASTE", grey);
      Say("TYPE HELP AND PRESS ENTER. TRY: RUN CATCH", grey)
    END
  END Start;

  PROCEDURE Enter*;   (* when the shell gets the screen: the finger that opened it does not press a key *)
  BEGIN down := TRUE; wasDown := TRUE; hit := FALSE; Keys1.Reset
  END Enter;

  PROCEDURE CopyAll;   (* every line of the shell, onto the phone's clipboard *)
    VAR i: INTEGER;
  BEGIN
    Clip2.Begin;
    FOR i := 0 TO nLines - 1 DO Clip2.Str(lines[i]); Clip2.Put(10) END;
    Clip2.End; Clr; Add("COPIED "); AddN(nLines); Add(" LINES"); Put(green)
  END CopyAll;

  PROCEDURE PasteIn;   (* the first line of the clipboard into the command line *)
    VAR n, i: INTEGER;
  BEGIN
    n := Clip2.Take(clip); i := 0;
    WHILE (i < n) & (clip[i] # 0AX) DO IF clip[i] >= " " THEN Type(clip[i]) END; INC(i) END;
    IF i < n - 1 THEN Say("PASTED ONLY THE FIRST LINE (EDIT TAKES ALL)", grey) END;
    pasting := FALSE
  END PasteIn;

  PROCEDURE Again(k: INTEGER);   (* a line "> command" touched: the command comes back *)
    VAR i: INTEGER;
  BEGIN
    IF (k >= 0) & (k < nLines) & (lines[k, 0] = ">") & (lines[k, 1] = " ") THEN
      nInp := 0; i := 2;
      WHILE (lines[k, i] # 0X) & (nInp < NC - 3) DO inp[nInp] := lines[k, i]; INC(nInp); INC(i) END;
      inp[nInp] := 0X
    END
  END Again;

  PROCEDURE Button(x, w: INTEGER; s: ARRAY OF CHAR; c: INTEGER): BOOLEAN;
  BEGIN
    Grafica.Dreptunghi(x, 8, w, 42, panel); Text1.Centre(x + w DIV 2, 22, s, 2, c)
    RETURN hit & In(x, 6, w, 46)
  END Button;

  PROCEDURE Normal(isDown: BOOLEAN; x, y: INTEGER);
    VAR i, k, first, yy: INTEGER;
  BEGIN
    wasDown := down; down := isDown; mx := x; my := y; hit := down & ~wasDown;
    keyDown := 0;
    first := nLines - vis - scroll; IF first < 0 THEN first := 0 END;
    (* the little menu of the command line: a touch on it, or anywhere else closes it *)
    IF menu & hit THEN
      menu := FALSE; k := inY - 58;
      IF In(4, k, 170, 52) THEN Clip2.Ask; pasting := TRUE
      ELSIF In(184, k, 170, 52) THEN Clip2.Begin; Clip2.Str(inp); Clip2.End; Say("COPIED THE COMMAND LINE", green)
      ELSIF In(364, k, 170, 52) THEN nInp := 0; inp[0] := 0X
      END;
      hit := FALSE; moved := TRUE   (* this touch does nothing else *)
    END;
    (* holding the finger on the command line opens the menu *)
    IF hit & In(4, inY, W - 8, 44) THEN holding := TRUE; holdT := Ceas.Ms(); startX := x
    ELSIF ~down OR (ABS(x - startX) > 14) OR (ABS(y - startY) > 14) THEN holding := FALSE
    ELSIF holding & (Ceas.Ms() - holdT > 450) THEN holding := FALSE; menu := TRUE
    END;
    (* a touch on a line (without dragging) *)
    IF hit THEN startY := y; moved := FALSE
    ELSIF down & (ABS(y - startY) > 14) THEN moved := TRUE
    ELSIF ~down & wasDown & ~moved & (my >= outTop) & (my < outBot) THEN Again(first + (my - outTop) DIV LH)
    END;
    (* scrolling: drag in the output *)
    IF hit THEN lastY := y; dragAcc := 0
    ELSIF down & (lastY >= outTop) & (lastY < outBot) & (y < kbTop) THEN
      dragAcc := dragAcc + y - lastY; lastY := y;
      WHILE dragAcc >= LH DO dragAcc := dragAcc - LH; INC(scroll) END;
      WHILE dragAcc <= -LH DO dragAcc := dragAcc + LH; DEC(scroll) END;
      k := nLines - vis; IF k < 0 THEN k := 0 END;
      IF scroll > k THEN scroll := k ELSIF scroll < 0 THEN scroll := 0 END
    END;
    Grafica.Dreptunghi(0, 0, W, kbTop, bg);
    Text1.Draw(12, 14, "SHELL", 4, gold);
    IF Button(W - 300, 104, "COPY", violet) THEN CopyAll END;
    IF Button(W - 190, 112, "PASTE", violet) THEN
      Clip2.Ask; pasting := TRUE
    END;
    IF pasting THEN
      IF Clip2.Ready() THEN PasteIn
      ELSIF Clip2.Late() THEN pasting := FALSE; Say("THE CLIPBOARD DID NOT ANSWER", red)
      END
    END;
    IF Button(W - 70, 64, "X", red) THEN result := -1 END;
    (* output *)
    first := nLines - vis - scroll; IF first < 0 THEN first := 0 END;
    yy := outTop;
    FOR i := first TO nLines - 1 - scroll DO
      Text1.Draw(8, yy, lines[i], 2, lcol[i]); yy := yy + LH
    END;
    IF scroll > 0 THEN Clr; Add("UP "); AddN(scroll); Text1.Draw(W - 96, outBot - 18, t, 2, violet) END;
    (* input line *)
    Grafica.Dreptunghi(4, inY, W - 8, 44, panel);
    Clr; Add("> "); Add(inp);
    IF Ceas.Ms() DIV 500 MOD 2 = 0 THEN Add("_") END;
    Text1.Draw(12, inY + 14, t, 2, white);
    IF holding & (Ceas.Ms() - holdT > 150) THEN Grafica.Dreptunghi(4, inY + 40, (Ceas.Ms() - holdT) * (W - 8) DIV 450, 4, gold) END;
    IF menu THEN
      k := inY - 58; Grafica.Dreptunghi(0, k - 4, W, 60, black);
      Grafica.Dreptunghi(4, k, 170, 52, gold); Text1.Centre(89, k + 18, "PASTE", 2, black);
      Grafica.Dreptunghi(184, k, 170, 52, panel); Text1.Centre(269, k + 18, "COPY", 2, white);
      Grafica.Dreptunghi(364, k, 170, 52, panel); Text1.Centre(449, k + 18, "CLEAR", 2, white)
    END;
    keyDown := Keys1.Draw(kbTop, down, hit, x, y);
    IF keyDown = 13 THEN Run
    ELSIF keyDown = 8 THEN Back
    ELSIF keyDown >= 32 THEN Type(CHR(keyDown))
    END
  END Normal;

  PROCEDURE Do*(s: ARRAY OF CHAR): INTEGER;   (* runs a command as if typed: 1 SYNTH, 2 PLAYER, 3 CANVAS, -1 HOME *)
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) & (i < NC - 1) DO inp[i] := s[i]; INC(i) END;
    inp[i] := 0X; nInp := i; result := 0; Run; nInp := 0; inp[0] := 0X
    RETURN result
  END Do;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;
  BEGIN
    result := 0;
    IF editing THEN
      IF Edit4.Frame(isDown, x, y) THEN
        editing := FALSE; down := TRUE; Keys1.Reset; Clr; Add("CLOSED "); Add(fname); Put(grey)
      END
    ELSE Normal(isDown, x, y)
    END
    RETURN result
  END Frame;

BEGIN
  started := FALSE; editing := FALSE; holding := FALSE; menu := FALSE; pasting := FALSE; moved := FALSE; startY := 0; rmName[0] := 0X; fname[0] := 0X; nLines := 0; scroll := 0; nInp := 0; inp[0] := 0X; down := FALSE; wasDown := FALSE;
  W := 1; H := 1; kbTop := 1; inY := 1; outTop := 1; outBot := 1; vis := 1; result := 0
END Shell12.
