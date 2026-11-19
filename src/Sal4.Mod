MODULE Sal4;  (* SALAMANDRA 4 (11 Nov 2026): Oberon is compiled by Ob2 (RECORD, CASE, Sound); the device is Scr2 (screen,
     touch and sound); the files are in Cubicum FS 2 (7 dimensions).
   SALAMANDRA 3 (11 Nov 2026): the device in the 11th dimension. LD, ST, LDW, STW at an address from Scr2.IO up
     go to the screen and the touch (module Scr1), not to the cells. After Show the process sleeps until the next frame.
     Oberon is compiled by Ob1 (with Screen and Touch).
   SALAMANDRA 2 (11 Nov 2026): runs Oberon too. A .mod file is compiled by Ob0 (Oberon-0 for Tor7) into
     Tor7 assembly, then assembled into the cells like a .z7. RUN name looks for name, name.mod, name.z7 (in this order).
     Compile errors go into the shell and the Ash. Assemble(name, out) writes the assembly into a file, to look at it.
     Room for bigger programs: 8000 instructions (the compiler writes a lot of small ones).
   SALAMANDRA 1 (11 Nov 2026): the Tor7 processor of Cubicum N - the kernel that runs programs on the torus.
     The same machine as in Cubicum OS 3 (v2.5, 49 instructions in 7 groups), now on Tor11 (11 dimensions), in OLL.
     7 processes, one on each turn of the spiral (turn s = cells s * 7^6 .. (s+1) * 7^6 - 1 of the dense torus).
     The code lives in the cells: one instruction = 4 cells (op DIV 7, op MOD 7, a, b), registers R0..R6.
     A program (.z7) is text: one instruction per line (or separated by ;), # comment, label: name.
     Names are English; the old Romanian names still work (in brackets), so old .z7 programs run unchanged.
       0 Data      SET DIG MOV LD ST NOTEC(NOTAC)
       1 Arith     ADD SUB MUL DIV MOD INC DEC
       2 Jumps     LT EQ JMP JZ JNZ CALL RET
       3 Space     LDW STW STEP COORD FIELD(CAMP) WAIT(ASTEAPTA) BASE(BAZA)
                   STEP Ra, Rb: address Ra one step on dimension Rb = 0..10 (11 dimensions!); Rb = -(d+1) one step back
                   COORD Ra, Rb: Ra := coordinate Rb (0..10) of address Ra, as 1..7
       4 Nephilim  NEPH(NEF) SETNEPH(PUNENEF) CORNER(COLT) EMIT(EMITE) LISTEN(ASCULTA) PLAYC(CANTA) NOTE(NOTA)
       5 Time      OPAL SYS(SIST) ASH SLEEP(DORMI) PRINT(SCRIE) PRINTC(SCRIEC) PRINTN(SCRIEN)
                   SYS forms: NOP, TURN Ra, PID Ra Rb, FROM Ra, TIME Ra, STATUS Ra Rb, CLOCK Ra Rb
                   (TURA PID DELA TIMP STARE CEAS)
       6 Process   SEND(TRIMITE) RECV(PRIMESTE) NEIGHBOR(VECIN) SPAWN(PORN) KILL(OPR) STOP YIELD(CEDEAZA)
     Salamandra in the processor: an error goes into the Ash (ash.txt), the turn burns and the program starts again from
     the Egg (read again from its file); after 7 restarts, the 8th error stops it.
     Pion & Claude, 11.11.2026 *)

  IMPORT Ceas, Fisier, Tor11, Synth9, Fs2, Ob2, Scr2;

  CONST NP* = 7; NQ = 64; NO = 49; NS = 8000; NE = 4000; NR = 49; MaxFall = 7; Slice = 64; NI = 80; LL = 44; TXT = 160000;
    oSYS = 36; oMOV = 3;
    Free* = 0; Active* = 1; Senses* = 2; Receives* = 3; Sleeps* = 4;

  TYPE Tok = ARRAY 5, 24 OF CHAR;
    Proc = RECORD
      name: ARRAY 32 OF CHAR;
      pid, state, pc, len, seenW, wake, lastNote, steps, falls, from, nq, nrs: INTEGER;
      r: ARRAY 7 OF INTEGER;
      qv, qs: ARRAY NQ OF INTEGER;
      rs: ARRAY NR OF INTEGER;
      line: ARRAY LL OF CHAR; nline: INTEGER
    END;

  VAR p: ARRAY NP OF Proc; nextPid, rr: INTEGER;
    outL: ARRAY NI, 64 OF CHAR; outC: ARRAY NI OF INTEGER; nout: INTEGER;
    ash: ARRAY 49, LL OF CHAR; nash, ashTotal: INTEGER;
    en, ro: ARRAY NO, 12 OF CHAR; kind: ARRAY NO OF INTEGER;
    z7: ARRAY 7 OF REAL;
    sOp, sA, sB, sImm, sSize, sAdr, sPre: ARRAY NS OF INTEGER; sLab: ARRAY NS, 16 OF CHAR; ns: INTEGER;
    eName: ARRAY NE, 16 OF CHAR; eAt: ARRAY NE OF INTEGER; ne: INTEGER;
    text: ARRAY TXT OF CHAR;
    m: ARRAY 120 OF CHAR; mn: INTEGER;   (* the message being built *)

  (* ---------- text ---------- *)

  PROCEDURE Clr; BEGIN mn := 0; m[0] := 0X END Clr;

  PROCEDURE Add(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (mn < LEN(m) - 1) DO m[mn] := s[i]; INC(mn); INC(i) END;
    m[mn] := 0X
  END Add;

  PROCEDURE AddN(n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN Add("-"); IF n = -2147483647 - 1 THEN n := 2147483647 ELSE n := -n END END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE (k > 0) & (mn < LEN(m) - 1) DO DEC(k); m[mn] := d[k]; INC(mn) END;
    m[mn] := 0X
  END AddN;

  PROCEDURE Copy(a: ARRAY OF CHAR; VAR b: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(a)) & (i < LEN(b) - 1) & (a[i] # 0X) DO b[i] := a[i]; INC(i) END;
    b[i] := 0X
  END Copy;

  PROCEDURE Eq(a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END
    RETURN ((i = LEN(a)) OR (a[i] = 0X)) & ((i = LEN(b)) OR (b[i] = 0X))
  END Eq;

  PROCEDURE Say(c: INTEGER);   (* the message in m goes to the shell; c = colour: 0 normal, 1 good, 2 bad *)
    VAR i: INTEGER;
  BEGIN
    IF nout = NI THEN FOR i := 1 TO NI - 1 DO outL[i - 1] := outL[i]; outC[i - 1] := outC[i] END; DEC(nout) END;
    Copy(m, outL[nout]); outC[nout] := c; INC(nout)
  END Say;

  PROCEDURE Lines*(): INTEGER; BEGIN RETURN nout END Lines;
  PROCEDURE Line*(k: INTEGER; VAR s: ARRAY OF CHAR; VAR c: INTEGER); BEGIN Copy(outL[k], s); c := outC[k] END Line;
  PROCEDURE Taken*; BEGIN nout := 0 END Taken;

  PROCEDURE SaveAsh;
    VAR h, i, j: INTEGER;
  BEGIN
    h := Fisier.Creeaza("ash.txt");
    IF h >= 0 THEN
      FOR i := 0 TO nash - 1 DO
        j := 0; WHILE (j < LL) & (ash[i, j] # 0X) DO Fisier.Scrie(h, ORD(ash[i, j])); INC(j) END;
        Fisier.Scrie(h, 10)
      END;
      Fisier.Gata(h); IF Fs2.Add("ash.txt") >= 0 THEN END
    END
  END SaveAsh;

  PROCEDURE ToAsh;   (* the message in m goes into the Ash too (it survives every burn) *)
    VAR i: INTEGER;
  BEGIN
    IF nash = 49 THEN FOR i := 1 TO 48 DO ash[i - 1] := ash[i] END; DEC(nash) END;
    Copy(m, ash[nash]); INC(nash); INC(ashTotal); SaveAsh
  END ToAsh;

  PROCEDURE AshLines*(): INTEGER; BEGIN RETURN nash END AshLines;
  PROCEDURE AshLine*(k: INTEGER; VAR s: ARRAY OF CHAR); BEGIN Copy(ash[k], s) END AshLine;

  (* ---------- the assembler ---------- *)

  PROCEDURE Cap(VAR w: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(w)) & (w[i] # 0X) DO IF (w[i] >= "a") & (w[i] <= "z") THEN w[i] := CHR(ORD(w[i]) - 32) END; INC(i) END
  END Cap;

  PROCEDURE Reg(w: ARRAY OF CHAR): INTEGER;
    VAR r: INTEGER;
  BEGIN
    r := -1;
    IF ((w[0] = "R") OR (w[0] = "r")) & (w[1] >= "0") & (w[1] <= "6") & (w[2] = 0X) THEN r := ORD(w[1]) - ORD("0") END
    RETURN r
  END Reg;

  PROCEDURE Num(w: ARRAY OF CHAR): INTEGER;   (* decimal >= 0, else -1 *)
    VAR i, n: INTEGER;
  BEGIN
    n := 0; i := 0; IF w[0] = 0X THEN n := -1 END;
    WHILE (n >= 0) & (i < LEN(w)) & (w[i] # 0X) DO
      IF (w[i] >= "0") & (w[i] <= "9") & (n < 100000000) THEN n := n * 10 + ORD(w[i]) - ORD("0") ELSE n := -1 END;
      INC(i)
    END
    RETURN n
  END Num;

  PROCEDURE Digits(n: INTEGER): INTEGER;
    VAR c: INTEGER;
  BEGIN c := 1; WHILE n >= 7 DO n := n DIV 7; INC(c) END
    RETURN c
  END Digits;

  PROCEDURE Put(base, k, op, a, b: INTEGER);
  BEGIN
    k := base + k * 4;
    Tor11.Write(k, op DIV 7); Tor11.Write(k + 1, op MOD 7); Tor11.Write(k + 2, a); Tor11.Write(k + 3, b)
  END Put;

  PROCEDURE PutNum(base: INTEGER; VAR k: INTEGER; r, n, c: INTEGER);   (* Ra := n in c instructions: SET + DIGs *)
    VAR d: ARRAY 12 OF INTEGER; j: INTEGER;
  BEGIN
    FOR j := 0 TO c - 1 DO d[j] := n MOD 7; n := n DIV 7 END;
    Put(base, k, 1, r, d[c - 1]); INC(k);
    FOR j := c - 2 TO 0 BY -1 DO Put(base, k, 2, r, d[j]); INC(k) END
  END PutNum;

  PROCEDURE Wrong(name: ARRAY OF CHAR; line: INTEGER; what, w: ARRAY OF CHAR);
  BEGIN
    Clr; Add(name); Add(" LINE "); AddN(line); Add(": "); Add(what); Add(" "); Add(w); Say(2); ToAsh
  END Wrong;

  PROCEDURE Instr(name: ARRAY OF CHAR; line: INTEGER; VAR tk: Tok; nt: INTEGER): BOOLEAN;
    VAR op, f, a, b, k: INTEGER; ok: BOOLEAN; w: ARRAY 24 OF CHAR;
  BEGIN
    ok := TRUE; Copy(tk[0], w); Cap(w);
    op := -1; k := 1;
    WHILE (op < 0) & (k < NO) DO IF Eq(en[k], w) OR Eq(ro[k], w) THEN op := k END; INC(k) END;
    sPre[ns] := -1; f := -1;
    IF Eq(w, "NOP") THEN f := 6 ELSIF Eq(w, "TURN") OR Eq(w, "TURA") THEN f := 0 ELSIF Eq(w, "FROM") OR Eq(w, "DELA") THEN f := 2
    ELSIF Eq(w, "TIME") OR Eq(w, "TIMP") THEN f := 3 ELSIF Eq(w, "PID") THEN f := 11
    ELSIF Eq(w, "STATUS") OR Eq(w, "STARE") THEN f := 14 ELSIF Eq(w, "CLOCK") OR Eq(w, "CEAS") THEN f := 15
    END;
    IF f >= 0 THEN
      sLab[ns, 0] := 0X; sImm[ns] := -1; sSize[ns] := 1; a := 0; b := f MOD 10;
      IF (f = 6) & (nt # 1) OR (f < 6) & (nt # 2) OR (f > 10) & (nt # 3) THEN Wrong(name, line, "WRONG OPERANDS FOR", tk[0]); ok := FALSE
      ELSIF f # 6 THEN
        a := Reg(tk[1]);
        IF a < 0 THEN Wrong(name, line, "REGISTER R0..R6, NOT", tk[1]); ok := FALSE
        ELSIF f > 10 THEN
          k := Reg(tk[2]);
          IF k < 0 THEN Wrong(name, line, "REGISTER R0..R6, NOT", tk[2]); ok := FALSE
          ELSIF k # a THEN sPre[ns] := k; sSize[ns] := 2
          END
        END
      END;
      IF ok THEN sOp[ns] := oSYS; sA[ns] := a; sB[ns] := b; INC(ns) END
    ELSIF op < 0 THEN Wrong(name, line, "UNKNOWN INSTRUCTION", tk[0]); ok := FALSE
    ELSE
      f := kind[op]; a := 0; b := 0; sLab[ns, 0] := 0X; sImm[ns] := -1; sSize[ns] := 1;
      IF (f = 0) & (nt # 1) OR (f = 1) & (nt # 2) OR (f = 5) & (nt # 2) OR (f >= 2) & (f # 5) & (nt # 3) THEN
        Wrong(name, line, "WRONG OPERANDS FOR", tk[0]); ok := FALSE
      ELSIF f = 0 THEN
      ELSIF f = 5 THEN
        a := Reg(tk[1]); IF a < 0 THEN Copy(tk[1], sLab[ns]); a := 6; sSize[ns] := 6 END
      ELSE
        a := Reg(tk[1]);
        IF a < 0 THEN Wrong(name, line, "REGISTER R0..R6, NOT", tk[1]); ok := FALSE
        ELSIF f = 2 THEN b := Reg(tk[2]); IF b < 0 THEN Wrong(name, line, "REGISTER R0..R6, NOT", tk[2]); ok := FALSE END
        ELSIF f = 3 THEN b := Num(tk[2]); IF (b < 0) OR (b > 6) THEN Wrong(name, line, "A DIGIT 0..6, NOT", tk[2]); ok := FALSE END
        ELSIF f = 4 THEN
          b := Num(tk[2]);
          IF b >= 0 THEN sImm[ns] := b; sSize[ns] := Digits(b) ELSE Copy(tk[2], sLab[ns]); sSize[ns] := 5 END
        ELSIF f = 6 THEN
          b := Reg(tk[2]); IF b < 0 THEN Copy(tk[2], sLab[ns]); b := 6; sSize[ns] := 6 END
        END
      END;
      IF ok THEN sOp[ns] := op; sA[ns] := a; sB[ns] := b; INC(ns) END
    END
    RETURN ok
  END Instr;

  PROCEDURE Assemble(name: ARRAY OF CHAR; base: INTEGER): INTEGER;   (* the program in text -> cells; instructions, -1 = error *)
    VAR i, j, k, nt, n, adr, e, line: INTEGER; ok, com: BOOLEAN; st: ARRAY 160 OF CHAR; tk: Tok;
      w: ARRAY 24 OF CHAR; ch: CHAR;
  BEGIN
    ns := 0; ne := 0; ok := TRUE; i := 0; line := 1;
    WHILE ok & (i < TXT) & (text[i] # 0X) DO
      j := 0; com := FALSE;
      WHILE (i < TXT) & (text[i] # 0X) & (text[i] # ";") & (text[i] # 0AX) & (text[i] # 0DX) DO
        IF text[i] = "#" THEN com := TRUE END;
        IF ~com & (j < LEN(st) - 1) THEN st[j] := text[i]; INC(j) END;
        INC(i)
      END;
      st[j] := 0X;
      IF (i < TXT) & (text[i] = 0AX) THEN INC(line) END;
      IF (i < TXT) & (text[i] # 0X) THEN INC(i) END;
      nt := 0; j := 0;
      WHILE ok & (st[j] # 0X) DO
        ch := st[j];
        IF (ch = " ") OR (ch = ",") OR (ch = 9X) OR (ch = ":") THEN INC(j)
        ELSE
          k := 0;
          WHILE (st[j] # 0X) & (st[j] # " ") & (st[j] # ",") & (st[j] # 9X) & (st[j] # ":") DO
            IF k < LEN(w) - 1 THEN w[k] := st[j]; INC(k) END; INC(j)
          END;
          w[k] := 0X;
          IF st[j] = ":" THEN
            IF ne < NE THEN Copy(w, eName[ne]); eAt[ne] := ns; INC(ne) END
          ELSIF nt < 4 THEN Copy(w, tk[nt]); INC(nt)
          ELSE Wrong(name, line, "TOO MANY OPERANDS AFTER", tk[0]); ok := FALSE
          END
        END
      END;
      IF ok & (nt > 0) THEN
        IF ns >= NS THEN Wrong(name, line, "PROGRAM TOO LONG", ""); ok := FALSE ELSE ok := Instr(name, line, tk, nt) END
      END
    END;
    adr := 0;
    FOR k := 0 TO ns - 1 DO sAdr[k] := adr; adr := adr + sSize[k] END;
    n := adr;
    IF n * 4 > Tor11.Turn THEN Wrong(name, line, "DOES NOT FIT IN A TURN", ""); ok := FALSE END;
    k := 0; i := 0;
    WHILE ok & (i < ns) DO
      IF sLab[i, 0] # 0X THEN
        e := -1; j := 0;
        WHILE (e < 0) & (j < ne) DO IF Eq(eName[j], sLab[i]) THEN e := j END; INC(j) END;
        IF e < 0 THEN Wrong(name, 0, "NO SUCH LABEL", sLab[i]); ok := FALSE
        ELSE
          IF eAt[e] < ns THEN adr := sAdr[eAt[e]] ELSE adr := n END;
          IF kind[sOp[i]] = 4 THEN PutNum(base, k, sA[i], adr, 5)
          ELSE PutNum(base, k, 6, adr, 5); Put(base, k, sOp[i], sA[i], sB[i]); INC(k)
          END
        END
      ELSIF sImm[i] >= 0 THEN PutNum(base, k, sA[i], sImm[i], sSize[i])
      ELSE
        IF sPre[i] >= 0 THEN Put(base, k, oMOV, sA[i], sPre[i]); INC(k) END;
        Put(base, k, sOp[i], sA[i], sB[i]); INC(k)
      END;
      INC(i)
    END;
    IF ~ok THEN n := -1 END
    RETURN n
  END Assemble;

  PROCEDURE Load(name: ARRAY OF CHAR): BOOLEAN;   (* the file into text *)
    VAR h, b, i: INTEGER;
  BEGIN
    h := Fisier.Deschide(name); i := 0;
    IF h >= 0 THEN
      b := Fisier.Citeste(h);
      WHILE (b >= 0) & (i < TXT - 1) DO text[i] := CHR(b); INC(i); b := Fisier.Citeste(h) END;
      Fisier.Gata(h)
    END;
    text[i] := 0X
    RETURN h >= 0
  END Load;

  PROCEDURE IsMod(name: ARRAY OF CHAR): BOOLEAN;   (* ends with .mod (any letters) *)
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(name)) & (name[i] # 0X) DO INC(i) END
    RETURN (i > 4) & (name[i - 4] = ".") & ((name[i - 3] = "m") OR (name[i - 3] = "M"))
      & ((name[i - 2] = "o") OR (name[i - 2] = "O")) & ((name[i - 1] = "d") OR (name[i - 1] = "D"))
  END IsMod;

  PROCEDURE Source(name: ARRAY OF CHAR): BOOLEAN;   (* the program as assembly in text: read, or compiled from Oberon *)
    VAR ok: BOOLEAN; i: INTEGER;
  BEGIN
    IF IsMod(name) THEN
      ok := Ob2.Compile(name);
      IF ok THEN
        i := 0; WHILE (i < TXT - 1) & (Ob2.asm[i] # 0X) DO text[i] := Ob2.asm[i]; INC(i) END; text[i] := 0X
      ELSE Clr; Add(name); Add(" LINE "); AddN(Ob2.errLine); Add(": "); Add(Ob2.err); Say(2); ToAsh
      END
    ELSE
      ok := Load(name);
      IF ~ok THEN Clr; Add("KERNEL: NO FILE "); Add(name); Say(2) END
    END
    RETURN ok
  END Source;

  PROCEDURE Compile(s: INTEGER; name: ARRAY OF CHAR): INTEGER;
    VAR n: INTEGER;
  BEGIN
    IF Source(name) THEN n := Assemble(name, s * Tor11.Turn) ELSE n := -1 END
    RETURN n
  END Compile;

  PROCEDURE Translate*(name, out: ARRAY OF CHAR): BOOLEAN;   (* the Oberon file -> its Tor7 assembly, in file out *)
    VAR h, i: INTEGER; ok: BOOLEAN;
  BEGIN
    ok := Source(name);
    IF ok THEN
      h := Fisier.Creeaza(out);
      IF h >= 0 THEN
        i := 0; WHILE (i < TXT) & (text[i] # 0X) DO Fisier.Scrie(h, ORD(text[i])); INC(i) END;
        Fisier.Gata(h); IF Fs2.Add(out) >= 0 THEN END
      ELSE ok := FALSE
      END
    END
    RETURN ok
  END Translate;

  (* ---------- processes ---------- *)

  PROCEDURE Fresh(s: INTEGER);
    VAR k: INTEGER;
  BEGIN
    p[s].pc := 0; p[s].nq := 0; p[s].nrs := 0; p[s].steps := 0; p[s].lastNote := -1000; p[s].wake := 0;
    p[s].seenW := Tor11.Writes(); FOR k := 0 TO 6 DO p[s].r[k] := 0 END;
    p[s].from := -1; p[s].nline := 0; p[s].line[0] := 0X
  END Fresh;

  PROCEDURE Who(s: INTEGER);   (* "[name] " *)
  BEGIN Clr; Add("["); Add(p[s].name); Add("] ")
  END Who;

  PROCEDURE Fall(s: INTEGER; what: ARRAY OF CHAR);   (* an error: Ash, the turn burns, the program starts again from the Egg *)
    VAR n: INTEGER;
  BEGIN
    Clr; Add(p[s].name); Add(": "); Add(what); ToAsh;
    Who(s); Add("FELL: "); Add(what); Say(2);
    INC(p[s].falls);
    IF p[s].falls > MaxFall THEN
      Who(s); Add("FELL "); AddN(p[s].falls); Add(" TIMES: SALAMANDRA STOPS IT"); Say(2);
      p[s].state := Free
    ELSE
      Tor11.BurnTurn(s);
      n := Compile(s, p[s].name);
      IF n < 0 THEN p[s].state := Free
      ELSE
        p[s].len := n; Fresh(s); p[s].state := Active;
        Who(s); Add("TURN "); AddN(s + 1); Add(" BURNS, FROM THE EGG ("); AddN(p[s].falls); Add(")"); Say(1)
      END
    END
  END Fall;

  PROCEDURE Neighbor(s: INTEGER): INTEGER;
    VAR k, r, t: INTEGER;
  BEGIN
    r := s; k := 1;
    WHILE (r = s) & (k < NP) DO
      t := (s + k) MOD NP;
      IF (p[t].state # Free) & Eq(p[t].name, p[s].name) THEN r := t END;
      INC(k)
    END
    RETURN r
  END Neighbor;

  PROCEDURE Send(s, t, v: INTEGER);
  BEGIN
    IF (p[t].state # Free) & (p[t].nq < NQ) THEN p[t].qv[p[t].nq] := v; p[t].qs[p[t].nq] := s; INC(p[t].nq) END
  END Send;

  PROCEDURE Flush(s: INTEGER);
  BEGIN Who(s); Add(p[s].line); Say(0); p[s].nline := 0; p[s].line[0] := 0X
  END Flush;

  PROCEDURE PutC(s, ch: INTEGER);
  BEGIN
    IF (ch = 10) OR (ch = 32) & (p[s].nline >= 26) THEN Flush(s); ch := 0   (* a long line breaks at a space *)
    ELSIF p[s].nline >= 32 THEN Flush(s)
    END;
    IF (ch >= 32) & (ch < 127) THEN p[s].line[p[s].nline] := CHR(ch); INC(p[s].nline); p[s].line[p[s].nline] := 0X END
  END PutC;

  PROCEDURE Busy*(): BOOLEAN;   (* some process is alive *)
    VAR s: INTEGER; b: BOOLEAN;
  BEGIN b := FALSE; FOR s := 0 TO NP - 1 DO IF p[s].state # Free THEN b := TRUE END END
    RETURN b
  END Busy;

  PROCEDURE Start*(name: ARRAY OF CHAR): INTEGER;   (* the program into a free turn; -1 = no *)
    VAR s, k, n: INTEGER; nm: ARRAY 32 OF CHAR;
  BEGIN
    Copy(name, nm);
    IF ~Fs2.Exists(nm) THEN
      k := 0; WHILE nm[k] # 0X DO INC(k) END;
      IF k < 27 THEN
        nm[k] := "."; nm[k + 1] := "m"; nm[k + 2] := "o"; nm[k + 3] := "d"; nm[k + 4] := 0X;
        IF ~Fs2.Exists(nm) THEN nm[k + 1] := "z"; nm[k + 2] := "7"; nm[k + 3] := 0X END
      END
    END;
    IF ~Busy() THEN Scr2.Reset END;   (* alone: a clean canvas *)
    s := -1; k := 0;
    WHILE (s < 0) & (k < NP) DO IF p[k].state = Free THEN s := k END; INC(k) END;
    IF s < 0 THEN Clr; Add("KERNEL: ALL 7 TURNS ARE BUSY (PS, KILL N)"); Say(2)
    ELSE
      n := Compile(s, nm);
      IF n < 0 THEN s := -1
      ELSE
        Copy(nm, p[s].name); p[s].len := n; p[s].falls := 0; p[s].pid := nextPid; INC(nextPid);
        Fresh(s); p[s].state := Active;
        Clr; Add("KERNEL: "); Add(nm); Add(" ON TURN "); AddN(s + 1); Add(", "); AddN(n); Add(" INSTRUCTIONS"); Say(1)
      END
    END
    RETURN s
  END Start;

  PROCEDURE Kill*(s: INTEGER);
  BEGIN
    IF (s >= 0) & (s < NP) & (p[s].state # Free) THEN
      IF p[s].nline > 0 THEN Flush(s) END;
      Who(s); Add("STOPPED"); Say(0); p[s].state := Free
    END
  END Kill;

  PROCEDURE Hz(a, b: INTEGER): REAL;
    VAR k: INTEGER; f: REAL;
  BEGIN f := z7[a MOD 7]; FOR k := 1 TO b MOD 3 DO f := f * 2.0 END
    RETURN f
  END Hz;

  PROCEDURE Step(s, now: INTEGER): BOOLEAN;   (* one instruction; FALSE = the slice of process s ends here *)
    VAR op, a, b, k, va, vb: INTEGER; cont: BOOLEAN; d: ARRAY 11 OF INTEGER; nm: ARRAY 32 OF CHAR;
  BEGIN
    cont := TRUE;
    IF (p[s].pc < 0) OR (p[s].pc >= p[s].len) THEN Fall(s, "WENT OUT OF THE PROGRAM"); cont := FALSE
    ELSE
      k := s * Tor11.Turn + p[s].pc * 4;
      op := Tor11.Read(k) MOD 7 * 7 + Tor11.Read(k + 1) MOD 7; a := Tor11.Read(k + 2) MOD 7; b := Tor11.Read(k + 3) MOD 7;
      INC(p[s].pc); INC(p[s].steps); Tor11.Beat;
      va := p[s].r[a]; vb := p[s].r[b];
      CASE op DIV 7 OF
      0:
        IF op = 0 THEN DEC(p[s].pc); Fall(s, "AN EMPTY CELL IS NOT AN INSTRUCTION"); cont := FALSE
        ELSIF op = 1 THEN p[s].r[a] := b
        ELSIF op = 2 THEN p[s].r[a] := va * 7 + b
        ELSIF op = 3 THEN p[s].r[a] := vb
        ELSIF op = 4 THEN IF Scr2.Is(vb) THEN p[s].r[a] := Scr2.Read(vb) ELSE p[s].r[a] := Tor11.Read(vb) END
        ELSIF op = 5 THEN
          IF Scr2.Is(vb) THEN IF Scr2.Write(vb, va) THEN p[s].state := Sleeps; p[s].wake := now + 15; cont := FALSE END
          ELSE Tor11.Write(vb, va); cont := FALSE
          END
        ELSE p[s].r[a] := Tor11.Degree(vb)
        END
      | 1:
        IF op = 7 THEN p[s].r[a] := va + vb
        ELSIF op = 8 THEN p[s].r[a] := va - vb
        ELSIF op = 9 THEN p[s].r[a] := va * vb
        ELSIF op = 10 THEN IF vb = 0 THEN Fall(s, "DIV BY 0"); cont := FALSE ELSIF vb > 0 THEN p[s].r[a] := va DIV vb ELSE p[s].r[a] := -va DIV (-vb) END
        ELSIF op = 11 THEN IF vb = 0 THEN Fall(s, "MOD BY 0"); cont := FALSE ELSIF vb > 0 THEN p[s].r[a] := va MOD vb ELSE p[s].r[a] := -((-va) MOD (-vb)) END
        ELSIF op = 12 THEN p[s].r[a] := va + 1
        ELSE p[s].r[a] := va - 1
        END
      | 2:
        IF op = 14 THEN IF va < vb THEN p[s].r[a] := 1 ELSE p[s].r[a] := 0 END
        ELSIF op = 15 THEN IF va = vb THEN p[s].r[a] := 1 ELSE p[s].r[a] := 0 END
        ELSIF op = 16 THEN p[s].pc := va
        ELSIF op = 17 THEN IF va = 0 THEN p[s].pc := vb END
        ELSIF op = 18 THEN IF va # 0 THEN p[s].pc := vb END
        ELSIF op = 19 THEN
          IF p[s].nrs >= NR THEN Fall(s, "CALL TOO DEEP (49)"); cont := FALSE
          ELSE p[s].rs[p[s].nrs] := p[s].pc; INC(p[s].nrs); p[s].pc := va
          END
        ELSE
          IF p[s].nrs = 0 THEN Fall(s, "RET WITHOUT CALL"); cont := FALSE
          ELSE DEC(p[s].nrs); p[s].pc := p[s].rs[p[s].nrs]
          END
        END
      | 3:
        IF op = 21 THEN IF Scr2.Is(vb) THEN p[s].r[a] := Scr2.Read(vb) ELSE p[s].r[a] := Tor11.Word(vb) END
        ELSIF op = 22 THEN
          IF Scr2.Is(vb) THEN IF Scr2.Write(vb, va) THEN p[s].state := Sleeps; p[s].wake := now + 15; cont := FALSE END
          ELSE Tor11.PutWord(vb, va); cont := FALSE
          END
        ELSIF op = 23 THEN p[s].r[a] := Tor11.Step(va, vb)
        ELSIF op = 24 THEN Tor11.Coord(va, d); p[s].r[a] := d[vb MOD 11] + 1
        ELSIF op = 25 THEN p[s].r[a] := Tor11.Field(); p[s].seenW := Tor11.Writes()
        ELSIF op = 26 THEN
          IF Tor11.Writes() > p[s].seenW THEN p[s].seenW := Tor11.Writes()
          ELSE DEC(p[s].pc); p[s].state := Senses; cont := FALSE
          END
        ELSE p[s].r[a] := s * Tor11.Turn
        END
      | 4:
        IF op = 28 THEN p[s].r[a] := Tor11.State(vb)
        ELSIF op = 29 THEN Tor11.Combine(vb, va)
        ELSIF op = 30 THEN Tor11.SetCorner(va)
        ELSIF op = 31 THEN p[s].r[a] := Tor11.Emit(va, vb); cont := FALSE
        ELSIF op = 32 THEN
          IF vb < 0 THEN p[s].r[a] := Tor11.Remember(-vb - 1) ELSE p[s].r[a] := Tor11.Listen(vb) END; cont := FALSE
        ELSIF (op = 33) OR (op = 34) THEN
          IF now >= p[s].lastNote + 120 THEN
            IF op = 33 THEN Synth9.NoteHz(Tor11.Hz(Tor11.Degree(va)), 400) ELSE Synth9.NoteHz(Hz(va, vb), 400) END;
            p[s].lastNote := now
          ELSE DEC(p[s].pc); p[s].state := Sleeps; p[s].wake := p[s].lastNote + 120; cont := FALSE
          END
        END
      | 5:
        IF op = 35 THEN p[s].r[a] := Tor11.Opal(vb)
        ELSIF op = 36 THEN
          IF b = 0 THEN p[s].r[a] := s
          ELSIF b = 1 THEN IF (va >= 0) & (va < NP) & (p[va].state # Free) THEN p[s].r[a] := p[va].pid ELSE p[s].r[a] := 0 END
          ELSIF b = 2 THEN p[s].r[a] := p[s].from
          ELSIF b = 3 THEN p[s].r[a] := now
          ELSIF b = 4 THEN IF (va >= 0) & (va < NP) THEN p[s].r[a] := p[va].state ELSE p[s].r[a] := 0 END
          ELSIF b = 5 THEN
            IF va = 0 THEN p[s].r[a] := Tor11.Cycle() ELSIF va = 1 THEN p[s].r[a] := Tor11.BeatInHour()
            ELSIF va = 3 THEN p[s].r[a] := Tor11.Burns() ELSE p[s].r[a] := Tor11.Beats() END
          END
        ELSIF op = 37 THEN p[s].r[a] := p[s].falls
        ELSIF op = 38 THEN IF va > 0 THEN p[s].wake := now + va; p[s].state := Sleeps; cont := FALSE END
        ELSIF op = 39 THEN Who(s); AddN(va); Say(0)
        ELSIF op = 40 THEN PutC(s, va)
        ELSE Clr; AddN(va); Copy(m, nm); k := 0; WHILE nm[k] # 0X DO PutC(s, ORD(nm[k])); INC(k) END   (* nm: PutC may reuse m *)
        END
      | 6:
        IF op = 42 THEN Send(s, vb MOD NP, va)
        ELSIF op = 43 THEN
          IF p[s].nq > 0 THEN
            p[s].r[a] := p[s].qv[0]; p[s].r[b] := p[s].qs[0]; p[s].from := p[s].qs[0];
            FOR k := 0 TO p[s].nq - 2 DO p[s].qv[k] := p[s].qv[k + 1]; p[s].qs[k] := p[s].qs[k + 1] END;
            DEC(p[s].nq)
          ELSE DEC(p[s].pc); p[s].state := Receives; cont := FALSE
          END
        ELSIF op = 44 THEN p[s].r[a] := Neighbor(s)
        ELSIF op = 45 THEN   (* SPAWN: the program's name is in the torus, one word per letter, from address Ra *)
          k := 0;
          WHILE (k < 31) & (Tor11.Word(va + 12 * k) > 0) & (Tor11.Word(va + 12 * k) < 127) DO nm[k] := CHR(Tor11.Word(va + 12 * k)); INC(k) END;
          nm[k] := 0X; p[s].r[b] := Start(nm); cont := FALSE
        ELSIF op = 46 THEN Kill(va MOD NP); cont := p[s].state # Free
        ELSIF op = 47 THEN
          IF p[s].nline > 0 THEN Flush(s) END;
          Who(s); Add("ENDED"); Say(0); p[s].state := Free; cont := FALSE; Scr2.Ended
        ELSE cont := FALSE
        END
      END
    END
    RETURN cont
  END Step;

  PROCEDURE Wake(now: INTEGER);
    VAR s, st: INTEGER;
  BEGIN
    FOR s := 0 TO NP - 1 DO
      st := p[s].state;
      IF (st = Sleeps) & (now >= p[s].wake) OR (st = Senses) & (Tor11.Writes() > p[s].seenW) OR (st = Receives) & (p[s].nq > 0) THEN
        p[s].state := Active
      END
    END
  END Wake;

  PROCEDURE Run*(budget: INTEGER);   (* at most budget instructions, shared in turn *)
    VAR now, s, k, n: INTEGER; any, cont: BOOLEAN;
  BEGIN
    now := Ceas.Ms();
    REPEAT
      any := FALSE;
      FOR k := 0 TO NP - 1 DO
        s := (rr + k) MOD NP;
        Wake(now);
        IF (p[s].state = Active) & (budget > 0) THEN
          n := 0; cont := TRUE;
          WHILE cont & (n < Slice) & (budget > 0) & (p[s].state = Active) DO cont := Step(s, now); INC(n); DEC(budget) END;
          any := TRUE
        END
      END
    UNTIL ~any OR (budget <= 0);
    rr := (rr + 1) MOD NP
  END Run;

  PROCEDURE StateOf*(s: INTEGER): INTEGER; BEGIN RETURN p[s].state END StateOf;
  PROCEDURE NameOf*(s: INTEGER; VAR n: ARRAY OF CHAR); BEGIN Copy(p[s].name, n) END NameOf;
  PROCEDURE StepsOf*(s: INTEGER): INTEGER; BEGIN RETURN p[s].steps END StepsOf;
  PROCEDURE FallsOf*(s: INTEGER): INTEGER; BEGIN RETURN p[s].falls END FallsOf;
  PROCEDURE PidOf*(s: INTEGER): INTEGER; BEGIN RETURN p[s].pid END PidOf;

  PROCEDURE LoadAsh;
    VAR h, b, j: INTEGER;
  BEGIN
    nash := 0; h := Fisier.Deschide("ash.txt");
    IF h >= 0 THEN
      b := Fisier.Citeste(h); j := 0;
      WHILE b >= 0 DO
        IF b = 10 THEN IF nash < 49 THEN ash[nash, j] := 0X; INC(nash) END; j := 0
        ELSIF (j < LL - 1) & (nash < 49) THEN ash[nash, j] := CHR(b); INC(j)
        END;
        b := Fisier.Citeste(h)
      END;
      Fisier.Gata(h)
    END
  END LoadAsh;

  PROCEDURE Mn(k: INTEGER; e, r: ARRAY OF CHAR; f: INTEGER);
  BEGIN Copy(e, en[k]); Copy(r, ro[k]); kind[k] := f
  END Mn;

  PROCEDURE Init*;   (* once, after the files are there *)
  BEGIN LoadAsh
  END Init;

BEGIN
  z7[0] := 196.0; z7[1] := 220.0; z7[2] := 246.94; z7[3] := 261.63; z7[4] := 293.66; z7[5] := 329.63; z7[6] := 369.99;
  (* kind: 0 no operands, 1 Ra, 2 Ra Rb, 3 Ra digit, 4 SET, 5 jump, 6 conditional jump *)
  Mn(0, "", "", 0); Mn(1, "SET", "SET", 4); Mn(2, "DIG", "DIG", 3); Mn(3, "MOV", "MOV", 2); Mn(4, "LD", "LD", 2); Mn(5, "ST", "ST", 2);
  Mn(6, "NOTEC", "NOTAC", 2);
  Mn(7, "ADD", "ADD", 2); Mn(8, "SUB", "SUB", 2); Mn(9, "MUL", "MUL", 2); Mn(10, "DIV", "DIV", 2); Mn(11, "MOD", "MOD", 2);
  Mn(12, "INC", "INC", 1); Mn(13, "DEC", "DEC", 1);
  Mn(14, "LT", "LT", 2); Mn(15, "EQ", "EQ", 2); Mn(16, "JMP", "JMP", 5); Mn(17, "JZ", "JZ", 6); Mn(18, "JNZ", "JNZ", 6);
  Mn(19, "CALL", "CALL", 5); Mn(20, "RET", "RET", 0);
  Mn(21, "LDW", "LDW", 2); Mn(22, "STW", "STW", 2); Mn(23, "STEP", "STEP", 2); Mn(24, "COORD", "COORD", 2);
  Mn(25, "FIELD", "CAMP", 1); Mn(26, "WAIT", "ASTEAPTA", 0); Mn(27, "BASE", "BAZA", 1);
  Mn(28, "NEPH", "NEF", 2); Mn(29, "SETNEPH", "PUNENEF", 2); Mn(30, "CORNER", "COLT", 1); Mn(31, "EMIT", "EMITE", 2);
  Mn(32, "LISTEN", "ASCULTA", 2); Mn(33, "PLAYC", "CANTA", 1); Mn(34, "NOTE", "NOTA", 2);
  Mn(35, "OPAL", "OPAL", 2); Mn(36, "SYS", "SIST", 3); Mn(37, "ASH", "ASH", 1); Mn(38, "SLEEP", "DORMI", 1);
  Mn(39, "PRINT", "SCRIE", 1); Mn(40, "PRINTC", "SCRIEC", 1); Mn(41, "PRINTN", "SCRIEN", 1);
  Mn(42, "SEND", "TRIMITE", 2); Mn(43, "RECV", "PRIMESTE", 2); Mn(44, "NEIGHBOR", "VECIN", 1); Mn(45, "SPAWN", "PORN", 2);
  Mn(46, "KILL", "OPR", 1); Mn(47, "STOP", "STOP", 0); Mn(48, "YIELD", "CEDEAZA", 0);
  nextPid := 2; rr := 0; nout := 0; nash := 0; ashTotal := 0;
  FOR rr := 0 TO NP - 1 DO p[rr].state := Free; p[rr].pid := 0; p[rr].nline := 0 END;
  rr := 0
END Sal4.
