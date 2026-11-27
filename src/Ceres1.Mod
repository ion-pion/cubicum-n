MODULE Ceres1;  (* CERES 1 (21 Nov 2026, Pixipogo 30): the recorder. In The Tempest Ceres comes with Iris and Juno; she
     gathers the harvest, here she gathers sounds. The big red button: on the phone the phone's own recorder opens
     (Pixipogo has no right to the microphone, Byz7 does not ask for it), and what you save there comes into the cube as
     voce-YYYYMMDD-HHMM.m4a; on a computer the window records by itself (STOP and the seconds). The recordings are listed
     here, a tap plays one with PHILOMEL. Window: rec.txt "start" / "stop" + rec-go; rec-st.txt "1 ms" (a computer
     that records itself); rec-ok.txt "1 name" / "0 why".
   Pion & Claude, 21.11.2026 *)

  IMPORT Fisier, Ceas, OllGL6, Fs2, Gazda4, Desk6, Zane4;

  CONST NL = 300; RH = 64; TOP = 470;

  VAR W, H, x0, y0, scroll, scroll0, n, wait, live, ms, tAsk, tPoll: INTEGER;
    down, moved: BOOLEAN;
    list: ARRAY NL OF INTEGER;
    msg: ARRAY 64 OF CHAR;   (* what CERES says under the button *)

  PROCEDURE Len(s: ARRAY OF CHAR): INTEGER;
    VAR k: INTEGER;
  BEGIN k := 0; WHILE (k < LEN(s)) & (s[k] # 0X) DO INC(k) END
    RETURN k
  END Len;

  PROCEDURE Add(VAR s: ARRAY OF CHAR; t: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN k := Len(s); i := 0; WHILE (i < LEN(t)) & (t[i] # 0X) & (k < LEN(s) - 1) DO s[k] := t[i]; INC(k); INC(i) END; s[k] := 0X
  END Add;

  PROCEDURE AddN(VAR s: ARRAY OF CHAR; v: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k, j: INTEGER;
  BEGIN
    k := 0; IF v < 0 THEN v := 0 END;
    REPEAT d[k] := CHR(ORD("0") + v MOD 10); v := v DIV 10; INC(k) UNTIL v = 0;
    j := Len(s); WHILE (k > 0) & (j < LEN(s) - 1) DO DEC(k); s[j] := d[k]; INC(j) END; s[j] := 0X
  END AddN;

  PROCEDURE Short(VAR s: ARRAY OF CHAR; k: INTEGER);
  BEGIN IF Len(s) > k THEN s[k - 1] := "."; s[k] := 0X END
  END Short;

  PROCEDURE Tell(cmd: ARRAY OF CHAR);
    VAR h, i: INTEGER;
  BEGIN
    h := Fisier.Creeaza("rec.txt");
    IF h >= 0 THEN
      i := 0; WHILE (i < LEN(cmd)) & (cmd[i] # 0X) DO Fisier.Scrie(h, ORD(cmd[i])); INC(i) END;
      Fisier.Scrie(h, 10); Fisier.Gata(h);
      h := Fisier.Creeaza("rec-go"); IF h >= 0 THEN Fisier.Scrie(h, 49); Fisier.Gata(h) END
    END
  END Tell;

  PROCEDURE IsVoice(VAR nm: ARRAY OF CHAR): BOOLEAN;   (* voce-... and a sound *)
  BEGIN RETURN (nm[0] = "v") & (nm[1] = "o") & (nm[2] = "c") & (nm[3] = "e") & (nm[4] = "-") & (Desk6.KindOf(nm) = 18)
  END IsVoice;

  PROCEDURE Build;
    VAR i: INTEGER; nm: ARRAY 40 OF CHAR;
  BEGIN
    n := 0; Fs2.Sync;
    FOR i := Fs2.Count() - 1 TO 0 BY -1 DO Fs2.Name(i, nm); IF IsVoice(nm) & (n < NL) THEN list[n] := i; INC(n) END END
  END Build;

  PROCEDURE Answer;   (* rec-ok.txt: "1 name" or "0 why"; rec-st.txt: "1 ms" while a computer records *)
    VAR h, c, k, ok: INTEGER; nm: ARRAY 40 OF CHAR; why: ARRAY 16 OF CHAR;
  BEGIN
    IF Ceas.Ms() - tPoll > 250 THEN
      tPoll := Ceas.Ms();
      h := Fisier.Deschide("rec-st.txt");
      IF h >= 0 THEN
        c := Fisier.Citeste(h);
        IF c = ORD("1") THEN
          live := 1; ms := 0; c := Fisier.Citeste(h); c := Fisier.Citeste(h);
          WHILE (c >= ORD("0")) & (c <= ORD("9")) DO ms := ms * 10 + c - ORD("0"); c := Fisier.Citeste(h) END
        ELSE live := 0
        END;
        Fisier.Gata(h)
      END;
      h := Fisier.Deschide("rec-ok.txt");
      IF h >= 0 THEN
        ok := Fisier.Citeste(h); c := Fisier.Citeste(h); c := Fisier.Citeste(h); k := 0;
        WHILE (c > 32) & (k < 39) DO nm[k] := CHR(c); INC(k); c := Fisier.Citeste(h) END; nm[k] := 0X;
        Fisier.Gata(h); Fisier.Sterge("rec-ok.txt"); wait := 0; live := 0;
        IF ok = ORD("1") THEN
          k := Fs2.Add(nm); Fs2.Sync; Build; msg := "NEW: "; Add(msg, nm)
        ELSE
          why[0] := 0X; Add(why, nm);
          IF (why[0] = "n") & (why[1] = "o") & (why[2] = "a") THEN msg := "NO RECORDER APP ON THIS PHONE"
          ELSIF why[0] = "n" THEN msg := "NOTHING RECORDED"
          ELSE msg := "THE RECORDING COULD NOT BE COPIED"
          END
        END
      ELSIF (wait = 1) & (live = 0) & (Ceas.Ms() - tAsk > 1500) THEN wait := 2   (* not a computer: the phone's recorder is open *)
      END
    END
  END Answer;

  PROCEDURE Frame*(isDown: BOOLEAN; x, y: INTEGER): INTEGER;   (* -1 HOME *)
    VAR r, i, yy, lim, cx, cy, rad, t: INTEGER; s, nm: ARRAY 64 OF CHAR;
  BEGIN
    r := 0; Answer;
    cx := W DIV 2; cy := 250; rad := 90;
    lim := H - 90 - TOP - n * RH; IF lim > 0 THEN lim := 0 END;
    IF isDown & ~down THEN down := TRUE; moved := FALSE; x0 := x; y0 := y; scroll0 := scroll
    ELSIF isDown THEN
      IF ABS(y - y0) > 14 THEN moved := TRUE END;
      IF moved & (y0 >= TOP) THEN scroll := scroll0 + y - y0 END
    ELSIF down THEN
      down := FALSE;
      IF ~moved THEN
        IF Desk6.IsHome(y0) THEN r := -1
        ELSIF (ABS(x0 - cx) < rad) & (ABS(y0 - cy) < rad) THEN
          IF ~Gazda4.Hosted() THEN Desk6.Say("NO HOST: NO MICROPHONE")
          ELSIF live = 1 THEN Tell("stop"); msg := "SAVING ..."
          ELSIF wait = 0 THEN Fisier.Sterge("rec-ok.txt"); Tell("start"); wait := 1; tAsk := Ceas.Ms(); msg[0] := 0X
          ELSE wait := 0; msg[0] := 0X   (* a second tap gives up waiting *)
          END
        ELSIF y0 >= TOP THEN
          i := (y0 - TOP - scroll) DIV RH;
          IF (i >= 0) & (i < n) THEN Fs2.Name(list[i], nm); Zane4.PhPlay(nm); msg := "PLAYING "; Add(msg, nm) END
        END
      END
    END;
    IF scroll > 0 THEN scroll := 0 ELSIF scroll < lim THEN scroll := lim END;
    OllGL6.Incepe(Desk6.bg);
    FOR i := 0 TO n - 1 DO
      yy := TOP + scroll + i * RH;
      IF (yy > TOP - RH) & (yy < H - 80) THEN
        Fs2.Name(list[i], nm); Desk6.Glyph(18, 24, yy + 6, 46); Short(nm, 30); OllGL6.Text2D(88, yy + 20, nm, 2, Desk6.text)
      END
    END;
    IF n = 0 THEN Desk6.Centre(W DIV 2, TOP + 40, "NO RECORDINGS YET", 2, Desk6.muted) END;
    OllGL6.Dreptunghi2D(0, 0, W, TOP - 6, Desk6.bg);
    (* the button: red; while it records it breathes *)
    t := Ceas.Ms();
    IF live = 1 THEN
      OllGL6.Cerc2D(cx, cy, rad + 8 + (t DIV 40) MOD 12, OllGL6.RGB(120, 20, 40));
      OllGL6.Cerc2D(cx, cy, rad, OllGL6.RGB(230, 50, 70)); OllGL6.Rotund2D(cx - 30, cy - 30, 60, 60, 8, Desk6.text);
      s := "RECORDING  "; AddN(s, ms DIV 60000); Add(s, ":"); IF ms DIV 1000 MOD 60 < 10 THEN Add(s, "0") END; AddN(s, ms DIV 1000 MOD 60);
      Desk6.Centre(cx, cy + rad + 30, s, 2, Desk6.red); Desk6.Centre(cx, cy + rad + 64, "TAP TO STOP", 2, Desk6.muted)
    ELSE
      OllGL6.Cerc2D(cx, cy, rad + 6, Desk6.surface2); OllGL6.Cerc2D(cx, cy, rad, OllGL6.RGB(200, 40, 60));
      OllGL6.Cerc2D(cx, cy, 34, Desk6.text);
      IF wait = 2 THEN
        Desk6.Centre(cx, cy + rad + 30, "THE PHONE'S RECORDER IS OPEN", 2, Desk6.Accent());
        Desk6.Centre(cx, cy + rad + 64, "SAVE THERE: IT COMES HERE", 2, Desk6.muted)
      ELSIF wait = 1 THEN Desk6.Centre(cx, cy + rad + 30, "...", 2, Desk6.muted)
      ELSIF msg[0] # 0X THEN s[0] := 0X; Add(s, msg); Short(s, (W - 40) DIV 12); Desk6.Centre(cx, cy + rad + 30, s, 2, Desk6.Accent())
      ELSE Desk6.Centre(cx, cy + rad + 30, "TAP TO RECORD", 2, Desk6.muted)
      END
    END;
    OllGL6.Dreptunghi2D(16, TOP - 10, W - 32, 1, Desk6.edge);
    s[0] := 0X; AddN(s, n); Add(s, " RECORDINGS . RECORDER"); Desk6.Header("CERES", s);
    Desk6.Bottom; Desk6.Toast(H - 200);
    OllGL6.Arata
    RETURN r
  END Frame;

  PROCEDURE Enter*;
  BEGIN down := TRUE; moved := TRUE; Build
  END Enter;

  PROCEDURE Start*(w, h: INTEGER);
  BEGIN W := w; H := h
  END Start;

BEGIN
  W := 1; H := 1; down := FALSE; moved := FALSE; scroll := 0; n := 0; wait := 0; live := 0; ms := 0; tAsk := 0; tPoll := 0;
  msg[0] := 0X
END Ceres1.
