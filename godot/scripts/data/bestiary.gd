class_name Bestiary
extends RefCounted
## Gegner-Lexikon: Infos zu allen Gegnern. Die Reihenfolge ist die Reihenfolge im Lexikon.

const LIST := [
	{ "id": "mouse", "name": "Staubmaus", "where": "Klassenzimmer, Turnhalle", "icon": "mouse-0", "defeatable": true,
		"behavior": "Huscht unter den Bänken umher. Kommst du nah, zeigt sie ein „!“ und flitzt los.",
		"tip": "Draufspringen oder zuschlagen." },
	{ "id": "plane", "name": "Papierflieger", "where": "Klassenzimmer", "icon": "plane", "defeatable": true,
		"behavior": "Fliegen zu dritt in Formation quer durch den Raum.",
		"tip": "Lücke abpassen oder zu Papierknäueln schlagen." },
	{ "id": "worm", "name": "Bücherwurm", "where": "Klassenzimmer, Physikraum", "icon": "worm", "defeatable": true,
		"behavior": "Frisst sich durch Regale. Erst raschelt es, dann taucht er aus einem der Löcher auf.",
		"tip": "Auf das Rascheln achten. Zwei Lineal-Hiebe, solange er draußen ist." },
	{ "id": "caterpillar", "name": "Raupe", "where": "Alle Level", "icon": "cat-0", "defeatable": true,
		"behavior": "Sitzt auf einem großen Ginkgoblatt und frisst es auf, sobald du in die Nähe kommst.",
		"tip": "Schnell sein! Je früher du sie erwischst, desto mehr vom Blatt bleibt übrig (bis zu 5)." },
	{ "id": "ball", "name": "Basketball", "where": "Turnhalle", "icon": "ball", "defeatable": false,
		"behavior": "Springt unermüdlich im festen Takt auf und ab.",
		"tip": "Unten durchlaufen, wenn er oben ist, oder von oben als Sprungbrett nutzen." },
	{ "id": "blower", "name": "Laubbläser", "where": "Turnhalle", "icon": "blower-0", "defeatable": true,
		"behavior": "Bläst im Takt und schiebt dich weg. Vor dem Anspringen ruckelt er kurz.",
		"tip": "Die Pause abwarten, dann zuschlagen (Lineal: zweimal)." },
	{ "id": "magnet", "name": "Magnet", "where": "Physikraum", "icon": "magnet", "defeatable": false,
		"behavior": "Zieht dich an (blaue Ringe) und stößt dich ab (rote Ringe).",
		"tip": "Bei Blau springen, dann trägt er dich über Lücken." },
	{ "id": "burner", "name": "Bunsenbrenner", "where": "Physikraum", "icon": "burner", "defeatable": false,
		"behavior": "Aus, dann eine kleine Zündflamme, dann eine hohe Stichflamme.",
		"tip": "Sobald die Flamme ausgeht, vorbeilaufen." },
]


static func find(id: String) -> Dictionary:
	for b in LIST:
		if b["id"] == id:
			return b
	return {}
