# A szenzor által figyelendő szabályok

A szenzor passzívan figyelje a Modbus/TCP-forgalmat, és az alábbi feltételeknél jelezzen:

| Szabály | Riasztási feltétel |
| --- | --- |
| Nem engedélyezett kliens | Az előre megadott engedélyezési listán kívüli IP-cím kapcsolódni próbál a PLC elérési pontjához. |
| Érvénytelen írás | Írás csak olvasható vagy nem létező regiszterbe; célérték kívül a 0–100 tartományon; vezérlésengedélyezés értéke nem 0 vagy 1. Egyetlen kísérlet is jelzést váltson ki, elutasított kérés esetén is. |
| Ismétlődő protokollhibák | Ugyanattól a klienstől legalább 5 hibás olvasás, hibás írás, nem támogatott funkció vagy a várt 1-től eltérő Unit ID érkezik gördülő 10 másodperc alatt. |
| Hibás Modbus-fejléc | Az MBAP protocol ID nem 0, vagy a length mező kívül esik a 2–254 tartományon. Azonnali jelzés, mert a jelenlegi PLC-kód az adott kapcsolat feldolgozását blokkolja. |
| Szokatlan vezérlési változás | Aktív üzemben, előre engedélyezett tesztműveleten kívül a PLC elfogadja a vezérlés kikapcsolását; vagy legalább 5 tényleges célértékváltoztatást fogad el gördülő 10 másodperc alatt. |
| Túlzott kérési gyakoriság | Egy kliens gördülő 1 másodperces kérési rátája legalább 3 másodpercig meghaladja az ellenőrzött normál üzemben meghatározott referencia háromszorosát. Csak alkalmazási kéréseket számoljon, TCP-újraküldéseket és válaszokat ne. |
| Kommunikációs kiesés | Korábban működő, aktív lekérdezés mellett 5 másodpercig nincs sikeres Modbus-kérés–válasz. Feltétele az előre beállított, legfeljebb 1 másodperces normál lekérdezési időköz. |
| Szélsőséges vízszint | Friss visszaolvasásokban a vízszint folyamatosan legalább 2 másodpercig 10% alatt vagy 90% felett van. |
| Ellentmondó folyamatállapot | Legalább két egymást követő, a négy regisztert együtt tartalmazó sikeres olvasás kikapcsolt vezérlést és működő pumpát jelez. |

**Regiszterek:** MATLAB-cím 1: vízszint, 2: célérték, 3: vezérlésengedélyezés, 4: pumpaállapot. Csak a 2-es és 3-as írható. A hálózati címek rendre 0, 1, 2, 3.

**Értékelés:** a kérés elküldését és annak elfogadását különböztesse meg. Elavult vagy hiányzó adatokból ne állapítson meg folyamatállapotot. Egy fennálló hibára egy riasztást adjon, a helyreállást külön jelezze. Minden beavatkozást és engedélyezett tesztet naplózzon.

**Küszöbök:** a fenti idő-, gyakoriság- és szinthatárok konfigurálható induló javaslatok, normál üzemi mérés és csapategyeztetés alapján véglegesítendők.
