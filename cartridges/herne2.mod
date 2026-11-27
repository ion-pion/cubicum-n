MODULE Herne2; (* HERNE 2, the boar hunt, turn by turn. Pion & Claude 2026 *)
IMPORT Screen, Touch, Sound, Tor;
CONST C = 13; R = 17; NN = 221; MH = 12; TREE = 1; BUSH = 2;
BG = 1836046; GOLD = 1548500; TXT = 16444400; PAN = 5641780; ORC = 2660085; BLC = 16094800; BOAR = 2639470;
AC = 3305130; TREEC = 1979408; BUSHC = 3436602; TRACK = 2640980; GR = 2904610; RED = 4474095;
VAR ter, urma: ARRAY NN OF INTEGER;
hx, hy, tx, ty: ARRAY MH OF INTEGER;
ax, ay: ARRAY 7 OF INTEGER;
nh, eaten, bx, by, dx, dy, turn, level, state, seed, cs, ox, oy, w, px, py, moved, quit, k, x, y: INTEGER;
PROCEDURE Rand(m: INTEGER): INTEGER;
BEGIN seed := (seed * 1103 + 12345) MOD 65536
RETURN seed * m DIV 65536
END Rand;
PROCEDURE At(a, b: INTEGER): INTEGER;
VAR r: INTEGER;
BEGIN r := TREE; IF (a >= 0) & (b >= 0) & (a < C) & (b < R) THEN r := ter[b * C + a] END
RETURN r
END At;
PROCEDURE Far(a, b, c, d: INTEGER): INTEGER;
BEGIN a := ABS(a - c); b := ABS(b - d); IF b > a THEN a := b END
RETURN a
END Far;
PROCEDURE Sgn(v: INTEGER): INTEGER;
BEGIN IF v > 0 THEN v := 1 ELSIF v < 0 THEN v := -1 END
RETURN v
END Sgn;
PROCEDURE Hunter(a, b: INTEGER): INTEGER;
VAR j, r: INTEGER;
BEGIN r := -1; FOR j := 0 TO MH - 1 DO IF (hx[j] = a) & (hy[j] = b) THEN r := j END END
RETURN r
END Hunter;
PROCEDURE Forest;
VAR j, q: INTEGER;
BEGIN
FOR j := 0 TO NN - 1 DO
q := Rand(100); ter[j] := 0;
IF (q < 14) & (j < 195) THEN ter[j] := TREE ELSIF q < 30 THEN ter[j] := BUSH END;
urma[j] := -100
END;
bx := 6; by := R - 1; dx := 1 + Rand(11); dy := 0;
ter[by * C + bx] := 0; ter[dx] := 0; ter[C + dx] := 0;
FOR j := 0 TO 6 DO
x := Rand(C); y := 1 + Rand(R - 3); ter[y * C + x] := 0; ax[j] := x; ay[j] := y
END;
eaten := 0; nh := level + 1; IF nh > MH THEN nh := MH END;
FOR j := 0 TO MH - 1 DO hx[j] := -9; hy[j] := -9 END;
FOR j := 0 TO nh - 1 DO
REPEAT x := Rand(C); y := Rand(8) UNTIL Hunter(x, y) < 0;
ter[y * C + x] := 0; hx[j] := x; hy[j] := y; tx[j] := x; ty[j] := y
END;
turn := 0; state := 0; moved := 0
END Forest;
PROCEDURE Step(j, sx, sy, gx, gy: INTEGER);
VAR q, a, b, d, bd, nx, ny: INTEGER;
BEGIN
nx := sx; ny := sy; bd := ABS(sx - gx) + ABS(sy - gy);
FOR q := 0 TO 8 DO
a := sx + q MOD 3 - 1; b := sy + q DIV 3 - 1;
IF (At(a, b) # TREE) & (Hunter(a, b) < 0) THEN
d := ABS(a - gx) + ABS(b - gy);
IF d < bd THEN bd := d; nx := a; ny := b END
END
END;
hx[j] := nx; hy[j] := ny
END Step;
PROCEDURE Hunters;
VAR j, a, b, d, fr, sx, sy, gx, gy: INTEGER;
BEGIN
FOR j := 0 TO nh - 1 DO
sx := hx[j]; sy := hy[j]; gx := tx[j]; gy := ty[j]; d := Far(sx, sy, bx, by);
IF (d <= 1) OR ((d <= 2) & ((ter[by * C + bx] # BUSH) OR (moved = 1))) THEN gx := bx; gy := by
ELSIF j MOD 2 = 0 THEN
fr := turn - 7;
FOR b := sy - 2 TO sy + 2 DO FOR a := sx - 2 TO sx + 2 DO
IF At(a, b) # TREE THEN
IF urma[b * C + a] > fr THEN fr := urma[b * C + a]; gx := a; gy := b END
END
END END
ELSIF (moved = 1) & (d <= 6) THEN gx := bx + Rand(3) - 1; gy := by + Rand(3) - 1
END;
IF (sx = gx) & (sy = gy) THEN gx := Rand(C); gy := Rand(R) END;
tx[j] := gx; ty[j] := gy;
IF (j MOD 2 = 0) OR (turn MOD 2 = 0) THEN Step(j, sx, sy, gx, gy) END;
IF (hx[j] = bx) & (hy[j] = by) THEN state := 1 END
END
END Hunters;
PROCEDURE Dot(a, b, r, c: INTEGER);
BEGIN Screen.Circle(ox + a * cs + cs DIV 2, oy + b * cs + cs DIV 2, r, c)
END Dot;
PROCEDURE Ring(a, b, c, e: INTEGER);
BEGIN Dot(a, b, cs DIV 2 - 2, c); Dot(a, b, cs DIV 2 - 6, e)
END Ring;
PROCEDURE Draw;
VAR j, c: INTEGER;
BEGIN
Screen.Clear(BG);
Screen.String(20, 24, "HERNE", 4, GOLD); Screen.Int(220, 30, level, 3, TXT);
Screen.Int(30, 80, eaten, 3, AC);
FOR j := 0 TO NN - 1 DO
c := GR;
IF ter[j] = TREE THEN c := TREEC ELSIF ter[j] = BUSH THEN c := BUSHC ELSIF turn - urma[j] < 7 THEN c := TRACK END;
Screen.Rect(ox + j MOD C * cs, oy + j DIV C * cs, cs - 1, cs - 1, c)
END;
Ring(dx, dy, GOLD, BG);
FOR j := 0 TO 6 DO IF ax[j] >= 0 THEN Dot(ax[j], ay[j], cs DIV 5, AC) END END;
FOR j := 0 TO nh - 1 DO
c := ORC; IF j MOD 2 = 1 THEN c := BLC END;
Ring(hx[j], hy[j], BG, c)
END;
Ring(bx, by, TXT, BOAR);
j := oy + R * cs + 20;
c := PAN; IF state = 1 THEN c := RED ELSIF state = 2 THEN c := GOLD END; Screen.Rect(20, j, w - 170, 44, c);
Screen.Rect(w - 130, j, 110, 44, PAN); Screen.String(w - 105, j + 14, "END", 2, TXT);
Screen.Show
END Draw;
BEGIN
w := Screen.Width(); seed := Tor.Time() MOD 65536;
cs := (w - 20) DIV C; k := (Screen.Height() - 260) DIV R; IF k < cs THEN cs := k END;
ox := (w - C * cs) DIV 2; oy := 120; level := 1; quit := 0;
Forest; Draw;
WHILE quit = 0 DO
IF Touch.Tap() THEN
px := Touch.X(); py := Touch.Y(); k := oy + R * cs + 20;
IF (px > w - 130) & (py > k) & (py < k + 44) THEN quit := 1
ELSIF state = 1 THEN Forest
ELSIF state = 2 THEN INC(level); Forest
ELSIF py < oy THEN Forest
ELSIF py < oy + R * cs THEN
x := bx + Sgn((px - ox) DIV cs - bx); y := by + Sgn((py - oy) DIV cs - by);
moved := 0;
IF (At(x, y) # TREE) & ((x # bx) OR (y # by)) THEN moved := 1; bx := x; by := y; urma[by * C + bx] := turn END;
FOR k := 0 TO 6 DO
IF (ax[k] = bx) & (ay[k] = by) THEN ax[k] := -1; INC(eaten); Sound.Note(eaten - 1, 2, 3, 160) END
END;
INC(turn);
IF (bx = dx) & (by = dy) THEN state := 2 ELSE Hunters END;
IF state = 1 THEN Sound.Note(0, 0, 0, 500) END
END;
Draw
END;
Tor.Sleep(20)
END;
Screen.Clear(BG); Screen.Show
END Herne2.
