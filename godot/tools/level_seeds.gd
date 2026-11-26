class_name LevelSeeds
extends RefCounted
## Startfassungen der Level als Textkarten. tools/level_builder.gd macht daraus Szenen in res://levels/.
## Danach werden die Szenen im Godot-Editor weiterbearbeitet – diese Datei ist nur der Ausgangspunkt.
## Legende: siehe scripts/data/levels.gd


static func all() -> Array:
	return [_tutorial(), _westfluegel(), _klassenzimmer(), _turnhalle(), _physikraum()]


## Baut eine Karte: die untersten drei Zeilen sind Boden (außer in den Lücken), dazu Objekte [Zeichen, Spalte, Zeile].
static func build(width: int, gaps: Array, items: Array, rows_n := 12) -> PackedStringArray:
	var rows: Array = []
	for r in rows_n:
		var row: Array[String] = []
		for c in width:
			var gap := false
			for g in gaps:
				if c >= g[0] and c <= g[1]:
					gap = true
			row.append("#" if r >= rows_n - 3 and not gap else " ")
		rows.append(row)
	for it in items:
		var ch: String = it[0]
		var col: int = it[1]
		var row: int = it[2]
		assert(rows[row][col] == " " or (rows[row][col] == "#" and ch == " "), "Level-Fehler: Zelle %d,%d ist doppelt belegt (%s)" % [col, row, ch])
		rows[row][col] = ch
	var out := PackedStringArray()
	for row in rows:
		out.append("".join(row))
	return out


## Waagerechte Reihe
static func line(ch: String, from: int, to: int, row: int) -> Array:
	var out := []
	for c in range(from, to + 1):
		out.append([ch, c, row])
	return out


## Senkrechte Reihe
static func column(ch: String, col: int, from: int, to: int) -> Array:
	var out := []
	for r in range(from, to + 1):
		out.append([ch, col, r])
	return out


static func at(ch: String, cells: Array) -> Array:
	var out := []
	for cell in cells:
		out.append([ch, cell[0], cell[1]])
	return out


static func _tutorial() -> Dictionary:
	return {
		"id": "tutorial", "name": "Erster Schultag", "bg": "bg-school", "par": 25.0, "hints": [],
		"map": build(68, [[9, 10]], [
			["P", 2, 8], ["c", 9, 6], ["c", 10, 6],
		] + at("R", [[16, 8], [16, 7], [17, 8], [17, 7]])
		+ at("c", [[20, 8], [21, 8], [22, 8], [23, 7], [24, 6], [25, 7], [26, 8]])
		+ [["S", 29, 8], ["T", 33, 8], ["D", 35, 8], ["m", 41, 8], ["D", 46, 8], ["M", 52, 8]]
		+ line("=", 54, 57, 4) + line("c", 54, 57, 3)
		+ [["F", 63, 8]]),
	}


## Langes Musterlevel über zwei Stockwerke mit allen neuen Mechaniken.
## Erdgeschoss: Boden in Zeile 18, man steht in Zeile 17. Obergeschoss: Boden in Zeile 9, man steht in Zeile 8.
static func _westfluegel() -> Dictionary:
	var items: Array = [["P", 2, 17]] + line("c", 5, 8, 17)
	# --- Abschnitt A: Bröckelbretter
	items += line("~", 13, 17, 18) + line("c", 14, 16, 17) + [["m", 21, 17]]
	items += at("~", [[25, 18], [26, 18], [28, 18], [29, 18], [31, 18]]) + at("c", [[25, 17], [28, 17], [31, 17]])
	items += at("=", [[28, 15], [29, 15]]) + [["h", 29, 14]]
	items += [["S", 34, 17]]
	# --- Abschnitt B: Rollwagen
	items += [["-", 39, 18]] + line("c", 41, 44, 16) + [["m", 50, 17], ["e", 64, 13]]
	items += [["-", 55, 18]] + line("~", 62, 64, 18) + line("c", 62, 64, 17) + [["h", 58, 14]]
	items += [["S", 68, 17]]
	# --- Abschnitt C: über die Sprossenwand ins Obergeschoss
	items += column("H", 77, 9, 17) + column("#", 78, 9, 17)
	for c in range(79, 133):
		if c == 98:
			continue
		items.append(["~" if c >= 100 and c <= 103 else "#", c, 9])
	items += column("H", 98, 9, 17) + column("#", 132, 10, 17)
	items += line("c", 80, 83, 8) + line("R", 86, 88, 8) + [["w", 87, 7], ["w", 92, 8]]
	items += [["_", 96, 8], ["m", 105, 8], ["D", 108, 8], ["S", 112, 8], ["C", 116, 8]] + line("c", 120, 124, 8) + [["e", 128, 4]]
	# unten: Sackgasse mit Geheimheft (man landet hier, wenn man durch die Bröckelbretter fällt)
	items += line("c", 104, 108, 17) + [["m", 115, 17], ["h", 129, 17]]
	# --- Abschnitt D: Finale im Erdgeschoss
	items += line("c", 135, 138, 17) + [["|", 144, 17]]
	for c in range(146, 150):
		items += column("K", c, 14, 17)
	items += line("c", 146, 149, 13) + [["m", 153, 17]]
	items += line("^", 156, 159, 17) + [["S", 162, 17], ["_", 164, 17]] + line("~", 169, 171, 18) + [["e", 172, 13], ["m", 174, 17], ["D", 178, 17]]
	items += [["F", 188, 17]]
	return {
		"id": "westfluegel", "name": "Der Westflügel", "bg": "bg-school", "par": 90.0,
		"hints": [
			[9, 12, "BRÖCKELBRETTER:\nNICHT STEHEN BLEIBEN!"],
			[35, 12, "ROLLWAGEN: AUFSPRINGEN\nUND MITFAHREN"],
			[69, 12, "SPROSSENWAND:\nMIT {HOCH} KLETTERN"],
			[91, 4, "DRUCKPLATTE: DIE TÜR\nBLEIBT NUR KURZ OFFEN!"],
			[137, 12, "AUFZUG: AUFSPRINGEN,\nWENN ER UNTEN IST"],
		],
		"map": build(196, [[13, 17], [25, 31], [39, 45], [55, 64], [169, 171]], items, 21),
	}


static func _klassenzimmer() -> Dictionary:
	return {
		"id": "klassenzimmer", "name": "Klassenzimmer", "bg": "bg-school", "par": 45.0,
		"hints": [
			[3, 5, "LAUFEN: {LAUFEN}\nSPRINGEN: {SPRINGEN}"],
			[29, 5, "{HIEB}: {WAFFE}"],
			[72, 4, "ES RASCHELT ..."],
		],
		"map": build(126, [[24, 26], [52, 54], [97, 99]],
			[["P", 2, 8]] + line("c", 6, 9, 8)
			+ at("R", [[12, 8], [13, 8], [13, 7], [14, 8], [14, 7]]) + at("c", [[12, 7], [13, 6], [14, 6]])
			+ line("c", 18, 20, 8) + line("c", 24, 26, 6)
			+ [["m", 34, 8]] + line("c", 37, 39, 8)
			+ [["S", 42, 8]]
			+ line("=", 44, 47, 6) + at("c", [[45, 5], [46, 5]])
			+ line("=", 49, 51, 4) + line("c", 49, 51, 3) + [["c", 53, 6]]
			+ at("c", [[57, 8], [58, 8]]) + at("^", [[59, 8], [60, 8]]) + at("c", [[59, 6], [60, 6]])
			+ [["B", 66, 8], ["c", 66, 7], ["e", 78, 4], ["S", 70, 8]]
			+ line("R", 77, 81, 8) + at("w", [[78, 7], [80, 7], [84, 8]]) + at("c", [[77, 7], [79, 7], [81, 7]])
			+ line("R", 87, 89, 8) + line("R", 87, 89, 7) + [["C", 88, 6]]
			+ at("c", [[91, 8], [92, 8]]) + [["m", 94, 8], ["c", 98, 6], ["S", 102, 8]]
			+ at("R", [[106, 8], [107, 8], [107, 7]]) + line("=", 109, 112, 5) + line("c", 109, 112, 4)
			+ [["m", 111, 8]] + at("^", [[115, 8], [116, 8]]) + at("c", [[115, 6], [116, 6]]) + [["e", 117, 4]]
			+ [["F", 121, 8]]),
	}


static func _turnhalle() -> Dictionary:
	return {
		"id": "turnhalle", "name": "Turnhalle", "bg": "bg-gym", "par": 50.0,
		"hints": [
			[14, 4, "VON OBEN FEDERT DER BALL"],
			[41, 4, "LAUBBLÄSER: PAUSE ABWARTEN,\nDANN ZUSCHLAGEN"],
		],
		"map": build(134, [[28, 31], [60, 62], [90, 94]],
			[["P", 2, 8]] + line("c", 5, 8, 8)
			+ at("K", [[11, 8], [12, 8], [12, 7]]) + at("c", [[11, 7], [12, 6]])
			+ [["o", 17, 4]] + line("c", 16, 18, 8) + [["m", 22, 8]]
			+ [["M", 26, 8]] + at("c", [[28, 3], [29, 2], [30, 2], [31, 3]])
			+ [["S", 36, 8]] + at("c", [[39, 8], [40, 8]])
			+ [["<", 50, 8]] + line("c", 45, 48, 8)
			+ at("K", [[54, 8], [55, 8], [55, 7], [56, 8], [56, 7], [56, 6]]) + at("c", [[54, 7], [55, 6], [56, 5]]) + [["c", 61, 6]]
			+ [["o", 66, 4], ["o", 70, 3]] + at("c", [[66, 8], [68, 8], [70, 8]])
			+ [["S", 74, 8]]
			+ [["M", 77, 8]] + line("=", 79, 81, 5) + [["C", 80, 4], ["m", 84, 8]]
			+ [["M", 88, 8]] + line("=", 91, 93, 5) + line("c", 91, 93, 4)
			+ [[">", 98, 8]] + line("c", 101, 103, 8) + at("^", [[105, 8], [106, 8]]) + at("c", [[105, 6], [106, 6]])
			+ [["S", 109, 8]]
			+ at("K", [[112, 8], [112, 7]]) + [["o", 116, 3]] + at("c", [[114, 8], [116, 8], [118, 8]]) + [["m", 121, 8]]
			+ [["F", 128, 8]]),
	}


static func _physikraum() -> Dictionary:
	return {
		"id": "physikraum", "name": "Physikraum", "bg": "bg-lab", "par": 75.0,
		"hints": [
			[11, 4, "BRENNER: AUF DIE PAUSE WARTEN"],
			[17, 6, "MAGNET: BEI BLAU SPRINGEN"],
		],
		"map": build(140, [[22, 26], [60, 64]],
			[["P", 2, 8]] + line("c", 5, 7, 8)
			+ at("L", [[10, 8], [11, 8]]) + at("c", [[10, 7], [11, 7]]) + [["f", 15, 8]]
			+ [["N", 24, 3]] + line("c", 23, 25, 5)
			+ [["S", 30, 8], ["f", 35, 8], ["c", 37, 8], ["f", 39, 8]]
			+ line("L", 44, 47, 8) + at("L", [[46, 7], [47, 7]]) + [["f", 45, 7]] + at("c", [[44, 7], [46, 6], [47, 6]])
			+ at("c", [[50, 8], [51, 8]]) + [["m", 54, 8]]
			+ [["N", 62, 3]] + line("c", 61, 63, 5)
			+ [["S", 68, 8]]
			+ at("w", [[73, 8], [77, 8], [81, 8]]) + at("c", [[72, 8], [75, 8], [79, 8], [83, 8]])
			+ line("L", 86, 88, 8) + line("L", 86, 88, 7) + [["C", 87, 6]]
			+ [["f", 92, 8], ["m", 96, 8]]
			+ line("^", 100, 103, 8) + [["N", 102, 3]] + at("c", [[101, 5], [102, 5]])
			+ [["S", 108, 8]]
			+ [["f", 113, 8], ["c", 114, 8], ["f", 116, 8], ["c", 117, 8], ["f", 119, 8], ["c", 121, 8]]
			+ at("L", [[125, 8], [126, 8]]) + at("c", [[125, 7], [126, 7]])
			+ [["F", 133, 8]]),
	}
