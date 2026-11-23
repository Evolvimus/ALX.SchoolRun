# ALX SchoolRun 🏃‍♂️🎓

2D-Jump-&-Run des Abikomitees. Spielbare Charaktere sind 20 Lehrer:innen, die über **einmalig einlösbare Codes** auf den ALX-Sammelkarten freigeschaltet werden. Nach der Kartenaktion kann man sie im Shop mit verdienten **ALX-Talern** kaufen. Es gibt keine Echtgeld-Käufe und keine Werbung.

**Plattformen:** Browser (PC) · Android-App (Play Store, über Capacitor)
**Technik:** Phaser 3 + TypeScript + Vite · Supabase (Codes) · Capacitor (App)

## Lokal starten
```bash
npm install
npm run dev        # http://localhost:5173
```
Ohne `.env` läuft das Spiel im **TESTMODUS**: Jeder formal gültige Code funktioniert einmal pro Gerät.

## Lehrerbilder einfügen
1. Bild als PNG (freigestellt, transparenter Hintergrund, Hochformat ca. 200×300 px) nach `public/characters/lehrer01.png` usw. legen.
2. ID in `public/characters/manifest.json` eintragen, z. B. `["lehrer01","lehrer02"]`.
3. Name, Fach, Seltenheit und Fähigkeit in `src/data/characters.ts` anpassen.

Fähigkeiten: `doubleJump`, `speed`, `highJump`, `glide`, `smash` (Kisten zerschlagen).

## Codes erzeugen (einmalig gültig)
```bash
npm run codes -- 50                    # 50 Codes pro Lehrer (alle 20)
npm run codes -- 30 lehrer01,lehrer05  # nur bestimmte Lehrer
```
Ergebnis in `codes-output/` (wird **nicht** committet):
- `codes.csv` ist die Liste für den Kartendruck. **Geheim halten!**
- `insert.sql` enthält nur Hashes und wird im Supabase SQL Editor ausgeführt.

## Server (Supabase) einrichten
1. Kostenloses Projekt auf supabase.com anlegen.
2. `supabase/migrations/001_codes.sql` im SQL Editor ausführen.
3. `codes-output/insert.sql` ausführen.
4. `.env` aus `.env.example` anlegen und URL + anon key eintragen.
5. Shop nach der Kartenaktion öffnen:
   `update public.settings set value = 'true' where key = 'shop_open';`

Codes liegen nur als SHA-256-Hash in der DB. Jeder Code kann genau einmal eingelöst werden (atomar in `redeem_code`). Freischaltungen sind an eine zufällige Spieler-ID gebunden.

## Android-App bauen
Benötigt Android Studio.
```bash
npx cap add android     # einmalig
npm run android:sync    # nach jeder Änderung
npm run android:open    # in Android Studio öffnen -> signiertes AAB für den Play Store
```

## Steuerung
PC: ←/→ oder A/D, Springen mit Leertaste/↑/W, Esc = Menü · Handy: Touch-Buttons
