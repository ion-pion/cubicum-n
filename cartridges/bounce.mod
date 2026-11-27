MODULE Bounce;  (* a ball; tap the screen and it changes colour *)
  IMPORT Screen, Touch;
  VAR x, y, dx, dy, w, h, c, k: INTEGER;
BEGIN
  w := Screen.Width(); h := Screen.Height();
  x := w DIV 2; y := h DIV 3; dx := 7; dy := 5; c := Screen.RGB(74, 222, 128); k := 0;
  REPEAT
    x := x + dx; y := y + dy;
    IF (x < 30) OR (x > w - 30) THEN dx := -dx END;
    IF (y < 30) OR (y > h - 30) THEN dy := -dy END;
    IF Touch.Tap() THEN c := Screen.RGB(Touch.X() MOD 256, 160, Touch.Y() MOD 256); INC(k) END;
    Screen.Clear(Screen.RGB(14, 4, 28));
    Screen.Circle(x, y, 28, c);
    Screen.String(20, 30, "TAPS ", 3, Screen.RGB(212, 160, 23)); Screen.Int(110, 30, k, 3, Screen.RGB(212, 160, 23));
    Screen.Show
  UNTIL k = 20
END Bounce.
