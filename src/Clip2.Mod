MODULE Clip2;  (* CLIP 2 (11 Nov 2026): Cubicum N keeps its own clipboard too (Pion: "both": copy-paste inside Cubicum N
     and with the phone). Copy goes to both; Paste takes the phone's text, and if the phone gives nothing (or the window is
     the old one), the last text copied in Cubicum N. So copy and paste between the shell and the editor always work.
   CLIP 1 (11 Nov 2026): the phone's clipboard in Cubicum N. Pion: "the shell has no copy paste".
     It needs the window ecran-gl3-sunet3.dex: the window and the program talk through small files in the app's folder.
       copy:  Begin; Put(c) / Str(s) ...; End         -> the text goes onto the phone's clipboard
       paste: Ask; then every frame Ready(); Take(buf)  -> the clipboard's text (only ASCII: the marks of letters go)
     Has() tells if the window knows the clipboard. Pion & Claude, 11.11.2026 *)

  IMPORT Ecran, Ceas, Fisier;

  CONST SEMN = 1129074743;   (* "CLP7" in .in, put there by the window *)

  VAR h, askedAt: INTEGER; asked, inner: BOOLEAN;
    mine: ARRAY 60000 OF CHAR; nm: INTEGER;   (* Cubicum N's own clipboard *)

  PROCEDURE Has*(): BOOLEAN;
  BEGIN RETURN Ecran.Citeste(25) = SEMN
  END Has;

  PROCEDURE Begin*;
  BEGIN nm := 0; mine[0] := 0X; IF Has() THEN h := Fisier.Creeaza("clip-out.txt") ELSE h := -1 END
  END Begin;

  PROCEDURE Put*(c: INTEGER);
  BEGIN
    IF nm < LEN(mine) - 1 THEN mine[nm] := CHR(c MOD 256); INC(nm); mine[nm] := 0X END;
    IF h >= 0 THEN Fisier.Scrie(h, c MOD 256) END
  END Put;

  PROCEDURE Str*(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Put(ORD(s[i])); INC(i) END
  END Str;

  PROCEDURE End*;   (* the text is ready: the window takes it *)
    VAR g: INTEGER;
  BEGIN
    IF h >= 0 THEN Fisier.Gata(h); h := -1; g := Fisier.Creeaza("clip-go"); IF g >= 0 THEN Fisier.Gata(g) END END
  END End;

  PROCEDURE Ask*;   (* ask the window for the clipboard *)
    VAR g: INTEGER;
  BEGIN
    asked := TRUE; askedAt := Ceas.Ms(); inner := ~Has();   (* the old window: only our own clipboard *)
    IF ~inner THEN
      Fisier.Sterge("clip-in.txt");
      g := Fisier.Creeaza("clip-req"); IF g >= 0 THEN Fisier.Gata(g) END
    END
  END Ask;

  PROCEDURE Ready*(): BOOLEAN;   (* the text has come *)
    VAR g: INTEGER; r: BOOLEAN;
  BEGIN
    r := asked & inner;
    IF asked & ~inner THEN
      g := Fisier.Deschide("clip-in.txt"); IF g >= 0 THEN Fisier.Gata(g); r := TRUE END;
      IF ~r & (Ceas.Ms() - askedAt > 1500) THEN inner := TRUE; r := TRUE; Fisier.Sterge("clip-req") END   (* no answer: ours *)
    END
    RETURN r
  END Ready;

  PROCEDURE Late*(): BOOLEAN;   (* kept for the callers: Ready falls back to our own clipboard, so never late *)
  BEGIN RETURN FALSE
  END Late;

  PROCEDURE Take*(VAR buf: ARRAY OF CHAR): INTEGER;   (* the text into buf (ends with 0X); how many letters *)
    VAR g, b, n: INTEGER;
  BEGIN
    n := 0;
    IF ~inner THEN
      g := Fisier.Deschide("clip-in.txt");
      IF g >= 0 THEN
        b := Fisier.Citeste(g);
        WHILE (b >= 0) & (n < LEN(buf) - 1) DO buf[n] := CHR(b); INC(n); b := Fisier.Citeste(g) END;
        Fisier.Gata(g); Fisier.Sterge("clip-in.txt")
      END
    END;
    IF n = 0 THEN   (* the phone gave nothing: what was copied here *)
      WHILE (n < nm) & (n < LEN(buf) - 1) DO buf[n] := mine[n]; INC(n) END
    END;
    buf[n] := 0X; asked := FALSE; inner := FALSE
    RETURN n
  END Take;

BEGIN
  h := -1; asked := FALSE; inner := FALSE; askedAt := 0; nm := 0; mine[0] := 0X
END Clip2.
