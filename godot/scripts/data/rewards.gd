class_name Rewards
extends RefCounted
## Sammel-Belohnungen: je mehr Lehrer freigeschaltet sind, desto mehr gibt es.
##   5 Lehrer  → 250 Ginkgo-Taler
##   10 Lehrer → Bonuslevel „Lehrerzimmer“
##   20 Lehrer → goldener Rahmen für alle Karten und Figuren-Glanz

const STEPS := [
	{ "id": "coins250", "need": 5, "name": "250 Ginkgo-Taler", "icon": "icon-coin" },
	{ "id": "bonus_level", "need": 10, "name": "Bonuslevel „Lehrerzimmer“", "icon": "icon-star" },
	{ "id": "gold_frame", "need": 20, "name": "Goldener Kartenrahmen", "icon": "icon-card" },
]


static func has(id: String) -> bool:
	return id in Save.data["rewards"]


## Neue Belohnungen vergeben (nach jedem Freischalten aufrufen)
static func check() -> void:
	var n := Achievements._teachers()
	for st in STEPS:
		if n >= st["need"] and not has(st["id"]):
			Save.data["rewards"].append(st["id"])
			if st["id"] == "coins250":
				Save.data["coins"] = int(Save.data["coins"]) + 250
			if not (Nav.args.has("bot") or Nav.args.has("unlock-all")):
				Nav.toast(st["icon"], "SAMMEL-BELOHNUNG", st["name"])
	Save.persist()
