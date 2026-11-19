MODULE Arch1;  (* ARCH 1 (19 Nov 2026): Z7 Arch inside Cubicum N. Pion: "put Z7 Arch in Cubicum N".
     The same engine and the same .z7c cubes as Z7 Arch 8 (context mixing, 64 KB cells, the Egg twice, the Ash,
     the cube map with Cubicum FS addresses, search through fingerprints, images/sound/video seen by their shape
     with Spatiu), working on the files of Cubicum N, from its shell:
       ARCH PACK NOTES [FILES...|ALL|.EXT]   ARCH LIST NOTES   ARCH GET NOTES FILE   ARCH ALL NOTES
       ARCH FIND NOTES WORD...   ARCH CHECK NOTES   ARCH ADD NOTES FILES...
     (NOTES means NOTES.Z7C). The shell gives the list of its files (Known) and shows the lines (Lines, Line).
     A cube made here opens in Z7 Arch 8 and the other way round.
     Pion & Claude, 19.11.2026 *)

  IMPORT Fisier, Spatiu;

  CONST
    TB = 2097152; CS = 65536; L = 8388608; NI = 8; NO = 6; MB = 131072; MH = 262144; LIM = 10; MOD32 = 65521;
    EGG = 16384; PC = 342;
    NC = 2394;   (* 7 cubes: plenty for the files of Cubicum N *)
    FPB = 512; FB = FPB * 8;
    NF = 128; NH = 40;
    NL = 60;     (* lines of output *)
    ALB = 0; VERDE = 1; ROSU = 2; AUR = 3;   (* the colours of the lines, for the shell *)

  VAR
    t: ARRAY TB OF INTEGER; w: ARRAY 256 * NI OF INTEGER;
    sq: ARRAY 33 OF INTEGER; st: ARRAY 4096 OF INTEGER;
    ord, hb, idx, s: ARRAY NI OF INTEGER; hist: ARRAY 8 OF INTEGER;
    c0, pm, pa, ab: INTEGER;
    buf: ARRAY MB OF CHAR; mt: ARRAY MH OF INTEGER; pos, mptr, mlen, mbit, mi: INTEGER;
    mm: ARRAY 64 OF INTEGER; ap: ARRAY 256 * 33 OF INTEGER;
    t2: ARRAY TB OF INTEGER; w2: ARRAY 256 * NI OF INTEGER;
    hb2: ARRAY NI OF INTEGER; hist2: ARRAY 8 OF INTEGER;
    buf2: ARRAY MB OF CHAR; mt2: ARRAY MH OF INTEGER; mm2: ARRAY 64 OF INTEGER; ap2: ARRAY 256 * 33 OF INTEGER;
    c02, pos2, mptr2, mlen2, mbit2: INTEGER;
    blk: ARRAY CS OF INTEGER; pr: ARRAY CS * 8 OF INTEGER; ob: ARRAY CS + CS DIV 4 + 64 OF INTEGER;
    hin, hout, written, inByte, ms1, ms2: INTEGER; bad: BOOLEAN;
    fNm: ARRAY NF, 64 OF CHAR; fStart, fLen, fS1, fS2: ARRAY NF OF INTEGER; fArs, fScos: ARRAY NF OF BOOLEAN; nfa: INTEGER;
    cRaw, cComp, cS1, cS2, cOff, cBeg: ARRAY NC OF INTEGER; cArs, cMarc, cFp, cTip, cLeg: ARRAY NC OF BOOLEAN; nca, ver, sarite: INTEGER;
    fKind, fOff, fStr, fBpp, fWd, fPl, fIn, fMod: ARRAY NF OF INTEGER;
    sp, ultimTip: BOOLEAN;
    vKind, vOff, vStr, vBpp, vWd, vPl, vIn, vMod: INTEGER;
    hd: ARRAY 4096 OF INTEGER; nhd: INTEGER;
    fp: ARRAY NC * FPB OF CHAR;
    eggLen, eggC, eggS1, eggS2, dataStart, oulBun, citite, ultimCel: INTEGER;
    ax, ay, az: ARRAY PC OF INTEGER; loc: ARRAY 343 OF INTEGER;
    sir: ARRAY 80 OF CHAR; ls: INTEGER;
    nume: ARRAY NF, 64 OF CHAR; marime: ARRAY NF OF INTEGER; nf: INTEGER;
    q: ARRAY 40 OF CHAR; nq: INTEGER;
    hitF: ARRAY NH OF INTEGER; hitS: ARRAY NH, 40 OF CHAR; nh: INTEGER;
    qb1, qb2: ARRAY 20 OF INTEGER; nqb: INTEGER;
    h1, h2, hl: INTEGER;
    arh: ARRAY 64 OF CHAR;   (* the cube being worked on *)
    known: ARRAY 300, 40 OF CHAR; nk: INTEGER;   (* the files of Cubicum N, given by the shell *)
    out: ARRAY NL, 46 OF CHAR; outc: ARRAY NL OF INTEGER; nout: INTEGER;
    cmd: ARRAY 8, 64 OF CHAR; ncmd: INTEGER; rest: ARRAY 64 OF CHAR;
    adrese: BOOLEAN;


  PROCEDURE Baza(VAR cale, b: ARRAY OF CHAR);
    VAR i, k, j: INTEGER;
  BEGIN
    i := 0; k := 0; WHILE (i < LEN(cale)) & (cale[i] # 0X) DO IF cale[i] = "/" THEN k := i + 1 END; INC(i) END;
    j := 0; WHILE (k < i) & (j < LEN(b) - 1) DO b[j] := cale[k]; INC(j); INC(k) END; b[j] := 0X
  END Baza;

  PROCEDURE Squash(d: INTEGER): INTEGER;
    VAR r, qq, f: INTEGER;
  BEGIN
    IF d > 2047 THEN r := 4095
    ELSIF d < -2047 THEN r := 0
    ELSE f := d MOD 128; qq := d DIV 128 + 16; r := (sq[qq] * (128 - f) + sq[qq + 1] * f + 64) DIV 128
    END
    RETURN r
  END Squash;

  PROCEDURE Hashes;
    VAR k, j, h: INTEGER;
  BEGIN
    FOR k := 0 TO NO - 1 DO
      h := (k + 1) * 7777;
      FOR j := 1 TO ord[k] DO h := (h * 263 + hist[j] + 1) MOD 1048573 END;
      hb[k] := h
    END
  END Hashes;

  PROCEDURE Match;
    VAR h, k: INTEGER;
  BEGIN
    buf[pos MOD MB] := CHR(hist[1]); INC(pos);
    IF (mlen > 0) & (ORD(buf[mptr MOD MB]) = hist[1]) THEN INC(mlen); INC(mptr)
    ELSE mlen := 0
    END;
    h := hb[NO - 1] MOD MH;
    IF (mlen = 0) & (pos > 6) THEN
      mptr := mt[h];
      IF (mptr > 0) & (pos - mptr < MB - 8) THEN
        k := 0;
        WHILE (k < 32) & (mptr - k > 0) & (ORD(buf[(mptr - k - 1) MOD MB]) = ORD(buf[(pos - k - 1) MOD MB])) DO INC(k) END;
        mlen := k
      END
    END;
    mt[h] := pos;
    IF mlen > 0 THEN mbit := ORD(buf[mptr MOD MB]) + 256 ELSE mbit := 0 END
  END Match;

  PROCEDURE Reset;
    VAR i, x, v, p: INTEGER;
  BEGIN
    sq[0] := 1; sq[1] := 2; sq[2] := 3; sq[3] := 6; sq[4] := 10; sq[5] := 16; sq[6] := 27; sq[7] := 45;
    sq[8] := 73; sq[9] := 120; sq[10] := 194; sq[11] := 310; sq[12] := 488; sq[13] := 747; sq[14] := 1101;
    sq[15] := 1546; sq[16] := 2047; sq[17] := 2549; sq[18] := 2994; sq[19] := 3348; sq[20] := 3607;
    sq[21] := 3785; sq[22] := 3901; sq[23] := 3975; sq[24] := 4022; sq[25] := 4050; sq[26] := 4068;
    sq[27] := 4079; sq[28] := 4085; sq[29] := 4089; sq[30] := 4092; sq[31] := 4093; sq[32] := 4094;
    p := 0;
    FOR x := -2047 TO 2047 DO
      v := Squash(x);
      FOR i := p TO v DO st[i] := x END;
      IF v + 1 > p THEN p := v + 1 END
    END;
    FOR i := p TO 4095 DO st[i] := 2047 END;
    FOR i := 0 TO TB - 1 DO t[i] := 32768 * 64 END;
    FOR i := 0 TO 256 * NI - 1 DO
      IF i MOD NI = NI - 1 THEN w[i] := 0 ELSE w[i] := 5000 END
    END;
    FOR i := 0 TO MH - 1 DO mt[i] := 0 END;
    FOR i := 0 TO 63 DO mm[i] := 32768 END;
    FOR i := 0 TO 256 * 33 - 1 DO ap[i] := Squash((i MOD 33) * 128 - 2048) * 16 END;
    pos := 0; mptr := 0; mlen := 0; mbit := 0;
    ord[0] := 0; ord[1] := 1; ord[2] := 2; ord[3] := 3; ord[4] := 4; ord[5] := 6;
    FOR i := 0 TO 7 DO hist[i] := 0 END;
    c0 := 1; Hashes
  END Reset;

  PROCEDURE Save;   (* remember the state after the Egg *)
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO TB - 1 DO t2[i] := t[i] END;
    FOR i := 0 TO 256 * NI - 1 DO w2[i] := w[i] END;
    FOR i := 0 TO 256 * 33 - 1 DO ap2[i] := ap[i] END;
    FOR i := 0 TO MH - 1 DO mt2[i] := mt[i] END;
    FOR i := 0 TO MB - 1 DO buf2[i] := buf[i] END;
    FOR i := 0 TO 63 DO mm2[i] := mm[i] END;
    FOR i := 0 TO NI - 1 DO hb2[i] := hb[i] END;
    FOR i := 0 TO 7 DO hist2[i] := hist[i] END;
    c02 := c0; pos2 := pos; mptr2 := mptr; mlen2 := mlen; mbit2 := mbit
  END Save;

  PROCEDURE Restore;   (* back to the state after the Egg *)
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO TB - 1 DO t[i] := t2[i] END;
    FOR i := 0 TO 256 * NI - 1 DO w[i] := w2[i] END;
    FOR i := 0 TO 256 * 33 - 1 DO ap[i] := ap2[i] END;
    FOR i := 0 TO MH - 1 DO mt[i] := mt2[i] END;
    FOR i := 0 TO MB - 1 DO buf[i] := buf2[i] END;
    FOR i := 0 TO 63 DO mm[i] := mm2[i] END;
    FOR i := 0 TO NI - 1 DO hb[i] := hb2[i] END;
    FOR i := 0 TO 7 DO hist[i] := hist2[i] END;
    c0 := c02; pos := pos2; mptr := mptr2; mlen := mlen2; mbit := mbit2
  END Restore;

  PROCEDURE Bits(): INTEGER;
    VAR n, c: INTEGER;
  BEGIN n := 0; c := c0; WHILE c > 1 DO c := c DIV 2; INC(n) END
    RETURN n
  END Bits;

  PROCEDURE Min(a, b: INTEGER): INTEGER;
  BEGIN IF b < a THEN a := b END
    RETURN a
  END Min;

  PROCEDURE Max(a, b: INTEGER): INTEGER;
  BEGIN IF b > a THEN a := b END
    RETURN a
  END Max;

  PROCEDURE Predict(): INTEGER;
    VAR i, dot, b, k, f: INTEGER;
  BEGIN
    b := c0 * NI; dot := 0;
    FOR i := 0 TO NO - 1 DO
      idx[i] := (hb[i] * 271 + c0 * 4099) MOD TB;
      s[i] := st[t[idx[i]] DIV 1024];
      dot := dot + w[b + i] * s[i]
    END;
    IF (mbit > 0) & (mbit DIV LSL(1, 8 - Bits()) = c0) THEN
      k := mbit DIV LSL(1, 7 - Bits()) MOD 2; mi := Min(mlen, 31) * 2 + k;
      s[NO] := st[mm[mi] DIV 16]
    ELSE mi := -1; s[NO] := 0
    END;
    dot := dot + w[b + NO] * s[NO];
    s[NI - 1] := 256; dot := dot + w[b + NI - 1] * 256;
    pm := Squash(dot DIV 16384);
    IF pm < 1 THEN pm := 1 ELSIF pm > 4095 THEN pm := 4095 END;
    k := st[pm] + 2048; ab := c0 * 33 + k DIV 128; f := k MOD 128;
    pa := (ap[ab] * (128 - f) + ap[ab + 1] * f) DIV 2048;
    k := (pm + 3 * pa) DIV 4;
    IF k < 1 THEN k := 1 ELSIF k > 4095 THEN k := 4095 END
    RETURN k
  END Predict;

  PROCEDURE Update(y: INTEGER);
    VAR i, err, b, p, k: INTEGER;
  BEGIN
    err := y * 4095 - pm; b := c0 * NI;
    FOR i := 0 TO NI - 1 DO
      k := w[b + i] + s[i] * err DIV 8192;
      IF k > 65535 THEN k := 65535 ELSIF k < -65535 THEN k := -65535 END;
      w[b + i] := k
    END;
    FOR i := 0 TO NO - 1 DO
      p := t[idx[i]]; k := p MOD 64; p := p DIV 64;
      p := p + (y * 65535 - p) * 2 DIV (2 * k + 3);
      IF k < LIM THEN INC(k) END;
      t[idx[i]] := p * 64 + k
    END;
    IF mi >= 0 THEN p := mm[mi]; mm[mi] := p + (y * 65535 - p) DIV 32 END;
    IF (mbit > 0) & (mbit DIV LSL(1, 7 - Bits()) MOD 2 # y) THEN mlen := 0; mbit := 0 END;
    ap[ab] := ap[ab] + (y * 65535 - ap[ab]) DIV 64; ap[ab + 1] := ap[ab + 1] + (y * 65535 - ap[ab + 1]) DIV 64;
    c0 := c0 * 2 + y;
    IF c0 >= 256 THEN
      FOR i := 7 TO 2 BY -1 DO hist[i] := hist[i - 1] END;
      hist[1] := c0 - 256; c0 := 1; Hashes; Match
    END
  END Update;

  PROCEDURE PredictX(): INTEGER;   (* the plain model or the spatial one *)
    VAR r: INTEGER;
  BEGIN IF sp THEN r := Spatiu.Predict() ELSE r := Predict() END
    RETURN r
  END PredictX;

  PROCEDURE UpdateX(y: INTEGER);
  BEGIN IF sp THEN Spatiu.Update(y) ELSE Update(y) END
  END UpdateX;

  PROCEDURE Put(b: INTEGER);
  BEGIN Fisier.Scrie(hout, b); INC(written); ms1 := (ms1 + b) MOD MOD32; ms2 := (ms2 + ms1) MOD MOD32
  END Put;

  PROCEDURE PutInt(x: INTEGER);
  BEGIN Put(x DIV 16777216 MOD 256); Put(x DIV 65536 MOD 256); Put(x DIV 256 MOD 256); Put(x MOD 256)
  END PutInt;

  PROCEDURE Get(): INTEGER;
    VAR b: INTEGER;
  BEGIN b := Fisier.Citeste(hin);
    IF b < 0 THEN bad := TRUE; b := 0 ELSE INC(inByte); ms1 := (ms1 + b) MOD MOD32; ms2 := (ms2 + ms1) MOD MOD32 END
    RETURN b
  END Get;

  PROCEDURE GetInt(): INTEGER;
    VAR x: INTEGER;
  BEGIN x := Get(); x := x * 256 + Get(); x := x * 256 + Get(); x := x * 256 + Get()
    RETURN x
  END GetInt;

  PROCEDURE Cop(VAR de, la: ARRAY OF CHAR);   (* one string into another, whatever their lengths *)
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(la) - 1) & (i < LEN(de)) & (de[i] # 0X) DO la[i] := de[i]; INC(i) END; la[i] := 0X
  END Cop;

  PROCEDURE CopiazaIn(de: ARRAY OF CHAR);   (* a whole file, appended to hout *)
    VAR a, c: INTEGER;
  BEGIN
    a := Fisier.Deschide(de);
    IF a >= 0 THEN c := Fisier.Citeste(a); WHILE c >= 0 DO Put(c); c := Fisier.Citeste(a) END; Fisier.Gata(a) END
  END CopiazaIn;

  PROCEDURE PackBlock(n: INTEGER);
    VAR i, k, b, y, p, f, st0, x, no, c: INTEGER;
  BEGIN
    k := 0;
    FOR i := 0 TO n - 1 DO
      c := blk[i];
      FOR b := 7 TO 0 BY -1 DO
        y := c DIV LSL(1, b) MOD 2; pr[k] := PredictX(); UpdateX(y); INC(k)
      END
    END;
    x := L; no := 0;
    FOR k := n * 8 - 1 TO 0 BY -1 DO
      y := blk[k DIV 8] DIV LSL(1, 7 - k MOD 8) MOD 2; p := pr[k];
      IF y = 1 THEN f := p; st0 := 0 ELSE f := 4096 - p; st0 := p END;
      WHILE x >= 524288 * f DO ob[no] := x MOD 256; INC(no); x := x DIV 256 END;
      x := x DIV f * 4096 + x MOD f + st0
    END;
    PutInt(n);
    IF no + 8 < n THEN PutInt(no); PutInt(x); FOR i := no - 1 TO 0 BY -1 DO Put(ob[i]) END
    ELSE PutInt(0); PutInt(0); FOR i := 0 TO n - 1 DO Put(blk[i]) END
    END
  END PackBlock;

  PROCEDURE UnpackBlock(n: INTEGER; VAR s1, s2: INTEGER);   (* into blk *)
    VAR i, j, y, p, f, st0, x, no, r, c, start: INTEGER;
  BEGIN
    no := GetInt(); x := GetInt(); start := inByte;
    IF (no = 0) & (x = 0) THEN
      FOR i := 0 TO n - 1 DO
        c := Get();
        FOR j := 7 TO 0 BY -1 DO p := PredictX(); UpdateX(c DIV LSL(1, j) MOD 2) END;
        s1 := (s1 + c) MOD MOD32; s2 := (s2 + s1) MOD MOD32; blk[i] := c
      END;
      no := n
    ELSE
      i := 0;
      WHILE (i < n) & ~bad DO
        c := 0;
        FOR j := 0 TO 7 DO
          p := PredictX(); r := x MOD 4096;
          IF r < p THEN y := 1; f := p; st0 := 0 ELSE y := 0; f := 4096 - p; st0 := p END;
          x := f * (x DIV 4096) + r - st0;
          WHILE (x < L) & ~bad DO x := x * 256 + Get() END;
          UpdateX(y); c := c * 2 + y
        END;
        s1 := (s1 + c) MOD MOD32; s2 := (s2 + s1) MOD MOD32; blk[i] := c; INC(i)
      END
    END;
    IF inByte - start # no THEN bad := TRUE END
  END UnpackBlock;

  PROCEDURE Low(c: INTEGER): INTEGER;
  BEGIN IF (c >= 65) & (c <= 90) THEN c := c + 32 END
    RETURN c
  END Low;

  PROCEDURE Litera(c: INTEGER): BOOLEAN;   (* part of a word *)
  BEGIN RETURN (c >= 97) & (c <= 122) OR (c >= 48) & (c <= 57) OR (c >= 128)
  END Litera;

  PROCEDURE Pune(k, b: INTEGER);
    VAR i, v: INTEGER;
  BEGIN i := k * FPB + b DIV 8; v := ORD(fp[i]);
    IF v DIV LSL(1, b MOD 8) MOD 2 = 0 THEN fp[i] := CHR(v + LSL(1, b MOD 8)) END
  END Pune;

  PROCEDURE Are(k, b: INTEGER): BOOLEAN;
  BEGIN RETURN ORD(fp[k * FPB + b DIV 8]) DIV LSL(1, b MOD 8) MOD 2 = 1
  END Are;

  PROCEDURE Cuvant(c: INTEGER): BOOLEAN;   (* one more character; TRUE when a valid word has ended *)
    VAR gata: BOOLEAN;
  BEGIN
    gata := FALSE; c := Low(c);
    IF Litera(c) THEN
      IF hl < 6 THEN h1 := (h1 * 31 + c) MOD 1000003; h2 := (h2 * 37 + c + 1) MOD 999983 END;   (* the first 6 letters *)
      INC(hl)
    ELSE gata := hl >= 3; IF ~gata THEN h1 := 0; h2 := 0; hl := 0 END
    END
    RETURN gata
  END Cuvant;

  PROCEDURE Amprenta(k, n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO FPB - 1 DO fp[k * FPB + i] := 0X END;
    h1 := 0; h2 := 0; hl := 0;
    FOR i := 0 TO n DO
      IF i < n THEN IF Cuvant(blk[i]) THEN Pune(k, h1 MOD FB); Pune(k, h2 MOD FB); h1 := 0; h2 := 0; hl := 0 END
      ELSIF Cuvant(32) THEN Pune(k, h1 MOD FB); Pune(k, h2 MOD FB); h1 := 0; h2 := 0; hl := 0
      END
    END
  END Amprenta;

  PROCEDURE Adrese;   (* the shells around the centre (4,4,4) (stored 0..6, shown 1..7) *)
    VAR d, x, y, z, j, m: INTEGER;
  BEGIN
    j := 0;
    FOR d := 1 TO 3 DO
      FOR z := 0 TO 6 DO FOR y := 0 TO 6 DO FOR x := 0 TO 6 DO
        m := Max(Max(ABS(x - 3), ABS(y - 3)), ABS(z - 3));
        IF m = d THEN ax[j] := x; ay[j] := y; az[j] := z; loc[x + 7 * y + 49 * z] := j; INC(j) END
      END END END
    END;
    loc[3 + 21 + 147] := -1
  END Adrese;

  PROCEDURE Clr; BEGIN ls := 0; sir[0] := 0X END Clr;

  PROCEDURE Add(tx: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(tx)) & (tx[i] # 0X) & (ls < 78) DO sir[ls] := tx[i]; INC(ls); INC(i) END;
    sir[ls] := 0X
  END Add;

  PROCEDURE AddN(n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN Add("-"); n := -n END;
    k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE (k > 0) & (ls < 78) DO DEC(k); sir[ls] := d[k]; INC(ls) END;
    sir[ls] := 0X
  END AddN;

  PROCEDURE AddK(n: INTEGER);   (* bytes, readable: 123 KB, 4.5 MB *)
  BEGIN
    IF n < 10240 THEN AddN(n); Add(" B")
    ELSIF n < 10485760 THEN AddN(n DIV 1024); Add(" KB")
    ELSE AddN(n DIV 1048576); Add("."); AddN(n * 10 DIV 1048576 MOD 10); Add(" MB")
    END
  END AddK;

  PROCEDURE AddPoz(j: INTEGER);   (* position j in the shell order; -1 = the centre; bijective base 7: 1..7 *)
  BEGIN
    IF j < 0 THEN Add("(4,4,4)")
    ELSE Add("("); AddN(ax[j] + 1); Add(","); AddN(ay[j] + 1); Add(","); AddN(az[j] + 1); Add(")")
    END
  END AddPoz;

  PROCEDURE AddCub(c: INTEGER);   (* where cube c sits in the super-cube: cube 0 in the centre, then the shells *)
  BEGIN AddPoz(c - 1)
  END AddCub;

  PROCEDURE AddAdr(k: INTEGER);   (* address of cell k, two levels: (super-cube)/(cell), e.g. (4,4,4)/(3,4,4) *)
  BEGIN AddCub(k DIV PC); Add("/"); AddPoz(k MOD PC)
  END AddAdr;

  PROCEDURE Text(n: INTEGER): BOOLEAN;   (* is blk[0..n) text? at least 3/4 printable characters or whitespace *)
    VAR i, k, c: INTEGER;
  BEGIN k := 0;
    FOR i := 0 TO n - 1 DO c := blk[i]; IF (c >= 32) & (c < 127) OR (c = 9) OR (c = 10) OR (c = 13) THEN INC(k) END END
    RETURN k * 4 >= n * 3
  END Text;

  PROCEDURE Celula(n: INTEGER);   (* blk[0..n) becomes cell nca, written to corp.tmp (hout) *)
    VAR i, a1, a2, w0: INTEGER;
  BEGIN
    a1 := 1; a2 := 0; FOR i := 0 TO n - 1 DO a1 := (a1 + blk[i]) MOD MOD32; a2 := (a2 + a1) MOD MOD32 END;
    cFp[nca] := Text(n); IF cFp[nca] THEN Amprenta(nca, n) END;
    IF nca = 0 THEN cBeg[0] := 0; cOff[0] := 0
    ELSE cBeg[nca] := cBeg[nca - 1] + cRaw[nca - 1]; cOff[nca] := cOff[nca - 1] + cComp[nca - 1]
    END;
    Restore; sp := FALSE; w0 := written; PackBlock(n);
    cRaw[nca] := n; cComp[nca] := written - w0; cS1[nca] := a1; cS2[nca] := a2;
    cArs[nca] := FALSE; cMarc[nca] := FALSE; cTip[nca] := FALSE; cLeg[nca] := FALSE; INC(nca)
  END Celula;

  PROCEDURE CelulaT(n: INTEGER; leg: BOOLEAN);   (* a cell of a run: the spatial model goes on from the cell before *)
    VAR i, a1, a2, w0: INTEGER;
  BEGIN
    a1 := 1; a2 := 0; FOR i := 0 TO n - 1 DO a1 := (a1 + blk[i]) MOD MOD32; a2 := (a2 + a1) MOD MOD32 END;
    cFp[nca] := FALSE;
    IF nca = 0 THEN cBeg[0] := 0; cOff[0] := 0
    ELSE cBeg[nca] := cBeg[nca - 1] + cRaw[nca - 1]; cOff[nca] := cOff[nca - 1] + cComp[nca - 1]
    END;
    sp := TRUE; w0 := written; PackBlock(n); sp := FALSE;
    cRaw[nca] := n; cComp[nca] := written - w0; cS1[nca] := a1; cS2[nca] := a2;
    cArs[nca] := FALSE; cMarc[nca] := FALSE; cTip[nca] := TRUE; cLeg[nca] := leg; INC(nca)
  END CelulaT;

  PROCEDURE LE(i, n: INTEGER): INTEGER;   (* little-endian number of n bytes from the header *)
    VAR r, k: INTEGER;
  BEGIN r := 0; FOR k := n - 1 TO 0 BY -1 DO r := r * 256 + hd[i + k] END
    RETURN r
  END LE;

  PROCEDURE Nr(VAR i: INTEGER): INTEGER;   (* a decimal number from a text header (PNM, Y4M), skipping spaces and comments *)
    VAR r: INTEGER;
  BEGIN
    r := -1;
    WHILE (i < nhd) & ((hd[i] = 32) OR (hd[i] = 10) OR (hd[i] = 13) OR (hd[i] = 9) OR (hd[i] = 35)) DO
      IF hd[i] = 35 THEN WHILE (i < nhd) & (hd[i] # 10) DO INC(i) END ELSE INC(i) END
    END;
    IF (i < nhd) & (hd[i] >= 48) & (hd[i] <= 57) THEN
      r := 0; WHILE (i < nhd) & (hd[i] >= 48) & (hd[i] <= 57) DO r := r * 10 + hd[i] - 48; INC(i) END
    END
    RETURN r
  END Nr;

  PROCEDURE Vede(VAR nm: ARRAY OF CHAR; marime0: INTEGER);   (* sets vKind: 0 plain, 1 BMP, 2 PNM, 3 WAV, 4 Y4M *)
    VAR h, b, i, k, w0, h0, bits, fmt, ba, cw, chh: INTEGER;
  BEGIN
    vKind := 0; nhd := 0; h := Fisier.Deschide(nm);
    IF h >= 0 THEN
      b := Fisier.Citeste(h); WHILE (b >= 0) & (nhd < 4096) DO hd[nhd] := b; INC(nhd); b := Fisier.Citeste(h) END; Fisier.Gata(h)
    END;
    vIn := 0; vMod := 2;
    IF (nhd >= 54) & (hd[0] = ORD("B")) & (hd[1] = ORD("M")) THEN   (* BMP *)
      IF (hd[21] = 0) & (hd[25] = 0) THEN w0 := LE(18, 4); h0 := LE(22, 4) ELSE w0 := 0; h0 := 0 END;   (* a top-down BMP (negative height) stays plain *)
      bits := LE(28, 2); k := LE(30, 4);
      IF (w0 > 0) & (w0 < 65536) & (h0 > 0) & ((bits = 8) OR (bits = 24) OR (bits = 32)) & ((k = 0) OR (k = 3)) THEN
        vKind := 1; vOff := LE(10, 4); vBpp := bits DIV 8; vWd := w0;
        vStr := (w0 * bits + 31) DIV 32 * 4; vPl := vStr * h0
      END
    ELSIF (nhd >= 16) & (hd[0] = ORD("P")) & ((hd[1] = ORD("5")) OR (hd[1] = ORD("6"))) THEN   (* PGM / PPM *)
      i := 2; w0 := Nr(i); h0 := Nr(i); k := Nr(i);
      IF (w0 > 0) & (h0 > 0) & (k > 0) & (k < 256) & (i < nhd) THEN
        vKind := 2; vOff := i + 1; IF hd[1] = ORD("5") THEN vBpp := 1 ELSE vBpp := 3 END;
        vWd := w0; vStr := w0 * vBpp; vPl := vStr * h0
      END
    ELSIF (nhd >= 44) & (hd[0] = ORD("R")) & (hd[1] = ORD("I")) & (hd[8] = ORD("W")) & (hd[9] = ORD("A")) THEN   (* WAV *)
      i := 12; fmt := 0; ba := 0;
      WHILE (i + 8 <= nhd) & (vKind = 0) DO
        k := LE(i + 4, 4);
        IF (hd[i] = ORD("f")) & (hd[i + 1] = ORD("m")) & (hd[i + 2] = ORD("t")) THEN fmt := LE(i + 8, 2); ba := LE(i + 20, 2) END;
        IF (hd[i] = ORD("d")) & (hd[i + 1] = ORD("a")) & (hd[i + 2] = ORD("t")) & (hd[i + 3] = ORD("a")) THEN
          IF (fmt = 1) & (ba > 0) & (ba <= 16) THEN
            vKind := 3; vOff := i + 8; vBpp := ba; vWd := 1; vStr := ba; vPl := 1073741824
          END;
          i := nhd
        ELSIF (k < 0) OR (k > 4096) THEN i := nhd
        ELSE i := i + 8 + k + k MOD 2
        END
      END
    ELSIF (nhd >= 20) & (hd[0] = ORD("Y")) & (hd[1] = ORD("U")) & (hd[2] = ORD("V")) & (hd[3] = ORD("4")) THEN   (* Y4M video *)
      i := 9; w0 := 0; h0 := 0; chh := 1;   (* chh: 0 mono, 1 = 4:2:0, 2 = 4:2:2, 3 = 4:4:4 *)
      WHILE (i < nhd) & (hd[i] # 10) DO
        IF (hd[i] = 32) & (i + 1 < nhd) THEN
          k := i + 2;
          IF hd[i + 1] = ORD("W") THEN w0 := Nr(k)
          ELSIF hd[i + 1] = ORD("H") THEN h0 := Nr(k)
          ELSIF hd[i + 1] = ORD("C") THEN
            IF (k + 3 < nhd) & (hd[k] = ORD("m")) THEN chh := 0   (* mono: only the Y plane *)
            ELSIF (k + 2 < nhd) & (hd[k] = ORD("4")) & (hd[k + 1] = ORD("4")) & (hd[k + 2] = ORD("4")) THEN chh := 3
            ELSIF (k + 2 < nhd) & (hd[k] = ORD("4")) & (hd[k + 1] = ORD("2")) & (hd[k + 2] = ORD("2")) THEN chh := 2
            END
          END
        END;
        INC(i)
      END;
      IF (w0 > 0) & (h0 > 0) & (i < nhd) THEN
        IF chh = 0 THEN cw := w0 * h0   (* bytes in one frame *)
        ELSIF chh = 1 THEN cw := w0 * h0 + 2 * ((w0 + 1) DIV 2) * ((h0 + 1) DIV 2)
        ELSIF chh = 2 THEN cw := w0 * h0 + 2 * ((w0 + 1) DIV 2) * h0
        ELSE cw := 3 * w0 * h0
        END;
        vKind := 4; vOff := i + 1; vBpp := 1; vWd := w0; vStr := w0; vIn := 6; vPl := cw + 6; vMod := 3
      END
    END;
    IF vKind = 0 THEN vOff := 0; vStr := 1; vBpp := 1; vWd := 1; vPl := 1; vIn := 0; vMod := 0 END
  END Vede;

  PROCEDURE Viu(VAR n: ARRAY OF CHAR): BOOLEAN;   (* compressible? the 16 most frequent byte values in the first 4 KB *)
    VAR h, b, k, i, j, m, sus: INTEGER; cnt: ARRAY 256 OF INTEGER;
  BEGIN
    FOR i := 0 TO 255 DO cnt[i] := 0 END; k := 0; sus := 0;
    h := Fisier.Deschide(n);
    IF h >= 0 THEN
      b := Fisier.Citeste(h); WHILE (b >= 0) & (k < 4096) DO INC(cnt[b]); INC(k); b := Fisier.Citeste(h) END; Fisier.Gata(h)
    END;
    FOR j := 1 TO 16 DO   (* the 16 largest *)
      m := 0; FOR i := 1 TO 255 DO IF cnt[i] > cnt[m] THEN m := i END END;
      sus := sus + cnt[m]; cnt[m] := -1
    END
    RETURN (k > 0) & (sus * 5 > k)   (* over 20%: text or something with patterns; noise (photos, archives) stays out *)
  END Viu;

  PROCEDURE Ou(VAR total: INTEGER);   (* the Egg: samples from the compressible files; written to ou.tmp *)
    VAR i, k, h, b, cat, a1, a2, w0, nv, pas, urm, felie: INTEGER; viu: ARRAY NF OF BOOLEAN;
  BEGIN
    eggLen := 0;
    IF total > CS THEN
      nv := 0; FOR i := 0 TO nf - 1 DO viu[i] := Viu(nume[i]); IF viu[i] THEN INC(nv) END END;
      (* 1 KB slices taken at equal distances over the whole stream: every cell finds its words in the Egg *)
      cat := Min(EGG, total DIV 8); k := 0;
      IF cat >= 1024 THEN pas := total DIV (cat DIV 1024) ELSE pas := total + 1 END;
      urm := pas DIV 2;
      FOR i := 0 TO nf - 1 DO
        IF viu[i] THEN h := Fisier.Deschide(nume[i]) ELSE h := -1 END;
        IF h >= 0 THEN
          b := Fisier.Citeste(h); felie := 0;
          WHILE (b >= 0) & (eggLen < cat) DO
            IF k >= urm THEN felie := 1024; urm := urm + pas END;
            IF felie > 0 THEN blk[eggLen] := b; INC(eggLen); DEC(felie) END;
            INC(k); b := Fisier.Citeste(h)
          END;
          Fisier.Gata(h)
        ELSE k := k + marime[i]
        END
      END
    END;
    a1 := 1; a2 := 0; FOR i := 0 TO eggLen - 1 DO a1 := (a1 + blk[i]) MOD MOD32; a2 := (a2 + a1) MOD MOD32 END;
    eggS1 := a1; eggS2 := a2;
    Reset;
    hout := Fisier.Creeaza("ou.tmp"); w0 := written;
    IF eggLen > 0 THEN PackBlock(eggLen) END;   (* the model has learned the Egg *)
    eggC := written - w0; Fisier.Gata(hout);
    Save
  END Ou;

  PROCEDURE ScrieArhiva(VAR nm: ARRAY OF CHAR): BOOLEAN;   (* header + map + the Egg twice + the cells *)
    VAR i, j, len, e1, e2: INTEGER; ok: BOOLEAN;
  BEGIN
    hout := Fisier.Creeaza(nm); ok := hout >= 0;
    IF ok THEN
      written := 0; Put(ORD("Z")); Put(ORD("7")); Put(ORD("C")); Put(6);
      ms1 := 1; ms2 := 0;
      PutInt(nfa); PutInt(nca); PutInt(CS); PutInt(eggLen); PutInt(eggC); PutInt(eggS1); PutInt(eggS2);
      FOR i := 0 TO nfa - 1 DO
        len := 0; WHILE (len < 63) & (fNm[i, len] # 0X) DO INC(len) END;
        Put(len); FOR j := 0 TO len - 1 DO Put(ORD(fNm[i, j])) END;
        PutInt(fStart[i]); PutInt(fLen[i]); PutInt(fS1[i]); PutInt(fS2[i]);
        Put(fKind[i]);
        IF fKind[i] > 0 THEN PutInt(fOff[i]); PutInt(fStr[i]); PutInt(fBpp[i]); PutInt(fWd[i]); PutInt(fPl[i]); PutInt(fIn[i]); PutInt(fMod[i]) END
      END;
      FOR i := 0 TO nca - 1 DO
        PutInt(cRaw[i]); PutInt(cComp[i]); PutInt(cS1[i]); PutInt(cS2[i]);
        len := 0; IF cFp[i] THEN len := 1 END; IF cTip[i] THEN len := len + 2 END; IF cLeg[i] THEN len := len + 4 END;
        Put(len); IF cFp[i] THEN FOR j := 0 TO FPB - 1 DO Put(ORD(fp[i * FPB + j])) END END
      END;
      e1 := ms1; e2 := ms2; PutInt(e1); PutInt(e2);
      CopiazaIn("ou.tmp"); CopiazaIn("ou.tmp");
      CopiazaIn("corp.tmp");
      Fisier.Gata(hout)
    END;
    Fisier.Sterge("ou.tmp"); Fisier.Sterge("corp.tmp")
    RETURN ok
  END ScrieArhiva;

  PROCEDURE Strange(VAR intrat: INTEGER): BOOLEAN;   (* the files in nume[] become new cells, in corp.tmp *)
    VAR i, h, b, n, a1, a2, sum, dus: INTEGER; ok, leg: BOOLEAN; nm: ARRAY 80 OF CHAR;
  BEGIN
    sum := 0; FOR i := 0 TO nf - 1 DO sum := sum + marime[i] END;
    IF nca > 0 THEN dus := cBeg[nca - 1] + cRaw[nca - 1] ELSE dus := 0 END;
    ok := (nfa + nf <= NF) & (nca + (sum + CS - 1) DIV CS + nf <= NC);
    IF ok THEN
      n := 0; intrat := 0;
      FOR i := 0 TO nf - 1 DO
        Baza(nume[i], nm); nm[63] := 0X; Cop(nm, fNm[nfa]); fStart[nfa] := dus + intrat;
        a1 := 1; a2 := 0;
        Vede(nume[i], marime[i]);
        fKind[nfa] := vKind; fOff[nfa] := vOff; fStr[nfa] := vStr; fBpp[nfa] := vBpp; fWd[nfa] := vWd; fPl[nfa] := vPl; fIn[nfa] := vIn; fMod[nfa] := vMod;
        IF vKind > 0 THEN   (* a run of its own: start on a fresh cell *)
          IF n > 0 THEN Celula(n); n := 0 END;
          Spatiu.Start(vOff, vStr, vBpp, vWd, vPl, vIn, vMod); fMod[nfa] := Spatiu.Mod(); leg := FALSE;
          fStart[nfa] := dus + intrat
        END;
        h := Fisier.Deschide(nume[i]);
        IF h >= 0 THEN
          b := Fisier.Citeste(h);
          WHILE b >= 0 DO
            blk[n] := b; INC(n); INC(intrat); a1 := (a1 + b) MOD MOD32; a2 := (a2 + a1) MOD MOD32;
            IF n = CS THEN
              IF vKind > 0 THEN CelulaT(n, leg); leg := TRUE ELSE Celula(n) END;
              n := 0
            END;
            b := Fisier.Citeste(h)
          END;
          Fisier.Gata(h)
        END;
        IF (vKind > 0) & (n > 0) THEN CelulaT(n, leg); n := 0 END;
        fLen[nfa] := dus + intrat - fStart[nfa]; fS1[nfa] := a1; fS2[nfa] := a2;
        fArs[nfa] := FALSE; fScos[nfa] := FALSE; INC(nfa)
      END;
      IF n > 0 THEN Celula(n) END
    END
    RETURN ok
  END Strange;

  PROCEDURE Sari(la: INTEGER);   (* no seek in files: read up to there *)
    VAR b: INTEGER;
  BEGIN
    IF inByte > la THEN Fisier.Gata(hin); hin := Fisier.Deschide(arh); inByte := 0 END;
    IF hin < 0 THEN bad := TRUE END;
    WHILE (inByte < la) & ~bad DO b := Get() END
  END Sari;

  PROCEDURE DesfaUna(k: INTEGER): BOOLEAN;   (* one cell, from the model state it needs (plain: the Egg; run: the cell before) *)
    VAR n, s1, s2: INTEGER;
  BEGIN
    bad := FALSE; Sari(dataStart + cOff[k]);
    sp := cTip[k]; IF ~sp THEN Restore END;
    n := GetInt();
    IF bad OR (n # cRaw[k]) THEN bad := TRUE
    ELSE s1 := 1; s2 := 0; UnpackBlock(n, s1, s2); IF (s1 # cS1[k]) OR (s2 # cS2[k]) THEN bad := TRUE END
    END;
    sp := FALSE; INC(citite);
    IF bad THEN cArs[k] := TRUE END
    RETURN ~bad
  END DesfaUna;

  PROCEDURE Desface(k: INTEGER): BOOLEAN;   (* cell k into blk; hin is open *)
    VAR j, f: INTEGER; ok: BOOLEAN;
  BEGIN
    IF k # ultimCel THEN
      IF ~cTip[k] THEN ok := DesfaUna(k)
      ELSE
        IF cLeg[k] & (ultimCel = k - 1) & ultimTip THEN j := k   (* the run goes on *)
        ELSE   (* start the run from its first cell *)
          j := k; WHILE (j > 0) & cLeg[j] DO DEC(j) END;
          ok := TRUE; f := j; WHILE f < k DO IF cArs[f] THEN ok := FALSE END; INC(f) END;   (* a cell before burned: this one burns too *)
          IF ~ok THEN j := k + 1 END;
          f := 0; WHILE (f < nfa - 1) & ~((fKind[f] > 0) & (fStart[f] = cBeg[j])) DO INC(f) END;
          Spatiu.Start(fOff[f], fStr[f], fBpp[f], fWd[f], fPl[f], fIn[f], fMod[f])
        END;
        IF j <= k THEN ok := TRUE END;
        WHILE ok & (j <= k) DO ok := DesfaUna(j); INC(j) END
      END;
      IF ok THEN ultimCel := k; ultimTip := cTip[k] ELSE cArs[k] := TRUE; ultimCel := -1; ultimTip := FALSE END
    END
    RETURN k = ultimCel
  END Desface;

  PROCEDURE OuDin(): BOOLEAN;   (* the Egg from the archive: the model reads it and learns; hin is at its start *)
    VAR n, s1, s2, start: INTEGER; ok: BOOLEAN;
  BEGIN
    start := inByte; Reset; ok := TRUE;
    IF eggLen > 0 THEN
      bad := FALSE; n := GetInt(); ok := ~bad & (n = eggLen) & (n <= CS);
      IF ok THEN s1 := 1; s2 := 0; UnpackBlock(n, s1, s2); ok := ~bad & (s1 = eggS1) & (s2 = eggS2) END
    END;
    IF ok THEN oulBun := 1; Save
    ELSE
      bad := FALSE; Sari(start + eggC); Reset;   (* the first Egg burned: the second one *)
      n := GetInt(); ok := ~bad & (n = eggLen) & (n <= CS);
      IF ok THEN s1 := 1; s2 := 0; UnpackBlock(n, s1, s2); ok := ~bad & (s1 = eggS1) & (s2 = eggS2) END;
      IF ok THEN oulBun := 2; Save ELSE oulBun := 0 END
    END;
    dataStart := start + 2 * eggC
    RETURN ok
  END OuDin;

  PROCEDURE Fragment(k, i: INTEGER);   (* the result: the file and the surrounding line *)
    VAR p, f, a, j, c: INTEGER;
  BEGIN
    p := cBeg[k] + i; f := 0;
    WHILE (f < nfa - 1) & ~((p >= fStart[f]) & (p < fStart[f] + fLen[f])) DO INC(f) END;
    hitF[nh] := f;
    j := 0; a := i; WHILE (a > 0) & (i - a < 10) & (blk[a - 1] # 10) DO DEC(a) END;
    WHILE (j < 38) & (a < cRaw[k]) & (blk[a] # 10) DO
      c := blk[a]; IF (c < 32) OR (c > 126) THEN c := 32 END;
      hitS[nh, j] := CHR(c); INC(j); INC(a)
    END;
    hitS[nh, j] := 0X; INC(nh)
  END Fragment;

  PROCEDURE Gaseste(k: INTEGER);   (* the word in cell k (already in blk) *)
    VAR i, j, n: INTEGER; ok: BOOLEAN;
  BEGIN
    n := cRaw[k]; i := 0;
    WHILE (i <= n - nq) & (nh < NH) DO
      j := 0; ok := TRUE;
      IF (i > 0) & Litera(Low(blk[i - 1])) THEN ok := FALSE END;   (* at the start of a word *)
      WHILE ok & (j < nq) DO IF Low(blk[i + j]) # Low(ORD(q[j])) THEN ok := FALSE END; INC(j) END;
      IF ok THEN Fragment(k, i); i := i + nq ELSE INC(i) END
    END
  END Gaseste;

  (* ---------- the lines for the shell ---------- *)

  PROCEDURE Rand(c: INTEGER);   (* sir becomes an output line *)
    VAR i: INTEGER;
  BEGIN
    IF nout < NL THEN
      i := 0; WHILE (i < 45) & (sir[i] # 0X) DO out[nout, i] := sir[i]; INC(i) END; out[nout, i] := 0X;
      outc[nout] := c; INC(nout)
    END
  END Rand;

  PROCEDURE Spune(tx: ARRAY OF CHAR; c: INTEGER);
  BEGIN Clr; Add(tx); Rand(c)
  END Spune;

  PROCEDURE Lines*(): INTEGER;
  BEGIN RETURN nout
  END Lines;

  PROCEDURE Line*(i: INTEGER; VAR tx: ARRAY OF CHAR): INTEGER;   (* line i; returns its colour: 0 white, 1 green, 2 red, 3 gold *)
    VAR j, c: INTEGER;
  BEGIN
    j := 0; c := ALB;
    IF (i >= 0) & (i < nout) THEN
      WHILE (j < LEN(tx) - 1) & (out[i, j] # 0X) DO tx[j] := out[i, j]; INC(j) END; c := outc[i]
    END;
    tx[j] := 0X
    RETURN c
  END Line;

  PROCEDURE Known*(nm: ARRAY OF CHAR);   (* one file of Cubicum N (the shell calls this for each, before Command) *)
    VAR j: INTEGER;
  BEGIN
    IF nk < 300 THEN j := 0; WHILE (j < 39) & (j < LEN(nm)) & (nm[j] # 0X) DO known[nk, j] := nm[j]; INC(j) END; known[nk, j] := 0X; INC(nk) END
  END Known;

  (* ---------- small helpers ---------- *)

  PROCEDURE Lung(a: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(a)) & (a[i] # 0X) DO INC(i) END
    RETURN i
  END Lung;

  PROCEDURE Acelasi(a, b: ARRAY OF CHAR): BOOLEAN;   (* the same name, small or capital letters alike *)
    VAR i: INTEGER; r: BOOLEAN;
  BEGIN
    i := 0; r := TRUE;
    WHILE r & (i < LEN(a)) & (i < LEN(b)) & ((a[i] # 0X) OR (b[i] # 0X)) DO
      IF Low(ORD(a[i])) # Low(ORD(b[i])) THEN r := FALSE END; INC(i)
    END
    RETURN r
  END Acelasi;

  PROCEDURE Termina(a, e: ARRAY OF CHAR): BOOLEAN;   (* a ends with e (small/capital alike) *)
    VAR la, le, i: INTEGER; r: BOOLEAN;
  BEGIN
    la := Lung(a); le := Lung(e); r := la >= le; i := 0;
    WHILE r & (i < le) DO IF Low(ORD(a[la - le + i])) # Low(ORD(e[i])) THEN r := FALSE END; INC(i) END
    RETURN r
  END Termina;

  PROCEDURE Exista(VAR n: ARRAY OF CHAR): BOOLEAN;
    VAR h: INTEGER;
  BEGIN h := Fisier.Deschide(n); IF h >= 0 THEN Fisier.Gata(h) END
    RETURN h >= 0
  END Exista;

  PROCEDURE Lungime(VAR n: ARRAY OF CHAR): INTEGER;
    VAR h, b, k: INTEGER;
  BEGIN k := 0; h := Fisier.Deschide(n);
    IF h >= 0 THEN b := Fisier.Citeste(h); WHILE b >= 0 DO INC(k); b := Fisier.Citeste(h) END; Fisier.Gata(h) END
    RETURN k
  END Lungime;

  PROCEDURE Copiaza(VAR de, la: ARRAY OF CHAR);
    VAR a, b, c: INTEGER;
  BEGIN
    a := Fisier.Deschide(de); b := Fisier.Creeaza(la);
    IF (a >= 0) & (b >= 0) THEN c := Fisier.Citeste(a); WHILE c >= 0 DO Fisier.Scrie(b, c); c := Fisier.Citeste(a) END END;
    IF a >= 0 THEN Fisier.Gata(a) END; IF b >= 0 THEN Fisier.Gata(b) END
  END Copiaza;

  (* ---------- reading a cube ---------- *)

  PROCEDURE Deschide(): BOOLEAN;   (* arh: map + Egg *)
    VAR i, j, len, e1, e2, cs: INTEGER; ok: BOOLEAN;
  BEGIN
    ultimCel := -1; ok := FALSE;
    hin := Fisier.Deschide(arh); bad := FALSE; inByte := 0;
    IF hin < 0 THEN Clr; Add("NO CUBE "); Add(arh); Rand(ROSU)
    ELSIF (Get() # ORD("Z")) OR (Get() # ORD("7")) THEN Clr; Add(arh); Add(" IS NOT A Z7 ARCH CUBE"); Rand(ROSU); Fisier.Gata(hin)
    ELSE
      i := Get(); j := Get();
      IF (i # ORD("C")) OR (j < 4) OR (j > 6) THEN Spune("NOT A .Z7C CUBE (FORMAT 4 TO 6)", ROSU); Fisier.Gata(hin)
      ELSE
        ver := j; ms1 := 1; ms2 := 0;
        nfa := GetInt(); nca := GetInt(); cs := GetInt(); eggLen := GetInt(); eggC := GetInt(); eggS1 := GetInt(); eggS2 := GetInt();
        IF bad OR (nfa < 0) OR (nfa > NF) OR (nca < 0) OR (nca > NC) OR (cs # CS) OR (eggLen > EGG) THEN bad := TRUE
        ELSE
          i := 0;
          WHILE (i < nfa) & ~bad DO
            len := Get(); IF len > 63 THEN bad := TRUE; len := 0 END;
            FOR j := 0 TO len - 1 DO fNm[i, j] := CHR(Get()) END; fNm[i, len] := 0X;
            fStart[i] := GetInt(); fLen[i] := GetInt(); fS1[i] := GetInt(); fS2[i] := GetInt();
            IF ver >= 6 THEN fKind[i] := Get() ELSE fKind[i] := 0 END;
            IF fKind[i] > 0 THEN
              fOff[i] := GetInt(); fStr[i] := GetInt(); fBpp[i] := GetInt(); fWd[i] := GetInt(); fPl[i] := GetInt(); fIn[i] := GetInt(); fMod[i] := GetInt()
            END;
            fArs[i] := FALSE; fScos[i] := FALSE; INC(i)
          END;
          i := 0;
          WHILE (i < nca) & ~bad DO
            cRaw[i] := GetInt(); cComp[i] := GetInt(); cS1[i] := GetInt(); cS2[i] := GetInt();
            IF ver = 4 THEN len := 1 ELSE len := Get() END;
            cFp[i] := ODD(len); cTip[i] := ODD(len DIV 2); cLeg[i] := ODD(len DIV 4);
            IF cFp[i] THEN FOR j := 0 TO FPB - 1 DO fp[i * FPB + j] := CHR(Get()) END END;
            IF i = 0 THEN cBeg[0] := 0; cOff[0] := 0
            ELSE cBeg[i] := cBeg[i - 1] + cRaw[i - 1]; cOff[i] := cOff[i - 1] + cComp[i - 1]
            END;
            IF (cRaw[i] < 1) OR (cRaw[i] > CS) THEN bad := TRUE END;
            cArs[i] := FALSE; cMarc[i] := FALSE; INC(i)
          END
        END;
        e1 := ms1; e2 := ms2;
        IF bad OR (GetInt() # e1) OR (GetInt() # e2) THEN Spune("ASH: THE MAP BURNED, CANNOT READ", ROSU); Fisier.Gata(hin)
        ELSE
          IF ~OuDin() THEN Spune("ASH: THE EGG BURNED (BOTH COPIES)", ROSU)
          ELSIF oulBun = 2 THEN Spune("FIRST EGG BURNED, USING THE SECOND", AUR)
          END;
          Fisier.Gata(hin); ok := oulBun > 0
        END
      END
    END
    RETURN ok
  END Deschide;

  PROCEDURE Scoate(f: INTEGER; VAR cale: ARRAY OF CHAR): BOOLEAN;   (* only the cells of file f, into the file cale; hin is open *)
    VAR k, i, a, b, p0, p1, s1, s2, h: INTEGER; ok: BOOLEAN;
  BEGIN
    h := Fisier.Creeaza(cale); ok := h >= 0; s1 := 1; s2 := 0;
    p0 := fStart[f]; p1 := p0 + fLen[f]; k := 0;
    WHILE ok & (k < nca) DO
      IF (cBeg[k] < p1) & (cBeg[k] + cRaw[k] > p0) THEN
        IF Desface(k) THEN
          a := Max(p0, cBeg[k]) - cBeg[k]; b := Min(p1, cBeg[k] + cRaw[k]) - cBeg[k];
          FOR i := a TO b - 1 DO Fisier.Scrie(h, blk[i]); s1 := (s1 + blk[i]) MOD MOD32; s2 := (s2 + s1) MOD MOD32 END
        ELSE ok := FALSE
        END
      END;
      INC(k)
    END;
    IF h >= 0 THEN Fisier.Gata(h) END;
    IF ok & ((s1 # fS1[f]) OR (s2 # fS2[f])) THEN ok := FALSE END;
    IF ~ok THEN fArs[f] := TRUE; Fisier.Sterge(cale) END
    RETURN ok
  END Scoate;

  PROCEDURE Liber(VAR n, d: ARRAY OF CHAR);   (* a name not yet used: n, or n with -2, -3 ... before the extension *)
    VAR i, k, p, nr: INTEGER;
  BEGIN
    Cop(n, d); nr := 2;
    WHILE Exista(d) & (nr < 100) DO
      i := Lung(n); p := i; WHILE (p > 0) & (n[p] # ".") DO DEC(p) END; IF p = 0 THEN p := i END;
      k := 0; WHILE (k < p) & (k < 50) DO d[k] := n[k]; INC(k) END;
      d[k] := "-"; INC(k); IF nr >= 10 THEN d[k] := CHR(ORD("0") + nr DIV 10); INC(k) END; d[k] := CHR(ORD("0") + nr MOD 10); INC(k);
      WHILE (p < i) & (k < LEN(d) - 1) DO d[k] := n[p]; INC(k); INC(p) END; d[k] := 0X; INC(nr)
    END
  END Liber;

  (* ---------- the commands ---------- *)

  PROCEDURE Lista;
    VAR f, k, n: INTEGER; nm: ARRAY 64 OF CHAR;
  BEGIN
    IF Deschide() THEN
      Clr; Add(arh); Add(": "); AddN(nfa); Add(" FILES, "); AddN(nca); Add(" CELLS"); Rand(VERDE);
      FOR f := 0 TO nfa - 1 DO
        Cop(fNm[f], nm); nm[18] := 0X; Clr; Add(nm); Add(" "); AddK(fLen[f]);
        k := 0; WHILE (k < nca) & ~((cBeg[k] <= fStart[f]) & (cBeg[k] + cRaw[k] > fStart[f])) DO INC(k) END;
        IF k < nca THEN Add(" "); AddAdr(k) END;
        IF fKind[f] = 3 THEN Add(" WAV") ELSIF fKind[f] = 4 THEN Add(" 3D") ELSIF fKind[f] > 0 THEN Add(" 2D") END;
        Rand(ALB)
      END;
      n := 0; FOR k := 0 TO nca - 1 DO n := n + cComp[k] END;
      Clr; Add("PACKED "); AddK(n); Add(" . ADDRESS: (SUPER-CUBE)/(CELL)"); Rand(AUR)
    END
  END Lista;

  PROCEDURE Gaseste1(VAR nm: ARRAY OF CHAR): INTEGER;   (* which file of the cube has this name *)
    VAR f: INTEGER;
  BEGIN f := 0; WHILE (f < nfa) & ~Acelasi(fNm[f], nm) DO INC(f) END;
    IF f = nfa THEN f := -1 END
    RETURN f
  END Gaseste1;

  PROCEDURE Scoate1(VAR nm: ARRAY OF CHAR);
    VAR f: INTEGER; d: ARRAY 64 OF CHAR;
  BEGIN
    IF Deschide() THEN
      f := Gaseste1(nm);
      IF f < 0 THEN Clr; Add(nm); Add(" IS NOT IN "); Add(arh); Rand(ROSU)
      ELSE
        Liber(fNm[f], d); citite := 0; ultimCel := -1;
        hin := Fisier.Deschide(arh); inByte := 0; bad := FALSE;
        IF Scoate(f, d) THEN
          Clr; Add("GOT "); Add(d); Add(" ("); AddK(fLen[f]); Add(")"); Rand(VERDE);
          Clr; Add("READ "); AddN(citite); Add(" OF "); AddN(nca); Add(" CELLS"); Rand(ALB)
        ELSE Clr; Add("ASH: "); Add(fNm[f]); Add(" BURNED"); Rand(ROSU)
        END;
        Fisier.Gata(hin)
      END
    END
  END Scoate1;

  PROCEDURE ScoateTot;
    VAR f, nb, nbun: INTEGER; d: ARRAY 64 OF CHAR;
  BEGIN
    IF Deschide() THEN
      citite := 0; ultimCel := -1; nb := 0; nbun := 0;
      hin := Fisier.Deschide(arh); inByte := 0; bad := FALSE;
      FOR f := 0 TO nfa - 1 DO
        Liber(fNm[f], d);
        IF Scoate(f, d) THEN INC(nbun); IF ~Acelasi(d, fNm[f]) THEN Clr; Add(fNm[f]); Add(" -> "); Add(d); Rand(ALB) END
        ELSE INC(nb); Clr; Add("ASH: "); Add(fNm[f]); Add(" BURNED"); Rand(ROSU)
        END
      END;
      Fisier.Gata(hin);
      Clr; Add("GOT "); AddN(nbun); Add(" FILE(S) FROM "); Add(arh); Rand(VERDE)
    END
  END ScoateTot;

  PROCEDURE Verifica;
    VAR k, f, nb, na: INTEGER; ok: BOOLEAN;
  BEGIN
    IF Deschide() THEN
      citite := 0; ultimCel := -1; nb := 0;
      hin := Fisier.Deschide(arh); inByte := 0; bad := FALSE;
      FOR k := 0 TO nca - 1 DO ok := Desface(k); IF ~ok THEN INC(nb) END END;
      Fisier.Gata(hin);
      na := 0;
      FOR f := 0 TO nfa - 1 DO
        FOR k := 0 TO nca - 1 DO
          IF cArs[k] & (cBeg[k] < fStart[f] + fLen[f]) & (cBeg[k] + cRaw[k] > fStart[f]) THEN fArs[f] := TRUE END
        END;
        IF fArs[f] THEN INC(na) END
      END;
      IF nb = 0 THEN Clr; Add("ALL "); AddN(nca); Add(" CELLS ARE GOOD"); Rand(VERDE)
      ELSE
        k := 0; WHILE k < nca DO IF cArs[k] THEN Clr; Add("ASH: CELL "); AddAdr(k); Rand(ROSU) END; INC(k) END;
        Clr; AddN(na); Add(" FILE(S) HIT, "); AddN(nfa - na); Add(" WHOLE"); Rand(ALB)
      END
    END
  END Verifica;

  PROCEDURE Cauta;
    VAR k, j: INTEGER; ok: BOOLEAN;
  BEGIN
    nh := 0;
    IF nq = 0 THEN Spune("FIND WHAT? LIKE: ARCH FIND NOTES SALAMANDRA", ROSU)
    ELSIF Deschide() THEN
      nqb := 0; h1 := 0; h2 := 0; hl := 0;
      FOR j := 0 TO nq DO
        IF j < nq THEN ok := Cuvant(ORD(q[j])) ELSE ok := Cuvant(32) END;
        IF ok THEN
          IF ((j < nq) OR (hl >= 6)) & (nqb < 20) THEN qb1[nqb] := h1 MOD FB; qb2[nqb] := h2 MOD FB; INC(nqb) END;
          h1 := 0; h2 := 0; hl := 0
        END
      END;
      citite := 0; ultimCel := -1; sarite := 0;
      hin := Fisier.Deschide(arh); inByte := 0; bad := FALSE;
      FOR k := 0 TO nca - 1 DO
        ok := cFp[k]; j := 0; IF ~ok THEN INC(sarite) END;
        WHILE ok & (j < nqb) DO ok := Are(k, qb1[j]) & Are(k, qb2[j]); INC(j) END;
        IF ok & (nh < NH) THEN IF Desface(k) THEN Gaseste(k) END END
      END;
      Fisier.Gata(hin);
      FOR k := 0 TO Min(nh, 12) - 1 DO
        Clr; Cop(fNm[hitF[k]], sir); sir[14] := 0X; ls := Lung(sir); Add(": "); Add(hitS[k]); Rand(ALB)
      END;
      Clr; AddN(nh); IF nh >= NH THEN Add("+") END; Add(" FOUND, READ "); AddN(citite); Add(" OF "); AddN(nca); Add(" CELLS"); Rand(VERDE)
    END
  END Cauta;

  PROCEDURE Alege(de: INTEGER): BOOLEAN;   (* the files named from word de on: names, ALL, or .EXT *)
    VAR i, k: INTEGER; ext: ARRAY 64 OF CHAR; tot: BOOLEAN;
  BEGIN
    nf := 0; tot := FALSE; ext[0] := 0X;
    IF ncmd <= de THEN tot := TRUE
    ELSIF Acelasi(cmd[de], "all") THEN tot := TRUE
    ELSIF cmd[de, 0] = "." THEN tot := TRUE; Cop(cmd[de], ext)
    END;
    IF tot THEN
      FOR k := 0 TO nk - 1 DO
        IF (nf < NF) & ~Termina(known[k], ".z7c") & ~Termina(known[k], ".tmp") & ((ext[0] = 0X) OR Termina(known[k], ext)) THEN
          Cop(known[k], nume[nf]); INC(nf)
        END
      END
    ELSE
      FOR i := de TO ncmd - 1 DO
        IF Exista(cmd[i]) THEN IF nf < NF THEN Cop(cmd[i], nume[nf]); INC(nf) END
        ELSE Clr; Add("NO FILE "); Add(cmd[i]); Rand(ROSU)
        END
      END
    END;
    FOR i := 0 TO nf - 1 DO marime[i] := Lungime(nume[i]) END
    RETURN nf > 0
  END Alege;

  PROCEDURE Impacheteaza;
    VAR i, intrat: INTEGER;
  BEGIN
    IF Exista(arh) THEN Clr; Add(arh); Add(" EXISTS: ARCH ADD, OR RM IT FIRST"); Rand(ROSU)
    ELSIF ~Alege(3) THEN Spune("NO FILES TO PACK", ROSU)
    ELSE
      intrat := 0; FOR i := 0 TO nf - 1 DO intrat := intrat + marime[i] END;
      nfa := 0; nca := 0; written := 0;
      Ou(intrat);
      hout := Fisier.Creeaza("corp.tmp"); written := 0;
      IF ~Strange(intrat) THEN Fisier.Gata(hout); Fisier.Sterge("corp.tmp"); Fisier.Sterge("ou.tmp"); Spune("TOO MUCH: MAX 7 CUBES, 128 FILES", ROSU)
      ELSE
        Fisier.Gata(hout);
        IF ScrieArhiva(arh) THEN
          Clr; AddN(nf); Add(" FILE(S): "); AddK(intrat); Add(" -> "); AddK(written);
          IF intrat > 0 THEN Add(" ("); AddN(written * 100 DIV intrat); Add("%)") END; Rand(VERDE);
          Clr; Add(arh); Add(": "); AddN(nca); Add(" CELL(S) AROUND THE EGG"); Rand(ALB);
          i := 0; FOR intrat := 0 TO nfa - 1 DO IF fKind[intrat] > 0 THEN INC(i) END END;
          IF i > 0 THEN Clr; Add("SEEN WITH SHAPE: "); AddN(i); Add(" FILE(S)"); Rand(AUR) END
        ELSE Spune("CANNOT WRITE THE CUBE", ROSU)
        END
      END
    END
  END Impacheteaza;

  PROCEDURE Adauga;   (* new files into an existing cube: the old cells are copied as they are *)
    VAR i, h, b, intrat, vechi: INTEGER; nou: ARRAY 64 OF CHAR;
  BEGIN
    IF ~Alege(3) THEN Spune("NO FILES TO ADD", ROSU)
    ELSIF Deschide() THEN
      hin := Fisier.Deschide(arh); inByte := 0; bad := FALSE;
      Sari(dataStart - 2 * eggC + (oulBun - 1) * eggC);
      hout := Fisier.Creeaza("ou.tmp"); FOR i := 1 TO eggC DO Fisier.Scrie(hout, Get()) END; Fisier.Gata(hout);
      Sari(dataStart);
      hout := Fisier.Creeaza("corp.tmp"); written := 0; vechi := 0;
      IF nca > 0 THEN vechi := cOff[nca - 1] + cComp[nca - 1] END;
      FOR i := 1 TO vechi DO Put(Get()) END;
      Fisier.Gata(hin);
      h := nca; b := nfa;
      IF bad OR ~Strange(intrat) THEN Fisier.Gata(hout); Fisier.Sterge("corp.tmp"); Fisier.Sterge("ou.tmp"); Spune("CANNOT ADD (TOO MUCH?)", ROSU)
      ELSE
        Fisier.Gata(hout);
        nou := "arch-new.tmp";
        IF ScrieArhiva(nou) THEN
          Fisier.Sterge(arh); Copiaza(nou, arh); Fisier.Sterge(nou);
          Clr; Add("+"); AddN(nfa - b); Add(" FILE(S), +"); AddN(nca - h); Add(" NEW CELL(S)"); Rand(VERDE);
          Clr; Add("THE "); AddN(h); Add(" OLD CELLS COPIED, NOT REPACKED"); Rand(ALB)
        ELSE Spune("CANNOT WRITE THE CUBE", ROSU)
        END
      END
    END
  END Adauga;

  PROCEDURE Ajutor;
  BEGIN
    Spune("ARCH: Z7 ARCH CUBES (.Z7C) IN CUBICUM N", AUR);
    Spune("ARCH PACK C [FILES|ALL|.MOD] MAKE C.Z7C", ALB);
    Spune("ARCH LIST C        FILES AND THEIR CELLS", ALB);
    Spune("ARCH GET C FILE    TAKE ONE FILE OUT", ALB);
    Spune("ARCH ALL C         TAKE EVERYTHING OUT", ALB);
    Spune("ARCH FIND C WORD   SEARCH INSIDE THE CUBE", ALB);
    Spune("ARCH CHECK C       EVERY CELL (THE ASH)", ALB);
    Spune("ARCH ADD C FILES   ADD, OLD CELLS KEPT", ALB)
  END Ajutor;

  PROCEDURE Imparte(s: ARRAY OF CHAR);   (* the words of the command, as typed; rest = all after word 3 *)
    VAR i, j: INTEGER;
  BEGIN
    ncmd := 0; i := 0; rest[0] := 0X;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (ncmd < 8) DO
      WHILE (i < LEN(s)) & (s[i] = " ") DO INC(i) END;
      IF (ncmd = 3) & (i < LEN(s)) THEN   (* the rest of the line, for FIND *)
        j := 0; WHILE (i + j < LEN(s)) & (s[i + j] # 0X) & (j < 39) DO rest[j] := s[i + j]; INC(j) END; rest[j] := 0X
      END;
      IF (i < LEN(s)) & (s[i] # 0X) THEN
        j := 0;
        WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # " ") DO IF j < 63 THEN cmd[ncmd, j] := s[i]; INC(j) END; INC(i) END;
        cmd[ncmd, j] := 0X; INC(ncmd)
      END
    END
  END Imparte;

  PROCEDURE Command*(s: ARRAY OF CHAR);   (* one ARCH command, as typed in the shell *)
    VAR i, k: INTEGER; ext: ARRAY 8 OF CHAR;
  BEGIN
    nout := 0; Imparte(s);
    IF ~adrese THEN Adrese; adrese := TRUE END;
    IF ncmd < 3 THEN Ajutor
    ELSE
      Cop(cmd[2], arh); ext := ".z7c";
      IF ~Termina(arh, ext) THEN k := Lung(arh); i := 0; WHILE (i < 4) & (k < 60) DO arh[k] := ext[i]; INC(k); INC(i) END; arh[k] := 0X END;
      IF Acelasi(cmd[1], "pack") THEN Impacheteaza
      ELSIF Acelasi(cmd[1], "list") OR Acelasi(cmd[1], "ls") THEN Lista
      ELSIF Acelasi(cmd[1], "get") THEN IF ncmd < 4 THEN Spune("GET WHICH FILE? ARCH GET C NAME", ROSU) ELSE Scoate1(cmd[3]) END
      ELSIF Acelasi(cmd[1], "all") THEN ScoateTot
      ELSIF Acelasi(cmd[1], "find") THEN Cop(rest, q); nq := Lung(q); Cauta
      ELSIF Acelasi(cmd[1], "check") THEN Verifica
      ELSIF Acelasi(cmd[1], "add") THEN Adauga
      ELSE Ajutor
      END
    END;
    nk := 0   (* the shell gives the list again next time *)
  END Command;

BEGIN
  nout := 0; nk := 0; adrese := FALSE; sp := FALSE; ultimTip := FALSE
END Arch1.
