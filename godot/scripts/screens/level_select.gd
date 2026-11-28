extends Control
## Schulplan: ein Kapitel pro Seite (wischen, Pfeile oder ← →), Stationen als Weg, unten alles zum
## ausgewählten Level und ein großer „Spielen“-Button. Freigeschaltete Level leuchten in ihrer Farbe,
## gesperrte sind grau, Herausforderungen lila (brauchen Medaillen), Bosse rot.

var params := {}
var _pages: Array = []  # [{ title, chapter, levels: [index …] }] – letzte Seite: kommende Kapitel
var _page := -1
var _selected := -1
var _page_root: Control
var _info: Control
var _dots: Array[Panel] = []
var _diff_buttons := {}
var _diff_info: Label
var _drag_from := Vector2.ZERO
var _dragging := false
var _node_buttons := {}

const ORDER := ["entspannt", "normal", "abi"]
const DIFF_INFO := {
	"entspannt": "5 Leben · nach Sturz direkt daneben weiter",
	"normal": "3 Leben · zurück zum Setzling",
	"abi": "1 Leben · 50 % mehr Taler",
}
const KIND_COLOR := { "tutorial": Color("#7ee08a"), "normal": Color("#ffcc33"), "challenge": Color("#b45cff"), "boss": Color("#ff5c8a"), "bonus": Color("#5ab0ff") }
const KIND_TEXT := { "tutorial": "TUTORIAL", "normal": "LEVEL", "challenge": "HERAUSFORDERUNG", "boss": "BOSS", "bonus": "BONUSLEVEL" }
const COMING := ["Mensa", "Bibliothek", "Computerraum", "Lehrertrakt"]


func _ready() -> void:
	UI.screen(self)
	UI.background(self, "bg-school", 120)
	var right := UI.top_bar(self, "Schulplan")
	_build_difficulty(right)
	_build_pages()

	_page_root = Control.new()
	_page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_page_root)
	_info = Control.new()
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_info)

	# Blättern
	UI.icon_button(self, "icon-back", Vector2(40, 250), func(): _flip(-1), 52, 2.4).focus_mode = Control.FOCUS_NONE
	var next := UI.icon_button(self, "icon-back", Vector2(920, 250), func(): _flip(1), 52, 2.4)
	next.focus_mode = Control.FOCUS_NONE
	var arrow := next.get_node("Icon") as TextureRect
	arrow.flip_h = true
	for i in _pages.size():
		_dots.append(UI.rect(self, Rect2(480 - _pages.size() * 9 + i * 18 + 3, 360, 12, 6), UI.DIM, 0, Color.TRANSPARENT, 3))

	var focus := int(params.get("focus", -1))
	if focus < 0:
		focus = 0
		for i in Levels.list.size():  # erstes freigeschaltetes, noch nicht geschafftes Level
			if Levels.list[i]["kind"] != "challenge" and Levels.is_unlocked(i) and not Levels.completed(i):
				focus = i
				break
	_select(clampi(focus, 0, Levels.list.size() - 1))


# ------------------------------------------------------------------ Aufbau

func _build_pages() -> void:
	for ci in range(1, Levels.CHAPTERS.size()):
		var idx: Array = []
		for i in Levels.list.size():
			var lc: int = Levels.list[i]["chapter"]
			if lc == ci or (ci == 1 and lc == 0):
				idx.append(i)
		_pages.append({ "title": Levels.CHAPTERS[ci]["title"], "chapter": ci, "levels": idx })
	# Bonuslevel (Sammel-Belohnung) als eigene Seite
	var bonus: Array = []
	for i in Levels.list.size():
		if Levels.list[i]["kind"] == "bonus":
			bonus.append(i)
	if not bonus.is_empty():
		_pages.append({ "title": Levels.BONUS["title"], "chapter": Levels.list[bonus[0]]["chapter"], "levels": bonus })
	_pages.append({ "title": "Bald: Kapitel 3–6", "chapter": -1, "levels": [] })


func _build_difficulty(right: float) -> void:
	var w := 104.0
	var x0 := right - w * 3
	var bg := UI.rect(self, Rect2(x0 - 4, 18, w * 3 + 8, 44), Color(0.06, 0.07, 0.15, 0.85), 2, UI.LINE, 22)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in ORDER.size():
		var d: String = ORDER[i]
		var b := UI.button(self, Game.DIFFICULTY[d]["label"], Vector2(x0 + w * i + w / 2, 40), func(): _set_difficulty(d), w - 4, 36)
		b.add_theme_font_size_override("font_size", 8)
		b.focus_mode = Control.FOCUS_NONE
		_diff_buttons[d] = b
	_diff_info = UI.label(self, "", Vector2(right, 70), 7, UI.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 420)
	_show_difficulty()


func _show_page(p: int) -> void:
	if p == _page:
		return
	var dir := signf(p - _page) if _page >= 0 else 0.0
	_page = p
	for c in _page_root.get_children():
		c.queue_free()
	_node_buttons.clear()
	for i in _dots.size():
		var s: StyleBoxFlat = _dots[i].get_theme_stylebox("panel")
		s.bg_color = UI.YELLOW if i == p else UI.DIM
	var page: Dictionary = _pages[p]
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_root.add_child(holder)
	var t := UI.label(holder, page["title"].to_upper(), Vector2(480, 108), 13, Color.WHITE)
	UI.outline(t, 6)
	if page["chapter"] < 0:
		_coming(holder)
	else:
		var total := 0
		for i in page["levels"]:
			if Levels.list[i]["kind"] not in ["challenge", "tutorial"]:
				total += 3
		var m := UI.chip(holder, "icon-star", "%d/%d" % [Levels.chapter_medals(page["chapter"]), total], 480, 142, Color("#ffd23f"), 9)
		m.position.x = 480 - m.size.x / 2
		_nodes(holder, page["levels"])
	if dir != 0.0 and not Nav.args.has("shot"):
		holder.position.x = 60 * dir
		holder.modulate.a = 0.0
		var tw := holder.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(holder, "position:x", 0.0, 0.3)
		tw.tween_property(holder, "modulate:a", 1.0, 0.25)


func _nodes(parent: Control, idx: Array) -> void:
	var n := idx.size()
	var x0 := 140.0
	var x1 := 820.0
	var pts: Array[Vector2] = []
	for k in n:
		var x := (x0 + x1) / 2 if n == 1 else x0 + (x1 - x0) * k / (n - 1)
		pts.append(Vector2(x, 238 + (18.0 if k % 2 == 1 else -10.0)))
	# Weg
	for k in range(1, n):
		var line := Line2D.new()
		line.points = [pts[k - 1], pts[k]]
		line.width = 8
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.default_color = Color(UI.YELLOW, 0.75) if Levels.is_unlocked(idx[k]) else Color(UI.LINE, 0.9)
		parent.add_child(line)
	for k in n:
		_node(parent, idx[k], pts[k])


func _node(parent: Control, i: int, pos: Vector2) -> void:
	var lv: Dictionary = Levels.list[i]
	var open := Levels.is_unlocked(i)
	var col: Color = KIND_COLOR[lv["kind"]]
	var size := 84.0 if lv["kind"] == "boss" else 70.0
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var style := UI.box(Color("#1a1f44") if open else Color("#10132a"), int(size / 2), 4, col if open else UI.LINE)
	var hover := UI.box(Color("#242a5c") if open else Color("#14183a"), int(size / 2), 4, col.lightened(0.3) if open else UI.DIM)
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(b)
	b.size = Vector2(size, size)
	b.position = pos - b.size / 2
	if open:
		var label := "T" if lv["kind"] == "tutorial" else Levels.label(i)
		UI.label(b, label, Vector2(size / 2, size / 2 - 7), 13 if label.length() < 3 else 11, col, HORIZONTAL_ALIGNMENT_CENTER, size)
	else:
		UI.image(b, "icon-lock", Vector2(size / 2, size / 2), 2.4).modulate = UI.DIM
	if Levels.completed(i):
		var badge := UI.rect(b, Rect2(size - 24, -4, 28, 28), Color("#1f8a3a"), 3, Color("#0d1024"), 14)
		UI.image(badge, "check", Vector2(14, 14), 1.8).modulate = Color.WHITE
	# Name und Medaillen unter der Station
	var name_label := UI.para(parent, lv["name"], Vector2(pos.x - 64, pos.y + size / 2 + 10), 128, 7, Color.WHITE if open else UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_constant_override("line_spacing", 4)
	if lv["kind"] not in ["tutorial", "challenge"] and open:
		var medals: Dictionary = Save.data["medals"].get(lv["id"], {})
		for m in Game.MEDALS.size():
			var icon := UI.image(parent, "medal-" + Game.MEDALS[m][0], pos + Vector2((m - 1) * 20, -size / 2 - 16), 1.4)
			if not medals.get(Game.MEDALS[m][0], false):
				icon.modulate = Color(0.25, 0.27, 0.4, 0.8)
	b.pressed.connect(func():
		if _selected == i:
			_play(i)
		else:
			Sfx.play("click")
			_select(i))
	_node_buttons[i] = b


func _coming(parent: Control) -> void:
	UI.label(parent, "Diese Kapitel sind in Arbeit.", Vector2(480, 140), 8, UI.MUTED)
	for k in COMING.size():
		var x := 480 + (k - 1.5) * 170
		var p := UI.panel(parent, Rect2(x - 70, 180, 140, 120), Color.TRANSPARENT, Color(0.06, 0.07, 0.15, 0.7))
		UI.image(p, "icon-lock", Vector2(70, 46), 3.0).modulate = UI.DIM
		UI.label(p, "Kapitel %d" % (k + 3), Vector2(70, 76), 7, UI.DIM)
		UI.label(p, COMING[k], Vector2(70, 94), 9, UI.MUTED)


## Info-Leiste unten zum ausgewählten Level
func _select(i: int) -> void:
	_selected = i
	for p in _pages.size():
		if i in _pages[p]["levels"]:
			_show_page(p)
			break
	for k in _node_buttons:
		var b: Button = _node_buttons[k]
		b.scale = Vector2.ONE
		b.pivot_offset = b.size / 2
	if _node_buttons.has(i):
		var b: Button = _node_buttons[i]
		b.create_tween().tween_property(b, "scale", Vector2(1.12, 1.12), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for c in _info.get_children():
		c.queue_free()
	var lv: Dictionary = Levels.list[i]
	var open := Levels.is_unlocked(i)
	var col: Color = KIND_COLOR[lv["kind"]]
	var panel := UI.panel(_info, Rect2(60, 392, 840, 128), col if open else UI.LINE)
	UI.tag(panel, KIND_TEXT[lv["kind"]] if lv["kind"] == "tutorial" else "%s %s" % [KIND_TEXT[lv["kind"]], Levels.label(i)], Vector2(22, 20), col if open else UI.DIM, 8)
	UI.label(panel, lv["name"], Vector2(22, 52), 16, Color.WHITE if open else UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 560)
	if not open:
		var why := "Erst %s schaffen." % _previous_name(i)
		if lv["kind"] == "bonus":
			why = "Sammel-Belohnung: wird ab 10 freigeschalteten Lehrern geöffnet."
		elif lv["kind"] == "challenge":
			why = "Braucht %d Medaillen aus diesem Kapitel – du hast %d." % [lv["medals_needed"], Levels.chapter_medals(lv["chapter"])]
		UI.image(panel, "icon-lock", Vector2(30, 94), 1.6).modulate = UI.MUTED
		UI.label(panel, why, Vector2(46, 88), 8, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 560)
		var locked := UI.primary(panel, "Gesperrt", Vector2(722, 64), func(): pass, 200, 64)
		locked.disabled = true
		return
	# Werte mit Symbolen
	var id: String = lv["id"]
	var best = Save.data["best_times"].get(id)
	var stats := [["leaf", "%d/%d" % [int(Save.data["best_leaves"].get(id, 0)), Levels.count_leaves(lv)]]]
	var hefte_total := Levels.count_hefte(lv)
	if hefte_total > 0:
		stats.append(["heft", "%d/%d" % [(Save.data["hefte"].get(id, []) as Array).size(), hefte_total]])
	stats.append(["icon-clock", ("%.1fs" % best) if best != null else "–"])
	stats.append(["icon-star", "Ziel %ds" % int(lv["par"])])
	var x := 22.0
	for s in stats:
		var chip := UI.chip(panel, s[0], s[1], 0, 98, Color.WHITE, 8)
		chip.position.x = x
		x += chip.size.x + 8
	var play := UI.primary(panel, "Spielen", Vector2(722, 64), func(): _play(i), 200, 64)
	play.focus_mode = Control.FOCUS_NONE
	if not Nav.args.has("shot"):
		panel.modulate.a = 0.6
		panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)


func _previous_name(i: int) -> String:
	for j in range(i - 1, -1, -1):
		if Levels.list[j]["kind"] != "challenge":
			return "„%s“ (%s)" % [Levels.list[j]["name"], Levels.label(j)]
	return "das vorige Level"


func _flip(dir: int) -> void:
	var p := clampi(_page + dir, 0, _pages.size() - 1)
	if p == _page:
		return
	Sfx.play("click")
	var levels: Array = _pages[p]["levels"]
	if levels.is_empty():
		_show_page(p)
		for c in _info.get_children():
			c.queue_free()
		_selected = -1
		return
	# auf der neuen Seite das erste offene, noch nicht geschaffte Level wählen
	var pick: int = levels[0]
	for i in levels:
		if Levels.is_unlocked(i) and not Levels.completed(i):
			pick = i
			break
	_select(pick)


func _play(i: int) -> void:
	if i < 0 or not Levels.is_unlocked(i):
		Sfx.play("hurt")
		return
	Sfx.play("click")
	Nav.goto("game", { "level": i })


func _set_difficulty(d: String) -> void:
	Save.data["difficulty"] = d
	Save.persist()
	_show_difficulty()


func _show_difficulty() -> void:
	var cur: String = Save.data["difficulty"]
	for d in _diff_buttons:
		var b: Button = _diff_buttons[d]
		var on: bool = d == cur
		b.add_theme_stylebox_override("normal", UI.box(UI.YELLOW if on else Color(0, 0, 0, 0), 18, 0))
		b.add_theme_stylebox_override("hover", UI.box(Color("#ffd95c") if on else Color(1, 1, 1, 0.08), 18, 0))
		b.add_theme_color_override("font_color", UI.INK if on else UI.MUTED)
		b.add_theme_color_override("font_hover_color", UI.INK if on else Color.WHITE)
	_diff_info.text = DIFF_INFO[cur]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_left"):
		var d := 1 if event.is_action_pressed("move_right") else -1
		if _selected < 0:
			_flip(d)
			return
		var j := _selected + d
		if j >= 0 and j < Levels.list.size():
			Sfx.play("click")
			_select(j)
		elif j >= Levels.list.size():
			_flip(1)
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		_flip(1 if event.is_action_pressed("move_down") else -1)
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_play(_selected)


## Wischen zum Blättern (Maus oder Finger)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_from = event.position
			_dragging = true
		elif _dragging:
			_dragging = false
			var d: Vector2 = event.position - _drag_from
			if absf(d.x) > 110 and absf(d.x) > absf(d.y) * 2:
				_flip(-1 if d.x > 0 else 1)
