MODULE Ob2;  (* OBERON-0 FOR TOR7, 3 (25 Nov 2026, Pixipogo 51, file Ob2b.Mod): ROOM FOR BIG GAMES.
       Pion: "make it go further, push it to the maximum". Until now the globals sat at BASE + 32000, so the code had room
       for only 8000 instructions and a longer program wrote its variables over its own code (AN EMPTY CELL...).
       Now every global is reached from GLOB, a place the kernel chooses when it loads the program: right after the
       code. So the code can grow until code + globals + a little stack fill the turn (about 27000 instructions for a
       game with few globals), and the stack gets all the rest (recursion 49 deep as before). The compiler only says
       how many words the globals take (gWords); Sal4 (Sal4b) checks that it all fits and says the room.
       Two new short instructions of the kernel make the programs smaller and faster:
         GLOB Ra  Ra := the start of the globals (right after the code)   DEV Ra  Ra := the device (Scr2.IO)
       A Screen, Touch or Sound word cost about 18 instructions (1694851494 in base 7), now 5; a global 8, now 3 to 5.
   OBERON-0 FOR TOR7, 2 (11 Nov 2026): RECORD, CASE and Sound (Pion: "all three").
       TYPE P = RECORD x, y: INTEGER; c: CHAR END;  p.x  a[i].y  (records are passed by reference, like arrays;
       a whole array or record can be assigned if it is small: a := b, up to 64 words)
       CASE x OF 1: ... | 2, 3: ... | 5..9: ... | "A": ... ELSE ... END
       Sound.Note(x, y, z, ms) a node of the Z7 cube   Sound.Hz(f, ms)   Sound.Play(slot)   Sound.Stop
   OBERON-0 FOR TOR7, 1 (11 Nov 2026): the screen and the touch (Pion: "Oberon does not know the touch screen").
       Screen.Clear(c) Rect(x, y, w, h, c) Circle(x, y, r, c) Char(x, y, ch, size, c) Int(x, y, n, size, c)
       Screen.String(x, y, "text", size, c) Show  and the functions Screen.Width() Height() Frames() RGB(r, g, b)
       Touch.Down() X() Y() Tap()   (Tap: TRUE once for every new touch)
     They are words in the 11th dimension (module Scr1): the compiler writes the parameters there and then the command.
     Draw, then Show: the picture changes and the program waits for the next frame (a game loop: draw, Show, again).
     The same program runs natively with OLL and the modules Screen.Mod and Touch.Mod.
   OBERON-0 FOR TOR7 (11 Nov 2026): the compiler of Cubicum N. Pion: "do it as you said".
     Wirth's Oberon-0 (plus Oberon-07 function procedures) compiled into Tor7 assembly, which Salamandra then puts
     in the cells of a turn. A program is ordinary Oberon: the same text compiles with OLL or Eula Oberon too.
       MODULE, IMPORT (Out, Tor), CONST, TYPE, VAR, PROCEDURE (value and VAR parameters, local variables,
       function procedures with RETURN at the end, recursion up to 49 deep), BEGIN ... END.
       Types INTEGER, BOOLEAN, CHAR and ARRAY n OF T (arrays are always passed by reference).
       Statements :=  IF ELSIF ELSE  WHILE  REPEAT UNTIL  FOR TO BY  procedure calls.
       Expressions + - * DIV MOD  = # < <= > >=  & OR ~ (short-circuit), ORD CHR ODD ABS INC DEC.
       Out.Int(x, n) Out.Char(c) Out.String("...") Out.Ln -> PRINTN / PRINTC.
       Tor: the world of the torus, each one instruction or a few:
         Step(a, d) Coord(a, d) Read(a) Write(a, v) Word(a) PutWord(a, v) Degree(a) Base() Field() Wait
         Neph(a) SetNeph(a, s) Corner(k) Emit(t, s) Listen(t) Play(a) Note(n, octave) Sleep(ms)
         Opal(hand) Ash() Time() Turn() Send(v, turn) Recv() From() Stop Yield
     Not yet: RECORD, CASE, REAL, strings in variables, nested procedures, bounds checks.
     The machine: R0..R3 hold the expression, R4 is for addresses, R5 is the frame, R6 belongs to the jumps.
     Every variable is a word of 12 cells; data starts at BASE + 32000 (after the code), frames grow upward.
     (Since version 3: at GLOB, right after the code, chosen by the kernel.)
     Pion & Claude, 11.11.2026 *)

  IMPORT Fisier;

  CONST
    SRC = 120000; OUT* = 480000; NID = 24; NSYM = 400; NTYP = 120;
    TURN = 117649; TEMPS = 32;
    (* symbols *)
    sNull = 0; sTimes = 1; sDiv = 2; sMod = 3; sAnd = 4; sPlus = 5; sMinus = 6; sOr = 7;
    sEql = 9; sNeq = 10; sLss = 11; sLeq = 12; sGtr = 13; sGeq = 14;
    sPeriod = 18; sComma = 19; sColon = 20; sRparen = 22; sRbrak = 23;
    sOf = 25; sThen = 26; sDo = 27; sTo = 28; sBy = 29; sUntil = 30;
    sLparen = 31; sLbrak = 32; sNot = 33; sBecomes = 34;
    sNumber = 35; sString = 36; sIdent = 37; sTrue = 38; sFalse = 39;
    sSemicolon = 40; sEnd = 41; sElse = 42; sElsif = 43; sIf = 44; sWhile = 45; sRepeat = 46; sFor = 47;
    sArray = 50; sRecord = 51; sConst = 52; sType = 53; sVar = 54; sProcedure = 55; sBegin = 56; sReturn = 57;
    sImport = 58; sModule = 59; sEof = 60; sCase = 61; sBar = 62; sUpto = 63;
    (* kinds of names *)
    kConst = 1; kVar = 2; kPar = 3; kVarPar = 4; kProc = 5; kType = 6;
    (* forms of types *)
    fInt = 1; fBool = 2; fChar = 3; fArray = 4; fRecord = 5; NF = 300;

  VAR
    src: ARRAY SRC OF CHAR; nsrc, pos, line: INTEGER; ch: CHAR;
    sym, val: INTEGER; id: ARRAY NID OF CHAR; str: ARRAY 200 OF CHAR; slen: INTEGER;
    asm*: ARRAY OUT OF CHAR; nasm: INTEGER;
    err*: ARRAY 100 OF CHAR; errLine*: INTEGER; bad: BOOLEAN;
    (* names *)
    sName: ARRAY NSYM, NID OF CHAR; sKind, sLev, sAdr, sTyp, sVal, sNp, sFirst: ARRAY NSYM OF INTEGER;
    nsym, nglob: INTEGER;   (* the local names start at nglob *)
    (* types *)
    tForm, tLen, tBase, tSize: ARRAY NTYP OF INTEGER; ntyp, tInt, tBool, tChar: INTEGER;
    (* procedures: the parameters of procedure p are the names sFirst[p] .. sFirst[p] + sNp[p] - 1 *)
    gWords*: INTEGER;   (* the words of the globals: the kernel puts them right after the code *)
    level, sp, labels, lWords, frame, spill, maxSpill, curProc: INTEGER;
    num: ARRAY 16 OF CHAR; pname: ARRAY NID OF CHAR; txt: ARRAY 200 OF CHAR;
    fName: ARRAY NF, NID OF CHAR; fOwn, fOff, fTyp: ARRAY NF OF INTEGER; nf: INTEGER;   (* the fields of the records *)
    Expression: PROCEDURE (VAR t: INTEGER); StatSeq: PROCEDURE;   (* they call each other *)

  (* ---------- output ---------- *)

  PROCEDURE Copy(VAR a: ARRAY OF CHAR; VAR b: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(b) - 1) & (i < LEN(a)) & (a[i] # 0X) DO b[i] := a[i]; INC(i) END; b[i] := 0X
  END Copy;


  PROCEDURE Error(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF ~bad THEN
      bad := TRUE; errLine := line; i := 0;
      WHILE (i < LEN(s)) & (i < LEN(err) - 1) & (s[i] # 0X) DO err[i] := s[i]; INC(i) END;
      err[i] := 0X
    END
  END Error;

  PROCEDURE A(s: ARRAY OF CHAR);   (* append to the assembly *)
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (nasm < OUT - 2) DO asm[nasm] := s[i]; INC(nasm); INC(i) END;
    IF nasm >= OUT - 2 THEN Error("PROGRAM TOO LONG") END;
    asm[nasm] := 0X
  END A;

  PROCEDURE Nl;   (* end of the line *)
  BEGIN IF nasm < OUT - 2 THEN asm[nasm] := 0AX; INC(nasm); asm[nasm] := 0X END
  END Nl;

  PROCEDURE N(n: INTEGER);   (* a number *)
    VAR d: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN A("-"); n := -n END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE k > 0 DO DEC(k); num[0] := d[k]; num[1] := 0X; A(num) END
  END N;

  PROCEDURE R(r: INTEGER);   (* a register *)
  BEGIN num[0] := "R"; num[1] := CHR(ORD("0") + r); num[2] := 0X; A(num)
  END R;

  PROCEDURE Op1(op: ARRAY OF CHAR; a: INTEGER);
  BEGIN A(op); A(" "); R(a); Nl
  END Op1;

  PROCEDURE Op2(op: ARRAY OF CHAR; a, b: INTEGER);
  BEGIN A(op); A(" "); R(a); A(", "); R(b); Nl
  END Op2;

  PROCEDURE Lab(l: INTEGER);   (* a label: Lnn *)
  BEGIN A("L"); N(l)
  END Lab;

  PROCEDURE Here(l: INTEGER);
  BEGIN Lab(l); A(":"); Nl
  END Here;

  PROCEDURE NewLab(): INTEGER;
  BEGIN INC(labels)
    RETURN labels
  END NewLab;

  PROCEDURE Jmp(l: INTEGER);
  BEGIN A("JMP "); Lab(l); Nl
  END Jmp;

  PROCEDURE Jz(r, l: INTEGER);
  BEGIN A("JZ "); R(r); A(", "); Lab(l); Nl
  END Jz;

  PROCEDURE Jnz(r, l: INTEGER);
  BEGIN A("JNZ "); R(r); A(", "); Lab(l); Nl
  END Jnz;

  PROCEDURE Const(r, n: INTEGER);   (* Rr := n *)
  BEGIN
    IF (n >= 0) & (n < 100000000) THEN A("SET "); R(r); A(", "); N(n); Nl
    ELSIF n >= 100000000 THEN
      Const(r, n DIV 10000); Const(4, 10000); Op2("MUL", r, 4); Const(4, n MOD 10000); Op2("ADD", r, 4)
    ELSIF n > -2147483647 THEN
      Const(r, -n); Const(4, 0); Op2("SUB", 4, r); Op2("MOV", r, 4)
    ELSE Error("NUMBER TOO SMALL")
    END
  END Const;

  PROCEDURE Push(): INTEGER;
    VAR r: INTEGER;
  BEGIN
    r := sp; IF sp >= 4 THEN Error("EXPRESSION TOO DEEP (SPLIT IT)") ELSE INC(sp) END
    RETURN r
  END Push;

  (* ---------- scanner ---------- *)

  PROCEDURE Next;
  BEGIN
    IF pos < nsrc THEN ch := src[pos]; INC(pos); IF ch = 0AX THEN INC(line) END ELSE ch := 0X END
  END Next;

  PROCEDURE Eq(a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN ((i = LEN(a)) OR (a[i] = 0X)) & ((i = LEN(b)) OR (b[i] = 0X))
  END Eq;

  PROCEDURE Comment;
    VAR depth: INTEGER;
  BEGIN
    depth := 1; Next;
    WHILE (depth > 0) & (ch # 0X) DO
      IF ch = "(" THEN Next; IF ch = "*" THEN INC(depth); Next END
      ELSIF ch = "*" THEN Next; IF ch = ")" THEN DEC(depth); Next END
      ELSE Next
      END
    END;
    IF depth > 0 THEN Error("COMMENT NOT CLOSED") END
  END Comment;

  PROCEDURE Word;
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE ((ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") OR (ch >= "0") & (ch <= "9")) DO
      IF i < NID - 1 THEN id[i] := ch; INC(i) END; Next
    END;
    id[i] := 0X; sym := sIdent;
    IF Eq(id, "DIV") THEN sym := sDiv ELSIF Eq(id, "MOD") THEN sym := sMod ELSIF Eq(id, "OR") THEN sym := sOr
    ELSIF Eq(id, "OF") THEN sym := sOf ELSIF Eq(id, "THEN") THEN sym := sThen ELSIF Eq(id, "DO") THEN sym := sDo
    ELSIF Eq(id, "TO") THEN sym := sTo ELSIF Eq(id, "BY") THEN sym := sBy ELSIF Eq(id, "UNTIL") THEN sym := sUntil
    ELSIF Eq(id, "END") THEN sym := sEnd ELSIF Eq(id, "ELSE") THEN sym := sElse ELSIF Eq(id, "ELSIF") THEN sym := sElsif
    ELSIF Eq(id, "IF") THEN sym := sIf ELSIF Eq(id, "WHILE") THEN sym := sWhile ELSIF Eq(id, "REPEAT") THEN sym := sRepeat
    ELSIF Eq(id, "FOR") THEN sym := sFor ELSIF Eq(id, "ARRAY") THEN sym := sArray ELSIF Eq(id, "RECORD") THEN sym := sRecord
    ELSIF Eq(id, "CONST") THEN sym := sConst ELSIF Eq(id, "TYPE") THEN sym := sType ELSIF Eq(id, "VAR") THEN sym := sVar
    ELSIF Eq(id, "PROCEDURE") THEN sym := sProcedure ELSIF Eq(id, "BEGIN") THEN sym := sBegin
    ELSIF Eq(id, "RETURN") THEN sym := sReturn ELSIF Eq(id, "IMPORT") THEN sym := sImport ELSIF Eq(id, "MODULE") THEN sym := sModule
    ELSIF Eq(id, "TRUE") THEN sym := sTrue ELSIF Eq(id, "FALSE") THEN sym := sFalse ELSIF Eq(id, "CASE") THEN sym := sCase
    END
  END Word;

  PROCEDURE Number;   (* 123, 0FFH (hex), 41X (a character) *)
    VAR d: ARRAY 20 OF INTEGER; n, i, v: INTEGER; hex: BOOLEAN;
  BEGIN
    n := 0; hex := FALSE;
    WHILE (ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "F") DO
      IF ch >= "A" THEN d[n MOD 20] := ORD(ch) - ORD("A") + 10; hex := TRUE ELSE d[n MOD 20] := ORD(ch) - ORD("0") END;
      INC(n); Next
    END;
    v := 0;
    IF (ch = "H") OR (ch = "X") THEN
      FOR i := 0 TO n - 1 DO v := v * 16 + d[i MOD 20] END;
      Next
    ELSE
      IF hex THEN Error("HEX NUMBERS END WITH H") END;
      FOR i := 0 TO n - 1 DO IF v <= 214748364 THEN v := v * 10 + d[i MOD 20] ELSE Error("NUMBER TOO BIG") END END
    END;
    val := v; sym := sNumber
  END Number;

  PROCEDURE Get;
  BEGIN
    WHILE (ch # 0X) & (ch <= " ") DO Next END;
    IF ch = 0X THEN sym := sEof
    ELSIF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN Word
    ELSIF (ch >= "0") & (ch <= "9") THEN Number
    ELSIF ch = 22X THEN
      Next; slen := 0;
      WHILE (ch # 22X) & (ch # 0X) & (ch # 0AX) DO IF slen < 199 THEN str[slen] := ch; INC(slen) END; Next END;
      str[slen] := 0X; IF ch = 22X THEN Next ELSE Error("STRING NOT CLOSED") END;
      sym := sString
    ELSE
      IF ch = "*" THEN Next; sym := sTimes
      ELSIF ch = "&" THEN Next; sym := sAnd
      ELSIF ch = "+" THEN Next; sym := sPlus
      ELSIF ch = "-" THEN Next; sym := sMinus
      ELSIF ch = "=" THEN Next; sym := sEql
      ELSIF ch = "#" THEN Next; sym := sNeq
      ELSIF ch = "<" THEN Next; IF ch = "=" THEN Next; sym := sLeq ELSE sym := sLss END
      ELSIF ch = ">" THEN Next; IF ch = "=" THEN Next; sym := sGeq ELSE sym := sGtr END
      ELSIF ch = "." THEN Next; IF ch = "." THEN Next; sym := sUpto ELSE sym := sPeriod END
      ELSIF ch = "|" THEN Next; sym := sBar
      ELSIF ch = "," THEN Next; sym := sComma
      ELSIF ch = ":" THEN Next; IF ch = "=" THEN Next; sym := sBecomes ELSE sym := sColon END
      ELSIF ch = ";" THEN Next; sym := sSemicolon
      ELSIF ch = ")" THEN Next; sym := sRparen
      ELSIF ch = "]" THEN Next; sym := sRbrak
      ELSIF ch = "[" THEN Next; sym := sLbrak
      ELSIF ch = "~" THEN Next; sym := sNot
      ELSIF ch = "(" THEN Next; IF ch = "*" THEN Comment; Get ELSE sym := sLparen END
      ELSE Next; sym := sNull; Error("A SIGN OBERON DOES NOT KNOW")
      END
    END
  END Get;

  PROCEDURE Check(s: INTEGER; what: ARRAY OF CHAR);
  BEGIN IF sym = s THEN Get ELSE Error(what) END
  END Check;

  (* ---------- names and types ---------- *)

  PROCEDURE NewType(form, len, base: INTEGER): INTEGER;
    VAR t: INTEGER;
  BEGIN
    t := ntyp;
    IF ntyp < NTYP THEN
      tForm[t] := form; tLen[t] := len; tBase[t] := base;
      IF form = fArray THEN tSize[t] := len * tSize[base] ELSE tSize[t] := 1 END;
      INC(ntyp)
    ELSE Error("TOO MANY TYPES"); t := 0
    END
    RETURN t
  END NewType;

  PROCEDURE Find(VAR name: ARRAY OF CHAR): INTEGER;   (* local names first; -1 = not known *)
    VAR i, r: INTEGER;
  BEGIN
    r := -1; i := nsym - 1;
    WHILE (r < 0) & (i >= 0) DO
      IF (sName[i, 0] # 0X) & Eq(sName[i], name) THEN r := i END;
      DEC(i)
    END
    RETURN r
  END Find;

  PROCEDURE Declare(VAR name: ARRAY OF CHAR; kind: INTEGER): INTEGER;
    VAR i, k: INTEGER;
  BEGIN
    IF level = 0 THEN i := 0 ELSE i := nglob END;
    WHILE i < nsym DO IF Eq(sName[i], name) THEN Error("THIS NAME IS ALREADY DECLARED") END; INC(i) END;
    k := nsym;
    IF nsym < NSYM THEN
      i := 0; WHILE (i < NID - 1) & (name[i] # 0X) DO sName[k, i] := name[i]; INC(i) END; sName[k, i] := 0X;
      sKind[k] := kind; sLev[k] := level; sAdr[k] := 0; sTyp[k] := tInt; sVal[k] := 0; sNp[k] := 0; sFirst[k] := 0;
      INC(nsym)
    ELSE Error("TOO MANY NAMES"); k := 0
    END
    RETURN k
  END Declare;

  PROCEDURE Builtin(VAR name: ARRAY OF CHAR; t: INTEGER);
    VAR k: INTEGER;
  BEGIN k := Declare(name, kType); sTyp[k] := t
  END Builtin;

  (* ---------- addresses ---------- *)

  PROCEDURE AddrOf(k, r: INTEGER);   (* Rr := the address of variable k (for a VAR parameter: the address it holds) *)
  BEGIN
    IF sLev[k] = 0 THEN Op1("GLOB", r); IF sAdr[k] # 0 THEN Const(4, 12 * sAdr[k]); Op2("ADD", r, 4) END
    ELSE Const(4, 12 * sAdr[k]); Op2("MOV", r, 5); Op2("ADD", r, 4)
    END;
    IF (sKind[k] = kVarPar) OR (sKind[k] = kPar) & (tForm[sTyp[k]] >= fArray) THEN Op2("LDW", r, r) END
  END AddrOf;

  PROCEDURE FrameSlot(slot: INTEGER);   (* R4 := FP + 12 * slot *)
  BEGIN Const(4, 12 * slot); Op2("ADD", 4, 5)
  END FrameSlot;

  PROCEDURE Designator(k: INTEGER; VAR t: INTEGER);   (* the address of variable k (with its indexes and fields) in a new register *)
    VAR r, ti, f: INTEGER;
  BEGIN
    r := Push(); AddrOf(k, r); t := sTyp[k];
    WHILE (sym = sLbrak) OR (sym = sPeriod) DO
      IF sym = sPeriod THEN   (* a field of a record *)
        Get;
        IF tForm[t] # fRecord THEN Error("NOT A RECORD")
        ELSIF sym # sIdent THEN Error("A FIELD NAME IS MISSING")
        ELSE
          f := 0; WHILE (f < nf) & ~((fOwn[f] = t) & Eq(fName[f], id)) DO INC(f) END;
          IF f = nf THEN Error("THE RECORD HAS NO SUCH FIELD")
          ELSE Const(4, 12 * fOff[f]); Op2("ADD", r, 4); t := fTyp[f]
          END;
          Get
        END
      ELSE
      Get;
      REPEAT
        IF tForm[t] # fArray THEN Error("NOT AN ARRAY") END;
        Expression(ti);
        IF tForm[ti] # fInt THEN Error("AN INDEX MUST BE AN INTEGER") END;
        Const(4, 12 * tSize[tBase[t]]); Op2("MUL", r + 1, 4); Op2("ADD", r, r + 1); DEC(sp);
        t := tBase[t];
        IF sym = sComma THEN Get; IF sym = sRbrak THEN Error("AN INDEX IS MISSING") END END
      UNTIL bad OR (sym = sRbrak);
      Check(sRbrak, "] IS MISSING")
      END
    END
  END Designator;

  (* ---------- calls ---------- *)

  PROCEDURE Call(p: INTEGER);   (* the arguments are in ( ... ); the result (of a function) in R0 *)
    VAR d, i, n, t, base, k, sv: INTEGER;
  BEGIN
    d := sp; base := spill;
    IF spill + d + sNp[p] > TEMPS THEN Error("CALLS NESTED TOO DEEP") END;
    FOR i := 0 TO d - 1 DO FrameSlot(frame - TEMPS + spill + i); Op2("STW", i, 4) END;   (* keep what was being computed *)
    spill := spill + d; sp := 0; n := 0;
    IF sym = sLparen THEN
      Get;
      IF sym # sRparen THEN
        REPEAT
          IF n >= sNp[p] THEN Error("TOO MANY ARGUMENTS") END;
          k := sFirst[p] + n;
          IF (sKind[k] = kVarPar) OR (tForm[sTyp[k]] >= fArray) THEN   (* by reference: the address *)
            IF sym # sIdent THEN Error("A VARIABLE IS NEEDED HERE")
            ELSE
              i := Find(id); Get;
              IF (i < 0) OR ~((sKind[i] = kVar) OR (sKind[i] = kPar) OR (sKind[i] = kVarPar)) THEN Error("A VARIABLE IS NEEDED HERE")
              ELSE Designator(i, t)
              END
            END
          ELSE Expression(t)
          END;
          sv := spill; FrameSlot(frame - TEMPS + spill); Op2("STW", 0, 4); DEC(sp);
          INC(spill); INC(n);
          IF sym = sComma THEN Get ELSIF sym # sRparen THEN Error(", OR ) IS MISSING") END
        UNTIL bad OR (sym = sRparen)
      END;
      Check(sRparen, ") IS MISSING")
    END;
    IF n # sNp[p] THEN Error("WRONG NUMBER OF ARGUMENTS") END;
    (* the arguments go into the new frame, which starts right after this one *)
    FOR i := 0 TO n - 1 DO
      FrameSlot(frame - TEMPS + base + d + i); Op2("LDW", 0, 4);
      FrameSlot(frame + 1 + i); Op2("STW", 0, 4)
    END;
    FrameSlot(frame); Op2("STW", 5, 4); Op2("MOV", 5, 4);   (* the new frame keeps the old one *)
    A("CALL P"); N(p); Nl;
    (* back: the result is in R0; what was being computed comes back *)
    IF d > 0 THEN
      IF sKind[p] = kProc THEN Op2("MOV", d, 0) END;
      FOR i := 0 TO d - 1 DO FrameSlot(frame - TEMPS + base + i); Op2("LDW", i, 4) END
    END;
    spill := base; sp := d
  END Call;

  PROCEDURE Args(n: INTEGER);   (* n arguments of a built-in, onto the expression stack *)
    VAR i, t: INTEGER;
  BEGIN
    Check(sLparen, "( IS MISSING");
    FOR i := 1 TO n DO Expression(t); IF i < n THEN Check(sComma, ", IS MISSING") END END;
    Check(sRparen, ") IS MISSING")
  END Args;

  PROCEDURE NoArgs;   (* Tor.Field or Tor.Field() *)
  BEGIN IF sym = sLparen THEN Get; Check(sRparen, ") IS MISSING") END
  END NoArgs;

  PROCEDURE DevAddr(r, k: INTEGER);   (* Rr := the address of device word k *)
  BEGIN Op1("DEV", r); IF k # 0 THEN Const(4, 12 * k); Op2("ADD", r, 4) END   (* r is never R4 *)
  END DevAddr;

  PROCEDURE DevArgs(first, n: INTEGER; open: BOOLEAN);   (* n arguments into the device words first.. (one at a time) *)
    VAR i, r, t: INTEGER;
  BEGIN
    IF open THEN Check(sLparen, "( IS MISSING") END;
    FOR i := 0 TO n - 1 DO
      Expression(t); r := sp - 1;
      IF r >= 3 THEN Error("EXPRESSION TOO DEEP (SPLIT IT)") END;
      DevAddr(r + 1, first + i); Op2("STW", r, r + 1); DEC(sp);
      IF i < n - 1 THEN Check(sComma, ", IS MISSING") END
    END
  END DevArgs;

  PROCEDURE DevCmd(code: INTEGER);
    VAR r: INTEGER;
  BEGIN
    r := sp; IF r >= 3 THEN Error("EXPRESSION TOO DEEP (SPLIT IT)") END;
    Const(r, code); DevAddr(r + 1, 16); Op2("STW", r, r + 1)
  END DevCmd;

  PROCEDURE DevRead(k: INTEGER);   (* a device word onto the stack *)
    VAR r: INTEGER;
  BEGIN r := Push(); DevAddr(r, k); Op2("LDW", r, r)
  END DevRead;

  PROCEDURE BuiltinCall(VAR m: ARRAY OF CHAR; VAR name: ARRAY OF CHAR; func: BOOLEAN; VAR t: INTEGER): BOOLEAN;
    (* Out.* and Tor.*; FALSE = unknown. A function leaves its value on the stack *)
    VAR r, i, w: INTEGER; ok, isf: BOOLEAN;
  BEGIN
    ok := TRUE; isf := FALSE; t := tInt; r := sp;
    IF Eq(m, "Out") THEN
      IF Eq(name, "Int") THEN
        Check(sLparen, "( IS MISSING"); Expression(t); IF sym = sComma THEN Get; Expression(w); DEC(sp) END;
        Check(sRparen, ") IS MISSING"); Op1("PRINTN", r); DEC(sp)
      ELSIF Eq(name, "Char") THEN Args(1); Op1("PRINTC", r); DEC(sp)
      ELSIF Eq(name, "Ln") THEN NoArgs; Const(4, 10); Op1("PRINTC", 4)
      ELSIF Eq(name, "String") THEN
        Check(sLparen, "( IS MISSING");
        IF sym # sString THEN Error("A STRING IS NEEDED") END;
        FOR i := 0 TO slen - 1 DO Const(4, ORD(str[i])); Op1("PRINTC", 4) END;
        Get; Check(sRparen, ") IS MISSING")
      ELSE ok := FALSE
      END
    ELSIF Eq(m, "Screen") THEN
      isf := FALSE;
      IF Eq(name, "Clear") THEN DevArgs(10, 1, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(1)
      ELSIF Eq(name, "Rect") THEN DevArgs(10, 5, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(2)
      ELSIF Eq(name, "Char") THEN DevArgs(10, 5, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(3)
      ELSIF Eq(name, "Int") THEN DevArgs(10, 5, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(4)
      ELSIF Eq(name, "Circle") THEN DevArgs(10, 4, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(6)
      ELSIF Eq(name, "Show") THEN NoArgs; DevCmd(5)
      ELSIF Eq(name, "String") THEN   (* x, y, "text", size, c *)
        DevArgs(10, 2, TRUE); Check(sComma, ", IS MISSING");
        IF sym # sString THEN Error("A STRING IS NEEDED") END;
        Copy(str, txt); w := slen; Get; Check(sComma, ", IS MISSING");
        DevArgs(12, 2, FALSE); Check(sRparen, ") IS MISSING");
        DevCmd(7);
        FOR i := 0 TO w - 1 DO r := sp; Const(r, ORD(txt[i])); DevAddr(r + 1, 10); Op2("STW", r, r + 1); DevCmd(8) END
      ELSE
        isf := TRUE;
        IF Eq(name, "Width") THEN NoArgs; DevRead(4)
        ELSIF Eq(name, "Height") THEN NoArgs; DevRead(5)
        ELSIF Eq(name, "Frames") THEN NoArgs; DevRead(6)
        ELSIF Eq(name, "RGB") THEN
          Args(3); Const(4, 256); Op2("MUL", r + 1, 4); Const(4, 65536); Op2("MUL", r + 2, 4);
          Op2("ADD", r, r + 1); Op2("ADD", r, r + 2); DEC(sp, 2)
        ELSE ok := FALSE
        END
      END
    ELSIF Eq(m, "Sound") THEN
      isf := FALSE;
      IF Eq(name, "Note") THEN DevArgs(10, 4, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(20)
      ELSIF Eq(name, "Hz") THEN DevArgs(10, 2, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(21)
      ELSIF Eq(name, "Play") THEN DevArgs(10, 1, TRUE); Check(sRparen, ") IS MISSING"); DevCmd(22)
      ELSIF Eq(name, "Stop") THEN NoArgs; DevCmd(23)
      ELSE ok := FALSE
      END
    ELSIF Eq(m, "Touch") THEN
      isf := TRUE;
      IF Eq(name, "Down") THEN NoArgs; DevRead(0); t := tBool
      ELSIF Eq(name, "X") THEN NoArgs; DevRead(1)
      ELSIF Eq(name, "Y") THEN NoArgs; DevRead(2)
      ELSIF Eq(name, "Tap") THEN NoArgs; DevRead(3); t := tBool
      ELSE ok := FALSE
      END
    ELSIF Eq(m, "Tor") THEN
      isf := TRUE;
      IF Eq(name, "Step") THEN Args(2); Op2("STEP", r, r + 1); DEC(sp)
      ELSIF Eq(name, "Coord") THEN Args(2); Op2("COORD", r, r + 1); DEC(sp)
      ELSIF Eq(name, "Read") THEN Args(1); Op2("LD", r, r)
      ELSIF Eq(name, "Word") THEN Args(1); Op2("LDW", r, r)
      ELSIF Eq(name, "Degree") THEN Args(1); Op2("NOTEC", r, r)
      ELSIF Eq(name, "Neph") THEN Args(1); Op2("NEPH", r, r)
      ELSIF Eq(name, "Emit") THEN Args(2); Op2("EMIT", r, r + 1); DEC(sp)
      ELSIF Eq(name, "Listen") THEN Args(1); Op2("LISTEN", r, r)
      ELSIF Eq(name, "Opal") THEN Args(1); Op2("OPAL", r, r)
      ELSIF Eq(name, "Base") THEN NoArgs; r := Push(); Op1("BASE", r)
      ELSIF Eq(name, "Field") THEN NoArgs; r := Push(); Op1("FIELD", r)
      ELSIF Eq(name, "Ash") THEN NoArgs; r := Push(); Op1("ASH", r)
      ELSIF Eq(name, "Time") THEN NoArgs; r := Push(); Op1("TIME", r)
      ELSIF Eq(name, "Turn") THEN NoArgs; r := Push(); Op1("TURN", r)
      ELSIF Eq(name, "From") THEN NoArgs; r := Push(); Op1("FROM", r)
      ELSIF Eq(name, "Recv") THEN NoArgs; r := Push(); Op2("RECV", r, 4)
      ELSE
        isf := FALSE;
        IF Eq(name, "Write") THEN Args(2); Op2("ST", r + 1, r); DEC(sp, 2)
        ELSIF Eq(name, "PutWord") THEN Args(2); Op2("STW", r + 1, r); DEC(sp, 2)
        ELSIF Eq(name, "SetNeph") THEN Args(2); Op2("SETNEPH", r + 1, r); DEC(sp, 2)
        ELSIF Eq(name, "Corner") THEN Args(1); Op1("CORNER", r); DEC(sp)
        ELSIF Eq(name, "Play") THEN Args(1); Op1("PLAYC", r); DEC(sp)
        ELSIF Eq(name, "Note") THEN Args(2); Op2("NOTE", r, r + 1); DEC(sp, 2)
        ELSIF Eq(name, "Sleep") THEN Args(1); Op1("SLEEP", r); DEC(sp)
        ELSIF Eq(name, "Send") THEN Args(2); Op2("SEND", r, r + 1); DEC(sp, 2)
        ELSIF Eq(name, "Wait") THEN NoArgs; A("WAIT"); Nl
        ELSIF Eq(name, "Stop") THEN NoArgs; A("STOP"); Nl
        ELSIF Eq(name, "Yield") THEN NoArgs; A("YIELD"); Nl
        ELSE ok := FALSE
        END
      END
    ELSE ok := FALSE
    END;
    IF ok & (isf # func) THEN
      IF func THEN Error("THIS GIVES NO VALUE") ELSE Error("THIS IS A FUNCTION: USE ITS VALUE") END
    END
    RETURN ok
  END BuiltinCall;

  (* ---------- expressions ---------- *)

  PROCEDURE Not(r: INTEGER);   (* Rr := (Rr = 0) *)
  BEGIN Const(4, 0); Op2("EQ", r, 4)
  END Not;

  PROCEDURE Factor(VAR t: INTEGER);
    VAR k, r, t2: INTEGER; m: ARRAY NID OF CHAR;
  BEGIN
    IF sym = sNumber THEN r := Push(); Const(r, val); t := tInt; Get
    ELSIF sym = sString THEN
      IF slen # 1 THEN Error("ONLY ONE LETTER HERE") END;
      r := Push(); Const(r, ORD(str[0])); t := tChar; Get
    ELSIF sym = sTrue THEN r := Push(); Const(r, 1); t := tBool; Get
    ELSIF sym = sFalse THEN r := Push(); Const(r, 0); t := tBool; Get
    ELSIF sym = sLparen THEN Get; Expression(t); Check(sRparen, ") IS MISSING")
    ELSIF sym = sNot THEN Get; Factor(t); Not(sp - 1); t := tBool
    ELSIF sym = sIdent THEN
      Copy(id, m); Get;
      IF (sym = sPeriod) & (Find(m) < 0) THEN   (* Out.x, Tor.x, ... *)
        Get;
        IF sym = sIdent THEN
          Copy(id, pname); Get;
          IF ~BuiltinCall(m, pname, TRUE, t) THEN Error("UNKNOWN: USE Tor.Step, Tor.Read, ...") END
        ELSE Error("A NAME IS MISSING AFTER .")
        END
      ELSIF Eq(m, "ORD") OR Eq(m, "CHR") OR Eq(m, "ABS") OR Eq(m, "ODD") THEN
        Args(1); r := sp - 1;
        IF Eq(m, "ORD") THEN t := tInt ELSIF Eq(m, "CHR") THEN t := tChar
        ELSIF Eq(m, "ODD") THEN Const(4, 2); Op2("MOD", r, 4); t := tBool
        ELSE   (* ABS: if R < 0 then 0 - R *)
          k := NewLab(); Const(4, 0); Op2("LT", 4, r); Jnz(4, k); Const(4, 0); Op2("SUB", 4, r); Op2("MOV", r, 4); Here(k);
          t := tInt
        END
      ELSE
        k := Find(m);
        IF k < 0 THEN Error("UNKNOWN NAME")
        ELSIF sKind[k] = kConst THEN r := Push(); Const(r, sVal[k]); t := sTyp[k]
        ELSIF (sKind[k] = kVar) OR (sKind[k] = kPar) OR (sKind[k] = kVarPar) THEN
          Designator(k, t);
          IF tForm[t] >= fArray THEN Error("A WHOLE ARRAY OR RECORD HAS NO VALUE HERE") END;
          Op2("LDW", sp - 1, sp - 1)
        ELSIF (sKind[k] = kProc) & (sTyp[k] # 0) THEN Call(k); r := Push(); t := sTyp[k]
        ELSE Error("THIS NAME HAS NO VALUE")
        END
      END
    ELSE Error("AN EXPRESSION IS MISSING"); Get
    END;
    t2 := t
  END Factor;

  PROCEDURE Term(VAR t: INTEGER);
    VAR op, t2, l: INTEGER;
  BEGIN
    Factor(t);
    WHILE ~bad & ((sym = sTimes) OR (sym = sDiv) OR (sym = sMod) OR (sym = sAnd)) DO
      op := sym; Get;
      IF op = sAnd THEN
        l := NewLab(); Jz(sp - 1, l); DEC(sp); Factor(t2); Here(l); t := tBool
      ELSE
        Factor(t2);
        IF op = sTimes THEN Op2("MUL", sp - 2, sp - 1) ELSIF op = sDiv THEN Op2("DIV", sp - 2, sp - 1)
        ELSE Op2("MOD", sp - 2, sp - 1)
        END;
        DEC(sp)
      END
    END
  END Term;

  PROCEDURE SimpleExpression(VAR t: INTEGER);
    VAR op, t2, l: INTEGER; neg: BOOLEAN;
  BEGIN
    neg := FALSE;
    IF sym = sMinus THEN Get; neg := TRUE ELSIF sym = sPlus THEN Get END;
    Term(t);
    IF neg THEN Const(4, 0); Op2("SUB", 4, sp - 1); Op2("MOV", sp - 1, 4) END;
    WHILE ~bad & ((sym = sPlus) OR (sym = sMinus) OR (sym = sOr)) DO
      op := sym; Get;
      IF op = sOr THEN
        l := NewLab(); Jnz(sp - 1, l); DEC(sp); Term(t2); Here(l); t := tBool
      ELSE
        Term(t2);
        IF op = sPlus THEN Op2("ADD", sp - 2, sp - 1) ELSE Op2("SUB", sp - 2, sp - 1) END;
        DEC(sp)
      END
    END
  END SimpleExpression;

  PROCEDURE Expression0(VAR t: INTEGER);
    VAR op, t2, a, b: INTEGER;
  BEGIN
    SimpleExpression(t);
    IF (sym >= sEql) & (sym <= sGeq) THEN
      op := sym; Get; SimpleExpression(t2);
      a := sp - 2; b := sp - 1;
      IF op = sEql THEN Op2("EQ", a, b)
      ELSIF op = sNeq THEN Op2("EQ", a, b); Not(a)
      ELSIF op = sLss THEN Op2("LT", a, b)
      ELSIF op = sGtr THEN Op2("LT", b, a); Op2("MOV", a, b)
      ELSIF op = sLeq THEN Op2("LT", b, a); Op2("MOV", a, b); Not(a)
      ELSE Op2("LT", a, b); Not(a)
      END;
      DEC(sp); t := tBool
    END
  END Expression0;


  (* ---------- statements ---------- *)

  PROCEDURE Cond;   (* a condition into R0 *)
    VAR t: INTEGER;
  BEGIN Expression(t); IF (tForm[t] # fBool) & ~bad THEN Error("A CONDITION (TRUE OR FALSE) IS NEEDED") END
  END Cond;

  PROCEDURE ConstExpr(): INTEGER;   (* a number, a constant, a letter, or -x *)
    VAR v, k: INTEGER; neg: BOOLEAN;
  BEGIN
    v := 0; neg := FALSE;
    IF sym = sMinus THEN Get; neg := TRUE END;
    IF sym = sNumber THEN v := val; Get
    ELSIF (sym = sString) & (slen = 1) THEN v := ORD(str[0]); Get
    ELSIF sym = sIdent THEN
      k := Find(id);
      IF (k >= 0) & (sKind[k] = kConst) THEN v := sVal[k] ELSE Error("A CONSTANT IS NEEDED") END;
      Get
    ELSE Error("A CONSTANT IS NEEDED")
    END;
    IF neg THEN v := -v END
    RETURN v
  END ConstExpr;

  PROCEDURE CopyWhole(t: INTEGER);   (* a := b for a whole array or record: the address of a is in R0 *)
    VAR k, t2, i: INTEGER;
  BEGIN
    IF sym # sIdent THEN Error("A VARIABLE OF THE SAME TYPE IS NEEDED")
    ELSE
      k := Find(id); Get;
      IF (k < 0) OR (sKind[k] < kVar) OR (sKind[k] > kVarPar) THEN Error("A VARIABLE OF THE SAME TYPE IS NEEDED")
      ELSE
        Designator(k, t2);   (* R1 = the address of b *)
        IF t2 # t THEN Error("THE TYPES DO NOT MATCH")
        ELSIF tSize[t] > 64 THEN Error("TOO BIG TO COPY AT ONCE: COPY IT IN A LOOP")
        ELSE
          FOR i := 0 TO tSize[t] - 1 DO
            Op2("LDW", 2, 1); Op2("STW", 2, 0);
            IF i < tSize[t] - 1 THEN Const(4, 12); Op2("ADD", 0, 4); Op2("ADD", 1, 4) END
          END
        END
      END
    END;
    sp := 0
  END CopyWhole;

  PROCEDURE CaseStat;   (* CASE e OF labels: S | ... ELSE S END; the value waits in a temporary word of the frame *)
    VAR t, slot, lend, lbody, lnext, lo, hi: INTEGER;
  BEGIN
    Get; sp := 0; Expression(t);
    IF spill >= TEMPS THEN Error("CASE NESTED TOO DEEP") END;
    slot := frame - TEMPS + spill; INC(spill);
    FrameSlot(slot); Op2("STW", 0, 4); sp := 0;
    Check(sOf, "OF IS MISSING");
    lend := NewLab();
    REPEAT
      IF sym = sBar THEN Get END;
      IF (sym # sBar) & (sym # sElse) & (sym # sEnd) THEN
        lbody := NewLab(); lnext := NewLab();
        REPEAT
          lo := ConstExpr(); hi := lo;
          IF sym = sUpto THEN Get; hi := ConstExpr() END;
          FrameSlot(slot); Op2("LDW", 0, 4);
          IF lo = hi THEN Const(1, lo); Op2("EQ", 0, 1)
          ELSE   (* lo <= v <= hi *)
            Const(1, lo); Op2("LT", 0, 1); Not(0);
            FrameSlot(slot); Op2("LDW", 1, 4); Const(2, hi); Op2("LT", 2, 1); Not(2); Op2("MUL", 0, 2)
          END;
          Jnz(0, lbody);
          IF sym = sComma THEN Get END
        UNTIL bad OR (sym = sColon) OR (sym # sNumber) & (sym # sString) & (sym # sIdent) & (sym # sMinus);
        Check(sColon, ": IS MISSING AFTER THE LABELS");
        Jmp(lnext); Here(lbody); StatSeq; Jmp(lend); Here(lnext)
      END
    UNTIL bad OR (sym # sBar);
    IF sym = sElse THEN Get; StatSeq END;
    Here(lend); DEC(spill); sp := 0;
    Check(sEnd, "END IS MISSING (CASE)")
  END CaseStat;

  PROCEDURE Statement;
    VAR k, t, t2, l1, l2, r: INTEGER; m: ARRAY NID OF CHAR; up: BOOLEAN; by: INTEGER;
  BEGIN
    sp := 0;
    IF sym = sIdent THEN
      Copy(id, m); Get;
      IF (sym = sPeriod) & (Find(m) < 0) THEN
        Get;
        IF sym = sIdent THEN Copy(id, pname); Get; IF ~BuiltinCall(m, pname, FALSE, t) THEN Error("UNKNOWN PROCEDURE") END
        ELSE Error("A NAME IS MISSING AFTER .")
        END
      ELSIF Eq(m, "INC") OR Eq(m, "DEC") THEN
        Check(sLparen, "( IS MISSING");
        IF sym # sIdent THEN Error("A VARIABLE IS NEEDED") END;
        k := Find(id); Get;
        IF (k < 0) OR (sKind[k] < kVar) OR (sKind[k] > kVarPar) THEN Error("A VARIABLE IS NEEDED")
        ELSE
          Designator(k, t);   (* R0 = address *)
          r := Push(); Op2("LDW", r, 0);
          IF sym = sComma THEN Get; Expression(t2) ELSE r := Push(); Const(r, 1) END;
          IF Eq(m, "INC") THEN Op2("ADD", 1, 2) ELSE Op2("SUB", 1, 2) END;
          Op2("STW", 1, 0); sp := 0;
          Check(sRparen, ") IS MISSING")
        END
      ELSE
        k := Find(m);
        IF k < 0 THEN Error("UNKNOWN NAME")
        ELSIF ((sKind[k] = kVar) OR (sKind[k] = kPar) OR (sKind[k] = kVarPar)) & (sym = sBecomes) & (tForm[sTyp[k]] < fArray) THEN
          (* a plain variable: first the value (R0), then the address (R1): one register more for the expression *)
          t := sTyp[k];
          IF tForm[t] = fArray THEN Error("CANNOT ASSIGN A WHOLE ARRAY") END;
          Get; Expression(t2);
          IF ~bad & (tForm[t] # tForm[t2]) & ~((tForm[t] # fBool) & (tForm[t2] # fBool)) THEN Error("THE TYPES DO NOT MATCH") END;
          AddrOf(k, 1); Op2("STW", 0, 1); sp := 0
        ELSIF (sKind[k] = kVar) OR (sKind[k] = kPar) OR (sKind[k] = kVarPar) THEN
          Designator(k, t);
          Check(sBecomes, ":= IS MISSING");
          IF tForm[t] >= fArray THEN CopyWhole(t) ELSE
          Expression(t2);
          IF ~bad & (tForm[t] # tForm[t2]) & ~((tForm[t] # fBool) & (tForm[t2] # fBool)) THEN Error("THE TYPES DO NOT MATCH") END;
          Op2("STW", 1, 0); sp := 0
          END
        ELSIF sKind[k] = kProc THEN
          IF sTyp[k] # 0 THEN Error("A FUNCTION: USE ITS VALUE") END;
          Call(k)
        ELSE Error("NOT A VARIABLE OR A PROCEDURE")
        END
      END
    ELSIF sym = sIf THEN
      Get; l2 := NewLab(); Cond; l1 := NewLab(); Jz(0, l1);
      Check(sThen, "THEN IS MISSING"); StatSeq; Jmp(l2); Here(l1);
      WHILE ~bad & (sym = sElsif) DO
        Get; sp := 0; Cond; l1 := NewLab(); Jz(0, l1); Check(sThen, "THEN IS MISSING"); StatSeq; Jmp(l2); Here(l1)
      END;
      IF sym = sElse THEN Get; StatSeq END;
      Here(l2); Check(sEnd, "END IS MISSING (IF)")
    ELSIF sym = sWhile THEN
      Get; l1 := NewLab(); l2 := NewLab(); Here(l1); Cond; Jz(0, l2);
      Check(sDo, "DO IS MISSING"); StatSeq; Jmp(l1); Here(l2); Check(sEnd, "END IS MISSING (WHILE)")
    ELSIF sym = sRepeat THEN
      Get; l1 := NewLab(); Here(l1); StatSeq; Check(sUntil, "UNTIL IS MISSING"); sp := 0; Cond; Jz(0, l1)
    ELSIF sym = sFor THEN
      Get;
      IF sym # sIdent THEN Error("A VARIABLE IS NEEDED") END;
      k := Find(id); Get;
      IF (k < 0) OR (sKind[k] < kVar) OR (sKind[k] > kVarPar) THEN Error("A VARIABLE IS NEEDED") END;
      Check(sBecomes, ":= IS MISSING");
      IF ~bad THEN
        Designator(k, t); Expression(t2); Op2("STW", 1, 0); sp := 0;
        Check(sTo, "TO IS MISSING");
        l1 := NewLab(); l2 := NewLab();
        Here(l1);
        Designator(k, t2); Op2("LDW", 0, 0); Expression(t2);   (* R0 = v, R1 = limit *)
        by := 1;
        IF sym = sBy THEN
          Get; up := TRUE;
          IF sym = sMinus THEN Get; up := FALSE END;
          IF sym # sNumber THEN Error("BY NEEDS A CONSTANT") ELSE by := val; IF ~up THEN by := -by END; Get END;
          IF by = 0 THEN Error("BY 0 NEVER ENDS") END
        END;
        IF by > 0 THEN Op2("LT", 1, 0) ELSE Op2("LT", 0, 1); Op2("MOV", 1, 0) END;   (* R1 = past the limit *)
        Jnz(1, l2); sp := 0;
        Check(sDo, "DO IS MISSING"); StatSeq;
        sp := 0; Designator(k, t2); r := Push(); Op2("LDW", 1, 0); r := Push(); Const(2, by); Op2("ADD", 1, 2); Op2("STW", 1, 0);
        sp := 0; Jmp(l1); Here(l2); Check(sEnd, "END IS MISSING (FOR)")
      END
    ELSIF sym = sCase THEN CaseStat
    END
  END Statement;

  PROCEDURE StatSeq0;
  BEGIN
    Statement;
    WHILE ~bad & (sym = sSemicolon) DO Get; Statement END
  END StatSeq0;

  (* ---------- declarations ---------- *)


  PROCEDURE Type(): INTEGER;
    VAR t, n, k, words, first, ft, i: INTEGER;
  BEGIN
    t := tInt;
    IF sym = sIdent THEN
      k := Find(id);
      IF (k >= 0) & (sKind[k] = kType) THEN t := sTyp[k] ELSE Error("UNKNOWN TYPE") END;
      Get
    ELSIF sym = sArray THEN
      Get; n := ConstExpr();
      IF n <= 0 THEN Error("THE LENGTH MUST BE MORE THAN 0") END;
      IF sym = sComma THEN sym := sArray; t := Type()   (* ARRAY n, m OF T = ARRAY n OF ARRAY m OF T *)
      ELSE Check(sOf, "OF IS MISSING"); t := Type()
      END;
      t := NewType(fArray, n, t)
    ELSIF sym = sRecord THEN
      Get; t := NewType(fRecord, 0, 0); words := 0;
      WHILE ~bad & (sym = sIdent) DO
        first := nf;
        REPEAT
          IF sym # sIdent THEN Error("A FIELD NAME IS MISSING")
          ELSIF nf >= NF THEN Error("TOO MANY FIELDS")
          ELSE Copy(id, fName[nf]); fOwn[nf] := t; INC(nf); Get
          END;
          IF sym = sComma THEN Get END
        UNTIL bad OR (sym = sColon);
        Get; ft := Type();
        FOR i := first TO nf - 1 DO fTyp[i] := ft; fOff[i] := words; words := words + tSize[ft] END;
        IF sym = sSemicolon THEN Get END
      END;
      tSize[t] := words; IF words = 0 THEN tSize[t] := 1 END;
      Check(sEnd, "END IS MISSING (RECORD)")
    ELSE Error("A TYPE IS NEEDED")
    END
    RETURN t
  END Type;

  PROCEDURE VarDecl(VAR words: INTEGER);   (* x, y: T; ... *)
    VAR first, k, t, i: INTEGER;
  BEGIN
    WHILE ~bad & (sym = sIdent) DO
      first := nsym;
      k := Declare(id, kVar); Get;
      WHILE sym = sComma DO Get; IF sym = sIdent THEN k := Declare(id, kVar); Get ELSE Error("A NAME IS MISSING") END END;
      Check(sColon, ": IS MISSING"); t := Type();
      FOR i := first TO nsym - 1 DO sTyp[i] := t; sAdr[i] := words; words := words + tSize[t] END;
      Check(sSemicolon, "; IS MISSING")
    END
  END VarDecl;

  PROCEDURE Declarations(VAR words: INTEGER);
    VAR k, t: INTEGER;
  BEGIN
    IF sym = sConst THEN
      Get;
      WHILE ~bad & (sym = sIdent) DO
        k := Declare(id, kConst); Get; Check(sEql, "= IS MISSING"); sVal[k] := ConstExpr();
        IF sVal[k] < 0 THEN sTyp[k] := tInt END;
        Check(sSemicolon, "; IS MISSING")
      END
    END;
    IF sym = sType THEN
      Get;
      WHILE ~bad & (sym = sIdent) DO
        k := Declare(id, kType); Get; Check(sEql, "= IS MISSING"); t := Type(); sTyp[k] := t;
        Check(sSemicolon, "; IS MISSING")
      END
    END;
    IF sym = sVar THEN Get; VarDecl(words) END
  END Declarations;

  PROCEDURE ProcDecl;
    VAR p, k, first, np, t, i, words: INTEGER; isVar: BOOLEAN;
  BEGIN
    Get;
    IF sym # sIdent THEN Error("THE PROCEDURE NEEDS A NAME") END;
    p := Declare(id, kProc); sTyp[p] := 0; Get;
    IF sym = sTimes THEN Get END;   (* exported: all the same here *)
    level := 1; nglob := nsym; np := 0; sFirst[p] := nsym;
    IF sym = sLparen THEN
      Get;
      WHILE ~bad & ((sym = sIdent) OR (sym = sVar)) DO
        isVar := sym = sVar; IF isVar THEN Get END;
        first := nsym;
        IF isVar THEN k := Declare(id, kVarPar) ELSE k := Declare(id, kPar) END; Get;
        WHILE sym = sComma DO
          Get; IF isVar THEN k := Declare(id, kVarPar) ELSE k := Declare(id, kPar) END; Get
        END;
        Check(sColon, ": IS MISSING");
        IF sym = sArray THEN   (* ARRAY OF T: an open array, by reference *)
          Get; Check(sOf, "OF IS MISSING"); t := Type(); t := NewType(fArray, 1000000, t)
        ELSE t := Type()
        END;
        FOR i := first TO nsym - 1 DO sTyp[i] := t; sAdr[i] := 1 + np; INC(np) END;
        IF sym = sSemicolon THEN Get ELSIF sym # sRparen THEN Error("; OR ) IS MISSING") END
      END;
      Check(sRparen, ") IS MISSING")
    END;
    sNp[p] := np;
    IF sym = sColon THEN Get; sTyp[p] := Type() END;
    Check(sSemicolon, "; IS MISSING");
    words := 1 + np;
    Declarations(words);
    IF sym = sProcedure THEN Error("PROCEDURES INSIDE PROCEDURES ARE NOT HERE YET") END;
    frame := words + TEMPS; spill := 0; curProc := p;
    A("P"); N(p); A(":"); Nl;
    IF sym = sBegin THEN Get; StatSeq END;
    IF sym = sReturn THEN
      Get; sp := 0; Expression(t);
      IF sTyp[p] = 0 THEN Error("A PROCEDURE WITHOUT A TYPE RETURNS NOTHING") END
    ELSIF sTyp[p] # 0 THEN Error("A FUNCTION NEEDS RETURN")
    END;
    Op2("LDW", 5, 5); A("RET"); Nl;
    Check(sEnd, "END IS MISSING (PROCEDURE)");
    IF (sym = sIdent) & ~Eq(id, sName[p]) THEN Error("THE NAME AFTER END IS NOT THE PROCEDURE'S") END;
    IF sym = sIdent THEN Get END;
    Check(sSemicolon, "; IS MISSING");
    (* the locals are forgotten, the parameters stay (for the calls) but cannot be found *)
    level := 0;
    FOR i := sFirst[p] TO nsym - 1 DO sName[i, 0] := 0X END;   (* the calls find the parameters by number *)
    nglob := nsym
  END ProcDecl;

  PROCEDURE Module;
    VAR main: INTEGER;
  BEGIN
    Get; Check(sModule, "MODULE IS MISSING");
    IF sym = sIdent THEN Get ELSE Error("THE MODULE NEEDS A NAME") END;
    Check(sSemicolon, "; IS MISSING");
    IF sym = sImport THEN
      Get;
      WHILE sym = sIdent DO
        IF ~(Eq(id, "Out") OR Eq(id, "Tor") OR Eq(id, "Screen") OR Eq(id, "Touch") OR Eq(id, "Sound")) THEN
          Error("ONLY Out, Tor, Screen, Touch, Sound CAN BE IMPORTED")
        END;
        Get; IF sym = sComma THEN Get END
      END;
      Check(sSemicolon, "; IS MISSING")
    END;
    level := 0; gWords := 0;
    Declarations(gWords);
    IF 12 * gWords > TURN - 20000 THEN Error("THE GLOBAL VARIABLES DO NOT FIT IN THE TURN") END;
    (* the start: the frame of the module body comes after the globals, the stack grows up to the end of the turn *)
    A("GLOB R5"); Nl; IF gWords > 0 THEN Const(4, 12 * gWords); Op2("ADD", 5, 4) END; A("JMP MAIN"); Nl;
    WHILE ~bad & (sym = sProcedure) DO ProcDecl END;
    main := 0;
    frame := 1 + TEMPS; spill := 0; curProc := -1;
    A("MAIN:"); Nl;
    IF sym = sBegin THEN Get; StatSeq END;
    A("STOP"); Nl;
    Check(sEnd, "END IS MISSING (MODULE)");
    IF sym = sIdent THEN Get END;
    Check(sPeriod, "THE MODULE ENDS WITH A DOT")
  END Module;

  PROCEDURE Compile*(name: ARRAY OF CHAR): BOOLEAN;   (* the Oberon file -> asm; FALSE = err, errLine *)
    VAR h, b: INTEGER; nm: ARRAY 12 OF CHAR;
  BEGIN
    bad := FALSE; err[0] := 0X; errLine := 0; nasm := 0; asm[0] := 0X; gWords := 0;
    nsrc := 0; h := Fisier.Deschide(name);
    IF h < 0 THEN Error("NO SUCH FILE")
    ELSE
      b := Fisier.Citeste(h);
      WHILE (b >= 0) & (nsrc < SRC - 1) DO src[nsrc] := CHR(b); INC(nsrc); b := Fisier.Citeste(h) END;
      Fisier.Gata(h);
      pos := 0; line := 1; Next;
      nsym := 0; ntyp := 0; level := 0; labels := 0; sp := 0; nf := 0;
      tInt := NewType(0, 0, 0);   (* type 0 = no type (a procedure that is not a function) *)
      tInt := NewType(fInt, 0, 0); tBool := NewType(fBool, 0, 0); tChar := NewType(fChar, 0, 0);
      nm := "INTEGER"; Builtin(nm, tInt); nm := "BOOLEAN"; Builtin(nm, tBool); nm := "CHAR"; Builtin(nm, tChar);
      nm := "BYTE"; Builtin(nm, tInt);
      nglob := nsym;
      Expression := Expression0; StatSeq := StatSeq0;
      Module
    END
    RETURN ~bad
  END Compile;

END Ob2.
