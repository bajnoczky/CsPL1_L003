# Git használata a CsPL1_L003 repositoryban

A projekt GitHub-címe: [bajnoczky/CsPL1_L003](https://github.com/bajnoczky/CsPL1_L003).

A közös `main` ágon dolgozunk; egyeztessük, ki melyik feladatot és fájlokat módosítja.

## 1. Első alkalommal

- Telepítsd a [Git-et](https://git-scm.com/downloads), és legyen GitHub-fiókod.
- Nyiss terminált; Windowson a PowerShell, a Git Bash vagy a VS Code terminálja is használható.

Állítsd be, milyen név és e-mail jelenjen meg a commitjaidon.

```bash
git config --global user.name "Saját Neved"
git config --global user.email "sajat@email.hu"
```

Ha még nincs helyi példányod, klónozd a repositoryt:

```bash
git clone https://github.com/bajnoczky/CsPL1_L003.git
cd CsPL1_L003
```

A `clone` letölti a projektet egy új mappába; ezt csak egyszer kell megtenni. A `cd` belép a létrejött mappába. **A további Git-parancsokat ebben a mappában futtasd.**

Ha már klónoztad a projektet, csak nyisd meg a saját `CsPL1_L003` mappádat a terminálban. Klónozás után a `main` ágon dolgozhatsz.

Ha klónozáskor vagy az első pushnál böngészős bejelentkezés nyílik meg, lépj be azzal a GitHub-fiókkal, amellyel elfogadtad a repository meghívását.


## 2. Minden munkamenet elején

```bash
git status
git pull --ff-only
```

A `status` megmutatja az aktuális ágat és a helyi változtatásokat. Ha a `main` ágon vagy, és `working tree clean` látható, frissíts a `pull` paranccsal, majd kezdheted a munkát. A `pull` letölti és beépíti a többiek frissítéseit.

Ha maradt helyi módosításod, előbb fejezd be és commitold a 3. pont szerint, utána frissíts. Ha a pull hibát jelez, ne folytasd vakon: nézd meg a 4. pontot. A `--ff-only` megáll, ha a saját és a közös történet már külön is bővült.

## 3. Saját változtatások mentése és feltöltése

Szerkeszd és mentsd el a fájlokat, majd ellenőrizd, hogy a változtatás működik.
pl.
```bash
git status
git add all
git commit -m "<változtatás rövid leírásaa>"
git push
```



## 4. Csapatszabályok

- Egyeztessük, ki melyik fájlon vagy feladaton dolgozik.
- Munka előtt pull, egy kész és ellenőrzött kisebb változtatás után commit és push.
- A commitüzenet mondja el, mi változott: például „README kiegészítése a futtatási lépésekkel”, ne csak „update”.
- Ha nagyobb hosszabb munkát kell csinálni, többen egyszerre dolgozni használjunk külön branchet (talán nem lesz szükséges, ha mégis updateljük ezt a doksit a "how to"-val)
