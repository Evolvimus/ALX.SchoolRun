# ALX SchoolRun – Godot-Version

2D-Jump-&-Run des Abikomitees in **Godot 4.3** (GDScript). Alle Grafiken und Sounds werden beim Start per Code erzeugt, es gibt keine fremden Dateien außer der Schrift „Press Start 2P“ (SIL Open Font License, siehe `fonts/`).

## Projekt öffnen
1. Godot **4.3** (oder neuer 4.x) installieren: https://godotengine.org/download
2. Repository holen und auf den Branch wechseln:
   ```bash
   git clone https://github.com/evolvimus/alx.schoolrun.git
   cd alx.schoolrun
   git checkout claude/festive-cannon-b4uewr
   ```
3. Godot starten → **Importieren** → im Ordner `godot/` die Datei `project.godot` auswählen → **Importieren & Bearbeiten**.
4. Oben rechts auf ▶ (**F5**) drücken.

Ohne Editor aus dem Terminal: `godot --path godot`

## Steuerung
| PC | Gamepad | Aktion |
|---|---|---|
| ← → oder A D | Stick / Steuerkreuz | Laufen |
| Leertaste, ↑, W | A | Springen (kurz tippen = kleiner Sprung) |
| X oder J | X / B | Lineal-Hieb bzw. Hammer |
| M | | Ton an/aus |
| Esc | Start | Zurück |

Auf Handy und Tablet erscheinen Touch-Buttons (am PC zum Testen mit `--touch`).

## Inhalt
- **Tutorial „Erster Schultag“** + 3 Level: Klassenzimmer, Turnhalle, Physikraum (`scripts/data/levels.gd`)
- **8 Gegner** mit Gegner-Lexikon (`scripts/game/enemies.gd`, Texte in `scripts/data/bestiary.gd`)
- **Ginkgo-Thema**: goldene Blätter sammeln, Setzlinge als Checkpoints, grüne Blätter als Leben, Ginkgo wird am Ziel golden
- **Figuren** (`scripts/data/chars.gd`): Herr Hammer (Legendär, Hammer, Sprüche, Zopf), Admin Hammer (Mythisch, goldener Hammer, Doppelsprung, Glitzer-Spur), 19 Platzhalter
- **Alle Figuren sind gleich groß** (90 px = zwei Kacheln). Detailfiguren (36×60 Pixel) werden 1,5-fach, einfache Figuren (12×20) 4,5-fach gezeigt. Bei 1280×720 und 1920×1080 bleiben alle Pixel scharf.
- **Karten-Codes**, **Sammelalbum**, **Lehrerzimmer-Shop** (nur Spielwährung)

## Echte Lehrerbilder
Ein Bild als `characters/<id>.png` (z. B. `characters/lehrer02.png`) ersetzt die Pixel-Figur automatisch. Besser: Aussehen als `look` in `scripts/data/chars.gd` eintragen, dann zeichnet das Spiel eine Detailfigur wie bei Herrn Hammer (`_draw_detailed` in `scripts/autoload/art.gd`).

## Karten-Codes und Server
- Ohne Server läuft das Spiel im **Testmodus**. Feste Testcodes: `ALX-HAMM-ER2N` (Herr Hammer), `ALX-MYTH-HAYH` (Admin Hammer). Jeder andere gültige Code schaltet einmal pro Gerät einen zufälligen Lehrer frei.
- Echte Codes erzeugen (im Hauptordner): `npm run codes -- 50 lehrer01`
- Server: Supabase wie im Haupt-README einrichten, dann `config/backend.cfg.example` nach `config/backend.cfg` kopieren und URL + anon key eintragen (die Datei wird nicht committet).

## Exportieren (App, Web, PC)
Vorlagen für **Android, iOS, Web, Windows, macOS** stehen in `export_presets.cfg`. Vorher in Godot unter *Editor → Export-Vorlagen verwalten* die Vorlagen für 4.3 herunterladen.
- **Android (Play Store)**: Android SDK + Java einrichten (*Editor → Editoreinstellungen → Export → Android*), Release-Keystore eintragen, als `.aab` exportieren.
- **iOS (App Store)**: auf einem Mac mit Xcode, Apple-Team-ID im iOS-Preset eintragen.
- **Web**: ergibt `build/web/index.html` für den PC-Browser.

## Testen
Startoptionen (nach `--`), z. B. `godot --path godot -- --level=2 --char=lehrer01 --unlock-all`:

| Option | Wirkung |
|---|---|
| `--level=N` | direkt Level N starten (0 = Tutorial) |
| `--char=ID` | mit dieser Figur spielen, z. B. `lehrer01`, `lehrer01m` |
| `--unlock-all` | alle Figuren freischalten |
| `--fresh` | leerer Spielstand, nichts wird gespeichert |
| `--touch` | Touch-Buttons am PC anzeigen |
| `--screen=NAME` | direkt `menu`, `levels`, `album`, `redeem`, `shop` oder `lexikon` öffnen |
| `--bot --quit` | ein Testbot spielt das Level und gibt `BOT_RESULT …` aus |

`./tests/run_bots.sh` lässt den Bot alle Level mit drei Figuren spielen und meldet, ob alles lösbar ist.
