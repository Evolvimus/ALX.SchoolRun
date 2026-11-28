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
## Arena:    A Arena-Gitter (zwei auf gleicher Höhe bilden eine Arena)   Y Spawner (Staubmäuse in 3 Wellen)
##           X Boss „Der Kopierer“ (steht in einer Arena)
## Sonst:    P Start   T Übungsscheibe
##
## Alles, was „steht“ (S F C f < > w T D _ |), kommt in die Zelle direkt über seiner Standfläche.

const T := 45

## Kapitel und ihre Level in Spielreihenfolge. Neues Level: Szene anlegen und hier eintragen.
## kind: "tutorial", "normal", "challenge" (optional, braucht Medaillen aus dem Kapitel) oder "boss"
const CHAPTERS := [
	{ "title": "Einführung", "levels": [
		{ "scene": "res://levels/tutorial.tscn", "kind": "tutorial" },
	] },
	{ "title": "Kapitel 1 · Klassentrakt", "levels": [
		{ "scene": "res://levels/westfluegel.tscn", "kind": "normal" },
		{ "scene": "res://levels/klassenzimmer.tscn", "kind": "normal" },
		{ "scene": "res://levels/treppenhaus.tscn", "kind": "normal" },
		{ "scene": "res://levels/nachsitzen.tscn", "kind": "challenge", "medals": 6 },
		{ "scene": "res://levels/kopierer.tscn", "kind": "boss" },
	] },
	{ "title": "Kapitel 2 · Sport & Naturwissenschaften", "levels": [
		{ "scene": "res://levels/turnhalle.tscn", "kind": "normal" },
		{ "scene": "res://levels/physikraum.tscn", "kind": "normal" },
	] },
]

## Tutorial-Aufgaben je Level-ID: { at = Spalte, ab der sie erscheint, text, touch (Text am Handy, optional),
##                                  done = { type = ... }, opens_door }
##   done.type: "col" (Spalte erreicht), "leaves" (Anzahl Blätter), "checkpoint", "defeat" (Gegnerart, "" = Übungsscheibe),
##              "timer" (Millisekunden), "goal"
const TUTORIALS := {
	"tutorial": [
		{ "at": 0, "text": "Willkommen am ALX!\nLaufe mit {LAUFEN} nach rechts.", "touch": "Willkommen am ALX!\nSchieb den Stick links nach rechts.", "done": { "type": "col", "col": 6 } },
		{ "at": 5, "text": "Spring mit {SPRINGEN} über die Lücke.", "touch": "Tipp auf den Sprung-Knopf\nund spring über die Lücke.", "done": { "type": "col", "col": 12 } },
		{ "at": 12, "text": "Halte {SPRINGEN} gedrückt:\nJe länger, desto höher springst du.", "touch": "Halte den Sprung-Knopf gedrückt:\nJe länger, desto höher springst du.", "done": { "type": "col", "col": 18 } },
		{ "at": 18, "text": "Sammle die goldenen Ginkgoblätter!", "done": { "type": "leaves", "count": 9 } },
		{ "at": 27, "text": "Ein Setzling! Lauf hindurch:\nNach einem Fehlversuch geht es hier weiter.", "done": { "type": "checkpoint" } },
		{ "at": 30, "text": "Hau die Übungsscheibe um: {HIEB}", "touch": "Hau die Übungsscheibe um:\nTipp auf den Hieb-Knopf.", "done": { "type": "defeat", "kind": "" }, "opens_door": true },
		{ "at": 36, "text": "Eine Staubmaus!\nSpring drauf oder schlag mit {HIEB} zu.", "touch": "Eine Staubmaus! Spring drauf\noder hau mit dem Hieb-Knopf zu.", "done": { "type": "defeat", "kind": "mouse" }, "opens_door": true },
		{ "at": 46, "text": "Jeden neuen Gegner findest du\nim Gegner-Lexikon im Menü.", "done": { "type": "timer", "ms": 3500 } },
		{ "at": 49, "text": "Blaue Turnmatten federn dich hoch!", "done": { "type": "col", "col": 58 } },
		{ "at": 58, "text": "Bring deine Blätter zum großen Ginkgo!", "done": { "type": "goal" } },
	],
}

## Eingelesene Level: { id, name, bg, par, map (PackedStringArray), hints ([x, y, text] in Pixeln), tutorial?,
##                      chapter, slot, kind, medals_needed }
static var list: Array[Dictionary] = []


static func load_all() -> void:
	list.clear()
	for ci in CHAPTERS.size():
		var slot := 0
		for entry in CHAPTERS[ci]["levels"]:
			if not ResourceLoader.exists(entry["scene"]):
				push_warning("Level fehlt: " + entry["scene"])
				continue
			slot += 1
			var lv := _read(entry["scene"])
			lv["chapter"] = ci
			lv["slot"] = slot
			lv["kind"] = entry["kind"]
			lv["medals_needed"] = int(entry.get("medals", 0))
			list.append(lv)


static func index_of(id: String) -> int:
	for i in list.size():
		if list[i]["id"] == id:
			return i
	return -1


static func completed(i: int) -> bool:
	return Save.data["best_times"].has(list[i]["id"])


static func medal_count(level_id: String) -> int:
	var n := 0
	for v in (Save.data["medals"].get(level_id, {}) as Dictionary).values():
		if v:
			n += 1
	return n


## Medaillen aller Level eines Kapitels (das Herausforderungslevel selbst zählt nicht mit)
static func chapter_medals(chapter: int) -> int:
	var n := 0
	for lv in list:
		if lv["chapter"] == chapter and lv["kind"] != "challenge":
			n += medal_count(lv["id"])
	return n


## Freigeschaltet? Tutorial und das erste Level von Kapitel 1 immer. Sonst muss das vorige Pflichtlevel
## (bzw. das letzte Level des vorigen Kapitels) geschafft sein. Herausforderungen brauchen Medaillen.
static func is_unlocked(i: int) -> bool:
	if Nav.args.has("unlock-all"):
		return true
	var lv := list[i]
	if lv["kind"] == "tutorial" or (lv["chapter"] == 1 and lv["slot"] == 1):
		return true
	if lv["kind"] == "challenge":
		return chapter_medals(lv["chapter"]) >= lv["medals_needed"]
	for j in range(i - 1, -1, -1):
		if list[j]["kind"] != "challenge" and list[j]["kind"] != "tutorial":
			return completed(j)
	return true


## Welches Level kommt nach i? Das nächste Pflichtlevel (Herausforderungen überspringt „Weiter“), sonst -1.
static func next_index(i: int) -> int:
	for j in range(i + 1, list.size()):
		if list[j]["kind"] != "challenge":
			return j
	return -1


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


## Anzeige-Name: „Tutorial“ oder Kapitel-Level, z. B. „1-3“.
static func label(i: int) -> String:
	var lv := list[i]
	if lv["kind"] == "tutorial":
		return "Tutorial"
	return "%d-%d" % [lv["chapter"], lv["slot"]]


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
