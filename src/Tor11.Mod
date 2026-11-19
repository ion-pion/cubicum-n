MODULE Tor11;  (* TOR 11 (11 Nov 2026): the memory of the Tor7 processor in Cubicum N, now up to the 11th dimension.
     Pion: "we go with Tor7 with the 11th dimension and we will make a compiler; Tor7 will have to run on any
     architecture". This is the Tor7 of Cubicum OS 3 (7.B) written for OLL, plus 4 more dimensions.

     An address is a number 0 .. 7^11 - 1 (it fits one 32-bit INTEGER: 7^11 = 1977326743 < 2^31).
     Its 11 coordinates d0..d10 are its digits in base 7. Cells hold the digits 1..7 (bijective: 7 is the full circle,
     a fresh cell holds 7 and sounds) and a Nephilim state: Inactive 0, Corpuscle 1, Wave 2, CorpuscleWave 3 (XOR = Klein group).
       Dimensions 1..7 (d0..d6): the dense torus of 7^7 = 823543 cells, always there. d6 counts the 7 turns of the spiral.
       Dimensions 8..11 (d7..d10): 7^4 = 2401 more tori. They are kept sparse, in pages of 7^3 = 343 cells: a page is made
       when something is written in it; a cell never written reads 7, Inactive (dark). Room for 4096 pages (1.4 million cells).
     A word (a number) takes 12 cells: the sign (7 zero, 1 plus, 2 minus), then up to 11 bijective digits 1..7, a dark cell ends it.
     Opal, the clock: hands 1, 3, 5, 7, 11; one beat = one instruction. Every 1155 beats (an hour) the torus slips one step:
       the content of logical address a sits at physical place (a + w) MOD 7^7 inside its own 7D torus.
     Notes: from the Do corner, each step along an edge raises one degree; degree = digit + distance (d0..d6).
     Roler (in the Do corner) listens and emits over the dense torus (dimensions 1..7).
     Burn empties the cells; the clock (cycle, beat, hands) goes on: the torus remembers its first start.
     Pion & Claude, 11.11.2026 *)

  CONST N* = 823543; Turn* = 117649; Max* = 1977326742; NPG = 4096; PG = 343; HS = 8192;
    Inactive* = 0; Corpuscle* = 1; Wave* = 2; CorpWave* = 3;
    Hour* = 1155; NA = 5;

  VAR c: ARRAY N OF CHAR;                         (* digit 1..7 + 8 * (state XOR 1) *)
    pg: ARRAY NPG, PG OF CHAR; pgKey: ARRAY NPG OF INTEGER; npg: INTEGER;
    hash: ARRAY HS OF INTEGER;                    (* page key -> page + 1, 0 = empty *)
    field, writes, last, w, beat, corner, dark, coma, burns, full: INTEGER;
    hand, pos, emitted, seen: ARRAY NA OF INTEGER;
    semi: ARRAY 7 OF INTEGER;

  PROCEDURE Norm(a: INTEGER): INTEGER;   (* any number -> 0 .. 7^11 - 1 *)
  BEGIN
    IF (a < 0) OR (a > Max) THEN a := a MOD (Max + 1) END
    RETURN a
  END Norm;

  PROCEDURE Page(key: INTEGER; make: BOOLEAN): INTEGER;   (* the page of 343 cells with this key; -1 = none *)
    VAR h, k, r, i: INTEGER;
  BEGIN
    h := key MOD HS; r := -1; k := 0;
    WHILE (r = -1) & (k < HS) & (hash[h] # 0) DO
      IF pgKey[hash[h] - 1] = key THEN r := hash[h] - 1 ELSE h := (h + 1) MOD HS; INC(k) END
    END;
    IF (r = -1) & make THEN
      IF (npg < NPG) & (k < HS) THEN
        r := npg; INC(npg); pgKey[r] := key; hash[h] := r + 1;
        FOR i := 0 TO PG - 1 DO pg[r, i] := CHR(7 + 8) END   (* 7, Inactive (stored as 1) *)
      ELSE INC(full)
      END
    END
    RETURN r
  END Page;

  PROCEDURE Phys*(a: INTEGER): INTEGER;   (* the physical place of logical address a (it slips inside its own 7D torus) *)
  BEGIN a := Norm(a)
    RETURN a DIV N * N + (a MOD N + w) MOD N
  END Phys;

  PROCEDURE Raw(a: INTEGER): INTEGER;   (* the stored byte of logical cell a *)
    VAR p, r: INTEGER;
  BEGIN
    a := Norm(a);
    IF a < N THEN r := ORD(c[a])
    ELSE p := Page(a DIV PG, FALSE); IF p < 0 THEN r := 7 + 8 ELSE r := ORD(pg[p, a MOD PG]) END
    END
    RETURN r
  END Raw;

  PROCEDURE SetRaw(a, v: INTEGER);
    VAR p: INTEGER;
  BEGIN
    a := Norm(a);
    IF a < N THEN c[a] := CHR(v)
    ELSE p := Page(a DIV PG, TRUE); IF p >= 0 THEN pg[p, a MOD PG] := CHR(v) END
    END
  END SetRaw;

  PROCEDURE Xor*(a, b: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN
    r := 0;
    IF ODD(a) # ODD(b) THEN r := 1 END;
    IF ODD(a DIV 2) # ODD(b DIV 2) THEN r := r + 2 END
    RETURN r
  END Xor;

  PROCEDURE Read*(a: INTEGER): INTEGER;   (* the digit 1..7 *)
  BEGIN RETURN Raw(a) MOD 8
  END Read;

  PROCEDURE State*(a: INTEGER): INTEGER;
  BEGIN RETURN Xor(Raw(a) DIV 8 MOD 4, 1)
  END State;

  PROCEDURE SetState*(a, s: INTEGER);
  BEGIN SetRaw(a, Raw(a) MOD 8 + 8 * Xor(s MOD 4, 1))
  END SetState;

  PROCEDURE Combine*(a, s: INTEGER);
  BEGIN SetState(a, Xor(State(a), s MOD 4))
  END Combine;

  PROCEDURE Write*(a, v: INTEGER);   (* writing into a dark cell lights it up *)
    VAR k, r: INTEGER;
  BEGIN
    a := Norm(a); v := (v - 1) MOD 7 + 1;
    r := Raw(a);
    IF Xor(r DIV 8 MOD 4, 1) = Inactive THEN r := r MOD 8 + 8 * Xor(Corpuscle, 1) END;
    k := r MOD 8;
    field := (field + v - k + 7) MOD 7;
    SetRaw(a, r - k + v); INC(writes); last := a
  END Write;

  PROCEDURE Field*(): INTEGER;   (* 1..7 *)
    VAR r: INTEGER;
  BEGIN r := field MOD 7; IF r = 0 THEN r := 7 END
    RETURN r
  END Field;

  PROCEDURE Writes*(): INTEGER; BEGIN RETURN writes END Writes;
  PROCEDURE Last*(): INTEGER; BEGIN RETURN last END Last;
  PROCEDURE Pages*(): INTEGER; BEGIN RETURN npg END Pages;
  PROCEDURE Full*(): INTEGER; BEGIN RETURN full END Full;

  PROCEDURE Coord*(a: INTEGER; VAR d: ARRAY OF INTEGER);   (* the 11 coordinates 0..6 of address a *)
    VAR k: INTEGER;
  BEGIN a := Norm(a); FOR k := 0 TO 10 DO d[k] := a MOD 7; a := a DIV 7 END
  END Coord;

  PROCEDURE Index*(d: ARRAY OF INTEGER): INTEGER;
    VAR k, a: INTEGER;
  BEGIN a := 0; FOR k := 10 TO 0 BY -1 DO a := a * 7 + d[k] MOD 7 END
    RETURN a
  END Index;

  PROCEDURE Step*(a, dim: INTEGER): INTEGER;   (* one step on dimension dim (0..10); dim = -(k+1): one step back on k *)
    VAR d: ARRAY 11 OF INTEGER; k: INTEGER;
  BEGIN
    Coord(a, d);
    IF dim >= 0 THEN k := dim MOD 11; d[k] := (d[k] + 1) MOD 7 ELSE k := (-dim - 1) MOD 11; d[k] := (d[k] + 6) MOD 7 END
    RETURN Index(d)
  END Step;

  PROCEDURE Word*(a: INTEGER): INTEGER;
    VAR k, n, v, sg: INTEGER; d: ARRAY 11 OF INTEGER;
  BEGIN
    v := 0; sg := Read(a);
    IF (sg = 1) OR (sg = 2) THEN
      n := 0; WHILE (n < 11) & (State(a + 1 + n) # Inactive) DO d[n] := Read(a + 1 + n); INC(n) END;
      FOR k := n - 1 TO 0 BY -1 DO IF v <= 306783377 THEN v := v * 7 + d[k] END END;
      IF sg = 2 THEN v := -v END
    END
    RETURN v
  END Word;

  PROCEDURE PutWord*(a, v: INTEGER);
    VAR k, d: INTEGER;
  BEGIN
    IF v = 0 THEN Write(a, 7) ELSIF v < 0 THEN Write(a, 2); v := -v ELSE Write(a, 1) END;
    IF v > Max THEN v := v MOD (Max + 1) END;
    k := 1;
    WHILE (v > 0) & (k <= 11) DO d := (v - 1) MOD 7 + 1; Write(a + k, d); v := (v - d) DIV 7; INC(k) END;
    IF k <= 11 THEN Write(a + k, 7); SetState(a + k, Inactive) END
  END PutWord;

  (* ---------- Opal ---------- *)

  PROCEDURE Beat*;
    VAR k, f, r: INTEGER;
  BEGIN
    INC(beat);
    FOR k := 0 TO NA - 1 DO
      pos[k] := (pos[k] + hand[k]) MOD N;
      IF beat MOD hand[k] = 0 THEN
        f := (pos[k] - w MOD N + N) MOD N; r := ORD(c[f]);
        IF r DIV 8 MOD 4 = 1 THEN seen[k] := -1 ELSE seen[k] := r MOD 8 END;
        INC(emitted[k])
      END
    END;
    IF beat = Hour THEN beat := 0; INC(w) END
  END Beat;

  PROCEDURE Opal*(p: INTEGER): INTEGER;   (* the last reading of hand p (1 3 5 7 11); -1 = nothing / dark *)
    VAR k, r: INTEGER;
  BEGIN
    r := -1;
    FOR k := 0 TO NA - 1 DO IF (hand[k] = p) & (emitted[k] > 0) THEN r := seen[k] END END
    RETURN r
  END Opal;

  PROCEDURE Cycle*(): INTEGER; BEGIN RETURN w END Cycle;
  PROCEDURE BeatInHour*(): INTEGER; BEGIN RETURN beat END BeatInHour;
  PROCEDURE Beats*(): INTEGER; BEGIN RETURN w * Hour + beat END Beats;
  PROCEDURE Burns*(): INTEGER; BEGIN RETURN burns END Burns;

  (* ---------- notes and Roler ---------- *)

  PROCEDURE SetCorner*(k: INTEGER); BEGIN corner := k MOD 128 END SetCorner;
  PROCEDURE Corner*(): INTEGER; BEGIN RETURN corner END Corner;

  PROCEDURE Distance*(f: INTEGER): INTEGER;   (* steps along the edges from the Do corner to physical place f (dims 1..7) *)
    VAR k, s, m: INTEGER; d: ARRAY 11 OF INTEGER;
  BEGIN
    Coord(f, d); s := 0; m := corner;
    FOR k := 0 TO 6 DO IF ODD(m) THEN s := s + 6 - d[k] ELSE s := s + d[k] END; m := m DIV 2 END
    RETURN s
  END Distance;

  PROCEDURE Degree*(a: INTEGER): INTEGER;
  BEGIN RETURN Read(a) + Distance(Phys(a))
  END Degree;

  PROCEDURE Hz*(degree: INTEGER): REAL;   (* the Do major scale from Do2 = 65.41 Hz *)
    VAR k: INTEGER; f: REAL;
  BEGIN
    f := 65.41; FOR k := 1 TO degree DIV 7 DO f := f * 2.0 END;
    FOR k := 1 TO semi[degree MOD 7] DO f := f * 1.0594631 END
    RETURN f
  END Hz;

  PROCEDURE Roler(t, s: INTEGER; emit: BOOLEAN): INTEGER;
    VAR f, a, k, dist, tr, v, st, act, m: INTEGER; d, sg: ARRAY 7 OF INTEGER;
  BEGIN
    m := corner; dist := 0;
    FOR k := 0 TO 6 DO d[k] := 0; IF ODD(m) THEN sg[k] := -1; dist := dist + 6 ELSE sg[k] := 1 END; m := m DIV 2 END;
    act := 0; dark := 0; coma := 0; s := s MOD 4;
    a := (N - w MOD N) MOD N;
    FOR f := 0 TO N - 1 DO
      v := ORD(c[a]); tr := v MOD 8 + dist;
      IF tr = t THEN
        IF emit & (s # 0) THEN st := Xor(v DIV 8 MOD 4, 1); v := v MOD 8 + 8 * Xor(Xor(st, s), 1); c[a] := CHR(v) END;
        IF v DIV 8 MOD 4 = 1 THEN INC(dark) ELSE INC(act) END
      ELSIF tr MOD 7 = t MOD 7 THEN INC(coma)
      END;
      INC(a); IF a = N THEN a := 0 END;
      k := 0;
      WHILE (k < 7) & (d[k] = 6) DO d[k] := 0; dist := dist - 6 * sg[k]; INC(k) END;
      IF k < 7 THEN INC(d[k]); dist := dist + sg[k] END
    END
    RETURN act
  END Roler;

  PROCEDURE Listen*(t: INTEGER): INTEGER; BEGIN RETURN Roler(t, 0, FALSE) END Listen;
  PROCEDURE Emit*(t, s: INTEGER): INTEGER; VAR r: INTEGER; BEGIN r := Roler(t, s, TRUE) RETURN r + dark END Emit;

  PROCEDURE Remember*(t: INTEGER): INTEGER;   (* the first active cell with degree t; -1 = none *)
    VAR f, a, k, dist, v, r, m: INTEGER; d, sg: ARRAY 7 OF INTEGER;
  BEGIN
    m := corner; dist := 0;
    FOR k := 0 TO 6 DO d[k] := 0; IF ODD(m) THEN sg[k] := -1; dist := dist + 6 ELSE sg[k] := 1 END; m := m DIV 2 END;
    r := -1; f := 0; a := (N - w MOD N) MOD N;
    WHILE (r < 0) & (f < N) DO
      v := ORD(c[a]);
      IF (v MOD 8 + dist = t) & (v DIV 8 MOD 4 # 1) THEN r := a END;
      INC(a); IF a = N THEN a := 0 END;
      k := 0;
      WHILE (k < 7) & (d[k] = 6) DO d[k] := 0; dist := dist - 6 * sg[k]; INC(k) END;
      IF k < 7 THEN INC(d[k]); dist := dist + sg[k] END;
      INC(f)
    END
    RETURN r
  END Remember;

  PROCEDURE Dark*(): INTEGER; BEGIN RETURN dark END Dark;
  PROCEDURE Coma*(): INTEGER; BEGIN RETURN coma END Coma;

  (* ---------- burning ---------- *)

  PROCEDURE Clear;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO N - 1 DO c[i] := CHR(7) END;   (* 7, Corpuscle (stored as 0) *)
    FOR i := 0 TO HS - 1 DO hash[i] := 0 END;
    npg := 0; field := 0; writes := 0; last := -1; corner := 0; full := 0;
    FOR i := 0 TO NA - 1 DO seen[i] := -1 END
  END Clear;

  PROCEDURE Burn*;   (* the cells empty; the clock goes on *)
  BEGIN Clear; INC(burns)
  END Burn;

  PROCEDURE BurnTurn*(t: INTEGER);   (* only turn t of the spiral (in the dense torus) *)
    VAR i, a, s: INTEGER;
  BEGIN
    a := (t MOD 7) * Turn; s := 0;
    FOR i := a TO a + Turn - 1 DO s := s + ORD(c[i]) MOD 8; c[i] := CHR(7) END;
    field := (field - s MOD 7 + 7 * Turn) MOD 7
  END BurnTurn;

BEGIN
  hand[0] := 1; hand[1] := 3; hand[2] := 5; hand[3] := 7; hand[4] := 11;
  semi[0] := 0; semi[1] := 2; semi[2] := 4; semi[3] := 5; semi[4] := 7; semi[5] := 9; semi[6] := 11;
  w := 0; beat := 0; burns := 0; dark := 0; coma := 0;
  FOR full := 0 TO NA - 1 DO pos[full] := 0; emitted[full] := 0 END;
  Clear
END Tor11.
