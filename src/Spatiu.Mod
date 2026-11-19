MODULE Spatiu;  (* Z7 ARCH 8: the spatial model. The same context-mixing engine as Z7 Arch, plus contexts taken from
     the data's own geometry: the neighbours in the plane (left, up, up-left, up-right, two back) and, for a third axis,
     the same point in the previous plane (z or time). Used only for files Z7 Arch 8 recognizes (BMP, PGM/PPM, WAV, Y4M),
     one run per file: the model keeps learning across the cells of that file. All neighbours are in the past, so the
     decoder already has them. Tested first as Spatiu1.Mod (19 Nov 2026). Pion & Claude *)

  CONST
    TB = 4194304; NIM = 24; MH = 1048576; LIM = 10;
    RB = 8388608;   (* history of the run: 8 MB; a 3D file needs 2 planes + a row inside it *)

  VAR
    t: ARRAY TB OF INTEGER;
    w: ARRAY 1024 * NIM OF INTEGER;
    sq: ARRAY 33 OF INTEGER; st: ARRAY 4096 OF INTEGER;
    ord, hb, idx, s: ARRAY NIM OF INTEGER;
    hist: ARRAY 8 OF INTEGER;
    c0, pm, pa, ab, nctx, ni, cset, q: INTEGER;
    hs: ARRAY RB OF CHAR; mt: ARRAY MH OF INTEGER; pos, mptr, mlen, mbit, mi: INTEGER;
    mm: ARRAY 64 OF INTEGER;
    ap: ARRAY 256 * 33 OF INTEGER;
    p, off, stride, bpp, wd, plane, inner, mode: INTEGER;

  PROCEDURE Squash(d: INTEGER): INTEGER;
    VAR r, q, f: INTEGER;
  BEGIN
    IF d > 2047 THEN r := 4095 ELSIF d < -2047 THEN r := 0
    ELSE f := d MOD 128; q := d DIV 128 + 16; r := (sq[q] * (128 - f) + sq[q + 1] * f + 64) DIV 128
    END
    RETURN r
  END Squash;

  PROCEDURE V(i: INTEGER): INTEGER;   (* a past byte of this run, 0 outside *)
    VAR r: INTEGER;
  BEGIN IF (i >= 0) & (i < p) & (p - i < RB) THEN r := ORD(hs[i MOD RB]) ELSE r := 0 END
    RETURN r
  END V;

  PROCEDURE Clip(x: INTEGER): INTEGER;
  BEGIN IF x < 0 THEN x := 0 ELSIF x > 255 THEN x := 255 END
    RETURN x
  END Clip;

  PROCEDURE H(k, a, b, c: INTEGER): INTEGER;
  BEGIN RETURN ((((k + 1) * 7777 + a + 1) MOD 1048573 * 263 + b + 1) MOD 1048573 * 263 + c + 1) MOD 1048573
  END H;

  PROCEDURE Hashes;   (* the order contexts + the spatial contexts, for byte p *)
    VAR k, j, h, ch, x, y, r, lf, up, ul, ur, uu, ll, uur, c1, c2, c3, bk, bl, bu, bul, bb: INTEGER;
  BEGIN
    FOR k := 0 TO 5 DO
      h := (k + 1) * 7777;
      FOR j := 1 TO ord[k] DO h := (h * 263 + hist[j] + 1) MOD 1048573 END;
      hb[k] := h
    END;
    q := p - off; IF q >= 0 THEN r := q MOD plane - inner ELSE r := -1 END;
    IF r < 0 THEN   (* header or frame marker: the spatial contexts are quiet *)
      FOR k := 6 TO 18 DO hb[k] := H(k, 0, 0, 0) END;
      IF mode >= 3 THEN nctx := 19 ELSE nctx := 14 END; ch := 0
    ELSE
      ch := r MOD stride MOD bpp; x := r MOD stride DIV bpp; y := r DIV stride;
      IF x > 0 THEN lf := V(p - bpp) ELSE lf := 0 END;
      IF y > 0 THEN up := V(p - stride) ELSE up := lf END;
      IF (x > 0) & (y > 0) THEN ul := V(p - stride - bpp) ELSE ul := up END;
      IF (x < wd - 1) & (y > 0) THEN ur := V(p - stride + bpp) ELSE ur := up END;
      IF y > 1 THEN uu := V(p - 2 * stride) ELSE uu := up END;
      IF x > 1 THEN ll := V(p - 2 * bpp) ELSE ll := lf END;
      IF (x < wd - 1) & (y > 1) THEN uur := V(p - 2 * stride + bpp) ELSE uur := ur END;
      hb[6] := H(6, ch, up, lf);
      hb[7] := H(7, ch, Clip(lf + up - ul), 0);
      hb[8] := H(8, ch, up DIV 4, lf DIV 4 * 64 + ul DIV 4);
      hb[9] := H(9, ch, (lf + up + 1) DIV 2, Clip(up + ur - uur) DIV 8);
      hb[10] := H(10, ch, Clip(up + ur - uur), Clip(lf + ur - up) DIV 4);
      hb[11] := H(11, ch, Clip(2 * up - uu), Clip(2 * lf - ll));
      hb[12] := H(12, ch, (ABS(up - ul) + ABS(lf - ul)) DIV 8, Clip(lf + up - ul) DIV 4);
      IF (bpp >= 3) & (ch > 0) THEN   (* colour: the previous channel of the same point *)
        c1 := V(p - 1);
        IF x > 0 THEN c2 := Clip(lf + c1 - V(p - 1 - bpp)) ELSE c2 := c1 END;
        IF y > 0 THEN c3 := Clip(up + c1 - V(p - 1 - stride)) ELSE c3 := c1 END;
        hb[13] := H(13, ch, c2, c3)
      ELSE hb[13] := H(13, ch, up DIV 16, lf DIV 16 * 16 + ur DIV 16)
      END;
      nctx := 14;
      IF mode >= 3 THEN
        IF q >= plane THEN bk := V(p - plane) ELSE bk := up END;
        IF (q >= plane) & (x > 0) THEN bl := V(p - plane - bpp) ELSE bl := lf END;
        IF (q >= plane) & (y > 0) THEN bu := V(p - plane - stride) ELSE bu := up END;
        IF (q >= plane) & (x > 0) & (y > 0) THEN bul := V(p - plane - stride - bpp) ELSE bul := ul END;
        IF q >= 2 * plane THEN bb := V(p - 2 * plane) ELSE bb := bk END;
        hb[14] := H(14, ch, bk, 0);
        hb[15] := H(15, ch, Clip(lf + up + bk - ul - bl - bu + bul), 0);
        hb[16] := H(16, ch, bk, up DIV 8 * 32 + lf DIV 8);
        hb[17] := H(17, ch, Clip(bk + lf - bl), Clip(bk + up - bu));
        hb[18] := H(18, ch, Clip(2 * bk - bb), bk DIV 8);
        nctx := 19
      END
    END;
    cset := ch MOD 4;
    ni := nctx + 2
  END Hashes;

  PROCEDURE Match;
    VAR h, k: INTEGER;
  BEGIN
    INC(pos);   (* the byte is already in hs *)
    IF (mlen > 0) & (ORD(hs[mptr MOD RB]) = hist[1]) THEN INC(mlen); INC(mptr) ELSE mlen := 0 END;
    h := hb[5] MOD MH;
    IF (mlen = 0) & (pos > 6) THEN
      mptr := mt[h];
      IF (mptr > 0) & (pos - mptr < RB - 8) THEN
        k := 0;
        WHILE (k < 32) & (mptr - k > 0) & (ORD(hs[(mptr - k - 1) MOD RB]) = ORD(hs[(pos - k - 1) MOD RB])) DO INC(k) END;
        mlen := k
      END
    END;
    mt[h] := pos;
    IF mlen > 0 THEN mbit := ORD(hs[mptr MOD RB]) + 256 ELSE mbit := 0 END
  END Match;

  PROCEDURE Reset;
    VAR i, x, v, q: INTEGER;
  BEGIN
    sq[0] := 1; sq[1] := 2; sq[2] := 3; sq[3] := 6; sq[4] := 10; sq[5] := 16; sq[6] := 27; sq[7] := 45;
    sq[8] := 73; sq[9] := 120; sq[10] := 194; sq[11] := 310; sq[12] := 488; sq[13] := 747; sq[14] := 1101;
    sq[15] := 1546; sq[16] := 2047; sq[17] := 2549; sq[18] := 2994; sq[19] := 3348; sq[20] := 3607;
    sq[21] := 3785; sq[22] := 3901; sq[23] := 3975; sq[24] := 4022; sq[25] := 4050; sq[26] := 4068;
    sq[27] := 4079; sq[28] := 4085; sq[29] := 4089; sq[30] := 4092; sq[31] := 4093; sq[32] := 4094;
    q := 0;
    FOR x := -2047 TO 2047 DO v := Squash(x); FOR i := q TO v DO st[i] := x END; IF v + 1 > q THEN q := v + 1 END END;
    FOR i := q TO 4095 DO st[i] := 2047 END;
    FOR i := 0 TO TB - 1 DO t[i] := 32768 * 64 END;
    FOR i := 0 TO 1024 * NIM - 1 DO IF i MOD NIM = NIM - 1 THEN w[i] := 0 ELSE w[i] := 3000 END END;
    FOR i := 0 TO MH - 1 DO mt[i] := 0 END;
    FOR i := 0 TO 63 DO mm[i] := 32768 END;
    FOR i := 0 TO 256 * 33 - 1 DO ap[i] := Squash((i MOD 33) * 128 - 2048) * 16 END;
    pos := 0; mptr := 0; mlen := 0; mbit := 0; p := 0;
    ord[0] := 0; ord[1] := 1; ord[2] := 2; ord[3] := 3; ord[4] := 4; ord[5] := 6;
    FOR i := 0 TO 7 DO hist[i] := 0 END;
    c0 := 1; Hashes
  END Reset;

  PROCEDURE Bits(): INTEGER;
    VAR k, c: INTEGER;
  BEGIN k := 0; c := c0; WHILE c > 1 DO c := c DIV 2; INC(k) END
    RETURN k
  END Bits;

  PROCEDURE Predict*(): INTEGER;
    VAR i, dot, b, k, f: INTEGER;
  BEGIN
    b := (c0 + 256 * cset) * NIM; dot := 0;
    FOR i := 0 TO nctx - 1 DO
      idx[i] := (hb[i] * 271 + c0 * 4099) MOD TB;
      s[i] := st[t[idx[i]] DIV 1024]; dot := dot + w[b + i] * s[i] DIV 16
    END;
    IF (mbit > 0) & (mbit DIV LSL(1, 8 - Bits()) = c0) THEN
      k := mbit DIV LSL(1, 7 - Bits()) MOD 2; IF mlen < 31 THEN mi := mlen * 2 + k ELSE mi := 62 + k END;
      s[nctx] := st[mm[mi] DIV 16]
    ELSE mi := -1; s[nctx] := 0
    END;
    dot := dot + w[b + nctx] * s[nctx] DIV 16;
    s[nctx + 1] := 256; dot := dot + w[b + NIM - 1] * 16;
    pm := Squash(dot DIV 1024);   (* the terms are already divided by 16: INTEGER has 32 bits *)
    IF pm < 1 THEN pm := 1 ELSIF pm > 4095 THEN pm := 4095 END;
    k := st[pm] + 2048; ab := c0 * 33 + k DIV 128; f := k MOD 128;
    pa := (ap[ab] * (128 - f) + ap[ab + 1] * f) DIV 2048;
    k := (pm + 3 * pa) DIV 4;
    IF k < 1 THEN k := 1 ELSIF k > 4095 THEN k := 4095 END
    RETURN k
  END Predict;

  PROCEDURE Update*(y: INTEGER);
    VAR i, err, b, q, k: INTEGER;
  BEGIN
    err := y * 4095 - pm; b := (c0 + 256 * cset) * NIM;
    FOR i := 0 TO nctx DO
      k := w[b + i] + s[i] * err DIV 8192;
      IF k > 65535 THEN k := 65535 ELSIF k < -65535 THEN k := -65535 END;
      w[b + i] := k
    END;
    k := w[b + NIM - 1] + 256 * err DIV 8192; IF k > 65535 THEN k := 65535 ELSIF k < -65535 THEN k := -65535 END; w[b + NIM - 1] := k;
    FOR i := 0 TO nctx - 1 DO
      q := t[idx[i]]; k := q MOD 64; q := q DIV 64;
      q := q + (y * 65535 - q) * 2 DIV (2 * k + 3);
      IF k < LIM THEN INC(k) END;
      t[idx[i]] := q * 64 + k
    END;
    IF mi >= 0 THEN q := mm[mi]; mm[mi] := q + (y * 65535 - q) DIV 32 END;
    IF (mbit > 0) & (mbit DIV LSL(1, 7 - Bits()) MOD 2 # y) THEN mlen := 0; mbit := 0 END;
    ap[ab] := ap[ab] + (y * 65535 - ap[ab]) DIV 64; ap[ab + 1] := ap[ab + 1] + (y * 65535 - ap[ab + 1]) DIV 64;
    c0 := c0 * 2 + y;
    IF c0 >= 256 THEN
      FOR i := 7 TO 2 BY -1 DO hist[i] := hist[i - 1] END;
      hist[1] := c0 - 256; hs[p MOD RB] := CHR(c0 - 256); c0 := 1; INC(p); Hashes; Match
    END
  END Update;

  PROCEDURE Start*(of, str, bp, w0, pl, inn, md: INTEGER);   (* a new run: one file, with its geometry *)
  BEGIN
    off := of; stride := str; bpp := bp; wd := w0; plane := pl; inner := inn; mode := md;
    IF stride < 1 THEN stride := 1 END; IF bpp < 1 THEN bpp := 1 END; IF plane < stride THEN plane := stride END;
    IF (mode >= 3) & (2 * plane + stride >= RB) THEN mode := 2 END;
    Reset
  END Start;

  PROCEDURE Mod*(): INTEGER;   (* 2 = plane, 3 = cube (after Start) *)
  BEGIN RETURN mode
  END Mod;

END Spatiu.
