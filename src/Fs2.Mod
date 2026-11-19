MODULE Fs2;  (* CUBICUM FS 2 (11 Nov 2026): the 7 dimensions of the address, as Pion chose them for Cubicum FS (Oct 2026):
       d1 name    a sum of its letters, MOD 7
       d2 type    0 text (.txt)  1 Oberon (.mod)  2 synth song  3 data (.dat)  4 shape (.cub)  5 sound (.wav)  6 other
       d3 day     the day of the week it was made (Monday 1 .. Sunday 7)
       d4 folder  the folder it was made in (FOLDER n in the shell, 1..7)
       d5 size    when it was made: 1 empty, 2 under 7 bytes, 3 under 49, ... 7 from 7^5 up
       d6 month   (year * 12 + month) MOD 7
       d7 hour    the hour MOD 7
     Each digit is shown 1..7 (base 7 without zero). The address is a cell of the 7D torus of 7^7 = 823543 cells; if it is
     taken, the file goes on to the next free cell (d1 first, then d2, ...). The index is cubicum-fs.txt; the first line is
     FS7, then one line per file: F d1 d2 d3 d4 d5 d6 d7 name (digits 0..6). The old index (Fs1, 3 numbers) is read too.
     The date comes from the window (clock.txt, written every second by ecran-gl3-sunet4.dex); without it, day/month/hour 0.
     At home the cube shows 3 of the 7: type, name, size (as before).
     Pion & Claude, 11.11.2026 *)

  IMPORT Fisier;

  CONST MAX = 2401; NL = 40; N7 = 823543;

  VAR n, folder: INTEGER;
    names: ARRAY MAX, NL OF CHAR; addr: ARRAY MAX OF INTEGER;
    proj: ARRAY 343 OF INTEGER;   (* how many files show in each cell of the home cube (type, name, size) *)
    now: ARRAY 7 OF INTEGER; hasClock: BOOLEAN;   (* year month day hour minute second weekday *)

  PROCEDURE Lower(ch: CHAR): CHAR;
  BEGIN IF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch) + 32) END
    RETURN ch
  END Lower;

  PROCEDURE Same*(a, b: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (Lower(a[i]) = Lower(b[i])) DO INC(i) END
    RETURN ((i = LEN(a)) OR (a[i] = 0X)) & ((i = LEN(b)) OR (b[i] = 0X))
  END Same;

  PROCEDURE Copy(a: ARRAY OF CHAR; VAR b: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(a)) & (i < LEN(b) - 1) & (a[i] # 0X) DO b[i] := a[i]; INC(i) END;
    b[i] := 0X
  END Copy;

  PROCEDURE Ends(s, e: ARRAY OF CHAR): BOOLEAN;
    VAR i, j: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
    j := 0; WHILE (j < LEN(e)) & (e[j] # 0X) DO INC(j) END;
    WHILE (j > 0) & (i > 0) & (Lower(s[i - 1]) = e[j - 1]) DO DEC(i); DEC(j) END
    RETURN j = 0
  END Ends;

  PROCEDURE Starts(s, e: ARRAY OF CHAR): BOOLEAN;
    VAR j: INTEGER;
  BEGIN
    j := 0; WHILE (j < LEN(e)) & (e[j] # 0X) & (j < LEN(s)) & (Lower(s[j]) = e[j]) DO INC(j) END
    RETURN (j = LEN(e)) OR (e[j] = 0X)
  END Starts;

  PROCEDURE Exists*(name: ARRAY OF CHAR): BOOLEAN;
    VAR h: INTEGER;
  BEGIN h := Fisier.Deschide(name); IF h >= 0 THEN Fisier.Gata(h) END
    RETURN h >= 0
  END Exists;

  PROCEDURE SizeOf*(name: ARRAY OF CHAR): INTEGER;
    VAR h, k: INTEGER;
  BEGIN
    h := Fisier.Deschide(name); k := -1;
    IF h >= 0 THEN k := 0; WHILE (Fisier.Citeste(h) >= 0) & (k < 10000000) DO INC(k) END; Fisier.Gata(h) END
    RETURN k
  END SizeOf;

  PROCEDURE Kind*(name: ARRAY OF CHAR): INTEGER;
    VAR k: INTEGER;
  BEGIN
    IF Starts(name, "synthz7-") THEN k := 2 ELSIF Ends(name, ".txt") THEN k := 0 ELSIF Ends(name, ".mod") THEN k := 1
    ELSIF Ends(name, ".dat") THEN k := 3 ELSIF Ends(name, ".cub") THEN k := 4 ELSIF Ends(name, ".wav") THEN k := 5
    ELSE k := 6
    END
    RETURN k
  END Kind;

  PROCEDURE Hash(name: ARRAY OF CHAR): INTEGER;
    VAR i, h: INTEGER;
  BEGIN
    i := 0; h := 0;
    WHILE (i < LEN(name)) & (name[i] # 0X) DO h := (h + (i + 1) * ORD(Lower(name[i]))) MOD 7; INC(i) END
    RETURN h
  END Hash;

  PROCEDURE SizeClass(s: INTEGER): INTEGER;
    VAR z, lim: INTEGER;
  BEGIN
    IF s <= 0 THEN z := 0 ELSE z := 1; lim := 7; WHILE (s >= lim) & (z < 6) DO INC(z); lim := lim * 7 END END
    RETURN z
  END SizeClass;

  (* ---------- the clock (from the window) ---------- *)

  PROCEDURE ReadClock*(): BOOLEAN;   (* now[] from clock.txt; FALSE = no clock (the old window) *)
    VAR h, b, k, v: INTEGER; inNum: BOOLEAN;
  BEGIN
    hasClock := FALSE; h := Fisier.Deschide("clock.txt");
    IF h >= 0 THEN
      k := 0; v := 0; inNum := FALSE; b := Fisier.Citeste(h);
      WHILE (b >= 0) & (k < 7) DO
        IF (b >= ORD("0")) & (b <= ORD("9")) THEN v := v * 10 + b - ORD("0"); inNum := TRUE
        ELSIF inNum THEN now[k] := v; INC(k); v := 0; inNum := FALSE
        END;
        b := Fisier.Citeste(h)
      END;
      IF inNum & (k < 7) THEN now[k] := v; INC(k) END;
      Fisier.Gata(h); hasClock := (k = 7) & (now[0] > 2000)
    END
    RETURN hasClock
  END ReadClock;

  PROCEDURE Now*(k: INTEGER): INTEGER;   (* 0 year 1 month 2 day 3 hour 4 minute 5 second 6 weekday (Monday 0); -1 = no clock *)
    VAR r: INTEGER;
  BEGIN IF hasClock & (k >= 0) & (k < 7) THEN r := now[k] ELSE r := -1 END
    RETURN r
  END Now;

  (* ---------- the index ---------- *)

  PROCEDURE Pack(VAR d: ARRAY OF INTEGER): INTEGER;
    VAR k, a: INTEGER;
  BEGIN a := 0; FOR k := 6 TO 0 BY -1 DO a := a * 7 + d[k] MOD 7 END
    RETURN a
  END Pack;

  PROCEDURE Digit*(k, d: INTEGER): INTEGER;   (* coordinate d (0..6) of file k, as 0..6 *)
    VAR a, i: INTEGER;
  BEGIN a := addr[k]; FOR i := 1 TO d DO a := a DIV 7 END
    RETURN a MOD 7
  END Digit;

  PROCEDURE ProjIndex(a: INTEGER): INTEGER;   (* the home cube: x = type (d2), y = name (d1), z = size (d5) *)
    VAR d: ARRAY 7 OF INTEGER; i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO d[i] := a MOD 7; a := a DIV 7 END
    RETURN d[1] * 49 + d[0] * 7 + d[4]
  END ProjIndex;

  PROCEDURE Rebuild;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 342 DO proj[i] := 0 END;
    FOR i := 0 TO n - 1 DO INC(proj[ProjIndex(addr[i])]) END
  END Rebuild;

  PROCEDURE Taken(a: INTEGER): BOOLEAN;
    VAR i: INTEGER; t: BOOLEAN;
  BEGIN t := FALSE; i := 0; WHILE ~t & (i < n) DO t := addr[i] = a; INC(i) END
    RETURN t
  END Taken;

  PROCEDURE Save;
    VAR h, i, j, k: INTEGER;
  BEGIN
    h := Fisier.Creeaza("cubicum-fs.txt");
    IF h >= 0 THEN
      Fisier.Scrie(h, ORD("F")); Fisier.Scrie(h, ORD("S")); Fisier.Scrie(h, ORD("7")); Fisier.Scrie(h, 10);
      FOR i := 0 TO n - 1 DO
        Fisier.Scrie(h, ORD("F"));
        FOR k := 0 TO 6 DO Fisier.Scrie(h, 32); Fisier.Scrie(h, ORD("0") + Digit(i, k)) END;
        Fisier.Scrie(h, 32);
        j := 0; WHILE (j < NL) & (names[i, j] # 0X) DO Fisier.Scrie(h, ORD(names[i, j])); INC(j) END;
        Fisier.Scrie(h, 10)
      END;
      Fisier.Gata(h)
    END
  END Save;

  PROCEDURE Find*(name: ARRAY OF CHAR): INTEGER;
    VAR i, k: INTEGER;
  BEGIN k := -1; i := 0; WHILE (i < n) & (k < 0) DO IF Same(names[i], name) THEN k := i END; INC(i) END
    RETURN k
  END Find;

  PROCEDURE Put(name: ARRAY OF CHAR; a: INTEGER): INTEGER;   (* a new entry at address a, or the next free one *)
    VAR k, t, i: INTEGER; d: ARRAY 7 OF INTEGER;
  BEGIN
    k := -1;
    IF n < MAX THEN
      t := 0;
      WHILE (t < N7) & Taken(a) DO   (* one step on the torus: d1 first, carrying into d2, ... *)
        FOR i := 0 TO 6 DO d[i] := a MOD 7; a := a DIV 7 END;
        i := 0; d[0] := (d[0] + 1) MOD 7; WHILE (i < 6) & (d[i] = 0) DO INC(i); d[i] := (d[i] + 1) MOD 7 END;
        a := Pack(d); INC(t)
      END;
      IF t < N7 THEN k := n; Copy(name, names[k]); addr[k] := a; INC(n); INC(proj[ProjIndex(a)]) END
    END
    RETURN k
  END Put;

  PROCEDURE Place(name: ARRAY OF CHAR): INTEGER;   (* the address of a new file, from what it is and when *)
    VAR d: ARRAY 7 OF INTEGER;
  BEGIN
    IF ReadClock() THEN END;
    d[0] := Hash(name); d[1] := Kind(name); d[3] := folder MOD 7; d[4] := SizeClass(SizeOf(name));
    IF hasClock THEN d[2] := now[6]; d[5] := (now[0] * 12 + now[1] - 1) MOD 7; d[6] := now[3] MOD 7
    ELSE d[2] := 0; d[5] := 0; d[6] := 0
    END
    RETURN Pack(d)
  END Place;

  PROCEDURE Add*(name: ARRAY OF CHAR): INTEGER;
    VAR k: INTEGER;
  BEGIN
    k := Find(name);
    IF k < 0 THEN k := Put(name, Place(name)); Save END
    RETURN k
  END Add;

  PROCEDURE Drop(k: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := k TO n - 2 DO names[i] := names[i + 1]; addr[i] := addr[i + 1] END;
    DEC(n); Rebuild
  END Drop;

  PROCEDURE Remove*(k: INTEGER);
  BEGIN IF (k >= 0) & (k < n) THEN Fisier.Sterge(names[k]); Drop(k); Save END
  END Remove;

  PROCEDURE Sync*;
    VAR i: INTEGER; changed: BOOLEAN; s: ARRAY 20 OF CHAR;
  BEGIN
    changed := FALSE; i := 0;
    WHILE i < n DO IF ~Exists(names[i]) THEN Drop(i); changed := TRUE ELSE INC(i) END END;
    FOR i := 1 TO 7 DO
      s := "SynthZ7-0.txt"; s[8] := CHR(ORD("0") + i);
      IF (Find(s) < 0) & Exists(s) THEN IF Put(s, Place(s)) >= 0 THEN changed := TRUE END END
    END;
    IF changed THEN Save END
  END Sync;

  PROCEDURE Load*;
    VAR h, b, k, j, m, a: INTEGER; s: ARRAY NL OF CHAR; d: ARRAY 8 OF INTEGER; new: BOOLEAN;
  BEGIN
    n := 0; Rebuild;
    h := Fisier.Deschide("cubicum-fs.txt");
    IF h >= 0 THEN
      b := Fisier.Citeste(h); new := b = ORD("F");
      IF new THEN b := Fisier.Citeste(h); new := b = ORD("S") END;   (* "FS7": the new index; "F x y z name": the old *)
      WHILE (b >= 0) & (b # 10) DO b := Fisier.Citeste(h) END;
      IF ~new THEN Fisier.Gata(h); h := Fisier.Deschide("cubicum-fs.txt") END;
      IF new THEN m := 7 ELSE m := 3 END;
      b := Fisier.Citeste(h);
      WHILE b >= 0 DO
        IF b = ORD("F") THEN
          FOR k := 0 TO m - 1 DO b := Fisier.Citeste(h); b := Fisier.Citeste(h); d[k] := (b - ORD("0")) MOD 7 END;
          b := Fisier.Citeste(h); b := Fisier.Citeste(h); j := 0;
          WHILE (b >= 0) & (b # 10) & (b # 13) DO IF j < NL - 1 THEN s[j] := CHR(b); INC(j) END; b := Fisier.Citeste(h) END;
          s[j] := 0X;
          IF ~new THEN   (* old: x type, y name, z size -> the 7 dimensions, with no date and folder 1 *)
            d[4] := d[2]; d[2] := 0; a := d[0]; d[0] := d[1]; d[1] := a; d[3] := 0; d[5] := 0; d[6] := 0
          END;
          IF (j > 0) & (Find(s) < 0) THEN k := Put(s, Pack(d)) END
        ELSE b := Fisier.Citeste(h)
        END
      END;
      Fisier.Gata(h);
      IF ~new THEN Save END
    END;
    Sync
  END Load;

  PROCEDURE SetFolder*(f: INTEGER); BEGIN folder := f MOD 7 END SetFolder;
  PROCEDURE Folder*(): INTEGER; BEGIN RETURN folder END Folder;

  PROCEDURE Count*(): INTEGER; BEGIN RETURN n END Count;
  PROCEDURE Name*(k: INTEGER; VAR s: ARRAY OF CHAR); BEGIN IF (k >= 0) & (k < n) THEN Copy(names[k], s) ELSE s[0] := 0X END END Name;
  PROCEDURE X*(k: INTEGER): INTEGER; BEGIN RETURN Digit(k, 1) END X;   (* the home cube: type *)
  PROCEDURE Y*(k: INTEGER): INTEGER; BEGIN RETURN Digit(k, 0) END Y;   (* name *)
  PROCEDURE Z*(k: INTEGER): INTEGER; BEGIN RETURN Digit(k, 4) END Z;   (* size *)
  PROCEDURE Address*(k: INTEGER): INTEGER; BEGIN RETURN addr[k] END Address;

  PROCEDURE At*(x, y, z: INTEGER): INTEGER;   (* the home cube: the first file in (type x, name y, size z); -1 = none *)
    VAR i, r: INTEGER;
  BEGIN
    r := -1;
    IF (x >= 0) & (x < 7) & (y >= 0) & (y < 7) & (z >= 0) & (z < 7) & (proj[x * 49 + y * 7 + z] > 0) THEN
      i := 0; WHILE (r < 0) & (i < n) DO IF ProjIndex(addr[i]) = x * 49 + y * 7 + z THEN r := i END; INC(i) END
    END
    RETURN r
  END At;

  PROCEDURE AtAddress*(a: INTEGER): INTEGER;   (* the file at a 7D address; -1 = none *)
    VAR i, r: INTEGER;
  BEGIN r := -1; i := 0; WHILE (r < 0) & (i < n) DO IF addr[i] = a THEN r := i END; INC(i) END
    RETURN r
  END AtAddress;

BEGIN
  n := 0; folder := 0; hasClock := FALSE; Rebuild
END Fs2.
