class_name Daily
extends RefCounted
## Tägliche Herausforderung: jeden Tag dasselbe Level mit einer Zusatzregel für alle.
## Gewertet wird die Bestzeit des Tages (Tagesrangliste). Das Level muss dafür nicht freigeschaltet sein.

const MODIFIERS := [
	{ "id": "one_life", "name": "Nur ein Leben", "text": "Ein Treffer und du startest am Setzling neu." },
	{ "id": "no_checkpoints", "name": "Ohne Setzlinge", "text": "Keine Checkpoints – jeder Fehler heißt: von vorne." },
	{ "id": "fast", "name": "Turbo", "text": "Alles läuft 20 % schneller." },
	{ "id": "leaves_only", "name": "Blätterjagd", "text": "Nur wer mindestens 3/4 der Blätter hat, kommt in die Wertung." },
	{ "id": "none", "name": "Klassisch", "text": "Keine Zusatzregel – reine Bestzeit." },
]


## Heutiges Datum als JJJJ-MM-TT (Ortszeit)
static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func _day_number() -> int:
	return int(Time.get_unix_time_from_datetime_string(today() + "T00:00:00") / 86400)


## Levels, die für die Tagesaufgabe in Frage kommen (normale Level, keine Bosse/Tutorial/Herausforderung)
static func pool() -> Array:
	var out := []
	for i in Levels.list.size():
		if Levels.list[i]["kind"] == "normal":
			out.append(i)
	return out


static func level_index() -> int:
	var p := pool()
	return p[posmod(_day_number() * 7 + 3, p.size())] if p.size() > 0 else 0


static func modifier() -> Dictionary:
	return MODIFIERS[posmod(_day_number() * 5 + 1, MODIFIERS.size())]


## Heute schon gespielt? Liefert die Bestzeit des Tages oder -1
static func best_today() -> float:
	var d: Dictionary = Save.data["daily"]
	return float(d.get("best", -1.0)) if d.get("day", "") == today() else -1.0
