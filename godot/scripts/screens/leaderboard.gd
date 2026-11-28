extends Control
## Rangliste für alle: Gesamtpunkte, Bestzeiten je Level und die Tagesaufgabe.

var params := {}
var _tab := "total"
var _level := 1
var _list: Control
var _tabs := {}
var _level_row: Control
var _busy := 0

const TABS := [["total", "Gesamt"], ["level", "Level"], ["daily", "Heute"]]


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	var right := UI.top_bar(self, "Rangliste", "menu", "für alle Spieler*innen")
	UI.chip(self, "icon-star", Names.current(), right, 40, UI.YELLOW, 8)
	_tab = str(params.get("tab", "total"))
	_level = int(params.get("level", 1))
	var w := 140.0
	for i in TABS.size():
		var t: String = TABS[i][0]
		var b := UI.button(self, TABS[i][1], Vector2(480 + (i - 1) * (w + 6), 104), func(): _set_tab(t), w, 40)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 10)
		_tabs[t] = b
	_level_row = Control.new()
	_level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_row)
	_list = Control.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list)
	_set_tab(_tab)


func _set_tab(t: String) -> void:
	_tab = t
	for k in _tabs:
		var on: bool = k == t
		var b: Button = _tabs[k]
		b.add_theme_stylebox_override("normal", UI.box(UI.YELLOW if on else UI.PANEL_LIGHT, 12, 2, UI.YELLOW if on else UI.LINE))
		b.add_theme_stylebox_override("hover", UI.box(Color("#ffd95c") if on else Color("#262c5a"), 12, 2, UI.YELLOW if on else Color("#4a5394")))
		b.add_theme_color_override("font_color", UI.INK if on else UI.MUTED)
		b.add_theme_color_override("font_hover_color", UI.INK if on else Color.WHITE)
	for c in _level_row.get_children():
		c.queue_free()
	if t == "level":
		var prev := UI.icon_button(_level_row, "icon-back", Vector2(250, 150), func(): _step_level(-1), 40, 2.0)
		prev.focus_mode = Control.FOCUS_NONE
		var next := UI.icon_button(_level_row, "icon-back", Vector2(710, 150), func(): _step_level(1), 40, 2.0)
		next.focus_mode = Control.FOCUS_NONE
		(next.get_node("Icon") as TextureRect).flip_h = true
		var lv: Dictionary = Levels.list[_level]
		UI.label(_level_row, "%s · %s" % [Levels.label(_level), lv["name"]], Vector2(480, 144), 10, Color.WHITE)
	elif t == "daily":
		var lv: Dictionary = Levels.list[Daily.level_index()]
		UI.label(_level_row, "%s · %s · %s" % [Daily.today(), lv["name"], Daily.modifier()["name"]], Vector2(480, 144), 9, Color.WHITE)
	else:
		UI.label(_level_row, "Punkte aus allen Leveln: Blätter, Medaillen und Tempo", Vector2(480, 144), 8, UI.MUTED)
	_load()


func _step_level(d: int) -> void:
	var n := Levels.list.size()
	_level = posmod(_level + d, n)
	if Levels.list[_level]["kind"] == "tutorial":
		_level = posmod(_level + d, n)
	_set_tab("level")


func _load() -> void:
	for c in _list.get_children():
		c.queue_free()
	_busy += 1
	var ticket := _busy
	var loading := UI.label(_list, "Lade …", Vector2(480, 300), 10, UI.MUTED)
	var key := ""
	if _tab == "level":
		key = Levels.list[_level]["id"]
	elif _tab == "daily":
		key = Daily.today()
	var res: Dictionary = await Backend.leaderboard(_tab, key)
	if ticket != _busy or not is_inside_tree():
		return
	loading.queue_free()
	var p := UI.panel(_list, Rect2(170, 170, 620, 330))
	var rows: Array = res["rows"]
	if not res["ok"]:
		UI.label(p, "Keine Verbindung – versuch es später nochmal.", Vector2(310, 150), 9, UI.RED, HORIZONTAL_ALIGNMENT_CENTER, 600)
		return
	if rows.is_empty():
		UI.label(p, "Noch keine Einträge – sei die oder der Erste!", Vector2(310, 150), 9, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 600)
		return
	var y := 14.0
	var shown := 0
	for r in rows:
		if shown >= 11:
			break
		shown += 1
		var me: bool = r.get("me", false)
		var rank := int(r["rank"])
		var row := UI.rect(p, Rect2(12, y, 596, 26), Color(UI.YELLOW, 0.16) if me else Color(1, 1, 1, 0.03 if shown % 2 == 0 else 0.0), 2 if me else 0, UI.YELLOW if me else Color.TRANSPARENT, 8)
		var medal_col: Color = [Color("#ffd23f"), Color("#d0d6e8"), Color("#e09a5a")][rank - 1] if rank <= 3 else UI.MUTED
		UI.label(row, "%d." % rank, Vector2(40, 7), 9, medal_col, HORIZONTAL_ALIGNMENT_RIGHT, 40)
		UI.label(row, str(r["name"]), Vector2(56, 7), 9, Color.WHITE if me else Color("#dfe2f2"), HORIZONTAL_ALIGNMENT_LEFT, 400)
		var v := float(r["value"])
		UI.label(row, ("%d P" % int(v)) if _tab == "total" else ("%.1f s" % v), Vector2(584, 7), 9, UI.YELLOW if me else Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 160)
		y += 28
	if res.get("sample", false):
		UI.label(p, "TESTMODUS · Beispiel-Einträge, kein Server verbunden", Vector2(310, 312), 7, Color("#a05a6a"), HORIZONTAL_ALIGNMENT_CENTER, 600)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
	elif _tab == "level" and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		_step_level(1 if event.is_action_pressed("move_right") else -1)
