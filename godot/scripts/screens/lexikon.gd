extends Control
## Gegner-Lexikon: rechts alle Gegner als Kacheln (unentdeckte als Silhouette), links alles zum angetippten.

var params := {}
var _tiles: Array[Panel] = []
var _focus := 0
var _cols := 3
var _detail: Control


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	var found := 0
	for b in Bestiary.LIST:
		if b["id"] in Save.data["seen"]:
			found += 1
	var right := UI.top_bar(self, "Gegner-Lexikon")
	UI.chip(self, "icon-book", "%d/%d entdeckt" % [found, Bestiary.LIST.size()], right, 40, UI.BLUE, 10)

	var n := Bestiary.LIST.size()
	_cols = 3 if n <= 9 else 4
	var rows := ceili(n / float(_cols))
	var area := Rect2(360, 84, 576, 436)
	var gap := 12.0
	var tw := (area.size.x - gap * (_cols - 1)) / _cols
	var th := minf(132.0, (area.size.y - gap * (rows - 1)) / rows)
	for i in n:
		var b: Dictionary = Bestiary.LIST[i]
		var known: bool = b["id"] in Save.data["seen"]
		var r := Rect2(area.position + Vector2((i % _cols) * (tw + gap), (i / _cols) * (th + gap)), Vector2(tw, th))
		var tile := UI.panel(self, r, UI.LINE, Color(0.075, 0.086, 0.18, 0.9) if known else Color(0.05, 0.06, 0.13, 0.85))
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon := UI.fit(tile, b["icon"], Vector2(tw / 2, th / 2 - 12), Vector2(tw * 0.5, th * 0.5))
		if not known:
			icon.modulate = Color(0.02, 0.024, 0.06, 0.9)
		UI.label(tile, b["name"] if known else "???", Vector2(tw / 2, th - 30), 8, Color.WHITE if known else UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, tw - 8)
		if known and b["defeatable"]:
			var cnt := int(Save.data["defeated"].get(b["id"], 0))
			if cnt > 0:
				UI.label(tile, "×%d" % cnt, Vector2(tw - 10, 8), 7, Color("#ffd23f"), HORIZONTAL_ALIGNMENT_RIGHT, 60)
		tile.gui_input.connect(func(e: InputEvent):
			if UI.is_tap(e):
				Sfx.play("click")
				_show(i))
		_tiles.append(tile)
		UI.pop_in(tile, 0.02 * i, 8)
	var first := 0
	for i in n:
		if Bestiary.LIST[i]["id"] in Save.data["seen"]:
			first = i
			break
	_show(first)


func _show(i: int) -> void:
	_focus = i
	for k in _tiles.size():
		var s: StyleBoxFlat = _tiles[k].get_theme_stylebox("panel")
		s.border_color = UI.YELLOW if k == i else UI.LINE
	if _detail:
		_detail.queue_free()
	var b: Dictionary = Bestiary.LIST[i]
	var known: bool = b["id"] in Save.data["seen"]
	_detail = UI.panel(self, Rect2(24, 84, 312, 436), UI.BLUE if known else UI.LINE)
	var d := _detail
	UI.glow(d, Vector2(156, 100), 100, Color(UI.BLUE, 0.25 if known else 0.06))
	var icon := UI.fit(d, b["icon"], Vector2(156, 100), Vector2(150, 120))
	if not known:
		icon.modulate = Color(0.02, 0.024, 0.06, 0.95)
		UI.label(d, "???", Vector2(156, 186), 13, UI.DIM)
		UI.para(d, "Diesen Gegner hast du noch nicht gesehen. Spiel weiter, um ihn zu entdecken!", Vector2(24, 230), 264, 8, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		return
	UI.label(d, b["name"], Vector2(156, 182), 13, Color.WHITE)
	UI.label(d, b["where"], Vector2(156, 204), 7, UI.MUTED)
	var tg_text := ("BESIEGT: %d" % int(Save.data["defeated"].get(b["id"], 0))) if b["defeatable"] else "UNBESIEGBAR"
	var tg := UI.tag(d, tg_text, Vector2.ZERO, Color("#ffd23f") if b["defeatable"] else UI.RED, 7)
	tg.position = Vector2(156 - tg.size.x / 2, 222)
	UI.rect(d, Rect2(24, 254, 264, 2), UI.LINE)
	var beh := UI.para(d, b["behavior"], Vector2(24, 268), 264, 8, Color.WHITE)
	var tip_y := 268 + beh.get_minimum_size().y + 14
	var tip := UI.panel(d, Rect2(16, tip_y, 280, 436 - tip_y - 16), Color(UI.GREEN, 0.5), Color(UI.GREEN, 0.08))
	UI.label(tip, "TIPP", Vector2(12, 10), 7, UI.GREEN, HORIZONTAL_ALIGNMENT_LEFT, 100)
	UI.para(tip, b["tip"], Vector2(12, 28), 256, 8, Color("#d6f5d9"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
		return
	var step := 0
	if event.is_action_pressed("move_right"): step = 1
	elif event.is_action_pressed("move_left"): step = -1
	elif event.is_action_pressed("move_down"): step = _cols
	elif event.is_action_pressed("move_up"): step = -_cols
	if step != 0:
		var j := _focus + step
		if j >= 0 and j < _tiles.size():
			Sfx.play("click")
			_show(j)
