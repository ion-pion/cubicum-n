MODULE Herne1;  (* HERNE 1 (25 Nov 2026): THE BOAR HUNT, a program of Pixipogo (Herne the Hunter, the spirit of the forest
     in Shakespeare, next to Oberon and Ariel).
   Pion's hunt: a wild boar runs through a forest of 49 x 49, and 14 hunters look for it: 7 with short Gaussians, who go
   with the little dog and follow the tracks from near, and 7 with long Gaussians, who go with the mammoth and listen
   across the whole forest. Each hunter is a bell of belief: "the boar is about here, this sure". The short bells are
   narrow and sharp, the long ones wide; where they meet, there the boar is. The map of the bells is drawn on the forest.
     You are the boar: hold the forest to run there; standing still in a bush, nobody hears you; the water washes
     your tracks. Reach the den (the gold ring) and you are safe.
     WATCH: the boar runs by itself, and the hunts follow one another: who catches it more, the short ones or the long?
   Pion & Claude, 25.11.2026 *)

  IMPORT OllGL6;

  CONST
    N = 49; NN = 2401; NH = 14; NS = 7;        (* the forest, the hunters: 0..6 short (the dog), 7..13 long (the mammoth) *)
    GROUND = 0; TREE = 1; BUSH = 2; WATER = 3;
    BT = 9; HT = 18;                           (* the boar steps every 9 frames (18 in the water), the hunters every 18 *)
    NA = 7;                                    (* the acorns: eat all 7, then the den opens *)
    TRACK = 420;                               (* frames a track keeps its smell *)
    PLAY = 0; CAUGHT = 1; ESCAPED = 2;

  VAR
    W, H, ox, oy, c, t, tStart, tEnd, state, catcher, seed: INTEGER;
    ter, urma, bs, bl, cost, way: ARRAY NN OF INTEGER;    (* the forest, when the boar passed, the bells of the short and the long *)
    hx, hy, tgx, tgy: ARRAY NH OF INTEGER; sg, gx, gy: ARRAY NH OF REAL;
    ex: ARRAY 128 OF REAL;                     (* e^(-k/8) *)
    bx, by, dx, dy, fx, fy, dogX, dogY, eaten: INTEGER; mamX, mamY: REAL;
    ax, ay: ARRAY NA OF INTEGER; got: ARRAY NA OF BOOLEAN;
    moved, heard, watch, showMap, wasDown, pressed, entered, fingerRun: BOOLEAN;
    nBoar, nShort, nLong, games: INTEGER;
    tallyFrames*, tallyEaten*: INTEGER;                     (* Tally: the frames of all its hunts *)
    bg, text, muted, gold, panel, orange, blue, red: INTEGER;

  PROCEDURE Rnd(n: INTEGER): INTEGER;   (* 0 .. n-1 *)
  BEGIN seed := (seed * 75 + 74) MOD 65537   (* the ZX81's: no number gets too big *)
    RETURN seed * n DIV 65537
  END Rnd;

  PROCEDURE Ex(x: REAL): REAL;   (* e^-x, as (1 - x/1024)^1024 *)
    VAR y: REAL; i: INTEGER;
  BEGIN
    y := 1.0 - x / 1024.0; IF y < 0.0 THEN y := 0.0 END;
    FOR i := 1 TO 10 DO y := y * y END
    RETURN y
  END Ex;

  PROCEDURE At(x, y: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF (x < 0) OR (y < 0) OR (x >= N) OR (y >= N) THEN r := TREE ELSE r := ter[y * N + x] END
    RETURN r
  END At;

  PROCEDURE Far(ax, ay, bx2, by2: INTEGER): INTEGER;   (* steps between two cells (8 ways) *)
    VAR a, b: INTEGER;
  BEGIN a := ABS(ax - bx2); b := ABS(ay - by2); IF b > a THEN a := b END
    RETURN a
  END Far;

  PROCEDURE Sign(v: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF v > 0 THEN r := 1 ELSIF v < 0 THEN r := -1 ELSE r := 0 END
    RETURN r
  END Sign;

  PROCEDURE Clear(x, y, r: INTEGER);   (* no trees around a place *)
    VAR i, j: INTEGER;
  BEGIN
    FOR j := y - r TO y + r DO FOR i := x - r TO x + r DO
      IF (i >= 0) & (j >= 0) & (i < N) & (j < N) THEN ter[j * N + i] := GROUND END
    END END
  END Clear;

  PROCEDURE NewForest;
    VAR i, x, y, k, lx, ly, rx, ry: INTEGER; q: REAL;
  BEGIN
    FOR i := 0 TO NN - 1 DO
      k := Rnd(100); IF k < 15 THEN ter[i] := TREE ELSIF k < 27 THEN ter[i] := BUSH ELSE ter[i] := GROUND END;
      urma[i] := 0
    END;
    FOR k := 1 TO 40 DO   (* groves: the trees like company *)
      x := Rnd(N); y := Rnd(N);
      FOR i := 0 TO 5 DO lx := x + Rnd(5) - 2; ly := y + Rnd(5) - 2; IF (lx >= 0) & (ly >= 0) & (lx < N) & (ly < N) THEN ter[ly * N + lx] := TREE END END
    END;
    k := Rnd(4); IF k = 0 THEN dx := 3; dy := 3 ELSIF k = 1 THEN dx := 45; dy := 3 ELSIF k = 2 THEN dx := 3; dy := 45 ELSE dx := 45; dy := 45 END;
    lx := 12 + Rnd(25); ly := 12 + Rnd(25); rx := 4 + Rnd(4); ry := 3 + Rnd(3);   (* the lake *)
    IF Far(lx, ly, 24, 24) < 7 THEN lx := 48 - dx; ly := dy END;
    FOR y := 0 TO N - 1 DO FOR x := 0 TO N - 1 DO
      q := FLT((x - lx) * (x - lx)) / FLT(rx * rx) + FLT((y - ly) * (y - ly)) / FLT(ry * ry);
      IF q <= 1.0 THEN ter[y * N + x] := WATER END
    END END;
    bx := 24; by := 24; Clear(bx, by, 2); Clear(dx, dy, 2);
    eaten := 0;
    FOR i := 0 TO NA - 1 DO   (* the acorns, one in each ring of the forest, away from the boar *)
      REPEAT x := 2 + Rnd(45); y := 2 + Rnd(45) UNTIL (Far(x, y, bx, by) >= 6 + i * 2) & (ter[y * N + x] # WATER);
      ter[y * N + x] := GROUND; ax[i] := x; ay[i] := y; got[i] := FALSE
    END;
    FOR i := 0 TO NH - 1 DO   (* the hunters come from the edges, the short and the long in turn *)
      k := (i * 196 DIV NH + Rnd(6)) MOD 196;
      IF k < 49 THEN x := k; y := 0 ELSIF k < 98 THEN x := 48; y := k - 49 ELSIF k < 147 THEN x := 146 - k; y := 48 ELSE x := 0; y := 195 - k END;
      IF Far(x, y, dx, dy) < 9 THEN x := 48 - x; y := 48 - y END;
      hx[i] := x; hy[i] := y; Clear(x, y, 1);
      gx[i] := FLT(x); gy[i] := FLT(y); tgx[i] := 24; tgy[i] := 24;
      IF i < NS THEN sg[i] := 3.0 ELSE sg[i] := 12.0 END
    END;
    state := PLAY; tStart := t; tEnd := 0; catcher := -1; fx := bx; fy := by; fingerRun := FALSE;
    REPEAT x := 4 + Rnd(41); y := 4 + Rnd(41) UNTIL Far(x, y, bx, by) >= 16;   (* the mammoth starts somewhere far *)
    mamX := FLT(x); mamY := FLT(y); dogX := hx[0]; dogY := hy[0]; heard := FALSE; moved := FALSE
  END NewForest;

  PROCEDURE Free(x, y: INTEGER; boar: BOOLEAN): BOOLEAN;   (* can one step here? the hunters stay out of the water *)
    VAR k: INTEGER; r: BOOLEAN;
  BEGIN k := At(x, y); r := (k # TREE) & (boar OR (k # WATER))
    RETURN r
  END Free;

  PROCEDURE Taken(x, y, me: INTEGER): BOOLEAN;   (* another hunter stands there *)
    VAR i: INTEGER; r: BOOLEAN;
  BEGIN r := FALSE; FOR i := 0 TO NH - 1 DO IF (i # me) & (hx[i] = x) & (hy[i] = y) THEN r := TRUE END END
    RETURN r
  END Taken;

  PROCEDURE StepHunter(i: INTEGER);   (* one step toward the target, around the trees *)
    VAR sx, sy, k, nx, ny, best, d: INTEGER;
  BEGIN
    sx := Sign(tgx[i] - hx[i]); sy := Sign(tgy[i] - hy[i]);
    IF (sx # 0) OR (sy # 0) THEN
      best := 1000; nx := hx[i]; ny := hy[i];
      FOR k := 0 TO 7 DO   (* of the 8 ways, the free one that comes nearest *)
        IF k = 0 THEN sx := 1; sy := 0 ELSIF k = 1 THEN sx := 1; sy := 1 ELSIF k = 2 THEN sx := 0; sy := 1 ELSIF k = 3 THEN sx := -1; sy := 1
        ELSIF k = 4 THEN sx := -1; sy := 0 ELSIF k = 5 THEN sx := -1; sy := -1 ELSIF k = 6 THEN sx := 0; sy := -1 ELSE sx := 1; sy := -1 END;
        IF Free(hx[i] + sx, hy[i] + sy, FALSE) & ~Taken(hx[i] + sx, hy[i] + sy, i) THEN
          d := Far(hx[i] + sx, hy[i] + sy, tgx[i], tgy[i]) * 4 + ABS(hx[i] + sx - tgx[i]) + ABS(hy[i] + sy - tgy[i]);
          IF d < best THEN best := d; nx := hx[i] + sx; ny := hy[i] + sy END
        END
      END;
      hx[i] := nx; hy[i] := ny
    END
  END StepHunter;

  PROCEDURE Sees(i: INTEGER): BOOLEAN;   (* near enough to see the boar (a bush hides it, but not from one step) *)
    VAR d: INTEGER; r: BOOLEAN;
  BEGIN d := Far(hx[i], hy[i], bx, by); r := (d <= 1) OR ((d <= 3) & (At(bx, by) # BUSH))
    RETURN r
  END Sees;

  PROCEDURE Hunters;   (* the bells move: what each hunter knows, then one step *)
    VAR i, j, x, y, best, ax, ay, n, k: INTEGER; sx, sy: REAL;
  BEGIN
    (* the long ones listen: a boar that runs on dry land is heard from far, not exactly *)
    heard := FALSE; sx := 0.0; sy := 0.0; n := 0;
    FOR i := NS TO NH - 1 DO
      IF moved & (At(bx, by) # WATER) & (Far(hx[i], hy[i], bx, by) <= 8) THEN
        gx[i] := FLT(bx + Rnd(7) - 3); gy[i] := FLT(by + Rnd(7) - 3); sg[i] := sg[i] - 2.0; IF sg[i] < 4.0 THEN sg[i] := 4.0 END;
        heard := TRUE; sx := sx + gx[i]; sy := sy + gy[i]; INC(n)
      END
    END;
    IF heard THEN   (* the mammoth trumpets: all the long bells lean toward what was heard *)
      mamX := sx / FLT(n); mamY := sy / FLT(n);
      FOR i := NS TO NH - 1 DO gx[i] := (gx[i] + 2.0 * mamX) / 3.0; gy[i] := (gy[i] + 2.0 * mamY) / 3.0; IF sg[i] > 7.0 THEN sg[i] := 7.0 END END
    END;
    FOR i := 0 TO NH - 1 DO
      IF Sees(i) THEN gx[i] := FLT(bx); gy[i] := FLT(by); sg[i] := 1.0
      ELSIF i < NS THEN   (* the dog smells the tracks around: the freshest one *)
        best := 0; ax := -1; ay := -1;
        FOR y := hy[i] - 2 TO hy[i] + 2 DO FOR x := hx[i] - 2 TO hx[i] + 2 DO
          IF (x >= 0) & (y >= 0) & (x < N) & (y < N) THEN
            k := urma[y * N + x]; IF (k > 0) & (t - k < TRACK) & (k > best) THEN best := k; ax := x; ay := y END
          END
        END END;
        IF ax >= 0 THEN gx[i] := FLT(ax); gy[i] := FLT(ay); sg[i] := 2.0; dogX := ax; dogY := ay
        ELSE   (* no smell: go where the mammoth says, and the bell widens *)
          sg[i] := sg[i] + 0.25; IF sg[i] > 4.0 THEN sg[i] := 4.0 END;
          gx[i] := (gx[i] * 3.0 + mamX) / 4.0 + FLT(Rnd(5) - 2); gy[i] := (gy[i] * 3.0 + mamY) / 4.0 + FLT(Rnd(5) - 2)
        END
      ELSIF ~heard THEN   (* the long ones heard nothing: the bell widens and wanders through the forest *)
        sg[i] := sg[i] + 0.5; IF sg[i] > 14.0 THEN sg[i] := 14.0 END;
        IF (Rnd(12) = 0) OR (Far(hx[i], hy[i], FLOOR(gx[i] + 0.5), FLOOR(gy[i] + 0.5)) <= 1) THEN
          gx[i] := FLT(4 + Rnd(41)); gy[i] := FLT(4 + Rnd(41))
        END
      END;
      IF gx[i] < 0.0 THEN gx[i] := 0.0 ELSIF gx[i] > 48.0 THEN gx[i] := 48.0 END;
      IF gy[i] < 0.0 THEN gy[i] := 0.0 ELSIF gy[i] > 48.0 THEN gy[i] := 48.0 END;
      tgx[i] := FLOOR(gx[i] + 0.5); tgy[i] := FLOOR(gy[i] + 0.5);
      StepHunter(i);
      IF (state = PLAY) & (Far(hx[i], hy[i], bx, by) <= 1) THEN state := CAUGHT; catcher := i; tEnd := t END
    END;
    moved := FALSE;
    IF ~heard THEN   (* the mammoth walks slowly to the middle of the long bells *)
      sx := 0.0; sy := 0.0; FOR j := NS TO NH - 1 DO sx := sx + gx[j]; sy := sy + gy[j] END;
      mamX := (mamX * 7.0 + sx / 7.0) / 8.0; mamY := (mamY * 7.0 + sy / 7.0) / 8.0
    END
  END Hunters;

  PROCEDURE BoarAim;   (* WATCH: the boar chooses alone. It sees the forest as a map of ways: each cell costs a step,
                          and more near a hunter; the cheapest way to the nearest acorn (then the den) is its way.
                          A hunter near and a bush under it: it stands still. *)
    VAR k, x, y, i, d, near, gx2, gy2, pass, v, best: INTEGER; changed: BOOLEAN;
  BEGIN
    near := 99; gx2 := dx; gy2 := dy; d := 1000;
    FOR i := 0 TO NA - 1 DO IF ~got[i] & (Far(ax[i], ay[i], bx, by) < d) THEN d := Far(ax[i], ay[i], bx, by); gx2 := ax[i]; gy2 := ay[i] END END;
    FOR i := 0 TO NH - 1 DO d := Far(hx[i], hy[i], bx, by); IF d < near THEN near := d END END;
    FOR i := 0 TO NN - 1 DO   (* the price of each cell *)
      x := i MOD N; y := i DIV N;
      IF ter[i] = TREE THEN cost[i] := -1
      ELSE
        v := 10; IF ter[i] = WATER THEN v := 20 END;
        FOR k := 0 TO NH - 1 DO d := Far(hx[k], hy[k], x, y); IF d < 8 THEN v := v + 400 DIV (d * d + 1) END END;
        cost[i] := v
      END;
      way[i] := 1000000
    END;
    way[gy2 * N + gx2] := 0;
    pass := 0; changed := TRUE;
    WHILE changed & (pass < 12) DO   (* the ways spread from the goal, forth and back, until they stop changing *)
      changed := FALSE; INC(pass);
      FOR i := 0 TO NN - 1 DO
        IF ODD(pass) THEN v := i ELSE v := NN - 1 - i END;
        IF cost[v] >= 0 THEN
          x := v MOD N; y := v DIV N; best := way[v];
          FOR k := 0 TO 8 DO
            d := (y + k DIV 3 - 1) * N + x + k MOD 3 - 1;
            IF (k # 4) & (x + k MOD 3 - 1 >= 0) & (x + k MOD 3 - 1 < N) & (y + k DIV 3 - 1 >= 0) & (y + k DIV 3 - 1 < N) THEN
              IF (cost[d] >= 0) & (way[d] + cost[v] < best) THEN best := way[d] + cost[v] END
            END
          END;
          IF best < way[v] THEN way[v] := best; changed := TRUE END
        END
      END
    END;
    fx := bx; fy := by; best := way[by * N + bx];
    IF (near <= 3) & (near > 1) & (At(bx, by) = BUSH) THEN best := -1 END;   (* hidden: do not move *)
    FOR k := 0 TO 8 DO
      x := bx + k MOD 3 - 1; y := by + k DIV 3 - 1;
      IF (k # 4) & Free(x, y, TRUE) THEN IF way[y * N + x] < best THEN best := way[y * N + x]; fx := x; fy := y END END
    END
  END BoarAim;

  PROCEDURE StepBoar;
    VAR sx, sy, nx, ny, k: INTEGER;
  BEGIN
    sx := Sign(fx - bx); sy := Sign(fy - by); nx := bx + sx; ny := by + sy;
    IF ~Free(nx, ny, TRUE) THEN   (* around the tree: try the two neighbours of the way *)
      IF (sx # 0) & Free(bx + sx, by, TRUE) THEN nx := bx + sx; ny := by
      ELSIF (sy # 0) & Free(bx, by + sy, TRUE) THEN nx := bx; ny := by + sy
      ELSE nx := bx; ny := by
      END
    END;
    IF (nx # bx) OR (ny # by) THEN
      bx := nx; by := ny; moved := TRUE;
      IF At(bx, by) # WATER THEN urma[by * N + bx] := t END   (* the water keeps no tracks *)
    END;
    FOR k := 0 TO NA - 1 DO IF ~got[k] & (ax[k] = bx) & (ay[k] = by) THEN got[k] := TRUE; INC(eaten) END END;
    IF (eaten = NA) & (Far(bx, by, dx, dy) = 0) THEN state := ESCAPED; tEnd := t END
  END StepBoar;

  PROCEDURE Bells;   (* the map: in each cell the sum of the short bells and of the long ones *)
    VAR x, y, i, q: INTEGER; s, l, d2, v: REAL;
  BEGIN
    FOR y := 0 TO N - 1 DO FOR x := 0 TO N - 1 DO
      s := 0.0; l := 0.0;
      FOR i := 0 TO NH - 1 DO
        d2 := (FLT(x) - gx[i]) * (FLT(x) - gx[i]) + (FLT(y) - gy[i]) * (FLT(y) - gy[i]);
        q := FLOOR(d2 / (2.0 * sg[i] * sg[i]) * 8.0);
        IF q < 128 THEN v := ex[q]; IF i < NS THEN s := s + v ELSE l := l + v END END
      END;
      l := l / 3.0;   (* seven wide bells cover the whole forest: a third of them is enough to see where they lean *)
      IF s > 1.0 THEN s := 1.0 END; IF l > 1.0 THEN l := 1.0 END;
      bs[y * N + x] := FLOOR(s * 255.0); bl[y * N + x] := FLOOR(l * 255.0)
    END END
  END Bells;

  PROCEDURE Mix(a, b, k: INTEGER): INTEGER;   (* a + (b - a) * k / 255 *)
  BEGIN RETURN a + (b - a) * k DIV 255
  END Mix;

  PROCEDURE Cell(x, y: INTEGER);
    VAR i, k, r, g, b, s, l, age: INTEGER;
  BEGIN
    i := y * N + x; k := ter[i];
    IF k = TREE THEN r := 16; g := 52; b := 30 ELSIF k = BUSH THEN r := 58; g := 112; b := 52
    ELSIF k = WATER THEN r := 34; g := 78; b := 150 ELSE r := 34; g := 82; b := 44 END;
    age := t - urma[i];
    IF (urma[i] > 0) & (age < TRACK) & (k # WATER) THEN s := 160 - age * 160 DIV TRACK; r := Mix(r, 120, s); g := Mix(g, 80, s); b := Mix(b, 40, s) END;
    IF showMap THEN
      s := bs[i] * 3 DIV 5; l := bl[i] DIV 2;
      r := Mix(r, 245, s); g := Mix(g, 150, s); b := Mix(b, 40, s);
      r := Mix(r, 70, l); g := Mix(g, 140, l); b := Mix(b, 245, l)
    END;
    OllGL6.Dreptunghi2D(ox + x * c, oy + y * c, c, c, OllGL6.RGB(r, g, b))
  END Cell;

  PROCEDURE Button(x, y, w: INTEGER; s: ARRAY OF CHAR; on: BOOLEAN);
    VAR n: INTEGER;
  BEGIN
    n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
    IF on THEN OllGL6.Rotund2D(x, y, w, 48, 24, gold); OllGL6.Text2D(x + w DIV 2 - n * 6, y + 17, s, 2, bg)
    ELSE OllGL6.Rotund2D(x, y, w, 48, 24, panel); OllGL6.Text2D(x + w DIV 2 - n * 6, y + 17, s, 2, text)
    END
  END Button;

  PROCEDURE In(x, y, x0, y0, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (x >= x0) & (x < x0 + w) & (y >= y0) & (y < y0 + h)
  END In;

  PROCEDURE Centre(cx, y: INTEGER; s: ARRAY OF CHAR; m, col: INTEGER);
    VAR n: INTEGER;
  BEGIN n := 0; WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END; OllGL6.Text2D(cx - n * 3 * m, y, s, m, col)
  END Centre;

  PROCEDURE Draw;
    VAR x, y, i, r, cx, cy, by0, bw: INTEGER;
  BEGIN
    OllGL6.Incepe(bg);
    OllGL6.Text2D(20, 18, "HERNE", 3, gold); OllGL6.Text2D(20 + 6 * 18 + 12, 26, "THE BOAR HUNT", 1, muted);
    OllGL6.Rotund2D(W - 58, 6, 52, 40, 12, panel); OllGL6.Text2D(W - 38, 18, "X", 2, red);
    IF state = PLAY THEN x := t - tStart ELSE x := tEnd - tStart END;
    OllGL6.Text2D(20, 62, "TIME", 2, muted); OllGL6.Numar2D(20 + 5 * 12, 62, x DIV 60, 2, text);
    IF ~watch THEN
      OllGL6.Text2D(W DIV 2 - 20, 62, "ACORNS", 2, muted);
      FOR i := 0 TO NA - 1 DO
        IF i < eaten THEN cx := OllGL6.RGB(150, 95, 40) ELSE cx := panel END;
        OllGL6.Cerc2D(W DIV 2 + 70 + i * 22, 69, 8, cx)
      END
    END;
    IF watch THEN
      OllGL6.Text2D(W DIV 2 - 40, 62, "BOAR", 2, OllGL6.RGB(200, 150, 100)); OllGL6.Numar2D(W DIV 2 + 14, 62, nBoar, 2, text);
      OllGL6.Text2D(W DIV 2 + 60, 62, "SHORT", 2, orange); OllGL6.Numar2D(W DIV 2 + 128, 62, nShort, 2, text);
      OllGL6.Text2D(W DIV 2 + 174, 62, "LONG", 2, blue); OllGL6.Numar2D(W DIV 2 + 230, 62, nLong, 2, text)
    END;
    OllGL6.Dreptunghi2D(ox - 3, oy - 3, N * c + 6, N * c + 6, panel);
    FOR y := 0 TO N - 1 DO FOR x := 0 TO N - 1 DO Cell(x, y) END END;
    r := c * 3 DIV 4 + 2;
    IF eaten = NA THEN x := gold ELSE x := muted END;
    OllGL6.Inel2D(ox + dx * c + c DIV 2, oy + dy * c + c DIV 2, c + 4, 3, x);   (* the den: gold when it is open *)
    FOR i := 0 TO NA - 1 DO   (* the acorns *)
      IF ~got[i] THEN
        OllGL6.Cerc2D(ox + ax[i] * c + c DIV 2, oy + ay[i] * c + c DIV 2 + 1, c DIV 2, OllGL6.RGB(150, 95, 40));
        OllGL6.Dreptunghi2D(ox + ax[i] * c + 1, oy + ay[i] * c, c - 2, c DIV 3, OllGL6.RGB(90, 60, 30))
      END
    END;
    IF showMap THEN
      OllGL6.Cerc2D(ox + FLOOR(mamX * FLT(c)) + c DIV 2, oy + FLOOR(mamY * FLT(c)) + c DIV 2, c, OllGL6.RGB(150, 150, 165));   (* the mammoth *)
      FOR i := 0 TO NH - 1 DO
        IF i < NS THEN cx := orange ELSE cx := blue END;
        IF sg[i] <= 7.0 THEN OllGL6.Inel2D(ox + FLOOR(gx[i] * FLT(c)) + c DIV 2, oy + FLOOR(gy[i] * FLT(c)) + c DIV 2, FLOOR(sg[i] * FLT(c)), 1, cx) END   (* the narrow bells: who is sure of what *)
      END
    END;
    OllGL6.Cerc2D(ox + dogX * c + c DIV 2, oy + dogY * c + c DIV 2, c DIV 3 + 1, text);   (* the little dog *)
    FOR i := 0 TO NH - 1 DO
      cx := ox + hx[i] * c + c DIV 2; cy := oy + hy[i] * c + c DIV 2;
      OllGL6.Cerc2D(cx, cy, r, bg);
      IF i < NS THEN OllGL6.Cerc2D(cx, cy, r - 2, orange) ELSE OllGL6.Cerc2D(cx, cy, r - 2, blue) END
    END;
    cx := ox + bx * c + c DIV 2; cy := oy + by * c + c DIV 2;   (* the boar, and its tusks *)
    IF At(bx, by) = BUSH THEN y := OllGL6.RGB(70, 45, 30) ELSE y := OllGL6.RGB(110, 70, 40) END;
    OllGL6.Cerc2D(cx, cy, c, text); OllGL6.Cerc2D(cx, cy, c - 2, y);
    OllGL6.Dreptunghi2D(cx - c DIV 2, cy + 1, 2, c DIV 2 + 1, text); OllGL6.Dreptunghi2D(cx + c DIV 2 - 1, cy + 1, 2, c DIV 2 + 1, text);
    IF state # PLAY THEN
      bw := N * c - 40; by0 := oy + N * c DIV 2 - 70;
      OllGL6.Rotund2D(ox + 20, by0, bw, 140, 24, OllGL6.RGB(14, 4, 28));
      IF state = ESCAPED THEN Centre(ox + N * c DIV 2, by0 + 26, "THE DEN!", 4, gold); Centre(ox + N * c DIV 2, by0 + 78, "THE BOAR ESCAPED", 2, text)
      ELSIF catcher < NS THEN Centre(ox + N * c DIV 2, by0 + 26, "CAUGHT", 4, orange); Centre(ox + N * c DIV 2, by0 + 78, "BY A SHORT ONE (THE DOG)", 2, text)
      ELSE Centre(ox + N * c DIV 2, by0 + 26, "CAUGHT", 4, blue); Centre(ox + N * c DIV 2, by0 + 78, "BY A LONG ONE (THE MAMMOTH)", 2, text)
      END;
      IF ~watch THEN Centre(ox + N * c DIV 2, by0 + 108, "TAP TO HUNT AGAIN", 1, muted) END
    END;
    y := oy + N * c + 16; bw := (W - 40 - 24) DIV 3;
    Button(20, y, bw, "NEW", FALSE); Button(32 + bw, y, bw, "MAP", showMap); Button(44 + 2 * bw, y, bw, "WATCH", watch);
    y := y + 68;
    IF y + 90 < H THEN
      OllGL6.Cerc2D(28, y + 7, 7, orange); OllGL6.Text2D(44, y, "7 SHORT BELLS . THE DOG FOLLOWS THE TRACKS", 1, text);
      OllGL6.Cerc2D(28, y + 29, 7, blue); OllGL6.Text2D(44, y + 22, "7 LONG BELLS . THE MAMMOTH HEARS FROM FAR", 1, text);
      OllGL6.Text2D(20, y + 50, "HOLD THE FOREST TO RUN THERE. STILL IN A BUSH,", 1, muted);
      OllGL6.Text2D(20, y + 66, "NOBODY HEARS YOU. THE WATER WASHES THE TRACKS.", 1, muted);
      OllGL6.Text2D(20, y + 82, "EAT THE 7 ACORNS, THEN RUN TO THE DEN.", 1, muted)
    END;
    OllGL6.Arata
  END Draw;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, bw, yb: INTEGER;
  BEGIN
    r := 0; INC(t);
    IF entered THEN IF ~isDown THEN entered := FALSE END; isDown := FALSE END;
    pressed := isDown & ~wasDown; wasDown := isDown;
    yb := oy + N * c + 16; bw := (W - 40 - 24) DIV 3;
    IF pressed & In(x, y, W - 64, 0, 64, 52) THEN r := -1
    ELSIF pressed & In(x, y, 20, yb, bw, 48) THEN watch := FALSE; NewForest
    ELSIF pressed & In(x, y, 32 + bw, yb, bw, 48) THEN showMap := ~showMap
    ELSIF pressed & In(x, y, 44 + 2 * bw, yb, bw, 48) THEN watch := ~watch; nBoar := 0; nShort := 0; nLong := 0; NewForest
    ELSIF pressed & (state # PLAY) & ~watch & In(x, y, ox, oy, N * c, N * c) THEN NewForest
    END;
    IF state = PLAY THEN
      IF watch THEN IF t MOD BT = 0 THEN BoarAim END
      ELSIF isDown & In(x, y, ox, oy, N * c, N * c) THEN fx := (x - ox) DIV c; fy := (y - oy) DIV c; fingerRun := TRUE
      ELSIF ~isDown THEN fx := bx; fy := by   (* the finger lifted: the boar stands *)
      END;
      IF (At(bx, by) = WATER) & (t MOD (2 * BT) = 0) OR (At(bx, by) # WATER) & (t MOD BT = 0) THEN StepBoar END;
      IF (state = PLAY) & (t MOD HT = 0) THEN Hunters END
    ELSIF watch & (t - tEnd > 90) THEN   (* the tally, and the next hunt *)
      IF state = ESCAPED THEN INC(nBoar) ELSIF catcher < NS THEN INC(nShort) ELSE INC(nLong) END;
      INC(games); NewForest
    END;
    IF showMap & (t MOD 3 = 0) THEN Bells END;
    Draw
    RETURN r
  END Frame;

  PROCEDURE Tally*(n: INTEGER; VAR boar, short, long: INTEGER);   (* n hunts in WATCH without drawing (to weigh the rules) *)
    VAR k: INTEGER;
  BEGIN
    boar := 0; short := 0; long := 0;
    FOR k := 1 TO n DO
      NewForest; watch := TRUE;
      WHILE (state = PLAY) & (t - tStart < 60 * 60 * 5) DO
        INC(t); IF t MOD BT = 0 THEN BoarAim END;
        IF (At(bx, by) = WATER) & (t MOD (2 * BT) = 0) OR (At(bx, by) # WATER) & (t MOD BT = 0) THEN StepBoar END;
        IF (state = PLAY) & (t MOD HT = 0) THEN Hunters END
      END;
      IF state = ESCAPED THEN INC(boar) ELSIF state = CAUGHT THEN IF catcher < NS THEN INC(short) ELSE INC(long) END END;
      tallyFrames := tallyFrames + t - tStart; tallyEaten := tallyEaten + eaten
    END;
    watch := FALSE
  END Tally;

  PROCEDURE Enter*;   (* the finger that opened HERNE does not press anything *)
  BEGIN entered := TRUE; wasDown := TRUE
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
    VAR k: INTEGER;
  BEGIN
    W := w; H := h;
    c := (W - 16) DIV N; k := (H - 260) DIV N; IF k < c THEN c := k END; IF c < 4 THEN c := 4 END;
    ox := (W - N * c) DIV 2; oy := 100;
    FOR k := 0 TO 127 DO ex[k] := Ex(FLT(k) / 8.0) END;
    NewForest; Bells
  END Start;

BEGIN
  W := 540; H := 1000; t := 0; seed := 2026; watch := FALSE; showMap := TRUE; wasDown := FALSE; entered := FALSE;
  nBoar := 0; nShort := 0; nLong := 0; games := 0; c := 10; ox := 0; oy := 100;
  bg := OllGL6.RGB(14, 4, 28); text := OllGL6.RGB(240, 235, 250); muted := OllGL6.RGB(150, 140, 175);
  gold := OllGL6.RGB(212, 160, 23); panel := OllGL6.RGB(52, 22, 86); orange := OllGL6.RGB(245, 150, 40);
  blue := OllGL6.RGB(80, 150, 245); red := OllGL6.RGB(239, 68, 68)
END Herne1.
