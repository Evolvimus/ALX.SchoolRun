extends Control
## Schulplan: Kapitel als Wege mit Stationen. Freigeschaltete Level sind gelb, gesperrte grau,
## Herausforderungen lila (brauchen Medaillen), Bosse rot. Unten steht alles zum ausgewählten Level.

var params := {}
var _nodes: Array[Button] = []
var _selected := -1
var _info: Control
var _diff: Button
var _diff_label: Label

const ORDER := ["entspannt", "normal", "abi"]
const DIFF_INFO := {
	"entspannt": "5 Leben · nach Sturz geht es direkt daneben weiter",
	"normal": "3 Leben · zurück zum Setzling",
	"abi": "1 Leben · 50 % mehr Taler",
}
const KIND_COLOR := { "tutorial": Color("#a6e07a"), "normal": Color("#ffcc33"), "challenge": Color("#b45cff"), "boss": Color("#ff3d7f") }


func _ready() -> void:
	UI.screen(self)
	UI.background(self, "bg-school", 120)
	UI.title(self, "Schulplan", 30)
	_diff_label = UI.label(self, "", Vector2(944, 54), 8, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_RIGHT, 420)
	_diff = UI.button(self, "", Vector2(846, 28), _toggle_difficulty, 196, 34)
	_diff.add_theme_font_size_override("font_size", 10)
	_show_difficulty()

	# Kapitelzeilen: Einführung + Kapitel 1 oben, Kapitel 2 darunter
	var rows := { 0: 120.0, 1: 120.0, 2: 268.0 }
	var x_start := { 0: 70.0, 1: 210.0, 2: 210.0 }
	for ci in Levels.CHAPTERS.size():
		var y: float = rows.get(ci, 268.0 + (ci - 2) * 148.0)
		if ci != 0:
			UI.label(self, Levels.CHAPTERS[ci]["title"], Vector2(x_start[ci] - 46 if x_start.has(ci) else 164, y - 50), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 500)
			var total := 0
			for lv in Levels.list:
				if lv["chapter"] == ci and lv["kind"] != "challenge":
					total += 3
			UI.label(self, "Medaillen %d/%d" % [Levels.chapter_medals(ci), total], Vector2(930, y - 50), 9, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var last_pos := {}
	for i in Levels.list.size():
		var lv: Dictionary = Levels.list[i]
		var ci: int = lv["chapter"]
		var y: float = rows.get(ci, 268.0 + (ci - 2) * 148.0)
		var x: float = x_start.get(ci, 210.0) + (lv["slot"] - 1) * 150.0
		var pos := Vector2(x, y + (14.0 if lv["slot"] % 2 == 0 else -6.0))
		if last_pos.has(ci) or (ci == 1 and last_pos.has(0)):
			var from: Vector2 = last_pos.get(ci, last_pos.get(0))
			_path(from, pos, Levels.is_unlocked(i))
		last_pos[ci] = pos
		_nodes.append(_node(i, pos))
	# Platzhalter für Kapitel, die noch kommen
	var y3 := 416.0
	UI.label(self, "Kapitel 3–6: Mensa · Bibliothek · Computerraum · Lehrertrakt", Vector2(164, y3 - 44), 9, Color("#666c88"), HORIZONTAL_ALIGNMENT_LEFT, 700)
	for k in 5:
		var dot := UI.rect(self, Rect2(210 + k * 150 - 18, y3 - 18, 36, 36), Color(0.08, 0.09, 0.16, 0.8), 3, Color("#3a3f5e"))
		UI.label(dot, "?", Vector2(18, 10), 12, Color("#3a3f5e"), HORIZONTAL_ALIGNMENT_CENTER, 36)

	_info = Control.new()
	add_child(_info)
	UI.back_button(self)
	var focus := int(params.get("focus", -1))
	if focus < 0:
		focus = 0
		for i in Levels.list.size():  # erstes freigeschaltetes, noch nicht geschafftes Level
			if Levels.is_unlocked(i) and not Levels.completed(i):
				focus = i
				break
	_select(clampi(focus, 0, Levels.list.size() - 1))
	_nodes[_selected].grab_focus.call_deferred()


func _path(a: Vector2, b: Vector2, open: bool) -> void:
	var line := Line2D.new()
	line.points = [a, b]
	line.width = 6
	line.default_color = Color("#ffcc33", 0.7) if open else Color("#3a3f5e", 0.8)
	add_child(line)
	move_child(line, 3)


func _node(i: int, pos: Vector2) -> Button:
	var lv: Dictionary = Levels.list[i]
	var open := Levels.is_unlocked(i)
	var size := 64.0 if lv["kind"] == "boss" else 52.0
	var b := Button.new()
	var col: Color = KIND_COLOR[lv["kind"]]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#14172e") if open else Color("#0d0f1f")
	style.border_color = col if open else Color("#3a3f5e")
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(size / 2))
	var focus := style.duplicate()
	focus.border_color = Color.WHITE
	focus.bg_color = Color("#20254a")
	for st in ["normal", "disabled"]:
		b.add_theme_stylebox_override(st, style)
	for st in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, focus)
	add_child(b)
	b.size = Vector2(size, size)
	b.position = pos - b.size / 2
	var label := "T" if lv["kind"] == "tutorial" else Levels.label(i)
	UI.label(b, label, Vector2(size / 2, size / 2 - 7), 12 if label.length() < 3 else 10, col if open else Color("#3a3f5e"), HORIZONTAL_ALIGNMENT_CENTER, size)
	if Levels.completed(i):
		UI.image(b, "check", Vector2(size - 6, 8), 1.6)
	# Medaillen unter der Station
	if lv["kind"] != "tutorial" and open:
		var medals: Dictionary = Save.data["medals"].get(lv["id"], {})
		for m in Game.MEDALS.size():
			var icon := UI.image(self, "medal-" + Game.MEDALS[m][0], pos + Vector2((m - 1) * 18, size / 2 + 14), 1.4)
			if not medals.get(Game.MEDALS[m][0], false):
				icon.modulate = Color(0.2, 0.2, 0.26)
	b.focus_entered.connect(func(): _select(i))
	b.mouse_entered.connect(func(): b.grab_focus())
	b.pressed.connect(func(): _play(i))
	return b


func _select(i: int) -> void:
	_selected = i
	for c in _info.get_children():
		c.queue_free()
	var lv: Dictionary = Levels.list[i]
	var open := Levels.is_unlocked(i)
	var id: String = lv["id"]
	var panel := UI.rect(_info, Rect2(196, 454, 748, 76), Color(0.043, 0.043, 0.051, 0.9), 3, KIND_COLOR[lv["kind"]] if open else Color("#3a3f5e"))
	var kind_text: String = { "tutorial": "Tutorial", "normal": "Level", "challenge": "Herausforderung", "boss": "BOSS" }[lv["kind"]]
	UI.label(panel, "%s %s · %s" % [kind_text, "" if lv["kind"] == "tutorial" else Levels.label(i), lv["name"]], Vector2(14, 10), 12, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 520)
	if not open:
		var why := "Erst %s schaffen." % _previous_name(i)
		if lv["kind"] == "challenge":
			why = "Braucht %d Medaillen aus diesem Kapitel (du hast %d)." % [lv["medals_needed"], Levels.chapter_medals(lv["chapter"])]
		UI.label(panel, "Gesperrt · " + why, Vector2(14, 40), 9, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_LEFT, 720)
		return
	var best = Save.data["best_times"].get(id)
	var hefte_total := Levels.count_hefte(lv)
	var parts := ["Blätter %d/%d" % [int(Save.data["best_leaves"].get(id, 0)), Levels.count_leaves(lv)]]
	if hefte_total > 0:
		parts.append("Hefte %d/%d" % [(Save.data["hefte"].get(id, []) as Array).size(), hefte_total])
	parts.append("Bestzeit %.1fs" % best if best != null else "Noch nicht geschafft")
	parts.append("Ziel %ds" % int(lv["par"]))
	UI.label(panel, " · ".join(parts), Vector2(14, 40), 9, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_LEFT, 560)
	var play := UI.button(panel, "Spielen", Vector2(670, 38), func(): _play(i), 130, 40)
	play.focus_mode = Control.FOCUS_NONE


func _previous_name(i: int) -> String:
	for j in range(i - 1, -1, -1):
		if Levels.list[j]["kind"] != "challenge":
			return "%s (%s)" % [Levels.list[j]["name"], Levels.label(j)]
	return "das vorige Level"


func _play(i: int) -> void:
	if not Levels.is_unlocked(i):
		Sfx.play("hurt")
		return
	Sfx.play("click")
	Nav.goto("game", { "level": i })


func _toggle_difficulty() -> void:
	Save.data["difficulty"] = ORDER[(ORDER.find(Save.data["difficulty"]) + 1) % ORDER.size()]
	Save.persist()
	_show_difficulty()


func _show_difficulty() -> void:
	var d: String = Save.data["difficulty"]
	_diff.text = "Stufe: " + Game.DIFFICULTY[d]["label"]
	_diff_label.text = DIFF_INFO[d]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
