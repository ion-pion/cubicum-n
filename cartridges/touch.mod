MODULE Touch1;  (* draw with the finger; the colour follows the height *)
  IMPORT Screen, Touch;
  VAR x, y, n: INTEGER;
BEGIN
  Screen.Clear(Screen.RGB(14, 4, 28));
  Screen.String(20, 30, "DRAW WITH YOUR FINGER", 3, Screen.RGB(212, 160, 23));
  Screen.Show;
  n := 0;
  WHILE n < 100000 DO
    IF Touch.Down() THEN
      x := Touch.X(); y := Touch.Y();
      Screen.Circle(x, y, 12, Screen.RGB(255 - y DIV 4, 120, y DIV 4))
    END;
    Screen.Show; INC(n)
  END
END Touch1.
