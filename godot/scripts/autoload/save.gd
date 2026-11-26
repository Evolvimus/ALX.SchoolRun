extends Node
## Lokaler Spielstand (user://save.json). Funktioniert auf PC, Handy und im Browser.

const PATH := "user://save.json"

var data := {}


func _ready() -> void:
	data = _defaults()
	if "--fresh" in OS.get_cmdline_user_args():
		return  # Testläufe starten mit leerem Spielstand
	if FileAccess.file_exists(PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			data.merge(parsed, true)
	persist()


func _defaults() -> Dictionary:
	return {
		"player_id": _uuid(), "unlocked": ["schueler"], "selected": "schueler", "coins": 0,
		"best_times": {}, "best_leaves": {}, "progress": 1, "muted": false,
		"seen": [], "defeated": {}, "mock_used": [],
		"difficulty": "normal", "medals": {}, "hefte": {},
	}


func persist() -> void:
	if "--fresh" in OS.get_cmdline_user_args():
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func unlock(id: String) -> void:
	if not id in data["unlocked"]:
		data["unlocked"].append(id)
	persist()


func is_unlocked(id: String) -> bool:
	return id in data["unlocked"]


func _uuid() -> String:
	var b := Crypto.new().generate_random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	var h := b.hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20)]
