# Git és GitHub – egyszerű útmutató a CsPL1_L003 csapatnak

**A közös projekt:** [bajnoczky/CsPL1_L003](https://github.com/bajnoczky/CsPL1_L003)

Ez az útmutató azoknak is szól, akik most használják először a Gitet. Nem kell minden parancsot megjegyezned: kövesd a lépéseket a megfelelő sorrendben.

## Gyors áttekintés: hogyan dolgozunk?

1. **Letöltöd a projektet** a saját gépedre (ezt csak az első alkalommal kell megtenned).
2. **Munka előtt frissítesz**, hogy nálad is a legújabb fájlok legyenek.
3. **Elvégzed és elmented a módosításaidat** a gépeden.
4. **Rögzíted a változtatásokat** a Gittel (`add`, majd `commit`).
5. **Feltöltöd a GitHubra** (`push`), hogy a többiek is megkapják őket.

> **Fontos:** Egyelőre mindannyian a közös `main` ágon dolgozunk. Beszéljük meg előre, ki melyik fájlt szerkeszti – különösen a PowerPoint-fájloknál, mert ezek módosításait a Git nem tudja egyszerűen összevonni.

## 1. Első használat – ezt csak egyszer kell megcsinálni

### 1.1. Telepítés és hozzáférés

- Telepítsd a [Gitet](https://git-scm.com/downloads). Windows alatt a **Git Bash** terminált ajánljuk.
- Legyen [GitHub-fiókod](https://github.com/), és fogadd el a projektmeghívást, ha kaptál ilyet.
- A terminált megnyithatod a Start menüből (**Git Bash**) vagy a VS Code-ban.

### 1.2. Add meg a neved és az e-mail-címed

Másold be a következő két parancsot a terminálba. Az idézőjelek közötti részeket cseréld ki a saját adataidra:

```bash
git config --global user.name "Saját Neved"
git config --global user.email "sajat@email.hu"
```

Ezek az adatok a későbbi mentéseidhez (commitjaidhoz) tartoznak. Az e-mail lehet a GitHub-fiókodhoz társított cím vagy a GitHub által biztosított privát `noreply` cím is.

### 1.3. Töltsd le a projektet

Először lépj abba a mappába, **ahová a projektet szeretnéd letölteni**. Például Git Bash-ben a Dokumentumok mappába:

```bash
cd ~/Documents
```

Ezután futtasd:

```bash
git clone https://github.com/bajnoczky/CsPL1_L003.git
cd CsPL1_L003
```

- A `git clone` létrehoz egy **CsPL1_L003** nevű mappát a projekt fájljaival.
- A `cd CsPL1_L003` belép ebbe a mappába.
- **A további Git-parancsokat ebben a projektmappában futtasd.**

A letöltést (`clone`) **nem kell minden alkalommal megismételni**. Legközelebb csak nyisd meg a már meglévő mappát a terminálban.

Ha a GitHub bejelentkezést kér, jelentkezz be a projekthez hozzáférő fiókoddal. Ha a projekt privát, hozzáférés nélkül a letöltés vagy a feltöltés nem fog sikerülni.

## 2. Minden alkalommal, mielőtt dolgozni kezdesz

Nyisd meg a terminált a **CsPL1_L003** mappában, majd írd be:

```bash
git status
```

Ellenőrizd, hogy a `main` ágon vagy-e (`On branch main`). Ha azt is látod, hogy `nothing to commit, working tree clean`, akkor nincs függőben lévő helyi módosításod.

**Ha tiszta a munkamappád**, töltsd le a többiek legfrissebb változtatásait:

```bash
git pull --ff-only
```

Ez frissíti a helyi projektedet, ha a módosítások egyszerűen átvehetők. A `--ff-only` biztonsági óvintézkedés: összetettebb eltérésnél a parancs megáll, ahelyett hogy automatikusan összevonást készítene.

**Ha a `git status` módosított vagy új fájlokat mutat**, ne indítsd el rögtön a `pull` parancsot. Előbb tisztázd, hogy szeretnéd-e megtartani ezeket a változtatásokat. Ha bizonytalan vagy, kérj segítséget; ne töröld őket csak azért, hogy frissíteni tudj.

## 3. Ha elkészültél: mentés és feltöltés

Először mentsd el a szerkesztett fájlokat a programban (például PowerPointban vagy VS Code-ban).

### 3.1. Nézd meg, mi változott

```bash
git status
```

### 3.2. Válaszd ki, mit szeretnél rögzíteni

**Ha a projektmappában lévő összes változtatást szeretnéd hozzáadni:**

```bash
git add .
```

Ezt a **CsPL1_L003 gyökérmappájából** futtasd. A parancs az új, módosított és törölt fájlok változásait is előkészítheti. Csak akkor használd, ha tényleg minden érintett fájlt fel szeretnél tölteni.

**Ha csak egyetlen fájlt szeretnél hozzáadni**, például ezt a PPT-t:

```bash
git add '#L03_csoportbemutato.pptx'
```

> A fájlnév elején lévő `#` miatt fontos az idézőjel! Enélkül a Git Bash megjegyzésként kezeli a parancs hátralévő részét. Ha a fájlnévben szóköz van, az idézőjel szintén segít.

Ellenőrizd újra:

```bash
git status
```

A `Changes to be committed` rész mutatja, mely fájlok kerülnek a következő mentésbe.

### 3.3. Készíts egy mentési pontot (commit)

```bash
git commit -m "Csoportbemutato PPT elso valtozat"
```

A `commit` **csak a saját gépeden** rögzíti az előkészített változtatásokat. Az idézőjelek közé röviden azt írd, ami valóban megváltozott.

### 3.4. Töltsd fel a GitHubra (push)

```bash
git push
```

A `push` a helyi commitjaidat feltölti a közös GitHub-repositoryba. **Ettől válnak a többiek számára elérhetővé a változtatásaid.**

A `git push origin main` is használható, de ebben a projektben általában elég a rövidebb `git push`, mert a helyi `main` ág a távoli `origin/main` ágat követi.

A végén nézd meg a [GitHubon](https://github.com/bajnoczky/CsPL1_L003), hogy megjelent-e a módosításod.

## 4. A négy legfontosabb parancs – puska

Ha **már letöltötted a projektet**, a munkamenet menete általában ez:

**Munka előtt** (ha a `git status` szerint minden tiszta):

```bash
git pull --ff-only
```

**Munka után** (ha minden változtatást fel akarsz tölteni):

```bash
git status
git add .
git status
git commit -m "Rovid, ertheto leiras"
git push
```

**Mit jelentenek?**

| Parancs | Mire való? |
| --- | --- |
| `git status` | Megmutatja, mi változott, és mi vár mentésre. |
| `git pull --ff-only` | Frissíti a helyi projektet a GitHubon lévő változtatásokkal, ha ez egyszerűen megtehető. |
| `git add .` | Előkészíti az aktuális mappából kiinduló változtatásokat a következő commitra. |
| `git commit -m "..."` | Helyben rögzíti az előkészített változtatásokat. |
| `git push` | Feltölti a helyi commitokat a GitHubra. |

## 5. Gyakori hibák és megoldásuk

### `git add all` → `pathspec 'all' did not match any files`

A Git ilyenkor egy `all` nevű fájlt keres. Ha minden változtatást hozzá szeretnél adni, ezt használd:

```bash
git add .
```

### `git add #L03_csoportbemutato.pptx` → nem történik semmi

A `#` miatt a Git Bash megjegyzésnek tekinti a szöveget. Írd idézőjelek közé:

```bash
git add '#L03_csoportbemutato.pptx'
```

### `nothing added to commit but untracked files present`

Van új fájlod, de még nem adtad hozzá a következő commithoz. Használd a `git add` parancsot, majd próbáld újra a `git commit`-ot.

### `nothing to commit, working tree clean`

Jelenleg nincs új, committá alakítható helyi változtatás. Ez **nem hiba**.

### A `push` hibát jelez (például `rejected` vagy `fetch first`)

Valószínűleg valaki időközben feltöltött új változtatásokat, és a közös ág már előrébb jár. **Ne használd a `git push --force` parancsot!** Ha a saját gépeden is van új commit, a helyzet nem mindig oldható meg egy egyszerű `pull --ff-only` paranccsal. Ilyenkor jelezd a csapatban, és egyeztessük az összevezetést.

### A `pull` hibát jelez, vagy ütközést (`conflict`) látsz

Ne próbáld találomra törölni vagy felülírni a fájlokat. A saját és a mások által készített változtatásokat külön kell kezelni. Kérj segítséget, és add meg, mit írt ki a terminál.

### A GitHub nem engedi a feltöltést (`permission denied`, `403`)

Ellenőrizd, hogy a megfelelő GitHub-fiókkal jelentkeztél-e be, elfogadtad-e a meghívást, és van-e írási jogosultságod a repositoryhoz.

## 6. Közös munkára vonatkozó szabályok

- **Munkakezdés előtt frissíts** (`git pull --ff-only`), ha nincs függőben lévő saját módosításod.
- **Egyeztessük előre, ki melyik fájlon dolgozik.** Ugyanazt a PPTX-fájlt lehetőleg ne szerkesszük egyszerre.
- **Kisebb, kész változtatásokat rögzíts**, beszédes commitüzenettel. Például `Csoportbemutato PPT elso valtozat`, ne csak `update`.
- **Feltöltés előtt nézd meg a `git status` kimenetét**, nehogy véletlenül ideiglenes vagy személyes fájl kerüljön a repositoryba.
- **Ne használj `push --force`-ot a közös `main` ágon.** Ha hiba történik, inkább kérj segítséget.
- Ha később több embernek kell tartósan, párhuzamosan fejlesztenie, külön ágakat (branch-eket) is bevezethetünk. **Egyelőre nem szükséges ezzel foglalkoznod.**

---

**Röviden:** `pull` = mások frissítéseinek letöltése, `add` = változtatások kiválasztása, `commit` = helyi mentési pont, `push` = feltöltés a közös GitHubra.
