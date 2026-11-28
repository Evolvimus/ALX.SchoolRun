class_name Names
extends RefCounted
## Zufällige Spielernamen für die Rangliste, z. B. „Flinker Bücherwurm 42“.
## Es gibt bewusst keine freie Namenseingabe: so landen keine echten Namen oder Beleidigungen in der Liste.

const ADJ := ["flink", "schlau", "mutig", "leise", "wild", "golden", "fröhlich", "schnell", "stark", "neugierig",
	"lässig", "fleißig", "frech", "cool", "listig", "rasant", "pfiffig", "tapfer", "witzig", "eifrig"]
## [Wort, Geschlecht] – m: -er, f: -e, n: -es
const NOUN := [["Bücherwurm", "m"], ["Ginkgo", "m"], ["Füller", "m"], ["Radiergummi", "m"], ["Tafelschwamm", "m"],
	["Staubmaus", "f"], ["Kreide", "f"], ["Brotdose", "f"], ["Schultasche", "f"], ["Pausenklingel", "f"],
	["Lineal", "n"], ["Geodreieck", "n"], ["Heft", "n"], ["Ginkgoblatt", "n"], ["Pausenbrot", "n"],
	["Mäppchen", "n"], ["Klassenbuch", "n"], ["Basketball", "m"], ["Magnet", "m"], ["Laubbläser", "m"]]
const ENDING := { "m": "er", "f": "e", "n": "es" }


static func random() -> String:
	var n: Array = NOUN[randi() % NOUN.size()]
	var a: String = ADJ[randi() % ADJ.size()]
	return "%s%s %s %d" % [a.capitalize(), ENDING[n[1]], n[0], randi_range(10, 99)]


## Aktueller Name (wird beim ersten Mal erzeugt und gespeichert)
static func current() -> String:
	if str(Save.data.get("player_name", "")) == "":
		Save.data["player_name"] = random()
		Save.persist()
	return Save.data["player_name"]
