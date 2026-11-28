extends Node
## Verbindung zum Server (Supabase) für die einmaligen Karten-Codes.
## Ohne config/backend.cfg läuft alles im TESTMODUS auf dem Gerät.

## Feste Testcodes, die im Testmodus immer denselben Lehrer freischalten. Auf dem Server gibt es sie nicht.
const TEST_CODES := { "ALX-HAMM-ER2N": "lehrer01", "ALX-MYTH-HAYH": "lehrer01m" }

var url := ""
var key := ""
var test_mode: bool:
	get: return url == "" or key == ""


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("res://config/backend.cfg") == OK:
		url = str(cfg.get_value("supabase", "url", "")).trim_suffix("/")
		key = str(cfg.get_value("supabase", "anon_key", ""))


## Löst einen Code ein. Ergebnis: { ok = true, id = "lehrer01" } oder { ok = false, reason = "invalid" | "used" | "network" }
## Auf dem Server ist jeder Code genau EINMAL gültig.
func redeem(code: String) -> Dictionary:
	if test_mode:
		return _mock(code)
	var r := await _rpc("redeem_code", { "p_code": code, "p_player": Save.data["player_id"] })
	if r["status"] == 200 and r["body"] is String:
		return { "ok": true, "id": r["body"] }
	var msg := str(r["body"])
	if "CODE_USED" in msg:
		return { "ok": false, "reason": "used" }
	if "CODE_INVALID" in msg:
		return { "ok": false, "reason": "invalid" }
	return { "ok": false, "reason": "network" }


## Stellt freigeschaltete Figuren vom Server wieder her (z. B. nach Neuinstallation).
func fetch_unlocks() -> Array:
	if test_mode:
		return []
	var r := await _rpc("my_unlocks", { "p_player": Save.data["player_id"] })
	return r["body"] if r["status"] == 200 and r["body"] is Array else []


## Ist der Shop schon offen? Wird zentral vom Abikomitee gesetzt (nach Ende der Kartenaktion).
func shop_open() -> bool:
	if test_mode:
		return true
	var r := await _rpc("shop_open", {})
	return r["status"] == 200 and r["body"] == true


# ------------------------------------------------------------------ Rangliste (für alle)

## Punkte für ein Level: Blätter, Medaillen und Tempo (schneller als die Zielzeit gibt Bonus)
static func points_for(leaves: int, medals: int, seconds: float, par: float) -> int:
	return leaves * 10 + medals * 100 + maxi(0, roundi((par * 1.5 - seconds) * 5))


## Levelergebnis melden (bestes je Spieler und Level zählt)
func submit_score(level_id: String, seconds: float, points: int) -> void:
	if Nav.args.has("bot") or Nav.args.has("fresh"):
		return
	if test_mode:
		var mock: Dictionary = Save.data["leaderboard_mock"]
		var old: Dictionary = mock.get(level_id, {})
		mock[level_id] = { "time": minf(seconds, old.get("time", INF)), "points": maxi(points, old.get("points", 0)) }
		Save.persist()
		return
	await _rpc("submit_score", { "p_player": Save.data["player_id"], "p_name": Names.current(), "p_level": level_id, "p_time": seconds, "p_points": points })


func submit_daily(day: String, level_id: String, seconds: float) -> void:
	if Nav.args.has("bot") or Nav.args.has("fresh"):
		return
	if test_mode:
		var mock: Dictionary = Save.data["leaderboard_mock"]
		mock["daily:" + day] = { "time": minf(seconds, (mock.get("daily:" + day, {}) as Dictionary).get("time", INF)) }
		Save.persist()
		return
	await _rpc("submit_daily", { "p_player": Save.data["player_id"], "p_name": Names.current(), "p_day": day, "p_level": level_id, "p_time": seconds })


## Rangliste laden. kind: "total", "level" (key = Level-ID), "daily" (key = Datum JJJJ-MM-TT).
## Ergebnis: { ok, rows = [{ rank, name, value, me }] }
func leaderboard(kind: String, key := "") -> Dictionary:
	if test_mode:
		return { "ok": true, "rows": _mock_board(kind, key), "sample": true }
	var r := await _rpc("leaderboard", { "p_kind": kind, "p_key": key, "p_player": Save.data["player_id"], "p_limit": 10 })
	if r["status"] == 200 and r["body"] is Array:
		return { "ok": true, "rows": r["body"] }
	return { "ok": false, "rows": [] }


## Testmodus: eigene Werte plus ein paar Beispiel-Einträge, damit man sieht, wie es aussieht
func _mock_board(kind: String, key: String) -> Array:
	var mock: Dictionary = Save.data["leaderboard_mock"]
	var mine := -1.0
	match kind:
		"total":
			var sum := 0
			for k in mock:
				if not str(k).begins_with("daily:"):
					sum += int(mock[k].get("points", 0))
			mine = sum if sum > 0 else -1.0
		"level":
			mine = float(mock.get(key, {}).get("time", -1.0))
		"daily":
			mine = float(mock.get("daily:" + key, {}).get("time", -1.0))
	var sample: Array = { "total": [2650.0, 1980.0, 1720.0, 990.0, 610.0], "level": [31.4, 36.9, 41.2, 48.0, 59.5], "daily": [29.8, 33.1, 38.7, 44.2, 52.6] }[kind]
	var names := ["Pfiffiges Geodreieck 12", "Rasante Kreide 77", "Schlauer Magnet 31", "Tapferes Heft 54", "Leise Staubmaus 20"]
	var rows: Array = []
	for i in sample.size():
		rows.append({ "name": names[i], "value": sample[i], "me": false })
	if mine >= 0:
		rows.append({ "name": Names.current(), "value": mine, "me": true })
	rows.sort_custom(func(a, b): return a["value"] > b["value"] if kind == "total" else a["value"] < b["value"])
	for i in rows.size():
		rows[i]["rank"] = i + 1
	return rows


func _rpc(fn: String, body: Dictionary) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 10.0
	add_child(req)
	var headers := ["apikey: " + key, "Authorization: Bearer " + key, "Content-Type: application/json"]
	var err := req.request("%s/rest/v1/rpc/%s" % [url, fn], headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return { "status": 0, "body": null }
	var res: Array = await req.request_completed
	req.queue_free()
	var parsed = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if parsed is Dictionary and parsed.has("message"):
		parsed = parsed["message"]
	return { "status": res[1], "body": parsed }


## Testmodus: Testcodes schalten feste Lehrer frei, jeder andere gültige Code einmal pro Gerät einen zufälligen.
func _mock(code: String) -> Dictionary:
	if TEST_CODES.has(code):
		return { "ok": true, "id": TEST_CODES[code] }
	var used: Array = Save.data["mock_used"]
	if code in used:
		return { "ok": false, "reason": "used" }
	used.append(code)
	Save.persist()
	var raw := code.replace("-", "").substr(3)
	var idx := CodeFormat.ALPHABET.find(CodeFormat.check_char(raw)) % Chars.teachers.size()
	return { "ok": true, "id": Chars.teachers[idx]["id"] }
