MODULE Text1;  (* TEXT 1 (11 Nov 2026): the full ASCII font of Cubicum N. Grafica draws digits, capitals and some
     signs (and draws small letters as capitals); Text1 adds real small letters (with tails: g j p q y) and the signs
     Oberon needs: ; " # [ ] { } & ~ ^ | ' _ @ $ \ `. Same 5 x 7 cell, 6 m wide, one more row below for tails.
     Pion & Claude, 11.11.2026 *)

  IMPORT Grafica;

  VAR up, row6, row7: ARRAY 128 OF INTEGER; own: ARRAY 128 OF BOOLEAN;

  PROCEDURE Char*(x, y: INTEGER; ch: CHAR; m, c: INTEGER);
    VAR k, r, b, v: INTEGER;
  BEGIN
    k := ORD(ch);
    IF (k > 32) & (k < 128) & own[k] THEN
      FOR r := 0 TO 7 DO
        IF r < 6 THEN v := up[k]; FOR b := r TO 4 DO v := v DIV 32 END; v := v MOD 32
        ELSIF r = 6 THEN v := row6[k] ELSE v := row7[k]
        END;
        FOR b := 0 TO 4 DO
          IF ODD(v DIV LSL(1, 4 - b)) THEN Grafica.Dreptunghi(x + b * m, y + r * m, m, m, c) END
        END
      END
    ELSIF (k > 32) & (k < 128) THEN Grafica.Litera(x, y, ch, m, c)
    END
  END Char;

  PROCEDURE Draw*(x, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Char(x + i * 6 * m, y, s[i], m, c); INC(i) END
  END Draw;

  PROCEDURE Part*(x, y: INTEGER; s: ARRAY OF CHAR; from, n, m, c: INTEGER);   (* n characters of s, from position from *)
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < n) & (from + i < LEN(s)) & (s[from + i] # 0X) DO Char(x + i * 6 * m, y, s[from + i], m, c); INC(i) END
  END Part;

  PROCEDURE Len*(s: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END
    RETURN i
  END Len;

  PROCEDURE Centre*(cx, y: INTEGER; s: ARRAY OF CHAR; m, c: INTEGER);
  BEGIN Draw(cx - Len(s) * 3 * m, y, s, m, c)
  END Centre;

  PROCEDURE G(k, a, b, d: INTEGER);
  BEGIN up[k] := a; row6[k] := b; row7[k] := d; own[k] := TRUE
  END G;

  PROCEDURE Letters;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 127 DO own[i] := FALSE END;
    G(97, 460273, 15, 0);
    G(98, 554649137, 30, 0);
    G(99, 475664, 14, 0);
    G(100, 35112497, 15, 0);
    G(101, 477168, 14, 0);
    G(102, 210706696, 8, 0);
    G(103, 509487, 1, 14);
    G(104, 554649137, 17, 0);
    G(105, 134615172, 14, 0);
    G(106, 67307586, 18, 12);
    G(107, 554259220, 18, 0);
    G(108, 406982788, 14, 0);
    G(109, 874165, 21, 0);
    G(110, 1001009, 17, 0);
    G(111, 476721, 14, 0);
    G(112, 1001022, 16, 16);
    G(113, 509487, 1, 1);
    G(114, 747024, 16, 0);
    G(115, 508353, 30, 0);
    G(116, 277815561, 6, 0);
    G(117, 575027, 13, 0);
    G(118, 575018, 4, 0);
    G(119, 575157, 10, 0);
    G(120, 567434, 17, 0);
    G(121, 575023, 1, 14);
    G(122, 1017992, 31, 0);
    G(59, 6488262, 4, 8);
    G(34, 346357760, 0, 0);
    G(35, 347057130, 10, 0);
    G(91, 478421256, 14, 0);
    G(93, 471926850, 14, 0);
    G(123, 209993992, 6, 0);
    G(125, 404816962, 12, 0);
    G(38, 422191794, 13, 0);
    G(126, 283712, 0, 0);
    G(94, 145260544, 0, 0);
    G(124, 138547332, 4, 0);
    G(39, 138674176, 0, 0);
    G(95, 0, 31, 0);
    G(64, 488363760, 14, 0);
    G(36, 150616254, 4, 0);
    G(92, 17043521, 0, 0);
    G(96, 272629760, 0, 0);
  END Letters;

BEGIN
  Letters
END Text1.
