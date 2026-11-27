MODULE Herne3; (* HERNE 3, the boar hunt, turn by turn, with the river. A cartridge of Pixipogo 51. Pion & Claude, 25.11.2026
  You are the boar. Tap a cell next to you to step there, tap yourself to stay still. Reach the den at the top.
  Dogs (orange) follow your fresh tracks. Bowmen (blue) hear you move within 6 cells and shoot you in the water.
  The river washes your tracks away and no hunter can wade it. A still boar in a bush cannot be seen from 2 cells.
  Three lives; the best score stays while Pixipogo runs. *)
IMPORT Screen, Touch, Sound, Tor;
CONST C = 13; R = 17; NN = 221; MH = 12; RIVER = 8; CP = 15; NP = 285;   (* the board with a border of trees: 15 x 19 *)
GROUND = 0; TREE = 1; BUSH = 2; WATER = 3;
BG = 1836046; GOLD = 1548500; TXT = 16444400; MUT = 11504790; PAN = 5641780; ORC = 2660085; BLC = 16094800;
BOAR = 2639470; AC = 3305130; TREEC = 1979408; BUSHC = 3436602; TRACK = 2640980; GR = 2904610; RED = 4474095;
WAT = 9853984; WAT2 = 12485190; DIM = 9200750;
VAR ter, urma: ARRAY NN OF INTEGER;
pw, dist, q: ARRAY NP OF INTEGER; off: ARRAY 8 OF INTEGER;   (* pw: the board with its border, for the paths *)
hx, hy, tx, ty: ARRAY MH OF INTEGER;
ax, ay: ARRAY 7 OF INTEGER;
nh, eaten, total, best, lives, bx, by, dx, dy, turn, level, state, seed, cs, ox, oy, w, h, px, py, moved, quit, heard, k, x, y: INTEGER;

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

PROCEDURE Fill(wet: INTEGER);   (* dist = steps from the boar; trees stop everyone, water stops the hunters (wet = 0) *)
VAR head, tail, c, d, j, n, t: INTEGER;
BEGIN
FOR j := 0 TO NP - 1 DO dist[j] := -1 END;
c := (by + 1) * CP + bx + 1; dist[c] := 0; q[0] := c; head := 0; tail := 1;
WHILE head < tail DO
c := q[head]; INC(head); d := dist[c] + 1;
FOR j := 0 TO 7 DO
n := c + off[j];
IF dist[n] < 0 THEN
t := pw[n];
IF (t # TREE) & ((wet = 1) OR (t # WATER)) THEN dist[n] := d; q[tail] := n; INC(tail) END
END
END
END
END Fill;

PROCEDURE Forest;
VAR j, v, f: INTEGER;
BEGIN
REPEAT
FOR j := 0 TO NN - 1 DO
v := Rand(100); ter[j] := GROUND; urma[j] := -100;
IF (v < 13 + level) & (v < 22) & (j < 195) THEN ter[j] := TREE ELSIF v < 32 THEN ter[j] := BUSH END
END;
FOR j := 0 TO C - 1 DO
ter[RIVER * C + j] := WATER;
IF Rand(100) < 40 THEN ter[(RIVER + 1) * C + j] := WATER END
END;
FOR f := 1 TO 2 DO j := Rand(C); ter[RIVER * C + j] := GROUND; ter[(RIVER + 1) * C + j] := GROUND END;
bx := 6; by := R - 1; dx := 1 + Rand(C - 2); dy := 0;
ter[by * C + bx] := GROUND; ter[dx] := GROUND; ter[C + dx] := GROUND;
FOR j := 0 TO NP - 1 DO pw[j] := TREE END;
FOR j := 0 TO NN - 1 DO pw[(j DIV C + 1) * CP + j MOD C + 1] := ter[j] END;
Fill(1)
UNTIL dist[(dy + 1) * CP + dx + 1] >= 0;
FOR j := 0 TO 6 DO
REPEAT x := Rand(C); y := 1 + Rand(R - 3) UNTIL (ter[y * C + x] = GROUND) OR (ter[y * C + x] = BUSH);
ax[j] := x; ay[j] := y
END;
eaten := 0; nh := level + 1; IF nh > MH THEN nh := MH END;
FOR j := 0 TO MH - 1 DO hx[j] := -9; hy[j] := -9 END;
FOR j := 0 TO nh - 1 DO
REPEAT x := Rand(C); y := Rand(RIVER - 1) UNTIL (ter[y * C + x] # TREE) & (Hunter(x, y) < 0) & ((x # dx) OR (y > 1));
hx[j] := x; hy[j] := y; tx[j] := x; ty[j] := y
END;
turn := 0; state := 0; moved := 0; heard := 0
END Forest;

PROCEDURE Step(j, sx, sy, gx, gy, chase: INTEGER);   (* one step of hunter j: along dist when chasing, else straight *)
VAR n, a, b, d, bd, nx, ny, t: INTEGER;
BEGIN
nx := sx; ny := sy;
IF (chase = 1) & (dist[(sy + 1) * CP + sx + 1] >= 0) THEN bd := dist[(sy + 1) * CP + sx + 1] ELSE chase := 0; bd := ABS(sx - gx) + ABS(sy - gy) END;
FOR n := 0 TO 8 DO
a := sx + n MOD 3 - 1; b := sy + n DIV 3 - 1; t := At(a, b);
IF (t # TREE) & (t # WATER) & (Hunter(a, b) < 0) THEN
IF chase = 1 THEN d := dist[(b + 1) * CP + a + 1]; IF d < 0 THEN d := 999 END
ELSE d := ABS(a - gx) + ABS(b - gy)
END;
IF d < bd THEN bd := d; nx := a; ny := b END
END
END;
hx[j] := nx; hy[j] := ny
END Step;

PROCEDURE Hunters;
VAR j, a, b, d, fr, sx, sy, gx, gy, chase, field, wet: INTEGER;
BEGIN
field := 0; heard := 0; wet := 0; IF ter[by * C + bx] = WATER THEN wet := 1 END;
FOR j := 0 TO nh - 1 DO
sx := hx[j]; sy := hy[j]; gx := tx[j]; gy := ty[j]; d := Far(sx, sy, bx, by); chase := 0;
IF (d <= 1) OR ((d <= 2) & ((ter[by * C + bx] # BUSH) OR (moved = 1))) THEN chase := 1
ELSIF j MOD 2 = 0 THEN   (* a dog: the freshest track within 2 *)
fr := turn - 7;
FOR b := sy - 2 TO sy + 2 DO FOR a := sx - 2 TO sx + 2 DO
IF At(a, b) # TREE THEN IF urma[b * C + a] > fr THEN fr := urma[b * C + a]; gx := a; gy := b END END
END END;
IF (gx = bx) & (gy = by) THEN chase := 1 END
ELSIF (moved = 1) & (d <= 6) THEN chase := 1; heard := 1   (* a bowman hears the step *)
END;
IF (j MOD 2 = 1) & (wet = 1) & (d <= 2) THEN state := 1 END;   (* shot in the water *)
IF chase = 1 THEN
gx := bx; gy := by;
IF field = 0 THEN Fill(0); field := 1 END
ELSIF (sx = gx) & (sy = gy) THEN gx := Rand(C); gy := Rand(RIVER)
END;
tx[j] := gx; ty[j] := gy;
IF (j MOD 2 = 0) OR (turn MOD 2 = 0) THEN Step(j, sx, sy, gx, gy, chase) END;
IF (hx[j] = bx) & (hy[j] = by) THEN state := 1 END
END
END Hunters;

PROCEDURE Dot(a, b, r, c: INTEGER);
BEGIN Screen.Circle(ox + a * cs + cs DIV 2, oy + b * cs + cs DIV 2, r, c)
END Dot;

PROCEDURE Draw;
VAR j, c, a, b, gx, gy: INTEGER;
BEGIN
Screen.Clear(BG);
Screen.String(20, 22, "HERNE", 4, GOLD);
Screen.String(180, 20, "LEVEL", 2, MUT); Screen.Int(250, 20, level, 2, TXT);
Screen.String(180, 50, "SCORE", 2, MUT); Screen.Int(250, 50, total, 2, TXT);
Screen.String(300, 50, "BEST", 2, MUT); Screen.Int(355, 50, best, 2, GOLD);
FOR j := 0 TO 2 DO c := PAN; IF j < lives THEN c := BOAR END; Screen.Circle(310 + j * 22, 28, 8, c) END;
Screen.Rect(w - 100, 14, 84, 44, PAN); Screen.String(w - 82, 28, "END", 2, TXT);
FOR j := 0 TO 6 DO c := PAN; IF j < eaten THEN c := AC END; Screen.Circle(30 + j * 26, 96, 9, c) END;
Screen.String(220, 90, "TURN", 2, MUT); Screen.Int(275, 90, turn, 2, TXT);
IF heard = 1 THEN Screen.String(340, 90, "HEARD!", 2, RED) END;
FOR j := 0 TO NN - 1 DO
c := GR; a := ter[j];
IF a = TREE THEN c := TREEC ELSIF a = BUSH THEN c := BUSHC ELSIF a = WATER THEN c := WAT
ELSIF turn - urma[j] < 7 THEN c := TRACK
END;
Screen.Rect(ox + j MOD C * cs, oy + j DIV C * cs, cs - 1, cs - 1, c);
IF a = WATER THEN Screen.Rect(ox + j MOD C * cs + 6, oy + j DIV C * cs + cs DIV 2, cs - 13, 3, WAT2) END
END;
Dot(dx, dy, cs DIV 2 - 2, GOLD); Dot(dx, dy, cs DIV 2 - 6, BG);
FOR j := 0 TO 6 DO IF ax[j] >= 0 THEN Dot(ax[j], ay[j], cs DIV 5, AC) END END;
IF state = 0 THEN   (* where the boar can step *)
FOR j := 0 TO 8 DO
a := bx + j MOD 3 - 1; b := by + j DIV 3 - 1;
IF (j # 4) & (At(a, b) # TREE) THEN Dot(a, b, 3, TXT) END
END
END;
FOR j := 0 TO nh - 1 DO
gx := ox + hx[j] * cs + cs DIV 2; gy := oy + hy[j] * cs + cs DIV 2;
Screen.Circle(gx, gy, cs DIV 2 - 3, BG);
IF j MOD 2 = 0 THEN
Screen.Circle(gx, gy, cs DIV 2 - 6, ORC); Screen.Circle(gx - 9, gy - 10, 5, ORC); Screen.Circle(gx + 9, gy - 10, 5, ORC)
ELSE
Screen.Circle(gx, gy, cs DIV 2 - 6, BLC); Screen.Rect(gx + 10, gy - 14, 3, 28, GOLD)
END
END;
gx := ox + bx * cs + cs DIV 2; gy := oy + by * cs + cs DIV 2;
Screen.Circle(gx, gy, cs DIV 2 - 2, TXT); Screen.Circle(gx, gy, cs DIV 2 - 5, BOAR);
Screen.Rect(gx - 7, gy + 2, 3, 7, TXT); Screen.Rect(gx + 4, gy + 2, 3, 7, TXT);
gy := oy + R * cs + 16;
IF state = 1 THEN
Screen.Rect(16, gy - 6, w - 32, 44, RED);
IF lives > 0 THEN Screen.String(30, gy + 6, "CAUGHT! TAP TO TRY AGAIN", 2, TXT)
ELSE Screen.String(30, gy + 6, "THE HUNT IS OVER. TAP: A NEW HUNT", 2, TXT)
END
ELSIF state = 2 THEN
Screen.Rect(16, gy - 6, w - 32, 44, GOLD); Screen.String(30, gy + 6, "THE DEN! TAP FOR THE NEXT FOREST", 2, BG)
ELSE
Screen.String(20, gy + 6, "TAP A CELL NEXT TO YOU, OR YOU TO STAY", 2, MUT)
END;
gy := gy + 60;
Screen.Circle(30, gy + 8, 9, ORC); Screen.String(50, gy, "DOG: SMELLS YOUR FRESH TRACKS", 2, DIM);
Screen.Circle(30, gy + 38, 9, BLC); Screen.String(50, gy + 30, "BOWMAN: HEARS YOU MOVE, SHOOTS IN WATER", 2, DIM);
Screen.Rect(21, gy + 60, 18, 18, WAT); Screen.String(50, gy + 60, "THE RIVER WASHES THE TRACKS AWAY", 2, DIM);
Screen.Rect(21, gy + 90, 18, 18, BUSHC); Screen.String(50, gy + 90, "STAY STILL IN A BUSH TO HIDE", 2, DIM);
Screen.Show
END Draw;

PROCEDURE Caught;
BEGIN
IF lives <= 0 THEN level := 1; total := 0; lives := 3 END;
Forest
END Caught;

BEGIN
w := Screen.Width(); h := Screen.Height(); seed := Tor.Time() MOD 65536;
cs := (w - 20) DIV C; k := (h - 420) DIV R; IF k < cs THEN cs := k END;
ox := (w - C * cs) DIV 2; oy := 120; level := 1;
off[0] := -CP - 1; off[1] := -CP; off[2] := -CP + 1; off[3] := -1; off[4] := 1; off[5] := CP - 1; off[6] := CP; off[7] := CP + 1; quit := 0; total := 0; best := 0; lives := 3;
Forest; Draw;
WHILE quit = 0 DO
IF Touch.Tap() THEN
px := Touch.X(); py := Touch.Y();
IF (px > w - 110) & (py < 70) THEN quit := 1
ELSIF state = 1 THEN Caught
ELSIF state = 2 THEN INC(level); Forest
ELSIF (py >= oy) & (py < oy + R * cs) & (px >= ox) & (px < ox + C * cs) THEN
x := bx + Sgn((px - ox) DIV cs - bx); y := by + Sgn((py - oy) DIV cs - by);
moved := 0;
IF (At(x, y) # TREE) & ((x # bx) OR (y # by)) THEN
moved := 1; bx := x; by := y;
IF ter[by * C + bx] # WATER THEN urma[by * C + bx] := turn END
END;
FOR k := 0 TO 6 DO
IF (ax[k] = bx) & (ay[k] = by) THEN ax[k] := -1; INC(eaten); Sound.Note(eaten - 1, 2, 3, 160) END
END;
INC(turn);
IF (bx = dx) & (by = dy) THEN
state := 2; total := total + 10 * level + 5 * eaten; IF total > best THEN best := total END;
FOR k := 0 TO 4 DO Sound.Note(k, 3, 3, 120) END
ELSE Hunters
END;
IF state = 1 THEN DEC(lives); Sound.Note(0, 0, 0, 500); IF total > best THEN best := total END END
END;
Draw
END;
Tor.Sleep(20)
END;
Screen.Clear(BG); Screen.String(150, h DIV 2, "HERNE SLEEPS", 3, GOLD); Screen.Show
END Herne3.
