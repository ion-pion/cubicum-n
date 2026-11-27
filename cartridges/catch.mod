MODULE Catch;  (* catch the falling notes: touch them before they reach the floor *)
  IMPORT Screen, Touch, Sound;
  CONST N = 5;
  TYPE Note = RECORD x, y, v, z: INTEGER END;
  VAR n: ARRAY N OF Note; i, w, h, score, miss, seed, tx, ty: INTEGER;

  PROCEDURE Rand(m: INTEGER): INTEGER;
  BEGIN seed := (seed * 1103 + 12345) MOD 65536
    RETURN seed MOD m
  END Rand;

  PROCEDURE Start(VAR a: Note);
  BEGIN a.x := 40 + Rand(w - 80); a.y := -Rand(400); a.v := 3 + Rand(4); a.z := Rand(7)
  END Start;

  PROCEDURE Colour(z: INTEGER): INTEGER;
    VAR c: INTEGER;
  BEGIN
    CASE z OF
      0: c := Screen.RGB(239, 68, 68)
    | 1: c := Screen.RGB(251, 146, 60)
    | 2: c := Screen.RGB(250, 204, 21)
    | 3: c := Screen.RGB(74, 222, 128)
    | 4: c := Screen.RGB(56, 189, 248)
    | 5: c := Screen.RGB(129, 140, 248)
    ELSE c := Screen.RGB(232, 121, 249)
    END
    RETURN c
  END Colour;

BEGIN
  w := Screen.Width(); h := Screen.Height(); seed := 7; score := 0; miss := 0;
  FOR i := 0 TO N - 1 DO Start(n[i]) END;
  WHILE miss < 10 DO
    Screen.Clear(Screen.RGB(14, 4, 28));
    IF Touch.Tap() THEN
      tx := Touch.X(); ty := Touch.Y();
      FOR i := 0 TO N - 1 DO
        IF (ABS(tx - n[i].x) < 50) & (ABS(ty - n[i].y) < 50) THEN
          Sound.Note(n[i].z, 1, 2, 300); INC(score); Start(n[i])
        END
      END
    END;
    FOR i := 0 TO N - 1 DO
      n[i].y := n[i].y + n[i].v;
      IF n[i].y > h THEN INC(miss); Start(n[i]) END;
      Screen.Circle(n[i].x, n[i].y, 30, Colour(n[i].z))
    END;
    Screen.String(20, 30, "SCORE", 3, Screen.RGB(212, 160, 23)); Screen.Int(140, 30, score, 3, Screen.RGB(212, 160, 23));
    Screen.String(300, 30, "MISS", 3, Screen.RGB(239, 68, 68)); Screen.Int(400, 30, miss, 3, Screen.RGB(239, 68, 68));
    Screen.Show
  END;
  Screen.String(120, h DIV 2, "GAME OVER", 5, Screen.RGB(212, 160, 23)); Screen.Show
END Catch.
