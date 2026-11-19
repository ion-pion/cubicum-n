MODULE Synth9;  (* SYNTH Z7 9 (11 Nov 2026): NoteHz(f, ms) plays any frequency (for the Tor7 processor: NOTE and PLAYC).
   SYNTH Z7 8 (11 Nov 2026): Pion: "I want everything in English". All screen text is now English.
     New for the Cubicum N shell:
       Rescan; Slot(n) notes in slot n (-1 = empty); SlotMs(n); PlaySlot(n); Stop; SetLoop(b); Looping();
       SetInOrder(b); InOrder(); Note(x, y, z, ms) plays one node of the cube; Freq(x, y, z); Rate(); Latency()
   SYNTH Z7 7 (11 nov 2026): synthul plus PLAYERUL pentru Cubicum N (bucata 2).
       Synth7.IntraPlayer                 cand intri in player (citeste cele 7 locuri)
       Synth7.Player(apasat, x, y)        cadrul playerului; TRUE = X (inapoi in cub)
       Synth7.Locul()                     ce loc canta acum playerul (0 = niciunul)
     Atingi un loc: il incarca (si sunetul lui) si il canta. LOOP il repeta; PE RAND trece la urmatorul loc plin.
     Muzica merge mai departe si in cub.
   SYNTH Z7 6 (10 nov 2026), Pion: "cand deschid fereastra asta (SUNET) face un zgomot continuu".
     Cauza: pe telefon ecranul e mai scund decat credeam, iar ultimele randuri de la SUNET (GOLURI si textul de sub el)
     se desenau peste randurile in care sta sunetul. De acolo venea si paraitul de la reglaje din Synth 2, 3 si 4.
     Acum fila SUNET isi potriveste randurile dupa inaltimea ecranului si nimic nu se mai deseneaza sub H.
   SYNTH Z7 5 (10 nov 2026): acelasi synth, dar ca MODUL pentru Cubicum N (Pion: "facem un nou cubicum
     ca aplicatie separata ... pe bucatele"). Nu mai are bucla lui: Cubicum cheama
       Synth6.Porneste                      o data, dupa ce exista fereastra
       Synth6.Sunet                         in fiecare cadru, oriunde ai fi (secventa si redarea canta si din cub)
       Synth6.Cadru(apasat, x, y)           cand synthul are ecranul; TRUE = omul a apasat X (inapoi in cub)
       Synth6.Canta()                       TRUE cat merge secventa sau redarea
   SYNTH Z7 4 (10 nov 2026), Pion: "vreau html-ul sa il trec in oberon ... stand alone ... sa il compilez
     cu byz7 ... hai sa-l facem cu sunet de orga". E cubicum_keyboard_recorder.html (Cubicum Synth) scris in Oberon (OLL):
     tot sunetul il socoteste programul, esantion cu esantion, iar fereastra doar il canta. Nota tine cat tii degetul.
     Trebuie fereastra cu sunet curgator, ecran-sunet2.dex (cu alta programul merge, dar tace si iti spune).
     Synth 2 fata de 1 (Pion: "paraie rau si sunetul are delay cam juma de secunda"): merge la rata placii de sunet
     (de obicei 48000) si dupa ceasul ei, cu un avans mic pe care il alegi la SUNET (AVANS, in ms): il scazi pana
     incep golurile (numarul de langa el creste = paraie), apoi il urci putin.
       CLAPE: grila Z7 (X = 0..6, Y = 2..0) pentru stratul Z ales, pianul C3..C5, unda pe ecran.
       SUNET: 7 oscilatori (pornit, forma undei, dezacord in centi, volum), filtrul (LP / HP / BP, taie, rezonanta),
              atacul si stingerea (FIB7: 8 13 21 34 55 89 144 ms), LFO (vibrato pe OSC1), ecoul (Pisano 7), volumul.
       SECV:  64 de pasi, PLAY / RAND / FIB / RST, BPM, pasul ales: X Y Z si MUT.
       REC:   inregistrezi ce canti (si secventa), asculti, LOOP, stergi.
     Frecventa unui nod, ca in HTML: 20 Hz * 1000^((x + 7y + 49z) / 342) * (1 + 0,05 (x + y + z)).
     Fata de HTML: fiecare oscilator intra in filtru cu volumul lui; preseturile si salvarea in fisier nu sunt inca.
     Synth 3 fata de 2 (Pion: "mai paraie doar cand trec pe fereastra sunet"): ce schimbi la SUNET nu mai sare dintr-o
     data, ci aluneca in cateva miimi de secunda (volumele, filtrul, ecoul, oscilatorii porniti si opriti).
     Synth 4 fata de 3 (Pion: "inregistrarea e doar de decor ... as vrea sa si salveze"): la REC, SALVEAZA si INCARCA,
     7 locuri. Fisierul e text, in Download (SynthZ7-1.txt .. SynthZ7-7.txt): sunetul (randurile S si O) si notele
     (N inceput x y z durata, in miimi de secunda). Il poate canta mai tarziu un player sau un joc, cu acelasi synth.
     Daca aplicatia n-are voie in Download, il pune in dosarul ei si iti spune.
       ollapk Synth4.Mod "Synth Z7 4"     (cu fereastra ecran-gl3-sunet2.dex sau ecran-sunet2.dex in unelte)
     Pion & Claude, 10.11.2026 *)

  IMPORT Ecran, Ceas, Math, Fisier, Grafica;

  CONST
    RANDURI = 20; SEMN = 1398099506;                 (* "SUN2": semnul ferestrei cu sunet *)
    NV = 8; NO = 7; LE = 32768;                      (* voci, oscilatori, lungimea ecoului *)
    MaxEv = 4000;
    idDeget = 1; idSecv = 3; idShell = 5; idTor = 6; idRedare = 1000;
    tClape = 0; tSunet = 1; tSecv = 2; tRec = 3;

  VAR
    W, H, fw, y0, inel, scris: INTEGER; cuSunet: BOOLEAN;
    SR, avansMs: INTEGER; srR: REAL;                 (* rata placii de sunet; cu cate ms merg inaintea ei *)
    (* felul sunetului *)
    oOn: ARRAY NO OF BOOLEAN; oUnda, oDez, oVol: ARRAY NO OF INTEGER;
    fTip, cutI, res, atkI, relI, lfo, dlyPas, fbk, mix, vol: INTEGER;
    fib7, pisano, cutHz: ARRAY 16 OF INTEGER;
    (* vocile *)
    vStare, vId, vX, vY, vZ: ARRAY NV OF INTEGER;    (* 0 = libera, 1 = suna, 2 = se stinge *)
    vF, vEnv, vPas, vZ1, vZ2: ARRAY NV OF REAL;
    vFaza: ARRAY NV, NO OF REAL;
    oPas: ARRAY NO OF REAL;                          (* 2^(dezacord / 1200) *)
    b0, b1, b2, a1, a2, castig, atkPas, lfoFaza: REAL;          (* tintele: unde vrea sa ajunga sunetul *)
    nb0, nb1, nb2, na1, na2, nCastig, nVol, nFb, nUd, nUscat, nLung, tLung: REAL;   (* unde e acum: aluneca spre tinte *)
    oG: ARRAY NO OF REAL;                            (* volumul de acum al fiecarui oscilator (0 = oprit) *)
    k5, k20, k50: REAL;                              (* cat de repede aluneca: in 5, 20, 50 ms *)
    eco: ARRAY LE OF REAL; ecoW: INTEGER; ecoFb, ecoUd, ecoUscat: REAL;
    unda: ARRAY 512 OF INTEGER; undaW: INTEGER;
    (* nota aratata *)
    nx, ny, nz: INTEGER; nf: REAL; nSuna: BOOLEAN;
    (* pianul *)
    pX, pY, pZ: ARRAY 25 OF INTEGER;
    (* secventa *)
    sX, sY, sZ: ARRAY 64 OF INTEGER; sMut: ARRAY 64 OF BOOLEAN;
    secvMerge: BOOLEAN; secvPoz, secvAcum, secvAles, bpm, secvUrm: INTEGER;
    (* inregistrarea: timpul in esantioane *)
    evT, evX, evY, evZ, evId: ARRAY MaxEv OF INTEGER; evOn: ARRAY MaxEv OF BOOLEAN;
    nEv, recStare, recStart, recDur, pbStart, pbI: INTEGER; bucla: BOOLEAN;   (* recStare: 0 nimic, 1 inregistrez, 2 redau *)
    (* ecranul si degetul *)
    tab, zStrat, tastaJos, prins, samanta: INTEGER;
    ap, apInainte, lovit, murdar: BOOLEAN; mx, my: INTEGER;
    fond, panou, aur, alb, gri, violet, cyan, rosu, verde, negru: INTEGER;
    t: ARRAY 64 OF CHAR; tn: INTEGER;
    iesire, pornit: BOOLEAN; rh: INTEGER;            (* inaltimea unui rand cu cursor *)
                                    (* X: inapoi in cub *)
    urm: BOOLEAN; shOff, torOff: INTEGER;                   (* when the shell's note ends (in samples; 0 = none) *)
                                      (* Sunet a cerut locul urmator (il porneste Urmatorul) *)
    loc, mesaj: INTEGER;                             (* locul de salvare ales (1..7); ce s-a intamplat la ultima salvare / incarcare *)
    nr: ARRAY 12 OF INTEGER;                         (* numerele de pe un rand citit *)
    (* playerul *)
    plLoc: INTEGER; plRand, plUrm: BOOLEAN;           (* locul care canta; pe rand; trebuie pornit urmatorul *)
    plNote, plMs: ARRAY 8 OF INTEGER;                 (* pentru fiecare loc: cate note (-1 = gol), cate ms *)

  (* ---------- text ---------- *)

  PROCEDURE Gol;
  BEGIN tn := 0; t[0] := 0X
  END Gol;

  PROCEDURE Ad(s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (tn < 62) DO t[tn] := s[i]; INC(tn); INC(i) END;
    t[tn] := 0X
  END Ad;

  PROCEDURE AdN(n: INTEGER);
    VAR d: ARRAY 12 OF CHAR; k: INTEGER;
  BEGIN
    IF n < 0 THEN Ad("-"); n := -n END;
    k := 0;
    REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
    WHILE (k > 0) & (tn < 62) DO DEC(k); t[tn] := d[k]; INC(tn) END;
    t[tn] := 0X
  END AdN;

  PROCEDURE AdHz(f: REAL);   (* 440.0 HZ sau 4.40 KHZ *)
    VAR n: INTEGER;
  BEGIN
    IF f < 1000.0 THEN n := FLOOR(f * 10.0 + 0.5); AdN(n DIV 10); Ad("."); AdN(n MOD 10); Ad(" HZ")
    ELSE n := FLOOR(f / 10.0 + 0.5); AdN(n DIV 100); Ad("."); AdN(n MOD 100 DIV 10); AdN(n MOD 10); Ad(" KHZ")
    END
  END AdHz;

  PROCEDURE AdNota(f: REAL);   (* numele notei celei mai apropiate: A4, C+3 (+ = diez) *)
    VAR m, s: INTEGER;
  BEGIN
    m := FLOOR(69.0 + 12.0 * Math.ln(f / 440.0) / Math.ln(2.0) + 0.5);
    IF m < 0 THEN m := 0 END;
    s := m MOD 12;
    IF s = 0 THEN Ad("C") ELSIF s = 1 THEN Ad("C+") ELSIF s = 2 THEN Ad("D") ELSIF s = 3 THEN Ad("D+")
    ELSIF s = 4 THEN Ad("E") ELSIF s = 5 THEN Ad("F") ELSIF s = 6 THEN Ad("F+") ELSIF s = 7 THEN Ad("G")
    ELSIF s = 8 THEN Ad("G+") ELSIF s = 9 THEN Ad("A") ELSIF s = 10 THEN Ad("A+") ELSE Ad("B")
    END;
    AdN(m DIV 12 - 1)
  END AdNota;

  PROCEDURE Scrie(x, y, m, c: INTEGER);   (* textul strans in t, de la x *)
  BEGIN Grafica.Text(x, y, t, m, c)
  END Scrie;

  PROCEDURE ScrieC(cx, y, m, c: INTEGER);   (* la mijloc pe cx *)
  BEGIN Grafica.Text(cx - tn * 3 * m, y, t, m, c)
  END ScrieC;

  (* ---------- sunetul ---------- *)

  PROCEDURE Hz(x, y, z: INTEGER): REAL;
  BEGIN RETURN 20.0 * Math.exp(FLT(x + 7 * y + 49 * z) / 342.0 * Math.ln(1000.0)) * (1.0 + 0.05 * FLT(x + y + z))
  END Hz;

  PROCEDURE HzBaza(x, y, z: INTEGER): REAL;
  BEGIN RETURN 20.0 * Math.exp(FLT(x + 7 * y + 49 * z) / 342.0 * Math.ln(1000.0))
  END HzBaza;

  PROCEDURE Potriveste;   (* dupa orice schimbare de la SUNET: filtrul, castigul, atacul, ecoul, dezacordurile *)
    VAR i, n, pv: INTEGER; w0, al, c, s, a0, q, dt: REAL;
  BEGIN
    n := 0;
    FOR i := 0 TO NO - 1 DO
      IF oOn[i] THEN INC(n) END;
      oPas[i] := Math.exp(FLT(oDez[i]) / 1200.0 * Math.ln(2.0))
    END;
    IF n = 0 THEN n := 1 END;
    castig := 0.7 / Math.sqrt(FLT(n));
    q := FLT(cutHz[cutI]); IF q > 0.45 * srR THEN q := 0.45 * srR END;
    w0 := 6.283185307179586 * q / srR; c := Math.cos(w0); s := Math.sin(w0);
    IF fTip = 2 THEN al := s / (2.0 * FLT(res))                                   (* BP: Q ca atare *)
    ELSE al := s / (2.0 * Math.exp(FLT(res) / 20.0 * Math.ln(10.0)))             (* LP, HP: Q in dB, ca in browser *)
    END;
    a0 := 1.0 + al;
    IF fTip = 0 THEN b0 := (1.0 - c) / 2.0 / a0; b1 := (1.0 - c) / a0; b2 := b0
    ELSIF fTip = 1 THEN b0 := (1.0 + c) / 2.0 / a0; b1 := -(1.0 + c) / a0; b2 := b0
    ELSE b0 := al / a0; b1 := 0.0; b2 := -al / a0
    END;
    a1 := -2.0 * c / a0; a2 := (1.0 - al) / a0;
    dt := FLT(fib7[atkI]) / 1000.0; IF dt > 0.02 THEN dt := 0.02 END;
    atkPas := 1.0 / (dt * srR);
    pv := pisano[dlyPas];
    IF pv = 0 THEN dt := 0.25 ELSE dt := FLT(pv) * 0.5 / 6.0 END;
    tLung := dt * srR; IF tLung > FLT(LE - 4) THEN tLung := FLT(LE - 4) END;
    IF tLung < 2.0 THEN tLung := 2.0 END;
    ecoFb := FLT(fbk) / 100.0; ecoUd := FLT(mix) / 100.0 * 0.8; ecoUscat := 1.0 - FLT(mix) / 100.0 * 0.6
  END Potriveste;

  PROCEDURE Tine(on: BOOLEAN; x, y, z, id: INTEGER);   (* in inregistrare, daca inregistrez *)
  BEGIN
    IF (recStare = 1) & (nEv < MaxEv) THEN
      evT[nEv] := scris - recStart; evOn[nEv] := on; evX[nEv] := x; evY[nEv] := y; evZ[nEv] := z; evId[nEv] := id; INC(nEv)
    END
  END Tine;

  PROCEDURE Stinge(id: INTEGER; repede: BOOLEAN);   (* vocea cu numele id se stinge; nu mai are nume *)
    VAR v: INTEGER; dt: REAL;
  BEGIN
    FOR v := 0 TO NV - 1 DO
      IF (vStare[v] # 0) & (vId[v] = id) THEN
        IF repede THEN dt := 0.004
        ELSE dt := FLT(fib7[relI]) / 1000.0; IF dt > 0.3 THEN dt := 0.3 END
        END;
        vStare[v] := 2; vId[v] := 0; vPas[v] := vEnv[v] / (dt * srR);
        IF vPas[v] < 0.000001 THEN vPas[v] := 0.000001 END
      END
    END
  END Stinge;

  PROCEDURE NotaOn(x, y, z, id: INTEGER);
    VAR v, k, i: INTEGER;
  BEGIN
    Stinge(id, TRUE);
    k := -1;
    FOR v := 0 TO NV - 1 DO IF (k < 0) & (vStare[v] = 0) THEN k := v END END;
    IF k < 0 THEN   (* toate ocupate: o iau pe cea mai stinsa dintre cele care se sting, altfel pe prima *)
      FOR v := 0 TO NV - 1 DO
        IF (vStare[v] = 2) & ((k < 0) OR (vEnv[v] < vEnv[k])) THEN k := v END
      END;
      IF k < 0 THEN k := 0 END
    END;
    vStare[k] := 1; vId[k] := id; vX[k] := x; vY[k] := y; vZ[k] := z; vF[k] := Hz(x, y, z);
    vEnv[k] := 0.0; vZ1[k] := 0.0; vZ2[k] := 0.0;
    FOR i := 0 TO NO - 1 DO vFaza[k, i] := 0.0 END;
    nx := x; ny := y; nz := z; nf := vF[k]; nSuna := TRUE; murdar := TRUE
  END NotaOn;

  PROCEDURE NotaOff(id: INTEGER);
  BEGIN Stinge(id, FALSE); murdar := TRUE
  END NotaOff;

  PROCEDURE Taci;   (* toate vocile se sting repede *)
    VAR v: INTEGER;
  BEGIN
    FOR v := 0 TO NV - 1 DO
      IF vStare[v] # 0 THEN vStare[v] := 2; vId[v] := 0; vPas[v] := vEnv[v] / (0.004 * srR) + 0.000001 END
    END
  END Taci;

  PROCEDURE Blep(p, dp: REAL): REAL;   (* netezeste saltul undei (polyBLEP), ca sa nu zbarnaie sus *)
    VAR r, u: REAL;
  BEGIN
    r := 0.0;
    IF p < dp THEN u := p / dp; r := u + u - u * u - 1.0
    ELSIF p > 1.0 - dp THEN u := (p - 1.0) / dp; r := u * u + u + u + 1.0
    END;
    RETURN r
  END Blep;

  PROCEDURE SecvPas;   (* pasul urmator al secventei (cei muti sunt sariti) *)
    VAR incerc: INTEGER;
  BEGIN
    incerc := 0;
    WHILE sMut[secvPoz] & (incerc < 64) DO secvPoz := (secvPoz + 1) MOD 64; INC(incerc) END;
    Tine(FALSE, 0, 0, 0, idSecv);
    IF incerc < 64 THEN
      NotaOn(sX[secvPoz], sY[secvPoz], sZ[secvPoz], idSecv);
      Tine(TRUE, sX[secvPoz], sY[secvPoz], sZ[secvPoz], idSecv)
    END;
    secvAcum := secvPoz; secvPoz := (secvPoz + 1) MOD 64; murdar := TRUE
  END SecvPas;

  PROCEDURE RedarePas;   (* evenimentele inregistrarii ajunse la timp *)
  BEGIN
    WHILE (pbI < nEv) & (evT[pbI] <= scris - pbStart) DO
      IF evOn[pbI] THEN NotaOn(evX[pbI], evY[pbI], evZ[pbI], evId[pbI] + idRedare)
      ELSE NotaOff(evId[pbI] + idRedare)
      END;
      INC(pbI)
    END;
    IF scris - pbStart > recDur + SR DIV 10 THEN
      IF bucla THEN pbStart := scris; pbI := 0
      ELSE recStare := 0; Taci; plUrm := plRand & (plLoc > 0)
      END;
      murdar := TRUE
    END
  END RedarePas;

  PROCEDURE Esantion(): INTEGER;   (* un esantion din tot synthul, -32000 .. 32000 *)
    VAR v, i, e: INTEGER; s, sv, p, dp, f, y, x, d, lf: REAL;
  BEGIN
    IF secvMerge & (scris >= secvUrm) THEN SecvPas; secvUrm := secvUrm + SR * 60 DIV bpm END;
    IF recStare = 2 THEN RedarePas END;
    IF (shOff > 0) & (scris >= shOff) THEN shOff := 0; NotaOff(idShell) END;
    IF (torOff > 0) & (scris >= torOff) THEN torOff := 0; NotaOff(idTor) END;
    lf := 0.0;
    IF lfo > 0 THEN
      lfoFaza := lfoFaza + FLT(lfo) / srR; IF lfoFaza >= 1.0 THEN lfoFaza := lfoFaza - 1.0 END;
      lf := 0.02 * Math.sin(6.283185307179586 * lfoFaza)
    END;
    nb0 := nb0 + (b0 - nb0) * k5; nb1 := nb1 + (b1 - nb1) * k5; nb2 := nb2 + (b2 - nb2) * k5;
    na1 := na1 + (a1 - na1) * k5; na2 := na2 + (a2 - na2) * k5;
    nCastig := nCastig + (castig - nCastig) * k20; nVol := nVol + (FLT(vol) / 100.0 - nVol) * k20;
    nFb := nFb + (ecoFb - nFb) * k20; nUd := nUd + (ecoUd - nUd) * k20; nUscat := nUscat + (ecoUscat - nUscat) * k20;
    nLung := nLung + (tLung - nLung) * k50;
    FOR i := 0 TO NO - 1 DO
      IF oOn[i] THEN x := FLT(oVol[i]) / 100.0 ELSE x := 0.0 END;
      oG[i] := oG[i] + (x - oG[i]) * k20
    END;
    s := 0.0;
    FOR v := 0 TO NV - 1 DO
      IF vStare[v] # 0 THEN
        sv := 0.0;
        FOR i := 0 TO NO - 1 DO
          f := vF[v] * oPas[i]; IF i = 0 THEN f := f * (1.0 + lf) END;
          dp := f / srR;
          IF (oOn[i] OR (oG[i] > 0.0005)) & (dp < 0.5) THEN   (* peste jumatate din 44100 nu se mai poate canta: tace, ca in browser *)
            p := vFaza[v, i];
            IF oUnda[i] = 0 THEN x := Math.sin(6.283185307179586 * p)
            ELSIF oUnda[i] = 1 THEN x := 2.0 * p - 1.0 - Blep(p, dp)
            ELSIF oUnda[i] = 2 THEN
              IF p < 0.5 THEN x := 1.0 ELSE x := -1.0 END;
              x := x + Blep(p, dp);
              d := p + 0.5; IF d >= 1.0 THEN d := d - 1.0 END;
              x := x - Blep(d, dp)
            ELSE x := 4.0 * ABS(p - 0.5) - 1.0
            END;
            sv := sv + x * oG[i];
            p := p + dp; IF p >= 1.0 THEN p := p - 1.0 END;
            vFaza[v, i] := p
          END
        END;
        y := nb0 * sv + vZ1[v];
        vZ1[v] := nb1 * sv - na1 * y + vZ2[v];
        vZ2[v] := nb2 * sv - na2 * y;
        IF vStare[v] = 1 THEN
          IF vEnv[v] < 1.0 THEN vEnv[v] := vEnv[v] + atkPas; IF vEnv[v] > 1.0 THEN vEnv[v] := 1.0 END END
        ELSE
          vEnv[v] := vEnv[v] - vPas[v];
          IF vEnv[v] <= 0.0 THEN vEnv[v] := 0.0; vStare[v] := 0 END
        END;
        s := s + y * vEnv[v] * nCastig
      END
    END;
    s := s * nVol;
    p := FLT(ecoW) - nLung; IF p < 0.0 THEN p := p + FLT(LE) END;   (* ecoul: citesc intre doua esantioane, ca lungimea sa poata aluneca *)
    i := FLOOR(p); f := p - FLT(i); IF i >= LE THEN i := i - LE END;
    e := i + 1; IF e >= LE THEN e := 0 END;
    d := eco[i] * (1.0 - f) + eco[e] * f;
    eco[ecoW] := s + d * nFb; ecoW := ecoW + 1; IF ecoW >= LE THEN ecoW := 0 END;
    s := s * nUscat + d * nUd;
    IF s > 1.0 THEN s := 1.0 ELSIF s < -1.0 THEN s := -1.0 END;
    e := FLOOR(s * 32000.0);
    unda[undaW] := e; undaW := (undaW + 1) MOD 512
    RETURN e
  END Esantion;

  PROCEDURE Sunet*;   (* umplu inelul pana la avansMs inaintea a ce a cantat placa de sunet *)
    VAR cantat, luat, n, k, p: INTEGER;
  BEGIN
    IF pornit & ~cuSunet THEN cuSunet := Ecran.Citeste(20) = SEMN END;
    IF pornit & cuSunet THEN
      cantat := Ecran.Citeste(22); luat := Ecran.Citeste(21);
      n := cantat + avansMs * SR DIV 1000 - scris;
      IF n > inel - (scris - luat) - 8 THEN n := inel - (scris - luat) - 8 END;
      IF n > 8192 THEN n := 8192 END;
      FOR k := 1 TO n DO
        p := scris MOD inel;
        Ecran.Pune(p MOD fw, y0 + p DIV fw, Esantion());
        INC(scris)
      END;
      Ecran.Pune(inel MOD fw, y0 + inel DIV fw, SEMN);
      Ecran.Pune((inel + 1) MOD fw, y0 + (inel + 1) DIV fw, scris)
    END;
    IF plUrm THEN plUrm := FALSE; urm := TRUE END
  END Sunet;

  (* ---------- butoane si cursoare ---------- *)

  PROCEDURE In(x, y, w, h: INTEGER): BOOLEAN;
  BEGIN RETURN (mx >= x) & (mx < x + w) & (my >= y) & (my < y + h)
  END In;

  PROCEDURE ButonT(x, y, w, h: INTEGER; aprins: BOOLEAN; c: INTEGER): BOOLEAN;   (* cu textul strans in t *)
  BEGIN
    IF aprins THEN Grafica.Dreptunghi(x + 2, y + 2, w - 4, h - 4, c) ELSE Grafica.Dreptunghi(x + 2, y + 2, w - 4, h - 4, panou) END;
    IF aprins THEN ScrieC(x + w DIV 2, y + h DIV 2 - 7, 2, negru) ELSE ScrieC(x + w DIV 2, y + h DIV 2 - 7, 2, c) END
    RETURN lovit & In(x, y, w, h)
  END ButonT;

  PROCEDURE Buton(x, y, w, h: INTEGER; s: ARRAY OF CHAR; aprins: BOOLEAN; c: INTEGER): BOOLEAN;
  BEGIN Gol; Ad(s)
    RETURN ButonT(x, y, w, h, aprins, c)
  END Buton;

  PROCEDURE Cursor(id, x, y, w, h: INTEGER; VAR v: INTEGER; min, max, pas, c: INTEGER);   (* tragi cu degetul *)
    VAR n, px: INTEGER;
  BEGIN
    IF lovit & In(x, y, w, h) THEN prins := id END;
    IF ap & (prins = id) THEN
      n := min + ((mx - x - 8) * (max - min) + (w - 16) DIV 2) DIV (w - 16);
      n := (n + pas DIV 2) DIV pas * pas;
      IF n < min THEN n := min ELSIF n > max THEN n := max END;
      IF n # v THEN v := n; Potriveste END
    END;
    Grafica.Dreptunghi(x, y + h DIV 2 - 3, w, 6, panou);
    px := x + 8 + (v - min) * (w - 16) DIV (max - min);
    Grafica.Dreptunghi(x, y + h DIV 2 - 3, px - x, 6, c);
    Grafica.Dreptunghi(px - 7, y + 4, 14, h - 8, c)
  END Cursor;

  PROCEDURE Rand(id, y: INTEGER; nume: ARRAY OF CHAR; VAR v: INTEGER; min, max, pas, c: INTEGER);   (* nume, cursor, valoare *)
  BEGIN
    Gol; Ad(nume); Scrie(10, y + rh DIV 2 - 7, 2, c);
    Cursor(id, 100, y, 320, rh, v, min, max, pas, c)
  END Rand;

  PROCEDURE Val(y, c: INTEGER);   (* valoarea din t, in dreapta randului *)
  BEGIN Scrie(432, y + rh DIV 2 - 7, 2, c)
  END Val;

  (* ---------- CLAPE ---------- *)

  PROCEDURE Negru(s: INTEGER): BOOLEAN;
  BEGIN RETURN (s = 1) OR (s = 3) OR (s = 6) OR (s = 8) OR (s = 10)
  END Negru;

  PROCEDURE TastaLa(yg, yp: INTEGER): INTEGER;   (* ce clapa e sub deget: 0..20 grila (x + 7 * (2 - rand)), 100 + midi pianul, -1 nimic *)
    VAR r, k, m, a, x, lw: INTEGER;
  BEGIN
    r := -1; lw := W DIV 15;
    IF (my >= yg) & (my < yg + 3 * 78) THEN
      k := mx * 7 DIV W; IF k > 6 THEN k := 6 END;
      r := k + 7 * ((my - yg) DIV 78)
    ELSIF (my >= yp) & (my < yp + 230) THEN
      IF my < yp + 140 THEN   (* intai clapele negre *)
        a := 0;
        FOR m := 48 TO 72 DO
          IF Negru(m MOD 12) THEN
            x := a * lw - lw * 3 DIV 10;
            IF (mx >= x) & (mx < x + lw * 6 DIV 10) THEN r := 100 + m END
          ELSE INC(a)
          END
        END
      END;
      IF r < 0 THEN
        k := mx DIV lw; IF k > 14 THEN k := 14 END;
        a := 0;
        FOR m := 48 TO 72 DO
          IF ~Negru(m MOD 12) THEN
            IF a = k THEN r := 100 + m END;
            INC(a)
          END
        END
      END
    END
    RETURN r
  END TastaLa;

  PROCEDURE Clape;
    VAR i, x, y, z, k, a, m, lw, yg, yp, c, v, ya, yb: INTEGER; f: REAL; b: BOOLEAN;
  BEGIN
    (* nota care suna *)
    IF nSuna THEN
      Gol; AdNota(nf); Scrie(12, 126, 4, aur);
      Gol; Ad("("); AdN(nx); Ad(","); AdN(ny); Ad(","); AdN(nz); Ad(")  "); AdHz(nf); Scrie(130, 134, 2, alb)
    ELSE Gol; Ad("TOUCH A KEY"); Scrie(12, 134, 2, gri)
    END;
    (* unda *)
    Grafica.Dreptunghi(8, 166, W - 16, 90, panou);
    ya := 211;
    FOR i := 0 TO 255 DO
      v := unda[(undaW + 256 + i) MOD 512];
      yb := 211 - v * 42 DIV 32000;
      Grafica.Linie(10 + i * (W - 20) DIV 256, ya, 10 + (i + 1) * (W - 20) DIV 256, yb, cyan);
      ya := yb
    END;
    (* straturile Z *)
    FOR z := 0 TO 6 DO
      Gol; Ad("Z"); AdN(z);
      IF ButonT(z * W DIV 7, 264, W DIV 7, 46, z = zStrat, aur) THEN zStrat := z END
    END;
    (* grila *)
    yg := 318; yp := 566; lw := W DIV 15;
    FOR y := 2 TO 0 BY -1 DO
      FOR x := 0 TO 6 DO
        f := Hz(x, y, zStrat); k := x + 7 * (2 - y);
        IF tastaJos = k THEN c := alb ELSE c := Grafica.RGB(50 + x * 28, 40 + y * 30, 70 + zStrat * 28) END;
        Grafica.Dreptunghi(x * W DIV 7 + 2, yg + (2 - y) * 78 + 2, W DIV 7 - 4, 74, c);
        Gol; AdNota(f); ScrieC(x * W DIV 7 + W DIV 14, yg + (2 - y) * 78 + 16, 2, negru);
        Gol; AdN(FLOOR(f + 0.5)); ScrieC(x * W DIV 7 + W DIV 14, yg + (2 - y) * 78 + 46, 2, negru)
      END
    END;
    (* pianul: intai albele, apoi negrele *)
    a := 0;
    FOR m := 48 TO 72 DO
      IF ~Negru(m MOD 12) THEN
        IF tastaJos = 100 + m THEN c := aur ELSE c := alb END;
        Grafica.Dreptunghi(a * lw + 1, yp, lw - 2, 230, c);
        IF m MOD 12 = 0 THEN Gol; Ad("C"); AdN(m DIV 12 - 1); ScrieC(a * lw + lw DIV 2, yp + 206, 2, negru) END;
        INC(a)
      END
    END;
    a := 0;
    FOR m := 48 TO 72 DO
      IF Negru(m MOD 12) THEN
        IF tastaJos = 100 + m THEN c := aur ELSE c := negru END;
        Grafica.Dreptunghi(a * lw - lw * 3 DIV 10, yp, lw * 6 DIV 10, 140, c)
      ELSE INC(a)
      END
    END;
    (* degetul: tii = suna, aluneci = trece pe clapa de sub deget, ridici = se stinge *)
    k := -1; IF ap THEN k := TastaLa(yg, yp) END;
    IF ap & (lovit OR (tastaJos >= 0)) & (k >= 0) THEN
      IF k # tastaJos THEN
        IF k < 100 THEN x := k MOD 7; y := 2 - k DIV 7; z := zStrat
        ELSE x := pX[k - 148]; y := pY[k - 148]; z := pZ[k - 148]
        END;
        NotaOn(x, y, z, idDeget); Tine(FALSE, 0, 0, 0, idDeget); Tine(TRUE, x, y, z, idDeget);
        tastaJos := k
      END
    ELSIF tastaJos >= 0 THEN
      b := ap & (k < 0);   (* a alunecat in afara clapelor *)
      IF ~ap OR b THEN NotaOff(idDeget); Tine(FALSE, 0, 0, 0, idDeget); tastaJos := -1 END
    END;
    Rand(90, 820, "VOLUME", vol, 0, 100, 1, verde); Gol; AdN(vol); Val(820, verde);
    IF Buton(8, 880, 200, 50, "SILENCE", FALSE, rosu) THEN Taci; secvMerge := FALSE; IF recStare = 2 THEN recStare := 0 END END
  END Clape;

  (* ---------- SUNET ---------- *)

  PROCEDURE NumeUnda(k: INTEGER);
  BEGIN
    IF k = 0 THEN Ad("SIN") ELSIF k = 1 THEN Ad("SAW") ELSIF k = 2 THEN Ad("SQ") ELSE Ad("TRI") END
  END NumeUnda;

  PROCEDURE Sunete;   (* 19 randuri, potrivite dupa inaltimea ecranului: nimic nu trece de H (dedesubt e sunetul) *)
    VAR i, y, pv, p: INTEGER;
  BEGIN
    p := (H - 146) DIV 19; IF p > 50 THEN p := 50 END; IF p < 24 THEN p := 24 END;
    rh := p - 4;
    Gol; Ad("OSC   WAVE   DETUNE         VOLUME"); Scrie(10, 122, 2, gri);
    FOR i := 0 TO NO - 1 DO
      y := 142 + i * p;
      Gol; AdN(i + 1);
      IF ButonT(4, y, 56, rh, oOn[i], aur) & (i > 0) THEN oOn[i] := ~oOn[i]; Potriveste END;
      Gol; NumeUnda(oUnda[i]);
      IF ButonT(62, y, 76, rh, FALSE, cyan) THEN oUnda[i] := (oUnda[i] + 1) MOD 4 END;
      Cursor(10 + i, 144, y, 170, rh, oDez[i], -50, 50, 1, violet);
      Gol; AdN(oDez[i]); Scrie(318, y + rh DIV 2 - 7, 2, violet);
      Cursor(20 + i, 368, y, 120, rh, oVol[i], 0, 100, 1, verde);
      Gol; AdN(oVol[i]); Scrie(492, y + rh DIV 2 - 7, 2, verde)
    END;
    y := 142 + 7 * p;
    Gol; Ad("FILTER"); Scrie(10, y + rh DIV 2 - 7, 2, cyan);
    IF Buton(110, y, 100, rh, "LP", fTip = 0, cyan) THEN fTip := 0; Potriveste END;
    IF Buton(214, y, 100, rh, "HP", fTip = 1, cyan) THEN fTip := 1; Potriveste END;
    IF Buton(318, y, 100, rh, "BP", fTip = 2, cyan) THEN fTip := 2; Potriveste END;
    Rand(30, y + p, "CUTOFF", cutI, 0, 6, 1, cyan); Gol; AdN(cutHz[cutI]); Val(y + p, cyan);
    Rand(31, y + 2 * p, "RES", res, 1, 20, 1, cyan); Gol; AdN(res); Val(y + 2 * p, cyan);
    Rand(32, y + 3 * p, "ATTACK", atkI, 0, 6, 1, aur); Gol; AdN(fib7[atkI]); Ad(" MS"); Val(y + 3 * p, aur);
    Rand(33, y + 4 * p, "RELEASE", relI, 0, 6, 1, aur); Gol; AdN(fib7[relI]); Ad(" MS"); Val(y + 4 * p, aur);
    Rand(34, y + 5 * p, "LFO", lfo, 0, 60, 1, violet); Gol; AdN(lfo); Ad(" HZ"); Val(y + 5 * p, violet);
    pv := pisano[dlyPas];
    Rand(35, y + 6 * p, "DELAY", dlyPas, 0, 15, 1, verde);
    Gol; IF pv = 0 THEN AdN(250) ELSE AdN(pv * 500 DIV 6) END; Ad(" MS"); Val(y + 6 * p, verde);
    Rand(36, y + 7 * p, "FEEDBK", fbk, 0, 90, 5, verde); Gol; AdN(fbk); Ad("%"); Val(y + 7 * p, verde);
    Rand(37, y + 8 * p, "MIX", mix, 0, 100, 5, verde); Gol; AdN(mix); Ad("%"); Val(y + 8 * p, verde);
    Rand(38, y + 9 * p, "VOLUME", vol, 0, 100, 1, verde); Gol; AdN(vol); Val(y + 9 * p, verde);
    Rand(39, y + 10 * p, "LATENCY", avansMs, 20, 200, 5, rosu); Gol; AdN(avansMs); Ad(" MS"); Val(y + 10 * p, rosu);
    Gol; Ad("UNDERRUNS: "); AdN(Ecran.Citeste(24)); Ad("   RATE: "); AdN(SR); Scrie(10, y + 11 * p + rh DIV 2 - 7, 2, gri);
    rh := 42
  END Sunete;

  (* ---------- SECV ---------- *)

  PROCEDURE Zar(n: INTEGER): INTEGER;
  BEGIN samanta := (samanta * 75 + 74) MOD 65537
    RETURN samanta MOD n
  END Zar;

  PROCEDURE Plus(x, y: INTEGER; nume: ARRAY OF CHAR; VAR v: INTEGER; max: INTEGER);   (* nume  -  valoare  + *)
  BEGIN
    Gol; Ad(nume); Scrie(x, y + 16, 2, alb);
    IF Buton(x + 30, y, 50, 46, "-", FALSE, aur) THEN v := (v + max) MOD (max + 1) END;
    Gol; AdN(v); ScrieC(x + 100, y + 16, 2, aur);
    IF Buton(x + 120, y, 50, 46, "+", FALSE, aur) THEN v := (v + 1) MOD (max + 1) END
  END Plus;

  PROCEDURE Secventa;
    VAR i, x, y, c, lat, v: INTEGER;
  BEGIN
    IF secvMerge THEN
      IF Buton(4, 122, 130, 50, "STOP", TRUE, verde) THEN secvMerge := FALSE; NotaOff(idSecv); Tine(FALSE, 0, 0, 0, idSecv) END
    ELSIF Buton(4, 122, 130, 50, "PLAY", FALSE, verde) THEN secvMerge := TRUE; secvPoz := 0; secvUrm := scris
    END;
    IF Buton(138, 122, 130, 50, "RND", FALSE, violet) THEN
      FOR i := 0 TO 63 DO sX[i] := Zar(7); sY[i] := Zar(3); sZ[i] := Zar(4); sMut[i] := FALSE END
    END;
    IF Buton(272, 122, 130, 50, "FIB", FALSE, aur) THEN
      FOR i := 0 TO 63 DO sX[i] := pisano[i MOD 16]; sY[i] := i DIV 16 MOD 3; sZ[i] := i * 2 MOD 7; sMut[i] := FALSE END
    END;
    IF Buton(406, 122, 130, 50, "RST", FALSE, rosu) THEN
      secvMerge := FALSE; NotaOff(idSecv); Tine(FALSE, 0, 0, 0, idSecv); secvPoz := 0; secvAcum := -1
    END;
    v := bpm; Rand(40, 178, "BPM", bpm, 40, 240, 1, aur); Gol; AdN(bpm); Val(178, aur);
    IF v # bpm THEN murdar := TRUE END;
    lat := W DIV 8;
    FOR i := 0 TO 63 DO
      x := i MOD 8 * lat; y := 230 + i DIV 8 * 62;
      IF sMut[i] THEN c := panou ELSE c := Grafica.RGB(50 + sX[i] * 28, 40 + sY[i] * 60, 70 + sZ[i] * 28) END;
      IF secvMerge & (i = secvAcum) THEN c := alb END;
      Grafica.Dreptunghi(x + 2, y + 2, lat - 4, 58, c);
      IF i = secvAles THEN
        Grafica.Dreptunghi(x, y, lat, 3, aur); Grafica.Dreptunghi(x, y + 59, lat, 3, aur);
        Grafica.Dreptunghi(x, y, 3, 62, aur); Grafica.Dreptunghi(x + lat - 3, y, 3, 62, aur)
      END;
      Gol; AdN(sX[i]); AdN(sY[i]); AdN(sZ[i]); ScrieC(x + lat DIV 2, y + 24, 2, negru);
      IF lovit & In(x, y, lat, 62) THEN secvAles := i END
    END;
    y := 740;
    Gol; Ad("STEP "); AdN(secvAles + 1); Ad(":  "); AdNota(Hz(sX[secvAles], sY[secvAles], sZ[secvAles])); Ad("  ");
    AdHz(Hz(sX[secvAles], sY[secvAles], sZ[secvAles])); Scrie(10, y, 2, alb);
    Plus(4, y + 30, "X", sX[secvAles], 6); Plus(184, y + 30, "Y", sY[secvAles], 6); Plus(364, y + 30, "Z", sZ[secvAles], 6);
    IF Buton(4, y + 86, 170, 50, "MUTE", sMut[secvAles], rosu) THEN sMut[secvAles] := ~sMut[secvAles] END;
    IF Buton(184, y + 86, 170, 50, "LISTEN", FALSE, cyan) THEN NotaOn(sX[secvAles], sY[secvAles], sZ[secvAles], idDeget) END;
    IF ~ap & apInainte & (tastaJos < 0) THEN NotaOff(idDeget) END
  END Secventa;

  (* ---------- REC ---------- *)

  PROCEDURE OpresteRec;
    VAR i: INTEGER;
  BEGIN
    recDur := scris - recStart; recStare := 0;
    FOR i := 0 TO NV - 1 DO   (* ce mai suna primeste un sfarsit *)
      IF (vStare[i] = 1) & (vId[i] # 0) & (nEv < MaxEv) THEN
        evT[nEv] := recDur; evOn[nEv] := FALSE; evX[nEv] := 0; evY[nEv] := 0; evZ[nEv] := 0; evId[nEv] := vId[i]; INC(nEv)
      END
    END
  END OpresteRec;

  (* ---------- fisierul: sunetul si notele, ca text ---------- *)

  PROCEDURE Ms(e: INTEGER): INTEGER;   (* esantioane -> miimi de secunda *)
  BEGIN RETURN e DIV SR * 1000 + e MOD SR * 1000 DIV SR
  END Ms;

  PROCEDURE Es(ms: INTEGER): INTEGER;   (* miimi de secunda -> esantioane *)
  BEGIN RETURN ms DIV 1000 * SR + ms MOD 1000 * SR DIV 1000
  END Es;

  PROCEDURE Cale(n: INTEGER; download: BOOLEAN; VAR c: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    Gol; IF download THEN Ad("/sdcard/Download/") END;
    Ad("SynthZ7-"); AdN(n); Ad(".txt");
    i := 0;
    WHILE (i < tn) & (i < LEN(c) - 1) DO c[i] := t[i]; INC(i) END;
    c[i] := 0X
  END Cale;

  PROCEDURE FSir(h: INTEGER; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO Fisier.Scrie(h, ORD(s[i])); INC(i) END
  END FSir;

  PROCEDURE FNr(h, n: INTEGER);   (* un spatiu si numarul *)
  BEGIN Gol; Ad(" "); AdN(n); FSir(h, t)
  END FNr;

  PROCEDURE Salveaza(n: INTEGER);
    VAR h, i, j, k, d: INTEGER; c: ARRAY 64 OF CHAR;
  BEGIN
    Cale(n, TRUE, c); h := Fisier.Creeaza(c); mesaj := 1;
    IF h < 0 THEN Cale(n, FALSE, c); h := Fisier.Creeaza(c); mesaj := 2 END;
    IF h < 0 THEN mesaj := 3
    ELSE
      FSir(h, "Z7SYNTH 1"); Fisier.Scrie(h, 10);
      FSir(h, "S"); FNr(h, fTip); FNr(h, cutI); FNr(h, res); FNr(h, atkI); FNr(h, relI); FNr(h, lfo); FNr(h, dlyPas);
      FNr(h, fbk); FNr(h, mix); FNr(h, vol); Fisier.Scrie(h, 10);
      FOR i := 0 TO NO - 1 DO
        FSir(h, "O"); FNr(h, i); IF oOn[i] THEN FNr(h, 1) ELSE FNr(h, 0) END;
        FNr(h, oUnda[i]); FNr(h, oDez[i]); FNr(h, oVol[i]); Fisier.Scrie(h, 10)
      END;
      FOR i := 0 TO nEv - 1 DO
        IF evOn[i] THEN   (* durata: pana la primul sfarsit cu acelasi nume *)
          k := -1; j := i + 1;
          WHILE (j < nEv) & (k < 0) DO
            IF evId[j] = evId[i] THEN k := j END;
            INC(j)
          END;
          IF k >= 0 THEN d := evT[k] - evT[i] ELSE d := recDur - evT[i] END;
          IF d < 1 THEN d := 1 END;
          FSir(h, "N"); FNr(h, Ms(evT[i])); FNr(h, evX[i]); FNr(h, evY[i]); FNr(h, evZ[i]); FNr(h, Ms(d)); Fisier.Scrie(h, 10)
        END
      END;
      FSir(h, "D"); FNr(h, Ms(recDur)); Fisier.Scrie(h, 10);
      Fisier.Gata(h)
    END
  END Salveaza;

  PROCEDURE Margini(VAR v: INTEGER; min, max: INTEGER);
  BEGIN IF v < min THEN v := min ELSIF v > max THEN v := max END
  END Margini;

  PROCEDURE PuneEv(tt: INTEGER; on: BOOLEAN; x, y, z, id: INTEGER);   (* la locul lui dupa timp (sfarsiturile inaintea inceputurilor) *)
    VAR i: INTEGER;
  BEGIN
    IF nEv < MaxEv THEN
      i := nEv;
      WHILE (i > 0) & ((evT[i - 1] > tt) OR ((evT[i - 1] = tt) & evOn[i - 1] & ~on)) DO
        evT[i] := evT[i - 1]; evOn[i] := evOn[i - 1]; evX[i] := evX[i - 1]; evY[i] := evY[i - 1]; evZ[i] := evZ[i - 1];
        evId[i] := evId[i - 1]; DEC(i)
      END;
      evT[i] := tt; evOn[i] := on; evX[i] := x; evY[i] := y; evZ[i] := z; evId[i] := id; INC(nEv)
    END
  END PuneEv;

  PROCEDURE Incarca(n: INTEGER);
    VAR h, b, k, v, i, note: INTEGER; tag: CHAR; minus, cifre: BOOLEAN; c: ARRAY 64 OF CHAR;
  BEGIN
    Cale(n, TRUE, c); h := Fisier.Deschide(c);
    IF h < 0 THEN Cale(n, FALSE, c); h := Fisier.Deschide(c) END;
    IF h < 0 THEN mesaj := 4
    ELSE
      Taci; recStare := 0; nEv := 0; recDur := 0; note := 0;
      b := Fisier.Citeste(h);
      WHILE b >= 0 DO
        WHILE (b = 10) OR (b = 13) OR (b = 32) DO b := Fisier.Citeste(h) END;
        IF b >= 0 THEN
          tag := CHR(b); k := 0; b := Fisier.Citeste(h);
          WHILE (b >= 0) & (b # 10) DO   (* numerele de pe rand *)
            IF (b = 45) OR ((b >= 48) & (b <= 57)) THEN
              minus := b = 45; v := 0; cifre := FALSE;
              IF minus THEN b := Fisier.Citeste(h) END;
              WHILE (b >= 48) & (b <= 57) DO v := v * 10 + b - 48; cifre := TRUE; b := Fisier.Citeste(h) END;
              IF minus THEN v := -v END;
              IF cifre & (k < 12) THEN nr[k] := v; INC(k) END
            ELSE b := Fisier.Citeste(h)
            END
          END;
          IF (tag = "S") & (k >= 10) THEN
            fTip := nr[0]; cutI := nr[1]; res := nr[2]; atkI := nr[3]; relI := nr[4]; lfo := nr[5]; dlyPas := nr[6];
            fbk := nr[7]; mix := nr[8]; vol := nr[9];
            Margini(fTip, 0, 2); Margini(cutI, 0, 6); Margini(res, 1, 20); Margini(atkI, 0, 6); Margini(relI, 0, 6);
            Margini(lfo, 0, 60); Margini(dlyPas, 0, 15); Margini(fbk, 0, 90); Margini(mix, 0, 100); Margini(vol, 0, 100)
          ELSIF (tag = "O") & (k >= 5) & (nr[0] >= 0) & (nr[0] < NO) THEN
            i := nr[0]; oOn[i] := (nr[1] # 0) OR (i = 0); oUnda[i] := nr[2]; oDez[i] := nr[3]; oVol[i] := nr[4];
            Margini(oUnda[i], 0, 3); Margini(oDez[i], -50, 50); Margini(oVol[i], 0, 100)
          ELSIF (tag = "N") & (k >= 5) & (nr[0] >= 0) & (nr[4] > 0) THEN
            Margini(nr[1], 0, 6); Margini(nr[2], 0, 6); Margini(nr[3], 0, 6);
            PuneEv(Es(nr[0]), TRUE, nr[1], nr[2], nr[3], 10 + note);
            PuneEv(Es(nr[0] + nr[4]), FALSE, 0, 0, 0, 10 + note);
            IF Es(nr[0] + nr[4]) > recDur THEN recDur := Es(nr[0] + nr[4]) END;
            INC(note)
          ELSIF (tag = "D") & (k >= 1) & (Es(nr[0]) > recDur) THEN recDur := Es(nr[0])
          END
        END
      END;
      Fisier.Gata(h); Potriveste; mesaj := 5
    END
  END Incarca;

  PROCEDURE Inreg;
    VAR i, x, y, n, d, k: INTEGER;
  BEGIN
    IF recStare = 1 THEN
      IF Buton(4, 122, 176, 56, "STOP", TRUE, rosu) THEN OpresteRec END
    ELSIF Buton(4, 122, 176, 56, "REC", FALSE, rosu) THEN
      IF recStare = 2 THEN Taci END;
      nEv := 0; recStart := scris; recDur := 0; recStare := 1; plLoc := 0
    END;
    IF recStare = 2 THEN
      IF Buton(182, 122, 176, 56, "STOP", TRUE, verde) THEN recStare := 0; Taci END
    ELSIF Buton(182, 122, 176, 56, "PLAY", FALSE, verde) & (recStare = 0) & (nEv > 0) THEN
      recStare := 2; pbStart := scris; pbI := 0; plLoc := 0
    END;
    IF Buton(360, 122, 176, 56, "LOOP", bucla, aur) THEN bucla := ~bucla END;
    IF Buton(4, 184, 176, 50, "CLEAR", FALSE, gri) & (recStare # 1) THEN
      IF recStare = 2 THEN Taci END;
      recStare := 0; nEv := 0; recDur := 0
    END;
    IF recStare = 1 THEN d := scris - recStart ELSE d := recDur END;
    Gol; AdN(d DIV SR); Ad("."); AdN(d MOD SR * 10 DIV SR); Ad(" S   "); AdN(nEv); Ad(" EVENTS"); Scrie(196, 202, 2, alb);
    (* banda: fiecare nota un punct, la timpul ei si la inaltimea ei *)
    Grafica.Dreptunghi(8, 250, W - 16, 300, panou);
    IF d > 0 THEN
      FOR i := 0 TO nEv - 1 DO
        IF evOn[i] THEN
          x := 10 + evT[i] DIV 64 * (W - 24) DIV (d DIV 64 + 1);
          n := evX[i] + 7 * evY[i] + 49 * evZ[i];
          y := 540 - n * 280 DIV 343;
          Grafica.Dreptunghi(x, y - 4, 10, 12, Grafica.RGB(120 + evX[i] * 22, 120 + evY[i] * 22, 130 + evZ[i] * 20))
        END
      END;
      IF recStare = 2 THEN
        k := scris - pbStart; IF k > d THEN k := d END;
        Grafica.Dreptunghi(10 + k DIV 64 * (W - 24) DIV (d DIV 64 + 1), 250, 2, 300, alb)
      END
    END;
    Gol; Ad("SLOT"); Scrie(10, 576, 2, alb);
    FOR i := 1 TO 7 DO
      Gol; AdN(i);
      IF ButonT(84 + (i - 1) * 64, 560, 64, 46, i = loc, aur) THEN loc := i; mesaj := 0 END
    END;
    IF Buton(4, 612, 264, 54, "SAVE", FALSE, cyan) & (recStare # 1) THEN
      IF nEv > 0 THEN Salveaza(loc) ELSE mesaj := 6 END
    END;
    IF Buton(272, 612, 264, 54, "LOAD", FALSE, violet) & (recStare # 1) THEN Incarca(loc); plLoc := 0 END;
    Gol;
    IF mesaj = 1 THEN Ad("SAVED TO DOWNLOAD: SYNTHZ7-"); AdN(loc); Ad(".TXT")
    ELSIF mesaj = 2 THEN Ad("SAVED IN THE APP (NO ACCESS TO DOWNLOAD)")
    ELSIF mesaj = 3 THEN Ad("COULD NOT SAVE")
    ELSIF mesaj = 4 THEN Ad("SLOT "); AdN(loc); Ad(" IS EMPTY")
    ELSIF mesaj = 5 THEN Ad("LOADED: SLOT "); AdN(loc); Ad(". PRESS PLAY.")
    ELSIF mesaj = 6 THEN Ad("NOTHING TO SAVE: REC FIRST")
    END;
    Scrie(10, 680, 2, verde);
    Gol; Ad("REC, THEN PLAY THE KEYS OR START SEQ."); Scrie(10, 716, 2, gri);
    Gol; Ad("PLAY PLAYS IT BACK. LOOP REPEATS IT."); Scrie(10, 740, 2, gri);
    Gol; Ad("SAVE WRITES NOTES AND SOUND TO A FILE."); Scrie(10, 764, 2, gri)
  END Inreg;

  (* ---------- cadrul ---------- *)

  PROCEDURE Deseneaza;
    VAR i: INTEGER; s: ARRAY 8 OF CHAR;
  BEGIN
    rh := 42;
    Grafica.Dreptunghi(0, 0, W, H, fond);
    Gol; Ad("SYNTH Z7"); Scrie(12, 14, 4, aur);
    IF recStare = 1 THEN Grafica.Cerc(W - 96, 28, 12, rosu) ELSIF recStare = 2 THEN Grafica.Cerc(W - 96, 28, 12, verde) END;
    IF secvMerge THEN Gol; Ad("SEQ"); Scrie(W - 190, 20, 2, verde) END;
    IF Buton(W - 70, 6, 66, 46, "X", FALSE, rosu) THEN
      iesire := TRUE;
      IF tastaJos >= 0 THEN NotaOff(idDeget); Tine(FALSE, 0, 0, 0, idDeget); tastaJos := -1 END
    END;
    FOR i := 0 TO 3 DO
      IF i = 0 THEN s := "KEYS" ELSIF i = 1 THEN s := "SOUND" ELSIF i = 2 THEN s := "SEQ" ELSE s := "REC" END;
      IF Buton(i * W DIV 4, 60, W DIV 4, 50, s, i = tab, aur) & (i # tab) THEN
        tab := i; prins := -1;
        IF tastaJos >= 0 THEN NotaOff(idDeget); Tine(FALSE, 0, 0, 0, idDeget); tastaJos := -1 END
      END
    END;
    IF tab = tClape THEN Clape ELSIF tab = tSunet THEN Sunete ELSIF tab = tSecv THEN Secventa ELSE Inreg END;
    IF ~cuSunet THEN
      Grafica.Dreptunghi(0, H - 70, W, 70, rosu);
      Gol; Ad("THIS WINDOW HAS NO STREAMING SOUND"); Scrie(10, H - 60, 2, alb);
      Gol; Ad("PUT ECRAN-GL3-SUNET2.DEX IN UNELTE, REBUILD"); Scrie(10, H - 34, 2, alb)
    END
  END Deseneaza;

  PROCEDURE Pornire;
    VAR i, m, x, y, z: INTEGER; f, d, cel: REAL;
  BEGIN
    fib7[0] := 8; fib7[1] := 13; fib7[2] := 21; fib7[3] := 34; fib7[4] := 55; fib7[5] := 89; fib7[6] := 144;
    pisano[0] := 0; pisano[1] := 1; pisano[2] := 1; pisano[3] := 2; pisano[4] := 3; pisano[5] := 5; pisano[6] := 1; pisano[7] := 6;
    pisano[8] := 0; pisano[9] := 6; pisano[10] := 6; pisano[11] := 5; pisano[12] := 4; pisano[13] := 2; pisano[14] := 6; pisano[15] := 1;
    cutHz[0] := 200; cutHz[1] := 500; cutHz[2] := 1000; cutHz[3] := 2000; cutHz[4] := 4000; cutHz[5] := 8000; cutHz[6] := 16000;
    FOR i := 0 TO NO - 1 DO oOn[i] := i = 0 END;
    oUnda[0] := 0; oDez[0] := 0; oVol[0] := 100;
    oUnda[1] := 1; oDez[1] := 7; oVol[1] := 50;
    oUnda[2] := 2; oDez[2] := -5; oVol[2] := 40;
    oUnda[3] := 3; oDez[3] := 12; oVol[3] := 45;
    oUnda[4] := 0; oDez[4] := -12; oVol[4] := 35;
    oUnda[5] := 1; oDez[5] := 19; oVol[5] := 30;
    oUnda[6] := 3; oDez[6] := -7; oVol[6] := 40;
    fTip := 0; cutI := 3; res := 2; atkI := 0; relI := 4; lfo := 0; dlyPas := 4; fbk := 50; mix := 30; vol := 70;
    FOR i := 0 TO NV - 1 DO vStare[i] := 0; vId[i] := 0; vEnv[i] := 0.0 END;
    FOR i := 0 TO LE - 1 DO eco[i] := 0.0 END;
    FOR i := 0 TO 511 DO unda[i] := 0 END;
    ecoW := 0; undaW := 0; lfoFaza := 0.0; scris := 0;
    FOR i := 0 TO 63 DO sX[i] := i MOD 7; sY[i] := 0; sZ[i] := 0; sMut[i] := FALSE END;
    secvMerge := FALSE; secvPoz := 0; secvAcum := -1; secvAles := 0; bpm := 120; secvUrm := 0;
    nEv := 0; recStare := 0; recStart := 0; recDur := 0; pbStart := 0; pbI := 0; bucla := FALSE;
    shOff := 0; torOff := 0; loc := 1; mesaj := 0; plLoc := 0; plRand := FALSE; plUrm := FALSE; urm := FALSE;
    tab := tClape; zStrat := 0; tastaJos := -1; prins := -1; nSuna := FALSE; nx := 0; ny := 0; nz := 0; nf := 0.0;
    ap := FALSE; apInainte := FALSE; lovit := FALSE; murdar := TRUE; mx := 0; my := 0;
    (* pianul: fiecare clapa canta nodul cu frecventa de baza cea mai apropiata, ca in HTML *)
    FOR m := 48 TO 72 DO
      f := 440.0 * Math.exp(FLT(m - 69) / 12.0 * Math.ln(2.0)); cel := 1000.0;
      FOR x := 0 TO 6 DO FOR y := 0 TO 6 DO FOR z := 0 TO 6 DO
        d := ABS(Math.ln(HzBaza(x, y, z) / f));
        IF d < cel THEN cel := d; pX[m - 48] := x; pY[m - 48] := y; pZ[m - 48] := z END
      END END END
    END;
    k5 := 1.0 - Math.exp(-1.0 / (0.005 * srR)); k20 := 1.0 - Math.exp(-1.0 / (0.02 * srR)); k50 := 1.0 - Math.exp(-1.0 / (0.05 * srR));
    Potriveste;
    nb0 := b0; nb1 := b1; nb2 := b2; na1 := a1; na2 := a2; nCastig := castig; nVol := FLT(vol) / 100.0;
    nFb := ecoFb; nUd := ecoUd; nUscat := ecoUscat; nLung := tLung;
    FOR i := 0 TO NO - 1 DO IF oOn[i] THEN oG[i] := FLT(oVol[i]) / 100.0 ELSE oG[i] := 0.0 END END
  END Pornire;

  PROCEDURE Porneste*;   (* dupa ce exista fereastra *)
  BEGIN
    W := Ecran.Latime(); fw := W; H := Ecran.Inaltime() - RANDURI; y0 := H; inel := RANDURI * fw - 2;
    fond := Grafica.RGB(22, 4, 42); panou := Grafica.RGB(52, 22, 86); aur := Grafica.RGB(212, 160, 23); alb := Grafica.RGB(240, 235, 250);
    gri := Grafica.RGB(140, 130, 160); violet := Grafica.RGB(191, 128, 255); cyan := Grafica.RGB(125, 211, 252); rosu := Grafica.RGB(239, 68, 68);
    verde := Grafica.RGB(74, 222, 128); negru := Grafica.RGB(10, 4, 20);
    SR := Ecran.Citeste(23); IF (SR < 8000) OR (SR > 96000) THEN SR := 44100 END;
    srR := FLT(SR); avansMs := 50;
    Pornire;
    samanta := Ceas.Ms() MOD 65536 + 1;
    cuSunet := Ecran.Citeste(20) = SEMN; iesire := FALSE; pornit := TRUE
  END Porneste;

  (* ---------- playerul ---------- *)

  PROCEDURE Citeste(n: INTEGER);   (* cate note si cat dureaza locul n; -1 note = gol *)
    VAR h, b, v, note, d: INTEGER; inceput, eD: BOOLEAN; c: ARRAY 64 OF CHAR;
  BEGIN
    Cale(n, TRUE, c); h := Fisier.Deschide(c);
    IF h < 0 THEN Cale(n, FALSE, c); h := Fisier.Deschide(c) END;
    IF h < 0 THEN plNote[n] := -1; plMs[n] := 0
    ELSE
      note := 0; d := 0; inceput := TRUE; eD := FALSE; v := 0;
      b := Fisier.Citeste(h);
      WHILE b >= 0 DO
        IF inceput THEN
          IF b = ORD("N") THEN INC(note) END;
          eD := b = ORD("D"); v := 0
        ELSIF eD & (b >= 48) & (b <= 57) THEN v := v * 10 + b - 48
        END;
        inceput := b = 10;
        IF inceput & eD THEN IF v > d THEN d := v END; eD := FALSE END;
        b := Fisier.Citeste(h)
      END;
      IF eD & (v > d) THEN d := v END;
      Fisier.Gata(h);
      IF note = 0 THEN plNote[n] := -1 ELSE plNote[n] := note END;
      plMs[n] := d
    END
  END Citeste;

  PROCEDURE IntraPlayer*;
    VAR n: INTEGER;
  BEGIN
    FOR n := 1 TO 7 DO Citeste(n) END;
    lovit := FALSE; ap := TRUE   (* degetul care a deschis playerul nu apasa si un loc *)
  END IntraPlayer;

  PROCEDURE CantaLoc(n: INTEGER);
  BEGIN
    IF recStare = 1 THEN OpresteRec END;
    Incarca(n);
    IF (mesaj = 5) & (nEv > 0) THEN
      recStare := 2; pbStart := scris; pbI := 0; plLoc := n; loc := n
    ELSE plNote[n] := -1; plLoc := 0
    END
  END CantaLoc;

  PROCEDURE Urmatorul;   (* PE RAND: primul loc plin dupa cel care s-a terminat *)
    VAR n, k: INTEGER;
  BEGIN
    IF urm THEN
      urm := FALSE; n := plLoc; k := 0; plLoc := 0;
      REPEAT n := n MOD 7 + 1; INC(k) UNTIL (plNote[n] > 0) OR (k = 7);
      IF plNote[n] > 0 THEN CantaLoc(n) END
    END
  END Urmatorul;

  PROCEDURE Locul*(): INTEGER;
  BEGIN Urmatorul;
    IF recStare # 2 THEN plLoc := 0 END
    RETURN plLoc
  END Locul;

  PROCEDURE Player*(apasat: BOOLEAN; x, y: INTEGER): BOOLEAN;   (* TRUE = inapoi in cub *)
    VAR n, ry, rh2, d, k, sus: INTEGER;
  BEGIN
    apInainte := ap; ap := apasat; mx := x; my := y; lovit := ap & ~apInainte; iesire := FALSE;
    Urmatorul;
    IF recStare # 2 THEN plLoc := 0 END;
    Grafica.Dreptunghi(0, 0, W, H, fond);
    Gol; Ad("PLAYER Z7"); Scrie(12, 14, 4, aur);
    IF Buton(W - 70, 6, 66, 46, "X", FALSE, rosu) THEN iesire := TRUE END;
    sus := 70; rh2 := (H - sus - 260) DIV 7; IF rh2 > 96 THEN rh2 := 96 END;
    FOR n := 1 TO 7 DO
      ry := sus + (n - 1) * rh2;
      IF n = plLoc THEN Grafica.Dreptunghi(6, ry + 2, W - 12, rh2 - 6, aur) END;
      Grafica.Dreptunghi(10, ry + 6, W - 20, rh2 - 14, panou);
      Gol; AdN(n); Scrie(28, ry + rh2 DIV 2 - 17, 4, aur);
      Gol;
      IF plNote[n] < 0 THEN Ad("EMPTY"); Scrie(90, ry + rh2 DIV 2 - 7, 2, gri)
      ELSE
        d := plMs[n]; AdN(d DIV 1000); Ad("."); AdN(d MOD 1000 DIV 100); Ad(" S   "); AdN(plNote[n]); Ad(" NOTES");
        IF n = plLoc THEN Scrie(90, ry + rh2 DIV 2 - 7, 2, alb) ELSE Scrie(90, ry + rh2 DIV 2 - 7, 2, cyan) END;
        IF (n = plLoc) & (recDur > 0) THEN   (* cat a cantat *)
          k := scris - pbStart; IF k > recDur THEN k := recDur END; IF k < 0 THEN k := 0 END;
          Grafica.Dreptunghi(20, ry + rh2 - 18, (W - 40) * (k DIV 64) DIV (recDur DIV 64 + 1), 4, verde)
        END
      END;
      IF lovit & In(10, ry + 6, W - 20, rh2 - 14) THEN
        IF n = plLoc THEN recStare := 0; Taci; plLoc := 0
        ELSIF plNote[n] > 0 THEN CantaLoc(n)
        END
      END
    END;
    ry := sus + 7 * rh2 + 10;
    IF Buton(4, ry, 176, 56, "LOOP", bucla, aur) THEN bucla := ~bucla; IF bucla THEN plRand := FALSE END END;
    IF Buton(182, ry, 176, 56, "IN ORDER", plRand, verde) THEN plRand := ~plRand; IF plRand THEN bucla := FALSE END END;
    IF Buton(360, ry, 176, 56, "STOP", FALSE, rosu) THEN
      IF recStare = 2 THEN recStare := 0; Taci END; plLoc := 0
    END;
    Gol;
    IF bucla THEN Ad("AT THE END: STARTS OVER") ELSIF plRand THEN Ad("AT THE END: NEXT FULL SLOT")
    ELSE Ad("AT THE END: STOPS") END;
    Scrie(10, ry + 72, 2, verde);
    Gol; Ad("TOUCH A SLOT: PLAYS IT WITH ITS SOUND."); Scrie(10, ry + 104, 2, gri);
    Gol; Ad("TOUCH THE PLAYING SLOT: STOPS."); Scrie(10, ry + 128, 2, gri);
    Gol; Ad("FILL THE SLOTS IN THE SYNTH: REC, SAVE."); Scrie(10, ry + 152, 2, gri);
    Gol; Ad("MUSIC KEEPS PLAYING BACK IN THE CUBE."); Scrie(10, ry + 176, 2, gri)
    RETURN iesire
  END Player;

  PROCEDURE Cadru*(apasat: BOOLEAN; x, y: INTEGER): BOOLEAN;   (* un cadru al synthului; TRUE = inapoi in cub *)
  BEGIN
    apInainte := ap; ap := apasat; mx := x; my := y;
    lovit := ap & ~apInainte;
    IF ~ap THEN prins := -1 END;
    Urmatorul;
    iesire := FALSE;
    Deseneaza
    RETURN iesire
  END Cadru;

  (* ---------- for the shell ---------- *)

  PROCEDURE Rescan*;
    VAR n: INTEGER;
  BEGIN FOR n := 1 TO 7 DO Citeste(n) END
  END Rescan;

  PROCEDURE Slot*(n: INTEGER): INTEGER;
  BEGIN IF (n < 1) OR (n > 7) THEN n := -1 ELSE n := plNote[n] END
    RETURN n
  END Slot;

  PROCEDURE SlotMs*(n: INTEGER): INTEGER;
  BEGIN IF (n < 1) OR (n > 7) THEN n := 0 ELSE n := plMs[n] END
    RETURN n
  END SlotMs;

  PROCEDURE PlaySlot*(n: INTEGER): BOOLEAN;
  BEGIN
    IF (n >= 1) & (n <= 7) THEN Citeste(n); IF plNote[n] > 0 THEN CantaLoc(n) END END
    RETURN (n >= 1) & (n <= 7) & (plLoc = n)
  END PlaySlot;

  PROCEDURE Stop*;
  BEGIN
    IF recStare = 1 THEN OpresteRec END;
    recStare := 0; secvMerge := FALSE; plLoc := 0; shOff := 0; Taci
  END Stop;

  PROCEDURE SetLoop*(b: BOOLEAN); BEGIN bucla := b; IF b THEN plRand := FALSE END END SetLoop;
  PROCEDURE Looping*(): BOOLEAN; BEGIN RETURN bucla END Looping;
  PROCEDURE SetInOrder*(b: BOOLEAN); BEGIN plRand := b; IF b THEN bucla := FALSE END END SetInOrder;
  PROCEDURE InOrder*(): BOOLEAN; BEGIN RETURN plRand END InOrder;

  PROCEDURE Note*(x, y, z, ms: INTEGER);
  BEGIN
    NotaOn(x MOD 7, y MOD 7, z MOD 7, idShell);
    IF ms < 20 THEN ms := 20 ELSIF ms > 10000 THEN ms := 10000 END;
    shOff := scris + Es(ms)
  END Note;

  PROCEDURE NoteHz*(f: REAL; ms: INTEGER);   (* any frequency, for ms milliseconds *)
    VAR v: INTEGER;
  BEGIN
    IF (f > 10.0) & (f < 20000.0) THEN
      NotaOn(0, 0, 0, idTor);
      FOR v := 0 TO NV - 1 DO IF (vStare[v] = 1) & (vId[v] = idTor) THEN vF[v] := f END END;
      nf := f;
      IF ms < 20 THEN ms := 20 ELSIF ms > 10000 THEN ms := 10000 END;
      torOff := scris + Es(ms)
    END
  END NoteHz;

  PROCEDURE Freq*(x, y, z: INTEGER): REAL;
  BEGIN RETURN Hz(x MOD 7, y MOD 7, z MOD 7)
  END Freq;

  PROCEDURE NoteName*(f: REAL; VAR s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN Gol; AdNota(f); i := 0;
    WHILE (i < tn) & (i < LEN(s) - 1) DO s[i] := t[i]; INC(i) END; s[i] := 0X
  END NoteName;

  PROCEDURE Rate*(): INTEGER; BEGIN RETURN SR END Rate;
  PROCEDURE Latency*(): INTEGER; BEGIN RETURN avansMs END Latency;

  PROCEDURE Canta*(): BOOLEAN;
  BEGIN RETURN secvMerge OR (recStare = 2)
  END Canta;

BEGIN
  pornit := FALSE; cuSunet := FALSE; scris := 0; plLoc := 0; plRand := FALSE; plUrm := FALSE; urm := FALSE
END Synth9.
