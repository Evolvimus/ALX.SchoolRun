class_name Levels
extends RefCounted
## Die Level sind Szenen in res://levels/ und werden im Godot-Kachel-Editor gemalt (siehe level_def.gd).
## Beim Start liest das Spiel jede Szene ein und macht daraus eine Textkarte (1 Zeichen = 1 Kachel à 45 px).
##
## Gelände:  # Boden   = Brett (von unten durchspringbar)   R Bücherregal   L Labortisch   K Turnkasten
##           B Karton (Hammer zertrümmert ihn)   M Matte (federt)   ^ Reißzwecken
##           ~ Bröckelbrett   - Rollwagen (liegt in einer Bodenlücke, fährt 5 Kacheln nach rechts und zurück)
##           | Aufzug (steht auf dem Boden, fährt 4 Kacheln hoch)
##           H Sprossenwand   _ Druckplatte (öffnet die nächste Tür rechts für ein paar Sekunden)   D Tür
## Ginkgo:   c Blatt   S Setzling (Checkpoint)   F großer Ginkgo (Ziel)   C großes Blatt mit Raupe   h Geheimheft
## Gegner:   m Staubmaus   e Papierflieger-Schwarm   w Wurmloch (benachbarte Löcher = ein Bücherwurm)
##           o Basketball  < > Laubbläser (bläst nach links/rechts)   N Magnet   f Bunsenbrenner
## Sonst:    P Start   T Übungsscheibe
##
## Alles, was „steht“ (S F C f < > w T D _ |), kommt in die Zelle direkt über seiner Standfläche.

const T := 45

## Reihenfolge der Level im Spiel. Neues Level: Szene anlegen und hier eintragen.
const SCENES := [
	"res://levels/tutorial.tscn",
	"res://levels/westfluegel.tscn",
	"res://levels/klassenzimmer.tscn",
	"res://levels/turnhalle.tscn",
	"res://levels/physikraum.tscn",
]

## Tutorial-Aufgaben je Level-ID: { at = Spalte, ab der sie erscheint, text, done = { type = ... }, opens_door }
##   done.type: "col" (Spalte erreicht), "leaves" (Anzahl Blätter), "checkpoint", "defeat" (Gegnerart, "" = Übungsscheibe),
##              "timer" (Millisekunden), "goal"
const TUTORIALS := {
	"tutorial": [
		{ "at": 0, "text": "Willkommen am ALX!\nLaufe mit {LAUFEN} nach rechts.", "done": { "type": "col", "col": 6 } },
		{ "at": 5, "text": "Spring mit {SPRINGEN} über die Lücke.", "done": { "type": "col", "col": 12 } },
		{ "at": 12, "text": "Halte {SPRINGEN} gedrückt:\nJe länger, desto höher springst du.", "done": { "type": "col", "col": 18 } },
		{ "at": 18, "text": "Sammle die goldenen Ginkgoblätter!", "done": { "type": "leaves", "count": 9 } },
		{ "at": 27, "text": "Ein Setzling! Lauf hindurch:\nNach einem Fehlversuch geht es hier weiter.", "done": { "type": "checkpoint" } },
		{ "at": 30, "text": "Hau die Übungsscheibe um: {HIEB}", "done": { "type": "defeat", "kind": "" }, "opens_door": true },
		{ "at": 36, "text": "Eine Staubmaus!\nSpring drauf oder schlag mit {HIEB} zu.", "done": { "type": "defeat", "kind": "mouse" }, "opens_door": true },
		{ "at": 46, "text": "Jeden neuen Gegner findest du\nim Gegner-Lexikon im Menü.", "done": { "type": "timer", "ms": 3500 } },
		{ "at": 49, "text": "Blaue Turnmatten federn dich hoch!", "done": { "type": "col", "col": 58 } },
		{ "at": 58, "text": "Bring deine Blätter zum großen Ginkgo!", "done": { "type": "goal" } },
	],
}

## Eingelesene Level: { id, name, bg, par, map (PackedStringArray), hints ([x, y, text] in Pixeln), tutorial? }
static var list: Array[Dictionary] = []


static func load_all() -> void:
	list.clear()
	for path in SCENES:
		if ResourceLoader.exists(path):
			list.append(_read(path))
		else:
			push_warning("Level fehlt: " + path)


static func _read(path: String) -> Dictionary:
	var root: Node = (load(path) as PackedScene).instantiate()
	var tiles: TileMapLayer = root.get_node("Tiles")
	var used := tiles.get_used_rect()
	var w := maxi(1, used.end.x)
	var h := maxi(1, used.end.y)
	var rows: Array = []
	for y in h:
		var row: Array[String] = []
		row.resize(w)
		row.fill(" ")
		rows.append(row)
	for cell in tiles.get_used_cells():
		if cell.x < 0 or cell.y < 0:
			continue
		var data := tiles.get_cell_tile_data(cell)
		if data:
			rows[cell.y][cell.x] = str(data.get_custom_data("ch"))
	var map := PackedStringArray()
	for row in rows:
		map.append("".join(row))
	var hints := []
	if root.has_node("Hints"):
		for l in root.get_node("Hints").get_children():
			if l is Label:
				hints.append([l.position.x, l.position.y, l.text])
	var id := path.get_file().get_basename()
	var level := {
		"id": id, "name": root.get("title"), "bg": root.get("background"), "par": float(root.get("par_seconds")),
		"map": map, "hints": hints,
	}
	if TUTORIALS.has(id):
		level["tutorial"] = TUTORIALS[id]
	root.free()
	return level


## Anzeige-Name: „Tutorial“ oder die Levelnummer.
static func label(i: int) -> String:
	return "Tutorial" if list[i].has("tutorial") else str(i)


## Wie viele Blätter es im Level insgesamt zu holen gibt (großes Blatt der Raupe = 5).
static func count_leaves(level: Dictionary) -> int:
	return _count(level, "c") + 5 * _count(level, "C")


static func count_hefte(level: Dictionary) -> int:
	return _count(level, "h")


static func _count(level: Dictionary, ch: String) -> int:
	var n := 0
	for row in level["map"]:
		n += (row as String).count(ch)
	return n
