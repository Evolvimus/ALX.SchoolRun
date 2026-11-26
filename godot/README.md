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
| ↑ / ↓ an der Sprossenwand | Steuerkreuz | Klettern. Mit Richtung + Sprung seitlich abspringen |
| X oder J | X / B | Lineal-Hieb bzw. Hammer |
| M | | Ton an/aus |
| Esc | Start | Zurück |

Auf Handy und Tablet erscheinen Touch-Buttons (am PC zum Testen mit `--touch`).

## Inhalt
- **Tutorial „Erster Schultag“** + 4 Level: Der Westflügel (langes Musterlevel über zwei Stockwerke), Klassenzimmer, Turnhalle, Physikraum
- **8 Gegner** mit Gegner-Lexikon (`scripts/game/enemies.gd`, Texte in `scripts/data/bestiary.gd`)
- **Ginkgo-Thema**: goldene Blätter sammeln, Setzlinge als Checkpoints, grüne Blätter als Leben, Ginkgo wird am Ziel golden
- **Figuren** (`scripts/data/chars.gd`): Herr Hammer (Legendär, Hammer, Sprüche, Zopf), Admin Hammer (Mythisch, goldener Hammer, Doppelsprung, Glitzer-Spur), 19 Platzhalter
- **Alle Figuren sind gleich groß** (90 px = zwei Kacheln). Detailfiguren (36×60 Pixel) werden 1,5-fach, einfache Figuren (12×20) 4,5-fach gezeigt. Bei 1280×720 und 1920×1080 bleiben alle Pixel scharf.
- **Karten-Codes**, **Sammelalbum**, **Lehrerzimmer-Shop** (nur Spielwährung)

## Spielregeln
- **Leben:** je nach Stufe 5, 3 oder 1 grünes Blatt. Ein **Setzling** füllt sie wieder auf.
- **Fehlversuch:** Sind alle Leben weg oder stürzt man ab, geht es sofort am letzten Setzling weiter. Der Zähler läuft mit, ein „Game Over“ gibt es nicht.
- **Schwierigkeitsstufen** (Umschalter in der Levelauswahl): *Entspannt* (5 Leben, nach einem Sturz geht es direkt daneben weiter), *Normal* (3 Leben), *Abiprüfung* (1 Leben, 50 % mehr Taler).
- **Geheimhefte:** bis zu 3 pro Level, an versteckten oder schweren Stellen. Einmal gefunden, bleiben sie gefunden.
- **Medaillen** pro Level: *Alle Blätter*, *Ohne Treffer* (kein Treffer, kein Fehlversuch), *Zielzeit*. Jede neue Medaille bringt 25 Taler.

## Mechaniken
| Kachel | Name | Verhalten |
|---|---|---|
| `~` | Bröckelbrett | wackelt kurz und fällt, wächst nach 3 Sekunden nach |
| `-` | Rollwagen | liegt in einer Bodenlücke, fährt 5 Kacheln nach rechts und zurück, hält an beiden Enden kurz |
| `\|` | Aufzug | steht auf dem Boden, fährt 4 Kacheln hoch und zurück. Aufspringen! |
| `H` | Sprossenwand | klettern mit ↑/↓; das obere Ende trägt wie ein Brett |
| `_` + `D` | Druckplatte + Tür | die Platte öffnet die nächste Tür rechts; nach dem Runtergehen bleibt sie 4–7 Sekunden offen |
| `M` | Turnmatte | schleudert hoch |
| `=` | Brett | von unten durchspringbar |
| `B` | Karton | nur Herr Hammer zertrümmert ihn (gut für Geheimwege) |

## Level bauen (Kachel-Editor)
Level sind Szenen in `levels/`. So entsteht ein neues:
1. Im Dateibaum eine Levelszene duplizieren (z. B. `westfluegel.tscn` → `mensa.tscn`) und öffnen.
2. Knoten **Tiles** anklicken, unten das Fenster **TileMap** öffnen, Kachel wählen und malen. Rechte Maustaste löscht.
   - Das Level beginnt bei Zelle (0, 0) oben links. Die untersten drei Zeilen sind normalerweise Boden (`#`).
   - Alles, was steht (Setzling, Tür, Gegner, Aufzug …), kommt in die Zelle direkt über seinem Boden.
   - Der Hintergrund wiederholt sich alle 9 Zeilen nach oben, ein Stockwerk ist also 9 Kacheln hoch.
3. Im Inspektor des obersten Knotens **Level**: Titel, Hintergrund und Zielzeit einstellen.
4. Hinweistexte: unter **Hints** Label-Knoten anlegen und hinschieben. Platzhalter: `{LAUFEN}` `{SPRINGEN}` `{HOCH}` `{HIEB}` `{WAFFE}`.
5. Die Szene in `scripts/data/levels.gd` in die Liste `SCENES` eintragen (die Reihenfolge dort ist die Reihenfolge im Spiel).
6. Testen: `godot --path godot -- --level=N` und mit `--bot --quit` prüfen, ob es lösbar ist.

Die Bedeutung aller Kacheln steht oben in `scripts/data/levels.gd`. Im Kachelsatz sind sie in dieser Reihenfolge:
Boden, Brett, Regal, Labortisch, Turnkasten, Karton, Bröckelbrett, Rollwagen, Aufzug, Sprossenwand, Matte, Reißzwecken, Druckplatte, Tür, Blatt, Geheimheft, Setzling, Ziel-Ginkgo, Raupe, Staubmaus, Papierflieger, Wurmloch, Basketball, Laubbläser links, Laubbläser rechts, Magnet, Bunsenbrenner, Start, Übungsscheibe.

Der Kachelsatz (`levels/tileset.tres`) und die Start-Level wurden mit `godot --path godot -- --build-levels` aus `tools/level_seeds.gd` erzeugt. **Vorsicht:** `--build-levels --force` überschreibt alle Levelszenen mit den Textkarten.

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
| `--difficulty=X` | `entspannt`, `normal` oder `abi` |
| `--touch` | Touch-Buttons am PC anzeigen |
| `--screen=NAME` | direkt `menu`, `levels`, `album`, `redeem`, `shop` oder `lexikon` öffnen |
| `--bot --quit` | ein Testbot spielt das Level und gibt `BOT_RESULT …` aus |

`./tests/run_bots.sh` lässt den Bot alle Level mit drei Figuren spielen und meldet, ob alles lösbar ist.
Der Bot läuft immer nach rechts, klettert Sprossenwände hoch, fährt Rollwagen und Aufzüge. Geheimwege und Wege nach links prüft er nicht.
