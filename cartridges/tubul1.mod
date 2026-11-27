MODULE Tubul1; (* TUBUL 1, the tube, as a cartridge of Pixipogo. Pion & Claude, 25.11.2026
  The pangolin rolls down the tube. Hold the left or the right half of the screen to turn around the wall.
  Red gates have a hole: go through the hole, or lose a life. The gems on the wall are notes: catch them.
  The tube goes faster and faster. Three lives. Whole numbers only: the sine is a table of 64. *)
IMPORT Screen, Touch, Sound, Tor;
CONST NR = 9; NG = 4; NM = 12; R0 = 250; HOLE = 7;
BG = 1836046; GOLD = 1548500; TXT = 16444400; MUT = 11504790; PAN = 5641780; RED = 4474095;
VAR sn: ARRAY 64 OF INTEGER; nc: ARRAY 7 OF INTEGER;
gz, ga: ARRAY NG OF INTEGER; mz, ma, mn: ARRAY NM OF INTEGER;
w, h, cx, cy, pos, speed, pa, score, best, lives, state, seed, far, flash, turn, quit, i, k, d, r, a, x, y, c, bend: INTEGER;

PROCEDURE Rand(m: INTEGER): INTEGER;
BEGIN seed := (seed * 1103 + 12345) MOD 65536
RETURN seed * m DIV 65536
END Rand;

PROCEDURE Sin(a: INTEGER): INTEGER;
BEGIN RETURN sn[a MOD 64]
END Sin;

PROCEDURE Cos(a: INTEGER): INTEGER;
BEGIN RETURN sn[(a + 16) MOD 64]
END Cos;

PROCEDURE Rad(d: INTEGER): INTEGER;   (* the radius of the tube at distance d (100 = the ring of the pangolin) *)
BEGIN IF d < 30 THEN d := 30 END
RETURN R0 * 100 DIV d
END Rad;

PROCEDURE Off(d: INTEGER): INTEGER;   (* the tube bends: how far its centre moves at distance d *)
BEGIN RETURN bend * (d DIV 10) * (d DIV 10) DIV 40000
END Off;

PROCEDURE NewGate(j: INTEGER);
BEGIN far := far + 650 + Rand(450) - speed * 8; IF far - pos < 500 THEN far := pos + 500 END;
gz[j] := far; ga[j] := Rand(64)
END NewGate;

PROCEDURE NewGem(j: INTEGER);
VAR b: INTEGER;
BEGIN b := 0; FOR i := 0 TO NM - 1 DO IF mz[i] > b THEN b := mz[i] END END;
IF b < pos + 300 THEN b := pos + 300 END;
mz[j] := b + 90 + Rand(160); ma[j] := Rand(64); mn[j] := Rand(7)
END NewGem;

PROCEDURE Start;
BEGIN
pos := 0; speed := 9; pa := 48; score := 0; lives := 3; state := 0; far := 600; flash := 0; turn := 0; bend := 0;
FOR k := 0 TO NG - 1 DO NewGate(k) END;
FOR k := 0 TO NM - 1 DO mz[k] := 0 END;
FOR k := 0 TO NM - 1 DO NewGem(k) END
END Start;

PROCEDURE Diff(a, b: INTEGER): INTEGER;   (* the distance of two angles, 0..32 *)
BEGIN a := (a - b) MOD 64; IF a > 32 THEN a := 64 - a END
RETURN a
END Diff;

PROCEDURE Draw;
VAR j, s, m, e, gx, gy: INTEGER;
BEGIN
IF flash > 0 THEN Screen.Clear(RED); DEC(flash) ELSE Screen.Clear(BG) END;
(* the rings, from the nearest to the farthest: each one a little smaller and darker *)
FOR j := 0 TO NR - 1 DO
d := 100 - pos MOD 100 + j * 100 + 40; e := Off(d); m := Rad(d);
IF j < 5 THEN Screen.Circle(cx + e, cy, m, 9185368); Screen.Circle(cx + e, cy, m - m DIV 14 - 2, 4591656)
ELSE Screen.Circle(cx + e, cy, m, 6560828); Screen.Circle(cx + e, cy, m - m DIV 14 - 2, 3017242)
END
END;
Screen.Circle(cx + Off(1000), cy, Rad(1000) - 4, BG);
(* the gems *)
FOR j := 0 TO NM - 1 DO
d := mz[j] - pos;
IF (d > 60) & (d < 1000) THEN
r := Rad(d) * 85 DIV 100; m := Rad(d) DIV 14 + 2;
Screen.Circle(cx + Off(d) + r * Cos(ma[j]) DIV 1000, cy + r * Sin(ma[j]) DIV 1000, m, nc[mn[j]])
END
END;
(* the gates: a ring of stones with a hole *)
FOR j := 0 TO NG - 1 DO
d := gz[j] - pos;
IF (d > 60) & (d < 1000) THEN
r := Rad(d) * 92 DIV 100; m := Rad(d) DIV 9 + 2; e := Off(d);
FOR s := 0 TO 31 DO
a := s * 2;
IF Diff(a, ga[j]) > HOLE DIV 2 + 1 THEN
Screen.Rect(cx + e + r * Cos(a) DIV 1000 - m DIV 2, cy + r * Sin(a) DIV 1000 - m DIV 2, m, m, RED)
END
END
END
END;
(* the pangolin *)
r := R0 * 80 DIV 100; gx := cx + Off(100) + r * Cos(pa) DIV 1000; gy := cy + r * Sin(pa) DIV 1000;
Screen.Circle(gx, gy, 28, TXT); Screen.Circle(gx, gy, 24, 2639470);
Screen.Circle(gx - 8 + Cos(pa + turn) DIV 200, gy - 6, 6, 3305130); Screen.Circle(gx + 6, gy + 7 + Sin(pa + turn) DIV 250, 5, 3305130);
(* the words *)
Screen.String(20, 22, "TUBUL", 4, GOLD); Screen.Int(200, 22, score, 4, TXT);
Screen.String(320, 30, "BEST", 2, MUT); Screen.Int(375, 30, best, 2, GOLD);
Screen.Rect(w - 100, 14, 84, 44, PAN); Screen.String(w - 82, 28, "END", 2, TXT);
FOR j := 0 TO 2 DO c := PAN; IF j < lives THEN c := 2639470 END; Screen.Circle(30 + j * 26, 90, 9, c) END;
y := h - 120;
IF state = 1 THEN
Screen.Rect(16, y - 10, w - 32, 50, RED); Screen.String(30, y + 4, "THE TUBE WON. TAP TO ROLL AGAIN", 2, TXT)
ELSE
Screen.Rect(0, y, w DIV 2 - 4, 60, PAN); Screen.Rect(w DIV 2 + 4, y, w DIV 2 - 4, 60, PAN);
Screen.String(w DIV 4 - 18, y + 22, "<<", 3, MUT); Screen.String(w * 3 DIV 4 - 18, y + 22, ">>", 3, MUT)
END;
Screen.Show
END Draw;

PROCEDURE Pass;   (* what reaches the pangolin's ring *)
VAR j: INTEGER;
BEGIN
FOR j := 0 TO NG - 1 DO
IF gz[j] - pos <= 100 THEN
IF Diff(pa, ga[j]) <= HOLE DIV 2 + 1 THEN INC(score, 5); Sound.Note(6, 2, 3, 120)
ELSE DEC(lives); flash := 4; speed := 9; Sound.Note(0, 0, 0, 400); IF lives <= 0 THEN state := 1 END
END;
NewGate(j)
END
END;
FOR j := 0 TO NM - 1 DO
IF mz[j] - pos <= 100 THEN
IF Diff(pa, ma[j]) <= 3 THEN INC(score); Sound.Note(mn[j], 3, 3, 140) END;
NewGem(j)
END
END
END Pass;

BEGIN
w := Screen.Width(); h := Screen.Height(); cx := w DIV 2; cy := h * 46 DIV 100;
seed := Tor.Time() MOD 65536; best := 0;
sn[0] := 0; sn[1] := 98; sn[2] := 195; sn[3] := 290; sn[4] := 383; sn[5] := 471; sn[6] := 556; sn[7] := 634; sn[8] := 707;
sn[9] := 773; sn[10] := 831; sn[11] := 882; sn[12] := 924; sn[13] := 957; sn[14] := 981; sn[15] := 995; sn[16] := 1000;
FOR i := 1 TO 15 DO sn[16 + i] := sn[16 - i] END;
FOR i := 1 TO 31 DO sn[32 + i] := -sn[32 - i] END;
nc[0] := 4474095; nc[1] := 2660085; nc[2] := 1548500; nc[3] := 8445514; nc[4] := 16301368; nc[5] := 16288897; nc[6] := 16349672;
Start; quit := 0;
WHILE quit = 0 DO
IF Touch.Tap() THEN
x := Touch.X(); y := Touch.Y();
IF (x > w - 110) & (y < 70) THEN quit := 1
ELSIF state = 1 THEN Start
END
END;
IF state = 0 THEN
IF Touch.Down() & (Touch.Y() > 120) THEN
IF Touch.X() < w DIV 2 THEN pa := (pa + 63) MOD 64 ELSE pa := (pa + 1) MOD 64 END
END;
pos := pos + speed; INC(turn, 3);
IF pos MOD 600 < speed THEN INC(speed); IF speed > 26 THEN speed := 26 END END;
bend := Sin(pos DIV 40) * 3 DIV 10;
Pass;
IF score > best THEN best := score END
END;
Draw
END;
Screen.Clear(BG); Screen.String(130, h DIV 2, "TUBUL SLEEPS", 3, GOLD); Screen.Show
END Tubul1.
