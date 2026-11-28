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
| Esc | Start | Pause (im Spiel), sonst zurück |

**Handy und Tablet** (am PC zum Testen mit `--touch`, die Maus ist dann der Finger):
- **Linke Bildschirmhälfte: Stick.** Wo der Daumen aufsetzt, erscheint er; zieht man weiter, wandert er mit. Links/rechts laufen, nach oben an der Sprossenwand klettern (springt nicht), nach unten ducken.
- **Rechts: zwei große Knöpfe.** Springen (außen, groß) und Hieb (mit dem Waffen-Symbol der Figur). Man muss sie nicht genau treffen: jede Berührung rechts zählt für den näheren Knopf, und man kann mit dem Daumen von einem zum anderen rollen.
- Oben rechts ist der **Pause-Knopf**. Geht die App in den Hintergrund (Anruf, Home-Taste), pausiert das Spiel von selbst.
- Bei einem Treffer vibriert das Handy kurz. Kerben/Notches werden berücksichtigt; auf Breitbild-Handys nutzt das Spiel die ganze Breite.

## Aufbau und Design
- **Intro** beim Start: „an evolvimus production“ und „by Nikola Kostic“ (`scripts/screens/intro.gd`, Tippen überspringt).
- **Hauptmenü:** großer „Spielen“-Button, der direkt mit dem nächsten offenen Level weitermacht, darunter Kacheln für Schulplan, Täglich, Rangliste, Erfolge, Figuren, Lexikon, Code und Shop; oben rechts Einstellungen und Ton; rechts die gewählte Figur.
- **Schulplan:** ein Kapitel pro Seite (wischen, Pfeile oder ← →), Stationen als Weg, unten Infos und „Spielen“. Schwierigkeit oben rechts als Umschalter.
- **Figuren / Shop / Lexikon:** links groß die angetippte Figur bzw. der Gegner, rechts das Raster.
- **Im Spiel:** schlanke Anzeigen oben (Leben, Blätter, Hefte, Zeit, Pause), Levelname kurz eingeblendet, Pausenmenü (Weiter, Neu starten, Schulplan, **Hauptmenü**, Ton, Einstellungen).
- Alle Farben, Buttons, Panels, Chips und Karten stehen zentral in `scripts/ui/ui.gd`. Die Menüs sind für 960×540 gebaut und werden auf breiteren Bildschirmen mittig gesetzt.

## Musik
Jedes Kapitel, das Menü und die Bosse haben ein eigenes Chiptune-Stück (`scripts/autoload/music.gd`). Die Stücke werden per Code komponiert (Tempo, Tonart, Akkordfolge, Stil) und beim Start nach und nach erzeugt, ohne Ruckeln und ohne Audiodateien. Lautstärke von Musik und Effekten getrennt in den Einstellungen.

## Einstellungen
Musik, Effekte, Größe der Touch-Knöpfe (klein/mittel/groß), Linkshänder-Layout (Stick rechts, Knöpfe links), Vibration, Geist der Bestzeit, Intro an/aus und der Name in der Rangliste (`scripts/ui/settings_panel.gd`). Erreichbar im Hauptmenü (Zahnrad) und im Pausenmenü.

## Rangliste (für alle)
- Eine gemeinsame Rangliste für alle Spieler*innen, nicht nach Stufen getrennt. Drei Ansichten: **Gesamt** (Punkte aus allen Leveln), **Level** (Bestzeit je Level) und **Heute** (Tagesaufgabe).
- Punkte je Level: Blätter × 10 + Medaillen × 100 + Tempo-Bonus (schneller als 1,5 × Zielzeit). Gezählt wird das beste Ergebnis je Level.
- **Namen werden zufällig erzeugt** („Flinker Bücherwurm 42“, `scripts/data/names.gd`), es gibt keine freie Eingabe. So landen weder echte Namen noch Beleidigungen in der Liste. Der Server lehnt andere Namen ab. In den Einstellungen kann man einen neuen Namen würfeln.
- Server: `supabase/migrations/002_leaderboard.sql` im Supabase-SQL-Editor ausführen (nach `001_codes.sql`). Im Testmodus speichert das Spiel die eigenen Werte lokal und zeigt Beispiel-Einträge.

## Tagesaufgabe
Jeden Tag dasselbe Level für alle, mit einer Zusatzregel (nur ein Leben, ohne Setzlinge, Turbo, Blätterjagd oder klassisch; `scripts/data/daily.gd`). Die Bestzeit des Tages kommt in die Rangliste „Heute“, die erste geschaffte Tagesaufgabe am Tag bringt 100 Taler. Das Level muss dafür nicht freigeschaltet sein.

## Geist der Bestzeit
Nach einer neuen Bestzeit läuft beim nächsten Versuch eine durchsichtige Figur den besten Lauf nach (`scripts/game/ghost.gd`). Wer schneller ist, schlägt den Geist (Erfolg „Geisterjäger*in“). In den Einstellungen abschaltbar.

## Erfolge und Sammel-Belohnungen
- 20 Erfolge (`scripts/data/achievements.gd`), z. B. „Kein Kratzer“ (Boss ohne Treffer), „Forscher*in“ (alle Gegner entdeckt), „Stammgast“ (7 Tagesaufgaben). Neue Erfolge werden eingeblendet; Übersicht im Menü unter „Erfolge“.
- **Sammel-Belohnungen** (`scripts/data/rewards.gd`): 5 Lehrer → 250 Taler, 10 Lehrer → Bonuslevel „Lehrerzimmer“, 20 Lehrer → goldener Rahmen für alle Karten.

## Fach-Fähigkeiten
Neben Doppelsprung, Sprinter, Supersprung, Gleiten und Kisten zerschlagen gibt es jetzt:
- **Schallwelle** (z. B. Musik): Der Hieb schickt eine Welle weit nach vorne, die Gegner trifft.
- **Zirkel-Bumerang** (z. B. Mathe): Der Hieb wirft einen Zirkel, der hin- und zurückfliegt.
- **Heft-Kompass** (z. B. Erdkunde): Ein Pfeil oben zeigt zum nächsten noch nicht gefundenen Geheimheft und wie viele Kacheln es entfernt ist.

Vorschläge je Fach stehen in `Chars.SUBJECT_ABILITY`. Wenn die echten Lehrer eingetragen werden, einfach `"ability"` passend setzen.

## Lehrer-Zitate
Die Sprechblasen-Sprüche stehen in **`data/zitate.txt`**, eine Zeile pro Spruch: `lehrer05: Das kommt in der Klausur dran!` (Zeilenumbruch mit `\n`). Die Datei kann das Abikomitee ohne Programmierkenntnisse bearbeiten.

## Event-Hüte
Zeitlich begrenzte Accessoires in **`data/events.cfg`**: Name, Start- und Enddatum und welche Hüte es gibt (Partyhut, Krone, Zylinder, Abi-Hut). Wer während eines Events ein Level schafft, bekommt den Hut und behält ihn. Getragen wird er im Figuren-Bildschirm (gilt für alle Figuren). Eingetragen sind „Start der Kartenaktion“ (bis 31.12.2026), Mottowoche und Abiball 2027 – die Daten bitte anpassen.

## Inhalt
- **Tutorial „Erster Schultag“**
- **Kapitel 1 · Klassentrakt** (Musterkapitel):
  - 1-1 Der Westflügel (zwei Stockwerke, alle neuen Mechaniken)
  - 1-2 Klassenzimmer (lang, Kampfarena, Kartonwand, Doppelsprung-Sims)
  - 1-3 Treppenhaus (drei Stockwerke nach oben, Aufzug, Kartonwand)
  - 1-4 Nachsitzen (Herausforderung, braucht 6 Medaillen aus Kapitel 1)
  - 1-5 **Boss: Der Kopierer**
- **Kapitel 2 · Sport & Naturwissenschaften:** Turnhalle, Physikraum (noch die kurzen Level, werden später ausgebaut)
- **Schulplan** statt Levelauswahl: Kapitel als Wege, Medaillen und Hefte pro Station
- **9 Gegner** inkl. Boss, mit Gegner-Lexikon (`scripts/game/enemies.gd`, Texte in `scripts/data/bestiary.gd`)
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

## Freischalten
- Tutorial und 1-1 sind immer offen. Jedes weitere Pflichtlevel braucht das vorige.
- Kapitel 2 öffnet sich nach dem Boss von Kapitel 1.
- **Herausforderungen** (z. B. 1-4 Nachsitzen) sind optional und brauchen Medaillen aus ihrem Kapitel. „Weiter“ überspringt sie.
- **Bonuslevel** (B-1 Lehrerzimmer) öffnen sich mit der Sammel-Belohnung ab 10 Lehrern.

## Kampfarenen und Boss
- Zwei **Arena-Gitter** (`A`) auf gleicher Höhe bilden eine Arena. Wer hineinläuft, wird eingesperrt.
- **Spawner** (`Y`) in der Arena werfen 3 Wellen Staubmäuse ab (in der letzten Welle doppelt so viele). Danach gehen die Gitter auf, es gibt 10 Bonus-Taler.
- Steht der **Boss** (`X`) in einer Arena, startet der Bosskampf mit Lebensleiste oben. Die Gitter öffnen sich, wenn er besiegt ist.
- **Der Kopierer:** wirft Papierblätter, schickt Papierwellen über den Boden (überspringen!) und überhitzt dann. Nur wenn der Deckel offen ist und es grell leuchtet, nimmt er Schaden: Lineal 1, Hammer 2, Draufspringen 2. Ab halber Energie ist er schneller und greift doppelt an.
- Nach einem Fehlversuch wird die Arena zurückgesetzt (Gegner weg, Boss wieder voll).

## Fähigkeiten-Wege (Sammelkarten lohnen sich)
- **Kartonwände** (`B`): nur Herr Hammer zertrümmert sie. Dahinter liegen Geheimhefte.
- **Hohe Simse**: nur mit Doppelsprung erreichbar (z. B. Admin Hammer).
- So hat jede Lehrer-Fähigkeit im Level einen eigenen Nutzen, und das Tauschen der Karten lohnt sich.

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
| `A` | Arena-Gitter | zwei auf gleicher Höhe = Arena |
| `Y` | Spawner | wirft in einer Arena 3 Wellen Staubmäuse ab |
| `X` | Boss „Der Kopierer“ | muss in einer Arena stehen |

## Level bauen (Kachel-Editor)
Level sind Szenen in `levels/`. So entsteht ein neues:
1. Im Dateibaum eine Levelszene duplizieren (z. B. `westfluegel.tscn` → `mensa.tscn`) und öffnen.
2. Knoten **Tiles** anklicken, unten das Fenster **TileMap** öffnen, Kachel wählen und malen. Rechte Maustaste löscht.
   - Das Level beginnt bei Zelle (0, 0) oben links. Die untersten drei Zeilen sind normalerweise Boden (`#`).
   - Alles, was steht (Setzling, Tür, Gegner, Aufzug …), kommt in die Zelle direkt über seinem Boden.
   - Der Hintergrund wiederholt sich alle 9 Zeilen nach oben, ein Stockwerk ist also 9 Kacheln hoch.
3. Im Inspektor des obersten Knotens **Level**: Titel, Hintergrund und Zielzeit einstellen.
4. Hinweistexte: unter **Hints** Label-Knoten anlegen und hinschieben. Platzhalter: `{LAUFEN}` `{SPRINGEN}` `{HOCH}` `{HIEB}` `{WAFFE}`.
5. Die Szene in `scripts/data/levels.gd` in die Liste `CHAPTERS` beim passenden Kapitel eintragen, mit `kind` = `normal`, `challenge` (plus `medals`) oder `boss`. Die Reihenfolge dort ist die Reihenfolge im Spiel.
6. Testen: `godot --path godot -- --level=N` und mit `--bot --quit` prüfen, ob es lösbar ist.

Die Bedeutung aller Kacheln steht oben in `scripts/data/levels.gd`. Im Kachelsatz sind sie in dieser Reihenfolge:
Boden, Brett, Regal, Labortisch, Turnkasten, Karton, Bröckelbrett, Rollwagen, Aufzug, Sprossenwand, Matte, Reißzwecken, Druckplatte, Tür, Blatt, Geheimheft, Setzling, Ziel-Ginkgo, Raupe, Staubmaus, Papierflieger, Wurmloch, Basketball, Laubbläser links, Laubbläser rechts, Magnet, Bunsenbrenner, Start, Übungsscheibe, Arena-Gitter, Spawner, Boss.

Der Kachelsatz (`levels/tileset.tres`) und die Start-Level wurden mit `godot --path godot -- --build-levels` aus `tools/level_seeds.gd` und den Textkarten in `tools/seeds/*.txt` erzeugt. Eine Textkarte ist einfach die Levelkarte als Text (ein Zeichen pro Kachel). Wer lieber tippt als malt, kann so ein Level auch als Text schreiben und mit `--build-levels --only=<id>` in eine Szene verwandeln.
**Vorsicht:** `--build-levels --force` und `--only=<id>` überschreiben die betroffenen Levelszenen mit den Textkarten. Änderungen, die im Editor gemacht wurden, gehen dabei verloren.

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

## iOS und TestFlight (iPhone + iPad)
Das geht nur auf einem **Mac mit Xcode**. Die Exportvorlage „iOS“ ist für iPhone und iPad eingestellt (ab iOS 14), das App-Icon liegt in `icons/ios_1024.png`.

**Einmalig vorbereiten**
1. **Apple Developer Program** (99 €/Jahr) für das Konto, unter dem die App erscheinen soll. Die **Team ID** steht unter developer.apple.com → Account → Membership.
2. **Xcode** aus dem Mac App Store installieren, einmal öffnen, unter *Settings → Accounts* mit dieser Apple-ID anmelden.
3. **Godot 4.3** installieren und im Editor unter *Editor → Export-Vorlagen verwalten* die Vorlagen für 4.3 herunterladen.
4. In **App Store Connect** (appstoreconnect.apple.com) unter *Apps → +* eine neue App anlegen: Plattform iOS, Name „ALX SchoolRun“, Bundle-ID `de.alx.schoolrun`.
   - Ist die Bundle-ID schon vergeben, eine eigene wählen (z. B. `de.<schule>.schoolrun`) und in `export_presets.cfg` beim iOS-Preset bei `application/bundle_identifier` eintragen.
   - Die Bundle-ID muss vorher unter developer.apple.com → *Identifiers* angelegt sein (Xcode macht das beim ersten Signieren meist automatisch).
5. Optional für automatisches Hochladen: in App Store Connect unter *Benutzer und Zugriff → Integrationen → App Store Connect API* einen Schlüssel (Rolle „App-Manager“) anlegen. Die Datei `AuthKey_<KEY_ID>.p8` nach `~/.appstoreconnect/private_keys/` legen und Key-ID und Issuer-ID notieren.

**Bauen und hochladen** (im Ordner `godot/`)
```bash
TEAM_ID=ABCDE12345 ./tools/testflight.sh
# oder gleich mit Upload:
TEAM_ID=ABCDE12345 ASC_KEY_ID=XYZ123 ASC_ISSUER_ID=1234-abcd-... ./tools/testflight.sh
```
Ohne API-Schlüssel die entstandene `build/ios/ALX-SchoolRun.ipa` mit der App **Transporter** hochladen.

**In TestFlight verteilen**
- Nach 10–30 Minuten erscheint der Build in App Store Connect unter **TestFlight**.
- **Interne Tester** (bis 100 Personen mit Zugang zum Developer-Team) können sofort testen.
- **Externe Tester** (bis 10.000, z. B. per öffentlichem Link für die Schule) brauchen eine kurze Beta-Prüfung durch Apple (meist 1 Tag) sowie eine Beschreibung und eine Kontakt-E-Mail.
- Die Tester installieren die App **TestFlight** aus dem App Store und nehmen die Einladung an. Die App läuft auf iPhone und iPad.

Die Frage nach Verschlüsselung (Exportbestimmungen) ist mit `ITSAppUsesNonExemptEncryption = false` schon beantwortet.

## Testen
Startoptionen (nach `--`), z. B. `godot --path godot -- --level=2 --char=lehrer01 --unlock-all`:

| Option | Wirkung |
|---|---|
| `--level=N` | direkt Level N starten (0 = Tutorial) |
| `--char=ID` | mit dieser Figur spielen, z. B. `lehrer01`, `lehrer01m` |
| `--unlock-all` | alle Figuren freischalten |
| `--fresh` | leerer Spielstand, nichts wird gespeichert |
| `--difficulty=X` | `entspannt`, `normal` oder `abi` |
| `--touch` | Touch-Steuerung am PC anzeigen (Maus = Finger) |
| `--screen=NAME` | direkt `intro`, `menu`, `levels`, `album`, `redeem`, `shop`, `lexikon`, `rangliste`, `erfolge` oder `einstellungen` öffnen |
| `--no-intro` | ohne Intro ins Menü |
| `--daily` | mit `--level=N`: als Tagesaufgabe spielen (heutige Zusatzregel) |
| `--music-timing` | meldet, wann jedes Musikstück fertig erzeugt ist |
| `--pause-test` | im Spiel nach 1 s das Pausenmenü öffnen |
| `--touch-probe` | mit `--level=1 --touch`: simulierter Finger testet Stick und Sprung, gibt `TOUCH_RESULT …` aus |
| `--bot --quit` | ein Testbot spielt das Level und gibt `BOT_RESULT …` aus |

`./tests/run_bots.sh` lässt den Bot alle Level mit drei Figuren spielen und meldet, ob alles lösbar ist.
Der Bot läuft immer nach rechts, klettert Sprossenwände hoch, fährt Rollwagen und Aufzüge, kämpft in Arenen und besiegt den Kopierer. Geheimwege und Wege nach links prüft er nicht.
