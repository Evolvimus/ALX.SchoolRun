# ALX SchoolRun 🏃‍♂️🎓

2D-Jump-&-Run des Abikomitees. Spielbare Charaktere sind 20 Lehrer:innen, die über **einmalig einlösbare Codes** auf den ALX-Sammelkarten freigeschaltet werden. Nach der Kartenaktion kann man sie im Shop mit verdienten **Ginkgo-Talern** kaufen. Es gibt keine Echtgeld-Käufe und keine Werbung.

**Plattformen:** Browser (PC) · Android-App (Play Store, über Capacitor)
**Technik:** Phaser 3 + TypeScript + Vite · Supabase (Codes) · Capacitor (App)

## Lokal starten
```bash
npm install
npm run dev        # http://localhost:5173
```
Ohne `.env` läuft das Spiel im **TESTMODUS**: Jeder formal gültige Code funktioniert einmal pro Gerät.
Fester Testcode für **Herr Hammer**: `ALX-HAMM-ER2N` (nur im Testmodus, auf dem Server gibt es ihn nicht).

## Lehrerbilder einfügen
1. Bild als PNG (freigestellt, transparenter Hintergrund, Hochformat ca. 200×300 px) nach `public/characters/lehrer01.png` usw. legen.
2. ID in `public/characters/manifest.json` eintragen, z. B. `["lehrer01","lehrer02"]`.
3. Name, Fach, Seltenheit und Fähigkeit in `src/data/characters.ts` anpassen.

Fähigkeiten: `doubleJump`, `speed`, `highJump`, `glide`, `smash` (Kisten zerschlagen).

### Herr Hammer (lehrer01)
Erster echter Lehrer. Bis das Foto da ist, hat er eine eigene Pixel-Figur (Werkkittel, Schutzbrille, Schnurrbart) in `src/scenes/pixelArt.ts` unter `LOOKS`. Statt des Lineals schwingt er einen **Hammer**: doppelter Schaden (Bücherwurm und Laubbläser fallen mit einem Hieb) und er zertrümmert Kartons. Echte Karten-Codes für ihn: `npm run codes -- 50 lehrer01`.

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

## Das Spiel

Das Ginkgoblatt (Schullogo) ist der rote Faden: Der alte Ginkgo hat seine goldenen Blätter verloren, sie liegen in der ganzen Schule.

- **Goldene Blätter** sammeln, am Levelende fliegen sie in die Krone und der Baum wird golden.
- **Drei grüne Blätter** sind die Leben. Ein Treffer lässt eines welken.
- **Setzlinge** sind Checkpoints. Nach einem Sturz und nach „Nachsitzen“ geht es dort weiter.
- Belohnung am Ende: Blätter + Bonus für besiegte Gegner + 5 Taler pro übrigem Leben.

### Level
| Nr. | Level | Neu darin |
|---|---|---|
| Tutorial | Erster Schultag | Laufen, Springen, Blätter, Setzling, Lineal, erste Staubmaus. Schritt-für-Schritt-Aufgaben, Türen öffnen sich erst nach der Aufgabe. Kein „Nachsitzen“ möglich. |
| 1 | Klassenzimmer | Staubmaus, Papierflieger, Bücherwurm, Raupe |
| 2 | Turnhalle | Basketball, Matten, Laubbläser |
| 3 | Physikraum | Magnet, Bunsenbrenner |

Level werden in `src/data/levels.ts` gebaut (Legende steht oben in der Datei). Die Tutorial-Aufgaben stehen beim Tutorial-Level unter `tutorial`.

Beim allerersten „Spielen“ startet direkt das Tutorial, danach geht es zur Levelauswahl.

### Gegner-Lexikon
Jeder Gegner, der zum ersten Mal ins Bild kommt, wird im **Gegner-Lexikon** (Hauptmenü) freigeschaltet, mit kurzer Einblendung „Neu im Lexikon“. Unentdeckte Gegner erscheinen dort als schwarze Silhouette. Für entdeckte Gegner zeigt das Lexikon Verhalten, Tipp, Fundort und wie oft man sie besiegt hat. Die Texte stehen in `src/data/bestiary.ts`.

### Gegner (keine Menschen)
| Gegner | Verhalten | Konter |
|---|---|---|
| Staubmaus | läuft Streife, flitzt bei Nähe los (vorher „!“) | Lineal oder draufspringen |
| Papierflieger | Dreierformation quer durch den Raum | wegschlagen oder ausweichen |
| Bücherwurm | raschelt, taucht dann aus einem von mehreren Löchern auf | zwei Hiebe, solange er draußen ist |
| Raupe | frisst ein großes Blatt (5 Blätter wert), sobald man in die Nähe kommt | schnell hin: Lineal oder draufspringen |
| Basketball | springt im festen Takt | unten durch, oder von oben als Sprungbrett |
| Laubbläser | bläst im Takt und schiebt die Figur weg | Pause abwarten, zwei Hiebe |
| Magnet | zieht an (blau) und stößt ab (rot) | bei Blau springen |
| Bunsenbrenner | aus – Zündflamme – Stichflamme | im Aus-Takt vorbei |

Der Code dazu liegt in `src/game/enemies.ts`, die Spielfigur in `src/game/Player.ts`.

## Steuerung
PC: ←/→ oder A/D laufen · Leertaste/↑/W springen (kurz tippen = kleiner Sprung) · **X oder J = Lineal-Hieb** · M = Ton an/aus · Esc = Levelauswahl
Handy: Touch-Buttons (links, rechts, X, Sprung)

## Testen
```bash
npm run build && npx vite preview --port 4173
```
- `http://localhost:4173/?level=2` startet direkt Level 2 (0 = Tutorial).
- `http://localhost:4173/?level=2&bot=1` lässt einen **Testbot** das Level spielen. Er prüft, ob ein Level lösbar ist. Das Ergebnis steht in `window.__alx`.
