class_name Achievements
extends RefCounted
## Erfolge: werden nach jedem Level, beim Freischalten und nach der Tagesaufgabe geprüft.
## Neue Erfolge erscheinen als Einblendung und im Bildschirm „Erfolge“.
## ctx (optional, vom gerade beendeten Level): { level_id, kind, hits, attempts, difficulty, all_leaves, ghost_beaten }

const LIST := [
	{ "id": "first_day", "name": "Erster Schultag", "text": "Das Tutorial geschafft." },
	{ "id": "all_leaves", "name": "Blattsammler*in", "text": "Ein Level mit allen goldenen Blättern beendet." },
	{ "id": "clean", "name": "Unberührt", "text": "Ein Level ohne Treffer und Fehlversuch geschafft." },
	{ "id": "abi", "name": "Abiprüfung bestanden", "text": "Ein Level auf der Stufe „Abiprüfung“ geschafft." },
	{ "id": "chapter1", "name": "Klassentrakt durch", "text": "Alle Pflichtlevel von Kapitel 1 geschafft." },
	{ "id": "boss", "name": "Bossbezwinger*in", "text": "Den ersten Boss besiegt." },
	{ "id": "boss_clean", "name": "Kein Kratzer", "text": "Einen Boss ohne Treffer besiegt." },
	{ "id": "all_bosses", "name": "Schulsieger*in", "text": "Alle Bosse besiegt." },
	{ "id": "medals10", "name": "Medaillenregen", "text": "10 Medaillen gesammelt." },
	{ "id": "hefte5", "name": "Geheimagent*in", "text": "5 Geheimhefte gefunden." },
	{ "id": "defeat50", "name": "Aufräumdienst", "text": "50 Gegner besiegt." },
	{ "id": "lexikon", "name": "Forscher*in", "text": "Alle Gegner im Lexikon entdeckt." },
	{ "id": "collect5", "name": "Sammelfieber", "text": "5 Lehrer freigeschaltet." },
	{ "id": "collect10", "name": "Halbe Lehrerschaft", "text": "10 Lehrer freigeschaltet." },
	{ "id": "collect20", "name": "Komplettes Kollegium", "text": "Alle 20 Lehrer freigeschaltet." },
	{ "id": "mythic", "name": "Mythos", "text": "Eine mythische Karte gefunden." },
	{ "id": "daily1", "name": "Tagesform", "text": "Die erste Tagesaufgabe geschafft." },
	{ "id": "daily7", "name": "Stammgast", "text": "7 Tagesaufgaben geschafft." },
	{ "id": "ghost", "name": "Geisterjäger*in", "text": "Den Geist deiner Bestzeit geschlagen." },
	{ "id": "rich", "name": "Taler-Tycoon", "text": "1000 Ginkgo-Taler auf einmal besessen." },
]


static func has(id: String) -> bool:
	return id in Save.data["achievements"]


static func find(id: String) -> Dictionary:
	for a in LIST:
		if a["id"] == id:
			return a
	return {}


## Alle Bedingungen prüfen, neue Erfolge speichern und einblenden. Gibt die neuen IDs zurück.
static func check(ctx := {}) -> Array:
	var got: Array = []
	for a in LIST:
		if not has(a["id"]) and _met(a["id"], ctx):
			Save.data["achievements"].append(a["id"])
			got.append(a["id"])
	if not got.is_empty():
		Save.persist()
		if not (Nav.args.has("bot") or Nav.args.has("unlock-all")):
			for id in got:
				var a := find(id)
				Nav.toast("icon-trophy", "ERFOLG", a["name"])
	return got


static func _met(id: String, ctx: Dictionary) -> bool:
	var d: Dictionary = Save.data
	match id:
		"first_day": return d["best_times"].has("tutorial")
		"all_leaves": return ctx.get("all_leaves", false)
		"clean": return ctx.has("level_id") and ctx.get("hits", 1) == 0 and ctx.get("attempts", 1) == 0 and ctx.get("kind", "") != "tutorial"
		"abi": return ctx.get("difficulty", "") == "abi"
		"chapter1": return _chapter_done(1)
		"boss": return _bosses_done() > 0
		"boss_clean": return ctx.get("kind", "") == "boss" and ctx.get("hits", 1) == 0
		"all_bosses":
			var total := 0
			for lv in Levels.list:
				if lv["kind"] == "boss":
					total += 1
			return total > 0 and _bosses_done() == total
		"medals10": return _medals() >= 10
		"hefte5":
			var n := 0
			for v in d["hefte"].values():
				n += (v as Array).size()
			return n >= 5
		"defeat50":
			var n := 0
			for v in d["defeated"].values():
				n += int(v)
			return n >= 50
		"lexikon":
			for b in Bestiary.LIST:
				if not b["id"] in d["seen"]:
					return false
			return true
		"collect5": return _teachers() >= 5
		"collect10": return _teachers() >= 10
		"collect20": return _teachers() >= 20
		"mythic":
			for c in Chars.all:
				if c["rarity"] == "mythisch" and Save.is_unlocked(c["id"]):
					return true
			return false
		"daily1": return int(d["stats"].get("dailies", 0)) >= 1
		"daily7": return int(d["stats"].get("dailies", 0)) >= 7
		"ghost": return ctx.get("ghost_beaten", false)
		"rich": return int(d["coins"]) >= 1000
	return false


static func _chapter_done(ch: int) -> bool:
	var any := false
	for i in Levels.list.size():
		var lv: Dictionary = Levels.list[i]
		if lv["chapter"] == ch and lv["kind"] != "challenge":
			any = true
			if not Levels.completed(i):
				return false
	return any


static func _bosses_done() -> int:
	var n := 0
	for i in Levels.list.size():
		if Levels.list[i]["kind"] == "boss" and Levels.completed(i):
			n += 1
	return n


static func _medals() -> int:
	var n := 0
	for lv in Levels.list:
		n += Levels.medal_count(lv["id"])
	return n


## Freigeschaltete echte Lehrer (ohne Schüler*in und Varianten)
static func _teachers() -> int:
	var n := 0
	for t in Chars.teachers:
		if Save.is_unlocked(t["id"]):
			n += 1
	return n
