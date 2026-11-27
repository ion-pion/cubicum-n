MODULE Tubul2; (* TUBUL 2, the tube in 3D, a cartridge of Pixipogo 52. Pion & Claude, 25.11.2026
  Pion: "no tilt control, no 3D graphics and the music is missing altogether" - now all three, from Pixipogo itself:
  the tube is drawn by the graphics card along a path that bends (IMPORT Space), you steer the pangolin by tilting the
  phone (Touch.TiltX; or hold the left / right half of the screen), and a song of two voices plays by itself (Sound.Seq).
  Red gates have a hole: roll through it, or lose a life. The gems on the wall are notes: catch them.
  The tube goes faster. Three lives. END is at the bottom left (the X of the canvas is at the top right). *)
IMPORT Screen, Touch, Sound, Space, Tor;
CONST NP = 512; R = 1500; AHEAD = 44; NG = 6; NM = 24; HOLE = 5;
W1 = 6822970; W2 = 8135750; BG = 1442826; RED = 3947745; BROWN = 2772600;
GOLD = 1548500; TXT = 16444400; MUT = 11504790; PAN = 5641780;
VAR gp, ga: ARRAY NG OF INTEGER; mp, ma, mn: ARRAY NM OF INTEGER; nc: ARRAY 7 OF INTEGER;
w, h, seed, n, x, y, bx, by, tbx, tby, pos, speed, pa, score, best, lives, state, quit, flash, lastGate, lastGem,
k, cur, d, a: INTEGER;

PROCEDURE Rand(m: INTEGER): INTEGER;
BEGIN seed := (seed * 1103 + 12345) MOD 65536
RETURN seed * m DIV 65536
END Rand;

PROCEDURE Grow;   (* the next point of the path: the tube bends slowly, left-right and up-down *)
BEGIN
IF Rand(100) < 6 THEN tbx := Rand(401) - 200 END;
IF Rand(100) < 5 THEN tby := Rand(241) - 120 END;
bx := bx + (tbx - bx) DIV 10; by := by + (tby - by) DIV 10;
x := x + bx; y := y + by;
Space.Point(n MOD NP, x, y, n * 1000); INC(n)
END Grow;

PROCEDURE Diff(a, b: INTEGER): INTEGER;   (* the distance of two angles in 64ths, 0..32 *)
BEGIN a := (a - b) MOD 64; IF a > 32 THEN a := 64 - a END
RETURN a
END Diff;

PROCEDURE NewGate(j: INTEGER);
BEGIN lastGate := lastGate + 18 + Rand(10) - speed DIV 40; IF lastGate < cur + 12 THEN lastGate := cur + 12 END;
gp[j] := lastGate; ga[j] := Rand(64)
END NewGate;

PROCEDURE NewGem(j: INTEGER);
BEGIN lastGem := lastGem + 3 + Rand(4); mp[j] := lastGem; ma[j] := (ma[(j + NM - 1) MOD NM] + Rand(9) + 60) MOD 64; mn[j] := Rand(7)
END NewGem;

PROCEDURE Song;   (* two voices, 16 steps: the melody walks the Do major of the cube, the bass holds *)
BEGIN
Sound.Seq(0, 0, 8); Sound.Seq(0, 1, 0); Sound.Seq(0, 2, 10); Sound.Seq(0, 3, 12);
Sound.Seq(0, 4, 11); Sound.Seq(0, 5, 0); Sound.Seq(0, 6, 9); Sound.Seq(0, 7, 8);
Sound.Seq(0, 8, 12); Sound.Seq(0, 9, 0); Sound.Seq(0, 10, 13); Sound.Seq(0, 11, 15);
Sound.Seq(0, 12, 14); Sound.Seq(0, 13, 12); Sound.Seq(0, 14, 10); Sound.Seq(0, 15, 0);
Sound.Seq(1, 0, 1); Sound.Seq(1, 4, 5); Sound.Seq(1, 8, 6); Sound.Seq(1, 12, 4);
Sound.Tempo(170); Sound.Loop(16)
END Song;

PROCEDURE Start;
BEGIN
n := 0; x := 0; y := 0; bx := 0; by := 0; tbx := 0; tby := 0;
FOR k := 0 TO 8 DO Space.Point(n MOD NP, 0, 0, n * 1000); INC(n) END;
WHILE n < AHEAD + 10 DO Grow END;
pos := 0; cur := 0; speed := 70; pa := 768; score := 0; lives := 3; state := 0; flash := 0;
lastGate := 14; lastGem := 6; ma[NM - 1] := 48;
FOR k := 0 TO NG - 1 DO NewGate(k) END;
FOR k := 0 TO NM - 1 DO NewGem(k) END;
Touch.Level
END Start;

PROCEDURE Pass;   (* what the pangolin reaches: it rolls 3.5 points in front of the camera *)
VAR j, p: INTEGER;
BEGIN
p := (pos + 3500) DIV 1000;
FOR j := 0 TO NG - 1 DO
IF gp[j] <= p THEN
IF Diff(pa DIV 16, ga[j]) <= HOLE THEN INC(score, 5); Sound.Note(6, 2, 3, 120)
ELSE DEC(lives); flash := 12; speed := speed * 2 DIV 3; IF speed < 70 THEN speed := 70 END;
Sound.Note(0, 0, 0, 400); IF lives <= 0 THEN state := 1; Sound.Loop(0) END
END;
NewGate(j)
END
END;
FOR j := 0 TO NM - 1 DO
IF mp[j] <= p THEN
IF Diff(pa DIV 16, ma[j]) <= 3 THEN INC(score); Sound.Note(mn[j], 3, 3, 140) END;
NewGem(j)
END
END
END Pass;

PROCEDURE Draw;
VAR j: INTEGER;
BEGIN
Screen.Clear(BG);
Space.Fov(70); Space.Fog(6000, 34000); Space.Light(450);
Space.Follow(pos, 8, pa, 520, 300); Space.Roll(768 - pa);
Space.Tube(cur - 1, cur + AHEAD, R, 24, W1, W2);
FOR j := 0 TO NG - 1 DO
IF (gp[j] >= cur) & (gp[j] < cur + AHEAD) THEN Space.Arc(gp[j], ga[j] + HOLE, ga[j] + 64 - HOLE, R, 420, RED) END
END;
FOR j := 0 TO NM - 1 DO
IF (mp[j] >= cur) & (mp[j] < cur + AHEAD) THEN Space.At(mp[j] * 1000, ma[j] * 16, 1250, 130, nc[mn[j]]) END
END;
Space.At(pos + 3500, pa, 1200, 230, BROWN);
IF flash > 0 THEN Screen.Rect(0, 0, w, 14, RED); Screen.Rect(0, h - 14, w, 14, RED); DEC(flash) END;
Screen.String(20, 22, "TUBUL", 4, GOLD); Screen.Int(190, 22, score, 4, TXT);
Screen.String(300, 30, "BEST", 2, MUT); Screen.Int(355, 30, best, 2, GOLD);
FOR j := 0 TO 2 DO a := PAN; IF j < lives THEN a := BROWN END; Screen.Circle(30 + j * 26, 90, 9, a) END;
Screen.Rect(16, h - 76, 110, 50, PAN); Screen.String(42, h - 60, "END", 2, TXT);
IF state = 1 THEN
Screen.Rect(16, h DIV 2 - 40, w - 32, 70, RED); Screen.String(40, h DIV 2 - 16, "THE TUBE WON. TAP TO ROLL AGAIN", 2, TXT)
END;
Screen.Show
END Draw;

BEGIN
w := Screen.Width(); h := Screen.Height(); seed := Tor.Time() MOD 65536; best := 0;
nc[0] := 4474095; nc[1] := 3969787; nc[2] := 1428730; nc[3] := 8445514; nc[4] := 16301368; nc[5] := 16288897; nc[6] := 16349672;
Start; Song; quit := 0;
WHILE quit = 0 DO
IF Touch.Tap() THEN
IF (Touch.X() < 140) & (Touch.Y() > h - 90) THEN quit := 1
ELSIF state = 1 THEN Start; Song
END
END;
IF state = 0 THEN
d := Touch.TiltX(); IF d > 600 THEN d := (d - 600) DIV 140 ELSIF d < -600 THEN d := (d + 600) DIV 140 ELSE d := 0 END;
IF Touch.Down() & (Touch.Y() > 120) & (Touch.Y() < h - 90) THEN
IF Touch.X() < w DIV 2 THEN d := d - 14 ELSE d := d + 14 END
END;
pa := (pa + d) MOD 1024;
pos := pos + speed; cur := pos DIV 1000;
WHILE n < cur + AHEAD + 4 DO Grow END;
IF pos MOD 5000 < speed THEN INC(speed, 4); IF speed > 260 THEN speed := 260 END END;
Pass;
IF score > best THEN best := score END
END;
Draw
END;
Sound.Loop(0); Screen.Clear(BG); Screen.String(130, h DIV 2, "TUBUL SLEEPS", 3, GOLD); Screen.Show
END Tubul2.
