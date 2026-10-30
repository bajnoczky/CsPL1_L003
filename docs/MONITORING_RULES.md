# L03 – Monitoring szabályok specifikációja

Kapcsolódó feladat: #12 – Monitoring szabályok definiálása. Szülő: #4 – Linux (WSL) szenzor + dashboard.

## 1. Hatókör és állapot

A dokumentum a mellékelt `CsPL1_L003-main.zip` forráskódjára épül (ZIP-kommentben szereplő commit: `190e900ac93aab90899b877be9c1eb700cf602b1`). A szabályok megvalósítási követelmények, nem már működő detektorok. A folyamatbiztonsági határok üzemviteli javaslatok, a forgalmi küszöbök pedig normál forgalmon kalibrálandók. Egyik sem mért vagy oktató által jóváhagyott határérték. MATLAB-futtatást és hálózati integrációs tesztet az elemzés nem helyettesít.

A #12 eredménye a szenzor fejlesztőjének átadható szabályleírás. Nem tartozik ide a relay, a teljes monitoring program és a dashboard implementálása. A tesztlépések kizárólag a projekt saját, izolált virtuális laborjára vonatkoznak.

## 2. A meglévő rendszer értelmezése

| Fájl | Tényleges szerepe |
| --- | --- |
| `PLC/matlab/TankPLC.m` | Tartályállapot, hiszterézises pumpavezérlés és részleges Modbus/TCP parser. Összerakja a TCP-ben szétdarabolt kéréseket, egy beolvasásból több Modbus-kérést is feldolgoz. |
| `PLC/matlab/TankServer.m` | MATLAB `tcpserver` burkoló. Alapértelmezés: 127.0.0.1:1502. Kezeli a kapcsolatot, beolvasást, válaszadást és az eltelt idő szerinti modellfrissítést. |
| `PLC/matlab/plc_panel.m` | Helyi GUI, indítás/leállítás és kb. 0,1 s-os frissítő timer. A kijelző közvetlenül a modellt olvassa, ezért nem foglal második Modbus-kapcsolatot. |
| `PLC/matlab/export_register_map.m` | Négy regiszter nevét, MATLAB-címét, típusát és Server ID-ját tartalmazó MATLAB-táblát ment. Nem monitoring konfiguráció. |
| `PLC/config/tank_registers.mat` | A Modbus Explorer importálható táblája. A bináris fájl MATLAB MCOS/table objektum; a teljes táblatartalom általános Python MAT-olvasóval nem volt megbízhatóan dekódolható. A regiszterkiosztást az exportáló forráskód és a PLC implementáció egybehangzóan rögzíti. |
| `PLC/VirtualOTLab.prj`, `PLC/resources/project/*.xml` | MATLAB projektleírók: munkamappa, MATLAB path, panelindító shortcut, fájllista és kategóriák. Nem tartalmaznak további PLC-programot vagy szenzort. |
| `README.md` | A jelenleg leírt helyi MATLAB-demo indítása és regiszterkiosztása. |
| `TEAM_PLAN.md` | Tervezett WSL relay, TShark capture, Python szabálymotor/CSV és Streamlit dashboard. Ezek programjai hiányoznak a ZIP-ből. |
| `GIT_GUIDE.md` | A csapat munkarendje: egyelőre közös main ág, frissítés, commit, push. PR-kötelezettséget nem ír elő. |
| `.gitattributes`, `.gitignore` | Szöveg/bináris kezelés, MATLAB merge-beállítások és ideiglenes állományok kizárása. |
| `LICENSE` | GNU GPL v3 licencszöveg. |
| `#L03_csoportbemutato.pptx` | Hatdiás projektindító bemutató; nem a jelenlegi implementáció bizonyítéka. |

### Folyamatmodell

Indításkor a vízszint 30%, a cél 60%, az automatikus vezérlés engedélyezett. A szerver induláskor `advance(0)` hívással rögtön meghatározza a pumpa állapotát. A kifolyás mindig 2 százalékpont/s. Bekapcsolt pumpánál a befolyás 8 százalékpont/s, így a nettó emelkedés 6 százalékpont/s. A vízszint 0–100% közé korlátozott, a kiolvasott érték kerekített.

A pumpa a célszinten kikapcsol, a cél mínusz 3 pontnál bekapcsol; a kettő között megtartja állapotát. Kikapcsolt vezérlésnél nem jár. A szerver újraindítása visszaállítja az induló folyamatállapotot; egy kliens újracsatlakozása csak a parser bufferét és blokkoltságát törli. Egyszerre egy klienssel számol a rendszer.

### Forgalom útja

Jelenlegi demo: Windows Modbus Explorer és MATLAB PLC közvetlenül, 1502-es porton.

Tervezett út: Explorer → WSL relay :1503 → MATLAB PLC :1502. A szenzor a relay **kliens felőli oldalát** figyelje, mert ott látszik az eredeti kliens. A PLC a relay-t látja kliensként. Csak az egyik relay-ágat szabad számolni. Két ág együttes figyelése duplázhatja az eseményeket. A szenzor nem pollolja és nem vezérli a PLC-t.

A Windows loopback-forgalom WSL-ből nem tekinthető automatikusan láthatónak. A címeket, interfészt, capture-jogosultságokat és elérési korlátozásokat integrációkor ellenőrizni kell. A nem szabványos 1503-as porton a Modbus dekódolást szükség esetén kifejezetten hozzá kell rendelni a protokollhoz.

## 3. Regiszter- és protokollprofil

| MATLAB-cím | Wire offset | Név | Olvasás | Írás | Tartomány |
| --- | --- | --- | --- | --- | --- |
| 1 | 0 | WaterLevel_pct | igen | nem | 0–100 |
| 2 | 1 | TargetLevel_pct | igen | igen | 0–100 |
| 3 | 2 | ControllerEnabled | igen | igen | 0 vagy 1 |
| 4 | 3 | PumpRunning | igen | nem | 0 vagy 1 |

Minden regiszter uint16, big endian. Unit ID: 1. A funkciók decimális kódjai: 3 (0x03, olvasás), 6 (0x06, egy regiszter írása), 16 (0x10, több regiszter írása). A 16 itt decimális 16, nem 0x16.

A teljes címtartományt és minden írt értéket vizsgálni kell. A PLC a többregiszteres írást csak akkor alkalmazza, ha az összes cím és érték megfelelő, tehát hibás FC16-kérésnél nincs részleges módosítás.

A kód az alábbi válaszokat adja Unit ID 1 és feldolgozható keret esetén:

- Nem támogatott funkció: kivételkód 1.
- Nem létező olvasási cím vagy nem írható cím: kivételkód 2.
- Hibás mennyiség, PDU-hossz, byte count vagy érték: kivételkód 3.
- A kivételválasz funkciókódja az eredeti kód felső bitjének beállításával keletkezik, pl. FC06 esetén 0x86.
- Más Unit ID esetén nincs Modbus-válasz, a kérés kimarad.
- MBAP protocol ID != 0, length < 2 vagy length > 254 esetén a PLC blokkolja az adott kapcsolat feldolgozását újracsatlakozásig. Nem küld szabályos kivételválaszt.

## 4. A riasztási koncepció

A monitoring célja annak észlelése, ha megváltozik, veszélyes állapotba kerül vagy többé nem figyelhető meg a tartály vezérlése. Egy szintaktikailag hibátlan, PLC által elfogadott parancs is okozhat problémát: például Target=0, vagy a vezérlés kikapcsolása. Egyetlen elrontott olvasási cím ezzel szemben lehet egyszerű kezelői hiba.

Ezért külön kezeljük:

- **Folyamatriasztás:** a megfigyelt tartályállapot eltér a kijelölt üzemi tartománytól.
- **Biztonsági figyelmeztetés:** váratlan kliens vagy beavatkozás jelenik meg.
- **Üzemzavar:** a kommunikáció vagy maga a megfigyelés hibás.
- **Eseménynapló:** normál műveletek, beállításváltozások és egyedi kezelési hibák.

Az INFO csak naplóbejegyzés. A WARNING kivizsgálandó eltérés. A CRITICAL az itt meghatározott súlyos folyamatállapot vagy elfogadott, nem engedélyezett beavatkozás; nem automatikusan bizonyított támadás.

A projekt kis méretéhez hat alapvető szabálycsaládot javaslunk, további diagnosztikával. A megvalósítás prioritása: a megfigyelés működőképessége, kommunikáció, regiszterek és vezérlési változások; utána a folyamatértékek elemzése.

## 5. Megfigyelési feltételek

- A szenzor a relay kliens felőli ágán figyel. A megfigyelt IP-cím engedélyezési lista, nem hitelesített felhasználóazonosság. Egy Windows-gépről érkező több program azonos IP-je nem különíthető el megbízhatóan. NAT vagy más proxy tovább csökkentheti a láthatóságot.
- TCP stream-összerakás szükséges. Az újraküldés nem új kérés; egy szegmensben több ADU is lehet. Párosítás: TCP stream + Transaction ID + Unit ID és művelet. Azonosítók újrahasználatát kezelni kell.
- A kérést, a sikeres/kivételes választ és az utólag visszaolvasott állapotot külön rögzítsük. A küldött parancs nem bizonyított végrehajtás. Sikeres írásválasz után a következő olvasás erősíti meg a folyamatállapotot.
- Az állapotot FC03 válaszokból, a kapcsolódó kérés címei alapján kell felépíteni. A szenzor nem indít saját olvasásokat. Ha az Explorer nem olvassa a szükséges regisztereket, az adott folyamatriasztás **nem értékelhető**.
- Első változatban 1 s-onkénti teljes, négyregiszteres olvasás javasolt. Nem feltételezzük, hogy az Explorer ezt már így végzi. Csak legfeljebb 3 s-os, egymáshoz legfeljebb 1 s eltéréssel megfigyelt értékeket vonjunk össze; régi adat esetén „ismeretlen/elavult” állapot legyen.
- Legyen explicit `MONITORING_ACTIVE` és `MAINTENANCE` állapot. Az engedélyezett változtatásokhoz regiszter/érték/tartomány/időablak szerint megadott terv tartozzon. A karbantartás ne kapcsolja ki a naplózást vagy a szenzorhibák jelzését.
- Az alábbi időtartamokat folyamatos fennállásra értjük, friss megfigyelések mellett. Adathiánynál a folyamatriasztás időzítője újraindul; a kommunikációs állapot veszi át a jelzést. A timeoutokat forgalomtól független timer vizsgálja.

## 6. Alapvető szabályok

### OT-01 – A megfigyelés nem működik

**Miért fontos:** néma vagy leállt szenzor mellett a „nincs riasztás” hamis biztonságérzetet ad.

**Feltétel:** a felügyelt capture-folyamat leáll, hibás az interfész, vagy a felügyelt kiértékelő/naplózó nem ad életjelet 5 s-ig. Ha a folyamat működik, de a capture eszköz csomagvesztést jelent, a megfigyelés minősége legyen „romlott”.

**Jelzés:** WARNING, „A monitoring eredménye nem megbízható / nem érhető el”. A teljes szabálymotor leállását külön folyamatnak vagy dashboard/watchdognak kell észlelnie; önmagát a leállt program nem tudja riasztani. A hálózati csend önmagában nem bizonyít capture-hibát.

**Helyreállás:** a felügyelt komponensek ismét működnek; a forgalmi láthatóságot az első érvényes tranzakció után tekintjük igazoltnak. A kiesés alatt a folyamat állapota ismeretlen.

### OT-02 – Elveszett kommunikáció vagy válasz nélküli kérések

**Miért fontos:** a kezelő elveszítheti a folyamat követését vagy vezérlését. Ettől a PLC helyi szabályozása még működhet.

**Feltételek aktív monitoringban:**

1. Már működő kapcsolatnál legalább `max(5 s, 3 × beállított pollingintervallum)` ideje nincs sikeres tranzakció → WARNING.
2. Kérés érkezik, de a párosított válasz 3 s-on belül nem látható → timeout esemény. Három egymást követő lejárt kérés → WARNING. Sikeres tranzakció nullázza a sorozatot.
3. Monitoring aktiválása után 10 s-ig egyetlen sikeres tranzakció sem jelenik meg → „A megfigyelési útvonal indulása nincs igazolva”.

A tartós kivételválaszok nem „nincs forgalom”, hanem „nincs sikeres kommunikáció” állapotot jelentenek. A későn beérkező választ naplózzuk. TCP FIN/RST külön esemény; aktív monitoringban a kiesési szabály tovább érvényes.

**Feloldás:** érvényes sikeres tranzakció, egy RECOVERY eseménnyel. Hosszabb kiesésnél a korábbi folyamatértékek ne maradjanak zöld, aktuális állapotként a felületen.

### OT-03 – Váratlan kliens vagy nem engedélyezett vezérlési művelet

**Feltétel:**

- A megfigyelt kliens IP nincs az előre beállított engedélyezési listán: első kapcsolódási kísérletre WARNING. A PLC csak egy klienst fogad, így a sikertelen próbálkozás is releváns.
- Írási kísérlet olyan klienstől, amelynek csak olvasási szerepet adtunk: WARNING; normál válasszal elfogadott írás esetén CRITICAL.
- Engedélyezett kliens esetén is WARNING, ha az írás nem fér bele az előre jóváhagyott műveletbe/időablakba.

Minden sikeres célérték- vagy engedélyezés-változás INFO esemény: korábbi ismert érték, új érték, kliens, időpont, elfogadás és visszaolvasási megerősítés. A pillanatnyilag leállt szerverre próbáló második kliens sem bizonyított támadó.

**Korlát:** ugyanazon engedélyezett gépről induló másik alkalmazás vagy felhasználó IP alapján nem hitelesíthető. A dokumentum nem állít Modbus-szintű felhasználóazonosítást.

### OT-04 – Tiltott vagy hibás vezérlési parancs

**Azonnali WARNING:** FC06/FC16 írás nem írható vagy nem létező címre; Target >100; Enabled nem 0/1; hibás írási PDU. Wire offset 1 és 2 írható; 0 és 3 csak olvasható. A teljes FC16 tartományt és minden értéket ellenőrizni kell.

**Üzemi eltérés, bár protokollszinten érvényes:** bemutatói munkahipotézisként célérték 20–80% az engedélyezett normál tartomány. Ezen kívüli, elfogadott célérték vagy az automatikus vezérlés kikapcsolása aktív, normál üzemmódban WARNING, kivéve ha kifejezetten engedélyezett tesztművelet. A 20–80% nem a program beépített korlátja és nem fizikai biztonsági határ; a csapatnak jóvá kell hagynia.

A 0 és 100 érték a PLC számára szabályos. Target=0 mellett leáll a pumpa, így a tartály kiürülhet; ez indokolja, hogy a protokollvalidálás mellett üzemviteli szabály is legyen.

**Válaszkezelés:** nem írható cím → kód szerint kivétel 2; hibás érték/PDU → kivétel 3. Az elutasított kérés és válasza egy összekapcsolt esemény. FC16 hibánál az implementáció egyik regisztert sem módosítja. Ha elutasított parancs után a folyamat mégis ugyanarra az értékre változik, az okát külön kell vizsgálni.

### OT-05 – Túl alacsony vagy túl magas vízszint

**Induló bemutatói határok:**

| Feltétel friss visszaolvasott vízszintre | Jelzés |
| --- | --- |
| Level <=10% vagy >=90% legalább 2 s-ig | WARNING |
| Level <=5% vagy >=95% legalább 1 s-ig | CRITICAL |

A határok oktatási demonstrációs értékek. A modell 0–100% közé korlátozza a vízszintet, ezért tényleges túlfolyást vagy szivattyúkárosodást nem szimulál. A riasztás a kijelölt üzemi tartomány megsértését jelzi.

**Hiszterézis és feloldás:** alacsony WARNING Level >=15%, magas WARNING Level <=85% legalább 2 s-ig. Alacsony CRITICAL Level >=10%, magas CRITICAL Level <=90% legalább 2 s-ig; a fennmaradó WARNING ettől még aktív lehet. Egy eseményállapotot frissítsünk, ne minden pollnál új riasztást küldjünk.

**Engedélyezett teszt:** előre rögzített leürítési/feltöltési tesztben az esemény jelzett, várt teszteseményként jelenhet meg. A szélsőséges állapotot karbantartás alatt se rejtsük el.

### OT-06 – A vezérlés és a visszajelzett állapot ellentmondása

**Az első verzióban ellenőrizhető állapotok:**

- Enabled=0 és Pump=1 legalább két egymást követő koherens mintában.
- Enabled=1, Level >= Target+2 és Pump=1 legalább két koherens mintában.
- Enabled=1, Target>0, Level <=max(0,Target−3)−2 és Pump=0 legalább két koherens mintában.
- Visszaolvasott Level/Target kívül 0–100 tartományon, vagy Enabled/Pump nem 0/1: azonnali WARNING, ha a dekódolás és kérés–válasz párosítás helyes.

**Jelzés:** WARNING, „A visszajelzett állapot nem egyezik a vezérlési profillal”. A 2 pontos tolerancia a kerekítés és időzítés hatását csökkenti. A hiszterézis belsejében a pumpa mindkét állapota megengedett; ott nincs ilyen riasztás.

A jelenlegi TankPLC ugyanabból a szoftverállapotból számolja a pumpát és a vízszintet. Ezért ilyen ellentmondás normál, módosítatlan működésben nem feltétlenül állítható elő. Teszteléshez offline rögzített/szintetikus eseménysor kell; nem állítjuk, hogy ezzel valódi pumpahibát detektálunk.

**Későbbi bővítés:** szintváltozás vizsgálata a −2 vagy +6 pont/s modellhez képest. Csak megbízható mintavétel, ismert pumpaváltások és igazolt MATLAB timer-viselkedés mellett érdemes bevezetni. A hosszú desktop timer-kimaradás miatt a modell egy lépésben túllendülhet a célszinten. A puszta célérték-eltérés ezért induláskor és célértékváltás után nem önmagában hiba.

## 7. További diagnosztikai szabályok

| Esemény | Reális kezelés |
| --- | --- |
| Egyedi hibás olvasás | INFO, kliens/cím/kivétel naplózása. Kezelési vagy konfigurációs hiba is lehet. Legalább 5 érvénytelen olvasás 10 s alatt ugyanattól a klienstől → WARNING. |
| Ismételt nem támogatott funkció vagy Unit ID | INFO, ismétlődő mintánál az előzőhöz hasonló WARNING. Más Unit ID-t a PLC válasz nélkül ignorálja. |
| Hibás MBAP-fejléc | WARNING már egy eseményre: a jelenlegi kód az adott kapcsolat feldolgozását újracsatlakozásig blokkolhatja. |
| Tartósan szokatlan kérési ráta | Legalább 60 s-os, stabil normál mérésből 1 s-os ablakszámok p95 értéke B. Küszöbjavaslat max(20 kérés/s, 3×B), legalább 3 s fennállással. Előzetes konfiguráció nélkül legyen „nincs kalibrálva” állapot, ne rejtett alapérték. |
| Gyakori célértékváltás | Legalább 5 tényleges, elfogadott Target-változás 10 s alatt → WARNING normál üzemben. Azonos érték ismételt írása nem célértékváltás. Tesztnél lehet várt viselkedés. |

A ráta emelkedése önmagában nem bizonyít túlterhelést vagy támadást. Válaszidő-növekedéssel, timeouttal és hibákkal együtt erősebb jel. Kizárólag a TCP csomagszám emelkedése nem megfelelő Modbus-terhelési metrika. Baseline-t csak ellenőrzött normál üzemben vegyünk fel; ne tanuljuk automatikusan újra a riasztás idején.

## 8. Naplózás, állapot és riasztási zaj

Minden olvasás/írás strukturált eseményként menthető, de a felület csak állapotváltáskor riasztson: OPEN, súlyosságváltozás, majd RECOVERY. Azonos hibát szabály + érintett endpoint/kliens szerint csoportosítsunk; tartós állapotra legfeljebb 30 s-onként összesítő emlékeztető készüljön. Egy tiltott kérés és kivételválasza ne duplázza a riasztást.

Ajánlott mezők: UTC idő, szabályazonosító, súlyosság, állapot, kliens/cél endpoint, stream/Transaction/Unit ID, funkció, cím és értékek, kivételkód, előző/új állapot, adatfrissesség, mérési minőség, maintenance jelölés, küszöbkonfiguráció verziója.

A dashboardon a folyamatérték mellett látszódjon a minta kora. Ha a szenzor vagy a kommunikáció kiesett, az „ismeretlen” állapot ne legyen összekeverhető az egészséges állapottal. A nyugtázás nem helyreállás: attól a hibafeltétel még fennállhat.

## 9. Ellenőrzési terv és megvalósítási sorrend

| Teszt kizárólag saját laborban vagy offline eseménysoron | Elvárt eredmény |
| --- | --- |
| Target=60, Enabled=1, normál polling legalább 60 s-ig | Nincs aktív folyamat- vagy kommunikációs riasztás; a 57–60% körüli normál ciklus megengedett. |
| Target=70 engedélyezett kézi műveletként | Változási napló, a feltöltési átmenet nem hiba. |
| Target=0 normál üzemben | Elfogadott, üzemi tartományon kívüli célérték jelzése; később alacsony szintriasztás. |
| Enabled=0 előre engedélyezett leürítési tesztben | Várt változási esemény, a szintcsökkenés látható. A szinthatár-jelzés tesztként azonosítható. |
| Target=101 vagy írás wire 0-ra | Tiltott írási kísérlet és a PLC kivételválasza, állapotváltozást nem állítunk. |
| Egy elrontott, majd sok ismételt hibás olvasás | Először INFO; a sorozatküszöbnél WARNING. |
| Explorer polling megállítása aktív monitoringban | Kommunikációs WARNING; folyamatadat elavult, nem bizonyított PLC-leállás. |
| Capture-folyamat leállítása | Külön felügyelet szenzorhibát jelez. |
| Ismeretlen kliens csatlakozási kísérlete | Engedélyezési lista eltérésének WARNING jelzése, sikertelen kapcsolatnál is. |
| Offline koherens Enabled=0, Pump=1 mintasor | Állapotellentmondás jelzése két mintánál. |
| Offline elavult vagy eltérő idejű állapotminták | Nincs hamis állapotellentmondás; nem értékelhető állapot. |
| A relay két ágának vagy TCP retransmissionnek a megjelenése | Ne duplázzuk a tranzakciókat; az egyik relay-ág a konfigurált forrás. |

A táblázat tervezett teszt, nem futtatási jegyzőkönyv. A jelenlegi környezetben MATLAB és teljes WSL capture-lánc nem volt futtatva.

**Minimális megvalósítás:** OT-01–OT-05, majd OT-06 egyszerű állapotellenőrzése. A folyamatfigyelés csak teljes regiszterolvasás beállítása után tekinthető késznek. A forgalmi anomáliák kalibrálása és a fizikai modell szerinti trendfigyelés ezután következhet.

**A csapattal jóváhagyandó:** normál üzemi cél- és szinthatárok; engedélyezett kliens és író szerep; pollingintervallum; teszt/karbantartási mód; a WSL capture elhelyezése. Ezek nélkül egy szenzor technikailag riaszthat, de a riasztás üzemviteli jelentése nem egyértelmű.

## 10. Átadás a #12 issue-hoz

Javasolt repository-útvonal: `docs/MONITORING_RULES.md`. A dokumentum és a commit hivatkozása kerüljön az issue-ba. A #12 a specifikáció átadásával zárható, az implementáció és a végrehajtott ellenőrzések külön nyomon követendők. A képen kért szakmai átadás Dugár Bálintnak szintén külön teendő; a dokumentum létrejötte nem e-mail-küldés.

A mellékelt GIT_GUIDE jelenleg main ágat, commitot és push-t ír le. A `refs #12` commitüzenet megfelelő hivatkozás. A sima GitHub-komment nem zárja az issue-t; teljesítéskor a Close issue gombbal lehet lezárni. A szülő #4 és a Project státusza külön ellenőrizendő.
