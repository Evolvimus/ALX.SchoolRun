extends Control
## Gegner-Lexikon: Welche Gegner hat man schon entdeckt? Unentdeckte erscheinen als Silhouette.

var params := {}
var _frames: Array[Panel] = []
var _detail: Control


func _ready() -> void:
	UI.screen(self)
	UI.background(self)
	var found := 0
	for b in Bestiary.LIST:
		if b["id"] in Save.data["seen"]:
			found += 1
	UI.title(self, "Gegner-Lexikon", 38)
	UI.label(self, "%d von %d entdeckt" % [found, Bestiary.LIST.size()], Vector2(480, 68), 11, Color("#c8c8d8"))
	UI.rect(self, Rect2(330, 90, 300, 8), Color("#2a2f5a"), 2, UI.DARK)
	if found > 0:
		UI.rect(self, Rect2(330, 90, 300.0 * found / Bestiary.LIST.size(), 8), Color("#5ab0ff"))
	for i in Bestiary.LIST.size():
		var b: Dictionary = Bestiary.LIST[i]
		var x := 480 + ((i % 4) - 1.5) * 222
		var y := 172 + floorf(i / 4.0) * 128
		var known: bool = b["id"] in Save.data["seen"]
		var frame := UI.rect(self, Rect2(x - 103, y - 58, 206, 116), UI.NAVY, 3, Color("#5ab0ff") if known else Color("#3a3f5e"))
		frame.mouse_filter = Control.MOUSE_FILTER_STOP
		_frames.append(frame)
		var icon := UI.fit(frame, b["icon"], Vector2(51, 56), Vector2(86, 80))
		if not known:
			icon.modulate = Color(0.02, 0.024, 0.06, 0.85)
		var name_label := UI.label(frame, b["name"] if known else "???", Vector2(101, 22), 10, Color.WHITE if known else Color("#666c88"), HORIZONTAL_ALIGNMENT_LEFT, 100)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		if known:
			var n := int(Save.data["defeated"].get(b["id"], 0))
			UI.label(frame, ("Besiegt: %d" % n) if b["defeatable"] else "Unbesiegbar", Vector2(101, 76), 8, Color("#ffd23f") if b["defeatable"] else Color("#ff8a8a"), HORIZONTAL_ALIGNMENT_LEFT, 100)
		else:
			UI.label(frame, "Noch nicht\nentdeckt", Vector2(101, 70), 8, Color("#666c88"), HORIZONTAL_ALIGNMENT_LEFT, 100)
		frame.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT or e is InputEventScreenTouch and e.pressed:
				Sfx.play("click")
				_show(i, known))
	var first := -1
	for i in Bestiary.LIST.size():
		if Bestiary.LIST[i]["id"] in Save.data["seen"]:
			first = i
			break
	_show(first, first >= 0)
	UI.back_button(self)


func _show(i: int, known: bool) -> void:
	for k in _frames.size():
		var s: StyleBoxFlat = _frames[k].get_theme_stylebox("panel")
		var seen: bool = Bestiary.LIST[k]["id"] in Save.data["seen"]
		s.border_color = UI.YELLOW if k == i else Color("#5ab0ff") if seen else Color("#3a3f5e")
	if _detail:
		_detail.queue_free()
	_detail = UI.rect(self, Rect2(180, 376, 760, 112), Color(0.043, 0.043, 0.051, 0.9), 3, UI.YELLOW)
	if i < 0 or not known:
		var text := "Diesen Gegner hast du noch nicht gesehen.\nSpiel weiter, um ihn zu entdecken!" if i >= 0 else "Noch keine Gegner entdeckt.\nSpiel das Tutorial oder Level 1!"
		UI.label(_detail, text, Vector2(380, 38), 11, Color("#c8c8d8"), HORIZONTAL_ALIGNMENT_CENTER, 740)
		return
	var b: Dictionary = Bestiary.LIST[i]
	UI.label(_detail, b["name"].to_upper(), Vector2(16, 12), 13, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, 400)
	UI.label(_detail, b["where"], Vector2(744, 14), 8, Color("#9a9aa8"), HORIZONTAL_ALIGNMENT_RIGHT, 400)
	var beh := UI.label(_detail, b["behavior"], Vector2(16, 36), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 728)
	beh.autowrap_mode = TextServer.AUTOWRAP_WORD
	var tip := UI.label(_detail, "TIPP: " + b["tip"], Vector2(16, 74), 9, Color("#a6e07a"), HORIZONTAL_ALIGNMENT_LEFT, 728)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		Nav.goto("menu")
