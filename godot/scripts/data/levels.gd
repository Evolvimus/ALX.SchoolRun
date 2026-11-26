class_name Levels
extends RefCounted
## Level als Textkarte (1 Zeichen = 1 Kachel à 45 px, 12 Zeilen; Boden ab Zeile 9, man steht in Zeile 8).
##
## Gelände:  # Boden   = Brett (von unten durchspringbar)   R Bücherregal   L Labortisch   K Turnkasten
##           B Karton   M Matte (federt)   ^ Reißzwecken
## Ginkgo:   c Blatt   S Setzling (Checkpoint)   F großer Ginkgo (Ziel)   C großes Blatt mit Raupe
## Gegner:   m Staubmaus   e Papierflieger-Schwarm   w Wurmloch (benachbarte Löcher = ein Bücherwurm)
##           o Basketball  < > Laubbläser (bläst nach links/rechts)   N Magnet   f Bunsenbrenner
## Sonst:    P Start   T Übungsscheibe   D Tür (öffnet sich, wenn eine Tutorial-Aufgabe erledigt ist)
##
## Alles, was „steht“ (S F C f < > w T D), kommt in die Zelle direkt über seiner Standfläche.
##
## Tutorial-Aufgaben: { at = Spalte, ab der sie erscheint, text, done = { type = ... }, opens_door }
##   done.type: "col" (Spalte erreicht), "leaves" (Anzahl Blätter), "checkpoint", "defeat" (Gegnerart, "" = Übungsscheibe),
##              "timer" (Millisekunden), "goal"
##   Platzhalter im Text: {LAUFEN} {SPRINGEN} {HIEB}

const T := 45
const ROWS := 12

static var list: Array[Dictionary] = []


static func _static_init() -> void:
	list.assign([
		{
			"id": "tutorial", "name": "Erster Schultag", "bg": "bg-school", "hints": [],
			"tutorial": [
				{ "at": 0, "text": "Willkommen am ALX!\nLaufe mit {LAUFEN} nach rechts.", "done": { "type": "col", "col": 6 } },
				{ "at": 5, "text": "Spring mit {SPRINGEN} über die Lücke.", "done": { "type": "col", "col": 12 } },
				{ "at": 12, "text": "Halte {SPRINGEN} gedrückt:\nJe länger, desto höher springst du.", "done": { "type": "col", "col": 18 } },
				{ "at": 18, "text": "Sammle die goldenen Ginkgoblätter!", "done": { "type": "leaves", "count": 9 } },
				{ "at": 27, "text": "Ein Setzling! Lauf hindurch:\nNach einem Sturz geht es hier weiter.", "done": { "type": "checkpoint" } },
				{ "at": 30, "text": "Hau die Übungsscheibe um: {HIEB}", "done": { "type": "defeat", "kind": "" }, "opens_door": true },
				{ "at": 36, "text": "Eine Staubmaus!\nSpring drauf oder schlag mit {HIEB} zu.", "done": { "type": "defeat", "kind": "mouse" }, "opens_door": true },
				{ "at": 46, "text": "Jeden neuen Gegner findest du\nim Gegner-Lexikon im Menü.", "done": { "type": "timer", "ms": 3500 } },
				{ "at": 49, "text": "Blaue Turnmatten federn dich hoch!", "done": { "type": "col", "col": 58 } },
				{ "at": 58, "text": "Bring deine Blätter zum großen Ginkgo!", "done": { "type": "goal" } },
			],
			"map": build(68, [[9, 10]], [
				["P", 2, 8], ["c", 9, 6], ["c", 10, 6],
			] + at("R", [[16, 8], [16, 7], [17, 8], [17, 7]])
			+ at("c", [[20, 8], [21, 8], [22, 8], [23, 7], [24, 6], [25, 7], [26, 8]])
			+ [["S", 29, 8], ["T", 33, 8], ["D", 35, 8], ["m", 41, 8], ["D", 46, 8], ["M", 52, 8]]
			+ line("=", 54, 57, 4) + line("c", 54, 57, 3)
			+ [["F", 63, 8]]),
		},
		{
			"id": "klassenzimmer", "name": "Klassenzimmer", "bg": "bg-school",
			"hints": [
				[3, 5, "LAUFEN: {LAUFEN}\nSPRINGEN: {SPRINGEN}"],
				[29, 5, "{HIEB}: {WAFFE}"],
				[72, 4, "ES RASCHELT ..."],
			],
			"map": build(126, [[24, 26], [52, 54], [97, 99]],
				[["P", 2, 8]] + line("c", 6, 9, 8)
				# Regal-Treppe
				+ at("R", [[12, 8], [13, 8], [13, 7], [14, 8], [14, 7]]) + at("c", [[12, 7], [13, 6], [14, 6]])
				+ line("c", 18, 20, 8) + line("c", 24, 26, 6)
				# erste Staubmaus
				+ [["m", 34, 8]] + line("c", 37, 39, 8)
				+ [["S", 42, 8]]
				+ line("=", 44, 47, 6) + at("c", [[45, 5], [46, 5]])
				+ line("=", 49, 51, 4) + line("c", 49, 51, 3) + [["c", 53, 6]]
				# Reißzwecken, Karton, Papierflieger
				+ at("c", [[57, 8], [58, 8]]) + at("^", [[59, 8], [60, 8]]) + at("c", [[59, 6], [60, 6]])
				+ [["B", 66, 8], ["c", 66, 7], ["e", 78, 4], ["S", 70, 8]]
				# Bücherwurm im Regal
				+ line("R", 77, 81, 8) + at("w", [[78, 7], [80, 7], [84, 8]]) + at("c", [[77, 7], [79, 7], [81, 7]])
				+ line("R", 87, 89, 8) + line("R", 87, 89, 7) + [["C", 88, 6]]
				+ at("c", [[91, 8], [92, 8]]) + [["m", 94, 8], ["c", 98, 6], ["S", 102, 8]]
				# Finale
				+ at("R", [[106, 8], [107, 8], [107, 7]]) + line("=", 109, 112, 5) + line("c", 109, 112, 4)
				+ [["m", 111, 8]] + at("^", [[115, 8], [116, 8]]) + at("c", [[115, 6], [116, 6]]) + [["e", 117, 4]]
				+ [["F", 121, 8]]),
		},
		{
			"id": "turnhalle", "name": "Turnhalle", "bg": "bg-gym",
			"hints": [
				[14, 4, "VON OBEN FEDERT DER BALL"],
				[41, 4, "LAUBBLÄSER: PAUSE ABWARTEN,\nDANN ZUSCHLAGEN"],
			],
			"map": build(134, [[28, 31], [60, 62], [90, 94]],
				[["P", 2, 8]] + line("c", 5, 8, 8)
				+ at("K", [[11, 8], [12, 8], [12, 7]]) + at("c", [[11, 7], [12, 6]])
				+ [["o", 17, 4]] + line("c", 16, 18, 8) + [["m", 22, 8]]
				# Matte über die erste Lücke
				+ [["M", 26, 8]] + at("c", [[28, 3], [29, 2], [30, 2], [31, 3]])
				+ [["S", 36, 8]] + at("c", [[39, 8], [40, 8]])
				# Laubbläser
				+ [["<", 50, 8]] + line("c", 45, 48, 8)
				+ at("K", [[54, 8], [55, 8], [55, 7], [56, 8], [56, 7], [56, 6]]) + at("c", [[54, 7], [55, 6], [56, 5]]) + [["c", 61, 6]]
				+ [["o", 66, 4], ["o", 70, 3]] + at("c", [[66, 8], [68, 8], [70, 8]])
				+ [["S", 74, 8]]
				# Raupe hoch oben
				+ [["M", 77, 8]] + line("=", 79, 81, 5) + [["C", 80, 4], ["m", 84, 8]]
				+ [["M", 88, 8]] + line("=", 91, 93, 5) + line("c", 91, 93, 4)
				# Rückenwind in die Reißzwecken
				+ [[">", 98, 8]] + line("c", 101, 103, 8) + at("^", [[105, 8], [106, 8]]) + at("c", [[105, 6], [106, 6]])
				+ [["S", 109, 8]]
				+ at("K", [[112, 8], [112, 7]]) + [["o", 116, 3]] + at("c", [[114, 8], [116, 8], [118, 8]]) + [["m", 121, 8]]
				+ [["F", 128, 8]]),
		},
		{
			"id": "physikraum", "name": "Physikraum", "bg": "bg-lab",
			"hints": [
				[11, 4, "BRENNER: AUF DIE PAUSE WARTEN"],
				[17, 6, "MAGNET: BEI BLAU SPRINGEN"],
			],
			"map": build(140, [[22, 26], [60, 64]],
				[["P", 2, 8]] + line("c", 5, 7, 8)
				+ at("L", [[10, 8], [11, 8]]) + at("c", [[10, 7], [11, 7]]) + [["f", 15, 8]]
				# Magnet über der Lücke
				+ [["N", 24, 3]] + line("c", 23, 25, 5)
				+ [["S", 30, 8], ["f", 35, 8], ["c", 37, 8], ["f", 39, 8]]
				+ line("L", 44, 47, 8) + at("L", [[46, 7], [47, 7]]) + [["f", 45, 7]] + at("c", [[44, 7], [46, 6], [47, 6]])
				+ at("c", [[50, 8], [51, 8]]) + [["m", 54, 8]]
				+ [["N", 62, 3]] + line("c", 61, 63, 5)
				+ [["S", 68, 8]]
				# Bücherwurm im Boden
				+ at("w", [[73, 8], [77, 8], [81, 8]]) + at("c", [[72, 8], [75, 8], [79, 8], [83, 8]])
				+ line("L", 86, 88, 8) + line("L", 86, 88, 7) + [["C", 87, 6]]
				+ [["f", 92, 8], ["m", 96, 8]]
				# Magnet über Reißzwecken
				+ line("^", 100, 103, 8) + [["N", 102, 3]] + at("c", [[101, 5], [102, 5]])
				+ [["S", 108, 8]]
				# Brenner-Parcours
				+ [["f", 113, 8], ["c", 114, 8], ["f", 116, 8], ["c", 117, 8], ["f", 119, 8], ["c", 121, 8]]
				+ at("L", [[125, 8], [126, 8]]) + at("c", [[125, 7], [126, 7]])
				+ [["F", 133, 8]]),
		},
	])


## Baut eine Karte aus Lücken im Boden und einzelnen Objekten [Zeichen, Spalte, Zeile].
static func build(width: int, gaps: Array, items: Array) -> PackedStringArray:
	var rows: Array = []
	for r in ROWS:
		var row: Array[String] = []
		for c in width:
			var gap := false
			for g in gaps:
				if c >= g[0] and c <= g[1]:
					gap = true
			row.append("#" if r >= 9 and not gap else " ")
		rows.append(row)
	for it in items:
		var ch: String = it[0]
		var col: int = it[1]
		var row: int = it[2]
		assert(rows[row][col] == " ", "Level-Fehler: Zelle %d,%d ist doppelt belegt" % [col, row])
		rows[row][col] = ch
	var out := PackedStringArray()
	for row in rows:
		out.append("".join(row))
	return out


static func line(ch: String, from: int, to: int, row: int) -> Array:
	var out := []
	for c in range(from, to + 1):
		out.append([ch, c, row])
	return out


static func at(ch: String, cells: Array) -> Array:
	var out := []
	for cell in cells:
		out.append([ch, cell[0], cell[1]])
	return out


## Anzeige-Name: „Tutorial“ oder die Levelnummer.
static func label(i: int) -> String:
	return "Tutorial" if list[i].has("tutorial") else str(i)


## Wie viele Blätter es im Level insgesamt zu holen gibt (großes Blatt der Raupe = 5).
static func count_leaves(level: Dictionary) -> int:
	var n := 0
	for row in level["map"]:
		for ch in row:
			if ch == "c":
				n += 1
			elif ch == "C":
				n += 5
	return n
