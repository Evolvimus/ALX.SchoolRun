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
