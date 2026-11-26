class_name Chars
extends RefCounted
## Die spielbaren Figuren. Bis auf Herrn Hammer sind Namen, Fächer und Fähigkeiten noch PLATZHALTER,
## bis das Abikomitee die echten Infos liefert.
##
## Seltenheiten: selten → superSelten → episch → legendaer → mythisch.
## „Mythisch“ ist keine eigene Person, sondern die Spezialversion eines Lehrers
## (gleiche Person, aber mit Extra-Fähigkeiten, goldener Waffe und Glitzer-Spur).
##
## Jede Figur ist ein Dictionary mit:
##   id, name, subject, rarity, ability, bonus (Array), weapon ("ruler" | "hammer" | "goldHammer"),
##   quotes (Array), smash_quote, look (Dictionary oder leer), variant_of, color, price, starter

const RARITY_LABEL := {
	"selten": "Selten", "superSelten": "Super selten", "episch": "Episch", "legendaer": "Legendär", "mythisch": "Mythisch",
}
const RARITY_COLOR := {
	"selten": 0x4aa3ff, "superSelten": 0x3ddc84, "episch": 0xb45cff, "legendaer": 0xffb627, "mythisch": 0xff3d7f,
}
const ABILITY_LABEL := {
	"none": "Keine", "doubleJump": "Doppelsprung", "speed": "Sprinter", "highJump": "Supersprung",
	"glide": "Gleiten (Sprung halten)", "smash": "Kisten zerschlagen",
}
## Preis im Shop in Ginkgo-Talern. Mythische Versionen gibt es nur über Sammelkarten.
const PRICE := { "selten": 150, "superSelten": 300, "episch": 600, "legendaer": 1200, "mythisch": 0 }

## Alle Figuren, die per Karten-Code freigeschaltet werden können.
static var teachers: Array[Dictionary] = []
## Startfigur + alle Lehrer
static var all: Array[Dictionary] = []
static var starter: Dictionary


static func _static_init() -> void:
	# ------------------------------------------------------------ Herr Hammer
	var hammer_look := {
		"hair": 0x4a3a30, "skin": 0xf0c4a0, "shirt": 0x2f5f63, "vest": 0x5a5a5e, "tie": 0x6fa3a0,
		"belt": 0x7a4a24, "pants": 0x34476e, "shoes": 0x5a3a22, "glasses": 0x5e2f2a, "stubble": 0xb09a88,
		"ponytail": true, "face": 1, "face_jump": 3,
	}
	var hammer_quotes := [
		"Ethik ist wie Religion,\nnur ohne Weihnachten.",
		"Ich hatte Deutsch\nLeistungskurs.",
		"Wer mag kein Nutella?",
		"Ich bin noch nicht satt\ngegessen am Leid.",
	]
	var hammer := _make({
		"id": "lehrer01", "name": "Herr Hammer", "subject": "Chemie · Bio", "rarity": "legendaer",
		"ability": "smash", "weapon": "hammer", "quotes": hammer_quotes,
		"smash_quote": "Das Feld wird auch nicht gefragt,\nob der Pflug drüber fährt!",
		"look": hammer_look, "color": 0x5a5a5e,
	})
	var mythic_look := hammer_look.duplicate()
	mythic_look["tie"] = 0xffc928
	var hammer_mythic := hammer.duplicate(true)
	hammer_mythic.merge({
		"id": "lehrer01m", "name": "Admin Hammer", "subject": "Chemie · Bio · IT", "rarity": "mythisch",
		"bonus": ["doubleJump"], "weapon": "goldHammer", "variant_of": "lehrer01",
		"quotes": hammer_quotes + ["Hast du es schon mal mit\nAus- und Einschalten probiert?"],
		"look": mythic_look, "price": 0,
	}, true)

	# ------------------------------------------------------------ Platzhalter 02–20
	var rarities := [
		"selten", "selten", "selten", "selten", "selten", "selten", "selten",
		"superSelten", "superSelten", "superSelten", "superSelten", "superSelten", "superSelten",
		"episch", "episch", "episch", "episch",
		"legendaer", "legendaer",
	]
	var abilities := ["doubleJump", "speed", "highJump", "glide", "smash"]
	var colors := [0x3cb44b, 0xffe119, 0x4363d8, 0xf58231, 0x911eb4, 0x46f0f0, 0xf032e6, 0xbcf60c, 0xfabebe,
		0x008080, 0xe6beff, 0x9a6324, 0xfffac8, 0x800000, 0xaaffc3, 0x808000, 0xffd8b1, 0x000075, 0xffffff]
	var placeholders: Array[Dictionary] = []
	for i in rarities.size():
		var n := "%02d" % (i + 2)
		placeholders.append(_make({
			"id": "lehrer" + n, "name": "Lehrer " + n, "subject": "Fach ?", "rarity": rarities[i],
			"ability": abilities[(i + 1) % abilities.size()], "color": colors[i],
		}))

	starter = _make({
		"id": "schueler", "name": "Abiturient*in", "subject": "Abi 2026", "rarity": "selten",
		"ability": "none", "color": 0xffcc33, "price": 0, "starter": true,
	})
	teachers.assign([hammer] + placeholders + [hammer_mythic])
	all.assign([starter] + teachers)


## Füllt fehlende Felder mit Standardwerten auf.
static func _make(d: Dictionary) -> Dictionary:
	var base := {
		"bonus": [], "weapon": "ruler", "quotes": [], "smash_quote": "", "look": {}, "variant_of": "",
		"subject": "", "starter": false,
	}
	base.merge(d, true)
	if not base.has("price"):
		base["price"] = PRICE[base["rarity"]]
	return base


static func get_char(id: String) -> Dictionary:
	for c in all:
		if c["id"] == id:
			return c
	return starter


static func has_ability(c: Dictionary, a: String) -> bool:
	return c["ability"] == a or a in c["bonus"]


static func ability_text(c: Dictionary) -> String:
	var parts: Array[String] = [ABILITY_LABEL[c["ability"]]]
	for b in c["bonus"]:
		parts.append(ABILITY_LABEL[b])
	return " + ".join(parts)


static func is_detailed(c: Dictionary) -> bool:
	return not (c["look"] as Dictionary).is_empty()


## Mit welchem Faktor die Figur angezeigt wird, damit alle gleich groß (90 px = zwei Kacheln) sind.
## Detailfiguren sind 36x60 Pixel groß, einfache Figuren 12x20.
static func display_scale(c: Dictionary) -> float:
	return 1.5 if is_detailed(c) else 4.5
